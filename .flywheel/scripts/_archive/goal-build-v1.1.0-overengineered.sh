#!/usr/bin/env bash
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (skeleton — info/schema/examples + build/doctor/health/validate)
#
# goal-build.sh — write a goal doc ≤4000 chars to a per-repo canonical path.
#
# Removes the recurring failure mode: Joshua repeatedly re-iterates the
# 4000-char limit because writers (operators, agents) keep emitting goal docs
# over the limit. The fix is to refuse the write at substrate level.
#
# Canonical output: ~/Desktop/zeststream-goals/<repo>/<slug>-<YYYYMMDD>.txt
# (Override via GOAL_BUILD_GOALS_DIR env var; in-repo not used so docs are
# accessible in Finder without traversing a dotfolder.)
#
# Exit codes:
#   0  goal written + validated
#   1  body exceeds 4000 chars (REFUSED with trim guidance)
#   2  usage error
#   3  I/O error
#   4  T2 full-validation failure when --validate-full requested
#
# Memory: feedback_goal_build_machine_enforced_4k_limit.md (to be saved by caller)

set -euo pipefail

VERSION="goal-build.v1.1.0"
SCHEMA_VERSION="flywheel.goal_build.v1"
MAX_CHARS=4000
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
GRADER="${SCRIPT_DIR}/goal_grade.py"
REPO_DEFAULT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
REPO_ROOT="${GOAL_BUILD_REPO:-$REPO_DEFAULT}"
# Default to ~/Desktop/zeststream-goals/ — visible in Finder, easy CLI access.
# Operator override via GOAL_BUILD_GOALS_DIR env var.
GOALS_DIR_DEFAULT="${GOAL_BUILD_GOALS_DIR:-$HOME/Desktop/zeststream-goals}"
T2_VALIDATOR="$REPO_ROOT/scripts/validate_goal_text.py"

usage() {
  cat <<'EOF'
usage:
  goal-build.sh build --repo NAME --slug SLUG (--from FILE | --stdin) [--validate-full] [--json]
  goal-build.sh check --from FILE [--json]
  goal-build.sh list [--repo NAME] [--json]
  goal-build.sh --info|--schema|--examples [--json]
  goal-build.sh doctor|health|validate|quickstart|help [TOPIC] [--json]
  goal-build.sh --help|-h

Writes goal docs ≤4000 chars to .flywheel/goals/<repo>/<slug>-<YYYYMMDD>.txt.
REFUSES to write any body over 4000 chars. The check subcommand validates
without writing.
EOF
}

# ── canonical metadata surfaces ──────────────────────────────────────────────

emit_info() {
  cat <<JSON
{
  "name": "goal-build",
  "version": "$VERSION",
  "schema_version": "$SCHEMA_VERSION",
  "purpose": "Write goal docs ≤${MAX_CHARS} chars to per-repo canonical path. Machine-enforced limit.",
  "default_goals_dir": "$GOALS_DIR_DEFAULT",
  "capabilities": [
    "validate body char count (≤${MAX_CHARS})",
    "write to ~/Desktop/zeststream-goals/<repo>/<slug>-<YYYYMMDD>.txt (override via GOAL_BUILD_GOALS_DIR)",
    "refuse over-limit writes with trim guidance",
    "optional T2 full-validation via validate_goal_text.py"
  ],
  "subcommands": ["build", "check", "list", "doctor", "health", "validate", "help", "quickstart"],
  "canonical_cli_flags": ["--info", "--schema", "--examples", "--json", "--help"],
  "mutates_state": "yes (writes to .flywheel/goals/)",
  "anti_pattern_fixed": "Joshua re-iterating 4k limit multiple times per session"
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
      "repo": {"type": "string", "description": "Repo slug (e.g. flywheel, skillos, mobile-eats, cross-repo)"},
      "slug": {"type": "string", "description": "Kebab-case topic slug"},
      "body_source": {"enum": ["file", "stdin"]}
    }
  },
  "output_schema": {
    "type": "object",
    "required": ["status", "char_count", "limit", "path"],
    "properties": {
      "status": {"enum": ["written", "refused", "error"]},
      "char_count": {"type": "integer"},
      "limit": {"type": "integer"},
      "path": {"type": "string"},
      "refuse_reason": {"type": "string"}
    }
  },
  "output_path_template": "~/Desktop/zeststream-goals/<repo>/<slug>-<YYYYMMDD>.txt",
  "env_overrides": {
    "GOAL_BUILD_GOALS_DIR": "override default output folder",
    "GOAL_BUILD_REPO": "override repo root (for the T2 validator path resolution)"
  }
}
JSON
}

