# Ofuscación XOR

## ¿Qué es?

La ofuscación XOR es una técnica que transforma valores en texto plano en secuencias de bytes codificadas que no son legibles por humanos. Utiliza la operación bitwise XOR (o exclusivo) combinada con múltiples capas de transformación para dificultar la identificación de los valores originales en el código fuente y en binarios compilados.

## ¿Por qué XOR?

En aplicaciones del lado del cliente (Flutter/Dart), cualquier valor incrustado en el binario puede eventualmente ser extraído por un atacante determinado. Incluso el cifrado AES-256 es inútil si la clave de descifrado está en el mismo binario.

La ofuscación XOR eleva el esfuerzo necesario para extraer valores de "trivial" a "requiere herramientas dedicadas de ingeniería inversa." Es el enfoque correcto para valores como URLs base, claves de SDK y feature flags que no deben ser visibles en texto plano, pero no son secretos críticamente sensibles.

## ¿Cómo funciona?

El algoritmo aplica cuatro capas de transformación a cada valor individualmente.

### Capa 1 — Salt por Valor

Un salt aleatorio único (32 a 64 bytes) se genera para cada valor usando `Random.secure()`.

```
salt = random_bytes(32..64)
```

Cada valor tiene su propio salt independiente. Conocer el salt de un valor no revela nada sobre otro.

**Ejemplo:** Dos valores tendrán salts completamente diferentes con tamaños diferentes:

```dart
// valor "baseUrl" recibe un salt de 47 bytes
final s1 = [0x7d, 0x94, ...];  // 41 bytes
final s2 = [0x05, 0x55, ...];  // 6 bytes

// valor "apiKey" recibe un salt de 53 bytes
final s1 = [0xa7, 0x4f, ...];  // 13 bytes
final s2 = [0xca, 0xe1, ...];  // 40 bytes
```

### Capa 2 — Primer Paso XOR

Cada byte del texto plano se combina con XOR con el byte correspondiente del salt. El salt es cíclico si el valor es más largo que el salt.

```
xored[i] = plain[i] ^ salt[i % salt.length]
```

**Ejemplo** con `"hi"` y salt `[0xAA, 0xBB]`:

```
'h' = 0x68  →  0x68 ^ 0xAA = 0xC2
'i' = 0x69  →  0x69 ^ 0xBB = 0xD2
Resultado: [0xC2, 0xD2]
```

### Capa 3 — Mezcla de Bytes

Los bytes del XOR se reorganizan usando una permutación Fisher-Yates. La permutación es determinística — sembrada por un hash FNV-1a del salt.

```
seed = FNV1a(salt)
permutation = fisher_yates(length, LCG(seed))
shuffled[perm[i]] = xored[i]
```

Esto destruye la relación posicional entre el valor original y la salida codificada. Sin conocer la permutación, un atacante no puede determinar qué byte en la salida corresponde a qué byte en la entrada.

**Ejemplo** con `[0xC2, 0xD2, 0xE5, 0xF1]` y permutación `[2, 0, 3, 1]`:

```
shuffled[2] = 0xC2  (del índice 0)
shuffled[0] = 0xD2  (del índice 1)
shuffled[3] = 0xE5  (del índice 2)
shuffled[1] = 0xF1  (del índice 3)
Resultado: [0xD2, 0xF1, 0xC2, 0xE5]
```

Un LCG (Generador Congruencial Lineal) determinístico se usa en vez de `dart:math Random` porque el `Random` de Dart no garantiza secuencias idénticas entre versiones del SDK. El LCG con constantes fijas (`a=1103515245, c=12345, m=2^31`) produce la misma permutación para siempre.

### Capa 4 — Segundo Paso XOR con Clave Derivada

Una segunda clave se deriva del salt invirtiéndolo y rotando cada byte 3 bits a la derecha. Los bytes mezclados se combinan con XOR con esta clave derivada.

```
derived[i] = rotate_right(salt.reversed[i], 3)
output[i] = shuffled[i] ^ derived[i % derived.length]
```

**Ejemplo** de derivación de clave para el byte `0xAA` (`10101010`):

```
rotate_right(10101010, 3) = 01010101 = 0x55
```

Esto añade una segunda capa XOR independiente. Un atacante que identifique el paso de mezcla aún necesita revertir la clave derivada antes de llegar al salt.

### Fragmentación del Salt

El salt se divide en dos fragmentos en un punto aleatorio antes de almacenarse en el código generado.

```dart
final s1 = [0x7d, 0x94, 0x51, ...];  // primera parte
final s2 = [0x05, 0x55, 0xfe, ...];  // segunda parte
// Reensamblado en tiempo de ejecución: [...s1, ...s2]
```

El punto de división varía por valor, así que los fragmentos tienen tamaños diferentes cada vez. Esto impide que el salt aparezca como un único bloque reconocible.

## ¿Cómo decodifica?

Para revertir la ofuscación, las cuatro capas se aplican en orden inverso:

```dart
String _decode(List<int> encoded, List<int> salt) {
  // Revertir capa 4: XOR con clave derivada
  final dk = salt.reversed.map((b) => ((b >> 3) | (b << 5)) & 0xFF).toList();
  final u2 = List.generate(encoded.length, (i) => encoded[i] ^ dk[i % dk.length]);

  // Revertir capa 3: deshacer mezcla
  final p = _perm(encoded.length, _seed(salt));
  final us = List.generate(encoded.length, (i) => u2[p[i]]);

  // Revertir capa 2: XOR con salt
  return String.fromCharCodes(
    List.generate(us.length, (i) => us[i] ^ salt[i % salt.length]),
  );
}
```

## Alcance de seguridad

**Protege contra:**

- Exposición en texto plano en código fuente y control de versiones
- Extracción vía comando `strings` en binarios compilados
- Escaneadores automatizados de secretos que buscan patrones de claves de API
- Inspección casual por alguien navegando el código

**No protege contra:**

- Ingeniería inversa dedicada con debuggers (Frida, IDA)
- Inspección de memoria en tiempo de ejecución
- Un atacante que lea y entienda la función decode

Para valores que requieren seguridad real, usa cifrado AES-256 con una clave en tiempo de ejecución proporcionada desde una fuente segura externa.

## Referencia técnica

| Componente | Algoritmo | Detalles |
|------------|-----------|----------|
| Generación del salt | `Random.secure()` | 32-64 bytes por valor |
| Derivación del seed | Hash FNV-1a | Offset: `0x5f3759df`, Primo: `0x01000193` |
| Permutación | Mezcla Fisher-Yates | LCG: `a=1103515245, c=12345, m=2^31` |
| Derivación de la clave | Inversión + rotación de bits | Rotación a la derecha por 3 bits |
| Formato de salida | Hexadecimal | Prefijo `0x`, separado por coma |
