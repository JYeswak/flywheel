#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
APPLY="$ROOT/.flywheel/scripts/branch-protection-apply.sh"
MODE=""
JSON_OUT=0
REPORT=""
OVERRIDES_FILE="$ROOT/.flywheel/state/branch-protection-overrides.json"

usage() {
  cat <<'EOF'
usage: branch-protection-fleet-rollout.sh (--dry-run|--apply) [--json] [--report FILE]

Iterates flywheel-managed repos: flywheel, skillos, zesttube, mobile-eats,
clutterfreespaces. Picoz is intentionally excluded pending flywheel-02oow.
EOF
}

die() {
  printf 'branch-protection-fleet-rollout: %s\n' "$1" >&2
  exit "${2:-2}"
}

now_iso() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) MODE="dry-run"; shift ;;
    --apply) MODE="apply"; shift ;;
    --json) JSON_OUT=1; shift ;;
    --report) [[ $# -ge 2 ]] || die "--report requires FILE"; REPORT="$2"; shift 2 ;;
    --report=*) REPORT="${1#*=}"; shift ;;
    --overrides-file) [[ $# -ge 2 ]] || die "--overrides-file requires PATH"; OVERRIDES_FILE="$2"; shift 2 ;;
    --overrides-file=*) OVERRIDES_FILE="${1#*=}"; shift ;;
    --help|-h) usage; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done

[[ -n "$MODE" ]] || die "choose exactly one of --dry-run or --apply"

repos=(
  "flywheel|JYeswak/flywheel|/Users/josh/Developer/flywheel"
  "skillos|JYeswak/zeststream-skillos|/Users/josh/Developer/skillos"
  "zesttube|JYeswak/zesttube|/Users/josh/Developer/zesttube"
  "mobile-eats|JYeswak/mobile-eats|/Users/josh/Developer/mobile-eats"
  "clutterfreespaces|JYeswak/ClutterFreeSpaces|/Users/josh/Developer/clutterfreespaces"
)

tmp="$(mktemp "${TMPDIR:-/tmp}/branch-protection-fleet.XXXXXX.jsonl")"
for entry in "${repos[@]}"; do
  IFS='|' read -r alias repo path <<<"$entry"
  if [[ ! -d "$path" ]]; then
    jq -nc --arg alias "$alias" --arg repo "$repo" --arg path "$path" \
      '{schema_version:"branch_protection_apply.v1",repo:$repo,alias:$alias,repo_path:$path,outcome:"error",error:"repo_path_missing"}' >>"$tmp"
    continue
  fi
  "$APPLY" --repo "$repo" --branch main "--$MODE" --repo-path "$path" --overrides-file "$OVERRIDES_FILE" --json \
    | jq -c --arg alias "$alias" --arg path "$path" '. + {alias:$alias, repo_path:$path}' >>"$tmp"
done

results="$(jq -sc '.' "$tmp")"
rm -f "$tmp"
envelope="$(jq -nc \
  --arg ts "$(now_iso)" \
  --arg mode "$MODE" \
  --argjson results "$results" \
  '{
    schema_version:"branch_protection_fleet_rollout.v1",
    ts:$ts,
    mode:$mode,
    outcome:(if all($results[]; .outcome != "error") then (if $mode == "apply" then "applied" else "dry-run" end) else "error" end),
    repos:($results | length),
    excluded:[{alias:"picoz", repo:"JYeswak/polymarket-pico-z", reason:"permissions issue tracked by flywheel-02oow"}],
    results:$results
  }')"

if [[ -n "$REPORT" ]]; then
  mkdir -p "$(dirname "$REPORT")"
  python3 - "$REPORT" "$envelope" <<'PY'
import json
import sys

path, raw = sys.argv[1], sys.argv[2]
data = json.loads(raw)
lines = [
    "# Branch Protection Fleet Dry-Run — 2026-05-20",
    "",
    f"Mode: `{data['mode']}`",
    f"Outcome: `{data['outcome']}`",
    "",
    "No GitHub branch-protection settings were mutated by this report when mode is `dry-run`.",
    "",
    "| Repo | Outcome | Required checks | Review gate | enforce_admins | allow_force_pushes | allow_deletions |",
    "|---|---|---|---|---|---|---|",
]
for row in data["results"]:
    desired = row.get("desired") or {}
    checks = ", ".join(row.get("required_checks") or [])
    reviews = desired.get("required_pull_request_reviews", None)
    lines.append(
        "| {repo} | `{outcome}` | {checks} | `{reviews}` | `{admin}` | `{force}` | `{delete}` |".format(
            repo=row.get("repo", ""),
            outcome=row.get("outcome", ""),
            checks=checks.replace("|", "\\|"),
            reviews=json.dumps(reviews),
            admin=json.dumps(desired.get("enforce_admins")),
            force=json.dumps(desired.get("allow_force_pushes")),
            delete=json.dumps(desired.get("allow_deletions")),
        )
    )
lines.extend(["", "## Excluded", ""])
for row in data["excluded"]:
    lines.append(f"- `{row['repo']}` ({row['alias']}): {row['reason']}")
lines.extend(["", "## Raw Envelope", "", "```json", json.dumps(data, indent=2, sort_keys=True), "```", ""])
open(path, "w").write("\n".join(lines))
PY
fi

if [[ "$JSON_OUT" -eq 1 ]]; then
  printf '%s\n' "$envelope"
else
  jq . <<<"$envelope"
fi

[[ "$(jq -r '.outcome' <<<"$envelope")" != "error" ]]
