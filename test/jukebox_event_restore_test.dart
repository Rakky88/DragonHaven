import 'package:dragon_haven/models/adventure.dart';
import 'package:dragon_haven/models/chest.dart';
import 'package:dragon_haven/models/redeem_code.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <MethodCall>[];
  const channel = MethodChannel('nl.dragonhaven.app/audio');
  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return true;
    });
  });
  tearDown(() => TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, null));

  List<String> playlist() => List<String>.from((calls
      .lastWhere((c) => c.method == 'setJukebox')
      .arguments as Map)['tracks'] as List);

  test(
      'natural expiry restores saved selection including music collected during event',
      () async {
    var now = DateTime.utc(2026, 9, 9, 12);
    final game = HouseholdProvider(clock: () => now, persistenceEnabled: false);
    addTearDown(game.dispose);
    await game.setMusicTrackEnabled('reverie', false);
    await game.setJukeboxShuffle(true);
    await game.setJukeboxRepeat(false);
    await game.synchronizeSeasonalEventPreviews({
      'christmas_winter_hearth': now.add(const Duration(seconds: 10)),
    });
    expect(playlist(), ['music_event_jingle_bells']);
    game.chestInventory[ChestTier.music] = 1;
    final found = (await game.openChest(ChestTier.music))!.musicTrackFound!;
    expect(playlist(), contains(found.rawResourceId));
    now = now.add(const Duration(seconds: 11));
    // This is exactly the app's event-boundary callback; no before/after getter.
    await game.refreshJukeboxAudio();
    expect(playlist(), [found.rawResourceId]);
    expect(game.enabledMusicTrackIds, {found.id});
    final args = calls.last.arguments as Map;
    expect(args['shuffle'], true);
    expect(args['repeat'], false);
    final count = calls.length;
    await game.refreshJukeboxAudio();
    expect(calls.length, count,
        reason: 'No queue reset on an unchanged timer tick');
  });

  test('birthday music replaces its preview and expires back to saved music',
      () async {
    var now = DateTime.utc(2026, 9, 9, 12);
    final game = HouseholdProvider(clock: () => now, persistenceEnabled: false);
    addTearDown(game.dispose);
    await game.synchronizeSeasonalEventPreviews({
      'christmas_winter_hearth': now.add(const Duration(hours: 48)),
    });
    await game.synchronizeSeasonalEventPreviews({
      'golden_wings_birthday': now.add(const Duration(seconds: 10)),
    });
    expect(playlist(), ['music_event_happy_birthday', 'music_reverie']);
    expect(game.ownedMusicTrackIds, isNot(contains('event_birthday_wish')));
    now = now.add(const Duration(seconds: 11));
    await game.refreshJukeboxAudio();
    expect(playlist(), ['music_reverie']);
    expect(game.enabledMusicTrackIds, {'reverie'});
  });

  test('explicit stop and calendar dismissal immediately remove event music',
      () async {
    var now = DateTime.utc(2026, 9, 9, 12);
    final game = HouseholdProvider(clock: () => now, persistenceEnabled: false);
    addTearDown(game.dispose);
    await game.synchronizeSeasonalEventPreviews({
      'christmas_winter_hearth': now.add(const Duration(hours: 48)),
    });
    expect(playlist(), contains('music_event_jingle_bells'));
    await game.synchronizeSeasonalEventPreviews({});
    expect(playlist(), ['music_reverie']);
    now = DateTime.utc(2026, 12, 25, 12);
    await game.refreshForCurrentDate();
    final window = game.activeSpecialAdventureWindows.single;
    expect(playlist(), contains('music_event_jingle_bells'));
    await game
        .synchronizeSeasonalEventDismissals({window.event.id: window.endsAt});
    expect(playlist(), ['music_reverie']);
  });

  test('master and every song switch reevaluate the current complete playlist',
      () async {
    final now = DateTime.utc(2026, 9, 9, 12);
    final game = HouseholdProvider(clock: () => now, persistenceEnabled: false);
    addTearDown(game.dispose);
    await game.setMusicEnabled(false);
    expect(playlist(), ['music_reverie']);
    expect(
        calls.lastWhere((c) => c.method == 'setPreferences').arguments['music'],
        false);
    await game.setMusicTrackEnabled('reverie', false);
    expect(playlist(), isEmpty);
    await game.setMusicTrackEnabled('reverie', true);
    expect(playlist(), ['music_reverie']);
    await game.setMusicEnabled(true);
    expect(playlist(), ['music_reverie']);
    expect(
        calls.lastWhere((c) => c.method == 'setPreferences').arguments['music'],
        true);
    await game.synchronizeSeasonalEventPreviews({
      'christmas_winter_hearth': now.add(const Duration(hours: 1)),
    });
    final eventTrack = game.activeSeasonalMusicTracks.single;
    await game.setMusicTrackEnabled(eventTrack.id, false);
    expect(playlist(), ['music_reverie']);
    await game.setMusicTrackEnabled(eventTrack.id, true);
    expect(playlist(), ['music_event_jingle_bells', 'music_reverie']);
  });

  test(
      'all catalog previews work for different keepers and preserve retry expiry',
      () async {
    final now = DateTime.utc(2026, 9, 9, 12);
    for (final keeper in ['DH-AAAA0001', 'DH-BBBB0002']) {
      final game =
          HouseholdProvider(clock: () => now, persistenceEnabled: false);
      addTearDown(game.dispose);
      for (final code in redeemCodeCatalog.where(
          (c) => c.rewardType == RedeemRewardType.seasonalEventPreview)) {
        expect(code.restrictedKeeperId, isNull);
        expect(specialAdventureEventById(code.rewardId)!.previewOwnerKeeperId,
            isNull);
        expect(await game.redeemCode(code.code, keeperId: keeper),
            'redeemed_event_preview');
        final expiry = game.seasonalEventPreviewExpiresAt[code.rewardId];
        expect(await game.redeemCode(code.code, keeperId: keeper),
            'preview_active');
        expect(game.seasonalEventPreviewExpiresAt, {code.rewardId: expiry});
      }
    }
  });
}
