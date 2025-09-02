import 'package:encrypt_env/src/utils/map_utils.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  test('merge function', () {
    final Map<String, dynamic> a = {
      'key1': 1,
      'ke2': 'abc',
      'key3': {'a': 'a', 'b': 'b'},
      'key5': {'d': 'd'},
    };

    final Map<String, dynamic> b = {
      'ke2': 'abcd',
      'key3': {'a': 'b', 'c': 'c'},
      'key4': {'b': 'c'},
    };

    final Map<String, dynamic> matcher = {
      'key1': 1,
      'ke2': 'abcd',
      'key3': {'a': 'b', 'b': 'b', 'c': 'c'},
      'key4': {'b': 'c'},
      'key5': {'d': 'd'},
    };

    expect(a.merge(b), matcher);
  });

  test('prettify function should format a Map as a JSON string', () {
    final Map<String, dynamic> data = {
      'name': 'Alice',
      'age': 25,
      'address': {'city': 'New York', 'zip': '10001'},
    };

    final String expectedJson = '''{
  "name": "Alice",
  "age": 25,
  "address": {
    "city": "New York",
    "zip": "10001"
  }
}''';

    expect(data.prettify(), expectedJson);
  });

  test(
    'prettify function should return an empty JSON object for an empty map',
    () {
      final Map<String, dynamic> emptyMap = {};

      expect(emptyMap.prettify(), '{}');
    },
  );

  test('prettify function should format nested maps correctly', () {
    final Map<String, dynamic> nestedMap = {
      'person': {
        'name': 'John',
        'details': {
          'age': 30,
          'languages': ['Dart', 'Python']
        }
      }
    };

    final String expectedJson = '''{
  "person": {
    "name": "John",
    "details": {
      "age": 30,
      "languages": [
        "Dart",
        "Python"
      ]
    }
  }
}''';

    expect(nestedMap.prettify(), expectedJson);
  });

  group('YamlMapExtension.convertToMap', () {
    test('converte mapa plano', () {
      const src = '''
name: app
version: 1.0.0
production: false
      ''';

      final root = loadYaml(src) as YamlMap;
      final map = root.convertToMap();

      expect(map, isA<Map<String, dynamic>>());
      expect(map['name'], 'app');
      expect(map['version'], '1.0.0');
      expect(map['production'], false);
    });

    test('converte mapa aninhado recursivamente', () {
      const src = '''
environment:
  headers:
    api-key: value
      ''';

      final root = loadYaml(src) as YamlMap;
      final map = root.convertToMap();

      expect(map['environment'], isA<Map<String, dynamic>>());
      final env = map['environment'] as Map<String, dynamic>;
      expect(env['headers'], isA<Map<String, dynamic>>());
      final headers = env['headers'] as Map<String, dynamic>;
      expect(headers['api-key'], 'value');
    });

    test('preserva YamlList sem conversão', () {
      const src = '''
endpoints:
  - a
  - b
      ''';

      final root = loadYaml(src) as YamlMap;
      final map = root.convertToMap();

      // Como a extensão não trata listas, o valor permanece YamlList
      expect(map['endpoints'], isA<YamlList>());
      final list = map['endpoints'] as YamlList;
      expect(list.length, 2);
      expect(list[0], 'a');
      expect(list[1], 'b');
    });

    test('chaves não string viram string', () {
      const src = '''
123: ok
true: yes
null: nada
      ''';

      final root = loadYaml(src) as YamlMap;
      final map = root.convertToMap();

      expect(map.containsKey('123'), isTrue);
      expect(map['123'], 'ok');
      expect(map.containsKey('true'), isTrue);
      expect(map['true'], 'yes');
      expect(map.containsKey('null'), isTrue);
      expect(map['null'], 'nada');
    });

    test('mapa vazio', () {
      const src = '{}';
      final root = loadYaml(src) as YamlMap;
      final map = root.convertToMap();

      expect(map, isEmpty);
    });

    test('aninhamento profundo', () {
      const src = '''
a:
  b:
    c:
      d: value
      ''';

      final root = loadYaml(src) as YamlMap;
      final map = root.convertToMap();

      expect(map['a'], isA<Map<String, dynamic>>());
      final a = map['a'] as Map<String, dynamic>;
      final b = a['b'] as Map<String, dynamic>;
      final c = b['c'] as Map<String, dynamic>;
      expect(c['d'], 'value');
    });
  });
}
