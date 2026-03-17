import 'bookmarks_service.dart';
import 'bookshelf_service.dart';
import 'settings_service.dart';

/// 应用启动阶段的统一初始化入口，仅负责底层 Service 的初始化。
class AppInitializer {
  AppInitializer._();

  static Future<void> init() async {
    await SettingsService().init();
    await BookmarksService().init();
    await BookshelfService().init();
  }
}

