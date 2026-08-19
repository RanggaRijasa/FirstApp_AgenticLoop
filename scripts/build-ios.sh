#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "$0")/_xcode-common.sh"

echo "Building $IOS_SCHEME from $IOS_CONTAINER ..."
xcodebuild \
  "${XCODE_CONTAINER_ARGS[@]}" \
  -scheme "$IOS_SCHEME" \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  build
