import 'package:flutter/material.dart';

import '../models/activity_entry.dart';
import '../models/adventure.dart';
import '../models/achievement.dart';
import '../models/chest.dart';
import '../models/day_phase.dart';
import '../models/dragon_lineage.dart';
import '../models/house.dart';
import '../models/pet.dart';
import '../models/shop_item.dart';
import '../services/release_service.dart';
import 'catalog_translations.dart';
import 'ui_phrase_translations.dart';

class AppStrings {
  const AppStrings(this.languageCode);

  final String languageCode;

  bool get isDutch => languageCode == 'nl';

  static const supportedLanguages = <String, String>{
    'de': 'Deutsch',
    'en': 'English',
    'es': 'Español',
    'fr': 'Français',
    'it': 'Italiano',
    'nl': 'Nederlands',
    'pt': 'Português',
    'zh': '中文',
    'ja': '日本語',
  };

  static AppStrings of(BuildContext context) =>
      AppStrings(Localizations.localeOf(context).languageCode);

  String pick(String english, String dutch) {
    if (languageCode == 'en') return english;
    if (languageCode == 'nl') return dutch;
    return translatedUiPhrase(english, languageCode) ?? english;
  }

  String tr(String key) =>
      _coreTranslations[key]?[languageCode] ??
      _coreTranslations[key]?['en'] ??
      key;

  String achievementTitle(AchievementDefinition achievement) {
    if (languageCode == 'en') return achievement.titleEn;
    if (languageCode == 'nl') return achievement.titleNl;
    return _achievementTranslations[achievement.id]?[languageCode]?[0] ??
        achievement.titleEn;
  }

  String achievementDescription(AchievementDefinition achievement) {
    if (languageCode == 'en') return achievement.descriptionEn;
    if (languageCode == 'nl') return achievement.descriptionNl;
    return _achievementTranslations[achievement.id]?[languageCode]?[1] ??
        achievement.descriptionEn;
  }

  String adventureTitle(AdventureDefinition adventure) {
    if (languageCode == 'en') return adventure.titleEn;
    if (languageCode == 'nl') return adventure.titleNl;
    return translatedAdventureTitle(adventure, languageCode) ??
        adventure.titleEn;
  }

