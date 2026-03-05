# 滚动到搜索结果 - 更精确方案规划

## 当前方案问题

使用 `localToGlobal` 获取视觉位置存在以下问题：
1. 返回的是屏幕/视图层级的绝对坐标
2. CustomScrollView 的滚动 offset 是逻辑偏移（viewport 内的相对位置）
3. 两者坐标系不同，导致计算不准确

---

## 更合适的方案：缓存段落高度 + SliverList 逻辑偏移

### 核心思路

使用 Sliver 协议的**逻辑偏移**来计算位置，而不是视觉坐标：
1. **缓存每个段落的实际高度**：在段落首次渲染后记录其实际高度
2. **使用缓存高度累加**：滚动时直接累加缓存的高度来计算精确的逻辑偏移量

### 实现原理

Sliver 的滚动是基于 **SliverConstraints** 和 **SliverGeometry** 的：
- SliverList 根据滚动偏移计算哪些子项应该显示
- 每个子项的位置由其前面的所有子项高度累加决定
- 因此，直接累加缓存的高度比使用 localToGlobal 更准确

---

## 实现步骤

### 步骤1：添加高度缓存 Map

```dart
final Map<int, GlobalKey> _paragraphKeys = {};
final Map<int, double> _paragraphHeights = {};
```

### 步骤2：修改段落构建，缓存高度

```dart
Widget _buildContentWithParagraphs(...) {
  return SliverList(
    delegate: SliverChildBuilderDelegate((context, index) {
      _paragraphKeys[index] ??= GlobalKey();

      // 在首次构建后缓存高度
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_paragraphKeys[index]?.currentContext != null) {
          final box = _paragraphKeys[index]!.currentContext!.findRenderObject() as RenderBox?;
          if (box != null && box.hasSize) {
            _paragraphHeights[index] = box.size.height + 16; // 包含间距
          }
        }
      });

      return RepaintBoundary(
        key: _paragraphKeys[index],
        child: Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: RichText(text: textSpan, softWrap: true),
        ),
      );
    }, childCount: paragraphs.length),
  );
}
```

### 步骤3：使用缓存高度计算滚动位置

```dart
void _scrollToSearchResult() {
  final provider = context.read<ReaderProvider>();
  if (provider.currentSearchIndex < 0 ||
      provider.currentSearchIndex >= provider.searchResults.length) {
    return;
  }

  final result = provider.searchResults[provider.currentSearchIndex];
  final targetIndex = result.paragraphIndex;

  // 计算逻辑偏移量：累加前面所有段落的高度
  double targetPosition = 0;
  final verticalPadding = 20.0;
  final scrollViewPadding = 20.0; // CustomScrollView 的 padding

  // 累加目标段落之前的所有缓存高度
  for (int i = 0; i < targetIndex; i++) {
    final cachedHeight = _paragraphHeights[i];
    if (cachedHeight != null) {
      targetPosition += cachedHeight;
    } else {
      // 没有缓存，使用估算值作为 fallback
      final paragraph = provider.getCurrentChapterContent()[i];
      final estimatedLines = (paragraph.length / 20).ceil().toDouble();
      final lineHeight = provider.settings.fontSize * provider.settings.lineHeight;
      targetPosition += lineHeight * estimatedLines + 16;
    }
  }

  // 添加顶部 padding
  targetPosition += scrollViewPadding + verticalPadding;

  if (_scrollController.hasClients) {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final targetScroll = targetPosition - 100; // 留出顶部空间

    _scrollController.animateTo(
      targetScroll.clamp(0.0, maxScroll),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}
```

### 步骤4：优化高度缓存时机

考虑到高度缓存可能在首次滚动时还未完成，需要在滚动时强制布局：

```dart
void _scrollToSearchResult() {
  // ... 验证逻辑 ...

  final targetIndex = result.paragraphIndex;

  // 尝试直接获取目标段落的高度
  double? targetHeight;
  final key = _paragraphKeys[targetIndex];
  if (key?.currentContext != null) {
    final box = key!.currentContext!.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      targetHeight = box.size.height + 16;
      _paragraphHeights[targetIndex] = targetHeight;
    }
  }

  // 计算位置（使用缓存或估算）
  double targetPosition = 0;
  for (int i = 0; i < targetIndex; i++) {
    final cachedHeight = _paragraphHeights[i];
    if (cachedHeight != null) {
      targetPosition += cachedHeight;
    } else {
      // 估算...
      targetPosition += _estimateParagraphHeight(i, provider);
    }
  }

  // 如果目标段落高度已知，加上它的部分高度使内容可见
  if (targetHeight != null) {
    targetPosition += targetHeight * 0.3; // 让目标段落显示在偏上位置
  }

  // 添加 padding
  targetPosition += 40; // scrollView padding + 额外间距

  // ... 滚动逻辑 ...
}

double _estimateParagraphHeight(int index, ReaderProvider provider) {
  final paragraphs = provider.getCurrentChapterContent();
  if (index >= paragraphs.length) return 50;
  final paragraph = paragraphs[index];
  final estimatedLines = (paragraph.length / 20).ceil().toDouble();
  final lineHeight = provider.settings.fontSize * provider.settings.lineHeight;
  return lineHeight * estimatedLines + 16;
}
```

### 步骤5：章节切换时清理缓存

```dart
void _onChapterSelected(int index) {
  _paragraphKeys.clear();
  _paragraphHeights.clear();
  // ...
}
```

---

## 方案对比

| 维度 | localToGlobal 方案 | 缓存高度方案 |
|------|-------------------|-------------|
| 坐标系 | 视觉坐标（屏幕） | 逻辑偏移（Sliver） |
| 准确性 | 较低 | 高 |
| 复杂度 | 简单 | 中等 |
| 首次滚动 | 需要 fallback | 需要 fallback |
| 后续滚动 | 准确 | 准确 |

---

## 额外优化：强制布局获取精确高度

如果需要更精确，可以在滚动前强制布局：

```dart
void _ensureParagraphHeights() {
  for (final entry in _paragraphKeys.entries) {
    final key = entry.value;
    if (key.currentContext != null) {
      final box = key.currentContext!.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        _paragraphHeights[entry.key] = box.size.height + 16;
      }
    }
  }
}
```

然后在滚动时调用：

```dart
void _scrollToSearchResult() {
  // 强制布局更新缓存
  _ensureParagraphHeights();

  // ... 后续逻辑 ...
}
```

---

## 结论

推荐使用**缓存段落高度**方案，原因：
1. 使用 Sliver 的逻辑偏移，与滚动机制一致
2. 首次滚动可能需要 fallback，后续滚动完全精确
3. 实现复杂度适中，不需要第三方库
4. 可以与现有的 GlobalKey 方案结合使用
