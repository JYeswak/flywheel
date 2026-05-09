#!/usr/bin/env bash
set -euo pipefail

/Users/josh/Developer/skillos/.flywheel/scripts/reap-pane-callbacks.py \
  --repo /Users/josh/Developer/skillos \
  --capture-text 'DONE skillos-v1q2-probe task_id=skillos-v1q2-probe-123 verdict=PASS tests=PASS' \
  --received-at 2026-05-09T08:45:00Z \
  --json
