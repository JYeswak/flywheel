#!/usr/bin/env bash
set -euo pipefail


# ====== BEGIN canonical-cli scaffold (bead flywheel-ws02m) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing
# doctor-mode-tier: filled (bead flywheel-1fk5f.1)
#
# Filled by flywheel-1fk5f.1: doctor probes the cmd_run substrate
# (jq/python3/dispatch_log/delivery_ledger_dir/lock_dir); health/audit/
# why bind to the live delivery ledger written by `mark-delivered`;
# validate enforces delivery-row schema; repair manages ledger_dir +
# lock_dir scopes.

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="dispatch-self-test-delivery-identity/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/dispatch-self-test-delivery-identity-runs.jsonl}"
# Module-scope lift of cmd_run state paths so canonical-cli stubs
# (which exit before the original parser runs) can resolve the real
# delivery ledger written by `mark-delivered`. Defaults track the
# original cmd_run definitions further down.
SCAFFOLD_DELIVERY_LEDGER="${DISPATCH_SELF_TEST_DELIVERY_LEDGER:-$HOME/.local/state/flywheel/dispatch-self-test-delivery-identity.jsonl}"
SCAFFOLD_DISPATCH_LOG="${DISPATCH_SELF_TEST_DISPATCH_LOG:-$_SCAFFOLD_REPO_ROOT/.flywheel/dispatch-log.jsonl}"
SCAFFOLD_LOCK_DIR="${DISPATCH_SELF_TEST_LOCK_DIR:-$HOME/.local/state/flywheel/dispatch-self-test-locks}"

