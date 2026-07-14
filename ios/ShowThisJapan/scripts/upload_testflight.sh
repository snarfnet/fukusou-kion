#!/usr/bin/env bash
set -euo pipefail

: "${SHOW_THIS_JAPAN_BUNDLE_ID:?Set SHOW_THIS_JAPAN_BUNDLE_ID}"
: "${APPLE_TEAM_ID:?Set APPLE_TEAM_ID}"
: "${ASC_KEY_ID:?Set ASC_KEY_ID}"
: "${ASC_ISSUER_ID:?Set ASC_ISSUER_ID}"
: "${ASC_KEY_PATH:?Set ASC_KEY_PATH to the AuthKey .p8 file}"

command -v xcodegen >/dev/null || { echo "Install XcodeGen first: brew install xcodegen"; exit 1; }
command -v xcodebuild >/dev/null || { echo "Xcode is required."; exit 1; }

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
xcodegen generate

xcodebuild \
  -project ShowThisJapan.xcodeproj \
  -scheme ShowThisJapan \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$ROOT/build/ShowThisJapan.xcarchive" \
  PRODUCT_BUNDLE_IDENTIFIER="$SHOW_THIS_JAPAN_BUNDLE_ID" \
  DEVELOPMENT_TEAM="$APPLE_TEAM_ID" \
  CODE_SIGN_STYLE=Automatic \
  -allowProvisioningUpdates \
  -authenticationKeyPath "$ASC_KEY_PATH" \
  -authenticationKeyID "$ASC_KEY_ID" \
  -authenticationKeyIssuerID "$ASC_ISSUER_ID" \
  clean archive

xcodebuild -exportArchive \
  -archivePath "$ROOT/build/ShowThisJapan.xcarchive" \
  -exportOptionsPlist "$ROOT/ExportOptions.plist" \
  -exportPath "$ROOT/build/export" \
  -allowProvisioningUpdates \
  -authenticationKeyPath "$ASC_KEY_PATH" \
  -authenticationKeyID "$ASC_KEY_ID" \
  -authenticationKeyIssuerID "$ASC_ISSUER_ID"

echo "Upload accepted. Processing now continues in App Store Connect."
