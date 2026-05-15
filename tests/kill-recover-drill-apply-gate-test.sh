#!/usr/bin/env bash
set -euo pipefail

SCRIPT="${KILL_RECOVER_DRILL_SCRIPT:-$HOME/.claude/skills/.flywheel/scripts/kill-recover-drill.sh}"
LIB="${FLYWHEEL_JSONL_APPEND_LIB:-$HOME/.local/share/flywheel-watchers/lib/jsonl-append.sh}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/kill-recover-drill-apply-gate.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

write_fixture_tools() {
  mkdir -p "$TMP/bin" "$TMP/state"

  cat >"$TMP/ntm" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
log="${FAKE_NTM_LOG:?}"
state="${FAKE_NTM_STATE:?}"
mkdir -p "$state"
printf '%s\n' "$*" >>"$log"
case "${1:-}" in
  list)
    jq -nc '{sessions:[{name:"fixture-session"}]}'
    ;;
  --robot-activity=*)
    jq -nc '{agents:[{pane_idx:1,agent_type:"codex",state:"WAITING"}]}'
    ;;
  --robot-inspect-pane=*)
    jq -nc '{agent:{command:"node",type:"codex"}}'
    ;;
  respawn)
    printf 'respawned\n'
    ;;
  send)
    printf '%s\n' "$*" >"$state/last-send"
    jq -nc '{success:true}'
    ;;
  copy)
    out=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --output) out="${2:?}"; shift 2 ;;
        --output=*) out="${1#*=}"; shift ;;
        *) shift ;;
      esac
    done
    cat "$state/last-send" >"$out"
    ;;
  logs)
    cat "$state/last-send" 2>/dev/null || true
    ;;
  *)
    printf 'unexpected fake ntm args: %s\n' "$*" >&2
    exit 2
    ;;
esac
EOF
  chmod +x "$TMP/ntm"

  cat >"$TMP/bin/tmux" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'tmux %s\n' "$*" >>"${FAKE_TMUX_LOG:?}"
case "${1:-}" in
  display-message)
    printf '9999\n'
    ;;
  send-keys)
    exit 0
    ;;
  has-session)
    exit 0
    ;;
  *)
    exit 0
    ;;
esac
EOF
  chmod +x "$TMP/bin/tmux"

  cat >"$TMP/bin/pgrep" <<'EOF'
#!/usr/bin/env bash
case "$*" in
  *"-f node"*) printf '424242\n' ;;
  *) exit 1 ;;
esac
EOF
  chmod +x "$TMP/bin/pgrep"

  cat >"$TMP/topology-probe" <<'EOF'
#!/usr/bin/env bash
jq -nc '{status:"pass",fixture:true}'
EOF
  chmod +x "$TMP/topology-probe"
}

run_drill() {
  local name="$1"
  shift
  local out="$TMP/$name.out" err="$TMP/$name.err"
  env \
    "PATH=$TMP/bin:$PATH" \
    "NTM_BIN=$TMP/ntm" \
    "FAKE_NTM_LOG=$TMP/$name.ntm.log" \
    "FAKE_NTM_STATE=$TMP/$name.ntm-state" \
    "FAKE_TMUX_LOG=$TMP/$name.tmux.log" \
    "DRILL_LOG=$TMP/$name.recovery-drill.jsonl" \
    "SNAPSHOT_DIR=$TMP/$name-snapshots" \
    "DRILL_TOPOLOGY_PROBE=$TMP/topology-probe" \
    "FLYWHEEL_JSONL_APPEND_LIB=$LIB" \
    "$SCRIPT" --session fixture-session --pane 1 --damage-class D3 --wait-seconds 0 --json "$@" \
    >"$out" 2>"$err"
}

write_fixture_tools

run_drill preview
if grep -q '"action":"would_send_interrupts"' "$TMP/preview.out" \
  && grep -q '"action":"would_force_respawn"' "$TMP/preview.out" \
  && grep -q 'preview-only, pass --apply to execute drill' "$TMP/preview.err" \
  && [[ ! -s "$TMP/preview.tmux.log" ]] \
  && ! grep -q '^respawn ' "$TMP/preview.ntm.log" \
  && ! grep -q '^send ' "$TMP/preview.ntm.log" \
  && [[ ! -e "$TMP/preview.recovery-drill.jsonl" ]]; then
  pass "default_preview_only_no_interrupt_stop_respawn_or_log"
