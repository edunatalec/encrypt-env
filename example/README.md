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

---

## Configuration examples

The CLI supports `.yaml`, `.yml`, and `.json` config files. Below are ready-to-use templates for common scenarios.

### YAML

#### Environment (`environment/environment.yaml`)

```yaml
environment:
  base_url: 'http://localhost:3000'
  version: '1.0.0'
  production: false
  debug: true
  api_key: 'dev_api_key_123'
  timeout: 30
  headers:
    content_type: 'application/json'
    accept: 'application/json'
    authorization:
      prefix: 'Bearer'
      refresh_enabled: true
```

#### Endpoints (`environment/environment.yaml`)

```yaml
endpoint:
  auth_login: '/api/v1/auth/login'
  auth_register: '/api/v1/auth/register'
  auth_refresh: '/api/v1/auth/refresh'
  users_profile: '/api/v1/users/profile'
  users_update: '/api/v1/users/update'
  products_list: '/api/v1/products'
  products_detail: '/api/v1/products/{id}'
  orders_create: '/api/v1/orders'
  orders_history: '/api/v1/orders/history'
```

#### Database (`environment/environment.yaml`)

```yaml
database:
  host: 'localhost'
  port: 5432
  name: 'myapp_dev'
  ssl: false
  credentials:
    username: 'dev_user'
    password: 'dev_password'
  pool:
    min_connections: 2
    max_connections: 10
    idle_timeout: 300
```

#### Full config (all sections combined)

```yaml
environment:
  base_url: 'http://localhost:3000'
  version: '1.0.0'
  production: false
  debug: true
  api_key: 'dev_api_key_123'
  timeout: 30
  headers:
    content_type: 'application/json'
    accept: 'application/json'
    authorization:
      prefix: 'Bearer'
      refresh_enabled: true

endpoint:
  auth_login: '/api/v1/auth/login'
  auth_register: '/api/v1/auth/register'
  auth_refresh: '/api/v1/auth/refresh'
  users_profile: '/api/v1/users/profile'
  products_list: '/api/v1/products'
  orders_create: '/api/v1/orders'

database:
  host: 'localhost'
  port: 5432
  name: 'myapp_dev'
  ssl: false
  credentials:
    username: 'dev_user'
    password: 'dev_password'
  pool:
    min_connections: 2
    max_connections: 10
```

### JSON

#### Environment (`environment/environment.json`)

```json
{
  "environment": {
    "base_url": "http://localhost:3000",
    "version": "1.0.0",
    "production": false,
    "debug": true,
    "api_key": "dev_api_key_123",
    "timeout": 30,
    "headers": {
      "content_type": "application/json",
      "accept": "application/json",
      "authorization": {
        "prefix": "Bearer",
        "refresh_enabled": true
      }
    }
  }
}
```

#### Endpoints (`environment/environment.json`)

```json
{
  "endpoint": {
    "auth_login": "/api/v1/auth/login",
    "auth_register": "/api/v1/auth/register",
    "auth_refresh": "/api/v1/auth/refresh",
    "users_profile": "/api/v1/users/profile",
    "users_update": "/api/v1/users/update",
    "products_list": "/api/v1/products",
    "products_detail": "/api/v1/products/{id}",
    "orders_create": "/api/v1/orders",
    "orders_history": "/api/v1/orders/history"
  }
}
```

#### Database (`environment/environment.json`)

```json
{
  "database": {
    "host": "localhost",
    "port": 5432,
    "name": "myapp_dev",
    "ssl": false,
    "credentials": {
      "username": "dev_user",
      "password": "dev_password"
    },
    "pool": {
      "min_connections": 2,
      "max_connections": 10,
      "idle_timeout": 300
    }
  }
}
```

#### Full config (all sections combined)

```json
{
  "environment": {
    "base_url": "http://localhost:3000",
    "version": "1.0.0",
    "production": false,
    "debug": true,
    "api_key": "dev_api_key_123",
    "timeout": 30,
    "headers": {
      "content_type": "application/json",
      "accept": "application/json",
      "authorization": {
        "prefix": "Bearer",
        "refresh_enabled": true
      }
    }
  },
  "endpoint": {
    "auth_login": "/api/v1/auth/login",
    "auth_register": "/api/v1/auth/register",
    "auth_refresh": "/api/v1/auth/refresh",
    "users_profile": "/api/v1/users/profile",
    "products_list": "/api/v1/products",
    "orders_create": "/api/v1/orders"
  },
  "database": {
    "host": "localhost",
    "port": 5432,
    "name": "myapp_dev",
    "ssl": false,
    "credentials": {
      "username": "dev_user",
      "password": "dev_password"
    },
    "pool": {
      "min_connections": 2,
      "max_connections": 10
    }
  }
}
```

### Merging environments

Merging works the same way for `.yaml`, `.yml`, and `.json`. The base file and the environment override file can even use **different formats** — e.g. base in `.yaml` and override in `.json`. Resolution priority is `.yaml` > `.yml` > `.json` per file.

#### YAML

Base config (`environment/environment.yaml`):

```yaml
environment:
  base_url: 'http://localhost:3000'
  production: false
  debug: true
  api_key: 'dev_api_key_123'
  timeout: 30
  headers:
    content_type: 'application/json'
    authorization:
      prefix: 'Bearer'
      refresh_enabled: true

database:
  host: 'localhost'
  port: 5432
  name: 'myapp_dev'
  ssl: false
  credentials:
    username: 'dev_user'
    password: 'dev_password'
  pool:
    min_connections: 2
    max_connections: 10
```

Production override (`environment/prod_environment.yaml`):

```yaml
environment:
  base_url: 'https://api.myapp.com'
  production: true
  debug: false
  api_key: 'prod_api_key_abc'
  timeout: 10
  headers:
    authorization:
      refresh_enabled: false

database:
  host: 'db.myapp.com'
  ssl: true
  credentials:
    username: 'prod_user'
    password: 'prod_password'
  pool:
    min_connections: 10
    max_connections: 100
```

#### JSON

Base config (`environment/environment.json`):

```json
{
  "environment": {
    "base_url": "http://localhost:3000",
    "production": false,
    "debug": true,
    "api_key": "dev_api_key_123",
    "timeout": 30,
    "headers": {
      "content_type": "application/json",
      "authorization": {
        "prefix": "Bearer",
        "refresh_enabled": true
      }
    }
  },
  "database": {
    "host": "localhost",
    "port": 5432,
    "name": "myapp_dev",
    "ssl": false,
    "credentials": {
      "username": "dev_user",
      "password": "dev_password"
    },
    "pool": {
      "min_connections": 2,
      "max_connections": 10
    }
  }
}
```

Production override (`environment/prod_environment.json`):

```json
{
  "environment": {
    "base_url": "https://api.myapp.com",
    "production": true,
    "debug": false,
    "api_key": "prod_api_key_abc",
    "timeout": 10,
    "headers": {
      "authorization": {
        "refresh_enabled": false
      }
    }
  },
  "database": {
    "host": "db.myapp.com",
    "ssl": true,
    "credentials": {
      "username": "prod_user",
      "password": "prod_password"
    },
    "pool": {
      "min_connections": 10,
      "max_connections": 100
    }
  }
}
```

#### Generate with merge

Same command for both formats — the CLI auto-detects which file exists:

```sh
encrypt_env gen -e prod
```

> Values from `prod_environment.{yaml,yml,json}` override the base. Nested maps are merged recursively — unspecified values like `database.port` and `database.name` are preserved from the base config.
