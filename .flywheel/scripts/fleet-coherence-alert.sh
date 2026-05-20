#!/usr/bin/env bash
set -euo pipefail


# ====== BEGIN canonical-cli scaffold (bead flywheel-ws02m) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (filled-in per bead flywheel-5ke66.9)
# doctor-mode-tier: scaffolded (bead flywheel-ws02m)
#
# This scaffold sits ahead of the python heredoc. The original python
# argparse already exposes flag-form surfaces (--info, --schema, --doctor,
# --health, --validate, --audit, --why, --repair) that fixture-check
# against .flywheel/fixtures/fleet-coherence-alerts.jsonl; those remain
# accessible verbatim because the scaffold's early-dispatch ONLY matches
# the no-dash subcommand forms (doctor, health, repair, validate, audit,
# why) plus the introspection flags --info / --schema / --examples.
#
# Backward-compat preservation for existing tests/fleet-coherence-alert.sh:
#   - scaffold_emit_info embeds `canonical_cli_surfaces` including --dry-run
#     (existing assertion: .canonical_cli_surfaces | index("--dry-run"))
#   - scaffold_emit_schema default branch embeds event_schema_version + the
#     l61_pairing_status enum (existing assertion: .event_schema_version
#     == 2 and (.l61_pairing_status | index("complete")))
#   - --doctor / --health / --validate / --audit / --why / --repair fall
#     through to the python's fixture-check handlers unchanged
#   - send command (default) falls through to python's alert dispatcher

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="fleet-coherence-alert/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-${FLEET_COHERENCE_ALERT_LEDGER:-$HOME/.local/state/flywheel/fleet-coherence-alerts.jsonl}}"
SCAFFOLD_FIXTURES="${FLEET_COHERENCE_ALERT_FIXTURES:-$_SCAFFOLD_REPO_ROOT/.flywheel/fixtures/fleet-coherence-alerts.jsonl}"
SCAFFOLD_NTM_BIN="${FLEET_COHERENCE_NTM:-/Users/josh/.local/bin/ntm}"
SCAFFOLD_AGENT_MAIL_SEND="$_SCAFFOLD_REPO_ROOT/.flywheel/scripts/agent-mail-send-redacted.sh"
SCAFFOLD_AUTH_PROBE="$_SCAFFOLD_REPO_ROOT/.flywheel/scripts/fleet-mail-auth-probe.sh"
SCAFFOLD_WRITER="$_SCAFFOLD_REPO_ROOT/.flywheel/scripts/fleet-coherence-write.sh"

scaffold_usage() {
  cat <<'USG'
usage: fleet-coherence-alert.sh [SUBCOMMAND] [OPTIONS]

Default invocation routes to the python `send` command (existing alert
dispatcher); `--doctor / --health / --validate / --audit / --why / --repair`
also route to the python heredoc's fixture-check surfaces unchanged.

Canonical CLI surfaces (intercepted before the python heredoc):
  doctor [--json]          probe substrate health (jq/python3/ntm/agent-mail/fixtures)
  health [--json]          last-run status (ledger tail + l61_pairing counts)
  repair --scope <s>       repair misconfigured state
                            Default: --dry-run; mutate with --apply --idempotency-key KEY
                            Scopes: audit-log-rotate, fixtures-prime
  validate <subject> [...] validate per-subject contract
                            Subjects: row, schema, config, fixtures, ledger
  audit [--json]           recent run history (ledger tail)
  why <id>                 explain provenance for a given id
                            (id matches event_id / dedupe_key / channel)
  quickstart [--json]      operator orientation
  help <topic>             topic help (run | doctor | health | repair | validate)
  completion <shell>       emit bash or zsh completion

Introspection (backward-compat shape preserved):
  --info --json            adds .version + canonical .subcommands; keeps
                           .canonical_cli_surfaces (with --dry-run) for
                           tests/fleet-coherence-alert.sh compatibility
  --schema [<surface>]     default branch keeps event_schema_version=2 +
                           l61_pairing_status enum for existing assertions
  --examples --json        curated workflow examples (NEW)
  --help / -h              this help
USG
}

