import 'dart:convert';

extension MapExtenstion on Map {
  Map merge(Map map) {
    final Map newMap = {...this, ...map};

    for (final key in keys) {
      if (map.containsKey(key) && map[key] is Map) {
        newMap[key] = (this[key] as Map).merge(map[key]);
      }
    }

    return newMap;
  }

  String prettify() {
    const JsonEncoder encoder = JsonEncoder.withIndent('  ');

    return encoder.convert(this);
  }
}
