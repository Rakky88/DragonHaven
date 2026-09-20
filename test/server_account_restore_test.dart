import 'package:dragon_haven/domain/server_entropy.dart';
import 'dart:convert';
import 'dart:io';

import 'package:dragon_haven/models/adventure.dart';
import 'package:dragon_haven/models/egg_altar.dart';
import 'package:dragon_haven/models/music_track.dart';
import 'package:dragon_haven/models/mystic_relic.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/supporter_pack.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:dragon_haven/services/canonical_game_actions.dart';
import 'package:dragon_haven/services/canonical_game_session.dart';
import 'package:dragon_haven/services/canonical_game_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/game_domain_probe.dart';
import 'support/canonical_ui_server.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'a completely empty second device restores all account collections and live journeys',
      () async {
    final initial =
        (await runGameDomainProbe())['state'] as Map<String, dynamic>;
    final now = DateTime.utc(2026, 9, 7, 12);
    final game = HouseholdProvider.forServerState(initial,
        now: now,
        random: ServerEntropy('a3' * 32, stream: 'rewards'),
        idGenerator: ServerEntropy('a3' * 32, stream: 'identities').uuid);
    game
      ..accountName = 'Cloud Keeper'
      ..onboardingComplete = true
      ..languageCode = 'nl'
      ..ownedBadgeIds = {supporterBadge.id}
      ..selectedBadgeId = supporterBadge.id
      ..ownedFrameIds = {supporterFrame.id}
      ..selectedFrameId = supporterFrame.id
      ..ownedMusicTrackIds = {for (final t in musicCatalog.take(3)) t.id}
      ..enabledMusicTrackIds = {musicCatalog[1].id}
      ..jukeboxShuffle = true
      ..towerFloorRoomIds = ['hearth', 'hearth', 'hearth']
      ..ownedItemIds = {'moss_cushion'}
      ..eggAltar = EggAltarState(
          ownerId: CanonicalUiServer.owner,
          wallet: const WeaveWallet(817, 36, 4));
    game.pet.training
      ..clear()
      ..addAll({'might': 580, 'arcana': 200, 'spirit': 170});
    game.pet.trialHighScores
      ..clear()
      ..addAll({'ruinBreaker': 12770, 'cavernFlight': 8138});
    game.pet.highlightedExpertises
      ..clear()
      ..addAll({TrainingFocus.might, TrainingFocus.spirit});
    game.relicInventory[MysticRelic.astralLens] = 5;
    game.untradeableRelicInventory[MysticRelic.astralLens] = 2;
    await game.applyVerifiedSupporterPack('restore-fixture-purchase');
    await game.placeHouseItem('moss_cushion', roomId: 'nest', x: .27, y: .68);
    final server = CanonicalUiServer(game.exportState());
    game.dispose();
    HouseholdProvider.forServerState(server.state,
            now: now,
            random: ServerEntropy('a3' * 32, stream: 'rewards'),
            idGenerator: ServerEntropy('a3' * 32, stream: 'identities').uuid)
        .dispose();
    final directories = <Directory>[];
    final sessions = <CanonicalGameSession>[];
    Future<CanonicalGameSession> device() async {
      final dir = await Directory.systemTemp.createTemp('dh-restore-device-');
      directories.add(dir);
      expect(dir.listSync(), isEmpty);
      final session = CanonicalGameSession(
          connection: CanonicalUiConnection(server), directory: dir);
      sessions.add(session);
      await session.synchronize();
      return session;
    }

    try {
      final first = await device();
      await CanonicalGameActions(first).refresh();
      final egg = first.snapshot!.eggs.firstWhere((e) => e.location == 'stash');
      await CanonicalGameActions(first).tagEgg(egg.id, true);
      final dragon = first.snapshot!.dragons.firstWhere((d) => d.owned);
      final adventure =
          first.snapshot!.adventures.offers(AdventureKind.mini).first;
      await CanonicalGameActions(first).startAdventure(adventure, dragon.id);
      final expected = jsonDecode(jsonEncode(first.snapshot!.toJson()));
      final privateSave = jsonEncode(server.state);
      final replacement = await device();
      expect(replacement.snapshot!.toJson(), expected);
      expect(jsonEncode(server.state), privateSave,
          reason: 'A restore must never create or rewrite inventory.');
      final view = replacement.snapshot!;
      expect(view.adventures.runs, hasLength(1));
      expect(view.dragon(dragon.id)!.trialHighScores['ruinBreaker'], 12770);
      expect(view.dragon(dragon.id)!.trialHighScores['cavernFlight'], 8138);
      expect(view.egg(egg.id)!.tagged, true);
      expect(view.house.floorRoomIds, hasLength(3));
      expect(view.house.placements.single.x, .27);
      expect(view.shop.untradeableRelics['astralLens'], 2);
      expect(view.shop.relics['astralLens'], 5);
      expect(view.shop.supporterPackOwned, true);
      expect(view.profile.selected('badge'), supporterBadge.id);
      expect(view.profile.selected('frame'), supporterFrame.id);
      expect(view.profile.preferences['enabledMusicTrackIds'],
          [musicCatalog[1].id]);
      expect(view.inventory.materials.fragments, 817);
      expect(view.inventory.materials.essence, 36);
      expect(view.inventory.materials.hearts, 4);
      // A stale phone may never overwrite the account restored on a newer one.
      await CanonicalGameActions(replacement)
          .setPreferences({'musicEnabled': false});
      await expectLater(
          CanonicalGameActions(first).setPreferences({'musicEnabled': true}),
          throwsA(isA<CanonicalGameException>()));
      await first.synchronize();
      expect(first.snapshot!.profile.preferences['musicEnabled'], false);
    } finally {
      for (final session in sessions) {
        await session.close();
      }
      for (final dir in directories) {
        await dir.delete(recursive: true);
      }
    }
  });
}
