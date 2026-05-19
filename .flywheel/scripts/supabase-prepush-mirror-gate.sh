#!/usr/bin/env bash
# shellcheck disable=SC2016
set -euo pipefail

SCHEMA_VERSION="flywheel.supabase_prepush_mirror_gate.v1"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
DEFAULT_LEDGER="$ROOT/.flywheel/runtime/supabase-local-mirror-ledger.jsonl"
DEFAULT_OVERRIDE_FILE="$ROOT/.flywheel/runtime/supabase-emergency-overrides.jsonl"

json=0
dry_run=0
repo="$ROOT"
commit_range=""
ledger="$DEFAULT_LEDGER"
override_file="$DEFAULT_OVERRIDE_FILE"
max_age_minutes=60
project=""

usage() {
  cat <<'EOF'
usage: supabase-prepush-mirror-gate.sh [options]

Tier 4.5 gate: blocks Supabase schema/RLS pushes unless a passing local-mirror
validation receipt exists in the ledger within the freshness window.

Options:
  --repo PATH                 Git repo to inspect
  --commit-range RANGE        Inspect committed diff range
  --project REF_OR_NAME       Require receipt for this project
  --ledger FILE               Local mirror ledger JSONL
  --override-file FILE        Emergency override ledger to report, not bypass
  --max-age-minutes N         Receipt freshness window, default 60
  --dry-run                   Report would-block/would-pass but exit 0
  --json                      Emit structured JSON
EOF
}

die_usage() {
  printf 'ERR: %s\n' "$1" >&2
  usage >&2
  exit 2
}

iso_now() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

jq_json() {
  jq -nc "$@"
}

emit() {
  local status="$1" reason="$2" exit_code="$3" changed_count="$4" receipt_status="$5" emergency_overrides="$6"
  if [[ "$json" -eq 1 ]]; then
    jq_json \
      --arg schema "$SCHEMA_VERSION" \
      --arg ts "$(iso_now)" \
      --arg status "$status" \
      --arg reason "$reason" \
      --arg repo "$repo" \
      --arg project "$project" \
      --arg commit_range "${commit_range:-working-tree}" \
      --arg ledger "$ledger" \
      --arg receipt_status "$receipt_status" \
      --arg override_file "$override_file" \
      --argjson changed_count "$changed_count" \
      --argjson emergency_overrides "$emergency_overrides" \
      --argjson max_age_minutes "$max_age_minutes" \
      --argjson dry_run "$dry_run" \
      --argjson exit_code "$exit_code" \
      '{
        schema_version:$schema,
        ts:$ts,
        status:$status,
        reason:$reason,
        repo:$repo,
        project:$project,
        commit_range:$commit_range,
        changed_supabase_files:$changed_count,
        receipt_status:$receipt_status,
        ledger:$ledger,
        max_age_minutes:$max_age_minutes,
        emergency_override_file:$override_file,
        emergency_overrides_seen:$emergency_overrides,
        emergency_override_auto_bypass:false,
        dry_run:($dry_run == 1),
        exit_code:$exit_code
      }'
  else
    printf 'supabase-prepush-mirror-gate status=%s reason=%s changed=%s receipt=%s\n' "$status" "$reason" "$changed_count" "$receipt_status"
  fi
}

changed_files() {
  if [[ -n "$commit_range" ]]; then
    git -C "$repo" diff --name-only "$commit_range"
  else
    {
      git -C "$repo" diff --cached --name-only
      git -C "$repo" diff --name-only
    } | sort -u
  fi
}

file_path_is_supabase() {
  case "$1" in
    supabase/migrations/*.sql|*/supabase/migrations/*.sql|supabase/seed.sql|*/supabase/seed.sql|.zs-tenant.yaml|*.zs-tenant.yaml) return 0 ;;
    *) return 1 ;;
  esac
}

diff_has_rls_signal() {
  local diff_text
  if [[ -n "$commit_range" ]]; then
    diff_text="$(git -C "$repo" diff "$commit_range" -- . 2>/dev/null || true)"
  else
    diff_text="$({ git -C "$repo" diff --cached -- .; git -C "$repo" diff -- .; } 2>/dev/null || true)"
  fi
  grep -Eiq 'enable[[:space:]]+row[[:space:]]+level[[:space:]]+security|disable[[:space:]]+row[[:space:]]+level[[:space:]]+security|create[[:space:]]+policy|alter[[:space:]]+policy|drop[[:space:]]+policy|supabase[[:space:]]+db[[:space:]]+push|project_ref|expected_supabase_ref' <<<"$diff_text"
}

