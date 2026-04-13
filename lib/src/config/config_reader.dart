import 'dart:io';

import 'package:yaml/yaml.dart';

import '../utils/map_utils.dart';

/// Reads and merges YAML configuration files.
class ConfigReader {
  /// The folder where the YAML file is located.
  final String folderName;

  /// The name of the YAML file (without extension).
  final String configName;

  /// The target environment (optional).
  final String? env;

  /// Creates a new [ConfigReader] instance.
  const ConfigReader({
    required this.folderName,
    required this.configName,
    this.env,
  });

  /// Reads the base config file and optionally merges with an
  /// environment-specific file.
  Future<Map<String, dynamic>> read() async {
    try {
      final YamlMap data = loadYaml(await _readFile());

      if (env == null) {
        return data.convertToMap();
      }

      final YamlMap envData = loadYaml(await _readFile(env));

      return data.convertToMap().merge(envData.convertToMap());
    } catch (e) {
      throw 'Invalid YAML configuration: $e\n'
          'For more details, see the documentation at '
          'https://pub.dev/packages/encrypt_env.';
    }
  }

  Future<String> _readFile([String? env]) async {
    var name = '$configName.yaml';

    if (env != null) {
      name = '${env}_$name';
    }

    final path = '$folderName/$name';

    try {
      return await File(path).readAsString();
    } catch (e) {
      throw '$path does not exist: $e';
    }
  }
}
