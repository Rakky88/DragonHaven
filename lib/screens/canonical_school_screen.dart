import '../theme/app_theme.dart';
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
        if (view.trialAttempt != null) {
          return Center(
              child: Text(strings.pick(
                  'Finish your Trial first.', 'Rond eerst je proef af.')));
        }
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
          ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(children: [
                Image.asset('assets/images/ui/dragon_school.webp',
                    height: 226, width: double.infinity, fit: BoxFit.cover),
                Positioned.fill(
                    child: DecoratedBox(
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                      Colors.transparent,
                      Color(0xF21D1436)
                    ])))),
                Positioned(
                    right: 10,
                    top: 8,
                    child: Image.asset(
                        'assets/images/ui/dragon_school/dragon_school_icon.png',
                        width: 92,
                        height: 92)),
                Positioned(
                    left: 18,
                    right: 18,
                    bottom: 16,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              strings.pick('Practice makes legends',
                                  'Oefening baart legenden'),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900)),
                          const SizedBox(height: 6),
                          Text(
                              strings.pick('3 attempts per lesson',
                                  '3 pogingen per les'),
                              style: const TextStyle(color: Colors.white)),
                        ])),
              ])),
          const SizedBox(height: 14),
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
          for (final (index, definition) in dragonSchoolGames.indexed)
            _SchoolLessonCard(
                number: index + 1,
                definition: definition,
                keeperRecord: (view.data['progress']['dragonSchoolRecords']
                        [definition.id] as int?) ??
                    0,
                onTap: session.canAct
                    ? () => _enroll(context, session, definition)
                    : null),
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
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                      child: Row(children: [
                        Image.asset(definition.iconAsset,
                            width: 58, height: 58),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(
                                  strings.pick(
                                      definition.titleEn, definition.titleNl),
                                  style:
                                      Theme.of(context).textTheme.titleLarge),
                              Text(
                                  strings.pick(
                                      'Choose pupils', 'Kies leerlingen'),
                                  style:
                                      const TextStyle(color: AppColors.muted)),
                            ])),
                      ])),
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

class _SchoolLessonCard extends StatelessWidget {
  const _SchoolLessonCard({
    required this.number,
    required this.definition,
    required this.keeperRecord,
    required this.onTap,
  });

  final int number;
  final DragonSchoolGameDefinition definition;
  final int keeperRecord;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = _schoolColors(definition.kind);
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: InkWell(
        key: Key('canonical-school-${definition.id}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Container(
                width: 59,
                height: 59,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Image.asset(definition.iconAsset),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$number. ${strings.pick(definition.titleEn, definition.titleNl)}',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                        if (definition.isTeamLesson)
                          Icon(Icons.groups_rounded,
                              size: 17,
                              color: AppColors.eventColor(
                                  context, AppColors.twilight)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      strings.pick(
                          definition.descriptionEn, definition.descriptionNl),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _lessonFocusLabel(strings, definition),
                      style: TextStyle(
                        color: colors.last,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              Column(
                children: [
                  Text('$keeperRecord',
                      style: TextStyle(
                          color:
                              AppColors.eventColor(context, AppColors.twilight),
                          fontWeight: FontWeight.w900,
                          fontSize: 17)),
                  Text(strings.pick('KEEPER BEST', 'KEEPER BESTE'),
                      style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 7,
                          fontWeight: FontWeight.w900)),
                ],
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

String _lessonFocusLabel(
  AppStrings strings,
  DragonSchoolGameDefinition definition,
) {
  final team = definition.isTeamLesson
      ? strings.pick(' · TEAMWORK', ' · SAMENWERKING')
      : '';
  return '${_focusName(strings, definition.focus).toUpperCase()}$team · '
      '${definition.minimumDragons == definition.maximumDragons ? definition.minimumDragons : '1–${definition.maximumDragons}'} '
      '${strings.pick(definition.maximumDragons == 1 ? 'DRAGON' : 'DRAGONS', definition.maximumDragons == 1 ? 'DRAAK' : 'DRAKEN')}';
}

String _focusName(AppStrings strings, TrainingFocus? focus) => switch (focus) {
      TrainingFocus.might => strings.pick('Might', 'Kracht'),
      TrainingFocus.arcana => strings.pick('Arcana', 'Arcana'),
      TrainingFocus.spirit => strings.pick('Spirit', 'Geest'),
      null => strings.pick('lowest expertise', 'laagste expertise'),
    };

List<Color> _schoolColors(DragonSchoolGameKind kind) =>
    switch (kind.index % 5) {
      0 => const [Color(0xFF5B3D91), Color(0xFF9A66C7)],
      1 => const [Color(0xFF246C8C), Color(0xFF55A9BB)],
      2 => const [Color(0xFF9B3C38), Color(0xFFE17743)],
      3 => const [Color(0xFF4D598E), Color(0xFF7F78C5)],
      _ => const [Color(0xFF47765A), Color(0xFF75A966)],
    };
