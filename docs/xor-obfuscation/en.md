# XOR Obfuscation

## What is it?

XOR obfuscation is a technique that transforms plain text values into encoded byte sequences that are not human-readable. It uses the XOR (exclusive or) bitwise operation combined with multiple transformation layers to make the original values difficult to identify in source code and compiled binaries.

## Why XOR?

In client-side applications (Flutter/Dart), any value embedded in the binary can eventually be extracted by a determined attacker. Even AES-256 encryption is useless if the decryption key is in the same binary.

XOR obfuscation raises the effort required to extract values from "trivial" to "requires dedicated reverse engineering tools." It is the right approach for values like base URLs, SDK keys, and feature flags that should not be visible in plain text but are not critically sensitive secrets.

## How does it work?

The algorithm applies four layers of transformation to each value individually.

### Layer 1 — Per-Value Salt

A unique random salt (32 to 64 bytes) is generated for each value using `Random.secure()`.

```
salt = random_bytes(32..64)
```

Each value has its own independent salt. Knowing one value's salt reveals nothing about another.

**Example:** Two values will have completely different salts with different sizes:

```dart
// value "baseUrl" gets a 47-byte salt
final s1 = [0x7d, 0x94, ...];  // 41 bytes
final s2 = [0x05, 0x55, ...];  // 6 bytes

// value "apiKey" gets a 53-byte salt
final s1 = [0xa7, 0x4f, ...];  // 13 bytes
final s2 = [0xca, 0xe1, ...];  // 40 bytes
```

### Layer 2 — First XOR Pass

Each byte of the plain text is XORed with the corresponding salt byte. The salt cycles if the value is longer than the salt.

```
xored[i] = plain[i] ^ salt[i % salt.length]
```

**Example** with `"hi"` and salt `[0xAA, 0xBB]`:

```
'h' = 0x68  →  0x68 ^ 0xAA = 0xC2
'i' = 0x69  →  0x69 ^ 0xBB = 0xD2
Result: [0xC2, 0xD2]
```

### Layer 3 — Byte Shuffle

The XORed bytes are rearranged using a Fisher-Yates permutation. The permutation is deterministic — seeded by an FNV-1a hash of the salt.

```
seed = FNV1a(salt)
permutation = fisher_yates(length, LCG(seed))
shuffled[perm[i]] = xored[i]
```

This destroys the positional relationship between the original value and the encoded output. Without knowing the permutation, an attacker cannot determine which byte in the output corresponds to which byte in the input.

**Example** with `[0xC2, 0xD2, 0xE5, 0xF1]` and permutation `[2, 0, 3, 1]`:

```
shuffled[2] = 0xC2  (from index 0)
shuffled[0] = 0xD2  (from index 1)
shuffled[3] = 0xE5  (from index 2)
shuffled[1] = 0xF1  (from index 3)
Result: [0xD2, 0xF1, 0xC2, 0xE5]
```

A deterministic LCG (Linear Congruential Generator) is used instead of `dart:math Random` because Dart's `Random` does not guarantee identical sequences across SDK versions. The LCG with fixed constants (`a=1103515245, c=12345, m=2^31`) produces the same permutation forever.

### Layer 4 — Second XOR Pass with Derived Key

A second key is derived from the salt by reversing it and rotating each byte right by 3 bits. The shuffled bytes are XORed with this derived key.

```
derived[i] = rotate_right(salt.reversed[i], 3)
output[i] = shuffled[i] ^ derived[i % derived.length]
```

**Example** of key derivation for byte `0xAA` (`10101010`):

```
rotate_right(10101010, 3) = 01010101 = 0x55
```

This adds a second independent XOR layer. An attacker who identifies the shuffle step still needs to reverse the derived key before reaching the salt.

### Salt Fragmentation

The salt is split into two fragments at a random point before being stored in the generated code.

```dart
final s1 = [0x7d, 0x94, 0x51, ...];  // first part
final s2 = [0x05, 0x55, 0xfe, ...];  // second part
// Reassembled at runtime: [...s1, ...s2]
```

The split point varies per value, so the fragments have different sizes each time. This prevents the salt from appearing as a single recognizable block.

## How does it decode?

To reverse the obfuscation, the four layers are applied in reverse order:

```dart
String _decode(List<int> encoded, List<int> salt) {
  // Reverse layer 4: XOR with derived key
  final dk = salt.reversed.map((b) => ((b >> 3) | (b << 5)) & 0xFF).toList();
  final u2 = List.generate(encoded.length, (i) => encoded[i] ^ dk[i % dk.length]);

  // Reverse layer 3: unshuffle
  final p = _perm(encoded.length, _seed(salt));
  final us = List.generate(encoded.length, (i) => u2[p[i]]);

  // Reverse layer 2: XOR with salt
  return String.fromCharCodes(
    List.generate(us.length, (i) => us[i] ^ salt[i % salt.length]),
  );
}
```

## Security scope

**Protects against:**

- Plain text exposure in source code and version control
- Extraction via `strings` command on compiled binaries
- Automated secret scanners that look for API key patterns
- Casual inspection by someone browsing the code

**Does not protect against:**

- Dedicated reverse engineering with debuggers (Frida, IDA)
- Runtime memory inspection
- An attacker who reads and understands the decode function

For values that require real security, use AES-256 encryption with a runtime key provided from a secure external source.

## Technical reference

| Component | Algorithm | Details |
|-----------|-----------|---------|
| Salt generation | `Random.secure()` | 32-64 bytes per value |
| Seed derivation | FNV-1a hash | Offset: `0x5f3759df`, Prime: `0x01000193` |
| Permutation | Fisher-Yates shuffle | LCG: `a=1103515245, c=12345, m=2^31` |
| Key derivation | Reverse + bit rotation | Right rotate by 3 bits |
| Output format | Hexadecimal | `0x` prefix, comma-separated |
