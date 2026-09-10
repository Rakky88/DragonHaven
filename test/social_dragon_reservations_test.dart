import 'dart:convert';
import 'package:dragon_haven/domain/game_command_engine.dart';
import 'package:dragon_haven/domain/game_public_projection.dart';
import 'package:dragon_haven/models/trial.dart';
import 'package:dragon_haven/domain/social_dragon_reservations.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const owner = '11111111-1111-4111-8111-111111111111';
  const firstSource = '22222222-2222-4222-8222-222222222222';
  const secondSource = '33333333-3333-4333-8333-333333333333';
  final now = DateTime.utc(2026, 9, 10, 12);
  late HouseholdProvider game;
  setUp(() {
    game = HouseholdProvider(persistenceEnabled: false, clock: () => now);
    game.pet
      ..stage = DragonStage.hatchling
      ..firstEgg = false;
  });
  tearDown(() => game.dispose());
  Map<String, dynamic> reservation(String kind, String source) => {
        'dragonId': game.pet.id,
        'kind': kind,
        'sourceId': source,
      };
  Map<String, dynamic> view(List<Map<String, dynamic>> values) => {
        'version': 1,
        'ownerId': owner,
        'reservations': values,
      };
  void apply(Map<String, dynamic>? data, {Map<String, dynamic>? attempt}) =>
      SocialDragonReservations.apply(
          game: game, ownerId: owner, verified: data, activeAttempt: attempt);

  test('authoritative group and pair reservations replace stale bindings', () {
    apply(view([reservation('group', firstSource)]));
    expect(game.pet.activeAdventureId, 'online-group:$firstSource');
    apply(view([reservation('pair', secondSource)]));
    expect(game.pet.activeAdventureId, 'online-seasonal:$secondSource');
    apply(view([]));
    expect(game.pet.activeAdventureId, isNull);
  });

  test('disabled social cutover and empty views preserve solo adventures', () {
    game.pet.activeAdventureId = 'online-group:$firstSource';
    apply(null);
    expect(game.pet.activeAdventureId, 'online-group:$firstSource');
    game.pet.activeAdventureId = 'ordinary-run';
    apply(view([]));
    expect(game.pet.activeAdventureId, 'ordinary-run');
    expect(() => apply(view([reservation('group', firstSource)])),
        throwsFormatException);
    expect(game.pet.activeAdventureId, 'ordinary-run');
  });

  test('foreign owners and conflicting social journeys are refused atomically',
      () {
    game.pet.activeAdventureId = 'online-group:$firstSource';
    for (final invalid in [
      {...view([]), 'ownerId': secondSource},
      {...view([]), 'version': 2},
      {...view([]), 'injected': true},
      view([
        reservation('group', firstSource),
        reservation('pair', secondSource),
      ]),
      view([
        {...reservation('group', firstSource), 'dragonId': 'foreign-dragon'},
      ]),
      view([reservation('solo', firstSource)]),
      view([reservation('group', 'not-a-server-source')]),
    ]) {
      expect(() => apply(invalid), throwsFormatException);
      expect(game.pet.activeAdventureId, 'online-group:$firstSource');
    }
  });

  test('active trial, pupil and mentor reservations cannot overlap social play',
      () {
    final incoming = view([reservation('group', firstSource)]);
    for (final attempt in [
      {
        'type': 'trial',
        'dragonIds': [game.pet.id]
      },
      {
        'type': 'school',
        'dragonIds': [game.pet.id],
        'mentorId': null
      },
      {
        'type': 'school',
        'dragonIds': ['another-pupil'],
        'mentorId': game.pet.id
      },
    ]) {
      expect(() => apply(incoming, attempt: attempt), throwsFormatException);
      expect(game.pet.activeAdventureId, isNull);
    }
    apply(incoming, attempt: {
      'type': 'trial',
      'dragonIds': ['another-dragon']
    });
    expect(game.pet.activeAdventureId, 'online-group:$firstSource');
  });
  test('the command engine and public view use the same reservation facts',
      () async {
    game.towerFloorRoomIds = List.filled(5, 'hearth');
    game.trialOffers = [
      TrialOffer(
          id: 'reserved-offer', kind: TrialKind.ruinBreaker, appearedAt: now)
    ];
    game.trialRefilledAt = now;
    game.sanctuaryDragons.add(Pet.fromJson(
        {...game.pet.toJson(), 'id': 'second-dragon', 'favorite': true}));
    final state = game.exportState();
    final before = jsonEncode(state);
    final reserved = view([reservation('group', firstSource)]);
    Future<Map<String, dynamic>> command(String action,
            Map<String, dynamic> payload, Map<String, dynamic>? bindings) =>
        GameCommandEngine.execute(
            state: state,
            action: action,
            payload: payload,
            secretSeed: 'a8' * 32,
            now: now,
            keeperId: owner,
            verifiedSocialReservations: bindings);
    final trial = {'offerId': 'reserved-offer', 'dragonId': game.pet.id};
    final school = {
      'gameId': 'runeRush',
      'dragonIds': jsonEncode([game.pet.id]),
      'mentorId': null
    };
    for (final (action, payload) in [
      ('start_trial', trial),
      ('start_school', school)
    ]) {
      final available = await command(action, payload, view([]));
      expect(
          available['state']['_activeGameAttempt']['dragonIds'], [game.pet.id]);
      await expectLater(
          command(action, payload, reserved),
          throwsA(isA<GameCommandException>().having(
              (e) => e.code, 'busy refusal', 'game_action_unavailable')));
    }
    expect(
        (await command(
            'release_dragon', {'dragonId': game.pet.id}, reserved))['result'],
        false);
    expect(
        (await command(
            'release_dragon', {'dragonId': game.pet.id}, view([])))['result'],
        true);
    final projection = GamePublicProjection.project(
        state: state,
        ownerId: owner,
        now: now,
        verifiedSocialReservations: reserved);
    final dragon = (projection['dragons'] as List)
        .singleWhere((d) => d['id'] == game.pet.id);
    expect(dragon['activeAdventureId'], 'online-group:$firstSource');
    expect(jsonEncode(state), before,
        reason: 'projection and declined commands never mutate their input');
    expect(game.pet.activeAdventureId, isNull);
  });
}
