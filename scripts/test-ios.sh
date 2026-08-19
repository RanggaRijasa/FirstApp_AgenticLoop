#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "$0")/_xcode-common.sh"

: "${IOS_SIMULATOR:?Set IOS_SIMULATOR in .agent/local.env}"

echo "Testing $IOS_SCHEME on $IOS_SIMULATOR ..."
xcodebuild \
  "${XCODE_CONTAINER_ARGS[@]}" \
  -scheme "$IOS_SCHEME" \
  -configuration Debug \
  -destination "platform=iOS Simulator,name=$IOS_SIMULATOR" \
  test
