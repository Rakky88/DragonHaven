abstract final class AppInfo {
  static const creator = 'Rick Groot';
  static const builtYear = '2026';
  static const buildNumber = int.fromEnvironment(
    'DRAGONHAVEN_BUILD_NUMBER',
    defaultValue: 10089,
  );
  static const version = String.fromEnvironment(
    'DRAGONHAVEN_APP_VERSION',
    defaultValue: '0.05.39',
  );
  static const displayVersion = 'v$version';
}
