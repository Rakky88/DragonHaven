import '../providers/household_provider.dart';
import 'chest.dart';
import 'dragon_egg.dart';
import 'mystic_relic.dart';
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
    this.cavernFlightBest = 0,
    this.ruinBreakerBest = 0,
    this.runeweaverBest = 0,
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
  final int cavernFlightBest;
  final int ruinBreakerBest;
  final int runeweaverBest;

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
        cavernFlightBest: _int(json['favorite_dragon_cavern_flight_best']),
        ruinBreakerBest: _int(json['favorite_dragon_ruin_breaker_best']),
        runeweaverBest: _int(json['favorite_dragon_runeweaver_best']),
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
    this.achievementCount = 0,
    this.dragonCount = 0,
    this.discoveredForms = const [],
    this.prismaticForms = const [],
    this.cavernFlightBest = 0,
    this.ruinBreakerBest = 0,
    this.runeweaverBest = 0,
    this.favoriteDragon,
  });

  final String userId;
  final String keeperCode;
  final String displayName;
  final String title;
  final String portraitKey;
  final int discoveredDragonCount;
  final bool inventoryImported;
  final int achievementCount;
  final int dragonCount;
  final List<String> discoveredForms;
  final List<String> prismaticForms;
  final int cavernFlightBest;
  final int ruinBreakerBest;
  final int runeweaverBest;
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
      achievementCount: _int(json['achievement_count']),
      dragonCount: _int(json['dragon_count']),
      discoveredForms: _stringList(json['discovered_forms']),
      prismaticForms: _stringList(json['prismatic_forms']),
      cavernFlightBest: _int(json['cavern_flight_best']),
      ruinBreakerBest: _int(json['ruin_breaker_best']),
      runeweaverBest: _int(json['runeweaver_best']),
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

class SocialNotification {
  const SocialNotification({
    required this.id,
    required this.kind,
    required this.entityId,
    required this.actorDisplayName,
    required this.createdAt,
  });

  final String id;
  final String kind;
  final String entityId;
  final String actorDisplayName;
  final DateTime createdAt;

