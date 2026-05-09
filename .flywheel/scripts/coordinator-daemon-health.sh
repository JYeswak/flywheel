#!/usr/bin/env bash
set -euo pipefail

VERSION="coordinator-daemon-health.v1.0.0"
LABEL_DEFAULT="ai.zeststream.flywheel-coordinator-daemon"
PLIST_DEFAULT="/Users/josh/Developer/flywheel/templates/flywheel-install/launchd/${LABEL_DEFAULT}.plist"
INSTALLED_PLIST_DEFAULT="$HOME/Library/LaunchAgents/${LABEL_DEFAULT}.plist"
CONFIG_DEFAULT="$HOME/.config/ntm/config.toml"
LOG_DEFAULT="/tmp/ntm-watcher-flywheel.log"
ERR_LOG_DEFAULT="/tmp/ntm-watcher-flywheel.err.log"
PATTERN_DEFAULT="ntm-coordinator-pinned.*--watch"

JSON_OUT=0
MODE="health"
LABEL="$LABEL_DEFAULT"
PLIST="$PLIST_DEFAULT"
INSTALLED_PLIST="$INSTALLED_PLIST_DEFAULT"
CONFIG="$CONFIG_DEFAULT"
LOG_PATH="$LOG_DEFAULT"
ERR_LOG_PATH="$ERR_LOG_DEFAULT"
PATTERN="$PATTERN_DEFAULT"
MAINTENANCE=0

usage() {
  cat <<'EOF'
usage: coordinator-daemon-health.sh [--health|--doctor|--validate|--audit|--schema|--info|--examples|--why|--repair] [--json]

Read-only health probe for the flywheel NTM coordinator daemon. It checks both
process state and launchd state, reports machine-readable coordinator_daemon_*
fields, and fail-opens for intentional maintenance.

Exit codes:
  0  probe completed, including WARN/SOFT states
  1  validation failed or repair refused
  2  usage error
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_OUT=1; shift ;;
    --health|--doctor|--validate|--audit|--schema|--info|--examples|--why|--repair)
      MODE="${1#--}"; shift ;;
    --dry-run) MODE="health"; shift ;;
    --apply)
      printf 'REFUSE: coordinator-daemon-health.sh is read-only; no --apply mode\n' >&2
      exit 1 ;;
    --label) LABEL="${2:?missing --label value}"; shift 2 ;;
    --plist) PLIST="${2:?missing --plist value}"; shift 2 ;;
    --installed-plist) INSTALLED_PLIST="${2:?missing --installed-plist value}"; shift 2 ;;
    --config) CONFIG="${2:?missing --config value}"; shift 2 ;;
    --log) LOG_PATH="${2:?missing --log value}"; shift 2 ;;
    --err-log) ERR_LOG_PATH="${2:?missing --err-log value}"; shift 2 ;;
    --pattern) PATTERN="${2:?missing --pattern value}"; shift 2 ;;
    --maintenance) MAINTENANCE=1; shift ;;
    --help|-h) usage; exit 0 ;;
    --version) printf '%s\n' "$VERSION"; exit 0 ;;
    *) printf 'unknown arg: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

emit() {
  local payload="$1" human="$2" rc="${3:-0}"
  if [[ "$JSON_OUT" -eq 1 || "$MODE" != "health" ]]; then
    printf '%s\n' "$payload"
  else
    printf '%s\n' "$human"
  fi
  exit "$rc"
}

json_array() {
  jq -R -s -c 'split("\n") | map(select(length > 0))'
}

