import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/firebase_config.dart';
import 'diagnostic_reporter.dart';
import 'monitoring_policy.dart';

/// Firebase is optional at build time. The native manifest also starts with
/// collection disabled, including before Dart starts and on failed setup.
class HavenFirebase {
  HavenFirebase._(this.app, this.reporter);

  final FirebaseApp? app;
  final DiagnosticReporter reporter;
  bool get available => app != null;
  static const consentKey = 'dragon_haven_diagnostics_opt_in_v1';
  static final diagnosticsEnabled = ValueNotifier<bool>(false);
  static FirebaseMonitoringReporter? _reporter;

  static Future<void> setDiagnosticsConsent(bool enabled) async {
    // Persist first: native startup reads the same choice before Firebase runs.
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setBool(consentKey, enabled)) {
      throw StateError('Privacy preference could not be saved.');
    }
    diagnosticsEnabled.value = enabled;
    _reporter?.enabled = enabled;
    if (_reporter == null) return;
    try {
      await Future.wait([
        FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(enabled),
        FirebasePerformance.instance.setPerformanceCollectionEnabled(enabled),
      ]);
    } finally {
      if (!enabled) await FirebaseCrashlytics.instance.deleteUnsentReports();
    }
  }

  static Future<HavenFirebase> initialize(HavenFirebaseConfig config) async {
    final buffer = BufferedDiagnosticReporter();
    final prefs = await SharedPreferences.getInstance();
    final consent = prefs.getBool(consentKey) ?? false;
    diagnosticsEnabled.value = consent;
    if (!config.collectInBuild(release: kReleaseMode) ||
        kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android) {
      return HavenFirebase._(null, buffer);
    }
    try {
      final app =
          await Firebase.initializeApp().timeout(const Duration(seconds: 8));
      if (app.options.projectId != config.projectId) {
        return HavenFirebase._(null, buffer);
      }
      final reporter = FirebaseMonitoringReporter(buffer)..enabled = consent;
      try {
        await FirebaseCrashlytics.instance
            .setCrashlyticsCollectionEnabled(consent);
        await FirebasePerformance.instance
            .setPerformanceCollectionEnabled(consent);
        if (!consent) await FirebaseCrashlytics.instance.deleteUnsentReports();
      } on Object {
        await Future.wait([
          FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false),
          FirebasePerformance.instance.setPerformanceCollectionEnabled(false),
        ]);
        rethrow;
      }
      reporter.installErrorHandlers();
      _reporter = reporter;
      return HavenFirebase._(app, reporter);
    } on Object {
      // Optional diagnostics cannot turn a missing configuration or a provider
      // outage into a startup failure. Never print SDK/configuration errors.
      return HavenFirebase._(null, buffer);
    }
  }
}

class FirebaseMonitoringReporter
    implements DiagnosticReporter, DiagnosticTracingReporter {
  FirebaseMonitoringReporter(this._buffer);

  final DiagnosticReporter _buffer;
  bool _enabled = false;
  bool get enabled => _enabled;
  set enabled(bool value) {
    _enabled = value;
    if (!value) {
      _traces.clear();
      _lastFailure.clear();
    }
  }

  final Map<String, Future<Trace?>> _traces = {};
  final Map<String, DateTime> _lastFailure = {};

  @override
  List<DiagnosticEvent> get recentEvents => _buffer.recentEvents;

  @override
  void operationStarted(String operation, String correlationId) {
    if (!enabled) return;
    if (_traces.length >= 32 || _traces.containsKey(correlationId)) return;
    _traces[correlationId] = _start(MonitoringPolicy.family(operation));
  }

  Future<Trace?> _start(String family) async {
    try {
      if (!enabled) return null;
      final trace = FirebasePerformance.instance.newTrace('dh_$family');
      await trace.start();
      return trace;
    } on Object {
      return null;
    }
  }

  @override
  void record(DiagnosticEvent event) {
    _buffer.record(event);
    if (!enabled) return;
    final trace = _traces.remove(event.correlationId);
    if (trace != null) unawaited(_finish(trace, event));
    if (event.outcome == DiagnosticOutcome.failure) {
      final category = MonitoringPolicy.failure(event.errorCode);
      final now = DateTime.now();
      final last = _lastFailure[category];
      // An outage must not flood the crash service with every failed poll.
      if (last == null || now.difference(last) >= const Duration(minutes: 5)) {
        _lastFailure[category] = now;
        unawaited(recordSafeError('online_$category', fatal: false));
      }
    }
  }

  Future<void> _finish(Future<Trace?> pending, DiagnosticEvent event) async {
    try {
      final trace = await pending;
      if (trace == null || !enabled) return;
      for (final attribute in MonitoringPolicy.attributes(event).entries) {
        trace.putAttribute(attribute.key, attribute.value);
      }
      trace.setMetric('operation_duration_ms',
          event.duration.inMilliseconds.clamp(0, 600000));
      await trace.stop();
    } on Object {
      // The local diagnostic buffer remains available during reporting errors.
    }
  }

  Future<void> recordSafeError(String category,
      {required bool fatal, StackTrace? stack}) async {
    if (!enabled) return;
    try {
      await FirebaseCrashlytics.instance.recordError(
        StateError(MonitoringPolicy.errorCategory(category)),
        MonitoringPolicy.safeStack(stack),
        fatal: fatal,
        printDetails: false,
      );
    } on Object {
      // Reporting an error must never create another unhandled error.
    }
  }

  void installErrorHandlers() {
    final previousFlutter = FlutterError.onError;
    FlutterError.onError = (details) {
      unawaited(recordSafeError('flutter_framework_error',
          fatal: true, stack: details.stack));
      previousFlutter?.call(details);
    };
    final previousPlatform = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stack) {
      unawaited(recordSafeError('flutter_unhandled_error',
          fatal: true, stack: stack));
      return previousPlatform?.call(error, stack) ?? true;
    };
  }
}
