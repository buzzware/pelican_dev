import 'package:flutter/widgets.dart';
import 'package:pelican_dev/pelican/PelicanRouteSegment.dart';

@immutable
class PelicanRoute {
  late final List<PelicanRouteSegment> _segments;
  List<PelicanRouteSegment> get segments => _segments;
  PelicanRoute(List<PelicanRouteSegment> segments) {
    _segments = List.unmodifiable(segments);
  }

  String toPath() {
    var parts = segments.map<String>((s) => s.toPathSegment()).join('/');
    var result = "/$parts";
    return result;
  }

  PelicanRoute.fromPath(String path) {
    var parts = path.split('/');
    if (parts.isNotEmpty && parts[0].isEmpty)
      parts.removeAt(0);
    _segments = List.unmodifiable(parts.map((p)=>PelicanRouteSegment.fromPathSegment(p)));
  }

  bool equals(PelicanRoute route) {
    return toPath()==route.toPath();
  }
}
