#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
CONFORMANCE="$ROOT/tests/security-control-conformance.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/security-control-fleet-smoke.XXXXXX")"
export TMP

cleanup() {
  python3 - <<'PY'
import os
import shutil
from pathlib import Path

tmp = os.environ.get("TMP")
if tmp:
    shutil.rmtree(Path(tmp), ignore_errors=True)
PY
}
trap cleanup EXIT HUP INT TERM

DRY_RUN=0
JSON_OUT=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --json) JSON_OUT=1; shift ;;
    --help|-h)
      printf 'usage: security-control-fleet-smoke.sh --dry-run [--json]\n'
      exit 0
      ;;
    *) printf 'unknown argument: %s\n' "$1" >&2; exit 2 ;;
  esac
done

[[ "$DRY_RUN" -eq 1 ]] || { printf 'FAIL fleet smoke requires --dry-run\n' >&2; exit 2; }

bash -n "$CONFORMANCE"

report="$TMP/flywheel-1gyiv/conformance-report.md"
receipt="$TMP/validation-receipts/flywheel-1gyiv-aae9be.json"
ledger="$TMP/validation-learn-ledger.jsonl"
fuckups="$TMP/fuckup-log.jsonl"

FLYWHEEL_SECURITY_CONTROL_REPORT="$report" \
FLYWHEEL_SECURITY_CONTROL_RECEIPT="$receipt" \
FLYWHEEL_VALIDATION_LEARN_LEDGER="$ledger" \
FLYWHEEL_FUCKUP_LOG="$fuckups" \
  "$CONFORMANCE" >"$TMP/conformance.out"

jq -e '.status == "pass" and .learn_route.route == "ignore"' "$receipt" >/dev/null
rg -q '^# flywheel-1gyiv Security Control Conformance Report' "$report"
if rg -q 'CANARY_TEST_' "$report" "$receipt" "$TMP/conformance.out"; then
  printf 'FAIL dry-run smoke emitted synthetic secret values\n' >&2
  exit 1
fi

if [[ "$JSON_OUT" -eq 1 ]]; then
  jq -nc \
    --arg report "$report" \
    --arg receipt "$receipt" \
    --arg ledger "$ledger" \
    '{schema_version:"security-control-fleet-smoke/v1",status:"pass",dry_run:true,live_pane_input_written:false,report_path:$report,receipt_path:$receipt,validation_learn_ledger:$ledger}'
else
  printf 'PASS security-control-fleet-smoke dry_run=true report=%s receipt=%s\n' "$report" "$receipt"
fi
