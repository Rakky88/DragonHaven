import 'package:flutter_test/flutter_test.dart';

import 'package:dragon_haven/config/online_config.dart';

void main() {
  test('official builds have a usable public online configuration by default',
      () {
    final config = OnlineConfig.fromEnvironment();

    expect(config.isConfigured, isTrue);
    expect(config.environment, OnlineEnvironment.production);
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

  test('staging can never silently fall back to the production server', () {
    expect(
      const OnlineConfig(
        url: OnlineConfig.productionUrl,
        publishableKey: OnlineConfig.productionPublishableKey,
        environment: OnlineEnvironment.staging,
      ).configurationIssue,
      'non_production_uses_production_server',
    );
    expect(
      const OnlineConfig(
        url: 'https://dragonhaven-staging.supabase.co',
        publishableKey: 'sb_publishable_staging-example',
        environment: OnlineEnvironment.staging,
      ).isConfigured,
      isTrue,
    );
  });

  test('only explicit local hosts are accepted for local development', () {
    expect(
      const OnlineConfig(
        url: 'http://127.0.0.1:54321',
        publishableKey: 'sb_publishable_local-example',
        environment: OnlineEnvironment.local,
      ).isConfigured,
      isTrue,
    );
    expect(
      const OnlineConfig(
        url: 'http://untrusted.example.test',
        publishableKey: 'sb_publishable_local-example',
        environment: OnlineEnvironment.local,
      ).isConfigured,
      isFalse,
    );
  });
}
