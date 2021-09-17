import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:henry_dev/TransitionDelegate.dart';
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


// @immutable
// class HenrySegmentDefinition {
//   final String pattern;               // eg. product_edit;id&color;size
//   late final String name;
//   late final List<String> params;
//   late final List<String> options;
//
//   HenrySegmentDefinition(this.pattern) {
//     var parts = pattern.split('&');
//     var nameAndParams = parts[0];
//     var optionsStr = parts.length > 1 ? parts[1] : '';
//     List<String> nameAndParamsParts = nameAndParams.isNotEmpty ? nameAndParams.split(';') : [];
//     name = nameAndParamsParts.removeAt(0);
//     // params = nameAndParamsParts.where((s)=>s.startsWith('(') && s.endsWith(')')).map((s)=>s.substring(1,s.length-3)).toList(); //   .map((s) =>  ?  : null).where((s) => s!=null).toList<String>(growable: false);
//     // options = (optionsStr ?? '').split(';').where((s)=>s.startsWith('(') && s.endsWith(')')).map((s)=>s.substring(1,s.length-3)).toList();
//     params = nameAndParamsParts; //   .map((s) =>  ?  : null).where((s) => s!=null).toList<String>(growable: false);
//     options = optionsStr.isEmpty ? [] : optionsStr.split(';');
//   }
//
//   static String getName(String segment) {
//     var parts = segment.split('/');
//     if (parts.isEmpty)
//       throw Exception('segment is empty');
//     return parts[0];
//   }
// }



// represents
@immutable
class HenryRouteSegment {
  late final String name;
  late final LinkedHashMap<String,String> params;
  late final LinkedHashMap<String,String> options;

  HenryRouteSegment(this.name, this.params, this.options);

  static LinkedHashMap<String,String> mapFromValues(String values) {
    return LinkedHashMap<String,String>.fromIterable(values.isEmpty ? [] : values.split(';'),key: (i) => i.split('=')[0],value: (i) {
      var parts = i.split('=');
      return i.length>1 ? parts[1] : '';
    });
  }

  static String getName(String segment) {
    var parts = segment.split(';');
    if (parts.isEmpty)
      throw Exception('segment is empty');
    return parts[0];
  }

  HenryRouteSegment.fromPathSegment(String path) {
    var parts = path.split('&');
    var nameAndParams = parts[0];
    var optionsStr = parts.length > 1 ? parts[1] : '';
    List<String> nameAndParamsParts = nameAndParams.isNotEmpty ? nameAndParams.split(';') : [];
    name = nameAndParamsParts.removeAt(0);
    params = mapFromValues(nameAndParamsParts.join(';'));
    options = mapFromValues(optionsStr);
  }

  String toPathSegment({HenryRouteSegment? definition}) {
    if (definition!=null && definition.name != name)
      throw Exception('definition name must match path name');

    var name_and_pars = [name];
    var ops = List<String>.empty(growable: true);
    if (definition!=null) {
      if (params.isNotEmpty) {
        for (var p in definition.params.keys) {
          if (params.containsKey(p)) {
            name_and_pars.add([p, params[p]].join('='));
          }
        }
      }
      if (options.isNotEmpty) {
        for (var op in definition.options.keys) {
          if (options.containsKey(op)) {
            ops.add([op, options[op]].join('='));
          }
        }
      }
    } else {
      for (var p in params.keys) {
        name_and_pars.add([p, params[p]].join('='));
      }
      for (var op in options.keys) {
        ops.add([op, options[op]].join('='));
      }
    }
    return [name_and_pars.join(';'), ops.join(';')].join('&');
  }
}

@immutable
class HenryRoute {
  late final String stackName;
  late final List<HenryRouteSegment> segments;
  HenryRoute(this.stackName, this.segments);

  String toPath() {
    var parts = segments.map<String>((s) => s.toPathSegment()).join('/');
    var result = "/$stackName/$parts";
    return result;
  }

