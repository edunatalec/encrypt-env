import 'dart:math';
import 'dart:typed_data';

/// Maximum size for key bytes.
const int _maxSize = 4096;

/// Minimum size for key bytes.
const int _minSize = 128;

/// Generates a random key size between [_minSize] and [_maxSize].
///
/// The size is determined using the current time in milliseconds as a seed.
int get keyBytesSize =>
    _minSize +
    Random(DateTime.now().millisecondsSinceEpoch).nextInt(_maxSize - _minSize);

/// Generates a secure random byte array of the given [length].
///
/// This is used for cryptographic operations requiring random bytes.
Uint8List randomBytes(int length) {
  final Random random = Random.secure();
  final Uint8List ret = Uint8List(length);

  for (int i = 0; i < length; i++) {
    ret[i] = random.nextInt(256);
  }

  return ret;
}

/// Converts a list of integers into a hexadecimal representation.
///
/// Each element in [list] is converted to a hex string prefixed with `0x`.
/// Example:
/// ```dart
/// listToHex([255, 16, 32]); // Output: "0xff, 0x10, 0x20"
/// ```
String listToHex(List<int> list) {
  return list
      .map((e) {
        return '0x'
            '${int.parse(e.toString().padLeft(2, '0')).toRadixString(16)}';
      })
      .toList()
      .join(', ');
}

/// Encodes a [value] string into a hexadecimal string using a [salt].
///
/// The encoding is performed using an XOR operation between each character
/// in the value and a corresponding character in the salt.
String stringToHex(String value, Uint8List salt) {
  return listToHex(_encode(value, String.fromCharCodes(salt)));
}

/// Encrypts a string using an XOR operation with a cipher key.
///
/// Each character in [string] is XOR'd with a character from [cipher].
/// The result is returned as a list of integers.
List<int> _encode(String string, String cipher) {
  return Iterable<int>.generate(string.length).toList().map((int e) {
    return string[e].codeUnits.first ^
        cipher[e % cipher.length].codeUnits.first;
  }).toList();
}
