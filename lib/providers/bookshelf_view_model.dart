import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/novel.dart';
import '../models/reading_progress.dart';
import '../services/bookshelf_repository.dart';
import '../utils/cache_manager.dart';

/// 排序类型枚举
enum SortType {
  byAddTime, // 按添加时间排序
  byTitle, // 按书名排序
  byFileSize, // 按文件大小排序
  byLastRead, // 按最近阅读排序
}

/// 书架视图模型，管理书架相关的状态和逻辑
class BookshelfViewModel extends ChangeNotifier {
  final BookshelfRepository _repository;
  late final SharedPreferences _prefs;

  /// 构造函数
  BookshelfViewModel({BookshelfRepository? repository})
    : _repository = repository ?? BookshelfRepository() {
    // 注册缓存区域
    _cacheManager.registerRegion(
      CacheRegionConfig(
        name: 'bookshelf_cache',
        maxSizeBytes: 5 * 1024 * 1024, // 5MB
        defaultExpiry: Duration(minutes: 30),
      ),
    );
  }

  /// 获取排序后的小说列表
  List<Novel> get novels => _sortedNovels;

  /// 加载状态
  bool _isLoading = false;

  /// 错误信息
  String? _error;

  /// 当前排序类型
  SortType _currentSortType = SortType.byAddTime;

  /// 获取加载状态
  bool get isLoading => _isLoading;

  /// 获取错误信息
  String? get error => _error;

  /// 获取当前排序类型
  SortType get currentSortType => _currentSortType;

  // 缓存管理器
  final CacheManager _cacheManager = CacheManager();

  // 缓存键前缀
  static const String SORTED_NOVELS_CACHE_KEY = 'sorted_novels';

  /// 获取排序后的小说列表（带缓存）
  List<Novel> get _sortedNovels {
    // 生成缓存键
    final cacheKey = '$SORTED_NOVELS_CACHE_KEY:${_currentSortType.index}';

    // 检查缓存是否有效
    final cachedSortedNovels = _cacheManager.get<List<Novel>>(
      'bookshelf_cache',
      cacheKey,
    );
    if (cachedSortedNovels != null) {
      return cachedSortedNovels;
    }

    final novels = _repository.novels;
    List<Novel> sortedNovels;

    switch (_currentSortType) {
      case SortType.byAddTime:
        sortedNovels = List.from(novels); // 保持原始顺序（添加时间）
        break;
      case SortType.byTitle:
        sortedNovels = List.from(novels)
          ..sort((a, b) => a.title.compareTo(b.title));
        break;
      case SortType.byFileSize:
        sortedNovels = List.from(novels)
          ..sort((a, b) => b.fileSize.compareTo(a.fileSize));
        break;
      case SortType.byLastRead:
        sortedNovels = List.from(novels)
          ..sort(
            (a, b) => (b.lastReadTime ?? DateTime(1970)).compareTo(
              a.lastReadTime ?? DateTime(1970),
            ),
          );
        break;
    }

    // 缓存排序结果
    _cacheManager.put('bookshelf_cache', cacheKey, sortedNovels);

    return sortedNovels;
  }

  /// 初始化方法
  Future<void> init() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 初始化SharedPreferences
      _prefs = await SharedPreferences.getInstance();
      // 加载保存的排序类型
      final savedSortType = _prefs.getInt('sortType');
      if (savedSortType != null) {
        _currentSortType = SortType.values[savedSortType];
      }
    } catch (e) {
      _error = '初始化失败: ${e.toString()}';
      debugPrint('BookshelfViewModel init error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 导入小说
  Future<bool> importNovel(String filePath) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.importAndPersistNovel(filePath);
      // 清除缓存，因为小说列表已更新
      _clearCache();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = '导入失败: ${e.toString()}';
      debugPrint('BookshelfViewModel importNovel error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 删除小说
  Future<void> removeNovel(String novelId) async {
    try {
      await _repository.removeNovel(novelId);
      // 清除缓存，因为小说列表已更新
      _clearCache();
      notifyListeners();
    } catch (e) {
      _error = '删除失败: ${e.toString()}';
      debugPrint('BookshelfViewModel removeNovel error: $e');
      notifyListeners();
    }
  }

  /// 更新最后阅读时间
  Future<void> updateLastReadTime(String novelId) async {
    try {
      await _repository.updateLastReadTime(novelId);
      // 清除缓存，因为排序可能会变化
      _clearCache();
      notifyListeners();
    } catch (e) {
      debugPrint('BookshelfViewModel updateLastReadTime error: $e');
    }
  }

  /// 获取小说
  Novel? getNovel(String novelId) {
    return _repository.getNovel(novelId);
  }

  /// 获取阅读进度
  ReadingProgress? getProgress(String novelId) {
    return _repository.getProgress(novelId);
  }

  /// 保存阅读进度
  Future<void> saveProgress(ReadingProgress progress) async {
    try {
      await _repository.saveProgress(progress);
    } catch (e) {
      debugPrint('BookshelfViewModel saveProgress error: $e');
    }
  }

  /// 设置排序类型
  Future<void> setSortType(SortType type) async {
    if (_currentSortType == type) return; // 避免重复操作

    _currentSortType = type;
    // 保存排序类型到SharedPreferences
    try {
      await _prefs.setInt('sortType', type.index);
    } catch (e) {
      debugPrint('BookshelfViewModel setSortType error: $e');
    }
    notifyListeners();
  }

  /// 清除缓存
  void _clearCache() {
    _cacheManager.clearRegion('bookshelf_cache');
  }
}
