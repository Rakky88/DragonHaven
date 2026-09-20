import '../models/egg_altar.dart';
import 'game_icon_sprite.dart';
// Presentation restored from published v0.05.39 (d71cc8e). No player state or mutations.
import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/mystic_relic.dart';
import '../theme/app_theme.dart';

class RestoredChestCard extends StatelessWidget {
  const RestoredChestCard({
    super.key,
    required this.assetPath,
    required this.color,
    required this.title,
    required this.count,
    required this.openKey,
    required this.openTenKey,
    required this.canOpen,
    required this.canOpenTen,
    required this.onOpen,
    required this.onOpenTen,
  });

  final String assetPath;
  final Color color;
  final String title;
  final int count;
  final Key openKey;
  final Key openTenKey;
  final bool canOpen;
  final bool canOpenTen;
  final VoidCallback onOpen;
  final VoidCallback onOpenTen;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 9, 8),
        child: Row(children: [
          Container(
            width: 72,
            height: 72,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Image.asset(assetPath, fit: BoxFit.contain),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  '×$count',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton(
                key: openKey,
                onPressed: canOpen ? onOpen : null,
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                ),
                child: Text(strings.pick('Open', 'Openen')),
              ),
              if (count >= 10) ...[
                const SizedBox(height: 5),
                OutlinedButton(
                  key: openTenKey,
                  onPressed: canOpenTen ? onOpenTen : null,
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                  ),
                  child: Text(strings.pick('Open 10', 'Open er 10')),
                ),
              ],
            ],
          ),
        ]),
      ),
    );
  }
}

class RestoredAcademyEntrance extends StatelessWidget {
  const RestoredAcademyEntrance(
      {super.key, required this.unlocked, required this.onTap});
  final bool unlocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final cardHeight = 136.0 + (textScale - 1).clamp(0, 1.5) * 220;
    return Semantics(
      button: unlocked,
      enabled: unlocked,
      label: strings.pick('Dragon Academy', 'Drakenacademie'),
      child: InkWell(
        key: const Key('dragon-school-entrance'),
        onTap: unlocked ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          height: cardHeight,
          decoration: BoxDecoration(
            color: const Color(0xFF302454),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/ui/dragon_school.webp',
                  fit: BoxFit.cover,
                  color: unlocked ? null : const Color(0x99605B67),
                  colorBlendMode: unlocked ? null : BlendMode.saturation,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                      colors: [Color(0xEE211638), Color(0x44211638)]),
                  border: Border.all(
                    color: unlocked ? AppColors.gold : Colors.white24,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .13),
                        shape: BoxShape.circle,
                      ),
                      child: unlocked
                          ? Image.asset(
                              'assets/images/ui/dragon_school/dragon_school_icon.png',
                              width: 52,
                              height: 52,
                            )
                          : const Icon(Icons.lock_rounded,
                              color: Colors.white70, size: 32),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.pick('Dragon Academy', 'Drakenacademie'),
                            key: const Key('tutorial-dragon-school-title'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            unlocked
                                ? strings.pick(
                                    '10 lessons · dragons, stars and records',
                                    '10 lessen · draken, sterren en records',
                                  )
                                : strings.pick(
                                    'Unlocks when your Tower has 5 floors',
                                    'Ontgrendelt bij 5 Torenverdiepingen',
                                  ),
                            maxLines: textScale > 1.2 ? 4 : 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFE5DAF3),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (unlocked)
                      const Icon(Icons.chevron_right_rounded,
                          color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RestoredRelicCard extends StatelessWidget {
  const RestoredRelicCard({
    super.key,
    required this.relic,
    required this.count,
    required this.canUse,
    required this.onUse,
    this.detail,
  });

  final MysticRelic relic;
  final int count;
  final bool canUse;
  final VoidCallback onUse;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(9, 9, 11, 9),
        child: Row(children: [
          Container(
            width: 84,
            height: 84,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              gradient: const RadialGradient(
                colors: [Color(0xFFFFF3BF), Color(0xFFE9DEFF)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Image.asset(relic.assetPath, fit: BoxFit.contain),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(
                      strings.relicName(relic),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  Text(
                    '×$count',
                    style: TextStyle(
                      color: AppColors.eventColor(context, AppColors.twilight),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ]),
                const SizedBox(height: 3),
                Text(
                  strings.relicDescription(relic),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
                if (detail != null && detail!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    detail!,
                    style: TextStyle(
                      color: AppColors.eventColor(context, AppColors.twilight),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
                const SizedBox(height: 7),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.tonal(
                    key: Key('use-relic-${relic.name}'),
                    onPressed: canUse ? onUse : null,
                    child: Text(strings.pick('Use', 'Gebruiken')),
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class RestoredRelicEmptyState extends StatelessWidget {
  const RestoredRelicEmptyState({super.key, required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 390),
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
            decoration: BoxDecoration(
              gradient: AppColors.panelGradient(context,
                  fallback: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF25194C), Color(0xFF624899)])),
              borderRadius: BorderRadius.circular(30),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x44342469),
                  blurRadius: 28,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Image.asset(
                MysticRelic.soulMirror.assetPath,
                width: 148,
                height: 148,
                fit: BoxFit.contain,
              ),
              Text(
                strings.pick('No Relics yet', 'Nog geen Relieken'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                strings.pick(
                  'These exceptionally rare treasures can appear in Gold Chests and rarer chests.',
                  'Deze uitzonderlijk zeldzame schatten kunnen verschijnen in Gouden Kisten en zeldzamere kisten.',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFD8CFF1),
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ]),
          ),
        ),
      );
}

String altarRelicEffect(AppStrings s, AltarRelic relic) => switch (relic) {
      AltarRelic.moralEcho => s.pick('Reveal an egg’s moral alignment.',
          'Onthul de morele aard van een ei.'),
      AltarRelic.orderSigil => s.pick('Reveal an egg’s order alignment.',
          'Onthul de orde-aard van een ei.'),
      AltarRelic.astralLens =>
        s.pick('Reveal an egg’s rarity.', 'Onthul de zeldzaamheid van een ei.'),
      AltarRelic.weaveOracle => s.pick(
          'Reveal an egg’s dragon family and rarity.',
          'Onthul de drakenfamilie en zeldzaamheid van een ei.'),
      AltarRelic.nameweaversQuill => s.pick(
          'Rename one dragon. Consumed on use.',
          'Hernoem één draak. Eenmalig te gebruiken.'),
    };

class RestoredAltarRecipeCard extends StatelessWidget {
  const RestoredAltarRecipeCard(
      {super.key,
      required this.relic,
      this.inventoryOnly = false,
      required this.owned,
      this.onCraft,
      this.onUse});
  final AltarRelic relic;
  final bool inventoryOnly;
  final int owned;
  final VoidCallback? onCraft, onUse;
  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Color(0xFFE8DFEE))),
      child: Padding(
          padding: const EdgeInsets.all(14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                  width: 58,
                  height: 64,
                  decoration: BoxDecoration(
                      color: AppColors.eventColor(
                          context, const Color(0xFFF5EFFA)),
                      borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.all(3),
                  child: Image.asset(relic.asset, fit: BoxFit.contain)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(relic.label,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 5),
                    Text(altarRelicEffect(s, relic),
                        style: const TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: Color(0xFF80708D))),
                    if (owned > 0)
                      Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text('${s.pick('Owned', 'In bezit')}: $owned',
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w700))),
                  ])),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              if (!inventoryOnly)
                Expanded(
                    child: Wrap(spacing: 10, runSpacing: 5, children: [
                  for (final material in WeaveMaterial.values
                      .where((m) => relic.cost.count(m) > 0))
                    Tooltip(
                        message: material.label,
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Image.asset(material.asset, width: 26, height: 26),
                          const SizedBox(width: 3),
                          Text('${relic.cost.count(material)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 12)),
                        ])),
                ]))
              else
                const Spacer(),
              if (!inventoryOnly)
                FilledButton(
                    key: Key('canonical-craft-${relic.name}'),
                    style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 18)),
                    onPressed: onCraft,
                    child: Text(s.pick('Craft', 'Maken'))),
              if (inventoryOnly)
                OutlinedButton(
                    key: Key('altar-use-${relic.name}'),
                    onPressed: onUse,
                    child: Text(s.pick('Use', 'Gebruiken'))),
            ]),
            if (!inventoryOnly && owned > 0)
              Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                      key: Key('altar-use-${relic.name}'),
                      onPressed: onUse,
                      child: Text(s.pick('Use relic', 'Gebruik relic')))),
          ])),
    );
  }
}