  HenryRoute.fromPath(String path) {
    var parts = path.split('/');
    if (parts.isNotEmpty && parts[0].isEmpty)
      parts.removeAt(0);
    stackName = parts.isNotEmpty ? parts.removeAt(0) : '';
    segments = parts.map((p)=>HenryRouteSegment.fromPathSegment(p)).toList();
  }
}





// typical url:

// /<stack>/<page>[;[param=value]*]&[option=value]*
// /main/console&color=red/product;id=5/

@immutable
class HenryRouterState with ChangeNotifier {

  HenryRoute _route;

  List<Page<dynamic>>? pages;

  HenryRouterState(HenryRoute route, {this.pages}) : _route = route;

  HenryRoute get route => _route;
  set route(HenryRoute route) {
    _route = route;
    notifyListeners();
  }

  void push(HenryRouteSegment segment) {
    _route.segments.add(segment);
    notifyListeners();
  }

  HenryRouteSegment pop() {
    final poppedItem = _route.segments.removeLast();
    notifyListeners();
    return poppedItem;
  }

}

class HenryRouteResult {
  Widget? pageWidget;
  String? redirectToPath;

  HenryRouteResult({this.redirectToPath,this.pageWidget});
}

@immutable
class HenryRouteContext {
  HenryRoute route;
  HenryRouteSegment? segment;

  HenryRouteContext(this.route,this.segment);

  HenryRouteResult page(Widget pageWidget) {
    return HenryRouteResult(pageWidget: pageWidget);
  }

  HenryRouteResult redirect(String path) {
    return HenryRouteResult(redirectToPath: path);
  }
}

typedef SegmentPageBuilder = Future<HenryRouteResult> Function(HenryRouteContext context);
typedef HenryRedirectBuilder = Future<String> Function(String string);

@immutable
class RouteTable {
  final Map<String, SegmentPageBuilder> segments;
  final Map<String, HenryRedirectBuilder>? redirects;
  late final HenryRedirectBuilder? _routeNotFound;

  RouteTable(this.segments,{HenryRedirectBuilder? onRouteNotFound, this.redirects}) {
    _routeNotFound = onRouteNotFound;
  }

  // Future<HenryRouteResult> segmentNotFound(HenryRouteContext context) async {
  //   if (_routeNotFound != null) {
  //     return await _routeNotFound(context.route!.toPath());
  //   } else {
  //     return HenryRouteResult(pageWidget: ErrorPage(text: "${context.path} doesn't exist"));
  //   }
  // }

  SegmentPageBuilder? matchRoute(HenryRouteSegment segment) {
    if (segments.containsKey(segment.name))
      return segments[segment.name];
    else
      return null;
  }

  Future<HenryRouteResult> executeSegment(HenryRouteContext context) async {
    var builder = matchRoute(context.segment!);
    if (builder==null)
      throw Exception("Segment route not matched");
    HenryRouteResult buildResult = await builder(context);
    return buildResult;
  }

  HenryRedirectBuilder? matchRedirect(String path) {
    if (redirects!.containsKey(path))
      return redirects![path];
    else
      return null;
  }


  Future<String> executeRedirects(String path) async {
    do {
      var redirectBuilder = matchRedirect(path);
      if (redirectBuilder == null) {
        return path;
      } else {
        var newPath = await redirectBuilder(path);
        path = newPath;
      }
    } while (true);
  }
}

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


class HenryRouteParser extends RouteInformationParser<HenryRouterState> {
  HenryRouter router;

  HenryRouteParser(this.router);

  // RouteInformation -> HenryRoute
  @override
  Future<HenryRouterState> parseRouteInformation(RouteInformation routeInformation) async {
    print('parseRouteInformation RouteInformation -> HenryRoute');
    var path = await router.routeTable.executeRedirects(routeInformation.location!);
    var route = HenryRoute.fromPath(path);
    return HenryRouterState(
      route
    );
  }