  factory SocialNotification.fromJson(Map<String, dynamic> json) =>
      SocialNotification(
        id: json['notification_id']?.toString() ?? '',
        kind: json['kind']?.toString() ?? '',
        entityId: json['entity_id']?.toString() ?? '',
        actorDisplayName: json['actor_display_name']?.toString() ?? 'Keeper',
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

class OnlineSocialSnapshot {
  const OnlineSocialSnapshot({
    required this.profile,
    required this.friends,
    required this.requests,
    required this.blockedKeepers,
    required this.groupAdventureStatus,
    required this.groupLobbies,
    required this.trades,
    required this.tradeInventory,
    required this.notifications,
  });

  final KeeperProfile profile;
  final List<KeeperProfile> friends;
  final List<FriendshipRequest> requests;
  final List<KeeperProfile> blockedKeepers;
  final GroupAdventureStatus groupAdventureStatus;
  final List<GroupAdventureLobby> groupLobbies;
  final List<TradeOffer> trades;
  final List<TradeInventoryItem> tradeInventory;
  final List<SocialNotification> notifications;

  factory OnlineSocialSnapshot.fromJson(Map<String, dynamic> json) {
    List<T> parseList<T>(
      String key,
      T Function(Map<String, dynamic>) parser,
    ) {
      final value = json[key];
      if (value is! List) return const [];
      return value
          .whereType<Map>()
          .map((row) => parser(Map<String, dynamic>.from(row)))
          .toList(growable: false);
    }

    final rawProfile = json['profile'];
    final rawGroupStatus = json['group_status'];
    if (rawProfile is! Map || rawGroupStatus is! Map) {
      throw const FormatException('Online snapshot is incomplete.');
    }
    return OnlineSocialSnapshot(
      profile: KeeperProfile.fromJson(Map<String, dynamic>.from(rawProfile)),
      friends: parseList('friends', KeeperProfile.fromJson),
      requests: parseList('requests', FriendshipRequest.fromJson),
      blockedKeepers: parseList('blocked_keepers', KeeperProfile.fromJson),
      groupAdventureStatus: GroupAdventureStatus.fromJson(
        Map<String, dynamic>.from(rawGroupStatus),
      ),
      groupLobbies: parseList('group_lobbies', GroupAdventureLobby.fromJson),
      trades: parseList('trades', TradeOffer.fromJson),
      tradeInventory: parseList('trade_inventory', TradeInventoryItem.fromJson),
      notifications: parseList('notifications', SocialNotification.fromJson),
    );
  }
}

class AccountAuthResult {
  const AccountAuthResult({required this.requiresEmailConfirmation});

  final bool requiresEmailConfirmation;
}

class CloudGameSave {
  const CloudGameSave({
    required this.revision,
    required this.state,
    required this.updatedAt,
    required this.deviceId,
  });

  final int revision;
  final Map<String, dynamic> state;
  final DateTime updatedAt;
  final String deviceId;

  factory CloudGameSave.fromJson(Map<String, dynamic> json) {
    final rawState = json['state'];
    if (rawState is! Map) {
      throw const FormatException('Cloud save has no valid game state.');
    }
    return CloudGameSave(
      revision: _int(json['revision']),
      state: Map<String, dynamic>.from(rawState),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      deviceId: json['device_id']?.toString() ?? '',
    );
  }
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

enum TradeItemKind { egg, chest, relic }

class TradeItem {
  const TradeItem({
    required this.kind,
    required this.key,
    required this.data,
  });

  final TradeItemKind kind;
  final String key;
  final Map<String, dynamic> data;

  factory TradeItem.fromJson(Map<String, dynamic> json) {
    final kind = TradeItemKind.values.firstWhere(
      (value) => value.name == json['kind']?.toString(),
      orElse: () => TradeItemKind.egg,
    );
    return TradeItem(
      kind: kind,
      key: json['key']?.toString() ?? '',
      data: json['data'] is Map
          ? Map<String, dynamic>.from(json['data'] as Map)
          : const {},
    );
  }

  factory TradeItem.egg(DragonEgg egg) => TradeItem(
        kind: TradeItemKind.egg,
        key: egg.id,
        data: egg.toJson(),
      );

  factory TradeItem.chest(ChestTier tier) => TradeItem(
        kind: TradeItemKind.chest,
        key: tier.name,
        data: const {},
      );

  factory TradeItem.relic(MysticRelic relic) => TradeItem(
        kind: TradeItemKind.relic,
        key: relic.name,
        data: const {},
      );

  Map<String, dynamic> toRequestJson() => {'kind': kind.name, 'key': key};

  DragonEgg? get egg => kind == TradeItemKind.egg
      ? DragonEgg.fromJson({...data, 'id': key})
      : null;
  ChestTier? get chestTier => kind == TradeItemKind.chest
      ? ChestTier.values.cast<ChestTier?>().firstWhere(
            (value) => value?.name == key,
            orElse: () => null,
          )
      : null;
  MysticRelic? get relic => kind == TradeItemKind.relic
      ? MysticRelic.values.cast<MysticRelic?>().firstWhere(
            (value) => value?.name == key,
            orElse: () => null,
          )
      : null;

  bool get isTradeable => switch (kind) {
        TradeItemKind.egg => egg != null,
        TradeItemKind.chest => chestTier?.isTradeable == true,
        TradeItemKind.relic => relic != null,
      };
}

class TradeInventoryItem {
  const TradeInventoryItem({required this.item, required this.available});

  final TradeItem item;
  final int available;

  factory TradeInventoryItem.fromJson(Map<String, dynamic> json) {
    final rawData = json['item_data'];
    return TradeInventoryItem(
      item: TradeItem.fromJson({
        'kind': json['item_type'],
        'key': json['item_key'],
        'data': rawData is Map ? Map<String, dynamic>.from(rawData) : const {},
      }),
      available: _int(json['available'], fallback: 1),
    );
  }
}

class TradeOffer {
  const TradeOffer({
    required this.id,
    required this.status,
    required this.initiatorId,
    required this.recipientId,
    required this.otherKeeper,
    required this.amInitiator,
    required this.initiatorItem,
    required this.recipientItem,
    required this.myAcknowledged,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String status;
  final String initiatorId;
  final String recipientId;
  final KeeperProfile otherKeeper;
  final bool amInitiator;
  final TradeItem initiatorItem;
  final TradeItem? recipientItem;
  final bool myAcknowledged;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isActive =>
      status == 'awaiting_recipient' || status == 'awaiting_initiator';
  bool get isCompleted => status == 'completed';
  bool get needsMyResponse =>
      (!amInitiator && status == 'awaiting_recipient') ||
      (amInitiator && status == 'awaiting_initiator');
  TradeItem get myItem => amInitiator ? initiatorItem : recipientItem!;
  TradeItem get receivedItem => amInitiator ? recipientItem! : initiatorItem;

  factory TradeOffer.fromJson(Map<String, dynamic> json) {
    final rawInitiator = json['initiator_item'];
    final rawRecipient = json['recipient_item'];
    return TradeOffer(
      id: json['trade_id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'awaiting_recipient',
      initiatorId: json['initiator_id']?.toString() ?? '',
      recipientId: json['recipient_id']?.toString() ?? '',
      otherKeeper: KeeperProfile.fromJson(json),
      amInitiator: json['am_initiator'] == true,
      initiatorItem: TradeItem.fromJson(rawInitiator is Map
          ? Map<String, dynamic>.from(rawInitiator)
          : const {}),
      recipientItem: rawRecipient is Map
          ? TradeItem.fromJson(Map<String, dynamic>.from(rawRecipient))
          : null,
      myAcknowledged: json['my_acknowledged'] == true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class TradeSettlement {
  const TradeSettlement({
    required this.tradeId,
    required this.sent,
    required this.received,
  });

  final String tradeId;
  final TradeItem sent;
  final TradeItem received;
}

class OnlineInventorySnapshot {
  const OnlineInventorySnapshot({
    required this.coins,
    required this.gems,
    required this.dragons,
    required this.eggs,
    required this.chests,
    required this.relics,
    required this.furnitureCatalogIds,
    required this.discoveredLineageIds,
    required this.discoveredForms,
    required this.prismaticForms,
    required this.achievementCount,
  });

  final int coins;
  final int gems;
  final List<Map<String, dynamic>> dragons;
  final List<Map<String, dynamic>> eggs;
  final Map<String, int> chests;
  final Map<String, int> relics;
  final List<String> furnitureCatalogIds;
  final List<String> discoveredLineageIds;
  final List<String> discoveredForms;
  final List<String> prismaticForms;
  final int achievementCount;

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
              'trial_high_scores': dragon.trialHighScores,
            })
        .toList(growable: false);
    final eggs = <Map<String, dynamic>>[
      if (game.pet.isEgg)
        {
          'client_id': game.pet.id,
          'lineage_id': game.pet.lineageId,
          'acquired_at': game.pet.acquiredAt.toUtc().toIso8601String(),
          'hatch_seed': game.pet.hatchSeed,
          'prismatic': game.pet.prismatic,
          'law_axis': game.pet.lawAxis.name,
          'moral_axis': game.pet.moralAxis.name,
          'size_factor': game.pet.sizeFactor,
          'incubation_minutes': game.pet.incubationMinutes,
          'sinister': game.pet.sinister,
          'xp': game.pet.xp,
          'tradeable': false,
        },
      if (game.incubatingEgg case final egg?)
        {
          'client_id': egg.id,
          'lineage_id': egg.lineageId,
          'acquired_at': egg.acquiredAt.toUtc().toIso8601String(),
          'hatch_seed': egg.hatchSeed,
          'prismatic': egg.prismatic,
          'law_axis': egg.lawAxis.name,
          'moral_axis': egg.moralAxis.name,
          'size_factor': egg.sizeFactor,
          'incubation_minutes': egg.incubationMinutes,
          'sinister': egg.sinister,
          'xp': egg.xp,
          'tradeable': false,
        },
      for (final egg in game.eggStash)
        {
          'client_id': egg.id,
          'lineage_id': egg.lineageId,
          'acquired_at': egg.acquiredAt.toUtc().toIso8601String(),
          'hatch_seed': egg.hatchSeed,
          'prismatic': egg.prismatic,
          'law_axis': egg.lawAxis.name,
          'moral_axis': egg.moralAxis.name,
          'size_factor': egg.sizeFactor,
          'incubation_minutes': egg.incubationMinutes,
          'sinister': egg.sinister,
          'xp': egg.xp,
          'tradeable': true,
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
      relics: {
        for (final relic in MysticRelic.values)
          relic.name: game.gameplayRelicCount(relic),
      },
      furnitureCatalogIds: game.ownedItemIds.toList(growable: false),
      discoveredLineageIds: {
        ...game.discoveredForms.map((key) => key.split(':').first),
        ...game.prismaticForms.map((key) => key.split(':').first),
      }.toList(growable: false),
      discoveredForms: game.discoveredForms.toList(growable: false),
      prismaticForms: game.prismaticForms.toList(growable: false),
      achievementCount: game.unlockedAchievementIds.length,
    );
  }

  Map<String, dynamic> toJson() => {
        'coins': coins,
        'gems': gems,
        'dragons': dragons,
        'eggs': eggs,
        'chests': chests,
        'relics': relics,
        'furniture_catalog_ids': furnitureCatalogIds,
        'discovered_lineage_ids': discoveredLineageIds,
      };

  Map<String, dynamic> toTradeJson() => {
        'eggs': [
          for (final egg in eggs)
            if (egg['tradeable'] == true) egg,
        ],
        'chests': {
          for (final entry in chests.entries)
            if (ChestTier.values.any(
              (tier) => tier.name == entry.key && tier.isTradeable,
            ))
              entry.key: entry.value,
        },
        'relics': relics,
      };

  Map<String, dynamic> toShowcaseJson() {
    final favorite = dragons.cast<Map<String, dynamic>?>().firstWhere(
          (dragon) => dragon?['favorite'] == true,
          orElse: () => null,
        );
    return {
      'discovered_dragon_count': discoveredLineageIds.length,
      'dragon_count': dragons.length,
      'achievement_count': achievementCount,
      'discovered_forms': discoveredForms,
      'prismatic_forms': prismaticForms,
      'trial_high_scores': {
        'cavernFlight': _bestDragonTrialScore('cavernFlight'),
        'ruinBreaker': _bestDragonTrialScore('ruinBreaker'),
        'runeweaver': _bestDragonTrialScore('runeweaver'),
      },
      'favorite_dragon': favorite,
    };
  }

  int _bestDragonTrialScore(String key) => dragons.fold<int>(
        0,
        (best, dragon) {
          final scores = dragon['trial_high_scores'];
          if (scores is! Map) return best;
          return best > _int(scores[key]) ? best : _int(scores[key]);
        },
      );
}

int _int(Object? value, {int fallback = 0}) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? fallback;

List<String> _stringList(Object? value) => value is List
    ? value.map((entry) => entry.toString()).toList(growable: false)
    : const [];
