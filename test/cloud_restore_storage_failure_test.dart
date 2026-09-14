import 'package:dragon_haven/providers/household_provider.dart';
import 'package:dragon_haven/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

class _RejectCheckpointStore extends InMemorySharedPreferencesStore {
  _RejectCheckpointStore() : super.empty();
  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (key.contains(StorageService.restoreCheckpointPrefix)) return false;
    return super.setValue(valueType, key, value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('failed checkpoint write refuses restore and preserves current save',
      () async {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance = _RejectCheckpointStore();
    final game = HouseholdProvider();
    await game.updateAccountName('Unsynced local progress');
    game.pet.coins = 23456;
    final old = game.exportState()..['accountName'] = 'Old cloud';
    expect(await game.restoreCloudState(old, recoveryOwner: 'owner'), isFalse);
    expect(game.accountName, 'Unsynced local progress');
    expect(game.pet.coins, 23456);
    expect((await StorageService.load())!['accountName'],
        'Unsynced local progress');
    game.dispose();
  });
}
