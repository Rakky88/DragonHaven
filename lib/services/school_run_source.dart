import 'package:flutter/foundation.dart';

import '../models/dragon_school.dart';
import '../models/pet.dart';

/// Only the visible pupil facts used by the Academy; never a reconstructed Pet.
class SchoolStudent {
  const SchoolStudent(
      {required this.id,
      required this.displayName,
      required this.lineageId,
      required this.stage,
      required this.path,
      required this.spectral,
      required this.sinister,
      required this.attempts,
      required this.stars,
      required this.complete,
      required this.outcome});
  factory SchoolStudent.fromPet(Pet pet) => SchoolStudent(
      id: pet.id,
      displayName: pet.displayName,
      lineageId: pet.lineageId,
      stage: pet.stage,
      path: pet.activeEvolutionPath,
      spectral: pet.spectral,
      sinister: pet.sinister,
      attempts: Map.unmodifiable(pet.dragonSchoolAttempts),
      stars: Map.unmodifiable(pet.dragonSchoolStars),
      complete: pet.dragonSchoolComplete,
      outcome: pet.dragonSchoolOutcome);
  final String id, displayName, lineageId, path;
  final DragonStage stage;
  final bool spectral, sinister, complete;
  final DragonSchoolOutcome outcome;
  final Map<String, int> attempts, stars;
  String get stageKey => switch (stage) {
        DragonStage.egg => 'moonEgg',
        DragonStage.hatchling => 'spark',
        DragonStage.wyrmling => 'nestDragon',
        DragonStage.ascended => 'homeGuardian',
      };
  String get activeEvolutionPath => path;
  bool get dragonSchoolComplete => complete;
  DragonSchoolOutcome get dragonSchoolOutcome => outcome;
  bool get dragonSchoolDropout => outcome == DragonSchoolOutcome.dropout;
  int schoolAttempts(String id) => attempts[id] ?? 0;
  int schoolStars(String id) => stars[id] ?? 0;
}

/// The screen shares its artwork and input model between local and server play.
/// An authoritative source receives inputs only and derives its own result.
abstract class SchoolRunSource extends ChangeNotifier {
  List<SchoolStudent> get participants;
  SchoolStudent? get mentor;
  int get keeperBest;
  bool get accountCurrent;
  Future<int> start();
  Future<DragonSchoolLessonResult> finish(String inputs);
  Future<void> cancel();
}
