#!/usr/bin/env bash
set -euo pipefail


# ====== BEGIN canonical-cli scaffold (bead flywheel-ws02m) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing
# doctor-mode-tier: filled (bead flywheel-gl7om)
#
# This block is APPENDED by scaffold-canonical-cli.sh. The original
# top-level dispatch is preserved at the bottom of the file (default
# invocation runs the original mission-lock validation). Canonical CLI
# subcommands intercept ahead of the original parser via
# _scaffold_is_canonical_arg. Surface-specific logic was filled in by
# flywheel-gl7om — doctor probes the substrate this validator depends
# on, health/audit/why read the run-history audit log, and validate
# carries audit-row + mission-lock-scaffold subjects.

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="mission-lock-scaffold-validator/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/mission-lock-scaffold-validator-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: mission-lock-scaffold-validator.sh [SUBCOMMAND] [OPTIONS]

Backward-compatible run mode: default invocation routes to the original
top-level logic (now exposed as `cmd_run`).

Canonical CLI surfaces:
  doctor [--json]          probe substrate health
  health [--json]          last-run status
  repair --scope <s>       repair misconfigured state
                            Default: --dry-run; mutate with --apply --idempotency-key KEY
  validate <subject> [...] validate per-subject contract (TODO: define subjects)
  audit [--json]           recent run history
  why <id>                 explain provenance for a given id (TODO: id semantics)
  quickstart [--json]      operator orientation
  help <topic>             topic help (run | doctor | health | repair | validate)
  completion <shell>       emit bash or zsh completion

Introspection:
  --info --json            version, paths, env vars, dependencies, sha256
  --schema [<surface>]     JSON Schema for output envelopes
  --examples --json        curated workflow examples
  --help / -h              this help
USG
}

scaffold_emit_info() {
  if ! command -v cli_emit_info >/dev/null; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "mission-lock-scaffold-validator.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "mission-lock-scaffold-validator.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"mission-lock-scaffold-validator.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"mission-lock-scaffold-validator.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"mission-lock-scaffold-validator.sh doctor --json"}'
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
    audit-row|default)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg log "$SCAFFOLD_AUDIT_LOG" \
        '{schema_version:$sv,command:"schema",surface:"audit-row",
          format:"jsonl",path:$log,
          required_fields:["ts","action","status","sha256"],
          optional_extra_fields:["mission_md_path","verdict","blocker_count","lock_hash_observed"],
          status_enum:["ready","incomplete","blocked"],
          appended_by:"cmd_run via cli_audit_append"}'
      ;;
    mission-lock-scaffold)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"mission-lock-scaffold",
          required_sections:["Mission Source","North-Star Outcome","Primary Beneficiary","Explicit Non-Goals","Safety And Privacy Boundaries","Evidence That Would Change The Mission","Owner-Review Cadence","Lock Receipt","Negative invariants (security)"],
          verdict_enum:["ready","incomplete","blocked"],
          section_hash_algorithm:"sha256 of normalized section body (strip section_hash comments, trim blank edges, LF-join, append LF)",
          section_hash_comment_form:"<!-- section_hash: <section title> sha256:<64 hex> -->",
          substrate_inventory_section:"Substrate inventory"}'
      ;;
    run)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"run",
          fields:{schema_version:"string",command:"string",ts:"date-time",mission_md_path:"string",
                  checks:"object",verdict:"string",blockers:"array",lock_hash_observed:"string|null",details:"object"},
          verdict_enum:["ready","incomplete","blocked"]}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,status:"unknown_surface",known_surfaces:["audit-row","mission-lock-scaffold","run"]}'
      ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  # Single-printf bodies — multiple printfs into a `grep -q` pipe trip SIGPIPE
  # under pipefail because grep -q exits on first match, closing the pipe
  # before later printfs complete.
  case "$topic" in
    run)
      printf 'topic: run — default invocation `mission-lock-scaffold-validator.sh [--mission PATH] [--json]` validates the mission lock against the 9 required sections, section hashes, substrate inventory pointers, and negative invariants. Emits verdict ready|incomplete|blocked. Each run appends one row to %s.\n' "$SCAFFOLD_AUDIT_LOG"
      ;;
    doctor)
      printf 'topic: doctor — probes the substrate this validator depends on: jq, python3, MISSION.md path readability, audit log directory writability, repo_root resolution. Emits {checks:[{check,status:ok|fail|warn,detail}],status}.\n'
      ;;
    health)
      printf 'topic: health — summarizes the run-history audit log: total_rows, last_status, last_ts, ready_count / incomplete_count / blocked_count, freshness_seconds. status: ok | empty | not_initialized.\n'
      ;;
    repair)
      printf 'topic: repair — scopes: audit_log_dir (ensure audit log directory exists), audit_log_truncate (backup-then-truncate; requires --apply --idempotency-key), none (no-op probe). Default --dry-run; --apply requires --idempotency-key. Dry-run emits planned_actions; apply emits applied_actions + idempotent_no_op flag.\n'
      ;;
    validate)
      printf 'topic: validate — subjects: audit-row (each audit row has ts, action, status, sha256 + status enum), mission-lock-scaffold (re-runs scaffold-validity probe against MISSION.md; verdict + blockers).\n'
      ;;
    *) printf 'topics: run | doctor | health | repair | validate\n' ;;
  esac
}

