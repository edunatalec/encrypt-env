import '../strategy/obfuscation_strategy.dart';
import '../utils/string_utils.dart';
import 'case_style.dart';

/// Builds the generated Dart source file from environment data.
class CodeBuilder {
  /// The case style for getter names.
  final CaseStyle caseStyle;

  /// The obfuscation strategy used to encode values.
  final ObfuscationStrategy strategy;

  /// Creates a new [CodeBuilder] instance.
  const CodeBuilder({
    required this.caseStyle,
    required this.strategy,
  });

  /// Builds the complete Dart source from [data].
  String build(Map<String, dynamic> data) {
    final file = StringBuffer();

    _buildHeader(file);
    _buildBody(file, data);
    _buildFooter(file);

    return file.toString();
  }

  void _buildHeader(StringBuffer file) {
    file.writeln(
      '/* ******************************************** */\n'
      '/* -- GENERATED CODE - DO NOT MODIFY BY HAND -- */\n'
      '/* ******************************************** */\n',
    );

    if (strategy.imports.isNotEmpty) {
      file.writeln(strategy.imports);
    }
  }

  void _buildBody(StringBuffer file, Map<String, dynamic> data) {
    for (final entry in data.entries) {
      _buildClass(file, {entry.key: entry.value});
    }
  }

  void _buildFooter(StringBuffer file) {
    file.write(strategy.decodeFunctionSource);
  }

  void _buildClass(StringBuffer file, Map<String, dynamic> map) {
    final key = map.keys.first;
    final name = key.toPascalCase();

    file.writeln('sealed class $name {');
    _buildGetters(file, map[key] as Map<String, dynamic>);
    file.writeln('}\n');
  }

  void _buildGetters(
    StringBuffer file,
    Map<String, dynamic> map, {
    bool private = false,
  }) {
    final entries = map.entries.toList();

    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final isLast = i == entries.length - 1;
      final name = _formatGetter(entry.key, private: private);

      if (entry.value is Map<String, dynamic>) {
        _buildMapGetter(file, name, entry.value as Map<String, dynamic>,
            private: private);
      } else {
        _buildValueGetter(file, name, entry, isLast: isLast);
      }
    }
  }

  void _buildMapGetter(
    StringBuffer file,
    String name,
    Map<String, dynamic> map, {
    bool private = false,
  }) {
    final text = map.keys.fold('', (prev, element) {
      final value = map[element];
      final encoded = strategy.encode(element);
      final decode = strategy.buildMapKeyDecode(encoded);
      final getterName = _formatGetter(element, private: private);

      return '$prev'
          '\t\t\t// $element: $value\n'
          '\t\t\t$decode: _$getterName,\n';
    });

    file.writeln(
      '\tstatic Map<String, dynamic> get $name {\n'
      '\t\treturn {\n'
      '$text'
      '\t\t};\n'
      '\t}\n',
    );

    _buildGetters(file, map, private: true);
  }

  void _buildValueGetter(
    StringBuffer file,
    String name,
    MapEntry<String, dynamic> entry, {
    bool isLast = false,
  }) {
    final encoded = strategy.encode(entry.value.toString());
    var body = strategy.buildGetterBody(encoded);

    if (entry.value is! String) {
      body = body.replaceFirst(
        'return ',
        'return ${entry.value.runtimeType}.parse(',
      );
      body += ')';
    }

    var text = '\t/// $name: ${entry.value}\n'
        '\tstatic ${entry.value.runtimeType} get $name {\n'
        '$body;\n'
        '\t}\n';

    if (isLast) {
      file.write(text);
    } else {
      file.writeln(text);
    }
  }

  String _formatGetter(String text, {bool private = false}) {
    text = text.replaceAll(' ', '_');

    switch (caseStyle) {
      case CaseStyle.snakeCase:
        text = text.toSnakeCase().toLowerCase();
      case CaseStyle.camelCase:
        text = text.toCamelCase();
      case CaseStyle.screamingSnakeCase:
        text = text.toSnakeCase().toUpperCase();
    }

    if (private) {
      text = '_$text';
    }

    return text;
  }
}
