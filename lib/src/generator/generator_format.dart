/// Defines the available formats for generated getter names.
enum GeneratorFormat {
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
  final String name;

  /// Creates a [GeneratorFormat] with the associated short name.
  const GeneratorFormat(this.name);
}
