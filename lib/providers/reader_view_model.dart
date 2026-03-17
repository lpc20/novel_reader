import 'package:flutter/material.dart';
import '../models/chapter.dart';
import '../models/reading_progress.dart';
import '../models/bookmark.dart';
import '../models/reader_data.dart';
import '../models/menu_data.dart';
import '../services/reader_repository.dart';
import '../services/settings_service.dart';

class ReaderViewModel extends ChangeNotifier {
  final ReaderRepository _readerRepository;

  String _content = '';
  List<Chapter> _chapters = [];
  int _currentChapterIndex = 0;
  String? _novelId;
  bool _isLoading = true;
  double _scrollProgress = 0.0;
  int _currentPage = 0;
  int _totalPages = 0;

  // 搜索相关状态
  String _searchQuery = '';
  final List<SearchResult> _searchResults = [];
  int _currentSearchIndex = -1;

  // 章节内容缓存，用于预加载
  final Map<int, List<String>> _chapterContentCache = {};
  static const int _maxPreloadChapters = 3; // 最多预加载3个章节

  ReaderScreenData get screenData => ReaderScreenData(
    settings: settings,
    paragraphs: getCurrentChapterContent(),
    isLoading: _isLoading,
    currentChapterIndex: _currentChapterIndex,
    chapters: _chapters,
    searchQuery: _searchQuery,
    searchResults: List.unmodifiable(_searchResults),
    currentSearchIndex: _currentSearchIndex,
  );

  MenuData get menuData => MenuData(
    currentChapterIndex: _currentChapterIndex,
    chaptersLength: _chapters.length,
    fontSize: settings.fontSize,
    lineHeight: settings.lineHeight,
    fontFamily: settings.fontFamily,
    themeIndex: settings.themeIndex,
  );

  ReaderViewModel({ReaderRepository? readerRepository})
    : _readerRepository = readerRepository ?? ReaderRepository();

  void setIsLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String get content => _content;
  List<Chapter> get chapters => _chapters;
  int get currentChapterIndex => _currentChapterIndex;
  Chapter? get currentChapter =>
      _chapters.isNotEmpty && _currentChapterIndex < _chapters.length
      ? _chapters[_currentChapterIndex]
      : null;
  bool get isLoading => _isLoading;
  double get scrollProgress => _scrollProgress;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  ReadingSettings get settings => _readerRepository.getSettings();
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
      _content = await _readerRepository.loadContent(
        filePath: filePath,
        encoding: encoding,
      );
      _chapters = await _readerRepository.parseChapters(
        content: _content,
        cacheKey: novelId,
      );

      final progress = _readerRepository.getProgress(novelId);
      if (progress != null && progress.chapterIndex < _chapters.length) {
        _currentChapterIndex = progress.chapterIndex;
        _scrollProgress = progress.scrollProgress;
      } else {
        _currentChapterIndex = 0;
        _scrollProgress = 0.0;
      }

      await _readerRepository.updateLastReadTime(novelId);

