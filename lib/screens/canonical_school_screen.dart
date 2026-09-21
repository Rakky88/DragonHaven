import '../theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/dragon_school.dart';
import '../models/pet.dart';
import '../services/canonical_game_actions.dart';
import '../services/canonical_game_session.dart';
import '../services/canonical_game_snapshot.dart';
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
          _SchoolHero(game: session),
          const SizedBox(height: 14),
          _AcademyStandings(game: session),
          const SizedBox(height: 14),
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
        .where((d) => d.owned && d.adventureId == null)
        .toList()
      ..sort((a, b) {
        if (a.favorite != b.favorite) return a.favorite ? -1 : 1;
        return a.name.compareTo(b.name);
      });
    final eligible = available.where((d) =>
        !d.schoolComplete &&
        (d.schoolAttempts[definition.id] ?? 0) < dragonSchoolAttemptsPerLesson);
    if (eligible.length < definition.minimumDragons) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppStrings.of(context).pick(
              'Not enough eligible dragons. Each pupil gets three attempts per lesson.',
              'Niet genoeg geschikte draken. Iedere leerling krijgt drie pogingen per les.'))));
      return;
    }
    final selected =
        eligible.take(definition.minimumDragons).map((d) => d.id).toList();
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
                height: MediaQuery.sizeOf(context).height * .88,
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
                                      'Choose ${definition.minimumDragons == definition.maximumDragons ? definition.minimumDragons : '1 to ${definition.maximumDragons}'} dragons',
                                      'Kies ${definition.minimumDragons == definition.maximumDragons ? definition.minimumDragons : '1 tot ${definition.maximumDragons}'} draken'),
                                  style:
                                      const TextStyle(color: AppColors.muted)),
                            ])),
                      ])),
                  Expanded(
                      child: ListView(children: [
                    for (final dragon in available)
                      _EnrollmentDragonTile(
                        dragon: dragon,
                        definition: definition,
                        selected: selected.contains(dragon.id),
                        onTap: dragon.schoolComplete ||
                                (dragon.schoolAttempts[definition.id] ?? 0) >=
                                    dragonSchoolAttemptsPerLesson
                            ? null
                            : () => setState(() {
                                  if (selected.contains(dragon.id)) {
                                    if (selected.length >
                                        definition.minimumDragons) {
                                      selected.remove(dragon.id);
                                    }
                                  } else if (definition.maximumDragons == 1) {
                                    selected
                                      ..clear()
                                      ..add(dragon.id);
                                  } else if (selected.length <
                                      definition.maximumDragons) {
                                    selected.add(dragon.id);
                                  }
                                  if (selected.contains(mentorId)) {
                                    mentorId = null;
                                  }
                                }),
                      ),
                    if (young && mentors.isNotEmpty) ...[
                      const SizedBox(height: 9),
                      Text(
                          strings.pick('Optional ascended mentor',
                              'Optionele Ascended-mentor'),
                          style: TextStyle(
                              color: AppColors.eventColor(
                                  context, AppColors.twilight),
                              fontWeight: FontWeight.w900)),
                      Text(
                          strings.pick(
                              'A mentor absorbs one mistake. The pupils receive all stars and rewards.',
                              'Een mentor vangt \u00e9\u00e9n fout op. De leerlingen ontvangen alle sterren en beloningen.'),
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 11)),
                      RadioGroup<String?>(
                          groupValue: mentorId,
                          onChanged: (value) =>
                              setState(() => mentorId = value),
                          child: Column(children: [
                            RadioListTile<String?>(
                                value: null,
                                title: Text(
                                    strings.pick('No mentor', 'Geen mentor'))),
                            for (final mentor in mentors)
                              RadioListTile<String?>(
                                  key: Key('school-mentor-${mentor.id}'),
                                  value: mentor.id,
                                  title: Text(mentor.name)),
                          ])),
                    ],
                  ])),
                  Padding(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            key: const Key('canonical-school-enroll'),
                            onPressed: current.canAct &&
                                    selected.length >=
                                        definition.minimumDragons &&
                                    selected.length <= definition.maximumDragons
                                ? () {
                                    if (!young) mentorId = null;
                                    Navigator.pop(context, true);
                                  }
                                : null,
                            icon: const Icon(Icons.school_rounded),
                            label: Text(
                                strings.pick('Enter classroom', 'Naar de les')),
                          ))),
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

class _SchoolHero extends StatelessWidget {
  const _SchoolHero({required this.game});

