import 'package:encrypt_env/src/strategy/xor_strategy.dart';
import 'package:encrypt_env/src/utils/bytes_utils.dart';
import 'package:test/test.dart';

/// Simulates the runtime decode from the generated Dart file.
String decode(List<int> encoded, List<int> salt) {
  final dk = salt.reversed.map((b) => ((b >> 3) | (b << 5)) & 0xFF).toList();
  final u2 = List.generate(
    encoded.length,
    (i) => encoded[i] ^ dk[i % dk.length],
  );
  final p = generatePermutation(encoded.length, seedFromSalt(salt));
  final us = List.generate(encoded.length, (i) => u2[p[i]]);
  return String.fromCharCodes(
    List.generate(us.length, (i) => us[i] ^ salt[i % salt.length]),
  );
}

/// Parses encoded output from XorStrategy into components.
({List<int> encoded, List<int> salt}) parseEncoded(String output) {
  final parts = output.split('|');
  return (
    encoded: _parseHexList(parts[0]),
    salt: [..._parseHexList(parts[1]), ..._parseHexList(parts[2])],
  );
}

List<int> _parseHexList(String hex) {
  if (hex.isEmpty) return [];
  return hex.split(', ').map((e) => int.parse(e.trim())).toList();
}

void main() {
  late XorStrategy strategy;

  setUp(() {
    strategy = XorStrategy();
  });

  group('encode/decode roundtrip', () {
    test('roundtrips ASCII string', () {
      const value = 'hello world';
      final output = strategy.encode(value);
      final parsed = parseEncoded(output);
      expect(decode(parsed.encoded, parsed.salt), value);
    });

    test('roundtrips URL string', () {
      const value = 'https://api.example.com/v1/users?key=abc123';
      final output = strategy.encode(value);
      final parsed = parseEncoded(output);
      expect(decode(parsed.encoded, parsed.salt), value);
    });

    test('roundtrips numeric string', () {
      const value = '12345';
      final output = strategy.encode(value);
      final parsed = parseEncoded(output);
      expect(decode(parsed.encoded, parsed.salt), value);
    });

    test('roundtrips boolean string', () {
      const value = 'true';
      final output = strategy.encode(value);
      final parsed = parseEncoded(output);
      expect(decode(parsed.encoded, parsed.salt), value);
    });

    test('roundtrips single character', () {
      const value = 'x';
      final output = strategy.encode(value);
      final parsed = parseEncoded(output);
      expect(decode(parsed.encoded, parsed.salt), value);
    });

    test('roundtrips long string', () {
      final value = 'a' * 500;
      final output = strategy.encode(value);
      final parsed = parseEncoded(output);
      expect(decode(parsed.encoded, parsed.salt), value);
    });

    test('roundtrips special characters', () {
      const value = '!@#\$%^&*()_+-=[]{}|;:,.<>?';
      final output = strategy.encode(value);
      final parsed = parseEncoded(output);
      expect(decode(parsed.encoded, parsed.salt), value);
    });
  });

  group('encode properties', () {
    test('produces different output on each call', () {
      const value = 'test';
      final a = strategy.encode(value);
      final b = strategy.encode(value);
      expect(a, isNot(equals(b)));
    });

    test('output has 3 parts separated by pipe', () {
      final output = strategy.encode('test');
      final parts = output.split('|');
      expect(parts.length, 3);
    });

    test('each part contains hex values', () {
      final output = strategy.encode('test');
      final parts = output.split('|');
      for (final part in parts) {
        expect(part, matches(RegExp(r'^0x[0-9a-f]{2}(, 0x[0-9a-f]{2})*$')));
      }
    });
  });

  group('decodeFunctionSource', () {
    test('contains _decode function', () {
      expect(strategy.decodeFunctionSource, contains('String _decode('));
    });

    test('contains _seed function', () {
      expect(strategy.decodeFunctionSource, contains('int _seed('));
    });

    test('contains _perm function', () {
      expect(strategy.decodeFunctionSource, contains('List<int> _perm('));
    });
  });

  group('buildGetterBody', () {
    test('contains encoded list and salt fragments', () {
      final encoded = strategy.encode('test');
      final body = strategy.buildGetterBody(encoded);
      expect(body, contains('final List<int> encoded'));
      expect(body, contains('final List<int> salt'));
      expect(body, contains('_decode(encoded, salt)'));
    });
  });

  group('buildMapKeyDecode', () {
    test('returns _decode expression', () {
      final encoded = strategy.encode('key');
      final expr = strategy.buildMapKeyDecode(encoded);
      expect(expr, startsWith('_decode('));
    });
  });

  group('imports', () {
    test('is empty for XOR strategy', () {
      expect(strategy.imports, isEmpty);
    });
  });
}
