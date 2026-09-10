import 'package:dragon_haven/screens/canonical_trials_screen.dart';
import 'package:dragon_haven/services/canonical_trial_run_source.dart';
// Isolated real-network staging test. Credentials exist only in this child
// process's environment; they are never compiled into an app or written to disk.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dragon_haven/config/online_config.dart';
import 'package:dragon_haven/services/canonical_game_intent.dart';
import 'package:dragon_haven/services/canonical_game_session.dart';
import 'package:dragon_haven/services/canonical_game_snapshot.dart';
import 'package:dragon_haven/services/canonical_game_transport.dart';
import 'package:dragon_haven/screens/shop_hub_screen.dart';
import 'package:dragon_haven/screens/canonical_inventory_screen.dart';
import 'package:dragon_haven/screens/canonical_dragons_screen.dart';
import 'package:dragon_haven/screens/canonical_adventures_screen.dart';
import 'package:dragon_haven/screens/canonical_house_screen.dart';
import 'package:dragon_haven/screens/canonical_school_screen.dart';
import 'package:dragon_haven/services/canonical_game_actions.dart';
import 'package:dragon_haven/widgets/expertise_score_badge.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/adventure.dart';
import 'package:dragon_haven/models/mystic_relic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

void require(bool condition, String code) {
  if (!condition) throw StateError(code);
}

