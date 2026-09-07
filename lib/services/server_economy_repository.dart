typedef EconomyRpcInvoker = Future<Object?> Function(
  String function,
  Map<String, dynamic> parameters,
);

enum VanityChestPurchaseOutcome {
  purchased,
  insufficientFunds,
  collectionComplete,
}

class VanityChestPurchaseReceipt {
  const VanityChestPurchaseReceipt({
    required this.outcome,
    required this.tier,
    required this.coins,
    required this.gems,
    required this.walletRevision,
    this.chestInstanceId,
    this.serverRevision,
  });

  final VanityChestPurchaseOutcome outcome;
  final String tier;
  final int coins;
  final int gems;
  final int walletRevision;
  final String? chestInstanceId;
  final int? serverRevision;

  bool get purchased => outcome == VanityChestPurchaseOutcome.purchased;
}

/// Dormant client boundary for the first server-owned economy mutation.
///
/// Callers must create one UUID per user intent and reuse that exact ID after a
/// timeout or reconnect. The database then returns the original receipt rather
/// than charging or granting twice. No production UI uses this repository while
/// [mutationsEnabled] is false.
class ServerEconomyRepository {
  const ServerEconomyRepository(this._invoke);

  static const mutationsEnabled = false;
  static const protocolVersion = 1;
  static const clientBuild = int.fromEnvironment(
    'DRAGONHAVEN_BUILD_NUMBER',
    defaultValue: 10067,
  );

  final EconomyRpcInvoker _invoke;

  Future<EconomyItemPurchaseReceipt> purchaseItem({
    required String requestId,
    required String kind,
    required String catalogId,
  }) async {
    if (!mutationsEnabled) {
      throw const ServerEconomyException('economy_client_disabled');
    }
    return purchaseItemForTesting(
        requestId: requestId, kind: kind, catalogId: catalogId);
  }

  Future<EconomyItemPurchaseReceipt> purchaseItemForTesting({
    required String requestId,
    required String kind,
    required String catalogId,
  }) async {
    if (!_uuidPattern.hasMatch(requestId) ||
        !const {'furniture', 'relic'}.contains(kind) ||
        !RegExp(r'^[A-Za-z0-9_.-]{1,100}$').hasMatch(catalogId)) {
      throw const ServerEconomyException('economy_request_invalid');
    }
    final response = _singleObject(await _invoke('purchase_economy_item', {
      'p_request_id': requestId,
      'p_item_kind': kind,
      'p_catalog_id': catalogId,
      'p_protocol_version': protocolVersion,
      'p_client_build': clientBuild,
    }));
    final outcome = switch (response['outcome']) {
      'purchased' => EconomyItemPurchaseOutcome.purchased,
      'already_owned' => EconomyItemPurchaseOutcome.alreadyOwned,
      'insufficient_funds' => EconomyItemPurchaseOutcome.insufficientFunds,
      _ => throw const ServerEconomyException('economy_response_invalid'),
    };
    final instanceId = response['instance_id'];
    if (response['item_kind'] != kind ||
        response['catalog_id'] != catalogId ||
        !const {'coins', 'gems'}.contains(response['currency']) ||
        (outcome != EconomyItemPurchaseOutcome.insufficientFunds &&
            (instanceId is! String || !_uuidPattern.hasMatch(instanceId))) ||
        (instanceId != null && instanceId is! String) ||
        (outcome == EconomyItemPurchaseOutcome.alreadyOwned &&
            kind != 'furniture')) {
      throw const ServerEconomyException('economy_response_invalid');
    }
    return EconomyItemPurchaseReceipt(
        outcome: outcome,
        kind: kind,
        catalogId: catalogId,
        instanceId: instanceId as String?,
        currency: response['currency'] as String,
        price: _requiredNonNegativeInt(response, 'price'),
        coins: _requiredNonNegativeInt(response, 'coins'),
        gems: _requiredNonNegativeInt(response, 'gems'),
        walletRevision: _requiredNonNegativeInt(response, 'wallet_revision'),
        serverRevision: _requiredNonNegativeInt(response, 'server_revision'));
  }

  Future<ChestOpeningReceipt> openChests({
    required String requestId,
    required List<String> chestIds,
  }) async {
    if (!mutationsEnabled) {
      throw const ServerEconomyException('economy_client_disabled');
    }
    return openChestsForTesting(requestId: requestId, chestIds: chestIds);
  }

