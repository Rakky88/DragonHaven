import 'package:flutter/material.dart';
import '../models/adventure.dart';
import '../models/social.dart';
import '../models/trial.dart';
import 'trial_rankings_sheet.dart';

Future<void> showSeasonalTrialRankingsSheet(
  BuildContext context, {
  required SpecialAdventureEventDefinition event,
  required bool preview,
}) =>
    showTrialRankingsSheet(context,
        scopes: const [TrialRankingScope.world, TrialRankingScope.friends],
        initialScope: TrialRankingScope.world,
        initialKind: trialDefinitions.values
            .firstWhere((trial) => trial.specialEventId == event.id)
            .kind);
