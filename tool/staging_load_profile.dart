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

class RequestResult {
  const RequestResult({
    required this.statusCode,
    required this.durationMs,
    required this.responseBytes,
    this.bodyBytes = const <int>[],
    this.networkFailure = false,
  });

  final int statusCode;
  final int durationMs;
  final int responseBytes;
  final List<int> bodyBytes;
  final bool networkFailure;

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
        ? 'network_error'
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
    'schemaVersion': 1,
    'kind': 'dragonhaven-staging-load-plan',
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

void validateBaselineReport(Map<String, Object?> report) {
  if (report['kind'] != 'dragonhaven-staging-load-report' ||
      report['productionTarget'] != false ||
      report['virtualUsers'] != 100 ||
      report['result'] != 'passed') {
    throw StateError(
        'The 1000-user stage requires a successful 100-user staging report.');
  }
  final errorRate = report['errorRatePercent'];
  if (errorRate is! num || errorRate > 2) {
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
}) async {
  final stopwatch = Stopwatch()..start();
  try {
    final request =
        await client.postUrl(uri).timeout(const Duration(seconds: 30));
    headers.forEach(request.headers.set);
    request.headers.contentType = ContentType.json;
    request.add(utf8.encode(jsonEncode(body)));
    final response = await request.close().timeout(const Duration(seconds: 30));
    final bytes = await response.fold<List<int>>(
      <int>[],
      (buffer, chunk) => buffer..addAll(chunk),
    ).timeout(const Duration(seconds: 30));
    stopwatch.stop();
    return RequestResult(
      statusCode: response.statusCode,
      durationMs: stopwatch.elapsedMilliseconds,
      responseBytes: bytes.length,
      bodyBytes: retainBody ? bytes : const <int>[],
    );
  } on Object {
    stopwatch.stop();
    return RequestResult(
      statusCode: 0,
      durationMs: stopwatch.elapsedMilliseconds,
      responseBytes: 0,
      networkFailure: true,
    );
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

Future<Map<String, Object>> executeLoadProfile({
  required String baseUrl,
  required String publishableKey,
  required List<SyntheticCredential> credentials,
  required int durationSeconds,
  required int rampUpSeconds,
  required double maxErrorPercent,
  required String appVersion,
  required String migrationVersion,
}) async {
  final startedAt = DateTime.now().toUtc();
  final endsAt = startedAt.add(Duration(seconds: durationSeconds));
  final metrics = <String, OperationMetrics>{};
  OperationMetrics metricFor(String operation) =>
      metrics.putIfAbsent(operation, OperationMetrics.new);

  Future<void> runUser(int index) async {
    final rampDelayMs =
        ((index / credentials.length) * rampUpSeconds * 1000).round();
    await Future<void>.delayed(Duration(milliseconds: rampDelayMs));
    if (DateTime.now().toUtc().isAfter(endsAt)) return;

    final credential = credentials[index];
    final random = Random(830017 + index);
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 30)
      ..maxConnectionsPerHost = 2
      ..userAgent = 'DragonHaven-Staging-Load-Audit';
    try {
      final login = await postJson(
        client: client,
        uri: Uri.parse('$baseUrl/auth/v1/token?grant_type=password'),
        headers: <String, String>{'apikey': publishableKey},
        body: <String, Object?>{
          'email': credential.email,
          'password': credential.password,
        },
        retainBody: true,
      );
      metricFor('password_login').record(login);
      if (!login.succeeded) return;

      String accessToken;
      try {
        final decoded = jsonDecode(utf8.decode(login.bodyBytes));
        accessToken =
            (decoded as Map<String, dynamic>)['access_token'] as String;
        if (accessToken.isEmpty) return;
      } on Object {
        metricFor('login_contract').record(const RequestResult(
          statusCode: 0,
          durationMs: 0,
          responseBytes: 0,
          networkFailure: true,
        ));
        return;
      }

      final headers = <String, String>{
        'apikey': publishableKey,
        'authorization': 'Bearer $accessToken',
      };
      final bootstrap = await postJson(
        client: client,
        uri: Uri.parse('$baseUrl/rest/v1/rpc/ensure_my_online_account'),
        headers: headers,
        body: const <String, Object?>{},
      );
      metricFor('ensure_my_online_account').record(bootstrap);
      if (!bootstrap.succeeded) return;

      while (DateTime.now().toUtc().isBefore(endsAt)) {
        final operation = chooseOperation(random);
        final result = await postJson(
          client: client,
          uri: Uri.parse('$baseUrl/rest/v1/rpc/${operation.name}'),
          headers: headers,
          body: const <String, Object?>{},
        );
        metricFor(operation.name).record(result);
        final thinkSeconds = 8 + random.nextInt(13);
        final remaining = endsAt.difference(DateTime.now().toUtc());
        if (remaining <= Duration.zero) break;
        await Future<void>.delayed(
          remaining < Duration(seconds: thinkSeconds)
              ? remaining
              : Duration(seconds: thinkSeconds),
        );
      }
    } finally {
      client.close(force: true);
    }
  }

  await Future.wait(<Future<void>>[
    for (var index = 0; index < credentials.length; index++) runUser(index),
  ]);

  final totalRequests =
      metrics.values.fold(0, (sum, item) => sum + item.requestCount);
  final totalSuccesses =
      metrics.values.fold(0, (sum, item) => sum + item.successes);
  final failures = totalRequests - totalSuccesses;
  final errorRate = totalRequests == 0 ? 100.0 : failures * 100 / totalRequests;
  final responseBytes =
      metrics.values.fold(0, (sum, item) => sum + item.responseBytes);
  final passed =
      totalRequests > credentials.length * 2 && errorRate <= maxErrorPercent;

  return <String, Object>{
    'schemaVersion': 1,
    'kind': 'dragonhaven-staging-load-report',
    'environment': 'staging',
    'productionTarget': false,
    'appVersion': appVersion,
    'applicationContractVersion': 1,
    'repositoryMigrationVersion': migrationVersion,
    'serverMigrationVersionVerified': false,
    'generatedAtUtc': DateTime.now().toUtc().toIso8601String(),
    'virtualUsers': credentials.length,
    'durationSeconds': durationSeconds,
    'rampUpSeconds': rampUpSeconds,
    'result': passed ? 'passed' : 'failed',
    'totalRequests': totalRequests,
    'successes': totalSuccesses,
    'failures': failures,
    'errorRatePercent': double.parse(errorRate.toStringAsFixed(3)),
    'responseBytesEstimate': responseBytes,
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
      validateBaselineReport((baseline as Map).cast<String, Object?>());
    }

    final environment = Platform.environment;
    final baseUrl = (environment['STAGING_SUPABASE_URL'] ?? '')
        .trim()
        .replaceFirst(RegExp(r'/$'), '');
    final projectRef = environment['STAGING_SUPABASE_PROJECT_REF'] ?? '';
    final publishableKey =
        environment['STAGING_SUPABASE_PUBLISHABLE_KEY'] ?? '';
    final rawCredentials = environment['STAGING_LOAD_CREDENTIALS_JSON'] ?? '';
    validateExecutionTarget(
      url: baseUrl,
      projectRef: projectRef,
      publishableKey: publishableKey,
    );
    final credentials = parseCredentialPool(rawCredentials, virtualUsers);
    final report = await executeLoadProfile(
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
  }
}
