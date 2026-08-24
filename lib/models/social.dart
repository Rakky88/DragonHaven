import '../providers/household_provider.dart';

enum FriendRequestDirection { incoming, outgoing }

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
