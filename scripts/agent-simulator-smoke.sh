#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ ! -f .agent/local.env ]]; then
  echo "Missing .agent/local.env"
  exit 1
fi
# shellcheck disable=SC1091
source .agent/local.env

: "${IOS_CONTAINER:?missing IOS_CONTAINER}"
: "${IOS_SCHEME:?missing IOS_SCHEME}"
: "${IOS_SIMULATOR:?missing IOS_SIMULATOR}"

RUNTIME="$ROOT/.agent/runtime"
DERIVED="$RUNTIME/DerivedData"
SCREENSHOT="$RUNTIME/simulator-latest.png"
mkdir -p "$RUNTIME"
rm -rf "$DERIVED"

if [[ "$IOS_CONTAINER" == *.xcworkspace ]]; then
  CONTAINER_ARGS=(-workspace "$IOS_CONTAINER")
else
  CONTAINER_ARGS=(-project "$IOS_CONTAINER")
fi

DEVICE_LINE="$(xcrun simctl list devices available | grep -F "$IOS_SIMULATOR (" | head -n 1 || true)"
if [[ -z "$DEVICE_LINE" ]]; then
  echo "Simulator not found: $IOS_SIMULATOR"
  exit 1
fi
UDID="$(echo "$DEVICE_LINE" | sed -E 's/.*\(([0-9A-Fa-f-]{36})\).*/\1/')"
if [[ -z "$UDID" || "$UDID" == "$DEVICE_LINE" ]]; then
  echo "Could not parse Simulator UDID from: $DEVICE_LINE"
  exit 1
fi

xcrun simctl boot "$UDID" >/dev/null 2>&1 || true
xcrun simctl bootstatus "$UDID" -b

xcodebuild \
  "${CONTAINER_ARGS[@]}" \
  -scheme "$IOS_SCHEME" \
  -destination "platform=iOS Simulator,id=$UDID" \
  -derivedDataPath "$DERIVED" \
  -configuration Debug \
  build

APP_PATH="$(find "$DERIVED/Build/Products/Debug-iphonesimulator" -maxdepth 1 -name '*.app' -type d | head -n 1)"
if [[ -z "$APP_PATH" ]]; then
  echo "Built .app not found"
  exit 1
fi

BUNDLE_ID="$(xcodebuild "${CONTAINER_ARGS[@]}" -scheme "$IOS_SCHEME" -configuration Debug -showBuildSettings | awk -F ' = ' '/PRODUCT_BUNDLE_IDENTIFIER/ {print $2; exit}')"
if [[ -z "$BUNDLE_ID" ]]; then
  echo "Could not determine PRODUCT_BUNDLE_IDENTIFIER"
  exit 1
fi

xcrun simctl install "$UDID" "$APP_PATH"
xcrun simctl launch "$UDID" "$BUNDLE_ID"
sleep 3
xcrun simctl io "$UDID" screenshot "$SCREENSHOT"

echo "SIMULATOR_SMOKE_OK"
echo "SCREENSHOT=$SCREENSHOT"
