import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/adventure.dart';
import '../models/dragon_egg.dart';
import 'dragon_art.dart';

class EggArt extends StatelessWidget {
  const EggArt({
    super.key,
    required this.lineageId,
    this.specialEggId,
    this.height = 86,
  });

  final String lineageId;
  final String? specialEggId;
  final double height;

  @override
  Widget build(BuildContext context) {
    final special = specialEggById(specialEggId) ??
        (specialEggId == null ? specialEggForLineage(lineageId) : null);
    if (special == null) {
      return DragonArt(
        height: height,
        animate: false,
        stageKey: 'moonEgg',
      );
    }
    return Semantics(
      image: true,
      child: Image.asset(
        special.assetPath,
        height: height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

String dragonEggDisplayName(AppStrings strings, DragonEgg egg) {
  final definition = specialEggById(egg.specialEggId) ??
      (egg.isSpecialEgg ? specialEggForLineage(egg.lineageId) : null);
  if (definition != null) {
    return strings.languageCode == 'nl'
        ? definition.titleNl
        : definition.titleEn;
  }
  return strings.eggName(
    sinister: egg.isSinisterEgg,
    special: egg.isSpecialEgg,
  );
}