else
  fail "default_preview_only_no_interrupt_stop_respawn_or_log"
  cat "$TMP/preview.out" "$TMP/preview.err" "$TMP/preview.ntm.log" "$TMP/preview.tmux.log" >&2 || true
fi

run_drill apply --apply
if grep -q 'tmux send-keys -t fixture-session:0.1 C-c' "$TMP/apply.tmux.log" \
  && grep -q 'tmux send-keys -t fixture-session:0.1 C-d' "$TMP/apply.tmux.log" \
  && grep -q '"action":"would_force_respawn"' "$TMP/apply.out" \
  && ! grep -q '^respawn ' "$TMP/apply.ntm.log" \
  && jq -e 'type == "object" and .dry_run == false' "$TMP/apply.recovery-drill.jsonl" >/dev/null; then
  pass "apply_runs_interrupts_but_not_force_respawn"
else
  fail "apply_runs_interrupts_but_not_force_respawn"
  cat "$TMP/apply.out" "$TMP/apply.err" "$TMP/apply.ntm.log" "$TMP/apply.tmux.log" "$TMP/apply.recovery-drill.jsonl" >&2 || true
fi

run_drill dangerous --damage-class D2 --apply --dangerous-drill
if grep -q '"action":"sent_kill_stop"' "$TMP/dangerous.out" \
  && grep -q '^respawn fixture-session --panes=1 --force$' "$TMP/dangerous.ntm.log" \
  && jq -e 'type == "object" and .dry_run == false' "$TMP/dangerous.recovery-drill.jsonl" >/dev/null; then
  pass "apply_dangerous_runs_kill_stop_and_force_respawn"
else
  fail "apply_dangerous_runs_kill_stop_and_force_respawn"
  cat "$TMP/dangerous.out" "$TMP/dangerous.err" "$TMP/dangerous.ntm.log" "$TMP/dangerous.tmux.log" "$TMP/dangerous.recovery-drill.jsonl" >&2 || true
fi

if jq -e 'type == "object" and .record_type == "l63_recovery_drill"' "$TMP/apply.recovery-drill.jsonl" >/dev/null; then
  pass "jsonl_site_appends_valid_object_via_primitive"
else
  fail "jsonl_site_appends_valid_object_via_primitive"
  cat "$TMP/apply.recovery-drill.jsonl" >&2 || true
fi

env \
  "PATH=$TMP/bin:$PATH" \
  "NTM_BIN=$TMP/ntm" \
  "FAKE_NTM_LOG=$TMP/empty.ntm.log" \
  "FAKE_NTM_STATE=$TMP/empty.ntm-state" \
  "FAKE_TMUX_LOG=$TMP/empty.tmux.log" \
  "DRILL_LOG=$TMP/empty.recovery-drill.jsonl" \
  "SNAPSHOT_DIR=$TMP/empty-snapshots" \
  "DRILL_TOPOLOGY_PROBE=$TMP/topology-probe" \
  "FLYWHEEL_JSONL_APPEND_LIB=$LIB" \
  "KILL_RECOVER_DRILL_FORCE_EMPTY_ROW=1" \
  "$SCRIPT" --session fixture-session --pane 1 --damage-class D1 --no-inject --primitive manual --wait-seconds 0 --apply --json \
  >"$TMP/empty.out" 2>"$TMP/empty.err"

if [[ ! -s "$TMP/empty.recovery-drill.jsonl" ]] \
  && grep -q 'drill log append failed rc=1' "$TMP/empty.err"; then
  pass "empty_row_rejected_without_log_write"
else
  fail "empty_row_rejected_without_log_write"
  cat "$TMP/empty.out" "$TMP/empty.err" "$TMP/empty.recovery-drill.jsonl" >&2 || true
fi

printf 'RESULT pass=%s fail=%s\n' "$pass_count" "$fail_count"
[[ "$pass_count" == "5" && "$fail_count" == "0" ]]
