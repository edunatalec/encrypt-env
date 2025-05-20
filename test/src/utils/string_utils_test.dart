import 'package:encrypt_env/src/utils/string_utils.dart';
import 'package:test/test.dart';

void main() {
  test('toPascalCase function', () {
    expect('hello_world'.toPascalCase(), equals('HelloWorld'));
    expect('hello_world_example_'.toPascalCase(), equals('HelloWorldExample'));
    expect('camel_case_example '.toPascalCase(), equals('CamelCaseExample'));
    expect('       SNAKE_CASE       '.toPascalCase(), equals('SnakeCase'));
    expect(''.toPascalCase(), equals(''));
    expect('__'.toPascalCase(), equals(''));
    expect('_-'.toPascalCase(), equals(''));
  });

  test('toCamelCase function', () {
    expect('hello_world'.toCamelCase(), equals('helloWorld'));
    expect('hello_world_example_'.toCamelCase(), equals('helloWorldExample'));
    expect('camel_case_example '.toCamelCase(), equals('camelCaseExample'));
    expect('       SNAKE_CASE       '.toCamelCase(), equals('snakeCase'));
    expect(''.toCamelCase(), equals(''));
    expect('__'.toCamelCase(), equals(''));
    expect('_-'.toCamelCase(), equals(''));
  });
}
