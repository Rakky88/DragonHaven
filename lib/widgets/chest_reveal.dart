import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/chest.dart';
import '../models/mystic_relic.dart';
import 'game_icon_sprite.dart';

Future<void> showChestReveal(
  BuildContext context,
  ChestTier tier, {
  required Future<ChestReward?> Function() openChest,
  FutureOr<void> Function()? onOpen,
}) =>
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ChestReveal(
        tier: tier,
        openChest: openChest,
        onOpen: onOpen,
      ),
    );

class _ChestReveal extends StatefulWidget {
  const _ChestReveal({
    required this.tier,
    required this.openChest,
    this.onOpen,
  });
  final ChestTier tier;
  final Future<ChestReward?> Function() openChest;
  final FutureOr<void> Function()? onOpen;

  @override
  State<_ChestReveal> createState() => _ChestRevealState();
}

class _ChestRevealState extends State<_ChestReveal>
    with TickerProviderStateMixin {
  bool _opened = false;
  bool _opening = false;
  bool _lidRevealed = false;
  bool _flash = false;
  ChestReward? _reward;
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1450),
  )..repeat(reverse: true);
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  late final AnimationController _openingMotion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2500),
  );

  @override
  void dispose() {
    _float.dispose();
    _burst.dispose();
    _openingMotion.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    if (_opening || _opened) return;
    setState(() => _opening = true);
    final reward = await widget.openChest();
    if (!mounted) return;
    if (reward == null) {
      Navigator.pop(context);
      return;
    }
    _reward = reward;
    final callback = widget.onOpen;
    if (callback != null) unawaited(Future<void>.sync(callback));
    unawaited(_openingMotion.forward());
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _flash = true);
    await Future<void>.delayed(const Duration(milliseconds: 240));
    if (!mounted) return;
    setState(() {
      _lidRevealed = true;
    });
    unawaited(_burst.forward());
    await Future<void>.delayed(const Duration(milliseconds: 260));
    if (!mounted) return;
    setState(() => _flash = false);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _opened = true);
  }

  void _close() {
    if (_opened) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final tier = widget.tier;
    final accent = Color(tier.colorValue);
    return PopScope(
      canPop: _opened,
      child: Dialog.fullscreen(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _opened ? _close : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _flash
                    ? const [Colors.white, Colors.white]
                    : const [
                        Color(0xFF100A2A),
                        Color(0xFF30215D),
                        Color(0xFF17102F),
                      ],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 76,
                  left: -110,
                  child: _GlowOrb(color: accent, size: 260),
                ),
                Positioned(
                  right: -90,
                  bottom: 38,
                  child: _GlowOrb(color: accent, size: 230),
                ),
                SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GameIconSprite(
                              GameIconKind.chest,
                              size: 42,
                              semanticLabel: strings.chestLabel(tier),
                            ),
                            const SizedBox(height: 9),
                            Text(
                              strings.chestLabel(tier),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 28,
                                letterSpacing: -.4,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _opened
                                  ? strings.pick(
                                      'Treasure revealed', 'Schat onthuld')
                                  : _opening
                                      ? strings.pick('Ancient magic awakens',
                                          'Oude magie ontwaakt')
                                      : strings.pick('Sealed treasure',
                                          'Verzegelde schat'),
                              style: const TextStyle(
                                color: Color(0xFFC9C2E5),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Semantics(
                              button: !_opening && !_opened,
                              label: _opening
                                  ? strings.pick('Chest opening', 'Kist opent')
                                  : strings.chestLabel(tier),
                              child: GestureDetector(
                                key: const Key('chest-reveal-tap-target'),
                                onTap: _opening || _opened ? null : _open,
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 300,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: 286,
                                        height: 286,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color:
                                                accent.withValues(alpha: .42),
                                          ),
                                          gradient: RadialGradient(colors: [
                                            accent.withValues(alpha: .48),
                                            accent.withValues(alpha: .12),
                                            Colors.transparent,
                                          ]),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  accent.withValues(alpha: .32),
                                              blurRadius: 56,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (_opening || _opened)
                                        AnimatedBuilder(
                                          animation: _openingMotion,
                                          builder: (_, child) =>
                                              Transform.scale(
                                            scale: .35 +
                                                _openingMotion.value * .95,
                                            child: Opacity(
                                              opacity:
                                                  (_openingMotion.value * 1.2)
                                                      .clamp(0, 1),
                                              child: child,
                                            ),
                                          ),
                                          child: Image.asset(
                                            GameVfxAssets.chestBurst,
                                            width: 305,
                                            height: 305,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      AnimatedBuilder(
                                        animation: Listenable.merge(
                                            [_float, _openingMotion]),
                                        builder: (_, child) {
                                          final direction =
                                              (_openingMotion.value * 18)
                                                      .round()
                                                      .isEven
                                                  ? 1.0
                                                  : -1.0;
                                          final shake = _opening
                                              ? (1 - _openingMotion.value) *
                                                  4 *
                                                  direction
                                              : 0.0;
                                          return Transform.translate(
                                            offset: Offset(
                                              shake,
                                              _lidRevealed
                                                  ? 0
                                                  : -5 + _float.value * 10,
                                            ),
                                            child: Transform.scale(
                                              scale: _lidRevealed
                                                  ? 1.05
                                                  : .96 + _float.value * .035,
                                              child: child,
                                            ),
                                          );
                                        },
                                        child: AnimatedSwitcher(
                                          duration:
                                              const Duration(milliseconds: 700),
                                          transitionBuilder:
                                              (child, animation) =>
                                                  FadeTransition(
                                            opacity: animation,
                                            child: ScaleTransition(
                                                scale:
                                                    Tween(begin: .82, end: 1.0)
                                                        .animate(animation),
                                                child: child),
                                          ),
                                          child: Padding(
                                            key: ValueKey(_lidRevealed),
                                            padding: const EdgeInsets.all(8),
                                            child: Image.asset(
                                              _lidRevealed
                                                  ? tier.openedAssetPath
                                                  : tier.assetPath,
                                              fit: BoxFit.contain,
                                              filterQuality: FilterQuality.high,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 480),
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(
                                opacity: animation,
                                child: ScaleTransition(
                                  scale: Tween(begin: .86, end: 1.0)
                                      .animate(animation),
                                  child: child,
                                ),
                              ),
                              child: !_opened
                                  ? const SizedBox(
                                      key: Key('chest-opening'), height: 72)
                                  : Column(
                                      key: const Key('chest-rewards'),
                                      children: [
                                        Wrap(
                                          alignment: WrapAlignment.center,
                                          spacing: 9,
                                          runSpacing: 9,
                                          children: [
                                            _Reward(
                                              kind: GameIconKind.coin,
                                              value: '+${_reward!.coins}',
                                              label: strings.tr('coins'),
                                            ),
                                            if (_reward!.gems > 0)
                                              _Reward(
                                                kind: GameIconKind.gem,
                                                value: '+${_reward!.gems}',
                                                label: strings.tr('gems'),
                                              ),
                                            if (_reward!.eggFound)
                                              _Reward(
                                                kind:
                                                    GameIconKind.mysteriousEgg,
                                                value: '1',
                                                label: strings.pick(
                                                  'Mysterious Egg',
                                                  'Mysterieus Ei',
                                                ),
                                              ),
                                            if (_reward!.relicFound
                                                case final relic?)
                                              _RelicReward(
                                                relic: relic,
                                                label: strings.relicName(relic),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 18),
                                        Text(
                                          strings.pick(
                                            'Tap anywhere to return',
                                            'Tik ergens om terug te gaan',
                                          ),
                                          style: const TextStyle(
                                            color: Color(0xFFC9C2E5),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ],
                        ),
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
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              color.withValues(alpha: .15),
              Colors.transparent,
            ]),
          ),
        ),
      );
}

class _Reward extends StatelessWidget {
  const _Reward({
    required this.kind,
    required this.value,
    required this.label,
  });

  final GameIconKind kind;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .94),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          GameIconSprite(kind, size: 30),
          const SizedBox(width: 7),
          Text('$value $label',
              style: const TextStyle(fontWeight: FontWeight.w900)),
        ]),
      );
}

class _RelicReward extends StatelessWidget {
  const _RelicReward({required this.relic, required this.label});

  final MysticRelic relic;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF6D7), Color(0xFFE9DEFF)],
          ),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0x66FFE08A)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Image.asset(relic.assetPath, width: 38, height: 38),
          const SizedBox(width: 7),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ]),
      );
}
