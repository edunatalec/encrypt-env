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
    final StringBuffer file = StringBuffer();

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
      final Map<String, dynamic> sectionData =
          entry.value as Map<String, dynamic>;

      _buildClass(
        file,
        pathSegments: <String>[entry.key.toPascalCase()],
        data: sectionData,
        isTopLevel: true,
      );
    }
  }

  void _buildFooter(StringBuffer file) {
    file.write(strategy.decodeFunctionSource);
  }

  void _buildClass(
    StringBuffer file, {
    required List<String> pathSegments,
    required Map<String, dynamic> data,
    required bool isTopLevel,
  }) {
    final String className = pathSegments.join('');

    if (isTopLevel) {
      file.writeln('sealed class $className {');
    } else {
      file.writeln('final class $className {');
      file.writeln('\tconst $className._();\n');
    }

    final List<MapEntry<String, dynamic>> entries = data.entries.toList();

    for (final MapEntry<String, dynamic> entry in entries) {
      if (entry.value is Map<String, dynamic>) {
        _buildChildAccessor(
          file,
          parentSegments: pathSegments,
          childKey: entry.key,
          isTopLevel: isTopLevel,
        );
      } else {
        _buildValueGetter(file, entry, isStatic: isTopLevel);
      }
    }

    _buildToMap(file, data, isStatic: isTopLevel);

    file.writeln('}\n');

    for (final MapEntry<String, dynamic> entry in entries) {
      if (entry.value is Map<String, dynamic>) {
        _buildClass(
          file,
          pathSegments: <String>[
            ...pathSegments,
            entry.key.toPascalCase(),
          ],
          data: entry.value as Map<String, dynamic>,
          isTopLevel: false,
        );
      }
    }
  }

  void _buildChildAccessor(
    StringBuffer file, {
    required List<String> parentSegments,
    required String childKey,
    required bool isTopLevel,
  }) {
    final String childClassName =
        <String>[...parentSegments, childKey.toPascalCase()].join('');
    final String getterName = caseStyle.format(childKey);
    final String prefix = isTopLevel ? 'static ' : '';

    file.writeln(
      '\t/// The `$childKey` section.\n'
      '\t$prefix$childClassName get $getterName => const $childClassName._();\n',
    );
  }

  void _buildValueGetter(
    StringBuffer file,
    MapEntry<String, dynamic> entry, {
    required bool isStatic,
  }) {
    if (entry.value == null) {
      throw FormatException(
        'Config key "${entry.key}" has a null value. '
        'Remove the key or provide a string/number/boolean value.',
      );
    }

    final String name = caseStyle.format(entry.key);
    final String encoded = strategy.encode(entry.value.toString());
    String body = strategy.buildGetterBody(encoded);

    if (entry.value is! String) {
      body = body.replaceFirst(
        'return ',
        'return ${entry.value.runtimeType}.parse(',
      );
      body += ')';
    }

    final String prefix = isStatic ? 'static ' : '';
    final String text = '\t/// $name: ${entry.value}\n'
        '\t$prefix${entry.value.runtimeType} get $name {\n'
        '$body;\n'
        '\t}\n';

    file.writeln(text);
  }

  void _buildToMap(
    StringBuffer file,
    Map<String, dynamic> data, {
    required bool isStatic,
  }) {
    final String entriesText = data.keys.fold('', (prev, key) {
      final dynamic value = data[key];
      final String encoded = strategy.encode(key);
      final String decode = strategy.buildMapKeyDecode(encoded);
      final String getterName = caseStyle.format(key);

      final String valueRef =
          value is Map<String, dynamic> ? '$getterName.toMap()' : getterName;
      final String comment =
          value is Map<String, dynamic> ? key : '$key: $value';

      return '$prev'
          '\t\t\t// $comment\n'
          '\t\t\t$decode: $valueRef,\n';
    });

    final String docDump = _buildMapDoc(data);
    final String prefix = isStatic ? 'static ' : '';

    file.writeln(
      '\t/// Returns a map representation of this section.\n'
      '\t///\n'
      '$docDump'
      '\t${prefix}Map<String, dynamic> toMap() {\n'
      '\t\treturn <String, dynamic>{\n'
      '$entriesText'
      '\t\t};\n'
      '\t}',
    );
  }

  String _buildMapDoc(Map<String, dynamic> data) {
    final StringBuffer doc = StringBuffer();

    doc.writeln('\t/// {');
    _appendMapDocBody(doc, data, indent: 1);
    doc.writeln('\t/// }');

    return doc.toString();
  }

  void _appendMapDocBody(
    StringBuffer doc,
    Map<String, dynamic> data, {
    required int indent,
  }) {
    final String pad = '  ' * indent;

    for (final entry in data.entries) {
      final dynamic value = entry.value;

      if (value is Map<String, dynamic>) {
        doc.writeln('\t/// $pad${entry.key}: {');
        _appendMapDocBody(doc, value, indent: indent + 1);
        doc.writeln('\t/// $pad},');
      } else {
        doc.writeln('\t/// $pad${entry.key}: $value,');
      }
    }
  }
}
