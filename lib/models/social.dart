import '../providers/household_provider.dart';
import 'pet.dart';

enum FriendRequestDirection { incoming, outgoing }

class OnlineProfileSnapshot {
  const OnlineProfileSnapshot({
    required this.displayName,
    required this.titleId,
    required this.portraitId,
  });

  final String displayName;
  final String titleId;
  final String portraitId;

  factory OnlineProfileSnapshot.fromGame(HouseholdProvider game) =>
      OnlineProfileSnapshot(
        displayName: game.accountName.trim().isEmpty
            ? 'Keeper'
            : game.accountName.trim(),
        titleId: game.selectedTitleId ?? 'title_001',
        portraitId: game.selectedPortraitId ?? 'portrait_001',
      );
}

class FavoriteDragonSummary {
  const FavoriteDragonSummary({
    required this.id,
    required this.name,
    required this.lineageId,
    required this.stage,
    required this.level,
    required this.might,
    required this.arcana,
    required this.spirit,
    required this.evolutionPath,
    required this.prismatic,
    required this.sinister,
  });

  final String id;
  final String name;
  final String lineageId;
  final String stage;
  final int level;
  final int might;
  final int arcana;
  final int spirit;
  final String evolutionPath;
  final bool prismatic;
  final bool sinister;

  String get stageKey => switch (stage) {
        'egg' => 'moonEgg',
        'hatchling' => 'spark',
        'wyrmling' => 'nestDragon',
        _ => 'homeGuardian',
      };

  factory FavoriteDragonSummary.fromJson(Map<String, dynamic> json) =>
      FavoriteDragonSummary(
        id: json['favorite_dragon_id']?.toString() ?? '',
        name: json['favorite_dragon_name']?.toString() ?? '',
        lineageId: json['favorite_dragon_lineage_id']?.toString() ?? '',
        stage: json['favorite_dragon_stage']?.toString() ?? 'hatchling',
        level: _int(json['favorite_dragon_level'], fallback: 1),
        might: _int(json['favorite_dragon_might']),
        arcana: _int(json['favorite_dragon_arcana']),
        spirit: _int(json['favorite_dragon_spirit']),
        evolutionPath:
            json['favorite_dragon_evolution_path']?.toString() ?? 'spirit',
        prismatic: json['favorite_dragon_prismatic'] == true,
        sinister: json['favorite_dragon_sinister'] == true,
      );
}

class KeeperProfile {
  const KeeperProfile({
    required this.userId,
    required this.keeperCode,
    required this.displayName,
    required this.title,
    required this.portraitKey,
    required this.discoveredDragonCount,
    required this.inventoryImported,
    this.favoriteDragon,
  });

  final String userId;
  final String keeperCode;
  final String displayName;
  final String title;
  final String portraitKey;
  final int discoveredDragonCount;
  final bool inventoryImported;
  final FavoriteDragonSummary? favoriteDragon;

  factory KeeperProfile.fromJson(Map<String, dynamic> json) {
    final favoriteId = json['favorite_dragon_id']?.toString();
    return KeeperProfile(
      userId: json['user_id']?.toString() ?? '',
      keeperCode: json['keeper_code']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? 'Keeper',
      title: json['title']?.toString() ?? 'Dragon Keeper',
      portraitKey: json['portrait_key']?.toString() ?? 'moon',
      discoveredDragonCount: _int(json['discovered_dragon_count']),
      inventoryImported: json['inventory_imported'] == true,
      favoriteDragon: favoriteId == null || favoriteId.isEmpty
          ? null
          : FavoriteDragonSummary.fromJson(json),
    );
  }
}

class FriendshipRequest {
  const FriendshipRequest({
    required this.id,
    required this.direction,
    required this.keeper,
    required this.createdAt,
  });

  final String id;
  final FriendRequestDirection direction;
  final KeeperProfile keeper;
  final DateTime createdAt;

  factory FriendshipRequest.fromJson(Map<String, dynamic> json) =>
      FriendshipRequest(
        id: json['request_id']?.toString() ?? '',
        direction: json['direction'] == 'incoming'
            ? FriendRequestDirection.incoming
            : FriendRequestDirection.outgoing,
        keeper: KeeperProfile.fromJson(json),
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}

class SocialDashboard {
  const SocialDashboard({
    required this.profile,
    required this.friends,
    required this.requests,
    required this.blockedKeepers,
  });

  final KeeperProfile profile;
  final List<KeeperProfile> friends;
  final List<FriendshipRequest> requests;
  final List<KeeperProfile> blockedKeepers;
}

class AccountAuthResult {
  const AccountAuthResult({required this.requiresEmailConfirmation});

  final bool requiresEmailConfirmation;
}

class GroupDragonSubmission {
  const GroupDragonSubmission({required this.data});

  final Map<String, dynamic> data;

