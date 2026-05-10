#!/usr/bin/env bash
set -uo pipefail

SCRIPT_VERSION="2026-05-10.1"
SCHEMA_VERSION="flywheel.agent_mail_fd_doctor.v1"
LABEL="${AGENT_MAIL_FD_LABEL:-ai.zeststream.mcp-agent-mail-local}"
DOMAIN="${AGENT_MAIL_FD_DOMAIN:-gui/$UID}"
TARGET="$DOMAIN/$LABEL"
PLIST="${AGENT_MAIL_FD_PLIST:-$HOME/Library/LaunchAgents/${LABEL}.plist}"
WARN_FDS="${AGENT_MAIL_FD_WARN_FDS:-128}"
WARN_LOCK_FDS="${AGENT_MAIL_FD_WARN_LOCK_FDS:-25}"
FAIL_FDS="${AGENT_MAIL_FD_FAIL_FDS:-220}"
# flywheel-5pjt2: portable liveness fallback. When lsof is unavailable
# (e.g., minimal hosts, Linux without procfs lsof, container images),
# the doctor previously returned FAIL even when the Agent Mail service
# was healthy. The portable path now probes the canonical
# /health/liveness HTTP endpoint (per memory rule
# reference_agent_mail_service.md) and downgrades lsof-unavailable to
# WARN if the service is alive — operator gets clear "FD-pressure data
# unavailable, service alive" signal instead of confusing FAIL.
LIVENESS_URL="${AGENT_MAIL_FD_LIVENESS_URL:-http://127.0.0.1:8765/health/liveness}"
LIVENESS_TIMEOUT="${AGENT_MAIL_FD_LIVENESS_TIMEOUT:-3}"
MODE="doctor"
JSON=0

usage() {
  cat <<'USAGE'
Usage:
  agent-mail-fd-doctor.sh [--doctor] [--json]
  agent-mail-fd-doctor.sh --health [--json]
  agent-mail-fd-doctor.sh --info [--json]
  agent-mail-fd-doctor.sh --schema
  agent-mail-fd-doctor.sh --examples
  agent-mail-fd-doctor.sh --help

Read-only Agent Mail FD pressure probe. Exit codes:
  0 PASS
  1 WARN: total FDs >128, lock FDs >25, or lsof unavailable + liveness OK
  2 FAIL: service down (HTTP /health/liveness failed AND child PID missing),
        or total FDs >220
USAGE
}

examples() {
  cat <<'EXAMPLES'
Examples:
  /tmp/agent-mail-fd-doctor-DRAFT/agent-mail-fd-doctor.sh --doctor
  /tmp/agent-mail-fd-doctor-DRAFT/agent-mail-fd-doctor.sh --doctor --json
  AGENT_MAIL_FD_FAIL_FDS=256 /tmp/agent-mail-fd-doctor-DRAFT/agent-mail-fd-doctor.sh --json
EXAMPLES
}

schema() {
  jq -nc --arg schema "$SCHEMA_VERSION" '{
    schema_version:$schema,
    required:[
      "success","status","exit_code","checked_at","label","target",
      "launch_pid","child_pid","total_fds","numeric_fds","max_fd",
      "lock_fd_count","launchctl_maxfiles_soft","launchctl_maxfiles_hard",
      "service_maxfiles_soft","service_maxfiles_hard",
      "plist_soft_number_of_files","plist_hard_number_of_files",
      "thresholds","checks","errors","warnings"
    ],
    exit_codes:{pass:0,warn:1,fail:2}
  }'
}

die_usage() {
  usage >&2
  exit 2
}

for arg in "$@"; do
  case "$arg" in
    --doctor|doctor) MODE="doctor" ;;
    --health|health) MODE="health" ;;
    --json) JSON=1 ;;
    --info) MODE="info" ;;
    --schema) schema; exit 0 ;;
    --examples) examples; exit 0 ;;
    completion) printf 'complete -W "--doctor doctor --health health --json --info --schema --examples completion --help" agent-mail-fd-doctor.sh\n'; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    *) die_usage ;;
  esac
done

now_iso() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

