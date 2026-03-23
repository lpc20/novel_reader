import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:charset_converter/charset_converter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/novel.dart';
import '../models/chapter.dart';
import '../utils/cache_manager.dart';
import '../constants/global.dart';

/// 文件服务类，处理文件操作、编码检测和章节解析
class FileService {
  static final FileService _instance = FileService._internal();
  factory FileService() => _instance;

  // 预编译正则表达式，用于章节检测
  static final List<RegExp> _chapterPatterns = [
    RegExp(r'^第[零一二三四五六七八九十百千万\d]+[章节回集卷部篇][\s\S]*?$', multiLine: true),
    RegExp(r'^[零一二三四五六七八九十百千万\d]+[、.][\s\S]*?$', multiLine: true),
    RegExp(r'^Chapter\s*\d+.*$', multiLine: true, caseSensitive: false),
  ];

  // 缓存管理器
  final CacheManager _cacheManager = CacheManager();

  FileService._internal() {
    // 注册缓存区域
    _cacheManager.registerRegion(
      CacheRegionConfig(
        name: Global.CHAPTER_CACHE_REGION,
        maxSizeBytes: Global.CHAPTER_CACHE_SIZE,
        defaultExpiry: Global.CHAPTER_CACHE_EXPIRY,
      ),
    );
    _cacheManager.registerRegion(
      CacheRegionConfig(
        name: Global.CONTENT_CACHE_REGION,
        maxSizeBytes: Global.CONTENT_CACHE_SIZE,
        defaultExpiry: Global.CONTENT_CACHE_EXPIRY,
      ),
    );
  }

  /// 检测文件编码
  Future<String> detectEncoding(String filePath) async {
    final file = File(filePath);
    final length = await file.length();

    if (length == 0) return 'UTF-8';

    final bytes = await file.readAsBytes();

    if (bytes.length < 3) return 'UTF-8';

    // 检查BOM标记
    if (bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF) {
      return 'UTF-8';
    }
    if (bytes[0] == 0xFF && bytes[1] == 0xFE) {
      return 'UTF-16LE';
    }
    if (bytes[0] == 0xFE && bytes[1] == 0xFF) {
      return 'UTF-16BE';
    }

    // 尝试UTF-8解码
    if (_isValidUtf8(bytes)) {
      try {
        utf8.decode(bytes);
        return 'UTF-8';
      } catch (_) {
        // UTF-8 解码失败，继续尝试其他编码
      }
    }

    // 尝试其他编码
    final encodings = ['GBK', 'GB18030', 'BIG5'];
    for (final encoding in encodings) {
      try {
        await CharsetConverter.decode(encoding.toLowerCase(), bytes);
        return encoding;
      } catch (_) {
        // 编码解码失败，继续尝试下一个
      }
    }

    // 默认返回UTF-8
    return 'UTF-8';
  }

  /// 验证UTF-8编码是否有效
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

  /// 读取文件内容
  Future<String> readFileContent(String filePath, String encoding) async {
    final cacheKey = '$filePath:$encoding';

    // 检查缓存
    final cachedContent = _cacheManager.get<String>(
      Global.CONTENT_CACHE_REGION,
      cacheKey,
    );
    if (cachedContent != null) {
      return cachedContent;
    }

    final file = File(filePath);
    final bytes = await file.readAsBytes();

    String content;
    try {
      switch (encoding.toUpperCase()) {
        case 'UTF-8':
          content = utf8.decode(bytes);
          break;
        case 'GBK':
          content = await CharsetConverter.decode('gbk', bytes);
          break;
        case 'GB18030':
          content = await CharsetConverter.decode('gb18030', bytes);
          break;
        case 'BIG5':
          content = await CharsetConverter.decode('big5', bytes);
          break;
        case 'UTF-16LE':
        case 'UTF-16BE':
          content = String.fromCharCodes(bytes);
          break;
        default:
          content = utf8.decode(bytes);
      }
    } catch (e) {
      content = '$encoding解码失败,小说txt已损坏';
    }

    // 缓存内容
    _cacheManager.put(Global.CONTENT_CACHE_REGION, cacheKey, content);
    return content;
  }

