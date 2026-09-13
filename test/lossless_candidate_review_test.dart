import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

// Opt-in review of generated candidates before any runtime asset is replaced.
// Run with --dart-define=REVIEW_LOSSLESS_CANDIDATES=true.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Flutter decodes lossless candidates exactly like their sources',
      () async {
    const proofFolder =
        String.fromEnvironment('LOSSLESS_PROOF_FOLDER', defaultValue: 'proofs');
    const applied = bool.fromEnvironment('REVIEW_APPLIED_LOSSLESS_ASSETS');
    final rows = applied
        ? ((jsonDecode(File('tool/asset_manifests/lossless_v35.json')
                    .readAsStringSync()) as Map<String, dynamic>)['imageRows']
                as List)
            .cast<Map<String, dynamic>>()
            .where((row) => row['retired'] != true)
        : Directory('.tools/lossless35/$proofFolder')
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.json'))
            .map((file) =>
                jsonDecode(file.readAsStringSync()) as Map<String, dynamic>);
    var checked = 0;
    final rejected = <String>[];
    final accepted = <String>[];
    for (final row in rows) {
      if (row['accepted'] != true) continue;
      final original = await ui.instantiateImageCodec(
        File(row[applied ? 'archive' : 'source'] as String).readAsBytesSync(),
      );
      final candidate = await ui.instantiateImageCodec(
        File(row[applied ? 'runtime' : 'candidate'] as String)
            .readAsBytesSync(),
      );
      final a = (await original.getNextFrame()).image;
      final b = (await candidate.getNextFrame()).image;
      final aBytes = (await a.toByteData(format: ui.ImageByteFormat.rawRgba))!;
      final bBytes = (await b.toByteData(format: ui.ImageByteFormat.rawRgba))!;
      var same = a.width == b.width &&
          a.height == b.height &&
          aBytes.lengthInBytes == bBytes.lengthInBytes;
      if (same) {
        final left = aBytes.buffer.asUint8List();
        final right = bBytes.buffer.asUint8List();
        for (var i = 0; i < left.length; i++) {
          if (left[i] != right[i]) {
            same = false;
            break;
          }
        }
      }
      if (!same) rejected.add(row['source'] as String);
      if (same) accepted.add(row['source'] as String);
      a.dispose();
      b.dispose();
      original.dispose();
      candidate.dispose();
      checked++;
    }
    File('.tools/lossless35/flutter-decoder-${applied ? 'applied' : proofFolder}.json')
        .writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'checked': checked,
        'rejected': rejected,
        'accepted': accepted,
      }),
    );
    expect(checked, greaterThan(0));
    if (applied) expect(rejected, isEmpty);
    // Differences are recorded as rejected candidates, never installed assets.
    // The applied manifest has a separate zero-difference regression check.
  },
      skip: !const bool.fromEnvironment('REVIEW_LOSSLESS_CANDIDATES') &&
          !const bool.fromEnvironment('REVIEW_APPLIED_LOSSLESS_ASSETS'),
      timeout: const Timeout(Duration(minutes: 20)));
}
