#!/usr/bin/env bash
set -euo pipefail

REPO="${1:-/Users/josh/Developer/flywheel}"
FUCKUP_LOG="${FUCKUP_LOG:-$HOME/.local/state/flywheel/fuckup-log.jsonl}"
BR_BIN="${BR_BIN:-br}"
PERIOD_DAYS="${DOCTRINE_LADDER_PERIOD_DAYS:-7}"

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

if [ ! -f "$FUCKUP_LOG" ]; then
  jq -nc '{action:"noop",reason:"no_fuckup_log"}'
  exit 0
fi

cutoff_iso() {
  python3 - "$PERIOD_DAYS" <<'PY' 2>/dev/null || date -u -v-"${PERIOD_DAYS}"d +%Y-%m-%dT%H:%M:%SZ
import datetime
import sys

days = int(sys.argv[1])
cutoff = datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(days=days)
print(cutoff.strftime("%Y-%m-%dT%H:%M:%SZ"))
PY
}

default_incident_paths() {
  printf '%s\n' "$HOME/.claude/skills/.flywheel/INCIDENTS.md"
  printf '%s\n' "$HOME"/.claude/skills/*/references/INCIDENTS.md
  printf '%s\n' "$REPO/INCIDENTS.md"
  printf '%s\n' "$REPO/AGENTS.md"
}

incident_paths() {
  if [ -n "${INCIDENTS_SEARCH_PATHS:-}" ]; then
    printf '%s\n' $INCIDENTS_SEARCH_PATHS
  else
    default_incident_paths
  fi
}

incidents_cover_class() {
  local class="$1"
  while IFS= read -r path; do
    [ -f "$path" ] || continue
    if grep -Fqi -- "$class" "$path"; then
      return 0
    fi
  done < <(incident_paths)
  return 1
}

issues_json() {
  (cd "$REPO" && "$BR_BIN" list --json --limit 0)
}

open_promotion_candidate_exists() {
  local class="$1"
  issues_json | jq -e --arg class "$class" '
    .issues[]?
    | select((.status // "") != "closed")
    | select(((.title // "") | ascii_downcase | contains("promotion-candidate"))
      and ((.title // "") | contains($class)))
  ' >/dev/null
}

create_candidate_bead() {
  local class="$1" count="$2"
  local description bead
  description="Auto-created by doctrine-ladder-promote.sh per L56 ladder. Trauma class '$class' hit $count times in last ${PERIOD_DAYS}d with no INCIDENTS coverage. Run /flywheel:learn --promote $class to draft doctrine entry."
  bead="$(cd "$REPO" && "$BR_BIN" create "[promotion-candidate] $class ($count events in ${PERIOD_DAYS}d)" \
    --type task \
    --priority 2 \
    --description "$description" \
    --silent)"
  printf '%s\n' "$bead"
}

cutoff="$(cutoff_iso)"
classes="$(
  jq -Rr 'fromjson? | select(type == "object")' "$FUCKUP_LOG" 2>/dev/null \
    | jq -r --arg cutoff "$cutoff" '
      select(((.ts // .timestamp // "") | tostring) >= $cutoff)
      | (.trauma_class // "") | tostring
      | select(length > 0)
    ' \
    | sort \
    | uniq -c \
    | awk -v threshold=3 '$1 >= threshold { count=$1; $1=""; sub(/^ +/, ""); print $0 "\t" count }'
)"

created_file="$(mktemp)"
skipped_file="$(mktemp)"
trap 'rm -f "$created_file" "$skipped_file"' EXIT

if [ -n "$classes" ]; then
  while IFS=$'\t' read -r class count; do
    [ -n "${class:-}" ] || continue
    if incidents_cover_class "$class"; then
      printf '%s:incidents_covered\n' "$class" >>"$skipped_file"
      continue
    fi
    if open_promotion_candidate_exists "$class"; then
      printf '%s:bead_exists\n' "$class" >>"$skipped_file"
      continue
    fi
    bead="$(create_candidate_bead "$class" "$count")"
    printf '%s:%s\n' "$class" "$bead" >>"$created_file"
  done <<<"$classes"
fi

created_json="$(jq -R 'select(length > 0)' "$created_file" | jq -s .)"
skipped_json="$(jq -R 'select(length > 0)' "$skipped_file" | jq -s .)"

jq -nc \
  --argjson period_days "$PERIOD_DAYS" \
  --arg cutoff "$cutoff" \
  --argjson created "$created_json" \
  --argjson skipped "$skipped_json" \
  '{
    action:"completed",
    period_days:$period_days,
    cutoff:$cutoff,
    created:$created,
    skipped:$skipped
  }'
