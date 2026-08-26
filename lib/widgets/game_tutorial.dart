import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/pet.dart';
import '../theme/app_theme.dart';
import 'dragon_art.dart';

Future<bool> showDragonHavenTutorial(
  BuildContext context, {
  required Pet dragon,
  required ValueChanged<int> onNavigate,
}) async {
  return await showGeneralDialog<bool>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        barrierLabel: 'DragonHaven tutorial',
        transitionDuration: const Duration(milliseconds: 360),
        transitionBuilder: (_, animation, __, child) => FadeTransition(
          opacity:
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          child: child,
        ),
        pageBuilder: (_, __, ___) => _DragonHavenTutorial(
          dragon: dragon,
          onNavigate: onNavigate,
        ),
      ) ??
      false;
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
      Navigator.pop(context, true);
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
    final target = _targetFor(step, size, padding);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              key: ValueKey('tutorial-spotlight-$_stepIndex'),
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
                              textAlign: TextAlign.start,
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
                                Flexible(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: TextButton(
                                      key: const Key('skip-tutorial'),
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 10,
                                        ),
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(strings.pick(
                                          'Skip tutorial',
                                          'Tutorial overslaan',
                                        )),
                                      ),
                                    ),
                                  ),
                                ),
                                Text(
                                  '${_stepIndex + 1}/${steps.length}',
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: FilledButton(
                                      key: const Key('next-tutorial-step'),
                                      onPressed: () => _next(steps),
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 11,
                                        ),
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          _stepIndex == steps.length - 1
                                              ? strings.pick(
                                                  'Finish', 'Afronden')
                                              : strings.pick(
                                                  'Next', 'Volgende'),
                                        ),
                                      ),
                                    ),
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
  const _TutorialStep(
    this.tabIndex,
    this.title,
    this.body, {
    this.spotlight = _TutorialSpotlight.navigation,
  });

  final int tabIndex;
  final String title;
  final String body;
  final _TutorialSpotlight spotlight;
}

enum _TutorialSpotlight { navigation, overflowMenu }

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
        strings.pick('Online friends', 'Online vrienden'),
        strings.pick(
          "Create an e-mail-verified online account, then add other keepers by their Keeper ID. Friends can open each other's public profile and see portraits, titles, favorite dragons, discovered forms and Trial records.",
          'Maak een online account met e-mailverificatie en voeg daarna andere hoeders toe via hun Keeper ID. Vrienden kunnen elkaars openbare profiel openen en portraits, titles, favoriete draken, ontdekte vormen en Trial-records bekijken.',
        ),
      ),
      _TutorialStep(
        0,
        strings.pick('Trade and travel together', 'Samen ruilen en reizen'),
        strings.pick(
          'From a friend you can offer a protected one-to-one Trade: eggs, chests and Relics stay reserved until it completes or expires. Logged-in friends can also enroll dragons together in asynchronous Group Adventures.',
          'Bij een vriend kun je een beveiligde één-op-één Trade aanbieden: eieren, kisten en Relieken blijven gereserveerd totdat de ruil voltooid is of verloopt. Ingelogde vrienden kunnen hun draken ook samen inschrijven voor asynchrone Group Adventures.',
        ),
      ),
      _TutorialStep(
        1,
        strings.tr('adventure'),
        strings.pick(
          "Mini Adventures take minutes, Short Adventures hours and Long Adventures days. A dragon's matching Expertise shortens the timer. Group Adventures need 2–4 logged-in friends and begin automatically when their requirements are met.",
          'Mini Adventures duren minuten, Short Adventures uren en Long Adventures dagen. De bijpassende Expertise van een draak verkort de timer. Group Adventures vereisen 2–4 ingelogde vrienden en beginnen automatisch zodra aan de vereisten is voldaan.',
        ),
      ),
      _TutorialStep(
        1,
        strings.pick('Trials', 'Trials'),
        strings.pick(
          'Trials are skill-based minigames and refill every 15 minutes, up to three waiting. Cavern Flight trains Spirit, Ruin Breaker trains Might and Runeweaver trains Arcana; your performance sets the rank, rewards and personal high score.',
          'Trials zijn minigames gebaseerd op vaardigheid en worden elke 15 minuten aangevuld, tot maximaal drie klaarstaan. Cavern Flight traint Spirit, Ruin Breaker traint Might en Runeweaver traint Arcana; je prestatie bepaalt de rank, beloningen en persoonlijke highscore.',
        ),
      ),
      _TutorialStep(
        2,
        strings.tr('tower'),
        strings.pick(
          'Use the two large sprites at the top right: My Dragons opens your complete dragon collection, while the Draconomicon shows every discovered dragon form. Below them you can build, visit and decorate Tower floors.',
          'Gebruik de twee grote sprites rechtsboven: My Dragons opent je volledige drakenverzameling en het Draconomicon toont iedere ontdekte drakenvorm. Daaronder kun je Torenverdiepingen bouwen, bezoeken en inrichten.',
        ),
      ),
      _TutorialStep(
        3,
        strings.tr('inventory'),
        strings.pick(
          'Eggs, unopened chests, furniture and Relics are stored here. Open chests, start an egg incubation or inspect what you own; items reserved for a Trade cannot be used until released.',
          'Hier worden eieren, ongeopende kisten, meubels en Relieken bewaard. Open kisten, start de incubatie van een ei of bekijk wat je bezit; voor een Trade gereserveerde items kun je pas weer gebruiken wanneer ze zijn vrijgegeven.',
        ),
      ),
      _TutorialStep(
        4,
        strings.tr('shop'),
        strings.pick(
          'Buy furniture for your Tower with coins or gems. Title Chests cost coins and unlock account titles; Portrait Chests cost gems and unlock profile portraits. Open both from Inventory.',
          'Koop met munten of edelstenen meubels voor je Toren. Title Chests kosten munten en ontgrendelen account-titles; Portrait Chests kosten edelstenen en ontgrendelen profielportraits. Je opent beide vanuit Inventory.',
        ),
      ),
      _TutorialStep(
        2,
        strings.pick('The three-dot menu', 'Het menu met drie stippen'),
        strings.pick(
          'Tap the three dots at the top right for Account info, where you can change your portrait and title and manage Notifications and Audio. The same menu opens Language, Achievements and this Tutorial again.',
          'Tik rechtsboven op de drie stippen voor Account info, waar je jouw portrait en title kunt wijzigen en Notifications en Audio kunt beheren. Via hetzelfde menu open je Language, Achievements en deze Tutorial opnieuw.',
        ),
        spotlight: _TutorialSpotlight.overflowMenu,
      ),
    ];

Rect _targetFor(_TutorialStep step, Size size, EdgeInsets padding) {
  if (step.spotlight == _TutorialSpotlight.overflowMenu) {
    return Rect.fromLTWH(size.width - 68, padding.top + 5, 62, 60);
  }
  final segmentWidth = size.width / 5;
  return Rect.fromLTWH(
    segmentWidth * step.tabIndex + 6,
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
