import 'package:flutter/widgets.dart';
import 'package:pigeon_dev/pigeon/PelicanRoute.dart';
import 'package:pigeon_dev/pigeon/PelicanRouteSegment.dart';

@immutable
class PigeonRouterState with ChangeNotifier {

  PigeonRoute _route;

  List<Page<dynamic>>? pages;

  PigeonRouterState(PigeonRoute route, {this.pages}) : _route = route;

  PigeonRoute get route => _route;
  set route(PigeonRoute route) {
    _route = route;
    notifyListeners();
  }

  void push(PigeonRouteSegment segment) {
    _route.segments.add(segment);
    notifyListeners();
  }

  PigeonRouteSegment pop() {
    final poppedItem = _route.segments.removeLast();
    notifyListeners();
    return poppedItem;
  }

}
