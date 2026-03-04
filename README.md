# 小说阅读器 (Novel Reader)

一个基于 Flutter 开发的本地小说阅读应用，支持 TXT 文件导入、章节解析、阅读设置和进度保存等功能。

## 功能特性

- 📚 **书架管理**：导入本地 TXT 小说，管理阅读列表
- 📖 **阅读功能**：章节自动解析，支持章节切换
- ⚙️ **阅读设置**：可调整字体大小、行高、主题样式
- 📈 **进度保存**：自动保存阅读位置，下次打开继续阅读
- 🎨 **界面美观**：现代化 Material Design 界面
- 🔒 **本地存储**：所有数据存储在本地，保护隐私

## 技术特点

- **Flutter 框架**：跨平台支持，性能优异
- **Provider 状态管理**：清晰的状态管理架构
- **Isolate 优化**：章节解析使用后台线程，避免 UI 卡顿
- **智能编码检测**：自动识别 TXT 文件编码（UTF-8、GBK 等）
- **缓存机制**：文件内容和章节列表缓存，提升阅读体验

## 安装说明

### 前提条件

- Flutter SDK 3.0+ 
- Dart 3.0+ 
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

- 点击书架页面右上角的 "+", 或底部的浮动按钮
- 选择本地 TXT 文件进行导入
- 应用会自动解析文件编码和章节

### 2. 开始阅读

- 点击书架上的小说封面进入阅读页面
- 点击屏幕中心区域打开/关闭阅读菜单
- 使用左右按钮切换章节

### 3. 阅读设置

- 点击阅读菜单中的设置图标
- 调整字体大小、行高和主题
- 支持多种预设主题样式

### 4. 章节管理

- 点击阅读菜单中的章节列表
- 快速跳转到任意章节
- 查看当前阅读进度

## 项目结构

```
lib/
├── models/          # 数据模型
│   ├── chapter.dart       # 章节模型
│   ├── novel.dart         # 小说模型
│   └── reading_progress.dart  # 阅读进度模型
├── providers/       # 状态管理
│   ├── bookshelf_provider.dart  # 书架状态管理
│   └── reader_provider.dart     # 阅读器状态管理
├── screens/         # 页面
│   ├── bookshelf_screen.dart    # 书架页面
│   └── reader_screen.dart       # 阅读页面
├── services/        # 服务
│   ├── bookshelf_service.dart   # 书架服务
│   ├── file_service.dart        # 文件服务
│   └── settings_service.dart    # 设置服务
├── utils/           # 工具类
│   ├── color_utils.dart         # 颜色工具
│   └── permission_helper.dart   # 权限管理
├── widgets/         # 组件
│   ├── chapter_list.dart        # 章节列表
│   ├── chapter_list_drawer.dart # 章节抽屉
│   └── reader_menu.dart         # 阅读菜单
└── main.dart        # 应用入口
```

## 性能优化

应用已经实现了以下性能优化：

1. **文件内容缓存**：避免重复读取文件
2. **章节解析缓存**：减少重复解析开销
3. **Isolate 章节解析**：后台线程处理，避免 UI 阻塞
4. **滚动节流**：优化滚动事件处理
5. **RepaintBoundary**：减少不必要的重绘

## 常见问题

### Q: 导入小说失败怎么办？
A: 请检查文件编码是否支持，目前支持 UTF-8 和 GBK 编码。

### Q: 阅读时卡顿怎么办？
A: 大文件可能需要更多时间解析，请耐心等待。应用会缓存解析结果。

### Q: 如何备份我的书架数据？
A: 应用数据存储在应用文档目录，可通过文件管理器备份 `novels.json` 和 `progress.json` 文件。

## 开发说明

- **开发环境**：Flutter 3.0+, Dart 3.0+
- **依赖库**：
  - `provider` - 状态管理
  - `file_picker` - 文件选择
  - `charset_converter` - 编码转换
  - `path_provider` - 路径管理

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request 来改进这个项目！