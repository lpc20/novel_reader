class Chapter {
  //章节数
  final int index;
  //章节标题
  final String title;
  //章节内容的起始位置
  final int startPosition;
  //章节内容的结束位置
  final int endPosition;

  Chapter({
    required this.index,
    required this.title,
    required this.startPosition,
    required this.endPosition,
  });

  int get length => endPosition - startPosition;

  @override
  String toString() => 'Chapter(index: $index, title: $title)';
}
