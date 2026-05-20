#!/usr/bin/env bash
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (partial → passing per bead flywheel-1hshd.6)
# bcv-task-harness.sh — orchestrate real Phase 4/6 BCV task packs.
set -euo pipefail


# ====== BEGIN canonical-cli scaffold (bead flywheel-ws02m) ======
# Wave-4 partial→passing additive coexistence. Existing script already has:
#   --info / --schema / --examples / --apply / --idempotency-key (rc=3 gate) /
#   --dry-run / --json + ~20 operational flags
# Gap closed: NEW no-dash subcommand family (doctor / health / repair /
# validate / audit / why / quickstart / help / completion) for AG3 parity
# with sister wave-4 scaffolds. Operational flags + existing dash-flag
# introspection unchanged.

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="bcv-task-harness/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/bcv-task-harness-runs.jsonl}"

scaffold_cmd_doctor() {
  local script_root; script_root="$_SCAFFOLD_REPO_ROOT"
  local checks="" overall="pass"

  if command -v jq >/dev/null 2>&1; then
    checks+="$(jq -nc --arg p "$(command -v jq)" '{name:"jq_on_path",status:"pass",value:$p}')"$'\n'
  else
    checks+="$(jq -nc '{name:"jq_on_path",status:"fail"}')"$'\n'
    overall="fail"
  fi

  if command -v shasum >/dev/null 2>&1; then
    checks+="$(jq -nc --arg p "$(command -v shasum)" '{name:"shasum_on_path",status:"pass",value:$p}')"$'\n'
  else
    checks+="$(jq -nc '{name:"shasum_on_path",status:"fail",detail:"used for target_beads_sha"}')"$'\n'
    overall="fail"
  fi

  local skill_dir="${BCV_SKILL_DIR:-/Users/josh/.claude/skills/beads-compliance-and-completion-verification}"
  if [[ -d "$skill_dir" ]]; then
    checks+="$(jq -nc --arg p "$skill_dir" '{name:"bcv_skill_dir_present",status:"pass",value:$p}')"$'\n'
  else
    checks+="$(jq -nc --arg p "$skill_dir" '{name:"bcv_skill_dir_present",status:"warn",value:$p,detail:"override via --skill-dir"}')"$'\n'
  fi

  local ledger_dir; ledger_dir="$(dirname "$SCAFFOLD_AUDIT_LOG")"
  if [[ -d "$ledger_dir" && -w "$ledger_dir" ]] || mkdir -p "$ledger_dir" 2>/dev/null; then
    local row_count=0
    [[ -r "$SCAFFOLD_AUDIT_LOG" ]] && row_count="$(wc -l < "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | tr -d ' ' || echo 0)"
    checks+="$(jq -nc --arg p "$SCAFFOLD_AUDIT_LOG" --argjson rc "${row_count:-0}" '{name:"audit_log_writable",status:"pass",value:$p,row_count:$rc}')"$'\n'
  else
    checks+="$(jq -nc --arg p "$SCAFFOLD_AUDIT_LOG" '{name:"audit_log_writable",status:"fail",value:$p}')"$'\n'
    overall="fail"
  fi

  local subagent_phase4="$skill_dir/subagents/compliance-verifier.md"
  if [[ -r "$subagent_phase4" ]]; then
    checks+="$(jq -nc --arg p "$subagent_phase4" '{name:"phase4_subagent_present",status:"pass",value:$p}')"$'\n'
  else
    checks+="$(jq -nc --arg p "$subagent_phase4" '{name:"phase4_subagent_present",status:"warn",value:$p,detail:"required for Phase 4 packs"}')"$'\n'
  fi

  if [[ -d "$script_root" ]]; then
    checks+="$(jq -nc --arg p "$script_root" '{name:"flywheel_root_resolvable",status:"pass",value:$p}')"$'\n'
  else
    checks+="$(jq -nc --arg p "$script_root" '{name:"flywheel_root_resolvable",status:"fail",value:$p}')"$'\n'
    overall="fail"
  fi

  local ts; ts="$(cli_iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf '%s' "$checks" | jq -sc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg status "$overall" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$status,checks:.}'
}

