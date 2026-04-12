# Ofuscação XOR

## O que é?

A ofuscação XOR é uma técnica que transforma valores em texto puro em sequências de bytes codificadas que não são legíveis por humanos. Ela utiliza a operação bitwise XOR (ou exclusivo) combinada com múltiplas camadas de transformação para dificultar a identificação dos valores originais no código-fonte e em binários compilados.

## Por que XOR?

Em aplicações client-side (Flutter/Dart), qualquer valor embutido no binário pode eventualmente ser extraído por um atacante determinado. Até criptografia AES-256 é inútil se a chave de descriptografia está no mesmo binário.

A ofuscação XOR eleva o esforço necessário para extrair valores de "trivial" para "requer ferramentas dedicadas de engenharia reversa." É a abordagem correta para valores como URLs base, chaves de SDK e feature flags que não devem ficar visíveis em texto puro, mas não são segredos criticamente sensíveis.

## Como funciona?

O algoritmo aplica quatro camadas de transformação a cada valor individualmente.

### Camada 1 — Salt por Valor

Um salt aleatório único (32 a 64 bytes) é gerado para cada valor usando `Random.secure()`.

```
salt = random_bytes(32..64)
```

Cada valor tem seu próprio salt independente. Conhecer o salt de um valor não revela nada sobre outro.

**Exemplo:** Dois valores terão salts completamente diferentes com tamanhos diferentes:

```dart
// valor "baseUrl" recebe um salt de 47 bytes
final s1 = [0x7d, 0x94, ...];  // 41 bytes
final s2 = [0x05, 0x55, ...];  // 6 bytes

// valor "apiKey" recebe um salt de 53 bytes
final s1 = [0xa7, 0x4f, ...];  // 13 bytes
final s2 = [0xca, 0xe1, ...];  // 40 bytes
```

### Camada 2 — Primeiro Passo XOR

Cada byte do texto puro é combinado com XOR com o byte correspondente do salt. O salt é cíclico se o valor for maior que o salt.

```
xored[i] = plain[i] ^ salt[i % salt.length]
```

**Exemplo** com `"hi"` e salt `[0xAA, 0xBB]`:

```
'h' = 0x68  →  0x68 ^ 0xAA = 0xC2
'i' = 0x69  →  0x69 ^ 0xBB = 0xD2
Resultado: [0xC2, 0xD2]
```

### Camada 3 — Embaralhamento de Bytes

Os bytes do XOR são reorganizados usando uma permutação Fisher-Yates. A permutação é determinística — semeada por um hash FNV-1a do salt.

```
seed = FNV1a(salt)
permutation = fisher_yates(length, LCG(seed))
shuffled[perm[i]] = xored[i]
```

Isso destrói a relação posicional entre o valor original e a saída codificada. Sem conhecer a permutação, um atacante não consegue determinar qual byte na saída corresponde a qual byte na entrada.

**Exemplo** com `[0xC2, 0xD2, 0xE5, 0xF1]` e permutação `[2, 0, 3, 1]`:

```
shuffled[2] = 0xC2  (do índice 0)
shuffled[0] = 0xD2  (do índice 1)
shuffled[3] = 0xE5  (do índice 2)
shuffled[1] = 0xF1  (do índice 3)
Resultado: [0xD2, 0xF1, 0xC2, 0xE5]
```

Um LCG (Gerador Congruencial Linear) determinístico é usado em vez de `dart:math Random` porque o `Random` do Dart não garante sequências idênticas entre versões do SDK. O LCG com constantes fixas (`a=1103515245, c=12345, m=2^31`) produz a mesma permutação para sempre.

### Camada 4 — Segundo Passo XOR com Chave Derivada

Uma segunda chave é derivada do salt invertendo-o e rotacionando cada byte 3 bits à direita. Os bytes embaralhados são combinados com XOR com essa chave derivada.

```
derived[i] = rotate_right(salt.reversed[i], 3)
output[i] = shuffled[i] ^ derived[i % derived.length]
```

**Exemplo** de derivação de chave para o byte `0xAA` (`10101010`):

```
rotate_right(10101010, 3) = 01010101 = 0x55
```

Isso adiciona uma segunda camada XOR independente. Um atacante que identifique o passo de embaralhamento ainda precisa reverter a chave derivada antes de chegar ao salt.

### Fragmentação do Salt

O salt é dividido em dois fragmentos em um ponto aleatório antes de ser armazenado no código gerado.

```dart
final s1 = [0x7d, 0x94, 0x51, ...];  // primeira parte
final s2 = [0x05, 0x55, 0xfe, ...];  // segunda parte
// Remontado em runtime: [...s1, ...s2]
```

O ponto de divisão varia por valor, então os fragmentos têm tamanhos diferentes a cada vez. Isso impede que o salt apareça como um único bloco reconhecível.

## Como decodifica?

Para reverter a ofuscação, as quatro camadas são aplicadas na ordem inversa:

```dart
String _decode(List<int> encoded, List<int> salt) {
  // Reverter camada 4: XOR com chave derivada
  final dk = salt.reversed.map((b) => ((b >> 3) | (b << 5)) & 0xFF).toList();
  final u2 = List.generate(encoded.length, (i) => encoded[i] ^ dk[i % dk.length]);

  // Reverter camada 3: desfazer embaralhamento
  final p = _perm(encoded.length, _seed(salt));
  final us = List.generate(encoded.length, (i) => u2[p[i]]);

  // Reverter camada 2: XOR com salt
  return String.fromCharCodes(
    List.generate(us.length, (i) => us[i] ^ salt[i % salt.length]),
  );
}
```

## Escopo de segurança

**Protege contra:**

- Exposição em texto puro no código-fonte e controle de versão
- Extração via comando `strings` em binários compilados
- Scanners automatizados de segredos que procuram padrões de chaves de API
- Inspeção casual por alguém navegando pelo código

**Não protege contra:**

- Engenharia reversa dedicada com debuggers (Frida, IDA)
- Inspeção de memória em runtime
- Um atacante que leia e entenda a função decode

Para valores que exigem segurança real, use criptografia AES-256 com uma chave em runtime fornecida de uma fonte segura externa.

## Referência técnica

| Componente | Algoritmo | Detalhes |
|------------|-----------|----------|
| Geração do salt | `Random.secure()` | 32-64 bytes por valor |
| Derivação do seed | Hash FNV-1a | Offset: `0x5f3759df`, Primo: `0x01000193` |
| Permutação | Embaralhamento Fisher-Yates | LCG: `a=1103515245, c=12345, m=2^31` |
| Derivação da chave | Inversão + rotação de bits | Rotação à direita por 3 bits |
| Formato de saída | Hexadecimal | Prefixo `0x`, separado por vírgula |
