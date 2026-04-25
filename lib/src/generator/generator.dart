import 'dart:io';

import '../config/config_reader.dart';
import '../utils/map_utils.dart';
import 'code_builder.dart';
import 'generator_response.dart';
import 'test_builder.dart';

/// Orchestrates the generation of an obfuscated Dart file
/// from YAML configuration.
class Generator {
  /// The configuration reader for loading YAML files.
  final ConfigReader configReader;

  /// The code builder that generates the Dart source.
  final CodeBuilder codeBuilder;

  /// The test builder that generates the test file.
  final TestBuilder? testBuilder;

  /// The output directory for the generated file.
  final String outDir;

  /// The output file name (without extension).
  final String outFile;

  /// Creates a new [Generator] instance.
  const Generator({
    required this.configReader,
    required this.codeBuilder,
    this.testBuilder,
    required this.outDir,
    required this.outFile,
  });

  /// Reads configuration, builds the Dart source, and writes the output file.
  Future<GeneratorResponse> run() async {
    final data = await configReader.read();
    final source = codeBuilder.build(data);

    final mainPath = '$outDir/$outFile.dart';

    await _writeFile(mainPath, source);

    String? testPath;

    if (testBuilder != null) {
      final testSource = testBuilder!.build(data);

      testPath = 'test/${outFile}_test.dart';

      await _writeFile(testPath, testSource);
      await _formatFile(testPath);
    }

    return GeneratorResponse(
      environment: data.prettify(),
      path: '$outDir/$outFile.dart',
      testPath: testPath,
    );
  }

  Future<void> _writeFile(String path, String content) async {
    final file = File(path);

    await file.parent.create(recursive: true);
    await file.create();
    await file.writeAsString(content);
  }

  Future<void> _formatFile(String path) async {
    await Process.run('dart', ['format', path]);
  }
}