auto_assign_enabled() {
  [[ -r "$CONFIG" ]] || return 1
  awk '
    /^\[coordinator\][[:space:]]*$/ {in_block=1; next}
    /^\[/ && in_block {in_block=0}
    in_block && /^[[:space:]]*auto_assign[[:space:]]*=/ {
      sub(/^[^=]*=[[:space:]]*/, "")
      sub(/[[:space:]]*#.*$/, "")
      sub(/[[:space:]]*$/, "")
      print
      exit
    }
  ' "$CONFIG" | grep -qx 'true'
}

log_lines_5m() {
  local now cutoff file count=0
  now="$(date -u +%s)"
  cutoff=$((now - 300))
  for file in "$LOG_PATH" "$ERR_LOG_PATH"; do
    [[ -r "$file" ]] || continue
    while IFS= read -r line; do
      # Count ISO-ish lines newer than 5 minutes; fallback to tail volume for logs
      # without timestamps so a running daemon still has signal.
      if [[ "$line" =~ ([0-9]{4}-[0-9]{2}-[0-9]{2}[T[:space:]][0-9]{2}:[0-9]{2}:[0-9]{2}) ]]; then
        ts_raw="${BASH_REMATCH[1]// /T}Z"
        ts_epoch="$(date -j -u -f '%Y-%m-%dT%H:%M:%SZ' "$ts_raw" +%s 2>/dev/null || printf '0')"
        [[ "$ts_epoch" -ge "$cutoff" ]] && count=$((count + 1))
      fi
    done < <(tail -n 200 "$file" 2>/dev/null || true)
    if [[ "$count" -eq 0 ]]; then
      count=$((count + $(tail -n 20 "$file" 2>/dev/null | wc -l | tr -d ' ')))
    fi
  done
  printf '%s\n' "$count"
}

schema_payload() {
  jq -nc '{
    schema_version:"coordinator-daemon-health.schema/v1",
    schema:{
      type:"object",
      required:["schema_version","status","coordinator_daemon_alive","coordinator_daemon_pid","coordinator_daemon_uptime_seconds","coordinator_daemon_log_lines_5m","auto_assign_enabled","soft_violations"],
      properties:{
        schema_version:{const:"coordinator-daemon-health/v1"},
        status:{enum:["pass","warn","fail","refused"]},
        coordinator_daemon_alive:{type:"boolean"},
        coordinator_daemon_pid:{type:["integer","null"]},
        coordinator_daemon_uptime_seconds:{type:["integer","null"]},
        coordinator_daemon_log_lines_5m:{type:"integer"},
        auto_assign_enabled:{type:"boolean"},
        soft_violations:{type:"array",items:{type:"string"}}
      }
    },
    exit_codes:{"0":"probe completed including fail-open WARN states","1":"validation failed or repair refused","2":"usage"}
  }'
}

if [[ "$MODE" == "schema" ]]; then
  emit "$(schema_payload)" "" 0
fi

if [[ "$MODE" == "info" ]]; then
  emit "$(jq -nc \
    --arg version "$VERSION" \
    --arg label "$LABEL" \
    --arg plist "$PLIST" \
    --arg installed_plist "$INSTALLED_PLIST" \
    --arg config "$CONFIG" \
    --arg log_path "$LOG_PATH" \
    --arg err_log_path "$ERR_LOG_PATH" \
    '{schema_version:"coordinator-daemon-health.info/v1",name:"coordinator-daemon-health.sh",version:$version,label:$label,plist_path:$plist,installed_plist_path:$installed_plist,config_path:$config,log_path:$log_path,err_log_path:$err_log_path,read_only:true,canonical_cli_surfaces:["--health","--doctor","--validate","--audit","--schema","--info","--examples","--why","--repair","--json"]}')" "" 0
fi

if [[ "$MODE" == "examples" ]]; then
  emit "$(jq -nc '{schema_version:"coordinator-daemon-health.examples/v1",examples:["coordinator-daemon-health.sh --health --json","coordinator-daemon-health.sh --doctor --json","coordinator-daemon-health.sh --validate --json","coordinator-daemon-health.sh --maintenance --json"]}')" "" 0
fi

if [[ "$MODE" == "why" ]]; then
  emit "$(jq -nc '{schema_version:"coordinator-daemon-health.why/v1",reason:"auto_assign=true is dangerous if the coordinator daemon silently stops; tick needs a fail-open health signal and a soft violation class, not a blocking gate."}')" "" 0
fi

if [[ "$MODE" == "repair" ]]; then
  emit "$(jq -nc '{schema_version:"coordinator-daemon-health.repair/v1",status:"refused",read_only:true,reason:"repair is out of scope; operator must use the coordinator daemon installer or launchctl rollback path explicitly."}')" "" 1
fi

if [[ "$MODE" == "validate" ]]; then
  lint_status="missing"
  if [[ -f "$PLIST" ]]; then
    if plutil -lint "$PLIST" >/dev/null 2>&1; then
      lint_status="pass"
    else
      lint_status="fail"
    fi
  fi
  payload="$(jq -nc \
    --arg lint_status "$lint_status" \
    --arg plist "$PLIST" \
    --arg installed_plist "$INSTALLED_PLIST" \
    '{schema_version:"coordinator-daemon-health.validate/v1",status:(if $lint_status=="pass" then "pass" else "fail" end),plist_path:$plist,installed_plist_path:$installed_plist,plist_lint:$lint_status}')"
  emit "$payload" "" "$([[ "$lint_status" == "pass" ]] && printf 0 || printf 1)"
fi

pgrep_output="$(pgrep -fl "$PATTERN" 2>/dev/null | awk -v self="$$" -v parent="$PPID" '$1 != self && $1 != parent && $0 !~ /coordinator-daemon-health[.]sh/ && $0 !~ / --pattern /' || true)"
pids="$(awk '{print $1}' <<<"$pgrep_output" | grep -E '^[0-9]+$' || true)"
pid="$(head -n 1 <<<"$pids" | tr -d '[:space:]')"
pid_json="null"
uptime_json="null"
alive=false
if [[ -n "$pid" ]]; then
  alive=true
  pid_json="$pid"
  etime="$(ps -o etime= -p "$pid" 2>/dev/null | awk '{print $1; exit}' || true)"
  uptime="$(python3 - "$etime" <<'PY' 2>/dev/null || true
import sys
s = sys.argv[1].strip()
days = 0
if "-" in s:
    d, s = s.split("-", 1)
    days = int(d)
parts = [int(p) for p in s.split(":")]
if len(parts) == 3:
    h, m, sec = parts
elif len(parts) == 2:
    h, m, sec = 0, parts[0], parts[1]
else:
    raise SystemExit(1)
print(days * 86400 + h * 3600 + m * 60 + sec)
PY
)"
  if [[ "$uptime" =~ ^[0-9]+$ ]]; then
    uptime_json="$uptime"
  fi
