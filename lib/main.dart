import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'constants/global.dart';
import 'providers/bookshelf_view_model.dart';
import 'providers/reader_view_model.dart';
import 'services/app_initializer.dart';
import 'utils/color_utils.dart';
import 'utils/cache_manager.dart';
import 'screens/bookshelf_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 初始化颜色缓存
  ColorUtils.init();
  // 启动时清理缓存
  CacheManager().clearAllCachesIfTooLarge();
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
      // 应用进入后台时清理所有缓存
      CacheManager().clearAllCachesIfTooLarge();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BookshelfViewModel()),
        ChangeNotifierProvider(create: (_) => ReaderViewModel()),
      ],
      child: Builder(
        builder: (context) {
          return MaterialApp(
            title: '墨读',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              scaffoldBackgroundColor: Colors.white,
              textTheme: ThemeData.light().textTheme.apply(
                fontFamily: 'OPPOSans',
              ),
              typography: Typography.material2021(
                platform: Theme.of(context).platform,
              ),
              appBarTheme: AppBarTheme(
                backgroundColor: Global.menuBackgroundColor,
                foregroundColor: Global.menuTextColor,
              ),
            ),
            home: const BookshelfScreen(),
          );
        },
      ),
    );
  }
}
