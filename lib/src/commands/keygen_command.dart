import 'package:args/command_runner.dart';
import 'package:fortis/fortis.dart';
import 'package:mason_logger/mason_logger.dart';

/// A command that generates a random AES-256 key in base64 format.
class KeygenCommand extends Command<int> {
  final Logger _logger;

  /// Creates a new [KeygenCommand] instance.
  KeygenCommand({
    required Logger logger,
  }) : _logger = logger;

  @override
  String get name => 'keygen';

  @override
  String get description => 'Generates a random AES-256 key in base64 format';

  @override
  Future<int> run() async {
    try {
      final key = await Fortis.aes().keySize(256).generateKey();

      _logger.success('AES-256 key generated:\n');
      _logger.info(key.toBase64());

      return ExitCode.success.code;
    } catch (error) {
      _logger.err(error.toString());

      return ExitCode.ioError.code;
    }
  }
}
