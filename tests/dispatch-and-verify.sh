#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT/.flywheel/scripts/dispatch-and-verify.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_text() {
  local file="$1" pattern="$2" name="$3"
  if grep -Eq "$pattern" "$file"; then pass "$name"; else fail "$name"; cat "$file" >&2 || true; fi
}

assert_send_count() {
  local dir="$1" expected="$2" name="$3" actual
  actual="$(wc -l <"$dir/send.log" | tr -d ' ')"
  if [[ "$actual" == "$expected" ]]; then pass "$name"; else fail "$name expected=$expected actual=$actual"; cat "$dir/send.log" >&2; fi
}

write_fake_ntm() {
  local path="$1"
  cat >"$path" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
dir="${FAKE_NTM_STATE:?}"
next_file() {
  local stem="$1" fallback="$2" count_file n file
  count_file="$dir/${stem}_calls"
  n=0
  [[ -f "$count_file" ]] && n="$(cat "$count_file")"
  n=$((n + 1))
  printf '%s\n' "$n" >"$count_file"
  file="$dir/${stem}-${n}"
  if [[ -f "$file" ]]; then cat "$file"; else cat "$fallback"; fi
}
case "${1:-}" in
  --robot-activity|--robot-activity=*)
    next_file activity "$dir/activity-default.json"
    ;;
  changes)
    next_file changes "$dir/changes-default.json"
    ;;
  conflicts)
    printf '{"status":"ok","conflict_count":0}\n'
    ;;
  copy)
    next_file copy "$dir/copy-default.txt"
    ;;
  send)
    shift
    printf '%s\n' "$*" >>"$dir/send.log"
    ;;
  *)
    printf 'unexpected fake ntm args: %s\n' "$*" >&2
    exit 9
    ;;
esac
EOF
  chmod +x "$path"
}

make_case() {
  local name="$1" dir
  dir="$TMP/$name"
  mkdir -p "$dir"
  : >"$dir/send.log"
  printf '{"agents":[{"pane":2,"state":"WAITING","velocity":0}]}\n' >"$dir/activity-default.json"
  printf '{"changed_count":0,"changes":[]}\n' >"$dir/changes-default.json"
  printf 'baseline\n' >"$dir/copy-default.txt"
  printf '%s\n' "$dir"
}

run_wrapper() {
  local dir="$1" out="$2"; shift 2
  FAKE_NTM_STATE="$dir" \
  NTM_BIN="$TMP/fake-ntm" \
  DISPATCH_VERIFY_INITIAL_SLEEP_SECONDS=0 \
  DISPATCH_VERIFY_RETRY_SLEEP_SECONDS=0 \
  DISPATCH_VERIFY_MAX_PROBES="${DISPATCH_VERIFY_MAX_PROBES:-3}" \
  "$SCRIPT" "$@" >"$out" 2>"$out.err"
}

write_fake_ntm "$TMP/fake-ntm"
printf 'dispatch packet\n' >"$TMP/dispatch.md"

"$SCRIPT" --help >"$TMP/help.txt"
assert_text "$TMP/help.txt" '^usage: dispatch-and-verify' "help_exits_zero_and_prints_usage"

"$SCRIPT" --info --json >"$TMP/info.json"
jq -e '.command == "info" and .name == "dispatch-and-verify" and .schema_version == "dispatch-and-verify.info.v1"' "$TMP/info.json" >/dev/null \
  && pass "info_json_surface" || { fail "info_json_surface"; cat "$TMP/info.json" >&2; }

"$SCRIPT" --examples --json >"$TMP/examples.json"
jq -e '.command == "examples" and (.examples | length) >= 3 and all(.examples[]; has("name") and has("command"))' "$TMP/examples.json" >/dev/null \
  && pass "examples_json_surface" || { fail "examples_json_surface"; cat "$TMP/examples.json" >&2; }

"$SCRIPT" --schema >"$TMP/schema.json"
jq -e '.schema_version == "dispatch-and-verify.schema.v1" and (.exit_codes."2" | test("usage"))' "$TMP/schema.json" >/dev/null \
  && pass "schema_surface" || { fail "schema_surface"; cat "$TMP/schema.json" >&2; }

