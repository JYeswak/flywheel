#!/usr/bin/env bash
# tests/low-bead-threshold-detector-canonical-cli.sh
# flywheel-k8gcv.2 (wave-3-02).
# shellcheck disable=SC2015
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/low-bead-threshold-detector.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

if bash -n "$SCRIPT" 2>/dev/null; then pass "syntax"; else fail "syntax"; fi

# AG3 — wave-3 acceptance gate (.name and .version and .capabilities)
"$SCRIPT" --info --json 2>/dev/null | jq -e '.name and .version and .capabilities and (.subcommands | length >= 5)' >/dev/null && pass "AG3 --info" || fail "AG3 --info"
"$SCRIPT" --schema --json 2>/dev/null | jq -e '.input_schema and .output_schema' >/dev/null && pass "AG3 --schema" || fail "AG3 --schema"
"$SCRIPT" --examples --json 2>/dev/null | jq -e '.examples | length > 0' >/dev/null && pass "AG3 --examples" || fail "AG3 --examples"
"$SCRIPT" doctor --json 2>/dev/null | jq -e '.checks' >/dev/null && pass "AG3 doctor (mutates_state=yes)" || fail "AG3 doctor"

# Canonical subcommands
"$SCRIPT" health --json 2>/dev/null | jq -e '.command == "health" and has("ledger_row_count")' >/dev/null && pass "health envelope" || fail "health"
"$SCRIPT" validate --json 2>/dev/null | jq -e '.command == "validate" and has("ledger_row_count")' >/dev/null && pass "validate envelope" || fail "validate"
"$SCRIPT" audit --json 2>/dev/null | jq -e '.command == "audit" and has("recent")' >/dev/null && pass "audit envelope" || fail "audit"
"$SCRIPT" why --json 2>/dev/null | jq -e '.command == "why" and has("body")' >/dev/null && pass "why envelope (default topic)" || fail "why default"
"$SCRIPT" why auto-bead --json 2>/dev/null | jq -e '.topic == "auto-bead"' >/dev/null && pass "why auto-bead topic" || fail "why auto-bead"
"$SCRIPT" quickstart 2>/dev/null | jq -e '.command == "quickstart" and (.steps | length >= 3)' >/dev/null && pass "quickstart envelope" || fail "quickstart"

# repair dry-run + apply contract
"$SCRIPT" repair --scope ledger-prime --dry-run --json 2>/dev/null | jq -e '.command == "repair" and .scope == "ledger-prime" and .mode == "dry_run"' >/dev/null && pass "repair --dry-run" || fail "repair --dry-run"
"$SCRIPT" repair --scope issues-jsonl-prime --dry-run --json 2>/dev/null | jq -e '.scope == "issues-jsonl-prime"' >/dev/null && pass "repair issues-jsonl-prime" || fail "repair issues-jsonl-prime"
"$SCRIPT" repair --scope ledger-prime --apply --json >/dev/null 2>&1; rc=$?
[[ "$rc" -eq 3 ]] && pass "repair --apply without --idempotency-key returns rc=3" || fail "repair apply rc=$rc"

# Magic comment + lint
grep -q '# flywheel-cli-surface: true' "$SCRIPT" && pass "L6 magic comment present" || fail "L6 missing"
"$ROOT/.flywheel/scripts/canonical-cli-lint.sh" "$SCRIPT" >/dev/null 2>&1 && rc=0 || rc=$?
[[ "$rc" -eq 0 ]] && pass "canonical-cli-lint RC=0" || fail "lint RC=$rc"

# --help
"$SCRIPT" --help 2>&1 | head -3 | grep -qE 'usage|low-bead-threshold' && pass "--help shows usage" || fail "--help"

# --examples text mode preserved
"$SCRIPT" --examples 2>&1 | grep -q "low-bead-threshold-detector.sh check" && pass "--examples text-mode preserved" || fail "--examples text"