# Hand-rolled info envelope (NOT via cli_emit_info) so we can preserve the
# python's `canonical_cli_surfaces` list (existing test asserts --dry-run is in it)
# while also adding the canonical .version + .subcommands AG3 fields.
scaffold_emit_info() {
  local sha; sha="$(cli_sha_self "${BASH_SOURCE[0]}" 2>/dev/null || echo)"
  jq -nc \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    --arg name "fleet-coherence-alert.sh" \
    --arg version "scaffolded-v0" \
    --arg sha "$sha" \
    --arg ledger "$SCAFFOLD_AUDIT_LOG" \
    --arg fixtures "$SCAFFOLD_FIXTURES" \
    '{
      schema_version: $sv,
      command: "info",
      name: $name,
      version: $version,
      sha256: $sha,
      subcommands: ["doctor","health","repair","validate","audit","why","quickstart","help","completion"],
      canonical_cli_surfaces: ["doctor","health","repair","validate","audit","why","quickstart","help","completion","--info","--schema","--examples","--doctor","--health","--validate","--audit","--why","--repair","--json","--dry-run"],
      env_vars: ["SCAFFOLD_AUDIT_LOG","FLEET_COHERENCE_ALERT_LEDGER","FLEET_COHERENCE_ALERT_FIXTURES","FLEET_COHERENCE_NTM","FLEET_COHERENCE_AGENT_MAIL_SEND","FLEET_COHERENCE_AUTH_PROBE","FLEET_COHERENCE_WRITER","FLEET_COHERENCE_FLEET_MAIL_PROJECT","FLYWHEEL_FLEET_COHERENCE_EVENTS"],
      dependencies: ["bash","python3","jq","date","shasum"],
      mutation_requires: "send appends ledger and event row after channel attempts; canonical repair --apply requires --idempotency-key",
      ledger: $ledger,
      fixtures: $fixtures
    }'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"send alert (default)",invocation:"fleet-coherence-alert.sh send --event-json {...} --sender LavenderGlen",purpose:"dispatch dual-channel L61 alert via agent-mail + ntm pane wake"}'
)"$'\n'"$(jq -nc '{name:"fixture doctor (python)",invocation:"fleet-coherence-alert.sh --doctor --json",purpose:"python-side fixture-presence check"}'
)"$'\n'"$(jq -nc '{name:"substrate doctor (canonical)",invocation:"fleet-coherence-alert.sh doctor --json",purpose:"canonical substrate probe: python3/jq/ntm/agent-mail-send/auth-probe/fixtures"}'
)"$'\n'"$(jq -nc '{name:"validate ledger",invocation:"fleet-coherence-alert.sh validate --ledger",purpose:"probe ledger row count + l61_pairing_status distribution"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"fleet-coherence-alert.sh doctor --json"}'
)"$'\n'"$(jq -nc '{step:2,action:"check ledger health",command:"fleet-coherence-alert.sh health --json"}'
)"$'\n'"$(jq -nc '{step:3,action:"send dry-run alert",command:"fleet-coherence-alert.sh send --event-json {...} --dry-run"}'
)"
  if command -v cli_emit_quickstart >/dev/null; then
    cli_emit_quickstart "$SCAFFOLD_SCHEMA_VERSION" "$steps" "doctor,health,repair"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"quickstart",helper_lib_missing:true}'
  fi
}

# Hand-rolled schema envelope. Default branch includes the python's existing
# event_schema_version + l61_pairing_status fields so the existing test's
# `.event_schema_version == 2 and (.l61_pairing_status | index("complete"))`
# assertion keeps passing.
scaffold_emit_schema() {
  local surface="${1:-default}"
  case "$surface" in
    doctor)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:["ts","status","checks[]"],check_fields:["name","status","value?","detail?"]}' ;;
    health)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:["ts","status","audit_log","stale_seconds","last_row?","attempt_count","delivered_count","degraded_count","failed_count","suppressed_count"]}' ;;
    repair)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,scopes:["audit-log-rotate","fixtures-prime"],fields:["status","mode","scope","idempotency_key?","rotated?","fixtures?","fixture_cases?"]}' ;;
    validate)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,subjects:["row","schema","config","fixtures","ledger"],fields:["status","subject","valid?","missing?","reason?","fixtures?","ledger?","row_count?"]}' ;;
    audit)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:["audit_log","row_count","rows[]"]}' ;;
    why)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:["id","status","matches[]"],id_pattern:"event_id|dedupe_key|channel"}' ;;
    audit-row)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,required:["schema_version","event_id","dedupe_key","attempt_ts","l61_pairing_status"],optional:["agent_mail_message_id","ntm_result","channel","retry_after_ts"]}' ;;
    *)
      # Default — backward-compat with python's existing --schema shape
      # (event_schema_version=2 + l61_pairing_status enum).
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{
          schema_version:$sv,
          command:"schema",
          surface:$surface,
          status:"ok",
          alert_attempt_required:["schema_version","event_id","dedupe_key","attempt_ts","agent_mail_message_id","ntm_result","l61_pairing_status","channel","retry_after_ts"],
          event_schema_version:2,
          l61_pairing_status:["not_attempted","complete","degraded","failed","suppressed"],
          stable_exit_codes:{"0":"complete or suppressed","1":"degraded or failed","64":"usage","65":"invalid event row"},
          note:"fleet-coherence-alert: dual-channel L61 alert dispatcher (agent-mail + ntm); fixtures at .flywheel/fixtures/fleet-coherence-alerts.jsonl"
        }' ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — python heredoc dispatcher; default command is `send` which reads --event-row/--event-json, attempts agent-mail send + ntm pane wake, records L61 pairing status, appends ledger and event row.\n' ;;
    doctor)   printf 'topic: doctor — substrate probe: python3, jq, ntm bin, agent-mail-send helper, fleet-mail-auth-probe helper, fixtures present, ledger writable, flywheel root. Sister surface --doctor (with dash) routes to the python fixture-check.\n' ;;
    health)   printf 'topic: health — tails ledger (= audit log); warn stale >7d. Counts l61_pairing_status distribution (complete/degraded/failed/suppressed).\n' ;;
    repair)   printf 'topic: repair — scopes: audit-log-rotate (>5MB → mv .ts), fixtures-prime (read-only — probes fixtures jsonl row count + required-cases presence).\n' ;;
    validate) printf 'topic: validate — subjects: --row-json JSON, --schema, --config, --fixtures (probes fixtures jsonl + required test cases), --ledger (probes ledger row schema + l61 distribution).\n' ;;
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
            && cli_emit_completion_bash "fleet-coherence-alert" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples,--event-row,--event-json,--ledger,--fixtures" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "fleet-coherence-alert" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (filled-in per flywheel-5ke66.9) ----------

