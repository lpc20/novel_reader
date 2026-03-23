import 'dart:math';

/// 缓存项，包含值和过期时间
class CacheItem<T> {
  final T value;
  final DateTime? expiryTime;
  final int size;

  CacheItem(this.value, this.size, {this.expiryTime});

  bool get isExpired {
    if (expiryTime == null) return false;
    return DateTime.now().isAfter(expiryTime!);
  }
}

/// 缓存区域配置
class CacheRegionConfig {
  final String name;
  final int maxSizeBytes;
  final Duration? defaultExpiry;

  const CacheRegionConfig({
    required this.name,
    required this.maxSizeBytes,
    this.defaultExpiry,
  });
}

/// 统一缓存管理类
class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  // 缓存区域
  final Map<String, Map<String, CacheItem>> _regions = {};
  // 缓存区域配置
  final Map<String, CacheRegionConfig> _regionConfigs = {};

  /// 注册缓存区域
  void registerRegion(CacheRegionConfig config) {
    _regionConfigs[config.name] = config;
    _regions[config.name] ??= {};
  }

  /// 获取缓存区域
  Map<String, CacheItem> _getRegion(String region) {
    _regions[region] ??= {};
    return _regions[region]!;
  }

  /// 获取缓存区域配置
  CacheRegionConfig _getRegionConfig(String region) {
    return _regionConfigs[region] ??
        CacheRegionConfig(
          name: region,
          maxSizeBytes: 10 * 1024 * 1024, // 默认10MB
        );
  }

  /// 存储缓存
  void put<T>(
    String region,
    String key,
    T value, {
    int? size,
    Duration? expiry,
  }) {
    final regionMap = _getRegion(region);
    final config = _getRegionConfig(region);

    // 计算大小
    final itemSize = size ?? _estimateSize(value);

    // 移除旧缓存（如果存在）
    if (regionMap.containsKey(key)) {
      regionMap.remove(key);
    }

    // 添加新缓存
    regionMap[key] = CacheItem(
      value,
      itemSize,
      expiryTime: expiry != null ? DateTime.now().add(expiry) : null,
    );

    // 清理过期缓存
    _cleanupExpired(region);

    // 检查并清理超出大小限制的缓存
    _enforceSizeLimit(region);
  }

  /// 获取缓存
  T? get<T>(String region, String key) {
    final regionMap = _getRegion(region);
    final item = regionMap[key];

    if (item == null) return null;
    if (item.isExpired) {
      regionMap.remove(key);
      return null;
    }

    return item.value as T?;
  }

  /// 移除缓存
  void remove(String region, String key) {
    final regionMap = _getRegion(region);
    regionMap.remove(key);
  }

  /// 清理指定区域的缓存
  void clearRegion(String region) {
    _regions[region]?.clear();
  }

  /// 清理所有缓存
  void clearAll() {
    _regions.clear();
  }

  /// 清理所有缓存区域的过期缓存并强制大小限制
  void clearAllCachesIfTooLarge() {
    for (final region in _regions.keys) {
      _cleanupExpired(region);
      _enforceSizeLimit(region);
    }
  }

  /// 清理指定小说的缓存
  void clearNovelCache(String novelId) {
    for (final region in _regions.keys) {
      final regionMap = _regions[region]!;
      final keysToRemove = regionMap.keys
          .where((key) => key.contains(novelId))
          .toList();
      for (final key in keysToRemove) {
        regionMap.remove(key);
      }
    }
  }

  /// 获取缓存大小
  int getRegionSize(String region) {
    final regionMap = _getRegion(region);
    return regionMap.values.fold(0, (sum, item) => sum + item.size);
  }

  /// 清理过期缓存
  void _cleanupExpired(String region) {
    final regionMap = _getRegion(region);
    final keysToRemove = <String>[];

    for (final entry in regionMap.entries) {
      if (entry.value.isExpired) {
        keysToRemove.add(entry.key);
      }
    }

    for (final key in keysToRemove) {
      regionMap.remove(key);
    }
  }

  /// 强制大小限制
  void _enforceSizeLimit(String region) {
    final regionMap = _getRegion(region);
    final config = _getRegionConfig(region);

    if (config.maxSizeBytes <= 0) return;

    int currentSize = getRegionSize(region);
    if (currentSize <= config.maxSizeBytes) return;

    // 按访问时间排序（这里简化处理，实际应该跟踪访问时间）
    final entries = regionMap.entries.toList();
    entries.shuffle(); // 随机顺序，实际应该按LRU排序

    for (final entry in entries) {
      if (currentSize <= config.maxSizeBytes) break;
      currentSize -= entry.value.size;
      regionMap.remove(entry.key);
    }
  }

  /// 估算对象大小（简化实现）
  int _estimateSize(dynamic value) {
    if (value == null) return 0;
    if (value is String) return value.length * 2; // 每个字符2字节
    if (value is List) return value.length * 4; // 每个元素4字节
    if (value is Map) return value.length * 8; // 每个键值对8字节
    if (value is int || value is double || value is bool) return 8; // 基本类型8字节
    return 100; // 默认100字节
  }
}
