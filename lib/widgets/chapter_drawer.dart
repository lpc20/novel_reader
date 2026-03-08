import 'package:flutter/material.dart';
import 'package:novel_reader/constants/app_constants.dart';
import 'package:novel_reader/services/settings_service.dart';
import '../models/chapter.dart';

class ChapterDrawer extends StatefulWidget {
  final List<Chapter> chapters;
  final int currentIndex;
  final Function(int) onChapterSelected;

  const ChapterDrawer({
    super.key,
    required this.chapters,
    required this.currentIndex,
    required this.onChapterSelected,
  });

  @override
  State<ChapterDrawer> createState() => _ChapterDrawerState();
}

class _ChapterDrawerState extends State<ChapterDrawer> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    debugPrint('ChapterDrawer initState');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentChapter();
    });
  }

  @override
  void didUpdateWidget(ChapterDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // if (widget.currentIndex != oldWidget.currentIndex) {
    //   debugPrint(
    //     'ChapterDrawer: 章节从 ${oldWidget.currentIndex} 变为 ${widget.currentIndex}',
    //   );
    // }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentChapter();
    });
  }

  void _scrollToCurrentChapter() {
    if (widget.chapters.isEmpty) {
      return;
    }

    if (widget.currentIndex < 0 ||
        widget.currentIndex >= widget.chapters.length) {
      return;
    }

    if (!_scrollController.hasClients) {
      return;
    }

    if (widget.currentIndex >= 3) {
      const itemHeight = AppConstants.listTileHeight;
      final offset = (widget.currentIndex - 3) * itemHeight;
      _scrollController.jumpTo(offset);
    } else {
      _scrollController.jumpTo(0);
    }
  }

  @override
  void dispose() {
    debugPrint('ChapterDrawer dispose');
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.menu_book,
                  color: SettingsService.menuHighlightColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '目录',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        '共 ${widget.chapters.length} 章',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Text(
                  '当前: 第${widget.currentIndex + 1}章',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: widget.chapters.length,
              itemExtent: AppConstants.listTileHeight,
              itemBuilder: (context, index) {
                final chapter = widget.chapters[index];
                final isCurrent = index == widget.currentIndex;

                return ListTile(
                  trailing: isCurrent
                      ? const Icon(
                          Icons.check_circle,
                          color: SettingsService.menuHighlightColor,
                          size: 20,
                        )
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            color: SettingsService.menuTextColor,
                          ),
                        ),
                  title: Text(
                    chapter.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: isCurrent
                          ? SettingsService.menuHighlightColor
                          : Colors.black87,
                      fontWeight: isCurrent
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  tileColor: isCurrent
                      ? SettingsService.menuHighlightColor.withValues(
                          alpha: 0.1,
                        )
                      : null,
                  onTap: () => widget.onChapterSelected(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
