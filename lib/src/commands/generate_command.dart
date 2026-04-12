import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import '../config/config_reader.dart';
import '../generator/case_style.dart';
import '../generator/code_builder.dart';
import '../generator/generator.dart';
import '../strategy/aes_strategy.dart';
import '../strategy/obfuscation_strategy.dart';
import '../strategy/xor_strategy.dart';

/// A command that generates an obfuscated or encrypted Dart file
/// based on a YAML configuration.
class GenerateCommand extends Command<int> {
  final Logger _logger;

  /// Creates a new [GenerateCommand] instance.
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
      )
      ..addFlag(
        'encrypt',
        help: 'Use AES-256-GCM encryption instead of XOR obfuscation',
      )
      ..addOption(
        'key',
        abbr: 'k',
        help: 'Base64 AES-256 key (required with --encrypt)',
      );
  }

  @override
  String get name => 'gen';

  @override
  String get description => 'Generates an encrypt file based on a YAML file';

  @override
  Future<int> run() async {
    try {
      final strategy = _buildStrategy();

      final configReader = ConfigReader(
        folderName: argResults?['folder'],
        configName: argResults?['config'],
        env: argResults?['env'],
      );

      final codeBuilder = CodeBuilder(
        caseStyle: CaseStyle.values.firstWhere(
          (format) => format.name == argResults?['style'],
        ),
        strategy: strategy,
      );

      final response = await Generator(
        configReader: configReader,
        codeBuilder: codeBuilder,
        outDir: argResults?['out-dir'],
        outFile: argResults?['out-file'],
      ).run();

      _logger.success('Encrypted\n');
      _logger.info(response.environment);
      _logger.success('\n\u2713 Path ${response.path}');

      return ExitCode.success.code;
    } catch (error) {
      _logger.err(error.toString());

      return ExitCode.ioError.code;
    }
  }

  ObfuscationStrategy _buildStrategy() {
    final useEncrypt = argResults?['encrypt'] == true;

    if (!useEncrypt) return XorStrategy();

    final key = argResults?['key'] as String?;

    if (key == null || key.isEmpty) {
      throw 'The --key option is required when using --encrypt.';
    }

    return AesStrategy(key: key);
  }
}
