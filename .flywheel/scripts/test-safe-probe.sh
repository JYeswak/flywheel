#!/usr/bin/env bash
set -euo pipefail


# ====== BEGIN canonical-cli scaffold (bead flywheel-ws02m) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (TODO markers in stubs need fill-in)
# doctor-mode-tier: scaffolded (bead flywheel-ws02m)
#
# This block is APPENDED by scaffold-canonical-cli.sh. The original
# top-level dispatch is preserved as `cmd_run` (the new main routes
# default invocation through cmd_run for backward compat). Surface-
# specific logic stays as scaffold-marker stubs — fillin replaces them with concrete impls.

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="test-safe-probe/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/test-safe-probe-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: test-safe-probe.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "test-safe-probe.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "test-safe-probe.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"test-safe-probe.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"test-safe-probe.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"test-safe-probe.sh doctor --json"}'
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
        '{schema_version:$sv,command:"schema",surface:$surface,fields:["ts","status","audit_log","stale_seconds","last_row?"]}' ;;
    repair)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,scopes:["audit-log-rotate","tmp-leftover-prune"],fields:["status","mode","scope","idempotency_key?","rotated?","leftovers_pruned?"]}' ;;
    validate)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,subjects:["row","schema","config","safe-probe-companion","tmpdir-policy"],fields:["status","subject","valid?","missing?","reason?","safe_probe_path?","tmpdir?"]}' ;;
    audit)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:["audit_log","row_count","rows[]"]}' ;;
    why)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:["id","status","matches[]"],id_pattern:"test-name|fake-secret-class|tmp-path"}' ;;
    audit-row)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,required:["ts","command","schema_version"],optional:["test_name","rc","expected_rc"]}' ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,note:"test-safe-probe: regression test for safe-probe.sh — creates tmp dirs with FAKE secrets + asserts no leak in stdout/stderr captures"}' ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — bare invocation runs regression test for safe-probe.sh; creates tmp dirs with FAKE GITHUB/INFISICAL tokens; asserts no fake-token leak in any safe-probe stdout/stderr. Exits 77 if rg missing (skip).\n' ;;
    doctor)   printf 'topic: doctor — probes substrate: rg, safe-probe.sh companion exists+executable, mktemp, jq, grep, TMPDIR writable.\n' ;;
    health)   printf 'topic: health — tails audit log; warn stale >7d (test runner is operator-triggered, not periodic).\n' ;;
    repair)   printf 'topic: repair — scopes: audit-log-rotate (>5MB → mv .ts), tmp-leftover-prune (>1d secret-safe-test.* tmp dirs from prior runs that leaked through traps).\n' ;;
    validate) printf 'topic: validate — subjects: --row-json JSON, --schema, --config, --safe-probe-companion (probes safe-probe.sh existence + executable bit), --tmpdir-policy (probes TMPDIR writable + cleanup hygiene).\n' ;;
    *)        printf 'topics: run | doctor | health | repair | validate\n' ;;
  esac
}

