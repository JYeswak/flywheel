#!/usr/bin/env bash
# agentmail-fd-pressure-probe.sh
#
# Stress the local mcp-agent-mail daemon with concurrent HTTP traffic and
# sample its lsof FD count to determine whether the soft-limit (4096) needs
# a bump per flywheel-tvd9q AG1-AG3 decision tree.
#
# Filed: flywheel-tvd9q (companion to skillos:1 plan_response_ack
# 2026-05-09T194900Z storage-fd-blocker handoff).
#
# Decision tree (per the bead body):
#   peak_fd_pct > 70  -> verdict=ulimit_bump_justified  (route to skillos:1)
#   40 <= peak_fd_pct <= 70 -> verdict=marginal_monitor_only
#   peak_fd_pct < 40  -> verdict=benign_no_action
#
# Canonical CLI shape:
#   agentmail-fd-pressure-probe.sh --info | --schema | --examples
#   agentmail-fd-pressure-probe.sh --doctor [--json]
#   agentmail-fd-pressure-probe.sh --probe --workers N --duration S [--json]
#   agentmail-fd-pressure-probe.sh --baselines [--json]   (runs idle/1/4/8/sustained series)

set -euo pipefail

VERSION="agentmail-fd-pressure-probe/v1"
DEFAULT_PORT="${AGENTMAIL_PORT:-8765}"
DEFAULT_HOST="${AGENTMAIL_HOST:-127.0.0.1}"
DEFAULT_LABEL="${AGENTMAIL_PLIST_LABEL:-ai.zeststream.mcp-agent-mail-local}"
DEFAULT_TARGET="${AGENTMAIL_TARGET:-/health/liveness}"

usage() {
  cat <<USAGE
$VERSION

USAGE:
  agentmail-fd-pressure-probe.sh --probe --workers N --duration S [--json]
  agentmail-fd-pressure-probe.sh --baselines [--json]
  agentmail-fd-pressure-probe.sh --doctor [--json]
  agentmail-fd-pressure-probe.sh --info | --schema | --examples | --help

MODES:
  --probe        Single burst run with explicit --workers and --duration.
  --baselines    Run idle/1/4/8/sustained series; output peak per series + verdict.
  --doctor       One-shot lightweight FD count + headroom; FAIL if >85% soft limit
                 (canonical doctor invariant agentmail_fd_count_under_pressure).
  --info         Print binary metadata (sha + version) as JSON.
  --schema       Emit JSON-schema for --probe / --baselines output.
  --examples     Print copy-pasteable example invocations.

FLAGS:
  --workers N    Concurrent curl worker count (default: 4).
  --duration S   Burst duration in seconds (default: 5).
  --target PATH  HTTP path to hit (default: $DEFAULT_TARGET).
  --port N       Daemon port (default: $DEFAULT_PORT).
  --host H       Daemon host (default: $DEFAULT_HOST).
  --label L      launchd label (default: $DEFAULT_LABEL).
  --json         JSON output (default for --probe / --baselines / --doctor).
  --apply        Run the burst (probe modes default to --apply).
  --dry-run      Print plan only, do not run burst.

EXIT CODES:
  0  success / verdict computed
  1  bad args
  2  daemon not running / lsof failed
  3  doctor FAIL (FD >85% of soft limit)
USAGE
}

emit_info() {
  local sha
  sha="$(shasum -a 256 "${BASH_SOURCE[0]}" 2>/dev/null | awk '{print $1}')"
  jq -nc --arg v "$VERSION" --arg sha "$sha" '{
    schema_version: $v,
    binary_sha256: $sha,
    soft_limit_default: 4096,
    decision_thresholds: {
      ulimit_bump_justified_min_pct: 70,
      marginal_monitor_min_pct: 40,
      doctor_fail_pct: 85
    }
  }'
}

emit_schema() {
  jq -nc '{
    "$schema": "http://json-schema.org/draft-07/schema#",
    title: "agentmail-fd-pressure-probe",
    type: "object",
    properties: {
      schema_version: {const: "agentmail-fd-pressure-probe/v1"},
      timestamp: {type: "string"},
      mode: {enum: ["probe","baselines","doctor"]},
      daemon: {
        type: "object",
        properties: {
          pid: {type: "integer"},
          label: {type: "string"},
          soft_limit: {type: "integer"},
          hard_limit: {type: "integer"}
        }
      },
      idle_fd_count: {type: "integer"},
      peak_fd_count: {type: "integer"},
      peak_fd_pct: {type: "number"},
      headroom_pct: {type: "number"},
      verdict: {enum: ["ulimit_bump_justified","marginal_monitor_only","benign_no_action","doctor_fail","doctor_pass"]},
      verdict_route: {enum: ["skillos:1","none"]},
      samples: {type: "array"}
    },
    required: ["schema_version","timestamp","mode","verdict"]
  }'
}

