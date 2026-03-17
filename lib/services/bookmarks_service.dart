import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/bookmark.dart';

class BookmarksService {
  static final BookmarksService _instance = BookmarksService._internal();
  factory BookmarksService() => _instance;
  BookmarksService._internal();

  List<Bookmark> _bookmarks = [];
  String? _dataPath;

  Future<void> init() async {
    final directory = await getApplicationDocumentsDirectory();
    _dataPath = directory.path;
    await _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final file = File('$_dataPath/bookmarks.json');
    if (await file.exists()) {
      try {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          final List<dynamic> jsonList = json.decode(content);
          _bookmarks = jsonList.map((json) => Bookmark.fromMap(json)).toList();
        } else {
          _bookmarks = [];
        }
      } catch (_) {
        _bookmarks = [];
      }
    } else {
      _bookmarks = [];
    }
  }

  Future<void> _saveBookmarks() async {
    final file = File('$_dataPath/bookmarks.json');
    try {
      final jsonList = _bookmarks.map((bookmark) => bookmark.toMap()).toList();
      await file.writeAsString(json.encode(jsonList));
    } catch (_) {
      // 保存失败静默处理
    }
  }

  List<Bookmark> getBookmarks(String novelId) {
    return _bookmarks.where((bookmark) => bookmark.novelId == novelId).toList();
  }

  Future<void> addBookmark(Bookmark bookmark) async {
    _bookmarks.add(bookmark);
    await _saveBookmarks();
  }

  Future<void> removeBookmark(String bookmarkId) async {
    _bookmarks.removeWhere((bookmark) => bookmark.id == bookmarkId);
    await _saveBookmarks();
  }

  Future<void> removeAllBookmarks(String novelId) async {
    _bookmarks.removeWhere((bookmark) => bookmark.novelId == novelId);
    await _saveBookmarks();
  }
}
