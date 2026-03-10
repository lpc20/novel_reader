import 'package:flutter/foundation.dart';
import '../models/chapter.dart';
import '../services/settings_service.dart';
import '../providers/reader_provider.dart';

class ReaderScreenData {
  final ReadingSettings settings;
  final List<String> paragraphs;
  final bool isLoading;
  final int currentChapterIndex;
  final List<Chapter> chapters;
  final String searchQuery;
  final List<SearchResult> searchResults;
  final int currentSearchIndex;

  const ReaderScreenData({
    required this.settings,
    required this.paragraphs,
    required this.isLoading,
    required this.currentChapterIndex,
    required this.chapters,
    required this.searchQuery,
    required this.searchResults,
    required this.currentSearchIndex,
  });

  ReaderScreenData copyWith({
    ReadingSettings? settings,
    List<String>? paragraphs,
    bool? isLoading,
    int? currentChapterIndex,
    List<Chapter>? chapters,
    String? searchQuery,
    List<SearchResult>? searchResults,
    int? currentSearchIndex,
  }) {
    return ReaderScreenData(
      settings: settings ?? this.settings,
      paragraphs: paragraphs ?? this.paragraphs,
      isLoading: isLoading ?? this.isLoading,
      currentChapterIndex: currentChapterIndex ?? this.currentChapterIndex,
      chapters: chapters ?? this.chapters,
      searchQuery: searchQuery ?? this.searchQuery,
      searchResults: searchResults ?? this.searchResults,
      currentSearchIndex: currentSearchIndex ?? this.currentSearchIndex,
    );
  }

  factory ReaderScreenData.fromProvider(ReaderProvider provider) {
    return ReaderScreenData(
      settings: provider.settings,
      paragraphs: provider.getCurrentChapterContent(),
      isLoading: provider.isLoading,
      currentChapterIndex: provider.currentChapterIndex,
      chapters: provider.chapters,
      searchQuery: provider.searchQuery,
      searchResults: provider.searchResults,
      currentSearchIndex: provider.currentSearchIndex,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReaderScreenData &&
        other.settings == settings &&
        listEquals(other.paragraphs, paragraphs) &&
        other.isLoading == isLoading &&
        other.currentChapterIndex == currentChapterIndex &&
        listEquals(other.chapters, chapters) &&
        other.searchQuery == searchQuery &&
        listEquals(other.searchResults, searchResults) &&
        other.currentSearchIndex == currentSearchIndex;
  }

  @override
  int get hashCode => Object.hash(
    settings,
    paragraphs,
    isLoading,
    currentChapterIndex,
    chapters,
    searchQuery,
    searchResults,
    currentSearchIndex,
  );
}

class SearchResult {
  final int paragraphIndex;
  final int startIndex;
  final int endIndex;

  const SearchResult({
    required this.paragraphIndex,
    required this.startIndex,
    required this.endIndex,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchResult &&
        other.paragraphIndex == paragraphIndex &&
        other.startIndex == startIndex &&
        other.endIndex == endIndex;
  }

  @override
  int get hashCode => Object.hash(paragraphIndex, startIndex, endIndex);
}
