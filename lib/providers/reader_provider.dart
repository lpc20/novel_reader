import 'package:flutter/material.dart';
import '../models/chapter.dart';
import '../models/reading_progress.dart';
import '../models/bookmark.dart';
import '../models/reader_data.dart';
import '../services/file_service.dart';
import '../services/settings_service.dart';
import '../services/bookshelf_service.dart';
import '../services/bookmarks_service.dart';

class ReaderProvider extends ChangeNotifier {
  final FileService _fileService = FileService();
  final SettingsService _settingsService = SettingsService();
  final BookshelfService _bookshelfService = BookshelfService();
  final BookmarksService _bookmarksService = BookmarksService();

  String _content = '';
  List<Chapter> _chapters = [];
  int _currentChapterIndex = 0;
  String? _novelId;
  bool _isLoading = false;
  double _scrollProgress = 0.0;

  // 搜索相关状态
  String _searchQuery = '';
  final List<SearchResult> _searchResults = [];
  int _currentSearchIndex = -1;

  String get content => _content;
  List<Chapter> get chapters => _chapters;
  int get currentChapterIndex => _currentChapterIndex;
  Chapter? get currentChapter =>
      _chapters.isNotEmpty && _currentChapterIndex < _chapters.length
      ? _chapters[_currentChapterIndex]
      : null;
  bool get isLoading => _isLoading;
  double get scrollProgress => _scrollProgress;
  ReadingSettings get settings => _settingsService.settings;
  String? get novelId => _novelId;
  String get searchQuery => _searchQuery;
  List<SearchResult> get searchResults => _searchResults;
  int get currentSearchIndex => _currentSearchIndex;
  bool get hasSearchResults => _searchResults.isNotEmpty;

