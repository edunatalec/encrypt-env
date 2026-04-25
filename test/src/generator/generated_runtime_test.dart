import 'dart:io';

import 'package:encrypt_env/src/generator/case_style.dart';
import 'package:encrypt_env/src/generator/code_builder.dart';
import 'package:encrypt_env/src/strategy/aes_strategy.dart';
import 'package:encrypt_env/src/strategy/xor_strategy.dart';
import 'package:fortis/fortis.dart';
import 'package:test/test.dart';

/// End-to-end tests: generate the file, execute it via `dart run`, and assert
/// each getter returns the original YAML/JSON value.
///
/// The temp directory is created **inside the project root** so the spawned
/// `dart run` inherits the project's `package_config.json` — required so the
/// generated AES file can resolve `package:fortis/fortis.dart`.
void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.current.createTempSync('.tmp_e2e_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test(
    'XOR-encoded getters return original values when the file is executed',
    () async {
      final builder = CodeBuilder(
        caseStyle: CaseStyle.camelCase,
        strategy: XorStrategy(),
      );

      final generated = builder.build({
        'app': {
          'name': 'My App',
          'url': 'https://api.example.com/v1?key=abc&token=xyz',
          'special': r'!@#$%^&*()_+-={}[]|;:,.<>?',
          'port': 3000,
          'production': true,
          'rate': 1.5,
        },
      });

      final out = await _runGenerated(
        tempDir: tempDir,
        generated: generated,
        prints: const {
          'name': 'App.name',
          'url': 'App.url',
          'special': 'App.special',
          'port': 'App.port',
          'production': 'App.production',
          'rate': 'App.rate',
        },
      );

      expect(out['name'], 'My App');
      expect(out['url'], 'https://api.example.com/v1?key=abc&token=xyz');
      expect(out['special'], r'!@#$%^&*()_+-={}[]|;:,.<>?');
      expect(out['port'], '3000');
      expect(out['production'], 'true');
      expect(out['rate'], '1.5');
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );

  test(
    'AES-encoded getters return original values when the file is executed',
    () async {
      final key = await Fortis.aes().keySize(256).generateKey();
      final keyBase64 = key.toBase64();

      final builder = CodeBuilder(
        caseStyle: CaseStyle.camelCase,
        strategy: AesStrategy(key: keyBase64),
      );

      final generated = builder.build({
        'app': {
          'name': 'My App',
          'url': 'https://api.example.com/v1?key=abc&token=xyz',
          'special': r'!@#$%^&*()_+-={}[]|;:,.<>?',
          'port': 3000,
          'production': true,
          'rate': 1.5,
        },
      });

      final out = await _runGenerated(
        tempDir: tempDir,
        generated: generated,
        setup: "EncryptEnv.init('$keyBase64');",
        prints: const {
          'name': 'App.name',
          'url': 'App.url',
          'special': 'App.special',
          'port': 'App.port',
          'production': 'App.production',
          'rate': 'App.rate',
        },
      );

      expect(out['name'], 'My App');
      expect(out['url'], 'https://api.example.com/v1?key=abc&token=xyz');
      expect(out['special'], r'!@#$%^&*()_+-={}[]|;:,.<>?');
      expect(out['port'], '3000');
      expect(out['production'], 'true');
      expect(out['rate'], '1.5');
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );

  test(
    'XOR-encoded nested map covers String, int, double and bool',
    () async {
      final builder = CodeBuilder(
        caseStyle: CaseStyle.camelCase,
        strategy: XorStrategy(),
      );

      final generated = builder.build({
        'api': {
          'config': {
            'base_url': 'https://api.example.com',
            'port': 8080,
            'timeout': 1.5,
            'secure': true,
          },
        },
      });

      final out = await _runGenerated(
        tempDir: tempDir,
        generated: generated,
        prints: const {
          'baseUrl': "Api.config['base_url']",
          'port': "Api.config['port']",
          'timeout': "Api.config['timeout']",
          'secure': "Api.config['secure']",
        },
      );

      expect(out['baseUrl'], 'https://api.example.com');
      expect(out['port'], '8080');
      expect(out['timeout'], '1.5');
      expect(out['secure'], 'true');
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );

  test(
    'AES-encoded nested map covers String, int, double and bool',
    () async {
      final key = await Fortis.aes().keySize(256).generateKey();
      final keyBase64 = key.toBase64();

      final builder = CodeBuilder(
        caseStyle: CaseStyle.camelCase,
        strategy: AesStrategy(key: keyBase64),
      );

      final generated = builder.build({
        'api': {
          'config': {
            'base_url': 'https://api.example.com',
            'port': 8080,
            'timeout': 1.5,
            'secure': true,
          },
        },
      });

      final out = await _runGenerated(
        tempDir: tempDir,
        generated: generated,
        setup: "EncryptEnv.init('$keyBase64');",
        prints: const {
          'baseUrl': "Api.config['base_url']",
          'port': "Api.config['port']",
          'timeout': "Api.config['timeout']",
          'secure': "Api.config['secure']",
        },
      );

      expect(out['baseUrl'], 'https://api.example.com');
      expect(out['port'], '8080');
      expect(out['timeout'], '1.5');
      expect(out['secure'], 'true');
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );

  test(
    'XOR-encoded deeply nested map (2 levels) decodes all primitive types',
    () async {
      final builder = CodeBuilder(
        caseStyle: CaseStyle.camelCase,
        strategy: XorStrategy(),
      );

      final generated = builder.build({
        'app': {
          'database': {
            'primary': {
              'host': 'db.example.com',
              'port': 5432,
              'pool_size': 2.5,
              'ssl': true,
            },
          },
        },
      });

      final out = await _runGenerated(
        tempDir: tempDir,
        generated: generated,
        prints: const {
          'host': "App.database['primary']['host']",
          'port': "App.database['primary']['port']",
          'poolSize': "App.database['primary']['pool_size']",
          'ssl': "App.database['primary']['ssl']",
        },
      );

      expect(out['host'], 'db.example.com');
      expect(out['port'], '5432');
      expect(out['poolSize'], '2.5');
      expect(out['ssl'], 'true');
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );

  test(
    'AES-encoded deeply nested map (2 levels) decodes all primitive types',
    () async {
      final key = await Fortis.aes().keySize(256).generateKey();
      final keyBase64 = key.toBase64();

      final builder = CodeBuilder(
        caseStyle: CaseStyle.camelCase,
        strategy: AesStrategy(key: keyBase64),
      );

      final generated = builder.build({
        'app': {
          'database': {
            'primary': {
              'host': 'db.example.com',
              'port': 5432,
              'pool_size': 2.5,
              'ssl': true,
            },
          },
        },
      });

      final out = await _runGenerated(
        tempDir: tempDir,
        generated: generated,
        setup: "EncryptEnv.init('$keyBase64');",
        prints: const {
          'host': "App.database['primary']['host']",
          'port': "App.database['primary']['port']",
          'poolSize': "App.database['primary']['pool_size']",
          'ssl': "App.database['primary']['ssl']",
        },
      );

      expect(out['host'], 'db.example.com');
      expect(out['port'], '5432');
      expect(out['poolSize'], '2.5');
      expect(out['ssl'], 'true');
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );
}

/// Writes [generated] + a `main` that prints each getter, runs it via
/// `dart run`, and returns a map of marker -> stringified value.
Future<Map<String, String>> _runGenerated({
  required Directory tempDir,
  required String generated,
  required Map<String, String> prints,
  String setup = '',
}) async {
  const marker = '__OUT__';

  final source = StringBuffer()
    ..writeln(generated)
    ..writeln('void main() {')
    ..writeln('  $setup');
  for (final entry in prints.entries) {
    source.writeln(
      "  print('$marker${entry.key}=' + (${entry.value}).toString());",
    );
  }
  source.writeln('}');

  final file = File('${tempDir.path}/check.dart');
  file.writeAsStringSync(source.toString());

  final result = await Process.run('dart', ['run', file.path]);
  if (result.exitCode != 0) {
    fail(
      'dart run failed (exitCode=${result.exitCode})\n'
      'stdout:\n${result.stdout}\n'
      'stderr:\n${result.stderr}\n'
      'source:\n${source.toString()}',
    );
  }

  final stdout = result.stdout as String;
  final out = <String, String>{};
  for (final key in prints.keys) {
    final match = RegExp(
      '^${RegExp.escape(marker)}${RegExp.escape(key)}=(.*)\$',
      multiLine: true,
    ).firstMatch(stdout);
    if (match == null) {
      fail('Marker $marker$key not found in stdout:\n$stdout');
    }
    out[key] = match.group(1)!;
  }
  return out;
}