recent_receipt_status() {
  [[ -r "$ledger" ]] || { printf 'missing_ledger\n'; return 1; }
  python3 - "$ledger" "$max_age_minutes" "$project" <<'PY'
import datetime as dt
import json
import sys

ledger, max_age, project = sys.argv[1], int(sys.argv[2]), sys.argv[3]
now = dt.datetime.now(dt.timezone.utc)
best = None
with open(ledger, encoding="utf-8") as handle:
    for line in handle:
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except json.JSONDecodeError:
            continue
        if row.get("event") != "validate" or row.get("status") != "pass":
            continue
        if project and project not in {row.get("project_ref"), row.get("project_name")}:
            continue
        raw_ts = row.get("ts")
        if not raw_ts:
            continue
        try:
            ts = dt.datetime.fromisoformat(raw_ts.replace("Z", "+00:00"))
        except ValueError:
            continue
        age = (now - ts).total_seconds()
        if age <= max_age * 60:
            best = row
if best:
    print("fresh")
    sys.exit(0)
print("stale_or_missing")
sys.exit(1)
PY
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) json=1; shift ;;
    --dry-run) dry_run=1; shift ;;
    --repo) repo="${2:-}"; [[ -n "$repo" ]] || die_usage "--repo requires PATH"; shift 2 ;;
    --repo=*) repo="${1#--repo=}"; shift ;;
    --commit-range) commit_range="${2:-}"; [[ -n "$commit_range" ]] || die_usage "--commit-range requires RANGE"; shift 2 ;;
    --commit-range=*) commit_range="${1#--commit-range=}"; shift ;;
    --project) project="${2:-}"; [[ -n "$project" ]] || die_usage "--project requires value"; shift 2 ;;
    --project=*) project="${1#--project=}"; shift ;;
    --ledger) ledger="${2:-}"; [[ -n "$ledger" ]] || die_usage "--ledger requires FILE"; shift 2 ;;
    --ledger=*) ledger="${1#--ledger=}"; shift ;;
    --override-file) override_file="${2:-}"; [[ -n "$override_file" ]] || die_usage "--override-file requires FILE"; shift 2 ;;
    --override-file=*) override_file="${1#--override-file=}"; shift ;;
    --max-age-minutes) max_age_minutes="${2:-}"; [[ "$max_age_minutes" =~ ^[0-9]+$ ]] || die_usage "--max-age-minutes requires integer"; shift 2 ;;
    --max-age-minutes=*) max_age_minutes="${1#--max-age-minutes=}"; [[ "$max_age_minutes" =~ ^[0-9]+$ ]] || die_usage "--max-age-minutes requires integer"; shift ;;
    --help|-h) usage; exit 0 ;;
    *) die_usage "unknown option: $1" ;;
  esac
done

repo="$(cd "$repo" 2>/dev/null && pwd -P)" || {
  emit "blocked" "repo_not_found" 1 0 "missing" 0
  exit 1
}

files=()
while IFS= read -r file; do
  [[ -n "$file" ]] && files+=("$file")
done < <(changed_files)
changed_count=0
for file in "${files[@]}"; do
  if file_path_is_supabase "$file"; then
    changed_count=$((changed_count + 1))
  fi
done
if diff_has_rls_signal; then
  changed_count=$((changed_count + 1))
fi

override_count=0
if [[ -r "$override_file" ]]; then
  override_count="$(grep -cve '^[[:space:]]*$' "$override_file" || true)"
fi

if [[ "$changed_count" -eq 0 ]]; then
  emit "pass" "no_supabase_schema_or_rls_changes" 0 0 "not_required" "$override_count"
  exit 0
fi

if receipt_status="$(recent_receipt_status)"; then
  emit "pass" "fresh_local_mirror_validation_receipt" 0 "$changed_count" "$receipt_status" "$override_count"
  exit 0
fi

if [[ "$dry_run" -eq 1 ]]; then
  emit "would_block" "missing_fresh_local_mirror_validation_receipt" 0 "$changed_count" "$receipt_status" "$override_count"
  exit 0
fi

emit "blocked" "missing_fresh_local_mirror_validation_receipt" 1 "$changed_count" "$receipt_status" "$override_count"
exit 1
