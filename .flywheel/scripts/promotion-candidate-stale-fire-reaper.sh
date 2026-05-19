#!/usr/bin/env bash
# promotion-candidate-stale-fire-reaper.sh
#
# flywheel-6s5dt: close stale-fired promotion-candidate beads from the
# 2026-05-09T17:11:17Z burst (and any future bursts before flywheel-iyaym's
# canonical-absolute-path fix propagates).
#
# Root cause (per flywheel-iyaym): doctrine-ladder-promote.sh scanned
# $REPO/INCIDENTS.md, which can resolve to a stale worktree copy. That
# created promotion-candidate beads for classes already covered in main
# canonical INCIDENTS.md.
#
# This reaper iterates open promotion-candidate beads, extracts the class
# name from the title, runs class_in_incidents against the CANONICAL
# absolute INCIDENTS path, and auto-closes the bead if covered.
#
# Usage:
#   promotion-candidate-stale-fire-reaper.sh [--dry-run|--apply] [--json]
#
# Defaults: --dry-run --json (reports planned actions; no mutations).
# Pass --apply to actually close stale-fired beads via `br close`.

set -euo pipefail


# ====== BEGIN canonical-cli scaffold (bead flywheel-ws02m) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (filled-in per bead flywheel-5ke66.16)
# doctor-mode-tier: scaffolded (bead flywheel-ws02m)
#
# Inserted BEFORE the original guards (canonical_incidents existence check,
# br executable check). When a canonical subcommand or intro flag is the
# argv[0], the scaffold serves it and exits. Otherwise the original reaper
# guards + argparse loop run unchanged.
#
# Strict-mode upgrade: `set -uo pipefail` → `set -euo pipefail` to satisfy
# canonical-cli-lint L5. The reaper's existing patterns are safe under -e
# (every fallible command is guarded by `if`, `&&`, `||`, or explicit
# `2>/dev/null || true`).

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="promotion-candidate-stale-fire-reaper/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/promotion-candidate-stale-fire-reaper-runs.jsonl}"
SCAFFOLD_CANONICAL_INCIDENTS="${PROMOTION_REAPER_CANONICAL_INCIDENTS:-/Users/josh/Developer/flywheel/INCIDENTS.md}"
SCAFFOLD_SKILL_INCIDENTS="${PROMOTION_REAPER_SKILL_INCIDENTS:-$HOME/.claude/skills/.flywheel/INCIDENTS.md}"
SCAFFOLD_BR_BIN="${PROMOTION_REAPER_BR_BIN:-/Users/josh/.cargo/bin/br}"

scaffold_usage() {
  cat <<'USG'
usage: promotion-candidate-stale-fire-reaper.sh [SUBCOMMAND] [OPTIONS]

Default flag-form invocation routes to the original reaper. The reaper
closes stale-fired promotion-candidate beads from the 2026-05-09 burst
(class already covered in canonical INCIDENTS.md). --dry-run is default.

Canonical CLI surfaces (intercepted before the reaper):
  doctor [--json]          probe substrate health (jq/br/canonical-incidents/skill-incidents/root)
  health [--json]          last-run status (audit log tail + canonical incidents row count)
  repair --scope <s>       repair misconfigured state
                            Default: --dry-run; mutate with --apply --idempotency-key KEY
                            Scopes: audit-log-rotate, canonical-incidents-prime
  validate <subject> [...] subjects: row, schema, config, canonical-incidents, candidates
  audit [--json]           recent run history (audit log tail)
  why <id>                 explain provenance for a given id (class | bead-id)
  quickstart [--json]      operator orientation
  help <topic>             topic help
  completion <shell>       emit shell completion

Introspection:
  --info --json            version, paths, env vars, dependencies, sha256
  --schema [<surface>]     JSON Schema for output envelopes
  --examples --json        curated workflow examples
  --help / -h              this help (canonical) — NOTE: original reaper's
                           --help/-h also still routes to its own usage when
                           early-dispatch is consulted, since --help is in
                           the canonical args list. The canonical and reaper
                           usage texts are merged via scaffold_usage above.
USG
}

