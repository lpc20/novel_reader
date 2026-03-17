import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:novel_reader/providers/settings_view_model.dart';
import 'package:provider/provider.dart';
import 'constants/global.dart';
import 'providers/bookshelf_view_model.dart';
import 'providers/reader_view_model.dart';
import 'services/app_initializer.dart';
import 'services/file_service.dart';
import 'screens/bookshelf_screen.dart';
import 'utils/color_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppInitializer.init();
  runApp(const NovelReaderApp());
}

class NovelReaderApp extends StatefulWidget {
  const NovelReaderApp({super.key});

  @override
  State<NovelReaderApp> createState() => _NovelReaderAppState();
}

class _NovelReaderAppState extends State<NovelReaderApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top],
    );
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      // 应用进入后台时清理缓存
      FileService().clearCacheIfTooLarge(
        Global.defaultCacheLimitBytes,
      ); // 50MB限制
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
        ChangeNotifierProvider(create: (_) => BookshelfViewModel()),
        ChangeNotifierProvider(create: (_) => ReaderViewModel()),
      ],
      child: Builder(
        builder: (context) {
          final settings = context.watch<SettingsViewModel>().settings;
          final backgroundColor = ColorUtils.parseColor(
            settings.backgroundColor,
          );
          final textColor = ColorUtils.parseColor(settings.textColor);
          final brightness = ColorUtils.getBrightness(backgroundColor);

          return MaterialApp(
            title: '墨读',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              scaffoldBackgroundColor: Colors.white,
              textTheme: ThemeData.light().textTheme.apply(
                fontFamily: settings.fontFamily == 'system'
                    ? 'OPPOSans'
                    : settings.fontFamily,
                bodyColor: textColor,
                displayColor: textColor,
              ),
              typography: Typography.material2021(
                platform: Theme.of(context).platform,
              ),
              appBarTheme: AppBarTheme(
                backgroundColor: Global.menuBackgroundColor,
                foregroundColor: Global.menuTextColor,
              ),
              colorScheme: ColorScheme.fromSeed(
                seedColor: textColor,
                brightness: brightness,
              ),
            ),
            home: const BookshelfScreen(),
          );
        },
      ),
    );
  }
}
