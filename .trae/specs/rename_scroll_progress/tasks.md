# 小说阅读器 - 变量重命名实现计划

## [x] 任务 1: 重命名 ReaderViewModel 中的 _scrollProgress 变量
- **Priority**: P0
- **Depends On**: None
- **Description**: 
  - 将 `_scrollProgress` 变量重命名为 `_progressInChapter`
  - 更新相关的注释和文档
- **Acceptance Criteria Addressed**: AC-1, AC-3
- **Test Requirements**:
  - `programmatic` TR-1.1: 变量成功重命名
  - `human-judgement` TR-1.2: 变量名语义清晰，易于理解
- **Notes**: 确保修改变量声明和所有引用

## [x] 任务 2: 修改 updateScrollProgress 方法
- **Priority**: P0
- **Depends On**: 任务 1
- **Description**:
  - 将 `updateScrollProgress` 方法重命名为 `updateProgressInChapter`
  - 修改方法内部的变量引用
- **Acceptance Criteria Addressed**: AC-2
- **Test Requirements**:
  - `programmatic` TR-2.1: 方法成功重命名
  - `programmatic` TR-2.2: 方法功能保持不变
- **Notes**: 确保修改方法名和所有调用

## [x] 任务 3: 修改 scrollProgress getter
- **Priority**: P0
- **Depends On**: 任务 1
- **Description**:
  - 将 `scrollProgress` getter 重命名为 `progressInChapter`
  - 修改内部实现
- **Acceptance Criteria Addressed**: AC-2
- **Test Requirements**:
  - `programmatic` TR-3.1: Getter 成功重命名
  - `programmatic` TR-3.2: Getter 功能保持不变
- **Notes**: 确保修改 getter 名和所有调用

## [x] 任务 4: 修改 _saveProgress 方法
- **Priority**: P0
- **Depends On**: 任务 1
- **Description**:
  - 修改 `_saveProgress` 方法中的变量引用
- **Acceptance Criteria Addressed**: AC-2
- **Test Requirements**:
  - `programmatic` TR-4.1: 方法中的变量引用已更新
  - `programmatic` TR-4.2: 方法功能保持不变
- **Notes**: 确保所有引用都已更新

## [x] 任务 5: 修改 updatePageInfo 方法
- **Priority**: P0
- **Depends On**: 任务 1
- **Description**:
  - 修改 `updatePageInfo` 方法中的变量引用
- **Acceptance Criteria Addressed**: AC-2
- **Test Requirements**:
  - `programmatic` TR-5.1: 方法中的变量引用已更新
  - `programmatic` TR-5.2: 方法功能保持不变
- **Notes**: 确保所有引用都已更新

## [x] 任务 6: 修改 loadNovel 方法
- **Priority**: P0
- **Depends On**: 任务 1
- **Description**:
  - 修改 `loadNovel` 方法中的变量引用
- **Acceptance Criteria Addressed**: AC-2
- **Test Requirements**:
  - `programmatic` TR-6.1: 方法中的变量引用已更新
  - `programmatic` TR-6.2: 方法功能保持不变
- **Notes**: 确保所有引用都已更新

## [x] 任务 7: 修改 goToChapter 方法
- **Priority**: P0
- **Depends On**: 任务 1
- **Description**:
  - 修改 `goToChapter` 方法中的变量引用
- **Acceptance Criteria Addressed**: AC-2
- **Test Requirements**:
  - `programmatic` TR-7.1: 方法中的变量引用已更新
  - `programmatic` TR-7.2: 方法功能保持不变
- **Notes**: 确保所有引用都已更新

## [x] 任务 8: 修改 addBookmark 方法
- **Priority**: P0
- **Depends On**: 任务 1
- **Description**:
  - 修改 `addBookmark` 方法中的变量引用
- **Acceptance Criteria Addressed**: AC-2
- **Test Requirements**:
  - `programmatic` TR-8.1: 方法中的变量引用已更新
  - `programmatic` TR-8.2: 方法功能保持不变
- **Notes**: 确保所有引用都已更新

## [x] 任务 9: 运行测试验证
- **Priority**: P0
- **Depends On**: 任务 1, 任务 2, 任务 3, 任务 4, 任务 5, 任务 6, 任务 7, 任务 8
- **Description**:
  - 运行 `flutter analyze` 检查代码
  - 验证代码编译通过
  - 验证功能保持不变
- **Acceptance Criteria Addressed**: AC-2, AC-3
- **Test Requirements**:
  - `programmatic` TR-9.1: 代码编译通过
  - `programmatic` TR-9.2: 无分析错误
  - `human-judgement` TR-9.3: 代码可读性提高
- **Notes**: 确保所有修改都已完成，无遗漏