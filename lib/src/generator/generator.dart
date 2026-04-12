import 'dart:io';

import '../config/config_reader.dart';
import '../utils/map_utils.dart';
import 'code_builder.dart';
import 'generator_response.dart';

/// Orchestrates the generation of an obfuscated Dart file
/// from YAML configuration.
class Generator {
  /// The configuration reader for loading YAML files.
  final ConfigReader configReader;

  /// The code builder that generates the Dart source.
  final CodeBuilder codeBuilder;

  /// The output directory for the generated file.
  final String outDir;

  /// The output file name (without extension).
  final String outFile;

  /// Creates a new [Generator] instance.
  const Generator({
    required this.configReader,
    required this.codeBuilder,
    required this.outDir,
    required this.outFile,
  });

  /// Reads configuration, builds the Dart source, and writes the output file.
  Future<GeneratorResponse> run() async {
    final data = await configReader.read();
    final source = codeBuilder.build(data);

    await _writeFile(source);

    return GeneratorResponse(
      environment: data.prettify(),
      path: '$outDir/$outFile.dart',
    );
  }

  Future<void> _writeFile(String content) async {
    await Directory(outDir).create(recursive: true);

    final file = File('$outDir/$outFile.dart');
    await file.create();
    await file.writeAsString(content);
  }
}
