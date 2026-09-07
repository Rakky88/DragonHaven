import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

const productionProjectRef = 'tnzathhutuwmohmjfrlo';
const productionUrl = 'https://$productionProjectRef.supabase.co';

const browsingOperations = <LoadOperation>[
  LoadOperation('get_online_snapshot', 50),
  LoadOperation('get_my_profile', 15),
  LoadOperation('list_my_cloud_game_save_revisions', 10),
  LoadOperation('list_group_adventures', 15),
  LoadOperation('list_conclaves', 10),
];

class LoadOperation {
  const LoadOperation(this.name, this.weight);

  final String name;
  final int weight;
}

class SyntheticCredential {
  const SyntheticCredential(this.email, this.password);

  final String email;
  final String password;
}

enum LoadNetworkFailure {
  connectionTimeout,
  responseTimeout,
  bodyTimeout,
  socketError,
  tlsError,
  protocolError,
  clientError,
}

class RequestResult {
  const RequestResult({
    required this.statusCode,
    required this.durationMs,
    required this.responseBytes,
    this.bodyBytes = const <int>[],
    this.networkFailure = false,
    this.networkFailureKind,
  });

  final int statusCode;
  final int durationMs;
  final int responseBytes;
  final List<int> bodyBytes;
  final bool networkFailure;
  final LoadNetworkFailure? networkFailureKind;

  bool get succeeded =>
      !networkFailure && statusCode >= 200 && statusCode < 300;
}

class OperationMetrics {
  final durationsMs = <int>[];
  final failures = <String, int>{};
  var responseBytes = 0;
  var successes = 0;

  int get requestCount => successes + failures.values.fold(0, (a, b) => a + b);

  void record(RequestResult result) {
    durationsMs.add(result.durationMs);
    responseBytes += result.responseBytes;
    if (result.succeeded) {
      successes++;
      return;
    }
    final key = result.networkFailure
        ? result.networkFailureKind?.name ?? 'network_error'
        : result.statusCode >= 500
            ? 'http_5xx'
            : result.statusCode == 429
                ? 'http_429'
                : result.statusCode == 401 || result.statusCode == 403
                    ? 'http_auth'
                    : 'http_other';
    failures.update(key, (value) => value + 1, ifAbsent: () => 1);
  }

  Map<String, Object> toJson() {
    final sorted = List<int>.from(durationsMs)..sort();
    return <String, Object>{
      'requests': requestCount,
      'successes': successes,
      'failures': requestCount - successes,
      'p50Ms': percentile(sorted, 50),
      'p95Ms': percentile(sorted, 95),
      'p99Ms': percentile(sorted, 99),
      'maxMs': sorted.isEmpty ? 0 : sorted.last,
      'responseBytes': responseBytes,
      'failureClasses': failures,
    };
  }
}

int percentile(List<int> sortedValues, int percentileValue) {
  if (sortedValues.isEmpty) return 0;
  if (percentileValue < 0 || percentileValue > 100) {
    throw ArgumentError.value(percentileValue, 'percentileValue');
  }
  final rank = (percentileValue / 100) * (sortedValues.length - 1);
  return sortedValues[rank.ceil()];
}

