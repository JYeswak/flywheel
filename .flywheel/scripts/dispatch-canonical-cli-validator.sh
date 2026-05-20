#!/usr/bin/env bash
set -euo pipefail


# ====== BEGIN canonical-cli scaffold (bead flywheel-ws02m) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing
# doctor-mode-tier: filled (bead flywheel-39vhm)
#
# This block is APPENDED by scaffold-canonical-cli.sh. The original
# top-level dispatch is preserved as `cmd_run` (the new main routes
# default invocation through cmd_run for backward compat). Surface-
# specific logic was filled in by flywheel-39vhm (doctor/health/repair/
# validate/audit/why all bind to the real decision ledger written by
# `check`). Per-surface schemas exposed via --schema decision|ledger.

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="dispatch-canonical-cli-validator/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/dispatch-canonical-cli-validator-runs.jsonl}"
# Lifted from cmd_run scope so canonical-cli stubs (which exit before
# the original parser runs) can resolve the real ledger written by
# `check`. Default tracks the original cmd_run definition (line ~245).
SCAFFOLD_LEDGER_PATH="${DISPATCH_CANONICAL_CLI_LEDGER:-$HOME/.local/state/flywheel/dispatch-canonical-cli-validator-ledger.jsonl}"
SCAFFOLD_DECISION_ROW_SCHEMA="dispatch-canonical-cli-decision/v1"
SCAFFOLD_DECISION_SCHEMA_SIDECAR="${_SCAFFOLD_REPO_ROOT}/.flywheel/validation-schema/v1/dispatch-canonical-cli-decision.schema.json"

scaffold_usage() {
  cat <<'USG'
usage: dispatch-canonical-cli-validator.sh [SUBCOMMAND] [OPTIONS]

Backward-compatible run mode: default invocation routes to the original
top-level logic (now exposed as `cmd_run`).

Canonical CLI surfaces:
  doctor [--json]          probe substrate health
  health [--json]          last-run status
  repair --scope <s>       repair misconfigured state
                            Default: --dry-run; mutate with --apply --idempotency-key KEY
  validate <subject> [...] validate decision ledger contracts
  audit [--json]           recent run history
  why <id>                 explain decision-ledger provenance for a timestamp or id
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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "dispatch-canonical-cli-validator.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "dispatch-canonical-cli-validator.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"dispatch-canonical-cli-validator.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"dispatch-canonical-cli-validator.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"dispatch-canonical-cli-validator.sh doctor --json"}'
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
    decision|default)
      jq -nc \
        --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        --arg row_schema "$SCAFFOLD_DECISION_ROW_SCHEMA" \
        --arg sidecar "$SCAFFOLD_DECISION_SCHEMA_SIDECAR" \
        '{schema_version:$sv,command:"schema",surface:"decision",
          row_schema_version:$row_schema,
          sidecar_path:$sidecar,
          required_fields:["schema_version","ts","decision","introduces_cli","missing_elements","reason","ledger_appended"],
          decision_enum:["allow","refuse"],
          missing_element_enum:["info_help_examples","json","exit_codes","canonical_cli_skill"],
          exit_codes:{"0":"allow","1":"refuse","2":"usage_or_malformed_fail_open"}}'
      ;;
    ledger)
      jq -nc \
        --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        --arg path "$SCAFFOLD_LEDGER_PATH" \
        --arg row_schema "$SCAFFOLD_DECISION_ROW_SCHEMA" \
        '{schema_version:$sv,command:"schema",surface:"ledger",
          format:"jsonl",path:$path,row_schema_version:$row_schema,
          override_env:"DISPATCH_CANONICAL_CLI_LEDGER"}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,status:"unknown_surface",known_surfaces:["decision","ledger"]}'
      ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)
      printf 'topic: run — `check --dispatch-file PATH [--json]` or `check --dispatch-stdin [--json]`.\n'
      printf '  Validates that a dispatch packet introducing a CLI surface includes the four\n'
      printf '  canonical-cli acceptance gates (--info/--help/--examples, --json output, exit\n'
      printf '  codes, canonical-cli-scoping skill citation). Writes a decision row to\n'
      printf '  %s.\n' "$SCAFFOLD_LEDGER_PATH"
      printf '  Exit codes: 0=allow, 1=refuse, 2=usage_or_malformed_fail_open.\n'
      ;;
    doctor)
      printf 'topic: doctor — probes the substrate this validator depends on:\n'
      printf '  jq (mandatory parser), repo_root resolution, ledger directory writability,\n'
      printf '  ledger file readability (or absent-ok), decision schema sidecar presence.\n'
      printf '  Emits {checks:[{check,status:ok|fail|warn,detail}], status:ok|fail}.\n'
      ;;
    health)
      printf 'topic: health — summarizes the dispatch decision ledger:\n'
      printf '  total_rows, last_decision (allow|refuse), last_ts, allow_count, refuse_count,\n'
      printf '  freshness_seconds (since last row). status: ok | empty | not_initialized.\n'
      ;;
    repair)
      printf 'topic: repair — scopes:\n'
      printf '  state  — ensure ledger directory exists (and ledger file is touchable).\n'
      printf '  none   — no-op probe (validator is otherwise read-only on substrate).\n'
      printf '  Default --dry-run; --apply requires --idempotency-key. Emits planned_actions\n'
      printf '  on dry-run; emits applied_actions + idempotent_no_op flag on apply.\n'
      ;;
    validate)
      printf 'topic: validate — subjects:\n'
      printf '  ledger — each row has schema_version=%s, ts (ISO8601),\n' "$SCAFFOLD_DECISION_ROW_SCHEMA"
      printf '          decision in {allow,refuse}, introduces_cli boolean, missing_elements\n'
      printf '          array, ledger_appended path. Returns per-row pass/fail with offending field.\n'
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
            && cli_emit_completion_bash "dispatch-canonical-cli-validator" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "dispatch-canonical-cli-validator" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli surface implementation ----------

