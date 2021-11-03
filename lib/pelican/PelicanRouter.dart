import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
//import 'package:get_it/get_it.dart';

import 'PelicanRoute.dart';
import 'PelicanRouteSegment.dart';
import 'PelicanRouterState.dart';
import 'PelicanUtilities.dart';
import 'TransitionDelegate.dart';


class PelicanRouteResult {
  Widget? pageWidget;

  PelicanRouteResult({this.pageWidget});
}

@immutable
class PelicanRouteContext {
  final PelicanRoute route;
  final PelicanRouteSegment? segment;

  PelicanRouteContext(this.route,this.segment);

  PelicanRouteResult page(Widget pageWidget) {
    return PelicanRouteResult(pageWidget: pageWidget);
  }
}

typedef SegmentPageBuilder = Future<PelicanRouteResult> Function(PelicanRouteContext context);
typedef PelicanRedirectBuilder = Future<String> Function(String string);

@immutable
class SegmentTableEntry {
  final SegmentPageBuilder builder;
  final PelicanRouteSegment segment;
  const SegmentTableEntry(this.segment,this.builder);
}

@immutable
class RouteTable {
  final Map<String, PelicanRedirectBuilder>? redirects;
  late final List<SegmentTableEntry> segments;

  RouteTable(Map<String, SegmentPageBuilder> segments,{this.redirects}) {
    this.segments = segments.entries.map<SegmentTableEntry>((e) {
      return SegmentTableEntry(PelicanRouteSegment.fromPathSegment(e.key),e.value);
    }).toList();
  }



  // Future<PelicanRouteResult> segmentNotFound(PelicanRouteContext context) async {
  //   if (_routeNotFound != null) {
  //     return await _routeNotFound(context.route!.toPath());
  //   } else {
  //     return PelicanRouteResult(pageWidget: ErrorPage(text: "${context.path} doesn't exist"));
  //   }
  // }

  SegmentPageBuilder? matchRoute(PelicanRouteSegment segment) {
    for (var s in segments) {
      if (s.segment.name==segment.name)
        return s.builder;
    }
    return null;
  }

  Future<PelicanRouteResult> executeSegment(PelicanRouteContext context) async {
    print("executeSegment ${context.segment!.toPathSegment()}");
    var builder = matchRoute(context.segment!);
    if (builder==null)
      throw Exception("Segment route not matched");
    PelicanRouteResult buildResult = await builder(context);
    return buildResult;
  }

  PelicanRedirectBuilder? matchRedirect(String path) {
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

  Future<PelicanRoute> executeRedirectsRoute(PelicanRoute route) async {
    var path = route.toPath();
    var redirected = await executeRedirects(path);
    if (redirected == path)
      return route;
    else
      return PelicanRoute.fromPath(redirected);
  }

}

class PelicanRouteParser extends RouteInformationParser<PelicanRouterState> {
  PelicanRouter router;

  PelicanRouteParser(this.router);

  // RouteInformation -> PelicanRoute
  @override
  Future<PelicanRouterState> parseRouteInformation(RouteInformation routeInformation) async {
    print('parseRouteInformation RouteInformation ${routeInformation.location} -> PelicanRoute');
    var path = await router.routeTable.executeRedirects(routeInformation.location!);
    var route = PelicanRoute.fromPath(path);
    return PelicanRouterState(
        route
    );
  }

  // PelicanRoute -> RouteInformation
  @override
  RouteInformation? restoreRouteInformation(PelicanRouterState configuration) {
    var location = configuration.route.toPath();
    print('restoreRouteInformation PelicanRoute ${location} -> RouteInformation');
    return RouteInformation(
      location: location,
    );
  }
}


class PelicanRouter extends RouterDelegate<PelicanRouterState> with ChangeNotifier, PopNavigatorRouterDelegateMixin<PelicanRouterState> {

  late final PelicanRouteParser parser;
  late PelicanRouterState state;
  late final RouteTable routeTable;

  @override
  late final GlobalKey<NavigatorState> navigatorKey;

  List<Page>? _cachePages;
  PelicanRoute? _cacheRoute;

  late final List<NavigatorObserver> observers;

