import 'pet.dart';

enum DragonDialogueTone { calm, proud, playful, adventurous, affectionate }

class DragonDialogueLine {
  const DragonDialogueLine(
      {required this.id,
      required this.stageKey,
      required this.tone,
      required this.en,
      required this.nl});
  final String id;
  final String stageKey;
  final DragonDialogueTone tone;
  final String en;
  final String nl;
  String text(String languageCode) {
    if (languageCode == 'en') return '“$en”';
    if (languageCode == 'nl') return '“$nl”';
    final parts = id.split('_');
    final baseIndex = int.tryParse(parts[parts.length - 2]);
    final translatedBases = _dialogueBases[languageCode];
    final translatedEndings = _dialogueEndings[languageCode];
    if (baseIndex == null ||
        translatedBases == null ||
        translatedEndings == null) {
      return '“$en”';
    }
    final stageOffset = switch (stageKey) {
      'spark' => 0,
      'nestDragon' => 20,
      _ => 40,
    };
    return '“${translatedBases[stageOffset + baseIndex]}${translatedEndings[tone.index]}”';
  }
}

typedef _Pair = ({String en, String nl});

const _hatchling = <_Pair>[
  (
    en: 'I wonder where the moon goes during daytime',
    nl: 'Ik vraag me af waar de maan overdag naartoe gaat'
  ),
  (
    en: 'My wings have learned three new wobbles',
    nl: 'Mijn vleugels hebben drie nieuwe wiebels geleerd'
  ),
  (
    en: 'I inspected this floorboard and declared it cozy',
    nl: 'Ik heb deze vloerplank onderzocht en gezellig verklaard'
  ),
  (
    en: 'Do clouds feel as soft as my cushion',
    nl: 'Voelen wolken net zo zacht als mijn kussen'
  ),
  (
    en: 'I heard the snack cupboard whisper my name',
    nl: 'Ik hoorde de snackkast mijn naam fluisteren'
  ),
  (
    en: 'My tail feels a little stronger today',
    nl: 'Mijn staart voelt vandaag een beetje sterker'
  ),
  (
    en: 'I want to count every star above the Spire',
    nl: 'Ik wil elke ster boven de Spire tellen'
  ),
  (
    en: 'The moon fern definitely waved at me',
    nl: 'De maanvaren zwaaide echt naar mij'
  ),
  (
    en: 'I found a sunbeam that is exactly dragon-sized',
    nl: 'Ik vond een zonnestraal die precies draakformaat heeft'
  ),
  (
    en: 'Can a brave dragon fear a squeaky door',
    nl: 'Mag een dappere draak bang zijn voor een piepende deur'
  ),
  (
    en: 'I am practicing my most heroic tiny roar',
    nl: 'Ik oefen mijn heldhaftigste kleine brul'
  ),
  (
    en: 'The tower smells like stories and toasted dreams',
    nl: 'De toren ruikt naar verhalen en geroosterde dromen'
  ),
  (
    en: 'That cloud looks suspiciously rideable',
    nl: 'Die wolk ziet er verdacht berijdbaar uit'
  ),
  (
    en: 'My shadow looked enormous for almost two seconds',
    nl: 'Mijn schaduw leek bijna twee seconden reusachtig'
  ),
  (
    en: 'I would like my own very small treasure chest',
    nl: 'Ik wil graag een heel klein eigen schatkistje'
  ),
  (
    en: 'I tried to roar but a squeak came out',
    nl: 'Ik probeerde te brullen maar er kwam een piepje uit'
  ),
  (
    en: 'The lantern makes my horns look magnificent',
    nl: 'De lantaarn laat mijn hoorns er indrukwekkend uitzien'
  ),
  (
    en: 'Every plant should have a heroic name',
    nl: 'Elke plant zou een heldhaftige naam moeten hebben'
  ),
  (
    en: 'I want to map every balcony of the tower',
    nl: 'Ik wil elk balkon van de toren in kaart brengen'
  ),
  (
    en: 'I saved you the warmest spot beside the nest',
    nl: 'Ik heb het warmste plekje naast het nest voor jou bewaard'
  ),
];

