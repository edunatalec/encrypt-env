import '../strategy/obfuscation_strategy.dart';
import '../utils/string_utils.dart';
import 'case_style.dart';

/// Builds a test file for the generated Dart source.
class TestBuilder {
  /// The case style for getter names.
  final CaseStyle caseStyle;

  /// The obfuscation strategy used to determine test setup.
  final ObfuscationStrategy strategy;

  /// The import path to the generated file.
  final String importPath;

  /// Whether to use `flutter_test` instead of `test`.
  final bool flutter;

  /// Creates a new [TestBuilder] instance.
  const TestBuilder({
    required this.caseStyle,
    required this.strategy,
    required this.importPath,
    this.flutter = false,
  });

  /// Builds the complete test source from [data].
  String build(Map<String, dynamic> data) {
    final file = StringBuffer();

    _buildHeader(file);
    _buildBody(file, data);

    return file.toString();
  }

  void _buildHeader(StringBuffer file) {
    final testPackage = flutter ? 'flutter_test' : 'test';

    file.writeln("import 'package:$testPackage/$testPackage.dart';");
    file.writeln("import '$importPath';");
    file.writeln();
  }

  void _buildBody(StringBuffer file, Map<String, dynamic> data) {
    file.writeln('void main() {');

    if (strategy.testSetup.isNotEmpty) {
      file.writeln(strategy.testSetup);
    }

    for (final entry in data.entries) {
      _buildClassTests(file, entry.key, entry.value as Map<String, dynamic>);
    }

    file.writeln('}');
  }

  void _buildClassTests(
    StringBuffer file,
    String key,
    Map<String, dynamic> map,
  ) {
    final className = key.toPascalCase();

    file.writeln("  group('$className', () {");

    for (final entry in map.entries) {
      if (entry.value is Map<String, dynamic>) {
        _buildMapTest(file, className, entry.key);
      } else {
        _buildValueTest(file, className, entry.key, entry.value);
      }
    }

    file.writeln('  });\n');
  }

  void _buildValueTest(
    StringBuffer file,
    String className,
    String key,
    dynamic value,
  ) {
    final getterName = _formatGetter(key);
    final type = value.runtimeType;

    String expected;
    if (value is String) {
      expected = "'${value.replaceAll("'", "\\'")}'";
    } else {
      expected = '$value';
    }

    file.writeln("    test('$getterName returns correct value', () {");
    file.writeln('      expect($className.$getterName, $expected);');
    file.writeln('    });\n');

    if (value is! String) {
      file.writeln("    test('$getterName returns $type', () {");
      file.writeln('      expect($className.$getterName, isA<$type>());');
      file.writeln('    });\n');
    }
  }

  void _buildMapTest(
    StringBuffer file,
    String className,
    String key,
  ) {
    final getterName = _formatGetter(key);

    file.writeln("    test('$getterName returns Map', () {");
    file.writeln(
      '      expect($className.$getterName, isA<Map<String, dynamic>>());',
    );
    file.writeln('    });\n');
  }

  String _formatGetter(String text) {
    text = text.replaceAll(' ', '_');

    switch (caseStyle) {
      case CaseStyle.snakeCase:
        text = text.toSnakeCase().toLowerCase();
      case CaseStyle.camelCase:
        text = text.toCamelCase();
      case CaseStyle.screamingSnakeCase:
        text = text.toSnakeCase().toUpperCase();
    }

    return text;
  }
}
