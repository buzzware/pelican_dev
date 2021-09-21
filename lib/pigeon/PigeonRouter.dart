import 'package:flutter/material.dart';
import 'package:henry_dev/TransitionDelegate.dart';
import 'package:henry_dev/henry/PigeonRoute.dart';
import 'package:henry_dev/henry/PigeonRouteSegment.dart';
import 'package:henry_dev/henry/PigeonRouterState.dart';

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
class SegmentTableEntry {
  final SegmentPageBuilder builder;
  final HenryRouteSegment segment;
  const SegmentTableEntry(this.segment,this.builder);
}

@immutable
class RouteTable {
  final Map<String, HenryRedirectBuilder>? redirects;
  late final List<SegmentTableEntry> segments;

  RouteTable(Map<String, SegmentPageBuilder> segments,{this.redirects}) {
    this.segments = segments.entries.map<SegmentTableEntry>((e) {
      return SegmentTableEntry(HenryRouteSegment.fromPathSegment(e.key),e.value);
    }).toList();
  }



  // Future<HenryRouteResult> segmentNotFound(HenryRouteContext context) async {
  //   if (_routeNotFound != null) {
  //     return await _routeNotFound(context.route!.toPath());
  //   } else {
  //     return HenryRouteResult(pageWidget: ErrorPage(text: "${context.path} doesn't exist"));
  //   }
  // }

  SegmentPageBuilder? matchRoute(HenryRouteSegment segment) {
    for (var s in segments) {
      if (s.segment.name==segment.name)
        return s.builder;
    }
    return null;
  }

  Future<HenryRouteResult> executeSegment(HenryRouteContext context) async {
    print("executeSegment ${context.segment!.toPathSegment()}");
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
    state.addListener(notifyListeners);
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

  @override
  Future<void> setNewRoutePath(HenryRouterState configuration) async {
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
      var context = HenryRouteContext(state.route,segment);
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
