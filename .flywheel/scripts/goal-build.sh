#!/usr/bin/env bash
# flywheel-cli-surface: true
# Compatibility note: goal-build.sh remains the authoring/grading entrypoint
# while loop-goal-gate.sh owns runtime loop halt decisions.
set -euo pipefail

VERSION="goal-build.v1.2.0"
SCHEMA_VERSION="flywheel.goal_build.v1"
MAX_CHARS=4000
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
GRADER="${SCRIPT_DIR}/goal_grade.py"
REPO_DEFAULT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
REPO_ROOT="${GOAL_BUILD_REPO:-$REPO_DEFAULT}"
GOALS_DIR_DEFAULT="${GOAL_BUILD_GOALS_DIR:-$HOME/Desktop/zeststream-goals}"
T2_VALIDATOR="$REPO_ROOT/scripts/validate_goal_text.py"

usage() {
  cat <<'EOF'
usage:
  goal-build.sh build --repo NAME --slug SLUG (--from FILE | --stdin) [--validate-full] [--json]
  goal-build.sh check --from FILE [--json]
  goal-build.sh grade --from FILE [--json]
  goal-build.sh list [--repo NAME] [--json]
  goal-build.sh --info|--schema|--examples [--json]
  goal-build.sh doctor|health|validate|quickstart|help [--json]

Compatibility note: goal-build.sh remains the legacy authoring/grading command.
loop-goal-gate.sh is the runtime loop halt gate, not the draft-goal grader.
EOF
}

emit_info() {
  cat <<JSON
{
  "name": "goal-build",
  "version": "$VERSION",
  "schema_version": "$SCHEMA_VERSION",
  "purpose": "Write and grade goal docs under ${MAX_CHARS} chars with authoring-time warnings.",
  "default_goals_dir": "$GOALS_DIR_DEFAULT",
  "compatibility_note": "goal-build.sh remains the legacy authoring/grading command; loop-goal-gate.sh owns runtime loop halt decisions.",
  "anti_pattern_fixed": "calendar-bound goal gates without event-bound override can stall infinite watches",
  "subcommands": ["build", "check", "list", "grade", "review", "weakest", "doctor", "health", "validate"],
  "warnings": ["calendar_bound_gate_without_event_bound_override"]
}
JSON
}

emit_schema() {
  cat <<JSON
{
  "schema_version": "$SCHEMA_VERSION",
  "max_chars": $MAX_CHARS,
  "input_schema": {
    "type": "object",
    "required": ["repo", "slug", "body_source"],
    "properties": {
      "repo": {"type": "string"},
      "slug": {"type": "string"},
      "body_source": {"enum": ["file", "stdin"]}
    }
  },
  "output_schema": {
    "type": "object",
    "required": ["status", "char_count", "limit"],
    "properties": {
      "status": {"enum": ["written", "refused", "pass", "fail", "error"]},
      "char_count": {"type": "integer"},
      "limit": {"type": "integer"},
      "path": {"type": "string"},
      "warnings": {"type": "array"}
    }
  },
  "output_path_template": "~/Desktop/zeststream-goals/<repo>/<slug>-<YYYYMMDD>.txt"
}
JSON
}

emit_examples() {
  cat <<'JSON'
{
  "examples": [
    {"name": "build from file", "command": "goal-build.sh build --repo flywheel --slug substrate --from /tmp/goal.txt --json"},
    {"name": "check only", "command": "goal-build.sh check --from /tmp/goal.txt --json"},
    {"name": "grade warnings", "command": "goal-build.sh grade --from /tmp/goal.txt --json"},
    {"name": "list repo goals", "command": "goal-build.sh list --repo flywheel --json"}
  ]
}
JSON
}

