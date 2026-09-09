import 'package:flutter/material.dart';

class EventAppearance extends ThemeExtension<EventAppearance> {
  static const logoKeys = <String, String>{
    'halloween_witchlight': 'halloween',
    'christmas_winter_hearth': 'christmas',
    'new_year_first_dawn': 'new_year',
    'valentine_two_heartlights': 'valentine',
    'pride_every_color': 'pride',
    'golden_wings_birthday': 'golden_wings',
    'harvestmoon_moonlit_orchard': 'harvestmoon',
    'sunwake_summer_sea': 'sunwake',
  };

  static String logoForEvent(String id) {
    final key = logoKeys[id];
    return key == null
        ? 'assets/images/dragonhaven_logo.png'
        : 'assets/images/event_logos/$key.png';
  }

  const EventAppearance(
      {required this.folder,
      required this.primary,
      required this.accent,
      required this.paper,
      required this.motif});

  final String? folder;
  final Color primary;
  final Color accent;
  final Color paper;
  final IconData motif;

  bool get isPride => folder == 'pride';

  List<Color> get panelColors => isPride
      ? const [
          Color(0xFF843B53),
          Color(0xFF825421),
          Color(0xFF28634D),
          Color(0xFF345681),
          Color(0xFF624795)
        ]
      : [Color.lerp(primary, Colors.black, .22)!, primary];

  @override
  EventAppearance copyWith({Color? primary, Color? accent, Color? paper}) =>
      EventAppearance(
          folder: folder,
          primary: primary ?? this.primary,
          accent: accent ?? this.accent,
          paper: paper ?? this.paper,
          motif: motif);

  @override
  EventAppearance lerp(covariant EventAppearance? other, double t) =>
      other == null || t < .5 ? this : other;

  String get _extension =>
      folder == 'sunwake' || folder == 'harvestmoon' ? 'png' : 'webp';

  String? get background => folder == null
      ? null
      : 'assets/images/events/$folder/trial_background.$_extension';
  String? get emblem => folder == null || folder == 'golden_wings'
      ? null
      : 'assets/images/events/$folder/trial_icon.$_extension';

  static EventAppearance forEvent(String id) => switch (id) {
        'sunwake_summer_sea' => const EventAppearance(
            folder: 'sunwake',
            primary: Color(0xFF238B91),
            accent: Color(0xFFF5A7A0),
            paper: Color(0xFFE6F9EE),
            motif: Icons.waves_rounded),
        'harvestmoon_moonlit_orchard' => const EventAppearance(
            folder: 'harvestmoon',
            primary: Color(0xFF806038),
            accent: Color(0xFFB96B45),
            paper: Color(0xFFF5E8CA),
            motif: Icons.eco_rounded),
        'halloween_witchlight' => const EventAppearance(
            folder: 'halloween',
            primary: Color(0xFF513277),
            accent: Color(0xFFF2A34B),
            paper: Color(0xFFF6EFFA),
            motif: Icons.nightlight_round),
        'christmas_winter_hearth' => const EventAppearance(
            folder: 'christmas',
            primary: Color(0xFF285D55),
            accent: Color(0xFFD69B51),
            paper: Color(0xFFEDF6F2),
            motif: Icons.ac_unit_rounded),
        'new_year_first_dawn' => const EventAppearance(
            folder: 'new_year',
            primary: Color(0xFF374A79),
            accent: Color(0xFFECC96A),
            paper: Color(0xFFF0F2FA),
            motif: Icons.auto_awesome_rounded),
        'valentine_two_heartlights' => const EventAppearance(
            folder: 'valentine',
            primary: Color(0xFFAE4778),
            accent: Color(0xFFFFD6E6),
            paper: Color(0xFFFFF3F7),
            motif: Icons.favorite_rounded),
        'pride_every_color' => const EventAppearance(
            folder: 'pride',
            primary: Color(0xFF624795),
            accent: Color(0xFF69CBB3),
            paper: Color(0xFFF4F0FB),
            motif: Icons.wb_sunny_rounded),
        _ => const EventAppearance(
            folder: 'golden_wings',
            primary: Color(0xFF7D5B29),
            accent: Color(0xFFF0C759),
            paper: Color(0xFFFFF6DE),
            motif: Icons.auto_awesome_rounded),
      };
}