scaffold_emit_completion() {
  local shell="${1:-bash}"
  case "$shell" in
    -h|--help) scaffold_emit_topic_help completion 2>/dev/null \
                 || printf 'topic: completion <bash|zsh> — emit shell completion script\n'
               return 0 ;;
    bash) command -v cli_emit_completion_bash >/dev/null \
            && cli_emit_completion_bash "test-safe-probe" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "test-safe-probe" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  # Substrate: rg (required for cmd_run, else exit 77), safe-probe.sh companion,
  # mktemp + grep + jq, TMPDIR writable.
  local script_dir; script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
  local safe_probe="$script_dir/safe-probe.sh"
  local tmpdir="${TMPDIR:-/tmp}"
  local checks="" overall="pass"

  if command -v rg >/dev/null 2>&1; then
    checks+="$(jq -nc --arg p "$(command -v rg)" '{name:"rg_on_path",status:"pass",value:$p}')"$'\n'
  else
    checks+="$(jq -nc '{name:"rg_on_path",status:"fail",detail:"ripgrep required for safe-probe regression (cmd_run exits 77 SKIP otherwise)"}')"$'\n'
    overall="fail"
  fi

  if [[ -x "$safe_probe" ]]; then
    checks+="$(jq -nc --arg p "$safe_probe" '{name:"safe_probe_companion",status:"pass",value:$p}')"$'\n'
  else
    checks+="$(jq -nc --arg p "$safe_probe" '{name:"safe_probe_companion",status:"fail",value:$p,detail:"target script under test is missing or not executable"}')"$'\n'
    overall="fail"
  fi

  if command -v mktemp >/dev/null 2>&1; then
    checks+="$(jq -nc --arg p "$(command -v mktemp)" '{name:"mktemp_on_path",status:"pass",value:$p}')"$'\n'
  else
    checks+="$(jq -nc '{name:"mktemp_on_path",status:"fail"}')"$'\n'
    overall="fail"
  fi

  if command -v jq >/dev/null 2>&1; then
    checks+="$(jq -nc --arg p "$(command -v jq)" '{name:"jq_on_path",status:"pass",value:$p}')"$'\n'
  else
    checks+="$(jq -nc '{name:"jq_on_path",status:"fail"}')"$'\n'
    overall="fail"
  fi

  if [[ -d "$tmpdir" && -w "$tmpdir" ]]; then
    checks+="$(jq -nc --arg p "$tmpdir" '{name:"tmpdir_writable",status:"pass",value:$p}')"$'\n'
  else
    checks+="$(jq -nc --arg p "$tmpdir" '{name:"tmpdir_writable",status:"fail",value:$p}')"$'\n'
    overall="fail"
  fi

  local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf '%s' "$checks" | jq -sc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg status "$overall" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$status,checks:.}'
}

