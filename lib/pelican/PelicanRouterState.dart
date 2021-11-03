import 'package:flutter/widgets.dart';

import 'PelicanRoute.dart';
import 'PelicanRouteSegment.dart';

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
    route = route.pushSegment(segment);
  }

  PelicanRouteSegment pop() {
    if (_route.segments.isEmpty)
      throw Exception("Can't pop when stack is empty");
    final poppedItem = _route.segments.isNotEmpty ? _route.segments.last : null;
    route = _route.popSegment();
    print("pop ${poppedItem!.toPathSegment()}");
    notifyListeners();
    return poppedItem;
  }
}
