import 'dart:io';

import 'package:dragon_haven/models/dragon_lineage.dart';
import 'package:dragon_haven/widgets/dragon_art.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

const _selectedForms = <String, List<String>>{
  'cluckatrice': ['wyrmling', 'might', 'arcana', 'spirit'],
  'sinisterra': ['wyrmling', 'might', 'arcana', 'spirit'],
  'auroracrown': ['wyrmling', 'might', 'arcana', 'spirit'],
  'bramblequill': ['wyrmling', 'might', 'arcana', 'spirit'],
  'cinderlynx': ['wyrmling', 'might', 'arcana', 'spirit'],
  'clockskip': ['might', 'spirit'],
  'coraloracle': ['wyrmling', 'might'],
  'crystalwhisk': ['might'],
  'dreammoth': ['arcana'],
  'dustglimmer': ['arcana', 'spirit'],
  'echofern': ['wyrmling', 'might', 'arcana'],
  'eclipseantler': ['wyrmling', 'might'],
  'everwyrm': ['wyrmling', 'might', 'spirit'],
  'frostfable': ['wyrmling', 'might', 'arcana'],
  'harmonytail': ['spirit'],
  'ironwhistle': ['wyrmling', 'might', 'arcana'],
  'leviathanecho': ['wyrmling', 'might', 'spirit'],
  'meteorhide': ['wyrmling', 'might'],
  'mistmantle': ['wyrmling', 'might', 'arcana', 'spirit'],
  'opalchimera': ['wyrmling', 'might', 'spirit'],
  'petaldrift': ['wyrmling', 'might', 'arcana', 'spirit'],
  'quietstar': ['might', 'spirit'],
  'rainbowruff': ['spirit'],
  'runehopper': ['might', 'arcana', 'spirit'],
  'starforged': ['wyrmling', 'might', 'arcana'],
  'sunmuzzle': ['wyrmling', 'might', 'arcana', 'spirit'],
  'temporalark': ['might'],
  'tidescale': ['might', 'spirit'],
  'twinflare': ['spirit'],
  'velvetvolt': ['wyrmling', 'might', 'arcana', 'spirit'],
  'voidbloom': ['wyrmling', 'might', 'arcana', 'spirit'],
  'worldroot': ['wyrmling', 'might'],
};