scaffold_usage() {
  cat <<'USG'
usage: dispatch-self-test-delivery-identity.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "dispatch-self-test-delivery-identity.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "dispatch-self-test-delivery-identity.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"dispatch-self-test-delivery-identity.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"dispatch-self-test-delivery-identity.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"dispatch-self-test-delivery-identity.sh doctor --json"}'
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
    delivery-row|default)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg log "$SCAFFOLD_DELIVERY_LEDGER" \
        '{schema_version:$sv,command:"schema",surface:"delivery-row",
          format:"jsonl",path:$log,
          required_fields:["schema_version","event","ts","idempotency_key","callback_delivery_verified"],
          event_enum:["delivery_confirmed"],
          idempotency_key_pattern:"^sha256:[0-9a-f]{64}$",
          appended_by:"cmd_run mark-delivered subcommand"}' ;;
    run)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"run",
          subcommands:["pretest","verify-identity","mark-delivered"],
          verdict_enum:["proceed","refuse_duplicate","refuse_complete","refuse_in_flight"],
          terminal_envelope_fields:["schema_version","ts","idempotency_key","verdict","prior_dispatch","reason"]}' ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,status:"unknown_surface",known_surfaces:["delivery-row","run"]}' ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  # Single-printf per topic (gl7om SIGPIPE/pipefail discipline).
  case "$topic" in
    run)
      printf 'topic: run — `dispatch-self-test-delivery-identity.sh {pretest|verify-identity|mark-delivered} ...` enforces dispatch identity discipline. pretest probes the dispatch packet; verify-identity checks dispatch_log for prior delivery; mark-delivered appends a delivery_confirmed row to %s. Verdicts: proceed | refuse_duplicate | refuse_complete | refuse_in_flight.\n' "$SCAFFOLD_DELIVERY_LEDGER"
      ;;
    doctor)
      printf 'topic: doctor — probes the substrate this delivery-identity gate depends on: jq, python3, dispatch_log readability, delivery_ledger directory writability, lock_dir writability. Emits {checks:[{check,status:ok|fail|warn,detail}],status}.\n'
      ;;
    health)
      printf 'topic: health — summarizes the delivery ledger: total_rows, delivery_confirmed_count, last_event, last_ts, freshness_seconds. status: ok | empty | not_initialized.\n'
      ;;
    repair)
      printf 'topic: repair — scopes: ledger_dir (ensure delivery_ledger directory exists), lock_dir (ensure lock_dir exists), none (no-op probe). Default --dry-run; --apply requires --idempotency-key. Dry-run emits planned_actions; apply emits applied_actions + idempotent_no_op flag.\n'
      ;;
    validate)
      printf 'topic: validate — subjects: delivery-row (each row has schema_version, event=delivery_confirmed, ts ISO8601, idempotency_key matching ^sha256:[0-9a-f]{64}$, callback_delivery_verified=true).\n'
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
            && cli_emit_completion_bash "dispatch-self-test-delivery-identity" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "dispatch-self-test-delivery-identity" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
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
    jq -nc --arg c "$name" --arg s "$status" --arg d "$detail" '{check:$c,status:$s,detail:$d}'
  }

  # 1. jq
  if command -v jq >/dev/null 2>&1; then
    checks_jsonl+="$(emit_check jq ok "$(command -v jq)")"$'\n'
  else
    checks_jsonl+="$(emit_check jq fail "jq not on PATH")"$'\n'
  fi

  # 2. python3 (cmd_run depends on it)
  if command -v python3 >/dev/null 2>&1; then
    checks_jsonl+="$(emit_check python3 ok "$(command -v python3)")"$'\n'
  else
    checks_jsonl+="$(emit_check python3 fail "python3 not on PATH (required by cmd_run)")"$'\n'
  fi

  # 3. dispatch_log readable when present (absent-ok on fresh installs)
  if [[ -f "$SCAFFOLD_DISPATCH_LOG" ]]; then
    if [[ -r "$SCAFFOLD_DISPATCH_LOG" ]]; then
      checks_jsonl+="$(emit_check dispatch_log ok "readable: $SCAFFOLD_DISPATCH_LOG")"$'\n'
    else
      checks_jsonl+="$(emit_check dispatch_log fail "exists but not readable: $SCAFFOLD_DISPATCH_LOG")"$'\n'
    fi
  else
    checks_jsonl+="$(emit_check dispatch_log warn "absent (verify-identity will fail-open): $SCAFFOLD_DISPATCH_LOG")"$'\n'
  fi

  # 4. delivery_ledger directory writable / absent-creatable
  local ledger_dir
  ledger_dir="$(dirname -- "$SCAFFOLD_DELIVERY_LEDGER")"
  if [[ -d "$ledger_dir" && -w "$ledger_dir" ]]; then
    checks_jsonl+="$(emit_check delivery_ledger_dir ok "$ledger_dir")"$'\n'
  elif [[ ! -e "$ledger_dir" ]]; then
    checks_jsonl+="$(emit_check delivery_ledger_dir warn "absent (mark-delivered will create): $ledger_dir")"$'\n'
  else
    checks_jsonl+="$(emit_check delivery_ledger_dir fail "exists but not writable: $ledger_dir")"$'\n'
  fi

  # 5. lock_dir writable / absent-creatable
  if [[ -d "$SCAFFOLD_LOCK_DIR" && -w "$SCAFFOLD_LOCK_DIR" ]]; then
    checks_jsonl+="$(emit_check lock_dir ok "$SCAFFOLD_LOCK_DIR")"$'\n'
  elif [[ ! -e "$SCAFFOLD_LOCK_DIR" ]]; then
    checks_jsonl+="$(emit_check lock_dir warn "absent (created on first lock acquisition): $SCAFFOLD_LOCK_DIR")"$'\n'
  else
    checks_jsonl+="$(emit_check lock_dir fail "exists but not writable: $SCAFFOLD_LOCK_DIR")"$'\n'
  fi

  local ts
  ts="$(cli_iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf '%s' "$checks_jsonl" | jq -sc \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg status "$overall" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$status,checks:.}'
}

