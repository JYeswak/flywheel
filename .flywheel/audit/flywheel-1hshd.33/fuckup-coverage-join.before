#!/usr/bin/env bash
set -euo pipefail

SCHEMA_VERSION="fuckup-coverage-join/v1"
REPO="$(pwd -P)"
LOG="${FLYWHEEL_FUCKUP_LOG:-$HOME/.local/state/flywheel/fuckup-log.jsonl}"
MEMORY_DIR="${FLYWHEEL_MEMORY_DIR:-$HOME/.claude/projects/-Users-josh-Developer-flywheel/memory}"
STATUS_DOC="${FLYWHEEL_STATUS_DOC:-$HOME/.claude/commands/flywheel/status.md}"
limit=50
json=0
schema=0
self_test=0

usage() {
  cat <<'EOF'
usage: fuckup-coverage-join.sh [--json] [--schema] [--self-test] [--repo PATH] [--log PATH] [--memory-dir PATH] [--limit N]

Joins unprocessed fuckup trauma classes to durable routing layers: memory,
INCIDENTS, canonical L-rules, probe scripts, and dashboard/status surfacing.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) json=1; shift ;;
    --schema) schema=1; shift ;;
    --self-test) self_test=1; shift ;;
    --repo) REPO="$(cd "${2:?missing repo}" && pwd -P)"; shift 2 ;;
    --log) LOG="${2:?missing log path}"; shift 2 ;;
    --memory-dir) MEMORY_DIR="${2:?missing memory dir}"; shift 2 ;;
    --status-doc) STATUS_DOC="${2:?missing status doc path}"; shift 2 ;;
    --limit) limit="${2:?missing limit}"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

emit_schema() {
  jq -nc --arg schema_version "$SCHEMA_VERSION" '{
    schema_version:$schema_version,
    joins:["memory","incident","canonical_l_rule","probe","dashboard"],
    output_fields:["fuckup_classes_without_route_count","promotion_ready_without_mechanism_count","rows"]
  }'
}

fixed_ref_exists() {
  local needle="$1"; shift
  local path
  for path in "$@"; do
    [[ -e "$path" ]] || continue
    if rg -q -F "$needle" "$path" 2>/dev/null; then
      return 0
    fi
  done
  return 1
}

