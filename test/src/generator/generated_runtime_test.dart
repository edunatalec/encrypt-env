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
          'baseUrl': 'Api.config.baseUrl',
          'port': 'Api.config.port',
          'timeout': 'Api.config.timeout',
          'secure': 'Api.config.secure',
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
          'baseUrl': 'Api.config.baseUrl',
          'port': 'Api.config.port',
          'timeout': 'Api.config.timeout',
          'secure': 'Api.config.secure',
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
          'host': 'App.database.primary.host',
          'port': 'App.database.primary.port',
          'poolSize': 'App.database.primary.poolSize',
          'ssl': 'App.database.primary.ssl',
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
          'host': 'App.database.primary.host',
          'port': 'App.database.primary.port',
          'poolSize': 'App.database.primary.poolSize',
          'ssl': 'App.database.primary.ssl',
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
    'XOR-encoded sibling maps with shared keys decode independent values',
    () async {
      final CodeBuilder builder = CodeBuilder(
        caseStyle: CaseStyle.camelCase,
        strategy: XorStrategy(),
      );

      final String generated = builder.build({
        'services': {
          'auth': {
            'base_url': 'https://auth.example.com',
            'token': 'AUTH_TOKEN',
          },
          'billing': {
            'base_url': 'https://billing.example.com',
            'token': 'BILL_TOKEN',
          },
        },
      });

      final Map<String, String> out = await _runGenerated(
        tempDir: tempDir,
        generated: generated,
        prints: const {
          'authUrl': 'Services.auth.baseUrl',
          'authToken': 'Services.auth.token',
          'billingUrl': 'Services.billing.baseUrl',
          'billingToken': 'Services.billing.token',
        },
      );

      expect(out['authUrl'], 'https://auth.example.com');
      expect(out['authToken'], 'AUTH_TOKEN');
      expect(out['billingUrl'], 'https://billing.example.com');
      expect(out['billingToken'], 'BILL_TOKEN');
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );

  test(
    'AES-encoded sibling maps with shared keys decode independent values',
    () async {
      final key = await Fortis.aes().keySize(256).generateKey();
      final String keyBase64 = key.toBase64();

      final CodeBuilder builder = CodeBuilder(
        caseStyle: CaseStyle.camelCase,
        strategy: AesStrategy(key: keyBase64),
      );

      final String generated = builder.build({
        'services': {
          'auth': {
            'base_url': 'https://auth.example.com',
            'token': 'AUTH_TOKEN',
          },
          'billing': {
            'base_url': 'https://billing.example.com',
            'token': 'BILL_TOKEN',
          },
        },
      });

      final Map<String, String> out = await _runGenerated(
        tempDir: tempDir,
        generated: generated,
        setup: "EncryptEnv.init('$keyBase64');",
        prints: const {
          'authUrl': 'Services.auth.baseUrl',
          'authToken': 'Services.auth.token',
          'billingUrl': 'Services.billing.baseUrl',
          'billingToken': 'Services.billing.token',
        },
      );

      expect(out['authUrl'], 'https://auth.example.com');
      expect(out['authToken'], 'AUTH_TOKEN');
      expect(out['billingUrl'], 'https://billing.example.com');
      expect(out['billingToken'], 'BILL_TOKEN');
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );

  test(
    'toMap preserves original YAML keys across chaotic mix and many levels',
    () async {
      final CodeBuilder builder = CodeBuilder(
        caseStyle: CaseStyle.camelCase,
        strategy: XorStrategy(),
      );

      // A deliberately chaotic config: snake_case, kebab-case, camelCase,
      // SCREAM_CASE, mixed forms, spaces, all stacked across 3 levels.
      // Whatever the active caseStyle, `toMap()` at every level must echo
      // back the literal YAML keys, not the transformed getter names.
      final String generated = builder.build({
        'config': {
          'snake_case': 'snake',
          'kebab-case': 'kebab',
          'camelCase': 'camel',
          'SCREAM_CASE': 'scream',
          'mixed_camelCase-stuff': 'mixed',
          'with space': 'spaced',
          'level_one': {
            'inner_snake': 'i-snake',
            'innerCamel': 'i-camel',
            'INNER-KEBAB': 'i-kebab',
            'level_two': {
              'KEY-with_mix space': 'leaf-1',
              'final_leaf': 'leaf-2',
            },
          },
        },
      });

      final Map<String, String> out = await _runGenerated(
        tempDir: tempDir,
        generated: generated,
        prints: const {
          // Top-level Config.toMap() must contain every literal key.
          'top-snake': "Config.toMap()['snake_case']",
          'top-kebab': "Config.toMap()['kebab-case']",
          'top-camel': "Config.toMap()['camelCase']",
          'top-scream': "Config.toMap()['SCREAM_CASE']",
          'top-mixed': "Config.toMap()['mixed_camelCase-stuff']",
          'top-spaced': "Config.toMap()['with space']",
          // Going through Config.toMap() to reach nested keys also keeps
          // the originals at every depth.
          'top-l1-snake': "Config.toMap()['level_one']['inner_snake']",
          'top-l1-camel': "Config.toMap()['level_one']['innerCamel']",
          'top-l1-kebab': "Config.toMap()['level_one']['INNER-KEBAB']",
          'top-l2-mix':
              "Config.toMap()['level_one']['level_two']['KEY-with_mix space']",
          'top-l2-leaf':
              "Config.toMap()['level_one']['level_two']['final_leaf']",
          // Nested instance.toMap() also keeps the originals.
          'l1-snake': "Config.levelOne.toMap()['inner_snake']",
          'l1-camel': "Config.levelOne.toMap()['innerCamel']",
          'l1-kebab': "Config.levelOne.toMap()['INNER-KEBAB']",
          'l2-mix': "Config.levelOne.levelTwo.toMap()['KEY-with_mix space']",
          'l2-leaf': "Config.levelOne.levelTwo.toMap()['final_leaf']",
        },
      );

      expect(out['top-snake'], 'snake');
      expect(out['top-kebab'], 'kebab');
      expect(out['top-camel'], 'camel');
      expect(out['top-scream'], 'scream');
      expect(out['top-mixed'], 'mixed');
      expect(out['top-spaced'], 'spaced');

      expect(out['top-l1-snake'], 'i-snake');
      expect(out['top-l1-camel'], 'i-camel');
      expect(out['top-l1-kebab'], 'i-kebab');
      expect(out['top-l2-mix'], 'leaf-1');
      expect(out['top-l2-leaf'], 'leaf-2');

      expect(out['l1-snake'], 'i-snake');
      expect(out['l1-camel'], 'i-camel');
      expect(out['l1-kebab'], 'i-kebab');
      expect(out['l2-mix'], 'leaf-1');
      expect(out['l2-leaf'], 'leaf-2');
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );

  test(
    'toMap preserves original YAML keys under snake_case style as well',
    () async {
      // Sanity check: changing the getter case style must NOT affect the
      // map keys returned by toMap() — only the getter names.
      final CodeBuilder builder = CodeBuilder(
        caseStyle: CaseStyle.snakeCase,
        strategy: XorStrategy(),
      );

      final String generated = builder.build({
        'config': {
          'camelCase': 'a',
          'kebab-case': 'b',
          'with space': 'c',
          'level_one': {
            'INNER-KEBAB': 'd',
          },
        },
      });

      final Map<String, String> out = await _runGenerated(
        tempDir: tempDir,
        generated: generated,
        prints: const {
          'camel': "Config.toMap()['camelCase']",
          'kebab': "Config.toMap()['kebab-case']",
          'spaced': "Config.toMap()['with space']",
          'innerKebab': "Config.toMap()['level_one']['INNER-KEBAB']",
          'l1': "Config.level_one.toMap()['INNER-KEBAB']",
        },
      );

      expect(out['camel'], 'a');
      expect(out['kebab'], 'b');
      expect(out['spaced'], 'c');
      expect(out['innerKebab'], 'd');
      expect(out['l1'], 'd');
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