scaffold_cmd_health() {
  local ts; ts="$(cli_iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  local log="$SCAFFOLD_AUDIT_LOG"
  local last_row="null" stale_seconds=-1 status="warn" row_count=0
  if [[ -r "$log" ]]; then
    row_count="$(wc -l < "$log" 2>/dev/null | tr -d ' ' || echo 0)"
    local row_raw; row_raw="$(tail -n 1 "$log" 2>/dev/null || true)"
    if [[ -n "$row_raw" ]] && printf '%s' "$row_raw" | jq -e '.' >/dev/null 2>&1; then
      last_row="$row_raw"
      local last_ts; last_ts="$(printf '%s' "$row_raw" | jq -r '.ts // .timestamp // empty' 2>/dev/null || true)"
      if [[ -n "$last_ts" ]]; then
        local last_epoch now_epoch
        last_epoch="$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$last_ts" +%s 2>/dev/null || echo 0)"
        now_epoch="$(date -u +%s)"
        if [[ "$last_epoch" -gt 0 ]]; then
          stale_seconds=$((now_epoch - last_epoch))
          if [[ "$stale_seconds" -le 604800 ]]; then status="pass"; fi
        fi
      fi
    fi
  fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$log" \
    --arg status "$status" --argjson stale "$stale_seconds" --argjson row "$last_row" --argjson rc "${row_count:-0}" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,audit_log:$log,stale_seconds:$stale,last_row:$row,row_count:$rc}'
}

scaffold_cmd_repair() {
  local scope="" mode="dry_run" idem_key=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) printf 'topic: repair — scopes: audit-log-rotate, skill-dir-prime\n'; return 0 ;;
      --scope) scope="${2:-}"; shift 2 ;;
      --dry-run) mode="dry_run"; shift ;;
      --apply) mode="apply"; shift ;;
      --idempotency-key) idem_key="${2:-}"; shift 2 ;;
      --idempotency-key=*) idem_key="${1#--idempotency-key=}"; shift ;;
      --json) shift ;;
      *) printf 'ERR: unknown repair arg %s\n' "$1" >&2; return 64 ;;
    esac
  done
  if [[ "$mode" == "apply" && -z "$idem_key" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" \
      '{schema_version:$sv,command:"repair",status:"refused",mode:"apply",scope:$scope,reason:"--apply requires --idempotency-key"}'
    exit 3
  fi
  case "$scope" in
    audit-log-rotate)
      local log="$SCAFFOLD_AUDIT_LOG" size_bytes=0 rotated=false
      [[ -r "$log" ]] && size_bytes="$(stat -f '%z' "$log" 2>/dev/null || echo 0)"
      if [[ "$mode" == "apply" && "$size_bytes" -gt 5242880 ]]; then
        local rotated_path="${log}.$(date -u +%Y%m%dT%H%M%SZ)"
        if mv "$log" "$rotated_path" 2>/dev/null; then : > "$log" 2>/dev/null || true; rotated=true; fi
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" \
        --arg log "$log" --argjson sz "$size_bytes" --argjson r "$rotated" \
        '{schema_version:$sv,command:"repair",status:"pass",mode:$mode,scope:$scope,audit_log:$log,size_bytes:$sz,rotation_threshold:5242880,rotated:$r}'
      ;;
    skill-dir-prime)
      local skill_dir="${BCV_SKILL_DIR:-/Users/josh/.claude/skills/beads-compliance-and-completion-verification}"
      local present=false subagent4=false subagent6=false
      if [[ -d "$skill_dir" ]]; then
        present=true
        [[ -r "$skill_dir/subagents/compliance-verifier.md" ]] && subagent4=true
        [[ -r "$skill_dir/subagents/test-depth-auditor.md" ]] && subagent6=true
      fi
      local status="pass"
      [[ "$present" != true ]] && status="warn"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" \
        --arg sd "$skill_dir" --arg s "$status" \
        --argjson present "$present" --argjson p4 "$subagent4" --argjson p6 "$subagent6" \
        '{schema_version:$sv,command:"repair",status:$s,mode:$mode,scope:$scope,skill_dir:$sd,present:$present,phase4_subagent_present:$p4,phase6_subagent_present:$p6,note:"read-only probe"}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" \
        '{schema_version:$sv,command:"repair",status:"unknown_scope",mode:$mode,scope:$scope,known_scopes:["audit-log-rotate","skill-dir-prime"]}'
      ;;
  esac
}

