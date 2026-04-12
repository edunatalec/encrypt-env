import 'package:fortis/fortis.dart';

import 'obfuscation_strategy.dart';

/// AES-256-GCM encryption strategy using the fortis library.
///
/// Values are encrypted at build time with a provided key.
/// The generated file requires `init(key)` to be called at runtime
/// before accessing any values.
class AesStrategy implements ObfuscationStrategy {
  /// The AES cipher used for encryption.
  final AesCipher _cipher;

  /// Creates an [AesStrategy] with the given base64-encoded [key].
  AesStrategy({required String key})
      : _cipher =
            Fortis.aes().mode(AesMode.gcm).cipher(FortisAesKey.fromBase64(key));

  @override
  String encode(String value) {
    return _cipher.encryptToString(value);
  }

  @override
  String buildGetterBody(String encoded) {
    return "\t\treturn _cipher.decryptToString('$encoded')";
  }

  @override
  String buildMapKeyDecode(String encoded) {
    return "_cipher.decryptToString('$encoded')";
  }

  @override
  String get decodeFunctionSource => '''
late AesCipher _cipher;

/// Initializes the decryption cipher with the provided base64-encoded [key].
///
/// Must be called before accessing any environment values.
void init(String key) {
  _cipher = Fortis.aes().mode(AesMode.gcm).cipher(FortisAesKey.fromBase64(key));
}''';

  @override
  String get imports => "import 'package:fortis/fortis.dart';\n";
}
