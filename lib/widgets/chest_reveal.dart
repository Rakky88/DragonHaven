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
      backgroundColor: const Color(0xFF211B46),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        color: _flash ? Colors.white : Colors.transparent,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
            child: Column(children: [
              Text(strings.chestLabel(tier),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 27)),
              const Spacer(),
              GestureDetector(
                key: const Key('chest-reveal-tap'),
                onTap: _open,
                child: AnimatedBuilder(
                  animation: _float,
                  builder: (_, child) => Transform.scale(
                    scale: _opened ? 1.08 : .98 + _float.value * .04,
                    child: child,
                  ),
                  child: Container(
                    width: 270,
                    height: 270,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        accent.withValues(alpha: .42),
                        Colors.transparent,
                      ]),
                    ),
                    child: Image.asset(tier.assetPath, fit: BoxFit.contain),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 420),
                child: !_opened
                    ? Text(
                        strings.pick('Tap the chest', 'Tik op de kist'),
                        key: const Key('chest-closed-label'),
                        style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w800,
                            fontSize: 17),
                      )
                    : Wrap(
                        key: const Key('chest-rewards'),
                        alignment: WrapAlignment.center,
                        spacing: 9,
                        runSpacing: 9,
                        children: [
                          _Reward(Icons.monetization_on_rounded,
                              '+${widget.reward.coins}', strings.tr('coins')),
                          if (widget.reward.gems > 0)
                            _Reward(Icons.diamond_rounded,
                                '+${widget.reward.gems}', strings.tr('gems')),
                          _Reward(Icons.auto_awesome_rounded,
                              '+${widget.reward.xp}', 'XP'),
                          if (widget.reward.eggFound)
                            _Reward(
                                Icons.egg_alt_rounded,
                                '1',
                                strings.pick(
                                    'Mysterious Egg', 'Mysterieus Ei')),
                        ],
                      ),
              ),
              const Spacer(),
              if (_opened)
                FilledButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check_rounded),
                  label: Text(strings.pick('Collect', 'Verzamelen')),
                ),
            ]),
          ),
        ),
      ),
    );
  }
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
