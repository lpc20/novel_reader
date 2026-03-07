import 'package:flutter/material.dart';
import 'package:novel_reader/constants/app_constants.dart';
import 'package:novel_reader/services/settings_service.dart';
import '../models/chapter.dart';

class ChapterListDrawer extends StatefulWidget {
  final List<Chapter> chapters;
  final int currentIndex;
  final Function(int) onChapterSelected;

  const ChapterListDrawer({
    super.key,
    required this.chapters,
    required this.currentIndex,
    required this.onChapterSelected,
  });

  @override
  State<ChapterListDrawer> createState() => _ChapterListDrawerState();
}

class _ChapterListDrawerState extends State<ChapterListDrawer> {
  final ScrollController _scrollController = ScrollController();
  @override
  void initState() {
    debugPrint('ChapterListDrawer initState');
    super.initState();
    // 延迟滚动到当前章节，等待抽屉布局完成
    // Future.delayed(AppConstants.scrollToChapterDelay, () {
    //   if (mounted) _scrollToCurrentChapter();
    // });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      //if (mounted)
      _scrollToCurrentChapter();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    debugPrint('ChapterListDrawer dispose');
    super.dispose();
  }

  void _scrollToCurrentChapter() {
    if (widget.currentIndex >= 3 && _scrollController.hasClients) {
      const itemHeight = AppConstants.listTileHeight;
      final offset = (widget.currentIndex - 3) * itemHeight;
      _scrollController.jumpTo(offset);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
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
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          '共 ${widget.chapters.length} 章',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '当前: 第${widget.currentIndex + 1}章',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
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
                    //dense: true,
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
      ),
    );
  }
}
