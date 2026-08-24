import 'package:flutter_test/flutter_test.dart';

import 'package:dragon_haven/config/online_config.dart';

void main() {
  test('official builds have a usable public online configuration by default',
      () {
    final config = OnlineConfig.fromEnvironment();

    expect(config.isConfigured, isTrue);
    expect(config.url, 'https://tnzathhutuwmohmjfrlo.supabase.co');
    expect(config.publishableKey, startsWith('sb_publishable_'));
  });

  test('configuration validation rejects incomplete values', () {
    expect(
      const OnlineConfig(url: '', publishableKey: '').isConfigured,
      isFalse,
    );
    expect(
      const OnlineConfig(
        url: 'not-a-url',
        publishableKey: 'sb_publishable_example',
      ).isConfigured,
      isFalse,
    );
  });
}
