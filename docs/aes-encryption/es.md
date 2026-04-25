# Cifrado AES-256-GCM

## ¿Qué es?

AES-256-GCM es un algoritmo de cifrado simétrico que transforma texto plano en texto cifrado que es matemáticamente imposible de revertir sin la clave secreta. Combina AES (Advanced Encryption Standard) con GCM (Galois/Counter Mode), que proporciona tanto confidencialidad como autenticidad.

A diferencia de la ofuscación XOR, el cifrado AES-256-GCM ofrece protección criptográfica real — incluso con acceso total a los datos cifrados, los valores originales no pueden ser recuperados sin la clave.

## ¿Por qué AES-256-GCM?

- **AES-256** es el estándar de la industria para cifrado simétrico, aprobado por el NIST y usado por gobiernos e instituciones financieras en todo el mundo
- **GCM** detecta alteraciones — si alguien modifica el texto cifrado, el descifrado falla en vez de devolver datos corruptos
- **IV aleatorio por valor** — cifrar el mismo valor dos veces produce textos cifrados completamente diferentes, previniendo el análisis de patrones

## ¿Cómo funciona?

### Cifrado (build time)

Cada valor pasa por este proceso:

1. Se genera un **IV de 12 bytes** (Vector de Inicialización) aleatorio
2. El valor se cifra con AES-256 usando la clave y el IV
3. GCM produce una **etiqueta de autenticación de 16 bytes** que verifica la integridad
4. La salida se empaqueta como: `IV (12 bytes) + texto cifrado + etiqueta (16 bytes)`
5. Todo se codifica como una única **cadena base64**

**Ejemplo** con el valor `"http://localhost:3000"`:

```
Entrada:  "http://localhost:3000"
Clave:    zOXJHeEV6EVCSludkRizg+oFSs3rdgCYtOgvgkayZBI=  (256 bits)
IV:       [12 bytes aleatorios]

Salida:   pLtABeegYXd+amw7aMNbNZ+0K0DPb5JmrrAG9xhmFfdXb/MKCo/W6OCYXmocFUEnuA==
```

El mismo valor cifrado de nuevo produce un resultado diferente porque el IV es aleatorio:

```
Primera:  pLtABeegYXd+amw7aMNbNZ+0K0DPb5JmrrAG9xhmFfdXb/MKCo/W6OCYXmocFUEnuA==
Segunda:  G0+SIfVcsrCY7GLWL5A/groe40fcqTD438NbQrF4KXdnx7ctelYX0R/jd9QjbS15+g==
```

Ambas descifran al mismo valor original, pero un atacante no puede identificar que representan los mismos datos.

### Descifrado (runtime)

Para descifrar, el proceso se invierte:

1. La cadena base64 se decodifica
2. Los primeros 12 bytes se extraen como IV
3. Los últimos 16 bytes se extraen como etiqueta de autenticación
4. Los bytes restantes son el texto cifrado
5. AES-256-GCM descifra usando la clave, IV y etiqueta
6. Si la etiqueta no coincide (los datos fueron alterados), el descifrado falla con un error

**Ejemplo:**

```
Entrada:  pLtABeegYXd+amw7aMNbNZ+0K0DPb5JmrrAG9xhmFfdXb/MKCo/W6OCYXmocFUEnuA==
Clave:    zOXJHeEV6EVCSludkRizg+oFSs3rdgCYtOgvgkayZBI=

→ Extraer IV:    pLtABeegYXd+amw7  (primeros 12 bytes)
→ Extraer etiqueta: FfdXb/MKCo...  (últimos 16 bytes)
→ Texto cifrado: aMNbNZ+0K0DP...   (bytes del medio)
→ Descifrar con AES-256-GCM

Salida:   "http://localhost:3000"
```

### Requisito de la clave

La clave es un valor aleatorio de **256 bits (32 bytes)** codificado en base64.

**Ejemplo de clave:** `zOXJHeEV6EVCSludkRizg+oFSs3rdgCYtOgvgkayZBI=`

La clave **nunca se almacena** en el archivo generado ni en el binario. Debe proporcionarse en tiempo de ejecución desde una fuente segura externa:

- API del backend
- Almacenamiento seguro del dispositivo (iOS Keychain, Android Keystore)
- Variables de entorno (lado del servidor)
- Firebase Remote Config

## Alcance de seguridad

**Protege contra:**

- Todos los ataques contra los que la ofuscación XOR protege
- Herramientas de análisis de binarios (Frida, IDA) — texto cifrado sin la clave es matemáticamente inútil
- Fuerza bruta — AES-256 tiene 2^256 claves posibles, lo cual es computacionalmente inviable de intentar
- Alteración del texto cifrado — la autenticación GCM detecta y rechaza modificaciones

**No protege contra:**

- Inspección de memoria en runtime después del descifrado — los valores existen como texto plano en memoria una vez descifrados
- Clave comprometida — si la clave se filtra, todos los valores quedan expuestos
- Debugger conectado durante la inicialización — la clave es visible en ese momento

## Referencia técnica

| Componente | Detalles |
|------------|----------|
| Algoritmo | AES-256-GCM |
| Tamaño de la clave | 256 bits (32 bytes) |
| IV/Nonce | 12 bytes, aleatorio por valor |
| Etiqueta de autenticación | 16 bytes (128 bits) |
| Formato de salida | Base64 (IV + texto cifrado + etiqueta) |
| Biblioteca | [fortis](https://pub.dev/packages/fortis) |
