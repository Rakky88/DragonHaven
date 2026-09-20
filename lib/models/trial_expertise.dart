import 'dart:math';

/// Expertise is expressed in actual trained points, never a capped 0-1 ratio.
/// Percentage improvements are relative to each game's untrained base.
abstract final class TrialExpertise {
  static double fraction(num points) => max(0, points) / 10000;
  static double cavernHitbox(int spirit) => 1 - fraction(spirit);
  static double ruinSuccess(int might) => 1 + fraction(might) * 1.5;
  static double ruinPerfect(int might) => 1 + fraction(might) * .5;
  static int runePreviewMs(int arcana) => 500 + (max(0, arcana) / 10).round();
  static int pumpkinPreviewMs(int arcana, {bool initial = false}) =>
      initial ? 2900 : max(100, arcana);
  static double pathRadius(num spirit) => 12 + max(0, spirit) / 200;
  static double parcelExtraSeconds(num might) => max(0, might) / 1000 * 3;
  static double accelerationScale(num spirit) => 1 - fraction(spirit);
  static double chimeWindow(num might) => .18 + max(0, might) / 10000;
  static double chimePreviewSeconds(num spirit) => max(0, spirit) / 10000 * 4;
  static int hints(num arcana) => 1 + (max(0, arcana) / 400).floor();
  static double cakeWidth(num might) => .44 * (1 + fraction(might));
  static double cakeTolerance(num arcana) => .018 * (1 + fraction(arcana));
  static double speedScale(num spirit) => 1 - fraction(spirit);
  static double reefWidth(num might) => .25 * (1 - fraction(might));
  static double pickupRadius(num arcana) => .10 * (1 + fraction(arcana));
  static double currentScale(num spirit) => 1 - fraction(spirit);
  static double smallPieceChance(num might, num arcana, num spirit) =>
      (.10 + (max(0, might) + max(0, arcana) + max(0, spirit)) / 5000)
          .clamp(0, 1);
}
