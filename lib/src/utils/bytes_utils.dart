import 'dart:math';
import 'dart:typed_data';

/// Shared cryptographically-secure PRNG. Instantiating `Random.secure()` is
/// expensive (each call reads from the OS entropy pool), so we reuse one
/// instance across all encoding operations.
final Random secureRandom = Random.secure();

/// Generates a secure random byte array of the given [length].
Uint8List randomBytes(int length) {
  final Uint8List bytes = Uint8List(length);

  for (int i = 0; i < length; i++) {
    bytes[i] = secureRandom.nextInt(256);
  }

  return bytes;
}

/// Converts a list of integers into a hex representation.
///
/// Example:
/// ```dart
/// listToHex([255, 16, 32]); // "0xff, 0x10, 0x20"
/// ```
String listToHex(List<int> list) {
  return list.map((e) => '0x${e.toRadixString(16).padLeft(2, '0')}').join(', ');
}

/// Derives a deterministic seed from a list of bytes using FNV-1a hashing.
int seedFromSalt(List<int> salt) {
  int s = 0x5f3759df;

  for (final int b in salt) {
    s = ((s ^ b) * 0x01000193) & 0xFFFFFFFF;
  }

  return s;
}

/// Generates a deterministic permutation of indices [0..length-1]
/// using Fisher-Yates shuffle with a Linear Congruential Generator (LCG).
List<int> generatePermutation(int length, int seed) {
  final List<int> perm = List<int>.generate(length, (i) => i);

  int s = seed;
  for (int i = length - 1; i > 0; i--) {
    s = ((s * 1103515245) + 12345) & 0x7FFFFFFF;
    final int j = s % (i + 1);
    final int tmp = perm[i];
    perm[i] = perm[j];
    perm[j] = tmp;
  }

  return perm;
}