Map<String, Object> buildLoadPlan({
  required int virtualUsers,
  required int durationSeconds,
  required int rampUpSeconds,
  String appVersion = 'unknown',
  String migrationVersion = 'unknown',
}) {
  validateProfileShape(
    virtualUsers: virtualUsers,
    durationSeconds: durationSeconds,
    rampUpSeconds: rampUpSeconds,
  );
  return <String, Object>{
    'schemaVersion': 2,
    'kind': 'dragonhaven-staging-load-plan',
    'measurementMode': loadMeasurementMode,
    'loginSpacingMs': loginSpacing.inMilliseconds,
    'steadyStateSeconds': durationSeconds,
    'environment': 'staging',
    'productionTarget': false,
    'appVersion': appVersion,
    'applicationContractVersion': 1,
    'repositoryMigrationVersion': migrationVersion,
    'serverMigrationVersionVerified': false,
    'virtualUsers': virtualUsers,
    'uniqueConfirmedSyntheticAccountsRequired': virtualUsers,
    'durationSeconds': durationSeconds,
    'rampUpSeconds': rampUpSeconds,
    'thinkTimeSeconds': <String, int>{'minimum': 8, 'maximum': 20},
    'operations': <Map<String, Object>>[
      for (final operation in browsingOperations)
        <String, Object>{
          'name': operation.name,
          'weightPercent': operation.weight,
        },
    ],
    'perUserSetup': <String>['password_login', 'ensure_my_online_account'],
    'sequentialGate': virtualUsers == 1000
        ? 'requires a successful 100-user report with <=2% errors'
        : 'first load stage',
    'reportIncludes': <String>[
      'request count and success/error percentage',
      'p50/p95/p99/max latency per operation',
      'privacy-safe error classes',
      'response-byte estimate',
    ],
    'dashboardEvidenceStillRequired': <String>[
      'staging server migration parity with repositoryMigrationVersion',
      'peak database connections and CPU',
      'database/query latency and rate-limit observations',
      'provider egress and any query/index findings',
    ],
  };
}

void validateProfileShape({
  required int virtualUsers,
  required int durationSeconds,
  required int rampUpSeconds,
}) {
  if (virtualUsers != 100 && virtualUsers != 1000) {
    throw ArgumentError(
        'Only the audited 100- and 1000-user stages are allowed.');
  }
  if (durationSeconds < 60 || durationSeconds > 900) {
    throw ArgumentError('Duration must be between 60 and 900 seconds.');
  }
  if (rampUpSeconds < 10 || rampUpSeconds >= durationSeconds) {
    throw ArgumentError(
        'Ramp-up must be at least 10 seconds and shorter than the test.');
  }
  if (browsingOperations.fold(0, (sum, item) => sum + item.weight) != 100) {
    throw StateError('The operation mix must add up to 100%.');
  }
}

void validateExecutionTarget({
  required String url,
  required String projectRef,
  required String publishableKey,
}) {
  final normalizedUrl = url.trim().replaceFirst(RegExp(r'/$'), '');
  final normalizedRef = projectRef.trim();
  if (normalizedUrl == productionUrl || normalizedRef == productionProjectRef) {
    throw StateError('Production is a forbidden load-test target.');
  }
  if (!RegExp(r'^[a-z0-9]{20}$').hasMatch(normalizedRef) ||
      normalizedUrl != 'https://$normalizedRef.supabase.co') {
    throw StateError('The staging URL and project reference do not match.');
  }
  if (!publishableKey.startsWith('sb_publishable_')) {
    throw StateError('A staging publishable client key is required.');
  }
}

void validateBaselineReport(Map<String, Object?> report,
    {String? migrationVersion}) {
  if (report['kind'] != 'dragonhaven-staging-load-report' ||
      report['schemaVersion'] != 2 ||
      report['measurementMode'] != loadMeasurementMode ||
      report['environment'] != 'staging' ||
      report['warmupCompleted'] != true ||
      report['sessionsCoverMeasurement'] != true ||
      report['preparedUsers'] != 100 ||
      report['peakConcurrentBrowsingUsers'] != 100 ||
      (report['steadyStateSeconds'] as num? ?? 0) < 180 ||
      (report['minimumReadRequestsPerUser'] as num? ?? 0) < 1 ||
      report['productionTarget'] != false ||
      report['virtualUsers'] != 100 ||
      report['result'] != 'passed' ||
      report['authenticatedUsers'] != 100 ||
      report['activeUsers'] != 100 ||
      (migrationVersion != null &&
          report['repositoryMigrationVersion'] != migrationVersion)) {
    throw StateError(
        'The 1000-user stage requires a successful 100-user staging report.');
  }
  final readErrorRate = report['readErrorRatePercent'];
  if (readErrorRate is! num ||
      !readErrorRate.isFinite ||
      readErrorRate < 0 ||
      readErrorRate > 2) {
    throw StateError('The baseline read error gate failed.');
  }
  final errorRate = report['errorRatePercent'];
  if (errorRate is! num ||
      !errorRate.isFinite ||
      errorRate < 0 ||
      errorRate > 2) {
    throw StateError('The 100-user baseline exceeded the 2% error gate.');
  }
}

