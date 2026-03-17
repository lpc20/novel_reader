import 'package:flutter/material.dart';
import '../models/novel.dart';
import '../models/reading_progress.dart';
import '../services/bookshelf_repository.dart';

enum SortType { byAddTime, byTitle, byFileSize, byLastRead }

class BookshelfViewModel extends ChangeNotifier {
  final BookshelfRepository _repository;

  BookshelfViewModel({BookshelfRepository? repository})
      : _repository = repository ?? BookshelfRepository();

  List<Novel> get novels => _sortedNovels;
  bool _isLoading = false;
  String? _error;
  SortType _currentSortType = SortType.byAddTime;

  bool get isLoading => _isLoading;
  String? get error => _error;
  SortType get currentSortType => _currentSortType;

  List<Novel> get _sortedNovels {
    final novels = _repository.novels;
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
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> importNovel(String filePath) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.importAndPersistNovel(filePath);
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
    await _repository.removeNovel(novelId);
    notifyListeners();
  }

  Future<void> updateLastReadTime(String novelId) async {
    await _repository.updateLastReadTime(novelId);
    notifyListeners();
  }

  Novel? getNovel(String novelId) {
    return _repository.getNovel(novelId);
  }

  ReadingProgress? getProgress(String novelId) {
    return _repository.getProgress(novelId);
  }

  Future<void> saveProgress(ReadingProgress progress) async {
    await _repository.saveProgress(progress);
  }

  void setSortType(SortType type) {
    _currentSortType = type;
    notifyListeners();
  }
}
