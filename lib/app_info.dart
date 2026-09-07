abstract final class AppInfo {
  static const creator = 'Rick Groot';
  static const builtYear = '2026';
  static const version = String.fromEnvironment(
    'DRAGONHAVEN_APP_VERSION',
    defaultValue: '0.05.16',
  );
  static const displayVersion = 'v$version';
}
