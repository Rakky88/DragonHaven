import 'dart:convert';
import 'dart:io';

/// Proves the real shared rules produce the same result in the Flutter VM and
/// compiled JavaScript under Deno. No Firebase, Supabase or player state is used.
Future<void> main(List<String> args) async {
  if (args.length != 1) {
    stderr.writeln(
        'Usage: dart run tool/game_domain_parity.dart <deno executable>');
    exitCode = 64;
    return;
  }
  final directory =
      await Directory.systemTemp.createTemp('dragonhaven-domain-');
  try {
    final bundle = File('${directory.path}/probe.js');
    final compilation = await Process.run(Platform.resolvedExecutable, [
      'compile',
      'js',
      '-O2',
      '--no-source-maps',
      '-o',
      bundle.path,
      'tool/game_domain_probe_web.dart',
    ]);
    if (compilation.exitCode != 0) {
      throw StateError('Domain compilation failed: ${compilation.stderr}');
    }
    final runner = File('${directory.path}/run.ts');
    await runner.writeAsString('''
import './probe.js';
const started = performance.now();
const output = await globalThis.dragonhavenProbe();
console.log(JSON.stringify({durationMs: performance.now() - started, output: JSON.parse(output)}));
''');
    final execution = await Process.run(args.single, ['run', runner.path]);
    if (execution.exitCode != 0) {
      throw StateError('Deno domain evaluation failed: ${execution.stderr}');
    }
    final deno = jsonDecode(execution.stdout as String) as Map<String, dynamic>;
    final nativeFile = File('${directory.path}/native.json');
    final flutterTools = File(
        '${File(Platform.resolvedExecutable).parent.parent.parent.path}/flutter_tools.snapshot');
    final nativeExecution = await Process.run(Platform.resolvedExecutable, [
      flutterTools.path,
      'test',
      '--no-pub',
      '--dart-define=DOMAIN_PARITY_OUTPUT=${nativeFile.path}',
      'test/game_domain_parity_fixture_test.dart',
    ]);
    if (nativeExecution.exitCode != 0) {
      throw StateError(
          'Native fixture failed: ${nativeExecution.stdout} ${nativeExecution.stderr}');
    }
    final native = jsonDecode(await nativeFile.readAsString());
    final difference = _difference(native, deno['output'], 'result');
    if (difference != null) {
      throw StateError('Domain parity failed at $difference');
    }
    stdout.writeln(jsonEncode({
      'parity': 'passed',
      'bundleBytes': await bundle.length(),
      'denoDurationMs': deno['durationMs'],
    }));
  } finally {
    await directory.delete(recursive: true);
  }
}

String? _difference(Object? expected, Object? actual, String path) {
  if (expected is Map && actual is Map) {
    if (expected.length != actual.length) return '$path.keys';
    for (final key in expected.keys) {
      if (!actual.containsKey(key)) return '$path.$key';
      final difference = _difference(expected[key], actual[key], '$path.$key');
      if (difference != null) return difference;
    }
    return null;
  }
  if (expected is List && actual is List) {
    if (expected.length != actual.length) return '$path.length';
    for (var index = 0; index < expected.length; index++) {
      final difference =
          _difference(expected[index], actual[index], '$path[$index]');
      if (difference != null) return difference;
    }
    return null;
  }
  return expected == actual ? null : path;
}
