import 'package:flutter/material.dart';
import '../models/chapter.dart';

class ChapterListSheet extends StatelessWidget {
  final List<Chapter> chapters;
  final int currentIndex;
  final Function(int) onSelect;
  final ScrollController scrollController;

  // 用于获取当前章节ListTile的尺寸
  //final GlobalKey currentChapterKey;

  const ChapterListSheet({
    super.key,
    required this.chapters,
    required this.currentIndex,
    required this.onSelect,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    // 在布局完成后滚动到当前章节
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (currentIndex >= 0 &&
          chapters.isNotEmpty &&
          scrollController.hasClients) {
        _scrollToCurrentChapter();
      }
    });

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '目录 (${chapters.length}章)',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '当前: 第${currentIndex + 1}章',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: chapters.length,
              itemBuilder: (context, index) {
                final chapter = chapters[index];
                final isCurrent = index == currentIndex;

                return ListTile(
                  title: Text(
                    chapter.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isCurrent ? Colors.blue : null,
                      fontWeight: isCurrent ? FontWeight.bold : null,
                    ),
                  ),
                  trailing: isCurrent
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                  onTap: () => onSelect(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToCurrentChapter() {
    const defaultTileHeight = 48.0; // Flutter ListTile默认高度
    final scrollOffset = (currentIndex - 3) * defaultTileHeight;
    debugPrint('scrollOffset: $scrollOffset');
    scrollController.animateTo(
      scrollOffset,
      duration: const Duration(seconds: 500),
      curve: Curves.easeInOut,
    );
  }
}