dir="$(make_case permissive_content_delta)"
printf '{"agents":[{"pane":2,"state":"THINKING","velocity":0}]}\n' >"$dir/activity-1"
printf 'queued prompt\n' >"$dir/copy-1"
printf 'Working (31s) | reading dispatch\n' >"$dir/copy-2"
DISPATCH_VERIFY_MAX_PROBES=1 run_wrapper "$dir" "$dir/out" flywheel 2 "$TMP/dispatch.md"
assert_text "$dir/out" 'state=THINKING_LIVE reason=pane_content_delta' "permissive_accepts_zero_velocity_content_delta"
assert_send_count "$dir" 1 "permissive_no_empty_enter_after_live_delta"

dir="$(make_case strict_ignores_content_delta)"
printf '{"agents":[{"pane":2,"state":"THINKING","velocity":0}]}\n' >"$dir/activity-1"
printf '{"agents":[{"pane":2,"state":"THINKING","velocity":0}]}\n' >"$dir/activity-2"
printf '{"agents":[{"pane":2,"state":"THINKING","velocity":0}]}\n' >"$dir/activity-3"
printf 'queued prompt\n' >"$dir/copy-1"
printf 'Working (31s) | reading dispatch\n' >"$dir/copy-2"
printf 'Working (46s) | reading dispatch\n' >"$dir/copy-3"
printf 'Working (61s) | reading dispatch\n' >"$dir/copy-4"
set +e
DISPATCH_VERIFY_MAX_PROBES=3 run_wrapper "$dir" "$dir/out" --probe-mode=strict flywheel 2 "$TMP/dispatch.md"
rc=$?
set -e
if [[ "$rc" == "1" ]]; then pass "strict_rejects_content_delta_without_velocity_or_changes"; else fail "strict_rejects_content_delta_without_velocity_or_changes rc=$rc"; fi
assert_send_count "$dir" 2 "strict_hysteresis_one_empty_enter"

dir="$(make_case changes_delta)"
printf '{"agents":[{"pane":2,"state":"THINKING","velocity":0}]}\n' >"$dir/activity-1"
printf '{"changed_count":0,"changes":[]}\n' >"$dir/changes-1"
printf '{"changed_count":1,"changes":[{"path":"x"}]}\n' >"$dir/changes-2"
printf 'same\n' >"$dir/copy-1"
printf 'same\n' >"$dir/copy-2"
DISPATCH_VERIFY_MAX_PROBES=1 run_wrapper "$dir" "$dir/out" --probe-mode=strict flywheel 2 "$TMP/dispatch.md"
assert_text "$dir/out" 'state=THINKING_LIVE reason=ntm_changes_delta' "changes_delta_accepts_strict_zero_velocity"

dir="$(make_case waiting_hysteresis)"
printf '{"agents":[{"pane":2,"state":"WAITING","velocity":0}]}\n' >"$dir/activity-1"
printf '{"agents":[{"pane":2,"state":"WAITING","velocity":0}]}\n' >"$dir/activity-2"
printf '{"agents":[{"pane":2,"state":"WAITING","velocity":0}]}\n' >"$dir/activity-3"
set +e
DISPATCH_VERIFY_MAX_PROBES=3 run_wrapper "$dir" "$dir/out" flywheel 2 "$TMP/dispatch.md"
rc=$?
set -e
if [[ "$rc" == "1" ]]; then pass "waiting_fails_after_probe_window"; else fail "waiting_fails_after_probe_window rc=$rc"; fi
assert_text "$dir/out" 'attempt 1 state=STUCK' "first_stuck_read_observed"
assert_text "$dir/out" '2 consecutive STUCK reads' "hysteresis_requires_second_stuck"
assert_send_count "$dir" 2 "waiting_hysteresis_limits_empty_enter"

dir="$(make_case invalid_mode)"
set +e
run_wrapper "$dir" "$dir/out" --probe-mode=loose flywheel 2 "$TMP/dispatch.md"
rc=$?
set -e
if [[ "$rc" == "2" ]]; then pass "invalid_probe_mode_exit_2"; else fail "invalid_probe_mode_exit_2 rc=$rc"; fi

printf 'SUMMARY pass=%s fail=%s\n' "$pass_count" "$fail_count"
[[ "$fail_count" == "0" ]]
