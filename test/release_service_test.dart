import 'package:dragon_haven/services/release_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
    expect(release('v0.01.03').isNewerThanInstalled, isTrue);
    expect(release('v0.02.00').isNewerThanInstalled, isTrue);
    expect(release('v0.00.00').isNewerThanInstalled, isFalse);
  });

  test('the copy button uses one permanent latest APK link', () {
    expect(ReleaseConfig.owner, 'Rakky88');
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
