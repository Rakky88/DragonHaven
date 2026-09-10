import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/game_domain_probe.dart' show runGameDomainProbe;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('native game produces the portable synthetic fixture', () async {
    final result = await runGameDomainProbe(includeTrialCommands: true);
    expect(result['purchase'], 'purchased');
    expect(result['state']['chestInventory']['sinister'], 0);
    const output = String.fromEnvironment('DOMAIN_PARITY_OUTPUT');
    if (output.isNotEmpty) {
      await File(output).writeAsString(jsonEncode(result));
    }
  });
}
