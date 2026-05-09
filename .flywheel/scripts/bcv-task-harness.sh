#!/usr/bin/env bash
# bcv-task-harness.sh — orchestrate real Phase 4/6 BCV task packs.
set -euo pipefail

VERSION="bcv-task-harness/v1"
DEFAULT_SKILL_DIR="/Users/josh/.claude/skills/beads-compliance-and-completion-verification"

usage() {
  cat <<'USAGE'
Usage:
  bcv-task-harness.sh --repo <path> --beads <id,id> --apply [options]
  bcv-task-harness.sh --info|--schema|--examples [--json]

Options:
  --repo PATH                 Project containing .beads/ (default: cwd)
  --audit-dir PATH            Audit directory override
  --beads IDS                 Comma-separated bead ids to audit
  --beads-file PATH           One bead id per line
  --threshold N               Score threshold (default: 700)
  --mode NAME                 Audit mode label (default: task-harness)
  --policy NAME               Audit policy label (default: completion-debt)
  --skill-dir PATH            BCV skill dir
  --wait-timeout-seconds N    Timeout for each Task-tool wait phase (default: 600)
  --poll-seconds N            Poll interval while waiting (default: 2)
  --apply                     Create pass and wait for real packs
  --dry-run                   Print plan only (default)
  --json                      Emit JSON receipt
  --help                      Show this help

This harness stops the deterministic BCV flow after Phase 3, emits Task-tool
prompt files for Phase 4 and Phase 6, waits for non-stub packs, then runs
Phase 5, validation, scoring, and master-report generation.
USAGE
}

json_escape() {
  jq -Rn --arg v "$1" '$v'
}

emit_info() {
  if [ "$JSON_OUT" = "1" ]; then
    jq -n --arg version "$VERSION" --arg skill_dir "$SKILL_DIR" '{
      tool: "bcv-task-harness.sh",
      version: $version,
      purpose: "Run BCV Phase 0.5-3 deterministically, delegate Phase 4/6 to Task-tool subagents, then validate/score/report non-stub packs.",
      skill_dir: $skill_dir,
      required_phase4_executor: "subagents/compliance-verifier.md",
      required_phase6_auditor: "subagents/test-depth-auditor.md"
    }'
  else
    printf '%s\n' "$VERSION"
    printf 'skill_dir=%s\n' "$SKILL_DIR"
    printf 'phase4_executor=subagents/compliance-verifier.md\n'
    printf 'phase6_auditor=subagents/test-depth-auditor.md\n'
  fi
}

emit_schema() {
  cat <<'SCHEMA'
{
  "tool": "bcv-task-harness.sh",
  "version": "string",
  "status": "dry_run|complete",
  "repo": "absolute path",
  "audit_dir": "absolute path or null",
  "pass_dir": "absolute path or null",
  "target_beads": ["bead-id"],
  "phase4_prompts": ["path"],
  "phase6_prompts": ["path"],
  "non_stub_compliance_count": 0,
  "non_stub_test_depth_count": 0,
  "validation_passed": true,
  "deterministic_banner_present": false,
  "report_path": "path or null"
}
SCHEMA
}

emit_examples() {
  cat <<'EXAMPLES'
# Plan only:
.flywheel/scripts/bcv-task-harness.sh --repo "$PWD" --beads bd-123,bd-456 --json

# Real run, waiting up to 15 minutes for Task-tool output packs:
.flywheel/scripts/bcv-task-harness.sh --repo "$PWD" --beads bd-123,bd-456 --apply --wait-timeout-seconds 900 --json
EXAMPLES
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 2
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"
}

abs_path() {
  local p="$1"
  if [ -d "$p" ]; then
    (cd "$p" && pwd -P)
  else
    local d b
    d="$(dirname "$p")"
    b="$(basename "$p")"
    (cd "$d" && printf '%s/%s\n' "$(pwd -P)" "$b")
  fi
}

