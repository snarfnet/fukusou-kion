#!/bin/bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

if ! command -v xcodegen >/dev/null 2>&1; then
    echo "XcodeGenが必要です。brew install xcodegen を実行してください。" >&2
    exit 1
fi

mkdir -p .build
swift test
xcodegen generate

RESULT_BUNDLE="$PROJECT_ROOT/.build/SukebanMahjongTests.xcresult"
ARCHIVE_PATH="$PROJECT_ROOT/.build/SukebanMahjong.xcarchive"
rm -rf "$RESULT_BUNDLE" "$ARCHIVE_PATH"

DEVICE_ID="$(
    xcrun simctl list devices available -j | python3 -c '
import json
import sys

data = json.load(sys.stdin)
for devices in data["devices"].values():
    for device in devices:
        if device.get("isAvailable") and device["name"].startswith("iPhone"):
            print(device["udid"])
            raise SystemExit(0)
raise SystemExit("利用可能なiPhone Simulatorがありません")
'
)"

set -o pipefail
xcodebuild \
    -project SukebanMahjong.xcodeproj \
    -scheme SukebanMahjong \
    -destination "platform=iOS Simulator,id=$DEVICE_ID" \
    -derivedDataPath .build/DerivedData \
    -resultBundlePath "$RESULT_BUNDLE" \
    CODE_SIGNING_ALLOWED=NO \
    test | tee .build/xcodebuild-test.log

test -d "$RESULT_BUNDLE"
xcrun xcresulttool get test-results summary \
    --path "$RESULT_BUNDLE" \
    > .build/xcodebuild-test-summary.json

xcodebuild \
    -project SukebanMahjong.xcodeproj \
    -scheme SukebanMahjong \
    -destination "generic/platform=iOS" \
    -archivePath "$ARCHIVE_PATH" \
    CODE_SIGNING_ALLOWED=NO \
    archive | tee .build/xcodebuild-archive.log

ARCHIVED_APP="$ARCHIVE_PATH/Products/Applications/SukebanMahjong.app"
test -f "$ARCHIVE_PATH/Info.plist"
test -d "$ARCHIVED_APP"

EXECUTABLE_NAME="$(
    /usr/libexec/PlistBuddy \
        -c "Print :CFBundleExecutable" \
        "$ARCHIVED_APP/Info.plist"
)"
test -n "$EXECUTABLE_NAME"
test -x "$ARCHIVED_APP/$EXECUTABLE_NAME"

echo "テスト結果: $RESULT_BUNDLE"
echo "検証完了: $ARCHIVE_PATH"
