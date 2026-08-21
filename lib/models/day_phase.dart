enum HavenDayPhase { deepNight, dawn, morning, day, goldenHour, dusk, night }

enum DragonTimeMood { active, restful, asleep, waking }

class HavenLightingState {
  const HavenLightingState({
    required this.from,
    required this.to,
    required this.progress,
  });

  final HavenDayPhase from;
  final HavenDayPhase to;
  final double progress;
}

HavenDayPhase havenDayPhaseAt(DateTime local) {
  final minutes = local.hour * 60 + local.minute;
  if (minutes < 300) return HavenDayPhase.deepNight;
  if (minutes < 420) return HavenDayPhase.dawn;
  if (minutes < 600) return HavenDayPhase.morning;
  if (minutes < 1020) return HavenDayPhase.day;
  if (minutes < 1140) return HavenDayPhase.goldenHour;
  if (minutes < 1260) return HavenDayPhase.dusk;
  return HavenDayPhase.night;
}

DragonTimeMood dragonTimeMoodAt(
  DateTime local,
  int visualSeed, {
  bool suppressed = false,
}) {
  if (suppressed) return DragonTimeMood.active;
  final staggeredMinute =
      local.hour * 60 + local.minute + visualSeed.abs().remainder(23);
  return switch (havenDayPhaseAt(local)) {
    HavenDayPhase.deepNight ||
    HavenDayPhase.night =>
      staggeredMinute.remainder(12) < 9
          ? DragonTimeMood.asleep
          : DragonTimeMood.restful,
    HavenDayPhase.dusk => staggeredMinute.remainder(15) < 6
        ? DragonTimeMood.restful
        : DragonTimeMood.active,
    HavenDayPhase.dawn ||
    HavenDayPhase.morning =>
      staggeredMinute.remainder(18) < 5
          ? DragonTimeMood.waking
          : DragonTimeMood.active,
    HavenDayPhase.day || HavenDayPhase.goldenHour => DragonTimeMood.active,
  };
}

HavenLightingState havenLightingAt(DateTime local) {
  final minute =
      local.hour * 60 + local.minute + local.second / Duration.secondsPerMinute;
  const transitions = <(double, HavenDayPhase, HavenDayPhase)>[
    (0, HavenDayPhase.night, HavenDayPhase.deepNight),
    (300, HavenDayPhase.deepNight, HavenDayPhase.dawn),
    (420, HavenDayPhase.dawn, HavenDayPhase.morning),
    (600, HavenDayPhase.morning, HavenDayPhase.day),
    (1020, HavenDayPhase.day, HavenDayPhase.goldenHour),
    (1140, HavenDayPhase.goldenHour, HavenDayPhase.dusk),
    (1260, HavenDayPhase.dusk, HavenDayPhase.night),
    (1440, HavenDayPhase.night, HavenDayPhase.deepNight),
  ];
  for (final transition in transitions) {
    final distance = minute - transition.$1;
    if (distance >= -10 && distance <= 10) {
      return HavenLightingState(
        from: transition.$2,
        to: transition.$3,
        progress: ((distance + 10) / 20).clamp(0.0, 1.0).toDouble(),
      );
    }
  }
  final phase = havenDayPhaseAt(local);
  return HavenLightingState(from: phase, to: phase, progress: 0.0);
}

extension HavenDayPhaseInfo on HavenDayPhase {
  String label(bool isDutch) => switch (this) {
        HavenDayPhase.deepNight => isDutch ? 'Diepe Nacht' : 'Deep Night',
        HavenDayPhase.dawn => isDutch ? 'Dageraad' : 'Dawn',
        HavenDayPhase.morning => isDutch ? 'Ochtend' : 'Morning',
        HavenDayPhase.day => isDutch ? 'Dag' : 'Day',
        HavenDayPhase.goldenHour => isDutch ? 'Gouden Uur' : 'Golden Hour',
        HavenDayPhase.dusk => isDutch ? 'Schemering' : 'Dusk',
        HavenDayPhase.night => isDutch ? 'Nacht' : 'Night',
      };

  bool get isDark =>
      this == HavenDayPhase.deepNight ||
      this == HavenDayPhase.dusk ||
      this == HavenDayPhase.night;

  String get assetKey => switch (this) {
        HavenDayPhase.deepNight => 'deep_night',
        HavenDayPhase.dawn => 'dawn',
        HavenDayPhase.morning => 'morning',
        HavenDayPhase.day => 'day',
        HavenDayPhase.goldenHour => 'golden_hour',
        HavenDayPhase.dusk => 'dusk',
        HavenDayPhase.night => 'night',
      };
}
