import 'package:flutter/material.dart';
import 'package:henry_dev/TransitionDelegate.dart';
import 'package:henry_dev/models/Book.dart';
import 'package:henry_dev/pages/BookDetailsPage.dart';
import 'package:henry_dev/pages/BooksListScreen.dart';

void main() {
  runApp(const HenryExampleApp());
}

class HenryRoute {
  final int? id;

  HenryRoute.home() : id = null;

  HenryRoute.details(this.id);

  bool get isHomePage => id == null;
  bool get isDetailsPage => id != null;
}


class HenryRouteParser extends RouteInformationParser<HenryRoute> {

  // RouteInformation -> HenryRoute
  @override
  Future<HenryRoute> parseRouteInformation(RouteInformation routeInformation) async {
    final uri = Uri.parse(routeInformation.location!);

    if (uri.pathSegments.length >= 2) {
      var remaining = uri.pathSegments[1];
      return HenryRoute.details(int.tryParse(remaining));
    } else {
      return HenryRoute.home();
    }
  }


  // HenryRoute -> RouteInformation
  @override
  RouteInformation? restoreRouteInformation(HenryRoute configuration) {
    if (configuration.isHomePage) {
      return const RouteInformation(location: '/');
    }
    if (configuration.isDetailsPage) {
      return RouteInformation(location: '/book/${configuration.id}');
    }
    return null;
  }
}

List<Book> books = [
  Book('Stranger in a Strange Land', 'Robert A. Heinlein'),
  Book('Foundation', 'Isaac Asimov'),
  Book('Fahrenheit 451', 'Ray Bradbury'),
];

class HenryRouterDelegate extends RouterDelegate<HenryRoute> with ChangeNotifier, PopNavigatorRouterDelegateMixin<HenryRoute> {
  @override
  final GlobalKey<NavigatorState> navigatorKey;

  HenryRouterDelegate() : navigatorKey = GlobalKey<NavigatorState>();

  Book? _selectedBook;
  // get current route
  @override
  HenryRoute get currentConfiguration {
    return _selectedBook == null
      ? HenryRoute.home()
      : HenryRoute.details(books.indexOf(_selectedBook!));
  }

  // set current route
  @override
  Future<void> setNewRoutePath(HenryRoute configuration) async {
    if (configuration.isDetailsPage) {
      _selectedBook = books[configuration.id!];
    }
  }

  _buildPages() {
    return [
      MaterialPage(
        key: const ValueKey('BooksListPage'),
        child: BooksListScreen(
          books: books,
          onTapped: (book) {
            _selectedBook = book;
            notifyListeners();
          },
        ),
      ),
      if (_selectedBook != null) BookDetailsPage(book: _selectedBook)
    ];
  }

  bool _onPopPage(Route<dynamic> route, dynamic result) {
    if (!route.didPop(result)) {
      return false;
    }

    // Update the list of pages by setting _selectedBook to null
    _selectedBook = null;
    notifyListeners();

    return true;
  }

  // build a Navigator
  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      transitionDelegate: NoAnimationTransitionDelegate(),
      pages: _buildPages(),
      onPopPage: _onPopPage
    );
  }
}


class HenryExampleApp extends StatefulWidget {
  const HenryExampleApp({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _HenryExampleAppState();
}

class _HenryExampleAppState extends State<HenryExampleApp> {
  final HenryRouterDelegate _routerDelegate = HenryRouterDelegate();
  final HenryRouteParser _routeInformationParser = HenryRouteParser();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Henry Example App',
      routerDelegate: _routerDelegate,
      routeInformationParser: _routeInformationParser,
    );
  }
}
