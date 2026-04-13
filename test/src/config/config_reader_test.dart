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

    test('merges base JSON with env YML (complex config)', () async {
      File('${tempDir.path}/environment.json').writeAsStringSync('''
{
  "base_url": "http://localhost:3000",
  "version": "1.0.0",
  "port": 3000,
  "production": false,
  "max_retries": 3,
  "timeout": 30.5,
  "headers": {
    "content_type": "application/json",
    "api_key": "dev_key_123",
    "auth": {
      "token_prefix": "Bearer",
      "refresh_enabled": true
    }
  },
  "database": {
    "host": "localhost",
    "port": 5432,
    "ssl": false,
    "pool": {
      "min": 2,
      "max": 10
    }
  }
}''');
      File('${tempDir.path}/prod_environment.yml').writeAsStringSync('''
base_url: 'https://api.production.com'
production: true
port: 443
timeout: 10.0
headers:
  api_key: 'prod_key_abc'
  auth:
    refresh_enabled: false
database:
  host: 'db.production.com'
  ssl: true
  pool:
    min: 5
    max: 50
''');

      final reader = ConfigReader(
        folderName: tempDir.path,
        configName: 'environment',
        env: 'prod',
      );

      final data = await reader.read();
      expect(data['base_url'], 'https://api.production.com');
      expect(data['version'], '1.0.0');
      expect(data['port'], 443);
      expect(data['production'], true);
      expect(data['max_retries'], 3);
      expect(data['timeout'], 10.0);
      expect(data['headers']['content_type'], 'application/json');
      expect(data['headers']['api_key'], 'prod_key_abc');
      expect(data['headers']['auth']['token_prefix'], 'Bearer');
      expect(data['headers']['auth']['refresh_enabled'], false);
      expect(data['database']['host'], 'db.production.com');
      expect(data['database']['port'], 5432);
      expect(data['database']['ssl'], true);
      expect(data['database']['pool']['min'], 5);
      expect(data['database']['pool']['max'], 50);
    });

    test('merges base YML with env YAML (complex config)', () async {
      File('${tempDir.path}/environment.yml').writeAsStringSync('''
app_name: 'MyApp'
debug: true
log_level: 'verbose'
max_connections: 100
rate_limit: 60.0
features:
  dark_mode: true
  notifications: false
  analytics:
    enabled: false
    provider: 'none'
    tracking:
      events: true
      crashes: false
cache:
  enabled: true
  ttl: 3600
  strategy: 'lru'
''');
      File('${tempDir.path}/staging_environment.yaml').writeAsStringSync('''
debug: false
log_level: 'warn'
rate_limit: 120.5
features:
  notifications: true
  analytics:
    enabled: true
    provider: 'firebase'
    tracking:
      crashes: true
cache:
  ttl: 1800
''');

      final reader = ConfigReader(
        folderName: tempDir.path,
        configName: 'environment',
        env: 'staging',
      );

      final data = await reader.read();
      expect(data['app_name'], 'MyApp');
      expect(data['debug'], false);
      expect(data['log_level'], 'warn');
      expect(data['max_connections'], 100);
      expect(data['rate_limit'], 120.5);
      expect(data['features']['dark_mode'], true);
      expect(data['features']['notifications'], true);
      expect(data['features']['analytics']['enabled'], true);
      expect(data['features']['analytics']['provider'], 'firebase');
      expect(data['features']['analytics']['tracking']['events'], true);
      expect(data['features']['analytics']['tracking']['crashes'], true);
      expect(data['cache']['enabled'], true);
      expect(data['cache']['ttl'], 1800);
      expect(data['cache']['strategy'], 'lru');
    });

    test('merges base JSON with env JSON (complex config)', () async {
      File('${tempDir.path}/environment.json').writeAsStringSync('''
{
  "api_url": "http://localhost:8080",
  "ws_url": "ws://localhost:8080",
  "secure": false,
  "retry_delay": 1.5,
  "auth": {
    "provider": "local",
    "session_ttl": 86400,
    "oauth": {
      "client_id": "dev_client",
      "scopes": "read",
      "redirect": {
        "url": "http://localhost:3000/callback",
        "auto_close": true
      }
    }
  },
  "storage": {
    "type": "local",
    "max_size": 1048576,
    "encryption": false
  }
}''');
      File('${tempDir.path}/prod_environment.json').writeAsStringSync('''
{
  "api_url": "https://api.example.com",
  "ws_url": "wss://api.example.com",
  "secure": true,
  "retry_delay": 5.0,
  "auth": {
    "provider": "oauth2",
    "session_ttl": 3600,
    "oauth": {
      "client_id": "prod_client_xyz",
      "scopes": "read write admin",
      "redirect": {
        "url": "https://app.example.com/callback",
        "auto_close": false
      }
    }
  },
  "storage": {
    "type": "s3",
    "max_size": 10485760,
    "encryption": true
  }
}''');

      final reader = ConfigReader(
        folderName: tempDir.path,
        configName: 'environment',
        env: 'prod',
      );

      final data = await reader.read();
      expect(data['api_url'], 'https://api.example.com');
      expect(data['ws_url'], 'wss://api.example.com');
      expect(data['secure'], true);
      expect(data['retry_delay'], 5.0);
      expect(data['auth']['provider'], 'oauth2');
      expect(data['auth']['session_ttl'], 3600);
      expect(data['auth']['oauth']['client_id'], 'prod_client_xyz');
      expect(data['auth']['oauth']['scopes'], 'read write admin');
      expect(data['auth']['oauth']['redirect']['url'],
          'https://app.example.com/callback');
      expect(data['auth']['oauth']['redirect']['auto_close'], false);
      expect(data['storage']['type'], 's3');
      expect(data['storage']['max_size'], 10485760);
      expect(data['storage']['encryption'], true);
    });

    test('merges base YML with env JSON (complex config)', () async {
      File('${tempDir.path}/environment.yml').writeAsStringSync('''
service_name: 'payment-gateway'
enabled: true
version: 42
threshold: 0.75
gateway:
  provider: 'stripe'
  sandbox: true
  credentials:
    public_key: 'pk_test_123'
    secret_key: 'sk_test_456'
    webhook:
      url: 'http://localhost/webhook'
      secret: 'whsec_test'
      retries: 3
logging:
  level: 'debug'
  output: 'console'
  structured: false
''');
      File('${tempDir.path}/prod_environment.json').writeAsStringSync('''
{
  "enabled": true,
  "version": 43,
  "threshold": 0.95,
  "gateway": {
    "sandbox": false,
    "credentials": {
      "public_key": "pk_live_abc",
      "secret_key": "sk_live_def",
      "webhook": {
        "url": "https://api.example.com/webhook",
        "secret": "whsec_live_xyz",
        "retries": 5
      }
    }
  },
  "logging": {
    "level": "error",
    "output": "cloudwatch",
    "structured": true
  }
}''');

      final reader = ConfigReader(
        folderName: tempDir.path,
        configName: 'environment',
        env: 'prod',
      );

      final data = await reader.read();
      expect(data['service_name'], 'payment-gateway');
      expect(data['enabled'], true);
      expect(data['version'], 43);
      expect(data['threshold'], 0.95);
      expect(data['gateway']['provider'], 'stripe');
      expect(data['gateway']['sandbox'], false);
      expect(data['gateway']['credentials']['public_key'], 'pk_live_abc');
      expect(data['gateway']['credentials']['secret_key'], 'sk_live_def');
      expect(data['gateway']['credentials']['webhook']['url'],
          'https://api.example.com/webhook');
      expect(data['gateway']['credentials']['webhook']['secret'],
          'whsec_live_xyz');
      expect(data['gateway']['credentials']['webhook']['retries'], 5);
      expect(data['logging']['level'], 'error');
      expect(data['logging']['output'], 'cloudwatch');
      expect(data['logging']['structured'], true);
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
