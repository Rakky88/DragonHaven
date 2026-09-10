import 'dart:convert';
import 'dart:io';

import 'package:dragon_haven/domain/game_public_projection.dart';
import 'package:dragon_haven/models/social_reward_claim.dart';
import 'package:dragon_haven/services/canonical_game_session.dart';
import 'package:dragon_haven/widgets/canonical_social_rewards.dart';
import 'package:dragon_haven/widgets/shop_economy_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../tool/game_domain_probe.dart';
import 'support/canonical_ui_server.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<String, dynamic> fixture;
  setUpAll(() async {
    fixture = (await runGameDomainProbe())['state'] as Map<String, dynamic>;
  });
  const ids = [
    '22222222-2222-4222-8222-222222222222',
    '33333333-3333-4333-8333-333333333333',
    '44444444-4444-4444-8444-444444444444'
  ];
  Map<String, dynamic> offer(int index, String dragon) => {
        'id': ids[index],
        'kind': ['group', 'pair', 'podium'][index],
        'catalogId': [
          'group_1',
          'valentine_two_heartlights',
          'sunwake_summer_sea'
        ][index],
        'dragonId': index == 2 ? null : dragon,
        'position': index == 2 ? 1 : null,
        'readyAt': '2026-09-07T10:00:00.000Z'
      };
  test(
      'social projection validates private SQL offer data and ignores injected save fields',
      () {
    final state = jsonDecode(jsonEncode(fixture)) as Map<String, dynamic>;
    state['socialClaims'] = [offer(0, state['pet']['id'] as String)];
    expect(
        GamePublicProjection.project(
            state: state,
            ownerId: CanonicalUiServer.owner,
            now: DateTime.utc(2026, 9, 7))['adventures']['socialClaims'],
        isEmpty);
    final valid = offer(0, state['pet']['id'] as String);
    for (final bad in [
      {...valid, 'xp': 99999},
      {...valid, 'id': 'wrong'},
      {...valid, 'dragonId': null},
      {...valid, 'readyAt': '2026-09-07T10:00:00'},
      {...valid, 'catalogId': 'mini_1'}
    ]) {
      expect(() => SocialRewardClaim.parse(bad), throwsFormatException);
    }
    expect(() => SocialRewardClaim.parseList([valid, valid]),
        throwsFormatException);
  });
  testWidgets(
      'compact social rewards claim once, recover a lost reply and clear on account exit',
      (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    late Directory directory;
    late CanonicalUiServer server;
    late CanonicalGameSession session;
    await tester.runAsync(() async {
      directory = await Directory.systemTemp.createTemp('dh-social-ui-');
      server = CanonicalUiServer(
          jsonDecode(jsonEncode(fixture)) as Map<String, dynamic>);
      final dragon = server.state['pet']['id'] as String;
      for (var i = 0; i < 3; i++) {
        server.socialOffers.add(offer(i, dragon));
      }
      final actions = [
        'claim_group_reward',
        'claim_pair_reward',
        'claim_podium_prize'
      ];
      final facts = [
        {
          'adventureId': 'group_1',
          'dragonId': dragon,
          'xp': 400,
          'focus': 'spirit',
          'statPoints': 5,
          'chestTier': 'dragon',
          'participantCount': 4
        },
        {
          'eventId': 'valentine_two_heartlights',
          'dragonId': dragon,
          'xp': 650,
          'might': 8,
          'arcana': 8,
          'spirit': 8,
          'specialChestId': 'twinheart_keepsake_chest_v1',
          'simulated': false
        },
        {'eventId': 'sunwake_summer_sea', 'position': 1}
      ];
      for (var i = 0; i < 3; i++) {
        server.socialContexts[ids[i]] = {
          'version': 1,
          'ownerId': CanonicalUiServer.owner,
          'action': actions[i],
          'sourceId': ids[i],
          'fingerprint': 'a5' * 32,
          'facts': facts[i]
        };
      }
      session = CanonicalGameSession(
          connection: CanonicalUiConnection(server), directory: directory);
      await session.synchronize();
    });
    addTearDown(() async {
      session.dispose();
      await directory.delete(recursive: true);
    });
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: session,
        child: MaterialApp(
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(1.35)),
                child: child!),
            home: const Scaffold(
                body: ShopEconomyBoundary(
                    child: SingleChildScrollView(
                        child: CanonicalSocialRewards()))))));
    final beforeChests = session.snapshot!.shop.chests['dragon'] ?? 0;
    for (var i = 0; i < 3; i++) {
      final button = find.byKey(Key('canonical-social-claim-${ids[i]}'));
      await tester.ensureVisible(button);
      await tester.pump();
      if (i == 0) server.loseReply = true;
      await tester.runAsync(() => tester.tap(button));
      for (var n = 0; n < 200 && session.busy; n++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)));
        await tester.pump();
      }
      if (i == 0) await tester.runAsync(session.synchronize);
      await tester.pump();
      expect(session.canAct, true, reason: session.errorCode);
      expect(
          session.snapshot!.adventures.socialClaims.any((c) => c.id == ids[i]),
          false);
      expect(tester.takeException(), isNull);
    }
    expect(session.snapshot!.shop.chests['dragon'], beforeChests + 1);
    expect(
        session.snapshot!.shop.specialChests['twinheart_keepsake_chest_v1'], 1);
    expect(
        server.receipts.values
            .where((r) => (r['result'] as Map?)?['accepted'] == true)
            .length,
        3);
    (session.connection as CanonicalUiConnection).signOut();
    await tester.pump();
    expect(find.byType(CanonicalSocialRewards), findsNothing);
  });
}
