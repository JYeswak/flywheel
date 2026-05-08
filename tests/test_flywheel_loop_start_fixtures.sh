#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
FIX="$ROOT/tests/fixtures/flywheel-loop"
TMP="$(mktemp -d -t 19g3.XXXXXX)"
trap 'chmod -R u+w "$TMP" 2>/dev/null || true; find "$TMP" -mindepth 1 -delete 2>/dev/null || true; rmdir "$TMP" 2>/dev/null || true' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

for file in "$FIX"/*.json "$FIX"/*.jsonl; do
  if [[ "$file" == *.jsonl ]]; then
    while IFS= read -r row; do
      [[ -z "$row" ]] && continue
      jq -e . <<<"$row" >/dev/null
    done <"$file"
  else
    jq empty "$file"
  fi
done
pass "fixtures_parse"

assert_jq "$FIX/start-dry-run.json" '.status == "dry_run" and .dry_run == true and .live_pane_input_written == false' "dry_run_no_live_input"
assert_jq "$FIX/start-dry-run.json" '.planned_orchestrator_cadence == "30m" and .planned_worker_cadence == "30m" and (.activation_steps | index("activate_driver"))' "dry_run_reports_planned_cadence"
assert_jq "$FIX/start-apply-state.json" '.schema_version == "flywheel-loop-state/v1" and .active == true and .tier == "active_normal" and .interval == "30m" and .worker_cadence == "30m"' "state_schema_core_fields"
assert_jq "$FIX/start-apply-state.json" '.topology.orchestrator_pane == 1 and (.topology.worker_panes | length == 2) and .topology.worker_cadence == "30m" and .driver.verified == true' "state_schema_topology_driver"
assert_jq "$FIX/start-apply-registry.jsonl" '.kind == "tmux+loop" and .registration_order == "before_activation" and .activation_performed_after_registry == true and .lifecycle_state == "active"' "registry_before_activation"
assert_jq "$FIX/missing-state.json" '.status == "blocked" and .reason == "missing_flywheel_state" and (.guidance | contains("/flywheel:init"))' "missing_state_fails_with_guidance"
assert_jq "$FIX/existing-loop.json" '(.status == "refused" or .status == "idempotent") and (.reason | startswith("existing_loop")) and (.guidance | contains("no duplicate activation"))' "existing_loop_idempotent_reconcile"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 && "$pass_count" -ge 8 ]]