class LostReplyClient extends http.BaseClient {
  LostReplyClient(this.shouldDrop, {this.action = 'purchase_title_chest'});
  final bool Function() shouldDrop;
  final String action;
  final http.Client inner = http.Client();
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = request is http.Request ? jsonDecode(request.body) : null;
    final result = await inner.send(request);
    if (body is Map && body['action'] == action && shouldDrop()) {
      require(result.statusCode == 200, 'client_probe_purchase_refused');
      await result.stream.drain<void>();
      throw TimeoutException('simulated lost receipt after real commit');
    }
    return result;
  }

  @override
  void close() => inner.close();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // This dedicated, guarded probe intentionally uses the real network, rather
  // than Flutter test's default all-400 HttpClient. It is not in the unit suite.
  HttpOverrides.global = null;
  test(
      'real staging client resumes committed requests and repairs corrupt journals',
      () async {
    final env = Platform.environment;
    require(
        env['STAGING_SUPABASE_PROJECT_REF'] == 'vtmjkhzalalozpfnbvsd' &&
            env['STAGING_SUPABASE_URL'] == CanonicalGameTransport.stagingUrl &&
            (env['STAGING_SUPABASE_PUBLISHABLE_KEY']?.isNotEmpty ?? false),
        'client_probe_staging_required');
    final raw = env['STAGING_GAME_CLIENT_SESSION'];
    require(raw != null, 'client_probe_session_missing');
    final sessionJson = jsonDecode(raw!) as Map<String, dynamic>;
    final owner = sessionJson['user']['id'] as String;
    require(
        sessionJson['user']['app_metadata']['dragonhaven_game_probe'] ==
            env['STAGING_GAME_PROBE_RUN'],
        'client_probe_synthetic_owner_required');
    final config = OnlineConfig(
        url: CanonicalGameTransport.stagingUrl,
        publishableKey: env['STAGING_SUPABASE_PUBLISHABLE_KEY']!,
        environment: OnlineEnvironment.staging);
    final auth = SupabaseClient(config.url, config.publishableKey,
        authOptions: const AuthClientOptions(autoRefreshToken: false));
    final directory =
        await Directory.systemTemp.createTemp('dh-staging-client-probe-');
    CanonicalGameSession? game;
    try {
      await auth.auth.recoverSession(raw);
      require((await auth.auth.getUser()).user?.id == owner,
          'client_probe_auth_mismatch');
      var drop = true;
      game = CanonicalGameSession(
          directory: directory,
          connection: CanonicalGameTransport.staging(auth, config,
              httpClientFactory: () => LostReplyClient(() {
                    if (!drop) return false;
                    drop = false;
                    return true;
                  })));
      await game.synchronize();
      stdout.writeln('PROBE: session_synchronized');
      require(game.canAct, 'client_probe_not_ready');
      final before = game.snapshot!;
      final titles =
          (before.data['inventory']['chestInventory']['title'] as int?) ?? 0;
      require(before.coins >= 100, 'client_probe_fixture_balance');
      var lost = false;
      try {
        final first = game.execute('purchase_title_chest', {});
        final second = game.execute('purchase_title_chest', {});
        require(identical(first, second), 'client_probe_duplicate_dispatch');
        await first;
      } on CanonicalGameException catch (error) {
        lost = error.code == 'game_command_unavailable';
      }
      require(lost && !game.canAct && !drop,
          'client_probe_lost_reply_not_retained');
      final pending = await game.intents.pending(owner);
      require(pending != null, 'client_probe_intent_missing');
      game.dispose();
      game = CanonicalGameSession(
          directory: directory,
          connection: CanonicalGameTransport.staging(auth, config));
      final receipt = await game.synchronize();
      final after = game.snapshot!;
      require(
          receipt?.requestId == pending!.requestId &&
              receipt?.replayed == true &&
              receipt?.result == 'purchased' &&
              after.coins == before.coins - 100 &&
              after.data['inventory']['chestInventory']['title'] ==
                  titles + 1 &&
              await game.intents.pending(owner) == null &&
              game.canAct,
          'client_probe_resume_failed');
      await game.intents.prepare(CanonicalGameIntent(
          ownerId: owner,
          requestId: const Uuid().v4(),
          action: 'purchase_title_chest',
          payload: {},
          minimumRevision: after.serverRevision));
      for (final suffix in ['', '.backup']) {
        await File('${directory.path}/intent-v2-$owner$suffix.json')
            .writeAsString('synthetic damage', flush: true);
      }
      await game.synchronize();
      final recovered = game.snapshot!;
      require(
          recovered.serverRevision > after.serverRevision &&
              recovered.stateHash == after.stateHash &&
              recovered.coins == after.coins &&
              await game.intents.pending(owner) == null &&
              game.canAct,
          'client_probe_recovery_failed');
      // Success is deliberately fixed text; no account, token, raw state or
      // private egg facts are included in test output.
      stdout.writeln(
          'PASS: real SDK/session/journals; one charge after lost reply; corrupt intent recovery without another purchase.');
    } finally {
      game?.dispose();
      await auth.dispose();
      await directory.delete(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 2)));

  testWidgets('ordinary shop and chest reveal use the real staging economy',
      (tester) async {
    final env = Platform.environment;
    require(
        env['STAGING_SUPABASE_PROJECT_REF'] == 'vtmjkhzalalozpfnbvsd' &&
            env['STAGING_SUPABASE_URL'] == CanonicalGameTransport.stagingUrl,
        'client_probe_staging_required');
    final raw = env['STAGING_GAME_CLIENT_SESSION'];
    require(raw != null, 'client_probe_session_missing');
    final sessionJson = jsonDecode(raw!) as Map<String, dynamic>;
    final owner = sessionJson['user']['id'] as String;
    require(
        sessionJson['user']['app_metadata']['dragonhaven_game_probe'] ==
            env['STAGING_GAME_PROBE_RUN'],
        'client_probe_synthetic_owner_required');
    final config = OnlineConfig(
        url: CanonicalGameTransport.stagingUrl,
        publishableKey: env['STAGING_SUPABASE_PUBLISHABLE_KEY']!,
        environment: OnlineEnvironment.staging);
    late SupabaseClient auth;
    late Directory directory;
    late CanonicalGameSession game;
    var loseAdventureClaim = false;
    await tester.runAsync(() async {
      stdout.writeln('PROBE: ui_auth_start');
      auth = SupabaseClient(config.url, config.publishableKey,
          authOptions: const AuthClientOptions(autoRefreshToken: false));
      await auth.auth.recoverSession(raw);
      require((await auth.auth.getUser()).user?.id == owner,
          'client_probe_auth_mismatch');
      directory = await Directory.systemTemp.createTemp('dh-staging-ui-probe-');
      game = CanonicalGameSession(
          directory: directory,
          connection: CanonicalGameTransport.staging(auth, config,
              httpClientFactory: () => LostReplyClient(() {
                    if (!loseAdventureClaim) return false;
                    loseAdventureClaim = false;
                    return true;
                  }, action: 'claim_adventure')));
      await game.synchronize();
      stdout.writeln('PROBE: ui_synchronized');
    });
    Future<void> settleCommand() async {
      for (var n = 0; n < 500 && game.busy; n++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 25)));
        await tester.pump();
      }
      if (game.busy || !game.canAct) {
        const known = {
          'game_command_unavailable',
          'game_snapshot_invalid',
          'game_snapshot_stale',
          'game_refresh_required',
          'game_intent_invalid',
          'game_attempt_unavailable',
          'game_attempt_time_invalid',
          'game_state_reconciliation_required',
          'game_result_invalid',
          'economy_rate_limited'
        };
        final code = game.busy
            ? 'busy'
            : known.contains(game.errorCode)
                ? game.errorCode!
                : 'unavailable';
        throw StateError('client_probe_ui_command_$code');
      }
    }

    Future<void> mount(Widget child) async {
      await tester.pumpWidget(ChangeNotifierProvider.value(
          value: game,
          child: MaterialApp(
              key: UniqueKey(),
              builder: (context, child) => MediaQuery(
                  data:
                      MediaQuery.of(context).copyWith(disableAnimations: true),
                  child: child!),
              home: Scaffold(body: child))));
      await tester.pump(const Duration(milliseconds: 400));
    }

    Future<void> tap(Finder finder) async {
      final list = find.byWidgetPredicate((widget) => const [
            Key('canonical-adventures-list'),
            Key('canonical-tower-list'),
            Key('canonical-rooms-list'),
            Key('canonical-room-editor-list')
          ].contains(widget.key));
      if (finder.evaluate().isEmpty && list.evaluate().isNotEmpty) {
        final scrollable =
            find.descendant(of: list, matching: find.byType(Scrollable)).first;
        tester.state<ScrollableState>(scrollable).position.jumpTo(0);
        await tester.pump();
        if (finder.evaluate().isEmpty) {
          await tester.scrollUntilVisible(finder, 200, scrollable: scrollable);
        }
      }
      require(finder.evaluate().length == 1,
          'client_probe_lifecycle_control_missing');
      await tester.ensureVisible(finder);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.runAsync(() => tester.tap(finder));
      // Route construction can start HTTP and filesystem work in initState.
      // Keep that work on the real clock, like the actual Flutter app.
      await tester.runAsync(() => tester.pump());
      await tester.pump(const Duration(milliseconds: 400));
    }

    Finder key(String name) => find.byKey(Key(name));
    Future<void> confirm() => tap(find.widgetWithText(FilledButton, 'Confirm'));

    try {
      await tester.binding.setSurfaceSize(const Size(430, 1000));
      final before = game.snapshot!;
      final initialChests = before.shop.chests['title'] ?? 0;
      final initialTitles = before.shop.titles.length;
      await mount(const ShopHubScreen(initialCategoryTab: 1));
      final purchase = find.byKey(const Key('buy-title-chest'));
      await tester.ensureVisible(purchase);
      await tester.pump(const Duration(milliseconds: 400));
      require(tester.widget<FilledButton>(purchase).onPressed != null,
          'client_probe_ui_buy_unavailable');
      // Start real filesystem/network callbacks outside the fake test clock.
      await tester.runAsync(() => tester.tap(purchase));
      await tester.pump();
      require(tester.widget<FilledButton>(purchase).onPressed == null,
          'client_probe_ui_double_tap_enabled');
      await settleCommand();
      stdout.writeln('PROBE: ui_purchase_settled');
      require(
          game.snapshot!.coins == before.coins - 100 &&
              game.snapshot!.shop.chests['title'] == initialChests + 1,
          'client_probe_ui_purchase_failed');
      await mount(const CanonicalInventoryScreen());
      final open = find.byKey(const Key('canonical-open-title'));
      await tester.ensureVisible(open);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(open);
      await tester.pump(const Duration(milliseconds: 400));
      require(game.snapshot!.shop.chests['title'] == initialChests + 1,
          'client_probe_ui_preview_consumed');
      await tester.runAsync(
          () => tester.tap(find.byKey(const Key('chest-reveal-tap-target'))));
      await settleCommand();
      stdout.writeln('PROBE: ui_reveal_settled');
      for (var n = 0; n < 30; n++) {
        // The callback (including reveal delays) runs on the real clock.
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      stdout.writeln('PROBE: ui_animation_finished');
      require(
          find.byKey(const Key('chest-rewards')).evaluate().length == 1 &&
              game.snapshot!.shop.chests['title'] == initialChests &&
              game.snapshot!.shop.titles.length == initialTitles + 1 &&
              game.snapshot!.coins == before.coins - 100 &&
              tester.takeException() == null,
          'client_probe_ui_reveal_failed');
      stdout.writeln(
          'PASS: real shop UI purchase, durable inventory and server chest reveal; one debit and one title.');

      final altarBefore = game.snapshot!.inventory.materials;
      final returnedEgg = game.snapshot!.eggs.firstWhere(
          (e) => e.kind == 'sinister' && e.returnBlockReason == null);
      await mount(const CanonicalInventoryScreen());
      await tap(find.text('Altar'));
      await tap(key('canonical-altar-choose'));
      await tap(key('canonical-egg-${returnedEgg.id}'));
      await tap(key('canonical-place-egg'));
      await tap(key('canonical-altar-return'));
      await confirm();
      require(
          find.textContaining('This is a Sinister egg').evaluate().length == 1,
          'client_probe_lifecycle_sinister_confirmation');
      await confirm();
      await settleCommand();
      await tester.pump();
      final returned = game.snapshot!;
      require(
          returned.egg(returnedEgg.id) == null &&
              returned.inventory.materials.fragments ==
                  altarBefore.fragments + 25 &&
              returned.inventory.materials.essence >= altarBefore.essence + 3 &&
              returned.inventory.materials.essence <= altarBefore.essence + 5 &&
              returned.inventory.materials.hearts >= altarBefore.hearts &&
              returned.inventory.materials.hearts <= altarBefore.hearts + 1,
          'client_probe_lifecycle_return_failed');
      stdout.writeln('PROBE: ui_altar_returned');
      await tap(key('canonical-craft-nameweaversQuill'));
      await settleCommand();
      await tap(key('canonical-craft-moralEcho'));
      await settleCommand();
      require(
          game.snapshot!.inventory.materials.fragments ==
                  returned.inventory.materials.fragments - 30 &&
              game.snapshot!.inventory.materials.essence ==
                  returned.inventory.materials.essence - 2,
          'client_probe_lifecycle_craft_cost');
      final keptEgg =
          game.snapshot!.eggs.firstWhere((e) => e.location == 'stash');
      await tap(find.text('Eggs'));
      await tap(key('canonical-egg-${keptEgg.id}'));
      await tap(key('canonical-reveal-moralEcho'));
      await confirm();
      await settleCommand();
      require(
          game.snapshot!.egg(keptEgg.id)!.revealedMoralAxis != null &&
              game.snapshot!.egg(keptEgg.id)!.revealedLineageId == null &&
              game.snapshot!.inventory.crafted['moralEcho'] == 0,
          'client_probe_lifecycle_discovery_failed');
      await tap(key('canonical-tag-egg'));
      await settleCommand();
      require(game.snapshot!.egg(keptEgg.id)!.returnBlockReason == 'egg_tagged',
          'client_probe_lifecycle_tag_failed');
      await tap(key('canonical-tag-egg'));
      await settleCommand();
      require(!game.snapshot!.egg(keptEgg.id)!.tagged,
          'client_probe_lifecycle_untag_failed');
      await tap(key('canonical-incubate-egg'));
      await confirm();
      await settleCommand();
      require(
          game.snapshot!.nest?.id == keptEgg.id &&
              tester
                      .widget<FilledButton>(find.descendant(
                          of: key('canonical-hatch-egg'),
                          matching: find.byType(FilledButton)))
                      .onPressed ==
                  null,
          'client_probe_lifecycle_incubation_failed');
      stdout.writeln('PROBE: ui_egg_incubating');
      final dragon = before.dragons.firstWhere((d) => d.owned);
      await mount(const CanonicalDragonsScreen());
      await tap(key('canonical-dragon-${dragon.id}'));
      await tap(key('canonical-name-dragon'));
      await tester.enterText(key('canonical-dragon-name-input'), 'UI Weaver');
      await tap(key('canonical-save-name'));
      await settleCommand();
      await tester.pump(const Duration(milliseconds: 400));
      require(
          game.snapshot!.dragon(dragon.id)!.name == 'UI Weaver' &&
              game.snapshot!.inventory.crafted['nameweaversQuill'] == 0,
          'client_probe_lifecycle_rename_failed');
      await tap(key('canonical-equip-twinstarBrooch'));
      await settleCommand();
      await tap(key('canonical-equip-emberheartBrooch'));
      await settleCommand();
      require(
          game.snapshot!.inventory.equippedOn(dragon.id) ==
                  MysticRelic.emberheartBrooch &&
              game.snapshot!.inventory.equipment[MysticRelic.twinstarBrooch] ==
                  null &&
              tester.takeException() == null,
          'client_probe_lifecycle_equipment_failed');
      stdout.writeln(
          'PASS: real lifecycle UI; Sinister confirmations and materials, crafting, hidden egg discovery, tags, incubation, Quill rename and exclusive equipment.');
      final beforeHighlight = game.snapshot!.dragon(dragon.id)!;
      await tap(key('canonical-highlight-${dragon.id}-might'));
      await settleCommand();
      await tap(key('canonical-highlight-${dragon.id}-spirit'));
      await settleCommand();
      await tap(key('canonical-highlight-${dragon.id}-spirit'));
      await settleCommand();
      final highlighted = game.snapshot!.dragon(dragon.id)!;
      require(
          highlighted.highlighted.length == 1 &&
              highlighted.highlighted.contains('might') &&
              highlighted.xp == beforeHighlight.xp &&
              highlighted.training.entries
                  .every((e) => beforeHighlight.training[e.key] == e.value),
          'client_probe_preferences_highlight');
      await mount(const CanonicalAdventuresScreen());
      await tap(key('canonical-refresh-adventures'));
      await settleCommand();
      require(
          game.snapshot!.adventures
              .offers(AdventureKind.mini)
              .contains('mini_1'),
          'client_probe_adventure_fixture_missing');
      await tap(key('canonical-select-adventure-mini_1'));
      await tap(key('canonical-expertise-info-${dragon.id}'));
      final mightInfo = find.byWidgetPredicate((w) =>
          w is ExpertiseScoreBadge &&
          w.dragonId == dragon.id &&
          w.focus == TrainingFocus.might &&
          w.iconSize == 30);
      require(tester.widget<ExpertiseScoreBadge>(mightInfo).highlighted,
          'client_probe_preferences_adventure_glow');
      await tap(find.widgetWithText(TextButton, 'Close'));
      await tap(key('canonical-adventure-dragon-${dragon.id}'));
      await tap(key('dragon-picker-draconomicon'));
      await tap(find.byType(BackButton));
      await tap(key('canonical-start-adventure'));
      await settleCommand();
      final run = game.snapshot!.adventures.runs.single;
      final beforeReward = game.snapshot!;
      require(
          run.revealedRewardId == null &&
              run.endsAt.difference(run.startedAt) ==
                  const Duration(minutes: 1),
          'client_probe_adventure_deadline_invalid');
      final early = await tester
          .runAsync(() => game.execute('claim_adventure', {'runId': run.id}));
      require(
          early?.result == null &&
              game.snapshot!.adventures.runs.length == 1 &&
              game.snapshot!.dragon(dragon.id)!.xp ==
                  beforeReward.dragon(dragon.id)!.xp,
          'client_probe_adventure_early_claim');
      stdout.writeln('PROBE: ui_adventure_waiting_for_server_deadline');
      final remaining = run.endsAt.difference(game.snapshot!.serverTime) +
          const Duration(seconds: 1);
      require(remaining <= const Duration(seconds: 65),
          'client_probe_adventure_wait_unbounded');
      final elapsed = Stopwatch()..start();
      while (elapsed.elapsed < remaining) {
        await tester
            .runAsync(() => Future<void>.delayed(const Duration(seconds: 1)));
        await tester.pump(const Duration(seconds: 1));
      }
      elapsed.stop();
      await tester.runAsync(() => game.synchronize());
      await tester.pump();
      require(!game.snapshot!.serverTime.isBefore(run.endsAt),
          'client_probe_adventure_not_due');
      loseAdventureClaim = true;
      await tap(key('canonical-claim-${run.id}'));
      for (var n = 0; n < 500 && game.busy; n++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 25)));
        await tester.pump();
      }
      require(!game.busy && !game.canAct && !loseAdventureClaim,
          'client_probe_adventure_reply_not_lost');
      await tap(key('economy-reconnect'));
      await settleCommand();
      final afterReward = game.snapshot!;
      final definition = AdventureCatalog.byId['mini_1']!;
      require(
          afterReward.adventures.runs.isEmpty &&
              afterReward.shop.chests['wooden'] ==
                  (beforeReward.shop.chests['wooden'] ?? 0) + 1 &&
              afterReward.dragon(dragon.id)!.xp ==
                  beforeReward.dragon(dragon.id)!.xp + definition.xp &&
              afterReward.dragon(dragon.id)!.training[definition.focus.name] ==
                  beforeReward
                          .dragon(dragon.id)!
                          .training[definition.focus.name]! +
                      2 * definition.statPoints,
          'client_probe_adventure_reward_wrong');
      stdout.writeln('PROBE: ui_adventure_claim_recovered');
      await tap(find.widgetWithText(ChoiceChip, 'Short'));
      final shortId =
          game.snapshot!.adventures.offers(AdventureKind.short).first;
      await tap(key('canonical-select-adventure-$shortId'));
      await tap(key('canonical-adventure-dragon-${dragon.id}'));
      await tap(key('canonical-start-adventure'));
      await settleCommand();
      final abortedId = game.snapshot!.adventures.runs.single.id;
      await tap(key('canonical-abort-$abortedId'));
      await confirm();
      await settleCommand();
      require(
          game.snapshot!.adventures.runs.isEmpty &&
              game.snapshot!.dragon(dragon.id)!.xp ==
                  afterReward.dragon(dragon.id)!.xp &&
              game.snapshot!.shop.chests['wooden'] ==
                  afterReward.shop.chests['wooden'],
          'client_probe_adventure_abort_reward');
      final offers =
          game.snapshot!.adventures.offers(AdventureKind.short).length;
      await tap(key('canonical-wayfinder-add'));
      await confirm();
      await settleCommand();
      require(
          game.snapshot!.shop.relics['wayfinderSigil'] == 0 &&
              game.snapshot!.adventures.offers(AdventureKind.short).length ==
                  offers + 1 &&
              tester.takeException() == null,
          'client_probe_adventure_wayfinder_failed');
      stdout.writeln(
          'PASS: real adventure UI; server deadline, early refusal, lost claim recovery, one reward, abort and Wayfinder.');
      final houseBalance = game.snapshot!.coins;
      await mount(const CanonicalHouseScreen());
      stdout.writeln('PROBE: ui_house_start');
      require(
          game.snapshot!.house.repairPrice(0) == 270 &&
              game.snapshot!.house.nextWardPrice == 150 &&
              game.snapshot!.house.nextFloorPrice == 2050,
          'client_probe_house_quotes');
      await tap(key('canonical-upgrade-ward'));
      await confirm();
      await settleCommand();
      await tap(key('canonical-repair-0'));
      await confirm();
      await settleCommand();
      require(
          game.snapshot!.house.wardLevel == 1 &&
              game.snapshot!.house.damagedFloors.isEmpty &&
              game.snapshot!.coins == houseBalance - 420,
          'client_probe_house_repair_cost');
      await tap(key('canonical-add-floor'));
      await tap(key('canonical-build-crystal'));
      await confirm();
      await settleCommand();
      require(
          game.snapshot!.house.floorRoomIds.length == 2 &&
              game.snapshot!.house.floorRoomIds.last == 'crystal' &&
              game.snapshot!.house.activeRoomId == 'crystal' &&
              game.snapshot!.coins == houseBalance - 2470,
          'client_probe_house_build_cost');
      await tap(find.widgetWithText(Tab, 'Rooms'));
      await tap(key('canonical-room-nest'));
      await settleCommand();
      await tap(key('canonical-room-crystal'));
      await settleCommand();
      require(
          game.snapshot!.house.activeRoomId == 'crystal' &&
              game.snapshot!.coins == houseBalance - 2470 &&
              tester.takeException() == null,
          'client_probe_house_room_selection');
      stdout.writeln(
          'PASS: real house UI; stored repair price, ward upgrade, floor purchase and free room selection.');
      await tester.runAsync(() =>
          game.execute('purchase_furniture', {'catalogId': 'moss_cushion'}));
      await tester.pump();
      final editingBalance = game.snapshot!.coins;
      await tap(key('canonical-edit-room-crystal'));
      await tap(key('canonical-select-furniture-moss_cushion'));
      final canvas = key('canonical-room-canvas');
      await tester.ensureVisible(canvas);
      await tester.pump();
      final rect = tester.getRect(canvas);
      await tester.runAsync(() => tester.tapAt(
          Offset(rect.left + rect.width * .3, rect.top + rect.height * .8)));
      await settleCommand();
      final placed = game.snapshot!.house.placements
          .singleWhere((p) => p.itemId == 'moss_cushion');
      require(placed.roomId == 'crystal' && (placed.x - .3).abs() < .001,
          'client_probe_room_placement');
      await tap(key('canonical-remove-furniture'));
      await settleCommand();
      require(
          !game.snapshot!.shop.placedItems.contains('moss_cushion') &&
              game.snapshot!.shop.ownedItems.contains('moss_cushion') &&
              game.snapshot!.coins == editingBalance,
          'client_probe_room_removal');
      await mount(const CanonicalHouseScreen());
      await tap(key('canonical-floor-up-0'));
      await settleCommand();
      require(
          game.snapshot!.house.floorRoomIds.join(',') == 'crystal,hearth' &&
              game.snapshot!.coins == editingBalance,
          'client_probe_floor_reorder');
      stdout.writeln(
          'PASS: real room editor; placement, removal retaining ownership and free floor reorder.');
      await mount(const CanonicalDragonsScreen());
      final other = game.snapshot!.dragons
          .firstWhere((d) => d.owned && d.id != dragon.id);
      final favoriteChanges =
          game.snapshot!.data['progress']['favoriteChanges'] as int;
      await tap(key('canonical-dragon-${other.id}'));
      await tap(key('canonical-favorite-dragon'));
      await settleCommand();
      require(
          game.snapshot!.dragons.where((d) => d.favorite).single.id ==
                  other.id &&
              game.snapshot!.data['progress']['favoriteChanges'] ==
                  favoriteChanges + 1,
          'client_probe_preferences_favorite');
      stdout.writeln(
          'PASS: real preferences UI; expertise highlights, adventure information and one favorite.');
      final roaming = game.snapshot!.dragon(other.id)!.roamsTower;
      await tap(key('canonical-roam-dragon'));
      await settleCommand();
      require(
          game.snapshot!.dragon(other.id)!.roamsTower == !roaming &&
              game.snapshot!.coins == editingBalance,
          'client_probe_roaming_desired_state');
      stdout.writeln(
          'PASS: real roaming UI; desired state preserved without wallet changes.');
      await tap(find.widgetWithText(TextButton, 'Close'));
      final beforeTreat = game.snapshot!;
      final treated = beforeTreat.dragon(beforeTreat.activeDragonId!)!;
      final treatXp =
          beforeTreat.inventory.equipment[MysticRelic.twinstarBrooch] ==
                  treated.id
              ? 50
              : 25;
      await tap(key('canonical-dragon-${treated.id}'));
      await tap(key('canonical-starlight-treat'));
      await tap(find.widgetWithText(FilledButton, 'Confirm'));
      await settleCommand();
      require(
          game.snapshot!.gems == beforeTreat.gems - 3 &&
              game.snapshot!.dragon(treated.id)!.xp == treated.xp + treatXp &&
              game.snapshot!.dragon(treated.id)!.joy ==
                  (treated.joy + 12).clamp(0, 100) &&
              game.snapshot!.dragon(treated.id)!.energy ==
                  (treated.energy + 12).clamp(0, 100) &&
              game.snapshot!.dragon(treated.id)!.comfort ==
                  (treated.comfort + 12).clamp(0, 100),
          'client_probe_care_treat');
      stdout.writeln(
          'PASS: real care UI; one treat debit, earned XP and bounded needs.');
      await tap(find.widgetWithText(TextButton, 'Close'));
      stdout.writeln('PROBE: ui_school_start');
      while (game.snapshot!.house.floorRoomIds.length < 5) {
        await tester
            .runAsync(() => CanonicalGameActions(game).buildFloor('hearth'));
        await tester.pump();
      }
      final pupil = game.snapshot!.dragon(game.snapshot!.activeDragonId!)!;
      final schoolXp =
          game.snapshot!.inventory.equipment[MysticRelic.twinstarBrooch] ==
                  pupil.id
              ? 30
              : 15;
      await mount(const CanonicalSchoolScreen());
      await tap(key('canonical-school-runeRush'));
      await tap(key('canonical-pupil-${pupil.id}'));
      await tap(key('canonical-school-enroll'));
      await tap(key('start-school-game'));
      await settleCommand();
      require(game.snapshot!.schoolAttempt?.gameId == 'runeRush',
          'client_probe_school_attempt');
      for (var i = 0; i < 30; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 90)));
        await tap(key('school-rune-rush-target'));
      }
      for (var i = 0;
          i < 400 &&
              (game.snapshot!.schoolAttempt != null ||
                  game.busy ||
                  find.text('Lesson complete').evaluate().isEmpty);
          i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pump();
      }
      require(
          game.snapshot!.schoolAttempt == null &&
              game.canAct &&
              find.text('Lesson complete').evaluate().length == 1 &&
              game.snapshot!.dragon(pupil.id)!.schoolStars['runeRush'] == 3 &&
              game.snapshot!.dragon(pupil.id)!.schoolAttempts['runeRush'] ==
                  1 &&
              game.snapshot!.dragon(pupil.id)!.xp == pupil.xp + schoolXp &&
              tester.takeException() == null,
          'client_probe_school_verified_reward');
      stdout.writeln(
          'PASS: real Academy UI; server-issued attempt, twenty-second input replay and one stars/XP reward.');
      stdout.writeln('PROBE: ui_trial_start');
      final trialDragon = game.snapshot!.dragon(pupil.id)!;
      await mount(const CanonicalTrialsScreen());
      await tap(key('choose-trial-staging-verified-ruin'));
      await tap(key('trial-dragon-${pupil.id}'));
      await settleCommand();
      stdout.writeln('PROBE: ui_trial_reserved');
      for (var i = 0;
          i < 250 && find.text('Continue').evaluate().isEmpty;
          i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pump(const Duration(milliseconds: 100));
        final surface = key('ruin-breaker-game');
        if (surface.evaluate().isNotEmpty &&
            game.snapshot!.trialAttempt != null) {
          await tester.runAsync(() => tester.tap(surface));
        }
      }
      await settleCommand();
      final trialResult = decodeTrialCompletion(
          game.snapshot!.data['trials']['lastResult']['result']);
      require(
          game.snapshot!.trialAttempt == null &&
              find.text('Continue').evaluate().length == 1 &&
              game.snapshot!.dragon(pupil.id)!.xp ==
                  trialDragon.xp + trialResult.reward.xp &&
              !game.snapshot!.trialOffers
                  .any((o) => o.id == 'staging-verified-ruin') &&
              tester.takeException() == null,
          'client_probe_trial_verified_reward');
      stdout.writeln(
          'PASS: real Trial selection and sprite game; server replay, consumed offer and exactly one reward.');
    } finally {
      stdout.writeln('PROBE: ui_cleanup_start');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(() async {
        game.dispose();
        await auth.dispose();
        await directory.delete(recursive: true);
      });
      await tester.binding.setSurfaceSize(null);
      stdout.writeln('PROBE: ui_cleanup_finished');
    }
  }, timeout: const Timeout(Duration(minutes: 5)));
}
