import 'dart:collection';

import 'package:flutter/material.dart';

bool linkedMapsEqual(LinkedHashMap<String, String> map1, LinkedHashMap<String, String> map2) {
  return map1.length==map2.length && map1.entries.every((e) {
    return map2.containsKey(e.key) && map2[e.key]==e.value;
  });
}

@immutable
class PelicanRouteSegment {
  late final String name;
  late final LinkedHashMap<String,String> params;
  late final LinkedHashMap<String,String> options;

  PelicanRouteSegment(this.name, this.params, this.options);

  static LinkedHashMap<String,String> mapFromValues(String values) {
    return LinkedHashMap<String,String>.fromIterable(values.isEmpty ? [] : values.split(';'),key: (i) => i.split('=')[0],value: (i) {
    var parts = i.split('=');
    return parts.length>1 ? parts[1] : '';
    });
  }

  static String getName(String segment) {
    var parts = segment.split(';');
    if (parts.isEmpty)
      throw Exception('segment is empty');
    return parts[0];
  }

  PelicanRouteSegment.fromPathSegment(String path) {
    var parts = path.split('+');
    var nameAndParams = parts[0];
    var optionsStr = parts.length > 1 ? parts[1] : '';
    List<String> nameAndParamsParts = nameAndParams.isNotEmpty ? nameAndParams.split(';') : [];
    name = nameAndParamsParts.isNotEmpty ? nameAndParamsParts.removeAt(0) : '';
    params = mapFromValues(nameAndParamsParts.join(';'));
    options = mapFromValues(optionsStr);
  }

  String toPathSegment({PelicanRouteSegment? definition}) {
    if (definition!=null && definition.name != name)
      throw Exception('definition name must match path name');

    var name_and_pars = [name];
    var ops = List<String>.empty(growable: true);
    if (definition!=null) {
      if (params.isNotEmpty) {
        for (var p in definition.params.keys) {
          if (params.containsKey(p)) {
            name_and_pars.add([p, params[p]].join('='));
          }
        }
      }
      if (options.isNotEmpty) {
        for (var op in definition.options.keys) {
          if (options.containsKey(op)) {
            ops.add([op, options[op]].join('='));
          }
        }
      }
    } else {
      for (var p in params.keys) {
        name_and_pars.add([p, params[p]].join('='));
      }
      for (var op in options.keys) {
        ops.add([op, options[op]].join('='));
      }
    }
    return [name_and_pars.join(';'), ops.join(';')].where((s) => s.isNotEmpty).join('+');
  }

  bool equals(PelicanRouteSegment other) {
    return name == other.name && linkedMapsEqual(params,other.params);
  }
}

