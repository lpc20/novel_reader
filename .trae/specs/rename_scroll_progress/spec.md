# 小说阅读器 - 变量重命名 PRD

## Overview
- **Summary**: 将 ReaderViewModel 中的 `_scrollProgress` 变量重命名为 `_progressInChapter`，并修改相关代码以适配这一变化
- **Purpose**: 提高代码可读性和语义清晰度，使变量名更准确地反映其功能
- **Target Users**: 开发人员和维护者

## Goals
- 将 `_scrollProgress` 变量重命名为 `_progressInChapter`
- 修改所有引用该变量的代码
- 确保功能保持不变
- 提高代码可读性

## Non-Goals (Out of Scope)
- 改变变量的功能或行为
- 修改其他不相关的代码
- 添加新功能

## Background & Context
- 当前 `_scrollProgress` 变量表示当前章节内的阅读进度
- 变量名不够直观，容易误解为仅与滚动模式相关
- 重命名为 `_progressInChapter` 更准确地反映其功能，适用于滚动模式和分页模式

## Functional Requirements
- **FR-1**: 将 ReaderViewModel 中的 `_scrollProgress` 变量重命名为 `_progressInChapter`
- **FR-2**: 修改所有引用 `_scrollProgress` 的代码，使用 `_progressInChapter` 替代
- **FR-3**: 确保代码编译通过，功能保持不变

## Non-Functional Requirements
- **NFR-1**: 代码可读性提高
- **NFR-2**: 变量名语义清晰
- **NFR-3**: 代码风格一致

## Constraints
- **Technical**: 仅修改与 `_scrollProgress` 相关的代码
- **Dependencies**: 无

## Assumptions
- 所有引用 `_scrollProgress` 的代码都需要修改
- 重命名不会影响功能

## Acceptance Criteria

### AC-1: 变量重命名
- **Given**: 代码库中存在 `_scrollProgress` 变量
- **When**: 将其重命名为 `_progressInChapter`
- **Then**: 变量名更准确地反映其功能
- **Verification**: `programmatic`

### AC-2: 代码适配
- **Given**: 代码库中存在引用 `_scrollProgress` 的代码
- **When**: 将所有引用修改为 `_progressInChapter`
- **Then**: 代码编译通过，功能保持不变
- **Verification**: `programmatic`

### AC-3: 代码可读性
- **Given**: 代码修改完成
- **When**: 阅读代码
- **Then**: 变量名语义清晰，易于理解
- **Verification**: `human-judgment`

## Open Questions
- 无