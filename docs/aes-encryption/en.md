# AES-256-GCM Encryption

## What is it?

AES-256-GCM is a symmetric encryption algorithm that transforms plain text into ciphertext that is mathematically impossible to reverse without the secret key. It combines AES (Advanced Encryption Standard) with GCM (Galois/Counter Mode), which provides both confidentiality and authenticity.

Unlike XOR obfuscation, AES-256-GCM offers real cryptographic protection — even with full access to the encrypted data, the original values cannot be recovered without the key.

## Why AES-256-GCM?

- **AES-256** is the industry standard for symmetric encryption, approved by NIST and used by governments and financial institutions worldwide
- **GCM** detects tampering — if anyone modifies the ciphertext, decryption fails instead of returning corrupted data
- **Random IV per value** — encrypting the same value twice produces completely different ciphertext, preventing pattern analysis

## How does it work?

### Encryption (build time)

Each value goes through this process:

1. A random **12-byte IV** (Initialization Vector) is generated
2. The value is encrypted with AES-256 using the key and IV
3. GCM produces a **16-byte authentication tag** that verifies integrity
4. The output is packaged as: `IV (12 bytes) + ciphertext + tag (16 bytes)`
5. Everything is encoded as a single **base64 string**

**Example** with value `"http://localhost:3000"`:

```
Input:    "http://localhost:3000"
Key:      zOXJHeEV6EVCSludkRizg+oFSs3rdgCYtOgvgkayZBI=  (256-bit)
IV:       [random 12 bytes]

Output:   pLtABeegYXd+amw7aMNbNZ+0K0DPb5JmrrAG9xhmFfdXb/MKCo/W6OCYXmocFUEnuA==
```

The same value encrypted again produces a different result because the IV is random:

```
First:    pLtABeegYXd+amw7aMNbNZ+0K0DPb5JmrrAG9xhmFfdXb/MKCo/W6OCYXmocFUEnuA==
Second:   G0+SIfVcsrCY7GLWL5A/groe40fcqTD438NbQrF4KXdnx7ctelYX0R/jd9QjbS15+g==
```

Both decrypt to the same original value, but an attacker cannot tell they represent the same data.

### Decryption (runtime)

To decrypt, the process is reversed:

1. The base64 string is decoded
2. The first 12 bytes are extracted as the IV
3. The last 16 bytes are extracted as the authentication tag
4. The remaining bytes are the ciphertext
5. AES-256-GCM decrypts using the key, IV, and tag
6. If the tag doesn't match (data was tampered), decryption fails with an error

**Example:**

```
Input:    pLtABeegYXd+amw7aMNbNZ+0K0DPb5JmrrAG9xhmFfdXb/MKCo/W6OCYXmocFUEnuA==
Key:      zOXJHeEV6EVCSludkRizg+oFSs3rdgCYtOgvgkayZBI=

→ Extract IV:   pLtABeegYXd+amw7  (first 12 bytes)
→ Extract tag:  FfdXb/MKCo...     (last 16 bytes)
→ Ciphertext:   aMNbNZ+0K0DP...   (middle bytes)
→ Decrypt with AES-256-GCM

Output:   "http://localhost:3000"
```

### Key requirement

The key is a **256-bit (32 bytes)** random value encoded in base64.

**Example key:** `zOXJHeEV6EVCSludkRizg+oFSs3rdgCYtOgvgkayZBI=`

The key is **never stored** in the generated file or the binary. It must be provided at runtime from a secure external source:

- Backend API
- Secure device storage (iOS Keychain, Android Keystore)
- Environment variables (server-side)
- Firebase Remote Config

## Security scope

**Protects against:**

- All attacks that XOR obfuscation protects against
- Binary analysis tools (Frida, IDA) — ciphertext without the key is mathematically useless
- Brute force — AES-256 has 2^256 possible keys, which is computationally infeasible to try
- Ciphertext tampering — GCM authentication detects and rejects modifications

**Does not protect against:**

- Runtime memory inspection after decryption — values exist as plain text in memory once decrypted
- Compromised key — if the key is leaked, all values are exposed
- Debugger attached during initialization — the key is visible at that moment

## Technical reference

| Component | Details |
|-----------|---------|
| Algorithm | AES-256-GCM |
| Key size | 256 bits (32 bytes) |
| IV/Nonce | 12 bytes, random per value |
| Auth tag | 16 bytes (128 bits) |
| Output format | Base64 (IV + ciphertext + tag) |
| Library | [fortis](https://pub.dev/packages/fortis) |
