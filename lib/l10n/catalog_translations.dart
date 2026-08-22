import '../models/adventure.dart';
import '../models/shop_item.dart';

const catalogLanguageIndex = <String, int>{
  'de': 0,
  'es': 1,
  'fr': 2,
  'it': 3,
  'pt': 4,
  'zh': 5,
  'ja': 6,
};

String _catalogValue(String languageCode, List<String> values) =>
    values[catalogLanguageIndex[languageCode]!];

String? translatedItemName(ShopItem item, String languageCode) {
  if (!catalogLanguageIndex.containsKey(languageCode)) return null;
  final original = _originalItemNames[item.id];
  if (original != null) return _catalogValue(languageCode, original);
  final parts = item.id.split('_');
  if (parts.length != 3 || parts.first != 'decor') return null;
  final theme = _furnitureThemes[parts[1]];
  final form = _furnitureForms[parts[2]];
  if (theme == null || form == null) return null;
  return '${_catalogValue(languageCode, theme)} ${_catalogValue(languageCode, form)}';
}

String? translatedItemDescription(ShopItem item, String languageCode) {
  if (!catalogLanguageIndex.containsKey(languageCode)) return null;
  final original = _originalItemDescriptions[item.id];
  if (original != null) return _catalogValue(languageCode, original);
  final parts = item.id.split('_');
  if (parts.length != 3 || parts.first != 'decor') return null;
  final description = _furnitureDescriptions[parts[2]];
  return description == null ? null : _catalogValue(languageCode, description);
}

const _originalItemNames = <String, List<String>>{
  'moss_cushion': [
    'Mooskissen',
    'Cojín de musgo',
    'Coussin de mousse',
    'Cuscino di muschio',
    'Almofada de musgo',
    '苔藓软垫',
    '苔のクッション'
  ],
  'cloud_basket': [
    'Wolkenkorb',
    'Cesta de nubes',
    'Panier-nuage',
    'Cesta di nuvole',
    'Cesto de nuvens',
    '云朵篮',
    '雲のかご'
  ],
  'moon_fern': [
    'Mondfarn',
    'Helecho lunar',
    'Fougère lunaire',
    'Felce lunare',
    'Samambaia lunar',
    '月光蕨',
    '月のシダ'
  ],
  'star_bonsai': [
    'Sternenbonsai',
    'Bonsái estelar',
    'Bonsaï étoilé',
    'Bonsai stellare',
    'Bonsai estelar',
    '星辰盆景',
    '星の盆栽'
  ],
  'spire_map': [
    'Turmspitzenkarte',
    'Mapa de la Aguja',
    'Carte de la Flèche',
    'Mappa della Guglia',
    'Mapa da Torre',
    '尖塔地图',
    '塔の地図'
  ],
  'moon_banner': [
    'Mondbanner',
    'Estandarte lunar',
    'Bannière lunaire',
    'Stendardo lunare',
    'Estandarte lunar',
    '月光旗帜',
    '月の旗'
  ],
  'firefly_lamp': [
    'Glühwürmchenlampe',
    'Lámpara de luciérnagas',
    'Lampe aux lucioles',
    'Lampada delle lucciole',
    'Lâmpada de vaga-lumes',
    '萤火虫灯',
    '蛍のランプ'
  ],
  'crystal_lantern': [
    'Kristalllaterne',
    'Farol de cristal',
    'Lanterne de cristal',
    'Lanterna di cristallo',
    'Lanterna de cristal',
    '水晶灯笼',
    '水晶のランタン'
  ],
};

