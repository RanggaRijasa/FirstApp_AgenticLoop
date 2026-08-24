#!/usr/bin/env bash
set -euo pipefail

./scripts/build-ios.sh
./scripts/test-ios.sh

echo
echo "VERIFY_OK: build and automated tests passed."
echo "If UI changed, run ./scripts/agent-simulator-smoke.sh and review the latest screenshot before delivery."
