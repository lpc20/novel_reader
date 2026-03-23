import 'package:flutter/material.dart';
import '../models/chapter.dart';
import '../models/reading_progress.dart';
import '../models/bookmark.dart';
import '../models/reader_data.dart';
import '../models/menu_data.dart';
import '../services/reader_repository.dart';
import '../services/settings_service.dart';
import '../utils/cache_manager.dart';
import '../constants/global.dart';

/// 阅读器视图模型，管理阅读器相关的状态和逻辑
class ReaderViewModel extends ChangeNotifier {
  final ReaderRepository _readerRepository;

  /// 小说内容
  String _content = '';

  /// 章节列表
  List<Chapter> _chapters = [];

  /// 当前章节索引
  int _currentChapterIndex = 0;

  /// 小说ID
  String? _novelId;

  /// 加载状态
  bool _isLoading = true;

  /// 滚动进度（表示当前章节内的阅读进度，范围 0.0-1.0）
  double _progressInChapter = 0.0;

  /// 当前页码
  int _currentPage = 0;

  /// 总页码
  int _totalPages = 0;

  // 搜索相关状态
  /// 搜索查询
  String _searchQuery = '';

  /// 搜索结果
  final List<SearchResult> _searchResults = [];

  /// 当前搜索结果索引
  int _currentSearchIndex = -1;

  // 缓存管理器
  final CacheManager _cacheManager = CacheManager();

  /// 最大预加载章节数
  static const int _maxPreloadChapters = 3;

  ReaderViewModel({ReaderRepository? readerRepository})
    : _readerRepository = readerRepository ?? ReaderRepository() {
    // 注册缓存区域
    _cacheManager.registerRegion(
      CacheRegionConfig(
        name: Global.CHAPTER_CONTENT_CACHE_REGION,
        maxSizeBytes: Global.CHAPTER_CONTENT_CACHE_SIZE,
        defaultExpiry: Global.CHAPTER_CONTENT_CACHE_EXPIRY,
      ),
    );
  }

  /// 获取屏幕数据
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

  /// 获取菜单数据
  MenuData get menuData => MenuData(
    currentChapterIndex: _currentChapterIndex,
    chaptersLength: _chapters.length,
    fontSize: settings.fontSize,
    lineHeight: settings.lineHeight,
    fontFamily: settings.fontFamily,
    themeIndex: settings.themeIndex,
  );

  /// 设置加载状态
  void setIsLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// 获取小说内容
  String get content => _content;

  /// 获取章节列表
  List<Chapter> get chapters => _chapters;

  /// 获取当前章节索引
  int get currentChapterIndex => _currentChapterIndex;

  /// 获取当前章节
  Chapter? get currentChapter =>
      _chapters.isNotEmpty && _currentChapterIndex < _chapters.length
      ? _chapters[_currentChapterIndex]
      : null;

  /// 获取加载状态
  bool get isLoading => _isLoading;

  /// 获取滚动当前章节内的阅读进度（范围 0.0-1.0）
  double get progressInChapter => _progressInChapter;

  /// 获取当前页码
  int get currentPage => _currentPage;

  /// 获取总页码
  int get totalPages => _totalPages;

  /// 获取阅读设置
  ReadingSettings get settings => _readerRepository.getSettings();

  /// 获取是否使用分页模式
  bool get usePageMode => settings.usePageMode;

  /// 获取小说ID
  String? get novelId => _novelId;

  /// 获取搜索查询
  String get searchQuery => _searchQuery;

  /// 获取搜索结果
  List<SearchResult> get searchResults => _searchResults;

  /// 获取当前搜索结果索引
  int get currentSearchIndex => _currentSearchIndex;

  /// 是否有搜索结果
  bool get hasSearchResults => _searchResults.isNotEmpty;

