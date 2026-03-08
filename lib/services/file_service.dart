import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:charset_converter/charset_converter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/novel.dart';
import '../models/chapter.dart';

class FileService {
  static final FileService _instance = FileService._internal();
  factory FileService() => _instance;
  FileService._internal();

  // 预编译正则表达式
  static final List<RegExp> _chapterPatterns = [
    RegExp(r'^第[零一二三四五六七八九十百千万\d]+[章节回集卷部篇][\s\S]*?$', multiLine: true),
    RegExp(r'^[零一二三四五六七八九十百千万\d]+[、.][\s\S]*?$', multiLine: true),
    RegExp(r'^Chapter\s*\d+.*$', multiLine: true, caseSensitive: false),
  ];

  // 章节列表缓存
  final Map<String, List<Chapter>> _chapterCache = {};

  // 文件内容缓存
  final Map<String, String> _contentCache = {};

  Future<String> detectEncoding(String filePath) async {
    final file = File(filePath);
    final length = await file.length();

    if (length == 0) return 'UTF-8';

    final bytes = await file.readAsBytes();

    if (bytes.length < 3) return 'UTF-8';

    if (bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF) {
      return 'UTF-8';
    }
    if (bytes[0] == 0xFF && bytes[1] == 0xFE) {
      return 'UTF-16LE';
    }
    if (bytes[0] == 0xFE && bytes[1] == 0xFF) {
      return 'UTF-16BE';
    }

    if (_isValidUtf8(bytes)) {
      try {
        utf8.decode(bytes);
        return 'UTF-8';
      } catch (e) {
        debugPrint('UTF-8 解码验证失败: $e');
      }
    }

    try {
      await CharsetConverter.decode('gbk', bytes);
      return 'GBK';
    } catch (e) {
      debugPrint('GBK 解码验证失败: $e');
    }

    try {
      await CharsetConverter.decode('gb18030', bytes);
      return 'GB18030';
    } catch (e) {
      debugPrint('GB18030 解码验证失败: $e');
    }

    try {
      await CharsetConverter.decode('big5', bytes);
      return 'BIG5';
    } catch (e) {
      debugPrint('BIG5 解码验证失败: $e');
    }

    return 'UTF-8';
  }

  bool _isValidUtf8(Uint8List bytes) {
    int i = 0;
    while (i < bytes.length) {
      final byte = bytes[i];
      if (byte < 0x80) {
        // ASCII
        i++;
      } else if ((byte & 0xE0) == 0xC0) {
        // 2-byte sequence
        if (i + 1 >= bytes.length) return false;
        if ((bytes[i + 1] & 0xC0) != 0x80) return false;
        // Check for overlong encoding (0xC080–0xC1BF are invalid)
        if (byte == 0xC0 || byte == 0xC1) return false;
        i += 2;
      } else if ((byte & 0xF0) == 0xE0) {
        // 3-byte sequence
        if (i + 2 >= bytes.length) return false;
        if ((bytes[i + 1] & 0xC0) != 0x80 || (bytes[i + 2] & 0xC0) != 0x80) {
          return false;
        }
        // Optional: check valid Unicode range (e.g., no surrogates)
        i += 3;
      } else if ((byte & 0xF8) == 0xF0) {
        // 4-byte sequence
        if (i + 3 >= bytes.length) return false;
        if ((bytes[i + 1] & 0xC0) != 0x80 ||
            (bytes[i + 2] & 0xC0) != 0x80 ||
            (bytes[i + 3] & 0xC0) != 0x80) {
          return false;
        }
        i += 4;
      } else {
        return false; // Invalid leading byte
      }
    }
    return true;
  }

  Future<String> readFileContent(String filePath, String encoding) async {
    final cacheKey = '$filePath:$encoding';

    if (_contentCache.containsKey(cacheKey)) {
      return _contentCache[cacheKey]!;
    }

    final file = File(filePath);
    final bytes = await file.readAsBytes();

    String content;
    //debugPrint('检测到编码: $encoding');
    if (encoding.toUpperCase() == 'UTF-8') {
      content = utf8.decode(bytes);
    } else if (encoding.toUpperCase() == 'GBK') {
      try {
        content = await CharsetConverter.decode('gbk', bytes);
      } catch (e) {
        content = 'GBK解码失败,小说txt已损坏';
      }
    } else if (encoding.toUpperCase() == 'GB18030') {
      try {
        content = await CharsetConverter.decode('gb18030', bytes);
      } catch (e) {
        content = 'GB18030解码失败,小说txt已损坏';
      }
    } else if (encoding.toUpperCase() == 'BIG5') {
      try {
        content = await CharsetConverter.decode('big5', bytes);
      } catch (e) {
        content = 'BIG5解码失败,小说txt已损坏';
      }
    } else if (encoding.toUpperCase() == 'UTF-16LE') {
      content = String.fromCharCodes(bytes);
    } else if (encoding.toUpperCase() == 'UTF-16BE') {
      content = String.fromCharCodes(bytes);
    } else {
      content = utf8.decode(bytes);
    }

    _contentCache[cacheKey] = content;
    return content;
  }

