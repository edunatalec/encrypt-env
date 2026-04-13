import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:fortis/fortis.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:yaml/yaml.dart';

import '../config/config_reader.dart';
import '../generator/case_style.dart';
import '../generator/code_builder.dart';
import '../generator/generator.dart';
import '../generator/test_builder.dart';
import '../strategy/aes_strategy.dart';
import '../strategy/obfuscation_strategy.dart';
import '../strategy/xor_strategy.dart';

const _modeXor = 'XOR obfuscation (no dependencies)';
const _modeAes = 'AES-256 encryption (requires fortis)';

const _styleOptions = {
  'camelCase': 'cc',
  'snake_case': 'sc',
  'SCREAMING_SNAKE_CASE': 'ssc',
};

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
      )
      ..addFlag(
        'test',
        defaultsTo: true,
        help: 'Generate a test file alongside the Dart file',
      );
  }

  @override
  String get name => 'gen';

  @override
  String get description => 'Generates an encrypt file based on a YAML file';

  bool get _isInteractive => argResults?.arguments.isEmpty == true;

  @override
  Future<int> run() async {
    try {
      final useEncrypt = _resolveEncrypt();
      final strategy = await _buildStrategy(useEncrypt);
      final style = _resolveStyle();
      final outFile = _resolveOption('out-file', 'Output file name:');
      final generateTest = argResults?['test'] == true;

      final caseStyle = CaseStyle.values.firstWhere(
        (format) => format.code == style,
      );

      final configReader = ConfigReader(
        folderName: _resolveOption('folder', 'Config folder:'),
        configName: _resolveOption('config', 'Config file name:'),
        env: _resolveOptional(
          'env',
          'Environment name (leave empty to skip):',
        ),
      );

      final codeBuilder = CodeBuilder(
        caseStyle: caseStyle,
        strategy: strategy,
      );

      final outDir = _resolveOption('out-dir', 'Output directory:');

      TestBuilder? testBuilder;

      if (generateTest) {
        final pubspec = _readPubspec();

        String importPath;

        if (pubspec.packageName != null) {
          final subPath = outDir.startsWith('lib/')
              ? outDir.substring(4)
              : outDir.startsWith('lib')
                  ? outDir.substring(3)
                  : outDir;
          final prefix = subPath.isEmpty ? '' : '$subPath/';
          importPath = 'package:${pubspec.packageName}/$prefix$outFile.dart';
        } else {
          importPath = '../$outDir/$outFile.dart';
        }

        testBuilder = TestBuilder(
          caseStyle: caseStyle,
          strategy: strategy,
          importPath: importPath,
          flutter: pubspec.isFlutter,
        );
      }

      final response = await Generator(
        configReader: configReader,
        codeBuilder: codeBuilder,
        testBuilder: testBuilder,
        outDir: outDir,
        outFile: outFile,
      ).run();

      _logger.success('Encrypted\n');
      _logger.info(response.environment);
      _logger.success('\n\u2713 Path ${response.path}');

      if (response.testPath != null) {
        _logger.success('\u2713 Test ${response.testPath}');
      }

      return ExitCode.success.code;
    } catch (error) {
      _logger.err(error.toString());

      return ExitCode.ioError.code;
    }
  }

  bool _resolveEncrypt() {
    if (!_isInteractive) return argResults?['encrypt'] == true;

    final mode = _logger.chooseOne(
      'Choose a mode:',
      choices: [_modeXor, _modeAes],
      defaultValue: _modeXor,
    );

    return mode == _modeAes;
  }

  String _resolveStyle() {
    if (!_isInteractive) return argResults!['style'] as String;

    final choice = _logger.chooseOne(
      'Choose a case style:',
      choices: _styleOptions.keys.toList(),
      defaultValue: 'camelCase',
    );

    return _styleOptions[choice]!;
  }

  String _resolveOption(String name, String prompt) {
    if (!_isInteractive) return argResults![name] as String;

    return _logger.prompt(
      prompt,
      defaultValue: argResults?.option(name),
    );
  }

  String? _resolveOptional(String name, String prompt) {
    if (!_isInteractive) return argResults?[name] as String?;

    final value = _logger.prompt(prompt);

    return value.isEmpty ? null : value;
  }

  ({String? packageName, bool isFlutter}) _readPubspec() {
    final file = File('pubspec.yaml');

    if (!file.existsSync()) return (packageName: null, isFlutter: false);

    try {
      final yaml = loadYaml(file.readAsStringSync()) as YamlMap;
      final name = yaml['name'] as String?;
      final deps = yaml['dependencies'];
      final isFlutter = deps is YamlMap && deps.containsKey('flutter');

      return (packageName: name, isFlutter: isFlutter);
    } catch (_) {
      return (packageName: null, isFlutter: false);
    }
  }

  Future<ObfuscationStrategy> _buildStrategy(bool useEncrypt) async {
    if (!useEncrypt) return XorStrategy();

    String? key;

    if (!_isInteractive) {
      key = argResults?['key'] as String?;
    } else {
      final input = _logger.prompt(
        'Enter your AES-256 base64 key (leave empty to generate):',
      );

      if (input.isNotEmpty) key = input;
    }

    if (key == null || key.isEmpty) {
      final generated = await Fortis.aes().keySize(256).generateKey();
      key = generated.toBase64();

      _logger.info('');
      _logger.success('Generated a new AES-256 key:\n');
      _logger.info(key);
      _logger.info('');
      _logger.warn('Save this key securely. You will need it at runtime.\n');
    }

    return AesStrategy(key: key);
  }
}
