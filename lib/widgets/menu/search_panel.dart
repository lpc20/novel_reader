import 'package:flutter/material.dart';
import 'package:novel_reader/constants/global.dart';

class SearchPanel extends StatelessWidget {
  final TextEditingController searchController;
  final VoidCallback onSearch;
  final bool hasSearchResults;
  final int currentSearchIndex;
  final int searchResultsLength;
  final VoidCallback onPreviousResult;
  final VoidCallback onNextResult;

  const SearchPanel({
    super.key,
    required this.searchController,
    required this.onSearch,
    required this.hasSearchResults,
    required this.currentSearchIndex,
    required this.searchResultsLength,
    required this.onPreviousResult,
    required this.onNextResult,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(24),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: '搜索',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              prefixIcon: const Icon(Icons.search, size: 16),
            ),
            onSubmitted: (_) => onSearch(),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Visibility(
                visible: hasSearchResults,
                child: TextButton.icon(
                  icon: const Icon(Icons.chevron_left, size: 16),
                  label: const Text('上一个'),
                  style: TextButton.styleFrom(
                    foregroundColor: Global.menuTextColor,
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: hasSearchResults
                      ? () {
                          onPreviousResult();
                          onSearch();
                        }
                      : null,
                ),
              ),
              Visibility(
                visible: hasSearchResults,
                child: Text(
                  hasSearchResults
                      ? '${currentSearchIndex + 1}/${searchResultsLength}'
                      : '无结果',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Global.menuTextColor,
                  ),
                ),
              ),
              Visibility(
                visible: hasSearchResults,
                child: TextButton.icon(
                  icon: const Icon(Icons.chevron_right, size: 16),
                  iconAlignment: IconAlignment.end,
                  label: const Text('下一个'),
                  style: TextButton.styleFrom(
                    foregroundColor: Global.menuTextColor,
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: hasSearchResults
                      ? () {
                          onNextResult();
                          onSearch();
                        }
                      : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
