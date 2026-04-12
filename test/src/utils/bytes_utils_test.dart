import 'package:encrypt_env/src/utils/bytes_utils.dart';
import 'package:test/test.dart';

void main() {
  group('randomBytes', () {
    test('returns correct length', () {
      expect(randomBytes(16).length, 16);
      expect(randomBytes(64).length, 64);
      expect(randomBytes(1).length, 1);
    });

    test('returns different values on successive calls', () {
      final a = randomBytes(32);
      final b = randomBytes(32);
      expect(a, isNot(equals(b)));
    });
  });

  group('listToHex', () {
    test('formats single values correctly', () {
      expect(listToHex([0]), '0x00');
      expect(listToHex([255]), '0xff');
      expect(listToHex([16]), '0x10');
    });

    test('formats multiple values with comma separator', () {
      expect(listToHex([0, 255, 16]), '0x00, 0xff, 0x10');
    });

    test('handles empty list', () {
      expect(listToHex([]), '');
    });
  });

  group('seedFromSalt', () {
    test('is deterministic for same input', () {
      final salt = [1, 2, 3, 4, 5];
      expect(seedFromSalt(salt), seedFromSalt(salt));
    });

    test('produces different seeds for different inputs', () {
      expect(seedFromSalt([1, 2, 3]), isNot(seedFromSalt([4, 5, 6])));
    });

    test('handles single byte', () {
      final seed = seedFromSalt([42]);
      expect(seed, isA<int>());
    });
  });

  group('generatePermutation', () {
    test('is deterministic for same seed and length', () {
      final a = generatePermutation(10, 12345);
      final b = generatePermutation(10, 12345);
      expect(a, equals(b));
    });

    test('is a valid permutation', () {
      final perm = generatePermutation(20, 99999);
      final sorted = List<int>.from(perm)..sort();
      expect(sorted, List<int>.generate(20, (i) => i));
    });

    test('produces different permutations for different seeds', () {
      final a = generatePermutation(10, 111);
      final b = generatePermutation(10, 222);
      expect(a, isNot(equals(b)));
    });

    test('handles length 1', () {
      expect(generatePermutation(1, 42), [0]);
    });

    test('handles length 0', () {
      expect(generatePermutation(0, 42), <int>[]);
    });
  });
}