split_beads() {
  local raw="$1"
  printf '%s\n' "$raw" | tr ',' '\n' | sed '/^[[:space:]]*$/d' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

load_targets() {
  TARGET_BEADS=()
  local seen=""
  if [ -n "$BEADS_RAW" ]; then
    while IFS= read -r id; do
      [ -n "$id" ] || continue
      case "
$seen
" in
        *"
$id
"*) ;;
        *) TARGET_BEADS+=("$id"); seen="${seen}${id}
" ;;
      esac
    done < <(split_beads "$BEADS_RAW")
  fi
  if [ -n "$BEADS_FILE" ]; then
    [ -f "$BEADS_FILE" ] || die "beads file not found: $BEADS_FILE"
    while IFS= read -r id; do
      id="${id%%#*}"
      id="$(printf '%s' "$id" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
      [ -n "$id" ] || continue
      case "
$seen
" in
        *"
$id
"*) ;;
        *) TARGET_BEADS+=("$id"); seen="${seen}${id}
" ;;
      esac
    done < "$BEADS_FILE"
  fi
  [ "${#TARGET_BEADS[@]}" -gt 0 ] || die "no target beads supplied; use --beads or --beads-file"
}

run_step() {
  printf '==> %s\n' "$*" >&2
  "$@"
}