scaffold_emit_completion() {
  local shell="${1:-bash}"
  case "$shell" in
    -h|--help) scaffold_emit_topic_help completion 2>/dev/null \
                 || printf 'topic: completion <bash|zsh> — emit shell completion script\n'
               return 0 ;;
    bash) command -v cli_emit_completion_bash >/dev/null \
            && cli_emit_completion_bash "mission-lock-scaffold-validator" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "mission-lock-scaffold-validator" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  local checks_jsonl="" overall="ok"
  local emit_check
  emit_check() {
    local name="$1" status="$2" detail="$3"
    if [[ "$status" == "fail" ]]; then overall="fail"; fi
    jq -nc --arg c "$name" --arg s "$status" --arg d "$detail" \
      '{check:$c,status:$s,detail:$d}'
  }

  # 1. jq present
  if command -v jq >/dev/null 2>&1; then
    checks_jsonl+="$(emit_check jq ok "$(command -v jq)")"$'\n'
  else
    checks_jsonl+="$(emit_check jq fail "jq not on PATH")"$'\n'
  fi

  # 2. python3 present (cmd_run validator depends on it)
  if command -v python3 >/dev/null 2>&1; then
    checks_jsonl+="$(emit_check python3 ok "$(command -v python3)")"$'\n'
  else
    checks_jsonl+="$(emit_check python3 fail "python3 not on PATH (required by cmd_run mission validator)")"$'\n'
  fi

  # 3. repo_root resolved
  if [[ -n "${_SCAFFOLD_REPO_ROOT:-}" && -d "${_SCAFFOLD_REPO_ROOT:-/nonexistent}" ]]; then
    checks_jsonl+="$(emit_check repo_root ok "$_SCAFFOLD_REPO_ROOT")"$'\n'
  else
    checks_jsonl+="$(emit_check repo_root fail "repo root not resolved or missing: ${_SCAFFOLD_REPO_ROOT:-<unset>}")"$'\n'
  fi

  # 4. MISSION.md readable
  local mission_path="${_SCAFFOLD_REPO_ROOT}/.flywheel/MISSION.md"
  if [[ -r "$mission_path" ]]; then
    checks_jsonl+="$(emit_check mission_md ok "$mission_path")"$'\n'
  else
    checks_jsonl+="$(emit_check mission_md fail "MISSION.md not readable: $mission_path")"$'\n'
  fi

  # 5. audit log directory writable (or absent-creatable)
  local audit_dir
  audit_dir="$(dirname -- "$SCAFFOLD_AUDIT_LOG")"
  if [[ -d "$audit_dir" && -w "$audit_dir" ]]; then
    checks_jsonl+="$(emit_check audit_log_dir ok "$audit_dir")"$'\n'
  elif [[ ! -e "$audit_dir" ]]; then
    checks_jsonl+="$(emit_check audit_log_dir warn "absent (will be created on first append): $audit_dir")"$'\n'
  else
    checks_jsonl+="$(emit_check audit_log_dir fail "exists but not writable: $audit_dir")"$'\n'
  fi

  local ts
  ts="$(cli_iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf '%s' "$checks_jsonl" | jq -sc \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    --arg ts "$ts" \
    --arg status "$overall" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$status,checks:.}'
}

