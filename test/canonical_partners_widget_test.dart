import 'dart:io';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/social.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:dragon_haven/screens/canonical_partners_screen.dart';
import 'package:dragon_haven/services/canonical_game_session.dart';
import 'package:dragon_haven/services/canonical_partners.dart';
import 'package:dragon_haven/theme/app_theme.dart';
import 'package:dragon_haven/widgets/expertise_score_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'support/canonical_ui_server.dart';

const lobby = '22222222-2222-4222-8222-222222222222';

class Source implements CanonicalPartnersSource {
  Source(this.server);
  final CanonicalUiServer server;
  @override
  Future<CanonicalPartnerList> load(String owner) async {
    final dragon = server.state['pet'] as Map;
    return (
      canInvite: dragon['activeAdventureId'] == null,
      pairs: dragon['activeAdventureId'] == null
          ? <SeasonalPairAdventure>[]
          : <SeasonalPairAdventure>[
              SeasonalPairAdventure.fromJson({
                'id': lobby,
                'event_id': 'valentine_two_heartlights',
                'occurrence_key': 'preview:valentine_two_heartlights:$owner',
                'status': 'invited',
                'creator': {'user_id': owner, 'display_name': 'Keeper'},
                'partner': {
                  'user_id': '33333333-3333-4333-8333-333333333333',
                  'display_name': 'Friend'
                },
                'is_creator': true,
                'my_dragon_id': dragon['id'],
                'created_at': '2026-09-10T12:00:00Z'
              })
            ]
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'partner picker shows three expertise scores and invites/cancels through the real engine',
      (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    late Directory directory;
    late CanonicalUiServer server;
    late CanonicalGameSession session;
    late CanonicalPartners groups;
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
      for (final action in ['invite_pair_adventure', 'cancel_pair_adventure']) {
        server.socialContexts[action] = {
          'version': 1,
          'ownerId': CanonicalUiServer.owner,
          'sourceId': lobby,
          'action': action,
          'fingerprint': 'ab' * 32,
          'facts': {
            'eventId': 'valentine_two_heartlights',
            'dragonId': server.state['pet']['id'],
            'otherId': '33333333-3333-4333-8333-333333333333',
            'keeperCode': 'DH-1234ABCD',
            'occurrenceKey':
                'preview:valentine_two_heartlights:${CanonicalUiServer.owner}',
            'simulated': true,
            'role': 'creator'
          }
        };
      }
      final connection = CanonicalUiConnection(server);
      session =
          CanonicalGameSession(connection: connection, directory: directory);
      groups =
          CanonicalPartners(connection: connection, source: Source(server));
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
                    body: SafeArea(child: CanonicalPartnersScreen()))))));
    await settle();
    final before = Map<String, dynamic>.from(server.state['pet'] as Map);
    await tester.enterText(
        find.byKey(const Key('canonical-partner-code')), 'DH-1234ABCD');
    await tester.pump();
    await tap(find.byKey(const Key('canonical-invite-partner')));
    await settle();
    await tap(find.byKey(Key('canonical-partner-expertise-${before['id']}')));
    await settle();
    expect(find.byType(ExpertiseScoreBadge).evaluate().length,
        greaterThanOrEqualTo(3));
    await tap(find.text('Close'));
    await settle();
    expect(server.sent, isEmpty);
    expect(find.byType(ExpertiseScoreBadge), findsNWidgets(3));
    await tap(find.byKey(Key('canonical-partner-dragon-${before['id']}')));
    await tester.pump();
    await tap(find.byKey(const Key('canonical-confirm-partner')));
    await settle();
    expect(server.sent.where((i) => i.action == 'invite_pair_adventure').length,
        1);
    expect(session.snapshot!.dragon(before['id'] as String)!.adventureId,
        'online-seasonal:$lobby');
    expect(find.byKey(Key('canonical-partner-$lobby')), findsOneWidget);
    expect(find.text('Waiting for acceptance'), findsOneWidget);
    final leave = find.byKey(Key('canonical-cancel-partner-$lobby'));
    await tester.ensureVisible(leave);
    await tap(leave);
    await settle();
    await tap(find.widgetWithText(FilledButton, 'Confirm'));
    await settle();
    expect(server.sent.where((i) => i.action == 'cancel_pair_adventure').length,
        1);
    expect(
        session.snapshot!.dragon(before['id'] as String)!.adventureId, isNull);
    expect(find.byKey(const Key('canonical-invite-partner')), findsOneWidget);
    expect(server.state['pet']['xp'], before['xp']);
    expect(server.state['pet']['coins'], before['coins']);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
