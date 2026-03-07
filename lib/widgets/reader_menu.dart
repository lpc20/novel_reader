import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'menu/menu_top_bar.dart';
import 'menu/chapter_navigation_panel.dart';
import 'menu/settings_panel.dart';
import 'menu/search_panel.dart';
import 'menu/bookmark_panel.dart';
import '../models/menu_data.dart';
import '../providers/reader_provider.dart';
import '../services/settings_service.dart';

class ReaderMenu extends StatefulWidget {
  final String title;
  final VoidCallback onClose;
  final VoidCallback onChapterList;
  final VoidCallback onSearch;
  final TextEditingController searchController;

  const ReaderMenu({
    super.key,
    required this.title,
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
    super.build(context);
    return Selector<ReaderProvider, MenuData>(
      selector: (context, provider) => MenuData.fromProvider(provider),
      builder: (context, data, child) {
        return Column(
          children: [
            RepaintBoundary(
              child: MenuTopBar(
                title: widget.title,
                onBack: _onBack,
                onOpenChapterList: widget.onChapterList,
              ),
            ),
            const Expanded(child: SizedBox()),
            RepaintBoundary(child: _buildBottomPanel(context, data)),
          ],
        );
      },
    );
  }

  void _onBack() {
    final readerProvider = context.read<ReaderProvider>();
    readerProvider.toggleMenu();
    Navigator.pop(context);
  }

  Widget _buildBottomPanel(BuildContext context, MenuData data) {
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
                  RepaintBoundary(
                    child: ChapterNavigationPanel(
                      currentChapterIndex: data.currentChapterIndex,
                      chaptersLength: data.chaptersLength,
                      onChapterChange: (index) =>
                          context.read<ReaderProvider>().goToChapter(index),
                      sliderValue: _sliderValue,
                      onSliderChange: (value) {
                        setState(() {
                          _sliderValue = value;
                        });
                      },
                      onSliderChangeEnd: (value) {
                        final targetChapter = (value * data.chaptersLength)
                            .floor();
                        context.read<ReaderProvider>().goToChapter(
                          targetChapter,
                        );
                        setState(() {
                          _sliderValue = null;
                        });
                      },
                    ),
                  )
                else if (_currentTabIndex == 1)
                  RepaintBoundary(
                    child: SettingsPanel(
                      fontSize: data.fontSize,
                      lineHeight: data.lineHeight,
                      fontFamily: data.fontFamily,
                      themeIndex: data.themeIndex,
                      onFontSizeChange: (size) =>
                          context.read<ReaderProvider>().setFontSize(size),
                      onLineHeightChange: (height) =>
                          context.read<ReaderProvider>().setLineHeight(height),
                      onFontFamilyChange: (font) =>
                          context.read<ReaderProvider>().setFontFamily(font),
                      onThemeChange: (index) =>
                          context.read<ReaderProvider>().setTheme(index),
                    ),
                  )
                else if (_currentTabIndex == 2)
                  RepaintBoundary(
                    child: SearchPanel(
                      searchController: widget.searchController,
                      onSearch: widget.onSearch,
                      hasSearchResults: context
                          .read<ReaderProvider>()
                          .hasSearchResults,
                      currentSearchIndex: context
                          .read<ReaderProvider>()
                          .currentSearchIndex,
                      searchResultsLength: context
                          .read<ReaderProvider>()
                          .searchResults
                          .length,
                      onPreviousResult: () =>
                          context.read<ReaderProvider>().previousSearchResult(),
                      onNextResult: () =>
                          context.read<ReaderProvider>().nextSearchResult(),
                    ),
                  )
                else if (_currentTabIndex == 3)
                  RepaintBoundary(
                    child: BookmarkPanel(
                      bookmarks: context.read<ReaderProvider>().getBookmarks(),
                      onAddBookmark: () =>
                          context.read<ReaderProvider>().addBookmark(),
                      onRemoveBookmark: (id) =>
                          context.read<ReaderProvider>().removeBookmark(id),
                      onGoToBookmark: (index) =>
                          context.read<ReaderProvider>().goToChapter(index),
                      onCloseMenu: widget.onClose,
                    ),
                  ),
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
}
