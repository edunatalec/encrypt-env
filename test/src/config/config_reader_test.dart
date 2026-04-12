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
  });
}
