#!/usr/bin/env bash
# shellcheck disable=SC2155,SC2317
# Regression test: sync-canonical-doctrine.sh discovers + writes to every
# named stamped repo, including newly-stamped terratitle and zeststream-infra.
#
# Fixture-based — never touches real /Users/josh/Developer trees or canonical
# AGENTS.md. Locks in the bead flywheel-ngfe acceptance contract:
#   - discovery covers all 6 stamped names: alpsinsurance, mobile-eats,
#     skillos, terratitle, zeststream-infra, zesttube
#   - apply writes to every one of them
#   - re-running is idempotent (zero further drift)
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

SCAFFOLD_SCHEMA_VERSION="test-sync-stamped-repos-coverage/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/test-sync-stamped-repos-coverage-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: test-sync-stamped-repos-coverage.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "test-sync-stamped-repos-coverage.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "test-sync-stamped-repos-coverage.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"test-sync-stamped-repos-coverage.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"test-sync-stamped-repos-coverage.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"test-sync-stamped-repos-coverage.sh doctor --json"}'
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
        '{schema_version:$sv,command:"schema",surface:$surface,subjects:["row","schema","config","sync-companion","stamped-repos-coverage"],fields:["status","subject","valid?","missing?","reason?","sync_canonical_path?","expected_repos?","extra_repos?"]}' ;;
    audit)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:["audit_log","row_count","rows[]"]}' ;;
    why)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:["id","status","matches[]"],id_pattern:"test-phase|repo-name|drift-marker"}' ;;
    audit-row)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,required:["ts","command","schema_version"],optional:["phase","repo","rc"]}' ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,note:"test-sync-stamped-repos-coverage: regression test for sync-canonical-doctrine.sh — fixture-based; verifies all 6 stamped repos get discovered + written"}' ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — bare invocation runs fixture-based regression test for sync-canonical-doctrine.sh; verifies all 6 stamped repos (alpsinsurance, mobile-eats, skillos, terratitle, zeststream-infra, zesttube) are discovered + written + idempotent.\n' ;;
    doctor)   printf 'topic: doctor — probes substrate: bash, sync-canonical-doctrine.sh companion, mktemp, jq, ROOT path (/Users/josh/Developer/flywheel).\n' ;;
    health)   printf 'topic: health — tails audit log; warn stale >7d (test is operator-triggered via CI/manual).\n' ;;
    repair)   printf 'topic: repair — scopes: audit-log-rotate (>5MB → mv .ts), tmp-leftover-prune (>1d sync-stamped-repos-coverage.* tmp dirs from trap failures).\n' ;;
    validate) printf 'topic: validate — subjects: --row-json JSON, --schema, --config, --sync-companion (probes sync-canonical-doctrine.sh existence), --stamped-repos-coverage (probes 6 expected stamped repo names against real fleet).\n' ;;
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
            && cli_emit_completion_bash "test-sync-stamped-repos-coverage" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "test-sync-stamped-repos-coverage" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  # Substrate: bash, sync-canonical-doctrine.sh companion, mktemp, jq, ROOT path.
  local root="/Users/josh/Developer/flywheel"
  local sync_companion="$root/.flywheel/scripts/sync-canonical-doctrine.sh"
  local tmpdir="${TMPDIR:-/tmp}"
  local checks="" overall="pass"

  if [[ -d "$root" ]]; then
    checks+="$(jq -nc --arg p "$root" '{name:"root_path_present",status:"pass",value:$p}')"$'\n'
  else
    checks+="$(jq -nc --arg p "$root" '{name:"root_path_present",status:"fail",value:$p,detail:"hardcoded /Users/josh/Developer/flywheel missing"}')"$'\n'
    overall="fail"
  fi

  if [[ -x "$sync_companion" ]]; then
    checks+="$(jq -nc --arg p "$sync_companion" '{name:"sync_companion_executable",status:"pass",value:$p}')"$'\n'
  else
    checks+="$(jq -nc --arg p "$sync_companion" '{name:"sync_companion_executable",status:"fail",value:$p,detail:"sync-canonical-doctrine.sh missing or not executable"}')"$'\n'
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
      # cmd_run creates mktemp -d sync-stamped-repos-coverage.XXXXXX dirs with a
      # trap rm -rf cleanup. If killed before trap fires, dirs leak. Prune >1d.
      local tmpdir="${TMPDIR:-/tmp}"
      local leftover_count=0 pruned_count=0
      leftover_count="$(find "$tmpdir" -maxdepth 1 -type d -name 'sync-stamped-repos-coverage.*' -mtime +1 2>/dev/null | wc -l | tr -d ' ' || echo 0)"
      if [[ "$mode" == "apply" && "$leftover_count" -gt 0 ]]; then
        while IFS= read -r d; do
          [[ -n "$d" && -d "$d" ]] && rm -rf "$d" 2>/dev/null && pruned_count=$((pruned_count + 1))
        done < <(find "$tmpdir" -maxdepth 1 -type d -name 'sync-stamped-repos-coverage.*' -mtime +1 2>/dev/null)
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
      --sync-companion) subject="sync-companion"; shift ;;
      --stamped-repos-coverage) subject="stamped-repos-coverage"; shift ;;
      --json) shift ;;
      *) printf 'ERR: unknown validate arg %s\n' "$1" >&2; return 64 ;;
    esac
  done
  local root="/Users/josh/Developer/flywheel"
  local sync_companion="$root/.flywheel/scripts/sync-canonical-doctrine.sh"
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
      local root_ok=false sp_ok=false mk_ok=false jq_ok=false
      [[ -d "$root" ]] && root_ok=true
      [[ -x "$sync_companion" ]] && sp_ok=true
      command -v mktemp >/dev/null 2>&1 && mk_ok=true
      command -v jq >/dev/null 2>&1 && jq_ok=true
      local overall=pass
      [[ "$root_ok" != true || "$sp_ok" != true || "$mk_ok" != true || "$jq_ok" != true ]] && overall=fail
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$overall" \
        --argjson rt "$root_ok" --argjson sp "$sp_ok" --argjson mk "$mk_ok" --argjson jqq "$jq_ok" \
        --arg root "$root" --arg sc "$sync_companion" \
        '{schema_version:$sv,command:"validate",subject:"config",status:$s,root_present:$rt,sync_companion_executable:$sp,mktemp_present:$mk,jq_present:$jqq,root:$root,sync_companion:$sc}'
      ;;
    sync-companion)
      # test-sync-specific: probe sync-canonical-doctrine.sh target script.
      local present=false executable=false lines=0
      [[ -r "$sync_companion" ]] && present=true && lines="$(wc -l < "$sync_companion" 2>/dev/null | tr -d ' ' || echo 0)"
      [[ -x "$sync_companion" ]] && executable=true
      local status="pass"
      [[ "$present" != true || "$executable" != true ]] && status="fail"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$status" --arg p "$sync_companion" \
        --argjson present "$present" --argjson exec "$executable" --argjson l "$lines" \
        '{schema_version:$sv,command:"validate",subject:"sync-companion",status:$s,sync_canonical_path:$p,present:$present,executable:$exec,lines:$l}'
      ;;
    stamped-repos-coverage)
      # test-sync-specific: probe whether each of the 6 expected stamped repos
      # exists in $HOME/Developer. The test fixture hardcodes these names;
      # this probe verifies the fixture list still matches the real fleet.
      local dev_root="$HOME/Developer"
      local expected=("alpsinsurance" "mobile-eats" "skillos" "terratitle" "zeststream-infra" "zesttube")
      local present_arr=() missing_arr=()
      for repo in "${expected[@]}"; do
        if [[ -d "$dev_root/$repo" ]]; then
          present_arr+=("$repo")
        else
          missing_arr+=("$repo")
        fi
      done
      local present_count="${#present_arr[@]}" missing_count="${#missing_arr[@]}"
      local present_json missing_json
      present_json="$(printf '%s\n' "${present_arr[@]+"${present_arr[@]}"}" | jq -R . | jq -sc '. // []')"
      missing_json="$(printf '%s\n' "${missing_arr[@]+"${missing_arr[@]}"}" | jq -R . | jq -sc '. // []')"
      local status="pass"
      [[ "$missing_count" -gt 0 ]] && status="warn"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$status" --arg dev "$dev_root" \
        --argjson present "$present_json" --argjson missing "$missing_json" \
        --argjson pc "$present_count" --argjson mc "$missing_count" \
        '{schema_version:$sv,command:"validate",subject:"stamped-repos-coverage",status:$s,dev_root:$dev,expected_repos:6,present_count:$pc,missing_count:$mc,present_repos:$present,missing_repos:$missing}'
      ;;
    "")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",status:"pass",subjects:["row","schema","config","sync-companion","stamped-repos-coverage"],usage:"validate --row-json JSON or --schema or --config or --sync-companion or --stamped-repos-coverage"}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$subject" \
        '{schema_version:$sv,command:"validate",subject:$s,status:"unknown_subject",known:["row","schema","config","sync-companion","stamped-repos-coverage"]}'
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
ROOT="/Users/josh/Developer/flywheel"
SYNC="$ROOT/.flywheel/scripts/sync-canonical-doctrine.sh"

