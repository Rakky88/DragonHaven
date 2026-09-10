import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/account_title.dart';
import '../models/profile_portrait.dart';
import '../models/supporter_pack.dart';
import '../services/canonical_game_actions.dart';
import '../services/canonical_game_session.dart';
import '../widgets/canonical_game_controls.dart';
import '../widgets/online_account_access.dart';
import '../widgets/profile_portrait_sprite.dart';
import '../widgets/shop_economy_scope.dart';

class CanonicalProfileScreen extends StatelessWidget {
  const CanonicalProfileScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const ShopEconomyBoundary(child: _ProfileContents());
}

class _ProfileContents extends StatelessWidget {
  const _ProfileContents();
  @override
  Widget build(BuildContext context) {
    final session = context.watch<CanonicalGameSession>();
    final profile = session.snapshot!.profile;
    final s = AppStrings.of(context);
    final actions = CanonicalGameActions(session);
    final titles = accountTitleById(profile.selected('title'));
    Widget choice(String kind, String? id, Widget art, String label,
        Future<void> Function() action) {
      final selected = profile.selected(kind) == id;
      return Card(
          child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                SizedBox(width: 64, height: 64, child: Center(child: art)),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                      Text(label),
                      CanonicalActionButton(
                          key: Key('canonical-profile-$kind-${id ?? 'none'}'),
                          label: s.pick(selected ? 'Selected' : 'Select',
                              selected ? 'Geselecteerd' : 'Selecteren'),
                          action: session.canAct && !selected ? action : null),
                    ]))
              ])));
    }

    return DefaultTabController(
        length: 4,
        child: Column(children: [
          Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                KeeperPortrait(
                    portraitKey: profile.selected('portrait') ?? '',
                    frameKey: profile.selected('frame'),
                    badgeKey: profile.selected('badge'),
                    displayName: '',
                    radius: 42),
                if (titles != null) ...[
                  const SizedBox(height: 12),
                  Text(titles.label(s.languageCode),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium),
                ]
              ])),
          TabBar(isScrollable: true, tabs: [
            Tab(text: s.pick('Portraits', 'Portretten')),
            Tab(text: s.pick('Titles', 'Titels')),
            Tab(text: s.pick('Badges', 'Badges')),
            Tab(text: s.pick('Frames', 'Frames')),
          ]),
          Expanded(
              child: TabBarView(children: [
            ListView(padding: const EdgeInsets.all(12), children: [
              for (final id in profile.owned('portrait'))
                if (profilePortraitById(id) case final portrait?)
                  choice(
                      'portrait',
                      id,
                      ProfilePortraitSprite(portrait: portrait, size: 56),
                      '${s.pick('Portrait', 'Portret')} ${portrait.number}',
                      () => actions.selectPortrait(id))
            ]),
            ListView(padding: const EdgeInsets.all(12), children: [
              for (final id in profile.owned('title'))
                if (accountTitleById(id) case final title?)
                  choice(
                      'title',
                      id,
                      const Icon(Icons.auto_awesome_outlined),
                      title.label(s.languageCode),
                      () => actions.selectTitle(id))
            ]),
            ListView(padding: const EdgeInsets.all(12), children: [
              choice('badge', null, const Icon(Icons.block_outlined),
                  s.pick('None', 'Geen'), () => actions.selectBadge(null)),
              for (final id in profile.owned('badge'))
                if (keeperBadgeById(id) case final badge?)
                  choice(
                      'badge',
                      id,
                      Image.asset(badge.assetPath),
                      s.pick(badge.nameEn, badge.nameNl),
                      () => actions.selectBadge(id))
            ]),
            ListView(padding: const EdgeInsets.all(12), children: [
              choice('frame', null, const Icon(Icons.block_outlined),
                  s.pick('None', 'Geen'), () => actions.selectFrame(null)),
              for (final id in profile.owned('frame'))
                if (keeperFrameById(id) case final frame?)
                  choice(
                      'frame',
                      id,
                      Image.asset(frame.assetPath),
                      s.pick(frame.nameEn, frame.nameNl),
                      () => actions.selectFrame(id))
            ]),
          ]))
        ]));
  }
}