List<SyntheticCredential> parseCredentialPool(
    String rawJson, int requiredCount) {
  final decoded = jsonDecode(rawJson);
  final credentials = <SyntheticCredential>[];
  if (decoded is Map<String, dynamic> && decoded['accounts'] is List) {
    for (final item in decoded['accounts'] as List) {
      if (item is! Map) throw const FormatException('Invalid account entry.');
      credentials.add(SyntheticCredential(
        (item['email'] as Object? ?? '').toString().trim().toLowerCase(),
        (item['password'] as Object? ?? '').toString(),
      ));
    }
  } else if (decoded is Map<String, dynamic>) {
    final template = (decoded['emailTemplate'] as Object? ?? '').toString();
    final password = (decoded['password'] as Object? ?? '').toString();
    final count = decoded['count'];
    if (!template.contains('{index}') || count is! int) {
      throw const FormatException(
          'Credential template requires {index} and count.');
    }
    for (var index = 1; index <= count; index++) {
      credentials.add(SyntheticCredential(
        template.replaceAll('{index}', index.toString()).trim().toLowerCase(),
        password,
      ));
    }
  } else {
    throw const FormatException('Credential pool must be a JSON object.');
  }

  if (credentials.length < requiredCount) {
    throw StateError(
        'The credential pool has fewer unique accounts than virtual users.');
  }
  final seen = <String>{};
  final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  for (final credential in credentials.take(requiredCount)) {
    if (!emailPattern.hasMatch(credential.email) ||
        credential.password.length < 12) {
      throw StateError(
          'Every synthetic credential must be valid and use a 12+ character password.');
    }
    if (!seen.add(credential.email)) {
      throw StateError(
          'Every virtual user requires a unique synthetic account.');
    }
  }
  return credentials.take(requiredCount).toList(growable: false);
}

Future<RequestResult> postJson({
  required HttpClient client,
  required Uri uri,
  required Map<String, String> headers,
  required Map<String, Object?> body,
  bool retainBody = false,
  Duration timeout = const Duration(seconds: 30),
}) async {
  final stopwatch = Stopwatch()..start();
  HttpClientRequest? request;
  var timeoutKind = LoadNetworkFailure.connectionTimeout;
  try {
    request = await client.postUrl(uri).timeout(timeout);
    headers.forEach(request.headers.set);
    request.headers.contentType = ContentType.json;
    request.add(utf8.encode(jsonEncode(body)));
    timeoutKind = LoadNetworkFailure.responseTimeout;
    final response = await request.close().timeout(timeout);
    timeoutKind = LoadNetworkFailure.bodyTimeout;
    final bytes = await _readResponseBytes(response, timeout);
    stopwatch.stop();
    return RequestResult(
      statusCode: response.statusCode,
      durationMs: stopwatch.elapsedMilliseconds,
      responseBytes: bytes.length,
      bodyBytes: retainBody ? bytes : const <int>[],
    );
  } on Object catch (error) {
    request?.abort();
    stopwatch.stop();
    return RequestResult(
      statusCode: 0,
      durationMs: stopwatch.elapsedMilliseconds,
      responseBytes: 0,
      networkFailure: true,
      networkFailureKind: switch (error) {
        TimeoutException() => timeoutKind,
        SocketException() => LoadNetworkFailure.socketError,
        HandshakeException() => LoadNetworkFailure.tlsError,
        HttpException() => LoadNetworkFailure.protocolError,
        _ => LoadNetworkFailure.clientError,
      },
    );
  }
}

