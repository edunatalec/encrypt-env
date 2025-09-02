import 'package:encrypt_env/src/utils/string_utils.dart';
import 'package:test/test.dart';

void main() {
  test('toPascalCase function', () {
    expect('hello_world'.toPascalCase(), 'HelloWorld');
    expect('hello_world_example_'.toPascalCase(), 'HelloWorldExample');
    expect('camel_case_example '.toPascalCase(), 'CamelCaseExample');
    expect('       SNAKE_CASE       '.toPascalCase(), 'SnakeCase');
    expect(''.toPascalCase(), '');
    expect('__'.toPascalCase(), '');
    expect('_-'.toPascalCase(), '');
  });

  test('toCamelCase function', () {
    expect('hello_world'.toCamelCase(), 'helloWorld');
    expect('hello_world_example_'.toCamelCase(), 'helloWorldExample');
    expect('camel_case_example '.toCamelCase(), 'camelCaseExample');
    expect('       SNAKE_CASE       '.toCamelCase(), 'snakeCase');
    expect(''.toCamelCase(), '');
    expect('__'.toCamelCase(), '');
    expect('_-'.toCamelCase(), '');
  });
}
