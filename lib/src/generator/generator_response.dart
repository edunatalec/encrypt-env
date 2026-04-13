/// Represents the result of the generation process.
///
/// Contains the generated environment details and the file paths where
/// the generated files were saved.
class GeneratorResponse {
  /// The formatted environment data as a string.
  final String environment;

  /// The file path where the generated Dart file was saved.
  final String path;

  /// The file path where the generated test file was saved.
  ///
  /// Null if test generation was disabled.
  final String? testPath;

  /// Creates a [GeneratorResponse] instance.
  GeneratorResponse({
    required this.environment,
    required this.path,
    this.testPath,
  });
}
