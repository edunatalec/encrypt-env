import 'package:encrypt_env/src/generator/case_style.dart';
import 'package:encrypt_env/src/generator/code_builder.dart';
import 'package:encrypt_env/src/strategy/aes_strategy.dart';
import 'package:encrypt_env/src/strategy/xor_strategy.dart';
import 'package:fortis/fortis.dart';
import 'package:test/test.dart';

void main() {
  late CodeBuilder builder;

  setUp(() {
    builder = CodeBuilder(
      caseStyle: CaseStyle.camelCase,
      strategy: XorStrategy(),
    );
  });

  group('build', () {
    test('produces generated code header', () {
      final result = builder.build({
        'environment': {'key': 'value'},
      });
      expect(result, contains('GENERATED CODE - DO NOT MODIFY BY HAND'));
    });

    test('produces sealed class with PascalCase name', () {
      final result = builder.build({
        'my_environment': {'key': 'value'},
      });
      expect(result, contains('sealed class MyEnvironment'));
    });

    test('contains header comment', () {
      final result = builder.build({
        'environment': {'key': 'value'},
      });
      expect(result,
          contains('/* ******************************************** */'));
    });

    test('contains decode function from strategy', () {
      final result = builder.build({
        'environment': {'key': 'value'},
      });
      expect(result, contains('String _decode('));
    });

    test('generates String getter', () {
      final result = builder.build({
        'environment': {'base_url': 'http://localhost'},
      });
      expect(result, contains('static String get baseUrl'));
    });

    test('generates bool getter', () {
      final result = builder.build({
        'environment': {'production': false},
      });
      expect(result, contains('static bool get production'));
      expect(result, contains('bool.parse'));
    });

    test('generates int getter', () {
      final result = builder.build({
        'environment': {'port': 3000},
      });
      expect(result, contains('static int get port'));
      expect(result, contains('int.parse'));
    });

    test('generates double getter', () {
      final result = builder.build({
        'environment': {'rate': 1.5},
      });
      expect(result, contains('static double get rate'));
      expect(result, contains('double.parse'));
    });

    test('generates child class and accessor for nested maps', () {
      final result = builder.build({
        'environment': {
          'headers': {'api_key': 'abc123'},
        },
      });
      expect(result, contains('final class EnvironmentHeaders'));
      expect(result, contains('const EnvironmentHeaders._();'));
      expect(
        result,
        contains(
          'static EnvironmentHeaders get headers '
          '=> const EnvironmentHeaders._();',
        ),
      );
      expect(result, contains('/// The `headers` section.'));
      expect(result, contains('String get apiKey'));
    });

    test('generates toMap on every level', () {
      final result = builder.build({
        'environment': {
          'host': 'localhost',
          'headers': {'api_key': 'abc123'},
        },
      });
      expect(result, contains('static Map<String, dynamic> toMap()'));
      expect(result, contains('Map<String, dynamic> toMap()'));
      expect(result, contains('headers.toMap()'));
    });

    test('toMap doc dumps the full map as a Dart-style literal', () {
      final result = builder.build({
        'database': {
          'host': 'localhost',
          'port': 5432,
          'credentials': {
            'username': 'dev_user',
            'meta': {'rotated_at': 'never'},
          },
        },
      });
      // Top-level Database.toMap() doc dumps the entire tree as `{ ... }`,
      // wrapped in a fenced code block so DartDoc / IDE hovers preserve
      // line breaks instead of collapsing the literal into one long line.
      // Keys are quoted; string values are quoted, primitives are not.
      expect(result, contains('\t/// ```\n'));
      expect(result, contains('\t/// {\n'));
      expect(result, contains("\t///   'host': 'localhost',\n"));
      expect(result, contains("\t///   'port': 5432,\n"));
      expect(result, contains("\t///   'credentials': {\n"));
      expect(result, contains("\t///     'username': 'dev_user',\n"));
      expect(result, contains("\t///     'meta': {\n"));
      expect(result, contains("\t///       'rotated_at': 'never',\n"));
      expect(result, contains('\t///     },\n'));
      expect(result, contains('\t///   },\n'));
      expect(result, contains('\t/// }\n'));
    });

    test('emits child classes recursively for deeply nested maps', () {
      final result = builder.build({
        'database': {
          'credentials': {
            'meta': {'rotated_at': 'never'},
          },
        },
      });
      expect(result, contains('final class DatabaseCredentials'));
      expect(result, contains('final class DatabaseCredentialsMeta'));
      expect(
        result,
        contains(
          'DatabaseCredentialsMeta get meta '
          '=> const DatabaseCredentialsMeta._();',
        ),
      );
    });

    test('sibling sub-maps with shared keys do not collide', () {
      final result = builder.build({
        'services': {
          'auth': {'token': 'A'},
          'billing': {'token': 'B'},
        },
      });
      expect(result, contains('final class ServicesAuth'));
      expect(result, contains('final class ServicesBilling'));
      // Each sibling has its own scope: getter `token` lives inside its own
      // class, so there is no `_token` declared at the parent scope.
      expect(result, isNot(contains('static String get _token')));
    });

    test('generates multiple classes for multiple top-level keys', () {
      final result = builder.build({
        'environment': {'key': 'value'},
        'settings': {'debug': true},
      });
      expect(result, contains('sealed class Environment'));
      expect(result, contains('sealed class Settings'));
    });

    test('throws FormatException on null value', () {
      expect(
        () => builder.build({
          'environment': {'api_key': null},
        }),
        throwsA(
          isA<FormatException>()
              .having((e) => e.message, 'message', contains('api_key')),
        ),
      );
    });

    test('generates snake_case getter from camelCase YAML key', () {
      final b = CodeBuilder(
        caseStyle: CaseStyle.snakeCase,
        strategy: XorStrategy(),
      );
      final result = b.build({
        'env': {'apiBaseUrl': 'x'},
      });
      expect(result, contains('get api_base_url'));
    });

    test('generates SCREAMING_SNAKE_CASE getter from camelCase YAML key', () {
      final b = CodeBuilder(
        caseStyle: CaseStyle.screamingSnakeCase,
        strategy: XorStrategy(),
      );
      final result = b.build({
        'env': {'apiBaseUrl': 'x'},
      });
      expect(result, contains('get API_BASE_URL'));
    });
  });

  group('case styles', () {
    test('camelCase getters', () {
      final b = CodeBuilder(
        caseStyle: CaseStyle.camelCase,
        strategy: XorStrategy(),
      );
      final result = b.build({
        'env': {'base_url': 'http://localhost'},
      });
      expect(result, contains('get baseUrl'));
    });

    test('snake_case getters', () {
      final b = CodeBuilder(
        caseStyle: CaseStyle.snakeCase,
        strategy: XorStrategy(),
      );
      final result = b.build({
        'env': {'base_url': 'http://localhost'},
      });
      expect(result, contains('get base_url'));
    });

    test('SCREAMING_SNAKE_CASE getters', () {
      final b = CodeBuilder(
        caseStyle: CaseStyle.screamingSnakeCase,
        strategy: XorStrategy(),
      );
      final result = b.build({
        'env': {'base_url': 'http://localhost'},
      });
      expect(result, contains('get BASE_URL'));
    });
  });

  group('AES strategy', () {
    late CodeBuilder aesBuilder;

    setUp(() async {
      final key = await Fortis.aes().keySize(256).generateKey();
      aesBuilder = CodeBuilder(
        caseStyle: CaseStyle.camelCase,
        strategy: AesStrategy(key: key.toBase64()),
      );
    });

    test('contains fortis import', () {
      final result = aesBuilder.build({
        'environment': {'key': 'value'},
      });
      expect(result, contains("import 'package:fortis/fortis.dart'"));
    });

    test('contains EncryptEnv class with init', () {
      final result = aesBuilder.build({
        'environment': {'key': 'value'},
      });
      expect(result, contains('sealed class EncryptEnv'));
      expect(result, contains('static void init('));
    });

    test('contains static _cipher declaration', () {
      final result = aesBuilder.build({
        'environment': {'key': 'value'},
      });
      expect(result, contains('static late AesAuthCipher _cipher'));
    });

    test('getters use EncryptEnv._cipher.decryptToString', () {
      final result = aesBuilder.build({
        'environment': {'base_url': 'http://localhost'},
      });
      expect(result, contains('EncryptEnv._cipher.decryptToString'));
    });

    test('generates typed getters with parse', () {
      final result = aesBuilder.build({
        'environment': {'port': 3000},
      });
      expect(result, contains('int.parse'));
      expect(result, contains('_cipher.decryptToString'));
    });
  });
}
