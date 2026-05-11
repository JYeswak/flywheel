#!/usr/bin/env bash
set -euo pipefail

REPO="${1:-/Users/josh/Developer/flywheel}"
REGISTRY="${JEFF_ISSUES_REGISTRY:-$HOME/.local/state/flywheel/jeff-issues.jsonl}"
STATUS_BIN="${JEFF_ISSUES_STATUS_BIN:-$HOME/.local/bin/jeff-issues-status}"
BR_BIN="${BR_BIN:-br}"
POLL_FIRST="${JEFF_ISSUE_RESPONSE_POLL_SKIP_NETWORK:-0}"

if ! command -v jq >/dev/null 2>&1; then
  printf '{"action":"error","reason":"jq_missing"}\n'
  exit 1
fi

if ! command -v "$BR_BIN" >/dev/null 2>&1; then
  if [ -x "$HOME/.cargo/bin/br" ]; then
    BR_BIN="$HOME/.cargo/bin/br"
  else
    printf '{"action":"error","reason":"br_missing"}\n'
    exit 1
  fi
fi

if [ ! -f "$REGISTRY" ]; then
  jq -nc '{action:"noop",reason:"no_registry"}'
  exit 0
fi

if [ "$POLL_FIRST" != "1" ] && [ -x "$STATUS_BIN" ]; then
  JEFF_ISSUES_REGISTRY="$REGISTRY" "$STATUS_BIN" poll --json >/dev/null 2>&1 || true
fi

issues_json() {
  (cd "$REPO" && "$BR_BIN" list --json)
}

open_bead_for_title() {
  local title="$1"
  issues_json | jq -r --arg title "$title" '
    .issues[]?
    | select((.title // "") == $title and (.status // "") != "closed")
    | .id
  ' | head -1
}

create_bead() {
  local title="$1" description="$2"
  (cd "$REPO" && "$BR_BIN" create "$title" \
    --type task \
    --priority 1 \
    --description "$description" \
    --json) | jq -r '.id // .issue.id // empty'
}

update_registry_triage() {
  local repo="$1" num="$2" last_jeff_ts="$3" bead_id="$4" tmp
  tmp="$(mktemp "${REGISTRY}.XXXXXX")"
  jq -c \
    --arg repo "$repo" \
    --argjson num "$num" \
    --arg ts "$last_jeff_ts" \
    --arg bead "$bead_id" \
    'if .repo == $repo and .number == $num
      then . + {last_triage_bead_ts:$ts,last_triage_bead_id:$bead}
      else .
    end' "$REGISTRY" >"$tmp"
  mv "$tmp" "$REGISTRY"
}

created_file="$(mktemp)"
skipped_file="$(mktemp)"
trap 'rm -f "$created_file" "$skipped_file"' EXIT

while IFS= read -r row; do
  repo="$(jq -r '.repo' <<<"$row")"
  num="$(jq -r '.number' <<<"$row")"
  last_jeff_ts="$(jq -r '.last_jeff_response_ts // ""' <<<"$row")"
  last_triage_ts="$(jq -r '.last_triage_bead_ts // ""' <<<"$row")"
  state="$(jq -r '.state // "unknown"' <<<"$row")"

  if [ -z "$last_jeff_ts" ]; then
    jq -nc --arg issue "$repo#$num" --arg reason "no_jeff_response" '{issue:$issue,reason:$reason}' >>"$skipped_file"
    continue
  fi

  if [ -n "$last_triage_ts" ] && { [[ "$last_jeff_ts" == "$last_triage_ts" ]] || [[ "$last_jeff_ts" < "$last_triage_ts" ]]; }; then
    jq -nc --arg issue "$repo#$num" --arg reason "no_new_response" '{issue:$issue,reason:$reason}' >>"$skipped_file"
    continue
  fi

  repo_short="$(basename "$repo")"
  title="[jeff-triage-$repo_short-$num] response from Jeff (state=$state)"
  existing="$(open_bead_for_title "$title")"
  if [ -n "$existing" ]; then
    update_registry_triage "$repo" "$num" "$last_jeff_ts" "$existing"
    jq -nc --arg issue "$repo#$num" --arg reason "bead_open" --arg bead "$existing" \
      '{issue:$issue,reason:$reason,bead:$bead}' >>"$skipped_file"
    continue
  fi

  description="Auto-created by jeff-issue-response-poll.sh.

Issue: https://github.com/$repo/issues/$num
Last Jeff response: $last_jeff_ts
State: $state

Triage:
- Read the full response via jeff-issues-status why $repo#$num and gh issue view $num --repo $repo.
- Apply our-side actions per jeff-issue-chain Phase 5: memory, skill, code, version, or template updates.
- Reply per jeff-issue-chain Phase 4 only if Jeff asked, new evidence exists, or a dogfood receipt is useful.
- Close this bead with the response receipt and any applied local actions."

  bead_id="$(create_bead "$title" "$description")"
  if [ -z "$bead_id" ]; then
    jq -nc --arg issue "$repo#$num" --arg reason "create_failed" '{issue:$issue,reason:$reason}' >>"$skipped_file"
    continue
  fi
  update_registry_triage "$repo" "$num" "$last_jeff_ts" "$bead_id"
  jq -nc --arg issue "$repo#$num" --arg bead "$bead_id" '{issue:$issue,bead:$bead}' >>"$created_file"
done < <(jq -c '.' "$REGISTRY")

created_json="$(jq -s . "$created_file")"
skipped_json="$(jq -s . "$skipped_file")"

jq -nc \
  --argjson created "$created_json" \
  --argjson skipped "$skipped_json" \
  '{action:"completed",created:$created,skipped:$skipped}'