scaffold_cmd_health() {
  local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  local log="$SCAFFOLD_AUDIT_LOG"
  local last_row="null" stale_seconds=-1 status="warn"
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
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$log" \
    --arg status "$status" --argjson stale "$stale_seconds" --argjson row "$last_row" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,audit_log:$log,stale_seconds:$stale,last_row:$row}'
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
    tmp-leftover-prune)
      # The test creates mktemp -d secret-safe-test.XXXXXX + secret-safe-captures.XXXXXX dirs
      # with a `trap rm -rf` cleanup. If a prior test process was killed before trap fired,
      # the dirs leak. This scope prunes leftover tmp dirs older than 1 day.
      local tmpdir="${TMPDIR:-/tmp}"
      local leftover_count=0 pruned_count=0
      leftover_count="$(find "$tmpdir" -maxdepth 1 -type d \( -name 'secret-safe-test.*' -o -name 'secret-safe-captures.*' \) -mtime +1 2>/dev/null | wc -l | tr -d ' ' || echo 0)"
      if [[ "$mode" == "apply" && "$leftover_count" -gt 0 ]]; then
        while IFS= read -r d; do
          [[ -n "$d" && -d "$d" ]] && rm -rf "$d" 2>/dev/null && pruned_count=$((pruned_count + 1))
        done < <(find "$tmpdir" -maxdepth 1 -type d \( -name 'secret-safe-test.*' -o -name 'secret-safe-captures.*' \) -mtime +1 2>/dev/null)
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" \
        --arg idem "$idem_key" --arg td "$tmpdir" \
        --argjson lc "$leftover_count" --argjson pc "$pruned_count" \
        '{schema_version:$sv,command:"repair",status:"pass",mode:$mode,scope:$scope,idempotency_key:$idem,tmpdir:$td,leftover_count:$lc,leftovers_pruned:$pc,stale_threshold_days:1}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" --arg idem "$idem_key" \
        '{schema_version:$sv,command:"repair",status:"unknown_scope",mode:$mode,scope:$scope,idempotency_key:$idem,known_scopes:["audit-log-rotate","tmp-leftover-prune"]}'
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
      --safe-probe-companion) subject="safe-probe-companion"; shift ;;
      --tmpdir-policy) subject="tmpdir-policy"; shift ;;
      --json) shift ;;
      *) printf 'ERR: unknown validate arg %s\n' "$1" >&2; return 64 ;;
    esac
  done
  local script_dir; script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
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
      for f in ts command schema_version; do
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
      local rg_ok=false sp_ok=false mk_ok=false jq_ok=false
      command -v rg >/dev/null 2>&1 && rg_ok=true
      [[ -x "$script_dir/safe-probe.sh" ]] && sp_ok=true
      command -v mktemp >/dev/null 2>&1 && mk_ok=true
      command -v jq >/dev/null 2>&1 && jq_ok=true
      local overall=pass
      [[ "$rg_ok" != true || "$sp_ok" != true || "$mk_ok" != true || "$jq_ok" != true ]] && overall=fail
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$overall" \
        --argjson rg "$rg_ok" --argjson sp "$sp_ok" --argjson mk "$mk_ok" --argjson jqq "$jq_ok" \
        '{schema_version:$sv,command:"validate",subject:"config",status:$s,rg_present:$rg,safe_probe_present:$sp,mktemp_present:$mk,jq_present:$jqq}'
      ;;
    safe-probe-companion)
      # test-safe-probe-specific: probes safe-probe.sh existence + exec bit + lines.
      local safe_probe="$script_dir/safe-probe.sh"
      local present=false executable=false lines=0
      [[ -r "$safe_probe" ]] && present=true && lines="$(wc -l < "$safe_probe" 2>/dev/null | tr -d ' ' || echo 0)"
      [[ -x "$safe_probe" ]] && executable=true
      local status="pass"
      [[ "$present" != true || "$executable" != true ]] && status="fail"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$status" --arg p "$safe_probe" \
        --argjson present "$present" --argjson exec "$executable" --argjson l "$lines" \
        '{schema_version:$sv,command:"validate",subject:"safe-probe-companion",status:$s,safe_probe_path:$p,present:$present,executable:$exec,lines:$l}'
      ;;
    tmpdir-policy)
      # test-safe-probe-specific: TMPDIR writable + count of leftover test dirs.
      local tmpdir="${TMPDIR:-/tmp}"
      local writable=false leftover_count=0
      [[ -d "$tmpdir" && -w "$tmpdir" ]] && writable=true
      leftover_count="$(find "$tmpdir" -maxdepth 1 -type d \( -name 'secret-safe-test.*' -o -name 'secret-safe-captures.*' \) 2>/dev/null | wc -l | tr -d ' ' || echo 0)"
      local status="pass"
      [[ "$writable" != true ]] && status="fail"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$status" --arg td "$tmpdir" \
        --argjson w "$writable" --argjson lc "$leftover_count" \
        '{schema_version:$sv,command:"validate",subject:"tmpdir-policy",status:$s,tmpdir:$td,writable:$w,leftover_test_dirs:$lc}'
      ;;
    "")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",status:"pass",subjects:["row","schema","config","safe-probe-companion","tmpdir-policy"],usage:"validate --row-json JSON or --schema or --config or --safe-probe-companion or --tmpdir-policy"}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$subject" \
        '{schema_version:$sv,command:"validate",subject:$s,status:"unknown_subject",known:["row","schema","config","safe-probe-companion","tmpdir-policy"]}'
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
  if [[ -r "$SCAFFOLD_AUDIT_LOG" ]]; then
    matches="$(grep -F "$id" "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | jq -sc '. // []' 2>/dev/null || echo '[]')"
    local n; n="$(printf '%s' "$matches" | jq 'length' 2>/dev/null || echo 0)"
    [[ "$n" -gt 0 ]] && status="found"
  else
    status="unavailable"
  fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" --arg s "$status" \
    --arg log "$SCAFFOLD_AUDIT_LOG" --argjson m "$matches" \
    '{schema_version:$sv,command:"why",id:$id,status:$s,audit_log:$log,matches:$m}'
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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAFE_PROBE="$SCRIPT_DIR/safe-probe.sh"