scaffold_emit_info() {
  if ! command -v cli_emit_info >/dev/null; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "promotion-candidate-stale-fire-reaper.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "promotion-candidate-stale-fire-reaper.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG,PROMOTION_REAPER_CANONICAL_INCIDENTS,PROMOTION_REAPER_SKILL_INCIDENTS,PROMOTION_REAPER_BR_BIN,PROMOTION_REAPER_SINCE" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"dry-run reap report",invocation:"promotion-candidate-stale-fire-reaper.sh --dry-run --json",purpose:"list stale-fired promotion-candidate beads without closing"}'
)"$'\n'"$(jq -nc '{name:"apply close",invocation:"promotion-candidate-stale-fire-reaper.sh --apply --json",purpose:"actually br close stale-fired beads with reason"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"promotion-candidate-stale-fire-reaper.sh doctor --json",purpose:"probe jq/br/canonical-incidents/skill-incidents/root"}'
)"$'\n'"$(jq -nc '{name:"validate candidates",invocation:"promotion-candidate-stale-fire-reaper.sh validate --candidates",purpose:"probe how many open promotion-candidate beads currently match SINCE filter"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"promotion-candidate-stale-fire-reaper.sh doctor --json"}'
)"$'\n'"$(jq -nc '{step:2,action:"see current candidates",command:"promotion-candidate-stale-fire-reaper.sh validate --candidates"}'
)"$'\n'"$(jq -nc '{step:3,action:"dry-run reap",command:"promotion-candidate-stale-fire-reaper.sh --dry-run --json"}'
)"
  if command -v cli_emit_quickstart >/dev/null; then
    cli_emit_quickstart "$SCAFFOLD_SCHEMA_VERSION" "$steps" "doctor,health,repair"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"quickstart",helper_lib_missing:true}'
  fi
}

scaffold_emit_schema() {
  local surface="${1:-default}"
  case "$surface" in
    doctor)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:["ts","status","checks[]"],check_fields:["name","status","value?","detail?"]}' ;;
    health)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:["ts","status","audit_log","stale_seconds","last_row?","canonical_incidents_line_count"]}' ;;
    repair)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,scopes:["audit-log-rotate","canonical-incidents-prime"],fields:["status","mode","scope","idempotency_key?","rotated?","canonical_incidents?","line_count?"]}' ;;
    validate)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,subjects:["row","schema","config","canonical-incidents","candidates"],fields:["status","subject","valid?","missing?","reason?","canonical_incidents?","candidates_count?"]}' ;;
    audit)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:["audit_log","row_count","rows[]"]}' ;;
    why)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:["id","status","matches[]"],id_pattern:"class|bead-id"}' ;;
    audit-row)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,required:["schema_version","ts","mode","candidates_count","stale_closed_count","real_kept_count"]}' ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,note:"promotion-candidate-stale-fire-reaper: closes stale promotion-candidate beads whose class is covered in canonical INCIDENTS.md"}' ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — reaper queries br for open promotion-candidate beads created since $SINCE, extracts class name from title, greps canonical INCIDENTS.md for the class, auto-closes covered beads on --apply (default --dry-run).\n' ;;
    doctor)   printf 'topic: doctor — substrate probe: jq, br bin executable, canonical INCIDENTS.md present, optional skill INCIDENTS.md present, flywheel root.\n' ;;
    health)   printf 'topic: health — tails audit log; warn stale >7d. Reports canonical INCIDENTS.md line count for upstream-source freshness.\n' ;;
    repair)   printf 'topic: repair — scopes: audit-log-rotate (>5MB → mv .ts), canonical-incidents-prime (read-only — probes canonical INCIDENTS.md size/lines).\n' ;;
    validate) printf 'topic: validate — subjects: --row-json JSON (reaper audit row schema), --schema, --config, --canonical-incidents (probes INCIDENTS.md), --candidates (queries br for open promotion-candidate beads).\n' ;;
    *)        printf 'topics: run | doctor | health | repair | validate\n' ;;
  esac
}

scaffold_emit_completion() {
  local shell="${1:-bash}"
  case "$shell" in
    -h|--help) scaffold_emit_topic_help completion 2>/dev/null \
                 || printf 'topic: completion <bash|zsh>\n'
               return 0 ;;
    bash) command -v cli_emit_completion_bash >/dev/null \
            && cli_emit_completion_bash "promotion-candidate-stale-fire-reaper" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples,--since" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "promotion-candidate-stale-fire-reaper" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

