import 'package:flutter/material.dart';
import 'package:novel_reader/constants/app_constants.dart';
import 'package:provider/provider.dart';
import '../models/reader_data.dart';
import '../providers/reader_provider.dart';
import '../widgets/reader_menu.dart';
import '../widgets/chapter_list_drawer.dart';
import '../models/novel.dart';
import '../utils/color_utils.dart';
import '../widgets/reader/reader_content.dart';
import '../widgets/reader/chapter_navigation.dart';

class ReaderScreen extends StatefulWidget {
  final Novel novel;

  const ReaderScreen({super.key, required this.novel});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _menuAnimationController;
  int? _lastScrollTimestamp;
  static const progressIndicator = Center(
    child: SizedBox(
      height: 40,
      width: 40,
      child: CircularProgressIndicator(
        strokeWidth: 1,
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3498DB)),
      ),
    ),
  );

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    _menuAnimationController = AnimationController(
      vsync: this,
      duration: AppConstants.menuAnimationDuration,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNovel();
    });
  }

  int _lastChapterIndex = -1;

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _menuAnimationController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final provider = context.read<ReaderProvider>();
    provider.performSearch(_searchController.text);
  }

  Future<void> _loadNovel() async {
    final readerProvider = context.read<ReaderProvider>();
    await readerProvider.loadNovel(
      widget.novel.id,
      widget.novel.filePath,
      widget.novel.encoding,
    );
    // 延迟滚动到上次阅读位置，等待布局完成
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final scrollProgress = readerProvider.scrollProgress;
        if (scrollProgress > 0 && _scrollController.hasClients) {
          // 在下一帧中滚动，确保布局已完成
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _scrollController.hasClients) {
              final maxScrollExtent =
                  _scrollController.position.maxScrollExtent;
              if (maxScrollExtent > 0) {
                final targetPosition = maxScrollExtent * scrollProgress;
                _scrollController.jumpTo(targetPosition);
              }
            }
          });
        }
      }
    });
  }

  void _onScroll() {
    if (!mounted) return;
    //debugPrint('ScrollController绑定了${_scrollController.hasClients}个');
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_lastScrollTimestamp == null ||
        now - _lastScrollTimestamp! > AppConstants.scrollThrottleDelay) {
      _lastScrollTimestamp = now;
      // 计算滚动进度并更新
      if (_scrollController.hasClients) {
        final position = _scrollController.position;
        final maxScrollExtent = position.maxScrollExtent;
        if (maxScrollExtent > 0) {
          final scrollProgress = position.pixels / maxScrollExtent;
          context.read<ReaderProvider>().updateScrollProgress(scrollProgress);
        }
      }
    }
  }

  void _toggleMenu() {
    final readerProvider = context.read<ReaderProvider>();
    if (readerProvider.showMenu) {
      _menuAnimationController.reverse();
    } else {
      _menuAnimationController.forward(from: 0);
    }
    readerProvider.toggleMenu();
  }

  void _openChapterDrawer() {
    _toggleMenu();
    _scaffoldKey.currentState?.openDrawer();
  }

  void _onChapterSelected(int index) {
    final readerProvider = context.read<ReaderProvider>();
    debugPrint(
      '章节切换前ScrollController绑定了${_scrollController.positions.length}个',
    );
    readerProvider.goToChapter(index);
    _scaffoldKey.currentState?.closeDrawer();
  }

  Widget? _buildChapterDrawer(ReaderScreenData data) {
    if (data.chapters.isEmpty) return null;
    return ChapterListDrawer(
      chapters: data.chapters,
      currentIndex: data.currentChapterIndex,
      onChapterSelected: _onChapterSelected,
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('ReaderScreen build');
    return Selector<ReaderProvider, ReaderScreenData>(
      selector: (context, provider) => ReaderScreenData.fromProvider(provider),
      builder: (context, data, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && data.currentChapterIndex != _lastChapterIndex) {
            _lastChapterIndex = data.currentChapterIndex;
            if (_scrollController.hasClients) {
              _scrollController.jumpTo(0);
            }
          }
        });

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: ColorUtils.parseColor(data.settings.backgroundColor),
          drawer: SizedBox(
            width: MediaQuery.of(context).size.width * 0.7,
            child: _buildChapterDrawer(data),
          ),
          body: GestureDetector(
            onTap: () => _toggleMenu(),
            child: Stack(
              children: [
                if (data.isLoading)
                  progressIndicator
                else
                  AnimatedSwitcher(
                    duration: AppConstants.fadeAnimationDuration,
                    transitionBuilder: (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                    child: CustomScrollView(
                      controller: _scrollController,
                      slivers: [
                        ...ReaderContent(
                          paragraphs: data.paragraphs,
                          settings: data.settings,
                          searchResults: data.searchResults,
                          currentSearchIndex: data.currentSearchIndex,
                          chapterTitle: data.currentChapter?.title,
                        ).buildSlivers(),
                        ChapterNavigation(
                          currentChapterIndex: data.currentChapterIndex,
                          chaptersLength: data.chapters.length,
                          onChapterChange: (index) =>
                              context.read<ReaderProvider>().goToChapter(index),
                          settings: data.settings,
                        ).buildSliver(),
                      ],
                    ),
                  ),
                AnimatedOpacity(
                  opacity: context.watch<ReaderProvider>().showMenu ? 1.0 : 0.0,
                  duration: AppConstants.fadeAnimationDuration,
                  curve: Curves.easeInOut,
                  child: Visibility(
                    visible: context.watch<ReaderProvider>().showMenu,
                    maintainState: true,
                    maintainAnimation: true,
                    maintainSize: true,
                    child: SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(0, 0.05),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: _menuAnimationController,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                      child: ReaderMenu(
                        title: widget.novel.title,
                        onClose: _toggleMenu,
                        onChapterList: _openChapterDrawer,
                        onSearch: _onSearch,
                        searchController: _searchController,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onSearch() {
    final provider = context.read<ReaderProvider>();
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      provider.clearSearch();
      return;
    }

    // 如果搜索查询没有变化，只滚动到当前结果
    if (query == provider.searchQuery && provider.hasSearchResults) {
      _scrollToSearchResult();
    } else {
      // 执行新搜索
      provider.performSearch(query);
      // 延迟滚动，等待UI更新
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scrollToSearchResult();
        }
      });
    }
  }

  void _scrollToSearchResult() {
    if (!mounted) return;

    final provider = context.read<ReaderProvider>();
    if (provider.currentSearchIndex < 0 ||
        provider.currentSearchIndex >= provider.searchResults.length) {
      return;
    }

    final result = provider.searchResults[provider.currentSearchIndex];
    final paragraphs = provider.getCurrentChapterContent();
    final targetIndex = result.paragraphIndex;

    if (targetIndex >= paragraphs.length) {
      return;
    }

    double targetPosition = 0;
    final lineHeight =
        provider.settings.fontSize * provider.settings.lineHeight;
    final paragraphSpacing = 16.0;
    final verticalPadding = 20.0;

    for (int i = 0; i < targetIndex; i++) {
      final paragraph = paragraphs[i];
      final estimatedLines = (paragraph.length / 20).ceil().toDouble();
      targetPosition += lineHeight * estimatedLines + paragraphSpacing;
    }

    targetPosition += verticalPadding;

    if (mounted && _scrollController.hasClients) {
      final scrollPosition = _scrollController.position;
      final targetScroll = targetPosition - 100;

      _scrollController.animateTo(
        targetScroll.clamp(0.0, scrollPosition.maxScrollExtent),
        duration: AppConstants.menuAnimationDuration,
        curve: Curves.easeInOut,
      );
    }
  }
}
