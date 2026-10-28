#!/usr/bin/env bash
# Regenerate the Xcode project and run the unit tests.
set -euo pipefail
cd "$(dirname "$0")/.."
xcodegen generate --quiet
xcodebuild test -project ClickWheel.xcodeproj -scheme ClickWheel -destination 'platform=macOS,arch=arm64' -derivedDataPath build -quiet "$@"