emit_examples() {
  cat <<'EOF'
# Single burst (4 workers, 5s)
agentmail-fd-pressure-probe.sh --probe --workers 4 --duration 5 --json

# Full baseline series (idle/1/4/8/sustained)
agentmail-fd-pressure-probe.sh --baselines --json

# Doctor invariant: agentmail_fd_count_under_pressure
agentmail-fd-pressure-probe.sh --doctor --json

# Schema
agentmail-fd-pressure-probe.sh --schema
EOF
}

iso_now() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

discover_pid() {
  local label="$1"
  if command -v launchctl >/dev/null 2>&1; then
    launchctl list 2>/dev/null | awk -v l="$label" '$3 == l {print $1}' | head -1
  fi
}

discover_limits() {
  local pid="$1"
  if [[ -z "$pid" || "$pid" == "-" ]]; then
    return
  fi
  # ulimit on macOS doesn't read other PIDs; use launchctl plist limits.
  local plist="$HOME/Library/LaunchAgents/${DEFAULT_LABEL}.plist"
  local soft=4096 hard=65536
  if [[ -r "$plist" ]]; then
    soft="$(/usr/libexec/PlistBuddy -c "Print :SoftResourceLimits:NumberOfFiles" "$plist" 2>/dev/null || echo 4096)"
    hard="$(/usr/libexec/PlistBuddy -c "Print :HardResourceLimits:NumberOfFiles" "$plist" 2>/dev/null || echo 65536)"
  fi
  jq -nc --argjson soft "$soft" --argjson hard "$hard" '{soft: $soft, hard: $hard}'
}

fd_count() {
  local pid="$1"
  lsof -p "$pid" 2>/dev/null | tail -n +2 | wc -l | tr -d ' '
}

burst_probe() {
  local pid="$1" workers="$2" duration="$3" target="$4" port="$5" host="$6" label="$7"
  local soft hard limits idle peak avg samples_json
  if [[ -z "$pid" || "$pid" == "-" ]]; then
    jq -nc --arg t "$(iso_now)" '{schema_version:"agentmail-fd-pressure-probe/v1",timestamp:$t,mode:"probe",error:"daemon_pid_not_found",verdict:"doctor_fail",verdict_route:"none"}'
    return 2
  fi
  limits="$(discover_limits "$pid")"
  soft="$(echo "$limits" | jq -r '.soft // 4096')"
  hard="$(echo "$limits" | jq -r '.hard // 65536')"
  idle="$(fd_count "$pid")"

  # Pre-warm: ensure daemon is reachable.
  local probe_url="http://${host}:${port}${target}"
  if ! curl -sf -m 3 -o /dev/null "$probe_url"; then
    jq -nc --arg t "$(iso_now)" --arg url "$probe_url" '{schema_version:"agentmail-fd-pressure-probe/v1",timestamp:$t,mode:"probe",error:"daemon_unreachable",probe_url:$url,verdict:"doctor_fail",verdict_route:"none"}'
    return 2
  fi

  # Spawn N parallel curl workers in background; each loops for $duration seconds.
  local end="$(( $(date +%s) + duration ))"
  local pids=()
  for ((i=0; i<workers; i++)); do
    (
      while [[ $(date +%s) -lt $end ]]; do
        curl -sf -m 2 -o /dev/null "$probe_url" || true
      done
    ) &
    pids+=("$!")
  done

  # Sample lsof every 100ms for the duration.
  local peak_local=$idle samples='[]'
  while [[ $(date +%s) -lt $end ]]; do
    local now sample
    now="$(fd_count "$pid")"
    sample="$now"
    if (( sample > peak_local )); then peak_local=$sample; fi
    samples="$(jq -nc --argjson s "$samples" --argjson v "$sample" '$s + [$v]')"
    sleep 0.1
  done

  # Wait for burst workers to drain.
  for p in "${pids[@]}"; do
    wait "$p" 2>/dev/null || true
  done

  peak="$peak_local"
  avg="$(jq -nc --argjson s "$samples" '($s | add) / ([$s | length, 1] | max) | floor' 2>/dev/null || echo 0)"
  local peak_pct headroom_pct verdict route
  peak_pct="$(awk -v p="$peak" -v s="$soft" 'BEGIN { if (s>0) printf "%.2f", (p/s)*100; else printf "0.00" }')"
  headroom_pct="$(awk -v p="$peak" -v s="$soft" 'BEGIN { if (s>0) printf "%.2f", ((s-p)/s)*100; else printf "0.00" }')"

  if awk -v x="$peak_pct" 'BEGIN { exit !(x >= 70.0) }'; then
    verdict="ulimit_bump_justified"; route="skillos:1"
  elif awk -v x="$peak_pct" 'BEGIN { exit !(x >= 40.0) }'; then
    verdict="marginal_monitor_only"; route="none"
  else
    verdict="benign_no_action"; route="none"
  fi

  jq -nc --arg t "$(iso_now)" \
        --argjson pid "$pid" \
        --arg label "$label" \
        --argjson soft "$soft" \
        --argjson hard "$hard" \
        --argjson idle "$idle" \
        --argjson peak "$peak" \
        --argjson avg "$avg" \
        --arg peak_pct "$peak_pct" \
        --arg headroom_pct "$headroom_pct" \
        --argjson workers "$workers" \
        --argjson duration "$duration" \
        --arg verdict "$verdict" \
        --arg route "$route" \
        --argjson samples "$samples" '{
    schema_version:"agentmail-fd-pressure-probe/v1",
    timestamp:$t,
    mode:"probe",
    daemon:{pid:$pid, label:$label, soft_limit:$soft, hard_limit:$hard},
    workers:$workers,
    duration_sec:$duration,
    idle_fd_count:$idle,
    peak_fd_count:$peak,
    average_fd_count:$avg,
    peak_fd_pct:($peak_pct|tonumber),
    headroom_pct:($headroom_pct|tonumber),
    verdict:$verdict,
    verdict_route:$route,
    samples:$samples
  }'
}

