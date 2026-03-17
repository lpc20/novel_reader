import '../models/novel.dart';
import '../models/reading_progress.dart';
import 'bookshelf_service.dart';
import 'file_service.dart';

/// 书架领域仓库：聚合文件导入、章节解析和书架持久化等操作。
class BookshelfRepository {
  BookshelfRepository({
    BookshelfService? bookshelfService,
    FileService? fileService,
  })  : _bookshelfService = bookshelfService ?? BookshelfService(),
        _fileService = fileService ?? FileService();

  final BookshelfService _bookshelfService;
  final FileService _fileService;

  List<Novel> get novels => _bookshelfService.novels;

  Future<Novel> importAndPersistNovel(String filePath) async {
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
    return updatedNovel;
  }

  Future<void> removeNovel(String novelId) {
    return _bookshelfService.removeNovel(novelId);
  }

  Future<void> updateLastReadTime(String novelId) {
    return _bookshelfService.updateLastReadTime(novelId);
  }

  Novel? getNovel(String novelId) {
    return _bookshelfService.getNovel(novelId);
  }

  ReadingProgress? getProgress(String novelId) {
    return _bookshelfService.getProgress(novelId);
  }

  Future<void> saveProgress(ReadingProgress progress) {
    return _bookshelfService.saveProgress(progress);
  }

  List<Novel> getRecentNovels({int limit = 10}) {
    return _bookshelfService.getRecentNovels(limit: limit);
  }
}

