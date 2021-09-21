import 'package:flutter/widgets.dart';
import 'package:henry_dev/henry/PigeonRouteSegment.dart';

@immutable
class HenryRoute {
  late final String stackName;
  late final List<HenryRouteSegment> segments;
  HenryRoute(this.stackName, this.segments);

  String toPath() {
    var parts = segments.map<String>((s) => s.toPathSegment()).join('/');
    var result = "/$stackName/$parts";
    return result;
  }

  HenryRoute.fromPath(String path) {
    var parts = path.split('/');
    if (parts.isNotEmpty && parts[0].isEmpty)
      parts.removeAt(0);
    stackName = parts.isNotEmpty ? parts.removeAt(0) : '';
    segments = parts.map((p)=>HenryRouteSegment.fromPathSegment(p)).toList();
  }
}
