import 'package:flutter/material.dart';

import '../models/activity_entry.dart';
import '../models/house.dart';
import '../models/pet.dart';
import '../models/shop_item.dart';
import '../services/release_service.dart';

class AppStrings {
  const AppStrings(this.languageCode);

  final String languageCode;

  bool get isDutch => languageCode == 'nl';

  static const supportedLanguages = <String, String>{
    'en': 'English',
    'nl': 'Nederlands',
    'de': 'Deutsch',
    'fr': 'Français',
    'es': 'Español',
    'pt': 'Português',
    'it': 'Italiano',
    'zh': '中文',
    'ja': '日本語',
  };

  static AppStrings of(BuildContext context) =>
      AppStrings(Localizations.localeOf(context).languageCode);

  String pick(String english, String dutch) => isDutch ? dutch : english;

  String tr(String key) =>
      _coreTranslations[key]?[languageCode] ??
      _coreTranslations[key]?['en'] ??
      key;

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return pick('Good morning', 'Goedemorgen');
    if (hour < 18) return pick('Good afternoon', 'Goedemiddag');
    return pick('Good evening', 'Goedenavond');
  }

  String petStage(Pet pet) => petStageNameByKey(pet.stageKey);

  String petStageNameByKey(String stageKey) => switch (stageKey) {
        'moonEgg' => pick('Egg', 'Ei'),
        'spark' => 'Hatchling',
        'nestDragon' => 'Wyrmling',
        _ => 'Ascended',
      };

  String personality(String personality) => switch (personality) {
        'curious' => pick('Curious', 'Nieuwsgierig'),
        _ => personality,
      };

  String dragonLineageName(Pet pet) => pet.lineage.name(isDutch);

  String dragonFormName(Pet pet) => pet.stageKey == 'moonEgg'
      ? pick('Possible hatchling', 'Mogelijke hatchling')
      : pet.stageKey == 'spark'
          ? pet.lineage.name(isDutch)
          : pet.lineage.formName(pet.activeEvolutionPath, isDutch);

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

  String itemName(ShopItem item) => isDutch ? item.nameNl : item.name;

  String itemNameById(String? id) {
    for (final item in shopCatalog) {
      if (item.id == id) return itemName(item);
    }
    return pick('House item', 'Huisitem');
  }

  String itemDescription(ShopItem item) =>
      isDutch ? item.descriptionNl : item.description;

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
  'stash': {
    'en': 'Stash',
    'nl': 'Voorraad',
    'de': 'Vorrat',
    'fr': 'Réserve',
    'es': 'Almacén',
    'pt': 'Reserva',
    'it': 'Scorta',
    'zh': '仓库',
    'ja': '保管庫'
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
};
