# Changelog

## 3.1.0 - 2026-04-13

### Added

- Support for `.yml` and `.json` config file formats in addition to `.yaml`
- Auto-detection of config file format with priority order: `.yaml` > `.yml` > `.json`
- Base and environment-specific files can use different formats (e.g., base in `.yaml`, env override in `.json`)
- Interactive prompt to enable/disable test file generation (`Generate test file?`)
- Configuration examples in `example/README.md` with ready-to-use YAML and JSON templates

### Changed

- Reordered interactive CLI flow: mode and style first, then config input, then output options
- Improved interactive prompts with clearer descriptions (e.g., `Config file name (without extension):`, `Output file name (without .dart):`)
- `ConfigReader` now probes for supported extensions instead of hardcoding `.yaml`
- Error messages list all tried file paths when no config file is found
- Updated CLI description and README to reflect multi-format support

## 3.0.0 - 2026-04-12

### Added

- Strategy pattern architecture for obfuscation/encryption extensibility
- Multi-layer XOR obfuscation: per-value salt, byte shuffle, derived key XOR
- AES-256-GCM encryption mode via `--encrypt --key <base64_key>` using [fortis](https://pub.dev/packages/fortis)
- `AesStrategy` for real encryption with runtime key initialization
- `ObfuscationStrategy` abstract interface for obfuscation/encryption extensibility
- `--encrypt` flag and `--key` option in CLI
- `keygen` command to generate random AES-256 keys
- Automatic test file generation (`test/{file}_test.dart`) with `--[no-]test` flag
- Auto-detection of Flutter vs Dart projects and package name via `pubspec.yaml`
- Interactive CLI mode when running `gen` without arguments
- `ConfigReader` for independent YAML configuration loading
- `CodeBuilder` and `TestBuilder` for Dart source code generation
- `bytes_utils.dart` with deterministic PRNG (`seedFromSalt`, `generatePermutation`)
- Documentation in English, Portuguese, and Spanish (`doc/xor-obfuscation/`, `doc/aes-encryption/`)
- Comprehensive test suite rewritten from scratch

### Changed

- Refactored `Generator` into a thin orchestrator delegating to `ConfigReader`, `CodeBuilder`, and `ObfuscationStrategy`
- Replaced single global salt with per-value unique salts (32-64 bytes each)
- Salt is now fragmented into two parts in the generated file
- Renamed `encrypt_utils.dart` to `bytes_utils.dart`
- Generated decode function now uses `String.fromCharCodes` instead of `Utf8Decoder`
- Generated file no longer requires `dart:convert` import

### Removed

- Old single-pass XOR obfuscation (`stringToHex`, `_encode`)
- Global `keyBytesSize` getter
- Previous test suite (replaced entirely)

## 2.1.0 - 2026-01-31

### Fixed

- Correct toCamelCase behavior for strings with length <= 2

## 2.0.2 - 2025-09-02

### Changed

- Updated documentation

## 2.0.1 - 2025-09-02

### Changed

- Updated documentation

## 2.0.0 - 2025-09-02

### Added

- Support for primitive types: **int**, **double**, and **bool** in YAML configuration

### Changed

- Updated CLI commands for generating the encrypted file
- Default `case style` changed to **camelCase**
- Generated class is now declared as **sealed**

### Fixed

- Improved error message when YAML configuration is invalid

### Removed

- Removed all `// coverage:ignore-line` directives

## 1.1.2 - 2025-05-19

### Changed

- Updated generator to insert `// coverage:ignore-line` for untestable lines
- Renamed internal files for consistency and clarity
- Updated package dependencies to latest versions

## 1.1.1 - 2025-02-10

### Changed

- Update project

## 1.1.0 - 2024-03-13

### Added

- Package update functionality

### Changed

- Enhance code for improved usability

## 1.0.1 - 2024-03-13

### Changed

- Update README

## 1.0.0 - 2024-03-13

- First release
