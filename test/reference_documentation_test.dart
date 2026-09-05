import 'dart:io';

import 'package:dragon_haven/models/adventure.dart';
import 'package:dragon_haven/models/chest.dart';
import 'package:dragon_haven/models/dragon_emote.dart';
import 'package:dragon_haven/models/redeem_code.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/reference_documentation_guard.dart';

void main() {
  test('reference fingerprints are identical for LF and CRLF checkouts', () {
    final root = Directory.systemTemp.createTempSync('dragonhaven-reference-');
    addTearDown(() => root.deleteSync(recursive: true));
    final source = File('${root.path}${Platform.pathSeparator}lib'
        '${Platform.pathSeparator}sample.dart')
      ..parent.createSync(recursive: true);
    const spec = ReferenceDocumentSpec(
      documentPath: 'REFERENCE.md',
      sourcePaths: ['lib/sample.dart'],
    );

    source.writeAsStringSync('first line\nsecond line\n');
    final lfFingerprint = calculateReferenceFingerprint(spec, root: root);
    source.writeAsStringSync('first line\r\nsecond line\r\n');

    expect(calculateReferenceFingerprint(spec, root: root), lfFingerprint);
  });

  test('living reference documents match their implementation sources', () {
    expect(
      verifyReferenceDocuments(),
      isEmpty,
      reason: 'Review and update the affected Markdown reference before '
          'accepting a new source fingerprint.',
    );
  });

  test('special content catalog names every implemented event and chest', () {
    final contents =
        File(specialContentReference.documentPath).readAsStringSync();

    for (final event in specialAdventureEventCatalog) {
      expect(contents, contains('`${event.id}`'));
      expect(contents, contains('`${event.adventureId}`'));
    }
    for (final tier in ChestTier.values) {
      expect(contents, contains('`${tier.name}`'));
    }
    for (final eggName in const [
      'Starter Egg',
      'Mysterious Egg',
      'Sinister Egg',
      'Special Egg',
    ]) {
      expect(contents, contains(eggName));
    }
  });

  test('redeem-code reference lists every active code and exact reward', () {
    final contents = File(redeemCodesReference.documentPath).readAsStringSync();
    expect(redeemCodeCatalog, isNotEmpty);
    expect(
      redeemCodeCatalog.map((definition) => definition.code).toSet(),
      hasLength(redeemCodeCatalog.length),
    );
    final documentedRewardsByCode = <String, String>{
      for (final match in RegExp(
        r'^\| `([A-Z0-9]+)` \| \*\*[^*]+\*\* \| `([^`]+)` \|',
        multiLine: true,
      ).allMatches(contents))
        match.group(1)!: match.group(2)!,
    };
    expect(
      documentedRewardsByCode,
      {
        for (final definition in redeemCodeCatalog)
          definition.code: definition.rewardId,
      },
      reason: 'The Active codes table must contain exactly the live catalog.',
    );

    for (final definition in redeemCodeCatalog) {
      expect(contents, contains('`${definition.code}`'));
      expect(contents, contains('`${definition.rewardId}`'));
      switch (definition.rewardType) {
        case RedeemRewardType.dragonEmotePack:
          final pack = dragonEmotePackById(definition.rewardId);
          expect(pack, isNotNull, reason: definition.code);
          expect(contents, contains(pack!.nameEn));
          expect(pack.emotes, hasLength(10), reason: definition.code);
          for (final emote in pack.emotes) {
            expect(contents, contains(emote.nameEn), reason: definition.code);
          }
      }
    }
  });

  test('public release notes never expose redeem codes', () {
    final releaseNotes = Directory.current.listSync().whereType<File>().where(
        (file) => RegExp(r'release-notes-.*\.md$', caseSensitive: false)
            .hasMatch(file.path));

    for (final notesFile in releaseNotes) {
      final contents = notesFile.readAsStringSync();
      expect(
        contents,
        isNot(matches(
            RegExp(r'redeem(?:able|ption)?[ -]?codes?', caseSensitive: false))),
        reason: '${notesFile.path} must not announce redeem codes.',
      );
      for (final definition in redeemCodeCatalog) {
        expect(
          contents,
          isNot(contains(definition.code)),
          reason: '${notesFile.path} exposes ${definition.code}.',
        );
      }
    }
  });
}
