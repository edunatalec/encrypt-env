# Example

## Installation

```sh
dart pub global activate encrypt_env
```

## Interactive mode

```sh
encrypt_env gen
```

## XOR obfuscation (default)

```sh
encrypt_env gen --folder environment --out-dir lib/src --out-file environment
```

## AES-256 encryption

```sh
# Generate a key
encrypt_env keygen

# Use the generated key
encrypt_env gen --encrypt --key <base64_key>

# Or let the CLI generate one automatically
encrypt_env gen --encrypt
```

## Merging environments

```sh
encrypt_env gen -e prod
```

## Disable test generation

```sh
encrypt_env gen --no-test
```

## Help

```sh
encrypt_env --help
encrypt_env gen --help
```
