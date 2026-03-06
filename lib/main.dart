import 'package:flutter/material.dart';
import 'package:novel_reader/services/bookmarks_service.dart';
import 'package:provider/provider.dart';
import 'providers/bookshelf_provider.dart';
import 'providers/reader_provider.dart';
import 'services/settings_service.dart';
import 'services/file_service.dart';
import 'screens/bookshelf_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsService().init();
  await BookmarksService().init();
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
      FileService().clearCacheIfTooLarge(50 * 1024 * 1024); // 50MB限制
      debugPrint('应用进入后台，清理缓存');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BookshelfProvider()),
        ChangeNotifierProvider(create: (_) => ReaderProvider()),
      ],
      child: MaterialApp(
        title: '小说阅读器',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          textTheme: ThemeData.light().textTheme.apply(fontFamily: '江西拙楷'),
          typography: Typography.material2021(
            platform: Theme.of(context).platform,
          ),
        ),
        home: const BookshelfScreen(),
      ),
    );
  }
}
