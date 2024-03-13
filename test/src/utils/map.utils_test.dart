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
}
