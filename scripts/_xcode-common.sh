#!/usr/bin/env bash
set -euo pipefail

# Pre-injected environment variables always win. The v3 .agent/local.env file is
# only a fallback for values the caller did not already provide.
if [[ -f .agent/local.env ]]; then
  while IFS='=' read -r _key _value; do
    _key="${_key%$'\r'}"
    [[ "$_key" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || continue
    # Never overwrite a value already present in the environment.
    [[ -z "${!_key:-}" ]] || continue
    _value="${_value%$'\r'}"
    # Strip surrounding quotes, mirroring shell sourcing of KEY="value" lines.
    _value="${_value#\"}"; _value="${_value%\"}"
    _value="${_value#\'}"; _value="${_value%\'}"
    export "$_key=$_value"
  done < .agent/local.env
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