scaffold_cmd_health() {
  local ts now_epoch
  ts="$(cli_iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  now_epoch="$(date -u +%s)"

  if [[ ! -e "$SCAFFOLD_DELIVERY_LEDGER" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg path "$SCAFFOLD_DELIVERY_LEDGER" \
      '{schema_version:$sv,command:"health",ts:$ts,status:"not_initialized",delivery_ledger_path:$path,total_rows:0}'
    return 0
  fi

  local total_rows
  total_rows="$(wc -l <"$SCAFFOLD_DELIVERY_LEDGER" 2>/dev/null | tr -d ' ' || printf '0')"
  total_rows="${total_rows:-0}"

  if [[ "$total_rows" -eq 0 ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg path "$SCAFFOLD_DELIVERY_LEDGER" \
      '{schema_version:$sv,command:"health",ts:$ts,status:"empty",delivery_ledger_path:$path,total_rows:0}'
    return 0
  fi

  local last_row last_ts last_event delivery_confirmed_count last_epoch freshness_seconds
  last_row="$(tail -n1 "$SCAFFOLD_DELIVERY_LEDGER" 2>/dev/null || printf '')"
  last_ts="$(printf '%s' "$last_row" | jq -r '.ts // ""' 2>/dev/null || printf '')"
  last_event="$(printf '%s' "$last_row" | jq -r '.event // ""' 2>/dev/null || printf '')"
  delivery_confirmed_count="$({ grep -c '"event":"delivery_confirmed"' "$SCAFFOLD_DELIVERY_LEDGER" 2>/dev/null || true; } | tr -d ' \n')"
  delivery_confirmed_count="${delivery_confirmed_count:-0}"

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
    --arg path "$SCAFFOLD_DELIVERY_LEDGER" \
    --argjson total_rows "$total_rows" \
    --argjson delivery_confirmed_count "$delivery_confirmed_count" \
    --arg last_event "$last_event" \
    --arg last_ts "$last_ts" \
    --argjson freshness_seconds "$freshness_seconds" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,delivery_ledger_path:$path,
      total_rows:$total_rows,delivery_confirmed_count:$delivery_confirmed_count,
      last_event:$last_event,last_ts:$last_ts,freshness_seconds:$freshness_seconds}'
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
  ledger_dir="$(dirname -- "$SCAFFOLD_DELIVERY_LEDGER")"

  case "$scope" in
    ledger_dir|lock_dir)
      local target_dir
      if [[ "$scope" == "ledger_dir" ]]; then target_dir="$ledger_dir"; else target_dir="$SCAFFOLD_LOCK_DIR"; fi
      if [[ "$mode" == "dry_run" ]]; then
        local actions_jsonl=""
        if [[ ! -d "$target_dir" ]]; then
          actions_jsonl+="$(jq -nc --arg p "$target_dir" --arg s "$scope" '{action:"mkdir_p",path:$p,scope:$s,reason:"directory absent"}')"$'\n'
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
      if [[ ! -d "$target_dir" ]]; then
        if mkdir -p "$target_dir" 2>/dev/null; then
          applied_jsonl+="$(jq -nc --arg p "$target_dir" '{action:"mkdir_p",path:$p,result:"created"}')"$'\n'
          idempotent_no_op=false
        else
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg scope "$scope" --arg dir "$target_dir" --arg idem "$idem_key" \
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
        '{schema_version:$sv,command:"repair",ts:$ts,status:"refused",mode:$mode,reason:"--scope <ledger_dir|lock_dir|none> required"}'
      return 64
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg scope "$scope" --arg mode "$mode" \
        '{schema_version:$sv,command:"repair",ts:$ts,status:"refused",mode:$mode,scope:$scope,reason:"unknown scope",known_scopes:["ledger_dir","lock_dir","none"]}'
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
    delivery-row|"")
      subject="delivery-row"
      if [[ ! -e "$SCAFFOLD_DELIVERY_LEDGER" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg subject "$subject" --arg path "$SCAFFOLD_DELIVERY_LEDGER" \
          '{schema_version:$sv,command:"validate",ts:$ts,subject:$subject,delivery_ledger_path:$path,status:"empty",results:[],pass:0,fail:0}'
        return 0
      fi
      local lineno=0 pass=0 fail=0 results_jsonl="" row_pass row_offending line
      while IFS= read -r line || [[ -n "$line" ]]; do
        lineno=$((lineno + 1))
        [[ -z "$line" ]] && continue
        row_pass=true
        row_offending="none"
        if printf '%s' "$line" | jq -e '
          (has("schema_version") and (.schema_version | type == "string"))
          and (has("event") and (.event | type == "string"))
          and (has("ts") and (.ts | type == "string") and (.ts | test("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$")))
          and (has("idempotency_key") and (.idempotency_key | type == "string") and (.idempotency_key | test("^sha256:[0-9a-f]{64}$")))
          and (has("callback_delivery_verified") and (.callback_delivery_verified == true))
        ' >/dev/null 2>&1; then
          # Cross-field invariant: delivery_confirmed event implies callback_delivery_verified=true.
          if ! printf '%s' "$line" | jq -e 'if .event == "delivery_confirmed" then (.callback_delivery_verified == true) else true end' >/dev/null 2>&1; then
            row_pass=false
            row_offending="delivery_confirmed_without_verified_flag"
          fi
        else
          row_pass=false
          row_offending="missing_or_malformed_required_field"
        fi
        if $row_pass; then pass=$((pass + 1)); else fail=$((fail + 1)); fi
        results_jsonl+="$(jq -nc --argjson lineno "$lineno" --arg pass "$row_pass" --arg offending "$row_offending" \
          '{lineno:$lineno,pass:($pass=="true"),offending_field:$offending}')"$'\n'
      done <"$SCAFFOLD_DELIVERY_LEDGER"

      local status="ok"
      if [[ "$fail" -gt 0 ]]; then status="fail"; fi
      printf '%s' "$results_jsonl" | jq -sc \
        --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg subject "$subject" --arg path "$SCAFFOLD_DELIVERY_LEDGER" \
        --arg status "$status" --argjson pass "$pass" --argjson fail "$fail" \
        '{schema_version:$sv,command:"validate",ts:$ts,subject:$subject,delivery_ledger_path:$path,status:$status,pass:$pass,fail:$fail,results:.}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg subject "$subject" \
        '{schema_version:$sv,command:"validate",ts:$ts,subject:$subject,status:"unknown_subject",known_subjects:["delivery-row"]}'
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
      -h|--help) scaffold_emit_topic_help audit 2>/dev/null || printf 'topic: audit — tail delivery ledger\n'; return 0 ;;
      *) shift ;;
    esac
  done

  if command -v cli_emit_audit_tail >/dev/null 2>&1; then
    # helper signature: cli_emit_audit_tail <log_path> <schema_version> [<limit>]
    cli_emit_audit_tail "$SCAFFOLD_DELIVERY_LEDGER" "$SCAFFOLD_SCHEMA_VERSION" "$tail_n"
    return 0
  fi

  local ts
  ts="$(cli_iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  if [[ ! -e "$SCAFFOLD_DELIVERY_LEDGER" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$SCAFFOLD_DELIVERY_LEDGER" --argjson tail_n "$tail_n" \
      '{schema_version:$sv,command:"audit",ts:$ts,audit_log:$log,status:"not_initialized",tail_n:$tail_n,rows:[]}'
    return 0
  fi
  local rows_jsonl
  rows_jsonl="$(tail -n "$tail_n" "$SCAFFOLD_DELIVERY_LEDGER" 2>/dev/null || printf '')"
  if [[ -z "$rows_jsonl" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$SCAFFOLD_DELIVERY_LEDGER" --argjson tail_n "$tail_n" \
      '{schema_version:$sv,command:"audit",ts:$ts,audit_log:$log,status:"empty",tail_n:$tail_n,rows:[]}'
  else
    printf '%s\n' "$rows_jsonl" | jq -sc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$SCAFFOLD_DELIVERY_LEDGER" --argjson tail_n "$tail_n" \
      '{schema_version:$sv,command:"audit",ts:$ts,audit_log:$log,status:"ok",tail_n:$tail_n,row_count:length,rows:.}'
  fi
}

scaffold_cmd_why() {
  local id="${1:-}"
  if [[ -z "$id" ]]; then
    printf 'ERR: why requires <id> argument (idempotency_key like sha256:<64-hex>, or delivery row ts, or 1-based row index)\n' >&2
    return 64
  fi
  local ts
  ts="$(cli_iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"

  if [[ ! -e "$SCAFFOLD_DELIVERY_LEDGER" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_DELIVERY_LEDGER" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"unavailable",delivery_ledger_path:$log,reason:"delivery ledger absent (no deliveries recorded yet)"}'
    return 0
  fi

  # Resolution order: numeric row index → idempotency_key exact → ts exact.
  local row="" resolution=""
  if [[ "$id" =~ ^[0-9]+$ ]]; then
    row="$(sed -n "${id}p" "$SCAFFOLD_DELIVERY_LEDGER" 2>/dev/null || true)"
    [[ -n "$row" ]] && resolution="row_index"
  fi
  if [[ -z "$row" ]]; then
    row="$(jq -c --arg id "$id" 'select(.idempotency_key == $id)' "$SCAFFOLD_DELIVERY_LEDGER" 2>/dev/null | head -n1 || true)"
    [[ -n "$row" ]] && resolution="idempotency_key_exact"
  fi
  if [[ -z "$row" ]]; then
    row="$(jq -c --arg id "$id" 'select(.ts == $id)' "$SCAFFOLD_DELIVERY_LEDGER" 2>/dev/null | head -n1 || true)"
    [[ -n "$row" ]] && resolution="ts_exact"
  fi

  if [[ -n "$row" ]]; then
    printf '%s' "$row" | jq -c \
      --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_DELIVERY_LEDGER" --arg resolution "$resolution" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"found",delivery_ledger_path:$log,resolution:$resolution,row:.,
        provenance:{event:.event,idempotency_key:.idempotency_key,callback_delivery_verified:.callback_delivery_verified}}'
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_DELIVERY_LEDGER" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"not_found",delivery_ledger_path:$log,reason:"no delivery row matched by row-index, idempotency_key, or ts"}'
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
VERSION="dispatch-self-test-delivery-identity/v1"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
DISPATCH_LOG="${DISPATCH_SELF_TEST_DISPATCH_LOG:-$ROOT/.flywheel/dispatch-log.jsonl}"
DELIVERY_LEDGER="${DISPATCH_SELF_TEST_DELIVERY_LEDGER:-$HOME/.local/state/flywheel/dispatch-self-test-delivery-identity.jsonl}"
LOCK_DIR="${DISPATCH_SELF_TEST_LOCK_DIR:-$HOME/.local/state/flywheel/dispatch-self-test-locks}"
CMD="" PACKET="" KEY="" QUIET=0

usage() {
  cat <<'USAGE'
usage: dispatch-self-test-delivery-identity.sh pretest --packet PATH [--dispatch-log PATH] [--lock-dir PATH] [--json] [--quiet]
       dispatch-self-test-delivery-identity.sh verify-identity --idempotency-key KEY --dispatch-log PATH [--json] [--quiet]
       dispatch-self-test-delivery-identity.sh mark-delivered --idempotency-key KEY [--ledger PATH] [--lock-dir PATH] [--json] [--quiet]
       dispatch-self-test-delivery-identity.sh --info|--help|--examples [--json]
USAGE
}

info() {
  jq -nc --arg version "$VERSION" --arg dispatch_log "$DISPATCH_LOG" --arg ledger "$DELIVERY_LEDGER" --arg lock_dir "$LOCK_DIR" '{
    name:"dispatch-self-test-delivery-identity",
    schema_version:$version,
    subcommands:["pretest","verify-identity","mark-delivered"],
    canonical_cli_flags:["--info","--help","--examples","--json","--quiet"],
    verdicts:["proceed","refuse_duplicate","refuse_complete","refuse_in_flight"],
    dispatch_log:$dispatch_log,
    delivery_ledger:$ledger,
    lock_dir:$lock_dir
  }'
}

examples() {
  jq -nc '{examples:[
    "dispatch-self-test-delivery-identity.sh pretest --packet /tmp/dispatch.md --json",
    "dispatch-self-test-delivery-identity.sh verify-identity --idempotency-key sha256:... --dispatch-log .flywheel/dispatch-log.jsonl --json",
    "dispatch-self-test-delivery-identity.sh mark-delivered --idempotency-key sha256:... --json"
  ]}'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    pretest|verify-identity|mark-delivered) CMD="$1"; shift ;;
    --packet) PACKET="${2:?--packet requires PATH}"; shift 2 ;;
    --packet=*) PACKET="${1#*=}"; shift ;;
    --idempotency-key) KEY="${2:?--idempotency-key requires KEY}"; shift 2 ;;
    --idempotency-key=*) KEY="${1#*=}"; shift ;;
    --dispatch-log) DISPATCH_LOG="${2:?--dispatch-log requires PATH}"; shift 2 ;;
    --dispatch-log=*) DISPATCH_LOG="${1#*=}"; shift ;;
    --ledger) DELIVERY_LEDGER="${2:?--ledger requires PATH}"; shift 2 ;;
    --ledger=*) DELIVERY_LEDGER="${1#*=}"; shift ;;
    --lock-dir) LOCK_DIR="${2:?--lock-dir requires PATH}"; shift 2 ;;
    --lock-dir=*) LOCK_DIR="${1#*=}"; shift ;;
    --json) shift ;;
    --quiet) QUIET=1; shift ;;
    --info) info; exit 0 ;;
    --examples) examples; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'ERR unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ -n "$CMD" ]] || { usage >&2; exit 2; }

