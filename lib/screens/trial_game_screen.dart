import '../models/trial_dragon.dart';
import '../models/trial_input.dart';
import '../services/canonical_trial_run_source.dart';
import '../services/canonical_game_snapshot.dart';
import '../services/trial_gameplay_controller.dart';
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/pet.dart';
import '../models/social.dart';
import '../models/dragon_emote.dart';
import '../models/mystic_relic.dart';
import '../models/trial.dart';
import '../models/classic_trial_game.dart';
import '../providers/household_provider.dart';
import '../providers/online_account_provider.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import '../widgets/dragon_art.dart';
import '../widgets/dragon_emote_picker.dart';
import '../widgets/game_icon_sprite.dart';
import '../widgets/trial_icon_sprite.dart';
import 'seasonal_trial_game.dart';

class TrialGameScreen extends StatefulWidget {
  const TrialGameScreen({
    super.key,
    required this.offerId,
    required this.dragonId,
    this.seasonalSession,
    this.source,
    this.elapsedMilliseconds,
  });

  final String offerId;
  final String dragonId;
  final SeasonalTrialSession? seasonalSession;
  final CanonicalTrialRunSource? source;
  final int Function()? elapsedMilliseconds;

  @override
  State<TrialGameScreen> createState() => _TrialGameScreenState();
}

class _TrialGameScreenState extends State<TrialGameScreen>
    with WidgetsBindingObserver {
  TrialOffer? _offer;
  TrialDragon? _dragon;
  TrialGameplayController? _controller;
  bool _showingResult = false, _leaving = false;
  Timer? _attemptLease;
  bool _renewingLease = false;

  @override
  void initState() {
    super.initState();
    final source = widget.source;
    if (source != null) {
      WidgetsBinding.instance.addObserver(this);
      _offer = source.offer;
      _dragon = source.dragon;
      _controller = TrialGameplayController(source,
          elapsedMilliseconds: widget.elapsedMilliseconds)
        ..addListener(_verifiedChanged);
      // Reserving a Trial notifies the account-wide session. Defer until this
      // route has finished building so ancestor consumers can rebuild safely.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_controller!.prepare());
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _controller?.pause();
  }

  void _verifiedChanged() {
    if (!mounted) return;
    setState(() {});
    final completion = _controller?.completion;
    if (completion != null && !_showingResult) {
      _showingResult = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _showTrialCompletion(context, completion, _dragon!.displayName);
        if (mounted) {
          setState(() => _leaving = true);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.pop(context, completion);
          });
        }
      });
    }
  }

  Future<void> _cancelVerified() async {
    final controller = _controller!;
    controller.pause();
    final s = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                content: Text(s.pick('Leave this Trial without rewards?',
                    'Deze proef zonder beloning verlaten?')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(s.pick('Stay', 'Blijven'))),
                  TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(s.pick('Leave', 'Verlaten')))
                ]));
    if (confirmed != true || !mounted) return;
    try {
      await controller.cancel();
      if (mounted) {
        setState(() => _leaving = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.pop(context);
        });
      }
    } on CanonicalGameException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(s.pick('Reconnect to finish saving this Trial.',
                'Maak opnieuw verbinding om deze proef op te slaan.'))));
      }
    }
  }

  Widget _verifiedBoundary(Widget child) {
    final controller = _controller!;
    final s = AppStrings.of(context);
    final hidden = !controller.source.accountCurrent;
    final blocked =
        !controller.ready || controller.paused || controller.error != null;
    return PopScope(
        canPop: _leaving,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && !controller.saving) unawaited(_cancelVerified());
        },
        child: Stack(children: [
          if (!hidden) child else const Scaffold(body: SizedBox.expand()),
          if (blocked || hidden)
            Positioned.fill(
                child: Material(
                    color: Colors.black87,
                    child: Center(
                        child: Padding(
                            padding: const EdgeInsets.all(28),
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                      hidden
                                          ? s.pick('Sign in again to continue.',
                                              'Meld je opnieuw aan om verder te gaan.')
                                          : controller.error != null
                                              ? s.pick(
                                                  'Your Trial is paused. Reconnect to save and continue.',
                                                  'Je proef is gepauzeerd. Maak opnieuw verbinding om op te slaan en verder te gaan.')
                                              : controller.paused
                                                  ? s.pick('Trial paused',
                                                      'Proef gepauzeerd')
                                                  : s.pick(
                                                      'Preparing your Trial...',
                                                      'Je proef wordt klaargezet...'),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 18)),
                                  const SizedBox(height: 20),
                                  if (!hidden &&
                                      (controller.paused ||
                                          controller.error != null))
                                    FilledButton(
                                        key: const Key('resume-verified-trial'),
                                        onPressed: controller.saving
                                            ? null
                                            : controller.resume,
                                        child:
                                            Text(s.pick('Continue', 'Verder'))),
                                  if (controller.saving ||
                                      !controller.ready &&
                                          controller.error == null)
                                    const CircularProgressIndicator(),
                                  if (!hidden)
                                    TextButton(
                                        onPressed: controller.saving
                                            ? null
                                            : _cancelVerified,
                                        child: Text(s.pick(
                                            'Leave Trial', 'Proef verlaten'))),
                                ]))))),
        ]));
  }

  void _keepAttemptAlive() {
    final session = widget.seasonalSession;
    if (session == null ||
        _offer?.kind != TrialKind.sunwakeSurf ||
        _attemptLease != null) {
      return;
    }
    final online = context.read<OnlineAccountProvider>();
    final owner = online.currentUserId;
    _attemptLease = Timer.periodic(const Duration(minutes: 5), (_) async {
      if (!mounted ||
          owner == null ||
          online.currentUserId != owner ||
          _renewingLease) {
        return;
      }
      _renewingLease = true;
      try {
        await online.renewSeasonalTrial(session);
      } finally {
        _renewingLease = false;
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.removeListener(_verifiedChanged);
    _controller?.dispose();
    _attemptLease?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.source != null || _offer != null && _dragon != null) return;
    final game = context.read<HouseholdProvider>();
    _offer = game.availableTrials.cast<TrialOffer?>().firstWhere(
          (candidate) => candidate?.id == widget.offerId,
          orElse: () => null,
        );
    _dragon = game.ownedDragons.cast<Pet?>().firstWhere(
          (candidate) => candidate?.id == widget.dragonId,
          orElse: () => null,
        );
  }

  @override
  Widget build(BuildContext context) {
    final offer = _offer;
    final dragon = _dragon;
    if (_controller case final controller?) {
      if (!controller.ready ||
          !controller.source.accountCurrent ||
          dragon == null) {
        return _verifiedBoundary(const Scaffold(body: SizedBox.expand()));
      }
    }
    if (offer == null || dragon == null) {
      return _UnavailableTrial(onClose: () => Navigator.pop(context));
    }
    final playfield = switch (offer.kind) {
      TrialKind.cavernFlight => _CavernFlightGame(
          offer: offer, dragon: dragon, controller: _controller),
      TrialKind.ruinBreaker =>
        _RuinBreakerGame(offer: offer, dragon: dragon, controller: _controller),
      TrialKind.runeweaver =>
        _RuneweaverGame(offer: offer, dragon: dragon, controller: _controller),
      TrialKind.witchlightWard ||
      TrialKind.hollyfrostGiftforge ||
      TrialKind.midnightChime ||
      TrialKind.rosevowRelay ||
      TrialKind.prismaticParade ||
      TrialKind.sunwakeSurf ||
      TrialKind.moonlitOrchard ||
      TrialKind.wishcakeTower =>
        SeasonalTrialGame(
          offer: offer,
          dragon: dragon,
          randomSeed: widget.seasonalSession?.seed,
          controller: _controller,
          onStarted: _keepAttemptAlive,
          onFinished: (result) async {
            if (_controller != null) return;
            _attemptLease?.cancel();
            return _finishTrial(
              context,
              offer: offer,
              dragon: dragon,
              score: result.score,
              seasonalSession: widget.seasonalSession,
              seasonalResult: result,
            );
          },
        ),
    };
    return _controller == null ? playfield : _verifiedBoundary(playfield);
  }
}

class _UnavailableTrial extends StatelessWidget {
  const _UnavailableTrial({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.eventColor(context, const Color(0xFF17102E)),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const GameIconSprite(
                    GameIconKind.adventureActive,
                    size: 110,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.of(context).pick(
                      'This Trial is no longer available.',
                      'Deze proef is niet meer beschikbaar.',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: onClose, child: const Text('OK')),
                ],
              ),
            ),
          ),
        ),
      );
}

