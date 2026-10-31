#!/bin/zsh
# Builds a downloadable ClickWheel: a universal (Apple Silicon + Intel) Release
# app, signed ad-hoc (no Developer ID, so not notarized), zipped into releases/.
# Usage: scripts/release.sh   (the version comes from project.yml)
set -euo pipefail
cd "$(dirname "$0")/.."

version=$(sed -n 's/.*CFBundleShortVersionString: "\(.*\)"/\1/p' project.yml)
[[ -n "$version" ]] || { echo "No version in project.yml" >&2; exit 1; }

xcodegen generate --quiet
xcodebuild -project ClickWheel.xcodeproj -scheme ClickWheel -configuration Release \
    -derivedDataPath build.noindex/release ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO build -quiet

app=build.noindex/release/Build/Products/Release/ClickWheel.app
codesign --force --deep --options runtime \
    --entitlements ClickWheel/App/ClickWheel.entitlements --sign - "$app"
codesign --verify --strict --verbose=1 "$app"

mkdir -p releases
zip="releases/ClickWheel-$version.zip"
rm -f "$zip"
ditto -c -k --keepParent "$app" "$zip"

echo "Built $zip"
lipo -archs "$app/Contents/MacOS/ClickWheel"
shasum -a 256 "$zip"
