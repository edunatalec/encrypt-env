import 'dart:convert';

/// Extension providing additional utilities for `Map` objects.
extension MapExtenstion on Map {
  /// Merges the current map with another [map].
  ///
  /// - If both maps contain the same key and the value is a `Map`,
  ///   the nested values will also be merged recursively.
  /// - Otherwise, values from [map] override the existing values.
  ///
  /// Example:
  /// ```dart
  /// final map1 = {'a': 1, 'b': {'c': 2}};
  /// final map2 = {'b': {'d': 3}, 'e': 4};
  ///
  /// final merged = map1.merge(map2);
  /// print(merged); // {a: 1, b: {c: 2, d: 3}, e: 4}
  /// ```
  Map merge(Map map) {
    final Map newMap = {...this, ...map};

    for (final key in keys) {
      if (map.containsKey(key) && map[key] is Map) {
        newMap[key] = (this[key] as Map).merge(map[key]);
      }
    }

    return newMap;
  }

  /// Converts the map into a prettified JSON string.
  ///
  /// - Uses a two-space indentation for better readability.
  ///
  /// Example:
  /// ```dart
  /// final map = {'name': 'Alice', 'age': 25};
  /// print(map.prettify());
  /// ```
  /// Output:
  /// ```json
  /// {
  ///   "name": "Alice",
  ///   "age": 25
  /// }
  /// ```
  String prettify() {
    const JsonEncoder encoder = JsonEncoder.withIndent('  ');

    return encoder.convert(this);
  }
}