scaffold_cmd_doctor() {
  # Substrate: python3, jq, ntm, agent-mail-send, fleet-mail-auth-probe, fixtures, ledger, flywheel root.
  local script_root; script_root="$_SCAFFOLD_REPO_ROOT"
  local checks="" overall="pass"

  if command -v python3 >/dev/null 2>&1; then
    checks+="$(jq -nc --arg p "$(command -v python3)" '{name:"python3_on_path",status:"pass",value:$p}')"$'\n'
  else
    checks+="$(jq -nc '{name:"python3_on_path",status:"fail",detail:"python3 required for heredoc dispatcher"}')"$'\n'
    overall="fail"
  fi

  if command -v jq >/dev/null 2>&1; then
    checks+="$(jq -nc --arg p "$(command -v jq)" '{name:"jq_on_path",status:"pass",value:$p}')"$'\n'
  else
    checks+="$(jq -nc '{name:"jq_on_path",status:"fail"}')"$'\n'
    overall="fail"
  fi

  if [[ -x "$SCAFFOLD_NTM_BIN" ]]; then
    checks+="$(jq -nc --arg p "$SCAFFOLD_NTM_BIN" '{name:"ntm_bin_executable",status:"pass",value:$p}')"$'\n'
  else
    checks+="$(jq -nc --arg p "$SCAFFOLD_NTM_BIN" '{name:"ntm_bin_executable",status:"fail",value:$p,detail:"used for NTM pane wake (L61 second leg)"}')"$'\n'
    overall="fail"
  fi

  if [[ -x "$SCAFFOLD_AGENT_MAIL_SEND" ]]; then
    checks+="$(jq -nc --arg p "$SCAFFOLD_AGENT_MAIL_SEND" '{name:"agent_mail_send_executable",status:"pass",value:$p}')"$'\n'
  else
    checks+="$(jq -nc --arg p "$SCAFFOLD_AGENT_MAIL_SEND" '{name:"agent_mail_send_executable",status:"warn",value:$p,detail:"agent-mail-send helper missing; alerts run in dry-run mode"}')"$'\n'
  fi

  # Fixtures presence + required-cases check.
  local fixtures_present=false fixture_rows=0 cases_complete=false
  if [[ -r "$SCAFFOLD_FIXTURES" ]]; then
    fixtures_present=true
    fixture_rows="$(wc -l < "$SCAFFOLD_FIXTURES" 2>/dev/null | tr -d ' ' || echo 0)"
    if jq -e -r '.case // empty' "$SCAFFOLD_FIXTURES" 2>/dev/null \
       | sort -u \
       | grep -qE '^success$' && \
       jq -e -r '.case // empty' "$SCAFFOLD_FIXTURES" 2>/dev/null \
       | sort -u \
       | grep -qE '^stale_callback_pane$'; then
      cases_complete=true
    fi
  fi
  local fx_status="pass"
  [[ "$fixtures_present" != true ]] && fx_status="fail" && overall="fail"
  [[ "$fixtures_present" == true && "$cases_complete" != true ]] && fx_status="warn"
  checks+="$(jq -nc --arg p "$SCAFFOLD_FIXTURES" --arg s "$fx_status" --argjson present "$fixtures_present" --argjson rows "$fixture_rows" --argjson cc "$cases_complete" \
    '{name:"fixtures_present",status:$s,value:$p,fixtures_present:$present,row_count:$rows,required_cases_complete:$cc}')"$'\n'

  local ledger_dir; ledger_dir="$(dirname "$SCAFFOLD_AUDIT_LOG")"
  if [[ -d "$ledger_dir" && -w "$ledger_dir" ]] || mkdir -p "$ledger_dir" 2>/dev/null; then
    local row_count=0
    [[ -r "$SCAFFOLD_AUDIT_LOG" ]] && row_count="$(wc -l < "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | tr -d ' ' || echo 0)"
    checks+="$(jq -nc --arg p "$SCAFFOLD_AUDIT_LOG" --argjson rc "${row_count:-0}" '{name:"ledger_writable",status:"pass",value:$p,row_count:$rc}')"$'\n'
  else
    checks+="$(jq -nc --arg p "$SCAFFOLD_AUDIT_LOG" '{name:"ledger_writable",status:"fail",value:$p}')"$'\n'
    overall="fail"
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
  local last_row="null" stale_seconds=-1 status="warn"
  local attempt_count=0 delivered_count=0 degraded_count=0 failed_count=0 suppressed_count=0
  if [[ -r "$log" ]]; then
    local row_raw; row_raw="$(tail -n 1 "$log" 2>/dev/null || true)"
    if [[ -n "$row_raw" ]] && printf '%s' "$row_raw" | jq -e '.' >/dev/null 2>&1; then
      last_row="$row_raw"
      local last_ts; last_ts="$(printf '%s' "$row_raw" | jq -r '.attempt_ts // .ts // empty' 2>/dev/null || true)"
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
    attempt_count="$(wc -l < "$log" 2>/dev/null | tr -d ' ' || echo 0)"
    delivered_count="$(grep -c '"l61_pairing_status":"complete"' "$log" 2>/dev/null; true)"
    degraded_count="$(grep -c '"l61_pairing_status":"degraded"' "$log" 2>/dev/null; true)"
    failed_count="$(grep -c '"l61_pairing_status":"failed"' "$log" 2>/dev/null; true)"
    suppressed_count="$(grep -c '"l61_pairing_status":"suppressed"' "$log" 2>/dev/null; true)"
  fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$log" \
    --arg status "$status" --argjson stale "$stale_seconds" --argjson row "$last_row" \
    --argjson ac "${attempt_count:-0}" --argjson dc "${delivered_count:-0}" \
    --argjson degc "${degraded_count:-0}" --argjson fc "${failed_count:-0}" \
    --argjson sc "${suppressed_count:-0}" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,audit_log:$log,stale_seconds:$stale,last_row:$row,attempt_count:$ac,delivered_count:$dc,degraded_count:$degc,failed_count:$fc,suppressed_count:$sc}'
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
    fixtures-prime)
      # Read-only: probe fixtures jsonl + required-cases presence.
      local present=false rows=0 cases_json="[]"
      if [[ -r "$SCAFFOLD_FIXTURES" ]]; then
        present=true
        rows="$(wc -l < "$SCAFFOLD_FIXTURES" 2>/dev/null | tr -d ' ' || echo 0)"
        cases_json="$(jq -r '.case // empty' "$SCAFFOLD_FIXTURES" 2>/dev/null | sort -u | jq -R . | jq -sc '.' 2>/dev/null || echo '[]')"
      fi
      local status="pass"
      [[ "$present" != true ]] && status="warn"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" \
        --arg idem "$idem_key" --arg fixtures "$SCAFFOLD_FIXTURES" --arg s "$status" \
        --argjson present "$present" --argjson rows "${rows:-0}" --argjson cases "$cases_json" \
        '{schema_version:$sv,command:"repair",status:$s,mode:$mode,scope:$scope,idempotency_key:$idem,fixtures:$fixtures,present:$present,row_count:$rows,fixture_cases:$cases,note:"read-only probe"}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" --arg idem "$idem_key" \
        '{schema_version:$sv,command:"repair",status:"unknown_scope",mode:$mode,scope:$scope,idempotency_key:$idem,known_scopes:["audit-log-rotate","fixtures-prime"]}'
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
      --fixtures) subject="fixtures"; shift ;;
      --ledger) subject="ledger"; shift ;;
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
      # Ledger attempt rows require schema_version + event_id + dedupe_key + attempt_ts + l61_pairing_status.
      for f in schema_version event_id dedupe_key attempt_ts l61_pairing_status; do
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
      local py_ok=false jq_ok=false ntm_ok=false ams_ok=false fix_ok=false ledger_dir_ok=false root_ok=false
      command -v python3 >/dev/null 2>&1 && py_ok=true
      command -v jq >/dev/null 2>&1 && jq_ok=true
      [[ -x "$SCAFFOLD_NTM_BIN" ]] && ntm_ok=true
      [[ -x "$SCAFFOLD_AGENT_MAIL_SEND" ]] && ams_ok=true
      [[ -r "$SCAFFOLD_FIXTURES" ]] && fix_ok=true
      [[ -d "$(dirname "$SCAFFOLD_AUDIT_LOG")" ]] && ledger_dir_ok=true
      [[ -d "$_SCAFFOLD_REPO_ROOT" ]] && root_ok=true
      local overall=pass
      [[ "$py_ok" != true || "$jq_ok" != true || "$ntm_ok" != true || "$fix_ok" != true || "$ledger_dir_ok" != true || "$root_ok" != true ]] && overall=fail
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$overall" \
        --argjson py "$py_ok" --argjson jqq "$jq_ok" --argjson ntm "$ntm_ok" --argjson ams "$ams_ok" \
        --argjson fix "$fix_ok" --argjson ld "$ledger_dir_ok" --argjson rt "$root_ok" \
        --arg root "$_SCAFFOLD_REPO_ROOT" --arg ledger "$SCAFFOLD_AUDIT_LOG" --arg fixtures "$SCAFFOLD_FIXTURES" \
        --arg ntm_p "$SCAFFOLD_NTM_BIN" --arg ams_p "$SCAFFOLD_AGENT_MAIL_SEND" \
        '{schema_version:$sv,command:"validate",subject:"config",status:$s,python3_present:$py,jq_present:$jqq,ntm_bin_present:$ntm,agent_mail_send_present:$ams,fixtures_present:$fix,ledger_dir_present:$ld,flywheel_root_present:$rt,flywheel_root:$root,ledger:$ledger,fixtures:$fixtures,ntm_bin:$ntm_p,agent_mail_send:$ams_p}'
      ;;
    fixtures)
      # surface-specific: probe fixtures jsonl + required test cases coverage.
      local present=false rows=0 cases_json="[]"
      local required_cases='["success","agent_mail_fails","ntm_fails","both_legs_fail","resend_suppressed","stale_callback_pane"]'
      if [[ -r "$SCAFFOLD_FIXTURES" ]]; then
        present=true
        rows="$(wc -l < "$SCAFFOLD_FIXTURES" 2>/dev/null | tr -d ' ' || echo 0)"
        cases_json="$(jq -r '.case // empty' "$SCAFFOLD_FIXTURES" 2>/dev/null | sort -u | jq -R . | jq -sc '.' 2>/dev/null || echo '[]')"
      fi
      local status="pass"
      [[ "$present" != true ]] && status="fail"
      local missing_cases
      missing_cases="$(jq -n --argjson cases "$cases_json" --argjson required "$required_cases" '$required - $cases' 2>/dev/null || echo '[]')"
      local missing_count
      missing_count="$(printf '%s' "$missing_cases" | jq 'length' 2>/dev/null || echo 0)"
      [[ "$present" == true && "$missing_count" -gt 0 ]] && status="warn"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$status" --arg fixtures "$SCAFFOLD_FIXTURES" \
        --argjson present "$present" --argjson rows "${rows:-0}" \
        --argjson cases "$cases_json" --argjson required "$required_cases" --argjson missing "$missing_cases" \
        '{schema_version:$sv,command:"validate",subject:"fixtures",status:$s,fixtures:$fixtures,present:$present,row_count:$rows,fixture_cases:$cases,required_cases:$required,missing_cases:$missing}'
      ;;
    ledger)
      # surface-specific: probe attempt ledger row schema + l61 distribution.
      local present=false rows=0 last_row=null last_row_valid=false
      local complete_count=0 degraded_count=0 failed_count=0
      if [[ -r "$SCAFFOLD_AUDIT_LOG" ]]; then
        present=true
        rows="$(wc -l < "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | tr -d ' ' || echo 0)"
        complete_count="$(grep -c '"l61_pairing_status":"complete"' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null; true)"
        degraded_count="$(grep -c '"l61_pairing_status":"degraded"' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null; true)"
        failed_count="$(grep -c '"l61_pairing_status":"failed"' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null; true)"
        local raw; raw="$(tail -n 1 "$SCAFFOLD_AUDIT_LOG" 2>/dev/null || true)"
        if [[ -n "$raw" ]] && printf '%s' "$raw" | jq -e '.' >/dev/null 2>&1; then
          last_row="$raw"
          if printf '%s' "$raw" | jq -e 'has("schema_version") and has("event_id") and has("dedupe_key") and has("l61_pairing_status")' >/dev/null 2>&1; then
            last_row_valid=true
          fi
        fi
      fi
      local status="pass"
      [[ "$present" != true ]] && status="warn"
      [[ "$present" == true && "$rows" -gt 0 && "$last_row_valid" != true ]] && status="warn"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$status" --arg ledger "$SCAFFOLD_AUDIT_LOG" \
        --argjson present "$present" --argjson rows "${rows:-0}" \
        --argjson cc "${complete_count:-0}" --argjson dc "${degraded_count:-0}" --argjson fc "${failed_count:-0}" \
        --argjson lr "$last_row" --argjson lrv "$last_row_valid" \
        '{schema_version:$sv,command:"validate",subject:"ledger",status:$s,ledger:$ledger,present:$present,row_count:$rows,complete_count:$cc,degraded_count:$dc,failed_count:$fc,last_row:$lr,last_row_valid:$lrv}'
      ;;
    "")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",status:"pass",subjects:["row","schema","config","fixtures","ledger"],usage:"validate --row-json JSON or --schema or --config or --fixtures or --ledger"}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$subject" \
        '{schema_version:$sv,command:"validate",subject:$s,status:"unknown_subject",known:["row","schema","config","fixtures","ledger"]}'
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

