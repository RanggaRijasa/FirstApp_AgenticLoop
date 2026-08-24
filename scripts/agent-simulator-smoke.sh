#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "$0")/_xcode-common.sh"

: "${IOS_SIMULATOR:?Set IOS_SIMULATOR in the environment or .agent/local.env}"

mkdir -p .agent/runtime .agent/screenshots
DERIVED_DATA="$(pwd)/.agent/runtime/DerivedData"

DEVICE_LINE="$(xcrun simctl list devices available | grep -F "${IOS_SIMULATOR} (" | head -n 1 || true)"
if [[ -z "$DEVICE_LINE" ]]; then
  echo "ERROR: Simulator '$IOS_SIMULATOR' not found."
  echo "Run: xcrun simctl list devices available"
  exit 1
fi

UDID="$(printf '%s\n' "$DEVICE_LINE" | sed -E 's/.*\(([0-9A-Fa-f-]{36})\).*/\1/')"
if [[ ! "$UDID" =~ ^[0-9A-Fa-f-]{36}$ ]]; then
  echo "ERROR: Could not parse simulator UDID from: $DEVICE_LINE"
  exit 1
fi

echo "Booting $IOS_SIMULATOR ($UDID) ..."
xcrun simctl boot "$UDID" >/dev/null 2>&1 || true
xcrun simctl bootstatus "$UDID" -b

echo "Building app for simulator ..."
rm -rf "$DERIVED_DATA"
xcodebuild \
  "${XCODE_CONTAINER_ARGS[@]}" \
  -scheme "$IOS_SCHEME" \
  -configuration Debug \
  -destination "id=$UDID" \
  -derivedDataPath "$DERIVED_DATA" \
  build

PRODUCTS="$DERIVED_DATA/Build/Products/Debug-iphonesimulator"
APP_PATH="$(find "$PRODUCTS" -maxdepth 1 -type d -name '*.app' ! -name '*Tests*' ! -name '*UITests*' | head -n 1 || true)"
if [[ -z "$APP_PATH" ]]; then
  echo "ERROR: Built .app not found in $PRODUCTS"
  exit 1
fi

BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP_PATH/Info.plist" 2>/dev/null || true)"
if [[ -z "$BUNDLE_ID" ]]; then
  echo "ERROR: Could not determine CFBundleIdentifier from $APP_PATH"
  exit 1
fi

xcrun simctl terminate "$UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true
xcrun simctl uninstall "$UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true
xcrun simctl install "$UDID" "$APP_PATH"
xcrun simctl launch "$UDID" "$BUNDLE_ID"
sleep "${IOS_SMOKE_WAIT_SECONDS:-4}"

STAMP="$(date +%Y%m%d-%H%M%S)"
SHOT=".agent/screenshots/simulator-${STAMP}.png"
xcrun simctl io "$UDID" screenshot "$SHOT"

echo
echo "SIMULATOR_SMOKE_OK"
echo "Simulator: $IOS_SIMULATOR"
echo "Bundle:    $BUNDLE_ID"
echo "Screenshot: $SHOT"