const _wyrmling = <_Pair>[
  (
    en: 'I can almost reach the highest shelf',
    nl: 'Ik kan bijna bij de hoogste plank'
  ),
  (
    en: 'I have a plan for making this room cozier',
    nl: 'Ik heb een plan om deze kamer gezelliger te maken'
  ),
  (
    en: 'The sunlight is perfect for dragon naps',
    nl: 'Het zonlicht is perfect voor drakendutjes'
  ),
  (
    en: 'The Rune Observatory left a spark in my thoughts',
    nl: 'Het Runenobservatorium liet een vonk in mijn gedachten achter'
  ),
  (
    en: 'My tail can balance three cushions now',
    nl: 'Mijn staart kan nu drie kussens balanceren'
  ),
  (
    en: 'The moon garden is whispering new secrets',
    nl: 'De maantuin fluistert nieuwe geheimen'
  ),
  (
    en: 'I arranged the cushions by maximum softness',
    nl: 'Ik heb de kussens op maximale zachtheid gesorteerd'
  ),
  (
    en: 'Every new form makes the Draconomicon hum',
    nl: 'Elke nieuwe vorm laat het Draconomicon neuriën'
  ),
  (
    en: 'I think an old coin is hiding under that chair',
    nl: 'Ik denk dat er een oude munt onder die stoel ligt'
  ),
  (
    en: 'The hearth needs an official marshmallow inspector',
    nl: 'De haard heeft een officiële marshmallowinspecteur nodig'
  ),
  (
    en: 'I can carry this treasure all by myself',
    nl: 'Ik kan deze schat helemaal zelf dragen'
  ),
  (
    en: 'I memorized the route from the nest to the snacks',
    nl: 'Ik heb de route van het nest naar de snacks onthouden'
  ),
  (
    en: 'The loft stars look close enough to tickle',
    nl: 'De zoldersterren lijken dichtbij genoeg om te kietelen'
  ),
  (
    en: 'Our furniture tells visitors who lives here',
    nl: 'Onze meubels vertellen bezoekers wie hier woont'
  ),
  (
    en: 'Today deserves a victory lap through every room',
    nl: 'Vandaag verdient een ereronde door elke kamer'
  ),
  (
    en: 'I know every room with my eyes closed',
    nl: 'Ik ken elke kamer met mijn ogen dicht'
  ),
  (
    en: 'The cliff course was definitely shorter yesterday',
    nl: 'Het klifparcours was gisteren beslist korter'
  ),
  (
    en: 'I am practicing a welcome dance for new furniture',
    nl: 'Ik oefen een welkomstdans voor nieuwe meubels'
  ),
  (
    en: 'That empty corner could use something shiny',
    nl: 'Die lege hoek kan wel iets glanzends gebruiken'
  ),
  (
    en: 'I moved the cushion for scientific reasons',
    nl: 'Ik heb het kussen om wetenschappelijke redenen verplaatst'
  ),
];

const _ascended = <_Pair>[
  (
    en: 'I know every creak and moonbeam in this sanctuary',
    nl: 'Ik ken ieder kraakje en elke maanstraal in dit reservaat'
  ),
  (
    en: 'Every room holds a different piece of our story',
    nl: 'Elke kamer bewaart een ander stukje van ons verhaal'
  ),
  (
    en: 'I can watch the tower while everyone rests',
    nl: 'Ik kan over de toren waken terwijl iedereen rust'
  ),
  (
    en: 'The hearth keeps the warmest stories for cold evenings',
    nl: 'De haard bewaart de warmste verhalen voor koude avonden'
  ),
  (
    en: 'The moon garden proves that quiet care matters',
    nl: 'De maantuin bewijst dat stille zorg ertoe doet'
  ),
  (
    en: 'The observatory makes even large worries look small',
    nl: 'Het observatorium laat zelfs grote zorgen klein lijken'
  ),
  (
    en: 'A patient bond outshines any treasure',
    nl: 'Een geduldige band straalt feller dan welke schat ook'
  ),
  (
    en: 'Strong wings are built one careful day at a time',
    nl: 'Sterke vleugels groeien met één zorgvuldige dag tegelijk'
  ),
  (
    en: 'Every cushion has an approved napping angle',
    nl: 'Elk kussen heeft een goedgekeurde dutjeshoek'
  ),
  (
    en: 'The highest shelf can no longer escape me',
    nl: 'De hoogste plank kan niet langer aan mij ontsnappen'
  ),
  (
    en: 'I remember the first sound I heard inside the egg',
    nl: 'Ik herinner me het eerste geluid dat ik in het ei hoorde'
  ),
  (
    en: 'A wise dragon notices when someone needs comfort',
    nl: 'Een wijze draak merkt wanneer iemand troost nodig heeft'
  ),
  (
    en: 'Our time together matters more than our collection',
    nl: 'Onze tijd samen is belangrijker dan onze verzameling'
  ),
  (
    en: 'Tonight I will count stars and unopened chests',
    nl: 'Vanavond tel ik sterren en ongeopende kisten'
  ),
  (
    en: 'This nest will always feel like home to me',
    nl: 'Dit nest zal voor mij altijd als thuis voelen'
  ),
  (
    en: 'The smallest discoveries often bring the biggest joy',
    nl: 'De kleinste ontdekkingen brengen vaak de grootste vreugde'
  ),
  (
    en: 'I can teach Hatchlings how to listen to the wind',
    nl: 'Ik kan Hatchlings leren luisteren naar de wind'
  ),
  (
    en: 'A room changes when someone truly cares for it',
    nl: 'Een kamer verandert wanneer iemand er echt om geeft'
  ),
  (
    en: 'I have a favorite memory in every corner',
    nl: 'Ik heb in elke hoek een favoriete herinnering'
  ),
  (
    en: 'Tomorrow is another page for the Draconomicon',
    nl: 'Morgen is een nieuwe pagina voor het Draconomicon'
  ),
];