scaffold_cmd_health() {
  local ts now_epoch
  ts="$(cli_iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  now_epoch="$(date -u +%s)"

  if [[ ! -e "$SCAFFOLD_AUDIT_LOG" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg path "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"health",ts:$ts,status:"not_initialized",audit_log_path:$path,total_rows:0}'
    return 0
  fi

  local total_rows
  total_rows="$(wc -l <"$SCAFFOLD_AUDIT_LOG" 2>/dev/null | tr -d ' ' || printf '0')"
  total_rows="${total_rows:-0}"

  if [[ "$total_rows" -eq 0 ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg path "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"health",ts:$ts,status:"empty",audit_log_path:$path,total_rows:0}'
    return 0
  fi

  local last_row last_ts last_status ready_count incomplete_count blocked_count last_epoch freshness_seconds
  last_row="$(tail -n1 "$SCAFFOLD_AUDIT_LOG" 2>/dev/null || printf '')"
  last_ts="$(printf '%s' "$last_row" | jq -r '.ts // ""' 2>/dev/null || printf '')"
  last_status="$(printf '%s' "$last_row" | jq -r '.status // ""' 2>/dev/null || printf '')"
  ready_count="$({ grep -c '"status":"ready"' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null || true; } | tr -d ' \n')"
  incomplete_count="$({ grep -c '"status":"incomplete"' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null || true; } | tr -d ' \n')"
  blocked_count="$({ grep -c '"status":"blocked"' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null || true; } | tr -d ' \n')"
  ready_count="${ready_count:-0}"
  incomplete_count="${incomplete_count:-0}"
  blocked_count="${blocked_count:-0}"

  if [[ -n "$last_ts" ]]; then
    last_epoch="$(date -u -j -f '%Y-%m-%dT%H:%M:%SZ' "$last_ts" '+%s' 2>/dev/null || date -u -d "$last_ts" '+%s' 2>/dev/null || printf '0')"
    if [[ "$last_epoch" -gt 0 ]]; then
      freshness_seconds=$((now_epoch - last_epoch))
    else
      freshness_seconds=-1
    fi
  else
    freshness_seconds=-1
  fi

  jq -nc \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    --arg ts "$ts" \
    --arg status "ok" \
    --arg path "$SCAFFOLD_AUDIT_LOG" \
    --argjson total_rows "$total_rows" \
    --argjson ready_count "$ready_count" \
    --argjson incomplete_count "$incomplete_count" \
    --argjson blocked_count "$blocked_count" \
    --arg last_status "$last_status" \
    --arg last_ts "$last_ts" \
    --argjson freshness_seconds "$freshness_seconds" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,audit_log_path:$path,
      total_rows:$total_rows,ready_count:$ready_count,incomplete_count:$incomplete_count,
      blocked_count:$blocked_count,last_status:$last_status,last_ts:$last_ts,
      freshness_seconds:$freshness_seconds}'
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

  local ts audit_dir
  ts="$(cli_iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  audit_dir="$(dirname -- "$SCAFFOLD_AUDIT_LOG")"

  case "$scope" in
    audit_log_dir)
      if [[ "$mode" == "dry_run" ]]; then
        local actions_jsonl=""
        if [[ ! -d "$audit_dir" ]]; then
          actions_jsonl+="$(jq -nc --arg p "$audit_dir" '{action:"mkdir_p",path:$p,reason:"audit log directory absent"}')"$'\n'
        fi
        if [[ -z "$actions_jsonl" ]]; then
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg scope "$scope" \
            '{schema_version:$sv,command:"repair",ts:$ts,status:"dry_run",mode:"dry_run",scope:$scope,planned_actions:[],idempotent_no_op:true}'
        else
          printf '%s' "$actions_jsonl" | jq -sc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg scope "$scope" \
            '{schema_version:$sv,command:"repair",ts:$ts,status:"dry_run",mode:"dry_run",scope:$scope,planned_actions:.,idempotent_no_op:false}'
        fi
        return 0
      fi
      # apply
      local applied_jsonl="" idempotent_no_op=true
      if [[ ! -d "$audit_dir" ]]; then
        if mkdir -p "$audit_dir" 2>/dev/null; then
          applied_jsonl+="$(jq -nc --arg p "$audit_dir" '{action:"mkdir_p",path:$p,result:"created"}')"$'\n'
          idempotent_no_op=false
        else
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg scope "$scope" --arg dir "$audit_dir" --arg idem "$idem_key" \
            '{schema_version:$sv,command:"repair",ts:$ts,status:"failed",mode:"apply",scope:$scope,idempotency_key:$idem,error:"mkdir_p failed",path:$dir}'
          return 1
        fi
      fi
      if [[ -z "$applied_jsonl" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg scope "$scope" --arg idem "$idem_key" \
          '{schema_version:$sv,command:"repair",ts:$ts,status:"applied",mode:"apply",scope:$scope,idempotency_key:$idem,applied_actions:[],idempotent_no_op:true}'
      else
        printf '%s' "$applied_jsonl" | jq -sc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg scope "$scope" --arg idem "$idem_key" --argjson noop "$idempotent_no_op" \
          '{schema_version:$sv,command:"repair",ts:$ts,status:"applied",mode:"apply",scope:$scope,idempotency_key:$idem,applied_actions:.,idempotent_no_op:$noop}'
      fi
      ;;
    audit_log_truncate)
      if [[ "$mode" == "dry_run" ]]; then
        local exists planned_jsonl=""
        if [[ -e "$SCAFFOLD_AUDIT_LOG" ]]; then
          exists=true
          local row_count
          row_count="$(wc -l <"$SCAFFOLD_AUDIT_LOG" 2>/dev/null | tr -d ' ' || printf '0')"
          row_count="${row_count:-0}"
          planned_jsonl+="$(jq -nc --arg p "$SCAFFOLD_AUDIT_LOG" --argjson rc "$row_count" \
            '{action:"backup_then_truncate",path:$p,row_count_before:$rc,backup_path_pattern:"<path>.bak.<ts>"}')"$'\n'
        fi
        if [[ -z "$planned_jsonl" ]]; then
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg scope "$scope" \
            '{schema_version:$sv,command:"repair",ts:$ts,status:"dry_run",mode:"dry_run",scope:$scope,planned_actions:[],idempotent_no_op:true,note:"audit log absent — nothing to truncate"}'
        else
          printf '%s' "$planned_jsonl" | jq -sc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg scope "$scope" \
            '{schema_version:$sv,command:"repair",ts:$ts,status:"dry_run",mode:"dry_run",scope:$scope,planned_actions:.,idempotent_no_op:false}'
        fi
        return 0
      fi
      # apply: backup then truncate
      if [[ ! -e "$SCAFFOLD_AUDIT_LOG" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg scope "$scope" --arg idem "$idem_key" \
          '{schema_version:$sv,command:"repair",ts:$ts,status:"applied",mode:"apply",scope:$scope,idempotency_key:$idem,applied_actions:[],idempotent_no_op:true,note:"audit log absent — nothing to truncate"}'
        return 0
      fi
      local backup_ts backup_path
      backup_ts="$(date -u +%Y%m%dT%H%M%SZ)"
      backup_path="${SCAFFOLD_AUDIT_LOG}.bak.${backup_ts}"
      if cp -p "$SCAFFOLD_AUDIT_LOG" "$backup_path" 2>/dev/null && : >"$SCAFFOLD_AUDIT_LOG" 2>/dev/null; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg scope "$scope" --arg idem "$idem_key" --arg bp "$backup_path" --arg p "$SCAFFOLD_AUDIT_LOG" \
          '{schema_version:$sv,command:"repair",ts:$ts,status:"applied",mode:"apply",scope:$scope,idempotency_key:$idem,
            applied_actions:[{action:"backup",backup_path:$bp,result:"created"},{action:"truncate",path:$p,result:"emptied"}],
            idempotent_no_op:false}'
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg scope "$scope" --arg idem "$idem_key" \
          '{schema_version:$sv,command:"repair",ts:$ts,status:"failed",mode:"apply",scope:$scope,idempotency_key:$idem,error:"backup_or_truncate_failed"}'
        return 1
      fi
      ;;
    none)
      if [[ "$mode" == "dry_run" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg scope "$scope" \
          '{schema_version:$sv,command:"repair",ts:$ts,status:"dry_run",mode:"dry_run",scope:$scope,planned_actions:[],idempotent_no_op:true}'
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg scope "$scope" --arg idem "$idem_key" \
          '{schema_version:$sv,command:"repair",ts:$ts,status:"applied",mode:"apply",scope:$scope,idempotency_key:$idem,applied_actions:[],idempotent_no_op:true,note:"no-op scope"}'
      fi
      ;;
    "")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg mode "$mode" \
        '{schema_version:$sv,command:"repair",ts:$ts,status:"refused",mode:$mode,reason:"--scope <audit_log_dir|audit_log_truncate|none> required"}'
      return 64
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg scope "$scope" --arg mode "$mode" \
        '{schema_version:$sv,command:"repair",ts:$ts,status:"refused",mode:$mode,scope:$scope,reason:"unknown scope",known_scopes:["audit_log_dir","audit_log_truncate","none"]}'
      return 64
      ;;
  esac
}

scaffold_cmd_validate() {
  local subject=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --json) shift ;;
      -h|--help) scaffold_emit_topic_help validate; return 0 ;;
      --*) shift ;;
      *) if [[ -z "$subject" ]]; then subject="$1"; fi; shift ;;
    esac
  done
  local ts
  ts="$(cli_iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"

  case "$subject" in
    audit-row|"")
      subject="audit-row"
      if [[ ! -e "$SCAFFOLD_AUDIT_LOG" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg subject "$subject" --arg path "$SCAFFOLD_AUDIT_LOG" \
          '{schema_version:$sv,command:"validate",ts:$ts,subject:$subject,audit_log_path:$path,status:"empty",results:[],pass:0,fail:0}'
        return 0
      fi
      local lineno=0 pass=0 fail=0 results_jsonl=""
      local row_pass row_offending line
      while IFS= read -r line || [[ -n "$line" ]]; do
        lineno=$((lineno + 1))
        [[ -z "$line" ]] && continue
        row_pass=true
        row_offending="none"
        if printf '%s' "$line" | jq -e '
          (has("ts") and (.ts | type == "string") and (.ts | test("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$")))
          and (has("action") and (.action | type == "string") and (.action | length > 0))
          and (has("status") and (.status | type == "string"))
          and (has("sha256") and (.sha256 | type == "string"))
        ' >/dev/null 2>&1; then
          # Cross-field invariant: status (when set to a verdict) must be in the verdict enum.
          # We accept any non-empty status string; the strict enum is enforced when action == "validate".
          if printf '%s' "$line" | jq -e 'if .action == "validate" then (.status | IN("ready","incomplete","blocked")) else true end' >/dev/null 2>&1; then
            :
          else
            row_pass=false
            row_offending="validate_action_status_not_in_verdict_enum"
          fi
        else
          row_pass=false
          row_offending="missing_or_malformed_required_field"
        fi
        if $row_pass; then
          pass=$((pass + 1))
        else
          fail=$((fail + 1))
        fi
        results_jsonl+="$(jq -nc --argjson lineno "$lineno" --arg pass "$row_pass" --arg offending "$row_offending" \
          '{lineno:$lineno,pass:($pass=="true"),offending_field:$offending}')"$'\n'
      done <"$SCAFFOLD_AUDIT_LOG"

      local status="ok"
      if [[ "$fail" -gt 0 ]]; then status="fail"; fi
      printf '%s' "$results_jsonl" | jq -sc \
        --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        --arg ts "$ts" \
        --arg subject "$subject" \
        --arg path "$SCAFFOLD_AUDIT_LOG" \
        --arg status "$status" \
        --argjson pass "$pass" \
        --argjson fail "$fail" \
        '{schema_version:$sv,command:"validate",ts:$ts,subject:$subject,audit_log_path:$path,status:$status,pass:$pass,fail:$fail,results:.}'
      ;;
    mission-lock-scaffold)
      # Re-run the original cmd_run mission validator (out-of-band, no audit append).
      local mission_path="${_SCAFFOLD_REPO_ROOT}/.flywheel/MISSION.md"
      if [[ ! -r "$mission_path" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg subject "$subject" --arg p "$mission_path" \
          '{schema_version:$sv,command:"validate",ts:$ts,subject:$subject,status:"unavailable",mission_md_path:$p,reason:"MISSION.md not readable"}'
        return 0
      fi
      local cmd_run_self="${BASH_SOURCE[0]}"
      local probe_json
      probe_json="$(env _SCAFFOLD_VALIDATE_NESTED=1 "$cmd_run_self" --mission "$mission_path" --json 2>/dev/null || printf '')"
      if [[ -z "$probe_json" ]] || ! printf '%s' "$probe_json" | jq -e .verdict >/dev/null 2>&1; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg subject "$subject" --arg p "$mission_path" \
          '{schema_version:$sv,command:"validate",ts:$ts,subject:$subject,status:"unavailable",mission_md_path:$p,reason:"cmd_run probe returned non-JSON or no .verdict"}'
        return 0
      fi
      printf '%s' "$probe_json" | jq -c \
        --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        --arg ts "$ts" \
        --arg subject "$subject" \
        '{schema_version:$sv,command:"validate",ts:$ts,subject:$subject,
          mission_md_path:.mission_md_path,verdict:.verdict,blockers:.blockers,
          checks:.checks,lock_hash_observed:.lock_hash_observed,
          status:(if .verdict == "ready" then "ok" elif .verdict == "blocked" then "fail" else "incomplete" end)}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg subject "$subject" \
        '{schema_version:$sv,command:"validate",ts:$ts,subject:$subject,status:"unknown_subject",known_subjects:["audit-row","mission-lock-scaffold"]}'
      return 64
      ;;
  esac
}

scaffold_cmd_audit() {
  local tail_n=20
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --tail) tail_n="${2:-20}"; shift 2 ;;
      --tail=*) tail_n="${1#--tail=}"; shift ;;
      --json) shift ;;
      -h|--help) scaffold_emit_topic_help audit 2>/dev/null || printf 'topic: audit — tail run-history\n'; return 0 ;;
      *) shift ;;
    esac
  done

  if command -v cli_emit_audit_tail >/dev/null 2>&1; then
    cli_emit_audit_tail "$SCAFFOLD_AUDIT_LOG" "$SCAFFOLD_SCHEMA_VERSION" "$tail_n"
    return 0
  fi

  local ts
  ts="$(cli_iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  if [[ ! -e "$SCAFFOLD_AUDIT_LOG" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$SCAFFOLD_AUDIT_LOG" --argjson tail_n "$tail_n" \
      '{schema_version:$sv,command:"audit",ts:$ts,audit_log:$log,status:"not_initialized",tail_n:$tail_n,rows:[]}'
    return 0
  fi
  local rows_jsonl
  rows_jsonl="$(tail -n "$tail_n" "$SCAFFOLD_AUDIT_LOG" 2>/dev/null || printf '')"
  if [[ -z "$rows_jsonl" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$SCAFFOLD_AUDIT_LOG" --argjson tail_n "$tail_n" \
      '{schema_version:$sv,command:"audit",ts:$ts,audit_log:$log,status:"empty",tail_n:$tail_n,rows:[]}'
  else
    printf '%s\n' "$rows_jsonl" | jq -sc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$SCAFFOLD_AUDIT_LOG" --argjson tail_n "$tail_n" \
      '{schema_version:$sv,command:"audit",ts:$ts,audit_log:$log,status:"ok",tail_n:$tail_n,row_count:length,rows:.}'
  fi
}

scaffold_cmd_why() {
  local id="${1:-}"
  if [[ -z "$id" ]]; then
    printf 'ERR: why requires <id> argument (audit row ts, e.g. 2026-05-10T17:00:00Z)\n' >&2
    return 64
  fi
  local ts
  ts="$(cli_iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"

  if [[ ! -e "$SCAFFOLD_AUDIT_LOG" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"unavailable",audit_log_path:$log,reason:"audit log absent (no runs recorded yet)"}'
    return 0
  fi

  local row
  row="$(jq -c --arg id "$id" 'select(.ts == $id)' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | head -n1 || true)"

  if [[ -n "$row" ]]; then
    printf '%s' "$row" | jq -c \
      --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
      --arg ts "$ts" \
      --arg id "$id" \
      --arg log "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"found",audit_log_path:$log,row:.,
        provenance:{action:.action,status:.status,sha256:.sha256,mission_md_path:(.mission_md_path // null),verdict:(.verdict // null)}}'
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"not_found",audit_log_path:$log,reason:"no audit row matched ts==id"}'
  fi
}

# ---------- scaffolded main dispatcher ----------

# When the scaffolder appends this block, it expects the target's original
# top-level main is renamed to `cmd_run` (or the original final
# `main "$@"` line is replaced with this dispatcher). Default invocation
# falls through to the original logic for backward compat.
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

# Early-dispatch intercept: if argv[0] looks like a canonical subcommand
# or introspection flag, run the canonical surface and exit BEFORE the
# target's original arg parser sees the args. Works for both `main "$@"`
# style and inline `while [[ $# -gt 0 ]]` style targets.
_scaffold_is_canonical_arg() {
  case "${1:-}" in
    doctor|health|repair|validate|audit|why|quickstart|completion) return 0 ;;
    --info|--schema|--examples) return 0 ;;
    -h|--help) return 0 ;;
    help)
      # Intercept `help <topic>` and `help --help`; bare `help` could be
      # a legacy subcommand of the target so it falls through.
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
VERSION="mission-lock-scaffold-validator/v1"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
MISSION_PATH="$ROOT/.flywheel/MISSION.md"
JSON_OUT=0
QUIET=0
COMMAND="validate"
for arg in "$@"; do [[ "$arg" == "--json" ]] && JSON_OUT=1; done

