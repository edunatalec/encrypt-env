import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import '../generator/generator.dart';
import '../generator/generator_format.dart';
import '../generator/generator_response.dart';

/// A command that generates an encrypted file based on a YAML configuration.
///
/// This command allows users to define an environment, file path,
/// naming conventions, and output formats for the encrypted file.
class GenerateCommand extends Command<int> {
  /// Logger instance for logging messages.
  final Logger _logger;

  /// Creates a new [GenerateCommand] instance.
  ///
  /// Accepts a required [logger] for displaying logs and execution results.
  GenerateCommand({
    required Logger logger,
  }) : _logger = logger {
    argParser
      ..addOption(
        'folder',
        defaultsTo: 'environment',
        help: 'Folder name',
      )
      ..addOption(
        'yaml',
        abbr: 'y',
        defaultsTo: 'environment',
        help: 'YAML file name',
      )
      ..addOption(
        'environment',
        abbr: 'e',
        help: 'Environment name',
      )
      ..addOption(
        'file-path',
        defaultsTo: 'lib',
        help: 'Encrypted file path',
      )
      ..addOption(
        'file',
        defaultsTo: 'environment',
        help: 'Encrypted file name',
      )
      ..addOption(
        'format',
        allowed: ['ssc', 'cc', 'sc'],
        allowedHelp: {
          'ssc': 'SCREAMING_SNAKE_CASE',
          'cc': 'camelCase',
          'sc': 'snake_case',
        },
        defaultsTo: 'ssc',
        help: 'Getter name format',
      );
  }

  @override
  String get name => 'gen';

  @override
  String get description => 'Generates an encrypt file based on a YAML file';

  @override
  Future<int> run() async {
    try {
      final GeneratorResponse reponse = await Generator(
        env: argResults?['environment'],
        folderName: argResults?['folder'],
        yamlName: argResults?['yaml'],
        fileName: argResults?['file'],
        filePath: argResults?['file-path'],
        format: GeneratorFormat.values.firstWhere(
          (format) => format.name == argResults?['format'],
        ),
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
