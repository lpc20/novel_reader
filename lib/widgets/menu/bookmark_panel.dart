import 'package:flutter/material.dart';
import '../../models/bookmark.dart';
import '../../services/settings_service.dart';

class BookmarkPanel extends StatelessWidget {
  final List<Bookmark> bookmarks;
  final VoidCallback onAddBookmark;
  final Function(String) onRemoveBookmark;
  final Function(int) onGoToBookmark;
  final VoidCallback onCloseMenu;

  const BookmarkPanel({
    super.key,
    required this.bookmarks,
    required this.onAddBookmark,
    required this.onRemoveBookmark,
    required this.onGoToBookmark,
    required this.onCloseMenu,
  });

  @override
  Widget build(BuildContext context) {
    if (bookmarks.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Icon(
            Icons.bookmark_outline,
            size: 24,
            color: SettingsService.menuTextColor,
          ),
          const SizedBox(height: 12),
          const Text(
            '暂无书签',
            style: TextStyle(
              fontSize: 14,
              color: SettingsService.menuTextColor,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onAddBookmark,
            style: TextButton.styleFrom(
              backgroundColor: SettingsService.buttonBackgroundColor,
              foregroundColor: SettingsService.buttonHighlightColor,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('添加当前位置为书签'),
          ),
          const SizedBox(height: 12),
        ],
      );
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.3,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '书签',
                  style: TextStyle(
                    fontSize: 16,
                    color: SettingsService.menuTextColor,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: onAddBookmark,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('添加'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SettingsService.buttonBackgroundColor,
                    foregroundColor: SettingsService.buttonHighlightColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...bookmarks.map((bookmark) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: SettingsService.menuDividerColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bookmark.chapterTitle,
                      style: const TextStyle(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      bookmark.contentPreview,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${bookmark.createdAt.month}月${bookmark.createdAt.day}日',
                          style: const TextStyle(
                            fontSize: 11,
                            color: SettingsService.buttonTextColor,
                          ),
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                onGoToBookmark(bookmark.chapterIndex);
                                onCloseMenu();
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: SettingsService.menuHighlightColor,
                                backgroundColor: SettingsService.buttonBackgroundColor,
                              ),
                              child: const Text('前往'),
                            ),
                            TextButton(
                              onPressed: () => onRemoveBookmark(bookmark.id),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('删除'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}