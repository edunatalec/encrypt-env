import 'dart:convert';

import 'package:yaml/yaml.dart';

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
  Map<String, dynamic> merge(Map<String, dynamic> map) {
    final Map<String, dynamic> newMap = {...this, ...map};

    for (final key in keys) {
      if (map.containsKey(key) && map[key] is Map<String, dynamic>) {
        newMap[key] = (this[key] as Map<String, dynamic>).merge(map[key]);
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

/// Extension to convert a [YamlMap] into a Dart `Map<String, dynamic>`.
extension YamlMapExtension on YamlMap {
  /// Recursively converts this [YamlMap] into a `Map<String, dynamic>`.
  Map<String, dynamic> convertToMap() {
    return _deepConvert(this) as Map<String, dynamic>;
  }

  dynamic _deepConvert(dynamic value) {
    if (value is YamlMap) {
      return Map<String, dynamic>.fromEntries(
        value.entries.map(
          (entry) => MapEntry(
            entry.key.toString(),
            _deepConvert(entry.value),
          ),
        ),
      );
    } else {
      return value;
    }
  }
}