emit_doctor() {
  local status="ok"
  local t2_ok=false
  [[ -f "$T2_VALIDATOR" ]] && t2_ok=true || status="warn"
  local grader_ok=false
  [[ -f "$GRADER" ]] && grader_ok=true || status="fail"
  local python_ok=false
  command -v python3 >/dev/null 2>&1 && python_ok=true || status="fail"
  jq -nc \
    --arg status "$status" \
    --arg grader "$GRADER" \
    --arg t2 "$T2_VALIDATOR" \
    --argjson grader_ok "$grader_ok" \
    --argjson t2_ok "$t2_ok" \
    --argjson python_ok "$python_ok" \
    '{command:"doctor",status:$status,checks:[
      {check:"goal_grader_present",ok:$grader_ok,path:$grader},
      {check:"t2_validator_present",ok:$t2_ok,path:$t2},
      {check:"python3_available",ok:$python_ok}
    ]}'
}

count_chars() {
  python3 -c 'import sys; print(len(sys.stdin.read()))' <"$1"
}

trim_guidance() {
  local chars="$1"
  local over=$((chars - MAX_CHARS))
  cat <<EOF
REFUSED: body is $chars chars; limit is $MAX_CHARS ($over over).

Run goal-build.sh check --from <draft> --json to re-count without writing.
EOF
}

warnings_json() {
  local file="$1"
  if [[ -f "$GRADER" ]]; then
    python3 "$GRADER" grade --from "$file" --json | jq -c '.warnings // []'
  else
    printf '[]\n'
  fi
}

cmd_build() {
  local repo="" slug="" body_source="" body_file="" json_out=0 validate_full=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --repo) repo="$2"; shift 2 ;;
      --slug) slug="$2"; shift 2 ;;
      --from) body_source="file"; body_file="$2"; shift 2 ;;
      --stdin) body_source="stdin"; shift ;;
      --validate-full) validate_full=1; shift ;;
      --json) json_out=1; shift ;;
      *) printf 'unknown arg: %s\n' "$1" >&2; return 2 ;;
    esac
  done
  if [[ -z "$repo" || -z "$slug" || -z "$body_source" ]]; then
    printf 'usage: goal-build.sh build --repo NAME --slug SLUG (--from FILE | --stdin)\n' >&2
    return 2
  fi
  local tmpfile
  tmpfile="$(mktemp "${TMPDIR:-/tmp}/goal-build-body.XXXXXX")"
  if [[ "$body_source" == "file" ]]; then
    [[ -f "$body_file" ]] || { rm -f "$tmpfile"; printf 'file not found: %s\n' "$body_file" >&2; return 3; }
    cp "$body_file" "$tmpfile"
  else
    cat >"$tmpfile"
  fi
  local chars
  chars="$(count_chars "$tmpfile")"
  if [[ "$chars" -gt "$MAX_CHARS" ]]; then
    rm -f "$tmpfile"
    if [[ "$json_out" -eq 1 ]]; then
      jq -nc --argjson chars "$chars" --argjson limit "$MAX_CHARS" '{status:"refused",char_count:$chars,limit:$limit,refuse_reason:"over-4k"}'
    else
      trim_guidance "$chars" >&2
    fi
    return 1
  fi
  local out_dir="$GOALS_DIR_DEFAULT/$repo"
  mkdir -p "$out_dir"
  local date_stamp out_path
  date_stamp="$(date -u +%Y%m%d)"
  out_path="$out_dir/${slug}-${date_stamp}.txt"
  cp "$tmpfile" "$out_path"
  rm -f "$tmpfile"
  local full_validation="skip"
  if [[ "$validate_full" -eq 1 && -f "$T2_VALIDATOR" ]]; then
    if python3 "$T2_VALIDATOR" --file "$out_path" >/dev/null 2>&1; then
      full_validation="pass"
    else
      full_validation="fail"
    fi
  fi
  local grade_output="" composite=0 weakest="?"
  if [[ -f "$GRADER" ]]; then
    grade_output="$(python3 "$GRADER" write-residue --goal "$out_path" --json 2>/dev/null || true)"
    composite="$(printf '%s' "$grade_output" | jq -r '.row.composite // 0' 2>/dev/null || printf '0')"
    weakest="$(printf '%s' "$grade_output" | jq -r '.row.weakest_dim // "?"' 2>/dev/null || printf '?')"
  fi
  if [[ "$json_out" -eq 1 ]]; then
    jq -nc \
      --argjson chars "$chars" \
      --argjson limit "$MAX_CHARS" \
      --arg path "$out_path" \
      --arg full_validation "$full_validation" \
      --argjson composite "$composite" \
      --arg weakest "$weakest" \
      --argjson residue_logged "$(if [[ -n "$grade_output" ]]; then printf true; else printf false; fi)" \
      '{status:"written",char_count:$chars,limit:$limit,path:$path,full_validation:$full_validation,composite:$composite,weakest_dim:$weakest,residue_logged:$residue_logged}'
  else
    printf 'WRITTEN (%s/%s chars) -> %s\n' "$chars" "$MAX_CHARS" "$out_path"
  fi
  [[ "$full_validation" == "fail" ]] && return 4 || return 0
}