baselines() {
  local pid label limits soft hard
  pid="$(discover_pid "$DEFAULT_LABEL")"
  label="$DEFAULT_LABEL"
  if [[ -z "$pid" || "$pid" == "-" ]]; then
    jq -nc --arg t "$(iso_now)" '{schema_version:"agentmail-fd-pressure-probe/v1",timestamp:$t,mode:"baselines",error:"daemon_pid_not_found",verdict:"doctor_fail",verdict_route:"none"}'
    return 2
  fi
  limits="$(discover_limits "$pid")"
  soft="$(echo "$limits" | jq -r '.soft // 4096')"
  hard="$(echo "$limits" | jq -r '.hard // 65536')"

  local idle series='[]'
  idle="$(fd_count "$pid")"
  for series_spec in "single:1:3" "burst4:4:5" "burst8:8:5" "sustained:8:10"; do
    local name workers duration
    name="${series_spec%%:*}"
    workers="$(echo "$series_spec" | cut -d: -f2)"
    duration="$(echo "$series_spec" | cut -d: -f3)"
    local row
    row="$(burst_probe "$pid" "$workers" "$duration" "$DEFAULT_TARGET" "$DEFAULT_PORT" "$DEFAULT_HOST" "$label")"
    series="$(jq -nc --argjson s "$series" --arg name "$name" --argjson row "$row" '$s + [{name:$name} + $row]')"
  done

  # Aggregate verdict from worst-case (highest peak_fd_pct).
  local worst_pct
  worst_pct="$(echo "$series" | jq -r 'map(.peak_fd_pct // 0) | max')"
  local verdict route
  if awk -v x="$worst_pct" 'BEGIN { exit !(x >= 70.0) }'; then
    verdict="ulimit_bump_justified"; route="skillos:1"
  elif awk -v x="$worst_pct" 'BEGIN { exit !(x >= 40.0) }'; then
    verdict="marginal_monitor_only"; route="none"
  else
    verdict="benign_no_action"; route="none"
  fi

  jq -nc --arg t "$(iso_now)" \
        --argjson pid "$pid" \
        --arg label "$label" \
        --argjson soft "$soft" \
        --argjson hard "$hard" \
        --argjson idle "$idle" \
        --argjson series "$series" \
        --arg worst_pct "$worst_pct" \
        --arg verdict "$verdict" \
        --arg route "$route" '{
    schema_version:"agentmail-fd-pressure-probe/v1",
    timestamp:$t,
    mode:"baselines",
    daemon:{pid:$pid, label:$label, soft_limit:$soft, hard_limit:$hard},
    idle_fd_count:$idle,
    series:$series,
    worst_peak_fd_pct:($worst_pct|tonumber),
    verdict:$verdict,
    verdict_route:$route
  }'
}

