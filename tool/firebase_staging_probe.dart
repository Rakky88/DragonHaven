import 'dart:convert';
import 'dart:io';

import 'package:dragon_haven/config/firebase_config.dart';
import 'package:dragon_haven/config/online_config.dart';
import 'package:dragon_haven/services/firebase_monitoring.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Explicit staging-only entry point. Does not load or modify the game save.
/// The token stays in app-private storage for the operator's device rehearsal.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = HavenFirebaseConfig.fromEnvironment();
  if (!config.allowDebugCollection ||
      config.environment != OnlineEnvironment.staging ||
      config.projectId != 'dragonhaven-prod-rakky88') {
    throw StateError('staging_probe_configuration_required');
  }
  final firebase = await HavenFirebase.initialize(config);
  if (!firebase.available) {
    throw StateError('staging_probe_initialization_failed');
  }
  final directory = await getApplicationDocumentsDirectory();
  await FirebaseMessaging.instance.setAutoInitEnabled(true);
  final token = await FirebaseMessaging.instance.getToken();
  if (token == null) throw StateError('staging_probe_token_missing');
  await File('${directory.path}/firebase-staging-probe-token.txt')
      .writeAsString(token, flush: true);
  final trace = FirebasePerformance.instance.newTrace('dh_staging_probe');
  await trace.start();
  trace.putAttribute('environment', 'staging');
  await (firebase.reporter as FirebaseMonitoringReporter).recordSafeError(
      'staging_monitoring_probe',
      fatal: false,
      stack: StackTrace.current);
  await trace.stop();
  await File('${directory.path}/firebase-staging-probe-status.json')
      .writeAsString(
          jsonEncode({
            'project': config.projectId,
            'token_available': true,
            'nonfatal_recorded_locally': true,
            'trace_recorded_locally': true
          }),
          flush: true);
  runApp(MaterialApp(
      home: Scaffold(
          body: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Text(
        'DragonHaven Firebase staging test\nMonitoring recorded; push device ready.',
        textAlign: TextAlign.center),
    TextButton(
        onPressed: () => FirebaseCrashlytics.instance.crash(),
        child: const Text('Staging crash probe')),
  ])))));
}
