/// Abstract contract for obfuscation/encryption strategies.
///
/// Implementations encode string values at build time and provide
/// the corresponding Dart decode function for the generated file.
abstract class ObfuscationStrategy {
  /// Encodes a string [value] into a hex-formatted string
  /// ready to embed in generated Dart source code.
  String encode(String value);

  /// Returns the Dart source code for the decode helper function(s)
  /// that will be embedded in the generated file.
  String get decodeFunctionSource;

  /// Returns the import statements required by the generated file.
  String get imports;
}