const _originalItemDescriptions = <String, List<String>>{
  'moss_cushion': [
    'Ein weiches Kissen, das nach Regen duftet.',
    'Un cojín suave que huele a lluvia.',
    'Un coussin moelleux qui sent la pluie.',
    'Un morbido cuscino che profuma di pioggia.',
    'Uma almofada macia com cheiro de chuva.',
    '散发着雨水气息的柔软坐垫。',
    '雨の香りがする柔らかなクッション。'
  ],
  'cloud_basket': [
    'Für Drachenträume ohne scharfe Kanten.',
    'Para sueños de dragón sin bordes afilados.',
    'Pour des rêves de dragon sans angles pointus.',
    'Per sogni di drago senza spigoli.',
    'Para sonhos de dragão sem pontas afiadas.',
    '让龙做没有尖角的美梦。',
    '角のない、やさしいドラゴンの夢のために。'
  ],
  'moon_fern': [
    'Seine Blätter entfalten sich im Mondlicht.',
    'Sus hojas se abren bajo la luz de la luna.',
    'Ses feuilles se déploient au clair de lune.',
    'Le sue foglie si aprono al chiaro di luna.',
    'Suas folhas se abrem ao luar.',
    '叶片会在月光下舒展。',
    '月明かりを浴びると葉が開きます。'
  ],
  'star_bonsai': [
    'Ein seltenes Bäumchen mit goldenen Knospen.',
    'Un arbolito raro con brotes dorados.',
    'Un petit arbre rare aux bourgeons dorés.',
    'Un raro alberello con gemme dorate.',
    'Uma rara arvorezinha com brotos dourados.',
    '一棵长着金色花苞的稀有小树。',
    '金色のつぼみをつけた珍しい小さな木。'
  ],
  'spire_map': [
    'Jeder markierte Balkon verspricht eine kleine Entdeckung.',
    'Cada balcón marcado promete un pequeño descubrimiento.',
    'Chaque balcon indiqué promet une petite découverte.',
    'Ogni balcone segnato promette una piccola scoperta.',
    'Cada varanda marcada promete uma pequena descoberta.',
    '每个标记的阳台都预示着一个小发现。',
    '印のついたバルコニーには小さな発見が待っています。'
  ],
  'moon_banner': [
    'Verleiht dem Nest einen heldenhaften Glanz.',
    'Da al nido un resplandor heroico.',
    'Donne au nid une lueur héroïque.',
    'Dona al nido un bagliore eroico.',
    'Dá ao ninho um brilho heroico.',
    '为巢穴增添英雄般的光辉。',
    '巣を勇ましく輝かせます。'
  ],
  'firefly_lamp': [
    'Warmes Licht, höflich in einem Glas aufbewahrt.',
    'Luz cálida, guardada con educación en un frasco.',
    'Une lumière chaude, poliment conservée dans un bocal.',
    'Luce calda, custodita con garbo in un barattolo.',
    'Luz quente, educadamente guardada em um pote.',
    '温暖的光，被礼貌地收在罐子里。',
    '瓶の中でお行儀よく光る、あたたかな明かり。'
  ],
  'crystal_lantern': [
    'Türkises Licht zum Lesen in langen Nächten.',
    'Un brillo turquesa para leer de noche.',
    'Une lueur turquoise pour les lectures nocturnes.',
    'Un bagliore turchese per leggere a tarda notte.',
    'Um brilho turquesa para leituras noturnas.',
    '适合深夜阅读的青绿色光芒。',
    '夜更けの読書にぴったりなターコイズの光。'
  ],
};

