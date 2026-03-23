# 小说阅读器 - 删除冗余代码计划

## [x] 任务 1: 清理 BookshelfService 中的冗余代码
- **Priority**: P1
- **Depends On**: None
- **Description**:
  - 删除未使用的 `updateNovel` 方法
  - 删除未使用的 `getRecentNovels` 方法
  - 移除 `removeNovel` 中删除原文件的逻辑（保留书架数据删除）
- **Success Criteria**:
  - 代码编译通过
  - 书架功能正常运行
- **Test Requirements**:
  - `programmatic` TR-1.1: 应用能正常启动
  - `programmatic` TR-1.2: 能正常导入和删除小说
  - `human-judgement` TR-1.3: 代码结构清晰，无未使用方法

## [x] 任务 2: 清理 BookshelfRepository 中的冗余代码
- **Priority**: P1
- **Depends On**: 任务 1
- **Description**:
  - 删除未使用的 `getRecentNovels` 方法
- **Success Criteria**:
  - 代码编译通过
  - 书架功能正常运行
- **Test Requirements**:
  - `programmatic` TR-2.1: 应用能正常启动
  - `programmatic` TR-2.2: 书架数据操作正常

## [x] 任务 3: 清理 BookshelfScreen 中的冗余代码
- **Priority**: P2
- **Depends On**: 任务 1, 任务 2
- **Description**:
  - 优化导入逻辑，减少重复代码
  - 简化排序选项的实现
- **Success Criteria**:
  - 代码编译通过
  - 书架界面功能正常
- **Test Requirements**:
  - `programmatic` TR-3.1: 应用能正常启动
  - `programmatic` TR-3.2: 导入和排序功能正常

## [x] 任务 4: 检查并清理其他文件中的冗余代码
- **Priority**: P2
- **Depends On**: 任务 1, 任务 2, 任务 3
- **Description**:
  - 检查 utils 目录下未使用的工具类
  - 检查 permissions 相关的冗余代码
  - 检查其他服务类中的未使用方法
- **Success Criteria**:
  - 代码编译通过
  - 应用功能正常运行
- **Test Requirements**:
  - `programmatic` TR-4.1: 应用能正常启动
  - `programmatic` TR-4.2: 所有功能正常运行
  - `human-judgement` TR-4.3: 代码结构清晰，无冗余文件

## [x] 任务 5: 运行测试验证代码清理结果
- **Priority**: P1
- **Depends On**: 任务 1, 任务 2, 任务 3, 任务 4
- **Description**:
  - 运行应用确保所有功能正常
  - 验证代码编译无错误
  - 检查应用性能是否有提升
- **Success Criteria**:
  - 应用能正常启动和运行
  - 无编译错误
  - 功能正常使用
- **Test Requirements**:
  - `programmatic` TR-5.1: 应用启动无错误
  - `programmatic` TR-5.2: 所有功能正常运行
  - `human-judgement` TR-5.3: 代码更加简洁清晰