# ---------- scaffolded main dispatcher ----------

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

# Early-dispatch intercept: canonical subcommand or intro flag → run the
# canonical surface and exit BEFORE the python heredoc parses args.
# IMPORTANT: dash-flag forms (--doctor, --health, --validate, --audit,
# --why, --repair) are NOT matched here; they fall through to the python
# heredoc's existing fixture-check handlers so tests/fleet-coherence-alert.sh
# continues to pass unchanged.
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

python3 - "$@" <<'PY'
import argparse
import json
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

VERSION = "fleet-coherence-alert/v1"
PROJECT_KEY = "/Users/josh/.local/state/flywheel/fleet-mail-project"


def utc_now():
    override = os.environ.get("FLYWHEEL_FLEET_COHERENCE_NOW")
    if override:
        return override
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def parse_ts(value):
    if not value:
        return None
    try:
        return datetime.fromisoformat(str(value).replace("Z", "+00:00"))
    except ValueError:
        return None


def emit(payload, pretty=False):
    text = json.dumps(payload, indent=2 if pretty else None, sort_keys=True, separators=None if pretty else (",", ":"))
    print(text)


def load_jsonl(path):
    path = Path(path).expanduser()
    rows = []
    if not path.exists():
        return rows
    for line_no, line in enumerate(path.read_text(encoding="utf-8", errors="ignore").splitlines(), 1):
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except json.JSONDecodeError:
            continue
        if isinstance(row, dict):
            row["__line"] = line_no
            rows.append(row)
    return rows


