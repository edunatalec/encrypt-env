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
    final StringBuffer file = StringBuffer();

    _buildHeader(file);
    _buildBody(file, data);

    return file.toString();
  }

  void _buildHeader(StringBuffer file) {
    final String testPackage = flutter ? 'flutter_test' : 'test';

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
    final String className = key.toPascalCase();

    file.writeln("  group('$className', () {");
    _buildEntriesTests(file, accessPath: className, data: map);
    file.writeln('  });\n');
  }

  void _buildEntriesTests(
    StringBuffer file, {
    required String accessPath,
    required Map<String, dynamic> data,
  }) {
    for (final entry in data.entries) {
      final String getterName = caseStyle.format(entry.key);

      if (entry.value is Map<String, dynamic>) {
        file.writeln("    group('$getterName', () {");
        _buildEntriesTests(
          file,
          accessPath: '$accessPath.$getterName',
          data: entry.value as Map<String, dynamic>,
        );
        file.writeln('    });\n');
      } else {
        _buildValueTest(file, accessPath, getterName, entry.value);
      }
    }

    _buildToMapTest(file, accessPath);
  }

  void _buildValueTest(
    StringBuffer file,
    String accessPath,
    String getterName,
    dynamic value,
  ) {
    final Type type = value.runtimeType;

    String expected;
    if (value is String) {
      expected = "'${_escapeDartString(value)}'";
    } else {
      expected = '$value';
    }

    file.writeln("    test('$getterName returns correct value', () {");
    file.writeln('      expect($accessPath.$getterName, $expected);');
    file.writeln('    });\n');

    if (value is! String) {
      file.writeln("    test('$getterName returns $type', () {");
      file.writeln('      expect($accessPath.$getterName, isA<$type>());');
      file.writeln('    });\n');
    }
  }

  void _buildToMapTest(StringBuffer file, String accessPath) {
    file.writeln("    test('toMap returns Map<String, dynamic>', () {");
    file.writeln(
      '      expect($accessPath.toMap(), isA<Map<String, dynamic>>());',
    );
    file.writeln('    });\n');
  }

  String _escapeDartString(String value) {
    return value
        .replaceAll(r'\', r'\\')
        .replaceAll(r'$', r'\$')
        .replaceAll("'", r"\'")
        .replaceAll('\r', r'\r')
        .replaceAll('\n', r'\n')
        .replaceAll('\t', r'\t');
  }
}