command -v rg >/dev/null 2>&1 || {
  printf 'SKIP: rg is required for safe-probe regression\n' >&2
  exit 77
}

tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/secret-safe-test.XXXXXX")"
captures="$(mktemp -d "${TMPDIR:-/tmp}/secret-safe-captures.XXXXXX")"
trap 'rm -rf "$tmp_root" "$captures"' EXIT HUP INT TERM

fake_github="FAKE_GITHUB_TOKEN_1234567890"
fake_infisical="FAKE_INFISICAL_CACHE_VALUE_1234567890"

mkdir -p "$tmp_root/normal-docs" "$tmp_root/.opencode/secrets" "$tmp_root/.config/infisical"
printf 'normal docs mention safe probe and token names only\n' > "$tmp_root/normal-docs/README.md"
printf 'GITHUB_TOKEN=%s\n' "$fake_github" > "$tmp_root/.opencode/secrets/infisical-cache.env"
printf 'INFISICAL_TOKEN=%s\n' "$fake_infisical" > "$tmp_root/.config/infisical/cubcloud-cache.env"
printf 'credential helper body: %s\n' "$fake_github" > "$tmp_root/credential-helper-output.txt"

assert_no_fake_output() {
  local file="$1"
  if grep -Fq "$fake_github" "$file" || grep -Fq "$fake_infisical" "$file"; then
    printf 'FAIL: fake token leaked in %s\n' "$file" >&2
    exit 1
  fi
}

run_expect_rc() {
  local name="$1"
  local expected="$2"
  shift 2
  local out="$captures/$name.out"
  local err="$captures/$name.err"
  local rc

  set +e
  "$@" >"$out" 2>"$err"
  rc=$?
  set -e

  assert_no_fake_output "$out"
  assert_no_fake_output "$err"

  if [ "$rc" -ne "$expected" ]; then
    printf 'FAIL: %s rc=%s expected=%s\n' "$name" "$rc" "$expected" >&2
    printf 'stderr:\n' >&2
    sed 's/^/  /' "$err" >&2
    exit 1
  fi

  printf 'PASS: %s rc=%s\n' "$name" "$rc"
}

run_expect_rc "blocked-tree-rg" 2 "$SAFE_PROBE" rg FAKE "$tmp_root"
run_expect_rc "safe-rg" 0 "$SAFE_PROBE" rg "safe probe" "$tmp_root/normal-docs"
run_expect_rc "blocked-credential-file" 2 "$SAFE_PROBE" cat "$tmp_root/credential-helper-output.txt"
run_expect_rc "blocked-env-command" 2 env FAKE_TEST_TOKEN="$fake_github" "$SAFE_PROBE" env
run_expect_rc "blocked-gh-auth-token" 2 "$SAFE_PROBE" gh auth token
run_expect_rc "env-names" 0 env FAKE_TEST_TOKEN="$fake_github" INFISICAL_CACHE_VALUE="$fake_infisical" "$SAFE_PROBE" env-names
run_expect_rc "has-env" 0 env GITHUB_TOKEN="$fake_github" "$SAFE_PROBE" has-env GITHUB_TOKEN

grep -q '^FAKE_TEST_TOKEN=SET$' "$captures/env-names.out" || {
  printf 'FAIL: env-names did not report FAKE_TEST_TOKEN status\n' >&2
  exit 1
}

grep -q '^GITHUB_TOKEN=SET$' "$captures/has-env.out" || {
  printf 'FAIL: has-env did not report GITHUB_TOKEN status\n' >&2
  exit 1
}

printf 'PASS: safe-probe synthetic regression complete\n'

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-02-conformance-fixtures.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-68-schema-executable-validator-pair.md`