  String adventureDescription(AdventureDefinition adventure) {
    if (languageCode == 'en') return adventure.descriptionEn;
    if (languageCode == 'nl') return adventure.descriptionNl;
    return translatedAdventureDescription(adventure, languageCode) ??
        adventure.descriptionEn;
  }

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return pick('Good morning', 'Goedemorgen');
    if (hour < 18) return pick('Good afternoon', 'Goedemiddag');
    return pick('Good evening', 'Goedenavond');
  }

  String petStage(Pet pet) => petStageNameByKey(pet.stageKey);

  String petStageNameByKey(String stageKey) => switch (stageKey) {
        'moonEgg' => pick('Egg', 'Ei'),
        'spark' => pick('Hatchling', 'Hatchling'),
        'nestDragon' => pick('Wyrmling', 'Wyrmling'),
        _ => pick('Ascended', 'Ascended'),
      };

  String personality(String personality) => switch (personality) {
        'curious' => pick('Curious', 'Nieuwsgierig'),
        _ => personality,
      };

  String dragonLineageName(Pet pet) => lineageName(pet.lineage);

  String lineageName(DragonLineage lineage) =>
      languageCode == 'nl' ? lineage.nameNl : lineage.nameEn;

  String lineageFormName(DragonLineage lineage, String path) =>
      lineage.formName(path, languageCode == 'nl');

  String lineageRarity(DragonLineage lineage) => switch (lineage.rarity) {
        DragonRarity.common => pick('Common', 'Gewoon'),
        DragonRarity.uncommon => pick('Uncommon', 'Ongewoon'),
        DragonRarity.rare => pick('Rare', 'Zeldzaam'),
        DragonRarity.veryRare => pick('Very Rare', 'Zeer zeldzaam'),
        DragonRarity.legendary => pick('Legendary', 'Legendarisch'),
        DragonRarity.mythical => pick('Mythical', 'Mythisch'),
      };

  String dragonFormName(Pet pet) => pet.stageKey == 'moonEgg'
      ? pick('Possible hatchling', 'Mogelijke hatchling')
      : pet.stageKey == 'spark'
          ? lineageName(pet.lineage)
          : lineageFormName(pet.lineage, pet.activeEvolutionPath);

  String dayPhase(HavenDayPhase phase) => switch (phase) {
        HavenDayPhase.deepNight => pick('Deep Night', 'Diepe Nacht'),
        HavenDayPhase.dawn => pick('Dawn', 'Dageraad'),
        HavenDayPhase.morning => pick('Morning', 'Ochtend'),
        HavenDayPhase.day => pick('Day', 'Dag'),
        HavenDayPhase.goldenHour => pick('Golden Hour', 'Gouden Uur'),
        HavenDayPhase.dusk => pick('Dusk', 'Schemering'),
        HavenDayPhase.night => pick('Night', 'Nacht'),
      };

  String levelShort(int level) => switch (languageCode) {
        'de' => 'St. $level',
        'es' || 'pt' => 'Nv. $level',
        'fr' => 'Niv. $level',
        'it' => 'Liv. $level',
        'zh' => '$level 级',
        'ja' => 'Lv.$level',
        _ => 'Lv. $level',
      };

  String adventureDuration(Duration duration) => duration.inDays >= 1
      ? _durationPart(duration.inDays, 'day')
      : _durationPart(duration.inHours, 'hour');

  String remainingDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${_durationPart(duration.inDays, 'day')} '
          '${_durationPart(duration.inHours % 24, 'hour')}';
    }
    if (duration.inHours > 0) {
      return '${_durationPart(duration.inHours, 'hour')} '
          '${_durationPart(duration.inMinutes % 60, 'minute')}';
    }
    return _durationPart(duration.inMinutes.clamp(1, 59), 'minute');
  }

  String evolutionRemaining(Duration duration) {
    final totalHours = (duration.inSeconds + 3599) ~/ 3600;
    final days = totalHours ~/ 24;
    final hours = totalHours % 24;
    if (days > 0) {
      return hours == 0
          ? _durationPart(days, 'day')
          : '${_durationPart(days, 'day')} ${_durationPart(hours, 'hour')}';
    }
    if (totalHours > 0) return _durationPart(totalHours, 'hour');
    return _durationPart(
        ((duration.inSeconds + 59) ~/ 60).clamp(1, 59), 'minute');
  }

  String _durationPart(int value, String unit) =>
      switch ((languageCode, unit)) {
        ('nl', 'hour') => '${value}u',
        ('fr', 'day') => '${value}j',
        ('it', 'day') => '${value}g',
        ('zh', 'day') => '$value天',
        ('zh', 'hour') => '$value小时',
        ('zh', 'minute') => '$value分钟',
        ('ja', 'day') => '$value日',
        ('ja', 'hour') => '$value時間',
        ('ja', 'minute') => '$value分',
        (_, 'day') => '${value}d',
        (_, 'hour') => '${value}h',
        _ => '${value}m',
      };

  String roomName(HouseRoomDefinition room) => switch (room.id) {
        'nest' => pick('Nest room', 'Nestkamer'),
        'hearth' => pick('Hearth room', 'Haardkamer'),
        'crystal' => pick('Crystal Grotto', 'Kristalgrot'),
        'garden' => pick('Moon garden', 'Maantuin'),
        'tidal_library' => pick('Tidal Library', 'Getijdenbibliotheek'),
        'loft' => pick('Star loft', 'Sterrenzolder'),
        'cloud' => pick('Cloud Sanctuary', 'Wolkenheiligdom'),
        'sunforge' => pick('Sunforge', 'Zonnesmederij'),
        _ => pick('Dragon room', 'Drakenkamer'),
      };

  String evolutionHint(Pet pet) => switch (pet.leadingPath) {
        'might' =>
          pick('Might is currently leading.', 'Might staat momenteel voor.'),
        'arcana' =>
          pick('Arcana is currently leading.', 'Arcana staat momenteel voor.'),
        'spirit' =>
          pick('Spirit is currently leading.', 'Spirit staat momenteel voor.'),
        _ => pick('The future form is still a mystery.',
            'De toekomstige vorm is nog een mysterie.'),
      };

  String itemName(ShopItem item) {
    if (languageCode == 'en') return item.name;
    if (languageCode == 'nl') return item.nameNl;
    return translatedItemName(item, languageCode) ?? item.name;
  }

  String itemNameById(String? id) {
    for (final item in shopCatalog) {
      if (item.id == id) return itemName(item);
    }
    return pick('House item', 'Huisitem');
  }

  String itemDescription(ShopItem item) {
    if (languageCode == 'en') return item.description;
    if (languageCode == 'nl') return item.descriptionNl;
    return translatedItemDescription(item, languageCode) ?? item.description;
  }

  String slotLabel(ItemSlot slot) => switch (slot) {
        ItemSlot.bed => pick('Comfort', 'Comfort'),
        ItemSlot.plant => pick('Greenery', 'Groen'),
        ItemSlot.wall => pick('Wall', 'Wand'),
        ItemSlot.light => pick('Magic', 'Magisch'),
      };

  String rarityLabel(ItemRarity rarity) => switch (rarity) {
        ItemRarity.common => pick('Common', 'Gewoon'),
        ItemRarity.special => pick('Special', 'Bijzonder'),
        ItemRarity.rare => pick('Rare', 'Zeldzaam'),
      };

  String chestLabel(ChestTier tier) => switch (tier) {
        ChestTier.wooden => pick('Wooden Chest', 'Houten Kist'),
        ChestTier.silver => pick('Silver Chest', 'Zilveren Kist'),
        ChestTier.gold => pick('Gold Chest', 'Gouden Kist'),
        ChestTier.dragon => pick('Dragon Chest', 'Drakenkist'),
        ChestTier.mythical => pick('Mythical Chest', 'Mythische Kist'),
        ChestTier.sinister => pick('Sinister Chest', 'Sinistere Kist'),
      };

  String activityMessage(ActivityEntry entry) => switch (entry.code) {
        ActivityCode.welcome => pick(
            'A Mysterious Egg appeared in the tower nest.',
            'Er verscheen een Mysterieus Ei in het torennest.'),
        ActivityCode.activityCompleted => pick(
            'A sanctuary activity was completed.',
            'Een activiteit in het reservaat is voltooid.'),
        ActivityCode.bonusFound => pick(
            'Something useful was discovered in the Spire.',
            'Er is iets bruikbaars ontdekt in de Spire.'),
        ActivityCode.chestOpened =>
          pick('A chest was opened.', 'Er is een kist geopend.'),
        ActivityCode.hatched =>
          pick('A dragon hatched!', 'Er is een draak uitgekomen!'),
        ActivityCode.evolved =>
          pick('A dragon evolved.', 'Een draak is geëvolueerd.'),
        ActivityCode.achievement =>
          pick('Achievement unlocked!', 'Achievement ontgrendeld!'),
        ActivityCode.itemPlaced => pick(
            '${itemNameById(entry.subject)} now has a place in the sanctuary.',
            '${itemNameById(entry.subject)} heeft nu een plek in het reservaat.'),
        ActivityCode.legacy => entry.message,
      };

  String releaseError(ReleaseException error) => switch (error.code) {
        ReleaseErrorCode.notConfigured => pick(
            'The GitHub repository is not connected yet. Build with '
                '--dart-define=DRAGONHAVEN_GITHUB_OWNER=yourname.',
            'De GitHub-repository is nog niet gekoppeld. Bouw met '
                '--dart-define=DRAGONHAVEN_GITHUB_OWNER=jouwnaam.'),
        ReleaseErrorCode.noRelease => pick(
            'No public GitHub Release has been published yet.',
            'Er is nog geen openbare GitHub Release gevonden.'),
        ReleaseErrorCode.httpError => pick(
            'GitHub could not be checked (code ${error.statusCode}).',
            'GitHub kon niet worden gecontroleerd (code ${error.statusCode}).'),
        ReleaseErrorCode.invalidData => pick(
            'The latest release contains no valid version data.',
            'De nieuwste release bevat geen geldige versiegegevens.'),
        ReleaseErrorCode.offline => pick(
            'No internet connection. Please try again later.',
            'Geen internetverbinding. Probeer het later opnieuw.'),
        ReleaseErrorCode.handshake => pick(
            'The secure connection to GitHub failed.',
            'De beveiligde verbinding met GitHub is mislukt.'),
        ReleaseErrorCode.format => pick(
            'GitHub returned unexpected release data.',
            'GitHub gaf onverwachte releasegegevens terug.'),
        ReleaseErrorCode.timeout => pick('The release check took too long.',
            'Het controleren van de release duurde te lang.'),
      };
}

