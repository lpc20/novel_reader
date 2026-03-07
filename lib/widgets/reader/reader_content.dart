import 'package:flutter/material.dart';
import '../../models/reader_data.dart';
import '../../services/settings_service.dart';
import '../../utils/color_utils.dart';

class ReaderContent extends StatelessWidget {
  final List<String> paragraphs;
  final ReadingSettings settings;
  final List<SearchResult> searchResults;
  final int currentSearchIndex;
  final String? chapterTitle;

  const ReaderContent({
    super.key,
    required this.paragraphs,
    required this.settings,
    required this.searchResults,
    required this.currentSearchIndex,
    this.chapterTitle,
  });

  List<Widget> buildSlivers() {
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 20,
        ),
        sliver: SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (chapterTitle != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Text(
                    chapterTitle!,
                    style: TextStyle(
                      fontSize: settings.fontSize + 6,
                      fontWeight: FontWeight.bold,
                      color: ColorUtils.parseColor(
                        settings.textColor,
                      ),
                      height: 1.3,
                      letterSpacing: 1.0,
                      fontFamily: settings.fontFamily == 'system' ? null : settings.fontFamily,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (chapterTitle != null)
                Divider(
                  height: 1,
                  color: ColorUtils.parseColor(
                    settings.textColor,
                  ),
                ),
            ],
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: _buildContentWithParagraphs(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // 这个方法保留是为了兼容现有代码，实际使用时应该直接调用buildSlivers()
    return CustomScrollView(
      key: ValueKey('content_${chapterTitle ?? ''}'),
      slivers: buildSlivers(),
    );
  }

  Widget _buildContentWithParagraphs() {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final paragraph = paragraphs[index];
        final textSpan = _buildHighlightedText(
          paragraph,
          index,
        );

        return RepaintBoundary(
          child: Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: RichText(text: textSpan, softWrap: true),
          ),
        );
      }, childCount: paragraphs.length),
    );
  }

  TextSpan _buildHighlightedText(
    String text,
    int paragraphIndex,
  ) {
    final textStyle = TextStyle(
      fontSize: settings.fontSize,
      color: ColorUtils.parseColor(settings.textColor),
      height: settings.lineHeight,
      fontWeight: FontWeight.normal,
      fontFamily: settings.fontFamily == 'system' ? null : settings.fontFamily,
    );

    if (searchResults.isEmpty || currentSearchIndex < 0) {
      return TextSpan(text: text, style: textStyle);
    }

    final currentResult = searchResults[currentSearchIndex];

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
        TextSpan(
          text: text.substring(0, startIndex),
          style: textStyle,
        ),
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
      spans.add(
        TextSpan(
          text: text.substring(endIndex),
          style: textStyle,
        ),
      );
    }
    return TextSpan(children: spans);
  }
}