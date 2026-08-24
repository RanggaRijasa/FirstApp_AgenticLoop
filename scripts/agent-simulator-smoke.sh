#!/usr/bin/env bash
set -euo pipefail

# Normalize to the repository root so project paths and output directories are
# independent of the caller's working directory.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# shellcheck disable=SC1091
source "$ROOT/scripts/_xcode-common.sh"

: "${IOS_SIMULATOR:?Set IOS_SIMULATOR in the environment or .agent/local.env}"

RUNTIME="$ROOT/.agent/runtime"
SCREENSHOTS="$ROOT/.agent/screenshots"
mkdir -p "$RUNTIME" "$SCREENSHOTS"
DERIVED_DATA="$RUNTIME/DerivedData"

# simctl can list devices whose runtime Xcode cannot resolve as a destination
# (e.g. simulators created with an unsupported runtime). Selecting the first
# simctl match makes xcodebuild fail with "Unable to find a destination
# matching the provided destination specifier". Resolve the UDID against
# Xcode's own destination list instead, and only accept a device that is also
# available in simctl (required for boot/install/launch).

# 1) Available simulator UDIDs from simctl.
AVAILABLE=()
while IFS= read -r uid; do
  AVAILABLE+=("$uid")
done < <(xcrun simctl list devices available | sed -nE 's/.*\(([0-9A-Fa-f-]{36})\).*/\1/p')
if [[ ${#AVAILABLE[@]} -eq 0 ]]; then
  echo "ERROR: No available simulators found. Run: xcrun simctl list devices available"
  exit 1
fi

# 2) First Xcode-resolvable destination named $IOS_SIMULATOR that is also
#    available in simctl.
UDID=""
while IFS= read -r line; do
  cand_id="$(printf '%s\n' "$line" | sed -nE 's/.*id:([0-9A-Fa-f-]{36}).*/\1/p')"
  cand_name="$(printf '%s\n' "$line" | sed -nE 's/.*name:([^,}]*).*/\1/p')"
  cand_name="${cand_name%"${cand_name##*[![:space:]]}"}"
  if [[ -z "$cand_id" || "$cand_name" != "$IOS_SIMULATOR" ]]; then
    continue
  fi
  if printf '%s\n' "${AVAILABLE[@]}" | grep -Fxq "$cand_id"; then
    UDID="$cand_id"
    break
  fi
done < <(xcodebuild "${XCODE_CONTAINER_ARGS[@]}" -scheme "$IOS_SCHEME" -showdestinations 2>/dev/null)

if [[ -z "$UDID" ]]; then
  echo "ERROR: '$IOS_SIMULATOR' is not an Xcode-resolvable, available simulator destination."
  echo "Run: xcodebuild ${XCODE_CONTAINER_ARGS[*]} -scheme \"$IOS_SCHEME\" -showdestinations"
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
SHOT="$SCREENSHOTS/simulator-${STAMP}.png"
xcrun simctl io "$UDID" screenshot "$SHOT"

echo
echo "SIMULATOR_SMOKE_OK"
echo "Simulator: $IOS_SIMULATOR"
echo "Bundle:    $BUNDLE_ID"
echo "Screenshot: $SHOT"
