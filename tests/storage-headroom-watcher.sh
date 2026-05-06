#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
WATCHER="$ROOT/.flywheel/scripts/storage-headroom-watcher.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/storage-headroom-watcher-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1"; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" || true
  fi
}

fixture() {
  local path="$1" free_gb="$2" protected="${3:-0}"
  jq -nc \
    --argjson free_gb "$free_gb" \
    --argjson protected "$protected" \
    --arg home "$HOME" \
    --arg repo "$ROOT" \
    '{
      schema_version:"storage-headroom-watcher.fixture.v1",
      disk_total_gb:926,
      disk_free_gb:$free_gb,
      disk_free_pct:($free_gb / 926 * 100),
      category_freed_mb:{
        "docker-model-runner-image-revert":5120,
        "docker-unused-images":5120,
        "pnpm-store-prune":5120,
        "go-clean-cache-modcache":2048,
        "ml-model-cache-files":1024
      }
    }
    + (if $protected == 1 then {
      candidate_paths:[
        ($home + "/.local/bin/ntm.bak.20260505"),
        ($home + "/.local/share/flywheel-watchers/backups/state.json"),
        ($repo + "/.git/config"),
        ($repo + "/.beads/issues.jsonl")
      ]
    } else {} end)' >"$path"
}

fixture_with_categories() {
  local path="$1" free_gb="$2" json="$3"
  jq -nc --argjson free_gb "$free_gb" --argjson categories "$json" '{
    schema_version:"storage-headroom-watcher.fixture.v1",
    disk_total_gb:926,
    disk_free_gb:$free_gb,
    disk_free_pct:($free_gb / 926 * 100),
    category_freed_mb:$categories
  }' >"$path"
}

export STORAGE_HEADROOM_WATCHER_LEDGER="$TMP/watcher.jsonl"
export STORAGE_HEADROOM_WATCHER_CONTRACT_LEDGER="$TMP/contract.jsonl"
export STORAGE_HEADROOM_WATCHER_FUCKUP_LOG="$TMP/fuckups.jsonl"
export STORAGE_HEADROOM_WATCHER_NOW="2026-05-05T04:00:00Z"

bash -n "$WATCHER" && pass "watcher_syntax" || fail "watcher_syntax"

"$WATCHER" --doctor --json >"$TMP/doctor.out"
assert_jq "$TMP/doctor.out" '.schema_version == "storage-headroom-watcher.doctor.v1" and .storage_headroom_watcher_apply_count_24h == 0 and .substrate_loop_contract_self_row_action == "appended"' "doctor_bootstraps_contract_row"
assert_jq "$STORAGE_HEADROOM_WATCHER_CONTRACT_LEDGER" '.primitive_name == "storage-headroom-watcher" and .measurement_field == "storage_headroom_watcher_apply_count_24h"' "contract_self_row_written"

fixture "$TMP/healthy.json" 70
"$WATCHER" --fixture "$TMP/healthy.json" --json >"$TMP/healthy.out"
assert_jq "$TMP/healthy.out" '.status == "ok" and .dry_run == true and .apply == false and (.categories_to_prune | length) == 0' "healthy_above_buffer_noop"

fixture "$TMP/between.json" 52 1
"$WATCHER" --fixture "$TMP/between.json" --buffer-gb 55 --json >"$TMP/between.out"
assert_jq "$TMP/between.out" '.status == "ok" and .dry_run == true and .apply == false and (.categories_to_prune | length) == 5 and (.protected_candidate_paths_skipped | length) == 4 and (.protected_path_violations | length) == 0' "between_threshold_and_buffer_dry_run_only"

fixture "$TMP/low.json" 48
"$WATCHER" --fixture "$TMP/low.json" --auto --trigger tick --json >"$TMP/low.out"
assert_jq "$TMP/low.out" '.status == "ok" and .apply == true and .dry_run == false and .disk_free_gb_before == 48 and .disk_free_gb_after >= 60 and (.categories_pruned | length) >= 3' "auto_apply_below_50_reaches_stop"

multi='{"docker-model-runner-image-revert":3072,"docker-unused-images":4096,"pnpm-store-prune":8192,"go-clean-cache-modcache":1024,"ml-model-cache-files":1024}'
fixture_with_categories "$TMP/multi.json" 45 "$multi"
"$WATCHER" --fixture "$TMP/multi.json" --apply --buffer-gb 55 --stop-gb 60 --json >"$TMP/multi.out"
assert_jq "$TMP/multi.out" '.status == "ok" and .apply == true and (.categories_pruned | length) >= 3 and .disk_free_gb_after >= 55' "apply_continues_until_stop_or_exhausted"

small='{"docker-model-runner-image-revert":512,"docker-unused-images":512,"pnpm-store-prune":512,"go-clean-cache-modcache":512,"ml-model-cache-files":512}'
fixture_with_categories "$TMP/exhausted.json" 40 "$small"
set +e
"$WATCHER" --fixture "$TMP/exhausted.json" --apply --buffer-gb 55 --stop-gb 60 --json >"$TMP/exhausted.out"
exhausted_rc=$?
set -e
if [[ "$exhausted_rc" -ne 0 ]]; then
  pass "exhausted_returns_nonzero"
else
  fail "exhausted_returns_nonzero"
fi
assert_jq "$TMP/exhausted.out" '.status == "fail" and .exhausted == true and .fuckup_append_status == "appended"' "exhausted_logs_fuckup"
assert_jq "$STORAGE_HEADROOM_WATCHER_FUCKUP_LOG" '.class == "storage-headroom-prune-exhausted" and .bead == "flywheel-3fzcm"' "fuckup_log_row_written"

"$WATCHER" validate protected-paths --json >"$TMP/protected.out"
assert_jq "$TMP/protected.out" '.status == "ok" and all(.samples[]; .protected == true)' "protected_path_validator"

"$WATCHER" --doctor --json >"$TMP/doctor-after.out"
assert_jq "$TMP/doctor-after.out" '.storage_headroom_watcher_apply_count_24h == 3 and .storage_headroom_watcher_freed_mb_24h > 0 and .storage_headroom_watcher_buffer_gb == 55' "doctor_reports_24h_apply_stats"

printf '\nSummary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
