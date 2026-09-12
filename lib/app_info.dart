abstract final class AppInfo {
  static const creator = 'Rick Groot';
  static const builtYear = '2026';
  static const buildNumber = int.fromEnvironment(
    'DRAGONHAVEN_BUILD_NUMBER',
    defaultValue: 10083,
  );
  static const version = String.fromEnvironment(
    'DRAGONHAVEN_APP_VERSION',
    defaultValue: '0.05.33',
  );
  static const displayVersion = 'v$version';
}