Future<List<int>> _readResponseBytes(
    HttpClientResponse response, Duration timeout) async {
  final completed = Completer<List<int>>();
  final bytes = <int>[];
  final timer = Timer(timeout, () {
    if (!completed.isCompleted) completed.completeError(TimeoutException(''));
  });
  final subscription =
      response.listen(bytes.addAll, onError: (Object error, StackTrace stack) {
    if (!completed.isCompleted) completed.completeError(error, stack);
  }, onDone: () {
    if (!completed.isCompleted) completed.complete(bytes);
  }, cancelOnError: true);
  try {
    return await completed.future;
  } finally {
    timer.cancel();
    await subscription.cancel();
  }
}

LoadOperation chooseOperation(Random random) {
  final roll = random.nextInt(100);
  var boundary = 0;
  for (final operation in browsingOperations) {
    boundary += operation.weight;
    if (roll < boundary) return operation;
  }
  return browsingOperations.last;
}

// Keep the password token endpoint below its per-IP refill rate. Setup and
// browsing are separate: the last user gets the full measured steady period.
const loginSpacing = Duration(milliseconds: 2200);
const loadMeasurementMode = 'preauthenticated_browsing';
typedef LoadRequest = Future<RequestResult> Function(Uri uri,
    Map<String, String> headers, Map<String, Object?> body, bool retainBody);

class PreparedLoadSession {
  const PreparedLoadSession(this.headers, this.expiresAt);
  final Map<String, String> headers;
  final DateTime expiresAt;
}

Future<List<PreparedLoadSession>> prepareLoadSessions({
  required String baseUrl,
  required String publishableKey,
  required List<SyntheticCredential> credentials,
  required LoadRequest request,
  required Map<String, OperationMetrics> metrics,
  DateTime Function()? clock,
  Future<void> Function(Duration)? pause,
}) async {
  final now = clock ?? () => DateTime.now().toUtc();
  final wait = pause ?? Future<void>.delayed;
  final sessions = <PreparedLoadSession>[];
  DateTime? previousLoginStartedAt;
  for (final credential in credentials) {
    if (previousLoginStartedAt != null) {
      final remaining =
          previousLoginStartedAt.add(loginSpacing).difference(now());
      if (remaining > Duration.zero) await wait(remaining);
    }
    previousLoginStartedAt = now();
    final login = await request(
        Uri.parse('$baseUrl/auth/v1/token?grant_type=password'),
        {'apikey': publishableKey},
        {'email': credential.email, 'password': credential.password},
        true);
    metrics.putIfAbsent('password_login', OperationMetrics.new).record(login);
    if (!login.succeeded) break; // A failed setup never becomes a partial load.
    String accessToken;
    DateTime expiry;
    try {
      final data =
          jsonDecode(utf8.decode(login.bodyBytes)) as Map<String, dynamic>;
      accessToken = data['access_token'] as String;
      final expiresAt = data['expires_at'];
      final expiresIn = data['expires_in'];
      expiry = expiresAt is int
          ? DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000, isUtc: true)
          : now().add(Duration(seconds: expiresIn as int));
      if (accessToken.isEmpty || !expiry.isAfter(now())) {
        throw const FormatException('Invalid session');
      }
    } on Object {
      metrics.putIfAbsent('login_contract', OperationMetrics.new).record(
          const RequestResult(
              statusCode: 0,
              durationMs: 0,
              responseBytes: 0,
              networkFailure: true));
      break;
    }
    final headers = {
      'apikey': publishableKey,
      'authorization': 'Bearer $accessToken'
    };
    final bootstrap = await request(
        Uri.parse('$baseUrl/rest/v1/rpc/ensure_my_online_account'),
        headers,
        {},
        false);
    metrics
        .putIfAbsent('ensure_my_online_account', OperationMetrics.new)
        .record(bootstrap);
    if (!bootstrap.succeeded) break;
    sessions.add(PreparedLoadSession(headers, expiry));
  }
  return sessions;
}

