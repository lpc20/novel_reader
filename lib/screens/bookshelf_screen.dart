import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:novel_reader/constants/global.dart';
import 'package:provider/provider.dart';
import '../providers/bookshelf_view_model.dart';
import '../models/novel.dart';
import '../screens/reader_screen.dart';
import '../utils/permission_helper.dart';
import '../widgets/book_card.dart';
import '../widgets/empty_bookshelf.dart';

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
      context.read<BookshelfViewModel>().init();
    });
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _importBook() async {
    final hasPermission = await PermissionHelper.requestStoragePermission();

    if (!hasPermission) {
      _showSnackBar('需要存储权限才能导入小说');
      return;
    }

    try {
      final provider = context.read<BookshelfViewModel>();
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final success = await provider.importNovel(filePath);

        if (success) {
          _showSnackBar('导入成功');
        } else {
          _showSnackBar(provider.error ?? '导入失败');
        }
      }
    } catch (e) {
      _showSnackBar('导入失败: $e');
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
      await context.read<BookshelfViewModel>().removeNovel(novel.id);
    }
  }

  void _showSortOptions() {
    final currentSortType = context.read<BookshelfViewModel>().currentSortType;

    // 使用类型安全的方式定义排序选项
    final sortOptions = [
      {'type': SortType.byAddTime, 'title': '按添加时间'},
      {'type': SortType.byTitle, 'title': '按书名'},
      {'type': SortType.byFileSize, 'title': '按文件大小'},
      {'type': SortType.byLastRead, 'title': '按最近阅读'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
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
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          ...sortOptions.map(
            (option) => ListTile(
              title: Text(option['title'] as String),
              textColor: Colors.black,
              tileColor: currentSortType == option['type']
                  ? Global.menuBackgroundColor.withValues(alpha: 0.5)
                  : null,
              trailing: currentSortType == option['type']
                  ? const Icon(Icons.check, color: Global.menuBackgroundColor)
                  : null,
              onTap: () async {
                Navigator.pop(context);
                await context.read<BookshelfViewModel>().setSortType(
                  option['type'] as SortType,
                );
              },
            ),
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
      body: Consumer<BookshelfViewModel>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.novels.isEmpty) {
            return EmptyBookshelf(onImport: _importBook);
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
                child: BookCard(
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
