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
  final VoidCallback onSearch;
  final TextEditingController searchController;

  const ReaderMenu({
    super.key,
    required this.novel,
    required this.onClose,
    required this.onChapterList,
    required this.onSearch,
    required this.searchController,
  });

  @override
  State<ReaderMenu> createState() => _ReaderMenuState();
}

class _ReaderMenuState extends State<ReaderMenu>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  late TabController _tabController;

  int _currentTabIndex = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    debugPrint('ReaderMenu initState');
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    debugPrint('ReaderMenu dispose');
    _tabController.dispose();
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
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 使用 TabBarView 切换面板，自适应高度
          // SizedBox(
          //   height: 140,
          //   child: TabBarView(
          //     controller: _tabController,
          //     children: [
          //       _buildSettingsPanel(context, data),
          //       _buildSearchPanel(context, data),
          //     ],
          //   ),
          // ),
          if (_currentTabIndex == 0)
            RepaintBoundary(child: _buildChapterNavigation(context, data))
          else if (_currentTabIndex == 1)
            _buildSettingsPanel(context, data)
          else
            _buildSearchPanel(context, data),
          // TabBar 放在底部，使用图标+文字
          TabBar(
            controller: _tabController,
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorPadding: const EdgeInsets.symmetric(horizontal: 4),
            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
            labelColor: SettingsService.menuHighlightTextColor,
            unselectedLabelColor: SettingsService.menuSecondaryTextColor,
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            tabs: const [
              Tab(icon: Icon(Icons.menu, size: 16), text: '目录'),
              Tab(icon: Icon(Icons.settings, size: 16), text: '设置'),
              Tab(icon: Icon(Icons.search, size: 16), text: '查找'),
            ],
            onTap: (index) {
              setState(() {
                _currentTabIndex = index;
              });
              if (index == 0) widget.onChapterList();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsPanel(BuildContext context, _MenuData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          //RepaintBoundary(child: _buildChapterNavigation(context, data)),
          //const SizedBox(height: 8),
          RepaintBoundary(child: _buildFontSizeControl(context, data)),
          const SizedBox(height: 8),
          RepaintBoundary(child: _buildThemeSelector(context, data)),
        ],
      ),
    );
  }

  Widget _buildSearchPanel(BuildContext context, _MenuData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: widget.searchController,
              decoration: InputDecoration(
                hintText: '输入搜索内容',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                // suffixIcon: Container(
                //   padding: const EdgeInsets.only(right: 8),
                //   child: GestureDetector(
                //     onTap: widget.onSearch,
                //     child: Container(
                //       padding: const EdgeInsets.all(8),
                //       decoration: BoxDecoration(
                //         color: SettingsService.menuHighlightColor,
                //         borderRadius: BorderRadius.circular(8),
                //       ),
                //       child: const Icon(
                //         Icons.search,
                //         color: SettingsService.menuHighlightTextColor,
                //         size: 20,
                //       ),
                //     ),
                //   ),
                // ),
              ),
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              onSubmitted: (_) => widget.onSearch(),
            ),
          ),
          const SizedBox(height: 12),
          Consumer<ReaderProvider>(
            builder: (context, provider, child) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    // icon: const Icon(Icons.chevron_left, size: 12),
                    onPressed: provider.hasSearchResults
                        ? () {
                            provider.previousSearchResult();
                            widget.onSearch();
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SettingsService.menuHighlightColor,
                      foregroundColor: SettingsService.menuHighlightTextColor,
                      disabledBackgroundColor: SettingsService.menuDividerColor,
                      disabledForegroundColor:
                          SettingsService.menuSecondaryTextColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('上一个', style: TextStyle(fontSize: 12)),
                  ),
                  Text(
                    provider.hasSearchResults
                        ? '${provider.currentSearchIndex + 1}/${provider.searchResults.length}'
                        : '无结果',
                    style: const TextStyle(
                      fontSize: 12,
                      color: SettingsService.menuTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  ElevatedButton(
                    // icon: const Icon(Icons.chevron_right, size: 20),
                    onPressed: provider.hasSearchResults
                        ? () {
                            provider.nextSearchResult();
                            widget.onSearch();
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SettingsService.menuHighlightColor,
                      foregroundColor: SettingsService.menuHighlightTextColor,
                      disabledBackgroundColor: SettingsService.menuDividerColor,
                      disabledForegroundColor:
                          SettingsService.menuSecondaryTextColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    // icon: const Icon(Icons.chevron_right, size: 20),
                    child: const Text('下一个', style: TextStyle(fontSize: 12)),
                  ),
                ],
              );
            },
          ),
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
            fontSize: 12,
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
          style: TextStyle(fontSize: 12, color: SettingsService.menuTextColor),
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
            fontSize: 12,
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
          style: TextStyle(fontSize: 12, color: SettingsService.menuTextColor),
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
          style: TextStyle(fontSize: 12, color: SettingsService.menuTextColor),
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
