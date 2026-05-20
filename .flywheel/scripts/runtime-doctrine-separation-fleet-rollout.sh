#!/usr/bin/env bash
# Fleet dry-run wrapper for runtime-vs-doctrine separation.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
MIGRATE="$ROOT/.flywheel/scripts/runtime-doctrine-separation-migrate.sh"
MODE="dry-run"
JSON_OUT=0
REPORT=""
JOSHUA_GATED_APPLY=0
REPOS=()

DEFAULT_REPOS=(
  "/Users/josh/Developer/flywheel"
  "/Users/josh/Developer/skillos"
  "/Users/josh/Developer/zesttube"
  "/Users/josh/Developer/mobile-eats"
  "/Users/josh/Developer/clutterfreespaces"
)

usage() {
  cat <<'USAGE'
usage: runtime-doctrine-separation-fleet-rollout.sh [--dry-run] [--json]
       [--report PATH] [--repo PATH ...]

Dry-run is the fleet default. --apply refuses unless paired with
--joshua-gated-apply, and should not be used by agents without direct approval.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) MODE="dry-run"; shift ;;
    --apply) MODE="apply"; shift ;;
    --joshua-gated-apply) JOSHUA_GATED_APPLY=1; shift ;;
    --json) JSON_OUT=1; shift ;;
    --report) REPORT="${2:-}"; shift 2 ;;
    --repo) REPOS+=("${2:-}"); shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ "$MODE" == "apply" && "$JOSHUA_GATED_APPLY" -ne 1 ]]; then
  jq -nc '{schema_version:"runtime_doctrine_separation_fleet_rollout.v1",outcome:"refused",reason:"--apply requires --joshua-gated-apply and direct Joshua approval"}'
  exit 3
fi

if [[ "${#REPOS[@]}" -eq 0 ]]; then
  REPOS=("${DEFAULT_REPOS[@]}")
fi

ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
stamp="$(date -u +%Y%m%dT%H%M%SZ)"
if [[ -z "$REPORT" ]]; then
  REPORT="$ROOT/.flywheel/audits/runtime-doctrine-separation-fleet-dry-run-$stamp.md"
fi

tmp="$(mktemp -d "${TMPDIR:-/tmp}/runtime-doctrine-fleet.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT
jsonl="$tmp/envelopes.jsonl"

for repo in "${REPOS[@]}"; do
  [[ -n "$repo" ]] || continue
  if [[ "$MODE" == "apply" ]]; then
    "$MIGRATE" --repo "$repo" --apply --json >>"$jsonl"
  else
    "$MIGRATE" --repo "$repo" --dry-run --json >>"$jsonl"
  fi
done

mkdir -p "$(dirname "$REPORT")"
{
  printf '# Runtime Doctrine Separation Fleet Dry Run\n\n'
  printf '%s\n' "- generated_at: \`$ts\`"
  printf '%s\n' "- mode: \`$MODE\`"
  printf '%s\n\n' "- apply_policy: \`Joshua-gated; agents must not apply fleet migration without direct approval\`"
  printf '| Repo | Outcome | Tracked before | Tracked after | Bytes recovered | Runtime classes | Mixed pending | Secret incidents |\n'
  printf '|---|---:|---:|---:|---:|---|---:|---:|\n'
  jq -r '[.repo,.outcome,.tracked_files_before,.tracked_files_after,.bytes_recovered,(.runtime_migrated|join("<br>")),(.mixed_classes_pending_review|length),(.secrets_incidents|length)] | @tsv' "$jsonl" |
    while IFS=$'\t' read -r repo outcome before after bytes runtime mixed incidents; do
      printf '| %s | %s | %s | %s | %s | %s | %s | %s |\n' "$repo" "$outcome" "$before" "$after" "$bytes" "${runtime:-none}" "$mixed" "$incidents"
    done
  printf '\n## Raw Summaries\n\n```json\n'
  jq -s 'map({
    schema_version,
    ts,
    repo,
    mode,
    outcome,
    runtime_migrated,
    tracked_files_before,
    tracked_files_after,
    bytes_recovered,
    secrets_incidents,
    mixed_classes_pending_review: (.mixed_classes_pending_review | map({
      class,
      path,
      tracked_files,
      tracked_bytes,
      operator_action,
      truncated
    })),
    runtime_actions: (.runtime_actions | map({
      class,
      path,
      target,
      planned,
      already_migrated,
      tracked_files_before,
      tracked_files_after,
      tracked_bytes_before,
      gitignore
    }))
  })' "$jsonl"
  printf '\n```\n'
} >"$REPORT"

payload="$(jq -s --arg sv "runtime_doctrine_separation_fleet_rollout.v1" --arg ts "$ts" --arg mode "$MODE" --arg report "$REPORT" '{schema_version:$sv,ts:$ts,mode:$mode,report:$report,repos:.}' "$jsonl")"

if [[ "$JSON_OUT" -eq 1 ]]; then
  printf '%s\n' "$payload"
else
  printf 'wrote %s\n' "$REPORT"
fi
