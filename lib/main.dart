import 'package:flutter/material.dart';
import 'package:henry_dev/TransitionDelegate.dart';
import 'package:henry_dev/models/Book.dart';
import 'package:henry_dev/pages/BookDetailsPage.dart';
import 'package:henry_dev/pages/BooksListScreen.dart';

void main() {
  runApp(const HenryExampleApp());
}

@immutable
class HenrySegmentDefinition {
  final String pattern;               // eg. product_edit;id&color;size
  late final String name;
  late final List<String> params;
  late final List<String> options;

  HenrySegmentDefinition(this.pattern) {
    var parts = pattern.split('&');
    var nameAndParams = parts[0];
    var optionsStr = parts.length > 1 ? parts[1] : '';
    List<String> nameAndParamsParts = nameAndParams.isNotEmpty ? nameAndParams.split(';') : [];
    name = nameAndParamsParts.removeAt(0);
    // params = nameAndParamsParts.where((s)=>s.startsWith('(') && s.endsWith(')')).map((s)=>s.substring(1,s.length-3)).toList(); //   .map((s) =>  ?  : null).where((s) => s!=null).toList<String>(growable: false);
    // options = (optionsStr ?? '').split(';').where((s)=>s.startsWith('(') && s.endsWith(')')).map((s)=>s.substring(1,s.length-3)).toList();
    params = nameAndParamsParts; //   .map((s) =>  ?  : null).where((s) => s!=null).toList<String>(growable: false);
    options = optionsStr.isEmpty ? [] : optionsStr.split(';');
  }

  static String getName(String segment) {
    var parts = segment.split('/');
    if (parts.isEmpty)
      throw Exception('segment is empty');
    return parts[0];
  }
}



// represents
@immutable
class HenryRouteSegment {
  late final String name;
  late final Map<String,String> params;
  late final Map<String,String> options;
  late final HenrySegmentDefinition? definition;   // eg. product_edit;$id

  HenryRouteSegment(this.name, this.params, this.options, {this.definition});

  HenryRouteSegment.fromDefinitionAndPath(this.definition,String path) {

  }

  String toLocationPart() {
    var name_and_pars = [definition!.name];
    if (params.isNotEmpty) {
      for (var p in definition!.params) {
        if (params.containsKey(p)) {
          name_and_pars.add([p,params[p]].join('='));
        }
      }
    }
    var ops = List<String>.empty(growable: true);
    if (options.isNotEmpty) {
      for (var op in definition!.options) {
        if (options.containsKey(op)) {
          ops.add([op,options[op]].join('='));
        }
      }
    }
    return [name_and_pars,ops].join('&');
  }
}


// typical url:

// /<stack>/<page>[;[param=value]*]&[option=value]*
// /main/console&color=red/product;id=5/

@immutable
class HenryRouterState {
  final String stackName;
  final List<HenryRouteSegment> segments;
  const HenryRouterState(this.stackName, this.segments);

  String toLocation() {
    var parts = segments.map<String>((s) => s.toLocationPart()).join('/');
    var result = "/$stackName/$parts";
    return result;
  }
}


class HenryRouteParser extends RouteInformationParser<HenryRouterState> {
  HenryRouter router;

  HenryRouteParser(this.router);

  HenryRouterState stateFromLocation(String location) {
    var parts = location.split('/');
    if (parts.isNotEmpty && parts[0].isEmpty)
      parts.removeAt(0);
    var stackName = parts.isNotEmpty ? parts.removeAt(0) : null;
    var segments = parts.map((segment) {
      var d = router.definitionForPathSegment(segment);
      if (d==null)
        throw Exception("unrecognised segment $segment");
      return HenryRouteSegment.fromDefinitionAndPath(d,segment);
    }).toList();
    return HenryRouterState(
        stackName!,
        segments
    );
  }

  // RouteInformation -> HenryRoute
  @override
  Future<HenryRouterState> parseRouteInformation(RouteInformation routeInformation) async {
    return stateFromLocation(routeInformation.location!);
  }

  // HenryRoute -> RouteInformation
  @override
  RouteInformation? restoreRouteInformation(HenryRouterState configuration) {
    return RouteInformation(
      location: configuration.toLocation(),
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

  @override
  late final GlobalKey<NavigatorState> navigatorKey;

  List<HenrySegmentDefinition> definitions;

  HenryRouterState? state;

  HenryRouter({required this.definitions, required String initialPath}) {
    parser = HenryRouteParser(this);
    navigatorKey = GlobalKey<NavigatorState>();
    //setNewRoutePath(parser.stateFromLocation(initialPath));
  }

  @override
  HenryRouterState? get currentConfiguration {
    return state;
  }


  HenrySegmentDefinition? definitionForPathSegment(String segment) {
    for (var d in definitions) {
      if (HenrySegmentDefinition.getName(segment)==d.name)
        return d;
    }
    return null;
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

  void goto(String path) {
    var state = parser.stateFromLocation(path);
    setNewRoutePath(state);
  }

  _buildPage(String key, Widget widget) {
    return MaterialPage(
      key: ValueKey(key),
      child: widget
    );
  }

  List<Page<dynamic>> _buildPages() {
    return [
      _buildPage(
          'BooksListPage',
          BooksListScreen(
            books: books,
            onTapped: (book) {
              //_selectedBook = book;
              notifyListeners();
            },
          )
      ),
      // if (_selectedBook != null)
      //   BookDetailsPage(book: _selectedBook)
    ];
  }

  bool _onPopPage(Route<dynamic> route, dynamic result) {
    if (!route.didPop(result)) {
      return false;
    }

    // Update the list of pages by setting _selectedBook to null
    //_selectedBook = null;
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
  static final HenryRouter router = HenryRouter(
    initialPath: '/app/books',
    definitions: [
      HenrySegmentDefinition("books"),
      HenrySegmentDefinition("book;id&color;size")
    ]
  );

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
      routerDelegate: HenryExampleApp.router,
      routeInformationParser: HenryExampleApp.router.parser,
    );
  }
}
