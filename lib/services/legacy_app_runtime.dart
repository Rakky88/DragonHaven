import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_info.dart';
import '../domain/game_time_bridge.dart';
import '../models/social.dart';
import '../providers/household_provider.dart';
import '../providers/online_account_provider.dart';
import 'account_legacy_game_storage.dart';
import 'audio_service.dart';
import 'diagnostic_reporter.dart';
import 'egg_altar_repository.dart';
import 'firebase_push.dart';
import 'social_repository.dart';
import 'storage_service.dart';

class LegacyAppRuntime {
  LegacyAppRuntime(this.game, this.online, this.altar, this.push);
  final HouseholdProvider game;
  final OnlineAccountProvider online;
  final EggAltarRepository? altar;
  final FirebasePushCoordinator? push;
}

Future<LegacyAppRuntime> createLegacyAppRuntime({
  required HouseholdProvider game,
  required SocialRepository socialRepository,
  required SupabaseClient? auth,
  required bool firebaseAvailable,
  required DiagnosticReporter diagnostics,
  AccountLegacyGameStorage? accountStorage,
}) async {
  final altar =
      auth == null ? null : EggAltarRepository(auth, socialRepository, game);
  if (altar != null) {
    game
      ..altarRequiresAccount = true
      ..altarCurrentUserId = (() =>
          socialRepository.isSignedIn ? socialRepository.currentUserId : null)
      ..altarSessionEpoch = (() => altar.sessionEpoch)
      ..altarCommand = altar.command
      ..loadWeaveBeacon = altar.beacon
      ..refreshEggAltar = altar.refresh;
  }
  FirebasePushCoordinator? push;
  late final OnlineAccountProvider online;
  online = OnlineAccountProvider(
    repository: socialRepository,
    inventorySnapshot: () => OnlineInventorySnapshot.fromGame(game),
    profileSnapshot: () => OnlineProfileSnapshot.fromGame(game),
    synchronizeEggAltar: game.refreshEggAltar,
    synchronizeKnownDiscoveries: (profile) async {
      if (socialRepository.currentUserId != profile.userId) return;
      await game.mergeKnownDiscoveries(
          profile.discoveredForms, profile.prismaticForms);
    },
    synchronizeGroupReservations: game.synchronizeOnlineGroupReservations,
    applyGroupReward: (reward) => game.applyOnlineGroupReward(
      lobbyId: reward.lobbyId,
      adventureId: reward.adventureId,
      dragonId: reward.dragonId,
      xp: reward.xp,
      focus: reward.focus,
      statPoints: reward.statPoints,
      chestTier: reward.chestTier,
      participantCount: reward.participantCount,
      completedAt: reward.completedAt,
    ),
    synchronizeTradeReservations: game.synchronizeOnlineTradeReservations,
    applyTradeSettlement: (settlement) => game.applyOnlineTradeSettlement(
      tradeId: settlement.tradeId,
      sentKind: settlement.sent.kind.name,
      sentKey: settlement.sent.key,
      sentData: settlement.sent.data,
      receivedKind: settlement.received.kind.name,
      receivedKey: settlement.received.key,
      receivedData: settlement.received.data,
    ),
    applySeasonalPrize: ({
      required prizeId,
      required eventId,
      required position,
    }) =>
        game.applySeasonalPodiumPrize(
      prizeId: prizeId,
      eventId: eventId,
      position: position,
    ),
    synchronizeSeasonalPreviews: game.synchronizeSeasonalEventPreviews,
    synchronizeSeasonalDismissals: game.synchronizeSeasonalEventDismissals,
    synchronizeSeasonalPairReservations:
        game.synchronizeOnlineSeasonalPairReservations,
    applySeasonalPairReward: (reward) => game.applyOnlineSeasonalPairReward(
      adventureId: reward.adventureId,
      eventId: reward.eventId,
      dragonId: reward.dragonId,
      xp: reward.xp,
      might: reward.might,
      arcana: reward.arcana,
      spirit: reward.spirit,
      specialChestId: reward.specialChestId,
      simulated: reward.simulated,
    ),
    gameStateSnapshot: () => GameTimeBridge.forUpload(game.exportState()),
    applyCloudState: (state) {
      final owner = socialRepository.currentUserId;
      final epoch = online.restoreSessionEpoch;
      return game.restoreCloudState(
        state,
        recoveryOwner: owner,
        canApplyRestore: () =>
            online.cloudRestoreStillAllowed &&
            socialRepository.isSignedIn &&
            socialRepository.currentUserId == owner &&
            online.restoreSessionEpoch == epoch,
      );
    },
    deviceId: StorageService.deviceId,
    clientVersion: AppInfo.version,
    loadCloudBaseRevision: (owner) => accountStorage == null
        ? StorageService.loadCloudBaseRevision(owner)
        : owner == accountStorage.owner
            ? accountStorage.cloudBaseRevision()
            : Future.error(const SocialException('online_login_required')),
    saveCloudBaseRevision: (owner, revision) => accountStorage == null
        ? StorageService.saveCloudBaseRevision(owner, revision)
        : owner == accountStorage.owner
            ? accountStorage.saveCloudBaseRevision(revision)
            : Future.error(const SocialException('online_login_required')),
    languageCode: () => game.languageCode,
    diagnostics: diagnostics,
    prepareAccountExit: () async {
      try {
        await push
            ?.unregisterBeforeSignOut()
            .timeout(const Duration(seconds: 3));
      } on Object {
        // Optional push cannot block signing out during a network outage.
      }
    },
    accountExitFinished: () => push?.afterSignOutAttempt(),
  );
  try {
    await online.initialize(waitForFirstRefresh: false);
    if (firebaseAvailable && auth != null) {
      push = FirebasePushCoordinator(game, online, auth);
    }
    await HavenAudio.configureJukebox(
      trackIds: game.enabledMusicResourceIds,
      shuffle: game.jukeboxShuffle,
      repeat: game.jukeboxRepeat,
    );
    await HavenAudio.applyPreferences(
      musicEnabled: game.musicEnabled,
      soundEffectsEnabled: game.soundEffectsEnabled,
      musicStyle: game.musicStyle,
    );
    final hour = DateTime.now().hour;
    await HavenAudio.setMusicScene(hour >= 21 || hour < 7
        ? HavenMusicScene.towerNight
        : HavenMusicScene.towerDay);
    return LegacyAppRuntime(game, online, altar, push);
  } on Object {
    push?.dispose();
    await online.stopLegacyOperations();
    await game.stopAltarOperations();
    await altar?.stopLegacyOperations();
    online.dispose();
    rethrow;
  }
}
