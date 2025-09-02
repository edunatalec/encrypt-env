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
  final String name;

  /// Creates a [CaseStyle] with the associated short name.
  const CaseStyle(this.name);
}
