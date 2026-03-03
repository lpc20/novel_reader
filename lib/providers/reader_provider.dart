import 'package:flutter/material.dart';
import '../models/chapter.dart';
import '../models/reading_progress.dart';
import '../services/file_service.dart';
import '../services/settings_service.dart';
import '../services/bookshelf_service.dart';

class ReaderProvider extends ChangeNotifier {
  final FileService _fileService = FileService();
  final SettingsService _settingsService = SettingsService();
  final BookshelfService _bookshelfService = BookshelfService();

  String _content = '';
  List<Chapter> _chapters = [];
  int _currentChapterIndex = 0;
  String? _novelId;
  bool _isLoading = false;
  double _scrollProgress = 0.0;
  bool _showMenu = false;

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
  bool get showMenu => _showMenu;
  String? get novelId => _novelId;

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
      }
      if (contentWithoutTitle.startsWith('\r\n')) {
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

  void toggleMenu() {
    _showMenu = !_showMenu;
    notifyListeners();
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
  }

  Future<void> setFontSize(double size) async {
    await _settingsService.setFontSize(size);
    notifyListeners();
  }

  Future<void> setLineHeight(double height) async {
    await _settingsService.setLineHeight(height);
    notifyListeners();
  }

  Future<void> setTheme(int index) async {
    await _settingsService.setTheme(index);
    notifyListeners();
  }
}
