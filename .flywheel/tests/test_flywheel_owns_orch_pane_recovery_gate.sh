#!/usr/bin/env bash
set -euo pipefail

HOOK="$HOME/.claude/hooks/flywheel-orch-flywheel-owns-orch-pane-recovery-gate.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/flywheel-owns-orch-recovery.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
case_pass=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }
case_ok() { pass "$1"; case_pass=$((case_pass + 1)); }

payload() {
  jq -nc --arg text "$1" '{tool_name:"Bash",tool_response:{stdout:$text}}'
}

run_hook() {
  local label="$1" text="$2" want="$3" rc out
  out="$TMP/$label.json"
  set +e
  payload "$text" | "$HOOK" --json >"$out"
  rc=$?
  set -e
  [[ "$rc" -eq 0 ]] || fail "$label rc=$rc"
  if [[ "$want" == warn ]]; then
    if jq -e '.decision == "warn" and (.reason | test("WARN \\[flywheel-owns-orch-pane-recovery\\]"))' "$out" >/dev/null; then
      case_ok "$label"
    else
      fail "$label expected warn"
      jq . "$out" >&2 || true
    fi
  elif [[ -s "$out" ]]; then
    fail "$label expected no warn"
    jq . "$out" >&2 || true
  else
    case_ok "$label"
  fi
}

bash -n "$HOOK" && pass "hook_syntax" || fail "hook_syntax"
"$HOOK" --info --json | jq -e '.mode == "advisory" and .blocks == false' >/dev/null && pass "hook_info" || fail "hook_info"
"$HOOK" --examples >/dev/null && pass "hook_examples" || fail "hook_examples"

run_hook case_1_refused_without_permit "I won't respawn skillos:1 because never respawn orchestrator_pane" warn
run_hook case_2_respawn_after_permit "respawning skillos:1 after permit gate PASS" allow
run_hook case_3_permit_script_proof "permit_gate=PASS, proceeding with peer-orch-respawn-permit.sh" allow
run_hook case_4_self_respawn_attempt "let me respawn flywheel:1 itself" warn
run_hook case_5_calling_in_sick_ok "calling-in-sick: peer orch will respawn flywheel:1" allow
run_hook case_6_unrelated_empty "" allow

set +e
printf '{not-json\n' | "$HOOK" --json >"$TMP/malformed.out" 2>"$TMP/malformed.err"
rc=$?
set -e
if [[ "$rc" -eq 0 && ! -s "$TMP/malformed.out" && ! -s "$TMP/malformed.err" ]]; then
  case_ok "case_7_malformed_json_silent"
else
  fail "case_7_malformed_json_silent rc=$rc"
fi

printf 'Flywheel owns orch pane recovery cases: %s/7 passed\n' "$case_pass"
printf 'Summary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$case_pass" -eq 7 && "$fail_count" -eq 0 ]]