scaffold_cmd_doctor() {
  # Probe the substrate this validator depends on: jq, repo_root, ledger
  # directory writability, ledger file readability, decision schema sidecar.
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

  # 2. repo_root resolved
  if [[ -n "${_SCAFFOLD_REPO_ROOT:-}" && -d "${_SCAFFOLD_REPO_ROOT:-/nonexistent}" ]]; then
    checks_jsonl+="$(emit_check repo_root ok "$_SCAFFOLD_REPO_ROOT")"$'\n'
  else
    checks_jsonl+="$(emit_check repo_root fail "repo root not resolved or missing: ${_SCAFFOLD_REPO_ROOT:-<unset>}")"$'\n'
  fi

  # 3. ledger directory: must exist OR be creatable
  local ledger_dir
  ledger_dir="$(dirname -- "$SCAFFOLD_LEDGER_PATH")"
  if [[ -d "$ledger_dir" && -w "$ledger_dir" ]]; then
    checks_jsonl+="$(emit_check ledger_dir ok "$ledger_dir")"$'\n'
  elif [[ ! -e "$ledger_dir" ]]; then
    checks_jsonl+="$(emit_check ledger_dir warn "absent (will be created on first write): $ledger_dir")"$'\n'
  else
    checks_jsonl+="$(emit_check ledger_dir fail "exists but not writable: $ledger_dir")"$'\n'
  fi

  # 4. ledger file: readable when present, absent-ok
  if [[ -f "$SCAFFOLD_LEDGER_PATH" ]]; then
    if [[ -r "$SCAFFOLD_LEDGER_PATH" ]]; then
      checks_jsonl+="$(emit_check ledger_file ok "readable: $SCAFFOLD_LEDGER_PATH")"$'\n'
    else
      checks_jsonl+="$(emit_check ledger_file fail "exists but not readable: $SCAFFOLD_LEDGER_PATH")"$'\n'
    fi
  else
    checks_jsonl+="$(emit_check ledger_file warn "absent (no decisions recorded yet): $SCAFFOLD_LEDGER_PATH")"$'\n'
  fi

  # 5. decision schema sidecar present
  if [[ -r "$SCAFFOLD_DECISION_SCHEMA_SIDECAR" ]]; then
    checks_jsonl+="$(emit_check decision_schema_sidecar ok "$SCAFFOLD_DECISION_SCHEMA_SIDECAR")"$'\n'
  else
    checks_jsonl+="$(emit_check decision_schema_sidecar fail "missing or unreadable: $SCAFFOLD_DECISION_SCHEMA_SIDECAR")"$'\n'
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
  # Summarize the dispatch decision ledger: total rows, last decision/ts,
  # allow/refuse counts, freshness in seconds since last row.
  local ts now_epoch
  ts="$(cli_iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  now_epoch="$(date -u +%s)"

  if [[ ! -e "$SCAFFOLD_LEDGER_PATH" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg path "$SCAFFOLD_LEDGER_PATH" \
      '{schema_version:$sv,command:"health",ts:$ts,status:"not_initialized",ledger_path:$path,total_rows:0}'
    return 0
  fi

  local total_rows
  total_rows="$(wc -l <"$SCAFFOLD_LEDGER_PATH" 2>/dev/null | tr -d ' ' || printf '0')"
  total_rows="${total_rows:-0}"

  if [[ "$total_rows" -eq 0 ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg path "$SCAFFOLD_LEDGER_PATH" \
      '{schema_version:$sv,command:"health",ts:$ts,status:"empty",ledger_path:$path,total_rows:0}'
    return 0
  fi

  # Read last row + counts. Wrap pipefail-sensitive grep with || true.
  local last_row last_ts last_decision allow_count refuse_count last_epoch freshness_seconds
  last_row="$(tail -n1 "$SCAFFOLD_LEDGER_PATH" 2>/dev/null || printf '')"
  last_ts="$(printf '%s' "$last_row" | jq -r '.ts // ""' 2>/dev/null || printf '')"
  last_decision="$(printf '%s' "$last_row" | jq -r '.decision // ""' 2>/dev/null || printf '')"
  allow_count="$({ grep -c '"decision":"allow"' "$SCAFFOLD_LEDGER_PATH" 2>/dev/null || true; } | tr -d ' \n')"
  refuse_count="$({ grep -c '"decision":"refuse"' "$SCAFFOLD_LEDGER_PATH" 2>/dev/null || true; } | tr -d ' \n')"
  allow_count="${allow_count:-0}"
  refuse_count="${refuse_count:-0}"

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
    --arg path "$SCAFFOLD_LEDGER_PATH" \
    --argjson total_rows "$total_rows" \
    --argjson allow_count "$allow_count" \
    --argjson refuse_count "$refuse_count" \
    --arg last_decision "$last_decision" \
    --arg last_ts "$last_ts" \
    --argjson freshness_seconds "$freshness_seconds" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,ledger_path:$path,
      total_rows:$total_rows,allow_count:$allow_count,refuse_count:$refuse_count,
      last_decision:$last_decision,last_ts:$last_ts,freshness_seconds:$freshness_seconds}'
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

  local ts ledger_dir
  ts="$(cli_iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  ledger_dir="$(dirname -- "$SCAFFOLD_LEDGER_PATH")"

  case "$scope" in
    state)
      if [[ "$mode" == "dry_run" ]]; then
        local actions_jsonl=""
        if [[ ! -d "$ledger_dir" ]]; then
          actions_jsonl+="$(jq -nc --arg p "$ledger_dir" '{action:"mkdir_p",path:$p,reason:"ledger directory absent"}')"$'\n'
        fi
        if [[ ! -e "$SCAFFOLD_LEDGER_PATH" ]]; then
          actions_jsonl+="$(jq -nc --arg p "$SCAFFOLD_LEDGER_PATH" '{action:"touch",path:$p,reason:"ledger file absent (validator will create on first decision)"}')"$'\n'
        fi
        if [[ -z "$actions_jsonl" ]]; then
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg scope "$scope" \
            '{schema_version:$sv,command:"repair",ts:$ts,status:"dry_run",mode:"dry_run",scope:$scope,planned_actions:[],idempotent_no_op:true}'
        else
          printf '%s' "$actions_jsonl" | jq -sc \
            --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg scope "$scope" \
            '{schema_version:$sv,command:"repair",ts:$ts,status:"dry_run",mode:"dry_run",scope:$scope,planned_actions:.,idempotent_no_op:false}'
        fi
        return 0
      fi

      # apply mode
      local applied_jsonl="" idempotent_no_op=true
      if [[ ! -d "$ledger_dir" ]]; then
        if mkdir -p "$ledger_dir" 2>/dev/null; then
          applied_jsonl+="$(jq -nc --arg p "$ledger_dir" '{action:"mkdir_p",path:$p,result:"created"}')"$'\n'
          idempotent_no_op=false
        else
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg scope "$scope" --arg dir "$ledger_dir" --arg idem "$idem_key" \
            '{schema_version:$sv,command:"repair",ts:$ts,status:"failed",mode:"apply",scope:$scope,idempotency_key:$idem,error:"mkdir_p failed",path:$dir}'
          return 1
        fi
      fi
      if [[ ! -e "$SCAFFOLD_LEDGER_PATH" ]]; then
        if : >>"$SCAFFOLD_LEDGER_PATH" 2>/dev/null; then
          applied_jsonl+="$(jq -nc --arg p "$SCAFFOLD_LEDGER_PATH" '{action:"touch",path:$p,result:"created"}')"$'\n'
          idempotent_no_op=false
        fi
      fi

      if [[ -z "$applied_jsonl" ]]; then
        jq -nc \
          --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg scope "$scope" --arg idem "$idem_key" \
          '{schema_version:$sv,command:"repair",ts:$ts,status:"applied",mode:"apply",scope:$scope,idempotency_key:$idem,applied_actions:[],idempotent_no_op:true}'
      else
        printf '%s' "$applied_jsonl" | jq -sc \
          --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg scope "$scope" --arg idem "$idem_key" \
          --argjson noop "$idempotent_no_op" \
          '{schema_version:$sv,command:"repair",ts:$ts,status:"applied",mode:"apply",scope:$scope,idempotency_key:$idem,applied_actions:.,idempotent_no_op:$noop}'
      fi
      ;;
    none)
      if [[ "$mode" == "dry_run" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg scope "$scope" \
          '{schema_version:$sv,command:"repair",ts:$ts,status:"dry_run",mode:"dry_run",scope:$scope,planned_actions:[],idempotent_no_op:true,note:"validator is otherwise read-only on substrate"}'
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg scope "$scope" --arg idem "$idem_key" \
          '{schema_version:$sv,command:"repair",ts:$ts,status:"applied",mode:"apply",scope:$scope,idempotency_key:$idem,applied_actions:[],idempotent_no_op:true,note:"no-op scope"}'
      fi
      ;;
    "")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg mode "$mode" \
        '{schema_version:$sv,command:"repair",ts:$ts,status:"refused",mode:$mode,reason:"--scope <state|none> required"}'
      return 64
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg scope "$scope" --arg mode "$mode" \
        '{schema_version:$sv,command:"repair",ts:$ts,status:"refused",mode:$mode,scope:$scope,reason:"unknown scope",known_scopes:["state","none"]}'
      return 64
      ;;
  esac
}

scaffold_cmd_validate() {
  # First non-flag arg is the subject. Defaults to `ledger` when only flags
  # are supplied (e.g. `validate --json`).
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
    ledger|"")
      subject="ledger"
      if [[ ! -e "$SCAFFOLD_LEDGER_PATH" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg subject "$subject" --arg path "$SCAFFOLD_LEDGER_PATH" \
          '{schema_version:$sv,command:"validate",ts:$ts,subject:$subject,ledger_path:$path,status:"empty",results:[],pass:0,fail:0}'
        return 0
      fi
      local lineno=0 pass=0 fail=0 results_jsonl=""
      local row_pass row_offending row line
      while IFS= read -r line || [[ -n "$line" ]]; do
        lineno=$((lineno + 1))
        [[ -z "$line" ]] && continue
        row_pass=true
        row_offending="none"
        # Required fields must all be present and non-null.
        local required_check
        required_check="$(printf '%s' "$line" | jq -e '
          (has("schema_version") and (.schema_version == "'"$SCAFFOLD_DECISION_ROW_SCHEMA"'"))
          and (has("ts") and (.ts | type == "string") and (.ts | test("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$")))
          and (has("decision") and (.decision == "allow" or .decision == "refuse"))
          and (has("introduces_cli") and (.introduces_cli | type == "boolean"))
          and (has("missing_elements") and (.missing_elements | type == "array"))
          and (has("reason") and (.reason | type == "string") and (.reason | length > 0))
          and (has("ledger_appended") and (.ledger_appended | type == "string"))
        ' >/dev/null 2>&1 && printf 'ok' || printf 'fail')"
        if [[ "$required_check" == "ok" ]]; then
          # Cross-field invariant: refuse implies missing_elements is non-empty.
          local invariant_check
          invariant_check="$(printf '%s' "$line" | jq -e 'if .decision == "refuse" then (.missing_elements | length > 0) else true end' >/dev/null 2>&1 && printf 'ok' || printf 'fail')"
          if [[ "$invariant_check" != "ok" ]]; then
            row_pass=false
            row_offending="refuse_with_empty_missing_elements"
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
      done <"$SCAFFOLD_LEDGER_PATH"

      local status="ok"
      if [[ "$fail" -gt 0 ]]; then status="fail"; fi
      printf '%s' "$results_jsonl" | jq -sc \
        --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        --arg ts "$ts" \
        --arg subject "$subject" \
        --arg path "$SCAFFOLD_LEDGER_PATH" \
        --arg status "$status" \
        --argjson pass "$pass" \
        --argjson fail "$fail" \
        '{schema_version:$sv,command:"validate",ts:$ts,subject:$subject,ledger_path:$path,status:$status,pass:$pass,fail:$fail,results:.}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg subject "$subject" \
        '{schema_version:$sv,command:"validate",ts:$ts,subject:$subject,status:"unknown_subject",known_subjects:["ledger"]}'
      return 64
      ;;
  esac
}

scaffold_cmd_audit() {
  # Tail the decision ledger and emit the last N rows. N defaults to 20 and
  # can be overridden with --tail N. Uses cli_emit_audit_tail when helper lib
  # is available; falls back to a self-contained jq tail.
  local tail_n=20
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --tail) tail_n="${2:-20}"; shift 2 ;;
      --tail=*) tail_n="${1#--tail=}"; shift ;;
      --json) shift ;;
      -h|--help) scaffold_emit_topic_help audit 2>/dev/null || printf 'topic: audit — tail decision ledger\n'; return 0 ;;
      *) shift ;;
    esac
  done

  if command -v cli_emit_audit_tail >/dev/null 2>&1; then
    # helper signature: cli_emit_audit_tail <audit_log_path> <schema_version> [<limit>]
    cli_emit_audit_tail "$SCAFFOLD_LEDGER_PATH" "$SCAFFOLD_SCHEMA_VERSION" "$tail_n"
    return 0
  fi

  local ts
  ts="$(cli_iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"

  if [[ ! -e "$SCAFFOLD_LEDGER_PATH" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$SCAFFOLD_LEDGER_PATH" --argjson tail_n "$tail_n" \
      '{schema_version:$sv,command:"audit",ts:$ts,audit_log:$log,status:"not_initialized",tail_n:$tail_n,rows:[]}'
    return 0
  fi

  local rows_jsonl
  rows_jsonl="$(tail -n "$tail_n" "$SCAFFOLD_LEDGER_PATH" 2>/dev/null || printf '')"
  if [[ -z "$rows_jsonl" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$SCAFFOLD_LEDGER_PATH" --argjson tail_n "$tail_n" \
      '{schema_version:$sv,command:"audit",ts:$ts,audit_log:$log,status:"empty",tail_n:$tail_n,rows:[]}'
  else
    printf '%s\n' "$rows_jsonl" | jq -sc \
      --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
      --arg ts "$ts" \
      --arg log "$SCAFFOLD_LEDGER_PATH" \
      --argjson tail_n "$tail_n" \
      '{schema_version:$sv,command:"audit",ts:$ts,audit_log:$log,status:"ok",tail_n:$tail_n,row_count:length,rows:.}'
  fi
}

scaffold_cmd_why() {
  local id="${1:-}"
  if [[ -z "$id" ]]; then
    printf 'ERR: why requires <id> argument (decision row ts, e.g. 2026-05-08T06:21:25Z)\n' >&2
    return 64
  fi
  # id semantics: a row ts. Look up the matching ledger row and emit
  # found|not_found|unavailable.
  local ts
  ts="$(cli_iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"

  if [[ ! -e "$SCAFFOLD_LEDGER_PATH" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_LEDGER_PATH" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"unavailable",ledger_path:$log,reason:"ledger absent (no decisions recorded yet)"}'
    return 0
  fi

  local row
  row="$(jq -c --arg id "$id" 'select(.ts == $id)' "$SCAFFOLD_LEDGER_PATH" 2>/dev/null | head -n1 || true)"

  if [[ -n "$row" ]]; then
    printf '%s' "$row" | jq -c \
      --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
      --arg ts "$ts" \
      --arg id "$id" \
      --arg log "$SCAFFOLD_LEDGER_PATH" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"found",ledger_path:$log,row:.,
        provenance:{decision:.decision,introduces_cli:.introduces_cli,missing_elements:.missing_elements,reason:.reason}}'
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_LEDGER_PATH" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"not_found",ledger_path:$log,reason:"no ledger row matched ts==id"}'
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
VERSION="dispatch-canonical-cli-validator/v1"
SCHEMA_VERSION="dispatch-canonical-cli-decision/v1"
LEDGER="${DISPATCH_CANONICAL_CLI_LEDGER:-$HOME/.local/state/flywheel/dispatch-canonical-cli-validator-ledger.jsonl}"
DISPATCH_FILE=""
DISPATCH_STDIN=0
JSON_OUT=0

usage() {
  cat <<'USAGE'
usage:
  dispatch-canonical-cli-validator.sh check --dispatch-file PATH [--json]
  dispatch-canonical-cli-validator.sh check --dispatch-stdin [--json]
  dispatch-canonical-cli-validator.sh --info|--help|--examples [--json]

Validates that dispatch packets introducing CLI surfaces include canonical
CLI scoping acceptance gates before dispatch is sent.

Exit codes:
  0  allow
  1  refuse
  2  usage error or malformed dispatch packet fail-open
USAGE
}

examples() {
  cat <<'EXAMPLES'
dispatch-canonical-cli-validator.sh check --dispatch-file /tmp/dispatch_abc123.md --json
dispatch-canonical-cli-validator.sh check --dispatch-stdin --json < /tmp/dispatch_abc123.md
DISPATCH_CANONICAL_CLI_LEDGER=/tmp/ledger.jsonl dispatch-canonical-cli-validator.sh check --dispatch-file fixture.md
EXAMPLES
}

info() {
  jq -nc \
    --arg name "dispatch-canonical-cli-validator.sh" \
    --arg version "$VERSION" \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg ledger "$LEDGER" \
    '{
      name:$name,
      version:$version,
      schema_version:$schema_version,
      ledger:$ledger,
      purpose:"pre-dispatch canonical-cli-scoping acceptance gate",
      output_schema:".flywheel/validation-schema/v1/dispatch-canonical-cli-decision.schema.json",
      exit_codes:{"0":"allow","1":"refuse","2":"usage or malformed dispatch fail-open"}
    }'
}

now_iso() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

fail_usage() {
  printf 'ERR: %s\n' "$1" >&2
  usage >&2
  exit 2
}

append_ledger() {
  local row="$1"
  mkdir -p "$(dirname "$LEDGER")"
  jq -c . <<<"$row" >>"$LEDGER"
}

missing_array_json() {
  if [[ "$#" -eq 0 ]]; then
    printf '[]'
    return 0
  fi
  printf '%s\n' "$@" | jq -R -s -c 'split("\n")[:-1]'
}

emit_decision() {
  local decision="$1" introduces_cli="$2" reason="$3" exit_code="$4"
  shift 4
  local missing_json payload
  missing_json="$(missing_array_json "$@")"
  payload="$(jq -nc \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg ts "$(now_iso)" \
    --arg decision "$decision" \
    --argjson introduces_cli "$introduces_cli" \
    --argjson missing_elements "$missing_json" \
    --arg reason "$reason" \
    --arg ledger "$LEDGER" \
    '{
      schema_version:$schema_version,
      ts:$ts,
      decision:$decision,
      introduces_cli:$introduces_cli,
      missing_elements:$missing_elements,
      reason:$reason,
      ledger_appended:$ledger
    }')"
  append_ledger "$payload" || true
  if [[ "$JSON_OUT" -eq 1 ]]; then
    printf '%s\n' "$payload"
  else
    jq -r '"decision=\(.decision) introduces_cli=\(.introduces_cli) reason=\(.reason) missing=\(.missing_elements|join(","))"' <<<"$payload"
  fi
  exit "$exit_code"
}

contains_ci() {
  grep -Eiq "$1" <<<"$2"
}

has_markdown_shape() {
  [[ "${#1}" -ge 20 ]] && grep -Eq '^#{1,6}[[:space:]]+' <<<"$1"
}

introduces_cli_surface() {
  local text="$1"
  if contains_ci '(^|[[:space:]`"])\.flywheel/scripts/[^[:space:]`")]+\.sh' "$text"; then
    return 0
  fi
  if contains_ci '(^|[[:space:]])--(info|help|examples|json)([[:space:]|,`.)]|$)' "$text"; then
    return 0
  fi
  if contains_ci '\b(CLI|command|flag|subcommand|operator-facing tool)\b' "$text"; then
    return 0
  fi
  return 1
}

has_info_help_examples() {
  local text="$1"
  if grep -Fq -- '--info|--help|--examples' <<<"$text"; then
    return 0
  fi
  grep -Fq -- '--info' <<<"$text" \
    && grep -Fq -- '--help' <<<"$text" \
    && grep -Fq -- '--examples' <<<"$text"
}

has_json_output() {
  local text="$1"
  grep -Fq -- '--json' <<<"$text" \
    && contains_ci '(json output|output[^[:alpha:]]+.*--json|--json.*output|machine-readable)' "$text"
}

has_exit_codes() {
  local text="$1"
  if contains_ci '(canonical-cli-scoping.*exit codes stable|exit codes stable.*canonical-cli-scoping)' "$text"; then
    return 0
  fi
  contains_ci 'exit[- ]codes?' "$text" \
    && contains_ci '(^|[^0-9])0[[:space:]]*[:=]' "$text" \
    && contains_ci '(^|[^0-9])1[[:space:]]*[:=]' "$text" \
    && contains_ci '(^|[^0-9])2[[:space:]]*[:=]' "$text"
}

has_canonical_skill() {
  local text="$1"
  grep -Fqi -- 'canonical-cli-scoping' <<<"$text" \
    && contains_ci '(skill|SKILL\.md|skills consulted|acceptance gate)' "$text"
}

run_check() {
  local body missing=()
  if [[ -n "$DISPATCH_FILE" ]]; then
    [[ -r "$DISPATCH_FILE" ]] || fail_usage "dispatch file not readable: $DISPATCH_FILE"
    body="$(<"$DISPATCH_FILE")"
  elif [[ "$DISPATCH_STDIN" -eq 1 ]]; then
    body="$(cat)"
  else
    fail_usage "check requires --dispatch-file or --dispatch-stdin"
  fi

  if ! has_markdown_shape "$body"; then
    emit_decision "allow" "false" "malformed_dispatch_packet_fail_open" 2
  fi

  if ! introduces_cli_surface "$body"; then
    emit_decision "allow" "false" "not_introducing_cli" 0
  fi

  has_info_help_examples "$body" || missing+=("info_help_examples")
  has_json_output "$body" || missing+=("json")
  has_exit_codes "$body" || missing+=("exit_codes")
  has_canonical_skill "$body" || missing+=("canonical_cli_skill")

  if [[ "${#missing[@]}" -eq 0 ]]; then
    emit_decision "allow" "true" "canonical_cli_acceptance_present" 0
  fi
  emit_decision "refuse" "true" "dispatch_packet_missing_canonical_cli_acceptance" 1 "${missing[@]}"
}

if [[ "$#" -eq 0 ]]; then
  fail_usage "missing command"
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    check) shift ;;
    --dispatch-file) DISPATCH_FILE="${2:-}"; shift 2 ;;
    --dispatch-file=*) DISPATCH_FILE="${1#*=}"; shift ;;
    --dispatch-stdin) DISPATCH_STDIN=1; shift ;;
    --json) JSON_OUT=1; shift ;;
    --info) info; exit 0 ;;
    --examples) examples; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    *) fail_usage "unknown argument: $1" ;;
  esac
done

[[ "$DISPATCH_STDIN" -eq 0 || -z "$DISPATCH_FILE" ]] || fail_usage "use either --dispatch-file or --dispatch-stdin"
run_check

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-20-cross-orch-handoff.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-63-phase-tick-bounded-action.md`
