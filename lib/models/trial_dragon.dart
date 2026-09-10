import 'dragon_appearance.dart';
import 'pet.dart';

/// Visible facts needed to render a Trial. No egg genetics or private seed.
abstract interface class TrialDragon implements DragonAppearance {
  String get displayName;
  String? get evolutionPath;
  bool get prismatic;
  int trainingFor(TrainingFocus focus);
  int trialBest(String trialKey);
}