scaffold_cmd_validate() {
  local subject="" row_json=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --row-json) subject="row"; row_json="${2:-}"; shift 2 ;;
      --row-json=*) subject="row"; row_json="${1#--row-json=}"; shift ;;
      --schema) subject="schema"; shift ;;
      --config) subject="config"; shift ;;
      --audit-log) subject="audit-log"; shift ;;
      --json) shift ;;
      *) shift ;;
    esac
  done
  case "$subject" in
    row)
      local valid=true missing=""
      if [[ -z "$row_json" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"validate",subject:"row",status:"fail",valid:false,reason:"--row-json required"}'
        return 0
      fi
      if ! printf '%s' "$row_json" | jq -e '.' >/dev/null 2>&1; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"validate",subject:"row",status:"fail",valid:false,reason:"invalid_json"}'
        return 0
      fi
      for f in tool version status; do
        if ! printf '%s' "$row_json" | jq -e --arg k "$f" 'has($k)' >/dev/null 2>&1; then
          valid=false; missing="${missing}${f},"
        fi
      done
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --argjson v "$valid" --arg m "${missing%,}" \
        '{schema_version:$sv,command:"validate",subject:"row",status:(if $v then "pass" else "fail" end),valid:$v,missing:$m}'
      ;;
    schema)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",subject:"schema",status:"pass",surfaces:["doctor","health","repair","validate","audit","why","audit-row"]}'
      ;;
    config)
      local jq_ok=false shasum_ok=false root_ok=false
      command -v jq >/dev/null 2>&1 && jq_ok=true
      command -v shasum >/dev/null 2>&1 && shasum_ok=true
      [[ -d "$_SCAFFOLD_REPO_ROOT" ]] && root_ok=true
      local overall=pass
      [[ "$jq_ok" != true || "$shasum_ok" != true || "$root_ok" != true ]] && overall=fail
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$overall" \
        --argjson jqq "$jq_ok" --argjson sha "$shasum_ok" --argjson rt "$root_ok" \
        --arg root "$_SCAFFOLD_REPO_ROOT" \
        '{schema_version:$sv,command:"validate",subject:"config",status:$s,jq_present:$jqq,shasum_present:$sha,flywheel_root_present:$rt,flywheel_root:$root}'
      ;;
    audit-log)
      local present=false rows=0
      if [[ -r "$SCAFFOLD_AUDIT_LOG" ]]; then
        present=true
        rows="$(wc -l < "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | tr -d ' ' || echo 0)"
      fi
      local status="pass"; [[ "$present" != true ]] && status="warn"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$status" --arg log "$SCAFFOLD_AUDIT_LOG" \
        --argjson present "$present" --argjson rows "${rows:-0}" \
        '{schema_version:$sv,command:"validate",subject:"audit-log",status:$s,audit_log:$log,present:$present,row_count:$rows}'
      ;;
    "")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",status:"pass",subjects:["row","schema","config","audit-log"]}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$subject" \
        '{schema_version:$sv,command:"validate",subject:$s,status:"unknown_subject",known:["row","schema","config","audit-log"]}'
      ;;
  esac
}

scaffold_cmd_audit() {
  local limit=50
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --limit) limit="${2:-50}"; shift 2 ;;
      --limit=*) limit="${1#--limit=}"; shift ;;
      --json) shift ;;
      *) shift ;;
    esac
  done
  if command -v cli_emit_audit_tail >/dev/null 2>&1; then
    cli_emit_audit_tail "$SCAFFOLD_AUDIT_LOG" "$SCAFFOLD_SCHEMA_VERSION" "$limit"
  else
    local rows="[]" count=0
    if [[ -r "$SCAFFOLD_AUDIT_LOG" ]]; then
      rows="$(tail -n "$limit" "$SCAFFOLD_AUDIT_LOG" | jq -sc '. // []' 2>/dev/null || echo '[]')"
      count="$(printf '%s' "$rows" | jq 'length' 2>/dev/null || echo 0)"
    fi
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg log "$SCAFFOLD_AUDIT_LOG" --argjson rows "$rows" --argjson count "$count" \
      '{schema_version:$sv,command:"audit",audit_log:$log,row_count:$count,rows:$rows}'
  fi
}

scaffold_cmd_why() {
  local id="${1:-}"
  if [[ -z "$id" ]]; then
    printf 'ERR: why requires <id>\n' >&2; return 64
  fi
  local matches="[]" status="not_found" any_source_present=false
  if [[ -r "$SCAFFOLD_AUDIT_LOG" ]]; then
    any_source_present=true
    local raw; raw="$(grep -F "$id" "$SCAFFOLD_AUDIT_LOG" 2>/dev/null || true)"
    if [[ -n "$raw" ]]; then
      matches="$(printf '%s' "$raw" | jq -sc '.' 2>/dev/null || echo '[]')"
    fi
  fi
  if [[ "$any_source_present" != true ]]; then status="unavailable"
  else
    local n; n="$(printf '%s' "$matches" | jq 'length' 2>/dev/null || echo 0)"
    n="${n//[^0-9]/}"; [[ -z "$n" ]] && n=0
    [[ "$n" -gt 0 ]] && status="found"
  fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" --arg s "$status" \
    --arg log "$SCAFFOLD_AUDIT_LOG" --argjson m "$matches" \
    '{schema_version:$sv,command:"why",id:$id,status:$s,audit_log:$log,matches:$m,total_matches:($m|length)}'
}

