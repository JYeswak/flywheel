#!/usr/bin/env bash
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
fi

cron_heartbeat_ts() {
  if [[ -n "${CRON_HEARTBEAT_NOW:-}" ]]; then
    printf '%s\n' "$CRON_HEARTBEAT_NOW"
  else
    date -u +%Y-%m-%dT%H:%M:%SZ
  fi
}

cron_heartbeat_ledger() {
  printf '%s\n' "${CRON_HEARTBEAT_LEDGER:-$HOME/.local/state/flywheel/cron-heartbeat.jsonl}"
}

cron_heartbeat_emit_row() {
  local label="$1" plist_path="$2" run_status="$3" runtime_ms="$4" source="$5"
  local ledger row
  ledger="$(cron_heartbeat_ledger)"

  if ! row="$(
    jq -nc \
      --arg schema_version "skillos.cron_heartbeat.v1" \
      --arg ts "$(cron_heartbeat_ts)" \
      --arg label "$label" \
      --arg plist_path "$plist_path" \
      --arg run_status "$run_status" \
      --arg source "$source" \
      --argjson runtime_ms "$runtime_ms" \
      '{schema_version:$schema_version,ts:$ts,label:$label,plist_path:$plist_path,run_status:$run_status,runtime_ms:$runtime_ms,source:$source}'
  )"; then
    printf 'cron-heartbeat-emit: failed to build JSON row\n' >&2
    return 0
  fi

  if mkdir -p "$(dirname "$ledger")" 2>/dev/null && printf '%s\n' "$row" >>"$ledger" 2>/dev/null; then
    return 0
  fi

  printf '%s\n' "$row" >&2
  return 0
}

cron_heartbeat_entry() {
  local label="${1:-${CRON_LABEL:-}}" plist_path="${2:-${CRON_PLIST_PATH:-}}"
  cron_heartbeat_emit_row "$label" "$plist_path" "started" "null" "entry"
}

cron_heartbeat_exit() {
  local run_status="$1" runtime_ms="$2" label="${3:-${CRON_LABEL:-}}" plist_path="${4:-${CRON_PLIST_PATH:-}}"
  cron_heartbeat_emit_row "$label" "$plist_path" "$run_status" "$runtime_ms" "exit"
}

cron_heartbeat_usage() {
  cat >&2 <<'EOF'
Usage:
  cron-heartbeat-emit.sh --entry --label <label> [--plist <path>]
  cron-heartbeat-emit.sh --exit <ok|warn|fail|emergency_no_log> <runtime_ms> --label <label> [--plist <path>]

Environment:
  CRON_HEARTBEAT_LEDGER  Override ledger path.
  CRON_HEARTBEAT_NOW     Override UTC timestamp for tests.
  CRON_LABEL             Default label.
  CRON_PLIST_PATH        Default plist path.
EOF
}

cron_heartbeat_main() {
  local mode="" status="" runtime_ms="" label="${CRON_LABEL:-}" plist_path="${CRON_PLIST_PATH:-}"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --entry)
        mode="entry"
        shift
        ;;
      --exit)
        mode="exit"
        status="${2:-}"
        runtime_ms="${3:-}"
        shift 3 || true
        ;;
      --label)
        label="${2:-}"
        shift 2 || true
        ;;
      --plist)
        plist_path="${2:-}"
        shift 2 || true
        ;;
      -h|--help)
        cron_heartbeat_usage
        return 0
        ;;
      *)
        printf 'cron-heartbeat-emit: unknown argument: %s\n' "$1" >&2
        cron_heartbeat_usage
        return 2
        ;;
    esac
  done

  if [[ -z "$mode" || -z "$label" ]]; then
    cron_heartbeat_usage
    return 2
  fi

  case "$mode" in
    entry)
      cron_heartbeat_entry "$label" "$plist_path"
      ;;
    exit)
      if [[ ! "$status" =~ ^(ok|warn|fail|emergency_no_log)$ || ! "$runtime_ms" =~ ^[0-9]+$ ]]; then
        cron_heartbeat_usage
        return 2
      fi
      cron_heartbeat_exit "$status" "$runtime_ms" "$label" "$plist_path"
      ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  cron_heartbeat_main "$@"
fi
