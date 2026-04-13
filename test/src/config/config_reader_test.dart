import 'dart:io';

import 'package:encrypt_env/src/config/config_reader.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('config_reader_test_');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('read', () {
    test('reads a simple YAML file', () async {
      File('${tempDir.path}/environment.yaml').writeAsStringSync(
        'base_url: http://localhost\nport: 3000',
      );

      final reader = ConfigReader(
        folderName: tempDir.path,
        configName: 'environment',
      );

      final data = await reader.read();
      expect(data['base_url'], 'http://localhost');
      expect(data['port'], 3000);
    });

    test('merges base and env config files', () async {
      File('${tempDir.path}/environment.yaml').writeAsStringSync(
        'base_url: http://localhost\nport: 3000',
      );
      File('${tempDir.path}/prod_environment.yaml').writeAsStringSync(
        'base_url: https://api.production.com',
      );

      final reader = ConfigReader(
        folderName: tempDir.path,
        configName: 'environment',
        env: 'prod',
      );

      final data = await reader.read();
      expect(data['base_url'], 'https://api.production.com');
      expect(data['port'], 3000);
    });

    test('reads nested YAML structures', () async {
      File('${tempDir.path}/environment.yaml').writeAsStringSync(
        'headers:\n  api_key: abc123\n  content_type: application/json',
      );

      final reader = ConfigReader(
        folderName: tempDir.path,
        configName: 'environment',
      );

      final data = await reader.read();
      expect(data['headers'], isA<Map>());
      expect(data['headers']['api_key'], 'abc123');
    });

    test('throws on missing file', () async {
      final reader = ConfigReader(
        folderName: tempDir.path,
        configName: 'nonexistent',
      );

      expect(() => reader.read(), throwsA(isA<String>()));
    });

    test('reads a .yml file', () async {
      File('${tempDir.path}/environment.yml').writeAsStringSync(
        'base_url: http://localhost\nport: 4000',
      );

      final reader = ConfigReader(
        folderName: tempDir.path,
        configName: 'environment',
      );

      final data = await reader.read();
      expect(data['base_url'], 'http://localhost');
      expect(data['port'], 4000);
    });

    test('reads a .json file', () async {
      File('${tempDir.path}/environment.json').writeAsStringSync(
        '{"base_url": "http://localhost", "port": 5000}',
      );

      final reader = ConfigReader(
        folderName: tempDir.path,
        configName: 'environment',
      );

      final data = await reader.read();
      expect(data['base_url'], 'http://localhost');
      expect(data['port'], 5000);
    });

    test('reads nested JSON structures', () async {
      File('${tempDir.path}/environment.json').writeAsStringSync(
        '{"headers": {"api_key": "abc123", "content_type": "application/json"}}',
      );

      final reader = ConfigReader(
        folderName: tempDir.path,
        configName: 'environment',
      );

      final data = await reader.read();
      expect(data['headers'], isA<Map>());
      expect(data['headers']['api_key'], 'abc123');
    });

    test('.yaml takes precedence over .yml and .json', () async {
      File('${tempDir.path}/environment.yaml').writeAsStringSync(
        'source: yaml',
      );
      File('${tempDir.path}/environment.yml').writeAsStringSync(
        'source: yml',
      );
      File('${tempDir.path}/environment.json').writeAsStringSync(
        '{"source": "json"}',
      );

      final reader = ConfigReader(
        folderName: tempDir.path,
        configName: 'environment',
      );

      final data = await reader.read();
      expect(data['source'], 'yaml');
    });

    test('.yml takes precedence over .json', () async {
      File('${tempDir.path}/environment.yml').writeAsStringSync(
        'source: yml',
      );
      File('${tempDir.path}/environment.json').writeAsStringSync(
        '{"source": "json"}',
      );

      final reader = ConfigReader(
        folderName: tempDir.path,
        configName: 'environment',
      );

      final data = await reader.read();
      expect(data['source'], 'yml');
    });

    test('merges base YAML with env JSON', () async {
      File('${tempDir.path}/environment.yaml').writeAsStringSync(
        'base_url: http://localhost\nport: 3000',
      );
      File('${tempDir.path}/prod_environment.json').writeAsStringSync(
        '{"base_url": "https://api.production.com"}',
      );

      final reader = ConfigReader(
        folderName: tempDir.path,
        configName: 'environment',
        env: 'prod',
      );

      final data = await reader.read();
      expect(data['base_url'], 'https://api.production.com');
      expect(data['port'], 3000);
    });

    test('throws on JSON array config', () async {
      File('${tempDir.path}/environment.json').writeAsStringSync(
        '[1, 2, 3]',
      );

      final reader = ConfigReader(
        folderName: tempDir.path,
        configName: 'environment',
      );

      expect(() => reader.read(), throwsA(isA<String>()));
    });

    test('error message lists all tried paths', () async {
      final reader = ConfigReader(
        folderName: tempDir.path,
        configName: 'missing',
      );

      try {
        await reader.read();
        fail('Should have thrown');
      } catch (e) {
        final error = e as String;
        expect(error, contains('.yaml'));
        expect(error, contains('.yml'));
        expect(error, contains('.json'));
      }
    });
  });
}