usage() {
  printf '%s\n' \
    'usage:' \
    '  mission-lock-scaffold-validator.sh [validate|doctor|health|audit|schema] [--mission MISSION.md] [--json] [--quiet]' \
    '  mission-lock-scaffold-validator.sh --info|--help|--examples [--json]'
}

examples() {
  if [[ "$JSON_OUT" -eq 1 ]]; then
    jq -nc '{examples:["mission-lock-scaffold-validator.sh --json","mission-lock-scaffold-validator.sh validate --mission .flywheel/MISSION.md --json","mission-lock-scaffold-validator.sh schema --json"]}'
  else
    printf '%s\n' 'mission-lock-scaffold-validator.sh --json' 'mission-lock-scaffold-validator.sh validate --mission .flywheel/MISSION.md --json' 'mission-lock-scaffold-validator.sh schema --json'
  fi
}

info() {
  jq -nc --arg version "$VERSION" '{name:"mission-lock-scaffold-validator.sh",version:$version,mutates:false,canonical_cli_flags:["--info","--help","--examples","--json","--quiet"],canonical_cli_verbs:["validate","doctor","health","audit","schema"],exit_codes:{"0":"ready_or_incomplete","1":"blocked","2":"usage"}}'
}

schema_payload() {
  jq -nc --arg version "$VERSION" '{schema_version:$version,required_sections:["Mission Source","North-Star Outcome","Primary Beneficiary","Explicit Non-Goals","Safety And Privacy Boundaries","Evidence That Would Change The Mission","Owner-Review Cadence","Lock Receipt","Negative invariants (security)"],section_hash_algorithm:"sha256 normalized section body after removing section-hash comments, trimming blank edges, joining with LF, and appending one LF",section_hash_comment:"<!-- section_hash: <section title> sha256:<64 hex> -->",substrate_inventory_section:"Substrate inventory"}'
}

