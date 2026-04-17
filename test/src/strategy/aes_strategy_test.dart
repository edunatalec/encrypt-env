import 'package:encrypt_env/src/strategy/aes_strategy.dart';
import 'package:fortis/fortis.dart';
import 'package:test/test.dart';

void main() {
  late AesStrategy strategy;
  late String testKey;

  setUp(() async {
    final key = await Fortis.aes().keySize(256).generateKey();
    testKey = key.toBase64();
    strategy = AesStrategy(key: testKey);
  });

  group('encode/decode roundtrip', () {
    test('roundtrips ASCII string', () {
      const value = 'hello world';
      final encoded = strategy.encode(value);
      final cipher =
          Fortis.aes().gcm().cipher(FortisAesKey.fromBase64(testKey));
      expect(cipher.decryptToString(encoded), value);
    });

    test('roundtrips URL string', () {
      const value = 'https://api.example.com/v1/users?key=abc123';
      final encoded = strategy.encode(value);
      final cipher =
          Fortis.aes().gcm().cipher(FortisAesKey.fromBase64(testKey));
      expect(cipher.decryptToString(encoded), value);
    });

    test('roundtrips numeric string', () {
      const value = '12345';
      final encoded = strategy.encode(value);
      final cipher =
          Fortis.aes().gcm().cipher(FortisAesKey.fromBase64(testKey));
      expect(cipher.decryptToString(encoded), value);
    });

    test('roundtrips boolean string', () {
      const value = 'true';
      final encoded = strategy.encode(value);
      final cipher =
          Fortis.aes().gcm().cipher(FortisAesKey.fromBase64(testKey));
      expect(cipher.decryptToString(encoded), value);
    });

    test('roundtrips special characters', () {
      const value = '!@#\$%^&*()_+-=[]{}|;:,.<>?';
      final encoded = strategy.encode(value);
      final cipher =
          Fortis.aes().gcm().cipher(FortisAesKey.fromBase64(testKey));
      expect(cipher.decryptToString(encoded), value);
    });

    test('roundtrips long string', () {
      final value = 'a' * 500;
      final encoded = strategy.encode(value);
      final cipher =
          Fortis.aes().gcm().cipher(FortisAesKey.fromBase64(testKey));
      expect(cipher.decryptToString(encoded), value);
    });
  });

  group('encode properties', () {
    test('produces different output on each call (random IV)', () {
      const value = 'test';
      final a = strategy.encode(value);
      final b = strategy.encode(value);
      expect(a, isNot(equals(b)));
    });

    test('output is a base64 string', () {
      final encoded = strategy.encode('test');
      expect(encoded, matches(RegExp(r'^[A-Za-z0-9+/]+=*$')));
    });
  });

  group('buildGetterBody', () {
    test('returns decryptToString call', () {
      final encoded = strategy.encode('test');
      final body = strategy.buildGetterBody(encoded);
      expect(body, contains("_cipher.decryptToString('$encoded')"));
    });
  });

  group('buildMapKeyDecode', () {
    test('returns decryptToString expression', () {
      final encoded = strategy.encode('key');
      final expr = strategy.buildMapKeyDecode(encoded);
      expect(expr, startsWith("EncryptEnv._cipher.decryptToString('"));
    });
  });

  group('decodeFunctionSource', () {
    test('contains EncryptEnv class', () {
      expect(
          strategy.decodeFunctionSource, contains('sealed class EncryptEnv'));
    });

    test('contains static init function', () {
      expect(strategy.decodeFunctionSource, contains('static void init('));
    });

    test('contains static _cipher declaration', () {
      expect(
        strategy.decodeFunctionSource,
        contains('static late AesAuthCipher _cipher'),
      );
    });

    test('contains FortisAesKey.fromBase64', () {
      expect(
        strategy.decodeFunctionSource,
        contains('FortisAesKey.fromBase64'),
      );
    });
  });

  group('imports', () {
    test('contains fortis import', () {
      expect(strategy.imports, contains("package:fortis/fortis.dart"));
    });
  });
}
