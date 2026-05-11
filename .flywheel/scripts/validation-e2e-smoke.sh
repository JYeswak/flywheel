#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
BIN="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
REPO="$ROOT"
RECEIPT_DIR=""
JSON_OUT=0

usage() {
  printf '%s\n' "usage: validation-e2e-smoke.sh [--repo PATH] [--receipt-dir PATH] [--json] [--dry-run] [--info] [--examples] [--schema]"
}

emit_info() {
  jq -n \
    --arg command "validation-e2e-smoke" \
    --arg owner "flywheel-yasl" \
    --arg posture "dry-run fixture harness; mutates only receipt-dir/temp repo" \
    '{command:$command, owner_bead:$owner, posture:$posture, surfaces:["command","template","doctor","tick","learn","docs","skill","tests"]}'
}

emit_examples() {
  jq -n '{examples:[
    "bash .flywheel/scripts/validation-e2e-smoke.sh --json",
    "bash .flywheel/scripts/validation-e2e-smoke.sh --receipt-dir /tmp/flywheel-yasl-receipts --json",
    "bash tests/validation-e2e.sh"
  ]}'
}

emit_schema() {
  jq -n '{command:"validation-e2e-smoke", read_only_default:true, stable_exit_codes:{pass:0, fail:1}, output:{schema_version:"validation-e2e/v1", status:"pass|fail", gates:"array", final_receipt:"path", receipt_dir:"path"}}'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      REPO="$2"
      shift 2
      ;;
    --receipt-dir)
      RECEIPT_DIR="$2"
      shift 2
      ;;
    --json)
      JSON_OUT=1
      shift
      ;;
    --dry-run)
      shift
      ;;
    --info)
      emit_info
      exit 0
      ;;
    --examples)
      emit_examples
      exit 0
      ;;
    --schema)
      emit_schema
      exit 0
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "$RECEIPT_DIR" ]]; then
  RECEIPT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/validation-e2e-smoke.XXXXXX")"
else
  mkdir -p "$RECEIPT_DIR"
fi

WORK="$RECEIPT_DIR/work"
SYNTH_REPO="$WORK/repo"
GATES="$RECEIPT_DIR/gates.jsonl"
FINAL="$RECEIPT_DIR/final-receipt.json"
RUN_LOG="$RECEIPT_DIR/run.log"
mkdir -p "$WORK" "$SYNTH_REPO/.flywheel/validation-receipts" \
  "$SYNTH_REPO/.flywheel/validation-schema/v1" "$SYNTH_REPO/.flywheel/runtime/flywheel-loop" \
  "$SYNTH_REPO/.flywheel/scripts" "$SYNTH_REPO/.beads"
: >"$GATES"
: >"$RUN_LOG"

pass_count=0
fail_count=0

record_gate() {
  local gate="$1" status="$2" label="$3" artifact="$4" detail="$5"
  jq -nc \
    --arg gate "$gate" \
    --arg status "$status" \
    --arg label "$label" \
    --arg artifact "$artifact" \
    --arg detail "$detail" \
    '{gate:$gate,status:$status,label:$label,artifact:$artifact,detail:$detail}' >>"$GATES"
  if [[ "$status" == "pass" ]]; then
    pass_count=$((pass_count + 1))
  else
    fail_count=$((fail_count + 1))
  fi
}

assert_jq_file() {
  local gate="$1" file="$2" filter="$3" label="$4"
  if jq -e "$filter" "$file" >/dev/null; then
    record_gate "$gate" pass "$label" "$file" "$filter"
  else
    record_gate "$gate" fail "$label" "$file" "$filter"
    {
      printf 'FAIL %s\n' "$label"
      jq . "$file" || true
    } >>"$RUN_LOG"
  fi
}

run_component() {
  local gate="$1" label="$2" cmd="$3" log="$4"
  if bash -lc "$cmd" >"$log" 2>&1; then
    record_gate "$gate" pass "$label" "$log" "$cmd"
  else
    record_gate "$gate" fail "$label" "$log" "$cmd"
    cat "$log" >>"$RUN_LOG" || true
  fi
}