scaffold_emit_topic_help() {
  case "${1:-}" in
    run)      printf 'topic: run — orchestrate Phase 4/6 BCV task packs. Default --dry-run; --apply requires --idempotency-key (rc=3 refusal).\n' ;;
    doctor)   printf 'topic: doctor — substrate probe: jq + shasum + bcv-skill-dir + audit-log + phase4 subagent + flywheel root.\n' ;;
    health)   printf 'topic: health — tails audit log; warn stale >7d.\n' ;;
    repair)   printf 'topic: repair — scopes: audit-log-rotate, skill-dir-prime (read-only).\n' ;;
    validate) printf 'topic: validate — subjects: row, schema, config, audit-log.\n' ;;
    *)        printf 'topics: run | doctor | health | repair | validate\n' ;;
  esac
}

_scaffold_is_canonical_arg() {
  case "${1:-}" in
    doctor|health|repair|validate|audit|why) return 0 ;;
    help)
      case "${2:-}" in run|doctor|health|repair|validate|audit|why|-h|--help) return 0 ;; esac
      return 1 ;;
    *) return 1 ;;
  esac
}

if [[ $# -gt 0 ]] && _scaffold_is_canonical_arg "$@"; then
  case "$1" in
    doctor)       shift; scaffold_cmd_doctor "$@"; exit $? ;;
    health)       shift; scaffold_cmd_health "$@"; exit $? ;;
    repair)       shift; scaffold_cmd_repair "$@"; exit $? ;;
    validate)     shift; scaffold_cmd_validate "$@"; exit $? ;;
    audit)        shift; scaffold_cmd_audit "$@"; exit $? ;;
    why)          shift; scaffold_cmd_why "$@"; exit $? ;;
    help)         shift; scaffold_emit_topic_help "${1:-}"; exit 0 ;;
  esac
fi
# ====== END canonical-cli scaffold ======


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
  --apply                     Create pass and wait for real packs (requires --idempotency-key)
  --idempotency-key KEY       Required under --apply. Per-(key, target_beads_sha) replay no-ops.
  --dry-run                   Print plan only (default)
  --json                      Emit JSON receipt
  --help                      Show this help

This harness stops the deterministic BCV flow after Phase 3, emits Task-tool
prompt files for Phase 4 and Phase 6, waits for non-stub packs, then runs
Phase 5, validation, scoring, and master-report generation.

Exit codes:
  0  dry-run succeeded, complete with banner, complete with validation, or replay-no-op
  1  validation failed or banner unexpectedly present
  2  usage or substrate error
  3  --apply without --idempotency-key (canonical refusal contract)
USAGE
}

json_escape() {
  jq -Rn --arg v "$1" '$v'
}

emit_info() {
  if [ "$JSON_OUT" = "1" ]; then
    jq -n --arg version "$VERSION" --arg skill_dir "$SKILL_DIR" --arg audit_log "$AUDIT_LOG" '{
      tool: "bcv-task-harness.sh",
      version: $version,
      purpose: "Run BCV Phase 0.5-3 deterministically, delegate Phase 4/6 to Task-tool subagents, then validate/score/report non-stub packs.",
      skill_dir: $skill_dir,
      apply_requires: "--idempotency-key",
      audit_log: $audit_log,
      required_phase4_executor: "subagents/compliance-verifier.md",
      required_phase6_auditor: "subagents/test-depth-auditor.md",
      exit_codes: {"0":"success or replay-no-op","1":"validation failed","2":"usage error","3":"--apply without --idempotency-key"}
    }'
  else
    printf '%s\n' "$VERSION"
    printf 'skill_dir=%s\n' "$SKILL_DIR"
    printf 'audit_log=%s\n' "$AUDIT_LOG"
    printf 'apply_requires=--idempotency-key\n'
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

# Real run with idempotency key (requires --idempotency-key; per-(key, target_beads_sha) replay):
.flywheel/scripts/bcv-task-harness.sh --repo "$PWD" --beads bd-123,bd-456 --apply --idempotency-key="bcv-$(date -u +%Y%m%d)" --wait-timeout-seconds 900 --json

# Same key + same target beads → replay-no-op. Different beads → fresh run.
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
IDEMPOTENCY_KEY=""
AUDIT_LOG="${BCV_TASK_HARNESS_AUDIT_LOG:-$HOME/.local/state/flywheel/bcv-task-harness-runs.jsonl}"

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
    --idempotency-key) [ -n "${2:-}" ] || die "--idempotency-key requires VALUE"; IDEMPOTENCY_KEY="$2"; shift 2 ;;
    --idempotency-key=*) IDEMPOTENCY_KEY="${1#--idempotency-key=}"; [ -n "$IDEMPOTENCY_KEY" ] || die "--idempotency-key requires VALUE"; shift ;;
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

