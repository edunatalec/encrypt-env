/// Represents the result of the generation process.
///
/// Contains the generated environment details and the file path where
/// the encrypted data was stored.
class GeneratorResponse {
  /// The formatted environment data as a string.
  final String environment;

  /// The file path where the encrypted environment file was saved.
  final String path;

  /// Creates a [GeneratorResponse] instance.
  ///
  /// Requires the generated [environment] data and the output file [path].
  GeneratorResponse({
    required this.environment,
    required this.path,
  });
}
