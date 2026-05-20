#!/usr/bin/env bash
set -u -o pipefail

VERSION="memory-rule-gate-parity-detector.v1.0.0"
SCHEMA_VERSION="memory-rule-gate-parity/v1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_DEFAULT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
REPO="${MEMORY_RULE_GATE_PARITY_REPO:-$REPO_DEFAULT}"
MEMORY_DIR="${MEMORY_RULE_GATE_PARITY_MEMORY_DIR:-$HOME/.claude/projects/-Users-josh-Developer-flywheel/memory}"
HOOKS_DIR="${MEMORY_RULE_GATE_PARITY_HOOKS_DIR:-$HOME/.claude/hooks}"
SETTINGS_JSON="${MEMORY_RULE_GATE_PARITY_SETTINGS_JSON:-$HOME/.claude/settings.json}"
INCIDENTS_PATH="${MEMORY_RULE_GATE_PARITY_INCIDENTS:-$REPO/INCIDENTS.md}"
LEDGER="${MEMORY_RULE_GATE_PARITY_LEDGER:-$HOME/.local/state/flywheel/memory-rule-gate-parity-ledger.jsonl}"
ISSUES_JSONL="${MEMORY_RULE_GATE_PARITY_ISSUES_JSONL:-$REPO/.beads/issues.jsonl}"
COMMAND="check"
AUTO_BEAD=0
JSON_OUT=0
REPO_SCOPE_CORRECTED_FROM=""
REPO_SCOPE_WARNING=""

usage() {
  cat <<'EOF'
usage:
  memory-rule-gate-parity-detector.sh check [--memory-dir PATH] [--auto-bead] [--json]
  memory-rule-gate-parity-detector.sh --info|--help|--examples

Audits feedback_*.md memory files for META-RULE markers and checks whether each
has structural gate evidence: script, hook/settings, test, and INCIDENTS entry.
EOF
}

examples() {
  cat <<'EOF'
examples:
  .flywheel/scripts/memory-rule-gate-parity-detector.sh check --json
  .flywheel/scripts/memory-rule-gate-parity-detector.sh check --memory-dir /tmp/memory --json
  MEMORY_RULE_GATE_PARITY_LEDGER=/tmp/parity.jsonl .flywheel/scripts/memory-rule-gate-parity-detector.sh check --auto-bead --json
EOF
}

now_iso() { date -u +%Y-%m-%dT%H:%M:%SZ; }

canonical_dir() {
  local path="$1"
  if [[ -d "$path" ]]; then
    (cd "$path" 2>/dev/null && pwd -P) || printf '%s\n' "$path"
  else
    printf '%s\n' "$path"
  fi
}

sql_escape() {
  printf '%s' "$1" | sed "s/'/''/g"
}

flywheel_memory_dir() {
  canonical_dir "$HOME/.claude/projects/-Users-josh-Developer-flywheel/memory"
}

normalize_created_bead_source_repo() {
  local bead_id="$1" db="$REPO/.beads/beads.db" repo_sql id_sql
  [[ -n "$bead_id" && -f "$db" ]] || return 0
  command -v sqlite3 >/dev/null 2>&1 || return 0
  repo_sql="$(sql_escape "$REPO")"
  id_sql="$(sql_escape "$bead_id")"
  sqlite3 "$db" "UPDATE issues SET source_repo = '$repo_sql' WHERE id = '$id_sql' AND (source_repo IS NULL OR source_repo != '$repo_sql');" >/dev/null 2>&1 || true
}

flywheel_repo_dir() {
  canonical_dir "$HOME/Developer/flywheel"
}

expected_repo_for_memory_dir() {
  local memory_abs="$1" flywheel_memory flywheel_repo
  flywheel_memory="$(flywheel_memory_dir)"
  flywheel_repo="$(flywheel_repo_dir)"
  if [[ "$memory_abs" == "$flywheel_memory" && -d "$flywheel_repo" ]]; then
    printf '%s\n' "$flywheel_repo"
    return 0
  fi
  return 1
}

