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

class _DragonHavenTutorialState extends State<_DragonHavenTutorial>
    with WidgetsBindingObserver {
  int _stepIndex = 0;
  Rect? _measuredTarget;
  bool _resolvingTarget = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onNavigate(2);
      _resolveCurrentTarget();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    _resolveCurrentTarget();
  }

  void _next(List<_TutorialStep> steps) {
    if (_stepIndex == steps.length - 1) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _stepIndex++;
      _measuredTarget = null;
      _resolvingTarget = true;
    });
    widget.onNavigate(steps[_stepIndex].tabIndex);
    _resolveCurrentTarget();
  }

  Future<void> _resolveCurrentTarget() async {
    if (!mounted) return;
    final requestIndex = _stepIndex;
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted || requestIndex != _stepIndex) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || requestIndex != _stepIndex) return;
    final strings = AppStrings.of(context);
    final step = _steps(strings, widget.dragon.displayName)[requestIndex];
    await _revealStepTarget(step, requestIndex);
    if (!mounted || requestIndex != _stepIndex) return;
    final measured = _rectForKey(step.targetKey, step.targetPadding);
    if (!mounted || requestIndex != _stepIndex) return;
    setState(() {
      _measuredTarget = measured;
      _resolvingTarget = false;
    });
  }

  Future<void> _revealStepTarget(
    _TutorialStep step,
    int requestIndex,
  ) async {
    final scrollKey = step.scrollKey;
    if (scrollKey == null) return;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final scrollRoot = _elementForKey(scrollKey);
    final scrollable =
        scrollRoot == null ? null : _scrollableStateWithin(scrollRoot);
    if (scrollable == null || !scrollable.position.hasContentDimensions) {
      return;
    }

    final position = scrollable.position;
    final requestedOffset =
        position.maxScrollExtent * step.scrollFraction.clamp(0, 1);
    if ((position.pixels - requestedOffset).abs() > 1) {
      await position.animateTo(
        requestedOffset,
        duration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    }
    if (!mounted || requestIndex != _stepIndex) return;
    await WidgetsBinding.instance.endOfFrame;

    final target = _elementForKey(step.targetKey);
    if (target == null) return;
    await Scrollable.ensureVisible(
      target,
      alignment: step.scrollAlignment,
      alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
    if (mounted && requestIndex == _stepIndex) {
      await WidgetsBinding.instance.endOfFrame;
    }
  }

  ScrollableState? _scrollableStateWithin(Element root) {
    ScrollableState? match;
    void visit(Element element) {
      if (match != null) return;
      if (element is StatefulElement && element.state is ScrollableState) {
        match = element.state as ScrollableState;
        return;
      }
      element.visitChildElements(visit);
    }

    visit(root);
    return match;
  }

  Rect? _rectForKey(Key key, EdgeInsets padding) {
    final element = _elementForKey(key);
    final renderObject = element?.renderObject;
    if (renderObject is! RenderBox ||
        !renderObject.attached ||
        !renderObject.hasSize) {
      return null;
    }
    final origin = renderObject.localToGlobal(Offset.zero);
    final rect = origin & renderObject.size;
    final viewport = Offset.zero & MediaQuery.sizeOf(context);
    if (!rect.overlaps(viewport)) return null;
    return Rect.fromLTRB(
      rect.left - padding.left,
      rect.top - padding.top,
      rect.right + padding.right,
      rect.bottom + padding.bottom,
    ).intersect(viewport);
  }

  Element? _elementForKey(Key key) {
    Element? match;
    void visit(Element element) {
      if (match != null) return;
      if (element.widget.key == key) {
        match = element;
        return;
      }
      element.visitChildElements(visit);
    }

    final root = WidgetsBinding.instance.rootElement;
    if (root == null) return null;
    visit(root);
    return match;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final steps = _steps(strings, widget.dragon.displayName);
    assert(steps.length == dragonHavenTutorialStepCount);
    final step = steps[_stepIndex];
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Material(
      color: Colors.transparent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          final padding = MediaQuery.paddingOf(context);
          final target = _measuredTarget ?? _targetFor(step, size, padding);
          final cardPlacement = _cardPlacementFor(target, size, padding);
          return Stack(
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
                      cardRegion: cardPlacement.region,
                      scale: value,
                      resolving: _resolvingTarget,
                    ),
                  ),
                ),
              ),
              if (!_resolvingTarget)
                Positioned.fromRect(
                  rect: target,
                  child: const IgnorePointer(
                    child: SizedBox(key: Key('tutorial-target-outline')),
                  ),
                ),
              Positioned.fromRect(
                rect: cardPlacement.region,
                child: Semantics(
                  liveRegion: true,
                  label: '${step.title}. ${step.body}',
                  child: ClipRect(
                    key: const Key('tutorial-card-region'),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Align(
                          alignment: cardPlacement.alignment,
                          child: SingleChildScrollView(
                            key: const Key('tutorial-card-scroll'),
                            padding: const EdgeInsets.fromLTRB(0, 64, 0, 16),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 410),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    key: Key('tutorial-step-$_stepIndex'),
                                    width: double.infinity,
                                    padding: const EdgeInsets.fromLTRB(
                                        24, 52, 24, 20),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFFFFFBF2),
                                          Color(0xFFF1E9FF)
                                        ],
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
                                        const SizedBox(height: 68),
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
                                            colors: [
                                              Colors.white,
                                              Color(0xFFE6D8FF)
                                            ],
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
                                            evolutionPath: widget
                                                .dragon.activeEvolutionPath,
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
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: _TutorialFooter(
                            strings: strings,
                            stepIndex: _stepIndex,
                            stepCount: steps.length,
                            busy: _resolvingTarget,
                            onSkip: () => Navigator.pop(context, false),
                            onNext: () => _next(steps),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TutorialFooter extends StatelessWidget {
  const _TutorialFooter({
    required this.strings,
    required this.stepIndex,
    required this.stepCount,
    required this.busy,
    required this.onSkip,
    required this.onNext,
  });

  final AppStrings strings;
  final int stepIndex;
  final int stepCount;
  final bool busy;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0xFFF9F4FF),
        elevation: 5,
        shadowColor: const Color(0x44201644),
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    key: const Key('skip-tutorial'),
                    onPressed: onSkip,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        strings.pick('Skip tutorial', 'Tutorial overslaan'),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: AppColors.mist),
                ),
                child: Text(
                  '${stepIndex + 1}/$stepCount',
                  style: const TextStyle(
                    color: AppColors.twilight,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    key: const Key('next-tutorial-step'),
                    onPressed: busy ? null : onNext,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                    ),
                    child: busy
                        ? const SizedBox.square(
                            dimension: 17,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              stepIndex == stepCount - 1
                                  ? strings.pick('Finish', 'Afronden')
                                  : strings.pick('Next', 'Volgende'),
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class _TutorialStep {
  const _TutorialStep(
    this.tabIndex,
    this.title,
    this.body, {
    this.spotlight = _TutorialSpotlight.navigation,
    required this.targetKey,
    this.targetPadding = const EdgeInsets.all(7),
    this.scrollKey,
    this.scrollFraction = 0,
    this.scrollAlignment = .42,
  });

  final int tabIndex;
  final String title;
  final String body;
  final _TutorialSpotlight spotlight;
  final Key targetKey;
  final EdgeInsets targetPadding;
  final Key? scrollKey;
  final double scrollFraction;
  final double scrollAlignment;
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
        targetKey: const Key('tutorial-tower-actions'),
        scrollKey: const PageStorageKey('dragon-tower-scroll'),
        spotlight: _TutorialSpotlight.topContent,
      ),
      _TutorialStep(
        0,
        strings.pick('Friends and profiles', 'Vrienden en profielen'),
        strings.pick(
          "Create a verified online account and add Keepers by their Keeper ID. A friend's profile shows vanity, favorite dragon, discovered forms, achievements and Trial records.",
          'Maak een geverifieerd online account en voeg Hoeders toe via hun Keeper-ID. Een vriendenprofiel toont vanity, favoriete draak, ontdekte vormen, achievements en Trial-records.',
        ),
        targetKey: const Key('tutorial-friends-header'),
        scrollKey: const PageStorageKey('friends-scroll'),
      ),
      _TutorialStep(
        0,
        strings.pick('Messages and safe trades', 'Berichten en veilig ruilen'),
        strings.pick(
          'Use CHAT on a friend card for private messages from the last 24 hours. Trade offers reserve eligible eggs, chests and Relics until the exchange completes or expires.',
          'Gebruik CHAT op een vriendenkaart voor privéberichten van de laatste 24 uur. Ruilaanbiedingen reserveren geschikte eieren, kisten en Relieken totdat de ruil voltooid is of verloopt.',
        ),
        targetKey: const Key('tutorial-friends-overview'),
        scrollKey: const PageStorageKey('friends-scroll'),
        spotlight: _TutorialSpotlight.middleContent,
      ),
      _TutorialStep(
        0,
        strings.pick('Your Conclave', 'Jouw Conclave'),
        strings.pick(
          'Conclave is directly below the Friends overview. Join or found one, chat with up to 20 Keepers, tend the shared Aerie, share achievements and follow its Chronicle.',
          'Conclave staat direct onder het vriendenoverzicht. Word lid of sticht er één, chat met maximaal 20 Hoeders, verzorg de gedeelde Aerie, deel achievements en volg de Chronicle.',
        ),
        targetKey: const Key('open-conclave'),
        scrollKey: const PageStorageKey('friends-scroll'),
        scrollAlignment: .52,
        spotlight: _TutorialSpotlight.middleContent,
      ),
      _TutorialStep(
        1,
        strings.pick('Adventures', 'Avonturen'),
        strings.pick(
          'Mini, Short and Long Adventures take progressively longer. Matching Expertise reduces their duration. Completed cards list rewards; a solo active Adventure can be aborted without rewards.',
          'Mini-, Short- en Long Adventures duren steeds langer. Bijpassende Expertise verkort de duur. Afgeronde kaarten tonen beloningen; een actief solo-avontuur kan zonder beloning worden afgebroken.',
        ),
        targetKey: const Key('tutorial-adventure-header'),
      ),
      _TutorialStep(
        1,
        strings.pick(
            'Group and Special Adventures', 'Group- en Special Adventures'),
        strings.pick(
          'Group Adventures show their combined Expertise requirement before joining. Special Adventures appear during events, show guaranteed rewards and remain finishable when started in time.',
          'Group Adventures tonen vóór deelname hun vereiste gecombineerde Expertise. Special Adventures verschijnen tijdens events, tonen gegarandeerde beloningen en blijven afmaakbaar als je op tijd begon.',
        ),
        targetKey: const Key('tutorial-adventure-section-group'),
        scrollKey: const PageStorageKey('available-adventures-scroll'),
        scrollFraction: .72,
        scrollAlignment: .4,
        spotlight: _TutorialSpotlight.topContent,
      ),
      _TutorialStep(
        1,
        strings.pick('Trials and constellation', 'Trials en constellatie'),
        strings.pick(
          'Trials refill every 15 minutes, up to three waiting. Might, Arcana and Spirit each have a skill game. Play daily for the seven-day constellation; missing a day resets it.',
          'Trials vullen iedere 15 minuten aan, tot maximaal drie klaarstaan. Might, Arcana en Spirit hebben elk een vaardigheidsspel. Speel dagelijks voor de zevendaagse constellatie; een gemiste dag zet hem terug.',
        ),
        targetKey: const Key('adventure-tab-trials'),
        spotlight: _TutorialSpotlight.lowerContent,
      ),
      _TutorialStep(
        2,
        strings.pick('Evolution and Expertise', 'Evolutie en Expertise'),
        strings.pick(
          'Train Expertise through Adventures, Trials and Academy lessons. Evolution choices raise different Expertise maximums; MAX always follows the correct dragon, form and Ascension cap.',
          'Train Expertise via Adventures, Trials en Academy-lessen. Evolutiekeuzes verhogen verschillende Expertise-maxima; MAX volgt altijd de juiste draak, vorm en Ascension-limiet.',
        ),
        targetKey: const Key('open-my-dragons'),
        scrollKey: const PageStorageKey('dragon-tower-scroll'),
        spotlight: _TutorialSpotlight.topContent,
      ),
      _TutorialStep(
        2,
        strings.pick('Dragons and Draconomicon', 'Draken en Draconomicon'),
        strings.pick(
          'My Dragons has grid and compact list views, reversible sorting and combined filters for form, rarity and spectral dragons. The Draconomicon tracks every family and evolved form.',
          'My Dragons heeft raster- en compacte lijstweergaven, omkeerbaar sorteren en combineerbare filters voor vorm, rarity en spectral draken. Het Draconomicon houdt iedere familie en evolutievorm bij.',
        ),
        targetKey: const Key('tutorial-tower-actions'),
        scrollKey: const PageStorageKey('dragon-tower-scroll'),
        spotlight: _TutorialSpotlight.topContent,
      ),
      _TutorialStep(
        2,
        strings.pick('Nest, rooms and Tower', 'Nest, kamers en Toren'),
        strings.pick(
          'Incubate an egg in the Rooftop Nest and watch its timer from the Tower. Starter Eggs can be tapped to speed up. Build, decorate and reorder every room except the Rooftop Nest.',
          'Incubeer een ei in het Daknest en bekijk de timer vanuit de Toren. Starter Eggs kun je aantikken om te versnellen. Bouw, decoreer en herschik iedere kamer behalve het Daknest.',
        ),
        targetKey: const Key('tutorial-rooftop-header'),
        scrollKey: const PageStorageKey('dragon-tower-scroll'),
        scrollAlignment: 0,
        spotlight: _TutorialSpotlight.middleContent,
      ),
      _TutorialStep(
        2,
        strings.pick('Dragon Academy', 'Dragon Academy'),
        strings.pick(
          'The Academy unlocks with Tower level 5 at the bottom. Choose available students, earn lesson stars and Expertise, use mentors and graduate early after passing every subject.',
          'De Academy ontgrendelt bij Torenlevel 5 onderaan. Kies beschikbare leerlingen, verdien lessterren en Expertise, gebruik mentoren en studeer vroeg af na een voldoende voor ieder vak.',
        ),
        targetKey: const Key('tutorial-dragon-school-title'),
        scrollKey: const PageStorageKey('dragon-tower-scroll'),
        scrollFraction: 1,
        scrollAlignment: .5,
        spotlight: _TutorialSpotlight.lowerContent,
      ),
      _TutorialStep(
        3,
        strings.pick('Organize Inventory', 'Inventory organiseren'),
        strings.pick(
          'Eggs and furniture have saved grid/list views, sorting and filters. Egg rows show hatch time; chests use a fixed rarity order. Trade-reserved items stay unavailable.',
          'Eieren en furniture hebben opgeslagen raster-/lijstweergaven, sortering en filters. Ei-rijen tonen uitbroedtijd; kisten gebruiken een vaste rarity-volgorde. Gereserveerde ruilitems blijven onbruikbaar.',
        ),
        targetKey: const Key('tutorial-inventory-tabs'),
      ),
      _TutorialStep(
        3,
        strings.pick('Chests and Relics', 'Kisten en Relieken'),
        strings.pick(
          'Open one chest full-screen, or ten together when possible. Relics show whether they are consumable, tradeable or equipable; an equipped XP Relic can move between dragons.',
          'Open één kist schermvullend, of tien tegelijk wanneer mogelijk. Relieken tonen of ze verbruikbaar, ruilbaar of uitrustbaar zijn; een uitgeruste XP-Relic kan tussen draken wisselen.',
        ),
        targetKey: const Key('inventory-tab-chests'),
        spotlight: _TutorialSpotlight.middleContent,
      ),
      _TutorialStep(
        4,
        strings.pick('Shops and currencies', 'Shops en valuta'),
        strings.pick(
          'Browse separate Coin, Gem and Packs shops. Furniture, Relics and collection chests show their currency clearly. Optional store bundles never replace normal gameplay.',
          'Bekijk aparte Coin-, Gem- en Packs-shops. Furniture, Relieken en verzamelkisten tonen hun valuta duidelijk. Optionele winkelbundels vervangen nooit de normale gameplay.',
        ),
        targetKey: const Key('shop-currency-tabs'),
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
        targetKey: const Key('shop-tab-packs'),
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
        targetKey: const Key('app-overflow-menu'),
        targetPadding: const EdgeInsets.all(4),
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
        targetKey: const Key('app-overflow-menu'),
        targetPadding: const EdgeInsets.all(4),
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

({Alignment alignment, Rect region}) _cardPlacementFor(
  Rect target,
  Size size,
  EdgeInsets safePadding,
) {
  const navigationClearance = 96.0;
  final safeTop = safePadding.top + 10;
  final safeBottom = size.height - safePadding.bottom - navigationClearance;
  final spaceAbove = target.top - safeTop;
  final spaceBelow = safeBottom - target.bottom;
  final placeAbove = spaceAbove >= spaceBelow;
  final horizontalInset = size.width > 446 ? (size.width - 410) / 2 : 18.0;

  if (placeAbove) {
    return (
      alignment: Alignment.bottomCenter,
      region: Rect.fromLTRB(
        horizontalInset,
        safeTop,
        size.width - horizontalInset,
        (target.top - 12).clamp(safeTop + 80, safeBottom),
      ),
    );
  }
  return (
    alignment: Alignment.topCenter,
    region: Rect.fromLTRB(
      horizontalInset,
      (target.bottom + 12).clamp(safeTop, safeBottom - 80),
      size.width - horizontalInset,
      safeBottom,
    ),
  );
}

class _TutorialSpotlightPainter extends CustomPainter {
  const _TutorialSpotlightPainter({
    required this.target,
    required this.cardRegion,
    required this.scale,
    required this.resolving,
  });

  final Rect target;
  final Rect cardRegion;
  final double scale;
  final bool resolving;

  @override
  void paint(Canvas canvas, Size size) {
    if (resolving) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = const Color(0xD9120C29),
      );
      return;
    }
    final scaled = Rect.fromCenter(
      center: target.center,
      width: target.width * scale,
      height: target.height * scale,
    );
    final radius = (target.shortestSide * .22).clamp(12, 24).toDouble();
    final hole = RRect.fromRectAndRadius(scaled, Radius.circular(radius));
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
    final cardAbove = cardRegion.center.dy < target.center.dy;
    final cardAnchor = cardAbove
        ? Offset(cardRegion.center.dx, cardRegion.bottom)
        : Offset(cardRegion.center.dx, cardRegion.top);
    final targetAnchor = cardAbove
        ? Offset(target.center.dx, target.top)
        : Offset(target.center.dx, target.bottom);
    final connector = Paint()
      ..color = const Color(0xFFFFDB70).withValues(alpha: .9)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(cardAnchor, targetAnchor, connector);
    canvas.drawCircle(targetAnchor, 5, connector);
    canvas.drawRRect(
      hole.inflate(5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0x66FFF1B2),
    );
  }

  @override
  bool shouldRepaint(covariant _TutorialSpotlightPainter oldDelegate) =>
      oldDelegate.target != target ||
      oldDelegate.cardRegion != cardRegion ||
      oldDelegate.scale != scale ||
      oldDelegate.resolving != resolving;
}
