#!/usr/bin/env bash
set -euo pipefail

command -v gh >/dev/null || { echo "gh is required"; exit 1; }

gh label create agent-ready --color 7C3AED --description "Queue this issue for the autonomous iOS agent" --force
gh label create agent-running --color 0EA5E9 --description "Autonomous iOS agent is working" --force
gh label create agent-done --color 16A34A --description "Autonomous agent completed and merged" --force
gh label create agent-blocked --color DC2626 --description "Autonomous agent stopped on a blocker" --force
gh label create agent-review-required --color F59E0B --description "Agent produced a PR but policy requires human review" --force

echo "Agent labels ready."