  // HenryRoute -> RouteInformation
  @override
  RouteInformation? restoreRouteInformation(HenryRouterState configuration) {
    print('restoreRouteInformation HenryRoute -> RouteInformation');
    return RouteInformation(
      location: configuration.route.toPath(),
    );
  }
}

List<Book> books = [
  Book('1','Stranger in a Strange Land', 'Robert A. Heinlein'),
  Book('2','Foundation', 'Isaac Asimov'),
  Book('3','Fahrenheit 451', 'Ray Bradbury'),
];

class HenryRouter extends RouterDelegate<HenryRouterState> with ChangeNotifier, PopNavigatorRouterDelegateMixin<HenryRouterState> {

  late final HenryRouteParser parser;
  late HenryRouterState state;
  late final RouteTable routeTable;

  @override
  late final GlobalKey<NavigatorState> navigatorKey;

  HenryRouter(
    String initialPath,
    this.routeTable
  ): super() {
    parser = HenryRouteParser(this);
    navigatorKey = GlobalKey<NavigatorState>();
    state = HenryRouterState(
      HenryRoute.fromPath(initialPath)
    );
    //setNewRoutePath(parser.stateFromLocation(initialPath));
  }

  @override
  void dispose() {
    state.removeListener(notifyListeners);
    super.dispose();
  }

  @override
  HenryRouterState get currentConfiguration {
    return state;
  }

  // HenryRouterState('auth',[
  //   HenryRouteSegment(
  //     definitions[0]
  //   )
  // ]);

  // set current route
  @override
  Future<void> setNewRoutePath(HenryRouterState configuration) async {
    state = configuration;
  }

  // void goto(String path) {
  //   var state =
  //   setNewRoutePath(state);
  // }

  _buildPage(String key, Widget widget) {
    return MaterialPage(
      key: ValueKey(key),
      child: widget
    );
  }

  //Future<List<Page<dynamic>>> _buildPages(BuildContext context) async =>

    // //var routeContext = HenryRouteContext(state.route.toPath(),segment);
    // HenryRouteResult buildResult = await routeTable.executeSegmentPath(
    //
    //
    // //
    // //
    // //
    // //
    // //
    // //
    // //
    // //       if (routes.containsKey(
    // //
    // //
    // //
    // //       }
    // //
    // //
    // //
    // //
    // //
    // // var route = router.routeTable.routes[segment.name];
    // // var result = route();
    // return MaterialPage(child: null);


  Future<List<Page<dynamic>>> buildPages(BuildContext context) async {
    print('Router.buildPages');
    var pages = List<Page<dynamic>>.empty(growable: true);
    for (var segment in state.route.segments) {
      var context = HenryRouteContext(state.route,segment);
      var buildResult = await routeTable.executeSegment(context);
      pages.add(_buildPage(segment.name,buildResult.pageWidget!));
    }
    return pages;
  }

  bool _onPopPage(Route<dynamic> route, dynamic result) {
    if (!route.didPop(result)) {
      return false;
    }
    state.pop();
    notifyListeners();
    return true;
  }

  // build a Navigator
  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: router.buildPages(context),
    initialData: [
      MaterialPage(child: Container(child: Text('Please Wait'))),
    ],
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        return Navigator(
            key: router.navigatorKey,
            transitionDelegate: NoAnimationTransitionDelegate(),
            pages: snapshot.data! as List<Page<dynamic>>,
            onPopPage: _onPopPage
        );
      } else {
        return CircularProgressIndicator();
      }
    }
  );
}


// 'BooksListPage',
// ),
// // if (_selectedBook != null)
// //   BookDetailsPage(book: _selectedBook)



HenryRouter router = HenryRouter(
  '/app/books',
  RouteTable(
    {
      '/': (_) async => _.redirect('/app/books'),
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
    // onRouteNotFound: (path) async {
    //   return HenryRouteResult(pageWidget: ErrorPage(text: '${path} Not Found'));
    // },
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
