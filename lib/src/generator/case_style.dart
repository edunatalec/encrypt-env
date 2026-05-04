import '../utils/string_utils.dart';

/// Defines the available formats for generated getter names.
enum CaseStyle {
  /// Uses SCREAMING_SNAKE_CASE format.
  ///
  /// Example: `MY_VARIABLE_NAME`
  screamingSnakeCase('ssc'),

  /// Uses camelCase format.
  ///
  /// Example: `myVariableName`
  camelCase('cc'),

  /// Uses snake_case format.
  ///
  /// Example: `my_variable_name`
  snakeCase('sc');

  /// The short identifier for the format.
  ///
  /// Used when specifying the format option in CLI.
  final String code;

  /// Creates a [CaseStyle] with the associated short [code].
  const CaseStyle(this.code);

  /// Formats [text] according to this case style.
  ///
  /// Example:
  /// ```dart
  /// CaseStyle.camelCase.format('hello_world');         // helloWorld
  /// CaseStyle.snakeCase.format('helloWorld');          // hello_world
  /// CaseStyle.screamingSnakeCase.format('helloWorld'); // HELLO_WORLD
  /// ```
  String format(String text) => switch (this) {
        CaseStyle.snakeCase => text.toSnakeCase(),
        CaseStyle.camelCase => text.toCamelCase(),
        CaseStyle.screamingSnakeCase => text.toScreamingSnakeCase(),
      };
}