  factory GroupDragonSubmission.fromPet(Pet dragon) => GroupDragonSubmission(
        data: {
          'client_id': dragon.id,
          'name': dragon.displayName,
          'lineage_id': dragon.lineageId,
          'stage': dragon.stage.name,
          'xp': dragon.xp,
          'might': dragon.training['might'] ?? 0,
          'arcana': dragon.training['arcana'] ?? 0,
          'spirit': dragon.training['spirit'] ?? 0,
          'evolution_path': dragon.activeEvolutionPath,
          'prismatic': dragon.prismatic,
          'sinister': dragon.sinister,
        },
      );
}

class GroupAdventureStatus {
  const GroupAdventureStatus({
    required this.slot,
    required this.adventureId,
    required this.alreadyCompleted,
  });

  final int slot;
  final String adventureId;
  final bool alreadyCompleted;

  factory GroupAdventureStatus.fromJson(Map<String, dynamic> json) =>
      GroupAdventureStatus(
        slot: _int(json['slot']),
        adventureId: json['adventure_id']?.toString() ?? '',
        alreadyCompleted: json['already_completed'] == true,
      );
}

class GroupAdventureParticipant {
  const GroupAdventureParticipant({
    required this.keeper,
    required this.dragonId,
    required this.dragonName,
    required this.lineageId,
    required this.stage,
    required this.level,
    required this.might,
    required this.arcana,
    required this.spirit,
    required this.evolutionPath,
    required this.prismatic,
    required this.sinister,
    required this.isOwner,
  });

  final KeeperProfile keeper;
  final String dragonId;
  final String dragonName;
  final String lineageId;
  final String stage;
  final int level;
  final int might;
  final int arcana;
  final int spirit;
  final String evolutionPath;
  final bool prismatic;
  final bool sinister;
  final bool isOwner;

  factory GroupAdventureParticipant.fromJson(Map<String, dynamic> json) =>
      GroupAdventureParticipant(
        keeper: KeeperProfile.fromJson(json),
        dragonId: json['dragon_id']?.toString() ?? '',
        dragonName: json['dragon_name']?.toString() ?? 'Dragon',
        lineageId: json['dragon_lineage_id']?.toString() ?? '',
        stage: json['dragon_stage']?.toString() ?? 'hatchling',
        level: _int(json['dragon_level'], fallback: 1),
        might: _int(json['dragon_might']),
        arcana: _int(json['dragon_arcana']),
        spirit: _int(json['dragon_spirit']),
        evolutionPath: json['dragon_evolution_path']?.toString() ?? 'spirit',
        prismatic: json['dragon_prismatic'] == true,
        sinister: json['dragon_sinister'] == true,
        isOwner: json['is_owner'] == true,
      );
}

class GroupAdventureLobby {
  const GroupAdventureLobby({
    required this.id,
    required this.slot,
    required this.adventureId,
    required this.ownerId,
    required this.status,
    required this.requiredPlayers,
    required this.focus,
    required this.startedAt,
    required this.endsAt,
    required this.isCurrentOffer,
    required this.isOwner,
    required this.isParticipant,
    required this.myDragonId,
    required this.rewardAcknowledged,
    required this.participants,
  });

  final String id;
  final int slot;
  final String adventureId;
  final String ownerId;
  final String status;
  final int requiredPlayers;
  final String focus;
  final DateTime? startedAt;
  final DateTime? endsAt;
  final bool isCurrentOffer;
  final bool isOwner;
  final bool isParticipant;
  final String? myDragonId;
  final bool rewardAcknowledged;
  final List<GroupAdventureParticipant> participants;

  bool get isWaiting => status == 'waiting';
  bool get isRunning => status == 'running';
  bool get isRewardReady => status == 'completed';
  GroupAdventureParticipant? get owner => participants
      .cast<GroupAdventureParticipant?>()
      .firstWhere((participant) => participant?.isOwner == true,
          orElse: () => null);

  factory GroupAdventureLobby.fromJson(Map<String, dynamic> json) {
    final rawParticipants = json['participants'];
    return GroupAdventureLobby(
      id: json['lobby_id']?.toString() ?? '',
      slot: _int(json['slot']),
      adventureId: json['adventure_id']?.toString() ?? '',
      ownerId: json['owner_id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'waiting',
      requiredPlayers: _int(json['required_players'], fallback: 2),
      focus: json['focus']?.toString() ?? 'might',
      startedAt: DateTime.tryParse(json['started_at']?.toString() ?? ''),
      endsAt: DateTime.tryParse(json['ends_at']?.toString() ?? ''),
      isCurrentOffer: json['is_current_offer'] == true,
      isOwner: json['is_owner'] == true,
      isParticipant: json['is_participant'] == true,
      myDragonId: json['my_dragon_id']?.toString(),
      rewardAcknowledged: json['reward_acknowledged'] == true,
      participants: rawParticipants is List
          ? rawParticipants
              .whereType<Map>()
              .map((entry) => GroupAdventureParticipant.fromJson(
                  Map<String, dynamic>.from(entry)))
              .toList(growable: false)
          : const [],
    );
  }
}

class GroupAdventureReward {
  const GroupAdventureReward({
    required this.lobbyId,
    required this.adventureId,
    required this.dragonId,
    required this.xp,
    required this.focus,
    required this.statPoints,
    required this.chestTier,
    required this.participantCount,
  });

