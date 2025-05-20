[![pub package](https://img.shields.io/pub/v/encrypt_env.svg)](https://pub.dev/packages/encrypt_env)
[![package publisher](https://img.shields.io/pub/publisher/encrypt_env.svg)](https://pub.dev/packages/encrypt_env/publisher)

**encrypt_env** is a Dart CLI tool designed to encrypt sensitive environment variables for Flutter and Dart applications. It helps you secure API keys, secrets, tokens, and other private configuration details by generating encrypted files from YAML definitions.

## Summary

- [Installation](#installation)
- [Setup](#setup)
- [How it works](#how-it-works)
  - [Basic example](#basic-example)
- [Behavior Summary](#behavior-summary)
- [Merging Environments](#merging-environments)
- [Customization](#customization)
  - [Available Flags](#available-flags)
  - [Formats](#formats)
- [Help](#help)

## Installation

Activate globally via Dart:

```sh
dart pub global activate encrypt_env
```

## Setup

To use `encrypt_env`, you need to organize your project with a folder named `environment` and a file named `environment.yaml` inside it — as shown in the image below:

<img src="./assets/folder-example.png">

This file will contain your sensitive environment variables, such as API keys, secrets, tokens, etc.

```text
your_project/
├── environment/
│   └── environment.yaml
```

> Note: You can change the folder and file name by using the --folder and --yaml options when running the CLI.

## How it works

The `encrypt_env` CLI reads your `environment.yaml` and generates a Dart class with **static, strongly-typed getters** where **all values are encrypted** at compile time and only decrypted at runtime.

Here's how each part is handled:

### Basic example

Given the following `environment.yaml`:

```yaml
environment:
  base_url: 'http://localhost:3000'
  version: '1.0.0'
  production: false
  headers:
    api-key: 'api-key-fake'
endpoint:
  endpoint_a: 'endpoint-a-fake'
  endpoint_b: 'endpoint-b-fake'
```

The generated Dart file will contain a class like this:

```dart
class Environment {
	Environment._(); // coverage:ignore-line

	/// BASE_URL: http://localhost:3000
	static String get BASE_URL {
		final List<int> encoded = [0x51, 0x17, 0x26, 0xd4, 0x4d, 0x3e, 0x7, 0x22, 0x1, 0x2a, 0xc3, 0x93, 0xf5, 0x86, 0xc7, 0x4c, 0xf5, 0xe7, 0xea, 0x38, 0x1];

		return _decode(encoded);
	}

	/// VERSION: 1.0.0
	static String get VERSION {
		final List<int> encoded = [0x8, 0x4d, 0x62, 0x8a, 0x47];

		return _decode(encoded);
	}

	/// PRODUCTION: false
	static bool get PRODUCTION {
		final List<int> encoded = [0x5f, 0x2, 0x3e, 0xd7, 0x12];

		return _decode(encoded) == _decode([0x4d, 0x11, 0x27, 0xc1]);
	}

	static Map<String, dynamic> get HEADERS {
		return {
			// api-key: api-key-fake
			_decode([0x58, 0x13, 0x3b, 0x89, 0x1c, 0x74, 0x51]): _API_KEY,
		};
	}

	/// _API_KEY: api-key-fake
	static String get _API_KEY {
		final List<int> encoded = [0x58, 0x13, 0x3b, 0x89, 0x1c, 0x74, 0x51, 0x63, 0x8, 0x28, 0xc9, 0x9a];

		return _decode(encoded);
	}
}

class Endpoint {
	Endpoint._(); // coverage:ignore-line

	/// ENDPOINT_A: endpoint-a-fake
	static String get ENDPOINT_A {
		final List<int> encoded = [0x5c, 0xd, 0x36, 0xd4, 0x18, 0x78, 0x46, 0x3a, 0x43, 0x28, 0x8f, 0x99, 0xfc, 0x82, 0xd1];

		return _decode(encoded);
	}

	/// ENDPOINT_B: endpoint-b-fake
	static String get ENDPOINT_B {
		final List<int> encoded = [0x5c, 0xd, 0x36, 0xd4, 0x18, 0x78, 0x46, 0x3a, 0x43, 0x2b, 0x8f, 0x99, 0xfc, 0x82, 0xd1];

		return _decode(encoded);
	}
}
```

## Behavior Summary

This table explains how each type of value in your `environment.yaml` is treated in the generated Dart code:

| YAML Input Type        | Dart Output Type       | Description                                                           |
| ---------------------- | ---------------------- | --------------------------------------------------------------------- |
| `String`               | `String`               | Encrypted and returned as-is                                          |
| `bool`                 | `bool`                 | Encrypted and returned as a boolean                                   |
| `int`, `double`, `num` | `String`               | Encrypted and returned as a string (no type casting)                  |
| `Map<String, dynamic>` | `Map<String, dynamic>` | Keys and values are both encrypted individually and returned as a map |

> All values — including keys inside maps — are encrypted and decrypted at runtime.

## Merging Environments

You can dynamically merge environment files using the `--environment` flag.

By default, the CLI looks for a base file:

```yaml
# environment/environment.yaml

environment:
  production: false
  base_url: 'http://localhost:3000'
  api_key: 'your_dev_api_key_here'
  database_url: 'your_dev_database_url_here'
endpoint:
  endpoint_a: 'endpoint-a-fake'
  endpoint_b: 'endpoint-b-fake'
```

```yaml
# environment/prod_environment.yaml

environment:
  production: true
  base_url: 'https://api.example.com'
  api_key: 'your_production_api_key_here'
  database_url: 'your_production_database_url_here'
```

```text
environment/
├── environment.yaml # Base config
└── prod_environment.yaml # Overrides
```

```sh
encrypt_env gen --environment prod
```

This will merge both YAMLs, applying all values from `prod_environment.yaml` on top of the base config.

> You can use any prefix (e.g. `staging`, `dev`, `uat`). Just keep the format `prefix_environment.yaml` and match it in `--environment`.

## Customization

You can customize how the CLI reads and writes files using optional flags.

### Available Flags

| Flag                  | Default       | Description                                       |
| --------------------- | ------------- | ------------------------------------------------- |
| `--folder`            | `environment` | Folder containing your YAML files                 |
| `-y`, `--yaml`        | `environment` | Base YAML file name (without `.yaml` extension)   |
| `-e`, `--environment` | _none_        | Optional environment prefix to merge files        |
| `--file-path`         | `lib`         | Output directory for the generated Dart file      |
| `--file`              | `environment` | Output Dart file name (without `.dart` extension) |
| `--format`            | `ssc`         | Getter naming format: `ssc`, `cc`, or `sc`        |

### Formats:

| Format | Description          | Example   |
| ------ | -------------------- | --------- |
| `ssc`  | SCREAMING_SNAKE_CASE | `API_KEY` |
| `cc`   | camelCase            | `apiKey`  |
| `sc`   | snake_case           | `api_key` |

> These options allow you to adapt the CLI to any project structure or naming convention.

## Help

To view all available commands and options, run:

```bash
encrypt_env -h
```
