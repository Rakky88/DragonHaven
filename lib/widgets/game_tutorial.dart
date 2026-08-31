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
    assert(steps.length == dragonHavenTutorialStepCount);
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
              alignment: _cardAlignmentFor(step.spotlight),
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

enum _TutorialSpotlight {
  navigation,
  overflowMenu,
  topContent,
  middleContent,
  lowerContent,
  currencies,
}

const dragonHavenTutorialStepCount = 17;

List<_TutorialStep> _steps(AppStrings strings, String dragonName) => [
      _TutorialStep(
        2,
        strings.pick('Welcome to DragonHaven', 'Welkom in DragonHaven'),
        '$dragonName ${strings.pick(
          'will show you around. You can skip now and replay this complete tour later from the three-dot menu.',
          'leidt je rond. Je kunt nu overslaan en deze complete rondleiding later opnieuw starten via het menu met de drie stippen.',
        )}',
        spotlight: _TutorialSpotlight.topContent,
      ),
      _TutorialStep(
        0,
        strings.pick('Friends and profiles', 'Vrienden en profielen'),
        strings.pick(
          "Create a verified online account and add Keepers by their Keeper ID. A friend's profile shows vanity, favorite dragon, discovered forms, achievements and Trial records.",
          'Maak een geverifieerd online account en voeg Hoeders toe via hun Keeper-ID. Een vriendenprofiel toont vanity, favoriete draak, ontdekte vormen, achievements en Trial-records.',
        ),
      ),
      _TutorialStep(
        0,
        strings.pick('Messages and safe trades', 'Berichten en veilig ruilen'),
        strings.pick(
          'Use CHAT on a friend card for private messages from the last 24 hours. Trade offers reserve eligible eggs, chests and Relics until the exchange completes or expires.',
          'Gebruik CHAT op een vriendenkaart voor privéberichten van de laatste 24 uur. Ruilaanbiedingen reserveren geschikte eieren, kisten en Relieken totdat de ruil voltooid is of verloopt.',
        ),
        spotlight: _TutorialSpotlight.middleContent,
      ),
      _TutorialStep(
        0,
        strings.pick('Your Conclave', 'Jouw Conclave'),
        strings.pick(
          'Conclave is directly below the Friends overview. Join or found one, chat with up to 20 Keepers, tend the shared Aerie, share achievements and follow its Chronicle.',
          'Conclave staat direct onder het vriendenoverzicht. Word lid of sticht er één, chat met maximaal 20 Hoeders, verzorg de gedeelde Aerie, deel achievements en volg de Chronicle.',
        ),
        spotlight: _TutorialSpotlight.middleContent,
      ),
      _TutorialStep(
        1,
        strings.pick('Adventures', 'Avonturen'),
        strings.pick(
          'Mini, Short and Long Adventures take progressively longer. Matching Expertise reduces their duration. Completed cards list rewards; a solo active Adventure can be aborted without rewards.',
          'Mini-, Short- en Long Adventures duren steeds langer. Bijpassende Expertise verkort de duur. Afgeronde kaarten tonen beloningen; een actief solo-avontuur kan zonder beloning worden afgebroken.',
        ),
      ),
      _TutorialStep(
        1,
        strings.pick(
            'Group and Special Adventures', 'Group- en Special Adventures'),
        strings.pick(
          'Group Adventures show their combined Expertise requirement before joining. Special Adventures appear during events, show guaranteed rewards and remain finishable when started in time.',
          'Group Adventures tonen vóór deelname hun vereiste gecombineerde Expertise. Special Adventures verschijnen tijdens events, tonen gegarandeerde beloningen en blijven afmaakbaar als je op tijd begon.',
        ),
        spotlight: _TutorialSpotlight.topContent,
      ),
      _TutorialStep(
        1,
        strings.pick('Trials and constellation', 'Trials en constellatie'),
        strings.pick(
          'Trials refill every 15 minutes, up to three waiting. Might, Arcana and Spirit each have a skill game. Play daily for the seven-day constellation; missing a day resets it.',
          'Trials vullen iedere 15 minuten aan, tot maximaal drie klaarstaan. Might, Arcana en Spirit hebben elk een vaardigheidsspel. Speel dagelijks voor de zevendaagse constellatie; een gemiste dag zet hem terug.',
        ),
        spotlight: _TutorialSpotlight.lowerContent,
      ),
      _TutorialStep(
        2,
        strings.pick('Evolution and Expertise', 'Evolutie en Expertise'),
        strings.pick(
          'Train Expertise through Adventures, Trials and Academy lessons. Evolution choices raise different Expertise maximums; MAX always follows the correct dragon, form and Ascension cap.',
          'Train Expertise via Adventures, Trials en Academy-lessen. Evolutiekeuzes verhogen verschillende Expertise-maxima; MAX volgt altijd de juiste draak, vorm en Ascension-limiet.',
        ),
        spotlight: _TutorialSpotlight.topContent,
      ),
      _TutorialStep(
        2,
        strings.pick('Dragons and Draconomicon', 'Draken en Draconomicon'),
        strings.pick(
          'My Dragons has grid and compact list views, reversible sorting and combined filters for form, rarity and spectral dragons. The Draconomicon tracks every family and evolved form.',
          'My Dragons heeft raster- en compacte lijstweergaven, omkeerbaar sorteren en combineerbare filters voor vorm, rarity en spectral draken. Het Draconomicon houdt iedere familie en evolutievorm bij.',
        ),
        spotlight: _TutorialSpotlight.topContent,
      ),
      _TutorialStep(
        2,
        strings.pick('Nest, rooms and Tower', 'Nest, kamers en Toren'),
        strings.pick(
          'Incubate an egg in the Rooftop Nest and watch its timer from the Tower. Starter Eggs can be tapped to speed up. Build, decorate and reorder every room except the Rooftop Nest.',
          'Incubeer een ei in het Daknest en bekijk de timer vanuit de Toren. Starter Eggs kun je aantikken om te versnellen. Bouw, decoreer en herschik iedere kamer behalve het Daknest.',
        ),
        spotlight: _TutorialSpotlight.middleContent,
      ),
      _TutorialStep(
        2,
        strings.pick('Dragon Academy', 'Dragon Academy'),
        strings.pick(
          'The Academy unlocks with Tower level 5 at the bottom. Choose available students, earn lesson stars and Expertise, use mentors and graduate early after passing every subject.',
          'De Academy ontgrendelt bij Torenlevel 5 onderaan. Kies beschikbare leerlingen, verdien lessterren en Expertise, gebruik mentoren en studeer vroeg af na een voldoende voor ieder vak.',
        ),
        spotlight: _TutorialSpotlight.lowerContent,
      ),
      _TutorialStep(
        3,
        strings.pick('Organize Inventory', 'Inventory organiseren'),
        strings.pick(
          'Eggs and furniture have saved grid/list views, sorting and filters. Egg rows show hatch time; chests use a fixed rarity order. Trade-reserved items stay unavailable.',
          'Eieren en furniture hebben opgeslagen raster-/lijstweergaven, sortering en filters. Ei-rijen tonen uitbroedtijd; kisten gebruiken een vaste rarity-volgorde. Gereserveerde ruilitems blijven onbruikbaar.',
        ),
      ),
      _TutorialStep(
        3,
        strings.pick('Chests and Relics', 'Kisten en Relieken'),
        strings.pick(
          'Open one chest full-screen, or ten together when possible. Relics show whether they are consumable, tradeable or equipable; an equipped XP Relic can move between dragons.',
          'Open één kist schermvullend, of tien tegelijk wanneer mogelijk. Relieken tonen of ze verbruikbaar, ruilbaar of uitrustbaar zijn; een uitgeruste XP-Relic kan tussen draken wisselen.',
        ),
        spotlight: _TutorialSpotlight.middleContent,
      ),
      _TutorialStep(
        4,
        strings.pick('Shops and currencies', 'Shops en valuta'),
        strings.pick(
          'Browse separate Coin, Gem and Packs shops. Furniture, Relics and collection chests show their currency clearly. Optional store bundles never replace normal gameplay.',
          'Bekijk aparte Coin-, Gem- en Packs-shops. Furniture, Relieken en verzamelkisten tonen hun valuta duidelijk. Optionele winkelbundels vervangen nooit de normale gameplay.',
        ),
        spotlight: _TutorialSpotlight.currencies,
      ),
      _TutorialStep(
        4,
        strings.pick(
            'Music and supporter vanity', 'Muziek en supporter-vanity'),
        strings.pick(
          'Music Chests always unlock a missing song. The Jukebox controls songs, order, Shuffle and Repeat. Packs can add separate portraits, titles, badges, frames and furniture.',
          'Music Chests ontgrendelen altijd een ontbrekend lied. De Jukebox beheert liedjes, volgorde, Shuffle en Repeat. Packs kunnen aparte portraits, titles, badges, frames en furniture toevoegen.',
        ),
        spotlight: _TutorialSpotlight.topContent,
      ),
      _TutorialStep(
        2,
        strings.pick('Account, audio and notifications',
            'Account, audio en notificaties'),
        strings.pick(
          'Account Info manages vanity, messages, audio and Jukebox. Notification types require device permission and open the right destination. Cloud backups and restore history protect online progress.',
          'Account Info beheert vanity, berichten, audio en Jukebox. Notificatietypen vereisen apparaatmachtiging en openen de juiste plek. Cloudback-ups en herstelgeschiedenis beschermen online voortgang.',
        ),
        spotlight: _TutorialSpotlight.overflowMenu,
      ),
      _TutorialStep(
        2,
        strings.pick(
            'Journal, achievements and help', 'Dagboek, achievements en hulp'),
        strings.pick(
          'The three-dot menu also opens Language, Achievements, the Keeper Journal and this Tutorial. The Journal records milestones; secret achievements reveal themselves only when earned.',
          'Het menu met drie stippen opent ook Language, Achievements, het Keeperdagboek en deze Tutorial. Het dagboek bewaart mijlpalen; geheime achievements onthullen zich pas wanneer je ze verdient.',
        ),
        spotlight: _TutorialSpotlight.overflowMenu,
      ),
    ];

