import '../models/bookmark.dart';
import '../models/chapter.dart';
import '../models/novel.dart';
import '../models/reading_progress.dart';
import 'bookmarks_service.dart';
import 'bookshelf_service.dart';
import 'file_service.dart';

/// 阅读领域仓库：封装文件读取、章节解析、进度和书签相关 IO 逻辑。
class ReaderRepository {
  ReaderRepository({
    FileService? fileService,
    BookshelfService? bookshelfService,
    BookmarksService? bookmarksService,
  }) : _fileService = fileService ?? FileService(),
       _bookshelfService = bookshelfService ?? BookshelfService(),
       _bookmarksService = bookmarksService ?? BookmarksService();

  final FileService _fileService;
  final BookshelfService _bookshelfService;
  final BookmarksService _bookmarksService;

  Future<String> loadContent({
    required String filePath,
    required String encoding,
  }) {
    return _fileService.readFileContent(filePath, encoding);
  }

  Future<List<Chapter>> parseChapters({
    required String content,
    required String cacheKey,
  }) {
    return _fileService.parseChapters(content, cacheKey: cacheKey);
  }

  ReadingProgress? getProgress(String novelId) {
    return _bookshelfService.getProgress(novelId);
  }

  Future<void> saveProgress(ReadingProgress progress) {
    return _bookshelfService.saveProgress(progress);
  }

  Future<void> updateLastReadTime(String novelId) {
    return _bookshelfService.updateLastReadTime(novelId);
  }

  Novel? getNovel(String novelId) {
    return _bookshelfService.getNovel(novelId);
  }

  Future<void> updateNovel(Novel novel) {
    return _bookshelfService.updateNovel(novel);
  }

  Future<void> addBookmark(Bookmark bookmark) {
    return _bookmarksService.addBookmark(bookmark);
  }

  Future<void> removeBookmark(String bookmarkId) {
    return _bookmarksService.removeBookmark(bookmarkId);
  }

  List<Bookmark> getBookmarks(String novelId) {
    return _bookmarksService.getBookmarks(novelId);
  }
}