Future<Map<String, Object>> executeLoadProfile({
  required String baseUrl,
  required String publishableKey,
  required List<SyntheticCredential> credentials,
  required int durationSeconds,
  required int rampUpSeconds,
  required double maxErrorPercent,
  required String appVersion,
  required String migrationVersion,
  Future<void> Function()? onMeasurementStarted,
  LoadRequest? requestOverride,
  DateTime Function()? clock,
  Future<void> Function(Duration)? pause,
}) async {
  final now = clock ?? () => DateTime.now().toUtc();
  final wait = pause ?? Future<void>.delayed;
  final setupStartedAt = now();
  final metrics = <String, OperationMetrics>{};
  final setupClient = HttpClient()
    ..connectionTimeout = const Duration(seconds: 30);
  final sessions = await (() async {
    try {
      return await prepareLoadSessions(
          baseUrl: baseUrl,
          publishableKey: publishableKey,
          credentials: credentials,
          metrics: metrics,
          clock: now,
          pause: wait,
          request: requestOverride ??
              (uri, headers, body, retainBody) => postJson(
                  client: setupClient,
                  uri: uri,
                  headers: headers,
                  body: body,
                  retainBody: retainBody));
    } finally {
      setupClient.close(force: true);
    }
  })();
  final warmupDurationMs = now().difference(setupStartedAt).inMilliseconds;
  final browsingStartedAt = now();
  final endsAt =
      browsingStartedAt.add(Duration(seconds: rampUpSeconds + durationSeconds));
  final warmupCompleted = sessions.length == credentials.length;
  final sessionsCoverMeasurement = warmupCompleted &&
      sessions.every((session) =>
          session.expiresAt.isAfter(endsAt.add(const Duration(seconds: 30))));
  final readCounts = List<int>.filled(credentials.length, 0);
  var simultaneousUsers = 0;
  var peakUsers = 0;
  Future<void> runUser(int index) async {
    final rampDelayMs =
        ((index / sessions.length) * rampUpSeconds * 1000).round();
    await wait(Duration(milliseconds: rampDelayMs));
    final random = Random(830017 + index);
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 30)
      ..maxConnectionsPerHost = 2
      ..userAgent = 'DragonHaven-Staging-Load-Audit';
    simultaneousUsers++;
    peakUsers = max(peakUsers, simultaneousUsers);
    try {
      while (now().isBefore(endsAt)) {
        final operation = chooseOperation(random);
        final uri = Uri.parse('$baseUrl/rest/v1/rpc/${operation.name}');
        final result = requestOverride != null
            ? await requestOverride(uri, sessions[index].headers, {}, false)
            : await postJson(
                client: client,
                uri: uri,
                headers: sessions[index].headers,
                body: const {});
        metrics
            .putIfAbsent(operation.name, OperationMetrics.new)
            .record(result);
        readCounts[index]++;
        final remaining = endsAt.difference(now());
        if (remaining <= Duration.zero) break;
        final think = Duration(seconds: 8 + random.nextInt(13));
        await wait(remaining < think ? remaining : think);
      }
    } finally {
      simultaneousUsers--;
      client.close(force: true);
    }
  }

  if (sessionsCoverMeasurement) {
    await onMeasurementStarted?.call();
    stdout.writeln(
        'Session preparation complete; starting the bounded browsing measurement.');
    await Future.wait([for (var i = 0; i < sessions.length; i++) runUser(i)]);
  }
  final totalRequests =
      metrics.values.fold(0, (sum, item) => sum + item.requestCount);
  final totalSuccesses =
      metrics.values.fold(0, (sum, item) => sum + item.successes);
  final failures = totalRequests - totalSuccesses;
  final errorRate = totalRequests == 0 ? 100.0 : failures * 100 / totalRequests;
  final readMetrics = [
    for (final operation in browsingOperations)
      if (metrics[operation.name] != null) metrics[operation.name]!
  ];
  final readRequests =
      readMetrics.fold<int>(0, (sum, item) => sum + item.requestCount);
  final readSuccesses =
      readMetrics.fold<int>(0, (sum, item) => sum + item.successes);
  final readErrorRate = readRequests == 0
      ? 100.0
      : (readRequests - readSuccesses) * 100 / readRequests;
  final activeUsers = readCounts.where((count) => count > 0).length;
  final passed = sessionsCoverMeasurement &&
      activeUsers == credentials.length &&
      peakUsers == credentials.length &&
      errorRate <= maxErrorPercent &&
      readErrorRate <= maxErrorPercent;
  return <String, Object>{
    'schemaVersion': 2,
    'kind': 'dragonhaven-staging-load-report',
    'measurementMode': loadMeasurementMode,
    'environment': 'staging',
    'productionTarget': false,
    'appVersion': appVersion,
    'applicationContractVersion': 1,
    'repositoryMigrationVersion': migrationVersion,
    'serverMigrationVersionVerified': false,
    'generatedAtUtc': now().toIso8601String(),
    'virtualUsers': credentials.length,
    'authenticatedUsers': metrics['password_login']?.successes ?? 0,
    'preparedUsers': sessions.length,
    'activeUsers': activeUsers,
    'peakConcurrentBrowsingUsers': peakUsers,
    'warmupCompleted': warmupCompleted,
    'warmupDurationMs': warmupDurationMs,
    'loginSpacingMs': loginSpacing.inMilliseconds,
    'sessionsCoverMeasurement': sessionsCoverMeasurement,
    'durationSeconds': durationSeconds,
    'steadyStateSeconds': durationSeconds,
    'rampUpSeconds': rampUpSeconds,
    'minimumReadRequestsPerUser': readCounts.reduce(min),
    'result': passed ? 'passed' : 'failed',
    'readRequests': readRequests,
    'readErrorRatePercent': double.parse(readErrorRate.toStringAsFixed(3)),
    'totalRequests': totalRequests,
    'successes': totalSuccesses,
    'failures': failures,
    'errorRatePercent': double.parse(errorRate.toStringAsFixed(3)),
    'responseBytesEstimate':
        metrics.values.fold<int>(0, (sum, item) => sum + item.responseBytes),
    'operations': <String, Object>{
      for (final entry in metrics.entries) entry.key: entry.value.toJson(),
    },
    'privacy':
        'No e-mail, password, token, user id, response body or save data is recorded.',
    'serverMetricsCaptured': false,
    'dashboardEvidenceStillRequired': <String>[
      'staging server migration parity with repositoryMigrationVersion',
      'peak database connections and CPU',
      'provider-measured egress',
      'query/index findings and rate-limit observations',
    ],
  };
}

