class TowerInteractionDefinition {
  const TowerInteractionDefinition({
    required this.id,
    required this.requiredTag,
    required this.messageEn,
    required this.messageNl,
  });

  final String id;
  final String requiredTag;
  final String messageEn;
  final String messageNl;
}

const towerInteractions = <TowerInteractionDefinition>[
  TowerInteractionDefinition(
    id: 'book_surprise',
    requiredTag: 'books',
    messageEn:
        '{dragon} pulled out a book and looked shocked by chapter three.',
    messageNl:
        '{dragon} trok een boek tevoorschijn en keek geschokt bij hoofdstuk drie.',
  ),
  TowerInteractionDefinition(
    id: 'fireplace_curl',
    requiredTag: 'fireplace',
    messageEn:
        '{dragon} curled up by the fire and immediately claimed the warmest spot.',
    messageNl:
        '{dragon} rolde zich op bij het vuur en pikte meteen de warmste plek in.',
  ),
  TowerInteractionDefinition(
    id: 'snack_inspection',
    requiredTag: 'food',
    messageEn:
        '{dragon} inspected the snacks. One snack is now mysteriously absent.',
    messageNl:
        '{dragon} inspecteerde de hapjes. Eentje is nu op mysterieuze wijze verdwenen.',
  ),
  TowerInteractionDefinition(
    id: 'water_splash',
    requiredTag: 'water',
    messageEn: '{dragon} made one tiny splash and one extremely non-tiny mess.',
    messageNl:
        '{dragon} maakte één klein plonsje en één buitengewoon grote bende.',
  ),
  TowerInteractionDefinition(
    id: 'treasure_count',
    requiredTag: 'treasure',
    messageEn: '{dragon} counted every shiny object twice, just to be certain.',
    messageNl:
        '{dragon} telde elk glimmend voorwerp twee keer, voor de zekerheid.',
  ),
  TowerInteractionDefinition(
    id: 'plant_nap',
    requiredTag: 'plants',
    messageEn:
        '{dragon} disappeared between the leaves for a highly strategic nap.',
    messageNl:
        '{dragon} verdween tussen de bladeren voor een bijzonder strategisch dutje.',
  ),
  TowerInteractionDefinition(
    id: 'bed_fort',
    requiredTag: 'bed',
    messageEn: '{dragon} turned the bedding into a fort. No adults allowed.',
    messageNl:
        '{dragon} bouwde van het beddengoed een fort. Volwassenen verboden.',
  ),
  TowerInteractionDefinition(
    id: 'magic_echo',
    requiredTag: 'magic',
    messageEn: '{dragon} tapped the magic ornament. It politely tapped back.',
    messageNl:
        '{dragon} tikte tegen het magische ornament. Het tikte beleefd terug.',
  ),
];

const roomOnlyInteraction = TowerInteractionDefinition(
  id: 'room_contentment',
  requiredTag: '',
  messageEn:
      '{dragon} looked around, nodded once, and declared this room acceptable.',
  messageNl:
      '{dragon} keek rond, knikte één keer en verklaarde deze kamer goedgekeurd.',
);
