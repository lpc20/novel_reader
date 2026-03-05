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
          // 底部分割线
          Container(
            height: 1,
            color: SettingsService.menuDividerColor,
            margin: const EdgeInsets.symmetric(vertical: 12),
          ),
          // TabBar 放在底部，使用图标+文字
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: SettingsService.menuHighlightColor,
                borderRadius: BorderRadius.circular(20),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelPadding: const EdgeInsets.symmetric(horizontal: 12),
              labelColor: SettingsService.menuHighlightTextColor,
              unselectedLabelColor: SettingsService.menuSecondaryTextColor,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(icon: Icon(Icons.menu_book, size: 16), text: '目录'),
                Tab(icon: Icon(Icons.settings, size: 16), text: '设置'),
                Tab(icon: Icon(Icons.search, size: 16), text: '查找'),
                Tab(icon: Icon(Icons.bookmark, size: 16), text: '书签'),
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
            Row(
              children: [
                Expanded(child: _buildFontSelector(context, data)),
                const SizedBox(width: 20),
                Expanded(child: _buildThemeSelector(context, data)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFontSelector(BuildContext context, _MenuData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '字体',
          style: TextStyle(fontSize: 12, color: SettingsService.menuTextColor),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: SettingsService.menuDividerColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: data.fontFamily,
            isExpanded: true,
            dropdownColor: SettingsService.menuDividerColor,
            underline: const SizedBox(),
            style: const TextStyle(
              fontSize: 12,
              color: SettingsService.menuTextColor,
            ),
            items: SettingsService.fontFamilies.map((font) {
              return DropdownMenuItem(
                value: font,
                child: Text(SettingsService.fontFamilyNames[font]!),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                context.read<ReaderProvider>().setFontFamily(value);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildThemeSelector(BuildContext context, _MenuData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '主题',
          style: TextStyle(fontSize: 12, color: SettingsService.menuTextColor),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: SettingsService.menuDividerColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<int>(
            value: data.themeIndex,
            isExpanded: true,
            dropdownColor: SettingsService.menuDividerColor,
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
                        border: Border.all(
                          color: SettingsService.menuSecondaryTextColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(theme['name']!),
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
              hintText: '输入搜索内容',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              suffixIcon: Container(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: widget.onSearch,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: SettingsService.menuHighlightColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.search,
                      color: SettingsService.menuHighlightTextColor,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            onSubmitted: (_) => widget.onSearch(),
          ),
        ),
        const SizedBox(height: 16),
        Consumer<ReaderProvider>(
          builder: (context, provider, child) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.chevron_left, size: 16),
                  label: const Text('上一个', style: TextStyle(fontSize: 12)),
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
                      horizontal: 20,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
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
                ElevatedButton.icon(
                  icon: const Icon(Icons.chevron_right, size: 16),
                  iconAlignment: IconAlignment.end,
                  label: const Text('下一个', style: TextStyle(fontSize: 12)),
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
                      horizontal: 20,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
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
          child: ElevatedButton.icon(
            icon: const Icon(Icons.chevron_left, size: 16),
            label: const Text('上一章'),
            onPressed: data.currentChapterIndex > 0
                ? () => context.read<ReaderProvider>().previousChapter()
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: SettingsService.menuTextColor,
              side: BorderSide(
                color: SettingsService.menuDividerColor,
                width: 1,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: SettingsService.menuDividerColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${data.currentChapterIndex + 1}/${data.chaptersLength}',
            style: const TextStyle(
              fontSize: 12,
              color: SettingsService.menuTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.chevron_right, size: 16),
            label: const Text('下一章'),
            onPressed: data.currentChapterIndex < data.chaptersLength - 1
                ? () => context.read<ReaderProvider>().nextChapter()
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: SettingsService.menuTextColor,
              side: BorderSide(
                color: SettingsService.menuDividerColor,
                width: 1,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
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
                  color: SettingsService.menuDividerColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${data.fontSize.toInt()}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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
                  color: SettingsService.menuDividerColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  data.lineHeight.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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
              const SizedBox(height: 20),
              Icon(
                Icons.bookmark_outline,
                size: 48,
                color: SettingsService.menuSecondaryTextColor,
              ),
              const SizedBox(height: 16),
              const Text(
                '暂无书签',
                style: TextStyle(
                  fontSize: 16,
                  color: SettingsService.menuTextColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '在阅读时添加书签',
                style: TextStyle(
                  fontSize: 14,
                  color: SettingsService.menuSecondaryTextColor,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => provider.addBookmark(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SettingsService.menuHighlightColor,
                  foregroundColor: SettingsService.menuHighlightTextColor,
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
            ],
          );
        }

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.4,
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
                        fontWeight: FontWeight.w600,
                        color: SettingsService.menuTextColor,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => provider.addBookmark(),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('添加'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SettingsService.menuHighlightColor,
                        foregroundColor: SettingsService.menuHighlightTextColor,
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
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: SettingsService.menuDividerColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bookmark.chapterTitle,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: SettingsService.menuTextColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          bookmark.contentPreview,
                          style: const TextStyle(
                            fontSize: 12,
                            color: SettingsService.menuSecondaryTextColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${bookmark.createdAt.month}月${bookmark.createdAt.day}日',
                              style: const TextStyle(
                                fontSize: 11,
                                color: SettingsService.menuSecondaryTextColor,
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
                                  ),
                                  child: const Text('前往'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      provider.removeBookmark(bookmark.id),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
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