apply_repo_scope_guard() {
  local memory_abs expected
  REPO="$(canonical_dir "$REPO")"
  memory_abs="$(canonical_dir "$MEMORY_DIR")"
  expected="$(expected_repo_for_memory_dir "$memory_abs" || true)"
  if [[ -n "$expected" && "$REPO" != "$expected" && "${MEMORY_RULE_GATE_PARITY_ALLOW_CROSS_REPO:-0}" != "1" ]]; then
    REPO_SCOPE_CORRECTED_FROM="$REPO"
    REPO_SCOPE_WARNING="repo_memory_scope_mismatch_corrected"
    REPO="$expected"
  fi
  INCIDENTS_PATH="$REPO/INCIDENTS.md"
  ISSUES_JSONL="$REPO/.beads/issues.jsonl"
}

info_json() {
  jq -nc \
    --arg version "$VERSION" \
    --arg schema "$SCHEMA_VERSION" \
    --arg repo "$REPO" \
    --arg memory_dir "$MEMORY_DIR" \
    --arg ledger "$LEDGER" \
    '{name:"memory-rule-gate-parity-detector.sh",version:$version,schema_version:$schema,
      repo:$repo,memory_dir:$memory_dir,ledger_path:$ledger,
      commands:["check","--memory-dir","--auto-bead","--json","--info","--examples","--help"],
      exits:{"0":"audit completed","2":"usage or missing memory dir"}}'
}

text_has() {
  local file="$1" needle="$2"
  [[ -f "$file" && -n "$needle" ]] || return 1
  if command -v rg >/dev/null 2>&1; then
    rg -q --fixed-strings -- "$needle" "$file"
  else
    grep -Fq -- "$needle" "$file"
  fi
}

safe_slug() {
  printf '%s' "$1" | tr '[:upper:]_' '[:lower:]-' | tr -c 'a-z0-9-' '-' | sed 's/--*/-/g; s/^-//; s/-$//'
}

rule_from_path() {
  local base stem
  base="$(basename "$1")"
  stem="${base#feedback_}"
  stem="${stem%.md}"
  safe_slug "$stem"
}

aliases_for_rule() {
  local stem="$1" under="$2" IFS="-" parts=() first2="" first3=""
  read -r -a parts <<<"$stem"
  [[ "${#parts[@]}" -ge 2 ]] && first2="${parts[0]}-${parts[1]}"
  [[ "${#parts[@]}" -ge 3 ]] && first3="${parts[0]}-${parts[1]}-${parts[2]}"
  printf '%s\n%s\n' "$stem" "$under"
  [[ -n "$first2" ]] && printf '%s\n' "$first2"
  [[ -n "$first3" ]] && printf '%s\n' "$first3"
  case "$stem" in
    data-decides-not-human-meatpuppet|orch-punt-is-l70-failure-dispatch-dont-ask|orch-paralysis-when-data-specifies-action|audit-findings-are-data-decided-not-joshua-gated)
      printf '%s\n' orch-no-punt-output orch-no-punt data-decides meatpuppet ;;
    donella-first-no-stop-to-ask)
      printf '%s\n' orch-donella-trace donella-trace donella-first ;;
    two-truth-sources-before-decide)
      printf '%s\n' two-truth-sources two-truth-sources-validator ;;
    dispatch-delivery-validation-required|worker-verify-callback-delivered)
      printf '%s\n' dispatch-delivery dispatch-delivery-verify verify-callback-delivery ;;
    orchestrator-validates-callbacks|orchestrator-rubber-stamp-drift)
      printf '%s\n' orchestrator-callback-artifact callback-receipt validate-callback ;;
  esac
}

append_ledger() {
  local row="$1"
  mkdir -p "$(dirname "$LEDGER")" 2>/dev/null || return 1
  jq -c . <<<"$row" >>"$LEDGER" 2>/dev/null
}

emit() {
  local payload="$1" text="$2" rc="${3:-0}"
  append_ledger "$payload" || payload="$(jq -c '. + {ledger_append_error:true}' <<<"$payload")"
  if [[ "$JSON_OUT" -eq 1 ]]; then
    printf '%s\n' "$payload"
  else
    printf '%s\n' "$text"
  fi
  return "$rc"
}

first_matching_name() {
  local dir="$1" pattern="$2"
  [[ -d "$dir" ]] || return 1
  find "$dir" -maxdepth 1 -type f -name "$pattern" -print -quit 2>/dev/null
}

first_gate_mention() {
  local dir="$1" aliases="$2" file alias
  [[ -d "$dir" ]] || return 1
  while IFS= read -r file; do
    while IFS= read -r alias; do
      [[ -n "$alias" ]] || continue
      if text_has "$file" "$alias"; then
        printf '%s\n' "$file"
        return 0
      fi
    done <<EOF
$aliases
EOF
  done <<EOF
$(find "$dir" -maxdepth 1 -type f -name '*-gate.sh' -print 2>/dev/null | sort)
EOF
  return 1
}