plist_value() {
  local key="$1"
  case "$key" in
    SoftResourceLimits:NumberOfFiles)
      if [ -n "${AGENT_MAIL_FD_PLIST_SOFT_NUMBER_OF_FILES:-}" ]; then
        printf '%s\n' "$AGENT_MAIL_FD_PLIST_SOFT_NUMBER_OF_FILES"
        return 0
      fi
      ;;
    HardResourceLimits:NumberOfFiles)
      if [ -n "${AGENT_MAIL_FD_PLIST_HARD_NUMBER_OF_FILES:-}" ]; then
        printf '%s\n' "$AGENT_MAIL_FD_PLIST_HARD_NUMBER_OF_FILES"
        return 0
      fi
      ;;
  esac
  /usr/libexec/PlistBuddy -c "Print :$key" "$PLIST" 2>/dev/null || true
}

launchctl_maxfiles() {
  if [ -n "${AGENT_MAIL_FD_LAUNCHCTL_LIMIT_FILE:-}" ]; then
    awk '$1 == "maxfiles" {print $2 " " $3; exit}' "$AGENT_MAIL_FD_LAUNCHCTL_LIMIT_FILE"
    return 0
  fi
  launchctl limit maxfiles 2>/dev/null | awk '$1 == "maxfiles" {print $2 " " $3; exit}'
}

service_maxfiles() {
  local source_cmd
  if [ -n "${AGENT_MAIL_FD_LAUNCHCTL_PRINT_FILE:-}" ]; then
    source_cmd=(cat "$AGENT_MAIL_FD_LAUNCHCTL_PRINT_FILE")
  else
    source_cmd=(launchctl print "$TARGET")
  fi
  "${source_cmd[@]}" 2>/dev/null | awk '
    /resource limits =/ {inside=1; next}
    inside && /^[[:space:]]*}/ {inside=0}
    inside && /maxfiles \(soft\)/ {soft=$4}
    inside && /maxfiles \(hard\)/ {hard=$4}
    END {print soft, hard}
  '
}

launch_pid() {
  if [ -n "${AGENT_MAIL_FD_LAUNCHCTL_PRINT_FILE:-}" ]; then
    awk '/^[[:space:]]*pid =/ {print $3; exit}' "$AGENT_MAIL_FD_LAUNCHCTL_PRINT_FILE"
    return 0
  fi
  launchctl print "$TARGET" 2>/dev/null | awk '/^[[:space:]]*pid =/ {print $3; exit}'
}

child_pid_for() {
  local parent="$1"
  [ -n "$parent" ] || return 0
  if [ -n "${AGENT_MAIL_FD_CHILD_PID:-}" ]; then
    printf '%s\n' "$AGENT_MAIL_FD_CHILD_PID"
    return 0
  fi
  pgrep -P "$parent" -f 'mcp_agent_mail\.cli serve-http' 2>/dev/null | head -1
}

# flywheel-5pjt2: portable liveness probe.
# Returns 0 if the canonical /health/liveness endpoint reports alive,
# 1 if curl is unavailable or the endpoint is unreachable / unhealthy.
# Honors AGENT_MAIL_FD_LIVENESS_OVERRIDE for fixture testing
# ("alive" → return 0, "down" → return 1, "no_curl" → simulates missing curl).
check_liveness() {
  case "${AGENT_MAIL_FD_LIVENESS_OVERRIDE:-}" in
    alive)   return 0 ;;
    down)    return 1 ;;
    no_curl) return 1 ;;
  esac
  command -v curl >/dev/null 2>&1 || return 1
  local body
  body="$(curl -fsS --max-time "$LIVENESS_TIMEOUT" "$LIVENESS_URL" 2>/dev/null || true)"
  [ -n "$body" ] || return 1
  case "$body" in
    *'"status":"alive"'*|*'"status": "alive"'*) return 0 ;;
    *) return 1 ;;
  esac
}

