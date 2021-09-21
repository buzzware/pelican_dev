import 'package:flutter/widgets.dart';
import 'package:pelican_dev/pelican/PelicanRoute.dart';
import 'package:pelican_dev/pelican/PelicanRouteSegment.dart';

@immutable
class PelicanRouterState with ChangeNotifier {

  PelicanRoute _route;

  List<Page<dynamic>>? pages;

  PelicanRouterState(PelicanRoute route, {this.pages}) : _route = route;

  PelicanRoute get route => _route;
  set route(PelicanRoute route) {
    _route = route;
    notifyListeners();
  }

  void push(String segmentPath) {
    var segment = PelicanRouteSegment.fromPathSegment(segmentPath);
    pushSegment(segment);
  }

  void pushSegment(PelicanRouteSegment segment) {
    _route.segments.add(segment);
    notifyListeners();
  }

  PelicanRouteSegment pop() {
    final poppedItem = _route.segments.removeLast();
    notifyListeners();
    return poppedItem;
  }
}