script_evidence() {
  local stem="$1" under="$2" scripts="$REPO/.flywheel/scripts" hit aliases alias
  aliases="$(aliases_for_rule "$stem" "$under")"
  while IFS= read -r alias; do
    [[ -n "$alias" ]] || continue
    hit="$(first_matching_name "$scripts" "*$alias*" || true)"
    [[ -n "$hit" ]] && break
  done <<EOF
$aliases
EOF
  [[ -n "$hit" ]] || hit="$(first_gate_mention "$scripts" "$aliases" || true)"
  printf '%s\n' "$hit"
}

hook_evidence() {
  local stem="$1" under="$2" script_path="$3" hit script_base="" aliases alias
  aliases="$(aliases_for_rule "$stem" "$under")"
  while IFS= read -r alias; do
    [[ -n "$alias" ]] || continue
    hit="$(first_matching_name "$HOOKS_DIR" "flywheel-*$alias*" || true)"
    [[ -n "$hit" ]] && break
  done <<EOF
$aliases
EOF
  if [[ -z "$hit" && -n "$script_path" ]]; then
    script_base="$(basename "$script_path")"
    if text_has "$SETTINGS_JSON" "$script_base"; then hit="$SETTINGS_JSON"; fi
  fi
  if [[ -z "$hit" ]]; then
    while IFS= read -r alias; do
      [[ -n "$alias" ]] || continue
      if text_has "$SETTINGS_JSON" "$alias"; then hit="$SETTINGS_JSON"; break; fi
    done <<EOF
$aliases
EOF
  fi
  printf '%s\n' "$hit"
}

test_evidence() {
  local stem="$1" under="$2" tests="$REPO/.flywheel/tests" hit aliases alias
  aliases="$(aliases_for_rule "$stem" "$under")"
  while IFS= read -r alias; do
    [[ -n "$alias" ]] || continue
    hit="$(first_matching_name "$tests" "test-*$alias*" || true)"
    [[ -n "$hit" ]] && break
  done <<EOF
$aliases
EOF
  printf '%s\n' "$hit"
}

incidents_evidence() {
  local stem="$1" under="$2" aliases alias
  aliases="$(aliases_for_rule "$stem" "$under")"
  while IFS= read -r alias; do
    [[ -n "$alias" ]] || continue
    if text_has "$INCIDENTS_PATH" "$alias"; then printf '%s\n' "$INCIDENTS_PATH"; return 0; fi
  done <<EOF
$aliases
EOF
}

bead_id_for_rule() {
  local stem="$1" hash prefix
  hash="$(printf '%s' "$stem" | shasum -a 256 | awk '{print substr($1,1,8)}')"
  prefix="$(safe_slug "$stem" | cut -c1-34 | sed 's/-$//')"
  printf 'flywheel-wire-%s-%s\n' "$prefix" "$hash"
}

existing_bead_for_title() {
  local title="$1"
  [[ -f "$ISSUES_JSONL" ]] || return 1
  jq -r --arg title "$title" 'select((.title // "") == $title) | .id // empty' "$ISSUES_JSONL" 2>/dev/null | tail -1
}