def append_jsonl(path, row):
    path = Path(path).expanduser()
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(row, sort_keys=True, separators=(",", ":")) + "\n")


def read_event(args):
    if args.event_json:
        return json.loads(args.event_json)
    if args.event_row:
        path = Path(args.event_row).expanduser()
        text = sys.stdin.read() if str(path) == "-" else path.read_text(encoding="utf-8")
        return json.loads(text)
    raise SystemExit("send requires --event-row or --event-json")


def run_command(argv, timeout):
    try:
        proc = subprocess.run(argv, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=timeout, check=False)
        return {
            "attempted": True,
            "exit_code": proc.returncode,
            "stdout": (proc.stdout or "").strip(),
            "stderr": (proc.stderr or "").strip(),
        }
    except FileNotFoundError:
        return {"attempted": True, "exit_code": 127, "stdout": "", "stderr": "command not found"}
    except subprocess.TimeoutExpired:
        return {"attempted": True, "exit_code": 124, "stdout": "", "stderr": "timeout"}


def parse_message_id(stdout):
    if not stdout:
        return None
    for line in stdout.splitlines()[::-1]:
        try:
            data = json.loads(line)
        except json.JSONDecodeError:
            continue
        if isinstance(data, dict):
            for key in ("message_id", "id"):
                if data.get(key) is not None:
                    return str(data[key])
            deliveries = data.get("deliveries")
            if isinstance(deliveries, list) and deliveries:
                payload = deliveries[0].get("payload") if isinstance(deliveries[0], dict) else None
                if isinstance(payload, dict) and payload.get("id") is not None:
                    return str(payload["id"])
    return None


def info(args):
    return {
        "schema_version": f"{VERSION}/info",
        "status": "ok",
        "name": "fleet-coherence-alert.sh",
        "commands": ["send", "doctor", "health", "validate", "audit"],
        "canonical_cli_surfaces": ["--info", "--schema", "--doctor", "--health", "--validate", "--audit", "--why", "--repair", "--json", "--dry-run"],
        "mutation_default": "send appends alert ledger and event ledger only after channel attempts",
        "project_key": args.project_key,
        "ledger": args.ledger,
    }


