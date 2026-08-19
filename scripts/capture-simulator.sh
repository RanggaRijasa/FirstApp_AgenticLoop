#!/usr/bin/env bash
set -euo pipefail
mkdir -p .agent/screenshots
STAMP=$(date +%Y%m%d-%H%M%S)
OUT=".agent/screenshots/simulator-${STAMP}.png"
xcrun simctl io booted screenshot "$OUT"
echo "$OUT"
