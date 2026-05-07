#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
BIN="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/skill-discovery-lock.XXXXXX")"
export TMP
trap 'python3 -c "import os, shutil; shutil.rmtree(os.environ[\"TMP\"], ignore_errors=True)"' EXIT

pass_count=0
fail_count=0
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

ledger="$TMP/state/skill-discoveries.jsonl"
export FLYWHEEL_SKILL_DISCOVERY_PATH="$ledger"
export APPEND_SAFE_WRITE="$ROOT/.flywheel/scripts/append-safe-write.sh"
export APPEND_SAFE_TEST_SLEEP_AFTER_TAIL_MS=80

"$BIN" skill-discovery init --json >/dev/null
pids=()
for pane in 2 3 4; do
  (
    "$BIN" skill-discovery append \
      --candidate-skill-name "fleet-liveness-watchdog-$pane" \
      --discovery-kind cross-repo-shared-pattern \
      --session fixture \
      --worker-pane "$pane" \
      --worker-kind codex \
      --task-context "concurrent fixture $pane" \
      --evidence-json "{\"pane\":$pane}" \
      --json >"$TMP/append-$pane.json"
  ) &
  pids+=("$!")
done
for pid in "${pids[@]}"; do
  wait "$pid"
done

[[ "$(wc -l <"$ledger" | tr -d ' ')" == "3" ]] && pass "01_three_rows_written" || fail "01_three_rows_written"
jq -s -e 'length == 3 and all(.[]; .schema_version=="skill-discovery/v1" and (.discovery_id|startswith("sd-")))' "$ledger" >/dev/null \
  && pass "02_all_rows_valid_json" || fail "02_all_rows_valid_json"
jq -s -e '[.[].discovery_id] | unique | length == 3' "$ledger" >/dev/null \
  && pass "03_unique_discovery_ids" || fail "03_unique_discovery_ids"
jq -s -e '[.[].worker_pane] | sort == [2,3,4]' "$ledger" >/dev/null \
  && pass "04_all_worker_panes_present" || fail "04_all_worker_panes_present"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$pass_count" -eq 4 && "$fail_count" -eq 0 ]]
