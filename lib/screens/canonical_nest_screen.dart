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
    final session = context.read<CanonicalGameSession>();
    final owner = session.snapshot?.ownerId;
    final epoch = session.connection.sessionEpoch;
    if (!session.canAct || session.snapshot?.nest != null) {
      return;
    }
    final selected = await showModalBottomSheet<String>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (sheetContext) => SafeArea(
            child: SizedBox(
                height: MediaQuery.sizeOf(sheetContext).height * .78,
                child: CanonicalEggList(
                    forNest: true,
                    onChoose: (id) => Navigator.pop(sheetContext, id)))));
    if (selected == null ||
        !mounted ||
        !session.canAct ||
        session.snapshot?.ownerId != owner ||
        session.connection.sessionEpoch != epoch ||
        session.snapshot?.nest != null) {
      return;
    }
    await runShopAction(
        context, () => CanonicalGameActions(session).activateEgg(selected));
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
            child: ListView(
                key: const PageStorageKey('rooftop-nest-scroll'),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 34),
                children: [
              Text(s.pick('Rooftop Nest', 'Daknest'),
                  style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 5),
              Text(
                  egg == null
                      ? s.pick(
                          'A quiet cradle for the next life in your collection.',
                          'Een rustige wieg voor het volgende leven in je collectie.')
                      : s.pick(
                          'One hidden dragon is growing beneath the shell.',
                          'Onder de schaal groeit \u00e9\u00e9n verborgen draak.'),
                  style: const TextStyle(color: AppColors.muted, fontSize: 15)),
              const SizedBox(height: 15),
              _NestScene(
                  hasEgg: egg != null,
                  starter: egg?.firstEgg == true,
                  onTap: _tap),
              const SizedBox(height: 16),
              if (egg != null) ...[
                EggHatchCountdown.confirmed(
                    eggId: egg.id,
                    confirmedHatchAt: egg.hatchAt!,
                    serverTime: view.serverTime),
                const SizedBox(height: 14),
                Container(
                    key: const Key('nest-egg-hint-card'),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(21),
                        border: Border.all(color: AppColors.mist)),
                    child: Row(children: [
                      const GameIconSprite(GameIconKind.mysteriousEgg,
                          key: Key('nest-egg-hint-icon'), size: 46),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(egg.hint(s.languageCode),
                              key: const Key('nest-egg-hint-text'),
                              style: const TextStyle(
                                  color: AppColors.muted,
                                  fontWeight: FontWeight.w700,
                                  fontStyle: FontStyle.italic))),
                    ])),
              ] else
                _EmptyNestCard(
                    hasEggs: view.eggs.any(
                        (e) => !view.inventory.reservedEggIds.contains(e.id)),
                    onChoose: _choose),
            ])));
  }
}

class _NestScene extends StatelessWidget {
  const _NestScene(
      {required this.hasEgg, required this.starter, required this.onTap});

  final bool hasEgg, starter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: !hasEgg || starter,
        child: InkWell(
          key: const Key('rooftop-nest-scene'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Ink(
            height: 270,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(28)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (!hasEgg)
                    const Positioned.fill(
                      child: HavenPhaseImage(
                        assetFor: _nestAssetForPhase,
                      ),
                    )
                  else
                    const Positioned(
                      left: 0,
                      top: 0,
                      right: 0,
                      bottom: 0,
                      child: RooftopEggNest(),
                    ),
                  if (!hasEgg)
                    Positioned(
                      left: 18,
                      right: 18,
                      bottom: 15,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.eventColor(
                              context, const Color(0xD91D1639)),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .18),
                          ),
                        ),
                        child: Text(
                          AppStrings.of(context).pick(
                            'Tap the nest to choose an egg',
                            'Tik op het nest om een ei te kiezen',
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
}

String _nestAssetForPhase(HavenDayPhase value) =>
    'assets/images/tower_nest_${value.assetKey}.webp';

class _EmptyNestCard extends StatelessWidget {
  const _EmptyNestCard({required this.hasEggs, required this.onChoose});

  final bool hasEggs;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF2ECFF), Color(0xFFFFF4D9)],
        ),
        borderRadius: BorderRadius.circular(22),
        border:
            Border.all(color: AppColors.eventColor(context, AppColors.mist)),
      ),
      child: Row(children: [
        const GameIconSprite(GameIconKind.mysteriousEgg, size: 58),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.pick('The nest is empty', 'Het nest is leeg'),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 3),
              Text(
                hasEggs
                    ? strings.pick(
                        'Choose one egg from your inventory.',
                        'Kies één ei uit je inventaris.',
                      )
                    : strings.pick(
                        'Rare eggs can be found in chests earned on Adventures.',
                        'Zeldzame eieren kun je vinden in kisten die je met Adventures verdient.',
                      ),
                style: const TextStyle(color: AppColors.muted),
              ),
            ],
          ),
        ),
        if (hasEggs)
          IconButton.filledTonal(
            key: const Key('choose-nest-egg'),
            tooltip: strings.pick('Choose an egg', 'Kies een ei'),
            onPressed: onChoose,
            icon: const Icon(Icons.arrow_forward_rounded),
          ),
      ]),
    );
  }
}
