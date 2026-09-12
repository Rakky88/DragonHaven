import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dragon_haven/models/social.dart';
import 'package:dragon_haven/theme/app_theme.dart';
import 'package:dragon_haven/widgets/keeper_list_row.dart';

void main() {
  for (final scale in [1.0, 1.6]) {
    testWidgets('framed and plain friends have equal geometry at $scale text',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final boundary = GlobalKey();
      int selected = 0;
      await tester.pumpWidget(MaterialApp(
          theme: buildAppTheme(),
          home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: Scaffold(
                  body: RepaintBoundary(
                      key: boundary,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(children: [
                          for (final framed in [false, true])
                            KeeperListRow(
                              key: Key('row-$framed'),
                              keeper: KeeperProfile(
                                  userId: '$framed',
                                  keeperCode: 'fixture',
                                  displayName: 'Luna Moonwhisper',
                                  title: 'Keeper',
                                  portraitKey: 'portrait_042',
                                  frameKey:
                                      framed ? 'frame_supporter_founder' : null,
                                  badgeKey:
                                      framed ? 'badge_supporter_founder' : null,
                                  discoveredDragonCount: 12,
                                  inventoryImported: true),
                              subtitle: const Text('Dragon Keeper',
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              detail: const Text('12 dragons discovered',
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                        onPressed: () {},
                                        icon: const Icon(Icons.mail_outline)),
                                    IconButton(
                                        onPressed: () {},
                                        icon: const Icon(Icons.swap_horiz)),
                                  ]),
                              onTap: () => selected++,
                            ),
                        ]),
                      ))))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byKey(const Key('row-true'))),
          tester.getSize(find.byKey(const Key('row-false'))));
      for (final framed in [false, true]) {
        expect(tester.getSize(find.byKey(Key('keeper-list-portrait-$framed'))),
            const Size.square(64));
      }
      await tester.tap(find.text('Luna Moonwhisper').first);
      await tester.pumpAndSettle();
      expect(selected, 1);
      if (scale == 1) {
        expect(tester.getSize(find.byKey(const Key('row-true'))).height,
            lessThan(100));
        final render = boundary.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await render.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory('build/friends-review').create(recursive: true);
          await File('build/friends-review/compact-rows.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    });
  }
}
