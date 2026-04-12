import 'package:encrypt_env/src/utils/string_utils.dart';
import 'package:test/test.dart';

void main() {
  group('toPascalCase', () {
    test('converts snake_case', () {
      expect('hello_world'.toPascalCase(), 'HelloWorld');
    });

    test('converts hyphenated', () {
      expect('my-variable'.toPascalCase(), 'MyVariable');
    });

    test('converts single word', () {
      expect('hello'.toPascalCase(), 'Hello');
    });

    test('handles empty string', () {
      expect(''.toPascalCase(), '');
    });

    test('handles multiple separators', () {
      expect('a_b-c_d'.toPascalCase(), 'ABCD');
    });

    test('handles whitespace', () {
      expect('  hello_world  '.toPascalCase(), 'HelloWorld');
    });
  });

  group('toCamelCase', () {
    test('converts snake_case', () {
      expect('hello_world'.toCamelCase(), 'helloWorld');
    });

    test('converts hyphenated', () {
      expect('my-variable'.toCamelCase(), 'myVariable');
    });

    test('converts single word', () {
      expect('hello'.toCamelCase(), 'hello');
    });

    test('handles two-letter result as lowercase', () {
      expect('ab'.toCamelCase(), 'ab');
    });

    test('handles single-letter result as lowercase', () {
      expect('a'.toCamelCase(), 'a');
    });

    test('handles empty string', () {
      expect(''.toCamelCase(), '');
    });
  });

  group('toSnakeCase', () {
    test('converts hyphenated', () {
      expect('hello-world'.toSnakeCase(), 'hello_world');
    });

    test('preserves underscores', () {
      expect('hello_world'.toSnakeCase(), 'hello_world');
    });

    test('handles single character', () {
      expect('a'.toSnakeCase(), 'a');
    });

    test('handles empty string', () {
      expect(''.toSnakeCase(), '');
    });

    test('lowercases first character', () {
      expect('Hello_World'.toSnakeCase(), 'hello_World');
    });

    test('handles whitespace', () {
      expect('  hello_world  '.toSnakeCase(), 'hello_world');
    });
  });
}
