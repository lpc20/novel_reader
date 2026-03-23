import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:novel_reader/utils/debouncer.dart';
import 'package:path_provider/path_provider.dart';
import '../constants/global.dart';

/// 阅读设置类
class ReadingSettings {
  /// 字体大小
  final double fontSize;

  /// 行高
  final double lineHeight;

  /// 字体
  final String fontFamily;

  /// 背景颜色
  final String backgroundColor;

  /// 文本颜色
  final String textColor;

  /// 主题索引
  final int themeIndex;

  /// 是否使用页面模式
  final bool usePageMode;

  /// 构造函数
  ReadingSettings({
    this.fontSize = Global.defaultFontSize,
    this.lineHeight = Global.defaultLineHeight,
    this.fontFamily = 'OPPOSans',
    this.backgroundColor = '#F5F5DC',
    this.textColor = '#333333',
    this.themeIndex = 0,
    this.usePageMode = true,
  });

  /// 复制方法
  ReadingSettings copyWith({
    double? fontSize,
    double? lineHeight,
    String? fontFamily,
    String? backgroundColor,
    String? textColor,
    int? themeIndex,
    bool? usePageMode,
  }) {
    return ReadingSettings(
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      fontFamily: fontFamily ?? this.fontFamily,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      themeIndex: themeIndex ?? this.themeIndex,
      usePageMode: usePageMode ?? this.usePageMode,
    );
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'fontSize': fontSize,
      'lineHeight': lineHeight,
      'fontFamily': fontFamily,
      'backgroundColor': backgroundColor,
      'textColor': textColor,
      'themeIndex': themeIndex,
      'usePageMode': usePageMode,
    };
  }

  /// 从Map创建实例
  factory ReadingSettings.fromMap(Map<String, dynamic> map) {
    return ReadingSettings(
      fontSize: map['fontSize'] as double? ?? Global.defaultFontSize,
      lineHeight: map['lineHeight'] as double? ?? Global.defaultLineHeight,
      fontFamily: map['fontFamily'] as String? ?? 'OPPOSans',
      backgroundColor: map['backgroundColor'] as String? ?? '#F5F5DC',
      textColor: map['textColor'] as String? ?? '#333333',
      themeIndex: map['themeIndex'] as int? ?? 0,
      usePageMode: map['usePageMode'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReadingSettings &&
        other.fontSize == fontSize &&
        other.lineHeight == lineHeight &&
        other.fontFamily == fontFamily &&
        other.backgroundColor == backgroundColor &&
        other.textColor == textColor &&
        other.themeIndex == themeIndex &&
        other.usePageMode == usePageMode;
  }

  @override
  int get hashCode => Object.hash(
    fontSize,
    lineHeight,
    fontFamily,
    backgroundColor,
    textColor,
    themeIndex,
    usePageMode,
  );
}

/// 设置服务类，管理应用设置的保存和加载
class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  final Debouncer _settingsDebouncer = Debouncer(delay: Global.debounceDelay);

  /// 当前设置
  ReadingSettings _settings = ReadingSettings();

  /// 数据路径
  String? _dataPath;

  /// 获取当前设置
  ReadingSettings get settings => _settings;
  bool get usePageMode => _settings.usePageMode;

  /// 初始化设置
  Future<void> init() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      _dataPath = directory.path;
      await _loadSettings();
    } catch (e) {
      debugPrint('SettingsService init error: $e');
    }
  }

  /// 加载设置
  Future<void> _loadSettings() async {
    try {
      if (_dataPath == null) return;

      final file = File('$_dataPath/settings.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          final Map<String, dynamic> jsonMap = json.decode(content);
          _settings = ReadingSettings.fromMap(jsonMap);
        }
      }
    } catch (e) {
      debugPrint('SettingsService _loadSettings error: $e');
    }
  }

  /// 保存设置
  Future<void> _saveSettings() async {
    try {
      if (_dataPath == null) return;

      final file = File('$_dataPath/settings.json');
      await file.writeAsString(json.encode(_settings.toMap()));
    } catch (e) {
      debugPrint('SettingsService _saveSettings error: $e');
    }
  }

  /// 更新设置
  Future<void> updateSettings(ReadingSettings settings) async {
    try {
      _settings = settings;
      _settingsDebouncer.run(() {
        _saveSettings();
      });
    } catch (e) {
      debugPrint('SettingsService updateSettings error: $e');
    }
  }

  /// 设置主题
  Future<void> setTheme(int index) async {
    try {
      if (index >= 0 && index < Global.themes.length) {
        _settings = _settings.copyWith(
          themeIndex: index,
          backgroundColor: Global.themes[index]['bg']!,
          textColor: Global.themes[index]['text']!,
        );
        _settingsDebouncer.run(() {
          _saveSettings();
        });
      }
    } catch (e) {
      debugPrint('SettingsService setTheme error: $e');
    }
  }

  /// 设置字体大小
  Future<void> setFontSize(double size) async {
    try {
      _settings = _settings.copyWith(fontSize: size);
      _settingsDebouncer.run(() {
        _saveSettings();
      });
    } catch (e) {
      debugPrint('SettingsService setFontSize error: $e');
    }
  }

  /// 设置行高
  Future<void> setLineHeight(double height) async {
    try {
      _settings = _settings.copyWith(lineHeight: height);
      _settingsDebouncer.run(() {
        _saveSettings();
      });
    } catch (e) {
      debugPrint('SettingsService setLineHeight error: $e');
    }
  }

  /// 设置字体
  Future<void> setFontFamily(String fontFamily) async {
    try {
      _settings = _settings.copyWith(fontFamily: fontFamily);
      _settingsDebouncer.run(() {
        _saveSettings();
      });
    } catch (e) {
      debugPrint('SettingsService setFontFamily error: $e');
    }
  }

  /// 设置页面模式
  Future<void> setUsePageMode(bool value) async {
    try {
      _settings = _settings.copyWith(usePageMode: value);
      _settingsDebouncer.run(() {
        _saveSettings();
      });
    } catch (e) {
      debugPrint('SettingsService setUsePageMode error: $e');
    }
  }
}