die_usage() { printf 'ERR: %s\n' "$1" >&2; exit 2; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    validate|doctor|health|audit|schema) COMMAND="$1"; shift ;;
    --json) JSON_OUT=1; shift ;;
    --quiet) QUIET=1; shift ;;
    --mission) [[ $# -ge 2 ]] || die_usage "--mission requires a path"; MISSION_PATH="$2"; shift 2 ;;
    --info) info; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    --examples) examples; exit 0 ;;
    --*) die_usage "unknown argument: $1" ;;
    *) MISSION_PATH="$1"; shift ;;
  esac
done

if [[ "$COMMAND" == "schema" ]]; then schema_payload; exit 0; fi
[[ -r "$MISSION_PATH" ]] || die_usage "mission file not readable: $MISSION_PATH"
TMP="$(mktemp "${TMPDIR:-/tmp}/mission-lock-scaffold.XXXXXX")"
trap 'rm -f "$TMP"' EXIT

python3 - "$MISSION_PATH" "$ROOT" "$VERSION" "$COMMAND" >"$TMP" <<'PY'
import datetime as D, hashlib, json, re, sys
from pathlib import Path

mission = Path(sys.argv[1]).resolve()
root = Path(sys.argv[2]).resolve()
version, command = sys.argv[3], sys.argv[4]
text = mission.read_text(encoding="utf-8")
lines = text.splitlines()
required = ["Mission Source","North-Star Outcome","Primary Beneficiary","Explicit Non-Goals","Safety And Privacy Boundaries","Evidence That Would Change The Mission","Owner-Review Cadence","Lock Receipt","Negative invariants (security)"]

