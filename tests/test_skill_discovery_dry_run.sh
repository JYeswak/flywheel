#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
BIN="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/skill-discovery-dry-run.XXXXXX")"
export TMP
trap 'python3 -c "import os, shutil; shutil.rmtree(os.environ[\"TMP\"], ignore_errors=True)"' EXIT

pass_count=0
fail_count=0
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

ledger="$TMP/skill-discoveries.jsonl"
export FLYWHEEL_SKILL_DISCOVERY_PATH="$ledger"
export APPEND_SAFE_WRITE="$ROOT/.flywheel/scripts/append-safe-write.sh"

"$BIN" skill-discovery append \
  --candidate-skill-name fleet-liveness-watchdog \
  --discovery-kind pattern-emerged \
  --session fixture \
  --worker-pane 2 \
  --worker-kind codex \
  --task-context fixture \
  --evidence-json '{"source":"test"}' \
  --dry-run \
  --json >"$TMP/dry-run.json"
jq -e '.dry_run == true and (.row.discovery_id | startswith("sd-"))' "$TMP/dry-run.json" >/dev/null \
  && pass "01_bead_dry_run_predicate" || fail "01_bead_dry_run_predicate"
test ! -e "$ledger" && pass "02_dry_run_no_file_write" || fail "02_dry_run_no_file_write"

set +e
"$BIN" skill-discovery append \
  --candidate-skill-name invalid-kind-case \
  --discovery-kind not-a-kind \
  --session fixture \
  --worker-pane 2 \
  --worker-kind codex \
  --task-context fixture \
  --evidence-json '{}' \
  --dry-run \
  --json >"$TMP/invalid.json"
invalid_rc=$?
set -e
if [[ "$invalid_rc" -ne 0 ]] && jq -e '.reason=="invalid_discovery_kind" and (.allowed_discovery_kinds | length == 7)' "$TMP/invalid.json" >/dev/null; then
  pass "03_invalid_kind_machine_error"
else
  fail "03_invalid_kind_machine_error"
  cat "$TMP/invalid.json" >&2 || true
fi

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$pass_count" -eq 3 && "$fail_count" -eq 0 ]]
