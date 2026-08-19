#!/usr/bin/env bash
set -euo pipefail

./scripts/build-ios.sh
./scripts/test-ios.sh

echo
echo "VERIFY_OK: build and automated tests passed."
echo "If this task changes UI, launch the app manually from Xcode and perform the manual UI check before marking it done."
