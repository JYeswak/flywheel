#!/usr/bin/env bash
set -euo pipefail

REPO="/Users/josh/Developer/flywheel"
JSON_OUT=0
LOG=""

usage() {
  printf 'usage: ticks-punted-probe.sh [--repo PATH] [--log PATH] [--json]\n'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      [[ -n "${2:-}" ]] || { usage >&2; exit 64; }
      REPO="$2"; shift 2 ;;
    --log)
      [[ -n "${2:-}" ]] || { usage >&2; exit 64; }
      LOG="$2"; shift 2 ;;
    --json)
      JSON_OUT=1; shift ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      usage >&2; exit 64 ;;
  esac
done

if [[ -z "$LOG" ]]; then
  LOG="$REPO/.flywheel/dispatch-log.jsonl"
fi

if [[ ! -f "$LOG" ]]; then
  payload="$(jq -nc --arg log "$LOG" '{status:"ok",ticks_punted_count:0,log:$log,checked:0,punted:[]}' )"
else
  payload="$(jq -s -c --arg log "$LOG" '
    def nonempty: ((. // "") | tostring | length) > 0;
    map(select(type == "object")) as $rows
    | [
        $rows[]
        | select((.event // "") == "l70_chain_decision")
        | select((.chain_required // false) == true)
        | select((.chained // false) != true)
        | select(((.chain_blocked_reason // "") | tostring | length) == 0)
      ] as $punted
    | {
        status:(if ($punted | length) > 0 then "fail" else "ok" end),
        ticks_punted_count:($punted | length),
        log:$log,
        checked:($rows | map(select((.event // "") == "l70_chain_decision")) | length),
        punted:$punted
      }
  ' "$LOG")"
fi

if [[ "$JSON_OUT" -eq 1 ]]; then
  printf '%s\n' "$payload"
else
  printf 'ticks_punted_count=%s status=%s log=%s\n' \
    "$(jq -r '.ticks_punted_count' <<<"$payload")" \
    "$(jq -r '.status' <<<"$payload")" \
    "$(jq -r '.log' <<<"$payload")"
fi
