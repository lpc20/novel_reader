import 'dart:ui';

class Global {
  static const int scrollThrottleDelay = 300;
  static const int defaultCacheLimitBytes = 50 * 1024 * 1024;
  static const Duration menuAnimationDuration = Duration(milliseconds: 300);
  static const Duration fadeAnimationDuration = Duration(milliseconds: 300);
  static const Duration scrollToChapterDelay = Duration(milliseconds: 200);
  static const Duration debounceDelay = Duration(seconds: 5);
  static const double defaultFontSize = 18.0;
  static const double defaultLineHeight = 1.8;
  static const double minFontSize = 12.0;
  static const double maxFontSize = 32.0;
  static const double minLineHeight = 1.2;
  static const double maxLineHeight = 2.4;
  static const double chapterSliderWidth = 160.0;
  static const double listTileHeight = 48.0;

  static const Color menuBackgroundColor = Color(0xFF333333);
  static const Color menuTextColor = Color(0xFFCCCCCC);
  static const Color menuIconColor = Color(0xFFC9C9C9);
  static const Color menuDividerColor = Color(0xFFFFFFFF);
  static const Color menuHighlightColor = Color(0xFFFF7135);
  static const Color buttonHighlightColor = Color(0xFFFF7135);
  static const Color buttonBackgroundColor = Color(0xFFFBEAD8);
  static const Color buttonTextColor = Color(0xFF474747);
  static const Color menuSliderThumbColor = Color(0xFF4E4E4E);
  static const Color menuSliderActiveColor = Color(0xFFFF7532);
  static const Color menuSliderInactiveColor = Color(0xFF4c4c4c);

  static const List<String> fontFamilies = [
    'system',
    'MiSans',
    'SourceHanSerif',
    '江西拙楷',
    'Alibaba',
  ];

  // 字体名称映射
  static const Map<String, String> fontFamilyNames = {
    'system': '系统默认',
    'MiSans': 'Xiaomi Sans',
    'SourceHanSerif': '思源宋体',
    '江西拙楷': '楷书',
    'Alibaba': 'Alibaba普惠体',
  };

  static const List<Map<String, String>> themes = [
    {'name': '护眼', 'bg': '#F5F5DC', 'text': '#333333'},
    {'name': '羊皮纸', 'bg': '#F5F0E6', 'text': '#4A4A4A'},
    {'name': '夜间', 'bg': '#1A1A1A', 'text': '#E0E0E0'},
    {'name': '深蓝', 'bg': '#E3F2FD', 'text': '#1976D2'},
    {'name': '复古', 'bg': '#FFF8E1', 'text': '#D84315'},
    {'name': '浅灰', 'bg': '#F5F5F5', 'text': '#424242'},
    {'name': '薄荷', 'bg': '#E0F2F1', 'text': '#00796B'},
    {'name': '薰衣草', 'bg': '#F3E5F5', 'text': '#7B1FA2'},
    {'name': '日出', 'bg': '#FFF3E0', 'text': '#E65100'},
  ];
}
