import 'package:flutter/material.dart';
import '../../services/settings_service.dart';
import '../../utils/color_utils.dart';

class SettingsPanel extends StatelessWidget {
  final double fontSize;
  final double lineHeight;
  final String fontFamily;
  final int themeIndex;
  final Function(double) onFontSizeChange;
  final Function(double) onLineHeightChange;
  final Function(String) onFontFamilyChange;
  final Function(int) onThemeChange;

  const SettingsPanel({
    super.key,
    required this.fontSize,
    required this.lineHeight,
    required this.fontFamily,
    required this.themeIndex,
    required this.onFontSizeChange,
    required this.onLineHeightChange,
    required this.onFontFamilyChange,
    required this.onThemeChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.35,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFontSizeControl(),
            const SizedBox(height: 12),
            _buildFontAndTheme(),
          ],
        ),
      ),
    );
  }

  Widget _buildFontAndTheme() {
    return Row(
      children: [
        Expanded(child: _buildFontSelector()),
        const SizedBox(width: 12),
        Expanded(child: _buildThemeSelector()),
      ],
    );
  }

  Widget _buildFontSelector() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          '字体',
          style: TextStyle(fontSize: 12, color: SettingsService.menuTextColor),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: SettingsService.buttonTextColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: fontFamily,
              isExpanded: true,
              dropdownColor: SettingsService.buttonTextColor,
              underline: const SizedBox(),
              style: const TextStyle(
                fontSize: 12,
                color: SettingsService.menuTextColor,
              ),
              items: SettingsService.fontFamilies.map((font) {
                return DropdownMenuItem(
                  value: font,
                  child: Text(
                    SettingsService.fontFamilyNames[font]!,
                    style: TextStyle(fontSize: 12, fontFamily: font),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  onFontFamilyChange(value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThemeSelector() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          '主题',
          style: TextStyle(fontSize: 12, color: SettingsService.menuTextColor),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: SettingsService.buttonTextColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<int>(
              value: themeIndex,
              isExpanded: true,
              dropdownColor: SettingsService.buttonTextColor,
              underline: const SizedBox(),
              style: const TextStyle(
                fontSize: 12,
                color: SettingsService.menuTextColor,
              ),
              items: SettingsService.themes.asMap().entries.map((entry) {
                final index = entry.key;
                final theme = entry.value;
                return DropdownMenuItem(
                  value: index,
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: ColorUtils.parseColor(theme['bg']!),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          theme['name']!,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  onThemeChange(value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFontSizeControl() {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              const Text(
                '字号',
                style: TextStyle(
                  fontSize: 12,
                  color: SettingsService.menuTextColor,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.remove, size: 16),
                onPressed: fontSize > 12
                    ? () => onFontSizeChange(fontSize - 2)
                    : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                color: SettingsService.menuTextColor,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: SettingsService.buttonTextColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${fontSize.toInt()}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: SettingsService.menuTextColor,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 16),
                onPressed: fontSize < 30
                    ? () => onFontSizeChange(fontSize + 2)
                    : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                color: SettingsService.menuTextColor,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Row(
            children: [
              const Text(
                '行距',
                style: TextStyle(
                  fontSize: 12,
                  color: SettingsService.menuTextColor,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.remove, size: 16),
                onPressed: lineHeight > 1.0
                    ? () => onLineHeightChange(lineHeight - 0.2)
                    : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                color: SettingsService.menuTextColor,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: SettingsService.buttonTextColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  lineHeight.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 12,
                    color: SettingsService.menuTextColor,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 16),
                onPressed: lineHeight < 2.0
                    ? () => onLineHeightChange(lineHeight + 0.2)
                    : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                color: SettingsService.menuTextColor,
              ),
            ],
          ),
        ),
      ],
    );
  }
}