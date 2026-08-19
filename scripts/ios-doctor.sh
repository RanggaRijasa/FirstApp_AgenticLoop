#!/usr/bin/env bash
set -euo pipefail

echo "== Toolchain =="
command -v xcodebuild >/dev/null || { echo "ERROR: xcodebuild not found"; exit 1; }
command -v xcrun >/dev/null || { echo "ERROR: xcrun not found"; exit 1; }
command -v git >/dev/null || { echo "ERROR: git not found"; exit 1; }
command -v omp >/dev/null || { echo "ERROR: omp not found"; exit 1; }

xcodebuild -version
swift --version | head -n 1
git --version
omp --version

echo
echo "== Xcode containers found =="
find . -maxdepth 2 \( -name '*.xcodeproj' -o -name '*.xcworkspace' \) -print | sort

echo
echo "== Available simulators =="
xcrun simctl list devices available

echo
echo "== Project-local config =="
if [[ -f .agent/local.env ]]; then
  # shellcheck disable=SC1091
  source .agent/local.env
  echo "IOS_CONTAINER=${IOS_CONTAINER:-<unset>}"
  echo "IOS_SCHEME=${IOS_SCHEME:-<unset>}"
  echo "IOS_SIMULATOR=${IOS_SIMULATOR:-<unset>}"
else
  echo "Missing .agent/local.env"
  echo "Copy .agent/local.env.example to .agent/local.env and edit it."
fi
