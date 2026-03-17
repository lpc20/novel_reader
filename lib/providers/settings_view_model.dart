
import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class SettingsViewModel extends ChangeNotifier {
  final SettingsService _settingsService = SettingsService();

  ReadingSettings get settings => _settingsService.settings;

  Future<void> init() async {
    await _settingsService.init();
    notifyListeners();
  }

  Future<void> setTheme(int index) async {
    await _settingsService.setTheme(index);
    notifyListeners();
  }

  Future<void> setFontSize(double size) async {
    await _settingsService.setFontSize(size);
    notifyListeners();
  }

  Future<void> setLineHeight(double height) async {
    await _settingsService.setLineHeight(height);
    notifyListeners();
  }

  Future<void> setFontFamily(String fontFamily) async {
    await _settingsService.setFontFamily(fontFamily);
    notifyListeners();
  }

  Future<void> setUsePageMode(bool value) async {
    await _settingsService.setUsePageMode(value);
    notifyListeners();
  }

  Future<void> updateSettings(ReadingSettings settings) async {
    await _settingsService.updateSettings(settings);
    notifyListeners();
  }
}