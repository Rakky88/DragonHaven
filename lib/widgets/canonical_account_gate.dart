import 'dart:async';

import 'package:flutter/widgets.dart';

import '../services/canonical_account_bootstrap.dart';

/// Owns the complete gameplay subtree, including its Navigator. Never place
/// account routes above this gate: they must disappear with their game lease.
class CanonicalAccountGate<T> extends StatefulWidget {
  const CanonicalAccountGate(
      {super.key,
      required this.createBootstrap,
      required this.gameplayBuilder,
      required this.statusBuilder});

  final CanonicalAccountBootstrap<T> Function(
      Future<void> Function() beforeRetire) createBootstrap;
  final Widget Function(BuildContext context, T gameplay) gameplayBuilder;
  final Widget Function(
          BuildContext context, CanonicalAccountBootstrap<T> bootstrap)
      statusBuilder;

  @override
  State<CanonicalAccountGate<T>> createState() =>
      _CanonicalAccountGateState<T>();
}

class _CanonicalAccountGateState<T> extends State<CanonicalAccountGate<T>>
    with WidgetsBindingObserver {
  late final CanonicalAccountBootstrap<T> _bootstrap;
  AppLifecycleState _lifecycle = AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    _lifecycle =
        WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;
    _bootstrap = widget.createBootstrap(() async {
      // A paused app cannot render a frame and exposes no interactive gameplay.
      if (mounted && _lifecycle == AppLifecycleState.resumed) {
        await WidgetsBinding.instance.endOfFrame;
      }
    });
    _bootstrap.addListener(_changed);
    WidgetsBinding.instance.addObserver(this);
    if (_lifecycle == AppLifecycleState.paused ||
        _lifecycle == AppLifecycleState.hidden ||
        _lifecycle == AppLifecycleState.detached) {
      unawaited(_bootstrap.setForeground(false));
    } else {
      unawaited(_bootstrap.synchronize());
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycle = state;
    // Transient system dialogs can make the app inactive without backgrounding.
    if (state == AppLifecycleState.inactive) return;
    unawaited(_bootstrap.setForeground(state == AppLifecycleState.resumed));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bootstrap.removeListener(_changed);
    _bootstrap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = _bootstrap.gameplay;
    if (game == null) return widget.statusBuilder(context, _bootstrap);
    return KeyedSubtree(
        key: ObjectKey(game), child: widget.gameplayBuilder(context, game));
  }
}
