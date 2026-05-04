#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
DOCTOR="$ROOT/.flywheel/scripts/agent-mail-fd-doctor.sh"
LOOP="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/agent-mail-fd-doctor.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() {
  pass_count=$((pass_count + 1))
  printf 'PASS %s\n' "$1"
}

fail() {
  fail_count=$((fail_count + 1))
  printf 'FAIL %s\n' "$1" >&2
}

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

write_launchctl_print() {
  local file="$1" soft="$2" hard="$3"
  cat >"$file" <<EOF
gui/501/ai.zeststream.mcp-agent-mail-local = {
    state = running
    pid = 100
    resource limits = {
        maxfiles (soft) => $soft
        maxfiles (hard) => $hard
    }
}
EOF
}

write_limit() {
  local file="$1" soft="$2" hard="$3"
  printf 'maxfiles    %s    %s\n' "$soft" "$hard" >"$file"
}

write_lsof() {
  local file="$1" count="$2" lock_count="${3:-0}"
  printf 'COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME\n' >"$file"
  local i
  for i in $(seq 1 "$count"); do
    if [ "$i" -le "$lock_count" ]; then
      printf 'python 200 josh %su REG 1,1 0 1 /tmp/.commit.lock\n' "$i" >>"$file"
    else
      printf 'python 200 josh %su REG 1,1 0 1 /tmp/file-%s\n' "$i" "$i" >>"$file"
    fi
  done
}

run_fixture() {
  local out="$1" service_soft="$2" service_hard="$3" fd_count="$4" lock_count="${5:-0}"
  write_launchctl_print "$TMP/launchctl-print.txt" "$service_soft" "$service_hard"
  write_limit "$TMP/launchctl-limit.txt" 256 unlimited
  write_lsof "$TMP/lsof.txt" "$fd_count" "$lock_count"
  AGENT_MAIL_FD_LAUNCHCTL_PRINT_FILE="$TMP/launchctl-print.txt" \
    AGENT_MAIL_FD_LAUNCHCTL_LIMIT_FILE="$TMP/launchctl-limit.txt" \
    AGENT_MAIL_FD_LSOF_FILE="$TMP/lsof.txt" \
    AGENT_MAIL_FD_CHILD_PID=200 \
    AGENT_MAIL_FD_PLIST_SOFT_NUMBER_OF_FILES="$service_soft" \
    AGENT_MAIL_FD_PLIST_HARD_NUMBER_OF_FILES="$service_hard" \
    "$DOCTOR" --doctor --json >"$out" || true
}

bash -n "$DOCTOR" && pass "syntax agent-mail-fd-doctor" || fail "syntax agent-mail-fd-doctor"
bash -n "$LOOP" && pass "syntax flywheel-loop"
"$DOCTOR" --schema | jq -e '.schema_version == "flywheel.agent_mail_fd_doctor.v1" and (.required | index("service_maxfiles_soft"))' >/dev/null \
  && pass "schema includes service maxfiles" || fail "schema includes service maxfiles"

run_fixture "$TMP/pass.json" 4096 65536 30 0
assert_jq "$TMP/pass.json" '.status == "PASS" and .success == true and .service_maxfiles_soft == "4096" and .launchctl_maxfiles_soft == "256" and (.warnings | length) == 0' "service limit overrides global launchctl maxfiles"

run_fixture "$TMP/warn-service.json" 256 65536 30 0
assert_jq "$TMP/warn-service.json" '.status == "WARN" and (.warnings[]?.message | contains("service soft maxfiles=256"))' "warns when service maxfiles too low"

run_fixture "$TMP/fail-fds.json" 4096 65536 221 0
assert_jq "$TMP/fail-fds.json" '.status == "FAIL" and (.errors[]?.message | contains("total_fds=221"))' "fails over total FD threshold"

run_fixture "$TMP/warn-locks.json" 4096 65536 40 26
assert_jq "$TMP/warn-locks.json" '.status == "WARN" and .lock_fd_count == 26 and (.warnings[]?.message | contains("lock_fd_count=26"))' "warns over lock FD threshold"

AGENT_MAIL_FD_LAUNCHCTL_PRINT_FILE="$TMP/launchctl-print.txt" \
  AGENT_MAIL_FD_LAUNCHCTL_LIMIT_FILE="$TMP/launchctl-limit.txt" \
  AGENT_MAIL_FD_LSOF_FILE="$TMP/lsof.txt" \
  AGENT_MAIL_FD_CHILD_PID=200 \
  AGENT_MAIL_FD_PLIST_SOFT_NUMBER_OF_FILES=4096 \
  AGENT_MAIL_FD_PLIST_HARD_NUMBER_OF_FILES=65536 \
  FLYWHEEL_AGENT_MAIL_FD_PROBE="$DOCTOR" \
  FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED=1 \
  "$LOOP" doctor --repo "$ROOT" --json >"$TMP/loop-doctor.json" 2>"$TMP/loop-doctor.err" || true
assert_jq "$TMP/loop-doctor.json" '.agent_mail_fd_pressure.status | IN("ok","warn","error")' "flywheel-loop exposes normalized fd doctor signal"

if [ "$fail_count" -gt 0 ]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
