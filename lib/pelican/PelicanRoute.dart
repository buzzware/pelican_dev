import 'package:flutter/widgets.dart';
import 'package:pigeon_dev/pigeon/PelicanRouteSegment.dart';

@immutable
class PigeonRoute {
  late final String stackName;
  late final List<PigeonRouteSegment> segments;
  PigeonRoute(this.stackName, this.segments);

  String toPath() {
    var parts = segments.map<String>((s) => s.toPathSegment()).join('/');
    var result = "/$stackName/$parts";
    return result;
  }

  PigeonRoute.fromPath(String path) {
    var parts = path.split('/');
    if (parts.isNotEmpty && parts[0].isEmpty)
      parts.removeAt(0);
    stackName = parts.isNotEmpty ? parts.removeAt(0) : '';
    segments = parts.map((p)=>PigeonRouteSegment.fromPathSegment(p)).toList();
  }
}
