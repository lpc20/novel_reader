import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:novel_reader/providers/bookshelf_view_model.dart';
import 'package:novel_reader/providers/reader_view_model.dart';
import 'package:provider/provider.dart';
import 'package:novel_reader/screens/bookshelf_screen.dart';

void main() {
  testWidgets('Bookshelf screen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => BookshelfViewModel()),
          ChangeNotifierProvider(create: (_) => ReaderViewModel()),
        ],
        child: const MaterialApp(
          home: BookshelfScreen(),
        ),
      ),
    );

    expect(find.text('我的书架'), findsOneWidget);
    expect(find.text('书架空空如也'), findsOneWidget);
  });
}