bead_action_for_rule() {
  local stem="$1" memory_path="$2" title id existing now desc created rc br_output br_id
  title="wire-${stem}-as-structural-gate"
  id="$(bead_id_for_rule "$stem")"
  existing="$(existing_bead_for_title "$title" || true)"
  if [[ -n "$existing" ]]; then
    jq -nc --arg rule "$stem" --arg title "$title" --arg id "$existing" '{rule_id:$rule,title:$title,bead_id:$id,action:"reused"}'
    return 0
  fi
  if [[ "$AUTO_BEAD" -eq 0 ]]; then
    jq -nc --arg rule "$stem" --arg title "$title" --arg id "$id" '{rule_id:$rule,title:$title,bead_id:$id,action:"would_file"}'
    return 0
  fi
  now="$(now_iso)"
  desc="Auto-filed by memory-rule-gate-parity-detector. META-RULE memory file has zero structural gate evidence. Wire script + hook/settings + test + INCIDENTS entry, then rerun detector. memory_path=$memory_path"
  if [[ ! -d "$REPO/.beads" ]]; then
    jq -nc --arg rule "$stem" --arg title "$title" --arg id "$id" --arg repo "$REPO" \
      '{rule_id:$rule,title:$title,bead_id:$id,action:"create_failed",reason:"repo_beads_missing",repo:$repo}'
    return 0
  fi
  set +e
  br_output="$(cd "$REPO" && br create "$title" --type bug --priority P0 --description "$desc" --labels "memory-rule-gate-parity,auto-repair,advisory-to-structural" --actor "memory-rule-gate-parity-detector" --json 2>&1)"
  rc=$?
  if [[ "$rc" -eq 0 ]]; then
    br_id="$(jq -r '.id // .issue.id // empty' <<<"$br_output" 2>/dev/null | head -1)"
    [[ -n "$br_id" ]] || br_id="$id"
    normalize_created_bead_source_repo "$br_id"
    jq -nc --arg rule "$stem" --arg title "$title" --arg id "$br_id" --arg repo "$REPO" \
      '{rule_id:$rule,title:$title,bead_id:$id,action:"br_created",repo:$repo}'
  else
    jq -nc --arg rule "$stem" --arg title "$title" --arg id "$id" --arg repo "$REPO" --arg rc "$rc" \
      '{rule_id:$rule,title:$title,bead_id:$id,action:"create_failed",repo:$repo,exit_code:($rc|tonumber)}'
  fi
}

audit_file_json() {
  local file="$1" stem under script hook test incident evidence_count classification
  stem="$(rule_from_path "$file")"
  under="$(basename "$file" .md)"
  under="${under#feedback_}"
  if ! text_has "$file" "META-RULE"; then
    jq -nc --arg rule "$stem" --arg path "$file" '{rule_id:$rule,memory_path:$path,classification:"NOT_META_RULE",evidence:{},missing_evidence:[]}'
    return 0
  fi
  script="$(script_evidence "$stem" "$under")"
  hook="$(hook_evidence "$stem" "$under" "$script")"
  test="$(test_evidence "$stem" "$under")"
  incident="$(incidents_evidence "$stem" "$under")"
  evidence_count=0
  [[ -n "$script" ]] && evidence_count=$((evidence_count + 1))
  [[ -n "$hook" ]] && evidence_count=$((evidence_count + 1))
  [[ -n "$test" ]] && evidence_count=$((evidence_count + 1))
  [[ -n "$incident" ]] && evidence_count=$((evidence_count + 1))
  if [[ "$evidence_count" -ge 3 ]]; then classification="WIRED"; elif [[ "$evidence_count" -gt 0 ]]; then classification="PARTIAL"; else classification="UNWIRED"; fi
  jq -nc \
    --arg rule "$stem" --arg path "$file" --arg class "$classification" \
    --arg script "$script" --arg hook "$hook" --arg test "$test" --arg incident "$incident" \
    --argjson count "$evidence_count" \
    '{rule_id:$rule,memory_path:$path,classification:$class,evidence_count:$count,
      evidence:{script:(if $script == "" then null else $script end),hook:(if $hook == "" then null else $hook end),test:(if $test == "" then null else $test end),incidents:(if $incident == "" then null else $incident end)},
      missing_evidence:([
        (if $script == "" then "script" else empty end),
        (if $hook == "" then "hook" else empty end),
        (if $test == "" then "test" else empty end),
        (if $incident == "" then "incidents" else empty end)
      ])}'
}

