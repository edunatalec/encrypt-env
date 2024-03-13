import 'package:encrypt_env/src/utils/string.utils.dart';
import 'package:test/test.dart';

void main() {
  test('toPascalCase function', () {
    expect('hello_world'.toPascalCase(), equals('HelloWorld'));
    expect('hello_world_example_'.toPascalCase(), equals('HelloWorldExample'));
    expect('camel_case_example '.toPascalCase(), equals('CamelCaseExample'));
    expect('       snake_case       '.toPascalCase(), equals('SnakeCase'));
    expect(''.toPascalCase(), equals(''));
    expect('__'.toPascalCase(), equals(''));
    expect('_-'.toPascalCase(), equals(''));
  });

  test('toCamelCase function', () {
    expect('hello_world'.toCamelCase(), equals('helloWorld'));
    expect('hello_world_example_'.toCamelCase(), equals('helloWorldExample'));
    expect('camel_case_example '.toCamelCase(), equals('camelCaseExample'));
    expect('       snake_case       '.toCamelCase(), equals('snakeCase'));
    expect(''.toCamelCase(), equals(''));
    expect('__'.toCamelCase(), equals(''));
    expect('_-'.toCamelCase(), equals(''));
  });

  test('transformGetter function', () {
    expect('hello_world'.transformGetter(), equals('HELLO_WORLD'));
    expect(
      'hello_world_example_'.transformGetter(),
      equals('HELLO_WORLD_EXAMPLE'),
    );
    expect(
      'camel_case_example '.transformGetter(),
      equals('CAMEL_CASE_EXAMPLE'),
    );
    expect('       snake_case       '.transformGetter(), equals('SNAKE_CASE'));
    expect(
      '       snake_case       '.transformGetter(private: true),
      equals('_SNAKE_CASE'),
    );
    expect(''.transformGetter(), equals(''));
    expect('__'.transformGetter(), equals(''));
    expect('_-'.transformGetter(private: true), equals('_'));

    expect(
      'hello_world'.transformGetter(uppercase: false),
      equals('helloWorld'),
    );
    expect(
      'hello_world_example_'.transformGetter(uppercase: false),
      equals('helloWorldExample'),
    );
    expect(
      'camel_case_example '.transformGetter(uppercase: false),
      equals('camelCaseExample'),
    );
    expect(
      '       snake_case       '.transformGetter(uppercase: false),
      equals('snakeCase'),
    );
    expect(
      '       snake_case       '.transformGetter(
        uppercase: false,
        private: true,
      ),
      equals('_snakeCase'),
    );
    expect(''.transformGetter(uppercase: false), equals(''));
    expect('__'.transformGetter(uppercase: false), equals(''));
    expect('_-'.transformGetter(uppercase: false, private: true), equals('_'));
  });
}
