import 'package:flutter/material.dart';
import '../../constants/global.dart';

class ChapterNavigationPanel extends StatelessWidget {
  final int currentChapterIndex;
  final int chaptersLength;
  final Function(int) onChapterChange;
  final double? sliderValue;
  final Function(double) onSliderChange;
  final Function(double) onSliderChangeEnd;

  const ChapterNavigationPanel({
    super.key,
    required this.currentChapterIndex,
    required this.chaptersLength,
    required this.onChapterChange,
    this.sliderValue,
    required this.onSliderChange,
    required this.onSliderChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: TextButton.icon(
            icon: const Icon(Icons.chevron_left, size: 12),
            label: const Text('上一章'),
            style: TextButton.styleFrom(
              foregroundColor: Global.menuTextColor,
              padding: EdgeInsets.zero,
            ),
            onPressed: currentChapterIndex > 0
                ? () => onChapterChange(currentChapterIndex - 1)
                : null,
          ),
        ),
        if (chaptersLength > 0)
          SizedBox(
            width: Global.chapterSliderWidth,
            child: Slider(
              value:
                  sliderValue ??
                  (currentChapterIndex + 1) / chaptersLength.toDouble(),
              min: 0.0,
              max: 1.0,
              activeColor: Global.menuSliderActiveColor,
              inactiveColor: Global.menuSliderInactiveColor,
              thumbColor: Global.menuSliderThumbColor,
              onChanged: onSliderChange,
              onChangeEnd: onSliderChangeEnd,
            ),
          ),
        Expanded(
          child: TextButton.icon(
            icon: const Icon(Icons.chevron_right, size: 12),
            iconAlignment: IconAlignment.end,
            label: const Text('下一章'),
            style: TextButton.styleFrom(
              foregroundColor: Global.menuTextColor,
              padding: EdgeInsets.zero,
            ),
            onPressed: currentChapterIndex < chaptersLength - 1
                ? () => onChapterChange(currentChapterIndex + 1)
                : null,
          ),
        ),
      ],
    );
  }
}
