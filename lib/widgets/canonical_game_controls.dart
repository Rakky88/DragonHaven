import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../services/canonical_game_session.dart';
import '../services/canonical_game_snapshot.dart';
import 'shop_economy_scope.dart';
import 'ui_bits.dart';

/// Each callback captures the displayed revision before any confirmation opens.
/// The session owns durable replay; a failed dialog never generates a retry.
class CanonicalActionButton extends StatefulWidget {
  const CanonicalActionButton(
      {super.key,
      required this.label,
      required this.action,
      this.primary = false,
      this.outlined = false,
      this.icon,
      this.confirmation,
      this.secondaryConfirmation});
  final String label;
  final bool primary, outlined;
  final IconData? icon;
  final Future<void> Function()? action;
  final String? confirmation, secondaryConfirmation;
  @override
  State<CanonicalActionButton> createState() => _CanonicalActionButtonState();
}

class _CanonicalActionButtonState extends State<CanonicalActionButton> {
  bool _busy = false;
  Future<void> _run() async {
    final action = widget.action;
    if (_busy || action == null) return;
    final session = context.read<CanonicalGameSession>();
    final owner = session.snapshot?.ownerId;
    final epoch = session.connection.sessionEpoch;
    setState(() => _busy = true);
    try {
      for (final message in [
        widget.confirmation,
        widget.secondaryConfirmation
      ]) {
        if (message == null) continue;
        if (!mounted ||
            !await confirmCanonicalAction(context, message,
                owner: owner, epoch: epoch)) {
          return;
        }
      }
      // This lock belongs to this button only; other controls can enqueue
      // their own actions while this receipt is pending.
      if (mounted &&
          session.connection.sessionEpoch == epoch &&
          session.snapshot?.ownerId == owner &&
          session.canAct) {
        await action();
      }
    } on CanonicalGameException catch (error) {
      if (mounted) {
        showAppSnackBar(
            context, gameConnectionMessage(AppStrings.of(context), error.code));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final onPressed = !_busy &&
            widget.action != null &&
            context.watch<CanonicalGameSession>().canAct
        ? _run
        : null;
    if (widget.primary) {
      return FilledButton.icon(
          onPressed: onPressed,
          icon: widget.icon == null ? null : Icon(widget.icon),
          label: Text(widget.label, textAlign: TextAlign.center));
    }
    if (widget.outlined) {
      final colors = Theme.of(context).colorScheme;
      final style = OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          foregroundColor: colors.primary,
          side: BorderSide(
              color: colors.primary.withValues(alpha: .34), width: 1.4),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800));
      if (widget.icon case final icon?) {
        return OutlinedButton.icon(
            onPressed: onPressed,
            style: style,
            icon: Icon(icon),
            label: Text(widget.label, textAlign: TextAlign.center));
      }
      return OutlinedButton(
          onPressed: onPressed,
          style: style,
          child: Text(widget.label, textAlign: TextAlign.center));
    }
    if (widget.icon case final icon?) {
      return FilledButton.tonalIcon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(widget.label, textAlign: TextAlign.center));
    }
    return FilledButton.tonal(
        onPressed: onPressed,
        child: Text(widget.label, textAlign: TextAlign.center));
  }
}

Future<bool> confirmCanonicalAction(BuildContext context, String message,
    {required String? owner, required int epoch}) async {
  return await showDialog<bool>(
          context: context,
          builder: (context) =>
              Consumer<CanonicalGameSession>(builder: (context, session, _) {
                final strings = AppStrings.of(context);
                final sameOwner = owner != null &&
                    session.snapshot?.ownerId == owner &&
                    session.connection.sessionEpoch == epoch;
                return AlertDialog(
                  title: Text(strings.pick('Confirm', 'Bevestigen')),
                  content: SingleChildScrollView(
                      child: Text(sameOwner
                          ? message
                          : gameConnectionMessage(
                              strings, 'game_account_changed'))),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(strings.pick('Cancel', 'Annuleren'))),
                    FilledButton(
                        onPressed: sameOwner && session.canAct
                            ? () => Navigator.pop(context, true)
                            : null,
                        child: Text(strings.pick('Confirm', 'Bevestigen')))
                  ],
                );
              })) ??
      false;
}

/// Clears visible entity information immediately on sign-out/account switch.
class CanonicalEntityDialog extends StatelessWidget {
  const CanonicalEntityDialog(
      {super.key, required this.ownerId, required this.builder});
  final String ownerId;
  final Widget Function(BuildContext, CanonicalGameSnapshot, bool) builder;
  @override
  Widget build(BuildContext context) {
    final session = context.watch<CanonicalGameSession>();
    final view = session.snapshot;
    if (view == null || view.ownerId != ownerId) {
      final strings = AppStrings.of(context);
      return AlertDialog(
          content: Text(gameConnectionMessage(strings, 'game_account_changed')),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(strings.pick('Close', 'Sluiten')))
          ]);
    }
    return builder(context, view, session.canAct);
  }
}
