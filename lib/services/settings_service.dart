import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class ReadingSettings {
  final double fontSize;
  final double lineHeight;
  final String fontFamily;
  final String backgroundColor;
  final String textColor;
  final int themeIndex;

  ReadingSettings({
    this.fontSize = 18.0,
    this.lineHeight = 1.8,
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
      fontSize: map['fontSize'] as double? ?? 18.0,
      lineHeight: map['lineHeight'] as double? ?? 1.8,
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

  static const List<Map<String, String>> themes = [
    {'name': '护眼', 'bg': '#CCE8CF', 'text': '#2C4A2E'},
    {'name': '羊皮纸', 'bg': '#F5F5DC', 'text': '#333333'},
    {'name': '夜间', 'bg': '#1A1A1A', 'text': '#AAAAAA'},
    {'name': '白色', 'bg': '#FFFFFF', 'text': '#333333'},
  ];

  // 护眼的AppBar颜色
  static const Color appBarColor = Color(0xFF2C3E50);
  static const Color appBarTextColor = Color(0xFFE8E8E8);

  // 护眼的菜单颜色
  static const Color menuBackgroundColor = Color(0xFF34495E);
  static const Color menuTextColor = Color(0xFFECF0F1);
  static const Color menuIconColor = Color(0xFFBDC3C7);

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
}
