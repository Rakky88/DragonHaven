import 'package:dragon_haven/services/audio_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('reasserting a music scene reaches Android as a playback keepalive',
      () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('nl.dragonhaven.app/audio'),
      (call) async {
        calls.add(call);
        return true;
      },
    );
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('nl.dragonhaven.app/audio'), null));

    await HavenAudio.applyPreferences(
      musicEnabled: true,
      soundEffectsEnabled: true,
    );
    await HavenAudio.setMusicScene(HavenMusicScene.towerDay);
    await HavenAudio.setMusicScene(HavenMusicScene.towerDay);

    expect(calls.where((call) => call.method == 'setMusicScene'), hasLength(2));
    expect(calls.last.arguments, {'id': 'tower_day'});
  });
}
