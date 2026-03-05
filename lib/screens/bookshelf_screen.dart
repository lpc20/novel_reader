import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../providers/bookshelf_provider.dart';
import '../models/novel.dart';
import '../screens/reader_screen.dart';
import '../utils/permission_helper.dart';
import '../utils/color_utils.dart';
import '../services/settings_service.dart';

class BookshelfScreen extends StatefulWidget {
  const BookshelfScreen({super.key});

  @override
  State<BookshelfScreen> createState() => _BookshelfScreenState();
}

class _BookshelfScreenState extends State<BookshelfScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookshelfProvider>().init();
    });
  }

  Future<void> _importBook() async {
    final hasPermission = await PermissionHelper.requestStoragePermission();

    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('需要存储权限才能导入小说')));
      }
      return;
    }

    _pickFile();
  }

  Future<void> _pickFile() async {
    try {
      final provider = context.read<BookshelfProvider>();
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final success = await provider.importNovel(filePath);

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('导入成功')));
          } else {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(provider.error ?? '导入失败')));
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('导入失败: $e')));
      }
    }
  }

  void _openBook(Novel novel) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ReaderScreen(novel: novel)),
    );
  }

  Future<void> _deleteBook(Novel novel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除确认'),
        content: Text('确定要从书架删除《${novel.title}》吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<BookshelfProvider>().removeNovel(novel.id);
    }
  }

  void _showSortOptions() {
    final currentSortType = context.read<BookshelfProvider>().currentSortType;

    showModalBottomSheet(
      context: context,
      backgroundColor: SettingsService.menuBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          const Text(
            '排序方式',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: SettingsService.menuTextColor,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('按添加时间'),
            textColor: SettingsService.menuTextColor,
            trailing: currentSortType == SortType.byAddTime
                ? const Icon(
                    Icons.check,
                    color: SettingsService.menuHighlightColor,
                  )
                : null,
            onTap: () {
              Navigator.pop(context);
              context.read<BookshelfProvider>().setSortType(SortType.byAddTime);
            },
          ),
          ListTile(
            title: const Text('按书名'),
            textColor: SettingsService.menuTextColor,
            trailing: currentSortType == SortType.byTitle
                ? const Icon(
                    Icons.check,
                    color: SettingsService.menuHighlightColor,
                  )
                : null,
            onTap: () {
              Navigator.pop(context);
              context.read<BookshelfProvider>().setSortType(SortType.byTitle);
            },
          ),
          ListTile(
            title: const Text('按文件大小'),
            textColor: SettingsService.menuTextColor,
            trailing: currentSortType == SortType.byFileSize
                ? const Icon(
                    Icons.check,
                    color: SettingsService.menuHighlightColor,
                  )
                : null,
            onTap: () {
              Navigator.pop(context);
              context.read<BookshelfProvider>().setSortType(
                SortType.byFileSize,
              );
            },
          ),
          ListTile(
            title: const Text('按最近阅读'),
            textColor: SettingsService.menuTextColor,
            trailing: currentSortType == SortType.byLastRead
                ? const Icon(
                    Icons.check,
                    color: SettingsService.menuHighlightColor,
                  )
                : null,
            onTap: () {
              Navigator.pop(context);
              context.read<BookshelfProvider>().setSortType(
                SortType.byLastRead,
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的书架'),
        centerTitle: true,
        backgroundColor: SettingsService.menuBackgroundColor,
        foregroundColor: SettingsService.menuTextColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () => _showSortOptions(),
            tooltip: '排序',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _importBook,
            tooltip: '导入小说',
          ),
        ],
      ),
      body: Consumer<BookshelfProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.novels.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: SettingsService.menuDividerColor,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      Icons.menu_book_outlined,
                      size: 60,
                      color: SettingsService.menuTextColor.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '书架空空如也',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: SettingsService.menuTextColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '点击右下角 + 导入本地小说',
                    style: TextStyle(
                      fontSize: 14,
                      color: SettingsService.menuTextColor.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _importBook,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('导入小说'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SettingsService.menuHighlightColor,
                      foregroundColor: SettingsService.menuHighlightTextColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.65,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: provider.novels.length,
            itemBuilder: (context, index) {
              final novel = provider.novels[index];
              return RepaintBoundary(
                child: _BookCard(
                  novel: novel,
                  onTap: () => _openBook(novel),
                  onLongPress: () => _deleteBook(novel),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _importBook,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(60)),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _BookCard extends StatefulWidget {
  final Novel novel;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _BookCard({
    required this.novel,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<_BookCard> createState() => _BookCardState();
}

class _BookCardState extends State<_BookCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final coverColor = ColorUtils.parseColor(widget.novel.coverColor);

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: coverColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // 背景渐变
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      coverColor.withValues(alpha: 0.95),
                      coverColor.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            // 装饰元素
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
            ),
            // 内容
            Positioned.fill(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 标题
                    Text(
                      widget.novel.title,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        height: 1.3,
                      ),
                    ),
                    // 信息
                    Column(
                      children: [
                        // 章节数
                        Text(
                          '${widget.novel.chaptersCount > 0 ? widget.novel.chaptersCount : 0} 章',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // 文件大小
                        Text(
                          widget.novel.fileSizeFormatted,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // 阅读进度条（如果有阅读记录）
            if (widget.novel.lastReadProgress > 0)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(16),
                    ),
                  ),
                  child: Container(
                    width: widget.novel.lastReadProgress * 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
            // 阅读状态指示器
            if (widget.novel.lastReadProgress > 0)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '已读',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
