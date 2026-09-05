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
  static const clientBuild = 10061;

  final EconomyRpcInvoker _invoke;

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
      chestInstanceId: response['chest_instance_id'] as String?,
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
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is List && raw.length == 1 && raw.single is Map) {
      return Map<String, dynamic>.from(raw.single as Map);
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

class ServerEconomyException implements Exception {
  const ServerEconomyException(this.code);

  final String code;

  @override
  String toString() => 'ServerEconomyException($code)';
}
