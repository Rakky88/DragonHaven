import 'pet.dart';

/// Public facts sufficient for existing dragon art and milestone animations.
abstract interface class DragonAppearance {
  String get id;
  String get lineageId;
  String get stageKey;
  String get activeEvolutionPath;
  DragonStage get stage;
  bool get spectral;
  bool get sinister;
}
