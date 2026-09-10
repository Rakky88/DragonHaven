import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/dragon_school.dart';
import '../models/pet.dart';
import '../services/canonical_game_actions.dart';
import '../services/canonical_game_session.dart';
import '../services/canonical_school_run_source.dart';
import '../widgets/canonical_game_controls.dart';
import '../widgets/dragon_art.dart';
import '../widgets/shop_economy_scope.dart';
import 'dragon_school_screen.dart';

class CanonicalSchoolScreen extends StatelessWidget {
  const CanonicalSchoolScreen({super.key});
  @override
  Widget build(BuildContext context) => ShopEconomyBoundary(
          child: Consumer<CanonicalGameSession>(builder: (context, session, _) {
        final view = session.snapshot!;
        final strings = AppStrings.of(context);
        final attempt = view.schoolAttempt;
        if (attempt != null) {
          final actions = CanonicalGameActions(session);
          return Center(
              child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                          strings.pick(
                              'An unfinished lesson is still reserved.',
                              'Er staat nog een onafgemaakte les open.'),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      CanonicalActionButton(
                          key: const Key('canonical-school-abandon'),
                          label: strings.pick('End lesson', 'Les beëindigen'),
                          confirmation: strings.pick('This attempt will count.',
                              'Deze poging telt mee.'),
                          action: () async {
                            await actions.execute(
                                'cancel_school', {'attemptId': attempt.id});
                          }),
                    ],
                  )));
        }
        if (view.house.floorRoomIds.length < 5) {
          return Center(
              child: Text(strings.pick('Dragon Academy unlocks at five floors.',
                  'De Drakenacademie opent bij vijf verdiepingen.')));
        }
        return ListView(padding: const EdgeInsets.all(16), children: [
          for (final dragon in view.dragons
              .where((d) => d.owned && !d.schoolComplete && d.schoolPassing))
            ListTile(
                title: Text(dragon.name),
                subtitle: Text('${dragon.schoolStarTotal}/30'),
                trailing: CanonicalActionButton(
                    label: strings.pick('Graduate', 'Afstuderen'),
                    confirmation: strings.pick(
                        'Finish Dragon Academy for this dragon?',
                        'De Drakenacademie voor deze draak afronden?'),
                    action: () async {
                      await CanonicalGameActions(session)
                          .execute('graduate_school', {'dragonId': dragon.id});
                    })),
          for (final definition in dragonSchoolGames)
            Card(
                child: ListTile(
              leading: Image.asset(definition.iconAsset, width: 42, height: 42),
              title: Text(strings.pick(definition.titleEn, definition.titleNl)),
              subtitle: Text(strings.pick(
                  definition.descriptionEn, definition.descriptionNl)),
              trailing: const Icon(Icons.chevron_right),
              key: ValueKey('canonical-school-${definition.id}'),
              onTap: session.canAct
                  ? () => _enroll(context, session, definition)
                  : null,
            )),
        ]);
      }));

  Future<void> _enroll(BuildContext context, CanonicalGameSession session,
      DragonSchoolGameDefinition definition) async {
    final epoch = session.connection.sessionEpoch,
        owner = session.connection.currentOwner;
    final available = session.snapshot!.dragons
        .where((d) =>
            d.owned &&
            d.adventureId == null &&
            !d.schoolComplete &&
            (d.schoolAttempts[definition.id] ?? 0) < 3)
        .toList();
    final selected = <String>[];
    String? mentorId;
    final strings = AppStrings.of(context);
    final confirmed = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => StatefulBuilder(builder: (context, setState) {
              final current = context.watch<CanonicalGameSession>();
              final sameAccount = current.connection.sessionEpoch == epoch &&
                  current.connection.currentOwner == owner;
              if (!sameAccount) return const SizedBox(height: 1);
              final mentors = current.snapshot!.dragons
                  .where((d) =>
                      d.owned &&
                      d.adventureId == null &&
                      d.stage == DragonStage.ascended &&
                      !selected.contains(d.id))
                  .toList();
              final young = available.any((d) =>
                  selected.contains(d.id) &&
                  (d.stage == DragonStage.hatchling ||
                      d.stage == DragonStage.wyrmling));
              return SafeArea(
                  child: SizedBox(
                height: MediaQuery.sizeOf(context).height * .75,
                child: Column(children: [
                  Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                          strings.pick('Choose pupils', 'Kies leerlingen'),
                          style: Theme.of(context).textTheme.titleLarge)),
                  Expanded(
                      child: ListView(children: [
                    for (final dragon in available)
                      CheckboxListTile(
                        key: ValueKey('canonical-pupil-${dragon.id}'),
                        value: selected.contains(dragon.id),
                        title: Text(dragon.name),
                        subtitle: Text(
                            '${dragon.schoolAttempts[definition.id] ?? 0}/3 · ${dragon.schoolStars[definition.id] ?? 0} ★'),
                        secondary: SizedBox(
                            width: 48,
                            child: DragonArt(
                                height: 48,
                                stageKey:
                                    canonicalSchoolStudent(dragon).stageKey,
                                lineageId: dragon.lineageId,
                                evolutionPath: dragon.path,
                                prismatic: dragon.spectral,
                                sinister: dragon.sinister,
                                animate: false)),
                        onChanged: (enabled) => setState(() {
                          if (enabled == false) {
                            selected.remove(dragon.id);
                          } else if (definition.maximumDragons == 1) {
                            selected
                              ..clear()
                              ..add(dragon.id);
                          } else if (selected.length <
                              definition.maximumDragons) {
                            selected.add(dragon.id);
                          }
                          if (selected.contains(mentorId)) mentorId = null;
                        }),
                      ),
                    if (young && mentors.isNotEmpty) ...[
                      Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(strings.pick(
                              'Mentor (optional)', 'Mentor (optioneel)'))),
                      for (final mentor in mentors)
                        CheckboxListTile(
                            title: Text(mentor.name),
                            value: mentorId == mentor.id,
                            onChanged: (value) => setState(() =>
                                mentorId = value == true ? mentor.id : null)),
                    ],
                  ])),
                  Padding(
                      padding: const EdgeInsets.all(12),
                      child: FilledButton(
                        key: const Key('canonical-school-enroll'),
                        onPressed: current.canAct &&
                                selected.length >= definition.minimumDragons &&
                                selected.length <= definition.maximumDragons
                            ? () {
                                if (!young) mentorId = null;
                                Navigator.pop(context, true);
                              }
                            : null,
                        child: Text(strings.pick('Continue', 'Doorgaan')),
                      )),
                ]),
              ));
            }));
    if (confirmed != true ||
        !context.mounted ||
        session.connection.sessionEpoch != epoch ||
        session.connection.currentOwner != owner) {
      return;
    }
    final source =
        CanonicalSchoolRunSource(session, definition, selected, mentorId);
    try {
      await Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => DragonSchoolGameScreen(
                definition: definition,
                dragonIds: selected,
                mentorDragonId: mentorId,
                source: source,
              )));
    } finally {
      source.dispose();
    }
  }
}