Map<String, String> parseArguments(List<String> arguments) {
  final parsed = <String, String>{};
  for (final argument in arguments) {
    if (!argument.startsWith('--')) {
      throw FormatException('Unknown argument: $argument');
    }
    final separator = argument.indexOf('=');
    if (separator < 0) {
      parsed[argument.substring(2)] = 'true';
    } else {
      parsed[argument.substring(2, separator)] =
          argument.substring(separator + 1);
    }
  }
  return parsed;
}

Future<void> writeJsonFile(String path, Map<String, Object> value) async {
  final file = File(path);
  await file.parent.create(recursive: true);
  await file
      .writeAsString('${const JsonEncoder.withIndent('  ').convert(value)}\n');
}

/// A pipe avoids Linux's per-environment-variable size limit for 1000 accounts.
/// The pool stays in memory, is bounded, and is never written to logs or disk.
Future<String> readCredentialInput(Stream<List<int>> input) async {
  final bytes = <int>[];
  await for (final chunk in input.timeout(const Duration(seconds: 30))) {
    if (bytes.length + chunk.length > 1024 * 1024) {
      throw const FormatException('Synthetic credential input is too large.');
    }
    bytes.addAll(chunk);
  }
  return utf8.decode(bytes);
}

String discoverAppVersion() {
  final source = File('lib/app_info.dart').readAsStringSync();
  final match = RegExp(r"defaultValue:\s*'([^']+)'").firstMatch(source);
  if (match == null) {
    throw StateError('The app version could not be derived safely.');
  }
  return 'v${match.group(1)}';
}

String discoverMigrationVersion() {
  final versions = Directory('supabase/migrations')
      .listSync()
      .whereType<File>()
      .map((file) => file.uri.pathSegments.last.split('_').first)
      .where((value) => RegExp(r'^\d{12}$').hasMatch(value))
      .toList()
    ..sort();
  if (versions.isEmpty) {
    throw StateError('The migration version could not be derived safely.');
  }
  return versions.last;
}

