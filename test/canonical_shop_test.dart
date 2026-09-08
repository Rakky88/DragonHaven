import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dragon_haven/canonical_staging_app.dart';
import 'package:dragon_haven/config/online_config.dart';
import 'package:dragon_haven/models/chest.dart';
import 'package:dragon_haven/models/mystic_relic.dart';
import 'package:dragon_haven/models/shop_item.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:dragon_haven/services/canonical_game_actions.dart';
import 'package:dragon_haven/services/canonical_game_session.dart';
import 'package:dragon_haven/services/canonical_game_snapshot.dart';
import 'package:dragon_haven/services/shop_economy.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/game_domain_probe.dart';
import 'support/canonical_ui_server.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<String, dynamic> fixture;
  setUpAll(() async {
    fixture = (await runGameDomainProbe())['state'] as Map<String, dynamic>;
  });
  late CanonicalUiServer server;
  late CanonicalGameSession session;
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('dh-canonical-shop-');
    server = CanonicalUiServer(
        jsonDecode(jsonEncode(fixture)) as Map<String, dynamic>);
    session = CanonicalGameSession(
        connection: CanonicalUiConnection(server), directory: directory);
    await session.synchronize();
  });
  tearDown(() async {
    session.dispose();
    await directory.delete(recursive: true);
  });

  test(
      'staging entry refuses production and a staging label on an arbitrary server',
      () {
    for (final config in [
      OnlineConfig.fromEnvironment(),
      const OnlineConfig(
          url: 'https://example.invalid',
          publishableKey: 'public',
          environment: OnlineEnvironment.staging),
      const OnlineConfig(
          url: OnlineConfig.productionUrl,
          publishableKey: 'public',
          environment: OnlineEnvironment.staging)
    ]) {
      expect(() => requireCanonicalStaging(config),
          throwsA(isA<CanonicalGameException>()));
    }
  });

  test(
      'furniture, relic and vanity purchases display absolute authoritative ownership',
      () async {
    final start = session.snapshot!;
    final item = shopCatalog.firstWhere((i) =>
        i.currency == ItemCurrency.coins &&
        !start.shop.ownedItems.contains(i.id));
    expect(await ShopEconomy.canonical(session).purchaseOrEquip(item),
        PurchaseResult.purchased);
    expect(session.snapshot!.coins, start.coins - item.price);
    expect(ShopEconomy.canonical(session).owns(item), isTrue);
    final relic = MysticRelic.values.firstWhere((r) => r.isShopAvailable);
    final gems = session.snapshot!.gems;
    final relics = ShopEconomy.canonical(session).relicCount(relic);
    final locked = ShopEconomy.canonical(session).untradeableRelicCount(relic);
    expect(await ShopEconomy.canonical(session).purchaseRelic(relic),
        MysticRelicPurchaseResult.purchased);
    expect(session.snapshot!.gems, gems - relicShopGemPrice);
    expect(ShopEconomy.canonical(session).relicCount(relic), relics + 1);
    expect(ShopEconomy.canonical(session).untradeableRelicCount(relic),
        locked + 1);
    expect(await ShopEconomy.canonical(session).purchaseTitleChest(),
        TitleChestPurchaseResult.purchased);
    expect(ShopEconomy.canonical(session).chestCount(ChestTier.title), 1);
  });

  test(
      'two taps share one debit; a lost reply resumes the same action after restart',
      () async {
    final coins = session.snapshot!.coins;
    server.loseReply = true;
    final held = Completer<void>();
    server.hold = held.future;
    final shop = ShopEconomy.canonical(session);
    final first = shop.purchaseTitleChest();
    final second = shop.purchaseTitleChest();
    final failures = Future.wait([
      for (final call in [first, second])
        expectLater(call, throwsA(isA<CanonicalGameException>()))
    ]);
    held.complete();
    await failures;
    expect(server.receipts, hasLength(1));
    expect(server.sent, hasLength(1));
    expect(session.snapshot!.coins, coins);
    expect(session.canAct, isFalse);
    final original = server.sent.single.requestId;
    session.dispose();
    session = CanonicalGameSession(
        connection: CanonicalUiConnection(server), directory: directory);
    await session.synchronize();
    expect(session.snapshot!.coins, coins - titleChestCoinPrice);
    expect(server.sent.last.requestId, original);
    expect(server.receipts, hasLength(1));
  });

  test('old screen callbacks and background returns cannot authorize spending',
      () async {
    final old = ShopEconomy.canonical(session);
    await old.purchaseTitleChest();
    await expectLater(
        old.purchasePortraitChest(), throwsA(isA<CanonicalGameException>()));
    session.setForeground(false);
    session.setForeground(true);
    expect(session.canAct, isFalse);
    await expectLater(ShopEconomy.canonical(session).purchasePortraitChest(),
        throwsA(isA<CanonicalGameException>()));
    await session.synchronize();
    final oldAccount = ShopEconomy.canonical(session);
    (session.connection as CanonicalUiConnection).signOut();
    await expectLater(oldAccount.purchaseTitleChest(),
        throwsA(isA<CanonicalGameException>()));
    expect(ShopEconomy.canonical(session).available, isFalse);
    expect(server.sent, hasLength(1));
  });

  test(
      'a command finishing in the background leaves spending locked until a fresh read',
      () async {
    final held = Completer<void>();
    server.hold = held.future;
    final result = ShopEconomy.canonical(session).purchaseTitleChest();
    session.setForeground(false);
    held.complete();
    await result;
    session.setForeground(true);
    expect(session.canAct, isFalse);
    await session.synchronize();
    expect(session.canAct, isTrue);
  });

  test('real chest receipts update stock and decode only revealed rewards',
      () async {
    await ShopEconomy.canonical(session).purchaseTitleChest();
    final result =
        await CanonicalGameActions(session).openChests(ChestTier.title);
    expect(result!.openedCount, 1);
    expect(result.titles, hasLength(1));
    expect(session.snapshot!.shop.titles, contains(result.titles.single.id));
    expect(session.snapshot!.shop.chests['title'], 0);
    final eggs = session.snapshot!.eggs.length;
    final bundle = await CanonicalGameActions(session)
        .openChests(ChestTier.wooden, count: 2);
    expect(bundle!.openedCount, 2);
    expect(session.snapshot!.shop.chests['wooden'], 0);
    expect(session.snapshot!.eggs.length, eggs + bundle.mysteriousEggCount);
    expect(
        jsonEncode(session.snapshot!.toJson()), isNot(contains('hatchSeed')));
  });

  test(
      'malformed inventory cannot become display state or invent item ownership',
      () {
    for (final corrupt in <void Function(Map<String, dynamic>)>[
      (d) => d['inventory']['chestInventory']['title'] = -1,
      (d) => d['inventory']['relicInventory'] = null,
      (d) => d['inventory']['untradeableRelicInventory']['astralLens'] = 999,
      (d) => d['collection']['ownedTitleIds'] = ['same', 'same'],
      (d) => d['house']['activeRoomId'] = 'unknown_room',
      (d) => d['house']['placements'] = [
            {'itemId': 'unowned_item'}
          ],
    ]) {
      final wire = jsonDecode(jsonEncode(server.wire)) as Map<String, dynamic>;
      corrupt(wire['data'] as Map<String, dynamic>);
      expect(
          () => CanonicalGameSnapshot.parse(wire,
              expectedOwner: CanonicalUiServer.owner),
          throwsA(isA<CanonicalGameException>()));
    }
  });
}
