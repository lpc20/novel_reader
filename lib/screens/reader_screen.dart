import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reader_provider.dart';
import '../services/settings_service.dart';
import '../widgets/reader_menu.dart';
import '../widgets/chapter_list_drawer.dart';
import '../models/novel.dart';
import '../models/chapter.dart';
import '../utils/color_utils.dart';

class _ReaderData {
  final ReadingSettings settings;
  final List<String> paragraphs;
  final Chapter? currentChapter;
  final bool isLoading;
  final int currentChapterIndex;
  final List<Chapter> chapters;
  final String searchQuery;
  final List<SearchResult> searchResults;
  final int currentSearchIndex;

  const _ReaderData({
    required this.settings,
    required this.paragraphs,
    required this.currentChapter,
    required this.isLoading,
    required this.currentChapterIndex,
    required this.chapters,
    required this.searchQuery,
    required this.searchResults,
    required this.currentSearchIndex,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _ReaderData &&
        other.settings == settings &&
        other.paragraphs == paragraphs &&
        other.currentChapter == currentChapter &&
        other.isLoading == isLoading &&
        other.currentChapterIndex == currentChapterIndex &&
        listEquals(other.chapters, chapters) &&
        other.searchQuery == searchQuery &&
        listEquals(other.searchResults, searchResults) &&
        other.currentSearchIndex == currentSearchIndex;
  }

  @override
  int get hashCode => Object.hash(
    settings,
    paragraphs,
    currentChapter,
    isLoading,
    currentChapterIndex,
    chapters,
    searchQuery,
    searchResults,
    currentSearchIndex,
  );
}

class ReaderScreen extends StatefulWidget {
  final Novel novel;

