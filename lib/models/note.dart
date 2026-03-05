class Note {
  final String id;
  final String novelId;
  final int chapterIndex;
  final String chapterTitle;
  final double scrollProgress;
  final String content;
  final String noteText;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note({
    required this.id,
    required this.novelId,
    required this.chapterIndex,
    required this.chapterTitle,
    required this.scrollProgress,
    required this.content,
    required this.noteText,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'novelId': novelId,
      'chapterIndex': chapterIndex,
      'chapterTitle': chapterTitle,
      'scrollProgress': scrollProgress,
      'content': content,
      'noteText': noteText,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as String,
      novelId: map['novelId'] as String,
      chapterIndex: map['chapterIndex'] as int,
      chapterTitle: map['chapterTitle'] as String,
      scrollProgress: map['scrollProgress'] as double,
      content: map['content'] as String,
      noteText: map['noteText'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}