({String stageKey, String path}) _renderingFor(String form) => switch (form) {
      'hatchling' => (stageKey: 'spark', path: 'might'),
      'wyrmling' => (stageKey: 'nestDragon', path: 'might'),
      _ => (stageKey: 'homeGuardian', path: form),
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'all 86 selected source forms retain a safety margin in five complete passes',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(180, 180));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (var pass = 1; pass <= 5; pass++) {
      for (final selection in _selectedForms.entries) {
        expect(
          dragonLineages.any((lineage) => lineage.id == selection.key),
          isTrue,
          reason: 'pass $pass: unknown lineage ${selection.key}',
        );
        for (final form in selection.value) {
          final rendering = _renderingFor(form);
          for (final spectral in [false, true]) {
            for (final silhouette in [true, false]) {
              await tester.pumpWidget(MaterialApp(
                home: Center(
                  child: DragonArt(
                    height: 96,
                    animate: false,
                    lineageId: selection.key,
                    stageKey: rendering.stageKey,
                    evolutionPath: rendering.path,
                    fit: BoxFit.contain,
                    prismatic: spectral,
                    silhouette: silhouette,
                  ),
                ),
              ));
              await tester.pump();

              final margin = tester.widget<Padding>(
                find.byKey(const ValueKey('dragon-art-safety-margin')),
              );
              final inset = margin.padding.resolve(TextDirection.ltr);
              expect(inset.left, greaterThanOrEqualTo(5.25),
                  reason:
                      'pass $pass ${selection.key} $form spectral=$spectral silhouette=$silhouette left');
              expect(inset.top, greaterThanOrEqualTo(5.25),
                  reason:
                      'pass $pass ${selection.key} $form spectral=$spectral silhouette=$silhouette top');

              final stack = tester.widget<Stack>(find.descendant(
                of: find.byType(DragonArt),
                matching: find.byType(Stack),
              ));
              expect(
                find.descendant(
                  of: find.byType(DragonArt),
                  matching: find.byType(ClipRect),
                ),
                findsNothing,
                reason:
                    'pass $pass ${selection.key} $form must use a standalone sprite instead of a runtime atlas crop',
              );
              if (spectral && !silhouette) {
                expect(stack.children.first, isA<IgnorePointer>(),
                    reason:
                        'pass $pass ${selection.key} $form: aura must be behind');
                expect(stack.children[1], isA<ColorFiltered>(),
                    reason:
                        'pass $pass ${selection.key} $form: dragon must be foreground');
              } else if (silhouette) {
                expect(stack.children.first, isA<ColorFiltered>());
              } else {
                expect(stack.children.first, isNot(isA<ColorFiltered>()));
              }
              expect(tester.takeException(), isNull,
                  reason: 'pass $pass ${selection.key} $form render');
            }
          }
        }
      }
    }
  }, timeout: const Timeout(Duration(minutes: 12)));

  test('all 86 selected source forms resolve to standalone safe artwork', () {
    var count = 0;
    for (final selection in _selectedForms.entries) {
      for (final form in selection.value) {
        final rendering = _renderingFor(form);
        final artwork = DragonArtwork.forStage(
          stageKey: rendering.stageKey,
          lineageId: selection.key,
          evolutionPath: rendering.path,
        );
        expect(artwork.frame, DragonArtworkFrame.fullImage,
            reason: '${selection.key} $form');
        expect(artwork.asset, matches(RegExp('_${form}_safe(?:_v2)?\\.webp\$')),
            reason: '${selection.key} $form');
        count++;
      }
    }
    expect(count, 86);
  });

  test('all 86 standalone sprites keep every opaque pixel inside the safe area',
      () {
    for (var pass = 1; pass <= 5; pass++) {
      for (final selection in _selectedForms.entries) {
        for (final form in selection.value) {
          final path = DragonArtwork.safeStandaloneFormAsset(
            selection.key,
            form,
          );
          final decoded = img.decodeImage(File(path).readAsBytesSync());
          expect(decoded, isNotNull, reason: 'pass $pass: $path decodes');
          final sprite = decoded!;
          expect(sprite.width, sprite.height, reason: 'pass $pass: $path');

          var minX = sprite.width;
          var minY = sprite.height;
          var maxX = -1;
          var maxY = -1;
          for (final pixel in sprite) {
            if (pixel.a <= 8) continue;
            if (pixel.x < minX) minX = pixel.x;
            if (pixel.x > maxX) maxX = pixel.x;
            if (pixel.y < minY) minY = pixel.y;
            if (pixel.y > maxY) maxY = pixel.y;
          }
          expect(maxX, greaterThanOrEqualTo(0),
              reason: 'pass $pass: $path contains visible artwork');
          final requiredMargin = DragonArtwork
                      .secondPassStandaloneForms[selection.key]
                      ?.contains(form) ==
                  true
              ? 144
              : 64;
          expect(minX, greaterThanOrEqualTo(requiredMargin),
              reason: 'pass $pass: $path left edge');
          expect(minY, greaterThanOrEqualTo(requiredMargin),
              reason: 'pass $pass: $path top edge');
          expect(sprite.width - 1 - maxX, greaterThanOrEqualTo(requiredMargin),
              reason: 'pass $pass: $path right edge');
          expect(sprite.height - 1 - maxY, greaterThanOrEqualTo(requiredMargin),
              reason: 'pass $pass: $path bottom edge');
        }
      }
    }
  }, timeout: const Timeout(Duration(minutes: 8)));

  test('Frostfable wyrmling keeps continuous scales through neck and chest',
      () {
    final sprite = img.decodeImage(
      File(
        DragonArtwork.safeStandaloneFormAsset('frostfable', 'wyrmling'),
      ).readAsBytesSync(),
    );
    expect(sprite, isNotNull);
    for (final point in const [
      (650, 455),
      (656, 505),
      (663, 555),
      (670, 605),
      (675, 655),
    ]) {
      expect(
        sprite!.getPixel(point.$1, point.$2).a,
        greaterThan(32),
        reason: 'unexpected transparent chest pixel at $point',
      );
    }
  });

  test('Supernova Sovereign has transparent negative space between its legs',
      () {
    final sprite = img.decodeImage(
      File(
        DragonArtwork.safeStandaloneFormAsset('starforged', 'arcana'),
      ).readAsBytesSync(),
    );
    expect(sprite, isNotNull);
    for (final point in const [(354, 413), (360, 420)]) {
      expect(
        sprite!.getPixel(point.$1, point.$2).a,
        lessThanOrEqualTo(8),
        reason: 'white background remnant at $point',
      );
    }
    for (final point in const [(344, 420), (377, 421)]) {
      expect(
        sprite!.getPixel(point.$1, point.$2).a,
        greaterThan(24),
        reason: 'dragon outline was damaged at $point',
      );
    }
  });

  test(
      'Seraphscale uses complete standalone artwork where replacement was needed',
      () {
    expect(
      DragonArtwork.forStage(
        stageKey: 'spark',
        lineageId: 'seraphscale',
        evolutionPath: 'might',
      ).asset,
      DragonArtwork.seraphscaleHatchlingAsset,
    );
    expect(
      DragonArtwork.allAssetPaths,
      containsAll([
        DragonArtwork.seraphscaleHatchlingSilhouetteAsset,
        DragonArtwork.seraphscaleHatchlingSpectralAsset,
      ]),
    );
    expect(
      DragonArtwork.forStage(
        stageKey: 'nestDragon',
        lineageId: 'seraphscale',
        evolutionPath: 'might',
      ).asset,
      DragonArtwork.seraphscaleWyrmlingAsset,
    );
    expect(
      DragonArtwork.forStage(
        stageKey: 'homeGuardian',
        lineageId: 'seraphscale',
        evolutionPath: 'might',
      ).asset,
      DragonArtwork.seraphscaleMightAsset,
    );
    expect(
      DragonArtwork.forStage(
        stageKey: 'homeGuardian',
        lineageId: 'seraphscale',
        evolutionPath: 'arcana',
      ).asset,
      DragonArtwork.seraphscaleArcanaAsset,
    );
  });
}
