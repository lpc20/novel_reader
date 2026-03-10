class Chapter {
  final int index;
  final String title;
  final int startPosition;
  final int endPosition;

  int get length => endPosition - startPosition;

  Chapter({
    required this.index,
    required this.title,
    required this.startPosition,
    required this.endPosition,
  });



  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Chapter &&
        other.index == index &&
        other.title == title &&
        other.startPosition == startPosition &&
        other.endPosition == endPosition;
  }

  @override
  int get hashCode => Object.hash(index, title, startPosition, endPosition);

  @override
  String toString() => 'Chapter(index: $index, title: $title)';
}