python3 - "$CMD" "$PACKET" "$KEY" "$DISPATCH_LOG" "$DELIVERY_LEDGER" "$LOCK_DIR" "$QUIET" <<'PY'
import hashlib, json, re, sys
from datetime import datetime, timezone
from pathlib import Path

VERSION = "dispatch-self-test-delivery-identity/v1"
cmd, packet, key, dispatch_log, delivery_ledger, lock_dir, quiet = sys.argv[1:8]
def ts():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
def norm_key(value):
    value = str(value or "").strip().strip("`'\"")
    if re.fullmatch(r"sha256:[0-9a-f]{64}", value):
        return value
    if re.fullmatch(r"[0-9a-f]{64}", value):
        return "sha256:" + value
    return None
def out(verdict, key_value, prior, reason, extra=None, rc=0):
    payload = {
        "schema_version": VERSION,
        "ts": ts(),
        "idempotency_key": key_value,
        "verdict": verdict,
        "prior_dispatch": prior,
        "reason": reason,
    }
    if extra:
        payload.update(extra)
    if quiet != "1":
        print(json.dumps(payload, separators=(",", ":")))
    raise SystemExit(rc)
def packet_identity(path):
    p = Path(path)
    if not p.exists() or not p.is_file():
        out("refuse_duplicate", None, None, f"malformed dispatch packet: not readable: {path}", rc=2)
    text = p.read_text(encoding="utf-8", errors="replace")
    if not text.strip():
        out("refuse_duplicate", None, None, "malformed dispatch packet: empty", rc=2)
    task = re.search(r"(?im)^(?:task[ _-]?id|Task ID):\s*`?([^`\n]+?)`?\s*$", text)
    target = re.search(r"(?im)^To:\s*([^\n]+?)\s*$", text)
    if not task or not target:
        out("refuse_duplicate", None, None, "malformed dispatch packet: missing Task ID or To", rc=2)
    explicit = re.search(r"(?i)\bidempotency[_-]?key\b\s*[:=]\s*`?([A-Za-z0-9:._-]+)`?", text)
    if explicit:
        parsed = norm_key(explicit.group(1))
        if not parsed:
            out("refuse_duplicate", None, None, "malformed dispatch packet: invalid idempotency_key", rc=2)
        return parsed, task.group(1).strip(), text
    basis = "\n".join([task.group(1).strip(), target.group(1).strip(), text])
    return "sha256:" + hashlib.sha256(basis.encode("utf-8")).hexdigest(), task.group(1).strip(), text
