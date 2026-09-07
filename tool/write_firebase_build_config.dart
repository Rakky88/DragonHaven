import 'dart:convert';
import 'dart:io';

/// CI supplies client configuration through its protected environment. No
/// service-account credential is ever accepted as Android configuration.
void main(List<String> args) {
  if (args.length != 1 || !{'production', 'staging'}.contains(args.single)) {
    stderr.writeln('Expected production or staging.');
    exitCode = 1;
    return;
  }
  final environment = args.single;
  final supplied = Platform.environment['DRAGONHAVEN_FIREBASE_ANDROID_CONFIG'];
  final defines = <String, Object>{'DRAGONHAVEN_FIREBASE_ENABLED': false};
  try {
    if (supplied != null && supplied.trim().isNotEmpty) {
      final projects =
          jsonDecode(File('firebase-projects.json').readAsStringSync()) as Map;
      final config = jsonDecode(supplied) as Map;
      final project = projects[environment];
      if (config['private_key'] != null ||
          config['type'] == 'service_account' ||
          config['project_info']?['project_id'] != project ||
          !(config['client'] as List).any((client) =>
              client['client_info']?['android_client_info']?['package_name'] ==
              'nl.dragonhaven.app')) {
        throw const FormatException();
      }
      File('android/app/google-services.json')
          .writeAsStringSync(jsonEncode(config), flush: true);
      defines['DRAGONHAVEN_FIREBASE_ENABLED'] = true;
      defines['DRAGONHAVEN_FIREBASE_PROJECT_ID'] = project as String;
    }
    Directory('.tools').createSync(recursive: true);
    File('.tools/firebase-build-defines.json')
        .writeAsStringSync(jsonEncode(defines), flush: true);
    stdout.writeln(
        'Firebase build configuration validated: $environment; enabled=${defines['DRAGONHAVEN_FIREBASE_ENABLED']}');
  } on Object {
    stderr.writeln(
        'Firebase configuration is invalid for this build environment.');
    exitCode = 1;
  }
}
