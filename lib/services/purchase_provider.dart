import '../models/supporter_pack.dart';

enum PurchaseCurrency { coins, gems }

class PurchaseProductDefinition {
  const PurchaseProductDefinition({
    required this.internalId,
    this.currency,
    required this.amount,
    required this.plannedEuroPriceCents,
    this.nonConsumable = false,
  });

  /// Stable DragonHaven ID. A future store adapter maps this to the external
  /// Google Play product ID; they deliberately do not have to be identical.
  final String internalId;
  final PurchaseCurrency? currency;
  final int amount;

  /// Intended base price for future Play Console setup and contract tests.
  /// The live UI must use Google Play's localized price, never this value.
  final int plannedEuroPriceCents;
  final bool nonConsumable;
}

abstract final class PurchaseCatalog {
  static const supporterPack = PurchaseProductDefinition(
    internalId: supporterPackInternalProductId,
    amount: 1,
    plannedEuroPriceCents: supporterPackPlannedEuroPriceCents,
    nonConsumable: true,
  );

  static const products = <PurchaseProductDefinition>[
    PurchaseProductDefinition(
      internalId: 'coins_0500',
      currency: PurchaseCurrency.coins,
      amount: 500,
      plannedEuroPriceCents: 100,
    ),
    PurchaseProductDefinition(
      internalId: 'coins_1200',
      currency: PurchaseCurrency.coins,
      amount: 1200,
      plannedEuroPriceCents: 200,
    ),
    PurchaseProductDefinition(
      internalId: 'coins_3200',
      currency: PurchaseCurrency.coins,
      amount: 3200,
      plannedEuroPriceCents: 500,
    ),
    PurchaseProductDefinition(
      internalId: 'coins_6500',
      currency: PurchaseCurrency.coins,
      amount: 6500,
      plannedEuroPriceCents: 1000,
    ),
    PurchaseProductDefinition(
      internalId: 'coins_15000',
      currency: PurchaseCurrency.coins,
      amount: 15000,
      plannedEuroPriceCents: 2000,
    ),
    PurchaseProductDefinition(
      internalId: 'coins_35000',
      currency: PurchaseCurrency.coins,
      amount: 35000,
      plannedEuroPriceCents: 3000,
    ),
    PurchaseProductDefinition(
      internalId: 'gems_0050',
      currency: PurchaseCurrency.gems,
      amount: 50,
      plannedEuroPriceCents: 100,
    ),
    PurchaseProductDefinition(
      internalId: 'gems_0120',
      currency: PurchaseCurrency.gems,
      amount: 120,
      plannedEuroPriceCents: 200,
    ),
    PurchaseProductDefinition(
      internalId: 'gems_0320',
      currency: PurchaseCurrency.gems,
      amount: 320,
      plannedEuroPriceCents: 500,
    ),
    PurchaseProductDefinition(
      internalId: 'gems_0650',
      currency: PurchaseCurrency.gems,
      amount: 650,
      plannedEuroPriceCents: 1000,
    ),
    PurchaseProductDefinition(
      internalId: 'gems_1500',
      currency: PurchaseCurrency.gems,
      amount: 1500,
      plannedEuroPriceCents: 2000,
    ),
    PurchaseProductDefinition(
      internalId: 'gems_3500',
      currency: PurchaseCurrency.gems,
      amount: 3500,
      plannedEuroPriceCents: 3000,
    ),
  ];

  static PurchaseProductDefinition? byInternalId(String internalId) {
    if (internalId == supporterPack.internalId) return supporterPack;
    for (final product in products) {
      if (product.internalId == internalId) return product;
    }
    return null;
  }
}

enum PurchaseAttemptStatus {
  disabled,
  cancelled,
  pending,
  verified,
  failed,
}

class PurchaseAttemptResult {
  const PurchaseAttemptResult({
    required this.status,
    required this.internalProductId,
    this.serverTransactionId,
    this.safeErrorCode,
  });

  final PurchaseAttemptStatus status;
  final String internalProductId;

  /// Server-authored identifier suitable for idempotency/support. This is
  /// never the raw Google purchase token.
  final String? serverTransactionId;
  final String? safeErrorCode;
}

/// Boundary for a future store implementation.
///
/// Implementations must send the provider receipt to a secure DragonHaven
/// server endpoint. They may return [PurchaseAttemptStatus.verified] only after
/// that endpoint validates and idempotently credits the server wallet. The
/// Flutter client itself must never grant coins or gems from a store callback.
abstract interface class PurchaseProvider {
  bool get isConfigured;

  Future<void> initialize();

  Future<PurchaseAttemptResult> startPurchase(String internalProductId);

  Future<void> reconcilePurchases();
}

class DisabledPurchaseProvider implements PurchaseProvider {
  const DisabledPurchaseProvider();

  @override
  bool get isConfigured => false;

  @override
  Future<void> initialize() async {}

  @override
  Future<PurchaseAttemptResult> startPurchase(
    String internalProductId,
  ) async =>
      PurchaseAttemptResult(
        status: PurchaseAttemptStatus.disabled,
        internalProductId: internalProductId,
        safeErrorCode: 'purchases_not_configured',
      );

  @override
  Future<void> reconcilePurchases() async {}
}
