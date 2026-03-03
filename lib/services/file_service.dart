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

  // Future<String> detectEncoding(String filePath) async {
  //   final file = File(filePath);
  //   final bytes = await file.readAsBytes();

  //   if (bytes.length < 3) return 'UTF-8';

  //   if (bytes[0] == 0xFF && bytes[1] == 0xFE) {
  //     return 'UTF-16LE';
  //   }
  //   if (bytes[0] == 0xFE && bytes[1] == 0xFF) {
  //     return 'UTF-16BE';
  //   }
  //   if (bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF) {
  //     return 'UTF-8';
  //   }
  //   bool isUtf8 = true;
  //   int i = 0;
  //   while (i < bytes.length && i < 10000) {
  //     int byte = bytes[i];
  //     if (byte < 0x80) {
  //       i++;
  //       continue;
  //     }
  //     int seqLen;
  //     if ((byte & 0xE0) == 0xC0) {
  //       seqLen = 2;
  //     } else if ((byte & 0xF0) == 0xE0) {
  //       seqLen = 3;
  //     } else if ((byte & 0xF8) == 0xF0) {
  //       seqLen = 4;
  //     } else {
  //       isUtf8 = false;
  //       break;
  //     }
  //     if (i + seqLen > bytes.length) {
  //       isUtf8 = false;
  //       break;
  //     }
  //     for (int j = 1; j < seqLen; j++) {
  //       if ((bytes[i + j] & 0xC0) != 0x80) {
  //         isUtf8 = false;
  //         break;
  //       }
  //     }
  //     if (!isUtf8) break;
  //     i += seqLen;
  //   }
  //   if (isUtf8) return 'UTF-8';
  //   return 'GBK';
  // }

  Future<String> detectEncoding(String filePath) async {
    final file = File(filePath);
    final length = await file.length();

    if (length == 0) return 'UTF-8';

    // 只读前 32KB（足够检测 BOM 和 UTF-8 结构）
    final readLength = min(length, 32 * 1024);
    final stream = file.openRead(0, readLength);
    // 合并所有 chunk 为 Uint8List
    final chunks = await stream.toList();
    final bytes = Uint8List(chunks.fold(0, (sum, chunk) => sum + chunk.length));
    int offset = 0;
    for (final chunk in chunks) {
      bytes.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    // 1. 检查 BOM
    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      return 'UTF-8';
    }
    if (bytes.length >= 2) {
      if (bytes[0] == 0xFF && bytes[1] == 0xFE) return 'UTF-16LE';
      if (bytes[0] == 0xFE && bytes[1] == 0xFF) return 'UTF-16BE';
    }

    // 2. 尝试 UTF-8 合法性检测
    if (_isValidUtf8(bytes)) {
      return 'UTF-8';
    }

    // 3. 回退到 GBK（中文小说场景合理）
    return 'GBK';
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
    // 生成缓存键（文件路径 + 编码）
    final cacheKey = '$filePath:$encoding';

    // 检查缓存
    if (_contentCache.containsKey(cacheKey)) {
      return _contentCache[cacheKey]!;
    }

    final file = File(filePath);
    final bytes = await file.readAsBytes();

    String content;
    if (encoding.toUpperCase() == 'UTF-8') {
      content = utf8.decode(bytes);
    } else if (encoding.toUpperCase() == 'GBK') {
      try {
        content = await CharsetConverter.decode('gbk', bytes);
      } catch (e) {
        content = 'GBK解码失败,小说txt已损坏';
      }
    } else if (encoding.toUpperCase() == 'UTF-16LE') {
      content = String.fromCharCodes(bytes);
    } else if (encoding.toUpperCase() == 'UTF-16BE') {
      content = String.fromCharCodes(bytes);
    } else {
      content = utf8.decode(bytes);
    }

    // 缓存结果
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
            index: i,
            title: title,
            startPosition: start,
            endPosition: end,
          ),
        );
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
}