const _coreTranslations = <String, Map<String, String>>{
  'adventure': {
    'en': 'Adventure',
    'nl': 'Avontuur',
    'de': 'Abenteuer',
    'fr': 'Aventure',
    'es': 'Aventura',
    'pt': 'Aventura',
    'it': 'Avventura',
    'zh': '冒险',
    'ja': '冒険'
  },
  'tower': {
    'en': 'Dragon Tower',
    'nl': 'Drakentoren',
    'de': 'Drachenturm',
    'fr': 'Tour des dragons',
    'es': 'Torre del dragón',
    'pt': 'Torre do dragão',
    'it': 'Torre dei draghi',
    'zh': '龙塔',
    'ja': 'ドラゴンタワー'
  },
  'friends': {
    'en': 'Friends',
    'nl': 'Vrienden',
    'de': 'Freunde',
    'fr': 'Amis',
    'es': 'Amigos',
    'pt': 'Amigos',
    'it': 'Amici',
    'zh': '好友',
    'ja': 'フレンド'
  },
  'inventory': {
    'en': 'Inventory',
    'nl': 'Inventaris',
    'de': 'Inventar',
    'fr': 'Inventaire',
    'es': 'Inventario',
    'pt': 'Inventário',
    'it': 'Inventario',
    'zh': '库存',
    'ja': '所持品'
  },
  'shop': {
    'en': 'Shop',
    'nl': 'Winkel',
    'de': 'Laden',
    'fr': 'Boutique',
    'es': 'Tienda',
    'pt': 'Loja',
    'it': 'Negozio',
    'zh': '商店',
    'ja': 'ショップ'
  },
  'account': {
    'en': 'Account Info',
    'nl': 'Accountinfo',
    'de': 'Kontoinfo',
    'fr': 'Compte',
    'es': 'Cuenta',
    'pt': 'Conta',
    'it': 'Account',
    'zh': '账户信息',
    'ja': 'アカウント'
  },
  'language': {
    'en': 'Language',
    'nl': 'Taal',
    'de': 'Sprache',
    'fr': 'Langue',
    'es': 'Idioma',
    'pt': 'Idioma',
    'it': 'Lingua',
    'zh': '语言',
    'ja': '言語'
  },
  'achievements': {
    'en': 'Achievements',
    'nl': 'Prestaties',
    'de': 'Erfolge',
    'fr': 'Succès',
    'es': 'Logros',
    'pt': 'Conquistas',
    'it': 'Obiettivi',
    'zh': '成就',
    'ja': '実績'
  },
  'more': {
    'en': 'More options',
    'nl': 'Meer opties',
    'de': 'Mehr Optionen',
    'fr': 'Plus d’options',
    'es': 'Más opciones',
    'pt': 'Mais opções',
    'it': 'Altre opzioni',
    'zh': '更多选项',
    'ja': 'その他'
  },
  'coins': {
    'en': 'coins',
    'nl': 'munten',
    'de': 'Münzen',
    'fr': 'pièces',
    'es': 'monedas',
    'pt': 'moedas',
    'it': 'monete',
    'zh': '金币',
    'ja': 'コイン'
  },
  'gems': {
    'en': 'gems',
    'nl': 'edelstenen',
    'de': 'Edelsteine',
    'fr': 'gemmes',
    'es': 'gemas',
    'pt': 'gemas',
    'it': 'gemme',
    'zh': '宝石',
    'ja': 'ジェム'
  },
  'music': {
    'en': 'Music',
    'nl': 'Muziek',
    'de': 'Musik',
    'fr': 'Musique',
    'es': 'Música',
    'pt': 'Música',
    'it': 'Musica',
    'zh': '音乐',
    'ja': '音楽'
  },
  'sound_effects': {
    'en': 'Sound Effects',
    'nl': 'Geluidseffecten',
    'de': 'Soundeffekte',
    'fr': 'Effets sonores',
    'es': 'Efectos de sonido',
    'pt': 'Efeitos sonoros',
    'it': 'Effetti sonori',
    'zh': '音效',
    'ja': '効果音'
  },
  'on': {
    'en': 'On',
    'nl': 'Aan',
    'de': 'An',
    'fr': 'Activé',
    'es': 'Sí',
    'pt': 'Ligado',
    'it': 'On',
    'zh': '开',
    'ja': 'オン'
  },
  'off': {
    'en': 'Off',
    'nl': 'Uit',
    'de': 'Aus',
    'fr': 'Désactivé',
    'es': 'No',
    'pt': 'Desligado',
    'it': 'Off',
    'zh': '关',
    'ja': 'オフ'
  },
  'save': {
    'en': 'Save',
    'nl': 'Opslaan',
    'de': 'Speichern',
    'fr': 'Enregistrer',
    'es': 'Guardar',
    'pt': 'Salvar',
    'it': 'Salva',
    'zh': '保存',
    'ja': '保存'
  },
  'cancel': {
    'en': 'Cancel',
    'nl': 'Annuleren',
    'de': 'Abbrechen',
    'fr': 'Annuler',
    'es': 'Cancelar',
    'pt': 'Cancelar',
    'it': 'Annulla',
    'zh': '取消',
    'ja': 'キャンセル'
  },
  'coming_online': {
    'en': 'Online service coming later',
    'nl': 'Online service komt later',
    'de': 'Onlinedienst folgt später',
    'fr': 'Service en ligne à venir',
    'es': 'Servicio en línea próximamente',
    'pt': 'Serviço online em breve',
    'it': 'Servizio online in arrivo',
    'zh': '在线服务即将推出',
    'ja': 'オンライン機能は今後追加'
  },
  'achievement_unlocked': {
    'en': 'Achievement unlocked',
    'nl': 'Prestatie behaald',
    'de': 'Erfolg freigeschaltet',
    'fr': 'Succès débloqué',
    'es': 'Logro desbloqueado',
    'pt': 'Conquista desbloqueada',
    'it': 'Obiettivo sbloccato',
    'zh': '成就已解锁',
    'ja': '実績解除'
  },
  'tap_to_continue': {
    'en': 'Tap to continue',
    'nl': 'Tik om door te gaan',
    'de': 'Tippen zum Fortfahren',
    'fr': 'Touchez pour continuer',
    'es': 'Toca para continuar',
    'pt': 'Toque para continuar',
    'it': 'Tocca per continuare',
    'zh': '点击继续',
    'ja': 'タップして続ける'
  },
};

