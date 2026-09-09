class SeasonalConclaveProject {
  const SeasonalConclaveProject(
      {required this.eventId,
      required this.occurrenceKey,
      required this.completedTrials,
      this.preview = false,
      this.active = false});
  final String eventId, occurrenceKey;
  final int completedTrials;
  final bool preview, active;
  static const milestones = [1, 5, 15, 30, 60];
  int get stage => milestones.where((n) => completedTrials >= n).length;
  int? get nextMilestone =>
      stage == milestones.length ? null : milestones[stage];
  double get fraction =>
      (completedTrials / (nextMilestone ?? milestones.last)).clamp(0, 1);
  bool get sunwake => eventId == 'sunwake_summer_sea';
  String get asset =>
      'assets/images/events/${sunwake ? 'sunwake' : 'harvestmoon'}/conclave_project.png';
  factory SeasonalConclaveProject.fromJson(Map<String, dynamic> json) =>
      SeasonalConclaveProject(
          eventId: json['event_id']?.toString() ?? '',
          occurrenceKey: json['occurrence_key']?.toString() ?? '',
          completedTrials: ((json['completed_trials'] as num?)?.toInt() ?? 0)
              .clamp(0, 1 << 50),
          preview: json['preview'] == true,
          active: json['active'] == true);
}
