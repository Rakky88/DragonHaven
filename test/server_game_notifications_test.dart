import 'package:dragon_haven/providers/household_provider.dart';
import 'package:dragon_haven/services/canonical_game_snapshot.dart';
import 'package:dragon_haven/services/server_game_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/canonical_ui_server.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('restored reminders use original server deadlines and account choices',
      () {
    final now = DateTime.utc(2026, 9, 7, 12);
    final game = HouseholdProvider(persistenceEnabled: false, clock: () => now);
    game.onboardingComplete = true;
    final server = CanonicalUiServer(game.exportState());
    game.dispose();
    CanonicalGameSnapshot read() => CanonicalGameSnapshot.parse(server.wire,
        expectedOwner: CanonicalUiServer.owner);
    final view = read();
    final plans = ServerGameNotifications.plan(view);
    final egg = plans.singleWhere((r) => r['kind'] == 'egg');
    expect(DateTime.parse(egg['at']), view.nest!.hatchAt);
    expect(egg['id'], contains(view.ownerId));
    expect(ServerGameNotifications.plan(read()), plans);
    server.state['enabledNotificationCategories'] = <String>[];
    expect(
        ServerGameNotifications.plan(read()).where((r) => r['kind'] == 'egg'),
        isEmpty);
    server.now = view.nest!.hatchAt!.add(const Duration(seconds: 1));
    expect(
        ServerGameNotifications.plan(read()).where((r) => r['kind'] == 'egg'),
        isEmpty);
  });
}
