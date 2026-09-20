import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

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

  /// The old subtree can still be mounted until the next frame after a lease
  /// is retired. Async navigation must check current authority, not just mounted.
  static bool isCurrentGameplay(BuildContext context) =>
      context
          .getInheritedWidgetOfExactType<_GameplayAuthority>()
          ?.isCurrent() ??
      true;

  @override
  State<CanonicalAccountGate<T>> createState() =>
      _CanonicalAccountGateState<T>();
}

class _CanonicalAccountGateState<T> extends State<CanonicalAccountGate<T>>
    with WidgetsBindingObserver {
  late final CanonicalAccountBootstrap<T> _bootstrap;
  AppLifecycleState _lifecycle = AppLifecycleState.resumed;
  Timer? _heartbeat;
  StreamSubscription<dynamic>? _network;
  bool? _connected;

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
    _heartbeat = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_connected != false) unawaited(_bootstrap.verifyConnection());
    });
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      _network = const EventChannel('nl.dragonhaven.app/network')
          .receiveBroadcastStream()
          .listen((value) {
        if (value is! bool || value == _connected) return;
        final previous = _connected;
        _connected = value;
        if (!value || previous == false) unawaited(_bootstrap.synchronize());
      }, onError: (Object _) {
        // Desktop/tests have no native signal. Server verification remains required.
      });
    }
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
    _heartbeat?.cancel();
    unawaited(_network?.cancel());
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
        key: ObjectKey(game),
        child: _GameplayAuthority(
          isCurrent: () => mounted && identical(_bootstrap.gameplay, game),
          child: widget.gameplayBuilder(context, game),
        ));
  }
}

class _GameplayAuthority extends InheritedWidget {
  const _GameplayAuthority({required this.isCurrent, required super.child});
  final bool Function() isCurrent;
  @override
  bool updateShouldNotify(_GameplayAuthority oldWidget) => false;
}
