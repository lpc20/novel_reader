import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:novel_reader/constants/app_constants.dart';
import 'package:path_provider/path_provider.dart';
import '../models/novel.dart';
import '../models/reading_progress.dart';
import '../utils/debouncer.dart';

class BookshelfService {
  static final BookshelfService _instance = BookshelfService._internal();
  factory BookshelfService() => _instance;
  BookshelfService._internal();

  List<Novel> _novels = [];
  Map<String, ReadingProgress> _progressMap = {};
  String? _dataPath;
  final _progressDebouncer = Debouncer(delay: AppConstants.debounceDelay);
  final _novelsDebouncer = Debouncer(delay: AppConstants.debounceDelay);

  List<Novel> get novels => List.unmodifiable(_novels);

  Future<void> init() async {
    final directory = await getApplicationDocumentsDirectory();
    _dataPath = directory.path;
    await _loadNovels();
    await _loadProgress();
  }

  Future<void> _loadNovels() async {
    final file = File('$_dataPath/novels.json');
    if (await file.exists()) {
      try {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          final List<dynamic> jsonList = json.decode(content);
          _novels = jsonList.map((json) => Novel.fromMap(json)).toList();
        }
      } catch (e) {
        debugPrint('加载小说列表失败: $e');
        // 如果解析失败，重置为空列表
        _novels = [];
      }
    }
  }

  Future<void> _saveNovels() async {
    final file = File('$_dataPath/novels.json');
    try {
      final jsonList = _novels.map((novel) => novel.toMap()).toList();
      await file.writeAsString(json.encode(jsonList));
    } catch (e) {
      debugPrint('保存小说列表失败: $e');
    }
  }

  void _debouncedSaveNovels() {
    _novelsDebouncer.run(() {
      _saveNovels();
    });
  }

  Future<void> _loadProgress() async {
    final file = File('$_dataPath/progress.json');
    if (await file.exists()) {
      try {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          final Map<String, dynamic> jsonMap = json.decode(content);
          _progressMap = jsonMap.map(
            (key, value) => MapEntry(key, ReadingProgress.fromMap(value)),
          );
        }
      } catch (e) {
        debugPrint('加载阅读进度失败: $e');
        // 如果解析失败，重置为空映射
        _progressMap = {};
      }
    }
  }

  Future<void> _saveProgress() async {
    final file = File('$_dataPath/progress.json');
    try {
      final jsonMap = _progressMap.map(
        (key, value) => MapEntry(key, value.toMap()),
      );
      await file.writeAsString(json.encode(jsonMap));
    } catch (e) {
      debugPrint('保存阅读进度失败: $e');
    }
  }

  Future<void> addNovel(Novel novel) async {
    final existingIndex = _novels.indexWhere(
      (n) => n.filePath == novel.filePath,
    );
    if (existingIndex >= 0) {
      _novels[existingIndex] = novel;
    } else {
      _novels.insert(0, novel);
    }
    _debouncedSaveNovels();
  }

  Future<void> removeNovel(String novelId) async {
    final novel = getNovel(novelId);
    if (novel != null) {
      try {
        final file = File(novel.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('删除文件失败: $e');
      }
    }

    _novels.removeWhere((novel) => novel.id == novelId);
    _progressMap.remove(novelId);
    _debouncedSaveNovels();
    _progressDebouncer.run(() {
      _saveProgress();
    });
  }

  Future<void> updateNovel(Novel novel) async {
    final index = _novels.indexWhere((n) => n.id == novel.id);
    if (index >= 0) {
      _novels[index] = novel;
      _debouncedSaveNovels();
    }
  }

  Novel? getNovel(String novelId) {
    try {
      return _novels.firstWhere((novel) => novel.id == novelId);
    } catch (e) {
      return null;
    }
  }

  ReadingProgress? getProgress(String novelId) {
    return _progressMap[novelId];
  }

  Future<void> saveProgress(ReadingProgress progress) async {
    _progressMap[progress.novelId] = progress;
    _progressDebouncer.run(() {
      _saveProgress();
    });
  }

  Future<void> updateLastReadTime(String novelId) async {
    final index = _novels.indexWhere((n) => n.id == novelId);
    if (index >= 0) {
      _novels[index] = _novels[index].copyWith(lastReadTime: DateTime.now());
      _debouncedSaveNovels();
    }
  }

  List<Novel> getRecentNovels({int limit = 10}) {
    final sortedNovels = _novels.where((n) => n.lastReadTime != null).toList();
    sortedNovels.sort(
      (a, b) => (b.lastReadTime ?? DateTime(1970)).compareTo(
        a.lastReadTime ?? DateTime(1970),
      ),
    );
    return sortedNovels.take(limit).toList();
  }
}
