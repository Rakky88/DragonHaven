import 'package:dragon_haven/services/diagnostic_reporter.dart';
import 'package:dragon_haven/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('diagnostic buffer is bounded and exposes only the safe event shape',
      () {
    final reporter = BufferedDiagnosticReporter(capacity: 2);
    for (var index = 0; index < 3; index++) {
      reporter.record(DiagnosticEvent(
        operation: 'test.operation.$index',
        correlationId: '12345678-0000-0000-0000-00000000000$index',
        outcome:
            index == 2 ? DiagnosticOutcome.failure : DiagnosticOutcome.success,
        startedAt: DateTime.utc(2026, 8, 28),
        duration: Duration(milliseconds: index + 1),
        errorCode: index == 2 ? 'safe_error_code' : null,
      ));
    }

    expect(reporter.recentEvents, hasLength(2));
    expect(reporter.recentEvents.first.operation, 'test.operation.1');
    expect(reporter.recentEvents.last.toSafeJson().keys, {
      'operation',
      'correlationId',
      'supportCode',
      'outcome',
      'startedAt',
      'durationMs',
      'errorCode',
    });
    expect(reporter.recentEvents.last.supportCode, '12345678');
  });

  test('cloud base revisions are stored separately for each account', () async {
    expect(await StorageService.loadCloudBaseRevision('keeper-a'), isNull);

    await StorageService.saveCloudBaseRevision('keeper-a', 3);
    await StorageService.saveCloudBaseRevision('keeper-b', 8);

    expect(await StorageService.loadCloudBaseRevision('keeper-a'), 3);
    expect(await StorageService.loadCloudBaseRevision('keeper-b'), 8);
  });

  test('automatic cloud backup cadence is stored per account', () async {
    final at = DateTime.utc(2026, 8, 28, 14, 30);
    expect(await StorageService.loadAutomaticCloudBackupAt('keeper-a'), isNull);

    await StorageService.saveAutomaticCloudBackupAt('keeper-a', at);

    expect(await StorageService.loadAutomaticCloudBackupAt('keeper-a'), at);
    expect(await StorageService.loadAutomaticCloudBackupAt('keeper-b'), isNull);
  });
}
