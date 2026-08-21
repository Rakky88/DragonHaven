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
  String text(bool isDutch) => '“${isDutch ? nl : en}”';
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