def schema(args):
    return {
        "schema_version": f"{VERSION}/schema",
        "status": "ok",
        "alert_attempt_required": [
            "schema_version",
            "event_id",
            "dedupe_key",
            "attempt_ts",
            "agent_mail_message_id",
            "ntm_result",
            "l61_pairing_status",
            "channel",
            "retry_after_ts",
        ],
        "event_schema_version": 2,
        "l61_pairing_status": ["not_attempted", "complete", "degraded", "failed", "suppressed"],
        "stable_exit_codes": {"0": "complete or suppressed", "1": "degraded or failed", "64": "usage", "65": "invalid event row"},
    }


def check_fixtures(args, mode):
    rows = load_jsonl(args.fixtures)
    cases = {r.get("case") for r in rows}
    required = {"success", "agent_mail_fails", "ntm_fails", "both_legs_fail", "resend_suppressed", "stale_callback_pane"}
    status = "ok" if required.issubset(cases) else "warn"
    payload = {
        "schema_version": f"{VERSION}/{mode}",
        "mode": mode,
        "status": status,
        "fixture_cases": sorted(c for c in cases if c),
        "fixtures": args.fixtures,
        "read_only": True,
    }
    if mode == "audit":
        attempts = load_jsonl(args.ledger)
        statuses = [str(r.get("l61_pairing_status") or "unknown") for r in attempts]
        payload["attempt_count"] = len(attempts)
        payload["delivered_count"] = statuses.count("complete")
        payload["degraded_count"] = statuses.count("degraded")
        payload["failed_count"] = statuses.count("failed")
        payload["suppressed_count"] = statuses.count("suppressed")
    return payload


def why(args):
    return {
        "schema_version": f"{VERSION}/why",
        "status": "ok",
        "reason": "L61 is only complete when fleet-mail durable delivery and NTM callback-pane wake signal succeed in the same logical exchange.",
    }


def repair(args):
    return {
        "schema_version": f"{VERSION}/repair",
        "status": "refused",
        "dry_run": True,
        "apply": False,
        "reason": "Cannot repair: alert delivery depends on live Agent Mail and NTM transport state; this helper records degraded attempts instead.",
    }


def latest_attempt(rows, dedupe_key):
    matches = [r for r in rows if r.get("dedupe_key") == dedupe_key]
    if not matches:
        return None
    return sorted(matches, key=lambda r: str(r.get("attempt_ts") or ""))[-1]


def should_suppress(event, ledger_rows, now):
    if event.get("state") in {"closed", "suppressed"}:
        return True, "event_state_not_alertable"
    resend_at = parse_ts(event.get("resend_after_ts"))
    now_dt = parse_ts(now)
    if resend_at and now_dt and now_dt < resend_at:
        return True, "resend_after_ts_not_reached"
    return False, None


def auth_probe(args, session, pane):
    if not args.auth_probe:
        return {"ready": True, "identity_name": args.sender, "identity_source": "explicit", "l61": {"vault_token_validated": False}}
    argv = [args.auth_probe, "--session", session, "--json"]
    if pane is not None:
        argv.extend(["--pane", str(pane)])
    result = run_command(argv, args.timeout)
    data = {}
    try:
        data = json.loads(result["stdout"])
    except Exception:
        pass
    data["_command"] = result
    return data


def attempt_agent_mail(args, event, sender, recipient, subject, body):
    if args.dry_run:
        return {"attempted": False, "exit_code": 0, "stdout": "", "stderr": "", "message_id": "dry-run"}
    if not args.agent_mail_send:
        return {"attempted": False, "exit_code": 127, "stdout": "", "stderr": "agent_mail_send command missing", "message_id": None}
    argv = [
        args.agent_mail_send,
        "send_message",
        "--project-key",
        args.project_key,
        "--sender-name",
        sender,
        "--to",
        recipient,
        "--subject",
        subject,
        "--body",
        body,
        "--sender-token-handle",
        args.sender_token_handle or f"vault:{sender}",
    ]
    if args.agent_mail_capture_dir:
        argv.extend(["--capture-dir", args.agent_mail_capture_dir])
    result = run_command(argv, args.timeout)
    result["message_id"] = parse_message_id(result["stdout"])
    return result


def attempt_ntm(args, session, pane, message):
    if args.dry_run:
        return {"attempted": False, "exit_code": 0, "stdout": "", "stderr": "", "status": "dry-run"}
    if not args.ntm_bin:
        return {"attempted": False, "exit_code": 127, "stdout": "", "stderr": "ntm command missing", "status": "missing"}
    if not session or pane is None:
        return {"attempted": False, "exit_code": 64, "stdout": "", "stderr": "missing callback pane", "status": "stale_callback_pane"}
    result = run_command([args.ntm_bin, "send", session, f"--pane={pane}", "--no-cass-check", message], args.timeout)
    result["status"] = "sent" if result["exit_code"] == 0 else "failed"
    return result


def pairing_status(mail_ok, ntm_ok, suppressed=False):
    if suppressed:
        return "suppressed"
    if mail_ok and ntm_ok:
        return "complete"
    if mail_ok or ntm_ok:
        return "degraded"
    return "failed"


def degraded_channel(mail_ok, ntm_ok, ntm_status=None, auth_failed=False):
    if auth_failed:
        return "agent_mail"
    if mail_ok and not ntm_ok:
        return "ntm"
    if ntm_ok and not mail_ok:
        return "agent_mail"
    if ntm_status == "stale_callback_pane":
        return "ntm"
    return "both"


