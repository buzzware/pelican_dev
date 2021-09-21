import 'package:flutter/widgets.dart';
import 'package:pelican_dev/pelican/PelicanRouteSegment.dart';

@immutable
class PelicanRoute {
  late final String stackName;
  late final List<PelicanRouteSegment> segments;
  PelicanRoute(this.stackName, this.segments);

  String toPath() {
    var parts = segments.map<String>((s) => s.toPathSegment()).join('/');
    var result = "/$stackName/$parts";
    return result;
  }

  PelicanRoute.fromPath(String path) {
    var parts = path.split('/');
    if (parts.isNotEmpty && parts[0].isEmpty)
      parts.removeAt(0);
    stackName = parts.isNotEmpty ? parts.removeAt(0) : '';
    segments = parts.map((p)=>PelicanRouteSegment.fromPathSegment(p)).toList();
  }
}