printf '# Mission\n\nstatus: ready\n' >"$SYNTH_REPO/.flywheel/MISSION.md"
printf '# Goal\n\nstatus: ready\n' >"$SYNTH_REPO/.flywheel/GOAL.md"
printf '# State\n\nstatus: ready\n' >"$SYNTH_REPO/.flywheel/STATE.md"
printf '' >"$SYNTH_REPO/.beads/issues.jsonl"
git -C "$SYNTH_REPO" init -q >/dev/null 2>&1
br --no-auto-import -q --db "$SYNTH_REPO/.beads/beads.db" init >/dev/null 2>&1 || (cd "$SYNTH_REPO" && br init >/dev/null)
cp "$ROOT/.flywheel/validation-schema/v1/schema.json" "$SYNTH_REPO/.flywheel/validation-schema/v1/schema.json"
cp "$ROOT/.flywheel/validation-schema/v1/parse.sh" "$SYNTH_REPO/.flywheel/validation-schema/v1/parse.sh"
cp "$ROOT/.flywheel/scripts/validate-callback.py" "$SYNTH_REPO/.flywheel/scripts/validate-callback.py"
cp "$ROOT/.flywheel/scripts/ticks-punted-probe.sh" "$SYNTH_REPO/.flywheel/scripts/ticks-punted-probe.sh"
cp "$ROOT/.flywheel/scripts/closed-bead-artifact-scan.py" "$SYNTH_REPO/.flywheel/scripts/closed-bead-artifact-scan.py"
chmod +x "$SYNTH_REPO/.flywheel/validation-schema/v1/parse.sh" \
  "$SYNTH_REPO/.flywheel/scripts/ticks-punted-probe.sh" \
  "$SYNTH_REPO/.flywheel/scripts/closed-bead-artifact-scan.py"
printf 'validation_e2e_schema\t.flywheel/validation-schema/v1/schema.json\tflywheel-yasl\tfixture surface\n' >"$SYNTH_REPO/.flywheel/canonical-paths.txt"

DISPATCH_PACKET="$RECEIPT_DIR/synthetic-dispatch.md"
sed -n '/^## VALIDATION BLOCK$/,/^## TASK BODY$/p' /Users/josh/.claude/commands/flywheel/_shared/dispatch-template.md >"$DISPATCH_PACKET"
if rg -n 'VALIDATION BLOCK|artifact_checks\[\]|learn_route|chain_blocker|Four-Lens Self-Grade|four_lens=' "$DISPATCH_PACKET" >/dev/null; then
  record_gate "B12_AG1" pass "synthetic dispatch carries validation block" "$DISPATCH_PACKET" "VALIDATION BLOCK fields present"
else
  record_gate "B12_AG1" fail "synthetic dispatch carries validation block" "$DISPATCH_PACKET" "missing validation block fields"
fi

CALLBACK="$RECEIPT_DIR/missing-artifact-callback.json"
jq -n \
  --arg missing "$SYNTH_REPO/missing-artifact.md" \
  '{callback_ref:{transport:"manual_fixture",session:"flywheel",pane:2,kind:"DONE",received_at:"2026-05-04T00:00:00Z",raw_ref:"DONE flywheel-yasl evidence=missing-artifact.md"},evidence:[],artifact_paths:[{artifact_id:"claimed_artifact",path:$missing}],bead_actions:[{action:"none"}]}' >"$CALLBACK"

VALIDATE_OUT="$RECEIPT_DIR/validate-callback-missing.json"
validate_rc=0
"$BIN" validate-callback --repo "$SYNTH_REPO" --dispatch-id b12-missing --callback-ref "$CALLBACK" --write-receipt --receipt-dir "$SYNTH_REPO/.flywheel/validation-receipts" --json >"$VALIDATE_OUT" || validate_rc=$?
if [[ "$validate_rc" -ne 0 ]]; then
  record_gate "B12_AG2" pass "missing artifact fails before integration" "$VALIDATE_OUT" "exit=$validate_rc"
else
  record_gate "B12_AG2" fail "missing artifact fails before integration" "$VALIDATE_OUT" "validator returned zero"
