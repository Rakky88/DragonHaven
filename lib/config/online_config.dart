enum OnlineEnvironment { production, staging, local, invalid }

class OnlineConfig {
  const OnlineConfig({
    required this.url,
    required this.publishableKey,
    this.environment = OnlineEnvironment.production,
  });

  factory OnlineConfig.fromEnvironment() {
    const environmentName = String.fromEnvironment(
      'DRAGONHAVEN_ENVIRONMENT',
      defaultValue: 'production',
    );
    return const OnlineConfig(
      url: String.fromEnvironment(
        'SUPABASE_URL',
        defaultValue: 'https://tnzathhutuwmohmjfrlo.supabase.co',
      ),
      publishableKey: String.fromEnvironment(
        'SUPABASE_PUBLISHABLE_KEY',
        defaultValue: 'sb_publishable_SllXjneKVmDAgtBGgkSgOg_tOJmYkX4',
      ),
      environment: environmentName == 'staging'
          ? OnlineEnvironment.staging
          : environmentName == 'local'
              ? OnlineEnvironment.local
              : environmentName == 'production'
                  ? OnlineEnvironment.production
                  : OnlineEnvironment.invalid,
    );
  }

  static const productionUrl = 'https://tnzathhutuwmohmjfrlo.supabase.co';
  static const productionPublishableKey =
      'sb_publishable_SllXjneKVmDAgtBGgkSgOg_tOJmYkX4';

  final String url;
  final String publishableKey;
  final OnlineEnvironment environment;

  String? get configurationIssue {
    final uri = Uri.tryParse(url);
    if (environment == OnlineEnvironment.invalid) {
      return 'unknown_online_environment';
    }
    final validScheme = environment == OnlineEnvironment.local
        ? uri?.scheme == 'http' || uri?.scheme == 'https'
        : uri?.scheme == 'https';
    final validLocalHost = environment != OnlineEnvironment.local ||
        const {'localhost', '127.0.0.1', '10.0.2.2'}.contains(uri?.host);
    if (uri == null ||
        !validScheme ||
        !validLocalHost ||
        uri.host.isEmpty ||
        publishableKey.trim().isEmpty) {
      return 'online_configuration_incomplete';
    }
    if (environment != OnlineEnvironment.production &&
        uri.toString() == productionUrl) {
      return 'non_production_uses_production_server';
    }
    return null;
  }

  bool get isConfigured => configurationIssue == null;
}
