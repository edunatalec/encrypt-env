import 'package:encrypt_env/src/utils/map_utils.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('merge', () {
    test('merges non-overlapping keys', () {
      final result = {'a': 1}.merge({'b': 2});
      expect(result, {'a': 1, 'b': 2});
    });

    test('overrides values from second map', () {
      final result = {'a': 1}.merge({'a': 2});
      expect(result, {'a': 2});
    });

    test('merges nested maps recursively', () {
      final result = {
        'a': {'b': 1, 'c': 2},
      }.merge({
        'a': {'d': 3},
      });
      expect(result, {
        'a': {'b': 1, 'c': 2, 'd': 3},
      });
    });

    test('handles deeply nested maps', () {
      final result = {
        'a': {
          'b': {'c': 1},
        },
      }.merge({
        'a': {
          'b': {'d': 2},
        },
      });
      expect(result, {
        'a': {
          'b': {'c': 1, 'd': 2},
        },
      });
    });

    test('handles empty maps', () {
      expect(<String, dynamic>{}.merge({'a': 1}), {'a': 1});
      expect({'a': 1}.merge(<String, dynamic>{}), {'a': 1});
    });

    test('throws FormatException when base is primitive and override is Map',
        () {
      expect(
        () => <String, dynamic>{'port': 3000}.merge({
          'port': <String, dynamic>{'host': 'localhost'},
        }),
        throwsA(
          isA<FormatException>()
              .having((e) => e.message, 'message', contains('port')),
        ),
      );
    });
  });

  group('prettify', () {
    test('produces valid JSON', () {
      final result = {'name': 'Alice', 'age': 25}.prettify();
      expect(result, contains('"name": "Alice"'));
      expect(result, contains('"age": 25'));
    });

    test('handles empty map', () {
      expect(<String, dynamic>{}.prettify(), '{}');
    });

    test('handles nested maps', () {
      final result = {
        'a': {'b': 1},
      }.prettify();
      expect(result, contains('"a"'));
      expect(result, contains('"b": 1'));
    });
  });

  group('YamlMapExtension.convertToMap', () {
    test('converts flat YAML', () {
      final yaml = loadYaml('a: 1\nb: hello') as YamlMap;
      final result = yaml.convertToMap();
      expect(result, {'a': 1, 'b': 'hello'});
    });

    test('converts nested YAML', () {
      final yaml = loadYaml('a:\n  b: 1\n  c: 2') as YamlMap;
      final result = yaml.convertToMap();
      expect(result, {
        'a': {'b': 1, 'c': 2},
      });
    });

    test('preserves lists', () {
      final yaml = loadYaml('a:\n  - 1\n  - 2') as YamlMap;
      final result = yaml.convertToMap();
      expect(result['a'], isA<List>());
    });

    test('converts non-string keys to strings', () {
      final yaml = loadYaml('1: one\n2: two') as YamlMap;
      final result = yaml.convertToMap();
      expect(result.keys, everyElement(isA<String>()));
    });

    test('handles empty map', () {
      final yaml = loadYaml('{}') as YamlMap;
      expect(yaml.convertToMap(), <String, dynamic>{});
    });

    test('handles deep nesting', () {
      final yaml = loadYaml('a:\n  b:\n    c:\n      d: 1') as YamlMap;
      final result = yaml.convertToMap();
      expect(result, {
        'a': {
          'b': {
            'c': {'d': 1},
          },
        },
      });
    });
  });
}
