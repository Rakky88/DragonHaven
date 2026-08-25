import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/chest.dart';
import '../models/dragon_egg.dart';
import '../models/game_presentation.dart';
import '../models/mystic_relic.dart';
import '../providers/household_provider.dart';
import '../theme/app_theme.dart';
import 'game_icon_sprite.dart';

Future<void> showTradeReveal(
  BuildContext context,
  HouseholdProvider game,
  GamePresentation presentation,
) =>
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0xE8110923),
      transitionDuration: const Duration(milliseconds: 650),
      transitionBuilder: (_, animation, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween(begin: .72, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.elasticOut),
          ),
          child: child,
        ),
      ),
      pageBuilder: (dialogContext, _, __) => _TradeReveal(
        game: game,
        presentation: presentation,
        onContinue: () => Navigator.pop(dialogContext),
      ),
    );

class _TradeReveal extends StatefulWidget {
  const _TradeReveal({
    required this.game,
    required this.presentation,
    required this.onContinue,
  });

  final HouseholdProvider game;
  final GamePresentation presentation;
  final VoidCallback onContinue;

  @override
  State<_TradeReveal> createState() => _TradeRevealState();
}

class _TradeRevealState extends State<_TradeReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final payload = widget.presentation.payload;
    final sent = _RevealItem.fromPayload(payload, 'sent');
    final received = _RevealItem.fromPayload(payload, 'received');
    return PopScope(
      canPop: false,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Material(
              color: Colors.transparent,
              child: Container(
                key: const Key('trade-complete-reveal'),
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF4A287E), Color(0xFF1B1034)],
                  ),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: AppColors.gold, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Color(0x886E43C8), blurRadius: 42),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (_, child) => Transform.rotate(
                        angle: sin(_controller.value * pi * 2) * .035,
                        child: Transform.scale(
                          scale: .96 + _controller.value * .06,
                          child: child,
                        ),
                      ),
                      child: const GameIconSprite(
                        GameIconKind.friendsTrade,
                        size: 104,
                      ),
                    ),
                    Text(
                      strings.pick('TRADE COMPLETE!', 'RUIL VOLTOOID!'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFFFE08A),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      strings.pick(
                        'The exchange is safely sealed.',
                        'De uitwisseling is veilig bezegeld.',
                      ),
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _TradeItemCard(
                            eyebrow: strings.pick('YOU SENT', 'JIJ GAF'),
                            item: sent,
                            game: widget.game,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: AnimatedBuilder(
                            animation: _controller,
                            builder: (_, child) => Transform.translate(
                              offset: Offset(
                                (_controller.value - .5) * 8,
                                0,
                              ),
                              child: child,
                            ),
                            child: const Icon(
                              Icons.swap_horiz_rounded,
                              color: Color(0xFFFFE08A),
                              size: 34,
                            ),
                          ),
                        ),
                        Expanded(
                          child: _TradeItemCard(
                            eyebrow: strings.pick('YOU RECEIVED', 'JIJ KREEG'),
                            item: received,
                            game: widget.game,
                            received: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        key: const Key('trade-reveal-continue'),
                        onPressed: widget.onContinue,
                        icon: const Icon(Icons.check_circle_rounded),
                        label: Text(strings.pick('Continue', 'Verder')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TradeItemCard extends StatelessWidget {
  const _TradeItemCard({
    required this.eyebrow,
    required this.item,
    required this.game,
    this.received = false,
  });

  final String eyebrow;
  final _RevealItem item;
  final HouseholdProvider game;
  final bool received;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 11),
        decoration: BoxDecoration(
          color: received
              ? const Color(0x22FFE08A)
              : Colors.white.withValues(alpha: .07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: received ? const Color(0xFFFFE08A) : Colors.white24,
          ),
        ),
        child: Column(
          children: [
            Text(
              eyebrow,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 8,
                letterSpacing: .8,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            _TradeItemArt(item: item),
            const SizedBox(height: 7),
            Text(
              item.label(AppStrings.of(context), game),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
}

class _TradeItemArt extends StatelessWidget {
  const _TradeItemArt({required this.item});

  final _RevealItem item;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: 72,
        child: switch (item.kind) {
          'chest' => Image.asset(
              item.chest?.assetPath ?? ChestTier.wooden.assetPath,
              fit: BoxFit.contain,
            ),
          'relic' => Image.asset(
              item.relic?.assetPath ?? MysticRelic.moralPrism.assetPath,
              fit: BoxFit.contain,
            ),
          _ => const GameIconSprite(GameIconKind.mysteriousEgg, size: 72),
        },
      );
}

class _RevealItem {
  const _RevealItem(this.kind, this.key, this.data);

  final String kind;
  final String key;
  final Map<String, dynamic> data;

  factory _RevealItem.fromPayload(Map<String, dynamic> payload, String prefix) {
    final rawData = payload['${prefix}Data'];
    return _RevealItem(
      payload['${prefix}Kind']?.toString() ?? 'egg',
      payload['${prefix}Key']?.toString() ?? '',
      rawData is Map ? Map<String, dynamic>.from(rawData) : const {},
    );
  }

  ChestTier? get chest => ChestTier.values.cast<ChestTier?>().firstWhere(
        (value) => value?.name == key,
        orElse: () => null,
      );

  MysticRelic? get relic => MysticRelic.values.cast<MysticRelic?>().firstWhere(
        (value) => value?.name == key,
        orElse: () => null,
      );

  String label(AppStrings strings, HouseholdProvider game) {
    if (kind == 'chest') {
      return chest?.label(strings.isDutch) ?? strings.pick('Chest', 'Kist');
    }
    if (kind == 'relic') {
      final value = relic;
      return value == null
          ? strings.pick('Relic', 'Reliek')
          : strings.relicName(value);
    }
    final egg = DragonEgg.fromJson({...data, 'id': key});
    return game.eggHintForEgg(egg, locale: strings.languageCode);
  }
}
