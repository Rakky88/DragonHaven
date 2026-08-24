class OnlineConfig {
  const OnlineConfig({required this.url, required this.publishableKey});

  factory OnlineConfig.fromEnvironment() => const OnlineConfig(
        url: String.fromEnvironment(
          'SUPABASE_URL',
          defaultValue: 'https://tnzathhutuwmohmjfrlo.supabase.co',
        ),
        publishableKey: String.fromEnvironment(
          'SUPABASE_PUBLISHABLE_KEY',
          defaultValue: 'sb_publishable_SllXjneKVmDAgtBGgkSgOg_tOJmYkX4',
        ),
      );

  final String url;
  final String publishableKey;

  bool get isConfigured =>
      Uri.tryParse(url)?.hasScheme == true && publishableKey.trim().isNotEmpty;
}
