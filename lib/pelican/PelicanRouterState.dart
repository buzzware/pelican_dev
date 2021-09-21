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
    route = PelicanRoute(_route.segments + [segment]);
  }

  PelicanRouteSegment pop() {
    if (_route.segments.isEmpty)
      throw Exception("Can't pop when stack is empty");
    final poppedItem = _route.segments.last;
    route = PelicanRoute(_route.segments.sublist(0,_route.segments.length-1));
    print("pop ${poppedItem.toPathSegment()}");
    notifyListeners();
    return poppedItem;
  }
}
