import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/pet.dart';
import '../theme/app_theme.dart';
import 'dragon_art.dart';

Future<void> showDragonHavenTutorial(
  BuildContext context, {
  required Pet dragon,
  required ValueChanged<int> onNavigate,
}) async {
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    barrierLabel: 'DragonHaven tutorial',
    transitionDuration: const Duration(milliseconds: 360),
    transitionBuilder: (_, animation, __, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
      child: child,
    ),
    pageBuilder: (_, __, ___) => _DragonHavenTutorial(
      dragon: dragon,
      onNavigate: onNavigate,
    ),
  );
}

class _DragonHavenTutorial extends StatefulWidget {
  const _DragonHavenTutorial({
    required this.dragon,
    required this.onNavigate,
  });

  final Pet dragon;
  final ValueChanged<int> onNavigate;

  @override
  State<_DragonHavenTutorial> createState() => _DragonHavenTutorialState();
}

class _DragonHavenTutorialState extends State<_DragonHavenTutorial> {
  int _stepIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onNavigate(2);
    });
  }

  void _next(List<_TutorialStep> steps) {
    if (_stepIndex == steps.length - 1) {
      Navigator.pop(context);
      return;
    }
    setState(() => _stepIndex++);
    widget.onNavigate(steps[_stepIndex].tabIndex);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final steps = _steps(strings, widget.dragon.displayName);
    final step = steps[_stepIndex];
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final target = _targetFor(step.tabIndex, size, padding);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              key: ValueKey('tutorial-spotlight-${step.tabIndex}'),
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 520),
              tween: Tween(begin: .72, end: 1),
              curve: Curves.easeOutBack,
              builder: (_, value, __) => CustomPaint(
                painter: _TutorialSpotlightPainter(
                  target: target,
                  scale: value,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: const Alignment(0, -.23),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 82, 18, 130),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 410),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        key: Key('tutorial-step-$_stepIndex'),
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(24, 52, 24, 20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFFFBF2), Color(0xFFF1E9FF)],
                          ),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: const Color(0xFFFFD86E),
                            width: 2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x88201644),
                              blurRadius: 32,
                              offset: Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              step.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontSize: 24,
                                height: 1.08,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 11),
                            Text(
                              step.body,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 15,
                                height: 1.42,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                TextButton(
                                  key: const Key('skip-tutorial'),
                                  onPressed: () => Navigator.pop(context),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 10,
                                    ),
                                  ),
                                  child: Text(strings.pick(
                                    'Skip tutorial',
                                    'Tutorial overslaan',
                                  )),
                                ),
                                const Spacer(),
                                Text(
                                  '${_stepIndex + 1}/${steps.length}',
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                FilledButton(
                                  key: const Key('next-tutorial-step'),
                                  onPressed: () => _next(steps),
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 11,
                                    ),
                                  ),
                                  child: Text(
                                    _stepIndex == steps.length - 1
                                        ? strings.pick('Finish', 'Afronden')
                                        : strings.pick('Next', 'Volgende'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: -58,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            key: const Key('tutorial-dragon-guide'),
                            width: 104,
                            height: 104,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const RadialGradient(
                                colors: [Colors.white, Color(0xFFE6D8FF)],
                              ),
                              border: Border.all(
                                color: const Color(0xFFFFD86E),
                                width: 3,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x665B3E91),
                                  blurRadius: 18,
                                  offset: Offset(0, 7),
                                ),
                              ],
                            ),
                            child: Transform.scale(
                              scale: 1.55,
                              alignment: const Alignment(0, -.7),
                              child: DragonArt(
                                height: 104,
                                animate: !reduceMotion,
                                stageKey: widget.dragon.stageKey,
                                lineageId: widget.dragon.lineageId,
                                evolutionPath:
                                    widget.dragon.activeEvolutionPath,
                                prismatic: widget.dragon.spectral,
                                sinister: widget.dragon.sinister,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TutorialStep {
  const _TutorialStep(this.tabIndex, this.title, this.body);

  final int tabIndex;
  final String title;
  final String body;
}

List<_TutorialStep> _steps(AppStrings strings, String dragonName) => [
      _TutorialStep(
        2,
        strings.pick('Welcome to DragonHaven', 'Welkom in DragonHaven'),
        '$dragonName ${strings.pick(
          'will show you around. You can skip now and replay this tour later from the three-dot menu.',
          'leidt je rond. Je kunt nu overslaan en deze rondleiding later opnieuw starten via het menu met de drie stippen.',
        )}',
      ),
      _TutorialStep(
        0,
        strings.tr('friends'),
        strings.pick(
          'This is the future meeting place for linked Dragonkeepers, visits and fair trades.',
          'Dit wordt de ontmoetingsplek voor gekoppelde Drakenhoeders, bezoekjes en eerlijke ruilhandel.',
        ),
      ),
      _TutorialStep(
        1,
        strings.tr('adventure'),
        strings.pick(
          'Send an available dragon on an Adventure to earn XP, Expertises and treasure chests.',
          'Stuur een beschikbare draak op Avontuur om XP, Expertises en schatkisten te verdienen.',
        ),
      ),
      _TutorialStep(
        2,
        strings.tr('tower'),
        strings.pick(
          'Build unique rooms, decorate them and choose which dragons may roam through their home.',
          'Bouw unieke kamers, richt ze in en kies welke draken vrij door hun thuis mogen lopen.',
        ),
      ),
      _TutorialStep(
        3,
        strings.tr('inventory'),
        strings.pick(
          'Your eggs, unopened chests, furniture and consumable Relics are safely stored here.',
          'Je eieren, ongeopende kisten, meubels en verbruikbare Relieken worden hier veilig bewaard.',
        ),
      ),
      _TutorialStep(
        4,
        strings.tr('shop'),
        strings.pick(
          'Spend coins or gems on furniture that makes every Tower room feel like home.',
          'Besteed munten of edelstenen aan meubels die elke Torenkamer als thuis laten voelen.',
        ),
      ),
    ];

Rect _targetFor(int tabIndex, Size size, EdgeInsets padding) {
  final segmentWidth = size.width / 5;
  return Rect.fromLTWH(
    segmentWidth * tabIndex + 6,
    size.height - padding.bottom - 83,
    segmentWidth - 12,
    77,
  );
}

class _TutorialSpotlightPainter extends CustomPainter {
  const _TutorialSpotlightPainter({required this.target, required this.scale});

  final Rect target;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final scaled = Rect.fromCenter(
      center: target.center,
      width: target.width * scale,
      height: target.height * scale,
    );
    final hole = RRect.fromRectAndRadius(scaled, const Radius.circular(24));
    final shade = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(hole);
    canvas.drawPath(shade, Paint()..color = const Color(0xB5120C29));
    canvas.drawRRect(
      hole,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = const Color(0xFFFFDB70),
    );
  }

  @override
  bool shouldRepaint(covariant _TutorialSpotlightPainter oldDelegate) =>
      oldDelegate.target != target || oldDelegate.scale != scale;
}