emit_examples() {
  cat <<JSON
{
  "examples": [
    {
      "name": "build a goal doc from a file",
      "command": "goal-build.sh build --repo flywheel --slug substrate-compounding --from ~/Desktop/goal-draft.txt"
    },
    {
      "name": "build from stdin (heredoc)",
      "command": "cat <<EOF | goal-build.sh build --repo skillos --slug fcla-w1 --stdin\\n<goal body>\\nEOF"
    },
    {
      "name": "check a file without writing",
      "command": "goal-build.sh check --from ~/Desktop/goal-draft.txt --json"
    },
    {
      "name": "list all goal docs for a repo",
      "command": "goal-build.sh list --repo flywheel"
    }
  ]
}
JSON
}

emit_doctor() {
  local checks_json=()
  local status="ok"
  local n=0
  if [[ -x "$T2_VALIDATOR" ]] || [[ -f "$T2_VALIDATOR" ]]; then
    checks_json+=("$(printf '{"check":"t2_validator_present","ok":true,"path":"%s"}' "$T2_VALIDATOR")")
  else
    checks_json+=("$(printf '{"check":"t2_validator_present","ok":false,"path":"%s"}' "$T2_VALIDATOR")")
    status="warn"
  fi
  if [[ -d "$GOALS_DIR_DEFAULT" ]]; then
    checks_json+=("$(printf '{"check":"goals_dir_exists","ok":true,"path":"%s"}' "$GOALS_DIR_DEFAULT")")
  else
    checks_json+=("$(printf '{"check":"goals_dir_exists","ok":false,"path":"%s"}' "$GOALS_DIR_DEFAULT")")
  fi
  if command -v python3 >/dev/null 2>&1; then
    checks_json+=('{"check":"python3_available","ok":true}')
  else
    checks_json+=('{"check":"python3_available","ok":false}')
    status="fail"
  fi
  printf '{"command":"doctor","status":"%s","checks":[%s]}\n' "$status" "$(IFS=,; echo "${checks_json[*]}")"
  [[ "$status" == "fail" ]] && return 1 || return 0
}

# ── core validation ──────────────────────────────────────────────────────────

count_chars() {
  python3 -c "import sys; print(len(sys.stdin.read()))" <"$1"
}

validate_size() {
  local file="$1"
  local n
  n="$(count_chars "$file")"
  echo "$n"
  [[ "$n" -le "$MAX_CHARS" ]]
}

trim_guidance() {
  local n="$1"
  local over=$((n - MAX_CHARS))
  cat <<EOF
REFUSED: body is $n chars; limit is $MAX_CHARS ($over over).

To fit:
  1. Drop "Why this is hard" / "Out of scope" / "When stuck" / process-doc sections.
  2. Compress each phase to: name + 1-line purpose + 1-line exit criterion.
  3. Mission anchors verbatim once at top; do not restate at bottom.
  4. Replace separator boxes (═══) with blank lines; saves ~80 chars per section.
  5. Use abbreviations: AC, EXIT, P1..P10 instead of "Acceptance Criterion", "EXIT CRITERION", "PHASE 1".

Run goal-build.sh check --from <draft> to re-count without writing.
EOF
}

# ── build (write) ────────────────────────────────────────────────────────────

cmd_build() {
  local repo="" slug="" body_source="" body_file="" validate_full=0 json_out=0
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
    if [[ ! -f "$body_file" ]]; then
      rm -f "$tmpfile"
      printf 'file not found: %s\n' "$body_file" >&2
      return 3
    fi
    cp "$body_file" "$tmpfile"
  else
    cat >"$tmpfile"
  fi
  local n
  n="$(count_chars "$tmpfile")"
  if [[ "$n" -gt "$MAX_CHARS" ]]; then
    rm -f "$tmpfile"
    if [[ "$json_out" -eq 1 ]]; then
      printf '{"status":"refused","char_count":%d,"limit":%d,"refuse_reason":"over-4k"}\n' "$n" "$MAX_CHARS"
    else
      trim_guidance "$n" >&2
    fi
    return 1
  fi
  local goals_dir="$GOALS_DIR_DEFAULT/$repo"
  mkdir -p "$goals_dir"
  local date_stamp
  date_stamp="$(date -u +%Y%m%d)"
  local out_path="$goals_dir/${slug}-${date_stamp}.txt"
  cp "$tmpfile" "$out_path"
  rm -f "$tmpfile"
  if [[ "$validate_full" -eq 1 && -f "$T2_VALIDATOR" ]]; then
    if ! python3 "$T2_VALIDATOR" --file "$out_path" >/dev/null 2>&1; then
      if [[ "$json_out" -eq 1 ]]; then
        printf '{"status":"written","char_count":%d,"limit":%d,"path":"%s","full_validation":"fail"}\n' "$n" "$MAX_CHARS" "$out_path"
      else
        printf 'WRITTEN (%d chars) but full T2 validation failed: %s\n' "$n" "$out_path"
      fi
      return 4
    fi
  fi
  # Auto-grade the written goal + append residue row to the ledger.
  # Failure to grade is non-fatal — the write already succeeded.
  local grade_output=""
  if [[ -x "$GRADER" ]] || [[ -f "$GRADER" ]]; then
    grade_output="$(python3 "$GRADER" write-residue --goal "$out_path" --json 2>/dev/null || true)"
  fi
  if [[ "$json_out" -eq 1 ]]; then
    if [[ -n "$grade_output" ]]; then
      local composite weakest
      composite="$(echo "$grade_output" | python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('row',{}).get('composite',0))" 2>/dev/null || echo 0)"
      weakest="$(echo "$grade_output" | python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('row',{}).get('weakest_dim','?'))" 2>/dev/null || echo '?')"
      printf '{"status":"written","char_count":%d,"limit":%d,"path":"%s","composite":%s,"weakest_dim":"%s","residue_logged":true}\n' "$n" "$MAX_CHARS" "$out_path" "$composite" "$weakest"
    else
      printf '{"status":"written","char_count":%d,"limit":%d,"path":"%s","residue_logged":false}\n' "$n" "$MAX_CHARS" "$out_path"
    fi
  else
    printf 'WRITTEN (%d/%d chars) → %s\n' "$n" "$MAX_CHARS" "$out_path"
    if [[ -n "$grade_output" ]]; then
      local composite weakest
      composite="$(echo "$grade_output" | python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('row',{}).get('composite',0))" 2>/dev/null || echo 0)"
      weakest="$(echo "$grade_output" | python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('row',{}).get('weakest_dim','?'))" 2>/dev/null || echo '?')"
      printf 'GRADE   %s/100 composite (weakest: %s)\nRESIDUE %s\n' "$composite" "$weakest" "$HOME/Desktop/zeststream-goals/_residue/ledger.jsonl"
    fi
  fi
  return 0
}

