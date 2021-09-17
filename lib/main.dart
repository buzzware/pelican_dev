import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:henry_dev/TransitionDelegate.dart';
import 'package:henry_dev/henry/HenryRouteSegment.dart';
import 'package:henry_dev/henry/HenryRouter.dart';
import 'package:henry_dev/models/Book.dart';
import 'package:henry_dev/pages/BookDetailsPage.dart';
import 'package:henry_dev/pages/BooksListScreen.dart';

void main() {
  const app = HenryExampleApp();
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

// typical url:

// /<stack>/<page>[;[param=value]*]&[option=value]*
// /main/console&color=red/product;id=5/

/*

redirects :
/                         => logged_in ? /auth/logged_in : /public/entrance
/auth/logged_in           => /app/dashboard
/app/new_user             => /app/intro

segmentBuilders
entrance        => Page
login           => Page
intro           => Page
dashboard       => Page
settings        => Page


'<segment>' (context) => context.page(Page())
OR
'<full_path>' (context) => context.redirect('<relative_or_absolute_path>')

 */


List<Book> books = [
  Book('1','Stranger in a Strange Land', 'Robert A. Heinlein'),
  Book('2','Foundation', 'Isaac Asimov'),
  Book('3','Fahrenheit 451', 'Ray Bradbury'),
];


HenryRouter router = HenryRouter(
  '/app/books',
  RouteTable(
    {
      'books': (_) async {
        print('books');
        return _.page(
          BooksListScreen(
            books: books,
            onTapped: (book) {
              router.state.push(HenryRouteSegment.fromPathSegment("book;id=${book.id}"));
            }
          )
        );
      },
      'book;id&color;size': (_) async {
        print('book');
        return _.page(BookDetailsScreen(book: books.firstWhere((b) => b.id==_.segment!.params['id'])));
      }
    },
    redirects: {
      '/': (_) async => '/app/books'
    }
  ),
);


class HenryExampleApp extends StatefulWidget {
  const HenryExampleApp({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _HenryExampleAppState();
}

class _HenryExampleAppState extends State<HenryExampleApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Henry Example App',
      restorationScopeId: 'root',
      routerDelegate: router,
      routeInformationParser: router.parser,
    );
  }
}