class_groups() {
  if [[ ! -f "$LOG" ]]; then
    return 0
  fi
  jq -Rsc --argjson limit "$limit" '
    split("\n")
    | map(select(length > 0) | try fromjson catch empty)
    | [ .[]
      | select(type == "object")
      | select((.trauma_class // "") != "")
      | select((.processed_at // null) == null)
    ]
    | group_by(.trauma_class)
    | map({
        trauma_class:.[0].trauma_class,
        count:length,
        max_severity:(
          if any(.[]; .severity == "high") then "high"
          elif any(.[]; .severity == "medium") then "medium"
          else "low" end
        ),
        latest_ts:(map(.ts // "") | max),
        should_become:(map(.should_become // empty) | unique)
      })
    | sort_by(-.count, .trauma_class)
    | .[:$limit]
    | .[]
  ' "$LOG"
}

emit_report() {
  local rows="[]" group class count has_memory has_incident has_l_rule has_probe has_dashboard route_missing promotion_ready no_mechanism

  while IFS= read -r group; do
    [[ -n "$group" ]] || continue
    class="$(jq -r '.trauma_class' <<<"$group")"
    count="$(jq -r '.count' <<<"$group")"

    has_memory=false
    has_incident=false
    has_l_rule=false
    has_probe=false
    has_dashboard=false

    if fixed_ref_exists "$class" "$MEMORY_DIR" "$REPO/.flywheel/doctrine" "$REPO/.flywheel/fuckup-log"; then
      has_memory=true
    fi
    if fixed_ref_exists "$class" "$REPO/INCIDENTS.md" "$HOME/.claude/skills"/*/references/INCIDENTS.md; then
      has_incident=true
    fi
    if fixed_ref_exists "$class" "$REPO/AGENTS.md" "$REPO/.flywheel/AGENTS-CANONICAL.md" "$REPO/templates/flywheel-install/AGENTS.md"; then
      has_l_rule=true
    fi
    if fixed_ref_exists "$class" "$REPO/.flywheel/scripts"; then
      has_probe=true
    fi
    if fixed_ref_exists "$class" "$STATUS_DOC" "$REPO/README.md"; then
      has_dashboard=true
    fi

    route_missing=false
    if [[ "$has_memory" == false && "$has_incident" == false && "$has_l_rule" == false && "$has_probe" == false && "$has_dashboard" == false ]]; then
      route_missing=true
    fi
    promotion_ready=false
    no_mechanism=false
    if [[ "$count" -ge 3 ]]; then
      promotion_ready=true
      if [[ "$has_l_rule" == false && "$has_probe" == false && "$has_dashboard" == false ]]; then
        no_mechanism=true
      fi
    fi

    rows="$(jq -c \
      --argjson group "$group" \
      --argjson has_memory "$has_memory" \
      --argjson has_incident "$has_incident" \
      --argjson has_l_rule "$has_l_rule" \
      --argjson has_probe "$has_probe" \
      --argjson has_dashboard "$has_dashboard" \
      --argjson route_missing "$route_missing" \
      --argjson promotion_ready "$promotion_ready" \
      --argjson no_mechanism "$no_mechanism" \
      '. + [$group + {has_memory:$has_memory,has_incident:$has_incident,has_canonical_l_rule:$has_l_rule,has_probe:$has_probe,has_dashboard:$has_dashboard,route_missing:$route_missing,promotion_ready:$promotion_ready,promotion_ready_without_mechanism:$no_mechanism}]' \
      <<<"$rows")"
  done < <(class_groups)

  jq -nc --arg schema_version "$SCHEMA_VERSION" --arg repo "$REPO" --arg log "$LOG" --arg memory_dir "$MEMORY_DIR" --argjson rows "$rows" '
    ($rows | map(select(.route_missing == true)) | length) as $without_route
    | ($rows | map(select(.promotion_ready_without_mechanism == true)) | length) as $without_mechanism
    | {
        schema_version:$schema_version,
        status:(if $without_route > 0 or $without_mechanism > 0 then "warn" else "pass" end),
        repo:$repo,
        fuckup_log:$log,
        memory_dir:$memory_dir,
        classes_checked_count:($rows | length),
        fuckup_classes_without_route_count:$without_route,
        promotion_ready_without_mechanism_count:$without_mechanism,
        rows:$rows
      }'
}

run_self_test() {
  local tmp repo log memory status out
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/fuckup-coverage.XXXXXX")"
  trap 'rm -rf "$tmp"' RETURN
  repo="$tmp/repo"
  memory="$tmp/memory"
  log="$tmp/fuckup-log.jsonl"
  status="$tmp/status.md"
  mkdir -p "$repo/.flywheel/scripts" "$repo/templates/flywheel-install" "$memory"
  printf 'known-class\n' >"$repo/AGENTS.md"
  printf 'probe-class\n' >"$repo/.flywheel/scripts/probe.sh"
  printf 'dashboard-class\n' >"$status"
  jq -nc '{trauma_class:"known-class",severity:"medium",ts:"2026-05-04T00:00:00Z",processed_at:null}' >>"$log"
  jq -nc '{trauma_class:"missing-class",severity:"high",ts:"2026-05-04T00:01:00Z",processed_at:null}' >>"$log"
  jq -nc '{trauma_class:"missing-class",severity:"high",ts:"2026-05-04T00:02:00Z",processed_at:null}' >>"$log"
  jq -nc '{trauma_class:"missing-class",severity:"high",ts:"2026-05-04T00:03:00Z",processed_at:null}' >>"$log"
  out="$("$0" --repo "$repo" --log "$log" --memory-dir "$memory" --status-doc "$status" --json)"
  jq -nc --arg schema_version "$SCHEMA_VERSION" --argjson report "$out" '{
    schema_version:$schema_version,
    status:(if $report.fuckup_classes_without_route_count == 1
      and $report.promotion_ready_without_mechanism_count == 1 then "pass" else "fail" end),
    report:$report
  }'
}

if [[ "$schema" -eq 1 ]]; then
  emit_schema
elif [[ "$self_test" -eq 1 ]]; then
  run_self_test
else
  emit_report
fi