const _furnitureThemes = <String, List<String>>{
  'aurora': [
    'Polarlicht',
    'Aurora',
    'Aurore',
    'Aurora',
    'Aurora',
    '极光',
    'オーロラ'
  ],
  'ember': ['Glut', 'Brasa', 'Braise', 'Brace', 'Brasa', '余烬', '残り火'],
  'moon': ['Mond', 'Luna', 'Lune', 'Luna', 'Lua', '月光', '月'],
  'forest': ['Wald', 'Bosque', 'Forêt', 'Foresta', 'Floresta', '森林', '森'],
  'ocean': ['Ozean', 'Océano', 'Océan', 'Oceano', 'Oceano', '海洋', '海'],
  'crystal': [
    'Kristall',
    'Cristal',
    'Cristal',
    'Cristallo',
    'Cristal',
    '水晶',
    '水晶'
  ],
  'cloud': ['Wolken', 'Nube', 'Nuage', 'Nuvola', 'Nuvem', '云朵', '雲'],
  'sun': ['Sonnen', 'Sol', 'Soleil', 'Sole', 'Sol', '太阳', '太陽'],
  'lavender': [
    'Lavendel',
    'Lavanda',
    'Lavande',
    'Lavanda',
    'Lavanda',
    '薰衣草',
    'ラベンダー'
  ],
  'copper': ['Kupfer', 'Cobre', 'Cuivre', 'Rame', 'Cobre', '铜', '銅'],
  'starlight': [
    'Sternenlicht',
    'Luz estelar',
    'Lumière astrale',
    'Luce stellare',
    'Luz estelar',
    '星光',
    '星明かり'
  ],
  'meadow': ['Wiesen', 'Pradera', 'Prairie', 'Prato', 'Prado', '草甸', '草原'],
  'storm': [
    'Sturm',
    'Tormenta',
    'Tempête',
    'Tempesta',
    'Tempestade',
    '风暴',
    '嵐'
  ],
  'cherry': [
    'Kirschblüten',
    'Cerezo',
    'Cerisier',
    'Ciliegio',
    'Cerejeira',
    '樱花',
    '桜'
  ],
  'frost': ['Frost', 'Escarcha', 'Givre', 'Brina', 'Geada', '霜冻', '霜'],
  'honey': ['Honig', 'Miel', 'Miel', 'Miele', 'Mel', '蜂蜜', '蜂蜜'],
  'mushroom': ['Pilz', 'Seta', 'Champignon', 'Fungo', 'Cogumelo', '蘑菇', 'キノコ'],
  'velvet': [
    'Samt',
    'Terciopelo',
    'Velours',
    'Velluto',
    'Veludo',
    '天鹅绒',
    'ベルベット'
  ],
  'rainbow': [
    'Regenbogen',
    'Arcoíris',
    'Arc-en-ciel',
    'Arcobaleno',
    'Arco-íris',
    '彩虹',
    '虹'
  ],
  'twilight': [
    'Dämmerung',
    'Crepúsculo',
    'Crépuscule',
    'Crepuscolo',
    'Crepúsculo',
    '暮光',
    '黄昏'
  ],
  'coral': ['Korallen', 'Coral', 'Corail', 'Corallo', 'Coral', '珊瑚', 'サンゴ'],
  'sapphire': [
    'Saphir',
    'Zafiro',
    'Saphir',
    'Zaffiro',
    'Safira',
    '蓝宝石',
    'サファイア'
  ],
  'rose': ['Rosen', 'Rosa', 'Rose', 'Rosa', 'Rosa', '玫瑰', 'バラ'],
  'dragon': ['Drachen', 'Dragón', 'Dragon', 'Drago', 'Dragão', '龙纹', 'ドラゴン'],
};

const _furnitureForms = <String, List<String>>{
  'cushion': [
    'Kissen',
    'cojín',
    'coussin',
    'cuscino',
    'almofada',
    '软垫',
    'クッション'
  ],
  'daybed': [
    'Ruhebett',
    'diván',
    'lit de repos',
    'lettino',
    'divã',
    '休憩床',
    'デイベッド'
  ],
  'planter': [
    'Pflanzkübel',
    'macetero',
    'jardinière',
    'fioriera',
    'vaso',
    '花盆',
    'プランター'
  ],
  'bonsai': ['Bonsai', 'bonsái', 'bonsaï', 'bonsai', 'bonsai', '盆景', '盆栽'],
  'tapestry': [
    'Wandteppich',
    'tapiz',
    'tapisserie',
    'arazzo',
    'tapeçaria',
    '挂毯',
    'タペストリー'
  ],
  'shelf': [
    'Kuriositätenregal',
    'estante de curiosidades',
    'étagère à curiosités',
    'mensola delle curiosità',
    'prateleira de curiosidades',
    '珍藏架',
    '飾り棚'
  ],
  'lantern': [
    'Leuchtlaterne',
    'farol luminoso',
    'lanterne lumineuse',
    'lanterna luminosa',
    'lanterna brilhante',
    '辉光灯笼',
    '光のランタン'
  ],
  'orb': [
    'Magiekugel',
    'orbe mágico',
    'orbe magique',
    'sfera magica',
    'orbe mágico',
    '魔法宝珠',
    '魔法のオーブ'
  ],
};

