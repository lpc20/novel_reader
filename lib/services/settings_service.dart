import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../constants/global.dart';

class ReadingSettings {
  final double fontSize;
  final double lineHeight;
  final String fontFamily;
  final String backgroundColor;
  final String textColor;
  final int themeIndex;
  final bool usePageMode;
  ReadingSettings({
    this.fontSize = Global.defaultFontSize,
    this.lineHeight = Global.defaultLineHeight,
    this.fontFamily = 'system',
    this.backgroundColor = '#F5F5DC',
    this.textColor = '#333333',
    this.themeIndex = 0,
    this.usePageMode = false,
  });

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

  factory ReadingSettings.fromMap(Map<String, dynamic> map) {
    return ReadingSettings(
      fontSize: map['fontSize'] as double? ?? Global.defaultFontSize,
      lineHeight: map['lineHeight'] as double? ?? Global.defaultLineHeight,
      fontFamily: map['fontFamily'] as String? ?? 'system',
      backgroundColor: map['backgroundColor'] as String? ?? '#F5F5DC',
      textColor: map['textColor'] as String? ?? '#333333',
      themeIndex: map['themeIndex'] as int? ?? 0,
      usePageMode: map['usePageMode'] as bool? ?? false,
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

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  ReadingSettings _settings = ReadingSettings();
  String? _dataPath;

  ReadingSettings get settings => _settings;

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
    if (index >= 0 && index < Global.themes.length) {
      _settings = _settings.copyWith(
        themeIndex: index,
        backgroundColor: Global.themes[index]['bg']!,
        textColor: Global.themes[index]['text']!,
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

  Future<void> setUsePageMode(bool value) async {
    _settings = _settings.copyWith(usePageMode: value);
    await _saveSettings();
  }
}
