class Bookmark {
  final String id;
  final String novelId;
  final int chapterIndex;
  final String chapterTitle;
  final double progressInChapter;
  final String contentPreview;
  final DateTime createdAt;

  Bookmark({
    required this.id,
    required this.novelId,
    required this.chapterIndex,
    required this.chapterTitle,
    required this.progressInChapter,
    required this.contentPreview,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'novelId': novelId,
      'chapterIndex': chapterIndex,
      'chapterTitle': chapterTitle,
      'progressInChapter': progressInChapter,
      'contentPreview': contentPreview,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Bookmark.fromMap(Map<String, dynamic> map) {
    return Bookmark(
      id: map['id'] as String,
      novelId: map['novelId'] as String,
      chapterIndex: map['chapterIndex'] as int,
      chapterTitle: map['chapterTitle'] as String,
      progressInChapter: map['progressInChapter'] as double,
      contentPreview: map['contentPreview'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