const _furnitureDescriptions = <String, List<String>>{
  'cushion': [
    'Ein praller Ruheplatz, durchwoben mit passender Magie.',
    'Un mullido rincón de descanso tejido con magia temática.',
    'Un repos moelleux tissé d’une magie assortie.',
    'Un soffice posto di riposo intrecciato di magia a tema.',
    'Um lugar macio para descansar, tecido com magia temática.',
    '一处蓬松的休息角落，交织着主题魔法。',
    'テーマの魔法を織り込んだ、ふかふかの休憩場所。'
  ],
  'daybed': [
    'Ein geräumiges Drachenbett für Nickerchen zwischen Abenteuern.',
    'Una cama amplia para siestas entre aventuras.',
    'Un grand lit de dragon pour les siestes entre deux aventures.',
    'Un ampio letto per i sonnellini tra un’avventura e l’altra.',
    'Uma cama espaçosa para cochilos entre aventuras.',
    '宽敞的龙床，适合在冒险间隙小睡。',
    '冒険の合間に昼寝できる、ゆったりしたドラゴン用ベッド。'
  ],
  'planter': [
    'Ein lebendiger Akzent, der die Stimmung des Raums verändert.',
    'Un detalle vivo que cambia el ambiente de la habitación.',
    'Une touche vivante qui transforme l’ambiance de la pièce.',
    'Un tocco vivo che cambia l’atmosfera della stanza.',
    'Um detalhe vivo que muda o clima do cômodo.',
    '鲜活的点缀，能改变整个房间的氛围。',
    '部屋の雰囲気を変える、生き生きとしたアクセント。'
  ],
  'bonsai': [
    'Ein winziger verzauberter Baum mit starkem Charakter.',
    'Un pequeño árbol encantado con mucha personalidad.',
    'Un petit arbre enchanté au caractère bien trempé.',
    'Un piccolo albero incantato dalla forte personalità.',
    'Uma pequena árvore encantada cheia de personalidade.',
    '一棵个性十足的迷你魔法树。',
    '個性の強い、小さな魔法の木。'
  ],
  'tapestry': [
    'Ein handgefertigter Wandschmuck für einen prächtigeren Raum.',
    'Una pieza mural hecha a mano para dar grandeza a la habitación.',
    'Une décoration murale faite main pour une pièce plus majestueuse.',
    'Un decoro da parete rifinito a mano per una stanza più maestosa.',
    'Uma peça de parede feita à mão para um cômodo mais grandioso.',
    '手工完成的墙饰，让房间更显华丽。',
    '部屋を豪華にする、手仕上げの壁飾り。'
  ],
  'shelf': [
    'Ein Wandregal voller harmloser kleiner Geheimnisse.',
    'Una estantería llena de pequeños misterios inofensivos.',
    'Une étagère remplie de petits mystères inoffensifs.',
    'Una mensola piena di piccoli misteri innocui.',
    'Uma prateleira cheia de pequenos mistérios inofensivos.',
    '摆满无害小秘密的墙架。',
    '無害な小さな謎でいっぱいの壁棚。'
  ],
  'lantern': [
    'Ein warmes magisches Licht in einer eigenen sanften Farbe.',
    'Una luz mágica y cálida con su propio color suave.',
    'Une lumière magique et chaleureuse à la teinte douce.',
    'Una calda luce magica dalla delicata tonalità.',
    'Uma luz mágica e quente com sua própria cor suave.',
    '带有独特色彩的温暖魔法灯光。',
    '独自のやさしい色を持つ、あたたかな魔法の光。'
  ],
  'orb': [
    'Ein schwebender Funke, der den ganzen Raum mit Stimmung füllt.',
    'Una chispa flotante que llena de ambiente toda la habitación.',
    'Une étincelle flottante qui donne une ambiance à toute la pièce.',
    'Una scintilla fluttuante che avvolge l’intera stanza.',
    'Uma faísca flutuante que dá atmosfera ao cômodo inteiro.',
    '一颗漂浮的火花，为整个房间营造氛围。',
    '部屋全体を彩る、宙に浮かぶ小さな光。'
  ],
};