scaffold_cmd_doctor() {
  local script_root; script_root="$_SCAFFOLD_REPO_ROOT"
  local checks="" overall="pass"

  if command -v jq >/dev/null 2>&1; then
    checks+="$(jq -nc --arg p "$(command -v jq)" '{name:"jq_on_path",status:"pass",value:$p}')"$'\n'
  else
    checks+="$(jq -nc '{name:"jq_on_path",status:"fail"}')"$'\n'
    overall="fail"
  fi

  if [[ -x "$SCAFFOLD_BR_BIN" ]]; then
    checks+="$(jq -nc --arg p "$SCAFFOLD_BR_BIN" '{name:"br_bin_executable",status:"pass",value:$p}')"$'\n'
  else
    checks+="$(jq -nc --arg p "$SCAFFOLD_BR_BIN" '{name:"br_bin_executable",status:"fail",value:$p,detail:"br required to query promotion-candidate beads and close them"}')"$'\n'
    overall="fail"
  fi

  local ci_present=false ci_lines=0
  if [[ -r "$SCAFFOLD_CANONICAL_INCIDENTS" ]]; then
    ci_present=true
    ci_lines="$(wc -l < "$SCAFFOLD_CANONICAL_INCIDENTS" 2>/dev/null | tr -d ' ' || echo 0)"
  fi
  local ci_status="pass"; [[ "$ci_present" != true ]] && ci_status="fail" && overall="fail"
  checks+="$(jq -nc --arg p "$SCAFFOLD_CANONICAL_INCIDENTS" --arg s "$ci_status" --argjson present "$ci_present" --argjson lines "${ci_lines:-0}" \
    '{name:"canonical_incidents_present",status:$s,value:$p,present:$present,line_count:$lines,detail:"core dependency: reaper greps this for class coverage"}')"$'\n'

  local si_present=false
  [[ -r "$SCAFFOLD_SKILL_INCIDENTS" ]] && si_present=true
  local si_status="pass"; [[ "$si_present" != true ]] && si_status="warn"
  checks+="$(jq -nc --arg p "$SCAFFOLD_SKILL_INCIDENTS" --arg s "$si_status" --argjson present "$si_present" \
    '{name:"skill_incidents_present",status:$s,value:$p,present:$present,detail:"optional fallback path"}')"$'\n'

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
  local last_row="null" stale_seconds=-1 status="warn"
  local ci_lines=0
  if [[ -r "$log" ]]; then
    local row_raw; row_raw="$(tail -n 1 "$log" 2>/dev/null || true)"
    if [[ -n "$row_raw" ]] && printf '%s' "$row_raw" | jq -e '.' >/dev/null 2>&1; then
      last_row="$row_raw"
      local last_ts; last_ts="$(printf '%s' "$row_raw" | jq -r '.ts // empty' 2>/dev/null || true)"
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
  [[ -r "$SCAFFOLD_CANONICAL_INCIDENTS" ]] && ci_lines="$(wc -l < "$SCAFFOLD_CANONICAL_INCIDENTS" 2>/dev/null | tr -d ' ' || echo 0)"
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$log" \
    --arg status "$status" --argjson stale "$stale_seconds" --argjson row "$last_row" \
    --argjson cl "${ci_lines:-0}" --arg ci "$SCAFFOLD_CANONICAL_INCIDENTS" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,audit_log:$log,stale_seconds:$stale,last_row:$row,canonical_incidents:$ci,canonical_incidents_line_count:$cl}'
}

