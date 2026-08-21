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
    final migration = _legacyTranslation(message);
    return ActivityEntry(
      id: nonEmptyStringFromJson(json['id']) ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      message: message,
      createdAt: DateTime.tryParse(stringFromJson(json['createdAt']) ?? '') ??
          DateTime.now(),
      type: enumByName(ActivityType.values, json['type']) ??
          _activityTypeFor(storedCode ?? migration.code),
      code: storedCode ?? migration.code,
      subject: stringFromJson(json['subject']) ?? migration.subject,
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

  static ({ActivityCode code, String? subject}) _legacyTranslation(
      String message) {
    if (message.startsWith('Nova is in het lege nest') ||
        message.startsWith('Nova arrived in the empty nest')) {
      return (code: ActivityCode.welcome, subject: null);
    }
    if (message.startsWith('Nova vond 5 sterrenmunten') ||
        message.startsWith('Nova found 5 star coins')) {
      return (code: ActivityCode.bonusFound, subject: null);
    }
    if (message.startsWith('Weekdoel gehaald') ||
        message.startsWith('Weekly goal reached')) {
      return (code: ActivityCode.legacy, subject: null);
    }
    for (final suffix in [' is verslagen.', ' was defeated.']) {
      if (message.endsWith(suffix)) {
        return (
          code: ActivityCode.legacy,
          subject: message.substring(0, message.length - suffix.length),
        );
      }
    }
    const itemNames = {
      'Moskussen': 'moss_cushion',
      'Moss cushion': 'moss_cushion',
      'Wolkenmand': 'cloud_basket',
      'Cloud basket': 'cloud_basket',
      'Maanvaren': 'moon_fern',
      'Moon fern': 'moon_fern',
      'Sterrenbonsai': 'star_bonsai',
      'Star bonsai': 'star_bonsai',
      'Questkaart': 'spire_map',
      'Quest map': 'spire_map',
      'Maanvaandel': 'moon_banner',
      'Moon banner': 'moon_banner',
      'Vuurvlieglamp': 'firefly_lamp',
      'Firefly lamp': 'firefly_lamp',
      'Kristallantaarn': 'crystal_lantern',
      'Crystal lantern': 'crystal_lantern',
    };
    for (final item in itemNames.entries) {
      if (message.startsWith(item.key)) {
        return (code: ActivityCode.itemPlaced, subject: item.value);
      }
    }
    return (code: ActivityCode.legacy, subject: null);
  }

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