Future<void> main(List<String> arguments) async {
  try {
    final options = parseArguments(arguments);
    final execute = options['execute'] == 'true';
    final planOnly = options['plan-only'] == 'true';
    if (execute == planOnly) {
      throw StateError('Choose exactly one of --plan-only or --execute.');
    }
    final virtualUsers = int.parse(options['virtual-users'] ?? '100');
    final durationSeconds = int.parse(options['duration-seconds'] ?? '180');
    final rampUpSeconds = int.parse(options['ramp-up-seconds'] ?? '60');
    final outputPath = options['output'] ?? 'staging/load-report.json';
    final appVersion = discoverAppVersion();
    final migrationVersion = discoverMigrationVersion();
    final plan = buildLoadPlan(
      virtualUsers: virtualUsers,
      durationSeconds: durationSeconds,
      rampUpSeconds: rampUpSeconds,
      appVersion: appVersion,
      migrationVersion: migrationVersion,
    );
    if (planOnly) {
      await writeJsonFile(outputPath, plan);
      stdout.writeln(
          'Privacy-safe staging load plan written for $virtualUsers virtual users.');
      return;
    }

    final expectedConfirmation = 'RUN_DRAGONHAVEN_STAGING_LOAD_$virtualUsers';
    if (options['confirmation'] != expectedConfirmation ||
        options['synthetic-accounts-confirmed'] != 'true') {
      throw StateError(
          'Execution requires exact confirmation and synthetic-account approval.');
    }
    if (virtualUsers == 1000) {
      final baselinePath = options['baseline'];
      if (baselinePath == null || baselinePath.isEmpty) {
        throw StateError(
            'The 1000-user stage requires a 100-user baseline file.');
      }
      final baseline = jsonDecode(await File(baselinePath).readAsString());
      validateBaselineReport((baseline as Map).cast<String, Object?>(),
          migrationVersion: migrationVersion);
    }

    final environment = Platform.environment;
    final baseUrl = (environment['STAGING_SUPABASE_URL'] ?? '')
        .trim()
        .replaceFirst(RegExp(r'/$'), '');
    final projectRef = environment['STAGING_SUPABASE_PROJECT_REF'] ?? '';
    final publishableKey =
        environment['STAGING_SUPABASE_PUBLISHABLE_KEY'] ?? '';
    validateExecutionTarget(
      url: baseUrl,
      projectRef: projectRef,
      publishableKey: publishableKey,
    );
    final rawCredentials = options['credentials-stdin'] == 'true'
        ? await readCredentialInput(stdin)
        : environment['STAGING_LOAD_CREDENTIALS_JSON'] ?? '';
    final credentials = parseCredentialPool(rawCredentials, virtualUsers);
    final report = await executeLoadProfile(
      onMeasurementStarted: () => writeJsonFile(
          '${File(outputPath).parent.path}/load-phase.json', {
        'phase': 'browsing',
        'startedAtUtc': DateTime.now().toUtc().toIso8601String()
      }),
      baseUrl: baseUrl,
      publishableKey: publishableKey,
      credentials: credentials,
      durationSeconds: durationSeconds,
      rampUpSeconds: rampUpSeconds,
      maxErrorPercent: 2,
      appVersion: appVersion,
      migrationVersion: migrationVersion,
    );
    await writeJsonFile(outputPath, report);
    stdout.writeln(
      'Staging load report written: ${report['result']} with ${report['errorRatePercent']}% errors.',
    );
    if (report['result'] != 'passed') exitCode = 1;
  } on Object catch (error) {
    stderr.writeln(
        'Staging load profile refused or failed safely: ${error.runtimeType}.');
    exitCode = 64;
  } finally {
    // Reports and client cleanup have been awaited. Abandoned transport handles
    // must not keep this CLI alive and postpone synthetic-account removal.
    await stdout.flush();
    await stderr.flush();
    exit(exitCode);
  }
}
