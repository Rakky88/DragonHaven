import '../utils/json_utils.dart';

enum ActivityType { explore, discovery, purchase, milestone }

enum ActivityCode {
  welcome,
  activityCompleted,
  bonusFound,
  chestOpened,
  hatched,
  evolved,
  achievement,
  itemPlaced,
  legacy,
}

class ActivityEntry {
  const ActivityEntry({
    required this.id,
    required this.message,
    required this.createdAt,
    required this.type,
    this.code = ActivityCode.legacy,
    this.subject,
    this.xp = 0,
    this.coins = 0,
    this.gems = 0,
  });

  final String id;
  final String message;
  final DateTime createdAt;
  final ActivityType type;
  final ActivityCode code;
  final String? subject;
  final int xp;
  final int coins;
  final int gems;

  factory ActivityEntry.fromJson(Map<String, dynamic> json) {
    final message =
        stringFromJson(json['message']) ?? 'Something happened in the nest.';
    final storedCode = enumByName(ActivityCode.values, json['code']);
    final code = storedCode ?? ActivityCode.legacy;
    return ActivityEntry(
      id: nonEmptyStringFromJson(json['id']) ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      message: message,
      createdAt: DateTime.tryParse(stringFromJson(json['createdAt']) ?? '') ??
          DateTime.now(),
      type: enumByName(ActivityType.values, json['type']) ??
          _activityTypeFor(code),
      code: code,
      subject: stringFromJson(json['subject']),
      xp: intFromJson(json['xp'], fallback: 0),
      coins: intFromJson(json['coins'], fallback: 0),
      gems: intFromJson(json['gems'], fallback: 0),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'message': message,
        'createdAt': createdAt.toIso8601String(),
        'type': type.name,
        'code': code.name,
        'subject': subject,
        'xp': xp,
        'coins': coins,
        'gems': gems,
      };

  static ActivityType _activityTypeFor(ActivityCode code) => switch (code) {
        ActivityCode.activityCompleted => ActivityType.explore,
        ActivityCode.bonusFound => ActivityType.discovery,
        ActivityCode.itemPlaced => ActivityType.purchase,
        ActivityCode.welcome ||
        ActivityCode.chestOpened ||
        ActivityCode.hatched ||
        ActivityCode.evolved ||
        ActivityCode.achievement ||
        ActivityCode.legacy =>
          ActivityType.milestone,
      };
}
