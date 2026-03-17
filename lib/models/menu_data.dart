class MenuData {
  final int currentChapterIndex;
  final int chaptersLength;
  final double fontSize;
  final double lineHeight;
  final String fontFamily;
  final int themeIndex;

  const MenuData({
    required this.currentChapterIndex,
    required this.chaptersLength,
    required this.fontSize,
    required this.lineHeight,
    required this.fontFamily,
    required this.themeIndex,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MenuData &&
        other.currentChapterIndex == currentChapterIndex &&
        other.chaptersLength == chaptersLength &&
        other.fontSize == fontSize &&
        other.lineHeight == lineHeight &&
        other.fontFamily == fontFamily &&
        other.themeIndex == themeIndex;
  }

  @override
  int get hashCode => Object.hash(
    currentChapterIndex,
    chaptersLength,
    fontSize,
    lineHeight,
    fontFamily,
    themeIndex,
  );
}
