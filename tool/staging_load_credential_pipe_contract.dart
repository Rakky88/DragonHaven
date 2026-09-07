import 'dart:convert';
import 'dart:io';

import 'staging_load_profile.dart';

Future<void> main(List<String> args) async {
  if (args.contains('--child')) {
    final pool = parseCredentialPool(await readCredentialInput(stdin), 1000);
    stdout.writeln(pool.length);
    return;
  }
  final payload = jsonEncode({
    'accounts': List.generate(
        1000,
        (i) => {
              'email': 'load-${'a' * 32}-$i@dragonhaven-load.invalid',
              'password': '${'synthetic-only-' * 4}Aa7!',
            })
  });
  if (utf8.encode(payload).length <= 131072) {
    throw StateError('Fixture must exceed the Linux environment-string limit.');
  }
  final process = await Process.start(
      Platform.resolvedExecutable, [Platform.script.toFilePath(), '--child'],
      environment: {'STAGING_LOAD_CREDENTIALS_JSON': ''});
  final output = process.stdout.transform(utf8.decoder).join();
  final errors = process.stderr.transform(utf8.decoder).join();
  process.stdin.add(utf8.encode(payload));
  await process.stdin.close();
  if (await process.exitCode.timeout(const Duration(seconds: 30)) != 0 ||
      (await output).trim() != '1000' ||
      (await errors).isNotEmpty) {
    throw StateError('The private credential pipe contract failed.');
  }
  var refused = false;
  try {
    await readCredentialInput(Stream.value(List.filled(1024 * 1024 + 1, 65)));
  } on FormatException {
    refused = true;
  }
  if (!refused) throw StateError('Oversized credential input was accepted.');
  stdout.writeln(
      'PASS: 1000 synthetic credentials cross a private pipe; oversized input rejected; no network or credentials logged.');
}