String? translatedAdventureTitle(
  AdventureDefinition adventure,
  String languageCode,
) {
  if (!catalogLanguageIndex.containsKey(languageCode)) return null;
  final index = int.tryParse(adventure.id.split('_').last);
  if (index == null || index < 1) return null;
  final zeroBased = index - 1;
  switch (adventure.kind) {
    case AdventureKind.short:
      final mission = _adventureMissions[languageCode]![zeroBased % 15];
      final place = _adventurePlaces[languageCode]![zeroBased % 20];
      return '$mission: $place';
    case AdventureKind.long:
      final place = _adventurePlaces[languageCode]![(zeroBased * 7) % 20];
      return _longAdventureTitle(languageCode, place, index);
    case AdventureKind.group:
      final place = _adventurePlaces[languageCode]![(zeroBased * 3) % 20];
      return _groupAdventureTitle(languageCode, place);
    case AdventureKind.special:
      return _specialAdventureTitle(
        languageCode,
        sinister: adventure.sinister,
        number: adventure.sinister ? index - 90 : index,
      );
  }
}

String? translatedAdventureDescription(
  AdventureDefinition adventure,
  String languageCode,
) {
  if (!catalogLanguageIndex.containsKey(languageCode)) return null;
  final index = int.tryParse(adventure.id.split('_').last) ?? 1;
  return switch (adventure.kind) {
    AdventureKind.short => _localizedAdventure(languageCode, [
        'Eine gezielte Expedition mit einem neugierigen Umweg ($index/300).',
        'Una expedición centrada con un curioso desvío ($index/300).',
        'Une expédition ciblée avec un curieux détour ($index/300).',
        'Una spedizione mirata con una curiosa deviazione ($index/300).',
        'Uma expedição focada com um desvio curioso ($index/300).',
        '一次目标明确、略带好奇心的远征（$index/300）。',
        '好奇心に導かれた小さな寄り道つきの探索（$index/300）。'
      ]),
    AdventureKind.long => _localizedAdventure(languageCode, const [
        'Eine sorgfältige mehrtägige Reise unter wechselndem Himmel.',
        'Un cuidadoso viaje de varios días bajo cielos cambiantes.',
        'Un voyage prudent de plusieurs jours sous des ciels changeants.',
        'Un viaggio attento di più giorni sotto cieli mutevoli.',
        'Uma jornada cuidadosa de vários dias sob céus mutáveis.',
        '一场穿越变幻天空、为期数日的谨慎旅程。',
        '移り変わる空の下を進む、慎重な数日間の旅。'
      ]),
    AdventureKind.group => _groupAdventureDescription(
        languageCode,
        adventure.requirements.players,
      ),
    AdventureKind.special => _localizedAdventure(
        languageCode,
        adventure.sinister
            ? const [
                'Ein freigelassener Drache hinterließ eine gefährlich wirkende Karte. Ihr zu folgen ist freiwillig.',
                'Un dragón liberado dejó un mapa de aspecto peligroso. Seguirlo es opcional.',
                'Un dragon libéré a laissé une carte inquiétante. La suivre reste facultatif.',
                'Un drago liberato ha lasciato una mappa dall’aria pericolosa. Seguirla è facoltativo.',
                'Um dragão libertado deixou um mapa de aparência perigosa. Segui-lo é opcional.',
                '一只被放归的龙留下了一张看起来很危险的地图。是否跟随由你决定。',
                '放したドラゴンが危険そうな地図を残しました。追跡するかは自由です。'
              ]
            : const [
                'Eine einmalige Spur mit vollständig bekannter Belohnung.',
                'Un rastro único con una recompensa totalmente conocida.',
                'Une piste unique dont la récompense est entièrement connue.',
                'Una pista irripetibile con una ricompensa del tutto nota.',
                'Uma trilha única com recompensa totalmente conhecida.',
                '一条仅出现一次、奖励完全已知的线索。',
                '報酬がすべて分かっている、一度きりの手がかり。'
              ],
      ),
  };
}

String _localizedAdventure(String languageCode, List<String> values) =>
    values[catalogLanguageIndex[languageCode]!];

String _longAdventureTitle(String language, String place, int number) =>
    switch (language) {
      'de' => 'Expedition nach $place $number',
      'es' => 'Expedición a $place $number',
      'fr' => 'Expédition vers $place $number',
      'it' => 'Spedizione a $place $number',
      'pt' => 'Expedição a $place $number',
      'zh' => '$place远征 $number',
      _ => '$place遠征 $number',
    };

String _groupAdventureTitle(String language, String place) =>
    switch (language) {
      'de' => 'Bündnis von $place',
      'es' => 'Concordia de $place',
      'fr' => 'Concorde de $place',
      'it' => 'Concordia di $place',
      'pt' => 'Concórdia de $place',
      'zh' => '$place盟约',
      _ => '$placeの盟約',
    };

