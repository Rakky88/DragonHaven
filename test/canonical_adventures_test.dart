import 'package:dragon_haven/widgets/event_progress_bar.dart';
import 'dart:convert';
import 'dart:io';

import 'package:dragon_haven/models/adventure.dart';
import 'package:dragon_haven/models/mystic_relic.dart';
import 'package:dragon_haven/services/canonical_game_actions.dart';
import 'package:dragon_haven/services/canonical_game_session.dart';
import 'package:dragon_haven/services/canonical_game_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dragon_haven/screens/canonical_adventures_screen.dart';

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
  CanonicalGameActions actions() => CanonicalGameActions(session);
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('dh-adventures-');
    server = CanonicalUiServer(
        jsonDecode(jsonEncode(fixture)) as Map<String, dynamic>);
    server.state['relicInventory']['wayfinderSigil'] = 2;
    final second =
        jsonDecode(jsonEncode(server.state['pet'])) as Map<String, dynamic>;
    second['id'] = '22222222-2222-4222-8222-222222222222';
    second['name'] = 'Second probe';
    second['favorite'] = false;
    server.state['sanctuaryDragons'] = [second];
    session = CanonicalGameSession(
        connection: CanonicalUiConnection(server), directory: directory);
    await session.synchronize();
    await actions().refresh();
  });
  tearDown(() async {
    session.dispose();
    await directory.delete(recursive: true);
  });
  Matcher error(String code) => throwsA(
      isA<CanonicalGameException>().having((e) => e.code, 'fixed error', code));
  Future<void> restart() async {
    session.dispose();
    session = CanonicalGameSession(
        connection: CanonicalUiConnection(server), directory: directory);
    await session.synchronize();
  }

  testWidgets('event replaces its adventure offer with points progress',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.runAsync(() async {
      server.state['seasonalEventPreviewExpiresAt'] = {
        'sunwake_summer_sea':
            server.now.add(const Duration(days: 2)).toIso8601String()
      };
      server.revision++;
      await session.synchronize();
    });
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: session,
        child: const MaterialApp(
            home: Scaffold(body: CanonicalAdventuresScreen()))));
    await tester.tap(find.widgetWithText(ChoiceChip, 'Special'));
    await tester.pump(const Duration(milliseconds: 1200));
    expect(
        find.byKey(Key(
            'canonical-select-adventure-${AdventureCatalog.sunwakeFestival.id}')),
        findsNothing);
    expect(find.text('0 / 2000 points'), findsNothing);
    expect(find.byType(EventProgressBar), findsOneWidget);
    expect(
        tester
            .widget<EventProgressBar>(find.byType(EventProgressBar))
            .progress
            .fraction,
        0);
    await tester.pumpWidget(const SizedBox());
  });

  test('start and reward recover lost replies; no early claim or second grant',
      () async {
    final before = session.snapshot!;
    final dragon = before.dragons.first;
    final id = before.adventures.offers(AdventureKind.mini).first;
    final definition = AdventureCatalog.byId[id]!;
    server.loseReply = true;
    await expectLater(actions().startAdventure(id, dragon.id),
        error('game_command_unavailable'));
    await restart();
    final run = session.snapshot!.adventures.runs.single;
    expect(run.revealedReward, isNull);
    expect(session.snapshot!.dragon(dragon.id)!.xp, dragon.xp);
    await expectLater(
        actions().claimAdventure(run.id), error('game_action_unavailable'));
    expect(session.snapshot!.adventures.runs, hasLength(1));
    server.now = run.endsAt.add(const Duration(seconds: 1));
    final stock = session.snapshot!.shop.chests['wooden'] ?? 0;
    server.loseReply = true;
    await expectLater(
        actions().claimAdventure(run.id), error('game_command_unavailable'));
    await restart();
    expect(session.snapshot!.adventures.runs, isEmpty);
    expect(session.snapshot!.shop.chests['wooden'], stock + 1);
    expect(session.snapshot!.dragon(dragon.id)!.xp, dragon.xp + definition.xp);
    expect(session.snapshot!.dragon(dragon.id)!.training[definition.focus.name],
        dragon.training[definition.focus.name]! + definition.statPoints);
    expect(session.snapshot!.dragon(dragon.id)!.adventureId, isNull);
    await expectLater(
        actions().claimAdventure(run.id), error('game_action_unavailable'));
    expect(session.snapshot!.shop.chests['wooden'], stock + 1);
  });

  test(
      'runs sort by ending time, refuse a busy dragon and abort without reward',
      () async {
    final view = session.snapshot!;
    final dragon = view.dragons.first;
    final long = view.adventures.offers(AdventureKind.long).first;
    final mini = view.adventures.offers(AdventureKind.mini).first;
    await actions().startAdventure(long, dragon.id);
    await expectLater(actions().startAdventure(mini, dragon.id),
        error('game_action_unavailable'));
    await actions().startAdventure(mini, view.dragons.last.id);
    final sorted = session.snapshot!.adventures.orderedRuns;
    expect(sorted.map((r) => r.adventureId), [mini, long]);
    final stock = session.snapshot!.shop.chests;
    final xp = session.snapshot!.dragon(dragon.id)!.xp;
    await actions().abortAdventure(sorted.last.id);
    expect(session.snapshot!.adventures.runs.single.adventureId, mini);
    expect(session.snapshot!.dragon(dragon.id)!.adventureId, isNull);
    expect(session.snapshot!.dragon(dragon.id)!.xp, xp);
    expect(session.snapshot!.shop.chests, stock);
  });

  test(
      'Wayfinder replay keeps one replacement and refuses capacity or stale selection',
      () async {
    final old = actions();
    final id = session.snapshot!.adventures.offers(AdventureKind.short).first;
    server.loseReply = true;
    await expectLater(
        actions().useWayfinder(AdventureKind.short, replaceAdventureId: id),
        error('game_command_unavailable'));
    await restart();
    final offers = session.snapshot!.adventures.offers(AdventureKind.short);
    expect(offers, hasLength(3));
    expect(offers, isNot(contains(id)));
    expect(session.snapshot!.inventory.usableRelics[MysticRelic.wayfinderSigil],
        1);
    await expectLater(actions().useWayfinder(AdventureKind.short),
        error('game_action_unavailable'));
    expect(session.snapshot!.adventures.offers(AdventureKind.short), offers);
    expect(session.snapshot!.inventory.usableRelics[MysticRelic.wayfinderSigil],
        1);
    // Capture a current selection and then change the available list.
    final selected = actions();
    await actions().dismissAdventure(offers.first);
    await expectLater(
        selected.startAdventure(
            offers.first, session.snapshot!.dragons.first.id),
        error('game_refresh_required'));
    expect(old.observed!.adventures.runs, isEmpty);
  });

  test(
      'malformed adventure ownership, dates, duplicates and premature rewards are rejected',
      () async {
    await actions().startAdventure(
        session.snapshot!.adventures.offers(AdventureKind.mini).first,
        session.snapshot!.dragons.first.id);
    for (final corrupt in <void Function(Map<String, dynamic>)>[
      (d) => d['adventures']['runs'][0]['dragonId'] = 'absent',
      (d) => d['adventures']['runs'][0]['endsAt'] = '2000-01-01T00:00:00Z',
      (d) => d['adventures']['runs'].add(d['adventures']['runs'][0]),
      (d) => d['adventures']['runs'][0]['rewardTier'] = 'mythical',
      (d) => d['dragons'][0]['activeAdventureId'] = null,
    ]) {
      final wire = jsonDecode(jsonEncode(server.wire)) as Map<String, dynamic>;
      corrupt(wire['data'] as Map<String, dynamic>);
      expect(
          () => CanonicalGameSnapshot.parse(wire,
              expectedOwner: CanonicalUiServer.owner),
          error('game_snapshot_invalid'));
    }
  });
}
