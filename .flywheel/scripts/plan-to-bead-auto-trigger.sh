#!/usr/bin/env bash
set -euo pipefail

REPO="${1:-/Users/josh/Developer/flywheel}"
BR_BIN="${BR_BIN:-br}"
PLANS_DIR="$REPO/.flywheel/PLANS"

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

if [ ! -d "$PLANS_DIR" ]; then
  printf '{"action":"noop","reason":"no_plans_dir"}\n'
  exit 0
fi

mtime_epoch() {
  stat -f %m "$1" 2>/dev/null || stat -c %Y "$1"
}

plan_key() {
  local plan="$1" rel dir
  rel="${plan#"$PLANS_DIR"/}"
  if [ "$(basename "$plan")" = "00-PLAN.md" ]; then
    dir="$(dirname "$rel")"
    printf '%s\n' "${dir//\//-}"
  else
    basename "$plan" .md
  fi
}

frontmatter_converged() {
  local plan="$1"
  awk '
    NR == 1 && $0 == "---" { in_fm=1; next }
    in_fm && $0 == "---" { exit }
    in_fm && tolower($0) ~ /^converged:[[:space:]]*true[[:space:]]*$/ { found=1 }
    END { exit found ? 0 : 1 }
  ' "$plan"
}

state_converged() {
  local plan="$1" state=""
  if [ "$(basename "$plan")" = "00-PLAN.md" ]; then
    state="$(dirname "$plan")/STATE.json"
  fi
  [ -f "$state" ] || return 1
  jq -e '(.convergence_streak // 0) >= 2 or (.converged == true)' "$state" >/dev/null 2>&1
}

existing_bead() {
  local key="$1" plan="$2" rel
  rel="${plan#"$REPO"/}"
  (cd "$REPO" && "$BR_BIN" list --json) | jq -r \
    --arg key "$key" \
    --arg rel "$rel" \
    --arg plan "$plan" '
      .issues[]?
      | select(.status != "closed")
      | select(
          ((.title // "") | ascii_downcase | contains("[plan-decompose] convert " + ($key | ascii_downcase)))
          or (((.title // "") | ascii_downcase | contains("convert")) and ((.title // "") | ascii_downcase | contains($key | ascii_downcase)))
          or ((.description // "") | contains($rel))
          or ((.description // "") | contains($plan))
        )
      | .id
    ' | head -1
}

create_bead() {
  local key="$1" plan="$2" converged="$3" stale_hours="$4"
  local description
  description="Auto-created by plan-to-bead-auto-trigger.sh.

Plan: $plan
Reason: converged=$converged stale_hours=$stale_hours.

## Goal
Read the plan and convert it into executable Beads.

## Acceptance
- Create one bead per phase or tightly-coupled work slice.
- Wire dependencies with br dep add.
- Run br dep cycles and confirm zero cycles.
- Reference this plan path in every created bead."
  (cd "$REPO" && "$BR_BIN" create "[plan-decompose] convert $key" \
    --type task \
    --priority 1 \
    --description "$description" \
    --json) | jq -r '.id // .issue.id // empty'
}

created_tmp="$(mktemp "${TMPDIR:-/tmp}/plan-to-bead-created.XXXXXX")"
skipped_tmp="$(mktemp "${TMPDIR:-/tmp}/plan-to-bead-skipped.XXXXXX")"
trap 'rm -f "$created_tmp" "$skipped_tmp"' EXIT

while IFS= read -r plan; do
  key="$(plan_key "$plan")"
  existing="$(existing_bead "$key" "$plan")"
  if [ -n "$existing" ]; then
    jq -nc --arg plan "$key" --arg reason "has_open_bead" --arg bead "$existing" \
      '{plan:$plan,reason:$reason,bead:$bead}' >>"$skipped_tmp"
    continue
  fi

  converged=false
  if frontmatter_converged "$plan" || state_converged "$plan"; then
    converged=true
  fi

  age_hours="$(( ( $(date +%s) - $(mtime_epoch "$plan") ) / 3600 ))"
  stale=false
  if [ "$age_hours" -gt 24 ]; then
    stale=true
  fi

  if [ "$converged" = "true" ] || [ "$stale" = "true" ]; then
    bead_id="$(create_bead "$key" "$plan" "$converged" "$age_hours")"
    jq -nc --arg plan "$key" --arg bead "$bead_id" --argjson stale_hours "$age_hours" --argjson converged "$converged" \
      '{plan:$plan,bead:$bead,converged:$converged,stale_hours:$stale_hours}' >>"$created_tmp"
  else
    jq -nc --arg plan "$key" --arg reason "fresh_and_unmarked" --argjson stale_hours "$age_hours" \
      '{plan:$plan,reason:$reason,stale_hours:$stale_hours}' >>"$skipped_tmp"
  fi
done < <(
  {
    find "$PLANS_DIR" -maxdepth 1 -type f -name '*.md' -print
    find "$PLANS_DIR" -mindepth 2 -maxdepth 2 -type f -name '00-PLAN.md' -print
  } | sort
)

jq -nc \
  --slurpfile created "$created_tmp" \
  --slurpfile skipped "$skipped_tmp" \
  '{action:"completed",created:$created,skipped:$skipped}'