const _endings = <_Pair>[
  (en: '.', nl: '.'),
  (en: '. I am very proud of that.', nl: '. Daar ben ik heel trots op.'),
  (
    en: '. Please pretend that was part of my plan.',
    nl: '. Doe maar alsof dat bij mijn plan hoorde.'
  ),
  (
    en: '. Let us turn it into our next adventure.',
    nl: '. Laten we er ons volgende avontuur van maken.'
  ),
  (
    en: '. Everything is better when you are here.',
    nl: '. Alles is fijner wanneer jij er bent.'
  ),
];

List<DragonDialogueLine> _build(String stageKey, List<_Pair> bases) =>
    List.unmodifiable([
      for (var base = 0; base < bases.length; base++)
        for (var tone = 0; tone < DragonDialogueTone.values.length; tone++)
          DragonDialogueLine(
            id: '${stageKey}_${base}_$tone',
            stageKey: stageKey,
            tone: DragonDialogueTone.values[tone],
            en: '${bases[base].en}${_endings[tone].en}',
            nl: '${bases[base].nl}${_endings[tone].nl}',
          ),
    ]);

final List<DragonDialogueLine> dragonDialogueLines = List.unmodifiable([
  ..._build('spark', _hatchling),
  ..._build('nestDragon', _wyrmling),
  ..._build('homeGuardian', _ascended),
]);

const _dialogueEndings = <String, List<String>>{
  'de': [
    '.',
    '. Darauf bin ich sehr stolz.',
    '. Tu bitte so, als wäre das Teil meines Plans gewesen.',
    '. Machen wir daraus unser nächstes Abenteuer.',
    '. Alles ist besser, wenn du hier bist.'
  ],
  'es': [
    '.',
    '. Estoy muy orgulloso de eso.',
    '. Finge que formaba parte de mi plan.',
    '. Convirtámoslo en nuestra próxima aventura.',
    '. Todo es mejor cuando estás aquí.'
  ],
  'fr': [
    '.',
    '. J’en suis très fier.',
    '. Faites comme si cela faisait partie de mon plan.',
    '. Faisons-en notre prochaine aventure.',
    '. Tout est mieux quand tu es là.'
  ],
  'it': [
    '.',
    '. Ne sono davvero orgoglioso.',
    '. Fai finta che facesse parte del mio piano.',
    '. Facciamone la nostra prossima avventura.',
    '. Tutto è più bello quando sei qui.'
  ],
  'pt': [
    '.',
    '. Tenho muito orgulho disso.',
    '. Finja que isso fazia parte do meu plano.',
    '. Vamos transformar isso na nossa próxima aventura.',
    '. Tudo é melhor quando você está aqui.'
  ],
  'zh': [
    '。',
    '。我对此非常自豪。',
    '。请假装这本来就是我的计划。',
    '。让它成为我们的下一次冒险吧。',
    '。有你在，一切都会更美好。'
  ],
  'ja': [
    '。',
    '。とても誇らしいです。',
    '。最初から計画どおりだったことにしてください。',
    '。次の冒険にしましょう。',
    '。あなたがいると、何もかもが素敵です。'
  ],
};