cmd_check() {
  local body_file="" json_out=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --from) body_file="$2"; shift 2 ;;
      --json) json_out=1; shift ;;
      *) printf 'unknown arg: %s\n' "$1" >&2; return 2 ;;
    esac
  done
  [[ -f "$body_file" ]] || { printf 'file not found: %s\n' "$body_file" >&2; return 3; }
  local chars warnings
  chars="$(count_chars "$body_file")"
  warnings="$(warnings_json "$body_file")"
  if [[ "$chars" -le "$MAX_CHARS" ]]; then
    [[ "$json_out" -eq 1 ]] && jq -nc --argjson chars "$chars" --argjson limit "$MAX_CHARS" --argjson warnings "$warnings" '{status:"pass",char_count:$chars,limit:$limit,warnings:$warnings}' || printf 'PASS (%s/%s chars)\n' "$chars" "$MAX_CHARS"
    return 0
  fi
  [[ "$json_out" -eq 1 ]] && jq -nc --argjson chars "$chars" --argjson limit "$MAX_CHARS" --argjson warnings "$warnings" '{status:"fail",char_count:$chars,limit:$limit,warnings:$warnings}' || trim_guidance "$chars" >&2
  return 1
}

cmd_list() {
  local repo="" json_out=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --repo) repo="$2"; shift 2 ;;
      --json) json_out=1; shift ;;
      *) printf 'unknown arg: %s\n' "$1" >&2; return 2 ;;
    esac
  done
  local search_dir="$GOALS_DIR_DEFAULT"
  [[ -n "$repo" ]] && search_dir="$GOALS_DIR_DEFAULT/$repo"
  [[ -d "$search_dir" ]] || { printf '[]\n'; return 0; }
  if [[ "$json_out" -eq 1 ]]; then
    find "$search_dir" -type f -name '*.txt' 2>/dev/null | python3 -c 'import json, sys
from pathlib import Path
limit = int(sys.argv[1])
rows = []
for line in sys.stdin:
    raw = line.strip()
    if not raw:
        continue
    path = Path(raw)
    try:
        chars = len(path.read_text())
    except OSError:
        continue
    rows.append({"path": str(path), "chars": chars, "limit_ok": chars <= limit})
print(json.dumps(rows, indent=2))' "$MAX_CHARS"
  else
    find "$search_dir" -type f -name '*.txt' 2>/dev/null
  fi
}

cmd_grader() {
  local subcommand="$1"
  shift
  [[ -f "$GRADER" ]] || { printf 'grader not found: %s\n' "$GRADER" >&2; return 3; }
  python3 "$GRADER" "$subcommand" "$@"
}

main() {
  case "${1:-}" in
    --info) shift; emit_info ;;
    --schema) shift; emit_schema ;;
    --examples) shift; emit_examples ;;
    --help|-h|"") usage ;;
    build) shift; cmd_build "$@" ;;
    check) shift; cmd_check "$@" ;;
    list) shift; cmd_list "$@" ;;
    grade) shift; cmd_grader grade "$@" ;;
    review) shift; cmd_grader review "$@" ;;
    weakest) shift; cmd_grader weakest "$@" ;;
    doctor|health|validate) shift; emit_doctor ;;
    quickstart) shift; printf '{"command":"quickstart","next":"goal-build.sh build --repo flywheel --slug <topic> --from <file>"}\n' ;;
    why|help) shift; usage ;;
    *) printf 'unknown subcommand: %s\n' "$1" >&2; usage >&2; return 2 ;;
  esac
}

main "$@"

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