STAMPED_REPOS=(
  alpsinsurance
  mobile-eats
  skillos
  terratitle
  zeststream-infra
  zesttube
)

TMP="$(mktemp -d "${TMPDIR:-/tmp}/sync-stamped-repos-coverage.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

CANONICAL="$TMP/source/AGENTS.md"
mkdir -p "$(dirname "$CANONICAL")"
printf '# Canonical doctrine\n\n## L66 - synthetic outbound-jeff-issues rule\nbody\n\n## L107 - synthetic shared-surface-writes rule\nbody\n' >"$CANONICAL"

for repo in "${STAMPED_REPOS[@]}"; do
  mkdir -p "$TMP/repos/$repo/.flywheel"
  printf 'stale doctrine for %s\n' "$repo" >"$TMP/repos/$repo/.flywheel/AGENTS-CANONICAL.md"
  printf '# %s local instructions\n\nKeep this line.\n' "$repo" >"$TMP/repos/$repo/AGENTS.md"
  cat >"$TMP/repos/$repo/.flywheel/ownership.json" <<'JSON'
{
  "schema_version": "flywheel.canonical_ownership.v1",
  "canonical_owner_class": "flywheel",
  "owned_canonical_paths": [
    {"path": "AGENTS.md", "owner_class": "flywheel"},
    {"path": ".flywheel", "owner_class": "flywheel"}
  ]
}
JSON
done