class _TrialScaffold extends StatelessWidget {
  const _TrialScaffold({
    required this.title,
    required this.focus,
    required this.score,
    required this.best,
    required this.child,
  });

  final String title;
  final TrainingFocus focus;
  final int score;
  final int best;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      backgroundColor: AppColors.eventColor(context, const Color(0xFF17102E)),
      appBar: AppBar(
        backgroundColor: AppColors.eventColor(context, const Color(0xFF17102E)),
        foregroundColor: Colors.white,
        title: Text(title),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              decoration: const BoxDecoration(
                color: Color(0xFF211641),
                border: Border(bottom: BorderSide(color: Color(0x355B4B8A))),
              ),
              child: Row(
                children: [
                  GameIconSprite(
                    GameIconSprite.forTrainingFocus(focus),
                    size: 30,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _focusLabel(strings, focus),
                    style: const TextStyle(
                      color: Color(0xFFFFE08A),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  TrialIconSprite(
                    kind: switch (focus) {
                      TrainingFocus.spirit => TrialKind.cavernFlight,
                      TrainingFocus.might => TrialKind.ruinBreaker,
                      TrainingFocus.arcana => TrialKind.runeweaver,
                    },
                    size: 30,
                  ),
                  const SizedBox(width: 7),
                  _HudValue(
                    label: strings.pick('SCORE', 'SCORE'),
                    value: '$score',
                  ),
                  const SizedBox(width: 16),
                  _HudValue(
                    label: strings.pick('BEST', 'BESTE'),
                    value: '$best',
                  ),
                ],
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _HudValue extends StatelessWidget {
  const _HudValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 8,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      );
}

Future<void> _finishTrial(
  BuildContext context, {
  required TrialOffer offer,
  required TrialDragon dragon,
  required int score,
  SeasonalTrialSession? seasonalSession,
  SeasonalTrialRunResult? seasonalResult,
}) async {
  // Keep the route navigator itself. Completing the Trial removes its offer and
  // rebuilds this screen, so the individual game's BuildContext can be disposed
  // while the result dialog is still visible.
  final routeNavigator = Navigator.of(context);
  final game = context.read<HouseholdProvider>();
  var completedWithoutRanking = false;
  if (offer.definition.isSeasonal) {
    final session = seasonalSession;
    final result = seasonalResult;
    if (session == null || result == null) {
      if (routeNavigator.mounted) routeNavigator.pop();
      return;
    }
    final online = context.read<OnlineAccountProvider>();
    final verified = await online.completeSeasonalTrial(
      session: session,
      score: score,
      correctActions: result.correctActions,
      totalActions: result.totalActions,
      durationMs: result.duration.inMilliseconds,
    );
    if (verified?.accepted != true) {
      completedWithoutRanking = const {
        'online_timeout',
        'online_server_error',
        'online_unexpected_error',
      }.contains(online.errorCode);
      if (completedWithoutRanking) {
        // The run began with a valid server token, so a lost connection during
        // play must not erase the normal local Trial reward. The unverified
        // score is deliberately excluded from the worldwide ranking.
      } else {
        if (routeNavigator.mounted) {
          ScaffoldMessenger.of(routeNavigator.context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.of(routeNavigator.context).pick(
                'The server could not verify this seasonal Trial. No reward was changed.',
                'De server kon deze seizoensproef niet verifiëren. Er is geen beloning aangepast.',
              )),
            ),
          );
          routeNavigator.pop();
        }
        return;
      }
    }
  }
  final completion = await game.completeTrial(
    offerId: offer.id,
    dragonId: dragon.id,
    score: score,
  );
  if (!routeNavigator.mounted) return;
  if (completion == null) {
    routeNavigator.pop();
    return;
  }
  if (completedWithoutRanking && routeNavigator.mounted) {
    ScaffoldMessenger.of(routeNavigator.context).showSnackBar(
      SnackBar(
        content: Text(AppStrings.of(routeNavigator.context).pick(
          'Your Trial reward is safe, but this offline score was not added to the event ranking.',
          'Je Trialbeloning is veilig, maar deze offline score is niet aan de eventranglijst toegevoegd.',
        )),
      ),
    );
  }
  await _showTrialCompletion(
      routeNavigator.context, completion, dragon.displayName);
  if (routeNavigator.mounted) routeNavigator.pop(completion);
}

Future<void> _showTrialCompletion(
    BuildContext context, TrialCompletion completion, String dragonName) async {
  final routeNavigator = Navigator.of(context);
  unawaited(HavenAudio.play(HavenSound.adventureReturn));
  await showGeneralDialog<void>(
    context: routeNavigator.context,
    barrierDismissible: false,
    barrierColor: Colors.black87,
    transitionDuration: const Duration(milliseconds: 500),
    transitionBuilder: (_, animation, __, child) {
      final entrance = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      );
      return FadeTransition(
        opacity: animation,
        child: RotationTransition(
          turns: Tween<double>(begin: -.16, end: 0).animate(entrance),
          child: ScaleTransition(
            scale: Tween<double>(begin: .68, end: 1).animate(entrance),
            child: child,
          ),
        ),
      );
    },
    pageBuilder: (dialogContext, _, __) => _TrialResultCard(
      completion: completion,
      dragonName: dragonName,
      onContinue: () => Navigator.pop(dialogContext),
    ),
  );
}

class _TrialResultCard extends StatelessWidget {
  const _TrialResultCard({
    required this.completion,
    required this.dragonName,
    required this.onContinue,
  });

