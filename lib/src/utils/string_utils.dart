final RegExp _separatorRegex = RegExp(r'[_\-\s]');

/// Extension providing utilities for converting strings into different case styles.
extension StringExtension on String {
  /// Converts a string to **PascalCase** (also known as UpperCamelCase).
  ///
  /// - Splits on underscores (`_`), hyphens (`-`), spaces, and existing
  ///   camelCase / PascalCase boundaries.
  /// - Capitalizes the first letter of each word; lowercases the rest.
  ///
  /// Example:
  /// ```dart
  /// print('hello_world'.toPascalCase());     // HelloWorld
  /// print('my-variable'.toPascalCase());     // MyVariable
  /// print('minConnections'.toPascalCase());  // MinConnections
  /// print('IDLE_timeout'.toPascalCase());    // IdleTimeout
  /// ```
  String toPascalCase() {
    return _splitWords().map(_capitalize).join('');
  }

  /// Converts a string to **camelCase** (first letter lowercase, rest PascalCase).
  ///
  /// - Uses `toPascalCase()` internally and converts the first letter to lowercase.
  ///
  /// Example:
  /// ```dart
  /// print('hello_world'.toCamelCase());     // helloWorld
  /// print('my-variable'.toCamelCase());     // myVariable
  /// print('minConnections'.toCamelCase());  // minConnections
  /// ```
  String toCamelCase() {
    final String text = toPascalCase();

    return text.length <= 2
        ? text.toLowerCase()
        : text[0].toLowerCase() + text.substring(1);
  }

  /// Converts the current [String] into canonical `snake_case`.
  ///
  /// - Splits on underscores (`_`), hyphens (`-`), spaces, and existing
  ///   camelCase / PascalCase boundaries.
  /// - Joins the resulting words with underscores and lowercases everything.
  ///
  /// Example:
  /// ```dart
  /// print('hello-world'.toSnakeCase());     // hello_world
  /// print('helloWorld'.toSnakeCase());      // hello_world
  /// print('HTTPServer'.toSnakeCase());      // http_server
  /// print('IDLE_timeout'.toSnakeCase());    // idle_timeout
  /// ```
  String toSnakeCase() {
    return _splitWords().map((word) => word.toLowerCase()).join('_');
  }

  /// Converts the current [String] into `SCREAMING_SNAKE_CASE`.
  ///
  /// - Splits on underscores (`_`), hyphens (`-`), spaces, and existing
  ///   camelCase / PascalCase boundaries.
  /// - Joins the resulting words with underscores and uppercases everything.
  ///
  /// Example:
  /// ```dart
  /// print('hello-world'.toScreamingSnakeCase());    // HELLO_WORLD
  /// print('helloWorld'.toScreamingSnakeCase());     // HELLO_WORLD
  /// print('IDLE_timeout'.toScreamingSnakeCase());   // IDLE_TIMEOUT
  /// ```
  String toScreamingSnakeCase() {
    return _splitWords().map((word) => word.toUpperCase()).join('_');
  }

  /// Splits this string into atomic words, breaking on `_`, `-`, whitespace,
  /// and camelCase / PascalCase boundaries (including acronyms followed by a
  /// capitalized word — e.g. `HTTPServer` → `['HTTP', 'Server']`).
  ///
  /// Used as the shared building block for [toPascalCase], [toCamelCase],
  /// [toSnakeCase], and [toScreamingSnakeCase].
  List<String> _splitWords() {
    final String joined = trim()
        .split(_separatorRegex)
        .where((element) => element.isNotEmpty)
        .join('_');

    final String separated = joined
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (m) => '${m[1]}_${m[2]}',
        )
        .replaceAllMapped(
          RegExp(r'([A-Z]+)([A-Z][a-z])'),
          (m) => '${m[1]}_${m[2]}',
        );

    return separated.split('_').where((element) => element.isNotEmpty).toList();
  }

  String _capitalize(String word) {
    if (word.isEmpty) return word;
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }
}
