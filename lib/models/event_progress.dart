import 'adventure.dart';
import 'trial.dart';

/// One occurrence, with an immutable reward definition and no claim deadline.
class EventProgress {
  EventProgress(
      {required this.eventId,
      required this.key,
      required this.startsAt,
      required this.endsAt,
      required this.target,
      required this.chestId,
      this.points = 0,
      this.partnerPoints = 0,
      this.claimed = false,
      this.preview = false});

  final String eventId, key, chestId;
  final DateTime startsAt, endsAt;
  final int target;
  int points, partnerPoints;
  bool claimed;
  final bool preview;
  int get total => points + partnerPoints;
  bool get complete => total >= target;
  bool get canClaim => complete && !claimed;
  double get fraction => (total / target).clamp(0.0, 1.0);
  bool activeAt(DateTime now) =>
      !now.isBefore(startsAt) && now.isBefore(endsAt);

  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'key': key,
        'chestId': chestId,
        'startsAt': startsAt.toUtc().toIso8601String(),
        'endsAt': endsAt.toUtc().toIso8601String(),
        'target': target,
        'points': points,
        'partnerPoints': partnerPoints,
        'claimed': claimed,
        'preview': preview,
      };
  factory EventProgress.fromJson(Map<String, dynamic> json) {
    if (const ['eventId', 'key', 'chestId', 'startsAt', 'endsAt']
            .any((k) => json[k] is! String) ||
        const ['target', 'points', 'partnerPoints']
            .any((k) => json[k] is! int) ||
        json['claimed'] is! bool ||
        json['preview'] is! bool) {
      throw const FormatException('Invalid event progress');
    }
    final value = EventProgress(
        eventId: json['eventId'] as String,
        key: json['key'] as String,
        chestId: json['chestId'] as String,
        startsAt: DateTime.parse(json['startsAt'] as String),
        endsAt: DateTime.parse(json['endsAt'] as String),
        target: json['target'] as int,
        points: json['points'] as int,
        partnerPoints: json['partnerPoints'] as int,
        claimed: json['claimed'] as bool,
        preview: json['preview'] as bool);
    if (!value.key.startsWith('${value.eventId}:') ||
        !value.startsAt.isUtc ||
        !value.endsAt.isUtc ||
        value.target <= 0 ||
        value.points < 0 ||
        value.partnerPoints < 0 ||
        !value.endsAt.isAfter(value.startsAt) ||
        specialAdventureEventById(value.eventId) == null ||
        specialChestById(value.chestId) == null) {
      throw const FormatException('Invalid event progress');
    }
    return value;
  }
}

int eventAdventurePoints(AdventureKind kind) => switch (kind) {
      AdventureKind.mini => 5,
      AdventureKind.short => 20,
      AdventureKind.long || AdventureKind.group => 50,
      AdventureKind.special => 0,
    };

int eventTrialPoints(TrialGrade grade) => switch (grade) {
      TrialGrade.d => 0,
      TrialGrade.c => 5,
      TrialGrade.b => 10,
      TrialGrade.a => 15,
      TrialGrade.s => 20,
      TrialGrade.sPlus => 25,
    };
