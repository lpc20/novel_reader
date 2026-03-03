import 'package:flutter/material.dart';

class ColorUtils {
  static final Map<String, Color> _colorCache = {};

  static Color parseColor(String hexColor) {
    // 检查缓存中是否存在
    if (_colorCache.containsKey(hexColor)) {
      return _colorCache[hexColor]!;
    }

    try {
      hexColor = hexColor.replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor';
      }
      final color = Color(int.parse(hexColor, radix: 16));
      // 缓存结果
      _colorCache[hexColor] = color;
      return color;
    } catch (e) {
      return const Color(0xFFF5F5DC);
    }
  }

  static Brightness getBrightness(Color color) {
    return color.computeLuminance() > 0.5 ? Brightness.dark : Brightness.light;
  }
}
