#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "DragonHaven iOS builds require macOS with Xcode." >&2
  exit 1
fi

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter is not available on PATH." >&2
  exit 1
fi

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "Xcode command-line tools are not installed." >&2
  exit 1
fi

ios_download_url="${DRAGONHAVEN_IOS_DOWNLOAD_URL:-}"
if [[ -z "$ios_download_url" ]]; then
  echo "Warning: no TestFlight URL is configured."
  echo "The in-app iPhone share/update action will remain unavailable."
fi

flutter pub get
flutter build ipa \
  --release \
  --dart-define="DRAGONHAVEN_IOS_DOWNLOAD_URL=$ios_download_url"

echo "Archive: build/ios/archive/Runner.xcarchive"
echo "IPA output: build/ios/ipa"
