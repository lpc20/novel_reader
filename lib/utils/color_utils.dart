import 'package:flutter/material.dart';
import '../utils/cache_manager.dart';
import '../constants/global.dart';

class ColorUtils {
  static final CacheManager _cacheManager = CacheManager();

  static Color parseColor(String hexColor) {
    // 生成缓存键
    final cacheKey = hexColor.replaceAll('#', '');
    
    // 检查缓存中是否存在
    final cachedColor = _cacheManager.get<Color>(Global.COLOR_CACHE_REGION, cacheKey);
    if (cachedColor != null) {
      return cachedColor;
    }

    try {
      hexColor = hexColor.replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor';
      }
      final color = Color(int.parse(hexColor, radix: 16));
      // 缓存结果
      _cacheManager.put(Global.COLOR_CACHE_REGION, cacheKey, color);
      return color;
    } catch (e) {
      return const Color(0xFFF5F5DC);
    }
  }

  static Brightness getBrightness(Color color) {
    return color.computeLuminance() > 0.5 ? Brightness.dark : Brightness.light;
  }

  // 初始化缓存区域
  static void init() {
    _cacheManager.registerRegion(CacheRegionConfig(
      name: Global.COLOR_CACHE_REGION,
      maxSizeBytes: Global.COLOR_CACHE_SIZE,
      defaultExpiry: Global.COLOR_CACHE_EXPIRY,
    ));
  }
}
