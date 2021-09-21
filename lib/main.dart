import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:pelican_dev/TransitionDelegate.dart';
import 'package:pelican_dev/pelican/PelicanRouteSegment.dart';
import 'package:pelican_dev/pelican/PelicanRouter.dart';
import 'package:pelican_dev/models/Book.dart';
import 'package:pelican_dev/pages/BookDetailsPage.dart';
import 'package:pelican_dev/pages/BooksListScreen.dart';

void main() {
  const app = PelicanExampleApp();
  runApp(app);
}

class ErrorPage extends StatelessWidget {
  final String text;

  const ErrorPage({required this.text});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Text(text),
        ),
      ),
    );
  }
}

List<Book> books = [
  Book('1','Stranger in a Strange Land', 'Robert A. Heinlein'),
  Book('2','Foundation', 'Isaac Asimov'),
  Book('3','Fahrenheit 451', 'Ray Bradbury'),
];


PelicanRouter router = PelicanRouter(
  '/books',
  RouteTable(
    {
      'books': (_) async {
        print('books');
        return _.page(
          BooksListScreen(
            books: books,
            onTapped: (book) {
              router.state.push("book;id=${book.id}");
            }
          )
        );
      },
      'book;id+color;size': (_) async {
        print('book');
        return _.page(BookDetailsScreen(book: books.firstWhere((b) => b.id==_.segment!.params['id'])));
      }
    },
    redirects: {
      '/': (_) async => '/books'
    }
  ),
);


class PelicanExampleApp extends StatefulWidget {
  const PelicanExampleApp({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PelicanExampleAppState();
}

class _PelicanExampleAppState extends State<PelicanExampleApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Pelican Example App',
      restorationScopeId: 'root',
      routerDelegate: router,
      routeInformationParser: router.parser,
    );
  }
}
