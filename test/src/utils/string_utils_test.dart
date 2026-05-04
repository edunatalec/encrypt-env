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

    test('preserves camelCase boundaries when input is already camelCase', () {
      expect('minConnections'.toPascalCase(), 'MinConnections');
      expect('helloWorld'.toPascalCase(), 'HelloWorld');
    });

    test('handles all-caps blocks (acronyms)', () {
      expect('IDLE_timeout'.toPascalCase(), 'IdleTimeout');
      expect('HTTPServer'.toPascalCase(), 'HttpServer');
    });

    test('handles chaotic mix of separators and casings', () {
      expect(
        'mixed_camelCase-stuff'.toPascalCase(),
        'MixedCamelCaseStuff',
      );
      expect('SCREAM_CASE'.toPascalCase(), 'ScreamCase');
      expect('with space'.toPascalCase(), 'WithSpace');
      expect('KEY-with_mix space'.toPascalCase(), 'KeyWithMixSpace');
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

    test('preserves camelCase boundaries when input is already camelCase', () {
      expect('minConnections'.toCamelCase(), 'minConnections');
      expect('helloWorld'.toCamelCase(), 'helloWorld');
    });

    test('handles all-caps blocks (acronyms)', () {
      expect('IDLE_timeout'.toCamelCase(), 'idleTimeout');
      expect('HTTPServer'.toCamelCase(), 'httpServer');
    });

    test('handles chaotic mix of separators and casings', () {
      expect(
        'mixed_camelCase-stuff'.toCamelCase(),
        'mixedCamelCaseStuff',
      );
      expect('SCREAM_CASE'.toCamelCase(), 'screamCase');
      expect('with space'.toCamelCase(), 'withSpace');
      expect('KEY-with_mix space'.toCamelCase(), 'keyWithMixSpace');
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

    test('lowercases the entire word', () {
      expect('Hello_World'.toSnakeCase(), 'hello_world');
    });

    test('handles whitespace', () {
      expect('  hello_world  '.toSnakeCase(), 'hello_world');
      expect('with space'.toSnakeCase(), 'with_space');
    });

    test('separates camelCase boundaries', () {
      expect('helloWorld'.toSnakeCase(), 'hello_world');
      expect('minConnections'.toSnakeCase(), 'min_connections');
    });

    test('separates PascalCase boundaries', () {
      expect('HelloWorld'.toSnakeCase(), 'hello_world');
    });

    test('separates consecutive uppercase runs before lowercase', () {
      expect('HTTPServer'.toSnakeCase(), 'http_server');
    });

    test('separates camelCase with digits', () {
      expect('user2Profile'.toSnakeCase(), 'user2_profile');
    });

    test('handles chaotic mix of separators and casings', () {
      expect(
        'mixed_camelCase-stuff'.toSnakeCase(),
        'mixed_camel_case_stuff',
      );
      expect('IDLE_timeout'.toSnakeCase(), 'idle_timeout');
      expect('KEY-with_mix space'.toSnakeCase(), 'key_with_mix_space');
    });
  });

  group('toScreamingSnakeCase', () {
    test('converts hyphenated', () {
      expect('hello-world'.toScreamingSnakeCase(), 'HELLO_WORLD');
    });

    test('preserves underscore separators', () {
      expect('hello_world'.toScreamingSnakeCase(), 'HELLO_WORLD');
    });

    test('handles single character', () {
      expect('a'.toScreamingSnakeCase(), 'A');
    });

    test('handles empty string', () {
      expect(''.toScreamingSnakeCase(), '');
    });

    test('handles whitespace', () {
      expect('with space'.toScreamingSnakeCase(), 'WITH_SPACE');
      expect('  hello_world  '.toScreamingSnakeCase(), 'HELLO_WORLD');
    });

    test('separates camelCase boundaries', () {
      expect('helloWorld'.toScreamingSnakeCase(), 'HELLO_WORLD');
      expect('minConnections'.toScreamingSnakeCase(), 'MIN_CONNECTIONS');
    });

    test('separates PascalCase boundaries', () {
      expect('HelloWorld'.toScreamingSnakeCase(), 'HELLO_WORLD');
    });

    test('separates consecutive uppercase runs before lowercase', () {
      expect('HTTPServer'.toScreamingSnakeCase(), 'HTTP_SERVER');
    });

    test('separates camelCase with digits', () {
      expect('user2Profile'.toScreamingSnakeCase(), 'USER2_PROFILE');
    });

    test('already-screaming snake stays the same', () {
      expect('IDLE_TIMEOUT'.toScreamingSnakeCase(), 'IDLE_TIMEOUT');
    });

    test('handles chaotic mix of separators and casings', () {
      expect(
        'mixed_camelCase-stuff'.toScreamingSnakeCase(),
        'MIXED_CAMEL_CASE_STUFF',
      );
      expect('IDLE_timeout'.toScreamingSnakeCase(), 'IDLE_TIMEOUT');
      expect(
        'KEY-with_mix space'.toScreamingSnakeCase(),
        'KEY_WITH_MIX_SPACE',
      );
    });
  });
}
