# 小说阅读器 (Novel Reader)

一个基于 Flutter 开发的本地小说阅读应用，支持 TXT 文件导入、章节解析、阅读设置、进度保存、搜索和书签等功能。

## 功能特性

- 📚 **书架管理**：导入本地 TXT 小说，管理阅读列表，支持多种排序方式
- 📖 **阅读功能**：章节自动解析，支持章节切换，提供滚动和分页两种阅读模式
- 🔍 **搜索功能**：支持章节内文本搜索，快速定位内容
- 🔖 **书签功能**：添加和管理书签，快速跳转到书签位置
- ⚙️ **阅读设置**：可调整字体大小、行高、字体类型、主题样式
- 📈 **进度保存**：自动保存阅读位置，下次打开继续阅读
- 🎨 **界面美观**：现代化 Material Design 界面，支持多种阅读主题
- 🔒 **本地存储**：所有数据存储在本地，保护隐私

## 技术特点

- **Flutter 框架**：跨平台支持，性能优异
- **Provider 状态管理**：清晰的状态管理架构
- **Isolate 优化**：章节解析使用后台线程，避免 UI 卡顿
- **智能编码检测**：自动识别 TXT 文件编码（UTF-8、GBK 等）
- **缓存机制**：文件内容和章节列表缓存，提升阅读体验
- **分页阅读**：支持文本分页显示，提供更好的阅读体验
- **搜索功能**：高效的文本搜索算法，快速定位内容
- **响应式设计**：适配不同屏幕尺寸

## 安装说明

### 前提条件

- Flutter SDK 3.11.0+
- Dart 3.11.0+
- Android Studio 或 Visual Studio Code

### 安装步骤

1. **克隆项目**
   ```bash
   git clone <项目地址>
   cd novel_reader
   ```

2. **安装依赖**
   ```bash
   flutter pub get
   ```

3. **运行项目**
   - Android: `flutter run`
   - iOS: 需要在 macOS 环境下运行

## 使用指南

### 1. 导入小说

- 点击书架页面右上角的 "+"，或底部的浮动按钮
- 选择本地 TXT 文件进行导入
- 应用会自动解析文件编码和章节

### 2. 开始阅读

- 点击书架上的小说封面进入阅读页面
- 点击屏幕中心区域打开/关闭阅读菜单
- 使用左右按钮切换章节（分页模式）或滑动屏幕（滚动模式）

### 3. 阅读设置

- 点击阅读菜单中的设置图标
- 调整字体大小、行高、字体类型和主题
- 支持多种预设主题样式
- 切换阅读模式（滚动或分页）

### 4. 章节管理

- 点击阅读菜单中的章节列表
- 快速跳转到任意章节
- 查看当前阅读进度

### 5. 搜索功能

- 点击阅读菜单中的搜索图标
- 输入搜索关键词
- 点击搜索按钮开始搜索
- 使用上/下按钮切换搜索结果

### 6. 书签功能

- 点击阅读菜单中的书签图标
- 点击"添加书签"按钮添加当前位置为书签
- 点击书签列表中的书签跳转到对应位置
- 长按书签删除书签

## 项目结构

```
lib/
├── constants/        # 常量定义
│   └── global.dart          # 全局常量
├── models/           # 数据模型
│   ├── bookmark.dart        # 书签模型
│   ├── chapter.dart         # 章节模型
│   ├── menu_data.dart       # 菜单数据模型
│   ├── novel.dart           # 小说模型
│   ├── reader_data.dart     # 阅读器数据模型
│   └── reading_progress.dart  # 阅读进度模型
├── providers/        # 状态管理
│   ├── bookshelf_provider.dart  # 书架状态管理
│   └── reader_provider.dart     # 阅读器状态管理
├── screens/          # 页面
│   ├── bookshelf_screen.dart    # 书架页面
│   └── reader_screen.dart       # 阅读页面
├── services/         # 服务
│   ├── bookmarks_service.dart   # 书签服务
│   ├── bookshelf_service.dart   # 书架服务
│   ├── file_service.dart        # 文件服务
│   ├── reader_repository.dart   # 阅读器仓库
│   └── settings_service.dart    # 设置服务
├── theme/            # 主题
│   └── app_theme.dart           # 应用主题
├── utils/            # 工具类
│   ├── color_utils.dart         # 颜色工具
│   ├── debouncer.dart           # 防抖工具
│   ├── keep_alive_wrapper.dart  # 保持活跃包装器
│   ├── permission_helper.dart   # 权限管理
│   ├── permission_helper_mobile.dart  # 移动设备权限管理
│   └── permission_helper_stub.dart    # 权限管理存根
├── widgets/          # 组件
│   ├── menu/         # 菜单组件
│   │   ├── bookmark_panel.dart       # 书签面板
│   │   ├── chapter_navigation_panel.dart  # 章节导航面板
│   │   ├── menu_top_bar.dart        # 菜单顶部栏
│   │   ├── search_panel.dart         # 搜索面板
│   │   └── settings_panel.dart       # 设置面板
│   ├── reader/       # 阅读器组件
│   │   ├── chapter_navigation.dart   # 章节导航
│   │   ├── reader_content.dart       # 阅读器内容
│   │   └── text_paginator.dart       # 文本分页器
│   ├── book_card.dart        # 书籍卡片
│   ├── chapter_drawer.dart   # 章节抽屉
│   ├── empty_bookshelf.dart  # 空书架
│   └── reader_menu.dart      # 阅读菜单
└── main.dart         # 应用入口
```

## 性能优化

应用已经实现了以下性能优化：

1. **文件内容缓存**：避免重复读取文件
2. **章节解析缓存**：减少重复解析开销
3. **Isolate 章节解析**：后台线程处理，避免 UI 阻塞
4. **滚动节流**：优化滚动事件处理
5. **RepaintBoundary**：减少不必要的重绘
6. **分页阅读**：优化大文件阅读体验
7. **搜索算法**：高效的文本搜索实现

## 常见问题

### Q: 导入小说失败怎么办？
A: 请检查文件编码是否支持，目前支持 UTF-8 和 GBK 编码。

### Q: 阅读时卡顿怎么办？
A: 大文件可能需要更多时间解析，请耐心等待。应用会缓存解析结果。

### Q: 如何备份我的书架数据？
A: 应用数据存储在应用文档目录，可通过文件管理器备份 `novels.json`、`progress.json` 和 `bookmarks.json` 文件。

### Q: 如何切换阅读模式？
A: 在阅读设置中，找到"阅读模式"选项，可切换滚动模式和分页模式。

## 开发说明

- **开发环境**：Flutter 3.11.0+, Dart 3.11.0+
- **依赖库**：
  - `provider` - 状态管理
  - `file_picker` - 文件选择
  - `charset_converter` - 编码转换
  - `path_provider` - 路径管理
  - `permission_handler` - 权限管理
  - `shared_preferences` - 本地存储

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request 来改进这个项目！