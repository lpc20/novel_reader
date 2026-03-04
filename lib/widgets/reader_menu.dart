import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/novel.dart';
import '../providers/reader_provider.dart';
import '../services/settings_service.dart';
import '../utils/color_utils.dart';

class _MenuData {
  final int currentChapterIndex;
  final int chaptersLength;
  final double fontSize;
  final double lineHeight;
  final int themeIndex;

  const _MenuData({
    required this.currentChapterIndex,
    required this.chaptersLength,
    required this.fontSize,
    required this.lineHeight,
    required this.themeIndex,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _MenuData &&
        other.currentChapterIndex == currentChapterIndex &&
        other.chaptersLength == chaptersLength &&
        other.fontSize == fontSize &&
        other.lineHeight == lineHeight &&
        other.themeIndex == themeIndex;
  }

  @override
  int get hashCode => Object.hash(
    currentChapterIndex,
    chaptersLength,
    fontSize,
    lineHeight,
    themeIndex,
  );
}

class ReaderMenu extends StatefulWidget {
  final Novel novel;
  final VoidCallback onClose;
  final VoidCallback onChapterList;

  const ReaderMenu({
    super.key,
    required this.novel,
    required this.onClose,
    required this.onChapterList,
  });

  @override
  State<ReaderMenu> createState() => _ReaderMenuState();
}

class _ReaderMenuState extends State<ReaderMenu>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    debugPrint('ReaderMenu initState');
    super.initState();
  }

  @override
  void dispose() {
    debugPrint('ReaderMenu dispose');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Selector<ReaderProvider, _MenuData>(
      selector: (context, provider) => _MenuData(
        currentChapterIndex: provider.currentChapterIndex,
        chaptersLength: provider.chapters.length,
        fontSize: provider.settings.fontSize,
        lineHeight: provider.settings.lineHeight,
        themeIndex: provider.settings.themeIndex,
      ),
      builder: (context, data, child) {
        return Column(
          children: [
            RepaintBoundary(child: _buildTopBar(context)),
            const Expanded(child: SizedBox()),
            RepaintBoundary(child: _buildBottomPanel(context, data)),
          ],
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      color: SettingsService.menuBackgroundColor,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 8,
        right: 8,
        bottom: 8,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: SettingsService.menuTextColor,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          Expanded(
            child: Text(
              widget.novel.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: SettingsService.menuTextColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.menu, color: SettingsService.menuTextColor),
            onPressed: widget.onChapterList,
            tooltip: '目录',
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel(BuildContext context, _MenuData data) {
    return Container(
      color: SettingsService.menuBackgroundColor,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RepaintBoundary(child: _buildChapterNavigation(context, data)),
          const SizedBox(height: 16),
          RepaintBoundary(child: _buildFontSizeControl(context, data)),
          const SizedBox(height: 16),
          RepaintBoundary(child: _buildThemeSelector(context, data)),
        ],
      ),
    );
  }

  Widget _buildChapterNavigation(BuildContext context, _MenuData data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        TextButton.icon(
          onPressed: data.currentChapterIndex > 0
              ? () => context.read<ReaderProvider>().previousChapter()
              : null,
          icon: const Icon(
            Icons.chevron_left,
            color: SettingsService.menuTextColor,
          ),
          label: const Text(
            '上一章',
            style: TextStyle(color: SettingsService.menuTextColor),
          ),
        ),
        Text(
          '${data.currentChapterIndex + 1}/${data.chaptersLength}',
          style: const TextStyle(
            fontSize: 14,
            color: SettingsService.menuTextColor,
          ),
        ),
        TextButton.icon(
          onPressed: data.currentChapterIndex < data.chaptersLength - 1
              ? () => context.read<ReaderProvider>().nextChapter()
              : null,
          icon: const Icon(
            Icons.chevron_right,
            color: SettingsService.menuTextColor,
          ),
          label: const Text(
            '下一章',
            style: TextStyle(color: SettingsService.menuTextColor),
          ),
          iconAlignment: IconAlignment.end,
        ),
      ],
    );
  }

  Widget _buildFontSizeControl(BuildContext context, _MenuData data) {
    return Row(
      children: [
        const Text(
          '字号',
          style: TextStyle(fontSize: 14, color: SettingsService.menuTextColor),
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: const Icon(Icons.remove, color: SettingsService.menuIconColor),
          onPressed: data.fontSize > 12
              ? () => context.read<ReaderProvider>().setFontSize(
                  data.fontSize - 2,
                )
              : null,
        ),
        Text(
          '${data.fontSize.toInt()}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: SettingsService.menuTextColor,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add, color: SettingsService.menuIconColor),
          onPressed: data.fontSize < 32
              ? () => context.read<ReaderProvider>().setFontSize(
                  data.fontSize + 2,
                )
              : null,
        ),
        const Spacer(),
        const Text(
          '行距',
          style: TextStyle(fontSize: 14, color: SettingsService.menuTextColor),
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: const Icon(Icons.remove, color: SettingsService.menuIconColor),
          onPressed: data.lineHeight > 1.2
              ? () => context.read<ReaderProvider>().setLineHeight(
                  data.lineHeight - 0.2,
                )
              : null,
        ),
        Text(
          data.lineHeight.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: SettingsService.menuTextColor,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add, color: SettingsService.menuIconColor),
          onPressed: data.lineHeight < 3.0
              ? () => context.read<ReaderProvider>().setLineHeight(
                  data.lineHeight + 0.2,
                )
              : null,
        ),
      ],
    );
  }

  Widget _buildThemeSelector(BuildContext context, _MenuData data) {
    final themes = SettingsService.themes;

    return Row(
      children: [
        const Text(
          '主题',
          style: TextStyle(fontSize: 14, color: SettingsService.menuTextColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(themes.length, (index) {
                final theme = themes[index];
                final isSelected = data.themeIndex == index;

                return GestureDetector(
                  onTap: () => context.read<ReaderProvider>().setTheme(index),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: ColorUtils.parseColor(theme['bg']!),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.blue
                                  : Colors.grey[300]!,
                              width: isSelected ? 3 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'Aa',
                              style: TextStyle(
                                color: ColorUtils.parseColor(theme['text']!),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          theme['name']!,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? Colors.blue
                                : SettingsService.menuTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}
