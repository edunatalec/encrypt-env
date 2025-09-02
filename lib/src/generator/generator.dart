import 'dart:io';
import 'dart:typed_data';

import '../utils/map_utils.dart';
import '../utils/string_utils.dart';
import 'package:yaml/yaml.dart';

import '../utils/encrypt_utils.dart';
import 'case_style.dart';
import 'generator_response.dart';

/// A class responsible for generating an encrypted file based on a YAML configuration.
///
/// This generator reads environment variables from a YAML file, applies encryption,
/// and writes the data into a Dart file with getter methods.
class Generator {
  /// The target environment (optional).
  final String? env;

  /// The format to be used for getter names.
  final CaseStyle caseStyle;

  /// The folder where the YAML file is located.
  final String folderName;

  /// The name of the YAML file (without extension).
  final String configName;

  /// Directory where the encrypted file will be saved.
  final Directory _fileDir;

  /// The encrypted Dart file that will be generated.
  final File _file;

  /// Creates a new [Generator] instance.
  ///
  /// Requires the [env] (optional), [caseStyle], [configName], [folderName],
  /// as well as [outDir] and [outFile] to define the output location.
  Generator({
    required this.env,
    required this.caseStyle,
    required this.configName,
    required this.folderName,
    required String outDir,
    required String outFile,
  })  : _fileDir = Directory(outDir),
        _file = File('$outDir/$outFile.dart');

  /// Randomly generated salt used for encryption.
  late Uint8List _salt;

  /// Runs the generator, creating an encrypted Dart file.
  ///
  /// Reads the YAML data, encrypts it, and writes it to the output file.
  Future<GeneratorResponse> run() async {
    final Map<String, dynamic> data = await _getDataFromConfigFile();

    _salt = randomBytes(keyBytesSize);

    final StringBuffer content = _generate(data);

    await _createEncryptedFile(content);

    return GeneratorResponse(
      environment: data.prettify(),
      path: _file.path,
    );
  }

  Future<void> _createEncryptedFile(StringBuffer content) async {
    await _fileDir.create();

    await _file.create();
    await _file.writeAsString(content.toString());
  }

  Future<Map<String, dynamic>> _getDataFromConfigFile() async {
    try {
      final YamlMap data = loadYaml(await _readConfigFile());

      if (env == null) {
        return data.convertToMap();
      }

      final YamlMap envData = loadYaml(await _readConfigFile(env));

      return data.convertToMap().merge(envData.convertToMap());
    } catch (_) {
      throw 'You must provide a valid YAML configuration. For more details, see the documentation at https://pub.dev/packages/encrypt_env.';
    }
  }

  StringBuffer _generate(Map<String, dynamic> data) {
    final file = StringBuffer();

    _buildHeader(file);
    _buildBody(file, data);
    _buildFooter(file);

    return file;
  }

  void _buildHeader(StringBuffer file) {
    file.writeln(
      '/* ******************************************** */\n'
      '/* -- GENERATED CODE - DO NOT MODIFY BY HAND -- */\n'
      '/* ******************************************** */\n'
      "\nimport 'dart:convert';\n",
    );
  }

  void _buildBody(StringBuffer file, Map<String, dynamic> data) {
    for (final entry in data.entries) {
      final Map<String, dynamic> value =
          Map<String, dynamic>.fromEntries([entry]);

      _buildClass(file, value);
    }
  }

  void _buildFooter(StringBuffer file) {
    final String saltAsHex = listToHex(_salt);

    file.write(
      'List<int> get _salt => [$saltAsHex];\n'
      '\n'
      'String _decode(List<int> encoded) {\n'
      '\treturn const Utf8Decoder(allowMalformed: true).convert(\n'
      '\t\tencoded.asMap().entries\n'
      '\t\t\t.map((MapEntry<int, int> e) => e.value ^ _salt[e.key % _salt.length])\n'
      '\t\t\t.toList(),\n'
      '\t);\n'
      '}',
    );
  }

  void _buildClass(StringBuffer file, Map<String, dynamic> map) {
    final String key = map.keys.first;
    final String name = key.toPascalCase();

    file.writeln('sealed class $name {');

    _buildGetters(file, map[key]);

    file.writeln('}\n');
  }

  void _buildGetters(
    StringBuffer file,
    Map<String, dynamic> map, {
    bool private = false,
  }) {
    for (int i = 0; i < map.entries.length; i++) {
      final MapEntry entry = map.entries.elementAt(i);

      final bool isLast = i == map.entries.length - 1;

      final String name = _formatGetter(
        entry.key,
        private: private,
      );

      if (entry.value is Map<String, dynamic>) {
        final String text = entry.value.keys.fold('', (previusValue, element) {
          final dynamic value = entry.value[element];
          final String enconded = stringToHex(element, _salt);
          final String name = _formatGetter(
            element,
            private: private,
          );

          return '$previusValue'
              '\t\t\t// $element: $value\n'
              '\t\t\t_decode([$enconded]): _$name,\n';
        });

        String value = '\tstatic Map<String, dynamic> get $name {\n'
            '\t\treturn {\n'
            '$text'
            '\t\t};\n'
            '\t}\n';

        file.writeln(value);

        _buildGetters(file, entry.value, private: true);
      } else {
        final String encoded = stringToHex(entry.value.toString(), _salt);

        String text = '\t/// $name: ${entry.value}\n'
            '\tstatic ${entry.value.runtimeType} get $name {\n'
            '\t\tfinal List<int> encoded = [$encoded];\n'
            '\n';

        String decode = '\t\treturn _decode(encoded);';

        if (entry.value is! String) {
          decode =
              '\t\treturn ${entry.value.runtimeType}.parse(_decode(encoded));';
        }

        text += '$decode\n'
            '\t}\n';

        if (isLast) {
          file.write(text);
        } else {
          file.writeln(text);
        }
      }
    }
  }

  Future<String> _readConfigFile([String? env]) async {
    String name = '$configName.yaml';

    if (env != null) {
      name = '${env}_$name';
    }

    final String path = '$folderName/$name';

    try {
      return File(path).readAsString();
    } catch (_) {
      throw '$path does not exist. Please check and try again.';
    }
  }

  String _formatGetter(
    String text, {
    bool private = false,
  }) {
    text = text.replaceAll(' ', '_');

    switch (caseStyle) {
      case CaseStyle.snakeCase:
        text = text.toSnakeCase().toLowerCase();
        break;
      case CaseStyle.camelCase:
        text = text.toCamelCase();
        break;
      case CaseStyle.screamingSnakeCase:
        text = text.toSnakeCase().toUpperCase();
        break;
    }

    if (private) {
      text = '_$text';
    }

    return text;
  }
}
