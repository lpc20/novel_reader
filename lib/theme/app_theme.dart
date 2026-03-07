import 'package:flutter/material.dart';

class AppColors {
  static const Color menuBackground = Color(0xFF333333);
  static const Color menuText = Color(0xFFCCCCCC);
  static const Color menuIcon = Color(0xFFC9C9C9);
  static const Color menuDivider = Color(0xFFFFFFFF);
  static const Color menuHighlight = Color(0xFFFF7135);
  static const Color buttonHighlight = Color(0xFFFF7135);
  static const Color buttonBackground = Color(0xFFFBEAD8);
  static const Color buttonText = Color(0xFF474747);
  static const Color sliderThumb = Color(0xFF4E4E4E);
  static const Color sliderActive = Color(0xFFFF7532);
  static const Color sliderInactive = Color(0xFF4c4c4c);

  static Color get menuBackgroundColor => menuBackground;
  static Color get menuTextColor => menuText;
  static Color get menuIconColor => menuIcon;
  static Color get menuDividerColor => menuDivider;
  static Color get menuHighlightColor => menuHighlight;
  static Color get buttonHighlightColor => buttonHighlight;
  static Color get buttonBackgroundColor => buttonBackground;
  static Color get buttonTextColor => buttonText;
  static Color get menuSliderThumbColor => sliderThumb;
  static Color get menuSliderActiveColor => sliderActive;
  static Color get menuSliderInactiveColor => sliderInactive;
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.menuHighlight,
        brightness: Brightness.light,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.menuHighlight,
        brightness: Brightness.dark,
      ),
    );
  }
}
