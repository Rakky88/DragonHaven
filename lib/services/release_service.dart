import 'dart:async';
import 'dart:convert';
import 'dart:io';

abstract final class ReleaseConfig {
  static const owner = String.fromEnvironment('DRAGONHAVEN_GITHUB_OWNER',
      defaultValue: 'Rakky88');
  static const repository = String.fromEnvironment('DRAGONHAVEN_GITHUB_REPO',
      defaultValue: 'DragonHaven');
  static const installedVersion = String.fromEnvironment(
      'DRAGONHAVEN_APP_VERSION',
      defaultValue: '0.00.07');

  static bool get isConfigured =>
      owner.trim().isNotEmpty && repository.trim().isNotEmpty;
  static String get repositoryUrl => 'https://github.com/$owner/$repository';
  static String get releasesUrl => '$repositoryUrl/releases/latest';
  static String get downloadUrl => '$releasesUrl/download/DragonHaven.apk';
  // Opens Rick Groot's focused Ko-fi tip panel.
  static const kofiUrl =
      'https://ko-fi.com/rgroot88/?hidefeed=true&widget=true&embed=true';
}

class LatestRelease {
  const LatestRelease({
    required this.tagName,
    required this.pageUrl,
    required this.downloadUrl,
    required this.hasApk,
  });

  final String tagName;
  final String pageUrl;
  final String downloadUrl;
  final bool hasApk;

  String get version => tagName.replaceFirst(RegExp(r'^[vV]'), '');
  bool get isNewerThanInstalled =>
      _compareVersions(version, ReleaseConfig.installedVersion) > 0;

  static int _compareVersions(String left, String right) {
    List<int> parts(String value) => value
        .split(RegExp(r'[.+-]'))
        .take(3)
        .map(
            (part) => int.tryParse(part.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();

    final a = parts(left);
    final b = parts(right);
    for (var index = 0; index < 3; index++) {
      final av = index < a.length ? a[index] : 0;
      final bv = index < b.length ? b[index] : 0;
      if (av != bv) return av.compareTo(bv);
    }
    return 0;
  }
}

enum ReleaseErrorCode {
  notConfigured,
  noRelease,
  httpError,
  invalidData,
  offline,
  handshake,
  format,
  timeout,
}

class ReleaseException implements Exception {
  const ReleaseException(this.code, {this.statusCode});
  final ReleaseErrorCode code;
  final int? statusCode;
  @override
  String toString() => 'ReleaseException(${code.name}, $statusCode)';
}

abstract final class ReleaseService {
  static const _requestTimeout = Duration(seconds: 15);

  static Future<LatestRelease> fetchLatest() async {
    if (!ReleaseConfig.isConfigured) {
      throw const ReleaseException(ReleaseErrorCode.notConfigured);
    }

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final uri = Uri.https('api.github.com',
          '/repos/${ReleaseConfig.owner}/${ReleaseConfig.repository}/releases/latest');
      final request = await client.getUrl(uri).timeout(_requestTimeout);
      request.headers
        ..set(HttpHeaders.acceptHeader, 'application/vnd.github+json')
        ..set(HttpHeaders.userAgentHeader,
            'DragonHaven/${ReleaseConfig.installedVersion}');
      final response = await request.close().timeout(_requestTimeout);
      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(_requestTimeout);

      if (response.statusCode == HttpStatus.notFound) {
        throw const ReleaseException(ReleaseErrorCode.noRelease);
      }
      if (response.statusCode != HttpStatus.ok) {
        throw ReleaseException(ReleaseErrorCode.httpError,
            statusCode: response.statusCode);
      }

      final decoded = jsonDecode(body);
      if (decoded is! Map) {
        throw const ReleaseException(ReleaseErrorCode.invalidData);
      }
      final json = <String, dynamic>{
        for (final entry in decoded.entries)
          if (entry.key is String) entry.key as String: entry.value,
      };
      final tagName = json['tag_name'];
      final pageUrl = json['html_url'];
      if (tagName is! String ||
          tagName.trim().isEmpty ||
          pageUrl is! String ||
          !_isSafeWebUrl(pageUrl)) {
        throw const ReleaseException(ReleaseErrorCode.invalidData);
      }

      final assets = json['assets'] is List ? json['assets'] as List : const [];
      Map<String, dynamic>? apk;
      for (final raw in assets) {
        if (raw is! Map) continue;
        final asset = <String, dynamic>{
          for (final entry in raw.entries)
            if (entry.key is String) entry.key as String: entry.value,
        };
        final rawName = asset['name'];
        final name = rawName is String ? rawName.toLowerCase() : '';
        if (name.endsWith('.apk')) {
          apk = asset;
          if (name.contains('dragonhaven')) break;
        }
      }
      final rawApkUrl = apk?['browser_download_url'];
      final apkUrl =
          rawApkUrl is String && _isSafeWebUrl(rawApkUrl) ? rawApkUrl : null;
      return LatestRelease(
        tagName: tagName,
        pageUrl: pageUrl,
        downloadUrl: apkUrl ?? pageUrl,
        hasApk: apkUrl != null,
      );
    } on SocketException {
      throw const ReleaseException(ReleaseErrorCode.offline);
    } on HandshakeException {
      throw const ReleaseException(ReleaseErrorCode.handshake);
    } on FormatException {
      throw const ReleaseException(ReleaseErrorCode.format);
    } on TimeoutException {
      throw const ReleaseException(ReleaseErrorCode.timeout);
    } finally {
      client.close(force: true);
    }
  }

  static bool _isSafeWebUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        uri.hasAuthority &&
        (uri.scheme == 'https' || uri.scheme == 'http');
  }
}