String _specialAdventureTitle(
  String language, {
  required bool sinister,
  required int number,
}) {
  final values = sinister
      ? [
          'Der Krumme Schatten $number',
          'La Sombra Torcida $number',
          'L’Ombre Courbe $number',
          'L’Ombra Storta $number',
          'A Sombra Torta $number',
          '扭曲之影 $number',
          '歪んだ影 $number',
        ]
      : [
          'Eine seltsame Einladung $number',
          'Una invitación extraña $number',
          'Une étrange invitation $number',
          'Uno strano invito $number',
          'Um convite estranho $number',
          '奇怪的邀请 $number',
          '不思議な招待状 $number',
        ];
  return _localizedAdventure(language, values);
}

String _groupAdventureDescription(String language, int players) =>
    _localizedAdventure(language, [
      'Eine gemeinsame Entdeckung für $players Drachenhüter.',
      'Un descubrimiento cooperativo para $players cuidadores de dragones.',
      'Une découverte coopérative pour $players gardiens de dragons.',
      'Una scoperta cooperativa per $players custodi di draghi.',
      'Uma descoberta cooperativa para $players guardiões de dragões.',
      '供 $players 名龙守护者合作探索。',
      '$players人のドラゴンキーパーで挑む協力探索。',
    ]);

const _adventurePlaces = <String, List<String>>{
  'de': [
    'Wolkenobstgarten',
    'Flüsterruinen',
    'Mondlichtsee',
    'Glutpass',
    'Kristallhöhle',
    'Silberkronen',
    'Uhrwerkhain',
    'Sternenfallküste',
    'Moostor',
    'Versunkenes Archiv',
    'Auroragrat',
    'Laternenmoor',
    'Donnerplateau',
    'Saphirgrotte',
    'Morgenwindtal',
    'Kometengarten',
    'Vergessener Glockenturm',
    'Träumende Dünen',
    'Gezeitenwarte',
    'Runenmarkt'
  ],
  'es': [
    'Huerto de las Nubes',
    'Ruinas Susurrantes',
    'Laguna Lunar',
    'Paso de las Brasas',
    'Hondonada de Cristal',
    'Dosel Plateado',
    'Arboleda Mecánica',
    'Costa Estelar',
    'Puerta Musgosa',
    'Archivo Sumergido',
    'Cresta de la Aurora',
    'Pantano de los Faroles',
    'Meseta del Trueno',
    'Gruta de Zafiro',
    'Valle del Viento del Alba',
    'Jardín de Cometas',
    'Campanario Olvidado',
    'Dunas Soñadoras',
    'Observatorio de las Mareas',
    'Mercado de Runas'
  ],
  'fr': [
    'Verger des Nuages',
    'Ruines Murmurantes',
    'Lac au Clair de Lune',
    'Col des Braises',
    'Creux de Cristal',
    'Canopée d’Argent',
    'Bosquet Mécanique',
    'Côte des Étoiles',
    'Porte Moussue',
    'Archives Englouties',
    'Crête de l’Aurore',
    'Marais aux Lanternes',
    'Mesa du Tonnerre',
    'Grotte de Saphir',
    'Val du Vent d’Aube',
    'Jardin des Comètes',
    'Beffroi Oublié',
    'Dunes Rêveuses',
    'Observatoire des Marées',
    'Marché aux Runes'
  ],
  'it': [
    'Frutteto delle Nuvole',
    'Rovine Sussurranti',
    'Lago Lunare',
    'Passo delle Braci',
    'Conca di Cristallo',
    'Volta d’Argento',
    'Boschetto Meccanico',
    'Costa delle Stelle',
    'Porta Muschiosa',
    'Archivio Sommerso',
    'Cresta dell’Aurora',
    'Palude delle Lanterne',
    'Mesa del Tuono',
    'Grotta di Zaffiro',
    'Valle del Vento d’Alba',
    'Giardino delle Comete',
    'Campanile Dimenticato',
    'Dune Sognanti',
    'Osservatorio delle Maree',
    'Mercato delle Rune'
  ],
  'pt': [
    'Pomar das Nuvens',
    'Ruínas Sussurrantes',
    'Lagoa Lunar',
    'Passagem das Brasas',
    'Vale de Cristal',
    'Dossel de Prata',
    'Bosque Mecânico',
    'Costa da Queda Estelar',
    'Portão Musgoso',
    'Arquivo Submerso',
    'Crista da Aurora',
    'Pântano das Lanternas',
    'Chapada do Trovão',
    'Gruta de Safira',
    'Vale do Vento da Alvorada',
    'Jardim dos Cometas',
    'Campanário Esquecido',
    'Dunas Sonhadoras',
    'Observatório das Marés',
    'Mercado de Runas'
  ],
  'zh': [
    '云端果园',
    '低语遗迹',
    '月光湖',
    '余烬隘口',
    '水晶谷',
    '银冠林',
    '发条幽谷',
    '星落海岸',
    '苔藓之门',
    '沉没档案馆',
    '极光山脊',
    '灯笼沼泽',
    '雷鸣高地',
    '蓝宝石洞窟',
    '晨风谷',
    '彗星花园',
    '遗忘钟楼',
    '梦境沙丘',
    '潮汐观测站',
    '符文市场'
  ],
  'ja': [
    '雲の果樹園',
    'ささやきの遺跡',
    '月明かりの湖',
    '残り火の峠',
    '水晶の窪地',
    '銀の樹冠',
    'からくりの谷',
    '星降り海岸',
    '苔むす門',
    '沈んだ書庫',
    'オーロラの尾根',
    'ランタン湿地',
    '雷鳴の台地',
    'サファイアの洞窟',
    '暁風の谷',
    '彗星の庭',
    '忘れられた鐘楼',
    '夢見る砂丘',
    '潮の観測所',
    'ルーン市場'
  ],
};

