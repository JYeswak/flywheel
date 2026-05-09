#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)"
ARTIFACT="$ROOT/.flywheel/audit/flywheel-215/jeff_filing_A6_validation.md"
NEXT="$ROOT/.flywheel/audit/flywheel-215/bv-robot-next.json"
ALERTS="$ROOT/.flywheel/audit/flywheel-215/bv-robot-alerts.json"
test -s "$ARTIFACT"
test -s "$NEXT"
test -s "$ALERTS"
grep -q '^`local_input_gap`$' "$ARTIFACT"
jq -e '.id == "flywheel-se3h.1" and .data_hash == "91de0ea1a646e9f0"' "$NEXT" >/dev/null
jq -e '.summary.total == 2 and ([.alerts[].issue_id] | index("flywheel-se3h.1") | not)' "$ALERTS" >/dev/null
printf 'OK_bv_A6_local_input_gap\n'