doctor() {
  local pid limits soft fd pct verdict
  pid="$(discover_pid "$DEFAULT_LABEL")"
  if [[ -z "$pid" || "$pid" == "-" ]]; then
    jq -nc --arg t "$(iso_now)" --arg name "agentmail_fd_count_under_pressure" '{schema_version:"agentmail-fd-pressure-probe/v1",timestamp:$t,mode:"doctor",invariant:$name,status:"fail",reason:"daemon_pid_not_found",verdict:"doctor_fail"}'
    return 3
  fi
  limits="$(discover_limits "$pid")"
  soft="$(echo "$limits" | jq -r '.soft // 4096')"
  fd="$(fd_count "$pid")"
  pct="$(awk -v p="$fd" -v s="$soft" 'BEGIN { if (s>0) printf "%.2f", (p/s)*100; else printf "0.00" }')"

  if awk -v x="$pct" 'BEGIN { exit !(x > 85.0) }'; then
    verdict="doctor_fail"
    jq -nc --arg t "$(iso_now)" --arg name "agentmail_fd_count_under_pressure" \
          --argjson pid "$pid" --argjson soft "$soft" --argjson fd "$fd" --arg pct "$pct" --arg v "$verdict" '{
      schema_version:"agentmail-fd-pressure-probe/v1",
      timestamp:$t,
      mode:"doctor",
      invariant:$name,
      daemon_pid:$pid,
      soft_limit:$soft,
      fd_count:$fd,
      fd_pct:($pct|tonumber),
      threshold_pct:85,
      status:"fail",
      verdict:$v
    }'
    return 3
  else
    verdict="doctor_pass"
    jq -nc --arg t "$(iso_now)" --arg name "agentmail_fd_count_under_pressure" \
          --argjson pid "$pid" --argjson soft "$soft" --argjson fd "$fd" --arg pct "$pct" --arg v "$verdict" '{
      schema_version:"agentmail-fd-pressure-probe/v1",
      timestamp:$t,
      mode:"doctor",
      invariant:$name,
      daemon_pid:$pid,
      soft_limit:$soft,
      fd_count:$fd,
      fd_pct:($pct|tonumber),
      threshold_pct:85,
      status:"pass",
      verdict:$v
    }'
  fi
}

mode=""
workers=4
duration=5
json=1
apply=1
target="$DEFAULT_TARGET"
port="$DEFAULT_PORT"
host="$DEFAULT_HOST"
label="$DEFAULT_LABEL"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --probe) mode="probe"; shift ;;
    --baselines) mode="baselines"; shift ;;
    --doctor) mode="doctor"; shift ;;
    --info) emit_info; exit 0 ;;
    --schema) emit_schema; exit 0 ;;
    --examples) emit_examples; exit 0 ;;
    -h|--help) usage; exit 0 ;;
    --workers) workers="$2"; shift 2 ;;
    --duration) duration="$2"; shift 2 ;;
    --target) target="$2"; shift 2 ;;
    --port) port="$2"; shift 2 ;;
    --host) host="$2"; shift 2 ;;
    --label) label="$2"; shift 2 ;;
    --json) json=1; shift ;;
    --apply) apply=1; shift ;;
    --dry-run) apply=0; shift ;;
    *) echo "ERROR: unknown arg: $1" >&2; usage >&2; exit 1 ;;
  esac
done

if [[ -z "$mode" ]]; then
  usage >&2; exit 1
fi

case "$mode" in
  probe)
    if [[ "$apply" -eq 0 ]]; then
      jq -nc --argjson w "$workers" --argjson d "$duration" --arg t "$target" '{mode:"probe",dry_run:true,workers:$w,duration_sec:$d,target:$t}'
      exit 0
    fi
    pid="$(discover_pid "$label")"
    burst_probe "$pid" "$workers" "$duration" "$target" "$port" "$host" "$label"
    ;;
  baselines)
    if [[ "$apply" -eq 0 ]]; then
      jq -nc '{mode:"baselines",dry_run:true,series:["idle","single","burst4","burst8","sustained"]}'
      exit 0
    fi
    baselines
    ;;
  doctor)
    doctor
    ;;
esac

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-20-cross-orch-handoff.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-100-contention-shaped-state-owner.md`
