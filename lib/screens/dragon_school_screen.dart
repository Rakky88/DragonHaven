import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/dragon_school.dart';
import '../models/pet.dart';
import '../providers/household_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/dragon_art.dart';

const _schoolIconRoot = 'assets/images/ui/dragon_school';
const _sigilAssets = <String>[
  '$_schoolIconRoot/piece_sigil_flame.png',
  '$_schoolIconRoot/piece_sigil_wave.png',
  '$_schoolIconRoot/piece_sigil_leaf.png',
  '$_schoolIconRoot/piece_sigil_moon.png',
  '$_schoolIconRoot/piece_sigil_lightning.png',
  '$_schoolIconRoot/piece_sigil_wind.png',
];

class DragonSchoolScreen extends StatelessWidget {
  const DragonSchoolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final game = context.watch<HouseholdProvider>();
    return Scaffold(
      appBar:
          AppBar(title: Text(strings.pick('Dragon Academy', 'Drakenacademie'))),
      body: ListView(
        key: const Key('dragon-school-games'),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
        children: [
          _SchoolHero(game: game),
          const SizedBox(height: 14),
          _AcademyStandings(game: game),
          const SizedBox(height: 14),
          for (var index = 0; index < dragonSchoolGames.length; index++) ...[
            _SchoolLessonCard(
              number: index + 1,
              definition: dragonSchoolGames[index],
              keeperRecord:
                  game.dragonSchoolRecords[dragonSchoolGames[index].id] ?? 0,
              onTap: () => _enroll(context, dragonSchoolGames[index]),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Future<void> _enroll(
    BuildContext context,
    DragonSchoolGameDefinition definition,
  ) async {
    final strings = AppStrings.of(context);
    final game = context.read<HouseholdProvider>();
    final present = game.ownedDragons
        .where((dragon) => !dragon.isEgg && dragon.activeAdventureId == null)
        .toList(growable: false)
      ..sort((a, b) {
        if (a.favorite != b.favorite) return a.favorite ? -1 : 1;
        return a.displayName.compareTo(b.displayName);
      });
    final eligible = present.where(
      (dragon) =>
          !dragon.dragonSchoolComplete &&
          dragon.schoolAttempts(definition.id) < dragonSchoolAttemptsPerLesson,
    );
    if (eligible.length < definition.minimumDragons) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(strings.pick(
          'Not enough eligible dragons. Each pupil gets three attempts per lesson.',
          'Niet genoeg geschikte draken. Iedere leerling krijgt drie pogingen per les.',
        )),
      ));
      return;
    }
    final enrollment = await showModalBottomSheet<_SchoolEnrollment>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _EnrollmentSheet(
        definition: definition,
        availableDragons: present,
      ),
    );
    if (enrollment == null || !context.mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => DragonSchoolGameScreen(
        definition: definition,
        dragonIds: enrollment.dragonIds,
        mentorDragonId: enrollment.mentorDragonId,
      ),
    ));
  }
}

class _SchoolHero extends StatelessWidget {
  const _SchoolHero({required this.game});

