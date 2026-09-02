import 'package:dragon_haven/services/purchase_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('payment-ready catalog has twelve stable unique internal products', () {
    expect(PurchaseCatalog.products, hasLength(12));
    expect(
      PurchaseCatalog.products.map((product) => product.internalId).toSet(),
      hasLength(12),
    );
    expect(
      PurchaseCatalog.products
          .where((product) => product.currency == PurchaseCurrency.coins)
          .map((product) => product.amount),
      [500, 1200, 3200, 6500, 15000, 35000],
    );
    expect(
      PurchaseCatalog.products
          .where((product) => product.currency == PurchaseCurrency.gems)
          .map((product) => product.amount),
      [50, 120, 320, 650, 1500, 3500],
    );
    for (final currency in PurchaseCurrency.values) {
      expect(
        PurchaseCatalog.products
            .where((product) => product.currency == currency)
            .map((product) => product.plannedEuroPriceCents),
        [100, 200, 500, 1000, 2000, 3000],
      );
    }
  });

  test('disabled provider never grants a client-side purchase', () async {
    const provider = DisabledPurchaseProvider();

    expect(provider.isConfigured, isFalse);
    final result = await provider.startPurchase('gems_0050');
    expect(result.status, PurchaseAttemptStatus.disabled);
    expect(result.serverTransactionId, isNull);
    expect(result.safeErrorCode, 'purchases_not_configured');
  });

  test('dragon emote packs are three distinct non-consumable €1.99 products',
      () {
    expect(PurchaseCatalog.emotePackProducts, hasLength(3));
    expect(
      PurchaseCatalog.emotePackProducts
          .map((product) => product.internalId)
          .toSet(),
      hasLength(3),
    );
    for (final product in PurchaseCatalog.emotePackProducts) {
      expect(product.currency, isNull);
      expect(product.amount, 1);
      expect(product.plannedEuroPriceCents, 199);
      expect(product.nonConsumable, isTrue);
      expect(PurchaseCatalog.byInternalId(product.internalId), same(product));
    }
  });
}