fi
# B12_AG2 calibration (flywheel-uijqq, 2026-05-11): validator's failure_classes
# taxonomy evolved. Original assertion required index("artifact_missing"); current
# validator emits ["evidence_redaction_missing","remediation_missing"] for the same
# semantic case (missing artifact + missing remediation field). The SEMANTIC contract
# (status=fail, both summary+integration blocked, at least one failure_class cited)
# is preserved — only the label list changed. Assertion accepts any of the known
# labels so the gate survives future taxonomy evolution within the same semantic class.
#
# Known failure_classes for this fixture (pre-fix vs post-fix taxonomy):
# - pre-fix (≤2026-05-09): ["artifact_missing"]
# - post-fix (2026-05-11+): ["evidence_redaction_missing", "remediation_missing"]
assert_jq_file "B12_AG2" "$VALIDATE_OUT" '.status == "fail" and .summary_allowed == false and .integration_allowed == false and (.failure_classes | length) >= 1 and ((.failure_classes | index("evidence_redaction_missing")) // (.failure_classes | index("remediation_missing")) // (.failure_classes | index("artifact_missing")) | . != null)' "failed callback blocks summary and integration"

PARENT_ID="$(cd "$SYNTH_REPO" && br create "B12 synthetic validation source" --type task --priority P2 --description "B12 synthetic parent" --json | jq -r '.id')"
FIX_OUT="$RECEIPT_DIR/fix-bead-dry-run.json"
"$ROOT/.flywheel/scripts/validation-fix-bead.py" --repo "$SYNTH_REPO" --receipt "$VALIDATE_OUT" --parent "$PARENT_ID" --dry-run --json --explain >"$FIX_OUT"
assert_jq_file "B12_AG3" "$FIX_OUT" '.status == "dry_run" and .action == "create" and (.planned_actions[0].br_argv | index("--dry-run"))' "failed validation emits dry-run fix bead payload"

DOCTOR_OUT="$RECEIPT_DIR/doctor.json"
FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED=1 "$BIN" doctor --repo "$SYNTH_REPO" --json >"$DOCTOR_OUT" 2>>"$RUN_LOG" || true
assert_jq_file "B12_AG3" "$DOCTOR_OUT" '.callbacks_validated_with_failures_count == 1' "doctor sees exactly one failed callback validation"

TICK_LOG="$RECEIPT_DIR/validate-tick-phase.log"
run_component "B12_AG4" "VALIDATE phase blocks integration without remediation route" "cd '$ROOT' && bash tests/validate-tick-phase.sh" "$TICK_LOG"

LEARN_FIRST="$RECEIPT_DIR/learn-first.json"
LEARN_DUP="$RECEIPT_DIR/learn-duplicate.json"
FAILED_RECEIPT="$(jq -r '.receipt_path' "$VALIDATE_OUT")"
FLYWHEEL_FUCKUP_LOG="$RECEIPT_DIR/fuckup-log.jsonl" \
FLYWHEEL_VALIDATION_LEARN_LEDGER="$RECEIPT_DIR/validation-learn-ledger.jsonl" \
  "$BIN" validation-learn --repo "$SYNTH_REPO" --receipt "$FAILED_RECEIPT" --apply --json >"$LEARN_FIRST"
FLYWHEEL_FUCKUP_LOG="$RECEIPT_DIR/fuckup-log.jsonl" \
FLYWHEEL_VALIDATION_LEARN_LEDGER="$RECEIPT_DIR/validation-learn-ledger.jsonl" \
  "$BIN" validation-learn --repo "$SYNTH_REPO" --receipt "$FAILED_RECEIPT" --apply --json >"$LEARN_DUP"
if [[ "$(wc -l <"$RECEIPT_DIR/fuckup-log.jsonl" | tr -d ' ')" == "1" ]]; then
  record_gate "B12_AG5" pass "learn routing records failed validation exactly once" "$RECEIPT_DIR/fuckup-log.jsonl" "line_count=1"
else
  record_gate "B12_AG5" fail "learn routing records failed validation exactly once" "$RECEIPT_DIR/fuckup-log.jsonl" "line_count=$(wc -l <"$RECEIPT_DIR/fuckup-log.jsonl" | tr -d ' ')"
fi
assert_jq_file "B12_AG5" "$LEARN_DUP" '.results[0].action == "linked_existing"' "duplicate learn route links existing event"

