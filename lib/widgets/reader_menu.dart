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
  final String fontFamily;
  final int themeIndex;

  const _MenuData({
    required this.currentChapterIndex,
    required this.chaptersLength,
    required this.fontSize,
    required this.lineHeight,
    required this.fontFamily,
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
        other.fontFamily == fontFamily &&
        other.themeIndex == themeIndex;
  }

  @override
  int get hashCode => Object.hash(
    currentChapterIndex,
    chaptersLength,
    fontSize,
    lineHeight,
    fontFamily,
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
  double? _sliderValue;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    debugPrint('ReaderMenu initState');
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
    //_currentTabIndex = 0;
    super.build(context);
    return Selector<ReaderProvider, _MenuData>(
      selector: (context, provider) => _MenuData(
        currentChapterIndex: provider.currentChapterIndex,
        chaptersLength: provider.chapters.length,
        fontSize: provider.settings.fontSize,
        lineHeight: provider.settings.lineHeight,
        fontFamily: provider.settings.fontFamily,
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
              color: SettingsService.menuIconColor,
            ),
            onPressed: () {
              final readerProvider = Provider.of<ReaderProvider>(
                context,
                listen: false,
              );
              readerProvider.toggleMenu();
              Navigator.pop(context);
            },
          ),
          Expanded(
            child: Text(
              widget.novel.title,
              style: const TextStyle(
                fontSize: 16,
                //fontWeight: FontWeight.bold,
                color: SettingsService.menuTextColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.menu, color: SettingsService.menuIconColor),
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
          // 内容面板
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_currentTabIndex == 0)
                  RepaintBoundary(child: _buildChapterNavigation(context, data))
                else if (_currentTabIndex == 1)
                  RepaintBoundary(child: _buildSettingsPanel(context, data))
                else if (_currentTabIndex == 2)
                  RepaintBoundary(child: _buildSearchPanel(context, data))
                else if (_currentTabIndex == 3)
                  RepaintBoundary(child: _buildBookmarksPanel(context, data)),
              ],
            ),
          ),
          //底部分割线
          Container(
            height: 1,
            color: SettingsService.menuIconColor,
            margin: const EdgeInsets.symmetric(vertical: 2),
          ),
          // TabBar 放在底部，使用图标+文字
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TabBar(
              controller: _tabController,
              indicatorColor: SettingsService.menuHighlightColor,
              indicatorSize: TabBarIndicatorSize.tab,
              labelPadding: const EdgeInsets.symmetric(horizontal: 8),
              // labelColor: SettingsService.menuTextColor,
              unselectedLabelColor: SettingsService.menuIconColor,
              labelStyle: const TextStyle(
                fontSize: 14,
                color: SettingsService.menuTextColor,
              ),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              tabs: const [
                Tab(icon: Icon(Icons.menu_book_outlined, size: 16), text: '目录'),
                Tab(icon: Icon(Icons.settings_outlined, size: 16), text: '设置'),
                Tab(icon: Icon(Icons.search_outlined, size: 16), text: '查找'),
                Tab(icon: Icon(Icons.bookmark_outlined, size: 16), text: '书签'),
              ],
              onTap: (index) {
                setState(() {
                  _currentTabIndex = index;
                });
                if (index == 0) widget.onChapterList();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsPanel(BuildContext context, _MenuData data) {
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
            RepaintBoundary(child: _buildFontSizeControl(context, data)),
            const SizedBox(height: 12),
            RepaintBoundary(child: _buildFontAndTheme(context, data)),
          ],
        ),
      ),
    );
  }

  Widget _buildFontAndTheme(BuildContext context, _MenuData data) {
    return Row(
      children: [
        Expanded(child: _buildFontSelector(context, data)),
        const SizedBox(width: 12),
        Expanded(child: _buildThemeSelector(context, data)),
      ],
    );
  }

  Widget _buildFontSelector(BuildContext context, _MenuData data) {
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
              value: data.fontFamily,
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
                  context.read<ReaderProvider>().setFontFamily(value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThemeSelector(BuildContext context, _MenuData data) {
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
              value: data.themeIndex,
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
                  context.read<ReaderProvider>().setTheme(value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchPanel(BuildContext context, _MenuData data) {
    return Column(
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
              hintText: '搜索',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              border: InputBorder.none,
              // enabledBorder: InputBorder.none,
              // focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              prefixIcon: const Icon(Icons.search, size: 16),
            ),
            // style: const TextStyle(fontSize: 14, color: Colors.black87),
            onSubmitted: (_) => widget.onSearch(),
          ),
        ),
        // const SizedBox(height: 16),
        Consumer<ReaderProvider>(
          builder: (context, provider, child) {
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Visibility(
                    visible: provider.hasSearchResults,
                    child: TextButton.icon(
                      icon: const Icon(Icons.chevron_left, size: 16),
                      label: const Text('上一个'),
                      style: TextButton.styleFrom(
                        foregroundColor: SettingsService.menuTextColor,
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: provider.hasSearchResults
                          ? () {
                              provider.previousSearchResult();
                              widget.onSearch();
                            }
                          : null,
                    ),
                  ),
                  Visibility(
                    visible: provider.hasSearchResults,
                    child: Text(
                      provider.hasSearchResults
                          ? '${provider.currentSearchIndex + 1}/${provider.searchResults.length}'
                          : '无结果',
                      style: const TextStyle(
                        fontSize: 12,
                        color: SettingsService.menuTextColor,
                      ),
                    ),
                  ),
                  Visibility(
                    visible: provider.hasSearchResults,
                    child: TextButton.icon(
                      icon: const Icon(Icons.chevron_right, size: 16),
                      iconAlignment: IconAlignment.end,
                      label: const Text('下一个'),
                      style: TextButton.styleFrom(
                        foregroundColor: SettingsService.menuTextColor,
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: provider.hasSearchResults
                          ? () {
                              provider.nextSearchResult();
                              widget.onSearch();
                            }
                          : null,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildChapterNavigation(BuildContext context, _MenuData data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: TextButton.icon(
            icon: const Icon(Icons.chevron_left, size: 12),
            label: const Text('上一章'),
            style: TextButton.styleFrom(
              foregroundColor: SettingsService.menuTextColor,
              padding: EdgeInsets.zero,
            ),
            onPressed: data.currentChapterIndex > 0
                ? () => context.read<ReaderProvider>().previousChapter()
                : null,
          ),
        ),
        if (data.chaptersLength > 0)
          SizedBox(
            width: 160,
            child: Slider(
              value:
                  _sliderValue ??
                  (data.currentChapterIndex + 1) /
                      data.chaptersLength.toDouble(),
              min: 0.0,
              max: 1.0,
              activeColor: SettingsService.menuSliderActiveColor,
              inactiveColor: SettingsService.menuSliderInactiveColor,
              thumbColor: SettingsService.menuSliderThumbColor,
              onChanged: (value) {
                setState(() {
                  _sliderValue = value;
                });
              },
              onChangeEnd: (value) {
                final targetChapter = (value * data.chaptersLength).floor();
                debugPrint('跳转到第$targetChapter章');
                context.read<ReaderProvider>().goToChapter(targetChapter);
                setState(() {
                  _sliderValue = null;
                });
              },
            ),
          ),
        Expanded(
          child: TextButton.icon(
            icon: const Icon(Icons.chevron_right, size: 12),
            iconAlignment: IconAlignment.end,
            label: const Text('下一章'),
            style: TextButton.styleFrom(
              foregroundColor: SettingsService.menuTextColor,
              padding: EdgeInsets.zero,
            ),
            onPressed: data.currentChapterIndex < data.chaptersLength - 1
                ? () => context.read<ReaderProvider>().nextChapter()
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildFontSizeControl(BuildContext context, _MenuData data) {
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
                onPressed: data.fontSize > 12
                    ? () => context.read<ReaderProvider>().setFontSize(
                        data.fontSize - 2,
                      )
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
                  '${data.fontSize.toInt()}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: SettingsService.menuTextColor,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 16),
                onPressed: data.fontSize < 32
                    ? () => context.read<ReaderProvider>().setFontSize(
                        data.fontSize + 2,
                      )
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
                onPressed: data.lineHeight > 1.2
                    ? () => context.read<ReaderProvider>().setLineHeight(
                        data.lineHeight - 0.2,
                      )
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
                  data.lineHeight.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 12,
                    color: SettingsService.menuTextColor,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 16),
                onPressed: data.lineHeight < 3.0
                    ? () => context.read<ReaderProvider>().setLineHeight(
                        data.lineHeight + 0.2,
                      )
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

  Widget _buildBookmarksPanel(BuildContext context, _MenuData data) {
    return Consumer<ReaderProvider>(
      builder: (context, provider, child) {
        final bookmarks = provider.getBookmarks();
        if (bookmarks.isEmpty) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Icon(
                Icons.bookmark_outline,
                size: 24,
                color: SettingsService.menuTextColor,
              ),
              const SizedBox(height: 12),
              const Text(
                '暂无书签',
                style: TextStyle(
                  fontSize: 14,
                  color: SettingsService.menuTextColor,
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => provider.addBookmark(),
                style: TextButton.styleFrom(
                  backgroundColor: SettingsService.buttonBackgroundColor,
                  foregroundColor: SettingsService.buttonHighlightColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('添加当前位置为书签'),
              ),
              const SizedBox(height: 12),
            ],
          );
        }

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.3,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '书签',
                      style: TextStyle(
                        fontSize: 16,
                        color: SettingsService.menuTextColor,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => provider.addBookmark(),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('添加'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SettingsService.buttonBackgroundColor,
                        foregroundColor: SettingsService.buttonHighlightColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...bookmarks.map((bookmark) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: SettingsService.menuDividerColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bookmark.chapterTitle,
                          style: const TextStyle(fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          bookmark.contentPreview,
                          style: const TextStyle(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${bookmark.createdAt.month}月${bookmark.createdAt.day}日',
                              style: const TextStyle(
                                fontSize: 11,
                                color: SettingsService.buttonTextColor,
                              ),
                            ),
                            Row(
                              children: [
                                TextButton(
                                  onPressed: () {
                                    provider.goToChapter(bookmark.chapterIndex);
                                    widget.onClose();
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor:
                                        SettingsService.menuHighlightColor,
                                    backgroundColor:
                                        SettingsService.buttonBackgroundColor,
                                  ),
                                  child: const Text('前往'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      provider.removeBookmark(bookmark.id),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    //backgroundColor:SettingsService.buttonBackgroundColor,
                                  ),
                                  child: const Text('删除'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