def degradation_reason(mail_ok, ntm_ok, ntm_status=None, auth_failed=False):
    if auth_failed:
        return "fleet_mail_auth_probe_failed"
    if ntm_status == "stale_callback_pane":
        return "stale_callback_pane"
    if mail_ok and not ntm_ok:
        return "ntm_send_failed"
    if ntm_ok and not mail_ok:
        return "agent_mail_send_failed"
    return "both_channels_failed"


def alert_channel_degraded_event(event, now, channel, reason):
    source = json.loads(json.dumps(event))
    original_id = source.get("event_id") or source.get("id") or "unknown"
    original_class = source.get("class") or "unknown"
    session = source.get("session") or "fleet"
    row = source
    row["event_id"] = f"{original_id}_alert_channel_degraded"
    row["class"] = "alert_channel_degraded"
    row["severity"] = "error"
    row["state"] = "open"
    row["ts"] = now
    row["source_ts"] = now
    row["source_age_s"] = 0
    row["first_seen_ts"] = row.get("first_seen_ts") or now
    row["last_seen_ts"] = now
    row["dedupe_key"] = f"alert_channel_degraded:{session}:{original_class}:{channel}"
    row["resend_after_ts"] = source.get("resend_after_ts") or now
    evidence = row.setdefault("evidence", {})
    evidence["alert_channel_degraded"] = {
        "channel": channel,
        "degraded_reason": reason,
        "original_event_id": original_id,
        "original_class": original_class,
    }
    actions = row.setdefault("actions", {})
    actions.update({
        "would_l61": False,
        "would_bead": True,
        "would_no_bead_reason": None,
        "bead_id": None,
        "no_bead_reason": None,
        "receipt_required": True,
        "shadow_mode": False,
    })
    return row


def append_event(args, event):
    writer = args.writer
    if not writer:
        return {"attempted": False, "exit_code": 0, "stdout": "", "stderr": "writer disabled"}
    return run_command([writer, "append", "--row-json", json.dumps(event, sort_keys=True), "--json"], args.timeout)


def send(args):
    event = read_event(args)
    now = args.now or utc_now()
    event_id = event.get("event_id") or event.get("id")
    dedupe_key = event.get("dedupe_key")
    if not event_id or not dedupe_key:
        raise SystemExit("event row requires event_id/id and dedupe_key")

    if args.ntm_session is not None:
        target_session = args.ntm_session
    else:
        target_session = event.get("session") or (event.get("l61") or {}).get("ntm_session")
    target_pane = args.ntm_pane
    if target_pane is None:
        target_pane = event.get("pane") if event.get("pane") is not None else (event.get("l61") or {}).get("ntm_pane")

    ledger_rows = load_jsonl(args.ledger)
    suppress, suppress_reason = should_suppress(event, ledger_rows, now)

    auth = auth_probe(args, args.sender_session or event.get("session") or "flywheel", args.sender_pane)
    sender = args.sender or auth.get("identity_name") or (event.get("l61") or {}).get("agent_mail_from") or "LavenderGlen"
    recipient = args.to or (event.get("l61") or {}).get("agent_mail_to") or os.environ.get("FLEET_COHERENCE_ALERT_TO", "FoggyBear")
    subject = args.subject or f"[fleet-coherence] {event.get('class', 'event')} {event.get('severity', '')}".strip()
    body = args.body or f"Fleet coherence event {event_id} dedupe_key={dedupe_key} session={target_session} pane={target_pane}"

    mail = {"attempted": False, "exit_code": None, "stdout": "", "stderr": "", "message_id": None}
    ntm = {"attempted": False, "exit_code": None, "stdout": "", "stderr": "", "status": None}
    degraded_reason = None
    channel = None

    if suppress:
        status = "suppressed"
        degraded_reason = suppress_reason
        channel = None
    elif not auth.get("ready", False):
        status = "failed"
        degraded_reason = degradation_reason(False, False, auth_failed=True)
        channel = degraded_channel(False, False, auth_failed=True)
    else:
        mail = attempt_agent_mail(args, event, sender, recipient, subject, body)
        mail_ok = mail.get("exit_code") == 0 and bool(mail.get("message_id"))
        poke = f'POKE fleet-coherence alert msg id={mail.get("message_id")} project={args.project_key} event_id={event_id} dedupe_key={dedupe_key}'
        ntm = attempt_ntm(args, target_session, target_pane, poke)
        ntm_ok = ntm.get("exit_code") == 0
        status = pairing_status(mail_ok, ntm_ok)
        if status != "complete":
            degraded_reason = degradation_reason(mail_ok, ntm_ok, ntm.get("status"))
            channel = degraded_channel(mail_ok, ntm_ok, ntm.get("status"))

    updated = json.loads(json.dumps(event))
    l61 = updated.setdefault("l61", {})
    l61.update({
        "project_key": args.project_key,
        "fleet_mail_identity_source": auth.get("identity_source") or auth.get("identity_name") or "probe",
        "vault_token_validated": bool((auth.get("l61") or {}).get("vault_token_validated")),
        "agent_mail_attempted": bool(mail.get("attempted")),
        "agent_mail_sent_at": now if mail.get("attempted") else None,
        "agent_mail_message_id": mail.get("message_id"),
        "agent_mail_from": sender,
        "agent_mail_to": recipient,
        "ntm_attempted": bool(ntm.get("attempted")),
        "ntm_sent_at": now if ntm.get("attempted") else None,
        "ntm_session": target_session,
        "ntm_pane": target_pane,
        "ntm_result": {"exit_code": ntm.get("exit_code"), "status": ntm.get("status"), "stdout": ntm.get("stdout")},
        "l61_pairing_status": status,
        "degraded_reason": degraded_reason,
        "channel": channel,
        "retry_after_ts": event.get("resend_after_ts"),
        "retry_recommended": status in {"degraded", "failed"},
    })
    updated["ts"] = now
    updated["last_seen_ts"] = now
    if suppress:
        updated.setdefault("actions", {})["would_l61"] = False

    if status == "failed" and str(event.get("severity")) in {"error", "critical"}:
        updated = alert_channel_degraded_event(updated, now, channel or "both", degraded_reason or "both_channels_failed")

    write_result = append_event(args, updated)
    attempt = {
        "schema_version": "fleet-coherence-alert-attempt/v1",
        "case": args.case,
        "event_id": event_id,
        "dedupe_key": dedupe_key,
        "attempt_ts": now,
        "project_key": args.project_key,
        "agent_mail_message_id": mail.get("message_id"),
        "agent_mail_exit_code": mail.get("exit_code"),
        "ntm_result": {"exit_code": ntm.get("exit_code"), "status": ntm.get("status")},
        "l61_pairing_status": status,
        "degraded_reason": degraded_reason,
        "channel": channel,
        "retry_after_ts": event.get("resend_after_ts"),
        "retry_recommended": status in {"degraded", "failed"},
        "resend_after_ts": event.get("resend_after_ts"),
        "resend_suppressed": bool(suppress),
        "alert_sent": status == "complete",
        "event_write_exit_code": write_result.get("exit_code"),
    }
    append_jsonl(args.ledger, attempt)

    receipt = {
        "schema_version": f"{VERSION}/receipt",
        "status": "pass" if status in {"complete", "suppressed"} else "fail",
        "event_id": event_id,
        "dedupe_key": dedupe_key,
        "ledger": args.ledger,
        "events_path": os.environ.get("FLYWHEEL_FLEET_COHERENCE_EVENTS"),
        "attempt": attempt,
        "updated_l61": l61,
        "writer": write_result,
    }
    return receipt, 0 if receipt["status"] == "pass" else 1