  Future<void> loadNovel(
    String novelId,
    String filePath,
    String encoding,
  ) async {
    _isLoading = true;
    _novelId = novelId;
    notifyListeners();

    try {
      _content = await _fileService.readFileContent(filePath, encoding);
      _chapters = await _fileService.parseChapters(_content, cacheKey: novelId);

      final progress = _bookshelfService.getProgress(novelId);
      if (progress != null && progress.chapterIndex < _chapters.length) {
        _currentChapterIndex = progress.chapterIndex;
        _scrollProgress = progress.scrollProgress;
      } else {
        _currentChapterIndex = 0;
        _scrollProgress = 0.0;
      }

      await _bookshelfService.updateLastReadTime(novelId);
    } catch (e) {
      debugPrint('Error loading novel: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  List<String> getCurrentChapterContent() {
    if (currentChapter == null) return [];
    final chapterTitle = currentChapter!.title;

    // 添加边界检查，防止越界
    final start = currentChapter!.startPosition;
    final end = currentChapter!.endPosition;

    if (start < 0 || end > _content.length || start >= end) {
      return [];
    }

    final fullContent = _content.substring(start, end);

    if (fullContent.startsWith(chapterTitle)) {
      var contentWithoutTitle = fullContent.substring(chapterTitle.length);
      // 只删除标题后的换行符，保留正文开头的空格缩进
      if (contentWithoutTitle.startsWith('\n')) {
        contentWithoutTitle = contentWithoutTitle.substring(1);
      } else if (contentWithoutTitle.startsWith('\r\n')) {
        contentWithoutTitle = contentWithoutTitle.substring(2);
      }
      return contentWithoutTitle
          .split('\n')
          .where((p) => p.trim().isNotEmpty)
          .toList();
    }

    return fullContent.split('\n').where((p) => p.trim().isNotEmpty).toList();
  }

  void goToChapter(int index) {
    if (index >= 0 && index < _chapters.length) {
      _currentChapterIndex = index;
      _scrollProgress = 0.0;
      _saveProgress();
      notifyListeners();
    }
  }

  void previousChapter() {
    if (_currentChapterIndex > 0) {
      goToChapter(_currentChapterIndex - 1);
    }
  }

  void nextChapter() {
    if (_currentChapterIndex < _chapters.length - 1) {
      goToChapter(_currentChapterIndex + 1);
    }
  }

  void updateScrollProgress(double progress) {
    _scrollProgress = progress.clamp(0.0, 1.0);
    _saveProgress();
  }

  Future<void> _saveProgress() async {
    if (_novelId == null) return;

    await _bookshelfService.saveProgress(
      ReadingProgress(
        novelId: _novelId!,
        chapterIndex: _currentChapterIndex,
        positionInChapter: 0,
        scrollProgress: _scrollProgress,
      ),
    );
    if (_chapters.isNotEmpty) {
      final overallProgress =
          (_currentChapterIndex + _scrollProgress) / _chapters.length;
      final novel = _bookshelfService.getNovel(_novelId!);
      if (novel != null) {
        final updatedNovel = novel.copyWith(
          lastReadProgress: overallProgress.clamp(0.0, 1.0),
        );
        await _bookshelfService.updateNovel(updatedNovel);
      }
    }
  }

  Future<void> setFontSize(double size) async {
    await _settingsService.setFontSize(size);
    notifyListeners();
  }

  Future<void> setLineHeight(double height) async {
    await _settingsService.setLineHeight(height);
    notifyListeners();
  }

  Future<void> setFontFamily(String fontFamily) async {
    await _settingsService.setFontFamily(fontFamily);
    notifyListeners();
  }

  Future<void> setTheme(int index) async {
    await _settingsService.setTheme(index);
    notifyListeners();
  }

  // 搜索相关方法
  void performSearch(String query) {
    _searchQuery = query;
    _currentSearchIndex = -1;

    if (query.isEmpty) {
      _searchResults.clear();
      notifyListeners();
      return;
    }

    final paragraphs = getCurrentChapterContent();
    _searchResults.clear();

    for (int i = 0; i < paragraphs.length; i++) {
      final paragraph = paragraphs[i];
      int startIndex = 0;
      while (startIndex < paragraph.length) {
        final index = paragraph.indexOf(query, startIndex);
        if (index == -1) break;

        _searchResults.add(
          SearchResult(
            paragraphIndex: i,
            startIndex: index,
            endIndex: index + query.length,
          ),
        );

        startIndex = index + query.length;
      }
    }

    // 如果有搜索结果，自动选中第一个
    if (_searchResults.isNotEmpty) {
      _currentSearchIndex = 0;
    }

    notifyListeners();
  }

  void nextSearchResult() {
    if (_searchResults.isEmpty) return;

    _currentSearchIndex = (_currentSearchIndex + 1) % _searchResults.length;
    notifyListeners();
  }

  void previousSearchResult() {
    if (_searchResults.isEmpty) return;

    _currentSearchIndex =
        (_currentSearchIndex - 1 + _searchResults.length) %
        _searchResults.length;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _searchResults.clear();
    _currentSearchIndex = -1;
    notifyListeners();
  }

  // 书签相关方法
  Future<void> addBookmark() async {
    if (_novelId == null || currentChapter == null) return;

    final paragraphs = getCurrentChapterContent();
    String contentPreview = '';
    if (paragraphs.isNotEmpty) {
      contentPreview = paragraphs.first.length > 50
          ? '${paragraphs.first.substring(0, 50)}...'
          : paragraphs.first;
    }

    final bookmark = Bookmark(
      id: '${_novelId}_${DateTime.now().millisecondsSinceEpoch}',
      novelId: _novelId!,
      chapterIndex: _currentChapterIndex,
      chapterTitle: currentChapter!.title,
      scrollProgress: _scrollProgress,
      contentPreview: contentPreview,
      createdAt: DateTime.now(),
    );

    await _bookmarksService.addBookmark(bookmark);
    notifyListeners();
  }

  Future<void> removeBookmark(String bookmarkId) async {
    await _bookmarksService.removeBookmark(bookmarkId);
    notifyListeners();
  }

  List<Bookmark> getBookmarks() {
    if (_novelId == null) return [];
    return _bookmarksService.getBookmarks(_novelId!);
  }
}
