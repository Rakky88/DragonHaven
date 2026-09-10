import 'dart:io';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/social.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:dragon_haven/screens/canonical_groups_screen.dart';
import 'package:dragon_haven/services/canonical_game_session.dart';
import 'package:dragon_haven/services/canonical_groups.dart';
import 'package:dragon_haven/theme/app_theme.dart';
import 'package:dragon_haven/widgets/expertise_score_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'support/canonical_ui_server.dart';

const lobby = '22222222-2222-4222-8222-222222222222';

class Source implements CanonicalGroupsSource {
  Source(this.server);
  final CanonicalUiServer server;
  @override
  Future<GroupAdventureStatus> status(String owner) async =>
      const GroupAdventureStatus(
          slot: 1, adventureId: 'group_1', alreadyCompleted: false);
  @override
  Future<List<GroupAdventureLobby>> lobbies(String owner) async {
    final dragon = server.state['pet'] as Map;
    return dragon['activeAdventureId'] == null
        ? []
        : [
            GroupAdventureLobby.fromJson({
              'lobby_id': lobby,
              'slot': 1,
              'adventure_id': 'group_1',
              'owner_id': owner,
              'status': 'waiting',
              'required_players': 3,
              'focus': 'spirit',
              'is_current_offer': true,
              'is_owner': true,
              'is_participant': true,
              'my_dragon_id': dragon['id'],
              'reward_acknowledged': false,
              'participants': [
                {
                  'user_id': owner,
                  'display_name': 'Keeper',
                  'dragon_id': dragon['id'],
                  'dragon_name': dragon['name'],
                  'dragon_lineage_id': dragon['lineageId'],
                  'dragon_stage': 'hatchling',
                  'dragon_level': 1,
                  'dragon_might': 10,
                  'dragon_arcana': 10,
                  'dragon_spirit': 10,
                  'is_owner': true
                }
              ]
            })
          ];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'real group picker inspects all expertise, creates once and leaves cleanly',
      (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    late Directory directory;
    late CanonicalUiServer server;
    late CanonicalGameSession session;
    late CanonicalGroups groups;
    await tester.runAsync(() async {
      directory = await Directory.systemTemp.createTemp('dh-group-ui-');
      final game = HouseholdProvider(
          persistenceEnabled: false,
          clock: () => DateTime.utc(2026, 9, 10, 12));
      game.pet
        ..stage = DragonStage.hatchling
        ..firstEgg = false
        ..favorite = true
        ..name = 'Fleet';
      server = CanonicalUiServer(game.exportState());
      game.dispose();
      for (final action in [
        'create_group_adventure',
        'leave_group_adventure'
      ]) {
        server.socialContexts[action] = {
          'version': 1,
          'ownerId': CanonicalUiServer.owner,
          'sourceId': lobby,
          'action': action,
          'fingerprint': 'ab' * 32,
          'facts': {
            'adventureId': 'group_1',
            'dragonId': server.state['pet']['id'],
            'memberId': null
          }
        };
      }
      final connection = CanonicalUiConnection(server);
      session =
          CanonicalGameSession(connection: connection, directory: directory);
      groups = CanonicalGroups(connection: connection, source: Source(server));
      await session.synchronize();
    });
    addTearDown(() async {
      groups.dispose();
      session.dispose();
      await directory.delete(recursive: true);
    });
    Future<void> tap(Finder finder) =>
        tester.runAsync(() => tester.tap(finder));
    Future<void> settle() async {
      for (var i = 0; i < 300; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)));
        await tester.pump(const Duration(milliseconds: 40));
        if (i > 10 && !session.busy && !groups.loading) break;
      }
      expect(tester.takeException(), isNull);
    }

    await tester.runAsync(() => tester.pumpWidget(MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: session),
              ChangeNotifierProvider.value(value: groups)
            ],
            child: MaterialApp(
                theme: buildAppTheme(),
                supportedLocales: const [Locale('en')],
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                home: const Scaffold(
                    body: SafeArea(child: CanonicalGroupsScreen()))))));
    await settle();
    final before = Map<String, dynamic>.from(server.state['pet'] as Map);
    await tap(find.byKey(const Key('canonical-create-group')));
    await settle();
    await tap(find.byKey(Key('canonical-group-expertise-${before['id']}')));
    await settle();
    expect(find.byType(ExpertiseScoreBadge).evaluate().length,
        greaterThanOrEqualTo(3));
    await tap(find.text('Close'));
    await settle();
    expect(server.sent, isEmpty);
    await tap(find.byKey(Key('canonical-group-dragon-${before['id']}')));
    await tester.pump();
    await tap(find.byKey(const Key('canonical-confirm-group')));
    await settle();
    expect(
        server.sent.where((i) => i.action == 'create_group_adventure').length,
        1);
    expect(session.snapshot!.dragon(before['id'] as String)!.adventureId,
        'online-group:$lobby');
    expect(find.byKey(Key('canonical-group-$lobby')), findsOneWidget);
    expect(find.text('No trail is available here right now'), findsOneWidget);
    final leave = find.byKey(Key('canonical-leave-group-$lobby'));
    await tester.ensureVisible(leave);
    await tap(leave);
    await settle();
    await tap(find.widgetWithText(FilledButton, 'Confirm'));
    await settle();
    expect(server.sent.where((i) => i.action == 'leave_group_adventure').length,
        1);
    expect(
        session.snapshot!.dragon(before['id'] as String)!.adventureId, isNull);
    expect(find.byKey(const Key('canonical-create-group')), findsOneWidget);
    expect(server.state['pet']['xp'], before['xp']);
    expect(server.state['pet']['coins'], before['coins']);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
