import 'dart:convert';

class Novel {
  final String id;
  final String title;
  final String filePath;
  final int fileSize;
  final String encoding;
  final DateTime addedTime;
  final DateTime? lastReadTime;
  final int totalChapters;
  final String coverColor;
  final double lastReadProgress;

  Novel({
    required this.id,
    required this.title,
    required this.filePath,
    required this.fileSize,
    required this.encoding,
    required this.addedTime,
    this.lastReadTime,
    this.totalChapters = 0,
    this.coverColor = '#4A90D9',
    this.lastReadProgress = 0.0,
  });

  Novel copyWith({
    String? id,
    String? title,
    String? filePath,
    int? fileSize,
    String? encoding,
    DateTime? addedTime,
    DateTime? lastReadTime,
    int? totalChapters,
    String? coverColor,
    double? lastReadProgress,
  }) {
    return Novel(
      id: id ?? this.id,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      encoding: encoding ?? this.encoding,
      addedTime: addedTime ?? this.addedTime,
      lastReadTime: lastReadTime ?? this.lastReadTime,
      totalChapters: totalChapters ?? this.totalChapters,
      coverColor: coverColor ?? this.coverColor,
      lastReadProgress: lastReadProgress ?? this.lastReadProgress,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'filePath': filePath,
      'fileSize': fileSize,
      'encoding': encoding,
      'addedTime': addedTime.toIso8601String(),
      'lastReadTime': lastReadTime?.toIso8601String(),
      'totalChapters': totalChapters,
      'coverColor': coverColor,
      'lastReadProgress': lastReadProgress,
    };
  }

  factory Novel.fromMap(Map<String, dynamic> map) {
    return Novel(
      id: map['id'] as String,
      title: map['title'] as String,
      filePath: map['filePath'] as String,
      fileSize: map['fileSize'] as int,
      encoding: map['encoding'] as String,
      addedTime: DateTime.parse(map['addedTime'] as String),
      lastReadTime: map['lastReadTime'] != null
          ? DateTime.parse(map['lastReadTime'] as String)
          : null,
      totalChapters: map['totalChapters'] as int? ?? 0,
      coverColor: map['coverColor'] as String? ?? '#4A90D9',
      lastReadProgress: map['lastReadProgress'] as double? ?? 0.0,
    );
  }

  String toJson() => json.encode(toMap());

  factory Novel.fromJson(String source) =>
      Novel.fromMap(json.decode(source) as Map<String, dynamic>);

  String get fileSizeFormatted {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  @override
  String toString() {
    return 'Novel(title: $title, chapters: $totalChapters, size: $fileSizeFormatted)';
  }
}