  PelicanRouter(
      String initialPath,
      this.routeTable,
      {this.observers = const []}
      ): super() {
    parser = PelicanRouteParser(this);
    navigatorKey = GlobalKey<NavigatorState>();
    state = PelicanRouterState(
        PelicanRoute.fromPath(initialPath)
    );
    state.addListener(notifyListeners);
  }

  @override
  void dispose() {
    state.removeListener(notifyListeners);
    super.dispose();
  }

  @override
  PelicanRouterState get currentConfiguration {
    return state;
  }

  @override
  Future<void> setRestoredRoutePath(PelicanRouterState configuration) {
    return setNewRoutePath(configuration);
  }


  @override
  Future<void> setInitialRoutePath(PelicanRouterState configuration) async {
    var newRoute = await routeTable.executeRedirectsRoute(configuration.route);
    if (!newRoute.equals(configuration.route)) {
      configuration.route = newRoute;
      await setNewRoutePath(configuration);
    }
  }

  @override
  Future<void> setNewRoutePath(PelicanRouterState configuration) async {
    if (configuration.route.equals(state.route))
      return;
    state.route = configuration.route;
  }

  Page<dynamic> _buildPage(String key, Widget widget) {
    return MaterialPage<dynamic>(
        key: ValueKey(key),
        child: widget
    );
  }



  Future<List<Page<dynamic>>> buildPages(BuildContext context) async {
    print('Router.buildPages');
    print("_pages is ${_cachePages==null ? 'not' : ''} set");
    var pages = List<Page<dynamic>>.empty(growable: true);
    var useCached = _cacheRoute!=null;
    for (var i=0; i<state.route.segments.length; i++) {
      var segment = state.route.segments[i];
      Page page;
      if (useCached && _cacheRoute!.segments.length>i && segment.equals(_cacheRoute!.segments[i])) {
        page = _cachePages![i];
        print("Use cached ${_cacheRoute!.segments[i].toPathSegment()}");
      } else {
        useCached = false;
        var prc = PelicanRouteContext(state.route, segment);
        var buildResult = await routeTable.executeSegment(prc);
        print("build ${segment.toPathSegment()}");
        page = _buildPage(segment.toPathSegment(),buildResult.pageWidget!);
      }
      pages.add(page);
    }

    _cacheRoute = state.route;
    var originalPages = _cachePages;
    if (originalPages?.isNotEmpty ?? false) {
      originalPages!.reversed.forEach((page) {
        if (pages.contains(page))
          return;
        var widget = as<MaterialPage<dynamic>>(page)?.child;
        //as<Disposable>(widget)?.onDispose();
      });
    }
    _cachePages = pages;
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
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: buildPages(context),
      initialData: [
        MaterialPage<dynamic>(child: Container(
          width: double.infinity,
          height: double.infinity,
          //child: Text('Please Wait')
        )),
      ],
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(child: Text(snapshot.error.toString()));
        } else if (snapshot.hasData) {
          return Navigator(
            key: navigatorKey,
            transitionDelegate: NoAnimationTransitionDelegate(),
            pages: snapshot.data! as List<Page<dynamic>>,
            onPopPage: _onPopPage,
            observers: observers,
          );
        } else {
          return CircularProgressIndicator();
        }
      }
    );
  }

  void push(String segmentPath) {
    state.push(segmentPath);
  }

  PelicanRouteSegment pop() {
    return state.pop();
  }

  bool get canPop => state.route.segments.length>1;

  Future<void> goto(String path) async {
    var newPath = await routeTable.executeRedirects(path);
    var route = PelicanRoute.fromPath(newPath);
    if (route.equals(state.route))
      return;
    state.route = route;
  }

  void replace(String segmentPath) {
    var route = state.route.popSegment();
    route = route.pushSegment(PelicanRouteSegment.fromPathSegment(segmentPath));
    state.route = route;
  }

  Page? getPage(String segmentName) {
    for (var i=state.route.segments.length-1; i>=0; i--) {
      if (_cacheRoute!.segments.length > i && _cacheRoute!.segments[i].name==segmentName)
        return _cachePages![i];
    }
    return null;
  }

  Widget? getPageWidget(String segmentName) {
    return (getPage(segmentName) as MaterialPage?)?.child;
  }
}