      // 预加载当前章节和相邻章节
      _preloadAdjacentChapters();
    } catch (e) {
      // 加载失败静默处理
    }

    _isLoading = false;
    notifyListeners();
  }

  List<String> getCurrentChapterContent() {
    return getChapterContent(_currentChapterIndex);
  }

  void goToChapter(int index) {
    if (index >= 0 && index < _chapters.length) {
      _currentChapterIndex = index;
      _scrollProgress = 0.0;
      _saveProgress();
      notifyListeners();
      // 章节切换后触发预加载
      _preloadAdjacentChapters();
    }
  }

  /// 预加载相邻章节内容
  void _preloadAdjacentChapters() {
    if (_novelId == null || _chapters.isEmpty) return;

    final prevIndex = _currentChapterIndex - 1;
    final nextIndex = _currentChapterIndex + 1;

    // 预加载上一章（不等待，避免阻塞）
    if (prevIndex >= 0 && !_chapterContentCache.containsKey(prevIndex)) {
      _preloadChapter(prevIndex);
    }

    // 预加载下一章（不等待，避免阻塞）
    if (nextIndex < _chapters.length && !_chapterContentCache.containsKey(nextIndex)) {
      _preloadChapter(nextIndex);
    }

    // 清理过期的缓存，只保留当前章节附近的缓存
    _cleanupOldCache();
  }

  /// 在后台加载指定章节内容
  Future<void> _preloadChapter(int index) async {
    if (index < 0 || index >= _chapters.length) return;

    // 使用 microtask 避免阻塞 UI
    await Future.microtask(() {
      if (!_chapterContentCache.containsKey(index)) {
        _chapterContentCache[index] = _computeChapterContent(index);
      }
    });
  }

  /// 清理过期的章节缓存，只保留当前章节附近的内容
  void _cleanupOldCache() {
    final keysToRemove = <int>[];
    for (final key in _chapterContentCache.keys) {
      if ((key - _currentChapterIndex).abs() > _maxPreloadChapters) {
        keysToRemove.add(key);
      }
    }
    for (final key in keysToRemove) {
      _chapterContentCache.remove(key);
    }
  }

  /// 获取章节内容，优先从缓存读取
  List<String> getChapterContent(int index) {
    if (index < 0 || index >= _chapters.length) return [];

    // 优先从缓存读取
    if (_chapterContentCache.containsKey(index)) {
      return _chapterContentCache[index]!;
    }

    // 缓存未命中，实时计算
    return _computeChapterContent(index);
  }

  /// 计算指定章节的内容
  List<String> _computeChapterContent(int index) {
    if (index < 0 || index >= _chapters.length) return [];

    final chapter = _chapters[index];
    final start = chapter.startPosition;
    final end = chapter.endPosition;

    if (start < 0 || end > _content.length || start >= end) return [];

    final fullContent = _content.substring(start, end);
    final chapterTitle = chapter.title;

    if (fullContent.startsWith(chapterTitle)) {
      var contentWithoutTitle = fullContent.substring(chapterTitle.length);
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

    await _readerRepository.saveProgress(
      ReadingProgress(
        novelId: _novelId!,
        chapterIndex: _currentChapterIndex,
        scrollProgress: _scrollProgress,
      ),
    );
    if (_chapters.isNotEmpty) {
      final overallProgress =
          (_currentChapterIndex + _scrollProgress) / _chapters.length;
      final novel = _readerRepository.getNovel(_novelId!);
      if (novel != null) {
        final updatedNovel = novel.copyWith(
          lastReadProgress: overallProgress.clamp(0.0, 1.0),
        );
        await _readerRepository.updateNovel(updatedNovel);
      }
    }
  }

  Future<void> setFontSize(double size) async {
    await _readerRepository.setFontSize(size);
    notifyListeners();
  }

  Future<void> setLineHeight(double height) async {
    await _readerRepository.setLineHeight(height);
    notifyListeners();
  }

  Future<void> setFontFamily(String fontFamily) async {
    await _readerRepository.setFontFamily(fontFamily);
    notifyListeners();
  }

  Future<void> setTheme(int index) async {
    await _readerRepository.setTheme(index);
    notifyListeners();
  }

  Future<void> setUsePageMode(bool value) async {
    await _readerRepository.setUsePageMode(value);
    notifyListeners();
  }

  void updatePageInfo({required int currentPage, required int totalPages}) {
    _currentPage = currentPage;
    _totalPages = totalPages;
    if (_chapters.isNotEmpty) {
      final overallProgress =
          (_currentChapterIndex +
              (_totalPages == 0 ? 0.0 : currentPage / totalPages)) /
          _chapters.length;
      _scrollProgress = overallProgress.clamp(0.0, 1.0);
    }
    _saveProgress();
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

    await _readerRepository.addBookmark(bookmark);
    notifyListeners();
  }

  Future<void> removeBookmark(String bookmarkId) async {
    await _readerRepository.removeBookmark(bookmarkId);
    notifyListeners();
  }

  List<Bookmark> getBookmarks() {
    if (_novelId == null) return [];
    return _readerRepository.getBookmarks(_novelId!);
  }
}