def norm(title):
    return re.sub(r"\s+", " ", title.strip()).lower()

sections, current = {}, None
for line in lines:
    m = re.match(r"^##\s+(.+?)\s*$", line)
    if m:
        current = m.group(1).strip()
        sections.setdefault(norm(current), {"title": current, "body": []})
    elif current is not None:
        sections[norm(current)]["body"].append(line)

def body(title):
    return list(sections.get(norm(title), {}).get("body", []))

def section_hash(title):
    kept = [line.rstrip() for line in body(title) if not re.search(r"<!--\s*section[_-]hash:", line, re.I)]
    while kept and kept[0] == "":
        kept.pop(0)
    while kept and kept[-1] == "":
        kept.pop()
    return hashlib.sha256(("\n".join(kept) + "\n").encode()).hexdigest()

missing_sections = [title for title in required if norm(title) not in sections]
hash_entries = re.findall(r"<!--\s*section[_-]hash:\s*(.+?)\s+(?:sha256:)?([0-9a-fA-F]{64})\s*-->", text, re.I)
hash_mismatches = []
for title, observed in hash_entries:
    title = title.strip()
    if norm(title) not in sections:
        hash_mismatches.append({"section": title, "reason": "missing_section"})
    else:
        expected = section_hash(title)
        if expected.lower() != observed.lower():
            hash_mismatches.append({"section": title, "expected": f"sha256:{expected}", "observed": f"sha256:{observed.lower()}"})