def iter_rows(path):
    p = Path(path).expanduser()
    if not p.exists():
        return
    with p.open(encoding="utf-8", errors="replace") as handle:
        for line_no, line in enumerate(handle, 1):
            if not line.strip():
                continue
            try:
                row = json.loads(line)
            except Exception:
                continue
            yield line_no, row
def has_key(obj, key_value):
    if isinstance(obj, dict):
        for k, v in obj.items():
            if k in {"idempotency_key", "dispatch_identity_key", "delivery_identity_key", "packet_hash", "replay_detection_hash"} and norm_key(v) == key_value:
                return True
            if has_key(v, key_value):
                return True
    elif isinstance(obj, list):
        return any(has_key(v, key_value) for v in obj)
    return False
def lookup(path, key_value):
    prior = None
    for line_no, row in iter_rows(path) or []:
        if not has_key(row, key_value):
            continue
        if prior is None:
            prior = {"task_id": None, "ts": None, "callback_received_at": None, "callback_delivery_verified": False}
        prior["task_id"] = row.get("task_id") or prior["task_id"]
        prior["ts"] = row.get("ts") or row.get("created_ts") or prior["ts"]
        if row.get("callback_received_at"):
            prior["callback_received_at"] = row.get("callback_received_at")
        if row.get("event") == "callback_received" or row.get("status") == "DONE":
            prior["callback_received_at"] = row.get("ts") or row.get("created_ts") or prior["callback_received_at"]
        if row.get("callback_delivery_verified") is True or row.get("event") == "callback_delivery_verified":
            prior["callback_delivery_verified"] = True
        prior["dispatch_log_ref"] = f"{path}#L{line_no}"
    return prior
