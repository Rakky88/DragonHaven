import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/dragon_art.dart';

const _forms = <({String label, String stageKey, String path})>[
  (label: 'Hatchling', stageKey: 'spark', path: 'might'),
  (label: 'Wyrmling', stageKey: 'nestDragon', path: 'might'),
  (label: 'Might Ascension', stageKey: 'homeGuardian', path: 'might'),
  (label: 'Arcana Ascension', stageKey: 'homeGuardian', path: 'arcana'),
  (label: 'Spirit Ascension', stageKey: 'homeGuardian', path: 'spirit'),
  (label: 'Mastery Ascension', stageKey: 'homeGuardian', path: 'mastery'),
];

class SpecialEventAuditApp extends StatelessWidget {
  const SpecialEventAuditApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Special Event Asset Review',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const SpecialEventAuditScreen(),
      );
}

class SpecialEventAuditScreen extends StatelessWidget {
  const SpecialEventAuditScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Special Event asset review'),
              Text(
                'Cluckatrice · chest · achievement',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
        ),
        body: ListView(
          key: const Key('special-event-audit-scroll'),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 32),
          children: [
            const _ReviewHeader(),
            const SizedBox(height: 14),
            Text('Complete dragon family',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: .78,
              ),
              itemCount: _forms.length,
              itemBuilder: (_, index) => _DragonReviewCard(
                form: _forms[index],
              ),
            ),
            const SizedBox(height: 22),
            Text('Special Chest',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Row(
              children: [
                Expanded(
                  child: _AssetReviewCard(
                    label: 'Closed',
                    asset: 'assets/images/chests/chest_special.webp',
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _AssetReviewCard(
                    label: 'Opened',
                    asset: 'assets/images/chests/open/chest_special_open.webp',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text('Achievement', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const _AssetReviewCard(
              label: 'Winner, winner, chicken dinner',
              asset: 'assets/images/achievements/winner_chicken_dinner.webp',
              compact: true,
            ),
          ],
        ),
      );
}

class _ReviewHeader extends StatelessWidget {
  const _ReviewHeader();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF25164D), Color(0xFF7253A8)],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Row(
          children: [
            Icon(Icons.fact_check_rounded, color: Color(0xFFFFD86E), size: 42),
            SizedBox(width: 13),
            Expanded(
              child: Text(
                'Inspect every edge, transparent background and full-body fit. '
                'Nothing should be cut off or surrounded by a checkerboard.',
                style: TextStyle(
                  color: Colors.white,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
}

class _DragonReviewCard extends StatelessWidget {
  const _DragonReviewCard({required this.form});

  final ({String label, String stageKey, String path}) form;

  @override
  Widget build(BuildContext context) => _ReviewSurface(
        label: form.label,
        child: DragonArt(
          key: Key('special-event-dragon-${form.path}-${form.stageKey}'),
          height: 185,
          animate: false,
          stageKey: form.stageKey,
          lineageId: 'cluckatrice',
          evolutionPath: form.path,
          fit: BoxFit.contain,
        ),
      );
}

class _AssetReviewCard extends StatelessWidget {
  const _AssetReviewCard({
    required this.label,
    required this.asset,
    this.compact = false,
  });

  final String label;
  final String asset;
  final bool compact;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: compact ? 190 : 220,
        child: _ReviewSurface(
          label: label,
          child: Image.asset(
            asset,
            key: Key('special-event-asset-$asset'),
            fit: BoxFit.contain,
          ),
        ),
      );
}

class _ReviewSurface extends StatelessWidget {
  const _ReviewSurface({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD4C8EA)),
        ),
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  // A saturated review color makes true alpha immediately
                  // visible and exposes baked white, black or checkerboards.
                  color: const Color(0xFF1976D2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFC8B9E2)),
                ),
                padding: const EdgeInsets.all(5),
                child: child,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      );
}
