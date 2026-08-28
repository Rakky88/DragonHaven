import 'dart:collection';

import 'package:uuid/uuid.dart';

enum DiagnosticOutcome { success, failure }

class DiagnosticEvent {
  const DiagnosticEvent({
    required this.operation,
    required this.correlationId,
    required this.outcome,
    required this.startedAt,
    required this.duration,
    this.errorCode,
  });

  final String operation;
  final String correlationId;
  final DiagnosticOutcome outcome;
  final DateTime startedAt;
  final Duration duration;
  final String? errorCode;

  String get supportCode => DiagnosticIds.supportCode(correlationId);

  Map<String, Object> toSafeJson() => {
        'operation': operation,
        'correlationId': correlationId,
        'supportCode': supportCode,
        'outcome': outcome.name,
        'startedAt': startedAt.toUtc().toIso8601String(),
        'durationMs': duration.inMilliseconds,
        if (errorCode != null) 'errorCode': errorCode!,
      };
}

abstract interface class DiagnosticReporter {
  void record(DiagnosticEvent event);

  List<DiagnosticEvent> get recentEvents;
}

class NoopDiagnosticReporter implements DiagnosticReporter {
  const NoopDiagnosticReporter();

  @override
  void record(DiagnosticEvent event) {}

  @override
  List<DiagnosticEvent> get recentEvents => const [];
}

/// A deliberately small, in-memory diagnostic buffer.
///
/// Events contain no request parameters, account data, e-mail addresses,
/// tokens or game state. A future external monitoring adapter can consume the
/// same safe event shape without changing the online feature code.
class BufferedDiagnosticReporter implements DiagnosticReporter {
  BufferedDiagnosticReporter({this.capacity = 100})
      : assert(capacity > 0, 'Diagnostic capacity must be positive.');

  final int capacity;
  final ListQueue<DiagnosticEvent> _events = ListQueue<DiagnosticEvent>();

  @override
  void record(DiagnosticEvent event) {
    if (_events.length == capacity) _events.removeFirst();
    _events.addLast(event);
  }

  @override
  List<DiagnosticEvent> get recentEvents =>
      List<DiagnosticEvent>.unmodifiable(_events);
}

abstract final class DiagnosticIds {
  static String create() => const Uuid().v4();

  static String supportCode(String correlationId) {
    final compact = correlationId.replaceAll('-', '').toUpperCase();
    if (compact.length >= 8) return compact.substring(0, 8);
    return compact.padRight(8, '0');
  }
}
