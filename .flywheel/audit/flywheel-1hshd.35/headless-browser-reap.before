#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
PROBE="${FLYWHEEL_HEADLESS_BROWSER_PROBE:-$ROOT/.flywheel/scripts/headless-browser-probe.sh}"
HISTORY="${FLYWHEEL_HEADLESS_BROWSER_REAP_HISTORY:-$HOME/.local/state/flywheel/headless-browser-reaps.jsonl}"
JSONL_APPEND_LIB="${FLYWHEEL_JSONL_APPEND_LIB:-$HOME/.local/share/flywheel-watchers/lib/jsonl-append.sh}"
JSONL_APPEND_AVAILABLE=0
MIN_AGE_MINUTES="${FLYWHEEL_HEADLESS_BROWSER_REAP_MIN_AGE_MINUTES:-30}"
COUNT_THRESHOLD="${FLYWHEEL_HEADLESS_BROWSER_REAP_COUNT_THRESHOLD:-5}"
APPLY=0
FIXTURE=""
NOW_EPOCH=""
NOTIFY=0
NOTIFY_BIN="${NOTIFY_BIN:-$HOME/.local/bin/notify}"

if [[ -f "$JSONL_APPEND_LIB" ]]; then
  # shellcheck disable=SC1090,SC1091
  if source "$JSONL_APPEND_LIB" && declare -F fw_jsonl_append_validated >/dev/null; then
    JSONL_APPEND_AVAILABLE=1
  fi
fi

usage() {
  printf '%s\n' \
    "Usage:" \
    "  headless-browser-reap.sh [--dry-run|--apply] [--json]" \
    "  headless-browser-reap.sh --fixture PATH [--dry-run] [--now-epoch EPOCH] [--json]" \
    "  headless-browser-reap.sh --help" \
    "" \
    "Candidates are agent-browser-chrome processes older than 30m, or all such processes when count > 5."
}

now_iso() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

append_jsonl_best_effort() {
  local path="$1" row="$2" label="$3" rc
  if [[ "$JSONL_APPEND_AVAILABLE" -ne 1 ]] || ! declare -F fw_jsonl_append_validated >/dev/null; then
    printf 'WARN: %s append skipped; JSONL primitive unavailable: %s\n' "$label" "$JSONL_APPEND_LIB" >&2
    return 0
  fi
  if fw_jsonl_append_validated "$path" "$row"; then
    return 0
  else
    rc=$?
    printf 'WARN: %s append failed rc=%s path=%s\n' "$label" "$rc" "$path" >&2
    return 0
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json|--dry-run)
      shift ;;
    --apply)
      APPLY=1; shift ;;
    --fixture)
      FIXTURE="${2:?missing fixture path}"; shift 2 ;;
    --now-epoch)
      NOW_EPOCH="${2:?missing epoch}"; shift 2 ;;
    --min-age-minutes)
      MIN_AGE_MINUTES="${2:?missing minutes}"; shift 2 ;;
    --count-threshold)
      COUNT_THRESHOLD="${2:?missing count}"; shift 2 ;;
    --history)
      HISTORY="${2:?missing history path}"; shift 2 ;;
    --notify)
      NOTIFY=1; shift ;;
    --help|-h)
      usage; exit 0 ;;
    *)
      printf 'unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2 ;;
  esac
done

probe_args=(--json)
if [[ -n "$FIXTURE" ]]; then
  probe_args+=(--fixture "$FIXTURE")
fi
if [[ -n "$NOW_EPOCH" ]]; then
  probe_args+=(--now-epoch "$NOW_EPOCH")
fi

probe_json="$("$PROBE" "${probe_args[@]}")"
if ! jq -e . >/dev/null 2>&1 <<<"$probe_json"; then
  jq -nc '{version:"headless-browser-reap.v1",status:"error",reason:"probe_invalid_json"}'
  exit 1
fi

candidates_json="$(jq -c --argjson min_age "$MIN_AGE_MINUTES" --argjson threshold "$COUNT_THRESHOLD" '
  . as $root
  | [(.agent_browser_processes // [])[]
      | select((.age_minutes // 0) > $min_age or (($root.headless_agent_browser_count // 0) > $threshold))]
' <<<"$probe_json")"
candidate_count="$(jq 'length' <<<"$candidates_json")"
killed_pids_json="[]"
kill_errors_json="[]"

if [[ "$APPLY" -eq 1 && "$candidate_count" -gt 0 && -z "$FIXTURE" ]]; then
  mapfile -t pids < <(jq -r '.[].pid' <<<"$candidates_json")
  killed=()
  errors=()
  for pid in "${pids[@]}"; do
    if kill -TERM "$pid" 2>/dev/null; then
      killed+=("$pid")
    else
      errors+=("term_failed:$pid")
    fi
  done
  sleep 1
  for pid in "${pids[@]}"; do
    if kill -0 "$pid" 2>/dev/null; then
      if kill -KILL "$pid" 2>/dev/null; then
        :
      else
        errors+=("kill_failed:$pid")
      fi
    fi
  done
  killed_pids_json="$(printf '%s\n' "${killed[@]}" | jq -R 'select(length > 0) | tonumber' | jq -s .)"
  kill_errors_json="$(printf '%s\n' "${errors[@]}" | jq -R 'select(length > 0)' | jq -s .)"
elif [[ "$APPLY" -eq 1 && -n "$FIXTURE" ]]; then
  kill_errors_json='["fixture_mode_no_kill"]'
fi

if [[ "$NOTIFY" -eq 1 && "$candidate_count" -gt 0 && -x "$NOTIFY_BIN" ]]; then
  "$NOTIFY_BIN" "HEADLESS BROWSER LEAK" "agent-browser-chrome candidates=$candidate_count" >/dev/null 2>&1 || true
fi

ts="$(now_iso)"
payload="$(jq -nc \
  --arg version "headless-browser-reap.v1" \
  --arg ts "$ts" \
  --argjson apply "$([[ "$APPLY" -eq 1 ]] && printf true || printf false)" \
  --argjson before "$probe_json" \
  --argjson candidates "$candidates_json" \
  --argjson killed "$killed_pids_json" \
  --argjson errors "$kill_errors_json" \
  --argjson min_age "$MIN_AGE_MINUTES" \
  --argjson threshold "$COUNT_THRESHOLD" \
  '{
    version:$version,
    ts:$ts,
    status:(if (($errors | length) > 0 and ($errors[0] != "fixture_mode_no_kill")) then "error" else "ok" end),
    apply:$apply,
    dry_run:($apply | not),
    before_count:($before.headless_agent_browser_count // 0),
    candidate_count:($candidates | length),
    candidates:$candidates,
    killed_pids:$killed,
    kill_errors:$errors,
    thresholds:{min_age_minutes:$min_age,count_threshold:$threshold},
    primary_chrome_profile:($before.primary_chrome_profile // null),
    history_path:null
  }')"

history_row="$(jq -c --arg path "$HISTORY" '.history_path=$path' <<<"$payload")"
if [[ "$APPLY" -eq 1 ]]; then
  append_jsonl_best_effort "$HISTORY" "$history_row" "headless-browser reap history"
fi
printf '%s\n' "$history_row"
