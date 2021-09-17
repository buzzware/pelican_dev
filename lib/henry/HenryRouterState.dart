import 'package:flutter/widgets.dart';
import 'package:henry_dev/henry/HenryRoute.dart';
import 'package:henry_dev/henry/HenryRouteSegment.dart';

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