  /// 加载小说
  Future<void> loadNovel(
    String novelId,
    String filePath,
    String encoding,
  ) async {
    _isLoading = true;
    _novelId = novelId;
    notifyListeners();

    try {
      // 加载小说内容
      _content = await _readerRepository.loadContent(
        filePath: filePath,
        encoding: encoding,
      );

      // 解析章节
      _chapters = await _readerRepository.parseChapters(
        content: _content,
        cacheKey: novelId,
      );

      // 加载阅读进度
      final progress = _readerRepository.getProgress(novelId);
      if (progress != null && progress.chapterIndex < _chapters.length) {
        _currentChapterIndex = progress.chapterIndex;
        // 加载保存的章节内进度（适用于滚动模式和分页模式）
        _progressInChapter = progress.progressInChapter;

        // 如果是分页模式，需要根据 scrollProgress 计算当前页码
        if (settings.usePageMode && _totalPages > 0) {
          _currentPage = (_progressInChapter * _totalPages).round();
        }
      } else {
        _currentChapterIndex = 0;
        _progressInChapter = 0.0;
        _currentPage = 0;
      }

      // 更新最后阅读时间
      await _readerRepository.updateLastReadTime(novelId);

      // 预加载当前章节和相邻章节
      _preloadAdjacentChapters();
    } catch (e) {
      debugPrint('ReaderViewModel loadNovel error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 获取当前章节内容
  List<String> getCurrentChapterContent() {
    return getChapterContent(_currentChapterIndex);
  }

  /// 跳转到指定章节
  void goToChapter(int index) {
    if (index >= 0 && index < _chapters.length) {
      _currentChapterIndex = index;
      _progressInChapter = 0.0;
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
    if (prevIndex >= 0) {
      _preloadChapter(prevIndex);
    }

    // 预加载下一章（不等待，避免阻塞）
    if (nextIndex < _chapters.length) {
      _preloadChapter(nextIndex);
    }

    // 清理过期的缓存，只保留当前章节附近的缓存
    _cleanupOldCache();
  }

  /// 在后台加载指定章节内容
  Future<void> _preloadChapter(int index) async {
    if (index < 0 || index >= _chapters.length) return;

    try {
      // 生成缓存键
      final cacheKey = '$_novelId:$index';

      // 检查缓存是否存在
      if (_cacheManager.get<List<String>>(
            Global.CHAPTER_CONTENT_CACHE_REGION,
            cacheKey,
          ) ==
          null) {
        // 使用 microtask 避免阻塞 UI
        await Future.microtask(() {
          final content = _computeChapterContent(index);
          if (_novelId != null) {
            _cacheManager.put(
              Global.CHAPTER_CONTENT_CACHE_REGION,
              cacheKey,
              content,
            );
          }
        });
      }
    } catch (e) {
      debugPrint('ReaderViewModel _preloadChapter error: $e');
    }
  }

  /// 清理过期的章节缓存，只保留当前章节附近的内容
  void _cleanupOldCache() {
    // 由于 CacheManager 已经内置了过期缓存清理和大小控制机制
    // 这里可以简化实现，或者直接移除
    // 手动清理当前章节范围外的缓存，以进一步优化内存使用
    if (_novelId != null) {
      // 清理当前章节范围外的缓存
      for (int i = 0; i < _chapters.length; i++) {
        if ((i - _currentChapterIndex).abs() > _maxPreloadChapters) {
          final cacheKey = '$_novelId:$i';
          _cacheManager.remove(Global.CHAPTER_CONTENT_CACHE_REGION, cacheKey);
        }
      }
    }
  }

  /// 获取章节内容，优先从缓存读取
  List<String> getChapterContent(int index) {
    if (index < 0 || index >= _chapters.length) return [];

    // 生成缓存键
    final cacheKey = '$_novelId:$index';

    // 优先从缓存读取
    final cachedContent = _cacheManager.get<List<String>>(
      Global.CHAPTER_CONTENT_CACHE_REGION,
      cacheKey,
    );
    if (cachedContent != null) {
      return cachedContent;
    }

    // 缓存未命中，实时计算
    final content = _computeChapterContent(index);
    // 缓存结果
    if (_novelId != null) {
      _cacheManager.put(Global.CHAPTER_CONTENT_CACHE_REGION, cacheKey, content);
    }
    return content;
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

  /// 上一章
  void previousChapter() {
    if (_currentChapterIndex > 0) {
      goToChapter(_currentChapterIndex - 1);
    }
  }

  /// 下一章
  void nextChapter() {
    if (_currentChapterIndex < _chapters.length - 1) {
      goToChapter(_currentChapterIndex + 1);
    }
  }

  /// 更新章节内阅读进度
  void updateProgressInChapter(double progress) {
    _progressInChapter = progress.clamp(0.0, 1.0);
    _saveProgress();
  }

  /// 保存阅读进度
  Future<void> _saveProgress() async {
    if (_novelId == null) return;

    try {
      // 保存阅读进度（scrollProgress 表示当前章节内的进度）
      await _readerRepository.saveProgress(
        ReadingProgress(
          novelId: _novelId!,
          chapterIndex: _currentChapterIndex,
          progressInChapter: _progressInChapter,
        ),
      );

      // 更新小说的整体阅读进度
      if (_chapters.isNotEmpty) {
        final overallProgress =
            (_currentChapterIndex + _progressInChapter) / _chapters.length;
        final novel = _readerRepository.getNovel(_novelId!);
        if (novel != null) {
          final updatedNovel = novel.copyWith(
            lastReadProgress: overallProgress.clamp(0.0, 1.0),
          );
          await _readerRepository.updateNovel(updatedNovel);
        }
      }
    } catch (e) {
      debugPrint('ReaderViewModel _saveProgress error: $e');
    }
  }

  /// 设置字体大小
  Future<void> setFontSize(double size) async {
    try {
      await _readerRepository.setFontSize(size);
      notifyListeners();
    } catch (e) {
      debugPrint('ReaderViewModel setFontSize error: $e');
    }
  }

  /// 设置行高
  Future<void> setLineHeight(double height) async {
    try {
      await _readerRepository.setLineHeight(height);
      notifyListeners();
    } catch (e) {
      debugPrint('ReaderViewModel setLineHeight error: $e');
    }
  }

  /// 设置字体
  Future<void> setFontFamily(String fontFamily) async {
    try {
      await _readerRepository.setFontFamily(fontFamily);
      notifyListeners();
    } catch (e) {
      debugPrint('ReaderViewModel setFontFamily error: $e');
    }
  }

  /// 设置主题
  Future<void> setTheme(int index) async {
    try {
      await _readerRepository.setTheme(index);
      notifyListeners();
    } catch (e) {
      debugPrint('ReaderViewModel setTheme error: $e');
    }
  }

  /// 设置页面模式
  Future<void> setUsePageMode(bool value) async {
    try {
      await _readerRepository.setUsePageMode(value);
      notifyListeners();
    } catch (e) {
      debugPrint('ReaderViewModel setUsePageMode error: $e');
    }
  }

  /// 更新页面信息
  void updatePageInfo({required int currentPage, required int totalPages}) {
    _currentPage = currentPage;
    _totalPages = totalPages;
    // 计算当前章节内的进度（0.0-1.0）
    final chapterProgress = _totalPages == 0 ? 0.0 : currentPage / totalPages;
    _progressInChapter = chapterProgress.clamp(0.0, 1.0);
    _saveProgress();
  }

  /// 执行搜索
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

  /// 下一个搜索结果
  void nextSearchResult() {
    if (_searchResults.isEmpty) return;

    _currentSearchIndex = (_currentSearchIndex + 1) % _searchResults.length;
    notifyListeners();
  }

  /// 上一个搜索结果
  void previousSearchResult() {
    if (_searchResults.isEmpty) return;

    _currentSearchIndex =
        (_currentSearchIndex - 1 + _searchResults.length) %
        _searchResults.length;
    notifyListeners();
  }

  /// 清除搜索
  void clearSearch() {
    _searchQuery = '';
    _searchResults.clear();
    _currentSearchIndex = -1;
    notifyListeners();
  }

  /// 添加书签
  Future<void> addBookmark() async {
    if (_novelId == null || currentChapter == null) return;

    try {
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
        progressInChapter: _progressInChapter,
        contentPreview: contentPreview,
        createdAt: DateTime.now(),
      );

      await _readerRepository.addBookmark(bookmark);
      notifyListeners();
    } catch (e) {
      debugPrint('ReaderViewModel addBookmark error: $e');
    }
  }

  /// 删除书签
  Future<void> removeBookmark(String bookmarkId) async {
    try {
      await _readerRepository.removeBookmark(bookmarkId);
      notifyListeners();
    } catch (e) {
      debugPrint('ReaderViewModel removeBookmark error: $e');
    }
  }

  /// 获取书签列表
  List<Bookmark> getBookmarks() {
    if (_novelId == null) return [];
    try {
      return _readerRepository.getBookmarks(_novelId!);
    } catch (e) {
      debugPrint('ReaderViewModel getBookmarks error: $e');
      return [];
    }
  }
}
