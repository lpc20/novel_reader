import 'package:flutter/material.dart';
import 'package:novel_reader/constants/global.dart';
import 'package:provider/provider.dart';
import 'menu/menu_top_bar.dart';
import 'menu/chapter_navigation_panel.dart';
import 'menu/settings_panel.dart';
import 'menu/search_panel.dart';
import 'menu/bookmark_panel.dart';
import '../models/menu_data.dart';
import '../providers/reader_view_model.dart';

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
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Selector<ReaderViewModel, MenuData>(
      selector: (context, provider) => provider.menuData,
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
    final usePageMode = context.read<ReaderViewModel>().settings.usePageMode;

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
                        context.read<ReaderViewModel>().goToChapter(
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
                          context.read<ReaderViewModel>().setFontSize(size),
                      onLineHeightChange: (height) =>
                          context.read<ReaderViewModel>().setLineHeight(height),
                      onFontFamilyChange: (font) =>
                          context.read<ReaderViewModel>().setFontFamily(font),
                      onThemeChange: (index) =>
                          context.read<ReaderViewModel>().setTheme(index),
                      usePageMode: usePageMode,
                      onUsePageModeChange: (value) =>
                          context.read<ReaderViewModel>().setUsePageMode(value),
                    ),
                  )
                else if (_currentTabIndex == 2)
                  RepaintBoundary(
                    child: usePageMode
                        ? Container(
                            padding: const EdgeInsets.all(20),
                            child: Center(
                              child: Text(
                                '分页模式下搜索功能不可用',
                                style: TextStyle(
                                  color: Global.menuTextColor,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : _buildSearchPanel(),
                  )
                else if (_currentTabIndex == 3)
                  RepaintBoundary(
                    child: _buildBookmarkPanel(),
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

  Widget _buildSearchPanel() {
    return Selector<ReaderViewModel, _SearchViewData>(
      selector: (context, vm) => _SearchViewData(
        hasResults: vm.hasSearchResults,
        currentIndex: vm.currentSearchIndex,
        resultsLength: vm.searchResults.length,
      ),
      builder: (context, data, child) {
        return SearchPanel(
          searchController: widget.searchController,
          onSearch: widget.onSearch,
          hasSearchResults: data.hasResults,
          currentSearchIndex: data.currentIndex,
          searchResultsLength: data.resultsLength,
          onPreviousResult: () =>
              context.read<ReaderViewModel>().previousSearchResult(),
          onNextResult: () =>
              context.read<ReaderViewModel>().nextSearchResult(),
        );
      },
    );
  }

  Widget _buildBookmarkPanel() {
    return Consumer<ReaderViewModel>(
      builder: (context, vm, child) {
        return BookmarkPanel(
          bookmarks: vm.getBookmarks(),
          onAddBookmark: () => vm.addBookmark(),
          onRemoveBookmark: (id) => vm.removeBookmark(id),
          onGoToBookmark: (index) => vm.goToChapter(index),
          onCloseMenu: widget.onClose,
        );
      },
    );
  }
}

class _SearchViewData {
  final bool hasResults;
  final int currentIndex;
  final int resultsLength;

  const _SearchViewData({
    required this.hasResults,
    required this.currentIndex,
    required this.resultsLength,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _SearchViewData &&
        other.hasResults == hasResults &&
        other.currentIndex == currentIndex &&
        other.resultsLength == resultsLength;
  }

  @override
  int get hashCode => Object.hash(hasResults, currentIndex, resultsLength);
}