import 'package:flutter/material.dart';
import 'package:novel_reader/constants/global.dart';
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
  final Function(int) onChapterChange;
  final TextEditingController searchController;

  const ReaderMenu({
    super.key,
    required this.title,
    required this.onClose,
    required this.onChapterList,
    required this.onSearch,
    required this.searchController,
    required this.onChapterChange,
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
                onBack: () {
                  widget.onClose();
                  Navigator.pop(context);
                },
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

  Widget _buildBottomPanel(BuildContext context, MenuData data) {
    return Container(
      color: Global.menuBackgroundColor,
      padding: EdgeInsets.only(
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
                      onChapterChange: widget.onChapterChange,
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
                      usePageMode: context
                          .read<ReaderProvider>()
                          .settings
                          .usePageMode,
                      onUsePageModeChange: (value) =>
                          context.read<ReaderProvider>().setUsePageMode(value),
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
          Container(
            height: 1,
            color: Global.menuIconColor,
            margin: const EdgeInsets.symmetric(vertical: 1),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.transparent,
              //indicatorSize: TabBarIndicatorSize.tab,
              //labelPadding: const EdgeInsets.symmetric(horizontal: 8),
              unselectedLabelColor: Global.menuIconColor,
              labelStyle: const TextStyle(
                fontSize: 14,
                color: Global.menuHighlightColor,
              ),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
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
}
