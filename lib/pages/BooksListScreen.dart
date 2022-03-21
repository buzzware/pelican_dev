import 'package:flutter/material.dart';
import 'package:pelican_dev/AppRoutes.dart';
import 'package:pelican_dev/main.dart';
import 'package:pelican_dev/models/Book.dart';

class BooksListScreen extends StatelessWidget {
  final List<Book> books;
  final ValueChanged<Book> onTapped;

  const BooksListScreen({Key? key,
    required this.books,
    required this.onTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              AppRoutes.router.push(AppRoutes.settings(vehicle_tab: 'Car',section_tab: 'Appearance'));
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          for (var book in books)
            ListTile(
              title: Text(book.title),
              subtitle: Text(book.author),
              onTap: () => onTapped(book),
            )
        ],
      ),
    );
  }
}
