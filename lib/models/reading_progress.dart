class ReadingProgress {
  //小说id
  final String novelId;
  //当前章节数
  final int chapterIndex;
  //当前位置在章节中的字节数
  final int positionInChapter;
  //当前滚动进度
  final double scrollProgress;

  ReadingProgress({
    required this.novelId,
    required this.chapterIndex,
    required this.positionInChapter,
    this.scrollProgress = 0.0,
  });

  ReadingProgress copyWith({
    String? novelId,
    int? chapterIndex,
    int? positionInChapter,
    double? scrollProgress,
  }) {
    return ReadingProgress(
      novelId: novelId ?? this.novelId,
      chapterIndex: chapterIndex ?? this.chapterIndex,
      positionInChapter: positionInChapter ?? this.positionInChapter,
      scrollProgress: scrollProgress ?? this.scrollProgress,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'novelId': novelId,
      'chapterIndex': chapterIndex,
      'positionInChapter': positionInChapter,
      'scrollProgress': scrollProgress,
    };
  }

  factory ReadingProgress.fromMap(Map<String, dynamic> map) {
    return ReadingProgress(
      novelId: map['novelId'] as String,
      chapterIndex: map['chapterIndex'] as int,
      positionInChapter: map['positionInChapter'] as int,
      scrollProgress: map['scrollProgress'] as double? ?? 0.0,
    );
  }
}
