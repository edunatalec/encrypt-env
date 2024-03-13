[![pub package](https://img.shields.io/pub/v/encrypt_env.svg)](https://pub.dev/packages/encrypt_env)
[![package publisher](https://img.shields.io/pub/publisher/encrypt_env.svg)](https://pub.dev/packages/encrypt_env/publisher)

encrypt_env is a Dart package designed to encrypt sensitive environment variables to enhance security for Flutter applications. It provides a convenient solution for protecting sensitive information such as API keys, passwords, and tokens stored in environment configuration files.

## Installation

To install the package, use the following command:

```sh
dart pub global activate encrypt_env
```

## Usage

1. Navigate to the root of your Flutter project and configure a folder named environment. Inside this folder, create a file named environment.yaml. This file will contain your sensitive environment variables.

![Folder example](./assets/folder-example.png)

2. Add your sensitive environment variables to the environment.yaml file. For example:

```yaml
environment:
  base_url: "http://localhost:3000"
  version: "1.0.0"
  production: false
  headers:
    api-key: ""
endpoints:
  endpoint_a: ""
  endpoint_b: ""
```

3. Run the following command in your terminal to encrypt the environment variables:

```sh
encrypt_env gen
```

**Note**: Ensure that you do not add the environment.yaml file to the assets section of your pubspec.yaml file to prevent it from being included in the final build of your application.

## Merging

You can merge a YAML file by providing an environment argument using the --environment option. For example, if you pass "prod" as the environment argument, the tool will merge the environment.yaml file with a prod_environment.yaml file, if it exists, into a single configuration.

```yaml
# prod_environment.yaml

environment:
  production: true
  base_url: "https://api.example.com"
  api_key: "your_production_api_key_here"
  database_url: "your_production_database_url_here"
```

```sh
encrypt_env gen --environment prod
```

## More

Customize the encryption process by providing optional arguments:

- `-e --environment`: Specify the environment name.
- `-y --yaml`: Specify the YAML file name. Defaults to environment.
- `--folder`: Specify the folder name. Defaults to environment.
- `--file-path`: Specify the encrypted file path. Defaults to lib.
- `--file`: Specify the encrypted file name. Defaults to environment.
- `--format`: Specify the getter name format. Defaults to ssc.

**Note**: Use the follow command for more information:

```sh
encrypt_env -h
```