def parse_args(argv):
    parser = argparse.ArgumentParser(description="Send fleet-coherence L61 dual-channel alerts.")
    parser.add_argument("command", nargs="?", default="send")
    parser.add_argument("--event-row")
    parser.add_argument("--event-json")
    parser.add_argument("--ledger", default=os.environ.get("FLEET_COHERENCE_ALERT_LEDGER", str(Path.home() / ".local/state/flywheel/fleet-coherence-alerts.jsonl")))
    parser.add_argument("--fixtures", default=os.environ.get("FLEET_COHERENCE_ALERT_FIXTURES", ".flywheel/fixtures/fleet-coherence-alerts.jsonl"))
    parser.add_argument("--writer", default=os.environ.get("FLEET_COHERENCE_WRITER", ".flywheel/scripts/fleet-coherence-write.sh"))
    parser.add_argument("--auth-probe", default=os.environ.get("FLEET_COHERENCE_AUTH_PROBE", ".flywheel/scripts/fleet-mail-auth-probe.sh"))
    parser.add_argument("--agent-mail-send", default=os.environ.get("FLEET_COHERENCE_AGENT_MAIL_SEND", ".flywheel/scripts/agent-mail-send-redacted.sh"))
    parser.add_argument("--ntm-bin", default=os.environ.get("FLEET_COHERENCE_NTM", "/Users/josh/.local/bin/ntm"))
    parser.add_argument("--agent-mail-capture-dir")
    parser.add_argument("--project-key", default=os.environ.get("FLEET_COHERENCE_FLEET_MAIL_PROJECT", PROJECT_KEY))
    parser.add_argument("--sender")
    parser.add_argument("--sender-session")
    parser.add_argument("--sender-pane", type=int)
    parser.add_argument("--sender-token-handle")
    parser.add_argument("--to")
    parser.add_argument("--subject")
    parser.add_argument("--body")
    parser.add_argument("--ntm-session")
    parser.add_argument("--ntm-pane", type=int)
    parser.add_argument("--timeout", type=float, default=float(os.environ.get("FLEET_COHERENCE_ALERT_TIMEOUT", "5")))
    parser.add_argument("--now")
    parser.add_argument("--case")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--pretty", action="store_true")
    parser.add_argument("--info", action="store_true")
    parser.add_argument("--schema", action="store_true")
    parser.add_argument("--doctor", action="store_true")
    parser.add_argument("--health", action="store_true")
    parser.add_argument("--validate", action="store_true")
    parser.add_argument("--audit", action="store_true")
    parser.add_argument("--why", action="store_true")
    parser.add_argument("--repair", action="store_true")
    return parser.parse_args(argv)


def main(argv):
    args = parse_args(argv)
    if args.info:
        emit(info(args), args.pretty and not args.json); return 0
    if args.schema:
        emit(schema(args), args.pretty and not args.json); return 0
    for flag, mode in ((args.doctor, "doctor"), (args.health, "health"), (args.validate, "validate"), (args.audit, "audit")):
        if flag:
            payload = check_fixtures(args, mode)
            emit(payload, args.pretty and not args.json)
            return 0 if payload["status"] == "ok" else 1
    if args.why:
        emit(why(args), args.pretty and not args.json); return 0
    if args.repair:
        emit(repair(args), args.pretty and not args.json); return 1
    if args.command != "send":
        raise SystemExit(f"unknown command: {args.command}")
    payload, rc = send(args)
    emit(payload, args.pretty and not args.json)
    return rc


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
PY

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
