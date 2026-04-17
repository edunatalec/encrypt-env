final RegExp _separatorRegex = RegExp(r'[_-]');

/// Extension providing utilities for converting strings into different case styles.
extension StringExtension on String {
  /// Converts a string to **PascalCase** (also known as UpperCamelCase).
  ///
  /// - Removes underscores (`_`) and hyphens (`-`).
  /// - Capitalizes the first letter of each word.
  ///
  /// Example:
  /// ```dart
  /// print('hello_world'.toPascalCase()); // HelloWorld
  /// print('my-variable'.toPascalCase()); // MyVariable
  /// ```
  String toPascalCase() {
    final List<String> words =
        trim().toLowerCase().split(_separatorRegex).where((element) {
      return element.isNotEmpty;
    }).toList();

    return words.fold('', (previousValue, element) {
      return previousValue + (element[0].toUpperCase() + element.substring(1));
    });
  }

  /// Converts a string to **camelCase** (first letter lowercase, rest PascalCase).
  ///
  /// - Uses `toPascalCase()` internally and converts the first letter to lowercase.
  ///
  /// Example:
  /// ```dart
  /// print('hello_world'.toCamelCase()); // helloWorld
  /// print('my-variable'.toCamelCase()); // myVariable
  /// ```
  String toCamelCase() {
    final String text = toPascalCase();

    return text.length <= 2
        ? text.toLowerCase()
        : text[0].toLowerCase() + text.substring(1);
  }

  /// Converts the current [String] into `snake_case`.
  ///
  /// Splits on underscores (`_`) and hyphens (`-`), joins with underscores,
  /// and lowercases the first character.
  ///
  /// If the string length is less than 2, returns it as-is.
  ///
  /// Example:
  /// ```dart
  /// print('hello-world'.toSnakeCase()); // "hello_world"
  /// print('hello_world'.toSnakeCase()); // "hello_world"
  /// ```
  String toSnakeCase() {
    String text = trim()
        .split(_separatorRegex)
        .where((element) => element.isNotEmpty)
        .toList()
        .join('_');

    text = text
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (m) => '${m[1]}_${m[2]}',
        )
        .replaceAllMapped(
          RegExp(r'([A-Z]+)([A-Z][a-z])'),
          (m) => '${m[1]}_${m[2]}',
        );

    return text.length < 2 ? text : text[0].toLowerCase() + text.substring(1);
  }
}
