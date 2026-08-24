class OnlineConfig {
  const OnlineConfig({required this.url, required this.publishableKey});

  factory OnlineConfig.fromEnvironment() => const OnlineConfig(
        url: String.fromEnvironment('SUPABASE_URL'),
        publishableKey: String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
      );

  final String url;
  final String publishableKey;

  bool get isConfigured =>
      Uri.tryParse(url)?.hasScheme == true && publishableKey.trim().isNotEmpty;
}