  /// Contract exercise only; the database still enforces its own feature gate.
  Future<ChestOpeningReceipt> openChestsForTesting({
    required String requestId,
    required List<String> chestIds,
  }) async {
    final ids = List<String>.unmodifiable(chestIds);
    if (!_uuidPattern.hasMatch(requestId) ||
        ids.isEmpty ||
        ids.length > 10 ||
        ids.any((id) => !_uuidPattern.hasMatch(id)) ||
        ids.map((id) => id.toLowerCase()).toSet().length != ids.length) {
      throw const ServerEconomyException('economy_request_invalid');
    }
    final raw = await _invoke('open_chest_instances', {
      'p_request_id': requestId,
      'p_chest_ids': ids,
      'p_protocol_version': protocolVersion,
      'p_client_build': clientBuild,
    });
    final response = _singleObject(raw);
    final chests = response['chests'];
    if (chests is! List || chests.length != ids.length) {
      throw const ServerEconomyException('economy_response_invalid');
    }
    final rewards = <ServerChestReward>[];
    for (var index = 0; index < ids.length; index++) {
      final reward = ServerChestReward.fromJson(_singleObject(chests[index]));
      if (reward.chestId != ids[index].toLowerCase()) {
        throw const ServerEconomyException('economy_response_invalid');
      }
      rewards.add(reward);
    }
    return ChestOpeningReceipt(
      chests: List.unmodifiable(rewards),
      coins: _requiredNonNegativeInt(response, 'coins'),
      gems: _requiredNonNegativeInt(response, 'gems'),
      walletRevision: _requiredNonNegativeInt(response, 'wallet_revision'),
      serverRevision: _requiredNonNegativeInt(response, 'server_revision'),
    );
  }

  Future<VanityChestPurchaseReceipt> purchaseVanityChest({
    required String requestId,
    required String tier,
  }) async {
    if (!mutationsEnabled) {
      throw const ServerEconomyException('economy_client_disabled');
    }
    return _purchaseVanityChestForTesting(
      requestId: requestId,
      tier: tier,
    );
  }

  /// Visible for contract tests while the production feature flag stays off.
  Future<VanityChestPurchaseReceipt> purchaseVanityChestForTesting({
    required String requestId,
    required String tier,
  }) =>
      _purchaseVanityChestForTesting(requestId: requestId, tier: tier);

  Future<VanityChestPurchaseReceipt> _purchaseVanityChestForTesting({
    required String requestId,
    required String tier,
  }) async {
    final normalizedTier = tier.trim().toLowerCase();
    if (!_uuidPattern.hasMatch(requestId) ||
        !const {'portrait', 'title', 'music'}.contains(normalizedTier)) {
      throw const ServerEconomyException('economy_request_invalid');
    }
    final raw = await _invoke('purchase_vanity_chest', {
      'p_request_id': requestId,
      'p_tier': normalizedTier,
      'p_protocol_version': protocolVersion,
      'p_client_build': clientBuild,
    });
    final response = _singleObject(raw);
    final outcome = switch (response['outcome']) {
      'purchased' => VanityChestPurchaseOutcome.purchased,
      'insufficient_funds' => VanityChestPurchaseOutcome.insufficientFunds,
      'collection_complete' => VanityChestPurchaseOutcome.collectionComplete,
      _ => throw const ServerEconomyException('economy_response_invalid'),
    };
    final receipt = VanityChestPurchaseReceipt(
      outcome: outcome,
      tier: _requiredString(response, 'tier'),
      coins: _requiredNonNegativeInt(response, 'coins'),
      gems: _requiredNonNegativeInt(response, 'gems'),
      walletRevision: _requiredNonNegativeInt(response, 'wallet_revision'),
      chestInstanceId: response['chest_instance_id'] == null
          ? null
          : _requiredString(response, 'chest_instance_id'),
      serverRevision: _optionalNonNegativeInt(response['server_revision']),
    );
    if (receipt.tier != normalizedTier ||
        (receipt.purchased &&
            (receipt.chestInstanceId == null ||
                receipt.serverRevision == null))) {
      throw const ServerEconomyException('economy_response_invalid');
    }
    return receipt;
  }

  static Map<String, dynamic> _singleObject(Object? raw) {
    if (raw is Map && raw.keys.every((key) => key is String)) {
      return Map<String, dynamic>.from(raw);
    }
    if (raw is List && raw.length == 1 && raw.single is Map) {
      return _singleObject(raw.single);
    }
    throw const ServerEconomyException('economy_response_invalid');
  }

  static String _requiredString(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is String && value.isNotEmpty) return value;
    throw const ServerEconomyException('economy_response_invalid');
  }

  static int _requiredNonNegativeInt(
    Map<String, dynamic> map,
    String key,
  ) {
    final value = _optionalNonNegativeInt(map[key]);
    if (value != null) return value;
    throw const ServerEconomyException('economy_response_invalid');
  }

  static int? _optionalNonNegativeInt(Object? raw) {
    final value = raw is int ? raw : int.tryParse(raw?.toString() ?? '');
    return value != null && value >= 0 ? value : null;
  }

  static final _uuidPattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );
}

enum EconomyItemPurchaseOutcome { purchased, alreadyOwned, insufficientFunds }

class EconomyItemPurchaseReceipt {
  const EconomyItemPurchaseReceipt(
      {required this.outcome,
      required this.kind,
      required this.catalogId,
      required this.instanceId,
      required this.currency,
      required this.price,
      required this.coins,
      required this.gems,
      required this.walletRevision,
      required this.serverRevision});

  final EconomyItemPurchaseOutcome outcome;
  final String kind;
  final String catalogId;
  final String? instanceId;
  final String currency;
  final int price;
  final int coins;
  final int gems;
  final int walletRevision;
  final int serverRevision;
}

