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

exit_code=0

if [[ ! -e "$LOG" ]]; then
  payload="$(jq -nc --arg log "$LOG" '{status:"ok",ticks_punted_count:0,log:$log,checked:0,punted:[]}' )"
elif [[ ! -f "$LOG" || ! -r "$LOG" ]]; then
  payload="$(jq -nc --arg log "$LOG" '{status:"error",ticks_punted_count:0,log:$log,checked:0,punted:[],malformed_row_count:0,malformed_rows:[],warning:"dispatch_log_unreadable"}')"
  exit_code=1
else
  payload="$(jq -R -n -c --arg log "$LOG" '
    def nonempty: ((. // "") | tostring | length) > 0;
    [inputs] as $lines
    | reduce range(0; ($lines | length)) as $i (
        {rows:[], malformed:[]};
        ($lines[$i]) as $line
        | if (($line | length) == 0) then .
          else (try ($line | fromjson) catch null) as $parsed
          | if (($parsed | type) == "object") then
              .rows += [($parsed + {__line:($i + 1)})]
            else
              .malformed += [{line:($i + 1), text:($line[0:200])}]
            end
          end
      )
    | .rows as $rows
    | [
        $rows[]
        | select((.event // "") == "l70_chain_decision")
        | select((.chain_required // false) == true)
        | select((.chained // false) != true)
        | select(((.chain_blocked_reason // "") | tostring | length) == 0)
        | del(.__line)
      ] as $punted
    | {
        status:(if (($rows | length) == 0 and (.malformed | length) > 0) then "error" elif ($punted | length) > 0 then "fail" else "ok" end),
        ticks_punted_count:($punted | length),
        log:$log,
        checked:($rows | map(select((.event // "") == "l70_chain_decision")) | length),
        punted:$punted,
        malformed_row_count:(.malformed | length),
        malformed_rows:.malformed
      }
  ' "$LOG")"
  if [[ "$(jq -r '.status // "ok"' <<<"$payload")" == "error" ]]; then
    exit_code=1
  fi
fi

if [[ "$JSON_OUT" -eq 1 ]]; then
  printf '%s\n' "$payload"
else
  printf 'ticks_punted_count=%s status=%s log=%s\n' \
    "$(jq -r '.ticks_punted_count' <<<"$payload")" \
    "$(jq -r '.status' <<<"$payload")" \
    "$(jq -r '.log' <<<"$payload")"
fi

exit "$exit_code"
