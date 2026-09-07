import 'diagnostic_reporter.dart';

/// Only fixed categories leave the device; no raw exception, RPC argument,
/// account identity, chat, save, token or correlation ID is exported.
abstract final class MonitoringPolicy {
  static String errorCategory(String category) => const {
        'flutter_framework_error',
        'flutter_unhandled_error',
        'online_timeout',
        'online_authentication',
        'online_rate_limit',
        'online_network',
        'online_conflict',
        'online_none',
        'online_other',
        'staging_monitoring_probe',
      }.contains(category)
          ? category
          : 'other';

  static const operationFamilies = {
    'auth',
    'cloud_save',
    'conclave',
    'friends',
    'group',
    'messages',
    'seasonal',
    'social',
    'trade',
    'trial',
    'economy',
    'push',
  };

  static String family(String operation) {
    final candidate = operation.split('.').first;
    return operationFamilies.contains(candidate) ? candidate : 'other';
  }

  static String failure(String? code) => switch (code) {
        'online_timeout' || 'economy_timeout' => 'timeout',
        'online_login_required' ||
        'not_authenticated' ||
        'invalid_credentials' ||
        'email_not_confirmed' =>
          'authentication',
        'rate_limit_exceeded' || 'online_rate_limited' => 'rate_limit',
        'network_error' || 'online_unavailable' => 'network',
        'cloud_save_conflict' || 'economy_snapshot_changed' => 'conflict',
        null => 'none',
        _ => 'other',
      };

  static Map<String, String> attributes(DiagnosticEvent event) => {
        'operation_family': family(event.operation),
        'outcome': event.outcome.name,
        'failure_category': failure(event.errorCode),
      };

  static StackTrace safeStack(StackTrace? stack) {
    // Preserve code locations for symbols while excluding local user paths,
    // dynamic exception/context text and URLs from third-party data.
    final source = stack?.toString() ?? '';
    final locations = RegExp(
      r'(?:package:dragon_haven/|package:flutter/|dart:)[A-Za-z0-9_./:-]+',
    ).allMatches(source).take(40).map((match) => match.group(0)!);
    return StackTrace.fromString(locations.indexed
        .map((entry) => '#${entry.$1} appFrame (${entry.$2})')
        .join('\n'));
  }
}
