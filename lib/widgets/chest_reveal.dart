import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/chest.dart';

Future<void> showChestReveal(BuildContext context, ChestReward reward) =>
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ChestReveal(reward: reward),
    );

class _ChestReveal extends StatefulWidget {
  const _ChestReveal({required this.reward});
  final ChestReward reward;

  @override
  State<_ChestReveal> createState() => _ChestRevealState();
}

class _ChestRevealState extends State<_ChestReveal>
    with SingleTickerProviderStateMixin {
  bool _opened = false;
  bool _flash = false;
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1450),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    if (_opened) return;
    setState(() => _flash = true);
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    setState(() {
      _flash = false;
      _opened = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final tier = widget.reward.tier;
    final accent = Color(tier.colorValue);
    return Dialog.fullscreen(
      backgroundColor: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _flash
                ? const [Colors.white, Colors.white]
                : const [
                    Color(0xFF16112F),
                    Color(0xFF292052),
                    Color(0xFF17122F),
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
                        Icon(
                          _opened
                              ? Icons.auto_awesome_rounded
                              : Icons.lock_open_rounded,
                          color: const Color(0xFFFFD76A),
                          size: 30,
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
                                  'Treasure claimed', 'Schat gevonden')
                              : strings.pick('A tower treasure awaits',
                                  'Een torenschat wacht op je'),
                          style: const TextStyle(
                            color: Color(0xFFC9C2E5),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          key: const Key('chest-reveal-tap'),
                          onTap: _open,
                          child: Semantics(
                            button: true,
                            label:
                                strings.pick('Tap the chest', 'Tik op de kist'),
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
                                        color: accent.withValues(alpha: .42),
                                      ),
                                      gradient: RadialGradient(colors: [
                                        accent.withValues(alpha: .48),
                                        accent.withValues(alpha: .12),
                                        Colors.transparent,
                                      ]),
                                      boxShadow: [
                                        BoxShadow(
                                          color: accent.withValues(alpha: .32),
                                          blurRadius: 56,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                  AnimatedBuilder(
                                    animation: _float,
                                    builder: (_, child) => Transform.translate(
                                      offset: Offset(
                                        0,
                                        _opened ? 0 : -5 + _float.value * 10,
                                      ),
                                      child: Transform.scale(
                                        scale: _opened
                                            ? 1.08
                                            : .96 + _float.value * .035,
                                        child: child,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(18),
                                      child: Image.asset(
                                        tier.assetPath,
                                        fit: BoxFit.contain,
                                        filterQuality: FilterQuality.high,
                                      ),
                                    ),
                                  ),
                                  if (_opened) ...const [
                                    _TreasureSpark(
                                        alignment: Alignment(-.82, -.62),
                                        size: 29),
                                    _TreasureSpark(
                                        alignment: Alignment(.78, -.35),
                                        size: 22),
                                    _TreasureSpark(
                                        alignment: Alignment(-.66, .48),
                                        size: 19),
                                    _TreasureSpark(
                                        alignment: Alignment(.72, .62),
                                        size: 27),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 420),
                          child: !_opened
                              ? Container(
                                  key: const Key('chest-closed-label'),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: .09),
                                    borderRadius: BorderRadius.circular(99),
                                    border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: .14),
                                    ),
                                  ),
                                  child: Text(
                                    strings.pick(
                                        'Tap the chest', 'Tik op de kist'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                )
                              : Wrap(
                                  key: const Key('chest-rewards'),
                                  alignment: WrapAlignment.center,
                                  spacing: 9,
                                  runSpacing: 9,
                                  children: [
                                    _Reward(
                                      Icons.monetization_on_rounded,
                                      '+${widget.reward.coins}',
                                      strings.tr('coins'),
                                    ),
                                    if (widget.reward.gems > 0)
                                      _Reward(
                                        Icons.diamond_rounded,
                                        '+${widget.reward.gems}',
                                        strings.tr('gems'),
                                      ),
                                    _Reward(
                                      Icons.auto_awesome_rounded,
                                      '+${widget.reward.xp}',
                                      'XP',
                                    ),
                                    if (widget.reward.eggFound)
                                      _Reward(
                                        Icons.egg_alt_rounded,
                                        '1',
                                        strings.pick(
                                          'Mysterious Egg',
                                          'Mysterieus Ei',
                                        ),
                                      ),
                                  ],
                                ),
                        ),
                        if (_opened) ...[
                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.check_rounded),
                              label:
                                  Text(strings.pick('Collect', 'Verzamelen')),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
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

class _TreasureSpark extends StatelessWidget {
  const _TreasureSpark({required this.alignment, required this.size});

  final Alignment alignment;
  final double size;

  @override
  Widget build(BuildContext context) => Align(
        alignment: alignment,
        child: Icon(
          Icons.auto_awesome_rounded,
          size: size,
          color: const Color(0xFFFFE895),
        ),
      );
}

class _Reward extends StatelessWidget {
  const _Reward(this.icon, this.value, this.label);
  final IconData icon;
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
          Icon(icon, size: 20, color: const Color(0xFF5F4A8E)),
          const SizedBox(width: 6),
          Text('$value $label',
              style: const TextStyle(fontWeight: FontWeight.w900)),
        ]),
      );
}