def verdict_for(prior):
    if prior is None:
        return "proceed", "dispatch identity not present in dispatch log"
    if prior.get("callback_received_at") and prior.get("callback_delivery_verified") is True:
        return "refuse_complete", "prior dispatch completed and delivery was verified"
    if not prior.get("task_id") and not prior.get("ts"):
        return "refuse_duplicate", "prior identity row exists but cannot be classified"
    return "refuse_in_flight", "prior dispatch exists without verified callback delivery"
def lock_path(key_value, prefix=""):
    safe = key_value.replace("sha256:", "")
    return Path(lock_dir).expanduser() / f"{prefix}{safe}.lock"
if cmd == "verify-identity":
    k = norm_key(key)
    if not k:
        out("refuse_duplicate", None, None, "invalid idempotency_key", rc=2)
    prior = lookup(dispatch_log, k)
    verdict, reason = verdict_for(prior)
    out(verdict, k, prior, reason)
if cmd == "pretest":
    k, task_id, body = packet_identity(packet)
    prior = lookup(dispatch_log, k)
    verdict, reason = verdict_for(prior)
    if verdict != "proceed":
        out(verdict, k, prior, reason, rc=1)
    Path(lock_dir).expanduser().mkdir(parents=True, exist_ok=True)
    lp = lock_path(k)
    try:
        lp.mkdir()
        (lp / "packet").write_text(packet + "\n", encoding="utf-8")
        (lp / "task_id").write_text(task_id + "\n", encoding="utf-8")
    except FileExistsError:
        out("refuse_in_flight", k, None, "dispatch identity lock already held", {"lock_path": str(lp)}, rc=1)
    out("proceed", k, None, reason, {"lock_path": str(lp)})