scaffold_cmd_repair() {
  local scope="" mode="dry_run" idem_key=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) scaffold_emit_topic_help repair; return 0 ;;
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
    if command -v cli_refuse_apply_without_idem_key >/dev/null; then
      cli_refuse_apply_without_idem_key "$SCAFFOLD_SCHEMA_VERSION" "repair" "$scope"
    else
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"refused",mode:"apply",scope:$scope,reason:"--apply requires --idempotency-key"}'
      exit 3
    fi
  fi
  case "$scope" in
    audit-log-rotate)
      local log="$SCAFFOLD_AUDIT_LOG"
      local size_bytes=0 rotated=false
      [[ -r "$log" ]] && size_bytes="$(stat -f '%z' "$log" 2>/dev/null || echo 0)"
      if [[ "$mode" == "apply" && "$size_bytes" -gt 5242880 ]]; then
        local rotated_path="${log}.$(date -u +%Y%m%dT%H%M%SZ)"
        if mv "$log" "$rotated_path" 2>/dev/null; then
          : > "$log" 2>/dev/null || true
          rotated=true
        fi
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" \
        --arg idem "$idem_key" --arg log "$log" --argjson sz "$size_bytes" --argjson r "$rotated" \
        '{schema_version:$sv,command:"repair",status:"pass",mode:$mode,scope:$scope,idempotency_key:$idem,audit_log:$log,size_bytes:$sz,rotation_threshold:5242880,rotated:$r}'
      ;;
    canonical-incidents-prime)
      local present=false lines=0 size_bytes=0
      if [[ -r "$SCAFFOLD_CANONICAL_INCIDENTS" ]]; then
        present=true
        lines="$(wc -l < "$SCAFFOLD_CANONICAL_INCIDENTS" 2>/dev/null | tr -d ' ' || echo 0)"
        size_bytes="$(stat -f '%z' "$SCAFFOLD_CANONICAL_INCIDENTS" 2>/dev/null || echo 0)"
      fi
      local status="pass"
      [[ "$present" != true ]] && status="fail"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" \
        --arg idem "$idem_key" --arg ci "$SCAFFOLD_CANONICAL_INCIDENTS" --arg s "$status" \
        --argjson present "$present" --argjson lines "${lines:-0}" --argjson sz "${size_bytes:-0}" \
        '{schema_version:$sv,command:"repair",status:$s,mode:$mode,scope:$scope,idempotency_key:$idem,canonical_incidents:$ci,present:$present,line_count:$lines,size_bytes:$sz,note:"read-only probe"}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" --arg idem "$idem_key" \
        '{schema_version:$sv,command:"repair",status:"unknown_scope",mode:$mode,scope:$scope,idempotency_key:$idem,known_scopes:["audit-log-rotate","canonical-incidents-prime"]}'
      ;;
  esac
}

