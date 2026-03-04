import 'package:flutter/material.dart';
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

class _ChapterListDrawerState extends State<ChapterListDrawer>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    debugPrint('ChapterListDrawer initState');
    super.initState();
    // 延迟滚动到当前章节，等待抽屉布局完成
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) _scrollToCurrentChapter();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    debugPrint('ChapterListDrawer dispose');
    super.dispose();
  }

  void _scrollToCurrentChapter() {
    if (widget.currentIndex > 0 && _scrollController.hasClients) {
      const itemHeight = 48.0; // ListTile 默认高度
      var itemCount = widget.currentIndex; // 包括标题和当前章节
      final offset = itemCount >= 2
          ? (itemCount - 2) * itemHeight
          : 0.0; // 滚动到视图中上部

      _scrollController.jumpTo(
        offset,
        // duration: const Duration(milliseconds: 300),
        // curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    //debugPrint('ChapterListDrawer build');
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
                  const Icon(Icons.menu_book, color: Colors.blue),
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
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: widget.chapters.length,
                itemExtent: 48.0,
                itemBuilder: (context, index) {
                  final chapter = widget.chapters[index];
                  final isCurrent = index == widget.currentIndex;

                  return ListTile(
                    dense: true,
                    trailing: isCurrent
                        ? const Icon(
                            Icons.check_circle,
                            color: Colors.blue,
                            size: 20,
                          )
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                    title: Text(
                      chapter.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: isCurrent ? Colors.blue : Colors.black87,
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    tileColor: isCurrent
                        ? Colors.blue.withValues(alpha: 0.1)
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
