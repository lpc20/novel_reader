class ReadingProgress {
  //小说id
  final String novelId;
  //当前章节数
  final int chapterIndex;
  //当前滚动进度
  final double scrollProgress;

  ReadingProgress({
    required this.novelId,
    required this.chapterIndex,
    this.scrollProgress = 0.0,
  });

  ReadingProgress copyWith({
    String? novelId,
    int? chapterIndex,
    double? scrollProgress,
  }) {
    return ReadingProgress(
      novelId: novelId ?? this.novelId,
      chapterIndex: chapterIndex ?? this.chapterIndex,
      scrollProgress: scrollProgress ?? this.scrollProgress,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'novelId': novelId,
      'chapterIndex': chapterIndex,
      'scrollProgress': scrollProgress,
    };
  }

  factory ReadingProgress.fromMap(Map<String, dynamic> map) {
    return ReadingProgress(
      novelId: map['novelId'] as String,
      chapterIndex: map['chapterIndex'] as int,
      scrollProgress: map['scrollProgress'] as double? ?? 0.0,
    );
  }
}
