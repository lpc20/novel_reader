import 'package:flutter/material.dart';
import 'package:novel_reader/constants/global.dart';

class EmptyBookshelf extends StatelessWidget {
  final VoidCallback onImport;

  const EmptyBookshelf({super.key, required this.onImport});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Global.menuDividerColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.menu_book_outlined,
              size: 60,
              color: Global.menuTextColor.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '书架空空如也',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Global.menuTextColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '点击右下角 + 导入本地小说',
            style: TextStyle(
              fontSize: 14,
              color: Global.menuTextColor.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: onImport,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('导入小说'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Global.menuHighlightColor,
              foregroundColor: Global.menuTextColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