def extract_pointers(section_lines):
    found = []
    for raw in section_lines:
        line = raw.strip()
        if not line or line.startswith(("#", "<!--")):
            continue
        local = re.findall(r"\[[^\]]+\]\(([^)]+)\)", line) + re.findall(r"`([^`]+)`", line)
        if not local:
            value = re.sub(r"^[-*]\s*", "", line)
            value = value.split(":", 1)[1].strip() if ":" in value else value
            if re.search(r"(^/|^\./|^\../|[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)", value):
                local.append(value)
        found.extend(local)
    clean = []
    for pointer in found:
        pointer = pointer.strip().strip("\"'")
        if pointer and pointer.lower() not in {"none", "n/a", "not_applicable"} and not re.match(r"^[a-z]+://", pointer) and not pointer.startswith("sha256:"):
            clean.append(pointer)
    return clean

substrate_body = body("Substrate inventory")
substrate_pointers = extract_pointers(substrate_body) if substrate_body else []
substrate_missing = []
for pointer in substrate_pointers:
    p = Path(pointer).expanduser()
    candidates = [p] if p.is_absolute() else [mission.parent / p, root / p, Path.cwd() / p]
    if not any(candidate.exists() for candidate in candidates):
        substrate_missing.append(pointer)

neg_body = [line.strip() for line in body("Negative invariants (security)") if line.strip() and not line.strip().startswith("<!--")]
blocked_states = []
for raw in lines:
    m = re.match(r"^(?:[-*]\s*)?(blocked[_ -]?readiness|blocked[_ -]?state|readiness)\s*[:=]\s*(.+)$", raw.strip(), re.I)
    if m and re.search(r"(blocked|missing|halt|hold|not_ready)", m.group(2), re.I):
        blocked_states.append(m.group(2).strip())

