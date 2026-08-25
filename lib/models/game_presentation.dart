import '../utils/json_utils.dart';

enum GamePresentationType { hatch, evolution, trade, achievement }

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
    this.payload = const {},
  });

  final String id;
  final GamePresentationType type;
  final DateTime createdAt;
  final DateTime sortAt;
  final String? dragonId;
  final String? achievementId;
  final String? previousStageKey;
  final Map<String, dynamic> payload;

  int get priority => switch (type) {
        GamePresentationType.hatch => 0,
        GamePresentationType.evolution => 1,
        GamePresentationType.trade => 2,
        GamePresentationType.achievement => 3,
      };

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'createdAt': createdAt.toIso8601String(),
        'sortAt': sortAt.toIso8601String(),
        'dragonId': dragonId,
        'achievementId': achievementId,
        'previousStageKey': previousStageKey,
        'payload': payload,
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
      payload: json['payload'] is Map
          ? Map<String, dynamic>.from(json['payload'] as Map)
          : const {},
    );
  }
}
