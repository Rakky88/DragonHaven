import 'dart:async';

import '../app_info.dart';

import 'canonical_game_snapshot.dart';

/// The adapter invokes execute-game-command with the active Supabase session.
/// Read-only; no local fallback can mint or guess missing server inventory.
class CanonicalGameReader {
  CanonicalGameReader(
      {required this.invoke,
      required this.currentOwner,
      required this.sessionEpoch,
      this.clientBuild = AppInfo.buildNumber,
      this.timeout = const Duration(seconds: 12)});

  final Future<Object?> Function(Map<String, dynamic>) invoke;
  final String? Function() currentOwner;
  // Increment on every account/session switch, including A -> B -> A.
  final int Function() sessionEpoch;
  final int clientBuild;
  final Duration timeout;

  Future<CanonicalGameSnapshot> fetch(String owner,
      {int minimumRevision = 0, int minimumRulesetRevision = 0}) async {
    final epoch = sessionEpoch();
    void requireSession() {
      if (currentOwner() != owner || sessionEpoch() != epoch) {
        throw const CanonicalGameException('game_account_changed');
      }
    }

    requireSession();
    final Object? response;
    try {
      response = await invoke({
        'protocol': 2,
        'clientBuild': clientBuild,
        'action': 'read_state'
      }).timeout(timeout);
    } on TimeoutException {
      throw const CanonicalGameException('game_snapshot_unavailable');
    }
    requireSession();
    return CanonicalGameSnapshot.parse(response,
        expectedOwner: owner,
        minimumRevision: minimumRevision,
        minimumRulesetRevision: minimumRulesetRevision);
  }
}
