import 'dart:io';

import 'package:dragon_haven/models/adventure.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:dragon_haven/services/event_branding_service.dart';
import 'package:dragon_haven/theme/event_appearance.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(EventBrandingService.channel, null);
  });

  test('all event logos and native variants exist with transparent artwork',
      () async {
    expect(EventAppearance.logoKeys.keys.toSet(),
        specialAdventureEventCatalog.map((e) => e.id).toSet());
    for (final entry in EventAppearance.logoKeys.entries) {
      final bytes =
          await rootBundle.load(EventAppearance.logoForEvent(entry.key));
      final art = img.decodePng(bytes.buffer.asUint8List())!;
      expect(art.width, art.height);
      expect(art.numChannels, 4);
      expect(art.getPixel(art.width - 1, 0).a, 0);
      final icon =
          'android/app/src/main/res/mipmap-anydpi-v26/ic_event_${entry.value}.xml';
      expect(File(icon).existsSync(), isTrue);
    }
  });

  test('schedule preserves Amsterdam boundaries and clears personal previews',
      () {
    final now = DateTime.utc(2026, 9, 8);
    final preview = SpecialAdventureWindow(
        event: specialAdventureEventById('halloween_witchlight')!,
        key: 'halloween_witchlight:preview:personal',
        startsAt: now,
        endsAt: now.add(const Duration(hours: 48)));
    final schedule = eventBrandingSchedule(now, [preview]);
    expect(schedule.where((w) => w['preview'] == true), hasLength(1));
    final halloween = schedule
        .singleWhere((w) => w['key'] == 'halloween_witchlight:launch:2026');
    expect(halloween['start'],
        DateTime.utc(2026, 10, 24, 22).millisecondsSinceEpoch);
    expect(
        halloween['end'], DateTime.utc(2026, 11, 1, 23).millisecondsSinceEpoch);
    expect(eventBrandingSchedule(now, []).any((w) => w['preview'] == true),
        isFalse);
    expect(
        eventBrandingSchedule(preview.endsAt, [preview])
            .any((w) => w['preview'] == true),
        isFalse);
    expect(schedule.map((w) => w['key']).toSet(), hasLength(schedule.length));
    expect(schedule.map((w) => w['logo']).toSet(),
        EventAppearance.logoKeys.values.toSet());
  });

  test('recurring New Year keeps the same window and logo across midnight', () {
    for (final year in [2027, 2028, 2030]) {
      final start = DateTime.utc(year, 12, 31, 17);
      final end = DateTime.utc(year + 1, 1, 1, 23);
      for (final now in [
        start,
        DateTime.utc(year, 12, 31, 23),
        end.subtract(const Duration(milliseconds: 1))
      ]) {
        final active = specialAdventureWindowsAt(now);
        final event =
            active.singleWhere((w) => w.event.id == 'new_year_first_dawn');
        expect(event.key, 'new_year_first_dawn:year:$year');
        expect(event.startsAt, start);
        expect(event.endsAt, end);
        final scheduled = eventBrandingSchedule(now, active)
            .singleWhere((w) => w['key'] == event.key);
        expect(scheduled['logo'], 'new_year');
        expect(scheduled['end'], end.millisecondsSinceEpoch);
      }
      for (final now in [
        start.subtract(const Duration(milliseconds: 1)),
        end
      ]) {
        expect(
            specialAdventureWindowsAt(now)
                .any((w) => w.event.id == 'new_year_first_dawn'),
            isFalse);
      }
    }
  });

  test('bridge skips unchanged schedules and retries after a platform failure',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    var attempts = 0;
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(EventBrandingService.channel,
        (call) async {
      calls.add(call);
      if (++attempts == 1) {
        throw PlatformException(code: 'temporarily_unavailable');
      }
      return null;
    });
    final service = EventBrandingService();
    final schedule = eventBrandingSchedule(DateTime.utc(2026, 9, 8), []);
    await service.synchronize(schedule);
    await service.synchronize(schedule);
    await service.synchronize(schedule);
    expect(calls, hasLength(2));
    expect(calls.last.arguments['windows'], schedule);
    await service.synchronize([]);
    expect(calls, hasLength(3));
    expect(calls.last.arguments['windows'], isEmpty);
  });
}
