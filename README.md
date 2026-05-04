# Encrypt Env

[![pub package](https://img.shields.io/pub/v/encrypt_env.svg)](https://pub.dev/packages/encrypt_env)
[![package publisher](https://img.shields.io/pub/publisher/encrypt_env.svg)](https://pub.dev/packages/encrypt_env/publisher)

A Dart CLI tool that generates obfuscated or encrypted Dart files from YAML or JSON configuration. It helps you protect API keys, secrets, tokens, and other sensitive data in Flutter and Dart applications.

## Summary

- [Installation](#installation)
- [Quick start](#quick-start)
- [Modes](#modes)
  - [XOR obfuscation](#xor-obfuscation)
  - [AES-256 encryption](#aes-256-encryption)
- [Setup](#setup)
  - [Basic example](#basic-example)
- [Merging environments](#merging-environments)
- [JSON configuration](#json-configuration)
- [Key generation](#key-generation)
- [Test generation](#test-generation)
- [Customization](#customization)
  - [Available flags](#available-flags)
- [Documentation](#documentation)
- [Help](#help)
- [License](#license)

## Installation

Activate globally via Dart:

```sh
dart pub global activate encrypt_env
```

## Quick start

Run without arguments for an interactive experience:

```sh
encrypt_env gen
```

The CLI will guide you through each option:

```
? Choose a mode:
❯ XOR obfuscation (no dependencies)
  AES-256 encryption (requires fortis)

? Choose a case style:
❯ camelCase
  snake_case
  SCREAMING_SNAKE_CASE

? Folder containing your config files: (environment)
? Config file name (without extension): (environment)
? Environment to merge (e.g. dev, prod — leave empty to skip):
? Output directory for generated Dart file: (lib)
? Output file name (without .dart): (environment)
? Generate test file? (Y/n)
```

Or pass flags directly for automation:

```sh
encrypt_env gen --style cc --env prod
```

> When any flag is passed, the CLI uses default values for the remaining options without prompting.

## Modes

### XOR obfuscation

The default mode. Uses multi-layer XOR obfuscation with per-value salt, byte shuffling, and derived key passes. The generated file has **zero external dependencies**.

```sh
encrypt_env gen
```

Values are obfuscated — not visible as plain text in the source code or binary, but not cryptographically secure. Ideal for base URLs, SDK keys, and feature flags.

> **Flutter projects:** For additional protection, enable Flutter's built-in obfuscation when building for release:
>
> ```sh
> flutter build apk --obfuscate --split-debug-info=debug-info/
> ```

### AES-256 encryption

Uses AES-256-GCM encryption via the [fortis](https://pub.dev/packages/fortis) package. The generated file requires `fortis` as a dependency and a runtime key to decrypt.

```sh
# With your own key
encrypt_env gen --encrypt --key <base64_key>

# Auto-generate a key
encrypt_env gen --encrypt
```

When no key is provided, the CLI generates one and displays it in the console:

```
Generated a new AES-256 key:

hEvB+s5mpCLmmioI6Ji53JwIzx7ZQ5HUih/7CTv5S2I=

⚠ Save this key securely. You will need it at runtime.
```

The generated file includes an `EncryptEnv` class with an `init()` method that must be called before accessing any value:

```dart
import 'environment.dart';

void main() {
  EncryptEnv.init('your-base64-key-here');
  print(Environment.baseUrl);
}
```

## Setup

Organize your project with a folder named `environment` and a config file (`.yaml`, `.yml`, or `.json`):

```text
your_project/
├── environment/
│   └── environment.yaml   # or .yml or .json
```

> The CLI auto-detects the file format. Priority order: `.yaml` > `.yml` > `.json`.
>
> You can change the folder and file name using `--folder` and `--config` flags.

### Basic example

Given the following `environment/environment.yaml`:

```yaml
environment:
  base_url: 'http://localhost:3000'
  version: '1.0.0'
  production: false
  headers:
    api-key: 'value'
endpoint:
  endpoint_a: 'endpoint-a'
  endpoint_b: 'endpoint-b'
```

> Prefer JSON? Skip ahead to the [JSON configuration](#json-configuration) section for the equivalent file and merging example.

Run:

```sh
encrypt_env gen
```

The file `lib/environment.dart` will be generated with sealed classes and strongly-typed getters. Nested maps become their own typed classes, recursively, so you get autocomplete all the way down:

```dart
sealed class Environment {
  static String get baseUrl {
    final List<int> encoded = [0xd5, 0x98, ...];
    final List<int> salt = [...[0xaa, 0xbb, ...], ...[0xcc, 0xdd, ...]];

    return _decode(encoded, salt);
  }

  static bool get production {
    final List<int> encoded = [0xdb, 0x8d, ...];
    final List<int> salt = [...[0x94, 0xb5, ...], ...[0xe3, 0xa0, ...]];

    return bool.parse(_decode(encoded, salt));
  }

  /// The `headers` section.
  static EnvironmentHeaders get headers => const EnvironmentHeaders._();

  /// Returns a map representation of this section.
  ///
  /// {
  ///   base_url: http://localhost:3000,
  ///   production: false,
  ///   headers: {
  ///     api-key: value,
  ///   },
  /// }
  static Map<String, dynamic> toMap() => <String, dynamic>{
    _decode([...], [...[...], ...[...]]): baseUrl,
    _decode([...], [...[...], ...[...]]): production,
    _decode([...], [...[...], ...[...]]): headers.toMap(),
  };
}

final class EnvironmentHeaders {
  const EnvironmentHeaders._();

  String get apiKey {
    final List<int> encoded = [0xdc, ...];
    final List<int> salt = [...[...], ...[...]];

    return _decode(encoded, salt);
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    _decode([...], [...[...], ...[...]]): apiKey,
  };
}

sealed class Endpoint {
  static String get endpointA { ... }
  static String get endpointB { ... }

  static Map<String, dynamic> toMap() { ... }
}
```

Access nested values with regular dot syntax — no map indexing, no string keys at the call site:

```dart
Environment.baseUrl;            // 'http://localhost:3000'
Environment.headers.apiKey;     // 'value'
Environment.headers.toMap();    // { 'api-key': 'value' }
Environment.toMap();            // entire section as a Map<String, dynamic>
```

Each value has its own unique salt, split into two fragments for additional obscurity. Map keys returned by `toMap()` are also encoded — they are decoded at call time, so the original YAML keys never appear in plaintext in the generated source.

## Merging environments

You can merge environment-specific overrides on top of a base config. The base file holds your full configuration; the override file only carries the keys that change for that environment. Nested maps are merged recursively — anything you don't repeat in the override is inherited from the base.

**Base** (`environment/environment.yaml`):

```yaml
environment:
  base_url: 'http://localhost:3000'
  version: '1.0.0'
  production: false
  debug: true
  api_key: 'dev_key'
  timeout: 30
  headers:
    content_type: 'application/json'
    authorization:
      prefix: 'Bearer'
      refresh_enabled: true

database:
  host: 'localhost'
  port: 5432
  name: 'myapp_dev'
  ssl: false
  credentials:
    username: 'dev_user'
    password: 'dev_password'
```

**Override** (`environment/prod_environment.yaml`) — only the keys that change in production:

```yaml
environment:
  base_url: 'https://api.example.com'
  production: true
  debug: false
  api_key: 'prod_key'
  headers:
    authorization:
      refresh_enabled: false

database:
  host: 'db.example.com'
  ssl: true
  credentials:
    username: 'prod_user'
    password: 'prod_password'
```

**Resulting merged config** used for code generation:

```yaml
environment:
  base_url: 'https://api.example.com'   # from prod
  version: '1.0.0'                      # from base
  production: true                      # from prod
  debug: false                          # from prod
  api_key: 'prod_key'                   # from prod
  timeout: 30                           # from base
  headers:
    content_type: 'application/json'    # from base
    authorization:
      prefix: 'Bearer'                  # from base
      refresh_enabled: false            # from prod

database:
  host: 'db.example.com'                # from prod
  port: 5432                            # from base
  name: 'myapp_dev'                     # from base
  ssl: true                             # from prod
  credentials:
    username: 'prod_user'               # from prod
    password: 'prod_password'           # from prod
```

Generate with:

```sh
encrypt_env gen -e prod
```

> Use any prefix: `staging`, `dev`, `uat`, etc. Format: `{prefix}_environment.{yaml|yml|json}`.

## JSON configuration

Every example in this README is shown in YAML for readability, but the CLI accepts `.json` (and `.yml`) as well. The format is **transparent** to every feature: code generation, [environment merging](#merging-environments), strategies (XOR/AES), case styles, and tests all behave identically — only the file extension changes.

Auto-detection priority is `.yaml` > `.yml` > `.json`. Base and override files can even use **different formats** in the same project (e.g. base in `.yaml`, override in `.json`).

Equivalent of the [Basic example](#basic-example) above, written as `environment/environment.json`:

```json
{
  "environment": {
    "base_url": "http://localhost:3000",
    "version": "1.0.0",
    "production": false,
    "headers": {
      "api-key": "value"
    }
  },
  "endpoint": {
    "endpoint_a": "endpoint-a",
    "endpoint_b": "endpoint-b"
  }
}
```

## Key generation

Generate a random AES-256 key:

```sh
encrypt_env keygen
```

```
AES-256 key generated:

y67ImXMjCr1Uuo6jvF0pXBuomlshiwCgbwYQFRiUHbk=
```

## Test generation

By default, a test file is generated alongside the Dart file at `test/{out-file}_test.dart`. The CLI automatically detects your project type by reading `pubspec.yaml`:

- **Flutter project** (has `flutter` dependency) → uses `package:flutter_test/flutter_test.dart`
- **Dart project** → uses `package:test/test.dart`
- **Package name** → uses `package:name/...` import style

Example generated test:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/environment.dart';

void main() {
  group('Environment', () {
    test('baseUrl returns correct value', () {
      expect(Environment.baseUrl, 'http://localhost:3000');
    });

    test('production returns correct value', () {
      expect(Environment.production, false);
    });

    test('production returns bool', () {
      expect(Environment.production, isA<bool>());
    });

    group('headers', () {
      test('apiKey returns correct value', () {
        expect(Environment.headers.apiKey, 'value');
      });

      test('toMap returns Map<String, dynamic>', () {
        expect(Environment.headers.toMap(), isA<Map<String, dynamic>>());
      });
    });

    test('toMap returns Map<String, dynamic>', () {
      expect(Environment.toMap(), isA<Map<String, dynamic>>());
    });
  });
}
```

To disable test generation:

```sh
encrypt_env gen --no-test
```

> ⚠ In `--encrypt` mode, the generated test embeds the AES-256 key in plaintext. Do **not** commit it to a public repository — add the test file to `.gitignore` or rotate the key before publishing.

## Customization

### Available flags

| Flag            | Default       | Description                                                                            |
| --------------- | ------------- | -------------------------------------------------------------------------------------- |
| `--folder`      | `environment` | Folder containing your configuration files                                             |
| `--config`      | `environment` | Base config file name (without extension)                                              |
| `-e`, `--env`   | _none_        | Environment name to merge (e.g., `dev`, `prod`)                                        |
| `--out-dir`     | `lib`         | Output directory for the generated Dart file                                           |
| `--out-file`    | `environment` | Output Dart file name (without `.dart`)                                                |
| `-s`, `--style` | `cc`          | Getter naming style: `cc` (camelCase), `sc` (snake_case), `ssc` (SCREAMING_SNAKE_CASE) |
| `--encrypt`     | `false`       | Use AES-256-GCM encryption instead of XOR obfuscation                                  |
| `-k`, `--key`   | _none_        | Base64 AES-256 key (used with `--encrypt`)                                             |
| `--[no-]test`   | `true`        | Generate a test file alongside the Dart file                                           |

## Documentation

Detailed documentation about how each mode works:

- [XOR obfuscation](docs/xor-obfuscation/) — [English](docs/xor-obfuscation/en.md) | [Português](docs/xor-obfuscation/pt-br.md) | [Español](docs/xor-obfuscation/es.md)
- [AES-256 encryption](docs/aes-encryption/) — [English](docs/aes-encryption/en.md) | [Português](docs/aes-encryption/pt-br.md) | [Español](docs/aes-encryption/es.md)

## Help

To view all available commands and options:

```bash
encrypt_env -h
```

## License

MIT License - see [LICENSE](LICENSE) for details.
