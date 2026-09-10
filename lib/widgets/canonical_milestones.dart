import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/achievement.dart';
import '../models/game_presentation.dart';
import '../screens/canonical_dragons_screen.dart';
import '../screens/pet_screen.dart';
import '../services/canonical_game_actions.dart';
import '../services/canonical_game_session.dart';
import '../services/canonical_game_snapshot.dart';
import 'achievement_reveal.dart';
import 'trade_reveal.dart';
import 'shop_economy_scope.dart';
import 'ui_bits.dart';

/// The reward already exists on the server. Closing a reveal only acknowledges
/// its saved presentation; process death leaves it available to show again.
Future<bool> showCanonicalMilestone(
    BuildContext context, CanonicalPresentationView event) async {
  final session = context.read<CanonicalGameSession>();
  final owner = session.snapshot?.ownerId;
  final epoch = session.connection.sessionEpoch;
  bool current() =>
      owner != null &&
      session.snapshot?.ownerId == owner &&
      session.connection.sessionEpoch == epoch;
  Widget guard(Widget child) =>
      _MilestoneOwner(owner: owner!, epoch: epoch, child: child);
  if (!current() || !session.canAct) return false;
  switch (event.type) {
    case GamePresentationType.hatch:
      final dragon = session.snapshot!.dragon(event.dragonId!);
      if (dragon == null) return false;
      await showDragonHatch(context, dragon,
          guard: guard,
          continueLabel: dragon.name.trim().isEmpty
              ? null
              : AppStrings.of(context).pick('Continue', 'Doorgaan'),
          onContinue: (dialogContext) async {
        if (!current() || !session.canAct) return;
        final latest = session.snapshot!.dragon(dragon.id);
        if (latest == null) return;
        if (latest.name.trim().isEmpty) {
          await nameCanonicalDragon(
              dialogContext, latest, owner!, CanonicalGameActions(session));
        }
        if (dialogContext.mounted &&
            current() &&
            session.snapshot!.dragon(dragon.id)?.name.trim().isNotEmpty ==
                true) {
          Navigator.pop(dialogContext);
        }
      });
    case GamePresentationType.evolution:
      final dragon = session.snapshot!.dragon(event.dragonId!);
      if (dragon == null) return false;
      await showDragonEvolution(context, dragon,
          previousStageKey: event.previousStageKey ?? 'nestDragon',
          guard: guard);
    case GamePresentationType.achievement:
      final achievement = achievementCatalog
          .where((a) => a.id == event.achievementId)
          .firstOrNull;
      if (achievement == null) return false;
      await showAchievementReveal(context, achievement, guard: guard);
    case GamePresentationType.trade:
      await showCanonicalTradeReveal(context, event.sent!, event.received!,
          guard: guard);
  }
  if (!context.mounted || !current() || !session.canAct) return false;
  await CanonicalGameActions(session).completePresentation(event.id);
  return current();
}

class _MilestoneOwner extends StatelessWidget {
  const _MilestoneOwner(
      {required this.owner, required this.epoch, required this.child});
  final String owner;
  final int epoch;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final session = context.watch<CanonicalGameSession>();
    if (session.snapshot?.ownerId == owner &&
        session.connection.sessionEpoch == epoch) {
      return child;
    }
    final s = AppStrings.of(context);
    return AlertDialog(
        content: Text(gameConnectionMessage(s, 'game_account_changed')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(s.pick('Close', 'Sluiten')))
        ]);
  }
}

class CanonicalMilestones extends StatefulWidget {
  const CanonicalMilestones({super.key, required this.child});
  final Widget child;
  @override
  State<CanonicalMilestones> createState() => _CanonicalMilestonesState();
}

class _CanonicalMilestonesState extends State<CanonicalMilestones> {
  bool _showing = false;
  String? _deferred;
  int? _epoch;
  Future<void> _show(CanonicalPresentationView event) async {
    if (_showing || !mounted) return;
    final session = context.read<CanonicalGameSession>();
    if (!session.canAct || ModalRoute.of(context)?.isCurrent != true) return;
    setState(() => _showing = true);
    try {
      final completed = await showCanonicalMilestone(context, event);
      _deferred = completed ? null : event.id;
    } on CanonicalGameException catch (error) {
      _deferred = event.id;
      if (mounted) {
        showAppSnackBar(
            context, gameConnectionMessage(AppStrings.of(context), error.code));
      }
    } finally {
      if (mounted) setState(() => _showing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<CanonicalGameSession>();
    if (_epoch != session.connection.sessionEpoch) {
      _epoch = session.connection.sessionEpoch;
      _deferred = null;
    }
    final view = session.snapshot;
    final event = view?.presentations.firstOrNull;
    final available = event != null &&
        view!.trialAttempt == null &&
        view.schoolAttempt == null;
    if (available && !_showing && _deferred != event.id && session.canAct) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _show(event);
      });
    }
    return Column(children: [
      if (available && !_showing && _deferred == event.id)
        TextButton(
            onPressed: session.canAct ? () => _show(event) : null,
            child: Text(AppStrings.of(context).pick('Continue', 'Doorgaan'))),
      Expanded(child: widget.child),
    ]);
  }
}
