# Changelog

## [3.3.0] - 2026-04-25

### Changed

- Bumped `fortis` dependency to `^0.3.0` (was `^0.2.0`). Projects consuming AES-encrypted output must update their own `fortis` constraint to match
- Generator no longer runs `dart format` on the main output file. The file is written as emitted by `CodeBuilder` (tab-indented, with hex literals kept on single lines), preserving a dense and predictable fingerprint. The accompanying test file is still formatted
- Generated `_decode` / `_seed` / `_perm` footer (XOR mode) now uses explicit types (`int s`, `final List<int> p`) and blank lines between setup and `return`, matching the package's internal code style

### Fixed

- Generated file no longer fails to compile when the config has nested maps with 2+ levels of depth. `_buildMapGetter` was double-prefixing inner-map value getters (`__host` instead of `_host`), producing `Undefined name '__host'` errors at compile time
- README links under "Documentation" pointed to the old `doc/` directory; they now resolve correctly after the rename to `docs/`

## [3.2.0] - 2026-04-16

### Added

- Warning when generating AES test files alerting that the embedded key must not be committed to public repositories
- Dartdoc on the library directive (resolves pub.dev `Documentation` scoring)

### Changed

- `AesStrategy` uses the typed `Fortis.aes().gcm().cipher(...)` shortcut; `_cipher` is now declared as `AesAuthCipher` (the statically-typed AEAD variant from fortis 0.2.0)
- Generator runs `dart format` on the main output file too — previously only the test file was formatted
- `Random.secure()` is reused across encoding operations instead of being re-instantiated per value
- Command error handlers now log stack traces via `_logger.detail(...)` — visible under `--verbose`
- `GenerateCommand` catches `FortisConfigException` separately, returning `ExitCode.usage` (64) with a clearer message for invalid AES keys

### Fixed

- `toSnakeCase()` now inserts `_` between camelCase/PascalCase boundaries. YAML keys like `helloWorld` produce `hello_world` (with `-s sc`) or `HELLO_WORLD` (with `-s ssc`), instead of the previous `helloworld`/`HELLOWORLD`
- Test generator now escapes `$`, `\`, `'`, `\n`, `\r`, `\t` in string values — values like `password$123` no longer produce a test file that fails to compile
- `CodeBuilder` rejects `null` config values with `FormatException` naming the offending key, instead of generating invalid Dart (`static Null get ...`)
- `Map.merge` detects base/override type mismatches (e.g. primitive vs map) and raises `FormatException` with context, instead of an opaque `TypeError`

## [3.1.0] - 2026-04-13

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

## [3.0.0] - 2026-04-12

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

## [2.1.0] - 2026-01-31

### Fixed

- Correct toCamelCase behavior for strings with length <= 2

## [2.0.2] - 2025-09-02

### Changed

- Updated documentation

## [2.0.1] - 2025-09-02

### Changed

- Updated documentation

## [2.0.0] - 2025-09-02

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

## [1.1.2] - 2025-05-19

### Changed

- Updated generator to insert `// coverage:ignore-line` for untestable lines
- Renamed internal files for consistency and clarity
- Updated package dependencies to latest versions

## [1.1.1] - 2025-02-10

### Changed

- Update project

## [1.1.0] - 2024-03-13

### Added

- Package update functionality

### Changed

- Enhance code for improved usability

## [1.0.1] - 2024-03-13

### Changed

- Update README

## [1.0.0] - 2024-03-13

- First release
