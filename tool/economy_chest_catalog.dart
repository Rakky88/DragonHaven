import 'dart:convert';
import 'dart:io';

import 'package:dragon_haven/models/account_title.dart';
import 'package:dragon_haven/models/adventure.dart';
import 'package:dragon_haven/models/day_phase.dart';
import 'package:dragon_haven/models/dragon_emote.dart';
import 'package:dragon_haven/models/dragon_lineage.dart';
import 'package:dragon_haven/models/music_track.dart';
import 'package:dragon_haven/models/mystic_relic.dart';
import 'package:dragon_haven/models/profile_portrait.dart';

/// Versioned server snapshot. Changes require a NEW forward migration once 45
/// has been applied. Never regenerate an already applied migration in place.
Map<String, Object?> economyChestCatalog() => {
      'version': 2,
      'portrait': profilePortraitCatalog.map((item) => item.id).toList(),
      'title': accountTitleCatalog.map((item) => item.id).toList(),
      'music': musicCatalog.map((item) => item.id).toList(),
      'emote': dragonEmotesForSource(DragonEmoteSource.chest)
          .map((item) => item.id)
          .toList(),
      'relic': MysticRelic.values.map((item) => item.name).toList(),
      'relic_weights': {
        for (final r in MysticRelic.values) r.name: r.dropWeight
      },
      'unique_relics': MysticRelic.values
          .where((r) => r.isEquipable)
          .map((r) => r.name)
          .toList(),
      'lineages': {
        for (final rarity in DragonRarity.values)
          rarity.name: standardDragonLineages
              .where((item) => item.rarity == rarity)
              .map((item) => item.id)
              .toList(),
      },
      'spectral_chance': 1 / spectralEggBaseRollSides,
      'special_eggs': {
        for (final egg in specialEggCatalog.values)
          egg.id: {
            'lineage': egg.lineageId,
            'incubation_seconds': egg.incubation.inSeconds,
            'moral': egg.fixedMoral?.name,
            'moral_known_at_hatch': egg.moralKnownAtHatch,
            'spectral_chance': egg.normalSpectralChance,
          },
      },
      'special_chests': {
        for (final chest in specialChestCatalog.values)
          chest.id: {
            'coins': chest.coins,
            'gems': chest.gems,
            'egg': chest.specialEggId,
          },
      },
      // Probabilities and inclusive ranges match HouseholdProvider's live
      // rules. Cumulative rarity order: common through mythical.
      'tiers': {
        'wooden': _tier(
            20, 40, 0, 0, 0, .01, 0, .005, [.75, .95, .995, .9995, .99999]),
        'silver':
            _tier(45, 80, .5, 1, 2, .04, 0, .01, [.65, .90, .98, .997, .9998]),
        'gold': _tier(
            90, 160, .72, 2, 4, .12, .01, .02, [.50, .80, .94, .99, .999]),
        'dragon':
            _tier(180, 300, .90, 4, 7, 1, .02, .04, [.25, .55, .80, .95, .995]),
        'mythical':
            _tier(400, 650, 1, 8, 13, 1, .04, .08, [.10, .30, .55, .80, .97]),
        'sinister':
            _tier(400, 650, 1, 8, 13, 1, 1, .12, [.10, .30, .55, .80, .97]),
      },
    };

Map<String, Object?> _tier(
        int coinsMin,
        int coinsMax,
        double gemChance,
        int gemsMin,
        int gemsMax,
        double eggChance,
        double relicChance,
        double emoteChance,
        List<double> rarity) =>
    {
      'coins_min': coinsMin,
      'coins_max': coinsMax,
      'gem_chance': gemChance,
      'gems_min': gemsMin,
      'gems_max': gemsMax,
      'egg_chance': eggChance,
      'relic_chance': relicChance,
      'emote_chance': emoteChance,
      'rarity': rarity,
    };

void main(List<String> arguments) {
  final snapshot = jsonEncode(economyChestCatalog());
  if (arguments.length != 1 || arguments.single != '--verify') {
    stdout.writeln(snapshot);
    return;
  }
  final sql = File('supabase/migrations/'
          '202609080058_equipment_relic_pool.sql')
      .readAsStringSync();
  if (!sql.contains('\$catalog\$$snapshot\$catalog\$::jsonb')) {
    stderr.writeln(
        'Server chest catalog drift: add a forward catalog migration.');
    exitCode = 1;
    return;
  }
  stdout.writeln('Server chest catalog matches the client catalogs.');
}