emit_human() {
  printf '%s\n' "agent-mail-fd-doctor $STATUS"
  printf 'label=%s target=%s mode=%s\n' "$LABEL" "$TARGET" "$MODE"
  printf 'launch_pid=%s child_pid=%s\n' "${LAUNCH_PID:-}" "${CHILD_PID:-}"
  printf 'total_fds=%s numeric_fds=%s max_fd=%s lock_fd_count=%s\n' "$TOTAL_FDS" "$NUMERIC_FDS" "$MAX_FD" "$LOCK_FD_COUNT"
  printf 'launchctl_maxfiles_soft=%s hard=%s\n' "$MAXFILES_SOFT" "$MAXFILES_HARD"
  printf 'service_maxfiles_soft=%s service_maxfiles_hard=%s\n' "$SERVICE_MAXFILES_SOFT" "$SERVICE_MAXFILES_HARD"
  printf 'plist_soft_number_of_files=%s plist_hard_number_of_files=%s\n' "$PLIST_SOFT" "$PLIST_HARD"
  if [ -s "$CHECKS_FILE" ]; then
    sed 's/^/- /' "$CHECKS_FILE"
  fi
}

emit_json() {
  jq -n \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg checked_at "$CHECKED_AT" \
    --arg mode "$MODE" \
    --arg script_version "$SCRIPT_VERSION" \
    --arg label "$LABEL" \
    --arg target "$TARGET" \
    --arg plist "$PLIST" \
    --arg status "$STATUS" \
    --argjson success "$SUCCESS_JSON" \
    --argjson exit_code "$EXIT_CODE" \
    --arg launch_pid "${LAUNCH_PID:-}" \
    --arg child_pid "${CHILD_PID:-}" \
    --argjson total_fds "$TOTAL_FDS" \
    --argjson numeric_fds "$NUMERIC_FDS" \
    --argjson max_fd "$MAX_FD" \
    --argjson lock_fd_count "$LOCK_FD_COUNT" \
    --arg maxfiles_soft "$MAXFILES_SOFT" \
    --arg maxfiles_hard "$MAXFILES_HARD" \
    --arg service_maxfiles_soft "$SERVICE_MAXFILES_SOFT" \
    --arg service_maxfiles_hard "$SERVICE_MAXFILES_HARD" \
    --arg plist_soft "$PLIST_SOFT" \
    --arg plist_hard "$PLIST_HARD" \
    --argjson warn_fds "$WARN_FDS" \
    --argjson warn_lock_fds "$WARN_LOCK_FDS" \
    --argjson fail_fds "$FAIL_FDS" \
    --slurpfile checks "$CHECKS_JSON" \
    '{
      schema_version:$schema_version,
      checked_at:$checked_at,
      mode:$mode,
      script_version:$script_version,
      success:$success,
      status:$status,
      exit_code:$exit_code,
      label:$label,
      target:$target,
      plist:$plist,
      launch_pid:($launch_pid | select(length > 0) // null),
      child_pid:($child_pid | select(length > 0) // null),
      total_fds:$total_fds,
      numeric_fds:$numeric_fds,
      max_fd:$max_fd,
      lock_fd_count:$lock_fd_count,
      launchctl_maxfiles_soft:$maxfiles_soft,
      launchctl_maxfiles_hard:$maxfiles_hard,
      service_maxfiles_soft:$service_maxfiles_soft,
      service_maxfiles_hard:$service_maxfiles_hard,
      plist_soft_number_of_files:$plist_soft,
      plist_hard_number_of_files:$plist_hard,
      thresholds:{warn_fds:$warn_fds,warn_lock_fds:$warn_lock_fds,fail_fds:$fail_fds},
      checks:$checks,
      max_fd_count:$total_fds,
      process_pattern:"mcp_agent_mail",
      errors:(if $status == "FAIL" then ($checks | map({code:"agent_mail_fd_doctor_fail",message:.})) else [] end),
      warnings:(if $status == "WARN" then ($checks | map({code:"agent_mail_fd_doctor_warn",message:.})) else [] end)
    }'
}

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/agent-mail-fd-doctor.XXXXXX")" || exit 2
trap 'rm -rf "$TMP_ROOT"' EXIT
LSOF_FILE="$TMP_ROOT/lsof.txt"
CHECKS_FILE="$TMP_ROOT/checks.txt"
CHECKS_JSON="$TMP_ROOT/checks.json"
: >"$CHECKS_FILE"
: >"$CHECKS_JSON"

CHECKED_AT="$(now_iso)"
LAUNCH_PID=""
CHILD_PID=""
TOTAL_FDS=0
NUMERIC_FDS=0
MAX_FD=0
LOCK_FD_COUNT=0
MAXFILES_SOFT=""
MAXFILES_HARD=""
SERVICE_MAXFILES_SOFT=""
SERVICE_MAXFILES_HARD=""
PLIST_SOFT=""
PLIST_HARD=""
STATUS="PASS"
EXIT_CODE=0

if [ "$MODE" = "info" ]; then
  read -r MAXFILES_SOFT MAXFILES_HARD <<EOF
$(launchctl_maxfiles)
EOF
  read -r SERVICE_MAXFILES_SOFT SERVICE_MAXFILES_HARD <<EOF
$(service_maxfiles)
EOF
  PLIST_SOFT="$(plist_value 'SoftResourceLimits:NumberOfFiles')"
  PLIST_HARD="$(plist_value 'HardResourceLimits:NumberOfFiles')"
  STATUS="INFO"
  SUCCESS_JSON=true
  if [ "$JSON" -eq 1 ]; then
    emit_json
  else
    emit_human
  fi
  exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
  printf '%s\n' "FAIL: jq unavailable; JSON doctor output cannot be built" >&2
  exit 2
fi
if ! command -v lsof >/dev/null 2>&1; then
  # flywheel-5pjt2: lsof unavailable. Try the canonical Agent Mail
  # /health/liveness endpoint as a portable liveness probe before
  # declaring the service down. If liveness OK → WARN with
  # fd_pressure_unknown_no_lsof code (operator sees "service alive,
  # FD data missing"); if liveness fails → FAIL with both codes.
  if check_liveness; then
    printf '%s\n' "lsof unavailable; liveness OK via $LIVENESS_URL — fd_pressure data unavailable" >>"$CHECKS_FILE"
    if [ "$EXIT_CODE" -eq 0 ]; then
      STATUS="WARN"
      EXIT_CODE=1
    fi
  else
    printf '%s\n' "lsof unavailable AND liveness failed at $LIVENESS_URL" >>"$CHECKS_FILE"
    STATUS="FAIL"
    EXIT_CODE=2
  fi
else
  LAUNCH_PID="$(launch_pid)"
  if [ -z "$LAUNCH_PID" ]; then
    printf '%s\n' "launchctl target not loaded: $TARGET" >>"$CHECKS_FILE"
    STATUS="FAIL"
    EXIT_CODE=2
  else
    CHILD_PID="$(child_pid_for "$LAUNCH_PID")"
    if [ -z "$CHILD_PID" ]; then
      printf '%s\n' "Agent Mail child PID missing under launch PID $LAUNCH_PID" >>"$CHECKS_FILE"
      STATUS="FAIL"
      EXIT_CODE=2
    elif [ -n "${AGENT_MAIL_FD_LSOF_FILE:-}" ]; then
      cp "$AGENT_MAIL_FD_LSOF_FILE" "$LSOF_FILE"
    elif ! lsof -nP -p "$CHILD_PID" >"$LSOF_FILE" 2>"$TMP_ROOT/lsof.err"; then
      printf '%s\n' "lsof failed for child PID $CHILD_PID: $(tr '\n' ' ' <"$TMP_ROOT/lsof.err")" >>"$CHECKS_FILE"
      STATUS="FAIL"
      EXIT_CODE=2
    fi
    if [ -s "$LSOF_FILE" ]; then
      TOTAL_FDS="$(awk 'NR > 1 {c++} END {print c + 0}' "$LSOF_FILE")"
      LOCK_FD_COUNT="$(grep -Ec '\.(commit|archive)\.lock' "$LSOF_FILE" || true)"
      read -r NUMERIC_FDS MAX_FD <<EOF
$(awk 'NR > 1 && $4 ~ /^[0-9]+[A-Za-z-]*$/ {fd=$4; sub(/[^0-9].*/, "", fd); if ((fd + 0) > max) max = fd + 0; n++} END {print n + 0, max + 0}' "$LSOF_FILE")
EOF
      if [ "$TOTAL_FDS" -gt "$FAIL_FDS" ]; then
        printf '%s\n' "total_fds=$TOTAL_FDS exceeds fail threshold $FAIL_FDS" >>"$CHECKS_FILE"
        STATUS="FAIL"
        EXIT_CODE=2
      elif [ "$TOTAL_FDS" -gt "$WARN_FDS" ]; then
        printf '%s\n' "total_fds=$TOTAL_FDS exceeds warn threshold $WARN_FDS" >>"$CHECKS_FILE"
        STATUS="WARN"
        EXIT_CODE=1
      fi
      if [ "$LOCK_FD_COUNT" -gt "$WARN_LOCK_FDS" ]; then
        printf '%s\n' "lock_fd_count=$LOCK_FD_COUNT exceeds warn threshold $WARN_LOCK_FDS" >>"$CHECKS_FILE"
        if [ "$EXIT_CODE" -eq 0 ]; then
          STATUS="WARN"
          EXIT_CODE=1
        fi
      fi
    fi
  fi
fi

read -r MAXFILES_SOFT MAXFILES_HARD <<EOF
$(launchctl_maxfiles)
EOF
read -r SERVICE_MAXFILES_SOFT SERVICE_MAXFILES_HARD <<EOF
$(service_maxfiles)
EOF
PLIST_SOFT="$(plist_value 'SoftResourceLimits:NumberOfFiles')"
PLIST_HARD="$(plist_value 'HardResourceLimits:NumberOfFiles')"

if [ -z "$PLIST_SOFT" ] || [ -z "$PLIST_HARD" ]; then
  printf '%s\n' "plist lacks SoftResourceLimits/HardResourceLimits NumberOfFiles" >>"$CHECKS_FILE"
  if [ "$EXIT_CODE" -eq 0 ]; then
    STATUS="WARN"
    EXIT_CODE=1
  fi
fi
if [ -n "$PLIST_SOFT" ] && [ "${PLIST_SOFT:-0}" -lt 4096 ] 2>/dev/null; then
  printf '%s\n' "plist SoftResourceLimits NumberOfFiles=$PLIST_SOFT below target 4096" >>"$CHECKS_FILE"
  if [ "$EXIT_CODE" -eq 0 ]; then
    STATUS="WARN"
    EXIT_CODE=1
  fi
fi
if [ -n "$PLIST_HARD" ] && [ "${PLIST_HARD:-0}" -lt 65536 ] 2>/dev/null; then
  printf '%s\n' "plist HardResourceLimits NumberOfFiles=$PLIST_HARD below target 65536" >>"$CHECKS_FILE"
  if [ "$EXIT_CODE" -eq 0 ]; then
    STATUS="WARN"
    EXIT_CODE=1
  fi
fi
if [ -n "$SERVICE_MAXFILES_SOFT" ] && [ "${SERVICE_MAXFILES_SOFT:-0}" != "unlimited" ] && [ "${SERVICE_MAXFILES_SOFT:-0}" -lt 4096 ] 2>/dev/null; then
  printf '%s\n' "service soft maxfiles=$SERVICE_MAXFILES_SOFT below target 4096" >>"$CHECKS_FILE"
  if [ "$EXIT_CODE" -eq 0 ]; then
    STATUS="WARN"
    EXIT_CODE=1
  fi
fi

if [ ! -s "$CHECKS_FILE" ]; then
  printf '%s\n' "all checks passed" >>"$CHECKS_FILE"
fi
jq -R . "$CHECKS_FILE" >"$CHECKS_JSON"

if [ "$EXIT_CODE" -eq 0 ]; then
  SUCCESS_JSON=true
else
  SUCCESS_JSON=false
fi

if [ "$JSON" -eq 1 ]; then
  emit_json
else
  emit_human
fi
exit "$EXIT_CODE"