  /// 章节解析函数（用于 isolate）
  static List<Chapter> _parseChaptersInIsolate(String content) {
    final chapters = <Chapter>[];

    // 收集所有章节匹配
    List<RegExpMatch> allMatches = [];
    for (var pattern in _chapterPatterns) {
      allMatches.addAll(pattern.allMatches(content));
    }

    // 按位置排序
    allMatches.sort((a, b) => a.start.compareTo(b.start));

    if (allMatches.isEmpty) {
      // 没有找到章节，按固定长度分割
      const chapterLength = 3000;
      final totalLength = content.length;
      final chapterCount = (totalLength / chapterLength).ceil();

      for (int i = 0; i < chapterCount; i++) {
        final start = i * chapterLength;
        final end = (i + 1) * chapterLength > totalLength
            ? totalLength
            : (i + 1) * chapterLength;

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

      // 添加前言部分
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

      // 添加章节
      for (int i = 0; i < allMatches.length; i++) {
        final match = allMatches[i];
        final start = match.start;
        final end = (i + 1 < allMatches.length)
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

  /// 解析章节（带缓存和 isolate 优化）
  Future<List<Chapter>> parseChapters(
    String content, {
    String? cacheKey,
  }) async {
    // 检查缓存
    if (cacheKey != null) {
      final cachedChapters = _cacheManager.get<List<Chapter>>(
        Global.CHAPTER_CACHE_REGION,
        cacheKey,
      );
      if (cachedChapters != null) {
        return cachedChapters;
      }
    }

    // 使用 isolate 解析章节
    final chapters = await compute(_parseChaptersInIsolate, content);

    // 缓存结果
    if (cacheKey != null) {
      _cacheManager.put(Global.CHAPTER_CACHE_REGION, cacheKey, chapters);
    }

    return chapters;
  }

  /// 导入小说
  Future<Novel> importNovel(String filePath) async {
    final file = File(filePath);
    final fileName = filePath.split(Platform.pathSeparator).last;
    final title = fileName.replaceAll(
      RegExp(r'\.txt$', caseSensitive: false),
      '',
    );
    final fileSize = await file.length();
    final encoding = await detectEncoding(filePath);

    // 随机生成封面颜色
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

    // 创建小说目录
    final appDirectory = await getAppDirectory();
    final novelsDirectory = Directory('$appDirectory/novels');
    if (!await novelsDirectory.exists()) {
      await novelsDirectory.create(recursive: true);
    }

    // 生成唯一ID和目标路径
    final novelId = DateTime.now().millisecondsSinceEpoch.toString();
    final targetFilePath = '${novelsDirectory.path}/$novelId.txt';

    // 复制文件
    await file.copy(targetFilePath);

    // 创建小说对象
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

  /// 获取应用目录
  Future<String> getAppDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  /// 清理缓存
  void clearCache() {
    _cacheManager.clearRegion(Global.CHAPTER_CACHE_REGION);
    _cacheManager.clearRegion(Global.CONTENT_CACHE_REGION);
  }

  /// 清理指定小说的缓存
  void clearNovelCache(String novelId) {
    _cacheManager.clearNovelCache(novelId);
  }

  /// 获取缓存大小（字节）
  int getCacheSize() {
    return _cacheManager.getRegionSize(Global.CHAPTER_CACHE_REGION) +
        _cacheManager.getRegionSize(Global.CONTENT_CACHE_REGION);
  }

  /// 清理超过指定大小的缓存
  void clearCacheIfTooLarge(int maxSizeBytes) {
    final currentSize = getCacheSize();
    if (currentSize > maxSizeBytes) {
      clearCache();
    }
  }
}
