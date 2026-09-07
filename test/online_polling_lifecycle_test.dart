import 'package:dragon_haven/models/social.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:dragon_haven/providers/online_account_provider.dart';
import 'package:dragon_haven/services/social_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('backgrounding stops periodic reads; push keeps a slow fallback',
      (tester) async {
    final repository = PollingRepository();
    final game = HouseholdProvider(persistenceEnabled: false);
    final online = OnlineAccountProvider(
        repository: repository,
        inventorySnapshot: () => OnlineInventorySnapshot.fromGame(game));
    addTearDown(online.dispose);
    addTearDown(game.dispose);
    online.setAppInForeground(true);
    await tester.pump(const Duration(seconds: 15));
    expect(repository.polls, 1);
    online.setAppInForeground(false);
    await tester.pump(const Duration(minutes: 5));
    expect(repository.polls, 1);
    online.setPushAvailable(true);
    await tester.pump(const Duration(minutes: 1));
    expect(repository.polls, 1,
        reason: 'enabling push cannot restart hidden polling');
    online.setAppInForeground(true);
    await tester.pump(const Duration(seconds: 59));
    expect(repository.polls, 1);
    await tester.pump(const Duration(seconds: 1));
    expect(repository.polls, 2);
    online.setPushAvailable(false);
    await tester.pump(const Duration(seconds: 15));
    expect(repository.polls, 3);
    online.setAppInForeground(false);
  });
}

class PollingRepository extends DisabledSocialRepository {
  int polls = 0;
  @override
  bool get isConfigured => true;
  @override
  bool get isSignedIn => true;
  @override
  Future<List<SocialNotification>> loadSocialNotifications() async {
    polls++;
    return [];
  }
}
