import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';

import '../utils/map_utils.dart';

/// Reads and merges configuration files (YAML or JSON).
class ConfigReader {
  static const _supportedExtensions = ['.yaml', '.yml', '.json'];

  /// The folder where the config file is located.
  final String folderName;

  /// The name of the config file (without extension).
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
      final data = await _loadConfig();

      if (env == null) return data;

      final envData = await _loadConfig(env);

      return data.merge(envData);
    } catch (e) {
      throw 'Invalid configuration: $e\n'
          'For more details, see the documentation at '
          'https://pub.dev/packages/encrypt_env.';
    }
  }

  Future<Map<String, dynamic>> _loadConfig([String? env]) async {
    final baseName = env != null ? '${env}_$configName' : configName;

    for (final ext in _supportedExtensions) {
      final path = '$folderName/$baseName$ext';
      final file = File(path);

      if (await file.exists()) {
        final content = await file.readAsString();
        return _parse(content, ext);
      }
    }

    final tried =
        _supportedExtensions.map((ext) => '$folderName/$baseName$ext').join(
              ', ',
            );

    throw 'No config file found. Looked for: $tried';
  }

  Map<String, dynamic> _parse(String content, String extension) {
    if (extension == '.json') {
      final decoded = jsonDecode(content);

      if (decoded is Map<String, dynamic>) return decoded;

      throw 'JSON config must be a top-level object';
    }

    final YamlMap data = loadYaml(content);

    return data.convertToMap();
  }
}
