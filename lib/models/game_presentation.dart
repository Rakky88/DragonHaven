import '../utils/json_utils.dart';

enum GamePresentationType { hatch, evolution, achievement }

/// A persisted cinematic milestone waiting to be shown to the player.
///
/// Gameplay state is committed before this record is saved. If Android closes
/// the process during a reveal, the presentation is therefore replayed rather
/// than losing the hatch, evolution or achievement.
class GamePresentation {
  const GamePresentation({
    required this.id,
    required this.type,
    required this.createdAt,
    required this.sortAt,
    this.dragonId,
    this.achievementId,
    this.previousStageKey,
  });

  final String id;
  final GamePresentationType type;
  final DateTime createdAt;
  final DateTime sortAt;
  final String? dragonId;
  final String? achievementId;
  final String? previousStageKey;

  int get priority => switch (type) {
        GamePresentationType.hatch => 0,
        GamePresentationType.evolution => 1,
        GamePresentationType.achievement => 2,
      };

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'createdAt': createdAt.toIso8601String(),
        'sortAt': sortAt.toIso8601String(),
        'dragonId': dragonId,
        'achievementId': achievementId,
        'previousStageKey': previousStageKey,
      };

  factory GamePresentation.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return GamePresentation(
      id: nonEmptyStringFromJson(json['id']) ??
          'legacy-presentation-${now.microsecondsSinceEpoch}',
      type: enumByName(GamePresentationType.values, json['type']) ??
          GamePresentationType.achievement,
      createdAt:
          DateTime.tryParse(stringFromJson(json['createdAt']) ?? '') ?? now,
      sortAt: DateTime.tryParse(stringFromJson(json['sortAt']) ?? '') ?? now,
      dragonId: nonEmptyStringFromJson(json['dragonId']),
      achievementId: nonEmptyStringFromJson(json['achievementId']),
      previousStageKey: nonEmptyStringFromJson(json['previousStageKey']),
    );
  }
}
