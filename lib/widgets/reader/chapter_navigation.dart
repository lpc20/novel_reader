import 'package:flutter/material.dart';
import '../../services/settings_service.dart';
import '../../utils/color_utils.dart';

class ChapterNavigation extends StatelessWidget {
  final int currentChapterIndex;
  final int chaptersLength;
  final Function(int) onChapterChange;
  final ReadingSettings settings;

  const ChapterNavigation({
    super.key,
    required this.currentChapterIndex,
    required this.chaptersLength,
    required this.onChapterChange,
    required this.settings,
  });

  Widget buildSliver() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 30,
      ),
      sliver: SliverToBoxAdapter(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 上一章按钮
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                child: TextButton.icon(
                  onPressed: currentChapterIndex > 0
                      ? () => onChapterChange(currentChapterIndex - 1)
                      : null,
                  icon: const Icon(
                    Icons.chevron_left,
                    size: 18,
                  ),
                  label: const Text('上一章'),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: ColorUtils.parseColor(
                      settings.textColor,
                    ),
                    side: BorderSide(
                      color: ColorUtils.parseColor(
                        settings.textColor,
                      ),
                      width: 1,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // 章节信息
            SizedBox(
              width: 80,
              child: Text(
                '${currentChapterIndex + 1}/${chaptersLength}',
                style: TextStyle(
                  fontSize: 14,
                  color: ColorUtils.parseColor(
                    settings.textColor,
                  ),
                ),
              ),
            ),
            // 下一章按钮
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(left: 10),
                child: TextButton.icon(
                  onPressed: currentChapterIndex < chaptersLength - 1
                      ? () => onChapterChange(currentChapterIndex + 1)
                      : null,
                  icon: const Icon(
                    Icons.chevron_right,
                    size: 18,
                  ),
                  iconAlignment: IconAlignment.end,
                  label: const Text('下一章'),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: ColorUtils.parseColor(
                      settings.textColor,
                    ),
                    side: BorderSide(
                      color: ColorUtils.parseColor(
                        settings.textColor,
                      ),
                      width: 1,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return buildSliver();
  }
}