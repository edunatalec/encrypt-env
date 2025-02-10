/// Regular expression to match underscores (_) and hyphens (-),
/// used for splitting strings into words.
final RegExp regex = RegExp(r'[_-]');

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
        trim().toLowerCase().split(regex).where((element) {
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

    return text.isEmpty ? '' : text[0].toLowerCase() + text.substring(1);
  }
}