# Phase 1: dry-run drift detection
rc=0
dry="$(SYNC_CANONICAL_SOURCE="$CANONICAL" \
       SYNC_CANONICAL_LEDGER="$TMP/doctrine-sync-ledger.jsonl" \
       SYNC_CANONICAL_ROOTS="$TMP/repos" \
       SYNC_CANONICAL_LOOPS_DIR="$TMP/no-loops" \
       "$SYNC" --dry-run --json 2>&1)" || rc=$?
if [[ "$rc" -ne 1 ]]; then
  printf 'FAIL: dry-run expected rc=1 for drift, got %s\n%s\n' "$rc" "$dry" >&2
  exit 1
fi
if [[ "$(jq -r '.canonical_drifted_count' <<<"$dry")" != "6" ]]; then
  printf 'FAIL: expected canonical_drifted_count=6, got %s\n%s\n' \
    "$(jq -r '.canonical_drifted_count' <<<"$dry")" "$dry" >&2
  exit 1
fi
if [[ "$(jq -r '.root_drifted_count' <<<"$dry")" != "6" ]]; then
  printf 'FAIL: expected root_drifted_count=6, got %s\n%s\n' \
    "$(jq -r '.root_drifted_count' <<<"$dry")" "$dry" >&2
  exit 1
fi