class RestoredDetailSheet extends StatelessWidget {
  const RestoredDetailSheet(
      {super.key, this.title, required this.content, required this.actions});
  final Widget? title;
  final Widget content;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) => SafeArea(
      child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .82,
          child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
              child: Column(children: [
                if (title != null)
                  DefaultTextStyle(
                      style: Theme.of(context).textTheme.headlineSmall!,
                      child: title!),
                if (title != null) const SizedBox(height: 12),
                Expanded(
                    child: SizedBox(width: double.infinity, child: content)),
                Wrap(spacing: 8, children: actions),
              ]))));
}

/// Original collection empty-state panel, sized by its scrolling parent.
class RestoredCollectionEmpty extends StatelessWidget {
  const RestoredCollectionEmpty(
      {super.key, required this.icon, required this.text});
  final GameIconKind icon;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
          child: Container(
              constraints: const BoxConstraints(maxWidth: 390),
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
              decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white, Color(0xFFF0EAFF)]),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                      color: AppColors.eventColor(context, AppColors.mist)),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x145B4B8A),
                        blurRadius: 24,
                        offset: Offset(0, 10))
                  ]),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                GameIconSprite(icon, size: 116),
                const SizedBox(height: 12),
                Text(text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 15,
                        height: 1.35,
                        fontWeight: FontWeight.w700)),
              ]))));
}

/// The original wellbeing icons, colors and meters with room for large text.
class RestoredNeedBar extends StatelessWidget {
  const RestoredNeedBar(
      {super.key,
      required this.icon,
      required this.label,
      required this.value,
      required this.color});
  final IconData icon;
  final String label;
  final int value;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(children: [
        Row(children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(width: 8),
          Expanded(
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w800))),
          Text('$value%', style: const TextStyle(fontWeight: FontWeight.w900))
        ]),
        const SizedBox(height: 5),
        LinearProgressIndicator(
            value: value / 100,
            minHeight: 8,
            color: color,
            backgroundColor: AppColors.eventColor(context, AppColors.mist),
            borderRadius: BorderRadius.circular(99)),
      ]));
}
