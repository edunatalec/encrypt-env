[![pub package](https://img.shields.io/pub/v/encrypt_env.svg)](https://pub.dev/packages/encrypt_env)
[![package publisher](https://img.shields.io/pub/publisher/encrypt_env.svg)](https://pub.dev/packages/encrypt_env/publisher)

**encrypt_env** is a Dart CLI tool that generates obfuscated or encrypted Dart files from YAML configuration. It helps you protect API keys, secrets, tokens, and other sensitive data in Flutter and Dart applications.

## Summary

- [Installation](#installation)
- [Quick start](#quick-start)
- [Modes](#modes)
  - [XOR obfuscation](#xor-obfuscation)
  - [AES-256 encryption](#aes-256-encryption)
- [Setup](#setup)
  - [Basic example](#basic-example)
- [Merging environments](#merging-environments)
- [Key generation](#key-generation)
- [Test generation](#test-generation)
- [Customization](#customization)
  - [Available flags](#available-flags)
- [Documentation](#documentation)
- [Help](#help)

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

? Config folder: (environment)
? Config file name: (environment)
? Environment name (leave empty to skip):
? Output directory: (lib)
? Output file name: (environment)
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

Organize your project with a folder named `environment` and a file named `environment.yaml`:

```text
your_project/
├── environment/
│   └── environment.yaml
```

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

Run:

```sh
encrypt_env gen
```

The file `lib/environment.dart` will be generated with sealed classes and strongly-typed getters:

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

  static Map<String, dynamic> get headers {
    return {
      _decode([0xdc, ...], [...[...], ...[...]]): _apiKey,
    };
  }
}

sealed class Endpoint {
  static String get endpointA { ... }
  static String get endpointB { ... }
}
```

Each value has its own unique salt, split into two fragments for additional obscurity.

## Merging environments

You can merge environment-specific overrides on top of a base config:

```yaml
# environment/environment.yaml (base)
environment:
  production: false
  base_url: 'http://localhost:3000'
  api_key: 'dev_key'
```

```yaml
# environment/prod_environment.yaml (overrides)
environment:
  production: true
  base_url: 'https://api.example.com'
  api_key: 'prod_key'
```

```sh
encrypt_env gen -e prod
```

Values from `prod_environment.yaml` override the base config. Unspecified values are preserved from the base.

> Use any prefix: `staging`, `dev`, `uat`, etc. Format: `{prefix}_environment.yaml`.

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
  });
}
```

To disable test generation:

```sh
encrypt_env gen --no-test
```

## Customization

### Available flags

| Flag | Default | Description |
|------|---------|-------------|
| `--folder` | `environment` | Folder containing your configuration files |
| `--config` | `environment` | Base config file name (without `.yaml`) |
| `-e`, `--env` | _none_ | Environment name to merge (e.g., `dev`, `prod`) |
| `--out-dir` | `lib` | Output directory for the generated Dart file |
| `--out-file` | `environment` | Output Dart file name (without `.dart`) |
| `-s`, `--style` | `cc` | Getter naming style: `cc` (camelCase), `sc` (snake_case), `ssc` (SCREAMING_SNAKE_CASE) |
| `--encrypt` | `false` | Use AES-256-GCM encryption instead of XOR obfuscation |
| `-k`, `--key` | _none_ | Base64 AES-256 key (used with `--encrypt`) |
| `--[no-]test` | `true` | Generate a test file alongside the Dart file |

## Documentation

Detailed documentation about how each mode works:

- [XOR obfuscation](doc/xor-obfuscation/) — [English](doc/xor-obfuscation/en.md) | [Portugues](doc/xor-obfuscation/pt-br.md) | [Espanol](doc/xor-obfuscation/es.md)
- [AES-256 encryption](doc/aes-encryption/) — [English](doc/aes-encryption/en.md) | [Portugues](doc/aes-encryption/pt-br.md) | [Espanol](doc/aes-encryption/es.md)

## Help

To view all available commands and options:

```bash
encrypt_env -h
```

## License

MIT License - see [LICENSE](LICENSE) for details.
