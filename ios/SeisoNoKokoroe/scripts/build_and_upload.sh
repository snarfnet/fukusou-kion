#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "xcodegen is required. Install with: brew install xcodegen"
  exit 1
fi

xcodegen generate

xcodebuild archive \
  -project SeisoNoKokoroe.xcodeproj \
  -scheme SeisoNoKokoroe \
  -configuration Release \
  -archivePath build/SeisoNoKokoroe.xcarchive \
  -destination "generic/platform=iOS"

xcodebuild -exportArchive \
  -archivePath build/SeisoNoKokoroe.xcarchive \
  -exportPath build/export \
  -exportOptionsPlist export_options.plist

echo "Archive exported to build/export"
echo "Upload the IPA with Transporter or xcrun altool / notarytool depending on your App Store Connect setup."
