import 'package:encrypt_env/src/utils/map.utils.dart';
import 'package:test/test.dart';

void main() {
  test('merge function', () {
    final Map a = {
      'key1': 1,
      'ke2': 'abc',
      'key3': {'a': 'a', 'b': 'b'},
      'key5': {'d': 'd'},
    };

    final Map b = {
      'ke2': 'abcd',
      'key3': {'a': 'b', 'c': 'c'},
      'key4': {'b': 'c'},
    };

    final Map matcher = {
      'key1': 1,
      'ke2': 'abcd',
      'key3': {'a': 'b', 'b': 'b', 'c': 'c'},
      'key4': {'b': 'c'},
      'key5': {'d': 'd'},
    };

    expect(a.merge(b), matcher);
  });

  test('prettify function should format a Map as a JSON string', () {
    final Map data = {
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

  test('prettify function should return an empty JSON object for an empty map',
      () {
    final Map emptyMap = {};

    expect(emptyMap.prettify(), '{}');
  });

  test('prettify function should format nested maps correctly', () {
    final Map nestedMap = {
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
}
