import 'dart:convert';
import 'dart:io';

import 'package:dragon_haven/domain/game_command_engine.dart';

import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/services/canonical_game_actions.dart';
import 'package:dragon_haven/services/canonical_game_session.dart';
import 'package:dragon_haven/services/canonical_game_snapshot.dart';
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
  const secondId = '22222222-2222-4222-8222-222222222222';
  CanonicalGameActions actions() => CanonicalGameActions(session);
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('dh-dragon-preferences-');
    server = CanonicalUiServer(
        jsonDecode(jsonEncode(fixture)) as Map<String, dynamic>);
    final second =
        jsonDecode(jsonEncode(server.state['pet'])) as Map<String, dynamic>;
    second['id'] = secondId;
    second['favorite'] = false;
    server.state['pet']['highlightedExpertises'] = [];
    server.state['sanctuaryDragons'] = [second];
    session = CanonicalGameSession(
        connection: CanonicalUiConnection(server), directory: directory);
    await session.synchronize();
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

  test('highlights set the desired state and lost replies never flip it back',
      () async {
    final before = session.snapshot!;
    final dragon = before.dragons.first;
    server.loseReply = true;
    await expectLater(
        actions().setDragonHighlight(dragon.id, TrainingFocus.might, true),
        error('game_command_unavailable'));
    await restart();
    expect(session.snapshot!.dragon(dragon.id)!.highlighted, {'might'});
    await actions().setDragonHighlight(dragon.id, TrainingFocus.might, true);
    await actions().setDragonHighlight(dragon.id, TrainingFocus.spirit, true);
    expect(
        session.snapshot!.dragon(dragon.id)!.highlighted, {'might', 'spirit'});
    await actions().setDragonHighlight(dragon.id, TrainingFocus.might, false);
    await actions().setDragonHighlight(dragon.id, TrainingFocus.might, false);
    expect(session.snapshot!.dragon(dragon.id)!.highlighted, {'spirit'});
    expect(session.snapshot!.dragon(dragon.id)!.training, dragon.training);
    expect(session.snapshot!.dragon(dragon.id)!.xp, dragon.xp);
    expect(session.snapshot!.coins, before.coins);
    expect(session.snapshot!.shop.chests, before.shop.chests);
  });

  test('favorite recovery preserves exactly one favorite and one change count',
      () async {
    final changes = server.state['favoriteChanges'] as int;
    final original = session.snapshot!.dragons.first.id;
    server.loseReply = true;
    await expectLater(actions().setFavoriteDragon(secondId),
        error('game_command_unavailable'));
    await restart();
    expect(
        session.snapshot!.dragons.where((d) => d.favorite).single.id, secondId);
    expect(server.state['favoriteChanges'], changes + 1);
    await actions().setFavoriteDragon(secondId);
    expect(server.state['favoriteChanges'], changes + 1);
    await expectLater(
        actions().releaseDragon(secondId), error('game_action_unavailable'));
    await actions().setFavoriteDragon(original);
    expect(
        session.snapshot!.dragons.where((d) => d.favorite).single.id, original);
    expect(server.state['favoriteChanges'], changes + 2);
  });

  test('unowned, egg, released and malformed preference intents are refused',
      () async {
    final egg = session.snapshot!.eggs.first.id;
    await actions().releaseDragon(secondId);
    for (final id in ['absent', egg, secondId]) {
      await expectLater(
          actions().setDragonHighlight(id, TrainingFocus.might, true),
          error('game_action_unavailable'));
      await expectLater(
          actions().setFavoriteDragon(id), error('game_action_unavailable'));
    }
    final id = session.snapshot!.dragons.first.id;
    for (final payload in [
      {'dragonId': id, 'focus': 'coins', 'highlighted': true},
      {'dragonId': id, 'focus': 'might', 'highlighted': 'true'},
    ]) {
      await expectLater(
          actions().execute('set_dragon_highlight', payload),
          error(payload['highlighted'] is bool
              ? 'invalid_argument'
              : 'game_intent_invalid'));
      await expectLater(
          GameCommandEngine.execute(
              state: server.state,
              action: 'set_dragon_highlight',
              payload: payload,
              secretSeed: 'a5' * 32,
              now: server.now,
              keeperId: CanonicalUiServer.owner),
          throwsA(isA<GameCommandException>()
              .having((e) => e.code, 'server rejection', 'invalid_argument')));
    }
    expect(session.snapshot!.dragon(id)!.highlighted, isEmpty);
  });
}
