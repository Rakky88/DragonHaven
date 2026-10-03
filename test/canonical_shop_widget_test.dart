import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dragon_haven/config/rewarded_ads_config.dart';
import 'package:dragon_haven/models/chest.dart';
import 'package:dragon_haven/models/mystic_relic.dart';
import 'package:dragon_haven/models/rewarded_ad.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:dragon_haven/screens/canonical_inventory_screen.dart';
import 'package:dragon_haven/screens/canonical_eggs.dart';
import 'package:dragon_haven/screens/shop_hub_screen.dart';
import 'package:dragon_haven/services/canonical_game_session.dart';
import 'package:dragon_haven/services/canonical_game_snapshot.dart';
import 'package:dragon_haven/services/audio_service.dart';
import 'package:dragon_haven/services/canonical_rewarded_ads.dart';
import 'package:dragon_haven/services/rewarded_ads_platform.dart';
import 'package:dragon_haven/services/rewarded_ads_repository.dart';
import 'package:dragon_haven/theme/app_theme.dart';
import 'package:dragon_haven/widgets/chest_reveal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../tool/game_domain_probe.dart';
import 'support/canonical_ui_server.dart';

class _ShopNativeAd extends Fake implements RewardedAd {
  _ShopNativeAd(this.onShow);
  final void Function(_ShopNativeAd) onShow;
  @override
  FullScreenContentCallback<RewardedAd>? fullScreenContentCallback;
  @override
  Future<void> setServerSideOptions(
      ServerSideVerificationOptions options) async {}
  @override
  Future<void> dispose() async {}
  @override
  Future<void> show(
      {required OnUserEarnedRewardCallback onUserEarnedReward}) async {
    onShow(this);
    fullScreenContentCallback?.onAdShowedFullScreenContent?.call(this);
  }
}

class _ShopAdPlatform implements RewardedAdsPlatform {
  VoidCallback? onShow;
  _ShopNativeAd? shown;
  late final native = GoogleRewardedAdsPlatform.forTesting(
      loadAd: (_, callback) async => callback.onAdLoaded(_ShopNativeAd((ad) {
            shown = ad;
            onShow?.call();
          })));
  @override
  Future<LoadedRewardedAd> load(String unitId) => native.load(unitId);
  @override
  Future<RewardedAdsConsentState> initializeConsent() async =>
      const RewardedAdsConsentState(
          canRequestAds: true, privacyOptionsRequired: false);
  @override
  Future<RewardedAdsConsentState> showPrivacyOptions() => initializeConsent();
}

class _ShopAdRepository implements RewardedAdsRepository {
  final releaseIssue = Completer<void>();
  @override
  Future<RewardedAdsStatus> status() async => RewardedAdsStatus(
          enabled: true,
          dailyLimit: 3,
          nextResetAt: DateTime.now().add(const Duration(days: 1)),
          offers: {
            for (final currency in rewardedCurrencyPlacements)
              currency: RewardedAdOffer(
                  currency: currency,
                  reward: currency.fallbackReward,
                  claimedToday: 0,
                  remaining: 3)
          });
  @override
  Future<RewardedAdClaim> issue(RewardedAdPlacement currency,
      {String? trialOfferId}) async {
    await releaseIssue.future;
    return RewardedAdClaim(
        id: '22222222-2222-4222-8222-222222222222',
        token: 'test-opaque-claim',
        currency: currency,
        expiresAt: DateTime.now().add(const Duration(minutes: 15)));
  }

  @override
  Future<RewardedAdClaimStatus> claimStatus(String id) async =>
      const RewardedAdClaimStatus('issued');
  @override
  Future<bool> cancel(String id) async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<String, dynamic> fixture;
  setUpAll(() async {
    fixture = (await runGameDomainProbe())['state'] as Map<String, dynamic>;
    const fontPath = String.fromEnvironment('ECONOMY_UI_FONT');
    if (fontPath.isNotEmpty) {
      final icons =
          File('${File(fontPath).parent.path}/materialicons-regular.otf');
      await (FontLoader('MaterialIcons')
            ..addFont(icons
                .readAsBytes()
                .then((bytes) => ByteData.sublistView(bytes))))
          .load();
      await (FontLoader('Roboto')
            ..addFont(File(fontPath)
                .readAsBytes()
                .then((bytes) => ByteData.sublistView(bytes))))
          .load();
    }
  });
  late CanonicalUiServer server;
  late CanonicalGameSession session;
  late HouseholdProvider legacy;
  late Directory directory;
  final screen = GlobalKey();

