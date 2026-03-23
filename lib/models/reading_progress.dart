class ReadingProgress {
  //小说id
  final String novelId;
  //当前章节数
  final int chapterIndex;
  //当前章节内阅读进度
  final double progressInChapter;

  ReadingProgress({
    required this.novelId,
    required this.chapterIndex,
    this.progressInChapter = 0.0,
  });

  ReadingProgress copyWith({
    String? novelId,
    int? chapterIndex,
    double? progressInChapter,
  }) {
    return ReadingProgress(
      novelId: novelId ?? this.novelId,
      chapterIndex: chapterIndex ?? this.chapterIndex,
      progressInChapter: progressInChapter ?? this.progressInChapter,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'novelId': novelId,
      'chapterIndex': chapterIndex,
      'progressInChapter': progressInChapter,
    };
  }

  factory ReadingProgress.fromMap(Map<String, dynamic> map) {
    return ReadingProgress(
      novelId: map['novelId'] as String,
      chapterIndex: map['chapterIndex'] as int,
      progressInChapter: map['progressInChapter'] as double? ?? 0.0,
    );
  }
}