  final CanonicalGameSession game;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final completed = game.snapshot!.dragons
        .where((dragon) => dragon.owned)
        .where((dragon) => dragon.schoolComplete)
        .length;
    return Container(
      height: 226,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.gold),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332A1E50),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/ui/dragon_school.webp',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF302454), Color(0xFF7961A8)],
                ),
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xF21D1436)],
              ),
            ),
          ),
          Positioned(
            right: 10,
            top: 8,
            child: Image.asset(
              'assets/images/ui/dragon_school/dragon_school_icon.png',
              width: 92,
              height: 92,
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 15,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.pick(
                      'Practice makes legends', 'Oefening baart legenden'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    shadows: [Shadow(blurRadius: 8)],
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  strings.pick(
                    'Every pupil gets up to three official attempts per lesson. Once every lesson is passed at least once, a pupil with 15 stars may graduate early.',
                    'Iedere leerling krijgt maximaal drie officiële pogingen per les. Zodra elk vak minimaal één keer is gedaan, mag een leerling met 15 sterren vervroegd afstuderen.',
                  ),
                  style:
                      const TextStyle(color: Color(0xFFE9DFF9), fontSize: 11.5),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _HeroPill(
                      icon: Icons.star_rounded,
                      label: strings.pick(
                          '3 attempts per lesson', '3 pogingen per les'),
                    ),
                    _HeroPill(
                      icon: Icons.school_rounded,
                      label: strings.pick('$completed final reports',
                          '$completed eindrapporten'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AcademyStandings extends StatelessWidget {
  const _AcademyStandings({required this.game});

  final CanonicalGameSession game;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final dragons = game.snapshot!.dragons
        .where((dragon) => dragon.owned)
        .where((dragon) =>
            dragon.schoolAttempts.values.fold<int>(0, (a, b) => a + b) > 0)
        .toList(growable: false)
      ..sort((a, b) {
        final score = _academyScore(b).compareTo(_academyScore(a));
        if (score != 0) return score;
        final stars = b.schoolStarTotal.compareTo(a.schoolStarTotal);
        if (stars != 0) return stars;
        return a.displayName.compareTo(b.displayName);
      });
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        key: const Key('dragon-school-standings'),
        initiallyExpanded: dragons.isNotEmpty,
        leading: Icon(Icons.leaderboard_rounded,
            color: AppColors.eventColor(context, AppColors.twilight)),
        title: Text(
          strings.pick('Academy standings', 'Academieranglijst'),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          strings.pick(
            'Best results, fairly normalized across all lessons',
            'Beste resultaten, eerlijk genormaliseerd over alle lessen',
          ),
          style: const TextStyle(fontSize: 10.5),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        children: dragons.isEmpty
            ? [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    strings.pick(
                      'Complete a first lesson to enter the standings.',
                      'Rond een eerste les af om in de ranglijst te komen.',
                    ),
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ),
              ]
            : [
                for (var index = 0; index < dragons.length; index++)
                  _AcademyStandingRow(
                    rank: index + 1,
                    dragon: dragons[index],
                    onGraduate: () => _confirmEarlyGraduation(
                      context,
                      game,
                      dragons[index],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Column(
                    children: [
                      Text(
                        strings.pick(
                          '15 stars: Graduate · 21: Honors · 27: High Honors · 30: Valedictorian. Early graduation requires one attempt in every lesson. Dropout is decided only after all 30 attempts.',
                          '15 sterren: Afgestudeerd · 21: Onderscheiding · 27: Grote onderscheiding · 30: Lichtingsbeste. Vervroegd afstuderen vereist één poging in elk vak. Uitval wordt pas na alle 30 pogingen bepaald.',
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color:
                              AppColors.eventColor(context, AppColors.twilight),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        strings.pick(
                          'Gold is 100 Academy points per lesson; exceptional scores can earn up to 20 bonus points.',
                          'Goud is 100 academiepunten per les; uitzonderlijke scores kunnen tot 20 bonuspunten opleveren.',
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 9.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
      ),
    );
  }
}

class _AcademyStandingRow extends StatelessWidget {
  const _AcademyStandingRow({
    required this.rank,
    required this.dragon,
    required this.onGraduate,
  });

  final int rank;
  final CanonicalDragonView dragon;
  final VoidCallback onGraduate;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final outcome = dragon.schoolOutcome;
    final color = _schoolOutcomeColor(outcome);
    return Container(
      key: Key('school-standing-${dragon.id}'),
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: rank == 1
            ? const Color(0xFFFFF8DC)
            : AppColors.eventColor(context, const Color(0xFFF7F3FA)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: .28)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '#$rank',
              style: TextStyle(
                color: rank <= 3 ? const Color(0xFF9A6A00) : AppColors.muted,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          SizedBox.square(
            dimension: 42,
            child: DragonArt(
                stageKey: dragon.stageKey,
                lineageId: dragon.lineageId,
                evolutionPath: dragon.path,
                prismatic: dragon.spectral,
                sinister: dragon.sinister,
                height: 42,
                animate: false),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dragon.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                Text(
                  '${strings.pick(outcome.titleEn, outcome.titleNl)} · '
                  '${dragon.schoolAttempts.values.fold<int>(0, (a, b) => a + b)}/$dragonSchoolMaximumAttempts ${strings.pick('attempts', 'pogingen')}',
                  style: TextStyle(
                    color: color,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_academyScore(dragon)}/$dragonSchoolMaximumAcademyScore',
                style: TextStyle(
                  color: AppColors.eventColor(context, AppColors.twilight),
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '${dragon.schoolStarTotal}/30 ★',
                style: const TextStyle(color: AppColors.muted, fontSize: 9.5),
              ),
              if (!dragon.schoolComplete && dragon.schoolPassing)
                TextButton(
                  key: Key('graduate-academy-${dragon.id}'),
                  onPressed: context.watch<CanonicalGameSession>().canAct
                      ? onGraduate
                      : null,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 28),
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(
                    strings.pick('Graduate now', 'Nu afstuderen'),
                    style: const TextStyle(fontSize: 9.5),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> _confirmEarlyGraduation(
  BuildContext context,
  CanonicalGameSession game,
  CanonicalDragonView dragon,
) async {
  final strings = AppStrings.of(context);
  final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(strings.pick(
            'Graduate ${dragon.displayName}?',
            '${dragon.displayName} laten afstuderen?',
          )),
          content: Text(strings.pick(
            'The current report becomes final. Unused lesson attempts cannot be played afterwards.',
            'Het huidige rapport wordt definitief. Ongebruikte pogingen kunnen daarna niet meer worden gespeeld.',
          )),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(strings.pick('Keep training', 'Verder trainen')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(strings.pick('Graduate', 'Afstuderen')),
            ),
          ],
        ),
      ) ??
      false;
  if (!confirmed || !context.mounted) return;
  await runShopAction(context, () async {
    await CanonicalGameActions(game)
        .execute('graduate_school', {'dragonId': dragon.id});
  });
  if (!context.mounted ||
      game.snapshot?.dragon(dragon.id)?.schoolComplete != true) {
    return;
  }
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(strings.pick(
      '${dragon.displayName} has graduated from Dragon Academy.',
      '${dragon.displayName} is afgestudeerd aan de Drakenacademie.',
    )),
  ));
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .13),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.gold, size: 14),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800)),
          ],
        ),
      );
}

Color _schoolOutcomeColor(DragonSchoolOutcome outcome) => switch (outcome) {
      DragonSchoolOutcome.inTraining => AppColors.twilight,
      DragonSchoolOutcome.dropout => const Color(0xFFB25434),
      DragonSchoolOutcome.graduate => const Color(0xFF47765A),
      DragonSchoolOutcome.honorsGraduate => const Color(0xFF246C8C),
      DragonSchoolOutcome.highHonors => const Color(0xFF6D4BA0),
      DragonSchoolOutcome.valedictorian => const Color(0xFF9A6A00),
    };

int _academyScore(CanonicalDragonView dragon) {
  var total = 0.0;
  for (final lesson in dragonSchoolGames) {
    total += ((dragon.schoolRecords[lesson.id] ?? 0) / lesson.goldScore)
            .clamp(0.0, 1.2) *
        100;
  }
  return total.round().clamp(0, dragonSchoolMaximumAcademyScore);
}

class _EnrollmentDragonTile extends StatelessWidget {
  const _EnrollmentDragonTile({
    required this.dragon,
    required this.definition,
    required this.selected,
    required this.onTap,
  });

  final CanonicalDragonView dragon;
  final DragonSchoolGameDefinition definition;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final stars = (dragon.schoolStars[definition.id] ?? 0);
    final attempts = (dragon.schoolAttempts[definition.id] ?? 0);
    final exhausted = attempts >= dragonSchoolAttemptsPerLesson;
    return Card(
      margin: const EdgeInsets.only(bottom: 7),
      color: exhausted
          ? const Color(0xFFF0EDF2)
          : selected
              ? AppColors.eventColor(context, const Color(0xFFF0E8FA))
              : Colors.white,
      child: ListTile(
        key: Key('school-pupil-${dragon.id}'),
        onTap: onTap,
        leading: SizedBox.square(
          dimension: 54,
          child: DragonArt(
              stageKey: dragon.stageKey,
              lineageId: dragon.lineageId,
              evolutionPath: dragon.path,
              prismatic: dragon.spectral,
              sinister: dragon.sinister,
              height: 52,
              animate: false),
        ),
        title: Text(dragon.displayName,
            style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(
          '${strings.petStageNameByKey(dragon.stageKey)} · ${strings.pick('Best', 'Beste')} ${(dragon.schoolRecords[definition.id] ?? 0)} · '
          '$attempts/$dragonSchoolAttemptsPerLesson ${strings.pick('attempts', 'pogingen')}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              for (var star = 0; star < 3; star++)
                Icon(
                    star < stars
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 17,
                    color: AppColors.gold)
            ]),
            const SizedBox(width: 5),
            Icon(
              exhausted
                  ? Icons.lock_rounded
                  : selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
              color: exhausted ? AppColors.muted : null,
            ),
          ],
        ),
      ),
    );
  }
}