  final String lobbyId;
  final String adventureId;
  final String dragonId;
  final int xp;
  final String focus;
  final int statPoints;
  final String chestTier;
  final int participantCount;

  factory GroupAdventureReward.fromJson(Map<String, dynamic> json) =>
      GroupAdventureReward(
        lobbyId: json['lobby_id']?.toString() ?? '',
        adventureId: json['adventure_id']?.toString() ?? '',
        dragonId: json['dragon_id']?.toString() ?? '',
        xp: _int(json['xp']),
        focus: json['focus']?.toString() ?? 'might',
        statPoints: _int(json['stat_points']),
        chestTier: json['chest_tier']?.toString() ?? 'gold',
        participantCount: _int(json['participant_count'], fallback: 2),
      );
}

class OnlineInventorySnapshot {
  const OnlineInventorySnapshot({
    required this.coins,
    required this.gems,
    required this.dragons,
    required this.eggs,
    required this.chests,
    required this.furnitureCatalogIds,
    required this.discoveredLineageIds,
  });

  final int coins;
  final int gems;
  final List<Map<String, dynamic>> dragons;
  final List<Map<String, dynamic>> eggs;
  final Map<String, int> chests;
  final List<String> furnitureCatalogIds;
  final List<String> discoveredLineageIds;

  factory OnlineInventorySnapshot.fromGame(HouseholdProvider game) {
    final dragons = [game.pet, ...game.sanctuaryDragons]
        .where((dragon) => !dragon.isEgg)
        .map((dragon) => {
              'client_id': dragon.id,
              'name': dragon.displayName,
              'lineage_id': dragon.lineageId,
              'stage': dragon.stage.name,
              'xp': dragon.xp,
              'might': dragon.training['might'] ?? 0,
              'arcana': dragon.training['arcana'] ?? 0,
              'spirit': dragon.training['spirit'] ?? 0,
              'evolution_path': dragon.activeEvolutionPath,
              'favorite': dragon.favorite,
              'prismatic': dragon.prismatic,
              'sinister': dragon.sinister,
            })
        .toList(growable: false);
    final eggs = <Map<String, dynamic>>[
      if (game.pet.isEgg)
        {
          'client_id': game.pet.id,
          'lineage_id': game.pet.lineageId,
          'acquired_at': game.pet.acquiredAt.toUtc().toIso8601String(),
          'prismatic': game.pet.prismatic,
          'sinister': game.pet.sinister,
        },
      if (game.incubatingEgg case final egg?)
        {
          'client_id': egg.id,
          'lineage_id': egg.lineageId,
          'acquired_at': egg.acquiredAt.toUtc().toIso8601String(),
          'prismatic': egg.prismatic,
          'sinister': egg.sinister,
        },
      for (final egg in game.eggStash)
        {
          'client_id': egg.id,
          'lineage_id': egg.lineageId,
          'acquired_at': egg.acquiredAt.toUtc().toIso8601String(),
          'prismatic': egg.prismatic,
          'sinister': egg.sinister,
        },
    ];
    return OnlineInventorySnapshot(
      coins: game.coins,
      gems: game.gems,
      dragons: dragons,
      eggs: eggs,
      chests: {
        for (final entry in game.chestInventory.entries)
          entry.key.name: entry.value,
      },
      furnitureCatalogIds: game.ownedItemIds.toList(growable: false),
      discoveredLineageIds: {
        ...game.discoveredForms.map((key) => key.split(':').first),
        ...game.prismaticForms.map((key) => key.split(':').first),
      }.toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => {
        'coins': coins,
        'gems': gems,
        'dragons': dragons,
        'eggs': eggs,
        'chests': chests,
        'furniture_catalog_ids': furnitureCatalogIds,
        'discovered_lineage_ids': discoveredLineageIds,
      };

  Map<String, dynamic> toShowcaseJson() {
    final favorite = dragons.cast<Map<String, dynamic>?>().firstWhere(
          (dragon) => dragon?['favorite'] == true,
          orElse: () => null,
        );
    return {
      'discovered_dragon_count': discoveredLineageIds.length,
      'favorite_dragon': favorite,
    };
  }
}

int _int(Object? value, {int fallback = 0}) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? fallback;
