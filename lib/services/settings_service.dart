import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../constants/app_constants.dart';

class ReadingSettings {
  final double fontSize;
  final double lineHeight;
  final String fontFamily;
  final String backgroundColor;
  final String textColor;
  final int themeIndex;

  ReadingSettings({
    this.fontSize = AppConstants.defaultFontSize,
    this.lineHeight = AppConstants.defaultLineHeight,
    this.fontFamily = 'system',
    this.backgroundColor = '#F5F5DC',
    this.textColor = '#333333',
    this.themeIndex = 0,
  });

  ReadingSettings copyWith({
    double? fontSize,
    double? lineHeight,
    String? fontFamily,
    String? backgroundColor,
    String? textColor,
    int? themeIndex,
  }) {
    return ReadingSettings(
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      fontFamily: fontFamily ?? this.fontFamily,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      themeIndex: themeIndex ?? this.themeIndex,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fontSize': fontSize,
      'lineHeight': lineHeight,
      'fontFamily': fontFamily,
      'backgroundColor': backgroundColor,
      'textColor': textColor,
      'themeIndex': themeIndex,
    };
  }

  factory ReadingSettings.fromMap(Map<String, dynamic> map) {
    return ReadingSettings(
      fontSize: map['fontSize'] as double? ?? AppConstants.defaultFontSize,
      lineHeight:
          map['lineHeight'] as double? ?? AppConstants.defaultLineHeight,
      fontFamily: map['fontFamily'] as String? ?? 'system',
      backgroundColor: map['backgroundColor'] as String? ?? '#F5F5DC',
      textColor: map['textColor'] as String? ?? '#333333',
      themeIndex: map['themeIndex'] as int? ?? 0,
    );
  }
}

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  ReadingSettings _settings = ReadingSettings();
  String? _dataPath;

  ReadingSettings get settings => _settings;

  // 支持的字体列表
  static const List<String> fontFamilies = [
    'system',
    'MiSans',
    'SourceHanSerif',
    'OPPOSans',
    '江西拙楷',
    'Alibaba',
  ];

  // 字体名称映射
  static const Map<String, String> fontFamilyNames = {
    'system': '系统默认',
    'MiSans': 'Xiaomi Sans',
    'SourceHanSerif': '思源宋体',
    'OPPOSans': 'OPPO Sans',
    '江西拙楷': '楷书',
    'Alibaba': 'Alibaba普惠体',
  };

  static const List<Map<String, String>> themes = [
    {'name': '护眼', 'bg': '#F5F5DC', 'text': '#333333'},
    {'name': '羊皮纸', 'bg': '#F5F0E6', 'text': '#4A4A4A'},
    {'name': '夜间', 'bg': '#1A1A1A', 'text': '#E0E0E0'},
    // {'name': '白色', 'bg': '#FFFFFF', 'text': '#333333'},
    {'name': '深蓝', 'bg': '#E3F2FD', 'text': '#1976D2'},
    {'name': '复古', 'bg': '#FFF8E1', 'text': '#D84315'},
    {'name': '浅灰', 'bg': '#F5F5F5', 'text': '#424242'},
    {'name': '薄荷', 'bg': '#E0F2F1', 'text': '#00796B'},
    {'name': '薰衣草', 'bg': '#F3E5F5', 'text': '#7B1FA2'},
    {'name': '日出', 'bg': '#FFF3E0', 'text': '#E65100'},
  ];

  // 菜单颜色 - 使用深色主题
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

  //默认字体颜色
  //static const Color defaultTextColor = Color(0xFFCCCCCC);

  Future<void> init() async {
    final directory = await getApplicationDocumentsDirectory();
    _dataPath = directory.path;
    await _loadSettings();
  }

  Future<void> _loadSettings() async {
    final file = File('$_dataPath/settings.json');
    if (await file.exists()) {
      final content = await file.readAsString();
      final Map<String, dynamic> jsonMap = json.decode(content);
      _settings = ReadingSettings.fromMap(jsonMap);
    }
  }

  Future<void> _saveSettings() async {
    final file = File('$_dataPath/settings.json');
    await file.writeAsString(json.encode(_settings.toMap()));
  }

  Future<void> updateSettings(ReadingSettings settings) async {
    _settings = settings;
    await _saveSettings();
  }

  Future<void> setTheme(int index) async {
    if (index >= 0 && index < themes.length) {
      _settings = _settings.copyWith(
        themeIndex: index,
        backgroundColor: themes[index]['bg']!,
        textColor: themes[index]['text']!,
      );
      await _saveSettings();
    }
  }

  Future<void> setFontSize(double size) async {
    _settings = _settings.copyWith(fontSize: size);
    await _saveSettings();
  }

  Future<void> setLineHeight(double height) async {
    _settings = _settings.copyWith(lineHeight: height);
    await _saveSettings();
  }

  Future<void> setFontFamily(String fontFamily) async {
    _settings = _settings.copyWith(fontFamily: fontFamily);
    await _saveSettings();
  }
}
