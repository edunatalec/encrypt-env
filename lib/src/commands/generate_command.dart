import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import '../generator/generator.dart';
import '../generator/case_style.dart';
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
        help: 'Folder where the config file is located',
      )
      ..addOption(
        'config',
        defaultsTo: 'environment',
        help: 'Configuration file name',
      )
      ..addOption(
        'env',
        abbr: 'e',
        help: 'Environment name (e.g. dev, staging, prod)',
      )
      ..addOption(
        'out-dir',
        defaultsTo: 'lib',
        help: 'Output folder for the encrypted file',
      )
      ..addOption(
        'out-file',
        defaultsTo: 'environment',
        help: 'Output encrypted file name',
      )
      ..addOption(
        'style',
        abbr: 's',
        allowed: ['ssc', 'cc', 'sc'],
        allowedHelp: {
          'ssc': 'SCREAMING_SNAKE_CASE',
          'cc': 'camelCase',
          'sc': 'snake_case',
        },
        defaultsTo: 'cc',
        help: 'Getter name case style',
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
        env: argResults?['env'],
        folderName: argResults?['folder'],
        configName: argResults?['config'],
        outFile: argResults?['out-file'],
        outDir: argResults?['out-dir'],
        caseStyle: CaseStyle.values.firstWhere(
          (format) => format.name == argResults?['style'],
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