const _adventureMissions = <String, List<String>>{
  'de': [
    'Kartografiere',
    'Erkunde',
    'Sammle',
    'Eskortiere',
    'Entschlüssle',
    'Stelle wieder her',
    'Beobachte',
    'Liefere',
    'Durchsuche',
    'Vermesse',
    'Katalogisiere',
    'Beschütze',
    'Verfolge',
    'Berge',
    'Untersuche'
  ],
  'es': [
    'Cartografiar',
    'Explorar',
    'Recolectar',
    'Escoltar',
    'Descifrar',
    'Restaurar',
    'Observar',
    'Entregar',
    'Buscar',
    'Inspeccionar',
    'Catalogar',
    'Proteger',
    'Rastrear',
    'Recuperar',
    'Estudiar'
  ],
  'fr': [
    'Cartographier',
    'Explorer',
    'Récolter',
    'Escorter',
    'Déchiffrer',
    'Restaurer',
    'Observer',
    'Livrer',
    'Rechercher',
    'Examiner',
    'Cataloguer',
    'Protéger',
    'Pister',
    'Récupérer',
    'Étudier'
  ],
  'it': [
    'Mappare',
    'Esplorare',
    'Raccogliere',
    'Scortare',
    'Decifrare',
    'Restaurare',
    'Osservare',
    'Consegnare',
    'Cercare',
    'Ispezionare',
    'Catalogare',
    'Proteggere',
    'Tracciare',
    'Recuperare',
    'Studiare'
  ],
  'pt': [
    'Mapear',
    'Explorar',
    'Coletar',
    'Escoltar',
    'Decifrar',
    'Restaurar',
    'Observar',
    'Entregar',
    'Procurar',
    'Vistoriar',
    'Catalogar',
    'Proteger',
    'Rastrear',
    'Recuperar',
    'Estudar'
  ],
  'zh': [
    '绘制地图',
    '侦察',
    '采集',
    '护送',
    '解码',
    '修复',
    '观察',
    '递送',
    '搜寻',
    '勘察',
    '编入图鉴',
    '保护',
    '追踪',
    '寻回',
    '研究'
  ],
  'ja': [
    '地図を作る',
    '偵察する',
    '集める',
    '護衛する',
    '解読する',
    '修復する',
    '観察する',
    '届ける',
    '捜索する',
    '調査する',
    '記録する',
    '守る',
    '追跡する',
    '回収する',
    '研究する'
  ],
};