# ── grade / review / weakest passthrough subcommands ────────────────────────

cmd_grade() {
  [[ -f "$GRADER" ]] || { printf 'grader not found: %s\n' "$GRADER" >&2; return 3; }
  python3 "$GRADER" grade "$@"
}

cmd_review() {
  [[ -f "$GRADER" ]] || { printf 'grader not found: %s\n' "$GRADER" >&2; return 3; }
  python3 "$GRADER" review "$@"
}

cmd_weakest() {
  [[ -f "$GRADER" ]] || { printf 'grader not found: %s\n' "$GRADER" >&2; return 3; }
  python3 "$GRADER" weakest "$@"
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
  local n
  n="$(count_chars "$body_file")"
  if [[ "$n" -le "$MAX_CHARS" ]]; then
    if [[ "$json_out" -eq 1 ]]; then
      printf '{"status":"pass","char_count":%d,"limit":%d}\n' "$n" "$MAX_CHARS"
    else
      printf 'PASS (%d/%d chars)\n' "$n" "$MAX_CHARS"
    fi
    return 0
  fi
  if [[ "$json_out" -eq 1 ]]; then
    printf '{"status":"fail","char_count":%d,"limit":%d}\n' "$n" "$MAX_CHARS"
  else
    trim_guidance "$n" >&2
  fi
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
    find "$search_dir" -type f -name "*.txt" 2>/dev/null | python3 -c "
import sys, os, json
paths = [l.strip() for l in sys.stdin if l.strip()]
out = []
for p in paths:
    try:
        n = len(open(p).read())
        out.append({'path': p, 'chars': n, 'limit_ok': n <= $MAX_CHARS})
    except OSError:
        pass
print(json.dumps(out, indent=2))
"
  else
    find "$search_dir" -type f -name "*.txt" 2>/dev/null | while read -r p; do
      n="$(python3 -c "print(len(open('$p').read()))" 2>/dev/null || echo "?")"
      printf '%5s chars  %s\n' "$n" "$p"
    done
  fi
}

# ── dispatch ──────────────────────────────────────────────────────────────────

main() {
  case "${1:-}" in
    --info) shift; emit_info; return 0 ;;
    --schema) shift; emit_schema; return 0 ;;
    --examples) shift; emit_examples; return 0 ;;
    --help|-h|"") usage; return 0 ;;
    build) shift; cmd_build "$@" ;;
    check) shift; cmd_check "$@" ;;
    list) shift; cmd_list "$@" ;;
    grade) shift; cmd_grade "$@" ;;
    review) shift; cmd_review "$@" ;;
    weakest) shift; cmd_weakest "$@" ;;
    doctor|health) shift; emit_doctor ;;
    validate) shift; emit_doctor ;;
    quickstart) printf '{"command":"quickstart","next":"goal-build.sh build --repo flywheel --slug <topic> --from <file>"}\n' ;;
    why|help) printf '{"command":"%s","see":"--help for usage"}\n' "${1:-help}" ;;
    *) printf 'unknown subcommand: %s\n' "$1" >&2; usage >&2; return 2 ;;
  esac
}

main "$@"