  const ReaderScreen({super.key, required this.novel});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  int? _lastScrollTimestamp;
  static const int _throttleDelay = 100; // 100ms 节流延迟
  static final progressIndicator = Center(
    child: SizedBox(
      height: 40,
      width: 40,
      child: CircularProgressIndicator(
        strokeWidth: 4,
        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3498DB)),
      ),
    ),
  );

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    // 延迟加载小说，避免在构建过程中调用 notifyListeners
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNovel();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final provider = context.read<ReaderProvider>();
    provider.performSearch(_searchController.text);
  }

  Future<void> _loadNovel() async {
    final readerProvider = Provider.of<ReaderProvider>(context, listen: false);
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
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_lastScrollTimestamp == null ||
        now - _lastScrollTimestamp! > _throttleDelay) {
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
    final readerProvider = Provider.of<ReaderProvider>(context, listen: false);
    readerProvider.toggleMenu();
  }

  void _openChapterDrawer() {
    _toggleMenu();
    _scaffoldKey.currentState?.openDrawer();
  }

  Widget _buildContentWithParagraphs(
    List<String> paragraphs,
    ReadingSettings settings,
    List<SearchResult> searchResults,
    int currentSearchIndex,
  ) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final paragraph = paragraphs[index];
        final textSpan = _buildHighlightedText(
          paragraph,
          settings,
          searchResults,
          index,
          currentSearchIndex,
        );

        return RepaintBoundary(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16), // 段落间距
            child: RichText(text: textSpan, textAlign: TextAlign.left),
          ),
        );
      }, childCount: paragraphs.length),
    );
  }

  TextSpan _buildHighlightedText(
    String text,
    ReadingSettings settings,
    List<SearchResult> searchResults,
    int paragraphIndex,
    int currentSearchIndex,
  ) {
    final textStyle = TextStyle(
      fontSize: settings.fontSize,
      color: ColorUtils.parseColor(settings.textColor),
      height: settings.lineHeight,
    );

    if (searchResults.isEmpty || currentSearchIndex < 0) {
      return TextSpan(text: text, style: textStyle);
    }

    // 查找当前段落中的搜索结果
    final currentResult = searchResults[currentSearchIndex];

    // 只高亮当前选中的搜索结果
    if (currentResult.paragraphIndex != paragraphIndex) {
      return TextSpan(text: text, style: textStyle);
    }

    // 构建高亮文本，只高亮当前结果
    final spans = <TextSpan>[];

    // 添加匹配前的文本
    if (currentResult.startIndex > 0) {
      spans.add(
        TextSpan(
          text: text.substring(0, currentResult.startIndex),
          style: textStyle,
        ),
      );
    }

    // 添加高亮的匹配文本
    spans.add(
      TextSpan(
        text: text.substring(currentResult.startIndex, currentResult.endIndex),
        style: textStyle.copyWith(
          backgroundColor: const Color(0xFFFFB74D),
          color: Colors.black,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    // 添加匹配后的文本
    if (currentResult.endIndex < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(currentResult.endIndex),
          style: textStyle,
        ),
      );
    }

    return TextSpan(children: spans);
  }

  void _onChapterSelected(int index) {
    final readerProvider = Provider.of<ReaderProvider>(context, listen: false);
    readerProvider.goToChapter(index);
    _scaffoldKey.currentState?.closeDrawer();
  }

  Widget? _buildChapterDrawer(_ReaderData data) {
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
    return Selector<ReaderProvider, _ReaderData>(
      selector: (context, provider) => _ReaderData(
        settings: provider.settings,
        paragraphs: provider.getCurrentChapterContent(),
        currentChapter: provider.currentChapter,
        isLoading: provider.isLoading,
        currentChapterIndex: provider.currentChapterIndex,
        chapters: provider.chapters,
        searchQuery: provider.searchQuery,
        searchResults: provider.searchResults,
        currentSearchIndex: provider.currentSearchIndex,
      ),
      builder: (context, data, child) {
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: ColorUtils.parseColor(data.settings.backgroundColor),
          drawer: _buildChapterDrawer(data),
          body: GestureDetector(
            onTap: () => _toggleMenu(),
            child: Stack(
              children: [
                if (data.isLoading)
                  progressIndicator
                else
                  CustomScrollView(
                    key: ValueKey('content_${data.currentChapterIndex}'),
                    controller: _scrollController,
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 20,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (data.currentChapter != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Text(
                                    data.currentChapter!.title,
                                    style: TextStyle(
                                      fontSize: data.settings.fontSize + 4,
                                      fontWeight: FontWeight.bold,
                                      color: ColorUtils.parseColor(
                                        data.settings.textColor,
                                      ),
                                      height: data.settings.lineHeight,
                                    ),
                                    textAlign: TextAlign.left,
                                  ),
                                ),
                              if (data.currentChapter != null)
                                const Divider(thickness: 2),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: _buildContentWithParagraphs(
                          data.paragraphs,
                          data.settings,
                          data.searchResults,
                          data.currentSearchIndex,
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton(
                                onPressed: data.currentChapterIndex > 0
                                    ? () => context
                                          .read<ReaderProvider>()
                                          .goToChapter(
                                            data.currentChapterIndex - 1,
                                          )
                                    : null,
                                child: const Icon(Icons.chevron_left),
                              ),
                              ElevatedButton(
                                onPressed:
                                    data.currentChapterIndex <
                                        data.chapters.length - 1
                                    ? () => context
                                          .read<ReaderProvider>()
                                          .goToChapter(
                                            data.currentChapterIndex + 1,
                                          )
                                    : null,
                                child: const Icon(Icons.chevron_right),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                AnimatedOpacity(
                  opacity: context.watch<ReaderProvider>().showMenu ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Visibility(
                    visible: context.watch<ReaderProvider>().showMenu,
                    maintainState: true,
                    maintainAnimation: true,
                    maintainSize: true,
                    child: ReaderMenu(
                      novel: widget.novel,
                      onClose: _toggleMenu,
                      onChapterList: _openChapterDrawer,
                      onSearch: _onSearch,
                      searchController: _searchController,
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
    final provider = context.read<ReaderProvider>();
    if (provider.currentSearchIndex < 0 ||
        provider.currentSearchIndex >= provider.searchResults.length) {
      return;
    }

    final result = provider.searchResults[provider.currentSearchIndex];
    final paragraphs = provider.getCurrentChapterContent();

    if (result.paragraphIndex >= paragraphs.length) {
      return;
    }

    // 计算目标滚动位置
    double targetPosition = 0;
    final lineHeight =
        provider.settings.fontSize * provider.settings.lineHeight;
    final paragraphSpacing = 16.0;
    final verticalPadding = 20.0;

    // 计算到目标段落的总高度
    for (int i = 0; i < result.paragraphIndex; i++) {
      final paragraph = paragraphs[i];
      final estimatedLines = (paragraph.length / 20).ceil().toDouble();
      targetPosition += lineHeight * estimatedLines + paragraphSpacing;
    }

    // 添加顶部内边距
    targetPosition += verticalPadding;

    // 滚动到目标位置，留出顶部空间
    if (_scrollController.hasClients) {
      final scrollPosition = _scrollController.position;
      final targetScroll = targetPosition - 100; // 留出顶部空间

      _scrollController.animateTo(
        targetScroll.clamp(0.0, scrollPosition.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
}