  final TrialCompletion completion;
  final String dragonName;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final reward = completion.reward;
    final grade = trialGradeLabel(reward.grade);
    final chest = reward.chestTier;
    final color = switch (reward.grade) {
      TrialGrade.d => AppColors.eventColor(context, const Color(0xFFB6B0C4)),
      TrialGrade.c => const Color(0xFF8BD8B9),
      TrialGrade.b => const Color(0xFF78B7FF),
      TrialGrade.a => const Color(0xFFF4C95D),
      TrialGrade.s => AppColors.eventColor(context, const Color(0xFFE987FF)),
      TrialGrade.sPlus => Colors.white,
    };
    return PopScope(
      canPop: false,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 390),
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
              decoration: BoxDecoration(
                gradient: AppColors.panelGradient(context,
                    fallback: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF392465), Color(0xFF1C1237)])),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: AppColors.gold, width: 1.5),
                boxShadow: [
                  BoxShadow(
                      color: color.withValues(alpha: .35), blurRadius: 38),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    completion.simulated
                        ? strings.pick(
                            'TEST EVENT · SIMULATED', 'TESTEVENT · GESIMULEERD')
                        : completion.testEvent
                            ? strings.pick('TEST EVENT · TRIAL COMPLETE',
                                'TESTEVENT · PROEF VOLTOOID')
                            : strings.pick('TRIAL COMPLETE', 'PROEF VOLTOOID'),
                    style: const TextStyle(
                      color: Color(0xFFFFE08A),
                      fontSize: 11,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 158,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: .06, end: 1),
                          duration: const Duration(milliseconds: 1050),
                          curve: Curves.elasticOut,
                          builder: (_, scale, child) => Transform.scale(
                            scale: scale,
                            child: child,
                          ),
                          child: Image.asset(
                            _trialGradeAsset(reward.grade),
                            key: const Key('trial-result-grade'),
                            width: 154,
                            height: 154,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                            semanticLabel: 'Trial grade $grade',
                          ),
                        ),
                      ],
                    ),
                  ),
                  TweenAnimationBuilder<double>(
                    key: const Key('trial-result-score'),
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 760),
                    curve: Curves.elasticOut,
                    builder: (_, progress, child) => Transform.rotate(
                      angle: (1 - progress) * -pi * 1.25,
                      child: Transform.scale(
                        scale: .18 + progress * .82,
                        child: child,
                      ),
                    ),
                    child: Text(
                      '${completion.score} ${strings.pick('points', 'punten')}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (completion.newDragonBest) ...[
                    const SizedBox(height: 6),
                    Text(
                      strings.pick('NEW $dragonName RECORD!',
                          'NIEUW RECORD VOOR $dragonName!'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFFFE08A),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  if (completion.simulated) ...[
                    Text(
                      strings.pick(
                        'Preview only: these rewards and this score were not added to your permanent production account.',
                        'Alleen preview: deze beloningen en score zijn niet aan je permanente productieaccount toegevoegd.',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFFFE08A),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .09),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      children: [
                        if (reward.coins > 0)
                          _RewardLine(
                            icon: GameIconKind.coin,
                            label:
                                '+${reward.coins} ${strings.pick('coins', 'munten')}',
                          ),
                        _RewardLine(
                          icon: GameIconKind.experience,
                          label: '+${reward.xp} XP',
                        ),
                        for (final expertise in reward.expertiseRewards.entries)
                          _RewardLine(
                            icon:
                                GameIconSprite.forTrainingFocus(expertise.key),
                            label:
                                '+${expertise.value} ${_focusLabel(strings, expertise.key)}',
                          ),
                        if (chest != null)
                          _RewardLine(
                            icon: GameIconKind.chest,
                            label: strings.chestLabel(chest),
                          ),
                        if (reward.relic case final relic?)
                          _RelicRewardLine(
                            relic: relic,
                            label: strings.relicName(relic),
                          ),
                        if (reward.emote case final emote?)
                          _EmoteRewardLine(
                            emote: emote,
                            label: emote.label(strings.languageCode),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: const Key('trial-result-continue'),
                      onPressed: onContinue,
                      child: Text(strings.pick('Continue', 'Verder')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _trialGradeAsset(TrialGrade grade) => switch (grade) {
      TrialGrade.d => 'assets/images/ui/trials/grade_d.png',
      TrialGrade.c => 'assets/images/ui/trials/grade_c.png',
      TrialGrade.b => 'assets/images/ui/trials/grade_b.png',
      TrialGrade.a => 'assets/images/ui/trials/grade_a.png',
      TrialGrade.s => 'assets/images/ui/trials/grade_s.png',
      TrialGrade.sPlus => 'assets/images/ui/trials/grade_s_plus.png',
    };

class _RewardLine extends StatelessWidget {
  const _RewardLine({required this.icon, required this.label});

  final GameIconKind icon;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            GameIconSprite(icon, size: 27),
            const SizedBox(width: 9),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
}

class _RelicRewardLine extends StatelessWidget {
  const _RelicRewardLine({required this.relic, required this.label});

  final MysticRelic relic;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Image.asset(relic.assetPath, width: 27, height: 27),
            const SizedBox(width: 9),
            Text(
              '+1 $label',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
}

class _EmoteRewardLine extends StatelessWidget {
  const _EmoteRewardLine({required this.emote, required this.label});

  final DragonEmoteDefinition emote;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        key: Key('trial-emote-reward-${emote.id}'),
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            DragonEmoteSprite(emote: emote, size: 34),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                '+1 $label',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      );
}

class _CavernFlightGame extends StatefulWidget {
  const _CavernFlightGame(
      {required this.offer, required this.dragon, this.controller});

  final TrialGameplayController? controller;
  final TrialOffer offer;
  final TrialDragon dragon;

  @override
  State<_CavernFlightGame> createState() => _CavernFlightGameState();
}

class _CavernFlightGameState extends State<_CavernFlightGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late final CavernFlightGame _game;
  Duration? _lastTick;
  Size _gameSize = Size.zero;
  bool _started = false, _finishing = false, _crashArcStarted = false;
  int _runMs = 0;
  List<FlightObstacle> get _obstacles => _game.obstacles;
  bool get _ended => _game.ended;
  double get _dragonY => _game.dragonY;
  double get _velocity => _started ? _game.velocity : 0;
  double get _elapsed => _game.elapsed;
  int get _score => _game.score;

  @override
  void initState() {
    super.initState();
    _game = widget.controller?.model.cavern ??
        CavernFlightGame(
            seed: widget.offer.id.hashCode,
            spirit: widget.dragon.trainingFor(TrainingFocus.spirit));
    _ticker = createTicker(_tick);
    if (widget.controller == null) _ticker.start();
    widget.controller?.addListener(_verifiedFrame);
  }

  void _verifiedFrame() {
    if (!mounted) return;
    setState(() {});
    if (_ended) unawaited(_finishAfterCrash());
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_verifiedFrame);
    _ticker.dispose();
    super.dispose();
  }

  void _tick(Duration elapsed) {
    final previous = _lastTick;
    _lastTick = elapsed;
    if (!_started || _ended || previous == null || _gameSize.isEmpty) return;
    _runMs += (elapsed - previous).inMilliseconds;
    final passed = _game.passed;
    _game.advanceTo(_runMs);
    if (_game.passed != passed || _ended) {
      unawaited(HavenAudio.play(HavenSound.uiConfirm));
    }
    setState(() {});
    if (_ended) unawaited(_finishAfterCrash());
  }

  Future<void> _finishAfterCrash() async {
    if (_finishing) return;
    _finishing = true;
    // Hold the exact collision frame long enough to register the mistake,
    // then let the dragon arc upward and fall out before granting anything.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    setState(() => _crashArcStarted = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    if (widget.controller != null) return;
    await _finishTrial(
      context,
      offer: widget.offer,
      dragon: widget.dragon,
      score: _score,
    );
  }

  void _flap() {
    if (_ended) return;
    if (!_started) {
      _started = true;
      _lastTick = null;
      unawaited(HavenAudio.play(HavenSound.adventureStart));
    }
    if (widget.controller case final controller?) {
      controller.start();
      controller.input(TrialControl.flap);
    } else {
      _game.flap(_runMs);
    }
    unawaited(HavenAudio.play(HavenSound.uiConfirm));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return _TrialScaffold(
      title: strings.pick(
        widget.offer.definition.titleEn,
        widget.offer.definition.titleNl,
      ),
      focus: TrainingFocus.spirit,
      score: _score,
      best: widget.dragon.trialBest(widget.offer.kind.name),
      child: LayoutBuilder(
        builder: (context, constraints) {
          _gameSize = Size(constraints.maxWidth, constraints.maxHeight);
          return GestureDetector(
            key: const Key('cavern-flight-game'),
            behavior: HitTestBehavior.opaque,
            onTap: _flap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/ui/trials/trial_cavern_background.webp',
                  fit: BoxFit.cover,
                ),
                _CavernObstacleSprites(
                  obstacles: _obstacles,
                  elapsed: _elapsed,
                ),
                CustomPaint(
                  painter: _CavernPainter(
                    elapsed: _elapsed,
                    spirit: widget.dragon.trainingFor(TrainingFocus.spirit),
                  ),
                ),
                Positioned(
                  left: constraints.maxWidth * .24 - 48,
                  top: constraints.maxHeight * _dragonY - 48,
                  child: Semantics(
                    key: _crashArcStarted
                        ? const Key('cavern-crash-arc-active')
                        : _ended
                            ? const Key('cavern-crash-freeze')
                            : const Key('cavern-flight-dragon'),
                    container: true,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: _crashArcStarted ? 1 : 0),
                      duration: _crashArcStarted
                          ? const Duration(milliseconds: 900)
                          : Duration.zero,
                      curve: Curves.easeInOutCubic,
                      builder: (_, progress, child) => Transform.translate(
                        offset: Offset(
                          66 * progress,
                          -72 * sin(pi * progress) + 132 * progress * progress,
                        ),
                        child: Transform.rotate(
                          angle: progress * 1.05,
                          child: child,
                        ),
                      ),
                      child: _FlightDragonSprite(
                        dragon: widget.dragon,
                        elapsed: _elapsed,
                        velocity: _velocity,
                        flying: _started,
                        crashed: _ended,
                      ),
                    ),
                  ),
                ),
                if (!_started)
                  _StartOverlay(
                    title: strings.pick('Tap to flap', 'Tik om te vliegen'),
                    body: strings.pick(
                      'Fly through every opening. Spirit subtly reduces your real hitbox.',
                      'Vlieg door iedere opening. Spirit verkleint subtiel je echte hitbox.',
                    ),
                    icon: Icons.touch_app_rounded,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FlightDragonSprite extends StatelessWidget {
  const _FlightDragonSprite({
    required this.dragon,
    required this.elapsed,
    required this.velocity,
    required this.flying,
    required this.crashed,
  });

  final TrialDragon dragon;
  final double elapsed;
  final double velocity;
  final bool flying;
  final bool crashed;

  @override
  Widget build(BuildContext context) {
    // Four beats use three purpose-built wing sprites: up, middle, down,
    // middle. The selected dragon remains visible at the common wing hinge.
    final beat = flying ? (elapsed * 8).floor() % 4 : 1;
    final frame = crashed ? 2 : const [0, 1, 2, 1][beat];
    final lift = switch (frame) { 0 => -3.0, 2 => 3.0, _ => 0.0 };
    final bodyOffset = switch (frame) { 0 => 18.0, 2 => -14.0, _ => 1.0 };
    final bodySize = switch (dragon.stage) {
      DragonStage.hatchling => 46.0,
      DragonStage.wyrmling => 52.0,
      DragonStage.ascended => 58.0,
      DragonStage.egg => 44.0,
    };
    final bank = crashed ? .34 : velocity.clamp(-.6, .7) * .32;
    return Semantics(
      label: 'Animated flight sprite for ${dragon.displayName}',
      child: Transform.translate(
        offset: Offset(crashed ? 10 : 0, lift),
        child: Transform.rotate(
          angle: bank,
          child: Transform.scale(
            scale: crashed ? .94 : 1,
            child: SizedBox.square(
              dimension: 96,
              child: ColorFiltered(
                colorFilter: crashed
                    ? const ColorFilter.mode(
                        Color(0xFFB8A5CB), BlendMode.modulate)
                    : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    _FlightWingFrame(frame: frame),
                    Transform.translate(
                      offset: Offset(0, bodyOffset),
                      child: DragonArt(
                        height: bodySize,
                        animate: false,
                        stageKey: dragon.stageKey,
                        lineageId: dragon.lineageId,
                        evolutionPath: dragon.activeEvolutionPath,
                        prismatic: dragon.prismatic,
                        sinister: dragon.sinister,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FlightWingFrame extends StatelessWidget {
  const _FlightWingFrame({required this.frame});

  final int frame;

  @override
  Widget build(BuildContext context) => ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: 288,
          maxWidth: 288,
          minHeight: 96,
          maxHeight: 96,
          child: Transform.translate(
            offset: Offset(-96.0 * frame, 0),
            child: Image.asset(
              'assets/images/ui/trials/trial_flight_wings.png',
              width: 288,
              height: 96,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      );
}

class _CavernPainter extends CustomPainter {
  const _CavernPainter({
    required this.elapsed,
    required this.spirit,
  });

  final double elapsed;
  final int spirit;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x44120C29), Color(0x552C1746), Color(0x660C1026)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, background);
    final particlePaint = Paint()
      ..color =
          spirit >= 200 ? const Color(0xA8A7FFF0) : const Color(0x6552C9DD)
      ..strokeWidth = spirit >= 200 ? 2 : 1;
    for (var index = 0; index < 13; index++) {
      final x = ((index * 83 + elapsed * 62) % size.width);
      final y = (index * 47.0) % size.height;
      canvas.drawLine(Offset(x, y), Offset(x + 12, y - 2), particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CavernPainter oldDelegate) => true;
}

class _CavernObstacleSprites extends StatelessWidget {
  const _CavernObstacleSprites({
    required this.obstacles,
    required this.elapsed,
  });

  final List<FlightObstacle> obstacles;
  final double elapsed;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          // The artwork deliberately fans out beyond the real .13-wide
          // collision column. Keep that gameplay column unchanged, while
          // centring a broader silhouette over it so the crystal formations
          // read as substantial cave obstacles instead of thin needles.
          final width = size.width * .22;
          return ClipRect(
            child: Stack(
              children: [
                for (final obstacle in obstacles) ...[
                  Positioned(
                    left: (obstacle.x - .045) * size.width,
                    top: 0,
                    width: width,
                    height: max(
                      1.0,
                      (obstacle.gapAt(elapsed) - obstacle.halfGap) *
                          size.height,
                    ),
                    child: Image.asset(
                      'assets/images/ui/trials/trial_stalactite.png',
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                  Positioned(
                    left: (obstacle.x - .045) * size.width,
                    top: (obstacle.gapAt(elapsed) + obstacle.halfGap) *
                        size.height,
                    bottom: 0,
                    width: width,
                    child: Image.asset(
                      'assets/images/ui/trials/trial_stalagmite.png',
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      );
}

class _StartOverlay extends StatelessWidget {
  const _StartOverlay({
    required this.title,
    required this.body,
    required this.icon,
  });

  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: Colors.black.withValues(alpha: .58),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 310),
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.eventColor(context, const Color(0xEE2A1E50)),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: AppColors.gold),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: AppColors.gold, size: 44),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFDCD2F4), height: 1.3),
                ),
              ],
            ),
          ),
        ),
      );
}

class _RuinBreakerGame extends StatefulWidget {
  const _RuinBreakerGame(
      {required this.offer, required this.dragon, this.controller});

  final TrialGameplayController? controller;
  final TrialOffer offer;
  final TrialDragon dragon;

  @override
  State<_RuinBreakerGame> createState() => _RuinBreakerGameState();
}

class _RuinBreakerGameState extends State<_RuinBreakerGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration? _lastTick;
  late final RuinBreakerGame _game;
  int _runMs = 0;
  bool _started = false, _barFading = false;
  bool get _locked => _game.locked;
  bool get _ended => _game.ended;
  bool get _impact => _game.locked;
  bool get _isGap => _game.isGap;
  int get _round => _game.round;
  int get _score => _game.score;
  int get _combo => _game.combo;
  int get _misses => _game.misses;
  double get _meter => _game.meter;
  String get _feedback => _game.feedback;

  static const _obstacles = [
    ('Rock', 'Rots', 100),
    ('Reinforced Rock', 'Versterkte rots', 140),
    ('Ancient Wall', 'Oude muur', 190),
    ('Crystal Formation', 'Kristalformatie', 250),
    ('Giant Boulder', 'Reuzenkei', 340),
  ];

  @override
  void initState() {
    super.initState();
    _game = widget.controller?.model.ruin ??
        RuinBreakerGame(might: widget.dragon.trainingFor(TrainingFocus.might));
    _ticker = createTicker(_tick);
    if (widget.controller == null) _ticker.start();
    widget.controller?.addListener(_verifiedFrame);
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_verifiedFrame);
    _ticker.dispose();
    super.dispose();
  }

  void _verifiedFrame() {
    if (!mounted) return;
    setState(() {});
    if (_ended) unawaited(_finish());
  }

  void _tick(Duration elapsed) {
    final previous = _lastTick;
    _lastTick = elapsed;
    if (!_started || _ended || previous == null) return;
    _runMs += (elapsed - previous).inMilliseconds;
    _game.advanceTo(_runMs);
    setState(() {});
    if (_ended) unawaited(_finish());
  }

  void _start() {
    if (_started) return;
    _started = true;
    _lastTick = null;
    widget.controller?.start();
    unawaited(HavenAudio.play(HavenSound.adventureStart));
    setState(() {});
  }

  void _strike() {
    if (!_started) {
      _start();
      return;
    }
    if (_locked || _ended) return;
    if (widget.controller case final controller?) {
      controller.input(TrialControl.strikeRuin);
    } else if (!_game.strike(_runMs)) {
      return;
    }
    unawaited(HavenAudio.play(HavenSound.uiConfirm));
    setState(() {});
  }

  Future<void> _finish() async {
    if (_barFading) return;
    setState(() => _barFading = true);
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    if (widget.controller != null) return;
    await _finishTrial(context,
        offer: widget.offer, dragon: widget.dragon, score: _score);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final obstacle = _obstacles[_round % _obstacles.length];
    return _TrialScaffold(
      title: strings.pick(
        widget.offer.definition.titleEn,
        widget.offer.definition.titleNl,
      ),
      focus: TrainingFocus.might,
      score: _score,
      best: widget.dragon.trialBest(widget.offer.kind.name),
      child: GestureDetector(
        key: const Key('ruin-breaker-game'),
        behavior: HitTestBehavior.opaque,
        onTap: _strike,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/ui/trials/trial_ruin_background.webp',
              fit: BoxFit.cover,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xFA120C29)],
                  stops: [.25, .72],
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 22,
              child: Column(
                children: [
                  AnimatedContainer(
                    key: const Key('ruin-attempts-left'),
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: _misses >= 2
                          ? const Color(0xD69B263C)
                          : AppColors.eventColor(
                              context, const Color(0xD62A1A51)),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _misses >= 2
                            ? const Color(0xFFFF9BAA)
                            : const Color(0x88FFE08A),
                      ),
                      boxShadow: const [
                        BoxShadow(color: Colors.black38, blurRadius: 12),
                      ],
                    ),
                    child: Text(
                      '${strings.pick('SCORING TURNS LEFT', 'SCOREBEURTEN OVER')}: '
                      '${_ended ? 0 : max(0, 30 - _round)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        letterSpacing: .8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${strings.pick('Misses left', 'Missers over')}: '
                    '${max(0, 3 - _misses)}',
                    key: const Key('ruin-misses-left'),
                    style: const TextStyle(
                      color: Color(0xFFE9DDF8),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Text(
                      _feedback.isEmpty
                          ? (_isGap
                              ? strings.pick('CHASM — JUMP!', 'KLOOF — SPRING!')
                              : strings.pick(obstacle.$1, obstacle.$2))
                          : _feedback,
                      key: ValueKey('$_round-$_feedback'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _feedback.contains('PERFECT') ||
                                _feedback.contains('STREAK')
                            ? AppColors.gold
                            : Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        shadows: const [Shadow(blurRadius: 10)],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  AnimatedScale(
                    scale: _impact ? 1.12 : 1,
                    duration: const Duration(milliseconds: 120),
                    child: _RuinDragonSprite(
                      dragon: widget.dragon,
                      impact: _impact,
                      success: _feedback.contains('PERFECT') ||
                          _feedback.contains('SMASH') ||
                          _feedback.contains('CLEAR'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedOpacity(
                    key: const Key('ruin-power-meter-fade'),
                    opacity: _barFading ? 0 : 1,
                    duration: const Duration(seconds: 1),
                    curve: Curves.easeIn,
                    child: _PowerMeter(value: _meter),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Spacer(),
                      Text(
                        _combo == 0
                            ? ''
                            : '${strings.pick('Combo', 'Combo')} x$_combo',
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!_started)
              _StartOverlay(
                title: strings.pick(
                    'Tap for the perfect hit', 'Tik voor de perfecte slag'),
                body: strings.pick(
                  'Stop the moving marker in the center. Watch out for chasms.',
                  'Stop de bewegende marker in het midden. Let op kloven.',
                ),
                icon: Icons.flash_on_rounded,
              ),
          ],
        ),
      ),
    );
  }
}

class _RuinDragonSprite extends StatelessWidget {
  const _RuinDragonSprite({
    required this.dragon,
    required this.impact,
    required this.success,
  });

  final TrialDragon dragon;
  final bool impact;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final hatchling = dragon.stage == DragonStage.hatchling;
    final ascended = dragon.stage == DragonStage.ascended;
    final lunge = impact ? (ascended ? 26.0 : 14.0) : 0.0;
    return SizedBox(
      height: 88,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (impact && success)
            Transform.scale(
              scale: ascended ? 1.35 : .82,
              child: const Icon(
                Icons.brightness_7_rounded,
                size: 82,
                color: Color(0x77FFE28A),
              ),
            ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 115),
            curve: Curves.easeOutBack,
            transform: Matrix4.identity()
              ..translateByDouble(lunge, impact ? 3 : 0, 0, 1)
              ..rotateZ(impact && hatchling ? .12 : 0),
            child: DragonArt(
              height: ascended ? 100 : 88,
              animate: !impact,
              stageKey: dragon.stageKey,
              lineageId: dragon.lineageId,
              evolutionPath: dragon.activeEvolutionPath,
              prismatic: dragon.prismatic,
              sinister: dragon.sinister,
            ),
          ),
        ],
      ),
    );
  }
}

class _PowerMeter extends StatelessWidget {
  const _PowerMeter({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 62,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/ui/trials/trial_reaction_bar.png',
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                Positioned(
                  left: (width - 50) * value,
                  top: 4,
                  child: Semantics(
                    label: 'Might timing marker',
                    image: true,
                    child: Image.asset(
                      'assets/images/ui/trials/trial_might_marker.png',
                      key: const Key('ruin-power-meter-marker'),
                      width: 50,
                      height: 54,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
}

class _RuneweaverGame extends StatefulWidget {
  const _RuneweaverGame(
      {required this.offer, required this.dragon, this.controller});

  final TrialGameplayController? controller;
  final TrialOffer offer;
  final TrialDragon dragon;

  @override
  State<_RuneweaverGame> createState() => _RuneweaverGameState();
}

class _RuneweaverGameState extends State<_RuneweaverGame> {
  late final RuneweaverGame _game;
  Timer? _ticker;
  bool _started = false, _resultStarting = false;
  List<int> get _sequence => _game.sequence;
  List<int> get _positions => _game.positions;
  bool get _showing => _game.showing;
  bool get _accepting => _started && _game.accepting;
  int? get _litRune => _game.litRune;
  int? get _echoRune => _showing ? null : _game.echoRune;
  int? get _wrongRune => _game.wrongRune;
  int get _rounds => _game.rounds;
  static const _runeKeys = ['fire', 'water', 'moon', 'star', 'wind'];

  @override
  void initState() {
    super.initState();
    _game = widget.controller?.model.runes ??
        RuneweaverGame(
            seed: widget.offer.id.hashCode ^ (widget.dragon as Pet).hatchSeed,
            arcana: widget.dragon.trainingFor(TrainingFocus.arcana));
    widget.controller?.addListener(_verifiedFrame);
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_verifiedFrame);
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _finishAfter(Duration delay) async {
    if (_resultStarting) return;
    _resultStarting = true;
    _ticker?.cancel();
    setState(() {});
    await Future<void>.delayed(delay);
    if (!mounted) return;
    if (widget.controller != null) return;
    await _finishTrial(context,
        offer: widget.offer, dragon: widget.dragon, score: _rounds);
  }

  void _verifiedFrame() {
    if (!mounted) return;
    if (_showing && _litRune != null && _litRune != _previousLit) {
      unawaited(HavenAudio.play(HavenSound.uiConfirm));
    }
    _previousLit = _litRune;
    setState(() {});
    if (_game.ended) unawaited(_finishAfter(const Duration(seconds: 1)));
  }

  int? _previousLit;
  void _start() {
    if (_started) return;
    _started = true;
    unawaited(HavenAudio.play(HavenSound.adventureStart));
    if (widget.controller case final controller?) {
      controller.start();
      setState(() {});
      return;
    }
    _ticker = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      if (!mounted || _game.ended) return;
      final previous = _game.litRune;
      _game.advanceTo(timer.tick * 10);
      if (_showing && _game.litRune != null && _game.litRune != previous) {
        unawaited(HavenAudio.play(HavenSound.uiConfirm));
      }
      setState(() {});
    });
    setState(() {});
  }

  void _tapRune(int rune) {
    if (!_accepting) return;
    if (widget.controller case final controller?) {
      controller.input(TrialControl.tapRune, rune);
    } else if (!_game.tap(rune, _game.milliseconds)) {
      return;
    }
    unawaited(HavenAudio.play(HavenSound.uiConfirm));
    setState(() {});
    if (_game.ended) unawaited(_finishAfter(const Duration(seconds: 1)));
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return _TrialScaffold(
      title: strings.pick(
        widget.offer.definition.titleEn,
        widget.offer.definition.titleNl,
      ),
      focus: TrainingFocus.arcana,
      score: _rounds,
      best: widget.dragon.trialBest(widget.offer.kind.name),
      child: GestureDetector(
        key: const Key('runeweaver-game'),
        behavior: HitTestBehavior.opaque,
        onTap: _started ? null : _start,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/ui/trials/trial_rune_background.webp',
              fit: BoxFit.cover,
            ),
            ColoredBox(
                color: AppColors.eventColor(context, const Color(0xAA100A25))),
            Column(
              children: [
                const SizedBox(height: 14),
                Text(
                  _showing
                      ? strings.pick('WATCH THE RUNES', 'KIJK NAAR DE RUNEN')
                      : _accepting
                          ? strings.pick('WEAVE THE SEQUENCE', 'WEEF DE REEKS')
                          : strings.pick('ARCANE SURGE', 'ARCANE SURGE'),
                  style: const TextStyle(
                    color: Color(0xFFFFE08A),
                    letterSpacing: 1.3,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '${strings.pick('Sequence', 'Reeks')} ${_sequence.length} · '
                  '${strings.pick('Completed', 'Voltooid')} $_rounds',
                  style: const TextStyle(color: Colors.white70),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 13,
                    runSpacing: 13,
                    children: [
                      for (final rune in _positions)
                        _RuneButton(
                          key: Key('rune-$rune'),
                          runeKey: _runeKeys[rune],
                          lit: _litRune == rune,
                          echo: _echoRune == rune,
                          error: _wrongRune == rune,
                          enabled: _accepting,
                          onTap: () => _tapRune(rune),
                        ),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 104,
                  child: DragonArt(
                    height: 104,
                    stageKey: widget.dragon.stageKey,
                    lineageId: widget.dragon.lineageId,
                    evolutionPath: widget.dragon.activeEvolutionPath,
                    prismatic: widget.dragon.prismatic,
                    sinister: widget.dragon.sinister,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
            if (!_started)
              _StartOverlay(
                title: strings.pick(
                    'Tap to awaken the gate', 'Tik om de poort te wekken'),
                body: strings.pick(
                  'Watch each rune, then reproduce the complete sequence.',
                  'Bekijk iedere rune en herhaal daarna de volledige reeks.',
                ),
                icon: Icons.auto_awesome_rounded,
              ),
          ],
        ),
      ),
    );
  }
}

class _RuneButton extends StatelessWidget {
  const _RuneButton({
    super.key,
    required this.runeKey,
    required this.lit,
    required this.echo,
    required this.error,
    required this.enabled,
    required this.onTap,
  });

  final String runeKey;
  final bool lit;
  final bool echo;
  final bool error;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AnimatedScale(
        scale: error ? 1.18 : (lit ? 1.13 : 1),
        duration: const Duration(milliseconds: 130),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(99),
          child: AnimatedContainer(
            key: error ? Key('rune-error-$runeKey') : null,
            duration: const Duration(milliseconds: 120),
            width: 82,
            height: 82,
            padding: EdgeInsets.all(error ? 3 : 0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: error ? const Color(0xBBFF173D) : Colors.transparent,
              border: error
                  ? Border.all(color: const Color(0xFFFFD5DC), width: 3)
                  : null,
              boxShadow: error
                  ? const [
                      BoxShadow(
                        color: Color(0xFFFF173D),
                        blurRadius: 24,
                        spreadRadius: 5,
                      ),
                    ]
                  : null,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 145),
              switchInCurve: Curves.easeOutBack,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              ),
              child: Opacity(
                key: ValueKey('$runeKey-$lit-$echo'),
                opacity: echo && !lit ? .78 : 1,
                child: ColorFiltered(
                  colorFilter: error
                      ? const ColorFilter.mode(
                          Color(0xFFFF284B),
                          BlendMode.modulate,
                        )
                      : const ColorFilter.mode(
                          Colors.transparent,
                          BlendMode.dst,
                        ),
                  child: Image.asset(
                    'assets/images/ui/trials/rune_$runeKey${lit || echo ? '_lit' : ''}.png',
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    semanticLabel: '$runeKey rune',
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

String _focusLabel(AppStrings strings, TrainingFocus focus) => switch (focus) {
      TrainingFocus.might => strings.pick('Might', 'Kracht'),
      TrainingFocus.arcana => 'Arcana',
      TrainingFocus.spirit => strings.pick('Spirit', 'Geest'),
    };
