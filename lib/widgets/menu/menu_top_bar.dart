import 'package:flutter/material.dart';
import '../../services/settings_service.dart';

class MenuTopBar extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final VoidCallback onOpenChapterList;

  const MenuTopBar({
    super.key,
    required this.title,
    required this.onBack,
    required this.onOpenChapterList,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: SettingsService.menuBackgroundColor,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 8,
        right: 8,
        bottom: 8,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: SettingsService.menuIconColor,
            ),
            onPressed: onBack,
          ),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: SettingsService.menuTextColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.menu, color: SettingsService.menuIconColor),
            onPressed: onOpenChapterList,
            tooltip: '目录',
          ),
        ],
      ),
    );
  }
}
