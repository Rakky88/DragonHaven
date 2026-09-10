import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import 'game_icon_sprite.dart';

/// Rounded down, so a shortened balance never promises an extra coin or gem.
String compactBalance(int value) {
  const units = ['', 'K', 'M', 'B', 'T', 'Qa', 'Qi'];
  var unit = 0, divisor = 1;
  while (unit < units.length - 1 && value >= divisor * 1000) {
    divisor *= 1000;
    unit++;
  }
  if (unit == 0) return '$value';
  final whole = value ~/ divisor;
  final tenth = (value % divisor) ~/ (divisor ~/ 10);
  return '$whole${whole < 100 && tenth > 0 ? '.$tenth' : ''}${units[unit]}';
}

class HavenHeaderTitle extends StatelessWidget {
  const HavenHeaderTitle({
    super.key,
    required this.subtitle,
    this.coins,
    this.gems,
  });

  final String subtitle;
  final int? coins, gems;

  static double toolbarHeight(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return max(76, scaler.scale(19) + scaler.scale(11) + 32);
  }

  static const _brandStyle = TextStyle(
    color: AppColors.ink,
    fontSize: 19,
    height: 1,
    fontWeight: FontWeight.w900,
    letterSpacing: -.65,
  );
  static const _balanceStyle = TextStyle(
      color: AppColors.ink, fontSize: 11, fontWeight: FontWeight.w900);

  double _textWidth(BuildContext context, String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(
          text: text, style: DefaultTextStyle.of(context).style.merge(style)),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, size) {
        final brand = FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text.rich(
            key: const Key('haven-full-brand'),
            TextSpan(children: [
              const TextSpan(text: 'Dragon'),
              TextSpan(
                text: 'Haven',
                style: TextStyle(
                    color: AppColors.eventColor(context, AppColors.twilight)),
              ),
            ]),
            maxLines: 1,
            overflow: TextOverflow.visible,
            style: _brandStyle,
          ),
        );
        final section = Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
                color: AppColors.gold, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Flexible(
              child: Text(subtitle.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 9,
                      height: 1,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .75))),
        ]);
        if (coins == null || gems == null) {
          return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [brand, const SizedBox(height: 5), section]);
        }
        final walletWidth =
            _textWidth(context, compactBalance(coins!), _balanceStyle) +
                _textWidth(context, compactBalance(gems!), _balanceStyle) +
                66;
        final inline = size.maxWidth >=
            _textWidth(context, 'DragonHaven', _brandStyle) + walletWidth + 16;
        final wallet = _wallet(context);
        if (inline) {
          return Row(children: [
            Expanded(
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [brand, const SizedBox(height: 5), section]),
            ),
            const SizedBox(width: 10),
            wallet,
          ]);
        }
        return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              brand,
              const SizedBox(height: 4),
              Row(children: [
                Expanded(child: section),
                const SizedBox(width: 6),
                // Currency gets its own row beside the section subtitle. Its
                // width cannot take space away from the name above it.
                Flexible(
                    flex: 0,
                    child: ConstrainedBox(
                        constraints:
                            BoxConstraints(maxWidth: size.maxWidth - 6),
                        child:
                            FittedBox(fit: BoxFit.scaleDown, child: wallet))),
              ]),
            ]);
      });

  Widget _wallet(BuildContext context) {
    final strings = AppStrings.of(context);
    final coinLabel = strings.tr('coins'), gemLabel = strings.tr('gems');
    final exact = '$coinLabel: $coins\n$gemLabel: $gems';
    return Semantics(
      button: true,
      label: exact,
      excludeSemantics: true,
      child: Tooltip(
        message: exact,
        child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                  color: AppColors.eventColor(context, AppColors.mist))),
          child: InkWell(
            key: const Key('haven-balances'),
            borderRadius: BorderRadius.circular(20),
            onTap: () => showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              builder: (context) => SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    for (final entry in [
                      (GameIconKind.coin, coinLabel, coins!),
                      (GameIconKind.gem, gemLabel, gems!),
                    ])
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: GameIconSprite(entry.$1, size: 32),
                        title: Text(entry.$2),
                        subtitle: SelectableText('${entry.$3}',
                            style:
                                const TextStyle(fontWeight: FontWeight.w900)),
                      ),
                  ]),
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                GameIconSprite(GameIconKind.coin, size: 18),
                const SizedBox(width: 3),
                Text(compactBalance(coins!), style: _balanceStyle),
                const SizedBox(width: 8),
                GameIconSprite(GameIconKind.gem, size: 18),
                const SizedBox(width: 3),
                Text(compactBalance(gems!), style: _balanceStyle),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
