import 'dart:io';

import 'package:dragon_haven/app_info.dart';
import 'package:dragon_haven/services/release_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('About and update checks share the same release version', () {
    expect(AppInfo.version, '0.05.01');
    expect(AppInfo.displayVersion, 'v0.05.01');
    expect(ReleaseConfig.installedVersion, AppInfo.version);
  });

  test('the visible version cannot lag behind pubspec', () {
    final source = File('pubspec.yaml').readAsStringSync();
    final match =
        RegExp(r'^version:\s*(\d+)\.(\d+)\.(\d+)\+\d+\s*$', multiLine: true)
            .firstMatch(source);
    expect(match, isNotNull);
    final displayVersion = [
      match!.group(1)!,
      match.group(2)!.padLeft(2, '0'),
      match.group(3)!.padLeft(2, '0'),
    ].join('.');
    expect(AppInfo.version, displayVersion);
  });

  LatestRelease release(String tag) => LatestRelease(
        tagName: tag,
        pageUrl: 'https://example.com/release',
        downloadUrl: 'https://example.com/DragonHaven.apk',
        hasApk: true,
      );

  test('release comparison understands the displayed version format', () {
    expect(release('v0.00.01').isNewerThanInstalled, isFalse);
    expect(release('v0.00.02').isNewerThanInstalled, isFalse);
    expect(release('v0.00.03').isNewerThanInstalled, isFalse);
    expect(release('v0.00.04').isNewerThanInstalled, isFalse);
    expect(release('v0.00.07').isNewerThanInstalled, isFalse);
    expect(release('v0.00.08').isNewerThanInstalled, isFalse);
    expect(release('v0.00.09').isNewerThanInstalled, isFalse);
    expect(release('v0.00.13').isNewerThanInstalled, isFalse);
    expect(release('v0.01.02').isNewerThanInstalled, isFalse);
    expect(release('v0.01.03').isNewerThanInstalled, isFalse);
    expect(release('v0.01.04').isNewerThanInstalled, isFalse);
    expect(release('v0.01.05').isNewerThanInstalled, isFalse);
    expect(release('v0.01.07').isNewerThanInstalled, isFalse);
    expect(release('v0.01.08').isNewerThanInstalled, isFalse);
    expect(release('v0.01.09').isNewerThanInstalled, isFalse);
    expect(release('v0.01.10').isNewerThanInstalled, isFalse);
    expect(release('v0.01.11').isNewerThanInstalled, isFalse);
    expect(release('v0.02.00').isNewerThanInstalled, isFalse);
    expect(release('v0.02.01').isNewerThanInstalled, isFalse);
    expect(release('v0.02.02').isNewerThanInstalled, isFalse);
    expect(release('v0.02.03').isNewerThanInstalled, isFalse);
    expect(release('v0.02.04').isNewerThanInstalled, isFalse);
    expect(release('v0.02.05').isNewerThanInstalled, isFalse);
    expect(release('v0.03.03').isNewerThanInstalled, isFalse);
    expect(release('v0.03.04').isNewerThanInstalled, isFalse);
    expect(release('v0.03.05').isNewerThanInstalled, isFalse);
    expect(release('v0.04.02').isNewerThanInstalled, isFalse);
    expect(release('v0.04.03').isNewerThanInstalled, isFalse);
    expect(release('v0.04.04').isNewerThanInstalled, isFalse);
    expect(release('v0.04.06').isNewerThanInstalled, isFalse);
    expect(release('v0.04.10').isNewerThanInstalled, isFalse);
    expect(release('v0.04.11').isNewerThanInstalled, isFalse);
    expect(release('v0.04.12').isNewerThanInstalled, isFalse);
    expect(release('v0.04.13').isNewerThanInstalled, isFalse);
    expect(release('v0.04.14').isNewerThanInstalled, isFalse);
    expect(release('v0.04.15').isNewerThanInstalled, isFalse);
    expect(release('v0.04.16').isNewerThanInstalled, isFalse);
    expect(release('v0.04.17').isNewerThanInstalled, isFalse);
    expect(release('v0.05.01').isNewerThanInstalled, isFalse);
    expect(release('v0.05.02').isNewerThanInstalled, isTrue);
    expect(release('v0.00.00').isNewerThanInstalled, isFalse);
  });

  test('the copy button uses one permanent latest APK link', () {
    expect(ReleaseConfig.owner, 'Rakky88');
    expect(ReleaseConfig.installedVersion, '0.05.01');
    expect(
      ReleaseConfig.downloadUrl,
      'https://github.com/Rakky88/DragonHaven/releases/latest/download/DragonHaven.apk',
    );
  });

  test('the support button uses the shared focused Ko-fi link', () {
    expect(
      ReleaseConfig.kofiUrl,
      'https://ko-fi.com/rgroot88/?hidefeed=true&widget=true&embed=true',
    );
    final uri = Uri.parse(ReleaseConfig.kofiUrl);
    expect(uri.scheme, 'https');
    expect(uri.host, 'ko-fi.com');
    expect(uri.path, '/rgroot88/');
  });
}
