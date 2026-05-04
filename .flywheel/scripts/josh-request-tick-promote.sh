#!/usr/bin/env bash
set -euo pipefail

STATE_FILE="${JOSH_REQUEST_STATE_FILE:-$HOME/.local/state/flywheel/josh-requests.jsonl}"
JSON=0

usage() {
  cat <<'USAGE'
usage: josh-request-tick-promote.sh [--json]

Reads ~/.local/state/flywheel/josh-requests.jsonl and emits a tick prelude
summary for requests with v2 state=needs_triage or legacy v1 status=open.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'ERR: unknown arg %s\n' "$1" >&2; exit 2 ;;
  esac
done

if [[ ! -f "$STATE_FILE" ]]; then
  result="$(jq -nc '{action:"missing_state_file",unread:0,highest_priority:null,ids:[],state_file:env.STATE_FILE}')"
else
  result="$(
    jq -s -c '
      def normalized_state:
        .state // (if (.status // "open") == "open" then "needs_triage" else (.status // "unknown") end);
      def priority_rank($p):
        if $p == "P0" then 0
        elif $p == "P1" then 1
        elif $p == "P2" then 2
        elif $p == "P3" then 3
        else 9 end;
      [ .[]?
        | select((normalized_state) == "needs_triage")
        | {
            id,
            priority:(.priority // "P1"),
            captured_at:(.captured_at // .ts // null),
            source_session:(.source_session // .session // null),
            excerpt:(.sanitized_excerpt // .excerpt // "")
          }
      ] as $items
      | ($items | sort_by(priority_rank(.priority)) | .[0].priority // null) as $highest
      | {
          action:"surfaced",
          unread:($items | length),
          highest_priority:$highest,
          ids:($items | map(.id)),
          requests:$items
        }
    ' "$STATE_FILE"
  )"
fi

if [[ "$JSON" -eq 1 ]]; then
  printf '%s\n' "$result"
else
  printf '## Joshua Requests pre-tick\n'
  jq -c '{action,unread,highest_priority,ids}' <<<"$result"
fi
