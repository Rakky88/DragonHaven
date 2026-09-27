import 'dart:math';

const int maximumKeeperLevel = 40;
const int firstKeeperLevelRequirement = 50000;

/// Cumulative XP floors for Keeper levels 1 through 40.
///
/// Level 2 costs 50,000 XP. Every later step costs 150% of the preceding
/// step, rounded up so progression never becomes cheaper through truncation.
final List<int> keeperLevelThresholds = List<int>.unmodifiable(() {
  final values = <int>[0];
  var requirement = firstKeeperLevelRequirement;
  var cumulative = 0;
  for (var level = 2; level <= maximumKeeperLevel; level++) {
    cumulative += requirement;
    values.add(cumulative);
    requirement = (requirement * 3 + 1) ~/ 2;
  }
  return values;
}());

int keeperLevelAtXp(int xp) {
  final safeXp = max(0, xp);
  for (var index = keeperLevelThresholds.length - 1; index >= 0; index--) {
    if (safeXp >= keeperLevelThresholds[index]) return index + 1;
  }
  return 1;
}

int keeperLevelFloor(int xp) => keeperLevelThresholds[keeperLevelAtXp(xp) - 1];

int keeperNextLevelTarget(int xp) {
  final level = keeperLevelAtXp(xp);
  return level >= maximumKeeperLevel
      ? keeperLevelThresholds.last
      : keeperLevelThresholds[level];
}

double keeperLevelProgressAtXp(int xp) {
  final level = keeperLevelAtXp(xp);
  if (level >= maximumKeeperLevel) return 1;
  final floor = keeperLevelThresholds[level - 1];
  final target = keeperLevelThresholds[level];
  return ((xp - floor) / max(1, target - floor)).clamp(0, 1);
}

String keeperLevelBadgeId(int level) =>
    'keeper_level_badge_${level.toString().padLeft(2, '0')}';

String keeperLevelEmoteId(int level) =>
    'keeper_level_emote_${level.toString().padLeft(2, '0')}';

const String keeperLevel40FrameId = 'keeper_level_frame_40';

bool isKeeperLevelBadgeId(String id) => id.startsWith('keeper_level_badge_');
