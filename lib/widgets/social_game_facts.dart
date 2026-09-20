import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../models/dragon_emote.dart';
import '../providers/household_provider.dart';
import '../services/canonical_game_session.dart';
import '../services/canonical_game_snapshot.dart';

/// Public facts used by social screens. Server accounts never open a local save.
class SocialGameFacts {
  SocialGameFacts._(this.languageCode, this.achievementIds, this.emotes,
      this.favorite, this.records);
  final String languageCode;
  final Set<String> achievementIds;
  final List<DragonEmoteDefinition> emotes;
  final ({String name, String lineageId})? favorite;
  final Map<String, int> records;

  static SocialGameFacts read(BuildContext context) {
    final session = context.read<CanonicalGameSession?>();
    if (session != null) {
      final view = session.snapshot;
      if (view == null) {
        throw const CanonicalGameException('game_snapshot_unavailable');
      }
      final collection = view.data['collection'] as Map;
      final ids = (collection['ownedDragonEmoteIds'] as List).cast<String>();
      final favorite =
          view.dragons.where((d) => d.owned && d.favorite).firstOrNull;
      return SocialGameFacts._(
          view.profile.preferences['languageCode'] as String,
          (collection['achievements'] as List).cast<String>().toSet(),
          ids.map(dragonEmoteById).whereType<DragonEmoteDefinition>().toList(),
          favorite == null
              ? null
              : (name: favorite.name, lineageId: favorite.lineageId),
          _best(view.dragons
              .where((d) => d.owned)
              .map((d) => d.trialHighScores)));
    }
    final game = context.read<HouseholdProvider>();
    final dragons = [game.pet, ...game.sanctuaryDragons].where((d) => !d.isEgg);
    final favorite = dragons.where((d) => d.favorite).firstOrNull;
    return SocialGameFacts._(
        game.languageCode,
        game.unlockedAchievementIds,
        game.ownedDragonEmotes,
        favorite == null
            ? null
            : (name: favorite.displayName, lineageId: favorite.lineageId),
        _best(dragons.map((d) => d.trialHighScores)));
  }

  static Map<String, int> _best(Iterable<Map<String, int>> scores) {
    final result = <String, int>{};
    for (final score in scores) {
      for (final entry in score.entries) {
        if (entry.value > (result[entry.key] ?? 0)) {
          result[entry.key] = entry.value;
        }
      }
    }
    return Map.unmodifiable(result);
  }
}
