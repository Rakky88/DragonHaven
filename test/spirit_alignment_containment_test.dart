import 'package:dragon_haven/models/standard_trial_games.dart';
import 'package:flutter_test/flutter_test.dart';

double _position(double shapeOffset) =>
    .5 +
    shapeOffset *
        SpiritAlignmentGeometry.shapeExtent /
        SpiritAlignmentGeometry.travelExtent;

int _score(SpiritAlignmentShape shape, double dx, double dy,
        {bool contained = true}) =>
    SpiritAlignmentGame.overlapPercent(shape,
        playerX: _position(dx),
        playerY: _position(dy),
        containedScoring: contained);

void main() {
  test('all three smaller shapes earn 100 anywhere fully inside the target',
      () {
    for (final shape in SpiritAlignmentShape.values) {
      expect(_score(shape, 0, 0), 100, reason: shape.name);
      expect(_score(shape, .012, .015), 100, reason: shape.name);
      expect(_score(shape, -.012, -.015), 100, reason: shape.name);
      expect(_score(shape, 2, 0), 0, reason: shape.name);
      expect(_score(shape, 0, -2), 0, reason: shape.name);
    }
  });

  test('the gold border is not part of the target and cannot round up to 100',
      () {
    // Measured in target-width units. The 86%-wide square/circle have a 7%
    // margin; the triangle's sloping sides allow 3.5% horizontal displacement.
    for (final shape in SpiritAlignmentShape.values) {
      final edge = shape == SpiritAlignmentShape.triangle ? .035 : .07;
      for (final direction in [-1, 1]) {
        expect(_score(shape, direction * edge, 0), 100, reason: shape.name);
        expect(_score(shape, direction * (edge + .000001), 0), 99,
            reason: '${shape.name}: even tiny border overlap is not perfect');
        expect(
            _score(shape, direction * (edge + .02), 0), inInclusiveRange(1, 99),
            reason: shape.name);
      }
    }
    expect(_score(SpiritAlignmentShape.triangle, 0, .07), 100);
    expect(_score(SpiritAlignmentShape.triangle, 0, .070001), 99);
    expect(_score(SpiritAlignmentShape.circle, .06, .06), lessThan(100));
  });

  test('partial percentage is the player area inside, not the target area', () {
    expect(_score(SpiritAlignmentShape.square, .14, 0), 92);
    expect(_score(SpiritAlignmentShape.square, .14, .14), 84);
  });

  test('contained off-centre placement awards five seconds only once', () {
    final game = SpiritAlignmentGame(seed: 17, spirit: 0);
    // Lock slightly off centre, outside the existing exact-centre snap.
    var at = 0;
    while (game.playerY < _position(.022)) {
      game.advanceTo(++at);
    }
    game.tap(at);
    while (game.playerX < _position(.022)) {
      game.advanceTo(++at);
    }
    expect(game.playerX, isNot(game.targetX));
    game.tap(at);
    expect(game.latestOverlap, 100);
    expect(game.perfectPlacements, 1);
    expect(game.remainingMs, 65000 - at);
    expect(game.tap(at), isFalse);
    final restored =
        SpiritAlignmentGame.fromCheckpoint(game.checkpoint(), spirit: 0);
    expect(restored.containedScoring, true);
    expect(restored.perfectPlacements, 1);
    expect(restored.remainingMs, game.remainingMs);
  });

  test('old timed and untimed checkpoints preserve equal-size scoring', () {
    for (final timed in [false, true]) {
      final old = SpiritAlignmentGame(
          seed: 5, spirit: 0, timed: timed, containedScoring: false);
      expect(old.checkpoint()['version'], timed ? 2 : 1);
      final restored =
          SpiritAlignmentGame.fromCheckpoint(old.checkpoint(), spirit: 0);
      expect(restored.containedScoring, false);
      expect(restored.checkpoint(), old.checkpoint());
    }
    expect(_score(SpiritAlignmentShape.square, .012, .015, contained: false),
        lessThan(100));
    expect(SpiritAlignmentGame(seed: 5, spirit: 0).checkpoint()['version'], 3);
  });
}
