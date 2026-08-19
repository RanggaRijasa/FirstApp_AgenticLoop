#!/usr/bin/env bash
set -euo pipefail

if [[ ! -f .agent/local.env ]]; then
  echo "ERROR: .agent/local.env not found"
  echo "Run: cp .agent/local.env.example .agent/local.env"
  exit 1
fi

# shellcheck disable=SC1091
source .agent/local.env

: "${IOS_CONTAINER:?Set IOS_CONTAINER in .agent/local.env}"
: "${IOS_SCHEME:?Set IOS_SCHEME in .agent/local.env}"

if [[ "$IOS_CONTAINER" == *.xcworkspace ]]; then
  XCODE_CONTAINER_ARGS=(-workspace "$IOS_CONTAINER")
elif [[ "$IOS_CONTAINER" == *.xcodeproj ]]; then
  XCODE_CONTAINER_ARGS=(-project "$IOS_CONTAINER")
else
  echo "ERROR: IOS_CONTAINER must end in .xcodeproj or .xcworkspace"
  exit 1
fi