fi

domain="gui/$(id -u)"
target="$domain/$LABEL"
launchctl_alive=false
launchctl_state="unavailable"
if launchctl print "$target" >/dev/null 2>&1; then
  launchctl_alive=true
  launchctl_state="loaded"
fi

if [[ "$alive" == false && "$launchctl_alive" == true ]]; then
  alive=true
fi

auto_assign=false
if auto_assign_enabled; then
  auto_assign=true
fi

log_count="$(log_lines_5m)"
soft_violations_json='[]'
status="pass"
maintenance_reason=""
if [[ "$alive" == false && "$auto_assign" == true ]]; then
  if [[ "$MAINTENANCE" -eq 1 || -f "$HOME/.local/state/flywheel/coordinator-daemon-maintenance" ]]; then
    status="warn"
    maintenance_reason="intentional_maintenance"
  else
    status="warn"
    soft_violations_json='["orch_coordinator_daemon_down"]'
  fi
fi

pids_json="$(printf '%s\n' "$pids" | json_array)"
payload="$(jq -nc \
  --arg status "$status" \
  --arg label "$LABEL" \
  --arg target "$target" \
  --arg plist "$PLIST" \
  --arg installed_plist "$INSTALLED_PLIST" \
  --arg launchctl_state "$launchctl_state" \
  --arg maintenance_reason "$maintenance_reason" \
  --argjson alive "$alive" \
  --argjson launchctl_alive "$launchctl_alive" \
  --argjson auto_assign "$auto_assign" \
  --argjson pid "$pid_json" \
  --argjson uptime "$uptime_json" \
  --argjson log_lines "$log_count" \
  --argjson pids "$pids_json" \
  --argjson soft_violations "$soft_violations_json" \
  '{
    schema_version:"coordinator-daemon-health/v1",
    status:$status,
    label:$label,
    launchctl_target:$target,
    plist_path:$plist,
    installed_plist_path:$installed_plist,
    launchctl_state:$launchctl_state,
    launchctl_alive:$launchctl_alive,
    coordinator_daemon_alive:$alive,
    coordinator_daemon_pid:$pid,
    coordinator_daemon_pids:$pids,
    coordinator_daemon_uptime_seconds:$uptime,
    coordinator_daemon_log_lines_5m:$log_lines,
    auto_assign_enabled:$auto_assign,
    fail_open:true,
    maintenance_reason:(if $maintenance_reason == "" then null else $maintenance_reason end),
    soft_violations:$soft_violations
  }')"

human="$(jq -r '"coordinator_daemon_alive=\(.coordinator_daemon_alive) coordinator_daemon_pid=\(.coordinator_daemon_pid // "null") coordinator_daemon_uptime_seconds=\(.coordinator_daemon_uptime_seconds // "null") coordinator_daemon_log_lines_5m=\(.coordinator_daemon_log_lines_5m) status=\(.status)"' <<<"$payload")"
emit "$payload" "$human" 0
