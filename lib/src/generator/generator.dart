import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:encrypt_env/src/utils/map.utils.dart';
import 'package:encrypt_env/src/utils/string.utils.dart';
import 'package:yaml/yaml.dart';

import '../utils/encrypt.utils.dart';
import 'generator.response.dart';

class Generator {
  final String? _env;
  final String _filePath;
  final String _fileName;
  final String _yamlFileName;
  final bool _uppercase;

  Generator({
    String? env,
    required String filePath,
    required String fileName,
    required String yamlFileName,
    required bool uppercase,
  })  : _env = env,
        _filePath = filePath,
        _fileName = fileName,
        _yamlFileName = yamlFileName,
        _uppercase = uppercase;

  late Uint8List _salt;

  String get _getFileName => '$_fileName.dart';
  File get _file => File('$_filePath/$_getFileName');
  Directory get _directory => Directory(_filePath);

  Future<GeneratorResponse> run() async {
    final Map data = _readFileAndParseData();

    final StringBuffer content = _generate(data);

    const JsonEncoder encoder = JsonEncoder.withIndent('  ');
    final String prettyJson = encoder.convert(data);

    _directory.createSync();

    _file
      ..createSync()
      ..writeAsStringSync(content.toString());

    return GeneratorResponse(
      environment: prettyJson,
      path: _file.path,
    );
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
    file.writeln('\t$name._();\n');

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

      final String name = entry.key
          .toString()
          .transformGetter(private: private, uppercase: _uppercase);

      if (entry.value is Map) {
        final String text = entry.value.keys.fold('', (previusValue, element) {
          final String value = entry.value[element];
          final String enconded = stringToHex(element, _salt);
          final String name = element
              .toString()
              .transformGetter(private: private, uppercase: _uppercase);

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

  String _readFile([String? env]) {
    String fileName = '$_yamlFileName.yaml';

    if (env != null) {
      fileName = '${env}_$fileName';
    }

    try {
      return File(fileName).readAsStringSync();
    } catch (_) {
      throw 'The $fileName does not exists';
    }
  }

  Map _readFileAndParseData() {
    final String content = _readFile();
    final YamlMap data = loadYaml(content);

    if (_env == null) {
      return data;
    }

    final String mergeContent = _readFile(_env);

    final YamlMap mergedData = loadYaml(mergeContent);

    return data.merge(mergedData);
  }
}
