#!/usr/bin/env bash
set -euo pipefail

SCHEMA_VERSION="probe-registry-audit/v1"
REPO="$(pwd -P)"
SKILLS_ROOT="${FLYWHEEL_SKILLS_ROOT:-$HOME/.claude/skills/.flywheel}"
FLYWHEEL_LOOP="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
STATUS_DOC="${FLYWHEEL_STATUS_DOC:-$HOME/.claude/commands/flywheel/status.md}"
json=0
schema=0
self_test=0

usage() {
  cat <<'EOF'
usage: probe-registry-audit.sh [--json] [--schema] [--self-test] [--repo PATH] [--skills-root PATH] [--flywheel-loop PATH] [--status-doc PATH]

Inventories probe scripts and checks whether each has a discoverable ownership
rule, doctor integration, or dashboard policy. It intentionally reports
machine-only scripts instead of forcing every probe onto the dashboard.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) json=1; shift ;;
    --schema) schema=1; shift ;;
    --self-test) self_test=1; shift ;;
    --repo) REPO="$(cd "${2:?missing repo}" && pwd -P)"; shift 2 ;;
    --skills-root) SKILLS_ROOT="$(cd "${2:?missing skills root}" && pwd -P)"; shift 2 ;;
    --flywheel-loop) FLYWHEEL_LOOP="${2:?missing flywheel-loop path}"; shift 2 ;;
    --status-doc) STATUS_DOC="${2:?missing status doc path}"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

emit_schema() {
  jq -nc --arg schema_version "$SCHEMA_VERSION" '{
    schema_version:$schema_version,
    row_fields:["path","source","basename","owner_l_rule","doctor_key","dashboard_policy","orphaned_probe"],
    counts:["orphaned_probe_script_count","scripts_without_dashboard_policy_count"]
  }'
}

script_source() {
  local path="$1"
  case "$path" in
    "$REPO"/*) printf 'repo\n' ;;
    "$SKILLS_ROOT"/*) printf 'skills\n' ;;
    *) printf 'unknown\n' ;;
  esac
}

has_fixed_ref() {
  local needle="$1"; shift
  local file
  for file in "$@"; do
    [[ -f "$file" ]] || continue
    if rg -q -F "$needle" "$file" 2>/dev/null; then
      return 0
    fi
  done
  return 1
}

emit_report() {
  local rows="[]" path base source owner doctor dashboard orphan
  local candidates=()
  while IFS= read -r path; do candidates+=("$path"); done < <(
    {
      find "$REPO/.flywheel/scripts" -maxdepth 1 -type f \( -name '*.sh' -o -name '*.py' \) 2>/dev/null || true
      find "$SKILLS_ROOT/scripts" -maxdepth 1 -type f \( -name '*.sh' -o -name '*.py' \) 2>/dev/null || true
    } | sort -u
  )

  for path in "${candidates[@]}"; do
    base="$(basename "$path")"
    source="$(script_source "$path")"
    owner=false
    doctor=false
    dashboard=false

    if rg -q 'owner_l_rule|L[0-9][0-9]+' "$path" 2>/dev/null; then
      owner=true
    fi
    if has_fixed_ref "$base" "$FLYWHEEL_LOOP" "$REPO/.flywheel/flywheel-loop-tick"; then
      doctor=true
    fi
    if has_fixed_ref "$base" "$STATUS_DOC" "$REPO/README.md" || rg -q 'dashboard_line|dashboard_policy' "$path" 2>/dev/null; then
      dashboard=true
    fi

    if [[ "$owner" == false && "$doctor" == false && "$dashboard" == false ]]; then
      orphan=true
    else
      orphan=false
    fi

    rows="$(jq -c \
      --arg path "$path" \
      --arg source "$source" \
      --arg base "$base" \
      --argjson owner "$owner" \
      --argjson doctor "$doctor" \
      --argjson dashboard "$dashboard" \
      --argjson orphan "$orphan" \
      '. + [{path:$path,source:$source,basename:$base,owner_l_rule:$owner,doctor_key:$doctor,dashboard_policy:$dashboard,orphaned_probe:$orphan}]' \
      <<<"$rows")"
  done

  jq -nc --arg schema_version "$SCHEMA_VERSION" --arg repo "$REPO" --arg skills_root "$SKILLS_ROOT" --argjson rows "$rows" '
    ($rows | map(select(.orphaned_probe == true)) | length) as $orphaned
    | ($rows | map(select(.dashboard_policy != true)) | length) as $without_dashboard
    | {
        schema_version:$schema_version,
        status:(if $orphaned > 0 then "warn" else "pass" end),
        repo:$repo,
        skills_root:$skills_root,
        scripts_checked_count:($rows | length),
        orphaned_probe_script_count:$orphaned,
        scripts_without_dashboard_policy_count:$without_dashboard,
        rows:$rows
      }'
}

run_self_test() {
  local tmp repo skills loop status out
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/probe-registry.XXXXXX")"
  trap 'rm -rf "$tmp"' RETURN
  repo="$tmp/repo"
  skills="$tmp/skills"
  loop="$tmp/flywheel-loop"
  status="$tmp/status.md"
  mkdir -p "$repo/.flywheel/scripts" "$skills/scripts"
  printf '#!/usr/bin/env bash\n# owner_l_rule: L60\n' >"$repo/.flywheel/scripts/owned.sh"
  printf '#!/usr/bin/env bash\n' >"$repo/.flywheel/scripts/orphan.sh"
  printf 'owned.sh\n' >"$loop"
  printf 'owned.sh\n' >"$status"
  out="$("$0" --repo "$repo" --skills-root "$skills" --flywheel-loop "$loop" --status-doc "$status" --json)"
  jq -nc --arg schema_version "$SCHEMA_VERSION" --argjson report "$out" '{
    schema_version:$schema_version,
    status:(if $report.scripts_checked_count == 2
      and $report.orphaned_probe_script_count == 1 then "pass" else "fail" end),
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
