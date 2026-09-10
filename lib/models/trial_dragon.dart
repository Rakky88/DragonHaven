import 'pet.dart';

/// Visible facts needed to render a Trial. No egg genetics or private seed.
abstract interface class TrialDragon {
  String get id;
  String get displayName;
  String get lineageId;
  String get stageKey;
  String get activeEvolutionPath;
  String? get evolutionPath;
  DragonStage get stage;
  bool get spectral;
  bool get prismatic;
  bool get sinister;
  int trainingFor(TrainingFocus focus);
  int trialBest(String trialKey);
}
