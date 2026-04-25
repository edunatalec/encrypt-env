# Criptografia AES-256-GCM

## O que é?

AES-256-GCM é um algoritmo de criptografia simétrica que transforma texto puro em texto cifrado que é matematicamente impossível de reverter sem a chave secreta. Ele combina AES (Advanced Encryption Standard) com GCM (Galois/Counter Mode), que fornece tanto confidencialidade quanto autenticidade.

Diferente da ofuscação XOR, a criptografia AES-256-GCM oferece proteção criptográfica real — mesmo com acesso total aos dados criptografados, os valores originais não podem ser recuperados sem a chave.

## Por que AES-256-GCM?

- **AES-256** é o padrão da indústria para criptografia simétrica, aprovado pelo NIST e usado por governos e instituições financeiras no mundo todo
- **GCM** detecta adulteração — se alguém modificar o texto cifrado, a descriptografia falha em vez de retornar dados corrompidos
- **IV aleatório por valor** — criptografar o mesmo valor duas vezes produz textos cifrados completamente diferentes, prevenindo análise de padrões

## Como funciona?

### Criptografia (build time)

Cada valor passa por este processo:

1. Um **IV de 12 bytes** (Vetor de Inicialização) aleatório é gerado
2. O valor é criptografado com AES-256 usando a chave e o IV
3. O GCM produz uma **tag de autenticação de 16 bytes** que verifica a integridade
4. A saída é empacotada como: `IV (12 bytes) + texto cifrado + tag (16 bytes)`
5. Tudo é codificado como uma única **string base64**

**Exemplo** com o valor `"http://localhost:3000"`:

```
Entrada:  "http://localhost:3000"
Chave:    zOXJHeEV6EVCSludkRizg+oFSs3rdgCYtOgvgkayZBI=  (256 bits)
IV:       [12 bytes aleatórios]

Saída:    pLtABeegYXd+amw7aMNbNZ+0K0DPb5JmrrAG9xhmFfdXb/MKCo/W6OCYXmocFUEnuA==
```

O mesmo valor criptografado novamente produz um resultado diferente porque o IV é aleatório:

```
Primeira: pLtABeegYXd+amw7aMNbNZ+0K0DPb5JmrrAG9xhmFfdXb/MKCo/W6OCYXmocFUEnuA==
Segunda:  G0+SIfVcsrCY7GLWL5A/groe40fcqTD438NbQrF4KXdnx7ctelYX0R/jd9QjbS15+g==
```

Ambas descriptografam para o mesmo valor original, mas um atacante não consegue identificar que representam os mesmos dados.

### Descriptografia (runtime)

Para descriptografar, o processo é invertido:

1. A string base64 é decodificada
2. Os primeiros 12 bytes são extraídos como IV
3. Os últimos 16 bytes são extraídos como tag de autenticação
4. Os bytes restantes são o texto cifrado
5. AES-256-GCM descriptografa usando a chave, IV e tag
6. Se a tag não corresponder (dados foram adulterados), a descriptografia falha com um erro

**Exemplo:**

```
Entrada:  pLtABeegYXd+amw7aMNbNZ+0K0DPb5JmrrAG9xhmFfdXb/MKCo/W6OCYXmocFUEnuA==
Chave:    zOXJHeEV6EVCSludkRizg+oFSs3rdgCYtOgvgkayZBI=

→ Extrair IV:   pLtABeegYXd+amw7  (primeiros 12 bytes)
→ Extrair tag:  FfdXb/MKCo...     (últimos 16 bytes)
→ Texto cifrado: aMNbNZ+0K0DP...  (bytes do meio)
→ Descriptografar com AES-256-GCM

Saída:    "http://localhost:3000"
```

### Requisito da chave

A chave é um valor aleatório de **256 bits (32 bytes)** codificado em base64.

**Exemplo de chave:** `zOXJHeEV6EVCSludkRizg+oFSs3rdgCYtOgvgkayZBI=`

A chave **nunca é armazenada** no arquivo gerado ou no binário. Ela deve ser fornecida em runtime de uma fonte segura externa:

- API do backend
- Armazenamento seguro do dispositivo (iOS Keychain, Android Keystore)
- Variáveis de ambiente (server-side)
- Firebase Remote Config

## Escopo de segurança

**Protege contra:**

- Todos os ataques contra os quais a ofuscação XOR protege
- Ferramentas de análise de binários (Frida, IDA) — texto cifrado sem a chave é matematicamente inútil
- Força bruta — AES-256 tem 2^256 chaves possíveis, o que é computacionalmente inviável de tentar
- Adulteração do texto cifrado — a autenticação GCM detecta e rejeita modificações

**Não protege contra:**

- Inspeção de memória em runtime após a descriptografia — valores existem como texto puro na memória uma vez descriptografados
- Chave comprometida — se a chave vazar, todos os valores são expostos
- Debugger conectado durante a inicialização — a chave é visível nesse momento

## Referência técnica

| Componente | Detalhes |
|------------|----------|
| Algoritmo | AES-256-GCM |
| Tamanho da chave | 256 bits (32 bytes) |
| IV/Nonce | 12 bytes, aleatório por valor |
| Tag de autenticação | 16 bytes (128 bits) |
| Formato de saída | Base64 (IV + texto cifrado + tag) |
| Biblioteca | [fortis](https://pub.dev/packages/fortis) |
