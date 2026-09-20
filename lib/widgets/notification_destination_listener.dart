import 'dart:async';
import 'package:flutter/widgets.dart';
import '../services/notification_service.dart';
import 'canonical_account_gate.dart';

/// Notification intent outlives the gameplay Navigator while online authority
/// is rechecked. Acknowledge only after the current, visible shell handles it.
class NotificationDestinationListener extends StatefulWidget {
  const NotificationDestinationListener(
      {super.key, required this.onDestination, required this.child});
  final ValueChanged<HavenNotificationDestination> onDestination;
  final Widget child;
  @override
  State<NotificationDestinationListener> createState() =>
      _NotificationDestinationListenerState();
}

class _NotificationDestinationListenerState
    extends State<NotificationDestinationListener> with WidgetsBindingObserver {
  late final StreamSubscription<HavenNotificationDestination> _events;
  bool _scheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _events = HavenNotifications.navigationEvents.listen((_) => _schedule());
    _schedule();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _schedule();
  }

  void _schedule() {
    if (_scheduled || !mounted) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted || !CanonicalAccountGate.isCurrentGameplay(context)) return;
      final lifecycle = WidgetsBinding.instance.lifecycleState;
      if (lifecycle != null && lifecycle != AppLifecycleState.resumed) return;
      final request = HavenNotifications.pendingNavigation;
      if (request == null) return;
      widget.onDestination(request.destination);
      HavenNotifications.acknowledgeNavigation(request);
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_events.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