  // 章节解析函数（用于 isolate）
  static List<Chapter> _parseChaptersInIsolate(String content) {
    final chapters = <Chapter>[];

    List<RegExpMatch> allMatches = [];
    for (var pattern in _chapterPatterns) {
      allMatches.addAll(pattern.allMatches(content));
    }

    allMatches.sort((a, b) => a.start.compareTo(b.start));

    if (allMatches.isEmpty) {
      int chapterLength = 3000;
      int totalLength = content.length;
      int chapterCount = (totalLength / chapterLength).ceil();

      for (int i = 0; i < chapterCount; i++) {
        int start = i * chapterLength;
        int end = (i + 1) * chapterLength;
        if (end > totalLength) end = totalLength;

        chapters.add(
          Chapter(
            index: i,
            title: '第${i + 1}节',
            startPosition: start,
            endPosition: end,
          ),
        );
      }
    } else {
      int index = 0;

      if (allMatches.first.start > 0) {
        chapters.add(
          Chapter(
            index: index,
            title: '前言',
            startPosition: 0,
            endPosition: allMatches.first.start,
          ),
        );
        index++;
      }

      for (int i = 0; i < allMatches.length; i++) {
        final match = allMatches[i];
        int start = match.start;
        int end = (i + 1 < allMatches.length)
            ? allMatches[i + 1].start
            : content.length;

        String title = content.substring(match.start, match.end).trim();
        if (title.length > 50) {
          title = '${title.substring(0, 50)}...';
        }

        chapters.add(
          Chapter(
            index: index,
            title: title,
            startPosition: start,
            endPosition: end,
          ),
        );
        index++;
      }
    }
    return chapters;
  }

  // 解析章节（带缓存和 isolate 优化）
  Future<List<Chapter>> parseChapters(
    String content, {
    String? cacheKey,
  }) async {
    // 检查缓存
    if (cacheKey != null && _chapterCache.containsKey(cacheKey)) {
      return _chapterCache[cacheKey]!;
    }

    // 使用 isolate 解析章节
    final chapters = await compute(_parseChaptersInIsolate, content);

    // 缓存结果
    if (cacheKey != null) {
      _chapterCache[cacheKey] = chapters;
    }

    return chapters;
  }

  Future<Novel> importNovel(String filePath) async {
    final file = File(filePath);
    final fileName = filePath.split(Platform.pathSeparator).last;
    final title = fileName.replaceAll(
      RegExp(r'\.txt$', caseSensitive: false),
      '',
    );
    final fileSize = await file.length();
    final encoding = await detectEncoding(filePath);

    final colors = [
      '#4A90D9',
      '#E74C3C',
      '#2ECC71',
      '#9B59B6',
      '#F39C12',
      '#1ABC9C',
      '#34495E',
    ];
    final coverColor = colors[Random().nextInt(colors.length)];

    final appDirectory = await getAppDirectory();
    final novelsDirectory = Directory('$appDirectory/novels');
    if (!await novelsDirectory.exists()) {
      await novelsDirectory.create(recursive: true);
    }

    final novelId = DateTime.now().millisecondsSinceEpoch.toString();
    final targetFilePath = '${novelsDirectory.path}/$novelId.txt';

    await file.copy(targetFilePath);

    return Novel(
      id: novelId,
      title: title,
      filePath: targetFilePath,
      fileSize: fileSize,
      encoding: encoding,
      addedTime: DateTime.now(),
      coverColor: coverColor,
    );
  }

  Future<String> getAppDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  // 清理缓存
  void clearCache() {
    _chapterCache.clear();
    _contentCache.clear();
    debugPrint('缓存已清理');
  }

  // 清理指定小说的缓存
  void clearNovelCache(String novelId) {
    // 清理章节缓存
    _chapterCache.remove(novelId);
    // 清理内容缓存（通过匹配novelId）
    _contentCache.removeWhere((key, value) => key.contains(novelId));
    debugPrint('小说 $novelId 的缓存已清理');
  }

  // 获取缓存大小
  int getCacheSize() {
    int size = 0;
    // 计算章节缓存大小
    for (var chapters in _chapterCache.values) {
      size += chapters.length * 100; // 估算每个章节对象大小
    }
    // 计算内容缓存大小
    for (var content in _contentCache.values) {
      size += content.length * 2; // 估算每个字符2字节
    }
    return size;
  }

  // 清理超过指定大小的缓存
  void clearCacheIfTooLarge(int maxSizeBytes) {
    final currentSize = getCacheSize();
    if (currentSize > maxSizeBytes) {
      clearCache();
      debugPrint('缓存大小超过限制，已清理');
    }
  }
}
