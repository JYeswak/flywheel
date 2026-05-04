#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/stale-error-auto-ping.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/stale-error-auto-ping-test.XXXXXX")"
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

activity_error="$TMP/activity-error.json"
activity_waiting="$TMP/activity-waiting.json"

jq -nc '{
  success:true,
  agents:[
    {pane_idx:2,agent_type:"codex",state:"ERROR",capture_provenance:"live",capture_collected_at:"2026-05-04T03:26:00Z",state_since:"2026-05-04T03:26:00Z",detected_patterns:["failed_text","codex_chevron_prompt"]},
    {pane_idx:3,agent_type:"codex",state:"ERROR",capture_provenance:"live",capture_collected_at:"2026-05-04T03:26:00Z",state_since:"2026-05-04T03:26:00Z",detected_patterns:["api_error","codex_chevron_prompt"]},
    {pane_idx:4,agent_type:"codex",state:"ERROR",capture_provenance:"unavailable",capture_error:"capture failed",detected_patterns:["failed_text","codex_chevron_prompt"]},
    {pane_idx:5,agent_type:"codex",state:"THINKING",capture_provenance:"live",detected_patterns:["codex_working","codex_chevron_prompt"]}
  ]
}' >"$activity_error"

jq -nc '{
  success:true,
  agents:[
    {pane_idx:2,agent_type:"codex",state:"WAITING",capture_provenance:"live",capture_collected_at:"2026-05-04T03:27:00Z",detected_patterns:["codex_chevron_prompt"]},
    {pane_idx:3,agent_type:"codex",state:"WAITING",capture_provenance:"live",capture_collected_at:"2026-05-04T03:27:00Z",detected_patterns:["codex_chevron_prompt"]}
  ]
}' >"$activity_waiting"

bash -n "$SCRIPT" && pass "script syntax" || fail "script syntax"
"$SCRIPT" --help | rg -q 'stale-error-auto-ping.sh' && pass "help exposes surface" || fail "help exposes surface"
"$SCRIPT" --version | rg -q 'stale-error-auto-ping.v1' && pass "version emits v1" || fail "version emits v1"
"$SCRIPT" --info --json >"$TMP/info.json"
assert_jq "$TMP/info.json" '.schema_version == "stale-error-auto-ping.v1" and .mutation_default == "dry-run"' "info JSON"

"$SCRIPT" --activity-file "$activity_error" --panes 2,3,4 --json >"$TMP/dry.json"
assert_jq "$TMP/dry.json" '.dry_run == true and .apply == false and .stale_error_candidate_count == 2 and (.actual_actions | length) == 0' "dry-run finds only live stale-error candidates"

fake_ntm="$TMP/ntm"
cat >"$fake_ntm" <<'FAKE'
#!/usr/bin/env bash
set -euo pipefail
state_dir="${FAKE_NTM_STATE:?}"
if [[ "${1:-}" == --robot-activity=* ]]; then
  if [[ -f "$state_dir/sent" ]]; then
    cat "$state_dir/waiting.json"
  else
    cat "$state_dir/error.json"
  fi
  exit 0
fi
if [[ "${1:-}" == "send" ]]; then
  printf '%s\n' "$*" >>"$state_dir/sends.log"
  touch "$state_dir/sent"
  exit 0
fi
printf 'unexpected fake ntm args: %s\n' "$*" >&2
exit 2
FAKE
chmod +x "$fake_ntm"
cp "$activity_error" "$TMP/error.json"
cp "$activity_waiting" "$TMP/waiting.json"

FAKE_NTM_STATE="$TMP" NTM_BIN="$fake_ntm" "$SCRIPT" --session flywheel --panes 2,3 --apply --json >"$TMP/apply.json"
assert_jq "$TMP/apply.json" '.apply == true and .send_count == 2 and .post_recheck_candidate_count == 0 and .recovered_count == 2' "apply sends ping and recheck recovers"
if [[ "$(wc -l <"$TMP/sends.log")" -eq 2 ]] && rg -q -- '--no-cass-check' "$TMP/sends.log"; then
  pass "fake ntm recorded no-cass-check sends"
else
  fail "fake ntm send log missing expected sends"
fi

printf 'Summary: %d passed, %d failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
