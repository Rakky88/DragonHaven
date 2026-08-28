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
  });

  test('disabled provider never grants a client-side purchase', () async {
    const provider = DisabledPurchaseProvider();

    expect(provider.isConfigured, isFalse);
    final result = await provider.startPurchase('gems_0050');
    expect(result.status, PurchaseAttemptStatus.disabled);
    expect(result.serverTransactionId, isNull);
    expect(result.safeErrorCode, 'purchases_not_configured');
  });
}
