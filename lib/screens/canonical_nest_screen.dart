import '../models/day_phase.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../services/canonical_game_session.dart';
import '../services/canonical_game_actions.dart';
import '../theme/app_theme.dart';
import '../widgets/haven_lighting.dart';
import '../widgets/rooftop_egg_nest.dart';
import '../widgets/game_icon_sprite.dart';
import '../widgets/shop_economy_scope.dart';
import 'canonical_eggs.dart';
import 'pet_screen.dart' show EggHatchCountdown;

class CanonicalNestScreen extends StatefulWidget {
  const CanonicalNestScreen({super.key});
  @override
  State<CanonicalNestScreen> createState() => _CanonicalNestScreenState();
}

class _CanonicalNestScreenState extends State<CanonicalNestScreen> {
  String? _seenEgg;
  Timer? _batch;
  int _taps = 0;
  @override
  void dispose() {
    _batch?.cancel();
    super.dispose();
  }

  Future<void> _choose() async {
    await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (_) => SizedBox(
            height: MediaQuery.sizeOf(context).height * .78,
            child: const CanonicalEggList()));
  }

  void _tap() {
    final session = context.read<CanonicalGameSession>();
    final egg = session.snapshot?.nest;
    if (egg == null) {
      unawaited(_choose());
      return;
    }
    if (!egg.firstEgg || !session.canAct || _taps >= 30) return;
    final owner = session.snapshot!.ownerId;
    final epoch = session.connection.sessionEpoch;
    _taps++;
    _batch ??= Timer(const Duration(milliseconds: 300), () async {
      _batch = null;
      final taps = _taps;
      _taps = 0;
      if (!mounted ||
          !session.canAct ||
          session.snapshot?.ownerId != owner ||
          session.connection.sessionEpoch != epoch ||
          session.snapshot?.nest?.id != egg.id) {
        return;
      }
      await runShopAction(
          context,
          () => CanonicalGameActions(session)
              .execute('tap_starter_egg', {'eggId': egg.id, 'taps': taps}));
    });
  }

  @override
  Widget build(BuildContext context) {
    final view = context.watch<CanonicalGameSession>().snapshot!;
    final egg = view.nest;
    final s = AppStrings.of(context);
    if (_seenEgg != null && egg == null && view.dragon(_seenEgg!) != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && ModalRoute.of(context)?.isCurrent == true) {
          Navigator.pop(context);
        }
      });
    }
    if (egg != null) _seenEgg = egg.id;
    return Scaffold(
        appBar: AppBar(title: Text(s.pick('Rooftop Nest', 'Daknest'))),
        body: ShopEconomyBoundary(
            child: ListView(padding: const EdgeInsets.all(16), children: [
          Text(s.pick('Rooftop Nest', 'Daknest'),
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(
              egg == null
                  ? s.pick(
                      'A quiet cradle for the next life in your collection.',
                      'Een rustige wieg voor het volgende leven in je collectie.')
                  : s.pick('One hidden dragon is growing beneath the shell.',
                      'Onder de schaal groeit \u00e9\u00e9n verborgen draak.'),
              style: const TextStyle(color: AppColors.muted, fontSize: 15)),
          const SizedBox(height: 15),
          InkWell(
              key: const Key('rooftop-nest-scene'),
              onTap: _tap,
              borderRadius: BorderRadius.circular(28),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: SizedBox(
                      height: 270,
                      child: egg == null
                          ? HavenPhaseImage(
                              assetFor: (phase) =>
                                  'assets/images/tower_nest_${phase.assetKey}.webp')
                          : const RooftopEggNest()))),
          const SizedBox(height: 16),
          if (egg != null) ...[
            EggHatchCountdown.confirmed(
                eggId: egg.id,
                confirmedHatchAt: egg.hatchAt!,
                serverTime: view.serverTime),
            const SizedBox(height: 14),
            Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(21),
                    border: Border.all(color: AppColors.mist)),
                child: Row(children: [
                  const GameIconSprite(GameIconKind.mysteriousEgg, size: 46),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(egg.hint(s.languageCode),
                          style: const TextStyle(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w700,
                              fontStyle: FontStyle.italic))),
                ])),
            TextButton(
                onPressed: () => showCanonicalEggDetails(context, egg.id),
                child: Text(s.pick('Details', 'Informatie'))),
          ] else
            Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFFF2ECFF), Color(0xFFFFF4D9)]),
                    borderRadius: BorderRadius.circular(22)),
                child: Column(children: [
                  Text(s.pick('The nest is empty', 'Het nest is leeg'),
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                  Text(s.pick('Choose one egg from your inventory.',
                      'Kies \u00e9\u00e9n ei uit je inventaris.')),
                  FilledButton(
                      onPressed: _choose,
                      child: Text(s.pick('Choose an egg', 'Kies een ei'))),
                ])),
        ])));
  }
}
