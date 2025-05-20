import 'dart:io';
import 'dart:typed_data';

import '../utils/map_utils.dart';
import '../utils/string_utils.dart';
import 'package:yaml/yaml.dart';

import '../utils/encrypt_utils.dart';
import 'generator_format.dart';
import 'generator_response.dart';

/// A class responsible for generating an encrypted file based on a YAML configuration.
///
/// This generator reads environment variables from a YAML file, applies encryption,
/// and writes the data into a Dart file with getter methods.
class Generator {
  /// The target environment (optional).
  final String? env;

  /// The format to be used for getter names.
  final GeneratorFormat format;

  /// The folder where the YAML file is located.
  final String folderName;

  /// The name of the YAML file (without extension).
  final String yamlName;

  /// Directory where the encrypted file will be saved.
  final Directory _fileDir;

  /// The encrypted Dart file that will be generated.
  final File _file;

  /// Creates a new [Generator] instance.
  ///
  /// Requires the [env] (optional), [format], [yamlName], [folderName],
  /// as well as [filePath] and [fileName] to define the output location.
  Generator({
    required this.env,
    required this.format,
    required this.yamlName,
    required this.folderName,
    required String filePath,
    required String fileName,
  })  : _fileDir = Directory(filePath),
        _file = File('$filePath/$fileName.dart');

  /// Randomly generated salt used for encryption.
  late Uint8List _salt;

  /// Runs the generator, creating an encrypted Dart file.
  ///
  /// Reads the YAML data, encrypts it, and writes it to the output file.
  Future<GeneratorResponse> run() async {
    final Map data = _getMappedDataFromYaml;

    final StringBuffer content = _generate(data);

    _fileDir.createSync();

    _file
      ..createSync()
      ..writeAsStringSync(content.toString());

    return GeneratorResponse(
      environment: data.prettify(),
      path: _file.path,
    );
  }

  Map get _getMappedDataFromYaml {
    final YamlMap data = loadYaml(_readYamlFile());

    if (env == null) {
      return data;
    }

    final YamlMap envData = loadYaml(_readYamlFile(env));

    return data.merge(envData);
  }

  StringBuffer _generate(Map data) {
    _salt = randomBytes(keyBytesSize);

    final StringBuffer file = StringBuffer();

    _buildHeader(file);
    _buildBody(file, data);
    _buildFooter(file);

    return file;
  }

  void _buildHeader(StringBuffer file) {
    file.writeln(
      '/* ******************************************** */\n'
      '/* -- GENERATED CODE - DO NOT MODIFY BY HAND -- */\n'
      '/* ******************************************** */\n',
    );

    final List<String> imports = ["import 'dart:convert';"];

    file.writeln("${imports.join('\n')}\n");
  }

  void _buildBody(StringBuffer file, Map data) {
    for (final entry in data.entries) {
      final Map map = Map.fromEntries([entry]);

      _buildClass(file, map);
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

  void _buildClass(StringBuffer file, Map map) {
    final String key = map.keys.first.toString();
    final String name = key.toPascalCase();

    file.writeln('class $name {');
    file.writeln('\t$name._(); // coverage:ignore-line\n');

    _buildGetters(file, map[key]);

    file.writeln('}\n');
  }

  void _buildGetters(
    StringBuffer file,
    Map data, {
    bool private = false,
  }) {
    for (int i = 0; i < data.entries.length; i++) {
      final MapEntry entry = data.entries.elementAt(i);
      final bool isLast = i == data.entries.length - 1;

      final String name = _formatGetter(
        entry.key,
        format: format,
        private: private,
      );

      if (entry.value is Map) {
        final String text = entry.value.keys.fold('', (previusValue, element) {
          final String value = entry.value[element];
          final String enconded = stringToHex(element, _salt);
          final String name = _formatGetter(
            element,
            format: format,
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
        final bool isBool = entry.value is bool;

        final String encoded = stringToHex(entry.value.toString(), _salt);

        String text = '\t/// $name: ${entry.value}\n'
            '\tstatic ${isBool ? 'bool' : 'String'} get $name {\n'
            '\t\tfinal List<int> encoded = [$encoded];\n'
            '\n';

        String decode = '\t\treturn _decode(encoded)';

        if (isBool) {
          final String trueEnconded = stringToHex('true', _salt);

          decode += ' == _decode([$trueEnconded])';
        }

        decode += ';\n';

        text += '$decode'
            '\t}\n';

        if (isLast) {
          file.write(text);
        } else {
          file.writeln(text);
        }
      }
    }
  }

  String _readYamlFile([String? env]) {
    String name = '$yamlName.yaml';

    if (env != null) {
      name = '${env}_$name';
    }

    final String path = '$folderName/$name';

    try {
      return File(path).readAsStringSync();
    } catch (_) {
      throw '$path does not exist. Please check and try again.';
    }
  }

  String _formatGetter(
    String text, {
    required GeneratorFormat format,
    bool private = false,
  }) {
    text = text
        .trim()
        .replaceAll('-', '_')
        .split(regex)
        .where((element) => element.isNotEmpty)
        .toList()
        .join('_');

    switch (format) {
      case GeneratorFormat.snakeCase:
        text = text.toLowerCase();
        break;
      case GeneratorFormat.camelCase:
        text = text.toCamelCase();
        break;
      case GeneratorFormat.screamingSnakeCase:
        text = text.toUpperCase();
        break;
    }

    return '${private ? '_' : ''}$text';
  }
}
