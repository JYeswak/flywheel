#!/usr/bin/env bash
set -euo pipefail

SCHEMA_VERSION="docs-validation-probe/v1"
REPO="$(pwd -P)"
json=0
schema=0
self_test=0
doc_paths=()

usage() {
  cat <<'EOF'
usage: docs-validation-probe.sh [--json] [--schema] [--self-test] [--repo PATH] [--doc PATH ...]

Checks load-bearing documentation for explicit cross-pane validation metadata.
Missing metadata is reported as pending; self-validation or failed validation is
reported as failed.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) json=1; shift ;;
    --schema) schema=1; shift ;;
    --self-test) self_test=1; shift ;;
    --repo) REPO="$(cd "${2:?missing repo}" && pwd -P)"; shift 2 ;;
    --doc) doc_paths+=("${2:?missing doc path}"); shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

emit_schema() {
  jq -nc --arg schema_version "$SCHEMA_VERSION" '{
    schema_version:$schema_version,
    metadata_fields:["docs_validation_status","validated_by_pane","authored_by_pane"],
    output_fields:["docs_validation_pending_count","docs_validation_failed_count","readme_below_floor_count","rows"]
  }'
}

field_value() {
  local file="$1" key="$2"
  awk -F: -v key="$key" '
    BEGIN { IGNORECASE=1 }
    $1 ~ "^[[:space:]]*" key "[[:space:]]*$" {
      sub(/^[^:]+:[[:space:]]*/, "")
      gsub(/^[[:space:]"'\''`]+|[[:space:]"'\''`]+$/, "")
      print
      exit
    }
  ' "$file" 2>/dev/null || true
}

line_count() {
  wc -l <"$1" 2>/dev/null | tr -d ' '
}

emit_report() {
  local rows="[]" candidates=() file status validated_by authored_by lines pending failed readme_below

  if [[ "${#doc_paths[@]}" -gt 0 ]]; then
    candidates=("${doc_paths[@]}")
  else
    candidates=(
      "$REPO/README.md"
      "$REPO/AGENTS.md"
      "$REPO/.flywheel/AGENTS-CANONICAL.md"
      "$REPO/.flywheel/MISSION.md"
      "$REPO/.flywheel/GOAL.md"
      "$REPO/.flywheel/STATE.md"
      "$REPO/templates/flywheel-install/AGENTS.md"
    )
  fi

  for file in "${candidates[@]}"; do
    [[ -f "$file" ]] || continue
    status="$(field_value "$file" "docs_validation_status")"
    [[ -n "$status" ]] || status="$(field_value "$file" "validation_status")"
    validated_by="$(field_value "$file" "validated_by_pane")"
    authored_by="$(field_value "$file" "authored_by_pane")"
    lines="$(line_count "$file")"

    pending=false
    failed=false
    readme_below=false
    if [[ -z "$status" || "$status" == "pending" || "$status" == "reviewed" || "$status" == "draft" ]]; then
      pending=true
    fi
    if [[ "$status" == "failed" || ( -n "$validated_by" && -n "$authored_by" && "$validated_by" == "$authored_by" ) ]]; then
      failed=true
    fi
    if [[ "$(basename "$file")" == "README.md" && "$lines" -lt 20 ]]; then
      readme_below=true
    fi

    rows="$(jq -c \
      --arg path "$file" \
      --arg status "${status:-missing}" \
      --arg validated_by "${validated_by:-}" \
      --arg authored_by "${authored_by:-}" \
      --argjson lines "$lines" \
      --argjson pending "$pending" \
      --argjson failed "$failed" \
      --argjson readme_below "$readme_below" \
      '. + [{path:$path,docs_validation_status:$status,validated_by_pane:$validated_by,authored_by_pane:$authored_by,line_count:$lines,pending:$pending,failed:$failed,readme_below_floor:$readme_below}]' \
      <<<"$rows")"
  done

  jq -nc --arg schema_version "$SCHEMA_VERSION" --arg repo "$REPO" --argjson rows "$rows" '
    ($rows | map(select(.pending == true)) | length) as $pending
    | ($rows | map(select(.failed == true)) | length) as $failed
    | ($rows | map(select(.readme_below_floor == true)) | length) as $below
    | {
        schema_version:$schema_version,
        status:(if $failed > 0 then "fail" elif $pending > 0 or $below > 0 then "warn" else "pass" end),
        repo:$repo,
        docs_checked_count:($rows | length),
        docs_validation_pending_count:$pending,
        docs_validation_failed_count:$failed,
        readme_below_floor_count:$below,
        rows:$rows
      }'
}

run_self_test() {
  local tmp repo out
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/docs-validation.XXXXXX")"
  trap 'rm -rf "$tmp"' RETURN
  repo="$tmp/repo"
  mkdir -p "$repo/.flywheel" "$repo/templates/flywheel-install"
  printf '# Good\n\ndocs_validation_status: validated\nauthored_by_pane: pane2\nvalidated_by_pane: pane3\n\nline\nline\nline\nline\nline\nline\nline\nline\nline\nline\nline\nline\nline\nline\nline\nline\nline\nline\n' >"$repo/README.md"
  printf '# Self\n\ndocs_validation_status: validated\nauthored_by_pane: pane2\nvalidated_by_pane: pane2\n' >"$repo/AGENTS.md"
  printf '# Pending\n' >"$repo/.flywheel/MISSION.md"
  out="$("$0" --repo "$repo" --json)"
  jq -nc --arg schema_version "$SCHEMA_VERSION" --argjson report "$out" '{
    schema_version:$schema_version,
    status:(if $report.docs_validation_failed_count == 1
      and $report.docs_validation_pending_count == 1 then "pass" else "fail" end),
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
