# 小说阅读器 - UI问题修复计划

## 问题分析

经过代码分析，发现以下三个问题：

1. **段落前的空格缩进消失**：在 `reader_provider.dart` 的 `getCurrentChapterContent` 方法中，使用了 `p.trim().isNotEmpty` 来过滤空段落，这会移除段落前的空格缩进。

2. **设置面板切换时菜单闪烁跳动**：在 `reader_provider.dart` 中，每次设置更新都会调用 `notifyListeners()`，这会触发整个菜单的重建，导致闪烁跳动。

3. **书签功能异常**：在 `bookmarks_service.dart` 中，`_loadBookmarks` 和 `_loadNotes` 方法只在文件存在时才加载数据，但没有在文件不存在时初始化空列表，这可能导致初始时书签功能异常。

## 修复计划

### [ ] 任务1：修复段落空格缩进问题
- **优先级**：P0
- **依赖**：None
- **描述**：
  - 修改 `reader_provider.dart` 中的 `getCurrentChapterContent` 方法
  - 替换 `p.trim().isNotEmpty` 为 `p.isNotEmpty`，保留段落前的空格缩进

- **成功标准**：
  - 小说段落前的空格缩进能够正确显示
  - 空段落被正确过滤

- **测试要求**：
  - `programmatic` TR-1.1: 段落前的空格缩进在阅读界面中正确显示
  - `human-judgement` TR-1.2: 阅读界面中的段落排版符合预期

### [ ] 任务2：修复设置面板闪烁跳动问题
- **优先级**：P0
- **依赖**：None
- **描述**：
  - 分析 `reader_menu.dart` 中的 `_MenuData` 类
  - 确保只有真正需要更新的设置才会触发菜单重建
  - 优化 `ReaderProvider` 中的设置更新方法，避免不必要的 `notifyListeners()` 调用

- **成功标准**：
  - 切换字体、字号和行距等设置时，菜单不再闪烁跳动
  - 设置变更能够正确应用到阅读界面

- **测试要求**：
  - `programmatic` TR-2.1: 切换设置时菜单重建次数减少
  - `human-judgement` TR-2.2: 切换设置时菜单界面保持稳定，无闪烁跳动

### [ ] 任务3：修复书签功能异常问题
- **优先级**：P0
- **依赖**：None
- **描述**：
  - 修改 `bookmarks_service.dart` 中的 `_loadBookmarks` 和 `_loadNotes` 方法
  - 在文件不存在时初始化空列表，确保书签功能在初始时正常工作

- **成功标准**：
  - 即使 `bookmark.json` 文件不存在，书签功能也能正常使用
  - 首次添加书签时能够正确创建文件

- **测试要求**：
  - `programmatic` TR-3.1: 首次使用书签功能时无异常
  - `programmatic` TR-3.2: 书签数据能够正确保存和加载

## 实施顺序

1. 任务1：修复段落空格缩进问题
2. 任务2：修复设置面板闪烁跳动问题
3. 任务3：修复书签功能异常问题

## 预期成果

通过以上修复，解决用户反馈的三个问题，提升小说阅读器的用户体验。