/// Twenty Hatchling, twenty Wyrmling and twenty Ascended base lines per
/// language. Five translated tone endings turn these into 300 unique lines.
const _dialogueBases = <String, List<String>>{
  'de': [
    'Ich frage mich, wohin der Mond am Tag geht',
    'Meine Flügel haben drei neue Wackler gelernt',
    'Ich habe diese Bodendiele geprüft und für gemütlich erklärt',
    'Ob Wolken wohl so weich sind wie mein Kissen',
    'Ich hörte den Snackschrank meinen Namen flüstern',
    'Mein Schwanz fühlt sich heute etwas stärker an',
    'Ich möchte jeden Stern über dem Turm zählen',
    'Der Mondfarn hat mir ganz bestimmt zugewinkt',
    'Ich fand einen Sonnenstrahl in genau der richtigen Drachengröße',
    'Darf ein mutiger Drache Angst vor einer quietschenden Tür haben',
    'Ich übe meinen heldenhaftesten kleinen Brüller',
    'Der Turm riecht nach Geschichten und gerösteten Träumen',
    'Diese Wolke sieht verdächtig gut reitbar aus',
    'Mein Schatten war fast zwei Sekunden lang riesig',
    'Ich hätte gern eine eigene winzig kleine Schatztruhe',
    'Ich wollte brüllen, aber es kam ein Quieken heraus',
    'Die Laterne lässt meine Hörner großartig aussehen',
    'Jede Pflanze sollte einen heldenhaften Namen haben',
    'Ich möchte jeden Balkon des Turms kartografieren',
    'Ich habe dir den wärmsten Platz neben dem Nest freigehalten',
    'Ich komme fast an das höchste Regal',
    'Ich habe einen Plan, um diesen Raum gemütlicher zu machen',
    'Das Sonnenlicht ist perfekt für Drachennickerchen',
    'Das Runenobservatorium hat einen Funken in meinen Gedanken hinterlassen',
    'Mein Schwanz kann jetzt drei Kissen balancieren',
    'Der Mondgarten flüstert neue Geheimnisse',
    'Ich habe die Kissen nach maximaler Weichheit sortiert',
    'Jede neue Form lässt das Draconomicon summen',
    'Ich glaube, unter diesem Stuhl versteckt sich eine alte Münze',
    'Die Feuerstelle braucht einen offiziellen Marshmallow-Prüfer',
    'Ich kann diesen Schatz ganz allein tragen',
    'Ich kenne den Weg vom Nest zu den Snacks auswendig',
    'Die Sterne am Dachboden sehen zum Kitzeln nah aus',
    'Unsere Möbel zeigen Besuchern, wer hier wohnt',
    'Heute ist eine Ehrenrunde durch alle Räume fällig',
    'Ich kenne jeden Raum mit geschlossenen Augen',
    'Der Klippenparcours war gestern bestimmt kürzer',
    'Ich übe einen Willkommenstanz für neue Möbel',
    'Diese leere Ecke könnte etwas Glänzendes gebrauchen',
    'Ich habe das Kissen aus wissenschaftlichen Gründen verschoben',
    'Ich kenne jedes Knarren und jeden Mondstrahl in diesem Refugium',
    'Jeder Raum bewahrt einen anderen Teil unserer Geschichte',
    'Ich kann über den Turm wachen, während alle ruhen',
    'Die Feuerstelle bewahrt die wärmsten Geschichten für kalte Abende',
    'Der Mondgarten beweist, dass stille Fürsorge zählt',
    'Das Observatorium lässt selbst große Sorgen klein erscheinen',
    'Eine geduldige Bindung strahlt heller als jeder Schatz',
    'Starke Flügel wachsen einen sorgsamen Tag nach dem anderen',
    'Jedes Kissen hat einen genehmigten Schlafwinkel',
    'Das höchste Regal kann mir nicht länger entkommen',
    'Ich erinnere mich an das erste Geräusch im Ei',
    'Ein weiser Drache merkt, wenn jemand Trost braucht',
    'Unsere gemeinsame Zeit ist wichtiger als unsere Sammlung',
    'Heute Nacht zähle ich Sterne und ungeöffnete Truhen',
    'Dieses Nest wird sich für mich immer wie Zuhause anfühlen',
    'Die kleinsten Entdeckungen bringen oft die größte Freude',
    'Ich kann Schlüpflingen beibringen, dem Wind zuzuhören',
    'Ein Raum verändert sich, wenn sich jemand wirklich um ihn kümmert',
    'In jeder Ecke habe ich eine Lieblingserinnerung',
    'Morgen beginnt eine neue Seite im Draconomicon',
  ],
  'es': [
    'Me pregunto adónde va la luna durante el día',
    'Mis alas han aprendido tres nuevos tambaleos',
    'He inspeccionado esta tabla y la declaro acogedora',
    '¿Serán las nubes tan suaves como mi cojín?',
    'Oí al armario de aperitivos susurrar mi nombre',
    'Hoy noto la cola un poco más fuerte',
    'Quiero contar todas las estrellas sobre la Torre',
    'El helecho lunar me saludó, seguro',
    'Encontré un rayo de sol del tamaño exacto de un dragón',
    '¿Puede un dragón valiente temer a una puerta chirriante?',
    'Estoy practicando mi rugidito más heroico',
    'La torre huele a historias y sueños tostados',
    'Esa nube parece sospechosamente cabalgable',
    'Mi sombra pareció enorme durante casi dos segundos',
    'Quisiera tener un cofrecito del tesoro propio',
    'Intenté rugir, pero salió un chillido',
    'El farol hace que mis cuernos se vean magníficos',
    'Cada planta debería tener un nombre heroico',
    'Quiero cartografiar todos los balcones de la torre',
    'Te guardé el lugar más cálido junto al nido',
    'Ya casi alcanzo el estante más alto',
    'Tengo un plan para hacer esta habitación más acogedora',
    'La luz del sol es perfecta para las siestas de dragón',
    'El Observatorio de Runas dejó una chispa en mis pensamientos',
    'Ahora mi cola puede equilibrar tres cojines',
    'El jardín lunar susurra nuevos secretos',
    'Ordené los cojines por suavidad máxima',
    'Cada nueva forma hace vibrar el Draconomicon',
    'Creo que hay una moneda antigua bajo esa silla',
    'El hogar necesita un inspector oficial de malvaviscos',
    'Puedo llevar este tesoro sin ayuda',
    'Memoricé la ruta del nido a los aperitivos',
    'Las estrellas del ático parecen lo bastante cerca para hacerles cosquillas',
    'Nuestros muebles cuentan a las visitas quién vive aquí',
    'Hoy merece una vuelta de honor por todas las habitaciones',
    'Conozco cada habitación con los ojos cerrados',
    'Ayer el recorrido del acantilado era más corto, seguro',
    'Practico un baile de bienvenida para los muebles nuevos',
    'A esa esquina vacía le vendría bien algo brillante',
    'Moví el cojín por motivos científicos',
    'Conozco cada crujido y cada rayo de luna de este santuario',
    'Cada habitación guarda una parte distinta de nuestra historia',
    'Puedo vigilar la torre mientras todos descansan',
    'El hogar guarda las historias más cálidas para las noches frías',
    'El jardín lunar demuestra que el cuidado tranquilo importa',
    'El observatorio hace pequeñas hasta las grandes preocupaciones',
    'Un vínculo paciente brilla más que cualquier tesoro',
    'Las alas fuertes se construyen con cuidado, día a día',
    'Cada cojín tiene un ángulo de siesta aprobado',
    'El estante más alto ya no puede escapar de mí',
    'Recuerdo el primer sonido que oí dentro del huevo',
    'Un dragón sabio nota cuando alguien necesita consuelo',
    'Nuestro tiempo juntos importa más que la colección',
    'Esta noche contaré estrellas y cofres sin abrir',
    'Este nido siempre será mi hogar',
    'Los descubrimientos más pequeños suelen dar la mayor alegría',
    'Puedo enseñar a las crías a escuchar el viento',
    'Una habitación cambia cuando alguien la cuida de verdad',
    'Tengo un recuerdo favorito en cada rincón',
    'Mañana será otra página del Draconomicon',
  ],
  'fr': [
    'Je me demande où va la lune pendant la journée',
    'Mes ailes ont appris trois nouveaux tremblements',
    'J’ai inspecté cette lame de parquet et je la déclare douillette',
    'Les nuages sont-ils aussi doux que mon coussin ?',
    'J’ai entendu le placard à friandises murmurer mon nom',
    'Ma queue me semble un peu plus forte aujourd’hui',
    'Je veux compter toutes les étoiles au-dessus de la Tour',
    'La fougère lunaire m’a vraiment fait signe',
    'J’ai trouvé un rayon de soleil exactement à ma taille',
    'Un dragon courageux peut-il craindre une porte qui grince ?',
    'Je répète mon plus héroïque petit rugissement',
    'La tour sent les histoires et les rêves grillés',
    'Ce nuage semble étrangement facile à chevaucher',
    'Mon ombre a paru immense pendant presque deux secondes',
    'J’aimerais avoir mon propre tout petit coffre au trésor',
    'J’ai essayé de rugir, mais un couinement est sorti',
    'La lanterne donne fière allure à mes cornes',
    'Chaque plante devrait porter un nom héroïque',
    'Je veux cartographier chaque balcon de la tour',
    'Je t’ai gardé la place la plus chaude près du nid',
    'J’atteins presque l’étagère la plus haute',
    'J’ai un plan pour rendre cette pièce plus douillette',
    'Le soleil est parfait pour les siestes de dragon',
    'L’Observatoire des Runes a laissé une étincelle dans mes pensées',
    'Ma queue peut maintenant tenir trois coussins en équilibre',
    'Le jardin lunaire murmure de nouveaux secrets',
    'J’ai classé les coussins du plus doux au plus doux',
    'Chaque nouvelle forme fait fredonner le Draconomicon',
    'Je crois qu’une vieille pièce se cache sous cette chaise',
    'Le foyer a besoin d’un inspecteur officiel des guimauves',
    'Je peux porter ce trésor tout seul',
    'J’ai mémorisé le chemin du nid aux friandises',
    'Les étoiles du grenier semblent assez proches pour être chatouillées',
    'Nos meubles racontent aux visiteurs qui vit ici',
    'Cette journée mérite un tour d’honneur dans chaque pièce',
    'Je connais chaque pièce les yeux fermés',
    'Le parcours des falaises était sûrement plus court hier',
    'Je prépare une danse d’accueil pour les nouveaux meubles',
    'Ce coin vide aurait besoin de quelque chose qui brille',
    'J’ai déplacé le coussin pour des raisons scientifiques',
    'Je connais chaque craquement et chaque rayon de lune de ce sanctuaire',
    'Chaque pièce abrite une part différente de notre histoire',
    'Je peux veiller sur la tour pendant que tout le monde se repose',
    'Le foyer garde les histoires les plus chaleureuses pour les soirées froides',
    'Le jardin lunaire prouve que les soins discrets comptent',
    'L’observatoire rapetisse même les plus gros soucis',
    'Un lien patient brille plus fort que n’importe quel trésor',
    'Des ailes fortes se bâtissent soigneusement, jour après jour',
    'Chaque coussin possède un angle de sieste homologué',
    'L’étagère la plus haute ne peut plus m’échapper',
    'Je me souviens du premier son entendu dans l’œuf',
    'Un dragon sage remarque quand quelqu’un a besoin de réconfort',
    'Le temps passé ensemble compte plus que notre collection',
    'Cette nuit, je compterai les étoiles et les coffres fermés',
    'Ce nid sera toujours mon foyer',
    'Les plus petites découvertes apportent souvent la plus grande joie',
    'Je peux apprendre aux nouveau-nés à écouter le vent',
    'Une pièce change quand quelqu’un en prend vraiment soin',
    'J’ai un souvenir préféré dans chaque recoin',
    'Demain ouvrira une nouvelle page du Draconomicon',
  ],
  'it': [
    'Mi chiedo dove vada la luna durante il giorno',
    'Le mie ali hanno imparato tre nuovi traballamenti',
    'Ho ispezionato questa asse e l’ho dichiarata accogliente',
    'Le nuvole sono morbide quanto il mio cuscino?',
    'Ho sentito la dispensa degli spuntini sussurrare il mio nome',
    'Oggi la mia coda sembra un po’ più forte',
    'Voglio contare ogni stella sopra la Torre',
    'La felce lunare mi ha salutato davvero',
    'Ho trovato un raggio di sole della misura esatta di un drago',
    'Un drago coraggioso può temere una porta cigolante?',
    'Sto provando il mio più eroico piccolo ruggito',
    'La torre profuma di storie e sogni tostati',
    'Quella nuvola sembra sospettosamente cavalcabile',
    'La mia ombra è sembrata enorme per quasi due secondi',
    'Vorrei un piccolo forziere tutto mio',
    'Ho provato a ruggire, ma è uscito uno squittio',
    'La lanterna rende magnifiche le mie corna',
    'Ogni pianta dovrebbe avere un nome eroico',
    'Voglio mappare ogni balcone della torre',
    'Ti ho tenuto il posto più caldo accanto al nido',
    'Riesco quasi a raggiungere lo scaffale più alto',
    'Ho un piano per rendere questa stanza più accogliente',
    'La luce del sole è perfetta per i pisolini dei draghi',
    'L’Osservatorio delle Rune ha lasciato una scintilla nei miei pensieri',
    'Ora la mia coda regge tre cuscini in equilibrio',
    'Il giardino lunare sussurra nuovi segreti',
    'Ho ordinato i cuscini per morbidezza massima',
    'Ogni nuova forma fa vibrare il Draconomicon',
    'Credo che sotto quella sedia si nasconda una vecchia moneta',
    'Il focolare ha bisogno di un ispettore ufficiale di marshmallow',
    'Posso portare questo tesoro tutto da solo',
    'Ho memorizzato il percorso dal nido agli spuntini',
    'Le stelle in soffitta sembrano abbastanza vicine da solleticare',
    'I nostri mobili raccontano ai visitatori chi vive qui',
    'Oggi merita un giro d’onore in ogni stanza',
    'Conosco ogni stanza a occhi chiusi',
    'Ieri il percorso sulla scogliera era certamente più corto',
    'Sto preparando una danza di benvenuto per i nuovi mobili',
    'Quell’angolo vuoto avrebbe bisogno di qualcosa di brillante',
    'Ho spostato il cuscino per motivi scientifici',
    'Conosco ogni scricchiolio e raggio di luna di questo santuario',
    'Ogni stanza custodisce una parte diversa della nostra storia',
    'Posso sorvegliare la torre mentre tutti riposano',
    'Il focolare conserva le storie più calde per le sere fredde',
    'Il giardino lunare dimostra che la cura silenziosa conta',
    'L’osservatorio fa sembrare piccole anche le grandi preoccupazioni',
    'Un legame paziente risplende più di qualsiasi tesoro',
    'Ali forti si costruiscono un giorno attento alla volta',
    'Ogni cuscino ha un angolo approvato per il pisolino',
    'Lo scaffale più alto non può più sfuggirmi',
    'Ricordo il primo suono sentito dentro l’uovo',
    'Un drago saggio nota quando qualcuno ha bisogno di conforto',
    'Il tempo insieme conta più della nostra collezione',
    'Stanotte conterò stelle e forzieri ancora chiusi',
    'Questo nido sarà sempre casa per me',
    'Le scoperte più piccole portano spesso la gioia più grande',
    'Posso insegnare ai cuccioli ad ascoltare il vento',
    'Una stanza cambia quando qualcuno se ne prende davvero cura',
    'Ho un ricordo preferito in ogni angolo',
    'Domani sarà un’altra pagina del Draconomicon',
  ],
  'pt': [
    'Será que a lua vai para onde durante o dia?',
    'Minhas asas aprenderam três novos jeitos de balançar',
    'Inspecionei esta tábua e a declarei aconchegante',
    'Será que nuvens são tão macias quanto minha almofada?',
    'Ouvi o armário de petiscos sussurrar meu nome',
    'Minha cauda parece um pouco mais forte hoje',
    'Quero contar todas as estrelas acima da Torre',
    'A samambaia lunar com certeza acenou para mim',
    'Encontrei um raio de sol do tamanho exato de um dragão',
    'Um dragão corajoso pode ter medo de uma porta rangendo?',
    'Estou praticando meu rugidinho mais heroico',
    'A torre tem cheiro de histórias e sonhos tostados',
    'Aquela nuvem parece suspeitosamente montável',
    'Minha sombra ficou enorme por quase dois segundos',
    'Eu gostaria de ter um baú do tesouro bem pequenino',
    'Tentei rugir, mas saiu um guincho',
    'A lanterna deixa meus chifres magníficos',
    'Toda planta deveria ter um nome heroico',
    'Quero mapear todas as varandas da torre',
    'Guardei para você o lugar mais quentinho ao lado do ninho',
    'Quase consigo alcançar a prateleira mais alta',
    'Tenho um plano para deixar este cômodo mais aconchegante',
    'A luz do sol é perfeita para cochilos de dragão',
    'O Observatório de Runas deixou uma faísca nos meus pensamentos',
    'Minha cauda agora equilibra três almofadas',
    'O jardim lunar está sussurrando novos segredos',
    'Organizei as almofadas por maciez máxima',
    'Cada nova forma faz o Draconomicon vibrar',
    'Acho que uma moeda antiga se esconde embaixo daquela cadeira',
    'A lareira precisa de um inspetor oficial de marshmallows',
    'Consigo carregar este tesouro sem ajuda',
    'Decorei o caminho do ninho até os petiscos',
    'As estrelas do sótão parecem perto o bastante para fazer cócegas',
    'Nossos móveis contam às visitas quem mora aqui',
    'Hoje merece uma volta da vitória por todos os cômodos',
    'Conheço todos os cômodos de olhos fechados',
    'O percurso do penhasco era menor ontem, com certeza',
    'Estou praticando uma dança de boas-vindas para móveis novos',
    'Aquele canto vazio precisa de algo brilhante',
    'Mudei a almofada por motivos científicos',
    'Conheço cada rangido e cada raio de lua deste santuário',
    'Cada cômodo guarda uma parte diferente da nossa história',
    'Posso vigiar a torre enquanto todos descansam',
    'A lareira guarda as histórias mais quentes para noites frias',
    'O jardim lunar prova que o cuidado tranquilo importa',
    'O observatório faz até grandes preocupações parecerem pequenas',
    'Um vínculo paciente brilha mais que qualquer tesouro',
    'Asas fortes são construídas com cuidado, um dia de cada vez',
    'Toda almofada tem um ângulo de cochilo aprovado',
    'A prateleira mais alta não pode mais fugir de mim',
    'Lembro do primeiro som que ouvi dentro do ovo',
    'Um dragão sábio percebe quando alguém precisa de conforto',
    'Nosso tempo juntos importa mais que nossa coleção',
    'Hoje à noite vou contar estrelas e baús fechados',
    'Este ninho sempre será meu lar',
    'As menores descobertas costumam trazer a maior alegria',
    'Posso ensinar os filhotes a escutar o vento',
    'Um cômodo muda quando alguém cuida dele de verdade',
    'Tenho uma lembrança favorita em cada canto',
    'Amanhã será mais uma página do Draconomicon',
  ],
  'zh': [
    '我想知道白天月亮去了哪里',
    '我的翅膀学会了三种新的摇晃方式',
    '我检查了这块地板，并宣布它很舒适',
    '云朵会像我的软垫一样柔软吗',
    '我听见零食柜在轻声叫我的名字',
    '我的尾巴今天好像更有力了',
    '我想数清高塔上方的每一颗星星',
    '月光蕨刚才绝对向我挥手了',
    '我找到了一束大小正适合龙的阳光',
    '勇敢的龙也可以害怕吱呀作响的门吗',
    '我正在练习最英勇的小小吼声',
    '高塔闻起来像故事和烤得暖暖的梦',
    '那朵云看起来很可疑地适合骑乘',
    '我的影子看起来巨大无比，足足接近两秒',
    '我想要一个属于自己的超小宝箱',
    '我试着吼叫，结果只发出了吱吱声',
    '这盏灯让我的角显得威风极了',
    '每株植物都应该有一个英雄般的名字',
    '我想画出高塔每个阳台的地图',
    '我给你留了巢穴旁边最温暖的位置',
    '我快能碰到最高的架子了',
    '我有一个让这个房间更舒适的计划',
    '阳光最适合龙打盹了',
    '符文观测站在我的思绪中留下了一点火花',
    '我的尾巴现在能同时托住三个软垫',
    '月光花园正在低声诉说新的秘密',
    '我按柔软程度把软垫排好了',
    '每发现一种新形态，《龙之秘典》都会轻轻鸣响',
    '我觉得那把椅子下面藏着一枚古老金币',
    '炉火边需要一位官方棉花糖检查员',
    '我可以独自搬动这件宝物',
    '我已经记住了从巢穴到零食的路线',
    '阁楼上的星星近得仿佛可以挠痒',
    '我们的家具会告诉访客是谁住在这里',
    '今天值得绕所有房间庆祝一圈',
    '闭着眼睛我也认识每个房间',
    '悬崖训练场昨天肯定没这么长',
    '我在为新家具练习欢迎舞',
    '那个空角落应该放点闪亮的东西',
    '我移动软垫是出于科学原因',
    '我熟悉这个庇护所里的每一声吱响和每一束月光',
    '每个房间都收藏着我们故事的不同片段',
    '大家休息时，我可以守望高塔',
    '炉火会把最温暖的故事留给寒冷的夜晚',
    '月光花园证明安静的照料同样重要',
    '在观测站里，再大的烦恼也显得很小',
    '耐心建立的羁绊比任何宝物都耀眼',
    '强健的翅膀来自日复一日的细心成长',
    '每个软垫都有一个经过批准的午睡角度',
    '最高的架子再也逃不过我了',
    '我还记得在蛋里听见的第一个声音',
    '聪明的龙会注意到谁需要安慰',
    '我们相伴的时光比收藏更重要',
    '今晚我要数星星和还没打开的宝箱',
    '这个巢穴对我来说永远是家',
    '最小的发现往往能带来最大的快乐',
    '我可以教幼龙聆听风的声音',
    '当有人真心照料时，房间也会改变',
    '每个角落都有一段我最喜欢的回忆',
    '明天又会为《龙之秘典》写下新的一页',
  ],
  'ja': [
    '昼のあいだ、月はどこへ行くのでしょう',
    '翼が新しいふらつき方を三つ覚えました',
    'この床板を調べて、居心地よしと認定しました',
    '雲はクッションと同じくらい柔らかいのでしょうか',
    'おやつ棚が私の名前をささやくのを聞きました',
    '今日は尻尾が少し強くなった気がします',
    '塔の上に見える星を全部数えたいです',
    '月のシダが確かに手を振ってくれました',
    'ドラゴンにちょうどいい大きさの日だまりを見つけました',
    '勇敢なドラゴンでも、きしむ扉を怖がっていいですか',
    'いちばん勇ましい小さな咆哮を練習しています',
    '塔は物語とこんがり焼けた夢の香りがします',
    'あの雲は怪しいほど乗りやすそうです',
    '私の影が、ほぼ二秒も巨大に見えました',
    '自分だけの、とても小さな宝箱がほしいです',
    '吠えようとしたら、きゅっと鳴いてしまいました',
    'ランタンのおかげで角が立派に見えます',
    'すべての植物に勇ましい名前をつけるべきです',
    '塔のバルコニーを全部地図にしたいです',
    '巣のとなりで一番あたたかい場所を取っておきました',
    'もう少しで一番高い棚に届きます',
    'この部屋をもっと居心地よくする計画があります',
    '日差しはドラゴンの昼寝にぴったりです',
    'ルーン観測所が思考の中に火花を残しました',
    '尻尾でクッションを三つ運べるようになりました',
    '月の庭園が新しい秘密をささやいています',
    'クッションを柔らかさ順に並べました',
    '新しい形態を見つけるたび、ドラコノミコンが歌います',
    'あの椅子の下に古いコインが隠れている気がします',
    '暖炉には公式マシュマロ検査官が必要です',
    'この宝物なら一人で運べます',
    '巣からおやつまでの道を暗記しました',
    'ロフトの星は、くすぐれそうなくらい近く見えます',
    '家具を見れば、誰がここに住んでいるか分かります',
    '今日は全部屋を勝利の行進で回るべき日です',
    '目を閉じても、すべての部屋が分かります',
    '崖のコースは昨日のほうが絶対に短かったです',
    '新しい家具を迎える踊りを練習しています',
    'あの空いた隅には、光るものが必要です',
    '科学的な理由でクッションを動かしました',
    'この聖域のきしむ音も月明かりも、すべて知っています',
    'どの部屋にも、私たちの物語の一片があります',
    'みんなが休むあいだ、塔を見守れます',
    '暖炉は寒い夜のために一番あたたかな物語を残しています',
    '月の庭園は、静かなお世話も大切だと教えてくれます',
    '観測所から見ると、大きな悩みさえ小さく見えます',
    '時間をかけて結んだ絆は、どんな宝物より輝きます',
    '強い翼は、丁寧な一日一日の積み重ねで育ちます',
    'どのクッションにも公認の昼寝角度があります',
    'もう一番高い棚にも逃げられません',
    '卵の中で最初に聞いた音を覚えています',
    '賢いドラゴンは、誰かが慰めを必要としていると気づきます',
    '一緒に過ごす時間は、コレクションより大切です',
    '今夜は星と未開封の宝箱を数えます',
    'この巣はいつまでも私の家です',
    '小さな発見ほど、大きな喜びを運んでくれます',
    '幼竜たちに風の声の聞き方を教えられます',
    '誰かが本当に大切にすると、部屋も変わります',
    'どの隅にも、お気に入りの思い出があります',
    '明日はドラコノミコンの新しい一ページです',
  ],
};

DragonDialogueLine dialogueFor(Pet pet, DateTime now) {
  final stageLines = dragonDialogueLines
      .where((line) => line.stageKey == pet.stageKey)
      .toList();
  final tone = pet.energy < 55
      ? DragonDialogueTone.calm
      : pet.joy > 88
          ? DragonDialogueTone.playful
          : pet.comfort > 88
              ? DragonDialogueTone.affectionate
              : pet.leadingPath == 'might'
                  ? DragonDialogueTone.proud
                  : DragonDialogueTone.adventurous;
  final candidates = stageLines.where((line) => line.tone == tone).toList();
  final index = (pet.hatchSeed + pet.xp * 7 + now.minute)
      .abs()
      .remainder(candidates.length);
  return candidates[index];
}