required_status = "pass" if not missing_sections else "fail"
hash_status = "skip" if not hash_entries else ("pass" if not hash_mismatches else "fail")
substrate_status = "skip" if not substrate_body else ("pass" if substrate_pointers and not substrate_missing else "fail")
negative_status = "pass" if neg_body else "fail"
blockers = [f"missing_required_section:{title}" for title in missing_sections]
blockers += [f"section_hash_mismatch:{item['section']}" for item in hash_mismatches]
blockers += [f"substrate_inventory_unresolved:{item}" for item in substrate_missing]
if substrate_body and not substrate_pointers:
    blockers.append("substrate_inventory_empty")
if negative_status == "fail":
    blockers.append("negative_invariants_empty")
blockers += [f"blocked_readiness:{item}" for item in blocked_states]
verdict = "blocked" if blockers else ("incomplete" if "skip" in {hash_status, substrate_status} else "ready")
lock_match = re.search(r"(?m)^lock_hash:\s*((?:sha256:)?[0-9a-fA-F]{64})\s*$", text)

print(json.dumps({
    "schema_version": version,
    "command": command,
    "ts": D.datetime.now(D.timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
    "mission_md_path": str(mission),
    "checks": {
        "required_sections_present": required_status,
        "section_hashes_match": hash_status,
        "substrate_inventory_resolves": substrate_status,
        "negative_invariants_non_empty": negative_status,
        "blocked_readiness_states": blocked_states
    },
    "verdict": verdict,
    "blockers": blockers,
    "lock_hash_observed": lock_match.group(1) if lock_match else None,
    "details": {
        "required_sections": required,
        "missing_sections": missing_sections,
        "section_hash_mismatches": hash_mismatches,
        "substrate_pointers": substrate_pointers,
        "substrate_unresolved": substrate_missing
    }
}, sort_keys=True))
PY

verdict="$(jq -r '.verdict' "$TMP")"
if [[ "$QUIET" -eq 0 && "$JSON_OUT" -eq 1 ]]; then
  cat "$TMP"
elif [[ "$QUIET" -eq 0 ]]; then
  jq -r '"verdict=\(.verdict) blockers=\(.blockers|length) mission=\(.mission_md_path)"' "$TMP"
fi

# Append run row to scaffold audit log (skip for nested probes from
# scaffold_cmd_validate to avoid recursion noise). Helper handles
# missing-dir + write-failure silently.
if [[ -z "${_SCAFFOLD_VALIDATE_NESTED:-}" ]] && command -v cli_audit_append >/dev/null 2>&1; then
  blocker_count="$(jq -r '.blockers | length' "$TMP" 2>/dev/null || printf '0')"
  lock_hash_observed="$(jq -r '.lock_hash_observed // ""' "$TMP" 2>/dev/null || printf '')"
  extra_json="$(jq -nc --arg mp "$MISSION_PATH" --arg verdict "$verdict" --argjson bc "${blocker_count:-0}" --arg lh "$lock_hash_observed" --arg cmd "$COMMAND" \
    '{mission_md_path:$mp,verdict:$verdict,blocker_count:$bc,lock_hash_observed:(if $lh == "" then null else $lh end),cmd_run_command:$cmd}' 2>/dev/null || printf '{}')"
  cli_audit_append "$SCAFFOLD_AUDIT_LOG" "$COMMAND" "$verdict" "$extra_json"
fi

[[ "$verdict" != "blocked" ]]