const _achievementTranslations = <String, Map<String, List<String>>>{
  'hello_little_one': {
    'de': ['Hallo, Kleines!', 'Brüte dein Starter-Ei aus.'],
    'es': ['¡Hola, pequeñín!', 'Haz eclosionar tu Huevo Inicial.'],
    'fr': ['Bonjour, petit !', 'Fais éclore ton Œuf de départ.'],
    'it': ['Ciao, piccolino!', 'Fai schiudere il tuo Uovo iniziale.'],
    'pt': ['Olá, pequenino!', 'Faça seu Ovo Inicial chocar.'],
    'zh': ['你好，小家伙！', '孵化你的初始龙蛋。'],
    'ja': ['こんにちは、ちびちゃん！', '最初のドラゴンの卵を孵化させる。'],
  },
  'first_flight': {
    'de': ['Erster Flug', 'Schließe dein erstes kurzes Abenteuer ab.'],
    'es': ['Primer vuelo', 'Completa tu primera Aventura corta.'],
    'fr': ['Premier vol', 'Termine ta première Aventure courte.'],
    'it': ['Primo volo', 'Completa la tua prima Avventura breve.'],
    'pt': ['Primeiro voo', 'Conclua sua primeira Aventura curta.'],
    'zh': ['初次飞行', '完成第一次短途冒险。'],
    'ja': ['はじめての飛行', '最初のショート冒険を完了する。'],
  },
  'chest_expectations': {
    'de': ['Truhige Erwartungen', 'Öffne deine erste Truhe.'],
    'es': ['Grandes expectativas', 'Abre tu primer cofre.'],
    'fr': ['Coffre à grandes attentes', 'Ouvre ton premier coffre.'],
    'it': ['Grandi aspettative', 'Apri il tuo primo forziere.'],
    'pt': ['Grandes expectativas', 'Abra seu primeiro baú.'],
    'zh': ['开箱有望', '打开你的第一个宝箱。'],
    'ja': ['箱への期待', '最初の宝箱を開ける。'],
  },
  'room_to_roost': {
    'de': ['Platz zum Nisten', 'Kaufe dein erstes zusätzliches Turmgeschoss.'],
    'es': ['Sitio para anidar', 'Compra tu primer piso adicional de la Torre.'],
    'fr': [
      'De la place pour nicher',
      'Achète ton premier étage supplémentaire.'
    ],
    'it': [
      'Spazio per il nido',
      'Compra il primo piano aggiuntivo della Torre.'
    ],
    'pt': ['Espaço para o ninho', 'Compre o primeiro andar extra da Torre.'],
    'zh': ['安巢之所', '购买第一层额外的龙塔楼层。'],
    'ja': ['巣ごもりの部屋', 'ドラゴンタワーの追加階を初めて購入する。'],
  },
  'feed_furniture': {
    'de': [
      'Bitte nicht die Möbel füttern',
      'Platziere dein erstes Möbelstück.'
    ],
    'es': ['No alimentes los muebles', 'Coloca tu primer mueble.'],
    'fr': ['Ne nourrissez pas les meubles', 'Place ton premier meuble.'],
    'it': ['Non dare da mangiare ai mobili', 'Posiziona il tuo primo mobile.'],
    'pt': ['Não alimente os móveis', 'Posicione seu primeiro móvel.'],
    'zh': ['请勿投喂家具', '摆放你的第一件家具。'],
    'ja': ['家具にエサを与えないで', '最初の家具を配置する。'],
  },
  'book_wyrm': {
    'de': ['Bücherwyrm', 'Entdecke 5 gewöhnliche Drachenfamilien.'],
    'es': [
      'Gusano de libros con alas',
      'Descubre 5 familias de dragones comunes.'
    ],
    'fr': ['Wyrm de bibliothèque', 'Découvre 5 familles de dragons communes.'],
    'it': ['Drago da biblioteca', 'Scopri 5 famiglie di draghi comuni.'],
    'pt': ['Dragão de biblioteca', 'Descubra 5 famílias de dragões comuns.'],
    'zh': ['书中之龙', '发现 5 个普通龙族。'],
    'ja': ['本の虫ならぬ本の竜', 'コモンのドラゴン一族を5種発見する。'],
  },
  'growing_pains': {
    'de': ['Wachstumsschmerzen', 'Entwickle einen Schlüpfling zum Jungwyrm.'],
    'es': ['Dolores de crecimiento', 'Evoluciona una cría a dragón joven.'],
    'fr': ['Crise de croissance', 'Fais évoluer un nouveau-né en jeune wyrm.'],
    'it': [
      'Dolori della crescita',
      'Fai evolvere un cucciolo in giovane wyrm.'
    ],
    'pt': ['Dores do crescimento', 'Evolua um filhote para um jovem wyrm.'],
    'zh': ['成长的烦恼', '让一只幼龙进化为少年龙。'],
    'ja': ['成長痛', '孵化した幼竜を若竜へ進化させる。'],
  },
  'not_picking_favorites': {
    'de': [
      'Ganz bestimmt keine Lieblinge',
      'Markiere einen Drachen als Favoriten.'
    ],
    'es': ['Aquí no hay favoritos', 'Marca un dragón como favorito.'],
    'fr': ['Pas de favoritisme, promis', 'Marque un dragon comme favori.'],
    'it': ['Nessun preferito, davvero', 'Segna un drago come preferito.'],
    'pt': ['Sem favoritos, claro', 'Marque um dragão como favorito.'],
    'zh': ['绝对没有偏心', '将一只龙标记为最爱。'],
    'ja': ['えこひいきではありません', 'ドラゴンをお気に入りにする。'],
  },
  'halfway_clouds': {
    'de': ['Halbwegs zu den Wolken', 'Baue 10 Stockwerke im Drachenturm.'],
    'es': ['A medio camino de las nubes', 'Construye 10 pisos de la Torre.'],
    'fr': ['À mi-chemin des nuages', 'Construis 10 étages de la Tour.'],
    'it': ['A metà strada dalle nuvole', 'Costruisci 10 piani della Torre.'],
    'pt': ['No meio do caminho até as nuvens', 'Construa 10 andares da Torre.'],
    'zh': ['半途入云', '建造 10 层龙塔。'],
    'ja': ['雲まであと半分', 'ドラゴンタワーを10階まで建てる。'],
  },
  'ascension_day': {
    'de': ['Tag des Aufstiegs', 'Entwickle deinen ersten Erhabenen Drachen.'],
    'es': ['Día de la ascensión', 'Evoluciona tu primer dragón Ascendido.'],
    'fr': [
      'Jour de l’Ascension',
      'Fais évoluer ton premier dragon Transcendé.'
    ],
    'it': ['Giorno dell’ascensione', 'Ottieni il tuo primo drago Asceso.'],
    'pt': ['Dia da ascensão', 'Evolua seu primeiro dragão Ascendido.'],
    'zh': ['飞升之日', '让第一只龙进化为升华形态。'],
    'ja': ['昇華の日', '最初のドラゴンをアセンデッドへ進化させる。'],
  },
  'something_spectral': {
    'de': ['Etwas Spektrales naht', 'Entdecke deinen ersten Spektraldrachen.'],
    'es': ['Algo espectral se acerca', 'Descubre tu primer dragón Espectral.'],
    'fr': ['Un spectre approche', 'Découvre ton premier dragon Spectral.'],
    'it': [
      'Qualcosa di spettrale arriva',
      'Scopri il tuo primo drago Spettrale.'
    ],
    'pt': [
      'Algo espectral se aproxima',
      'Descubra seu primeiro dragão Espectral.'
    ],
    'zh': ['幽光将至', '发现第一只幻彩龙。'],
    'ja': ['スペクトラルな何かが来る', '最初のスペクトラルドラゴンを発見する。'],
  },
  'well_read_scaled': {
    'de': [
      'Belesen und beschuppt',
      'Entdecke alle 20 gewöhnlichen Drachenfamilien.'
    ],
    'es': ['Bien leído, bien escamado', 'Descubre las 20 familias comunes.'],
    'fr': ['Bien lu, bien écailleux', 'Découvre les 20 familles communes.'],
    'it': ['Colto e ben squamato', 'Scopri tutte le 20 famiglie comuni.'],
    'pt': ['Bem lido, bem escamado', 'Descubra as 20 famílias comuns.'],
    'zh': ['博览群龙', '发现全部 20 个普通龙族。'],
    'ja': ['読書家は鱗も立派', 'コモンのドラゴン一族20種をすべて発見する。'],
  },
  'frequent_flyer': {
    'de': ['Vielflieger', 'Schließe 50 Abenteuer ab.'],
    'es': ['Viajero frecuente', 'Completa 50 Aventuras.'],
    'fr': ['Grand voyageur', 'Termine 50 Aventures.'],
    'it': ['Volo frequente', 'Completa 50 Avventure.'],
    'pt': ['Viajante frequente', 'Conclua 50 Aventuras.'],
    'zh': ['飞行常客', '完成 50 次冒险。'],
    'ja': ['空の常連', '冒険を50回完了する。'],
  },
  'full_party': {
    'de': [
      'Volle Gruppe, volle Kraft',
      'Schließe ein Gruppenabenteuer mit 4 Teilnehmern ab.'
    ],
    'es': [
      'Grupo completo, sin frenos',
      'Completa una Aventura grupal con 4 participantes.'
    ],
    'fr': ['Équipe au complet', 'Termine une Aventure de groupe à 4.'],
    'it': [
      'Gruppo pieno, avanti tutta',
      'Completa un’Avventura di gruppo con 4 partecipanti.'
    ],
    'pt': [
      'Grupo completo, força total',
      'Conclua uma Aventura em grupo com 4 participantes.'
    ],
    'zh': ['满员出发', '与 4 名参与者完成一次团队冒险。'],
    'ja': ['フルパーティー、全速前進', '4人でグループ冒険を完了する。'],
  },
  'came_crawling_back': {
    'de': [
      'Sieh an, wer zurückgekrochen kam',
      'Erhalte Wochenbesuch von einem freigelassenen Drachen.'
    ],
    'es': [
      'Mira quién volvió arrastrándose',
      'Recibe la visita semanal de un dragón liberado.'
    ],
    'fr': [
      'Tiens, qui revoilà',
      'Reçois la visite hebdomadaire d’un dragon libéré.'
    ],
    'it': [
      'Guarda chi è tornato strisciando',
      'Ricevi la visita settimanale di un drago liberato.'
    ],
    'pt': [
      'Olha quem voltou rastejando',
      'Receba a visita semanal de um dragão libertado.'
    ],
    'zh': ['看看谁爬回来了', '迎来一只已放归龙的每周拜访。'],
    'ja': ['這い戻ってきたのは誰？', '放したドラゴンの週替わり訪問を受ける。'],
  },
  'sky_ceiling': {
    'de': ['Der Himmel hat doch eine Decke', 'Erreiche 20 Turmgeschosse.'],
    'es': ['El cielo sí tenía techo', 'Alcanza 20 pisos de la Torre.'],
    'fr': ['Le ciel a donc un plafond', 'Atteins 20 étages de la Tour.'],
    'it': [
      'Il cielo ha davvero un soffitto',
      'Raggiungi 20 piani della Torre.'
    ],
    'pt': ['O céu tem teto, afinal', 'Alcance 20 andares da Torre.'],
    'zh': ['天空原来也有天花板', '将龙塔建到 20 层。'],
    'ja': ['空にも天井はあった', 'ドラゴンタワーを20階まで建てる。'],
  },
  'scale_every_tale': {
    'de': [
      'Eine Schuppe für jede Geschichte',
      'Entdecke alle 42 Drachenfamilien.'
    ],
    'es': [
      'Una escama para cada historia',
      'Descubre las 42 familias de dragones.'
    ],
    'fr': [
      'Une écaille pour chaque histoire',
      'Découvre les 42 familles de dragons.'
    ],
    'it': [
      'Una squama per ogni storia',
      'Scopri tutte le 42 famiglie di draghi.'
    ],
    'pt': [
      'Uma escama para cada história',
      'Descubra as 42 famílias de dragões.'
    ],
    'zh': ['一族一传奇', '发现全部 42 个龙族。'],
    'ja': ['物語ごとに一枚の鱗', 'ドラゴン一族42種をすべて発見する。'],
  },
  'ghost_writer': {
    'de': ['Geisterschreiber', 'Entdecke Spektralformen von 10 Familien.'],
    'es': ['Escritor fantasma', 'Descubre formas Espectrales de 10 familias.'],
    'fr': ['Nègre spectral', 'Découvre les formes Spectrales de 10 familles.'],
    'it': ['Scrittore fantasma', 'Scopri forme Spettrali di 10 famiglie.'],
    'pt': ['Escritor fantasma', 'Descubra formas Espectrais de 10 famílias.'],
    'zh': ['幽灵作家', '发现 10 个龙族的幻彩形态。'],
    'ja': ['ゴーストライター', '10一族のスペクトラル形態を発見する。'],
  },
  'myth_made_real': {
    'de': [
      'Mythos wird Wirklichkeit',
      'Erhalte einen Drachen aus einer mythischen Familie.'
    ],
    'es': ['El mito hecho realidad', 'Obtén un dragón de familia Mítica.'],
    'fr': [
      'Le mythe devient réalité',
      'Obtiens un dragon d’une famille Mythique.'
    ],
    'it': ['Il mito diventa realtà', 'Ottieni un drago di famiglia Mitica.'],
    'pt': ['O mito se torna real', 'Obtenha um dragão de família Mítica.'],
    'zh': ['神话成真', '获得一只神话族龙。'],
    'ja': ['神話が現実に', 'ミシカル一族のドラゴンを手に入れる。'],
  },
  'probably_fine': {
    'de': [
      'Das geht bestimmt gut',
      'Schließe ein finsteres Spezialabenteuer ab.'
    ],
    'es': [
      'Seguro que todo sale bien',
      'Completa una Aventura especial siniestra.'
    ],
    'fr': [
      'Ça va sûrement bien se passer',
      'Termine une Aventure spéciale sinistre.'
    ],
    'it': [
      'Andrà sicuramente tutto bene',
      'Completa un’Avventura speciale sinistra.'
    ],
    'pt': [
      'Provavelmente vai dar tudo certo',
      'Conclua uma Aventura especial sinistra.'
    ],
    'zh': ['大概没事吧', '完成一次诡秘特殊冒险。'],
    'ja': ['たぶん大丈夫', '不吉なスペシャル冒険を完了する。'],
  },
};
