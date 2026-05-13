#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/worker-tick-jsm-outcomes.sh"
TMP="$(mktemp -d -t 0x9f.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

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

write_receipt() {
  local path="$1" harness="$2" status="$3" skill="$4"
  local violations="[]"
  if [[ "$status" != "ok" ]]; then
    violations='["worker_low_socraticode_K"]'
  fi
  jq -n \
    --arg harness "$harness" \
    --arg status "$status" \
    --arg skill "$skill" \
    --argjson violations "$violations" \
    '{
      schema_version:"flywheel-worker-tick/v1",
      mode:"worker-mode",
      status:$status,
      harness:$harness,
      session:"flywheel",
      pane:3,
      task_id:"flywheel-0x9f-fixture",
      repo:"<flywheel-repo>",
      violations:$violations,
      check_results:[
        {
          id:"skill-tool-call-presence",
          observed:{skills_consulted:[$skill]}
        }
      ]
    }' >"$path"
}

bash -n "$SCRIPT" && pass "script_syntax" || fail "script_syntax"

write_receipt "$TMP/codex-ok.json" codex ok beads-workflow
jq '.check_results[0].observed.skills_consulted += ["jsm"]' "$TMP/codex-ok.json" >"$TMP/codex-ok-2.json"

"$SCRIPT" --receipt "$TMP/codex-ok-2.json" --dry-run --json >"$TMP/dry-run.json"
assert_jq "$TMP/dry-run.json" '
  .mode == "dry-run"
  and .phase_b_receipts_validated == 1
  and .events_count == 2
  and ([.planned_events[].skill] | sort == ["beads-workflow","jsm"])
  and all(.planned_events[]; .success == true and .harness == "codex")
' "dry_run_plans_per_skill"

mock_jsm="$TMP/jsm"
cat >"$mock_jsm" <<'MOCK'
#!/usr/bin/env bash
python3 - "$@" <<'PY'
import json
import os
import sys
with open(os.environ["JSM_MOCK_LOG"], "a", encoding="utf-8") as handle:
    handle.write(json.dumps(sys.argv[1:]) + "\n")
print('{"success":true}')
PY
MOCK
chmod +x "$mock_jsm"

JSM_MOCK_LOG="$TMP/jsm-args.jsonl" \
  "$SCRIPT" --receipt "$TMP/codex-ok.json" --apply --jsm-bin "$mock_jsm" --json >"$TMP/apply.json"
assert_jq "$TMP/apply.json" '.mode == "apply" and .applied_count == 1 and .applied[0].exit_code == 0' "apply_mode_records_success"
jq -s '.' "$TMP/jsm-args.jsonl" >"$TMP/jsm-args.json"
assert_jq "$TMP/jsm-args.json" '
  length == 1
  and .[0][0:4] == ["outcome","-s","beads-workflow","--success"]
  and (.[0] | index("--context")) != null
  and (.[0][(.[0] | index("--context")) + 1] | fromjson | .harness == "codex")
' "apply_mode_context_contains_harness"

mkdir -p "$TMP/replay/a" "$TMP/replay/b"
write_receipt "$TMP/replay/a/last_tick.json" claude ok beads-workflow
write_receipt "$TMP/replay/b/last_tick.json" codex violation beads-workflow
"$SCRIPT" --receipt-dir "$TMP/replay" --dry-run --json >"$TMP/drift.json"
assert_jq "$TMP/drift.json" '
  .events_count == 2
  and .harness_drift_candidates[0].skill == "beads-workflow"
  and .harness_drift_candidates[0].class == "harness_partitioned_drift_candidate"
  and (.harness_drift_candidates[0].success_harnesses | index("claude"))
  and (.harness_drift_candidates[0].failure_harnesses | index("codex"))
' "harness_partitioned_drift_candidate"

jq -n '{schema_version:"wrong/v0", mode:"worker-mode"}' >"$TMP/invalid-phase-b.json"
"$SCRIPT" --receipt "$TMP/invalid-phase-b.json" --dry-run --json >"$TMP/invalid-phase-b.out"
assert_jq "$TMP/invalid-phase-b.out" '
  .events_count == 0
  and .phase_b_receipts_validated == 0
  and .validation_errors[0].reason == "phase_b_receipt_invalid"
' "phase_c_gated_on_phase_b_shape"

write_receipt "$TMP/invalid-skill.json" codex ok "bad skill"
"$SCRIPT" --receipt "$TMP/invalid-skill.json" --dry-run --json >"$TMP/invalid-skill.out"
assert_jq "$TMP/invalid-skill.out" '
  .events_count == 0
  and .phase_b_receipts_validated == 1
  and .validation_errors[0].reason == "invalid_skill_name"
' "invalid_skill_names_do_not_poison_bandit"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
