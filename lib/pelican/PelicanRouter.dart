import 'package:flutter/material.dart';
import 'package:pigeon_dev/TransitionDelegate.dart';
import 'package:pigeon_dev/pigeon/PelicanRoute.dart';
import 'package:pigeon_dev/pigeon/PelicanRouteSegment.dart';
import 'package:pigeon_dev/pigeon/PelicanRouterState.dart';

class PigeonRouteResult {
  Widget? pageWidget;
  String? redirectToPath;

  PigeonRouteResult({this.redirectToPath,this.pageWidget});
}

@immutable
class PigeonRouteContext {
  PigeonRoute route;
  PigeonRouteSegment? segment;

  PigeonRouteContext(this.route,this.segment);

  PigeonRouteResult page(Widget pageWidget) {
    return PigeonRouteResult(pageWidget: pageWidget);
  }

  PigeonRouteResult redirect(String path) {
    return PigeonRouteResult(redirectToPath: path);
  }
}

typedef SegmentPageBuilder = Future<PigeonRouteResult> Function(PigeonRouteContext context);
typedef PigeonRedirectBuilder = Future<String> Function(String string);

@immutable
class SegmentTableEntry {
  final SegmentPageBuilder builder;
  final PigeonRouteSegment segment;
  const SegmentTableEntry(this.segment,this.builder);
}

@immutable
class RouteTable {
  final Map<String, PigeonRedirectBuilder>? redirects;
  late final List<SegmentTableEntry> segments;

  RouteTable(Map<String, SegmentPageBuilder> segments,{this.redirects}) {
    this.segments = segments.entries.map<SegmentTableEntry>((e) {
      return SegmentTableEntry(PigeonRouteSegment.fromPathSegment(e.key),e.value);
    }).toList();
  }



  // Future<PigeonRouteResult> segmentNotFound(PigeonRouteContext context) async {
  //   if (_routeNotFound != null) {
  //     return await _routeNotFound(context.route!.toPath());
  //   } else {
  //     return PigeonRouteResult(pageWidget: ErrorPage(text: "${context.path} doesn't exist"));
  //   }
  // }

  SegmentPageBuilder? matchRoute(PigeonRouteSegment segment) {
    for (var s in segments) {
      if (s.segment.name==segment.name)
        return s.builder;
    }
    return null;
  }

  Future<PigeonRouteResult> executeSegment(PigeonRouteContext context) async {
    print("executeSegment ${context.segment!.toPathSegment()}");
    var builder = matchRoute(context.segment!);
    if (builder==null)
      throw Exception("Segment route not matched");
    PigeonRouteResult buildResult = await builder(context);
    return buildResult;
  }

  PigeonRedirectBuilder? matchRedirect(String path) {
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

class PigeonRouteParser extends RouteInformationParser<PigeonRouterState> {
  PigeonRouter router;

  PigeonRouteParser(this.router);

  // RouteInformation -> PigeonRoute
  @override
  Future<PigeonRouterState> parseRouteInformation(RouteInformation routeInformation) async {
    print('parseRouteInformation RouteInformation -> PigeonRoute');
    var path = await router.routeTable.executeRedirects(routeInformation.location!);
    var route = PigeonRoute.fromPath(path);
    return PigeonRouterState(
        route
    );
  }

  // PigeonRoute -> RouteInformation
  @override
  RouteInformation? restoreRouteInformation(PigeonRouterState configuration) {
    print('restoreRouteInformation PigeonRoute -> RouteInformation');
    return RouteInformation(
      location: configuration.route.toPath(),
    );
  }
}


class PigeonRouter extends RouterDelegate<PigeonRouterState> with ChangeNotifier, PopNavigatorRouterDelegateMixin<PigeonRouterState> {

  late final PigeonRouteParser parser;
  late PigeonRouterState state;
  late final RouteTable routeTable;

  @override
  late final GlobalKey<NavigatorState> navigatorKey;

  PigeonRouter(
      String initialPath,
      this.routeTable
      ): super() {
    parser = PigeonRouteParser(this);
    navigatorKey = GlobalKey<NavigatorState>();
    state = PigeonRouterState(
        PigeonRoute.fromPath(initialPath)
    );
    state.addListener(notifyListeners);
  }

  @override
  void dispose() {
    state.removeListener(notifyListeners);
    super.dispose();
  }

  @override
  PigeonRouterState get currentConfiguration {
    return state;
  }

  @override
  Future<void> setNewRoutePath(PigeonRouterState configuration) async {
    state.route = configuration.route;
  }

  _buildPage(String key, Widget widget) {
    return MaterialPage(
        key: ValueKey(key),
        child: widget
    );
  }

  Future<List<Page<dynamic>>> buildPages(BuildContext context) async {
    print('Router.buildPages');
    var pages = List<Page<dynamic>>.empty(growable: true);
    for (var segment in state.route.segments) {
      var context = PigeonRouteContext(state.route,segment);
      var buildResult = await routeTable.executeSegment(context);
      pages.add(_buildPage(segment.toPathSegment(),buildResult.pageWidget!));
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
    future: buildPages(context),
    initialData: [
      MaterialPage(child: Container(child: Text('Please Wait'))),
    ],
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Container(child: Text(snapshot.error.toString()));
      } else if (snapshot.hasData) {
        return Navigator(
          key: navigatorKey,
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
