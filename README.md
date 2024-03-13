## encrypt_env

An encrypted file generator.

## Getting Started 🚀

Download the project and run this command inside the folder

```sh
dart pub global activate encrypt_env
```

## Usage

Now after the installation you are able to encrypt your sensitive data, but before that we need the data

![Não me diga](./assets/nao-me-diga.jpg)

You need to create a YAML file inside your project in the root as the follow example

![Folder example](./assets/folder-example.png)

Maybe you are wondering, "What I need to put inside the environment.yaml file?". The answer is simple, just folow the example.

`environment.yaml`

```yaml
environment:
  base_url: "http://localhost:3000"
  version: "1.0.0"
  production: false
  database_path: ""
  app_store_id: ""
  app_store_url: ""
  play_store_url: ""
  package_name: ""
  bundle_id: ""
  headers:
    api-key: ""
endpoints:
  endpoint_a: ""
  endpoint_b: ""
```

`prod_environment.yaml`

```yaml
environment:
  production: true
```

After all of that, go to your new environment folder and via terminal, run

```sh
$ encrypt_env gen
```

The generator always merge yaml\`s files, so when you use `encrypt_env gen --env prod`, actually
you are merging the `environment.yaml` with `prod_environment.yaml`

![It's done](./assets/its-done.jpeg)

## Features

```sh
# Generator
$ encrypt_env gen
$ encrypt_env gen --env prod
$ encrypt_env gen --file-name environment.util
$ encrypt_env gen --file-path ../lib/src/core/utils
$ encrypt_env gen --yaml-file-name environment
$ encrypt_env gen --uppercase false

# Show CLI version
$ encrypt_env --version

# Show usage help
$ encrypt_env --help
```