db_path() {
  shopt -s nullglob
  local dbs=( "$REPO/.beads"/*.db )
  shopt -u nullglob
  [ "${#dbs[@]}" -gt 0 ] || die "no SQLite DB in $REPO/.beads/"
  printf '%s\n' "${dbs[0]}"
}

scoped_inventory_fallback() {
  local db id bd raw_show status closed_total=0 closed_with_xref=0
  db="$(db_path)"
  printf 'WARN: inventory-beads.sh failed; using scoped target-bead inventory fallback\n' >&2
  mkdir -p "$PASS_DIR/beads"
  br --db "$db" doctor --json > "$PASS_DIR/doctor.json"
  br --db "$db" dep cycles --json > "$PASS_DIR/cycles.json" 2>/dev/null || echo '[]' > "$PASS_DIR/cycles.json"
  : > "$PASS_DIR/inventory.jsonl"
  for id in "${TARGET_BEADS[@]}"; do
    bd="$PASS_DIR/beads/$id"
    mkdir -p "$bd"
    raw_show="$(br --db "$db" show "$id" --format json 2>/dev/null || true)"
    if [ -z "$raw_show" ]; then
      raw_show="$(br --db "$db" show "$id" --json 2>/dev/null || true)"
    fi
    [ -n "$raw_show" ] || die "br show failed for target bead $id"
    printf '%s' "$raw_show" | jq 'if type == "array" then .[0] else . end' > "$bd/show.json"
    jq -c '{
      id,
      title,
      status,
      priority,
      issue_type,
      created_at,
      closed_at,
      closed_by_session,
      close_reason
    }' "$bd/show.json" >> "$PASS_DIR/inventory.jsonl"
    status="$(jq -r '.status | if type == "string" then . elif type == "object" then (to_entries[0].value | tostring) else "unknown" end' "$bd/show.json")"
    if [ "$status" = "closed" ]; then
      closed_total=$((closed_total + 1))
      if [ -d "$REPO/.git" ]; then
        git -C "$REPO" log --all -F --grep="$id" --format='%H%x09%ad%x09%s' --date=iso \
          > "$bd/git_xref.txt" 2>/dev/null || true
        if [ -s "$bd/git_xref.txt" ]; then
          closed_with_xref=$((closed_with_xref + 1))
        fi
      else
        : > "$bd/git_xref.txt"
      fi
    fi
  done
  jq -n \
    --argjson total "$closed_total" \
    --argjson with_xref "$closed_with_xref" \
    '{
      closed_beads_total: $total,
      closed_beads_with_git_xref: $with_xref,
      coverage_pct: (if $total == 0 then 0 else (($with_xref * 10000 / $total) | floor / 100) end),
      project_convention_gap_widespread: false,
      threshold_pct: 30.0,
      min_n_for_gap_detection: 10,
      note: "scoped fallback inventory for bcv-task-harness"
    }' > "$PASS_DIR/git_xref_coverage.json"
}

run_inventory() {
  if run_step bash "$SCRIPTS_DIR/inventory-beads.sh" "$REPO" "$PASS_DIR" >/dev/null; then
    return 0
  fi
  scoped_inventory_fallback
}

bead_dir_for() {
  printf '%s/beads/%s\n' "$PASS_DIR" "$1"
}

ensure_bead_dir() {
  local id="$1" bd
  bd="$(bead_dir_for "$id")"
  [ -d "$bd" ] || die "target bead $id was not inventoried under $PASS_DIR"
}

write_phase4_prompt() {
  local id="$1" bd="$2" out="$3"
  mkdir -p "$(dirname "$out")"
  cat > "$out" <<EOF
Task tool prompt: compliance-verifier

Subagent contract:
  /Users/josh/.claude/skills/beads-compliance-and-completion-verification/subagents/compliance-verifier.md

Inputs:
  repo: $REPO
  bead_dir: $bd
  bead_id: $id
  show_json: $bd/show.json
  spec_json: $bd/spec.json
  evidence_json: $bd/evidence.json

Required output:
  Write $bd/compliance.json with:
    - bead_id: "$id"
    - executed_at: current UTC timestamp
    - executor: "subagents/compliance-verifier.md"
    - checks: array of required-test verdict checks

Do not write executor="stub-wrapper", executor="single-bead-stub", or stub_reason.
EOF
}

write_phase6_prompt() {
  local id="$1" bd="$2" out="$3"
  mkdir -p "$(dirname "$out")"
  cat > "$out" <<EOF
Task tool prompt: test-depth-auditor

Subagent contract:
  /Users/josh/.claude/skills/beads-compliance-and-completion-verification/subagents/test-depth-auditor.md

Inputs:
  repo: $REPO
  bead_dir: $bd
  bead_id: $id
  show_json: $bd/show.json
  spec_json: $bd/spec.json
  evidence_json: $bd/evidence.json
  compliance_json: $bd/compliance.json
  theater_json: $bd/theater.json

Required output:
  Write $bd/test_depth.json with:
    - bead_id: "$id"
    - audited_at: current UTC timestamp
    - auditor: "subagents/test-depth-auditor.md"
    - checks: array of test-depth checks

Do not write auditor="stub-wrapper", auditor="single-bead-stub", or stub_reason.
EOF
}

is_non_stub_pack() {
  local file="$1" field="$2"
  [ -f "$file" ] || return 1
  jq -e --arg field "$field" '
    type == "object"
    and (.stub_reason? | not)
    and ((.[$field] // "") | tostring | length > 0)
    and ((.[$field] // "") | tostring | IN("stub-wrapper", "single-bead-stub") | not)
  ' "$file" >/dev/null 2>&1
}

wait_for_non_stub_pack() {
  local id="$1" file="$2" field="$3" phase="$4"
  local deadline now
  deadline=$(( $(date +%s) + WAIT_TIMEOUT_SECONDS ))
  while true; do
    if is_non_stub_pack "$file" "$field"; then
      return 0
    fi
    now="$(date +%s)"
    if [ "$now" -ge "$deadline" ]; then
      die "timed out waiting for non-stub $phase pack for $id at $file"
    fi
    sleep "$POLL_SECONDS"
  done
}

validate_target_pack() {
  local id="$1" bd
  bd="$(bead_dir_for "$id")"
  run_step python3 "$SCRIPTS_DIR/validate-evidence.py" "$bd" >/dev/null
}

target_json_array() {
  printf '%s\n' "${TARGET_BEADS[@]}" | jq -R . | jq -s .
}

path_json_array() {
  if [ "$#" -eq 0 ]; then
    jq -n '[]'
  else
    printf '%s\n' "$@" | jq -R . | jq -s .
  fi
}

emit_receipt() {
  local status="$1" validation_passed="$2" banner_present="$3" report_path="${4:-}"
  local target_json phase4_json phase6_json audit_json pass_json report_json
  target_json="$(target_json_array)"
  phase4_json="$(path_json_array "${PHASE4_PROMPTS[@]:-}")"
  phase6_json="$(path_json_array "${PHASE6_PROMPTS[@]:-}")"
  audit_json="null"
  pass_json="null"
  report_json="null"
  [ -n "${AUDIT_DIR:-}" ] && audit_json="$(json_escape "$AUDIT_DIR")"
  [ -n "${PASS_DIR:-}" ] && pass_json="$(json_escape "$PASS_DIR")"
  [ -n "$report_path" ] && report_json="$(json_escape "$report_path")"
  jq -n \
    --arg version "$VERSION" \
    --arg status "$status" \
    --arg repo "$REPO" \
    --argjson audit_dir "$audit_json" \
    --argjson pass_dir "$pass_json" \
    --argjson target_beads "$target_json" \
    --argjson phase4_prompts "$phase4_json" \
    --argjson phase6_prompts "$phase6_json" \
    --argjson non_stub_compliance_count "$NON_STUB_COMPLIANCE_COUNT" \
    --argjson non_stub_test_depth_count "$NON_STUB_TEST_DEPTH_COUNT" \
    --argjson validation_passed "$validation_passed" \
    --argjson deterministic_banner_present "$banner_present" \
    --argjson report_path "$report_json" \
    '{
      tool: "bcv-task-harness.sh",
      version: $version,
      status: $status,
      repo: $repo,
      audit_dir: $audit_dir,
      pass_dir: $pass_dir,
      target_beads: $target_beads,
      phase4_prompts: $phase4_prompts,
      phase6_prompts: $phase6_prompts,
      non_stub_compliance_count: $non_stub_compliance_count,
      non_stub_test_depth_count: $non_stub_test_depth_count,
      validation_passed: $validation_passed,
      deterministic_banner_present: $deterministic_banner_present,
      report_path: $report_path
    }'
}

REPO="$PWD"
AUDIT_DIR=""
BEADS_RAW=""
BEADS_FILE=""
THRESHOLD="700"
MODE="task-harness"
POLICY="completion-debt"
SKILL_DIR="$DEFAULT_SKILL_DIR"
WAIT_TIMEOUT_SECONDS="600"
POLL_SECONDS="2"
APPLY="0"
JSON_OUT="0"
INFO="0"
SCHEMA="0"
EXAMPLES="0"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo) REPO="${2:?--repo requires path}"; shift 2 ;;
    --audit-dir) AUDIT_DIR="${2:?--audit-dir requires path}"; shift 2 ;;
    --beads) BEADS_RAW="${2:?--beads requires ids}"; shift 2 ;;
    --beads-file) BEADS_FILE="${2:?--beads-file requires path}"; shift 2 ;;
    --threshold) THRESHOLD="${2:?--threshold requires value}"; shift 2 ;;
    --mode) MODE="${2:?--mode requires value}"; shift 2 ;;
    --policy) POLICY="${2:?--policy requires value}"; shift 2 ;;
    --skill-dir) SKILL_DIR="${2:?--skill-dir requires path}"; shift 2 ;;
    --wait-timeout-seconds) WAIT_TIMEOUT_SECONDS="${2:?--wait-timeout-seconds requires value}"; shift 2 ;;
    --poll-seconds) POLL_SECONDS="${2:?--poll-seconds requires value}"; shift 2 ;;
    --apply) APPLY="1"; shift ;;
    --dry-run) APPLY="0"; shift ;;
    --json) JSON_OUT="1"; shift ;;
    --info) INFO="1"; shift ;;
    --schema) SCHEMA="1"; shift ;;
    --examples) EXAMPLES="1"; shift ;;
    --help|-h) usage; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done

if [ "$INFO" = "1" ]; then emit_info; exit 0; fi
if [ "$SCHEMA" = "1" ]; then emit_schema; exit 0; fi
if [ "$EXAMPLES" = "1" ]; then emit_examples; exit 0; fi

require_cmd jq
require_cmd br
require_cmd python3
require_cmd git

REPO="$(abs_path "$REPO")"
[ -d "$REPO/.beads" ] || die "$REPO does not contain .beads/"
SKILL_DIR="$(abs_path "$SKILL_DIR")"
SCRIPTS_DIR="$SKILL_DIR/scripts"
[ -f "$SCRIPTS_DIR/bootstrap-audit.sh" ] || die "missing bootstrap-audit.sh under $SCRIPTS_DIR"
[ -f "$SCRIPTS_DIR/inventory-beads.sh" ] || die "missing inventory-beads.sh under $SCRIPTS_DIR"

if [ -n "$AUDIT_DIR" ]; then
  mkdir -p "$(dirname "$AUDIT_DIR")"
  AUDIT_DIR="$(abs_path "$AUDIT_DIR")"
fi

case "$WAIT_TIMEOUT_SECONDS" in ''|*[!0-9]*) die "--wait-timeout-seconds must be numeric" ;; esac
case "$POLL_SECONDS" in ''|*[!0-9]*) die "--poll-seconds must be numeric" ;; esac

load_targets
NON_STUB_COMPLIANCE_COUNT=0
NON_STUB_TEST_DEPTH_COUNT=0
PHASE4_PROMPTS=()
PHASE6_PROMPTS=()
PASS_DIR=""

if [ "$APPLY" != "1" ]; then
  emit_receipt "dry_run" "false" "false" ""
  exit 0
fi

if [ -n "$AUDIT_DIR" ]; then
  PASS_DIR="$(AUDIT_DIR_OVERRIDE="$AUDIT_DIR" run_step bash "$SCRIPTS_DIR/bootstrap-audit.sh" "$REPO" "$THRESHOLD" "$MODE" "$POLICY" | tail -1)"
else
  PASS_DIR="$(run_step bash "$SCRIPTS_DIR/bootstrap-audit.sh" "$REPO" "$THRESHOLD" "$MODE" "$POLICY" | tail -1)"
  AUDIT_DIR="$REPO/beads_compliance_audit"
fi
[ -d "$PASS_DIR" ] || die "bootstrap did not create pass dir: $PASS_DIR"

run_inventory

for id in "${TARGET_BEADS[@]}"; do
  ensure_bead_dir "$id"
  bd="$(bead_dir_for "$id")"
  run_step python3 "$SCRIPTS_DIR/extract-spec.py" "$bd/show.json" > "$bd/spec.json"
  run_step bash "$SCRIPTS_DIR/gather-evidence.sh" "$REPO" "$bd" >/dev/null
done

for id in "${TARGET_BEADS[@]}"; do
  bd="$(bead_dir_for "$id")"
  prompt="$PASS_DIR/task-prompts/phase4/$id.md"
  write_phase4_prompt "$id" "$bd" "$prompt"
  PHASE4_PROMPTS+=("$prompt")
done

for id in "${TARGET_BEADS[@]}"; do
  bd="$(bead_dir_for "$id")"
  wait_for_non_stub_pack "$id" "$bd/compliance.json" "executor" "Phase 4 compliance"
  NON_STUB_COMPLIANCE_COUNT=$((NON_STUB_COMPLIANCE_COUNT + 1))
done

for id in "${TARGET_BEADS[@]}"; do
  bd="$(bead_dir_for "$id")"
  run_step bash "$SCRIPTS_DIR/theater-scan.sh" "$REPO" "$bd" >/dev/null
  run_step bash "$SCRIPTS_DIR/anomaly-scan.sh" "$REPO" "$bd" >/dev/null
done

for id in "${TARGET_BEADS[@]}"; do
  bd="$(bead_dir_for "$id")"
  prompt="$PASS_DIR/task-prompts/phase6/$id.md"
  write_phase6_prompt "$id" "$bd" "$prompt"
  PHASE6_PROMPTS+=("$prompt")
done

for id in "${TARGET_BEADS[@]}"; do
  bd="$(bead_dir_for "$id")"
  wait_for_non_stub_pack "$id" "$bd/test_depth.json" "auditor" "Phase 6 test-depth"
  NON_STUB_TEST_DEPTH_COUNT=$((NON_STUB_TEST_DEPTH_COUNT + 1))
done

VALIDATION_PASSED=true
for id in "${TARGET_BEADS[@]}"; do
  validate_target_pack "$id" || VALIDATION_PASSED=false
done

run_step python3 "$SCRIPTS_DIR/synthesize.py" "$PASS_DIR" >/dev/null
for id in "${TARGET_BEADS[@]}"; do
  bd="$(bead_dir_for "$id")"
  run_step python3 "$SCRIPTS_DIR/score-bead.py" "$bd" \
    --rubric "$AUDIT_DIR/rubric.md" \
    --threshold "$THRESHOLD" \
    --synthesis "$PASS_DIR/synthesis.md" >/dev/null
done

REPORT_PATH="$PASS_DIR/REPORT.md"
run_step python3 "$SCRIPTS_DIR/master-report.py" "$PASS_DIR" > "$REPORT_PATH"
BANNER_PRESENT=false
if grep -Fq "DETERMINISTIC-ONLY PASS" "$REPORT_PATH"; then
  BANNER_PRESENT=true
fi

if [ "$VALIDATION_PASSED" != "true" ]; then
  emit_receipt "complete" "false" "$BANNER_PRESENT" "$REPORT_PATH"
  exit 1
fi
if [ "$BANNER_PRESENT" = "true" ]; then
  emit_receipt "complete" "true" "true" "$REPORT_PATH"
  exit 1
fi

emit_receipt "complete" "true" "false" "$REPORT_PATH"
