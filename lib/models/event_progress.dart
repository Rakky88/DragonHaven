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
      this.rankingHidden = false,
      this.preview = false});

  final String eventId, key, chestId;
  final DateTime startsAt, endsAt;
  final int target;
  int points, partnerPoints;
  bool claimed;
  // Presentation retirement only: earned points and chest claims are preserved.
  bool rankingHidden;
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
        'targetPolicyVersion': 2,
        'points': points,
        'partnerPoints': partnerPoints,
        'claimed': claimed,
        'rankingHidden': rankingHidden,
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
    final policy = json['targetPolicyVersion'] ?? 1;
    if (policy is! int || (policy != 1 && policy != 2)) {
      throw const FormatException('Invalid event target policy');
    }
    final storedTarget = json['target'] as int;
    // Upgrade the former 1,000/day (Valentine 2,000/day) exactly once.
    // Stored durations may predate calendar extensions; preserve that window.
    final oldDailyTarget =
        json['eventId'] == 'valentine_two_heartlights' ? 2000 : 1000;
    // Older app builds omit unknown fields when saving. Already lowered goals
    // in the current calendar must survive that round trip without a new cut.
    final target = policy == 1 && storedTarget % oldDailyTarget == 0
        ? (storedTarget * 7 + 9) ~/ 10
        : storedTarget;
    final value = EventProgress(
        eventId: json['eventId'] as String,
        key: json['key'] as String,
        chestId: json['chestId'] as String,
        startsAt: DateTime.parse(json['startsAt'] as String),
        endsAt: DateTime.parse(json['endsAt'] as String),
        target: target,
        points: json['points'] as int,
        partnerPoints: json['partnerPoints'] as int,
        claimed: json['claimed'] as bool,
        rankingHidden: json['rankingHidden'] == true,
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