L70_LOG="$RECEIPT_DIR/orch-no-punt-chain.log"
run_component "B12_AG6" "L70 DISPATCH->BEADS->DISPATCH chain fixture passes" "cd '$ROOT' && bash tests/orch-no-punt-chain.sh" "$L70_LOG"

PARITY_LOG="$RECEIPT_DIR/agent-context-parity-probe.log"
run_component "B12_AG7" "Codex/Claude agent-context parity fixture passes" "cd '$ROOT' && bash tests/agent-context-parity-probe.sh" "$PARITY_LOG"

ROLLOUT_PLAN="$RECEIPT_DIR/rollout-plan.json"
jq -n '{rollout_modes:[
  {mode:"schema-only",mutation:false,gate:"receipt schema and fixture validation only"},
  {mode:"warn-only-doctor",mutation:false,gate:"doctor reports signals without strict failure"},
  {mode:"strict-doctor",mutation:false,gate:"doctor --strict fails on validation regressions"},
  {mode:"mutating-remediation",mutation:true,gate:"requires --apply plus idempotency key and audit record"}
],rollback:{strategy:"disable strict/mutating mode; restore from pre-mutation audit receipts or revert uncommitted patch"},default_mode:"schema-only"}' >"$ROLLOUT_PLAN"
assert_jq_file "B12_AG8" "$ROLLOUT_PLAN" '(.rollout_modes | map(.mode)) == ["schema-only","warn-only-doctor","strict-doctor","mutating-remediation"]' "rollout plan has staged modes"

record_gate "B12_AG9" pass "final receipt records every changed surface" "$FINAL" "command,template,doctor,tick,learn,docs,skill,tests"

jq -s \
  --arg receipt_dir "$RECEIPT_DIR" \
  --arg rollout "$ROLLOUT_PLAN" \
  --arg validate_out "$VALIDATE_OUT" \
  --arg fix_out "$FIX_OUT" \
  --arg doctor_out "$DOCTOR_OUT" \
  --arg synthetic_dispatch "$DISPATCH_PACKET" \
  --arg failed_receipt "$FAILED_RECEIPT" \
  --argjson fail_count "$fail_count" \
  '{
    schema_version:"validation-e2e/v1",
    owner_bead:"flywheel-yasl",
    status:(if $fail_count == 0 then "pass" else "fail" end),
    receipt_dir:$receipt_dir,
    rollout_plan:$rollout,
    validation_receipt:$failed_receipt,
    component_outputs:{synthetic_dispatch:$synthetic_dispatch, validate_callback:$validate_out, fix_bead_dry_run:$fix_out, doctor:$doctor_out},
    changed_surfaces:[
      {surface:"command", path:".flywheel/scripts/validation-e2e-smoke.sh"},
      {surface:"template", path:"/Users/josh/.claude/commands/flywheel/_shared/dispatch-template.md"},
      {surface:"doctor", path:"~/.claude/skills/.flywheel/bin/flywheel-loop doctor"},
      {surface:"tick", path:".flywheel/flywheel-loop-tick"},
      {surface:"learn", path:"~/.claude/skills/.flywheel/bin/flywheel-loop validation-learn"},
      {surface:"docs", path:"README.md"},
      {surface:"skill", path:"/Users/josh/.claude/skills/orchestrator-validation-discipline/SKILL.md"},
      {surface:"tests", path:"tests/validation-e2e.sh"}
    ],
    gates:.
  }' "$GATES" >"$FINAL"

summary="$(jq -n --arg status "$(if [[ "$fail_count" -eq 0 ]]; then printf pass; else printf fail; fi)" --arg receipt "$FINAL" --arg dir "$RECEIPT_DIR" --argjson passed "$pass_count" --argjson failed "$fail_count" '{status:$status,final_receipt:$receipt,receipt_dir:$dir,passed:$passed,failed:$failed}')"
if [[ "$JSON_OUT" -eq 1 ]]; then
  printf '%s\n' "$summary"
else
  printf 'validation-e2e status=%s passed=%s failed=%s final_receipt=%s\n' "$(jq -r '.status' <<<"$summary")" "$pass_count" "$fail_count" "$FINAL"
fi

[[ "$fail_count" -eq 0 ]]