Rect _targetFor(_TutorialStep step, Size size, EdgeInsets padding) {
  return switch (step.spotlight) {
    _TutorialSpotlight.overflowMenu =>
      Rect.fromLTWH(size.width - 68, padding.top + 5, 62, 60),
    _TutorialSpotlight.topContent => Rect.fromLTWH(
        12,
        padding.top + 72,
        size.width - 24,
        size.height * .21,
      ),
    _TutorialSpotlight.middleContent => Rect.fromLTWH(
        12,
        padding.top + size.height * .28,
        size.width - 24,
        size.height * .24,
      ),
    _TutorialSpotlight.lowerContent => Rect.fromLTWH(
        12,
        size.height - padding.bottom - 292,
        size.width - 24,
        190,
      ),
    _TutorialSpotlight.currencies => Rect.fromLTWH(
        size.width - 245,
        padding.top + 5,
        178,
        60,
      ),
    _TutorialSpotlight.navigation => () {
        final segmentWidth = size.width / 5;
        return Rect.fromLTWH(
          segmentWidth * step.tabIndex + 6,
          size.height - padding.bottom - 83,
          segmentWidth - 12,
          77,
        );
      }(),
  };
}

Alignment _cardAlignmentFor(_TutorialSpotlight spotlight) =>
    switch (spotlight) {
      _TutorialSpotlight.navigation ||
      _TutorialSpotlight.lowerContent =>
        const Alignment(0, -.6),
      _TutorialSpotlight.topContent ||
      _TutorialSpotlight.middleContent ||
      _TutorialSpotlight.overflowMenu ||
      _TutorialSpotlight.currencies =>
        const Alignment(0, .66),
    };

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
