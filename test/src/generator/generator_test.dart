import 'dart:io';

import 'package:encrypt_env/src/config/config_reader.dart';
import 'package:encrypt_env/src/generator/case_style.dart';
import 'package:encrypt_env/src/generator/code_builder.dart';
import 'package:encrypt_env/src/generator/generator.dart';
import 'package:encrypt_env/src/generator/test_builder.dart';
import 'package:encrypt_env/src/strategy/xor_strategy.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late Directory outDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('generator_test_');
    outDir = Directory('${tempDir.path}/output');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('run', () {
    test('creates the output Dart file', () async {
      File('${tempDir.path}/environment.yaml').writeAsStringSync(
        'app:\n  base_url: http://localhost\n  port: 3000',
      );

      final generator = Generator(
        configReader: ConfigReader(
          folderName: tempDir.path,
          configName: 'environment',
        ),
        codeBuilder: CodeBuilder(
          caseStyle: CaseStyle.camelCase,
          strategy: XorStrategy(),
        ),
        outDir: outDir.path,
        outFile: 'environment',
      );

      final response = await generator.run();

      expect(File('${outDir.path}/environment.dart').existsSync(), isTrue);
      expect(response.path, '${outDir.path}/environment.dart');
    });

    test('generated file contains expected class', () async {
      File('${tempDir.path}/environment.yaml').writeAsStringSync(
        'app:\n  base_url: http://localhost\n  debug: true',
      );

      final generator = Generator(
        configReader: ConfigReader(
          folderName: tempDir.path,
          configName: 'environment',
        ),
        codeBuilder: CodeBuilder(
          caseStyle: CaseStyle.camelCase,
          strategy: XorStrategy(),
        ),
        outDir: outDir.path,
        outFile: 'environment',
      );

      await generator.run();

      final content =
          File('${outDir.path}/environment.dart').readAsStringSync();
      expect(content, contains('sealed class App'));
      expect(content, contains('static String get baseUrl'));
      expect(content, contains('static bool get debug'));
    });

    test('response environment contains prettified JSON', () async {
      File('${tempDir.path}/environment.yaml').writeAsStringSync(
        'config:\n  name: test\n  value: 42',
      );

      final generator = Generator(
        configReader: ConfigReader(
          folderName: tempDir.path,
          configName: 'environment',
        ),
        codeBuilder: CodeBuilder(
          caseStyle: CaseStyle.camelCase,
          strategy: XorStrategy(),
        ),
        outDir: outDir.path,
        outFile: 'environment',
      );

      final response = await generator.run();

      expect(response.environment, contains('"name": "test"'));
      expect(response.environment, contains('"value": 42'));
    });

    test('writes a test file when testBuilder is provided', () async {
      File('${tempDir.path}/environment.yaml').writeAsStringSync(
        'app:\n  base_url: http://localhost\n  port: 3000',
      );

      // Generator writes the test file at a RELATIVE `test/<outFile>_test.dart`
      // path (into the project CWD); use a unique name to avoid clobbering.
      final outFile = '_gen_test_tmp_${tempDir.uri.pathSegments.last}';
      final testPath = 'test/${outFile}_test.dart';
      final testFile = File(testPath);
      addTearDown(() {
        if (testFile.existsSync()) testFile.deleteSync();
      });

      final strategy = XorStrategy();
      final generator = Generator(
        configReader: ConfigReader(
          folderName: tempDir.path,
          configName: 'environment',
        ),
        codeBuilder: CodeBuilder(
          caseStyle: CaseStyle.camelCase,
          strategy: strategy,
        ),
        testBuilder: TestBuilder(
          caseStyle: CaseStyle.camelCase,
          strategy: strategy,
          importPath: 'package:consumer/environment.dart',
        ),
        outDir: outDir.path,
        outFile: outFile,
      );

      final response = await generator.run();

      expect(response.testPath, testPath);
      expect(testFile.existsSync(), isTrue);

      final testContent = testFile.readAsStringSync();
      expect(testContent, contains("import 'package:test/test.dart';"));
      expect(
        testContent,
        contains("import 'package:consumer/environment.dart';"),
      );
      expect(testContent, contains('void main()'));
      expect(testContent, contains('test('));
      expect(testContent, contains('expect('));
    });

    test('does not run dart format on the generated main file', () async {
      File('${tempDir.path}/environment.yaml').writeAsStringSync(
        'app:\n  base_url: http://localhost\n  port: 3000',
      );

      final generator = Generator(
        configReader: ConfigReader(
          folderName: tempDir.path,
          configName: 'environment',
        ),
        codeBuilder: CodeBuilder(
          caseStyle: CaseStyle.camelCase,
          strategy: XorStrategy(),
        ),
        outDir: outDir.path,
        outFile: 'environment',
      );

      await generator.run();

      // CodeBuilder emits tab-indented source; `dart format` would replace
      // tabs with spaces, so the presence of tabs proves no formatting ran.
      final written =
          File('${outDir.path}/environment.dart').readAsStringSync();
      expect(written, contains('\t'));
    });

    test('does not write a test file when testBuilder is null', () async {
      File('${tempDir.path}/environment.yaml').writeAsStringSync(
        'app:\n  base_url: http://localhost',
      );

      final generator = Generator(
        configReader: ConfigReader(
          folderName: tempDir.path,
          configName: 'environment',
        ),
        codeBuilder: CodeBuilder(
          caseStyle: CaseStyle.camelCase,
          strategy: XorStrategy(),
        ),
        outDir: outDir.path,
        outFile: 'environment',
      );

      final response = await generator.run();

      expect(response.testPath, isNull);
    });

    test('works with env merging', () async {
      File('${tempDir.path}/environment.yaml').writeAsStringSync(
        'app:\n  url: http://localhost\n  port: 3000',
      );
      File('${tempDir.path}/prod_environment.yaml').writeAsStringSync(
        'app:\n  url: https://api.production.com',
      );

      final generator = Generator(
        configReader: ConfigReader(
          folderName: tempDir.path,
          configName: 'environment',
          env: 'prod',
        ),
        codeBuilder: CodeBuilder(
          caseStyle: CaseStyle.camelCase,
          strategy: XorStrategy(),
        ),
        outDir: outDir.path,
        outFile: 'environment',
      );

      final response = await generator.run();

      expect(response.environment, contains('https://api.production.com'));
      expect(response.environment, contains('3000'));
    });
  });
}