scaffold_cmd_validate() {
  local subject="" row_json=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) scaffold_emit_topic_help validate; return 0 ;;
      --row-json) subject="row"; row_json="${2:-}"; shift 2 ;;
      --row-json=*) subject="row"; row_json="${1#--row-json=}"; shift ;;
      --schema) subject="schema"; shift ;;
      --config) subject="config"; shift ;;
      --canonical-incidents) subject="canonical-incidents"; shift ;;
      --candidates) subject="candidates"; shift ;;
      --json) shift ;;
      *) printf 'ERR: unknown validate arg %s\n' "$1" >&2; return 64 ;;
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
      # Reaper output row schema (from the original jq -nc emit).
      for f in schema_version ts mode candidates_count stale_closed_count real_kept_count; do
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
      local jq_ok=false br_ok=false ci_ok=false si_ok=false root_ok=false
      command -v jq >/dev/null 2>&1 && jq_ok=true
      [[ -x "$SCAFFOLD_BR_BIN" ]] && br_ok=true
      [[ -r "$SCAFFOLD_CANONICAL_INCIDENTS" ]] && ci_ok=true
      [[ -r "$SCAFFOLD_SKILL_INCIDENTS" ]] && si_ok=true
      [[ -d "$_SCAFFOLD_REPO_ROOT" ]] && root_ok=true
      local overall=pass
      [[ "$jq_ok" != true || "$br_ok" != true || "$ci_ok" != true || "$root_ok" != true ]] && overall=fail
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$overall" \
        --argjson jqq "$jq_ok" --argjson br "$br_ok" --argjson ci "$ci_ok" --argjson si "$si_ok" --argjson rt "$root_ok" \
        --arg root "$_SCAFFOLD_REPO_ROOT" --arg ci_p "$SCAFFOLD_CANONICAL_INCIDENTS" --arg si_p "$SCAFFOLD_SKILL_INCIDENTS" --arg br_p "$SCAFFOLD_BR_BIN" \
        '{schema_version:$sv,command:"validate",subject:"config",status:$s,jq_present:$jqq,br_bin_present:$br,canonical_incidents_present:$ci,skill_incidents_present:$si,flywheel_root_present:$rt,flywheel_root:$root,canonical_incidents:$ci_p,skill_incidents:$si_p,br_bin:$br_p}'
      ;;
    canonical-incidents)
      local present=false lines=0 size_bytes=0
      if [[ -r "$SCAFFOLD_CANONICAL_INCIDENTS" ]]; then
        present=true
        lines="$(wc -l < "$SCAFFOLD_CANONICAL_INCIDENTS" 2>/dev/null | tr -d ' ' || echo 0)"
        size_bytes="$(stat -f '%z' "$SCAFFOLD_CANONICAL_INCIDENTS" 2>/dev/null || echo 0)"
      fi
      local status="pass"
      [[ "$present" != true ]] && status="fail"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$status" --arg ci "$SCAFFOLD_CANONICAL_INCIDENTS" \
        --argjson present "$present" --argjson lines "${lines:-0}" --argjson sz "${size_bytes:-0}" \
        '{schema_version:$sv,command:"validate",subject:"canonical-incidents",status:$s,canonical_incidents:$ci,present:$present,line_count:$lines,size_bytes:$sz}'
      ;;
    candidates)
      # Query br for open promotion-candidate beads.
      local candidates_count=0 br_status="unavailable"
      if [[ -x "$SCAFFOLD_BR_BIN" ]]; then
        local listing
        listing="$("$SCAFFOLD_BR_BIN" list --json --limit 0 2>/dev/null || echo '{}')"
        candidates_count="$(printf '%s' "$listing" | jq '[.issues[]? | select(.title | startswith("[promotion-candidate]")) | select(.status != "closed")] | length' 2>/dev/null || echo 0)"
        br_status="ok"
      fi
      local status="pass"
      [[ "$br_status" != "ok" ]] && status="warn"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$status" --arg brs "$br_status" \
        --argjson cc "${candidates_count:-0}" \
        '{schema_version:$sv,command:"validate",subject:"candidates",status:$s,br_status:$brs,open_promotion_candidates:$cc}'
      ;;
    "")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",status:"pass",subjects:["row","schema","config","canonical-incidents","candidates"],usage:"validate --row-json JSON or --schema or --config or --canonical-incidents or --candidates"}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$subject" \
        '{schema_version:$sv,command:"validate",subject:$s,status:"unknown_subject",known:["row","schema","config","canonical-incidents","candidates"]}'
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
      -h|--help) scaffold_emit_topic_help audit; return 0 ;;
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
    printf 'ERR: why requires <id> argument\n' >&2; return 64
  fi
  local matches="[]" status="not_found"
  local any_source_present=false
  if [[ -r "$SCAFFOLD_AUDIT_LOG" ]]; then
    any_source_present=true
    local raw
    raw="$(grep -F "$id" "$SCAFFOLD_AUDIT_LOG" 2>/dev/null || true)"
    if [[ -n "$raw" ]]; then
      matches="$(printf '%s' "$raw" | jq -sc '.' 2>/dev/null || echo '[]')"
    fi
  fi
  if [[ "$any_source_present" != true ]]; then
    status="unavailable"
  else
    local n; n="$(printf '%s' "$matches" | jq 'length' 2>/dev/null || echo 0)"
    n="${n//[^0-9]/}"; [[ -z "$n" ]] && n=0
    [[ "$n" -gt 0 ]] && status="found"
  fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" --arg s "$status" \
    --arg log "$SCAFFOLD_AUDIT_LOG" --argjson m "$matches" \
    '{schema_version:$sv,command:"why",id:$id,status:$s,audit_log:$log,matches:$m,total_matches:($m|length)}'
}