# Backward-compat: legacy check shape against synthetic issues.jsonl
TMP_REPO="$(mktemp -d -t low-bead.XXXXXX)"
mkdir -p "$TMP_REPO/.beads"
# RED scenario: 0 ready beads
: >"$TMP_REPO/.beads/issues.jsonl"
TMP_LEDGER="$(mktemp -t low-bead-led.XXXXXX)"

LOW_BEAD_THRESHOLD_LEDGER="$TMP_LEDGER" \
  "$SCRIPT" check --repo "$TMP_REPO" --threshold 5 --json 2>/dev/null \
  | jq -e '.signal == "RED" and .ready_count == 0' >/dev/null \
  && pass "legacy check RED on empty issues.jsonl" || fail "legacy check RED"

# GREEN scenario: 10 ready beads
python3 - "$TMP_REPO/.beads/issues.jsonl" <<'PY'
import json, sys
path = sys.argv[1]
with open(path, 'w') as f:
    for i in range(10):
        row = {"id": f"flywheel-test-{i}", "title": f"t{i}", "status": "open", "priority": 0, "issue_type": "task", "created_at": "2026-05-11T00:00:00Z", "updated_at": "2026-05-11T00:00:00Z"}
        f.write(json.dumps(row) + "\n")
PY

LOW_BEAD_THRESHOLD_LEDGER="$TMP_LEDGER" \
  "$SCRIPT" check --repo "$TMP_REPO" --threshold 5 --json 2>/dev/null \
  | jq -e '.signal == "GREEN" and .ready_count == 10' >/dev/null \
  && pass "legacy check GREEN on 10 ready beads" || fail "legacy check GREEN"

# Auto-bead on RED — idempotent (verify by-id dedupe)
: >"$TMP_REPO/.beads/issues.jsonl"
LOW_BEAD_THRESHOLD_LEDGER="$TMP_LEDGER" \
  "$SCRIPT" check --repo "$TMP_REPO" --threshold 5 --auto-bead --json 2>/dev/null \
  | jq -e '.auto_bead_filed == true and .hunt_bead_id == "flywheel-hunt-work-mission-env-skills"' >/dev/null \
  && pass "legacy --auto-bead files hunt bead on RED" || fail "legacy --auto-bead"

LOW_BEAD_THRESHOLD_LEDGER="$TMP_LEDGER" \
  "$SCRIPT" check --repo "$TMP_REPO" --threshold 5 --auto-bead --json 2>/dev/null \
  | jq -e '.auto_bead_filed == false and .auto_bead_action == "reused"' >/dev/null \
  && pass "legacy --auto-bead idempotent (reuses existing hunt bead)" || fail "legacy --auto-bead idempotent"

python3 - "$TMP_REPO/.beads/issues.jsonl" <<'PY'
import json, sys
path = sys.argv[1]
with open(path, 'w') as f:
    row = {
        "id": "flywheel-hunt-work-mission-env-skills",
        "title": "hunt-work-MISSION-env-skills",
        "status": "closed",
        "priority": 0,
        "issue_type": "task",
        "created_by": "low-bead-threshold-detector",
        "created_at": "2026-05-11T00:00:00Z",
        "updated_at": "2026-05-11T00:00:00Z",
    }
    f.write(json.dumps(row) + "\n")
PY

LOW_BEAD_THRESHOLD_LEDGER="$TMP_LEDGER" \
  "$SCRIPT" check --repo "$TMP_REPO" --threshold 5 --auto-bead --json 2>/dev/null \
  | jq -e '.auto_bead_filed == false and .auto_bead_action == "suppressed_existing_id" and .hunt_bead_id == "flywheel-hunt-work-mission-env-skills"' >/dev/null \
  && pass "legacy --auto-bead suppresses closed fixed id" || fail "legacy --auto-bead suppress closed fixed id"

# Cleanup tmp files (safe paths)
rm -f "$TMP_LEDGER" "$TMP_REPO/.beads/issues.jsonl"
rmdir "$TMP_REPO/.beads" "$TMP_REPO" 2>/dev/null || true

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