class ChestOpeningReceipt {
  const ChestOpeningReceipt(
      {required this.chests,
      required this.coins,
      required this.gems,
      required this.walletRevision,
      required this.serverRevision});

  final List<ServerChestReward> chests;
  final int coins;
  final int gems;
  final int walletRevision;
  final int serverRevision;
}

class ServerChestReward {
  const ServerChestReward(
      {required this.chestId,
      required this.tier,
      required this.opened,
      required this.coins,
      required this.gems,
      required this.items,
      this.egg});

  final String chestId;
  final String tier;
  final bool opened;
  final int coins;
  final int gems;
  final List<ServerChestItem> items;
  final ServerChestEgg? egg;

  factory ServerChestReward.fromJson(Map<String, dynamic> json) {
    final id =
        ServerEconomyRepository._requiredString(json, 'chest_instance_id');
    final tier = ServerEconomyRepository._requiredString(json, 'tier');
    final outcome = json['outcome'];
    final rawItems = json['items'];
    if (!ServerEconomyRepository._uuidPattern.hasMatch(id) ||
        !const {
          'wooden',
          'silver',
          'gold',
          'dragon',
          'mythical',
          'sinister',
          'special',
          'portrait',
          'title',
          'music'
        }.contains(tier) ||
        !const {'opened', 'collection_complete'}.contains(outcome) ||
        rawItems is! List ||
        rawItems.length > 2) {
      throw const ServerEconomyException('economy_response_invalid');
    }
    final result = ServerChestReward(
      chestId: id,
      tier: tier,
      opened: outcome == 'opened',
      coins: ServerEconomyRepository._requiredNonNegativeInt(json, 'coins'),
      gems: ServerEconomyRepository._requiredNonNegativeInt(json, 'gems'),
      items: List.unmodifiable(rawItems.map((item) => ServerChestItem.fromJson(
          ServerEconomyRepository._singleObject(item)))),
      egg: json['egg'] == null
          ? null
          : ServerChestEgg.fromJson(
              ServerEconomyRepository._singleObject(json['egg'])),
    );
    if (!result.opened &&
        (result.coins != 0 ||
            result.gems != 0 ||
            result.items.isNotEmpty ||
            result.egg != null ||
            !const {'portrait', 'title', 'music'}.contains(tier))) {
      throw const ServerEconomyException('economy_response_invalid');
    }
    return result;
  }
}

class ServerChestItem {
  const ServerChestItem(
      {required this.instanceId,
      required this.kind,
      required this.catalogId,
      this.reductionPercent});

  final String instanceId;
  final String kind;
  final String catalogId;
  final int? reductionPercent;

  factory ServerChestItem.fromJson(Map<String, dynamic> json) {
    final id = ServerEconomyRepository._requiredString(json, 'instance_id');
    final kind = ServerEconomyRepository._requiredString(json, 'kind');
    final catalogId =
        ServerEconomyRepository._requiredString(json, 'catalog_id');
    final percent = ServerEconomyRepository._optionalNonNegativeInt(
        json['reduction_percent']);
    if (!ServerEconomyRepository._uuidPattern.hasMatch(id) ||
        !const {'relic', 'portrait', 'title', 'music', 'emote'}
            .contains(kind) ||
        (catalogId == 'chronoshard' &&
            (kind != 'relic' ||
                percent == null ||
                percent < 10 ||
                percent > 90)) ||
        (catalogId != 'chronoshard' && json['reduction_percent'] != null)) {
      throw const ServerEconomyException('economy_response_invalid');
    }
    return ServerChestItem(
        instanceId: id,
        kind: kind,
        catalogId: catalogId,
        reductionPercent: percent);
  }
}

class ServerChestEgg {
  const ServerChestEgg(
      {required this.instanceId,
      required this.sinister,
      required this.incubationSeconds,
      this.specialEggId});

  final String instanceId;
  final bool sinister;
  final int incubationSeconds;
  final String? specialEggId;

  factory ServerChestEgg.fromJson(Map<String, dynamic> json) {
    final id = ServerEconomyRepository._requiredString(json, 'instance_id');
    final seconds = ServerEconomyRepository._requiredNonNegativeInt(
        json, 'incubation_seconds');
    final special = json['special_egg_id'];
    if (!ServerEconomyRepository._uuidPattern.hasMatch(id) ||
        json['sinister'] is! bool ||
        seconds < 60 ||
        seconds > 1209600 ||
        (special != null && (special is! String || special.isEmpty)) ||
        (special != null && json['sinister'] == true)) {
      throw const ServerEconomyException('economy_response_invalid');
    }
    return ServerChestEgg(
        instanceId: id,
        sinister: json['sinister'] as bool,
        incubationSeconds: seconds,
        specialEggId: special as String?);
  }
}

class ServerEconomyException implements Exception {
  const ServerEconomyException(this.code);

  final String code;

  @override
  String toString() => 'ServerEconomyException($code)';
}
