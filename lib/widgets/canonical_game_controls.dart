import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../services/canonical_game_session.dart';
import '../services/canonical_game_snapshot.dart';
import 'game_icon_sprite.dart';
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
    OverlayEntry? serverActionOverlay;
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
        // Confirmed actions deliberately wait for the authoritative receipt.
        // Cover the whole app while that receipt is pending so the player
        // cannot accidentally enqueue a conflicting irreversible action.
        if (widget.confirmation != null ||
            widget.secondaryConfirmation != null) {
          serverActionOverlay = OverlayEntry(
              builder: (_) => const _CanonicalServerActionOverlay());
          Overlay.of(context, rootOverlay: true).insert(serverActionOverlay);
        }
        await action();
      }
    } on CanonicalGameException catch (error) {
      if (mounted) {
        showAppSnackBar(
            context, gameConnectionMessage(AppStrings.of(context), error.code));
      }
    } finally {
      serverActionOverlay?.remove();
      serverActionOverlay?.dispose();
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

class _CanonicalServerActionOverlay extends StatefulWidget {
  const _CanonicalServerActionOverlay();

  @override
  State<_CanonicalServerActionOverlay> createState() =>
      _CanonicalServerActionOverlayState();
}

class _CanonicalServerActionOverlayState
    extends State<_CanonicalServerActionOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1800))
    ..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final strings = AppStrings.of(context);
    return Material(
      color: Colors.transparent,
      child: Stack(children: [
        ModalBarrier(
            dismissible: false,
            color: colors.onSurface.withValues(alpha: .68),
            semanticsLabel: strings.pick(
                'Confirming with the server', 'Bevestigen met de server')),
        Center(
          child: Semantics(
            liveRegion: true,
            label: strings.pick('Sealing your choice with DragonHaven.',
                'Je keuze wordt bezegeld door DragonHaven.'),
            child: Container(
              key: const Key('canonical-server-action-overlay'),
              constraints: const BoxConstraints(maxWidth: 310),
              margin: const EdgeInsets.symmetric(horizontal: 28),
              padding: const EdgeInsets.fromLTRB(26, 24, 26, 22),
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [colors.surface, colors.primaryContainer]),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                      color: colors.tertiary.withValues(alpha: .8), width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: colors.primary.withValues(alpha: .42),
                        blurRadius: 32,
                        spreadRadius: 4)
                  ]),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(
                  width: 132,
                  height: 132,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      final turn = _controller.value * math.pi * 2;
                      final pulse = 1 + math.sin(turn * 2) * .055;
                      return Stack(alignment: Alignment.center, children: [
                        Transform.rotate(
                          angle: turn,
                          child: Container(
                            width: 112,
                            height: 112,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: SweepGradient(colors: [
                                  colors.primary.withValues(alpha: .05),
                                  colors.tertiary,
                                  colors.primary,
                                  colors.primary.withValues(alpha: .05),
                                ])),
                            child: const Padding(
                              padding: EdgeInsets.all(5),
                              child: DecoratedBox(
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle)),
                            ),
                          ),
                        ),
                        Transform.scale(
                            scale: pulse,
                            child: const GameIconSprite(
                                GameIconKind.draconomicon,
                                size: 76)),
                        for (var i = 0; i < 3; i++)
                          Transform.translate(
                            offset: Offset(
                                math.cos(turn + (i * math.pi * 2 / 3)) * 59,
                                math.sin(turn + (i * math.pi * 2 / 3)) * 59),
                            child: Icon(Icons.auto_awesome,
                                size: 15, color: colors.tertiary),
                          ),
                      ]);
                    },
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  strings.pick(
                      'Sealing your choice…', 'Je keuze wordt bezegeld…'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: colors.onSurface),
                ),
                const SizedBox(height: 7),
                Text(
                  strings.pick('DragonHaven is safely recording the result.',
                      'DragonHaven legt het resultaat veilig vast.'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                      minHeight: 7,
                      backgroundColor: colors.surface.withValues(alpha: .7),
                      color: colors.primary),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
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
