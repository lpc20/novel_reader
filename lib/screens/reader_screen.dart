import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:novel_reader/constants/global.dart';
import 'package:novel_reader/widgets/chapter_drawer.dart';
import 'package:novel_reader/widgets/reader/text_paginator.dart';
import 'package:provider/provider.dart';
import '../models/reader_data.dart';
import '../providers/reader_view_model.dart';
import '../widgets/reader_menu.dart';
import '../models/novel.dart';
import '../utils/color_utils.dart';
import '../widgets/reader/chapter_navigation.dart';

class ReaderScreen extends StatefulWidget {
  final Novel novel;

  const ReaderScreen({super.key, required this.novel});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen>
    with SingleTickerProviderStateMixin {
  bool _showDrawer = false;
  bool _showMenu = false;
  late final ScrollController _scrollController;
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _menuAnimationController;
  late Animation<Offset> _menuAnimation;
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
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    _menuAnimationController = AnimationController(
      vsync: this,
      duration: Global.menuAnimationDuration,
    );
    _menuAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _menuAnimationController,
            curve: Curves.easeOutCubic,
          ),
        );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNovel();
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top],
    );
    _scrollController.dispose();
    _searchController.dispose();
    _menuAnimationController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final provider = context.read<ReaderViewModel>();
    provider.performSearch(_searchController.text);
  }

  Future<void> _loadNovel() async {
    final vm = context.read<ReaderViewModel>();
    await vm.loadNovel(
      widget.novel.id,
      widget.novel.filePath,
      widget.novel.encoding,
    );
    // 延迟滚动到上次阅读位置，等待布局完成
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !vm.usePageMode) {
        final progressInChapter = vm.progressInChapter;
        if (progressInChapter > 0 && _scrollController.hasClients) {
          // 在下一帧中滚动，确保布局已完成
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _scrollController.hasClients) {
              final maxScrollExtent =
                  _scrollController.position.maxScrollExtent;
              if (maxScrollExtent > 0) {
                final targetPosition = maxScrollExtent * progressInChapter;
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
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_lastScrollTimestamp == null ||
        now - _lastScrollTimestamp! > Global.scrollThrottleDelay) {
      _lastScrollTimestamp = now;
      // 计算滚动进度并更新
      if (_scrollController.hasClients) {
        final position = _scrollController.position;
        final maxScrollExtent = position.maxScrollExtent;
        if (maxScrollExtent > 0) {
          final progressInChapter = position.pixels / maxScrollExtent;
          context.read<ReaderViewModel>().updateProgressInChapter(
            progressInChapter,
          );
        }
      }
    }
  }

  void _toggleMenu() {
    if (_menuAnimationController.isAnimating) return;
    if (_showMenu) {
      _menuAnimationController.reverse();
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      _menuAnimationController.forward(from: 0);
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: [SystemUiOverlay.top],
      );
    }
    setState(() {
      _showMenu = !_showMenu;
    });
  }

  void _openChapterDrawer() {
    if (_showMenu) _toggleMenu();
    _showDrawer = true;
  }

  void _onChapterSelected(int index) {
    final readerProvider = context.read<ReaderViewModel>();
    if (index == readerProvider.currentChapterIndex) {
      _showDrawer = false;
      return;
    }
    readerProvider.goToChapter(index);
    _showDrawer = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: Global.scrollToChapterDelay,
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final vm = context.read<ReaderViewModel>();

    return Scaffold(
      backgroundColor: ColorUtils.parseColor(
        context.select<ReaderViewModel, String>(
          (p) => p.settings.backgroundColor,
        ),
      ),
      body: GestureDetector(
        onTap: () => _toggleMenu(),
        child: Stack(
          children: [
            // 主内容区域：根据阅读模式选择滚动或翻页
            vm.settings.usePageMode
                ? _buildMainContentWithPaginator()
                : _buildMainContentWithScrollView(),
            // 章节抽屉
            _buildChapterDrawer(screenWidth),
            // 阅读器菜单
            _buildReaderMenu(screenWidth),
            !_showMenu?Positioned(
              top: 35,
              left: 16,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.transparent,
                ),
                child: RichText(
                  text: TextSpan(
                    text: vm.currentChapter!=null?vm.currentChapter!.title:'',
                    style: TextStyle(
                      fontSize: vm.settings.fontSize-6,
                      color: Global.menuTextColor,
                      height: 1.3,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ):const SizedBox(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContentWithScrollView() {
    final data = context.select<ReaderViewModel, ReaderScreenData>(
      (p) => p.screenData,
    );

    if (data.isLoading) {
      return progressIndicator;
    }
    return Padding(
      padding: const EdgeInsets.only(top: 48.0),
      child: CustomScrollView(
        controller: _scrollController,
        physics: _showMenu ? NeverScrollableScrollPhysics() : null,
        slivers: [
          ..._buildReaderContentSlivers(data),
          ChapterNavigation(
            currentChapterIndex: data.currentChapterIndex,
            chaptersLength: data.chapters.length,
            onChapterChange: _onChapterSelected,
            settings: data.settings,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildReaderContentSlivers(ReaderScreenData data) {
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        sliver: SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  data.chapters[data.currentChapterIndex].title,
                  style: TextStyle(
                    fontSize: data.settings.fontSize + 6,
                    fontWeight: FontWeight.bold,
                    color: ColorUtils.parseColor(data.settings.textColor),
                    height: 1.3,
                    letterSpacing: 1.0,
                    fontFamily: data.settings.fontFamily,
                  ),
                  textAlign: TextAlign.left,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Divider(
                height: 1,
                color: ColorUtils.parseColor(data.settings.textColor),
              ),
            ],
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final paragraph = data.paragraphs[index];
            final textSpan = _buildHighlightedText(paragraph, index, data);

            return RepaintBoundary(
              child: Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: RichText(text: textSpan, softWrap: true),
              ),
            );
          }, childCount: data.paragraphs.length),
        ),
      ),
    ];
  }

  TextSpan _buildHighlightedText(
    String text,
    int paragraphIndex,
    ReaderScreenData data,
  ) {
    final textStyle = TextStyle(
      fontSize: data.settings.fontSize,
      color: ColorUtils.parseColor(data.settings.textColor),
      height: data.settings.lineHeight,
      fontWeight: FontWeight.normal,
      fontFamily: data.settings.fontFamily,
    );

    if (data.searchResults.isEmpty || data.currentSearchIndex < 0) {
      return TextSpan(text: text, style: textStyle);
    }

    final currentResult = data.searchResults[data.currentSearchIndex];

    if (currentResult.paragraphIndex != paragraphIndex) {
      return TextSpan(text: text, style: textStyle);
    }

    final startIndex = currentResult.startIndex;
    final endIndex = currentResult.endIndex;

    if (startIndex == 0 && endIndex >= text.length) {
      return TextSpan(
        text: text,
        style: textStyle.copyWith(
          backgroundColor: const Color(0xFFFFB74D),
          color: Colors.black,
        ),
      );
    }

    final spans = <TextSpan>[];

    if (startIndex > 0) {
      spans.add(
        TextSpan(text: text.substring(0, startIndex), style: textStyle),
      );
    }

    spans.add(
      TextSpan(
        text: text.substring(startIndex, endIndex),
        style: textStyle.copyWith(
          backgroundColor: const Color(0xFFFFB74D),
          color: Colors.black,
        ),
      ),
    );

    if (endIndex < text.length) {
      spans.add(TextSpan(text: text.substring(endIndex), style: textStyle));
    }
    return TextSpan(children: spans);
  }

  Widget _buildMainContentWithPaginator() {
    final data = context.select<ReaderViewModel, ReaderScreenData>(
      (p) => p.screenData,
    );

    if (data.isLoading) {
      return progressIndicator;
    }

    final vm = context.read<ReaderViewModel>();
    return Padding(
      padding: const EdgeInsets.only(top: 48.0, bottom: 10.0),
      child: TextPaginator(
        paragraphs: data.paragraphs,
        chapterTitle: data.chapters[data.currentChapterIndex].title,
        style: TextStyle(
          fontSize: data.settings.fontSize,
          height: data.settings.lineHeight,
          fontFamily: data.settings.fontFamily,
          color: ColorUtils.parseColor(data.settings.textColor),
        ),
        onNextChapter: () => vm.nextChapter(),
        onPreviousChapter: () => vm.previousChapter(),
        initialProgress: vm.progressInChapter,
        enablePaging: !_showMenu,
      ),
    );
  }

  Widget _buildChapterDrawer(double screenWidth) {
    final data = context.select<ReaderViewModel, ReaderScreenData>(
      (p) => p.screenData,
    );
    return AnimatedPositioned(
      duration: Global.fadeAnimationDuration,
      curve: Curves.easeInOut,
      left: _showDrawer ? 0 : -screenWidth,
      top: 0,
      bottom: 0,
      width: screenWidth,
      child: GestureDetector(
        onTap: () {
          setState(() => _showDrawer = false);
        },
        child: Container(
          color: _showDrawer ? Colors.black54 : Colors.transparent, // 遮罩层
          child: Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () {}, // 阻止点击穿透到遮罩
              child: Container(
                width: screenWidth * 0.7,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: ChapterDrawer(
                  chapters: data.chapters,
                  currentIndex: data.currentChapterIndex,
                  onChapterSelected: _onChapterSelected,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReaderMenu(double screenWidth) {
    return AnimatedOpacity(
      opacity: _showMenu ? 1.0 : 0.0,
      duration: Global.menuAnimationDuration,
      curve: Curves.easeInOut,
      child: Visibility(
        visible: _showMenu,
        maintainState: true,
        maintainAnimation: true,
        maintainSize: true,
        child: SlideTransition(
          position: _menuAnimation,
          child: ReaderMenu(
            title: widget.novel.title,
            onClose: _toggleMenu,
            onChapterList: _openChapterDrawer,
            onSearch: _onSearch,
            onChapterChange: _onChapterSelected,
            searchController: _searchController,
          ),
        ),
      ),
    );
  }

  void _onSearch() {
    final provider = context.read<ReaderViewModel>();

    // 检查是否为分页模式，如果是则不执行搜索
    if (provider.settings.usePageMode) {
      return;
    }

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

    final provider = context.read<ReaderViewModel>();
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
        duration: Global.scrollToChapterDelay,
        curve: Curves.easeInOut,
      );
    }
  }
}
