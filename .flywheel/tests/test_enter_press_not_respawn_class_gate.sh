#!/usr/bin/env bash
set -euo pipefail

HOOK="$HOME/.claude/hooks/flywheel-orch-enter-press-not-respawn-class-gate.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/enter-press-not-respawn.XXXXXX")"
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

chev="$(printf '\342\200\272')"

run_hook case_1_oom_citation_ok \
  "respawning pane because oom-killed in scrollback" \
  allow
run_hook case_2_pane_gone_citation_ok \
  "respawning pane because pane is gone" \
  allow
run_hook case_3_respawn_without_citation_warn \
  "respawning pane to clear queued state" \
  warn respawn-proposed-without-trauma-class-citation
run_hook case_4_queued_prompt_visible_warn \
  "respawn pane 4 - ${chev} Run /review queued and codex Working" \
  warn respawn-proposed-with-queued-prompt-visible
run_hook case_5_capacity_halt_warn \
  "respawn alps:2 - selected model is at capacity" \
  warn respawn-proposed-with-capacity-halt-text
run_hook case_6_bare_enter_ok \
  "bare-Enter via ntm send to clear queued chevron" \
  allow
run_hook case_7_auto_continue_ok \
  "auto-continue primitive fired on capacity-halt" \
  allow
run_hook case_8_kitty_12645_ok \
  "#12645 kitty-keyboard Enter drop confirmed; respawning" \
  allow
run_hook case_9_empty_unrelated_ok "" allow

set +e
printf '{not-json\n' | "$HOOK" --json >"$TMP/malformed.out" 2>"$TMP/malformed.err"
rc=$?
set -e
if [[ "$rc" -eq 0 && ! -s "$TMP/malformed.out" && ! -s "$TMP/malformed.err" ]]; then
  case_ok "case_10_malformed_json_silent"
else
  fail "case_10_malformed_json_silent rc=$rc"
fi

printf 'Enter-press-not-respawn cases: %s/10 passed\n' "$case_pass"
printf 'Summary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$case_pass" -eq 10 && "$fail_count" -eq 0 ]]
