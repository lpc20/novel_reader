// lib/widgets/text_paginator.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class TextPaginator extends StatefulWidget {
  final List<String> paragraphs;
  final TextStyle style;
  final EdgeInsetsGeometry padding;
  final String chapterTitle;
  final VoidCallback onNextChapter;
  final VoidCallback onPreviousChapter;

  const TextPaginator({
    super.key,
    required this.paragraphs,
    required this.style,
    required this.chapterTitle,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0),
    required this.onNextChapter,
    required this.onPreviousChapter,
  });

  @override
  State<TextPaginator> createState() => _TextPaginatorState();
}

class _TextPaginatorState extends State<TextPaginator> {
  late PageController _pageController;
  List<List<String>> _pages = [];
  bool _isCalculating = true;
  final double _paragraphSpacing = 16.0;
  int _currentPage = 0;
  int _totalPages = 0;
  Size? _lastSize;

  @override
  void initState() {
    super.initState();
    _pageController = PageController()
      ..addListener(() {
        setState(() {
          _currentPage = _pageController.page?.round() ?? 0;
        });
      });
    _calculatePages();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentSize = MediaQuery.sizeOf(context);
    if (_lastSize != currentSize) {
      _lastSize = currentSize;
      _calculatePages();
    }
  }

  @override
  void didUpdateWidget(TextPaginator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.paragraphs, widget.paragraphs) ||
        !_styleEquals(oldWidget.style, widget.style)) {
      _calculatePages();
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
  Future<void> _calculatePages() async {
    if (widget.paragraphs.isEmpty) {
      _updatePages([]);
      return;
    }

    await Future.microtask(() {});
    if (!mounted) return;
    final mediaQuery = MediaQuery.maybeOf(context);
    if (mediaQuery == null) return;

    final (usableWidth, usableHeight) = _getUsableSize();
    debugPrint('宽度:$usableWidth\t高度:$usableHeight');
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

    // 所有待处理的“文本片段”队列（初始为原始段落）
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
          debugPrint('第${pages.length}页高度:$currentPageHeight');
          currentPage = [];
          currentPageHeight = 0.0;

          // 剩余部分重新入队（可能还需继续拆分）
          if (splitResult.remaining.isNotEmpty) {
            pendingFragments.insert(0, splitResult.remaining);
          }
        } else {
          // 即使一个字都放不下？极端情况，强制放入（避免死循环）
          pages.add([...currentPage]);
          debugPrint('第${pages.length}页高度:$currentPageHeight');
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
      debugPrint('第${pages.length}页高度:$currentPageHeight');
    }

    _updatePages(pages);
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
      // 连一个字符都放不下？不太可能，但安全起见
      return _SplitResult(fit: '', remaining: text);
    }

    // 贪心法：逐字符尝试（可优化为二分查找）
    int bestIndex = 0;
    for (int i = 1; i <= text.length; i++) {
      final h = _measureTextHeight(text.substring(0, i), maxWidth, style);
      if (h <= maxHeight) {
        bestIndex = i;
      } else {
        break;
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

  void _updatePages(List<List<String>> pages) {
    if (!mounted) return;
    setState(() {
      _pages = pages;
      _isCalculating = false;
      _totalPages = _pages.length;
    });
  }

  (double, double) _getUsableSize() {
    final direction = Directionality.of(context);
    final horizontalPadding = widget.padding.resolve(direction).horizontal;
    final usableWidth = MediaQuery.of(context).size.width - horizontalPadding;
    final usableHeight = MediaQuery.of(context).size.height * 0.9;
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

  @override
  Widget build(BuildContext context) {
    if (_isCalculating) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pages.isEmpty) {
      return const Center(child: Text('无内容'));
    }
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: _pages.length,
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
            onTap: () {
              final currentPage = _pageController.page?.round() ?? 0;
              if (currentPage > 0) {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                );
              } else {
                debugPrint('上一章');
                widget.onPreviousChapter();
                // 重置到上一章的第一页
                _pageController.animateToPage(
                  _pages.length - 1,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                );
              }
            },
            child: Container(
              width: MediaQuery.of(context).size.width / 4,
              color: Colors.transparent,
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () {
              final currentPage = _pageController.page?.round() ?? 0;
              if (currentPage < _pages.length - 1) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeIn,
                );
              } else {
                debugPrint('下一章');
                widget.onNextChapter();
                // 重置到下一章的第一页
                _pageController.animateToPage(
                  0,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeIn,
                );
              }
            },
            child: Container(
              width: MediaQuery.of(context).size.width / 4,
              height: double.infinity,
              color: Colors.transparent,
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.black54,
            ),
            child: Text('${_currentPage + 1}/$_totalPages'),
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
