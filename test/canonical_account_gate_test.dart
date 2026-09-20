import 'dart:async';
import 'dart:io';

import 'package:dragon_haven/services/canonical_account_bootstrap.dart';
import 'package:dragon_haven/services/canonical_account_handoff.dart';
import 'package:dragon_haven/widgets/canonical_account_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const a = '11111111-1111-4111-8111-111111111111';
const b = '22222222-2222-4222-8222-222222222222';

class _Game {
  _Game(this.owner);
  final String owner;
}

class _View extends StatefulWidget {
  const _View({required this.game, required this.closed});
  final _Game game;
  final Set<_Game> closed;
  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  @override
  void dispose() {
    widget.closed.add(widget.game);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
      home: Builder(
          builder: (context) => Scaffold(
                  body: Column(children: [
                Text('game-${widget.game.owner}'),
                ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                            builder: (_) => Scaffold(
                                body: Text('private-${widget.game.owner}')))),
                    child: const Text('Open private route'))
              ]))));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('nl.dragonhaven.app/network'),
            (_) async => null);
  });
  testWidgets(
      'account switch removes the old Navigator before draining its writers',
      (tester) async {
    final directory = (await tester
        .runAsync(() => Directory.systemTemp.createTemp('dh-account-gate-')))!;
    final events = StreamController<int>.broadcast(sync: true);
    var owner = a;
    var epoch = 0;
    final removedViews = <_Game>{};
    final retired = <String>[];
    late CanonicalAccountBootstrap<_Game> bootstrap;
    await tester.pumpWidget(CanonicalAccountGate<_Game>(
      createBootstrap: (beforeRetire) => bootstrap = CanonicalAccountBootstrap(
          directory: directory,
          currentOwner: () => owner,
          sessionEpoch: () => epoch,
          accountChanges: events.stream,
          beforeRetire: beforeRetire,
          readStatus: (owner) async => CanonicalAccountStatus.parse({
                'owner_id': owner,
                'phase': 'legacy',
                'migration_enabled': false,
                'source_revision': null,
                'server_revision': null,
              }, owner),
          prepareAndUploadLegacy: (_) =>
              throw StateError('Unexpected migration'),
          activate: (_, __, ___) => throw StateError('Unexpected activation'),
          openServer: (_, __) => throw StateError('Unexpected server'),
          openLegacy: (owner) async {
            final game = _Game(owner);
            return CanonicalGameplayLease(game, close: () async {
              expect(removedViews, contains(game));
              retired.add(owner);
            });
          }),
      gameplayBuilder: (_, game) => _View(game: game, closed: removedViews),
      statusBuilder: (_, controller) =>
          const MaterialApp(home: Text('Checking account')),
    ));
    for (var attempt = 0;
        bootstrap.gameplay == null && attempt < 100;
        attempt++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
    }
    expect(bootstrap.phase, CanonicalBootstrapPhase.legacy);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open private route'));
    await tester.pumpAndSettle();
    expect(find.text('private-$a'), findsOneWidget);
    owner = b;
    epoch++;
    events.add(epoch);
    await tester.pump();
    expect(find.text('private-$a'), findsNothing);
    for (var attempt = 0;
        bootstrap.gameplay == null && attempt < 100;
        attempt++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
    }
    expect(bootstrap.phase, CanonicalBootstrapPhase.legacy);
    await tester.pumpAndSettle();
    expect(find.text('game-$b'), findsOneWidget);
    expect(retired, [a]);
    final context = tester.element(find.text('game-$b'));
    expect(Navigator.of(context).canPop(), false);
    await tester.pumpWidget(const SizedBox());
    for (var attempt = 0; retired.length < 2 && attempt < 100; attempt++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
    }
    expect(retired, [a, b]);
    await bootstrap.shutdown();
    expect(retired, [a, b]);
    await events.close();
    await tester.runAsync(() => directory.delete(recursive: true));
  });
}
