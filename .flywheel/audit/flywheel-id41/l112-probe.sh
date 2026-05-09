#!/usr/bin/env bash
set -euo pipefail

ROOT="/Users/josh/Developer/flywheel"
STATUS="/Users/josh/.claude/commands/flywheel/status.md"

bash "$ROOT/tests/test_mission_lock_status_dashboard.sh" >/dev/null
rg -n 'Mission lock:' "$STATUS" >/dev/null
rg -n 'mission_lock_age|mission_lock_status|mission_lock_age_hours|warning_code' "$STATUS" >/dev/null
rg -n '# \| agent \| state \| ctx \| last action' "$STATUS" >/dev/null

printf '%s\n' 'OK_status_mission_lock_age_dashboard'