  Future<void> prepare(WidgetTester tester) async {
    await tester.runAsync(() async {
      directory = await Directory.systemTemp.createTemp('dh-shop-widget-');
      server = CanonicalUiServer(
          jsonDecode(jsonEncode(fixture)) as Map<String, dynamic>);
      session = CanonicalGameSession(
          connection: CanonicalUiConnection(server), directory: directory);
      legacy = HouseholdProvider(persistenceEnabled: false)..pet.coins = 77777;
      await session.synchronize();
    });
    addTearDown(() async {
      session.dispose();
      legacy.dispose();
      await directory.delete(recursive: true);
    });
    await tester.binding.setSurfaceSize(const Size(320, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  Future<void> mount(WidgetTester tester, Widget child,
      {String locale = 'en',
      double scale = 1,
      CanonicalRewardedAds? ads}) async {
    final baseTheme = buildAppTheme();
    const visual = String.fromEnvironment('ECONOMY_UI_FONT');
    final theme = visual.isEmpty
        ? baseTheme
        : baseTheme.copyWith(
            textTheme: baseTheme.textTheme.apply(fontFamily: 'Roboto'),
            filledButtonTheme: FilledButtonThemeData(
                style: baseTheme.filledButtonTheme.style!.copyWith(
                    textStyle: const WidgetStatePropertyAll(TextStyle(
                        fontFamily: 'Roboto', fontWeight: FontWeight.w800)))),
          );
    await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: session),
          ChangeNotifierProvider.value(value: legacy),
          if (ads != null)
            ChangeNotifierProvider<CanonicalRewardedAds>(create: (_) => ads),
        ],
        child: MaterialApp(
          theme: theme,
          locale: Locale(locale),
          supportedLocales: const [Locale('en'), Locale('nl')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(scale),
                  disableAnimations: true),
              child: child!),
          home: RepaintBoundary(key: screen, child: Scaffold(body: child)),
        )));
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> waitForCommand(WidgetTester tester) async {
    // Match the transport's ten-second deadline. Parallel sprite tests can
    // briefly delay the real filesystem journal on Windows.
    for (var n = 0; n < 500 && session.busy; n++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
    }
    expect(session.busy, isFalse);
    await tester.pump();
  }

  Future<void> screenshot(WidgetTester tester, String name) async {
    const target = String.fromEnvironment('ECONOMY_UI_SCREENSHOTS');
    if (target.isEmpty) return;
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 400)));
    await tester.pump();
    await tester.runAsync(() async {
      final boundary =
          screen.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory(target).create(recursive: true);
      await File('$target/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  testWidgets(
      'ordinary shop predicts stock, survives lost reply and never spends the local save',
      (tester) async {
    await prepare(tester);
    final localBefore = jsonEncode(legacy.exportState());
    final coins = session.snapshot!.coins;
    await mount(tester, const ShopHubScreen(initialCategoryTab: 1));
    final buy = find.byKey(const Key('buy-title-chest'));
    await tester.ensureVisible(buy);
    await tester.pump(const Duration(milliseconds: 400));
    await screenshot(tester, 'shop-en-320');
    server.loseReply = true;
    final held = Completer<void>();
    server.hold = held.future;
    await tester.tap(buy);
    await tester.pump();
    expect(tester.widget<FilledButton>(buy).onPressed, isNotNull);
    expect(session.snapshot!.coins, coins - 500);
    expect(session.confirmedSnapshot!.coins, coins);
    // A duplicate tap shares the pending request; it never spends twice.
    await tester.tap(buy);
    await tester.pump();
    expect(session.snapshot!.coins, coins - 500);
    held.complete();
    await waitForCommand(tester);
    expect(find.textContaining('We could not confirm'), findsWidgets);
    expect(session.snapshot!.coins, coins);
    expect(server.receipts, hasLength(1));
    await tester.tap(find.byKey(const Key('economy-reconnect')));
    await waitForCommand(tester);
    expect(session.snapshot!.coins, coins - 500);
    expect(find.text('1 unopened chests'), findsOneWidget);
    expect(jsonEncode(legacy.exportState()), localBefore);
    expect(server.receipts, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Quill leads the relic shop and buys one bound copy for 100 gems',
      (tester) async {
    await prepare(tester);
    final gems = session.snapshot!.gems;
    final inventory = session.snapshot!.shop;
    final quills = inventory.relics['nameweaversQuill'] ?? 0;
    final bound = inventory.untradeableRelics['nameweaversQuill'] ?? 0;
    await mount(tester,
        const ShopHubScreen(initialCurrencyTab: 1, initialCategoryTab: 1));
    final quill = find.byKey(const Key('shop-relic-nameweaversQuill'));
    final next = find.byKey(const Key('shop-relic-moralPrism'));
    expect(tester.getTopLeft(quill).dy, lessThan(tester.getTopLeft(next).dy));
    final buy = find.byKey(const Key('buy-relic-nameweaversQuill'));
    expect(
        find.descendant(of: buy, matching: find.text('100')), findsOneWidget);
    await tester.ensureVisible(buy);
    await tester.pump(const Duration(milliseconds: 300));
    await screenshot(tester, 'quill-shop-en-320');
    await tester.tap(buy);
    await waitForCommand(tester);
    expect(session.snapshot!.gems, gems - 100);
    expect(session.snapshot!.shop.relics['nameweaversQuill'], quills + 1);
    expect(session.snapshot!.shop.untradeableRelics['nameweaversQuill'],
        bound + 1);
    expect(server.receipts, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'offline cache is browsable at large Dutch text; signout removes stock without fallback',
      (tester) async {
    await prepare(tester);
    server.online = false;
    await tester.runAsync(() async {
      await expectLater(
          session.synchronize(), throwsA(isA<CanonicalGameException>()));
    });
    await mount(tester, const ShopHubScreen(initialCategoryTab: 1),
        locale: 'nl', scale: 1.35);
    await screenshot(tester, 'shop-nl-offline-320-large');
    expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('buy-title-chest')))
            .onPressed,
        isNull);
    expect(find.text('77777'), findsNothing);
    (session.connection as CanonicalUiConnection).signOut();
    await tester.pump();
    expect(find.byKey(const Key('buy-title-chest')), findsNothing);
    expect(find.text('77777'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'inventory reveals a real server chest with no local grant or duplicate open',
      (tester) async {
    await prepare(tester);
    const audio = MethodChannel('nl.dragonhaven.app/audio');
    final audioCalls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(audio,
        (call) async {
      audioCalls.add(call);
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(audio, null));
    await HavenAudio.applyPreferences(
        musicEnabled: true,
        soundEffectsEnabled: true,
        musicStyle: HavenMusicStyle.classic);
    final localBefore = jsonEncode(legacy.exportState());
    await mount(tester, const CanonicalInventoryScreen());
    await screenshot(tester, 'inventory-en-320');
    await tester.tap(find.byKey(const Key('canonical-open-wooden')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(server.sent, isEmpty);
    await tester.tap(find.byKey(const Key('chest-reveal-tap-target')));
    await tester.tap(find.byKey(const Key('chest-reveal-tap-target')));
    await waitForCommand(tester);
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(const Key('chest-rewards')), findsOneWidget);
    expect(session.snapshot!.shop.chests['wooden'], 1);
    expect(server.receipts, hasLength(1));
    expect(
        audioCalls.where((call) =>
            call.method == 'playSound' &&
            (call.arguments as Map)['id'] == 'chest_wooden'),
        hasLength(1));
    expect(jsonEncode(legacy.exportState()), localBefore);
    await tester.tapAt(const Offset(8, 8));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'a failed chest reveal offers an exit and cannot dispatch another opening',
      (tester) async {
    await prepare(tester);
    var calls = 0;
    await mount(
        tester,
        Builder(
            builder: (context) => TextButton(
                onPressed: () {
                  showChestReveal(context, ChestTier.wooden,
                      openChest: () async {
                    calls++;
                    throw const CanonicalGameException(
                        'game_command_unavailable');
                  });
                },
                child: const Text('Open'))));
    await tester.tap(find.text('Open'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('chest-reveal-tap-target')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('chest-open-failed')), findsOneWidget);
    await tester.tap(find.byKey(const Key('chest-reveal-tap-target')));
    expect(calls, 1);
    await tester.ensureVisible(find.byKey(const Key('chest-error-close')));
    await tester.tap(find.byKey(const Key('chest-error-close')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('chest-reveal-tap-target')), findsNothing);
    expect(tester.takeException(), isNull);
  });
  for (final gems in [false, true]) {
    testWidgets(
        'preparation overlay is removed before native ad starts (gems=$gems)',
        (tester) async {
      await prepare(tester);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      final repository = _ShopAdRepository();
      final platform = _ShopAdPlatform();
      final ads = CanonicalRewardedAds(
          session: session,
          repository: repository,
          platform: platform,
          config: RewardedAdsConfig(
              mode: RewardedAdsMode.test,
              gemsAdUnitId: RewardedAdsConfig.androidRewardedTestUnitId,
              coinsAdUnitId: RewardedAdsConfig.androidRewardedTestUnitId,
              trialRefreshAdUnitId: RewardedAdsConfig.androidRewardedTestUnitId,
              platformSupported: true));
      await tester.runAsync(ads.initialize);
      await mount(
          tester,
          ShopHubScreen(
              initialCurrencyTab: gems ? 1 : 0,
              initialCategoryTab: gems ? 3 : 2),
          ads: ads);
      final card = find.byKey(Key('rewarded-chest-${gems ? 'gems' : 'coins'}'));
      final scroll = find
          .descendant(
              of: find.byKey(
                  PageStorageKey('${gems ? 'gems' : 'coins'}-packs-scroll')),
              matching: find.byType(Scrollable))
          .first;
      await tester.scrollUntilVisible(card, 250, scrollable: scroll);
      await tester.drag(scroll, const Offset(0, -240));
      await tester.pump(const Duration(milliseconds: 400));
      var nativeShows = 0;
      platform.onShow = () {
        nativeShows++;
        // Include offstage widgets: the preparation route must be disposed,
        // not merely hidden behind a native surface that has already started.
        expect(find.byType(Dialog, skipOffstage: false), findsNothing);
        expect(find.text('Preparing ads…', skipOffstage: false), findsNothing);
      };
      await tester
          .tap(find.descendant(of: card, matching: find.byType(FilledButton)));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Preparing ads…'), findsOneWidget);
      expect(nativeShows, 0);

      repository.releaseIssue.complete();
      // The SDK must wait for the overlay's disposal and the next painted frame.
      for (var frame = 0; frame < 6; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(nativeShows, 1);
      expect(find.byType(Dialog, skipOffstage: false), findsNothing);
      final currency =
          gems ? RewardedAdPlacement.gems : RewardedAdPlacement.coins;
      expect(ads.busy(currency), isTrue);
      expect(server.sent, isEmpty);
      platform.shown!.fullScreenContentCallback!
          .onAdDismissedFullScreenContent!(platform.shown!);
      await tester.pump(const Duration(seconds: 3));
      expect(ads.busy(currency), isFalse);
      expect(find.byType(Dialog, skipOffstage: false), findsNothing);
      expect(server.sent, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'free currency ad stays disabled under Buy with no reward command (gems=$gems)',
        (tester) async {
      await prepare(tester);
      await mount(
          tester,
          ShopHubScreen(
              initialCurrencyTab: gems ? 1 : 0,
              initialCategoryTab: gems ? 3 : 2));
      final card = find.byKey(Key('rewarded-chest-${gems ? 'gems' : 'coins'}'));
      final packScroll = find
          .descendant(
              of: find.byKey(
                  PageStorageKey('${gems ? 'gems' : 'coins'}-packs-scroll')),
              matching: find.byType(Scrollable))
          .first;
      await tester.scrollUntilVisible(card, 250, scrollable: packScroll);
      await tester.drag(packScroll, const Offset(0, -240));
      await tester.pump(const Duration(milliseconds: 400));
      await screenshot(tester, 'free-${gems ? 'gems' : 'coins'}-buy-en-320');
      final button =
          find.descendant(of: card, matching: find.byType(FilledButton));
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
      expect(
          find.descendant(of: card, matching: find.text(gems ? '15' : '150')),
          findsOneWidget);
      expect(
          find.descendant(
              of: card, matching: find.text(gems ? 'Free gems' : 'Free coins')),
          findsOneWidget);
      expect(find.descendant(of: card, matching: find.text('Watch an ad 3/3')),
          findsOneWidget);
      expect(server.sent, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
      'restored Open 10 waits for one durable batch and never grants locally',
      (tester) async {
    await prepare(tester);
    server.state['chestInventory']['wooden'] = 12;
    server.revision++;
    await tester.runAsync(session.synchronize);
    final localBefore = jsonEncode(legacy.exportState());
    await mount(tester, const CanonicalInventoryScreen());
    await tester.tap(find.byKey(const Key('canonical-open-ten-wooden')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(server.sent, isEmpty);
    await tester.tap(find.byKey(const Key('chest-reveal-tap-target')));
    await tester.tap(find.byKey(const Key('chest-reveal-tap-target')));
    await waitForCommand(tester);
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(session.snapshot!.shop.chests['wooden'], 2);
    expect(server.receipts, hasLength(1));
    expect(jsonEncode(legacy.exportState()), localBefore);
    expect(tester.takeException(), isNull);
  });
  testWidgets('long relic reward labels fit compact screens at large text',
      (tester) async {
    await prepare(tester);
    await mount(
        tester,
        Builder(
            builder: (context) => TextButton(
                onPressed: () => showChestReveal(context, ChestTier.wooden,
                    openChest: () async =>
                        ChestRewardBundle(tier: ChestTier.wooden, rewards: [
                          for (final relic in MysticRelic.values)
                            ChestReward(
                                tier: ChestTier.wooden,
                                coins: 1234,
                                gems: 20,
                                eggFound: false,
                                relicFound: relic)
                        ])),
                child: const Text('Preview reward'))),
        locale: 'nl',
        scale: 1.35);
    await tester.tap(find.text('Preview reward'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('chest-reveal-tap-target')));
    for (var i = 0; i < 32; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(const Key('chest-rewards')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'egg collection restores tags and previews its saved view preference at large text',
      (tester) async {
    await prepare(tester);
    final localBefore = jsonEncode(legacy.exportState());
    final total = session.snapshot!.eggs.length;
    final tagged = session.snapshot!.eggs.where((e) => e.tagged).length;
    await mount(tester, const CanonicalEggList(), locale: 'nl', scale: 1.35);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Niet getagd'));
    await tester.pump();
    expect(
        tester.widget<Text>(find.byKey(const Key('egg-inventory-count'))).data,
        startsWith('${total - tagged} '));
    await tester.tap(find.widgetWithText(ChoiceChip, 'Getagd'));
    await tester.pump();
    expect(
        tester.widget<Text>(find.byKey(const Key('egg-inventory-count'))).data,
        startsWith('$tagged '));
    expect(server.sent, isEmpty);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Alle'));
    await tester.pump();
    await screenshot(tester, 'v0540-eggs-nl-large');
    final before =
        session.snapshot!.profile.preferences['eggInventoryViewMode'];
    final held = Completer<void>();
    server.hold = held.future;
    await tester.tap(find.byKey(const Key('egg-inventory-view-toggle')));
    await tester.pump();
    expect(session.snapshot!.profile.preferences['eggInventoryViewMode'],
        before == 'list' ? 'tiles' : 'list');
    expect(
        session.confirmedSnapshot!.profile.preferences['eggInventoryViewMode'],
        before);
    held.complete();
    await waitForCommand(tester);
    expect(session.snapshot!.profile.preferences['eggInventoryViewMode'],
        before == 'list' ? 'tiles' : 'list');
    expect(server.receipts, hasLength(1));
    await screenshot(tester, 'v0540-eggs-list-nl-large');
    expect(jsonEncode(legacy.exportState()), localBefore);
    expect(tester.takeException(), isNull);
  });
}