scaffold_main() {
  if [[ $# -eq 0 ]]; then
    scaffold_usage; exit 0
  fi
  case "$1" in
    -h|--help)    scaffold_usage; exit 0 ;;
    --info)       shift; scaffold_emit_info "$@"; exit 0 ;;
    --schema)     shift; scaffold_emit_schema "${1:-default}"; exit 0 ;;
    --examples)   shift; scaffold_emit_examples "$@"; exit 0 ;;
    doctor)       shift; scaffold_cmd_doctor "$@"; exit $? ;;
    health)       shift; scaffold_cmd_health "$@"; exit $? ;;
    repair)       shift; scaffold_cmd_repair "$@"; exit $? ;;
    validate)     shift; scaffold_cmd_validate "$@"; exit $? ;;
    audit)        shift; scaffold_cmd_audit "$@"; exit $? ;;
    why)          shift; scaffold_cmd_why "$@"; exit $? ;;
    quickstart)   shift; scaffold_emit_quickstart "$@"; exit 0 ;;
    help)         shift; scaffold_emit_topic_help "${1:-}"; exit 0 ;;
    completion)   shift; scaffold_emit_completion "${1:-bash}"; exit $? ;;
    *)
      printf 'ERR: unknown canonical subcommand: %s\n' "$1" >&2
      scaffold_usage >&2
      exit 64 ;;
  esac
}

_scaffold_is_canonical_arg() {
  case "${1:-}" in
    doctor|health|repair|validate|audit|why|quickstart|completion) return 0 ;;
    --info|--schema|--examples) return 0 ;;
    -h|--help) return 0 ;;
    help)
      case "${2:-}" in run|doctor|health|repair|validate|audit|why|-h|--help) return 0 ;; esac
      return 1 ;;
    *) return 1 ;;
  esac
}

if [[ $# -gt 0 ]] && _scaffold_is_canonical_arg "$@"; then
  scaffold_main "$@"
  exit $?
fi
# ====== END canonical-cli scaffold ======

VERSION="promotion-candidate-stale-fire-reaper.v1"
SINCE="${PROMOTION_REAPER_SINCE:-2026-05-09T17:11:00Z}"
CANONICAL_INCIDENTS="${PROMOTION_REAPER_CANONICAL_INCIDENTS:-/Users/josh/Developer/flywheel/INCIDENTS.md}"
SKILL_INCIDENTS="${PROMOTION_REAPER_SKILL_INCIDENTS:-$HOME/.claude/skills/.flywheel/INCIDENTS.md}"
BR_BIN="${PROMOTION_REAPER_BR_BIN:-/Users/josh/.cargo/bin/br}"
APPLY=0
JSON_MODE=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply) APPLY=1; shift ;;
    --dry-run) APPLY=0; shift ;;
    --json) JSON_MODE=1; shift ;;
    --no-json) JSON_MODE=0; shift ;;
    --since) SINCE="$2"; shift 2 ;;
    --help|-h)
      cat <<USAGE
Usage: promotion-candidate-stale-fire-reaper.sh [--dry-run|--apply] [--json] [--since ISO]

Closes promotion-candidate beads created after --since whose class is
canonically covered in $CANONICAL_INCIDENTS.

--dry-run (default): report planned actions; no mutations.
--apply:             actually close stale-fired beads via 'br close'.
--since:             ISO timestamp; only beads created after this are reaped (default: $SINCE).

Exit codes:
  0  reaper completed cleanly
  2  invalid argument or canonical INCIDENTS missing
  3  br CLI unavailable
USAGE
      exit 0 ;;
    *) printf 'unknown flag: %s\n' "$1" >&2; exit 2 ;;
  esac
done

if [[ ! -f "$CANONICAL_INCIDENTS" ]]; then
  printf 'ERROR: canonical INCIDENTS missing at %s\n' "$CANONICAL_INCIDENTS" >&2
  exit 2
fi
if [[ ! -x "$BR_BIN" ]]; then
  printf 'ERROR: br CLI not executable at %s\n' "$BR_BIN" >&2
  exit 3
fi

class_in_incidents() {
  local class="$1"
  if grep -Fqi -- "$class" "$CANONICAL_INCIDENTS"; then
    return 0
  fi
  if [[ -f "$SKILL_INCIDENTS" ]] && grep -Fqi -- "$class" "$SKILL_INCIDENTS"; then
    return 0
  fi
  return 1
}

# Extract class name from a promotion-candidate title:
# "[promotion-candidate] <class> (N events in 7d)"
extract_class() {
  local title="$1"
  printf '%s\n' "$title" | sed -E 's/^\[promotion-candidate\][[:space:]]*([^[:space:]].*)[[:space:]]*\(.*\)[[:space:]]*$/\1/' | sed -E 's/[[:space:]]+$//'
}