# Every stamped repo name MUST appear in dry-run drift details.
for repo in "${STAMPED_REPOS[@]}"; do
  hit="$(jq -r --arg name "$repo" '[.details[] | select(.target | test("/repos/" + $name + "/"))] | length' <<<"$dry")"
  if [[ "$hit" != "1" ]]; then
    printf 'FAIL: dry-run details missing stamped repo %s (hit=%s)\n%s\n' "$repo" "$hit" "$dry" >&2
    exit 1
  fi
done

# Phase 2: apply writes to all 6
apply="$(SYNC_CANONICAL_SOURCE="$CANONICAL" \
         SYNC_CANONICAL_LEDGER="$TMP/doctrine-sync-ledger.jsonl" \
         SYNC_CANONICAL_ROOTS="$TMP/repos" \
         SYNC_CANONICAL_LOOPS_DIR="$TMP/no-loops" \
         "$SYNC" --apply --idempotency-key stamped-coverage-apply --json)"
if [[ "$(jq -r '.status' <<<"$apply")" != "ok" ]]; then
  printf 'FAIL: apply expected status=ok\n%s\n' "$apply" >&2
  exit 1
fi
if [[ "$(jq -r '.canonical_synced_count' <<<"$apply")" != "6" ]]; then
  printf 'FAIL: expected canonical_synced_count=6, got %s\n%s\n' \
    "$(jq -r '.canonical_synced_count' <<<"$apply")" "$apply" >&2
  exit 1
fi
if [[ "$(jq -r '.root_synced_count' <<<"$apply")" != "6" ]]; then
  printf 'FAIL: expected root_synced_count=6, got %s\n%s\n' \
    "$(jq -r '.root_synced_count' <<<"$apply")" "$apply" >&2
  exit 1
fi

# File-level proof: every stamped repo got the canonical mirror updated.
for repo in "${STAMPED_REPOS[@]}"; do
  if ! diff -q "$CANONICAL" "$TMP/repos/$repo/.flywheel/AGENTS-CANONICAL.md" >/dev/null 2>&1; then
    printf 'FAIL: %s canonical mirror did not match source after apply\n' "$repo" >&2
    exit 1
  fi
  if ! grep -q 'L66' "$TMP/repos/$repo/AGENTS.md"; then
    printf 'FAIL: %s root AGENTS.md missing L66 after apply\n' "$repo" >&2
    exit 1
  fi
  if ! grep -q 'L107' "$TMP/repos/$repo/AGENTS.md"; then
    printf 'FAIL: %s root AGENTS.md missing L107 after apply\n' "$repo" >&2
    exit 1
  fi
  if ! grep -q 'Keep this line.' "$TMP/repos/$repo/AGENTS.md"; then
    printf 'FAIL: %s root AGENTS.md lost local content outside canonical block\n' "$repo" >&2
    exit 1
  fi
done

# Phase 3: idempotent re-run — apply twice yields zero further drift.
post="$(SYNC_CANONICAL_SOURCE="$CANONICAL" \
        SYNC_CANONICAL_LEDGER="$TMP/doctrine-sync-ledger.jsonl" \
        SYNC_CANONICAL_ROOTS="$TMP/repos" \
        SYNC_CANONICAL_LOOPS_DIR="$TMP/no-loops" \
        "$SYNC" --dry-run --json)"
if [[ "$(jq -r '.status' <<<"$post")" != "ok" ]]; then
  printf 'FAIL: post-apply dry-run expected status=ok\n%s\n' "$post" >&2
  exit 1
fi
if [[ "$(jq -r '.drifted_count' <<<"$post")" != "0" ]]; then
  printf 'FAIL: post-apply expected drifted_count=0, got %s\n%s\n' \
    "$(jq -r '.drifted_count' <<<"$post")" "$post" >&2
  exit 1
fi

printf 'PASS: sync-canonical-doctrine.sh discovers + writes all 6 stamped repos (incl. terratitle, zeststream-infra)\n'
