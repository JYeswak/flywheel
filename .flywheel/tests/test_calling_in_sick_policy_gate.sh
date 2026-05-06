#!/usr/bin/env bash
set -euo pipefail

HOOK="$HOME/.claude/hooks/flywheel-orch-calling-in-sick-policy-gate.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/calling-in-sick-policy.XXXXXX")"
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
  local label="$1" text="$2" want="$3" pattern="${4:-}" out rc
  out="$TMP/$label.json"
  set +e
  payload "$text" | "$HOOK" --json >"$out"
  rc=$?
  set -e
  [[ "$rc" -eq 0 ]] || fail "$label rc=$rc"
  if [[ "$want" == warn ]]; then
    if jq -e --arg pattern "$pattern" '.decision == "warn" and (.reason | contains($pattern))' "$out" >/dev/null; then
      case_ok "$label"
    else
      fail "$label expected warn for $pattern"
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

run_hook case_1_worker_freeze_to_joshua \
  "notify Joshua - flywheel:2 worker pane is frozen" \
  warn worker-failure-escalated-to-joshua-instead-of-detector
run_hook case_2_worker_detector_recovery_ok \
  "frozen-pane-detector flagged flywheel:2; auto-recovery in progress" \
  allow
run_hook case_3_peer_orch_to_joshua \
  "skillos:1 orch is dead, paging Joshua" \
  warn orch-failure-escalated-to-joshua-instead-of-flywheel1
run_hook case_4_peer_orch_flywheel1_permit_ok \
  "skillos:1 orch dead - flywheel:1 invoking peer-orch-respawn-permit.sh" \
  allow
run_hook case_5_flywheel1_self_failure_no_broadcast \
  "flywheel:1 stepping out, going offline" \
  warn flywheel1-self-failure-not-broadcast-to-peer-orchs
run_hook case_6_flywheel1_broadcast_ok \
  "flywheel:1 stepping out - broadcasting to peer-orch mesh: alps:1/mobile-eats:1/vrtx:1/skillos:1" \
  allow
run_hook case_7_empty_unrelated_ok "" allow

set +e
printf '{not-json\n' | "$HOOK" --json >"$TMP/malformed.out" 2>"$TMP/malformed.err"
rc=$?
set -e
if [[ "$rc" -eq 0 && ! -s "$TMP/malformed.out" && ! -s "$TMP/malformed.err" ]]; then
  case_ok "case_8_malformed_json_silent"
else
  fail "case_8_malformed_json_silent rc=$rc"
fi

printf 'Calling-in-sick policy cases: %s/8 passed\n' "$case_pass"
printf 'Summary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$case_pass" -eq 8 && "$fail_count" -eq 0 ]]