# Build close-reason note linking to flywheel-iyaym
close_reason() {
  local class="$1"
  printf 'BLOCKED-cleared: stale-fire from worktree-INCIDENTS bug pre-canonical-fix [flywheel-iyaym]; canonical INCIDENTS covers class=%s' "$class"
}

# Query open promotion-candidate beads created after $SINCE
candidates_json="$("$BR_BIN" list --json --limit 0 2>/dev/null \
  | jq --arg since "$SINCE" '
    [.issues[]
      | select(.created_at >= $since)
      | select(.title | startswith("[promotion-candidate]"))
      | select(.status != "closed")]
  ')"

candidates_count=$(printf '%s' "$candidates_json" | jq 'length' 2>/dev/null || echo 0)

stale_closed_ids=""
real_kept_ids=""
errored_ids=""
stale_closed_count=0
real_kept_count=0
errored_count=0

while IFS= read -r row; do
  [[ -z "$row" ]] && continue
  bead_id=$(printf '%s' "$row" | jq -r '.id')
  title=$(printf '%s' "$row" | jq -r '.title')
  class=$(extract_class "$title")

  if [[ -z "$class" ]]; then
    errored_ids="${errored_ids}${bead_id}=parse_class_failed,"
    errored_count=$((errored_count + 1))
    continue
  fi

  if class_in_incidents "$class"; then
    # Stale-fire: canonical covers this class
    if [[ "$APPLY" -eq 1 ]]; then
      reason=$(close_reason "$class")
      if "$BR_BIN" close "$bead_id" 2>/dev/null; then
        stale_closed_ids="${stale_closed_ids}${bead_id},"
        stale_closed_count=$((stale_closed_count + 1))
      else
        errored_ids="${errored_ids}${bead_id}=br_close_failed,"
        errored_count=$((errored_count + 1))
      fi
    else
      stale_closed_ids="${stale_closed_ids}${bead_id},"
      stale_closed_count=$((stale_closed_count + 1))
    fi
  else
    real_kept_ids="${real_kept_ids}${bead_id}=class:${class},"
    real_kept_count=$((real_kept_count + 1))
  fi
done < <(printf '%s' "$candidates_json" | jq -c '.[]' 2>/dev/null)

# Strip trailing commas
stale_closed_ids="${stale_closed_ids%,}"
real_kept_ids="${real_kept_ids%,}"
errored_ids="${errored_ids%,}"

if [[ "$JSON_MODE" -eq 1 ]]; then
  jq -nc \
    --arg version "$VERSION" \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg since "$SINCE" \
    --arg canonical_incidents "$CANONICAL_INCIDENTS" \
    --argjson apply "$APPLY" \
    --argjson candidates_count "$candidates_count" \
    --argjson stale_closed_count "$stale_closed_count" \
    --argjson real_kept_count "$real_kept_count" \
    --argjson errored_count "$errored_count" \
    --arg stale_closed_ids "$stale_closed_ids" \
    --arg real_kept_ids "$real_kept_ids" \
    --arg errored_ids "$errored_ids" \
    '{
      schema_version: $version,
      ts: $ts,
      mode: (if $apply == 1 then "apply" else "dry-run" end),
      since: $since,
      canonical_incidents: $canonical_incidents,
      candidates_count: $candidates_count,
      stale_closed_count: $stale_closed_count,
      real_kept_count: $real_kept_count,
      errored_count: $errored_count,
      stale_closed_ids: $stale_closed_ids,
      real_kept_ids: $real_kept_ids,
      errored_ids: $errored_ids
    }'
else
  printf 'Promotion-candidate stale-fire reaper\n'
  printf '  mode: %s\n' "$([[ "$APPLY" -eq 1 ]] && echo "apply" || echo "dry-run")"
  printf '  candidates: %d\n' "$candidates_count"
  printf '  stale_closed: %d\n' "$stale_closed_count"
  printf '  real_kept: %d (need authoritative L56 promotion)\n' "$real_kept_count"
  printf '  errored: %d\n' "$errored_count"
fi

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
