import 'package:encrypt_env/src/generator/case_style.dart';
import 'package:encrypt_env/src/generator/test_builder.dart';
import 'package:encrypt_env/src/strategy/aes_strategy.dart';
import 'package:encrypt_env/src/strategy/xor_strategy.dart';
import 'package:fortis/fortis.dart';
import 'package:test/test.dart';

void main() {
  late TestBuilder builder;

  setUp(() {
    builder = TestBuilder(
      caseStyle: CaseStyle.camelCase,
      strategy: XorStrategy(),
      importPath: 'package:consumer/environment.dart',
    );
  });

  group('string value escaping', () {
    test('escapes dollar sign to avoid Dart interpolation', () {
      final result = builder.build({
        'env': {'secret': r'password$123'},
      });
      expect(result, contains(r"'password\$123'"));
    });

    test('escapes backslash', () {
      final result = builder.build({
        'env': {'path': r'C:\Users'},
      });
      expect(result, contains(r"'C:\\Users'"));
    });

    test('escapes newline', () {
      final result = builder.build({
        'env': {'multiline': 'line1\nline2'},
      });
      expect(result, contains(r"'line1\nline2'"));
    });

    test('escapes single quote', () {
      final result = builder.build({
        'env': {'msg': "it's fine"},
      });
      expect(result, contains(r"'it\'s fine'"));
    });

    test('leaves double quote as-is inside single-quoted literal', () {
      final result = builder.build({
        'env': {'greeting': 'say "hi"'},
      });
      expect(result, contains("'say \"hi\"'"));
    });

    test('escapes dollar followed by braces', () {
      final result = builder.build({
        'env': {'template': r'${API}'},
      });
      expect(result, contains(r"'\${API}'"));
    });
  });

  group('structure', () {
    test('imports the configured package', () {
      final result = builder.build({
        'env': {'k': 'v'},
      });
      expect(result, contains("import 'package:consumer/environment.dart';"));
    });

    test('uses test package by default', () {
      final result = builder.build({
        'env': {'k': 'v'},
      });
      expect(result, contains("import 'package:test/test.dart';"));
    });

    test('uses flutter_test when flutter flag is set', () {
      final flutterBuilder = TestBuilder(
        caseStyle: CaseStyle.camelCase,
        strategy: XorStrategy(),
        importPath: 'package:x/x.dart',
        flutter: true,
      );
      final result = flutterBuilder.build({
        'env': {'k': 'v'},
      });
      expect(
          result, contains("import 'package:flutter_test/flutter_test.dart';"));
    });

    test('wraps each top-level key in its own group', () {
      final result = builder.build({
        'env': {'k': 'v'},
        'settings': {'debug': true},
      });
      expect(result, contains("group('Env'"));
      expect(result, contains("group('Settings'"));
    });

    test('typed value has isA assertion', () {
      final result = builder.build({
        'env': {'port': 3000},
      });
      expect(result, contains('isA<int>()'));
    });

    test('nested map produces a nested group with typed access', () {
      final result = builder.build({
        'env': {
          'headers': {'x': 'y'},
        },
      });
      expect(result, contains("group('headers'"));
      expect(result, contains('Env.headers.x'));
    });

    test('every level emits a toMap assertion', () {
      final result = builder.build({
        'env': {
          'host': 'localhost',
          'headers': {'x': 'y'},
        },
      });
      expect(result, contains('Env.toMap()'));
      expect(result, contains('Env.headers.toMap()'));
      expect(result, contains('isA<Map<String, dynamic>>()'));
    });
  });

  group('getter case style', () {
    String buildWith(CaseStyle style) {
      return TestBuilder(
        caseStyle: style,
        strategy: XorStrategy(),
        importPath: 'package:consumer/environment.dart',
      ).build({
        'env': {'base_url': 'http://localhost'},
      });
    }

    test('camelCase produces baseUrl getter access', () {
      final result = buildWith(CaseStyle.camelCase);
      expect(result, contains('Env.baseUrl'));
      expect(result, contains("test('baseUrl returns correct value'"));
    });

    test('snakeCase produces base_url getter access', () {
      final result = buildWith(CaseStyle.snakeCase);
      expect(result, contains('Env.base_url'));
      expect(result, contains("test('base_url returns correct value'"));
    });

    test('screamingSnakeCase produces BASE_URL getter access', () {
      final result = buildWith(CaseStyle.screamingSnakeCase);
      expect(result, contains('Env.BASE_URL'));
      expect(result, contains("test('BASE_URL returns correct value'"));
    });
  });

  group('strategy testSetup', () {
    test('emits AES setUpAll block when strategy provides testSetup', () async {
      final key = await Fortis.aes().keySize(256).generateKey();
      final aesBuilder = TestBuilder(
        caseStyle: CaseStyle.camelCase,
        strategy: AesStrategy(key: key.toBase64()),
        importPath: 'package:consumer/environment.dart',
      );

      final result = aesBuilder.build({
        'env': {'k': 'v'},
      });

      expect(result, contains('setUpAll'));
      expect(result, contains('EncryptEnv.init('));
    });
  });
}
