/// Abstract contract for obfuscation/encryption strategies.
///
/// Implementations encode string values at build time and provide
/// the corresponding Dart decode function for the generated file.
abstract class ObfuscationStrategy {
  /// Encodes a string [value] into an opaque format
  /// specific to the strategy implementation.
  String encode(String value);

  /// Builds the body of a getter that decodes the [encoded] value.
  ///
  /// Returns Dart source code lines for the getter body
  /// (without the getter signature or closing brace).
  String buildGetterBody(String encoded);

  /// Builds a decode expression for a map key from the [encoded] value.
  ///
  /// Returns a single Dart expression that evaluates to the decoded string.
  String buildMapKeyDecode(String encoded);

  /// Returns the Dart source code for the decode helper function(s)
  /// that will be embedded in the generated file.
  String get decodeFunctionSource;

  /// Returns the import statements required by the generated file.
  String get imports;

  /// Returns the test setup code (e.g., `setUpAll`) for the generated test file.
  ///
  /// Return an empty string if no setup is needed.
  String get testSetup;
}
