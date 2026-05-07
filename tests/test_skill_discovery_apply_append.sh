#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
BIN="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/skill-discovery-apply.XXXXXX")"
export TMP
trap 'python3 -c "import os, shutil; shutil.rmtree(os.environ[\"TMP\"], ignore_errors=True)"' EXIT

pass_count=0
fail_count=0
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

ledger="$TMP/state/skill-discoveries.jsonl"
export FLYWHEEL_SKILL_DISCOVERY_PATH="$ledger"
export APPEND_SAFE_WRITE="$ROOT/.flywheel/scripts/append-safe-write.sh"

"$BIN" skill-discovery append \
  --candidate-skill-name fleet-liveness-watchdog \
  --discovery-kind pattern-emerged \
  --session fixture \
  --worker-pane 2 \
  --worker-kind codex \
  --task-context fixture \
  --evidence-json '{"source":"test","line":1}' \
  --promotion-signal first_sighting \
  --should-become skill-builder-dispatch-candidate \
  --json >"$TMP/apply.json"
jq -e '.dry_run == false and .append_receipt.status == "ok" and (.row.discovery_id | startswith("sd-"))' "$TMP/apply.json" >/dev/null \
  && pass "01_apply_receipt_ok" || fail "01_apply_receipt_ok"
[[ "$(wc -l <"$ledger" | tr -d ' ')" == "1" ]] && pass "02_apply_writes_one_row" || fail "02_apply_writes_one_row"
tail -1 "$ledger" | jq -e '.discovery_id and .candidate_skill_name and .evidence and .promotion_signal' >/dev/null \
  && pass "03_bead_tail_predicate" || fail "03_bead_tail_predicate"
jq -e 'select(.ts and .discovery_id and .session and .worker_pane and .worker_kind and .task_context and .discovery_kind and .candidate_skill_name and .evidence and .promotion_signal and .should_become and (.blocking_current_work == false))' "$ledger" >/dev/null \
  && pass "04_required_fields_present" || fail "04_required_fields_present"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$pass_count" -eq 4 && "$fail_count" -eq 0 ]]
