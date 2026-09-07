import 'online_config.dart';

/// Deployment configuration, never a credential or an automatic billing switch.
class HavenFirebaseConfig {
  const HavenFirebaseConfig({
    required this.enabled,
    required this.projectId,
    required this.environment,
    this.allowDebugCollection = false,
  });

  factory HavenFirebaseConfig.fromEnvironment() => HavenFirebaseConfig(
        enabled: const bool.fromEnvironment('DRAGONHAVEN_FIREBASE_ENABLED'),
        projectId:
            const String.fromEnvironment('DRAGONHAVEN_FIREBASE_PROJECT_ID'),
        environment: OnlineConfig.fromEnvironment().environment,
        allowDebugCollection:
            const bool.fromEnvironment('DRAGONHAVEN_FIREBASE_STAGING_PROBE'),
      );

  final bool enabled;
  final String projectId;
  final OnlineEnvironment environment;
  final bool allowDebugCollection;

  bool get isValid =>
      enabled &&
      RegExp(r'^[a-z][a-z0-9-]{4,28}[a-z0-9]$').hasMatch(projectId) &&
      (environment == OnlineEnvironment.production ||
          environment == OnlineEnvironment.staging);

  bool collectInBuild({required bool release}) =>
      isValid &&
      (release ||
          (allowDebugCollection && environment == OnlineEnvironment.staging));
}
