#!/usr/bin/env bash
set -euo pipefail

# Multica v5 supports either pre-injected environment variables or the v3 local file.
if [[ -f .agent/local.env ]]; then
  # shellcheck disable=SC1091
  source .agent/local.env
fi

: "${IOS_CONTAINER:?Set IOS_CONTAINER in the environment or .agent/local.env}"
: "${IOS_SCHEME:?Set IOS_SCHEME in the environment or .agent/local.env}"

if [[ "$IOS_CONTAINER" == *.xcworkspace ]]; then
  XCODE_CONTAINER_ARGS=(-workspace "$IOS_CONTAINER")
elif [[ "$IOS_CONTAINER" == *.xcodeproj ]]; then
  XCODE_CONTAINER_ARGS=(-project "$IOS_CONTAINER")
else
  echo "ERROR: IOS_CONTAINER must end in .xcodeproj or .xcworkspace"
  exit 1
fi