# Mutation gate (7axmt P2 fix, sister j0xpa whole-run-scoped-per-target-set variant).
# Scope identifier: sha256 of sorted TARGET_BEADS — same set of beads + same key → replay.
# Fires AFTER load_targets so we know which beads we'd process; BEFORE bootstrap-audit
# creates the pass dir (hoqq8 invariant — gate before side-effect).
if [ -z "$IDEMPOTENCY_KEY" ]; then
  jq -nc \
    --arg version "$VERSION" \
    --arg repo "$REPO" \
    '{tool:"bcv-task-harness.sh",version:$version,status:"refused",mode:"apply",repo:$repo,reason:"--apply requires --idempotency-key"}' >&2
  exit 3
fi

# Compute target_beads_sha (sorted set hash) for per-target-set replay scope.
TARGET_BEADS_SHA="$(printf '%s\n' "${TARGET_BEADS[@]}" | sort | shasum -a 256 | awk '{print $1}')"

# Replay-check (tolerant-parse per sister 8sx9w skill discovery). Match on
# (idempotency_key, target_beads_sha) tuple — same key + same target set → no-op.
replay_prior_bcv_run() {
  if [ -z "$IDEMPOTENCY_KEY" ] || [ ! -r "$AUDIT_LOG" ]; then
    printf ''
    return 0
  fi
  jq -Rc --arg k "$IDEMPOTENCY_KEY" --arg sha "$TARGET_BEADS_SHA" \
    'fromjson? | select((.idempotency_key // "") == $k and (.target_beads_sha // "") == $sha and ((.status // "") | IN("complete","replay")))' \
    "$AUDIT_LOG" 2>/dev/null | tail -n 1 || true
}

audit_append_bcv() {
  local row="$1"
  mkdir -p "$(dirname "$AUDIT_LOG")" 2>/dev/null || true
  printf '%s\n' "$row" >>"$AUDIT_LOG"
}

REPLAY_ROW="$(replay_prior_bcv_run)"
if [ -n "$REPLAY_ROW" ]; then
  if [ "$JSON_OUT" = "1" ]; then
    jq -c --arg k "$IDEMPOTENCY_KEY" '. + {replay:true,replay_for_idempotency_key:$k,status:"replay"}' <<<"$REPLAY_ROW"
  else
    printf 'bcv-task-harness: replay idempotency_key=%s target_beads_sha=%s — prior row found, no-op\n' "$IDEMPOTENCY_KEY" "$TARGET_BEADS_SHA"
  fi
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

# Audit-append at terminal: row carries idempotency_key + target_beads_sha + outcome.
# Sister 8sx9w + j0xpa pattern: row format includes the original report_path so a
# replay no-op can emit the prior receipt with the same content.
audit_terminal_row() {
  local status="$1" validation="$2" banner="$3" report_path="$4"
  audit_append_bcv "$(jq -nc \
    --arg version "$VERSION" \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg status "$status" \
    --arg repo "$REPO" \
    --arg idempotency_key "$IDEMPOTENCY_KEY" \
    --arg target_beads_sha "$TARGET_BEADS_SHA" \
    --arg report_path "$report_path" \
    --argjson validation_passed "$validation" \
    --argjson deterministic_banner_present "$banner" \
    --argjson target_beads "$(target_json_array)" \
    '{tool:"bcv-task-harness.sh",version:$version,ts:$ts,status:$status,repo:$repo,idempotency_key:$idempotency_key,target_beads_sha:$target_beads_sha,target_beads:$target_beads,validation_passed:$validation_passed,deterministic_banner_present:$deterministic_banner_present,report_path:$report_path}')"
}

if [ "$VALIDATION_PASSED" != "true" ]; then
  audit_terminal_row "complete" "false" "$BANNER_PRESENT" "$REPORT_PATH"
  emit_receipt "complete" "false" "$BANNER_PRESENT" "$REPORT_PATH"
  exit 1
fi
if [ "$BANNER_PRESENT" = "true" ]; then
  audit_terminal_row "complete" "true" "true" "$REPORT_PATH"
  emit_receipt "complete" "true" "true" "$REPORT_PATH"
  exit 1
fi

audit_terminal_row "complete" "true" "false" "$REPORT_PATH"
emit_receipt "complete" "true" "false" "$REPORT_PATH"

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
