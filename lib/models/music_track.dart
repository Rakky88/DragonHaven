class MusicTrack {
  const MusicTrack({
    required this.id,
    required this.title,
    required this.composer,
  });

  final String id;
  final String title;
  final String composer;

  String get rawResourceId => 'music_$id';
}

/// Stable jukebox order. IDs are persisted in saves and must never be reused.
const musicCatalog = <MusicTrack>[
  MusicTrack(id: 'clair_de_lune', title: 'Clair de Lune', composer: 'Debussy'),
  MusicTrack(id: 'arabesque_1', title: 'Arabesque No. 1', composer: 'Debussy'),
  MusicTrack(id: 'reverie', title: 'Rêverie', composer: 'Debussy'),
  MusicTrack(
    id: 'flaxen_hair',
    title: 'The Girl with the Flaxen Hair',
    composer: 'Debussy',
  ),
  MusicTrack(
    id: 'golliwoggs_cakewalk',
    title: "Golliwogg's Cakewalk",
    composer: 'Debussy',
  ),
  MusicTrack(id: 'gymnopedie_1', title: 'Gymnopédie No. 1', composer: 'Satie'),
  MusicTrack(id: 'gymnopedie_2', title: 'Gymnopédie No. 2', composer: 'Satie'),
  MusicTrack(id: 'gymnopedie_3', title: 'Gymnopédie No. 3', composer: 'Satie'),
  MusicTrack(id: 'gnossienne_1', title: 'Gnossienne No. 1', composer: 'Satie'),
  MusicTrack(id: 'gnossienne_3', title: 'Gnossienne No. 3', composer: 'Satie'),
  MusicTrack(id: 'je_te_veux', title: 'Je te veux', composer: 'Satie'),
  MusicTrack(id: 'fur_elise', title: 'Für Elise', composer: 'Beethoven'),
  MusicTrack(
    id: 'moonlight_1',
    title: 'Moonlight Sonata – I',
    composer: 'Beethoven',
  ),
  MusicTrack(
    id: 'moonlight_3',
    title: 'Moonlight Sonata – III',
    composer: 'Beethoven',
  ),
  MusicTrack(
    id: 'pathetique_2',
    title: 'Pathétique Sonata – II',
    composer: 'Beethoven',
  ),
  MusicTrack(id: 'ode_to_joy', title: 'Ode to Joy', composer: 'Beethoven'),
  MusicTrack(
    id: 'symphony_5_1',
    title: 'Symphony No. 5 – I',
    composer: 'Beethoven',
  ),
  MusicTrack(
    id: 'symphony_7_2',
    title: 'Symphony No. 7 – II',
    composer: 'Beethoven',
  ),
  MusicTrack(
    id: 'eine_kleine_nachtmusik',
    title: 'Eine kleine Nachtmusik',
    composer: 'Mozart',
  ),
  MusicTrack(
      id: 'rondo_alla_turca', title: 'Rondo Alla Turca', composer: 'Mozart'),
  MusicTrack(
    id: 'symphony_40_1',
    title: 'Symphony No. 40 – I',
    composer: 'Mozart',
  ),
  MusicTrack(
    id: 'sonata_k545_1',
    title: 'Piano Sonata K.545 – I',
    composer: 'Mozart',
  ),
  MusicTrack(id: 'lacrimosa', title: 'Lacrimosa', composer: 'Mozart'),
  MusicTrack(id: 'dies_irae', title: 'Dies Irae – Requiem', composer: 'Mozart'),
  MusicTrack(id: 'ave_verum', title: 'Ave Verum Corpus', composer: 'Mozart'),
  MusicTrack(id: 'canon_in_d', title: 'Canon in D', composer: 'Pachelbel'),
  MusicTrack(
      id: 'air_g_string', title: 'Air on the G String', composer: 'Bach'),
  MusicTrack(
      id: 'prelude_c_major', title: 'Prelude in C Major', composer: 'Bach'),
  MusicTrack(
    id: 'toccata_fugue_d_minor',
    title: 'Toccata and Fugue in D Minor',
    composer: 'Bach',
  ),
  MusicTrack(
    id: 'cello_suite_1_prelude',
    title: 'Cello Suite No. 1 Prelude',
    composer: 'Bach',
  ),
  MusicTrack(
    id: 'jesu_joy',
    title: "Jesu, Joy of Man's Desiring",
    composer: 'Bach',
  ),
  MusicTrack(id: 'badinerie', title: 'Badinerie', composer: 'Bach'),
  MusicTrack(
    id: 'minuet_g_major',
    title: 'Minuet in G Major (BWV Anh.114)',
    composer: 'Petzold',
  ),
  MusicTrack(id: 'spring', title: 'Spring – Four Seasons', composer: 'Vivaldi'),
  MusicTrack(
      id: 'summer_presto', title: 'Summer – Presto', composer: 'Vivaldi'),
  MusicTrack(id: 'autumn_1', title: 'Autumn – I', composer: 'Vivaldi'),
  MusicTrack(id: 'winter_1', title: 'Winter – I', composer: 'Vivaldi'),
  MusicTrack(id: 'winter_2', title: 'Winter – II', composer: 'Vivaldi'),
  MusicTrack(
    id: 'sugar_plum',
    title: 'Dance of the Sugar Plum Fairy',
    composer: 'Tchaikovsky',
  ),
  MusicTrack(
    id: 'waltz_flowers',
    title: 'Waltz of the Flowers',
    composer: 'Tchaikovsky',
  ),
  MusicTrack(id: 'trepak', title: 'Trepak', composer: 'Tchaikovsky'),
  MusicTrack(
      id: 'swan_lake_scene',
      title: 'Swan Lake – Scene',
      composer: 'Tchaikovsky'),
  MusicTrack(
    id: 'sleeping_beauty_waltz',
    title: 'Sleeping Beauty Waltz',
    composer: 'Tchaikovsky',
  ),
  MusicTrack(
      id: '1812_finale',
      title: '1812 Overture – Finale',
      composer: 'Tchaikovsky'),
  MusicTrack(
    id: 'mountain_king',
    title: 'In the Hall of the Mountain King',
    composer: 'Grieg',
  ),
  MusicTrack(id: 'morning_mood', title: 'Morning Mood', composer: 'Grieg'),
  MusicTrack(id: 'anitras_dance', title: "Anitra's Dance", composer: 'Grieg'),
  MusicTrack(id: 'solveigs_song', title: "Solveig's Song", composer: 'Grieg'),
  MusicTrack(
      id: 'nocturne_9_2', title: 'Nocturne Op. 9 No. 2', composer: 'Chopin'),
  MusicTrack(
      id: 'prelude_28_4', title: 'Prelude Op. 28 No. 4', composer: 'Chopin'),
  MusicTrack(
    id: 'raindrop_prelude',
    title: 'Prelude Op. 28 No. 15 “Raindrop”',
    composer: 'Chopin',
  ),
  MusicTrack(
    id: 'minute_waltz',
    title: 'Waltz Op. 64 No. 1 “Minute Waltz”',
    composer: 'Chopin',
  ),
  MusicTrack(id: 'funeral_march', title: 'Funeral March', composer: 'Chopin'),
  MusicTrack(
      id: 'fantaisie_impromptu',
      title: 'Fantaisie-Impromptu',
      composer: 'Chopin'),
  MusicTrack(
      id: 'hungarian_dance_5',
      title: 'Hungarian Dance No. 5',
      composer: 'Brahms'),
  MusicTrack(
      id: 'hungarian_dance_6',
      title: 'Hungarian Dance No. 6',
      composer: 'Brahms'),
  MusicTrack(id: 'lullaby', title: 'Lullaby (Wiegenlied)', composer: 'Brahms'),
  MusicTrack(
      id: 'blue_danube',
      title: 'The Blue Danube',
      composer: 'Johann Strauss II'),
  MusicTrack(
    id: 'tritsch_tratsch',
    title: 'Tritsch-Tratsch-Polka',
    composer: 'Johann Strauss II',
  ),
  MusicTrack(
      id: 'radetzky_march',
      title: 'Radetzky March',
      composer: 'Johann Strauss I'),
  MusicTrack(id: 'can_can', title: 'Can-Can', composer: 'Offenbach'),
  MusicTrack(id: 'barcarolle', title: 'Barcarolle', composer: 'Offenbach'),
  MusicTrack(
      id: 'ride_valkyries', title: 'Ride of the Valkyries', composer: 'Wagner'),
  MusicTrack(id: 'bridal_chorus', title: 'Bridal Chorus', composer: 'Wagner'),
  MusicTrack(
    id: 'bumblebee',
    title: 'Flight of the Bumblebee',
    composer: 'Rimsky-Korsakov',
  ),
  MusicTrack(
    id: 'scheherazade_prince_princess',
    title: 'Scheherazade – Young Prince and Princess',
    composer: 'Rimsky-Korsakov',
  ),
  MusicTrack(
    id: 'procession_nobles',
    title: 'Procession of the Nobles',
    composer: 'Rimsky-Korsakov',
  ),
  MusicTrack(
      id: 'entertainer', title: 'The Entertainer', composer: 'Scott Joplin'),
  MusicTrack(
      id: 'maple_leaf_rag', title: 'Maple Leaf Rag', composer: 'Scott Joplin'),
  MusicTrack(
      id: 'easy_winners', title: 'The Easy Winners', composer: 'Scott Joplin'),
  MusicTrack(id: 'solace', title: 'Solace', composer: 'Scott Joplin'),
  MusicTrack(
      id: 'elite_syncopations',
      title: 'Elite Syncopations',
      composer: 'Scott Joplin'),
  MusicTrack(
      id: 'greensleeves', title: 'Greensleeves', composer: 'Traditional'),
  MusicTrack(
      id: 'scarborough_fair',
      title: 'Scarborough Fair',
      composer: 'Traditional'),
  MusicTrack(
      id: 'drunken_sailor', title: 'Drunken Sailor', composer: 'Traditional'),
  MusicTrack(
    id: 'irish_washerwoman',
    title: 'The Irish Washerwoman',
    composer: 'Traditional',
  ),
  MusicTrack(id: 'korobeiniki', title: 'Korobeiniki', composer: 'Traditional'),
  MusicTrack(
    id: 'house_rising_sun',
    title: 'House of the Rising Sun',
    composer: 'Traditional',
  ),
  MusicTrack(
      id: 'amazing_grace', title: 'Amazing Grace', composer: 'Traditional'),
  MusicTrack(
      id: 'auld_lang_syne', title: 'Auld Lang Syne', composer: 'Traditional'),
];

final musicTracksById = <String, MusicTrack>{
  for (final track in musicCatalog) track.id: track,
};
