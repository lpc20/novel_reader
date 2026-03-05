import 'package:flutter/material.dart';
import '../models/novel.dart';
import '../models/reading_progress.dart';
import '../services/bookshelf_service.dart';
import '../services/file_service.dart';

enum SortType { byAddTime, byTitle, byFileSize, byLastRead }

class BookshelfProvider extends ChangeNotifier {
  final BookshelfService _bookshelfService = BookshelfService();
  final FileService _fileService = FileService();

  List<Novel> get novels => _sortedNovels;
  bool _isLoading = false;
  String? _error;
  SortType _currentSortType = SortType.byAddTime;

  bool get isLoading => _isLoading;
  String? get error => _error;
  SortType get currentSortType => _currentSortType;

  List<Novel> get _sortedNovels {
    final novels = _bookshelfService.novels;
    switch (_currentSortType) {
      case SortType.byAddTime:
        return List.from(novels); // 保持原始顺序（添加时间）
      case SortType.byTitle:
        return List.from(novels)..sort((a, b) => a.title.compareTo(b.title));
      case SortType.byFileSize:
        return List.from(novels)
          ..sort((a, b) => b.fileSize.compareTo(a.fileSize));
      case SortType.byLastRead:
        return List.from(novels)..sort(
          (a, b) => (b.lastReadTime ?? DateTime(1970)).compareTo(
            a.lastReadTime ?? DateTime(1970),
          ),
        );
    }
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _bookshelfService.init();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> importNovel(String filePath) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final novel = await _fileService.importNovel(filePath);
      final content = await _fileService.readFileContent(
        novel.filePath,
        novel.encoding,
      );
      final chapters = await _fileService.parseChapters(
        content,
        cacheKey: novel.id,
      );

      final updatedNovel = novel.copyWith(totalChapters: chapters.length);
      await _bookshelfService.addNovel(updatedNovel);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> removeNovel(String novelId) async {
    await _bookshelfService.removeNovel(novelId);
    notifyListeners();
  }

  Future<void> updateLastReadTime(String novelId) async {
    await _bookshelfService.updateLastReadTime(novelId);
    notifyListeners();
  }

  Novel? getNovel(String novelId) {
    return _bookshelfService.getNovel(novelId);
  }

  ReadingProgress? getProgress(String novelId) {
    return _bookshelfService.getProgress(novelId);
  }

  Future<void> saveProgress(ReadingProgress progress) async {
    await _bookshelfService.saveProgress(progress);
  }

  void setSortType(SortType type) {
    _currentSortType = type;
    notifyListeners();
  }
}