run_check() {
  local audit_ts tmp rows_file beads_file files_file rows_json beads_json payload rc=0
  audit_ts="$(now_iso)"
  if [[ ! -d "$MEMORY_DIR" ]]; then
    payload="$(jq -nc --arg schema "$SCHEMA_VERSION" --arg ts "$audit_ts" --arg repo "$REPO" --arg memory_dir "$MEMORY_DIR" --arg ledger "$LEDGER" \
      '{schema_version:$schema,audit_ts:$ts,repo:$repo,memory_dir:$memory_dir,status:"gray",signal:"GRAY",total_files:0,total_meta_rules:0,wired:0,partial:0,unwired:0,not_meta_rule:0,unwired_rules:[],partial_rules:[],beads_filed:[],beads_would_file:[],ledger_appended:$ledger,warnings:["memory_dir_missing"],exit_code:2}')"
    emit "$payload" "GRAY memory_dir_missing=$MEMORY_DIR" 2
    return $?
  fi
  tmp="$(mktemp -d -t memory-rule-gate-parity.XXXXXX)"
  rows_file="$tmp/rows.jsonl"; beads_file="$tmp/beads.jsonl"; files_file="$tmp/files.txt"
  find "$MEMORY_DIR" -maxdepth 1 -type f -name 'feedback_*.md' -print 2>/dev/null | sort >"$files_file"
  while IFS= read -r file; do
    [[ -n "$file" ]] || continue
    audit_file_json "$file" >>"$rows_file"
  done <"$files_file"
  [[ -s "$rows_file" ]] || : >"$rows_file"
  rows_json="$(jq -s -c '.' "$rows_file")"
  jq -c '.[] | select(.classification == "UNWIRED")' <<<"$rows_json" | while IFS= read -r row; do
    bead_action_for_rule "$(jq -r '.rule_id' <<<"$row")" "$(jq -r '.memory_path' <<<"$row")" >>"$beads_file"
  done
  [[ -s "$beads_file" ]] || : >"$beads_file"
  beads_json="$(jq -s -c '.' "$beads_file")"
  payload="$(jq -nc \
    --arg schema "$SCHEMA_VERSION" --arg ts "$audit_ts" --arg repo "$REPO" --arg memory_dir "$MEMORY_DIR" --arg ledger "$LEDGER" \
    --arg scope_warning "$REPO_SCOPE_WARNING" --arg scope_from "$REPO_SCOPE_CORRECTED_FROM" \
    --argjson rows "$rows_json" --argjson beads "$beads_json" \
    '($rows | map(select(.classification != "NOT_META_RULE"))) as $meta
     | ($rows | map(select(.classification == "WIRED"))) as $wired
     | ($rows | map(select(.classification == "PARTIAL"))) as $partial
     | ($rows | map(select(.classification == "UNWIRED"))) as $unwired
     | ($unwired | length) as $unwired_count
     | {
        schema_version:$schema,audit_ts:$ts,repo:$repo,memory_dir:$memory_dir,
        status:(if $unwired_count > 2 then "fail" elif $unwired_count > 0 then "warn" else "pass" end),
        signal:(if $unwired_count > 2 then "RED" elif $unwired_count > 0 then "YELLOW" else "GREEN" end),
        total_files:($rows | length),total_meta_rules:($meta | length),
        wired:($wired | length),partial:($partial | length),unwired:$unwired_count,not_meta_rule:($rows | map(select(.classification == "NOT_META_RULE")) | length),
        unwired_rules:($unwired | map({rule_id,memory_path,missing_evidence})),
        partial_rules:($partial | map({rule_id,memory_path,missing_evidence,evidence_count})),
        rules:$rows,
        beads_filed:($beads | map(select(.action == "br_created" or .action == "reused" or .action == "create_failed"))),
        beads_would_file:($beads | map(select(.action == "would_file"))),
        repo_scope:{corrected:($scope_from != ""),corrected_from:(if $scope_from == "" then null else $scope_from end),active_repo:$repo},
        ledger_appended:$ledger,
        errors:[],warnings:([if $scope_warning == "" then empty else $scope_warning end]),
        exit_code:0
      }')"
  rm -rf "$tmp"
  emit "$payload" "$(jq -r '"signal=\(.signal) meta=\(.total_meta_rules) wired=\(.wired) partial=\(.partial) unwired=\(.unwired)"' <<<"$payload")" "$rc"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    check) COMMAND="check"; shift ;;
    --memory-dir) MEMORY_DIR="${2:-}"; shift 2 ;;
    --memory-dir=*) MEMORY_DIR="${1#*=}"; shift ;;
    --repo) REPO="${2:-}"; INCIDENTS_PATH="$REPO/INCIDENTS.md"; ISSUES_JSONL="$REPO/.beads/issues.jsonl"; shift 2 ;;
    --repo=*) REPO="${1#*=}"; INCIDENTS_PATH="$REPO/INCIDENTS.md"; ISSUES_JSONL="$REPO/.beads/issues.jsonl"; shift ;;
    --auto-bead) AUTO_BEAD=1; shift ;;
    --json) JSON_OUT=1; shift ;;
    --info) info_json; exit 0 ;;
    --examples) examples; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'ERR unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

apply_repo_scope_guard

case "$COMMAND" in
  check) run_check ;;
  *) printf 'ERR unknown command: %s\n' "$COMMAND" >&2; exit 2 ;;
esac

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
