import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:novel_reader/providers/reader_view_model.dart';
import 'package:provider/provider.dart';

class TextPaginator extends StatefulWidget {
  final List<String> paragraphs;
  final TextStyle style;
  final EdgeInsetsGeometry padding;
  final String chapterTitle;
  final VoidCallback onNextChapter;
  final VoidCallback onPreviousChapter;
  final double? initialProgress;
  final bool enablePaging;

  const TextPaginator({
    super.key,
    required this.paragraphs,
    required this.style,
    required this.chapterTitle,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0),
    required this.onNextChapter,
    required this.onPreviousChapter,
    this.initialProgress,
    this.enablePaging = true,
  });

  @override
  State<TextPaginator> createState() => _TextPaginatorState();
}

class _TextPaginatorState extends State<TextPaginator> {
  late PageController _pageController;
  List<List<String>> _pages = [];
  bool _isCalculating = true;
  static const double _paragraphSpacing = 16.0;
  int _currentPage = 0;
  int _totalPages = 0;
  Size? _lastSize;
  bool _isBackward = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController()
      ..addListener(() {
        setState(() {
          _currentPage = _pageController.page?.round() ?? 0;
        });
      });
    // double start = DateTime.now().millisecondsSinceEpoch.toDouble();
    _calculatePages(isBackward: false);
    // double end = DateTime.now().millisecondsSinceEpoch.toDouble();
    // print('calculate pages cost: ${end - start}');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentSize = MediaQuery.sizeOf(context);
    if (_lastSize != currentSize) {
      _lastSize = currentSize;
      // double start = DateTime.now().millisecondsSinceEpoch.toDouble();
      _calculatePages(isBackward: false);
      // double end = DateTime.now().millisecondsSinceEpoch.toDouble();
      // print('calculate pages cost: ${end - start}');
    }
  }

  @override
  void didUpdateWidget(TextPaginator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.paragraphs, widget.paragraphs) ||
        !_styleEquals(oldWidget.style, widget.style)) {
      // 章节内容变化时，重新计算分页
      // 如果是返回上一章，则跳转到最后一页；否则跳转到第一页
      _currentPage = _isBackward ? -1 : 0; // -1表示稍后跳转到最后一页
      if (_pageController.hasClients && !_isBackward) {
        _pageController.jumpToPage(0);
      }
      // double start = DateTime.now().millisecondsSinceEpoch.toDouble();
      _calculatePages(isBackward: _isBackward);
      // double end = DateTime.now().millisecondsSinceEpoch.toDouble();
      // print('calculate pages cost: ${end - start}');
    }
  }

  bool _styleEquals(TextStyle a, TextStyle b) {
    if (a == b) return true;
    if (a.fontFamily != b.fontFamily ||
        a.fontSize != b.fontSize ||
        a.height != b.height) {
      return false;
    }

    return true;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // === 核心：支持段落跨页的分页逻辑 ===
  Future<void> _calculatePages({bool isBackward = false}) async {
    if (widget.paragraphs.isEmpty) {
      _updatePages([], isBackward: isBackward);
      return;
    }

    setState(() {
      _isCalculating = true;
    });

    // 使用 microtask 让 UI 先显示加载状态，然后在下一帧执行计算
    await Future.microtask(() {});
    if (!mounted) return;

    final mediaQuery = MediaQuery.maybeOf(context);
    if (mediaQuery == null) return;

    final (usableWidth, usableHeight) = _getUsableSize();
    debugPrint('usableWidth: $usableWidth, usableHeight: $usableHeight');
    final effectiveStyle = widget.style;
    final titleStyle = effectiveStyle.copyWith(
      fontSize: effectiveStyle.fontSize! + 6,
      fontWeight: FontWeight.bold,
    );
    final pages = <List<String>>[];
    List<String> currentPage = [widget.chapterTitle];
    double currentPageHeight = _measureTextHeight(
      widget.chapterTitle,
      usableWidth,
      titleStyle,
    );

    // 所有待处理的"文本片段"队列（初始为原始段落）
    final pendingFragments = <String>[...widget.paragraphs];

    while (pendingFragments.isNotEmpty) {
      final fragment = pendingFragments.removeAt(0);

      // 如果当前页为空，重置高度
      if (currentPage.isEmpty) {
        currentPageHeight = 0.0;
      }

      // 测量当前 fragment 能否完整放入
      final fullHeight = _measureTextHeight(
        fragment,
        usableWidth,
        effectiveStyle,
      );

      // 计算加入该 fragment 所需的高度（考虑段间距）
      final spacing = currentPage.isEmpty ? 0.0 : _paragraphSpacing;
      final neededHeight = currentPageHeight + spacing + fullHeight;

      if (neededHeight <= usableHeight) {
        // 完全放得下
        currentPage.add(fragment);
        currentPageHeight = neededHeight;
      } else {
        // 放不下，尝试拆分
        final splitResult = _splitTextToFit(
          text: fragment,
          maxWidth: usableWidth,
          maxHeight: usableHeight - currentPageHeight - spacing,
          style: effectiveStyle,
        );

        if (splitResult.fit.isNotEmpty) {
          // 有内容可以放入当前页
          currentPage.add(splitResult.fit);
          currentPageHeight +=
              spacing +
              _measureTextHeight(splitResult.fit, usableWidth, effectiveStyle);
          pages.add([...currentPage]);
          currentPage = [];
          currentPageHeight = 0.0;

          // 剩余部分重新入队（可能还需继续拆分）
          if (splitResult.remaining.isNotEmpty) {
            pendingFragments.insert(0, splitResult.remaining);
          }
        } else {
          // 一个字都放不下？极端情况，内容顺延到下一页
          pages.add([...currentPage]);
          currentPage = [fragment];
          currentPageHeight = _measureTextHeight(
            fragment,
            usableWidth,
            effectiveStyle,
          );
        }
      }
    }
    // 添加最后一页
    if (currentPage.isNotEmpty) {
      pages.add(currentPage);
    }

    if (!mounted) return;
    _updatePages(pages, isBackward: isBackward);
  }

  /// 拆分文本：返回 fit（可放入的部分）和 remaining（剩余部分）
  _SplitResult _splitTextToFit({
    required String text,
    required double maxWidth,
    required double maxHeight,
    required TextStyle style,
  }) {
    if (text.isEmpty) return _SplitResult(fit: '', remaining: '');

    // 先看是否一行都放不下
    final firstCharHeight = _measureTextHeight(
      text.substring(0, 1),
      maxWidth,
      style,
    );
    if (firstCharHeight > maxHeight) {
      return _SplitResult(fit: '', remaining: text);
    }
    // 二分查找最佳分割点
    int left = 1, right = text.length;
    int bestIndex = 0;
    while (left <= right) {
      final mid = (left + right) ~/ 2;
      final h = _measureTextHeight(text.substring(0, mid), maxWidth, style);

      if (h <= maxHeight) {
        bestIndex = mid;
        left = mid + 1;
      } else {
        right = mid - 1;
      }
    }

    if (bestIndex == 0) {
      return _SplitResult(fit: '', remaining: text);
    }

    String fit = text.substring(0, bestIndex);
    String remaining = text.substring(bestIndex);
    while (fit.isNotEmpty) {
      final lastChar = fit.codeUnitAt(fit.length - 1);
      if (lastChar == 0x0A || lastChar == 0x0D) {
        fit = fit.substring(0, fit.length - 1);
      } else {
        break;
      }
    }
    return _SplitResult(fit: fit, remaining: remaining);
  }

  double _measureTextHeight(String text, double maxWidth, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: null,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.start,
      strutStyle: StrutStyle.disabled,
    )..layout(maxWidth: maxWidth);
    return painter.height;
  }

  void _updatePages(List<List<String>> pages, {bool isBackward = false}) {
    if (!mounted) return;
    setState(() {
      _pages = pages;
      _isCalculating = false;
      _totalPages = _pages.length;

      // 如果是返回上一章，跳转到最后一页
      if (isBackward && _pages.isNotEmpty) {
        _currentPage = _pages.length - 1;
        // 在下一帧跳转到最后一页
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients && mounted) {
            _pageController.jumpToPage(_currentPage);
          }
        });
      } else if (widget.initialProgress != null &&
          widget.initialProgress! > 0 &&
          _pages.isNotEmpty) {
        // 根据初始进度跳转到相应页面
        _currentPage = ((widget.initialProgress! * (_pages.length - 1)))
            .floor();
        _currentPage = _currentPage.clamp(0, _pages.length - 1);
        // 在下一帧跳转到相应页面
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients && mounted) {
            _pageController.jumpToPage(_currentPage);
          }
        });
      }
    });
  }

  (double, double) _getUsableSize() {
    final direction = Directionality.of(context);
    final horizontalPadding = widget.padding.resolve(direction).horizontal;
    final verticalPadding = widget.padding.resolve(direction).vertical;
    final usableWidth = MediaQuery.of(context).size.width - horizontalPadding;
    final usableHeight =
        MediaQuery.of(context).size.height * 0.92 - verticalPadding-48.0;
    return (usableWidth, usableHeight);
  }

  Widget _buildParagraph(String text, bool isTitle) {
    final style = isTitle
        ? widget.style.copyWith(
            fontSize: widget.style.fontSize! + 6,
            fontWeight: FontWeight.bold,
          )
        : widget.style;

    return Padding(
      padding: EdgeInsets.only(bottom: _paragraphSpacing),
      child: isTitle
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(text: text, style: style),
                  textAlign: TextAlign.start,
                  textDirection: TextDirection.ltr,
                  softWrap: true,
                ),
                Divider(height: 1, color: Colors.black26),
              ],
            )
          : RichText(
              text: TextSpan(text: text, style: style),
              textAlign: TextAlign.start,
              textDirection: TextDirection.ltr,
              softWrap: true,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCalculating) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pages.isEmpty) {
      return const Center(child: Text('无内容'));
    }
    final infoStyle = widget.style.copyWith(
      fontSize: widget.style.fontSize! - 10,
      fontWeight: FontWeight.bold,
    );
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: _pages.length,
          physics: widget.enablePaging ? null : NeverScrollableScrollPhysics(),
          onPageChanged: (index) {
            if (widget.enablePaging) {
              context.read<ReaderViewModel>().updatePageInfo(
                currentPage: index + 1,
                totalPages: _pages.length,
              );
            }
          },
          itemBuilder: (context, index) {
            return Padding(
              padding: widget.padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _pages[index].asMap().entries.map((entry) {
                  final int paragraphIndex = entry.key;
                  final String p = entry.value;

                  // 判断是否是第一页的第一个段落（即标题）
                  bool isTitle = (index == 0 && paragraphIndex == 0);
                  return _buildParagraph(p, isTitle);
                }).toList(),
              ),
            );
          },
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: widget.enablePaging
                ? () {
                    final currentPage = _pageController.page?.round() ?? 0;
                    if (currentPage > 0) {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      );
                    } else {
                      _isBackward = true;
                      widget.onPreviousChapter();
                    }
                  }
                : null,
            child: Container(
              width: MediaQuery.of(context).size.width / 4,
              color: Colors.transparent,
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: widget.enablePaging
                ? () {
                    final currentPage = _pageController.page?.round() ?? 0;
                    if (currentPage < _pages.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeIn,
                      );
                    } else {
                      _isBackward = false;
                      widget.onNextChapter();
                    }
                  }
                : null,
            child: Container(
              width: MediaQuery.of(context).size.width / 4,
              height: double.infinity,
              color: Colors.transparent,
            ),
          ),
        ),
        Positioned(
          bottom: 10,
          left: MediaQuery.of(context).size.width / 2,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.transparent,
            ),
            child: RichText(
              text: TextSpan(
                text: '${_currentPage + 1}/$_totalPages',
                style: infoStyle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SplitResult {
  final String fit;
  final String remaining;
  const _SplitResult({required this.fit, required this.remaining});
}
