import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/bookmark.dart';
import '../models/note.dart';

class BookmarksService {
  static final BookmarksService _instance = BookmarksService._internal();
  factory BookmarksService() => _instance;
  BookmarksService._internal();

  List<Bookmark> _bookmarks = [];
  List<Note> _notes = [];
  String? _dataPath;

  Future<void> init() async {
    final directory = await getApplicationDocumentsDirectory();
    _dataPath = directory.path;
    await _loadBookmarks();
    await _loadNotes();
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
      } catch (e) {
        debugPrint('加载书签失败: $e');
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
    } catch (e) {
      debugPrint('保存书签失败: $e');
    }
  }

  Future<void> _loadNotes() async {
    final file = File('$_dataPath/notes.json');
    if (await file.exists()) {
      try {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          final List<dynamic> jsonList = json.decode(content);
          _notes = jsonList.map((json) => Note.fromMap(json)).toList();
        } else {
          _notes = [];
        }
      } catch (e) {
        debugPrint('加载笔记失败: $e');
        _notes = [];
      }
    } else {
      _notes = [];
    }
  }

  Future<void> _saveNotes() async {
    final file = File('$_dataPath/notes.json');
    try {
      final jsonList = _notes.map((note) => note.toMap()).toList();
      await file.writeAsString(json.encode(jsonList));
    } catch (e) {
      debugPrint('保存笔记失败: $e');
    }
  }

  List<Bookmark> getBookmarks(String novelId) {
    return _bookmarks.where((bookmark) => bookmark.novelId == novelId).toList();
  }

  List<Note> getNotes(String novelId) {
    return _notes.where((note) => note.novelId == novelId).toList();
  }

  Future<void> addBookmark(Bookmark bookmark) async {
    _bookmarks.add(bookmark);
    await _saveBookmarks();
  }

  Future<void> removeBookmark(String bookmarkId) async {
    _bookmarks.removeWhere((bookmark) => bookmark.id == bookmarkId);
    await _saveBookmarks();
  }

  Future<void> addNote(Note note) async {
    _notes.add(note);
    await _saveNotes();
  }

  Future<void> updateNote(Note note) async {
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index >= 0) {
      _notes[index] = note;
      await _saveNotes();
    }
  }

  Future<void> removeNote(String noteId) async {
    _notes.removeWhere((note) => note.id == noteId);
    await _saveNotes();
  }

  Future<void> removeAllBookmarks(String novelId) async {
    _bookmarks.removeWhere((bookmark) => bookmark.novelId == novelId);
    await _saveBookmarks();
  }

  Future<void> removeAllNotes(String novelId) async {
    _notes.removeWhere((note) => note.novelId == novelId);
    await _saveNotes();
  }
}