  final HouseholdProvider game;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final completed =
        game.ownedDragons.where((dragon) => dragon.dragonSchoolComplete).length;
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
            'assets/images/ui/dragon_school.png',
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
              '$_schoolIconRoot/dragon_school_icon.png',
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
                Row(
                  children: [
                    _HeroPill(
                      icon: Icons.star_rounded,
                      label: strings.pick(
                          '3 attempts per lesson', '3 pogingen per les'),
                    ),
                    const SizedBox(width: 6),
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

  final HouseholdProvider game;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final dragons = game.ownedDragons
        .where((dragon) => !dragon.isEgg && dragon.dragonSchoolAttemptTotal > 0)
        .toList(growable: false)
      ..sort((a, b) {
        final score =
            dragonSchoolAcademyScore(b).compareTo(dragonSchoolAcademyScore(a));
        if (score != 0) return score;
        final stars =
            b.dragonSchoolStarTotal.compareTo(a.dragonSchoolStarTotal);
        if (stars != 0) return stars;
        return a.displayName.compareTo(b.displayName);
      });
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        key: const Key('dragon-school-standings'),
        initiallyExpanded: dragons.isNotEmpty,
        leading:
            const Icon(Icons.leaderboard_rounded, color: AppColors.twilight),
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
                        style: const TextStyle(
                          color: AppColors.twilight,
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
  final Pet dragon;
  final VoidCallback onGraduate;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final outcome = dragon.dragonSchoolOutcome;
    final color = _schoolOutcomeColor(outcome);
    return Container(
      key: Key('school-standing-${dragon.id}'),
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: rank == 1 ? const Color(0xFFFFF8DC) : const Color(0xFFF7F3FA),
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
            child: _DragonImage(dragon: dragon, height: 42, animate: false),
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
                  '${dragon.dragonSchoolAttemptTotal}/$dragonSchoolMaximumAttempts ${strings.pick('attempts', 'pogingen')}',
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
                '${dragonSchoolAcademyScore(dragon)}/$dragonSchoolMaximumAcademyScore',
                style: const TextStyle(
                  color: AppColors.twilight,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '${dragon.dragonSchoolStarTotal}/30 ★',
                style: const TextStyle(color: AppColors.muted, fontSize: 9.5),
              ),
              if (dragon.canGraduateDragonSchoolEarly)
                TextButton(
                  key: Key('graduate-academy-${dragon.id}'),
                  onPressed: onGraduate,
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
  HouseholdProvider game,
  Pet dragon,
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
  final graduated = await game.graduateDragonFromAcademy(dragon.id);
  if (!context.mounted || !graduated) return;
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
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = _schoolColors(definition.kind);
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: InkWell(
        key: Key('dragon-school-game-${definition.id}'),
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
                          const Icon(Icons.groups_rounded,
                              size: 17, color: AppColors.twilight),
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
                      style: const TextStyle(
                          color: AppColors.twilight,
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

class _SchoolEnrollment {
  const _SchoolEnrollment(this.dragonIds, this.mentorDragonId);

  final List<String> dragonIds;
  final String? mentorDragonId;
}

class _EnrollmentSheet extends StatefulWidget {
  const _EnrollmentSheet({
    required this.definition,
    required this.availableDragons,
  });

  final DragonSchoolGameDefinition definition;
  final List<Pet> availableDragons;

  @override
  State<_EnrollmentSheet> createState() => _EnrollmentSheetState();
}

class _EnrollmentSheetState extends State<_EnrollmentSheet> {
  final _selectedIds = <String>{};
  String? _mentorId;

  @override
  void initState() {
    super.initState();
    _selectedIds.addAll(widget.availableDragons
        .where((dragon) =>
            !dragon.dragonSchoolComplete &&
            dragon.schoolAttempts(widget.definition.id) <
                dragonSchoolAttemptsPerLesson)
        .take(widget.definition.minimumDragons)
        .map((dragon) => dragon.id));
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final selectedDragons = widget.availableDragons
        .where((dragon) => _selectedIds.contains(dragon.id))
        .toList(growable: false);
    final hasYoungPupil = selectedDragons.any((dragon) =>
        dragon.stage == DragonStage.hatchling ||
        dragon.stage == DragonStage.wyrmling);
    final mentors = widget.availableDragons
        .where((dragon) =>
            dragon.stage == DragonStage.ascended &&
            !_selectedIds.contains(dragon.id))
        .toList(growable: false);
    if (!hasYoungPupil || !mentors.any((dragon) => dragon.id == _mentorId)) {
      _mentorId = null;
    }
    final canStart = _selectedIds.length >= widget.definition.minimumDragons &&
        _selectedIds.length <= widget.definition.maximumDragons &&
        selectedDragons.every((dragon) =>
            !dragon.dragonSchoolComplete &&
            dragon.schoolAttempts(widget.definition.id) <
                dragonSchoolAttemptsPerLesson);

    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: .88,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
              child: Row(
                children: [
                  Image.asset(widget.definition.iconAsset,
                      width: 58, height: 58),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.pick(widget.definition.titleEn,
                              widget.definition.titleNl),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          widget.definition.minimumDragons ==
                                  widget.definition.maximumDragons
                              ? strings.pick(
                                  'Choose ${widget.definition.minimumDragons} ${widget.definition.minimumDragons == 1 ? 'dragon' : 'dragons'}',
                                  'Kies ${widget.definition.minimumDragons} ${widget.definition.minimumDragons == 1 ? 'draak' : 'draken'}',
                                )
                              : strings.pick(
                                  'Choose 1 to ${widget.definition.maximumDragons} dragons',
                                  'Kies 1 tot ${widget.definition.maximumDragons} draken',
                                ),
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                key: const Key('school-dragon-picker'),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                children: [
                  for (final dragon in widget.availableDragons)
                    _EnrollmentDragonTile(
                      dragon: dragon,
                      definition: widget.definition,
                      selected: _selectedIds.contains(dragon.id),
                      onTap: dragon.dragonSchoolComplete ||
                              dragon.schoolAttempts(widget.definition.id) >=
                                  dragonSchoolAttemptsPerLesson
                          ? null
                          : () => _toggleDragon(dragon.id),
                    ),
                  if (hasYoungPupil && mentors.isNotEmpty) ...[
                    const SizedBox(height: 9),
                    Text(
                      strings.pick('Optional ascended mentor',
                          'Optionele Ascended-mentor'),
                      style: const TextStyle(
                          color: AppColors.twilight,
                          fontWeight: FontWeight.w900),
                    ),
                    Text(
                      strings.pick(
                        'A mentor absorbs one mistake. The pupils receive all stars and rewards.',
                        'Een mentor vangt één fout op. De leerlingen ontvangen alle sterren en beloningen.',
                      ),
                      style:
                          const TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                    RadioGroup<String?>(
                      groupValue: _mentorId,
                      onChanged: (value) => setState(() => _mentorId = value),
                      child: Column(
                        children: [
                          RadioListTile<String?>(
                            value: null,
                            title:
                                Text(strings.pick('No mentor', 'Geen mentor')),
                          ),
                          for (final mentor in mentors)
                            RadioListTile<String?>(
                              key: Key('school-mentor-${mentor.id}'),
                              value: mentor.id,
                              title: Text(mentor.displayName),
                              subtitle: Text(strings.pick(
                                '${mentor.dragonSchoolMentorLessons} lessons taught',
                                '${mentor.dragonSchoolMentorLessons} lessen gegeven',
                              )),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('confirm-school-dragons'),
                  onPressed: canStart
                      ? () => Navigator.pop(
                            context,
                            _SchoolEnrollment(
                                _selectedIds.toList(growable: false),
                                _mentorId),
                          )
                      : null,
                  icon: const Icon(Icons.school_rounded),
                  label: Text(strings.pick('Enter classroom', 'Naar de les')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleDragon(String dragonId) {
    setState(() {
      if (_selectedIds.contains(dragonId)) {
        if (_selectedIds.length > widget.definition.minimumDragons) {
          _selectedIds.remove(dragonId);
        }
      } else if (_selectedIds.length < widget.definition.maximumDragons) {
        _selectedIds.add(dragonId);
      } else if (widget.definition.maximumDragons == 1) {
        _selectedIds
          ..clear()
          ..add(dragonId);
      }
    });
  }
}

class _EnrollmentDragonTile extends StatelessWidget {
  const _EnrollmentDragonTile({
    required this.dragon,
    required this.definition,
    required this.selected,
    required this.onTap,
  });

  final Pet dragon;
  final DragonSchoolGameDefinition definition;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final stars = dragon.schoolStars(definition.id);
    final attempts = dragon.schoolAttempts(definition.id);
    final exhausted = attempts >= dragonSchoolAttemptsPerLesson;
    return Card(
      margin: const EdgeInsets.only(bottom: 7),
      color: exhausted
          ? const Color(0xFFF0EDF2)
          : selected
              ? const Color(0xFFF0E8FA)
              : Colors.white,
      child: ListTile(
        key: Key('school-pupil-${dragon.id}'),
        onTap: onTap,
        leading: SizedBox.square(
          dimension: 54,
          child: _DragonImage(dragon: dragon, height: 52, animate: false),
        ),
        title: Text(dragon.displayName,
            style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(
          '${strings.petStage(dragon)} · ${strings.pick('Best', 'Beste')} ${dragon.schoolBest(definition.id)} · '
          '$attempts/$dragonSchoolAttemptsPerLesson ${strings.pick('attempts', 'pogingen')}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MiniStars(count: stars),
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

class DragonSchoolGameScreen extends StatefulWidget {
  const DragonSchoolGameScreen({
    super.key,
    required this.definition,
    required this.dragonIds,
    this.mentorDragonId,
  });

  final DragonSchoolGameDefinition definition;
  final List<String> dragonIds;
  final String? mentorDragonId;

  @override
  State<DragonSchoolGameScreen> createState() => _DragonSchoolGameScreenState();
}

class _DragonSchoolGameScreenState extends State<DragonSchoolGameScreen> {
  static const _lessonDuration = Duration(seconds: 20);
  final _random = Random();
  Timer? _ticker;
  Timer? _challengeTimer;
  Timer? _reactionTimer;
  DateTime? _endsAt;
  Duration _remaining = _lessonDuration;
  int _score = 0;
  int _target = 0;
  int _shadowDifference = 0;
  int _expected = 1;
  List<int> _order = [1, 2, 3, 4, 5, 6];
  List<int> _constellationOrder = [0, 1, 2, 3, 4, 5];
  bool _cueReady = false;
  bool _memoryVisible = false;
  bool _started = false;
  bool _ended = false;
  bool _saving = false;
  bool _mentorShieldUsed = false;
  double _phase = 0;
  int _reaction = 0;
  int _reactionToken = 0;
  Alignment _runeAlignment = Alignment.center;
  DragonSchoolLessonResult? _result;

  DragonSchoolGameKind get kind => widget.definition.kind;

  @override
  void dispose() {
    _ticker?.cancel();
    _challengeTimer?.cancel();
    _reactionTimer?.cancel();
    super.dispose();
  }

  List<Pet> _participants(HouseholdProvider game) => game.ownedDragons
      .where((dragon) => widget.dragonIds.contains(dragon.id))
      .toList(growable: false);

  Pet? _mentor(HouseholdProvider game) {
    if (widget.mentorDragonId == null) return null;
    final matches =
        game.ownedDragons.where((dragon) => dragon.id == widget.mentorDragonId);
    return matches.isEmpty ? null : matches.first;
  }

  void _start() {
    final game = context.read<HouseholdProvider>();
    final participants = _participants(game);
    if (participants.length != widget.dragonIds.length ||
        participants.any((dragon) =>
            dragon.dragonSchoolComplete ||
            dragon.schoolAttempts(widget.definition.id) >=
                dragonSchoolAttemptsPerLesson)) {
      final strings = AppStrings.of(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(strings.pick(
          'Every selected pupil has used all three attempts for this lesson.',
          'Iedere gekozen leerling heeft alle drie de pogingen voor deze les gebruikt.',
        )),
      ));
      return;
    }
    _ticker?.cancel();
    _challengeTimer?.cancel();
    _reactionTimer?.cancel();
    _score = 0;
    _remaining = _lessonDuration;
    _endsAt = DateTime.now().add(_lessonDuration);
    _target =
        _random.nextInt(kind == DragonSchoolGameKind.crystalChase ? 9 : 6);
    _shadowDifference = _random.nextInt(4);
    _expected = kind == DragonSchoolGameKind.constellationTrace ? 0 : 1;
    _order = [1, 2, 3, 4, 5, 6]..shuffle(_random);
    _constellationOrder = [0, 1, 2, 3, 4, 5]..shuffle(_random);
    _cueReady = false;
    _memoryVisible = false;
    _phase = 0;
    _reaction = 0;
    _mentorShieldUsed = false;
    _result = null;
    _saving = false;
    _started = true;
    _ended = false;
    _moveRune();
    _ticker = Timer.periodic(const Duration(milliseconds: 45), (_) => _tick());
    if (kind == DragonSchoolGameKind.emberReflex) _scheduleReflexCue();
    if (kind == DragonSchoolGameKind.sigilMemory) _scheduleMemoryHide();
    setState(() {});
  }

  void _tick() {
    if (!_started || _ended || !mounted) return;
    final remaining = _endsAt!.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      unawaited(_finish());
      return;
    }
    setState(() {
      _remaining = remaining;
      _phase = (_phase + .018) % 1;
    });
  }

  Future<void> _finish() async {
    if (_ended) return;
    _ended = true;
    _saving = true;
    _remaining = Duration.zero;
    _ticker?.cancel();
    _challengeTimer?.cancel();
    if (mounted) setState(() {});
    final result =
        await context.read<HouseholdProvider>().completeDragonSchoolLesson(
              gameId: widget.definition.id,
              score: _score,
              dragonIds: widget.dragonIds,
              mentorDragonId: widget.mentorDragonId,
            );
    if (!mounted) return;
    setState(() {
      _result = result;
      _saving = false;
    });
  }

  void _scheduleReflexCue() {
    _challengeTimer?.cancel();
    _cueReady = false;
    _challengeTimer = Timer(
      Duration(milliseconds: 600 + _random.nextInt(900)),
      () {
        if (mounted && !_ended) setState(() => _cueReady = true);
      },
    );
  }

  void _scheduleMemoryHide() {
    _challengeTimer?.cancel();
    _target = _random.nextInt(6);
    _memoryVisible = true;
    _challengeTimer = Timer(const Duration(milliseconds: 820), () {
      if (mounted && !_ended) setState(() => _memoryVisible = false);
    });
  }

  void _moveRune() {
    const points = [
      Alignment(-.72, -.65),
      Alignment(0, -.72),
      Alignment(.72, -.61),
      Alignment(-.68, .05),
      Alignment.center,
      Alignment(.68, .05),
      Alignment(-.65, .68),
      Alignment(0, .72),
      Alignment(.65, .68),
    ];
    _runeAlignment = points[_random.nextInt(points.length)];
  }

  void _correct([int points = 1]) {
    setState(() => _score += points);
    _react(1);
  }

  void _mistake({int penalty = 1}) {
    if (widget.mentorDragonId != null && !_mentorShieldUsed) {
      setState(() => _mentorShieldUsed = true);
      _react(2);
      return;
    }
    setState(() => _score = max(0, _score - penalty));
    _react(-1);
  }

  void _react(int reaction) {
    final token = ++_reactionToken;
    if (mounted) setState(() => _reaction = reaction);
    _reactionTimer?.cancel();
    _reactionTimer = Timer(const Duration(milliseconds: 430), () {
      if (mounted && token == _reactionToken) setState(() => _reaction = 0);
    });
  }

  void _tap(int index) {
    if (!_started || _ended) return;
    switch (kind) {
      case DragonSchoolGameKind.runeRush:
        _correct();
        setState(_moveRune);
      case DragonSchoolGameKind.crystalChase:
        index == _target ? _correct() : _mistake();
        setState(() => _target = _random.nextInt(9));
      case DragonSchoolGameKind.emberReflex:
        if (_cueReady) {
          _correct();
          _scheduleReflexCue();
        } else {
          _mistake();
        }
      case DragonSchoolGameKind.sigilMemory:
        if (_memoryVisible) return;
        index == _target ? _correct(2) : _mistake();
        _scheduleMemoryHide();
      case DragonSchoolGameKind.scaleOrder:
        if (_order[index] == _expected) {
          _correct();
          setState(() {
            _expected++;
            if (_expected > 6) {
              _expected = 1;
              _order.shuffle(_random);
            }
          });
        } else {
          _mistake();
          setState(() => _expected = 1);
        }
      case DragonSchoolGameKind.shadowMatch:
        index == _target ? _correct(2) : _mistake();
        setState(() {
          _target = _differentTarget(_target, 6);
          _shadowDifference = _random.nextInt(4);
        });
      case DragonSchoolGameKind.breathBalance:
        (_phase - .5).abs() < .12 ? _correct(2) : _mistake();
      case DragonSchoolGameKind.cloudWeave:
        index == _target ? _correct() : _mistake();
        setState(() => _target = _differentTarget(_target, 3));
      case DragonSchoolGameKind.safeHoard:
        index == _target ? _mistake(penalty: 2) : _correct();
        setState(() => _target = _differentTarget(_target, 6));
      case DragonSchoolGameKind.constellationTrace:
        if (index == _constellationOrder[_expected]) {
          _correct();
          setState(() {
            _expected++;
            if (_expected >= _constellationOrder.length) {
              _expected = 0;
              _constellationOrder.shuffle(_random);
            }
          });
        } else {
          _mistake();
          setState(() => _expected = 0);
        }
    }
  }

  int _differentTarget(int current, int count) {
    var next = _random.nextInt(count);
    while (next == current && count > 1) {
      next = _random.nextInt(count);
    }
    return next;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final game = context.watch<HouseholdProvider>();
    final participants = _participants(game);
    final mentor = _mentor(game);
    final colors = _schoolColors(kind);
    final keeperBest = game.dragonSchoolRecords[widget.definition.id] ?? 0;
    return Scaffold(
      appBar: AppBar(
        title: Text(
            strings.pick(widget.definition.titleEn, widget.definition.titleNl)),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colors.first.withValues(alpha: .18), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(13, 10, 13, 13),
            child: Column(
              children: [
                Row(
                  children: [
                    _GameScore(
                        label: strings.pick('SCORE', 'SCORE'), value: _score),
                    const Spacer(),
                    _GameScore(
                      label: strings.pick('TIME', 'TIJD'),
                      value: (_remaining.inMilliseconds / 1000).ceil(),
                    ),
                    const Spacer(),
                    _GameScore(
                        label: strings.pick('KEEPER BEST', 'KEEPER BESTE'),
                        value: keeperBest),
                  ],
                ),
                const SizedBox(height: 8),
                _StudentStrip(
                  dragons: participants,
                  mentor: mentor,
                  reaction: _reaction,
                  mentorShieldUsed: _mentorShieldUsed,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    key: Key('school-session-${widget.definition.id}'),
                    width: double.infinity,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .95),
                      borderRadius: BorderRadius.circular(27),
                      border:
                          Border.all(color: colors.last.withValues(alpha: .35)),
                      boxShadow: const [
                        BoxShadow(color: Color(0x142A1E50), blurRadius: 14),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            widget.definition.backgroundAsset,
                            key: Key(
                                'school-background-${widget.definition.id}'),
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                          ),
                        ),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: .03),
                                  Colors.black.withValues(alpha: .15),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.all(13),
                            child: _started && !_ended
                                ? DefaultTextStyle.merge(
                                    style: const TextStyle(
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          color: Color(0xCC201638),
                                          blurRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: _gameArea(strings, participants),
                                  )
                                : _LessonGlassPanel(
                                    child: _ended
                                        ? _resultPanel(
                                            strings, participants, keeperBest)
                                        : _intro(strings, participants),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _intro(AppStrings strings, List<Pet> participants) =>
      SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(widget.definition.iconAsset, width: 82, height: 82),
            const SizedBox(height: 8),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              alignment: WrapAlignment.center,
              children: [
                for (final dragon in participants)
                  _AttemptPill(
                    label:
                        '${dragon.displayName}: ${dragon.schoolAttempts(widget.definition.id) + 1}/$dragonSchoolAttemptsPerLesson',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              strings.pick(widget.definition.descriptionEn,
                  widget.definition.descriptionNl),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 9),
            _ScoreThresholds(definition: widget.definition),
            const SizedBox(height: 8),
            Text(
              strings.pick(
                'Each new star gives every pupil 5 XP and +1 ${_focusName(strings, widget.definition.focus)}. Only the best of three official attempts counts.',
                'Elke nieuwe ster geeft iedere leerling 5 XP en +1 ${_focusName(strings, widget.definition.focus)}. Alleen de beste van drie officiële pogingen telt.',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontSize: 11.5),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              key: const Key('start-school-game'),
              onPressed: participants.length == widget.dragonIds.length
                  ? _start
                  : null,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(strings.pick('Start lesson', 'Start les')),
            ),
          ],
        ),
      );

  Widget _resultPanel(
    AppStrings strings,
    List<Pet> participants,
    int keeperBest,
  ) {
    if (_saving || _result == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final earned = widget.definition.starsForScore(_score);
    final finalized = participants
        .where((dragon) => _result!.finalizedDragonIds.contains(dragon.id))
        .toList(growable: false);
    final canReplay = participants.every((dragon) =>
        !dragon.dragonSchoolComplete &&
        dragon.schoolAttempts(widget.definition.id) <
            dragonSchoolAttemptsPerLesson);
    return SingleChildScrollView(
      child: Column(
        children: [
          Image.asset(
              finalized.isEmpty
                  ? '$_schoolIconRoot/school_graduate.png'
                  : finalized.first.dragonSchoolOutcome.badgeAsset,
              width: 91,
              height: 91),
          Text(strings.pick('Lesson complete', 'Les voltooid'),
              style:
                  const TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
          Text('$_score',
              style: const TextStyle(
                  color: AppColors.twilight,
                  fontSize: 48,
                  fontWeight: FontWeight.w900)),
          _MiniStars(count: earned, size: 27),
          Text('${strings.pick('Keeper Best', 'Keeper Beste')}: $keeperBest'),
          const SizedBox(height: 12),
          for (final dragon in participants)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F0FA),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  SizedBox.square(
                    dimension: 40,
                    child: _DragonImage(
                        dragon: dragon, height: 40, animate: false),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dragon.displayName,
                            style:
                                const TextStyle(fontWeight: FontWeight.w900)),
                        Text(
                          '${dragon.schoolAttempts(widget.definition.id)}/$dragonSchoolAttemptsPerLesson ${strings.pick('attempts', 'pogingen')}',
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 9.5),
                        ),
                      ],
                    ),
                  ),
                  _MiniStars(count: dragon.schoolStars(widget.definition.id)),
                  const SizedBox(width: 6),
                  Text(
                    _dragonResultLabel(strings, dragon),
                    style: const TextStyle(
                        color: AppColors.twilight,
                        fontSize: 10,
                        fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          for (final dragon in finalized)
            Container(
              key: Key('school-final-outcome-${dragon.id}'),
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: _schoolOutcomeColor(dragon.dragonSchoolOutcome)
                    .withValues(alpha: .10),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: _schoolOutcomeColor(dragon.dragonSchoolOutcome)
                      .withValues(alpha: .35),
                ),
              ),
              child: Row(
                children: [
                  Image.asset(dragon.dragonSchoolOutcome.badgeAsset,
                      width: 54, height: 54),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.pick(dragon.dragonSchoolOutcome.titleEn,
                              dragon.dragonSchoolOutcome.titleNl),
                          style: TextStyle(
                            color:
                                _schoolOutcomeColor(dragon.dragonSchoolOutcome),
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          strings.pick(
                            dragon.dragonSchoolDropout
                                ? 'Final report complete. No diploma this time, but the story is worth recording.'
                                : 'Final report complete. Diploma earned!',
                            dragon.dragonSchoolDropout
                                ? 'Eindrapport voltooid. Ditmaal geen diploma, maar het verhaal verdient een plek.'
                                : 'Eindrapport voltooid. Diploma behaald!',
                          ),
                          style: const TextStyle(fontSize: 10.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const Key('replay-school-game'),
            onPressed: canReplay ? _start : null,
            icon: Icon(canReplay ? Icons.replay_rounded : Icons.lock_rounded),
            label: Text(canReplay
                ? strings.pick('Use next attempt', 'Gebruik volgende poging')
                : strings.pick(
                    'All 3 attempts used', 'Alle 3 pogingen gebruikt')),
          ),
        ],
      ),
    );
  }

  String _dragonResultLabel(AppStrings strings, Pet dragon) {
    final stars = _result?.newStarsByDragon[dragon.id];
    if (stars == null) return strings.pick('Best kept', 'Beste behouden');
    return '+$stars ★ · +${_result?.xpByDragon[dragon.id] ?? 0} XP';
  }

  Widget _gameArea(AppStrings strings, List<Pet> participants) =>
      switch (kind) {
        DragonSchoolGameKind.runeRush => AnimatedAlign(
            duration: const Duration(milliseconds: 210),
            curve: Curves.easeOutBack,
            alignment: _runeAlignment,
            child: InkWell(
              key: const Key('school-rune-rush-target'),
              borderRadius: BorderRadius.circular(70),
              onTap: () => _tap(0),
              child:
                  _GlowingSprite(asset: widget.definition.iconAsset, size: 118),
            ),
          ),
        DragonSchoolGameKind.crystalChase => _choiceGrid(
            9,
            (index) => AnimatedScale(
              scale: index == _target ? 1 : .48,
              duration: const Duration(milliseconds: 180),
              child: Opacity(
                opacity: index == _target ? 1 : .16,
                child: Image.asset(widget.definition.iconAsset, width: 66),
              ),
            ),
          ),
        DragonSchoolGameKind.emberReflex => Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: .96, end: _cueReady ? 1.09 : .96),
              duration: const Duration(milliseconds: 260),
              builder: (_, scale, child) => Transform.scale(
                scale: scale,
                child: child,
              ),
              child: InkWell(
                key: const Key('school-reflex-button'),
                onTap: () => _tap(0),
                borderRadius: BorderRadius.circular(120),
                child: SizedBox.square(
                  dimension: 210,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: animation,
                      child: FadeTransition(opacity: animation, child: child),
                    ),
                    child: Image.asset(
                      _cueReady
                          ? widget.definition.iconAsset
                          : '$_schoolIconRoot/piece_ember_dormant.png',
                      key: ValueKey(_cueReady),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),
        DragonSchoolGameKind.sigilMemory => Column(
            children: [
              Text(
                _memoryVisible
                    ? strings.pick('Remember…', 'Onthoud…')
                    : strings.pick('Which sigil?', 'Welk sigil?'),
                style:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 210),
                  child: _memoryVisible
                      ? Center(
                          key: const Key('school-sigil-preview'),
                          child: Image.asset(
                            _sigilAssets[_target],
                            width: 116,
                            height: 116,
                            fit: BoxFit.contain,
                          ),
                        )
                      : _centeredChoiceGrid(
                          key: const Key('school-sigil-grid'),
                          count: 6,
                          child: (index) => Image.asset(
                            _sigilAssets[index],
                            width: 64,
                            height: 64,
                            fit: BoxFit.contain,
                          ),
                        ),
                ),
              ),
            ],
          ),
        DragonSchoolGameKind.scaleOrder => Column(
            children: [
              Text(
                  '${strings.pick('Next scale', 'Volgende schub')}: $_expected',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 20)),
              const SizedBox(height: 10),
              Expanded(
                child: _choiceGrid(
                  6,
                  (index) => Stack(
                    alignment: Alignment.center,
                    children: [
                      Opacity(
                        opacity: .94,
                        child: Image.asset(
                          '$_schoolIconRoot/piece_scale.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      Text('${_order[index]}',
                          style: const TextStyle(
                              color: AppColors.twilight,
                              fontSize: 31,
                              fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        DragonSchoolGameKind.shadowMatch => _centeredChoiceGrid(
            key: const Key('school-shadow-grid'),
            count: 6,
            child: (index) => _shadowChoice(participants, index),
          ),
        DragonSchoolGameKind.breathBalance => _timingGame(strings),
        DragonSchoolGameKind.cloudWeave => _cloudWeave(strings, participants),
        DragonSchoolGameKind.safeHoard => _choiceGrid(
            6,
            (index) => AnimatedScale(
              duration: const Duration(milliseconds: 190),
              scale: index == _target ? .93 : 1,
              child: Image.asset(
                index == _target
                    ? '$_schoolIconRoot/piece_cursed_chest.png'
                    : '$_schoolIconRoot/piece_safe_treasure.png',
                width: 68,
                height: 68,
                fit: BoxFit.contain,
              ),
            ),
          ),
        DragonSchoolGameKind.constellationTrace => _constellationGame(strings),
      };

  Widget _choiceGrid(int count, Widget Function(int) child) => GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 9,
          mainAxisSpacing: 9,
        ),
        itemCount: count,
        itemBuilder: (context, index) => InkWell(
          key: Key('school-choice-$index'),
          onTap: () => _tap(index),
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xE8FAF7FD), Color(0xDCF0E8F8)],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFD7CDEA)),
            ),
            child: Center(child: child(index)),
          ),
        ),
      );

  Widget _centeredChoiceGrid({
    required Key key,
    required int count,
    required Widget Function(int) child,
  }) =>
      Center(
        child: ConstrainedBox(
          key: key,
          constraints: const BoxConstraints(maxWidth: 320, maxHeight: 244),
          child: _choiceGrid(count, child),
        ),
      );

  Widget _shadowChoice(List<Pet> participants, int index) {
    Widget shadow = ColorFiltered(
      colorFilter: const ColorFilter.mode(Color(0xFF170D28), BlendMode.srcIn),
      child: participants.isEmpty
          ? Image.asset(widget.definition.iconAsset)
          : _DragonImage(
              dragon: participants.first,
              height: 65,
              animate: false,
              silhouette: true,
            ),
    );
    if (index == _target) {
      shadow = switch (_shadowDifference) {
        0 => Transform.flip(flipX: true, child: shadow),
        1 => Transform.scale(scale: .82, child: shadow),
        2 => Transform.rotate(angle: .13, child: shadow),
        _ => Transform.translate(
            offset: const Offset(5, -3),
            child: Transform.scale(scaleX: .88, scaleY: 1.03, child: shadow),
          ),
      };
    }
    return Container(
      margin: const EdgeInsets.all(3),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .48),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x889D88BE)),
      ),
      child: shadow,
    );
  }

  Widget _timingGame(AppStrings strings) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _GlowingSprite(asset: widget.definition.iconAsset, size: 104),
          const SizedBox(height: 24),
          SizedBox(
            height: 92,
            child: LayoutBuilder(builder: (context, constraints) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      '$_schoolIconRoot/piece_breath_gauge.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  Positioned(
                    left: 18 + (constraints.maxWidth - 76) * _phase,
                    child: Image.asset(
                      '$_schoolIconRoot/piece_breath_orb.png',
                      width: 46,
                      height: 46,
                    ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            key: const Key('school-timing-stop'),
            onPressed: () => _tap(0),
            icon: const Icon(Icons.touch_app_rounded),
            label: Text(strings.pick('Balance', 'Balanceer')),
          ),
        ],
      );

  Widget _cloudWeave(AppStrings strings, List<Pet> participants) {
    final pupil = participants.isEmpty
        ? ''
        : participants[_score.remainder(participants.length)].displayName;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(widget.definition.iconAsset, width: 64, height: 64),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                strings.pick('Guide $pupil through the glowing cloud',
                    'Leid $pupil door de gloeiende wolk'),
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        Expanded(
          child: Row(
            children: [
              for (var lane = 0; lane < 3; lane++) ...[
                if (lane > 0) const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    key: Key('school-cloud-gate-$lane'),
                    onTap: () => _tap(lane),
                    borderRadius: BorderRadius.circular(80),
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutBack,
                      scale: lane == _target ? 1 : .86,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 220),
                            opacity: lane == _target ? 1 : .62,
                            child: Image.asset(
                              '$_schoolIconRoot/piece_cloud_gate.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          if (lane == _target)
                            Image.asset(
                              'assets/images/ui/trials/trial_constellation_node.png',
                              width: 42,
                              height: 42,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _constellationGame(AppStrings strings) => Column(
        children: [
          Row(
            children: [
              Image.asset(widget.definition.iconAsset, width: 58, height: 58),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  strings.pick('Follow the glowing path in order',
                      'Volg het gloeiende pad in de juiste volgorde'),
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final points = _constellationPoints(constraints.biggest);
                return Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _ConstellationPainter(
                          points: points,
                          path: _constellationOrder,
                          completed: _expected,
                        ),
                      ),
                    ),
                    for (var index = 0; index < points.length; index++)
                      Positioned(
                        left: points[index].dx - 27,
                        top: points[index].dy - 27,
                        child: InkResponse(
                          key: Key('school-constellation-star-$index'),
                          onTap: () => _tap(index),
                          radius: 34,
                          child: AnimatedScale(
                            duration: const Duration(milliseconds: 180),
                            scale: index == _constellationOrder[_expected]
                                ? 1.18
                                : .88,
                            child: Image.asset(
                              'assets/images/ui/trials/trial_constellation_node.png',
                              width: 54,
                              height: 54,
                              opacity: AlwaysStoppedAnimation(
                                index == _constellationOrder[_expected]
                                    ? 1
                                    : .58,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      );
}

class _StudentStrip extends StatelessWidget {
  const _StudentStrip({
    required this.dragons,
    required this.mentor,
    required this.reaction,
    required this.mentorShieldUsed,
  });

  final List<Pet> dragons;
  final Pet? mentor;
  final int reaction;
  final bool mentorShieldUsed;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCD2E8)),
      ),
      child: Row(
        children: [
          for (final dragon in dragons)
            Expanded(
              child: AnimatedScale(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutBack,
                scale: reaction == 1
                    ? 1.08
                    : reaction == -1
                        ? .9
                        : 1,
                child: Column(
                  children: [
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          _DragonImage(
                              dragon: dragon, height: 53, animate: true),
                          if (reaction != 0)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Image.asset(
                                reaction == 1
                                    ? '$_schoolIconRoot/reaction_success.png'
                                    : reaction == 2
                                        ? '$_schoolIconRoot/reaction_mentor_shield.png'
                                        : '$_schoolIconRoot/reaction_mistake.png',
                                width: 28,
                                height: 28,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(dragon.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 9.5, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ),
          if (mentor != null) ...[
            const VerticalDivider(width: 8),
            SizedBox(
              width: 74,
              child: Column(
                children: [
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Opacity(
                          opacity: mentorShieldUsed ? .55 : 1,
                          child: _DragonImage(
                              dragon: mentor!, height: 49, animate: true),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Opacity(
                            opacity: mentorShieldUsed ? .35 : 1,
                            child: Image.asset(
                              '$_schoolIconRoot/reaction_mentor_shield.png',
                              width: 24,
                              height: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(strings.pick('Mentor', 'Mentor'),
                      style: const TextStyle(
                          fontSize: 9, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DragonImage extends StatelessWidget {
  const _DragonImage({
    required this.dragon,
    required this.height,
    required this.animate,
    this.silhouette = false,
  });

  final Pet dragon;
  final double height;
  final bool animate;
  final bool silhouette;

  @override
  Widget build(BuildContext context) => DragonArt(
        height: height,
        animate: animate,
        stageKey: dragon.stageKey,
        lineageId: dragon.lineageId,
        evolutionPath: dragon.activeEvolutionPath,
        prismatic: dragon.spectral,
        sinister: dragon.sinister,
        silhouette: silhouette,
      );
}

class _ScoreThresholds extends StatelessWidget {
  const _ScoreThresholds({required this.definition});

  final DragonSchoolGameDefinition definition;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Threshold(
              label: '★',
              score: definition.bronzeScore,
              color: const Color(0xFFB87333)),
          const SizedBox(width: 7),
          _Threshold(
              label: '★★',
              score: definition.silverScore,
              color: const Color(0xFF8C92A2)),
          const SizedBox(width: 7),
          _Threshold(
              label: '★★★',
              score: definition.goldScore,
              color: const Color(0xFFD39A16)),
        ],
      );
}

class _Threshold extends StatelessWidget {
  const _Threshold(
      {required this.label, required this.score, required this.color});

  final String label;
  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: color.withValues(alpha: .4)),
        ),
        child: Text('$label  $score',
            style: TextStyle(color: color, fontWeight: FontWeight.w900)),
      );
}

class _MiniStars extends StatelessWidget {
  const _MiniStars({required this.count, this.size = 16});

  final int count;
  final double size;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < 3; index++)
            Opacity(
              opacity: index < count ? 1 : .28,
              child: ColorFiltered(
                colorFilter: index < count
                    ? const ColorFilter.mode(
                        Colors.transparent,
                        BlendMode.dst,
                      )
                    : const ColorFilter.mode(
                        Color(0xFF9385A5),
                        BlendMode.srcIn,
                      ),
                child: Image.asset(
                  'assets/images/ui/trials/trial_constellation_node.png',
                  width: size,
                  height: size,
                ),
              ),
            ),
        ],
      );
}

class _LessonGlassPanel extends StatelessWidget {
  const _LessonGlassPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .91),
          borderRadius: BorderRadius.circular(21),
          border: Border.all(color: Colors.white.withValues(alpha: .75)),
          boxShadow: const [
            BoxShadow(color: Color(0x33201638), blurRadius: 16),
          ],
        ),
        child: child,
      );
}

class _GlowingSprite extends StatelessWidget {
  const _GlowingSprite({required this.asset, required this.size});

  final String asset;
  final double size;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Color(0x665B3D91), blurRadius: 30)],
        ),
        child: Image.asset(asset, width: size, height: size),
      );
}

class _AttemptPill extends StatelessWidget {
  const _AttemptPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFF0E8FA),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: const Color(0xFFC9B4DE)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.twilight,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
}

class _GameScore extends StatelessWidget {
  const _GameScore({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Container(
        width: 89,
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDCD2E8)),
        ),
        child: Column(
          children: [
            Text('$value',
                style: const TextStyle(
                    color: AppColors.twilight,
                    fontSize: 19,
                    fontWeight: FontWeight.w900)),
            Text(label,
                maxLines: 1,
                style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 7.5,
                    fontWeight: FontWeight.w900)),
          ],
        ),
      );
}

class _ConstellationPainter extends CustomPainter {
  const _ConstellationPainter({
    required this.points,
    required this.path,
    required this.completed,
  });

  final List<Offset> points;
  final List<int> path;
  final int completed;

  @override
  void paint(Canvas canvas, Size size) {
    final faint = Paint()
      ..color = const Color(0x336E55A0)
      ..strokeWidth = 2;
    final glowing = Paint()
      ..color = const Color(0xFFFFC93D)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (var index = 1; index < path.length; index++) {
      canvas.drawLine(points[path[index - 1]], points[path[index]], faint);
    }
    for (var index = 1; index < completed; index++) {
      canvas.drawLine(points[path[index - 1]], points[path[index]], glowing);
    }
  }

  @override
  bool shouldRepaint(covariant _ConstellationPainter oldDelegate) =>
      oldDelegate.completed != completed || oldDelegate.path != path;
}

List<Offset> _constellationPoints(Size size) => [
      Offset(size.width * .18, size.height * .22),
      Offset(size.width * .50, size.height * .10),
      Offset(size.width * .82, size.height * .27),
      Offset(size.width * .72, size.height * .67),
      Offset(size.width * .42, size.height * .84),
      Offset(size.width * .15, size.height * .63),
    ];

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

Color _schoolOutcomeColor(DragonSchoolOutcome outcome) => switch (outcome) {
      DragonSchoolOutcome.inTraining => AppColors.twilight,
      DragonSchoolOutcome.dropout => const Color(0xFFB25434),
      DragonSchoolOutcome.graduate => const Color(0xFF47765A),
      DragonSchoolOutcome.honorsGraduate => const Color(0xFF246C8C),
      DragonSchoolOutcome.highHonors => const Color(0xFF6D4BA0),
      DragonSchoolOutcome.valedictorian => const Color(0xFF9A6A00),
    };

List<Color> _schoolColors(DragonSchoolGameKind kind) =>
    switch (kind.index % 5) {
      0 => const [Color(0xFF5B3D91), Color(0xFF9A66C7)],
      1 => const [Color(0xFF246C8C), Color(0xFF55A9BB)],
      2 => const [Color(0xFF9B3C38), Color(0xFFE17743)],
      3 => const [Color(0xFF4D598E), Color(0xFF7F78C5)],
      _ => const [Color(0xFF47765A), Color(0xFF75A966)],
    };
