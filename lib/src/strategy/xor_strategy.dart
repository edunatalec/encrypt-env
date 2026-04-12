import 'dart:math';
import 'dart:typed_data';

import '../utils/bytes_utils.dart';
import 'obfuscation_strategy.dart';

/// XOR-based obfuscation strategy with multiple layers.
///
/// Each value gets its own unique salt. The encoding process applies:
/// 1. XOR pass with per-value salt
/// 2. Byte shuffle using a deterministic permutation
/// 3. XOR pass with a derived key (reversed + bit-rotated salt)
/// 4. Salt is split into two fragments for storage
class XorStrategy implements ObfuscationStrategy {
  static const int _minSaltSize = 32;
  static const int _maxSaltSize = 64;

  @override
  String encode(String value) {
    final plainBytes = Uint8List.fromList(value.codeUnits);
    final saltSize =
        _minSaltSize + Random.secure().nextInt(_maxSaltSize - _minSaltSize + 1);
    final salt = randomBytes(saltSize);

    // Pass 1: XOR with salt
    final xored1 = _xor(plainBytes, salt);

    // Pass 2: Shuffle bytes
    final seed = seedFromSalt(salt);
    final perm = generatePermutation(xored1.length, seed);
    final shuffled = _applyShuffle(xored1, perm);

    // Pass 3: XOR with derived key
    final derivedKey = _deriveKey(salt);
    final xored2 = _xor(shuffled, derivedKey);

    // Fragment salt into 2 parts
    final splitPoint = 1 + Random.secure().nextInt(salt.length - 1);
    final f1 = salt.sublist(0, splitPoint);
    final f2 = salt.sublist(splitPoint);

    final encodedHex = listToHex(xored2);
    final f1Hex = listToHex(f1);
    final f2Hex = listToHex(f2);

    return '$encodedHex|$f1Hex|$f2Hex';
  }

  @override
  String get decodeFunctionSource => '''
String _decode(List<int> encoded, List<int> salt) {
  final dk = salt.reversed.map((b) => ((b >> 3) | (b << 5)) & 0xFF).toList();
  final u2 = List.generate(encoded.length, (i) => encoded[i] ^ dk[i % dk.length]);
  final p = _perm(encoded.length, _seed(salt));
  final us = List.generate(encoded.length, (i) => u2[p[i]]);
  return String.fromCharCodes(List.generate(us.length, (i) => us[i] ^ salt[i % salt.length]));
}

int _seed(List<int> salt) {
  var s = 0x5f3759df;
  for (final b in salt) {
    s = ((s ^ b) * 0x01000193) & 0xFFFFFFFF;
  }
  return s;
}

List<int> _perm(int length, int seed) {
  final p = List<int>.generate(length, (i) => i);
  var s = seed;
  for (var i = length - 1; i > 0; i--) {
    s = ((s * 1103515245) + 12345) & 0x7FFFFFFF;
    final j = s % (i + 1);
    final tmp = p[i];
    p[i] = p[j];
    p[j] = tmp;
  }
  return p;
}''';

  @override
  String buildGetterBody(String encoded) {
    final parts = encoded.split('|');
    return '\t\tfinal List<int> encoded = [${parts[0]}];\n'
        '\t\tfinal List<int> salt = [...[${parts[1]}], ...[${parts[2]}]];\n'
        '\n'
        '\t\treturn _decode(encoded, salt)';
  }

  @override
  String buildMapKeyDecode(String encoded) {
    final parts = encoded.split('|');
    return '_decode([${parts[0]}], [...[${parts[1]}], ...[${parts[2]}]])';
  }

  @override
  String get imports => '';

  List<int> _xor(List<int> data, List<int> key) {
    return List<int>.generate(
      data.length,
      (i) => data[i] ^ key[i % key.length],
    );
  }

  List<int> _applyShuffle(List<int> data, List<int> perm) {
    final result = List<int>.filled(data.length, 0);
    for (var i = 0; i < data.length; i++) {
      result[perm[i]] = data[i];
    }
    return result;
  }

  List<int> _deriveKey(Uint8List salt) {
    return salt.reversed.map((b) => ((b >> 3) | (b << 5)) & 0xFF).toList();
  }
}
