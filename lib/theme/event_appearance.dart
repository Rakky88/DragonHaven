import 'package:flutter/material.dart';

class EventAppearance {
  static const logoKeys = <String, String>{
    'halloween_witchlight': 'halloween',
    'christmas_winter_hearth': 'christmas',
    'new_year_first_dawn': 'new_year',
    'valentine_two_heartlights': 'valentine',
    'pride_every_color': 'pride',
    'golden_wings_birthday': 'golden_wings',
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

  String? get background => folder == null
      ? null
      : 'assets/images/events/$folder/trial_background.webp';
  String? get emblem =>
      folder == null ? null : 'assets/images/events/$folder/trial_icon.webp';

  static EventAppearance forEvent(String id) => switch (id) {
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
            primary: Color(0xFF8B3B63),
            accent: Color(0xFFECA8B9),
            paper: Color(0xFFFFF0F4),
            motif: Icons.favorite_rounded),
        'pride_every_color' => const EventAppearance(
            folder: 'pride',
            primary: Color(0xFF624795),
            accent: Color(0xFF69CBB3),
            paper: Color(0xFFF4F0FB),
            motif: Icons.wb_sunny_rounded),
        _ => const EventAppearance(
            folder: null,
            primary: Color(0xFF7D5B29),
            accent: Color(0xFFF0C759),
            paper: Color(0xFFFFF6DE),
            motif: Icons.auto_awesome_rounded),
      };
}
