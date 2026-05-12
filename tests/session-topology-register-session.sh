#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
LOOP="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
APPEND_SAFE="$ROOT/.flywheel/scripts/append-safe-write.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/session-topology-register.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

line_count() {
  [[ -f "$1" ]] || { printf '0'; return 0; }
  wc -l <"$1" | tr -d ' '
}

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

expect_rc() {
  local want="$1" label="$2"; shift 2
  set +e
  "$@" >/dev/null 2>"$TMP/$label.err"
  local got=$?
  set -e
  [[ "$got" -eq "$want" ]] && pass "$label" || fail "$label rc=$got want=$want"
}

mkdir -p "$TMP/bin"
cat >"$TMP/bin/tmux" <<'SH'
#!/usr/bin/env bash
set -euo pipefail

pane_command() {
  case "$1" in
    0) printf 'zsh\n' ;;
    1) printf 'node\n' ;;
    2) printf 'node\n' ;;
    3) printf 'claude\n' ;;
    4) printf 'bash\n' ;;
    *) printf 'node\n' ;;
  esac
}

case "${1:-}" in
  display-message)
    shift
    target=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
        -p) shift ;;
        -t) target="${2:-}"; shift 2 ;;
        '#S') printf 'fixture\n'; exit 0 ;;
        '#{pane_current_command}') shift ;;
        *) shift ;;
      esac
    done
    pane="${target##*.}"
    pane_command "${pane:-1}"
    ;;
  list-panes)
    shift
    format=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
        -F) format="${2:-}"; shift 2 ;;
        *) shift ;;
      esac
    done
    if [[ "$format" == '#{pane_index}' ]]; then
      printf '0\n1\n2\n3\n4\n'
    else
      printf '0 zsh\n1 node\n2 node\n3 claude\n4 bash\n'
    fi
    ;;
  *)
    printf 'unsupported fake tmux args: %s\n' "$*" >&2
    exit 2
    ;;
esac
SH
chmod +x "$TMP/bin/tmux"

export PATH="$TMP/bin:$PATH"
export FLYWHEEL_APPEND_SAFE_WRITE="$APPEND_SAFE"
export FLYWHEEL_SESSION_TOPOLOGY="$TMP/session-topology.jsonl"

bash -n "$LOOP" && pass "flywheel_loop_syntax" || fail "flywheel_loop_syntax"
"$LOOP" register-session --help | rg -q -- '--json' && pass "help_lists_json" || fail "help_lists_json"

env FLYWHEEL_REGISTER_SESSION_NOW="2026-05-07T00:00:00Z" \
  "$LOOP" register-session --session fixture --orchestrator-pane 1 --kind codex \
    --workers "2:codex,3:claude" --callback-pane 1 --human-pane 0 --notes initial --json >"$TMP/first.json"
assert_jq "$TMP/first.json" \
  '.status == "ok" and .l112_observed == "OK_session_topology_register" and .append_receipt.idempotent_skip == false and .mission_anchor == "continuous-orchestrator-uptime-self-sustaining-fleet"' \
  "first_register_receipt"
jq empty "$FLYWHEEL_SESSION_TOPOLOGY" && pass "topology_jsonl_valid_after_first" || fail "topology_jsonl_valid_after_first"
[[ "$(line_count "$FLYWHEEL_SESSION_TOPOLOGY")" == "1" ]] && pass "first_write_appends_one_row" || fail "first_write_appends_one_row"
assert_jq "$FLYWHEEL_SESSION_TOPOLOGY" \
  '.schema_version == "session-topology-ledger/v1" and .writer_contract == "append-safe-write" and .writer_contract_version == "session-topology-register-session/v1" and (.append_safe_idempotency_key | startswith("register-session:"))' \
  "row_has_writer_contract_fields"

env FLYWHEEL_REGISTER_SESSION_NOW="2026-05-07T00:00:01Z" \
  "$LOOP" register-session --session fixture --orchestrator-pane 1 --kind codex \
    --workers "2:codex,3:claude" --callback-pane 1 --human-pane 0 --notes initial --json >"$TMP/duplicate.json"
assert_jq "$TMP/duplicate.json" '.append_receipt.idempotent_skip == true' "duplicate_shape_idempotent_skip"
[[ "$(line_count "$FLYWHEEL_SESSION_TOPOLOGY")" == "1" ]] && pass "duplicate_shape_no_extra_row" || fail "duplicate_shape_no_extra_row"

env FLYWHEEL_REGISTER_SESSION_NOW="2026-05-07T00:00:02Z" \
  "$LOOP" register-session --session fixture --orchestrator-pane 1 --kind codex \
    --workers "2:codex,3:claude" --callback-pane 1 --human-pane 0 --notes updated --json >"$TMP/updated.json"
assert_jq "$TMP/updated.json" '.append_receipt.idempotent_skip == false' "updated_shape_appends_audit_row"
[[ "$(line_count "$FLYWHEEL_SESSION_TOPOLOGY")" == "2" ]] && pass "updated_shape_second_row" || fail "updated_shape_second_row"
jq -s 'group_by(.session) | map(max_by(.effective_at))' "$FLYWHEEL_SESSION_TOPOLOGY" >"$TMP/latest.json"
assert_jq "$TMP/latest.json" 'length == 1 and .[0].notes == "updated"' "latest_wins_uses_newest_register_row"

before_mismatch="$(line_count "$FLYWHEEL_SESSION_TOPOLOGY")"
expect_rc 2 "mismatch_refuses_without_append" \
  env FLYWHEEL_REGISTER_SESSION_NOW="2026-05-07T00:00:03Z" \
  "$LOOP" register-session --session fixture --orchestrator-pane 1 --kind claude \
    --workers "2:codex" --callback-pane 1 --human-pane 0 --notes mismatch --json
[[ "$(line_count "$FLYWHEEL_SESSION_TOPOLOGY")" == "$before_mismatch" ]] && pass "mismatch_keeps_ledger_unchanged" || fail "mismatch_keeps_ledger_unchanged"

for i in 1 2 3 4 5 6 7 8; do
  env FLYWHEEL_REGISTER_SESSION_NOW="2026-05-07T00:01:0${i}Z" \
    "$LOOP" register-session --session "fixture-${i}" --orchestrator-pane 1 --kind codex \
      --workers "2:codex" --callback-pane 1 --human-pane 0 --notes "concurrent-${i}" --json \
      >"$TMP/concurrent-${i}.json" &
done
wait
[[ "$(line_count "$FLYWHEEL_SESSION_TOPOLOGY")" == "10" ]] && pass "concurrent_writers_all_appended" || fail "concurrent_writers_all_appended"
jq empty "$FLYWHEEL_SESSION_TOPOLOGY" && pass "topology_jsonl_valid_after_concurrency" || fail "topology_jsonl_valid_after_concurrency"

"$LOOP" doctor --repo "$ROOT" --scope session-topology-register --json >"$TMP/doctor.json"
assert_jq "$TMP/doctor.json" \
  '.status == "pass" and .topology_writer_contract == "session-topology-register-session/v1" and .append_safe_write_available == true and .register_session_contract_rows == 10 and .contract_invalid_count == 0' \
  "doctor_scope_reports_writer_contract_health"

printf 'OK_session_topology_register\n'
printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 && "$pass_count" -ge 16 ]]