if cmd == "mark-delivered":
    k = norm_key(key)
    if not k:
        out("refuse_duplicate", None, None, "invalid idempotency_key", rc=2)
    prior = lookup(delivery_ledger, k)
    if prior and prior.get("callback_delivery_verified"):
        out("refuse_complete", k, prior, "delivery already confirmed", {"ledger_written": False})
    Path(delivery_ledger).expanduser().parent.mkdir(parents=True, exist_ok=True)
    Path(lock_dir).expanduser().mkdir(parents=True, exist_ok=True)
    mlp = lock_path(k, "mark-")
    try:
        mlp.mkdir()
    except FileExistsError:
        out("refuse_in_flight", k, None, "delivery confirmation lock already held", {"ledger_written": False}, rc=1)
    try:
        prior = lookup(delivery_ledger, k)
        if prior and prior.get("callback_delivery_verified"):
            out("refuse_complete", k, prior, "delivery already confirmed", {"ledger_written": False})
        row = {"schema_version": VERSION, "event": "delivery_confirmed", "ts": ts(), "idempotency_key": k, "callback_delivery_verified": True}
        with Path(delivery_ledger).expanduser().open("a", encoding="utf-8") as handle:
            handle.write(json.dumps(row, separators=(",", ":")) + "\n")
        pre_lock = lock_path(k)
        if pre_lock.exists():
            for child in pre_lock.iterdir():
                child.unlink()
            pre_lock.rmdir()
        out("proceed", k, None, "delivery confirmed event appended", {"ledger_written": True, "ledger": delivery_ledger})
    finally:
        if mlp.exists():
            mlp.rmdir()

out("refuse_duplicate", None, None, f"unknown command: {cmd}", rc=2)
PY

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-20-cross-orch-handoff.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-100-contention-shaped-state-owner.md`
