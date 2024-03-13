import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import '../generator/generator.dart';
import '../generator/generator.response.dart';

class GenerateCommand extends Command<int> {
  final Logger _logger;

  GenerateCommand({
    required Logger logger,
  }) : _logger = logger {
    argParser
      ..addOption(
        'env',
        help: 'The environment target',
      )
      ..addOption(
        'file-path',
        help: 'The generated file path',
      )
      ..addOption(
        'file-name',
        help: 'The generated file name',
      )
      ..addOption(
        'yaml-file-name',
        help: 'The yaml file name',
      )
      ..addOption(
        'uppercase',
        help: 'The getters name form. '
            'Default value true, if false the name will be in camelCase',
      );
  }

  @override
  String get name => 'gen';

  @override
  String get description => 'Generates an encrypt file based on a yaml file';

  @override
  Future<int> run() async {
    try {
      bool uppercase = argResults?['uppercase'] == null
          ? true
          : argResults?['uppercase'] == 'true';

      final GeneratorResponse reponse = await Generator(
        env: argResults?['env'],
        fileName: argResults?['file-name'] ?? 'environment',
        filePath: argResults?['file-path'] ?? '../lib',
        yamlFileName: argResults?['yaml-file-name'] ?? 'environment',
        uppercase: uppercase,
      ).run();

      _logger.success('Encrypted\n');
      _logger.info(reponse.environment);
      _logger.success('\n✓ Path ${reponse.path}');

      return ExitCode.success.code;
    } catch (error) {
      _logger.err(error.toString());

      return ExitCode.ioError.code;
    }
  }
}
