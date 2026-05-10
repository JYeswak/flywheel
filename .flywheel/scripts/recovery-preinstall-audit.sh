#!/usr/bin/env bash
set -euo pipefail


# ====== BEGIN canonical-cli scaffold (bead flywheel-ws02m) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (TODO markers in stubs need fill-in)
# doctor-mode-tier: scaffolded (bead flywheel-ws02m)
#
# This block was scaffolded by scaffold-canonical-cli.sh. The original
# top-level dispatch is preserved as `cmd_run` (the new main routes
# default invocation through cmd_run for backward compat). Surface-
# specific logic was filled in by bead flywheel-wzjo9.2.8 (no remaining
# scaffold stubs). Largest surface in wave-2.0b (519 → 765 lines).

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="recovery-preinstall-audit/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/recovery-preinstall-audit-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: recovery-preinstall-audit.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "recovery-preinstall-audit.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "recovery-preinstall-audit.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"recovery-preinstall-audit.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"recovery-preinstall-audit.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"recovery-preinstall-audit.sh doctor --json"}'
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
        '{schema_version:$sv,command:"schema",surface:$surface,
          required:["status","checks"],status_enum:["pass","fail","warn"]}'
      ;;
    health)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,
          required:["status","audit_log","recent_runs"],status_enum:["pass","warn","fail"]}'
      ;;
    repair)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,
          required:["status","mode","scope"],mode_enum:["dry_run","apply"],
          valid_scopes:["audit-log-rotate","topology-prime"],
          mutation_gates:["--apply requires --idempotency-key"]}'
      ;;
    validate)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,
          required:["status","subject"],valid_subjects:["row","schema","config","topology","agent-mail"],
          status_enum:["pass","fail","warn","refused","info"]}'
      ;;
    audit)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,
          required:["audit_log","row_count","recent"]}'
      ;;
    why)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,
          required:["id","status"],status_enum:["found","not_found","unavailable"],
          provenance_fields:["ts","check","client","verdict","blockers"]}'
      ;;
    audit-row|run)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,
          required:["ts","command","schema_version"],
          optional:["client","verdict","blockers","check"],
          purpose:"row shape written to SCAFFOLD_AUDIT_LOG by cmd_run terminal envelopes"}'
      ;;
    default|*)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,
          surfaces:["doctor","health","repair","validate","audit","why","audit-row","default"],
          purpose:"recovery preinstall audit — probes ntm/agent-mail/topology/roster/loops/agent-mail-liveness before per-client plist install; substrate-level canonical layer over cmd_run python3",
          stable_exit_codes:{"0":"pass","1":"general error","3":"refused (--apply without --idempotency-key)","64":"bad args"}}'
      ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  local _runs="${SCAFFOLD_AUDIT_LOG:-${HOME}/.local/state/flywheel/recovery-preinstall-audit-runs.jsonl}"
  case "$topic" in
    run)
      printf 'topic: run — default backward-compatible invocation routes to cmd_run (python3 heredoc). Probes recovery system preinstall conditions: ntm binary/config, topology + roster, loops dir, agent-mail state + CLI + liveness HTTP, target repo path. Emits JSON audit report. Called by recovery-install-plist-* sister surfaces.\n'
      ;;
    doctor)
      printf 'topic: doctor — substrate health probes (python3, ntm, agent-mail CLI, topology readable, roster readable, loops dir, agent-mail liveness endpoint). Per-client preinstall probe lives in cmd_run.\n'
      ;;
    health)
      printf 'topic: health — recent audit summary from %s (recent_count, last_run_ts, age_seconds, distinct clients audited, distinct verdicts). Warn when ledger absent or stale (>24h — preinstall audits are on-demand, daily cadence preferred).\n' "$_runs"
      ;;
    repair)
      printf 'topic: repair — read-only by default; mutate with --apply --idempotency-key KEY. Scopes: audit-log-rotate (rotate %s when >5MB), topology-prime (read-only probe of session-topology.jsonl: row count + distinct sessions). Apply without --idempotency-key returns refused (rc 3).\n' "$_runs"
      ;;
    validate)
      printf 'topic: validate — per-subject contract checks. Subjects: row (--row-json=JSON validates audit-log row schema), schema (--surface=NAME re-emits the schema), config (env: python3, ntm, agent-mail, ntm-config), topology (probe session-topology.jsonl JSONL shape), agent-mail (probe agent-mail liveness HTTP endpoint).\n'
      ;;
    audit)
      printf 'topic: audit — tail %s (default --tail=10). Returns rows[] with ts, client, verdict, blockers, check.\n' "$_runs"
      ;;
    why)
      printf 'topic: why <id> — provenance lookup by client or check name in the audit log; emits ts/client/verdict/blockers or status=not_found when absent.\n'
      ;;
    *)
      printf 'topics: run | doctor | health | repair | validate | audit | why\n'
      ;;
  esac
}

scaffold_emit_completion() {
  local shell="${1:-bash}"
  case "$shell" in
    -h|--help) scaffold_emit_topic_help completion 2>/dev/null \
                 || printf 'topic: completion <bash|zsh> — emit shell completion script\n'
               return 0 ;;
    bash) command -v cli_emit_completion_bash >/dev/null \
            && cli_emit_completion_bash "recovery-preinstall-audit" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "recovery-preinstall-audit" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  # 7 named substrate probes for recovery-preinstall-audit.
  local ts ntm_bin agent_mail_cli topology roster loops_dir agent_mail_state
  ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  ntm_bin="/Users/josh/.local/bin/ntm"
  agent_mail_cli="/Users/josh/.local/bin/agent-mail"
  topology="$HOME/.local/state/flywheel/session-topology.jsonl"
  roster="$HOME/.local/state/flywheel/team-roster.jsonl"
  loops_dir="$HOME/.flywheel/loops"
  agent_mail_state="$HOME/.local/state/flywheel/agent-mail"

  local py_status="fail" py_reason=""
  if command -v python3 >/dev/null 2>&1; then py_status="pass"
  else py_reason="python3 not on PATH"; fi

  local ntm_status="fail" ntm_reason=""
  if [[ -x "$ntm_bin" ]]; then ntm_status="pass"
  else ntm_reason="ntm not executable: $ntm_bin"; fi

  local am_cli_status="fail" am_cli_reason=""
  if [[ -x "$agent_mail_cli" ]]; then am_cli_status="pass"
  else am_cli_status="warn"; am_cli_reason="agent-mail CLI absent: $agent_mail_cli (preinstall audit warns but continues)"; fi

  local topo_status="fail" topo_reason=""
  if [[ -r "$topology" ]]; then topo_status="pass"
  else topo_status="warn"; topo_reason="topology absent: $topology"; fi

  local roster_status="fail" roster_reason=""
  if [[ -r "$roster" ]]; then roster_status="pass"
  else roster_status="warn"; roster_reason="roster absent: $roster"; fi

  local loops_status="fail" loops_reason=""
  if [[ -d "$loops_dir" ]]; then loops_status="pass"
  else loops_status="warn"; loops_reason="loops dir absent: $loops_dir"; fi

  local am_state_status="fail" am_state_reason=""
  if [[ -d "$agent_mail_state" ]]; then am_state_status="pass"
  else am_state_status="warn"; am_state_reason="agent-mail state dir absent: $agent_mail_state"; fi

  local overall="pass" s
  for s in "$py_status" "$ntm_status"; do
    if [[ "$s" == "fail" ]]; then overall="fail"; fi
  done
  if [[ "$overall" == "pass" ]]; then
    for s in "$am_cli_status" "$topo_status" "$roster_status" "$loops_status" "$am_state_status"; do
      if [[ "$s" == "warn" ]]; then overall="warn"; fi
    done
  fi

  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg overall "$overall" \
    --arg py_s "$py_status" --arg py_r "$py_reason" \
    --arg ntm "$ntm_bin" --arg ntm_s "$ntm_status" --arg ntm_r "$ntm_reason" \
    --arg am_cli "$agent_mail_cli" --arg am_s "$am_cli_status" --arg am_r "$am_cli_reason" \
    --arg topo "$topology" --arg topo_s "$topo_status" --arg topo_r "$topo_reason" \
    --arg roster "$roster" --arg roster_s "$roster_status" --arg roster_r "$roster_reason" \
    --arg loops "$loops_dir" --arg loops_s "$loops_status" --arg loops_r "$loops_reason" \
    --arg am_st "$agent_mail_state" --arg am_st_s "$am_state_status" --arg am_st_r "$am_state_reason" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$overall,checks:[
      {name:"python3_on_path",status:$py_s,reason:$py_r},
      {name:"ntm_binary_executable",status:$ntm_s,path:$ntm,reason:$ntm_r},
      {name:"agent_mail_cli_executable",status:$am_s,path:$am_cli,reason:$am_r},
      {name:"topology_readable",status:$topo_s,path:$topo,reason:$topo_r},
      {name:"roster_readable",status:$roster_s,path:$roster,reason:$roster_r},
      {name:"loops_dir_present",status:$loops_s,path:$loops,reason:$loops_r},
      {name:"agent_mail_state_present",status:$am_st_s,path:$am_st,reason:$am_st_r}
    ]}'
}

scaffold_cmd_health() {
  # Tail SCAFFOLD_AUDIT_LOG. Reports recent_count, last_run_ts, age_seconds,
  # distinct clients + verdicts. Warn stale >24h.
  local ts log_path tail_n=20 tail_lines total last_ts age_seconds distinct_clients distinct_verdicts
  ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  log_path="$SCAFFOLD_AUDIT_LOG"

  if [[ ! -f "$log_path" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$log_path" \
      '{schema_version:$sv,command:"health",ts:$ts,status:"warn",reason:"audit ledger absent (no historical runs yet)",audit_log:$log,recent_runs:0}'
    return 0
  fi

  tail_lines="$(tail -n "$tail_n" "$log_path" 2>/dev/null)"
  total="$(printf '%s\n' "$tail_lines" | grep -c . || true)"
  if [[ -z "$total" ]]; then total=0; fi
  set +e
  last_ts="$(printf '%s\n' "$tail_lines" | tail -1 | jq -r '.ts // ""' 2>/dev/null)"
  distinct_clients="$(printf '%s\n' "$tail_lines" | jq -r '.client // empty' 2>/dev/null | sort -u | tr '\n' ',' | sed 's/,$//')"
  distinct_verdicts="$(printf '%s\n' "$tail_lines" | jq -r '.verdict // empty' 2>/dev/null | sort -u | tr '\n' ',' | sed 's/,$//')"
  set -e

  if [[ -n "$last_ts" ]]; then
    local now_epoch last_epoch
    now_epoch="$(date -u +%s)"
    last_epoch="$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$last_ts" +%s 2>/dev/null || echo "$now_epoch")"
    age_seconds=$((now_epoch - last_epoch))
  else
    age_seconds=null
  fi

  local status="pass" reason=""
  if [[ "$total" -eq 0 ]]; then
    status="warn"; reason="empty tail"
  elif [[ "$age_seconds" != "null" && "$age_seconds" -gt 86400 ]]; then
    status="warn"; reason="last run >24h ago (stale)"
  fi

  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg status "$status" --arg reason "$reason" \
    --arg log "$log_path" \
    --argjson total "${total:-0}" \
    --arg last_ts "$last_ts" \
    --argjson age "${age_seconds:-null}" \
    --arg clients "$distinct_clients" --arg verdicts "$distinct_verdicts" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,reason:(if $reason == "" then null else $reason end),
      audit_log:$log,recent_runs:$total,
      last_run_ts:(if $last_ts == "" then null else $last_ts end),
      last_run_age_seconds:$age,
      recent_clients:($clients | split(",") | map(select(length > 0))),
      recent_verdicts:($verdicts | split(",") | map(select(length > 0)))}'
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
  # Per-scope repair: audit-log-rotate (5MB) + topology-prime (read-only).
  local log_path topology
  log_path="$SCAFFOLD_AUDIT_LOG"
  topology="$HOME/.local/state/flywheel/session-topology.jsonl"
  case "$scope" in
    audit-log-rotate)
      if [[ ! -f "$log_path" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg log "$log_path" \
          '{schema_version:$sv,command:"repair",status:"warn",mode:"dry_run",scope:$scope,reason:"audit ledger absent — nothing to rotate",log_path:$log}'
        return 0
      fi
      local size threshold=5242880 lines
      size="$(stat -f%z "$log_path" 2>/dev/null || stat -c%s "$log_path" 2>/dev/null || echo 0)"
      lines="$(wc -l <"$log_path" | tr -d ' ')"
      if [[ "$mode" == "apply" ]]; then
        if [[ "$size" -lt "$threshold" ]]; then
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg idem "$idem_key" \
            --argjson size "$size" --argjson threshold "$threshold" --argjson lines "$lines" \
            '{schema_version:$sv,command:"repair",status:"noop",mode:"apply",scope:$scope,idempotency_key:$idem,
              size_bytes:$size,threshold_bytes:$threshold,lines:$lines,note:"under threshold — no rotation needed"}'
        else
          local rotated="${log_path%.jsonl}.$(date -u +%Y%m%dT%H%M%SZ).jsonl"
          mv "$log_path" "$rotated"
          : > "$log_path"
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg idem "$idem_key" \
            --arg rotated "$rotated" --argjson size "$size" --argjson threshold "$threshold" --argjson lines "$lines" \
            '{schema_version:$sv,command:"repair",status:"ok",mode:"apply",scope:$scope,idempotency_key:$idem,
              rotated_to:$rotated,size_bytes:$size,threshold_bytes:$threshold,lines:$lines}'
        fi
      else
        local will_rotate="false"
        if [[ "$size" -ge "$threshold" ]]; then will_rotate="true"; fi
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" \
          --argjson size "$size" --argjson threshold "$threshold" --argjson lines "$lines" \
          --argjson will "$will_rotate" \
          '{schema_version:$sv,command:"repair",status:"plan",mode:"dry_run",scope:$scope,
            size_bytes:$size,threshold_bytes:$threshold,lines:$lines,will_rotate:$will,
            planned_actions:["rotate audit-log when --apply --idempotency-key KEY passed"]}'
      fi
      ;;
    topology-prime)
      if [[ ! -f "$topology" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg path "$topology" \
          '{schema_version:$sv,command:"repair",status:"warn",mode:"read_only",scope:$scope,reason:"topology absent",path:$path}'
        return 0
      fi
      local row_count distinct_sessions
      row_count="$(wc -l <"$topology" 2>/dev/null | tr -d ' ')"
      set +e
      distinct_sessions="$(jq -r '.session // empty' "$topology" 2>/dev/null | sort -u | tr '\n' ',' | sed 's/,$//')"
      set -e
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" \
        --arg path "$topology" --argjson rows "$row_count" --arg sessions "$distinct_sessions" \
        '{schema_version:$sv,command:"repair",status:"ok",mode:"read_only",scope:$scope,
          path:$path,row_count:$rows,
          distinct_sessions:($sessions | split(",") | map(select(length > 0))),
          note:"read-only probe of session-topology.jsonl"}'
      ;;
    ""|none)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg mode "$mode" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"info",mode:$mode,scope:$scope,reason:"no scope specified",valid_scopes:["audit-log-rotate","topology-prime"]}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg mode "$mode" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"refused",mode:$mode,scope:$scope,reason:"unknown scope",valid_scopes:["audit-log-rotate","topology-prime"]}'
      return 64
      ;;
  esac
}

scaffold_cmd_validate() {
  # Per-subject contract checks. Subjects: row / schema / config / topology / agent-mail.
  local subject="" row_json="" surface_arg=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --row-json=*) row_json="${1#--row-json=}"; subject="row"; shift ;;
      --row-json) row_json="${2:-}"; subject="row"; shift 2 ;;
      --surface=*) surface_arg="${1#--surface=}"; subject="schema"; shift ;;
      --surface) surface_arg="${2:-}"; subject="schema"; shift 2 ;;
      --config) subject="config"; shift ;;
      --topology) subject="topology"; shift ;;
      --agent-mail) subject="agent-mail"; shift ;;
      --json) shift ;;
      -h|--help) scaffold_emit_topic_help validate; return 0 ;;
      *) printf 'ERR: unknown validate arg: %s\n' "$1" >&2; return 64 ;;
    esac
  done

  case "$subject" in
    row)
      if [[ -z "$row_json" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"validate",status:"refused",reason:"--row-json=JSON required for subject=row"}'
        return 64
      fi
      local required='["ts","command","schema_version"]'
      local valid missing
      set +e
      valid="$(printf '%s' "$row_json" | jq -e '. | type == "object"' >/dev/null 2>&1 && echo true || echo false)"
      missing="$(printf '%s' "$row_json" | jq -c --argjson req "$required" '$req - keys' 2>/dev/null || echo "[]")"
      set -e
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --argjson valid "$valid" --argjson missing "$missing" \
        '{schema_version:$sv,command:"validate",subject:"row",
          status:(if ($valid and ($missing | length == 0)) then "pass" else "fail" end),
          valid:$valid,missing_required:$missing}'
      ;;
    schema)
      if [[ -z "$surface_arg" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"validate",status:"refused",reason:"--surface=NAME required for subject=schema"}'
        return 64
      fi
      local schema_out
      schema_out="$(scaffold_emit_schema "$surface_arg")"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surf "$surface_arg" --argjson schema "$schema_out" \
        '{schema_version:$sv,command:"validate",subject:"schema",surface:$surf,status:"pass",schema:$schema}'
      ;;
    config)
      local missing=()
      command -v python3 >/dev/null 2>&1 || missing+=("python3:not_on_path")
      [[ -x /Users/josh/.local/bin/ntm ]] || missing+=("ntm:/Users/josh/.local/bin/ntm")
      [[ -x /Users/josh/.local/bin/agent-mail ]] || missing+=("agent-mail:/Users/josh/.local/bin/agent-mail (warn)")
      [[ -f "$HOME/.config/ntm/config.toml" ]] || missing+=("ntm_config:~/.config/ntm/config.toml")
      local missing_json
      if [[ ${#missing[@]} -eq 0 ]]; then
        missing_json='[]'
      else
        missing_json="$(printf '%s\n' "${missing[@]}" | jq -R . | jq -sc .)"
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        --argjson missing "$missing_json" \
        '{schema_version:$sv,command:"validate",subject:"config",
          status:(if ($missing | length) == 0 then "pass" else "fail" end),
          missing:$missing}'
      ;;
    topology)
      local topo2 lines_total lines_valid
      topo2="$HOME/.local/state/flywheel/session-topology.jsonl"
      if [[ ! -f "$topo2" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg path "$topo2" \
          '{schema_version:$sv,command:"validate",subject:"topology",status:"warn",reason:"topology absent",path:$path}'
        return 0
      fi
      lines_total=0; lines_valid=0
      while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        lines_total=$((lines_total + 1))
        if printf '%s' "$line" | jq -e . >/dev/null 2>&1; then
          lines_valid=$((lines_valid + 1))
        fi
      done < <(tail -n 100 "$topo2")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg path "$topo2" \
        --argjson total "$lines_total" --argjson valid "$lines_valid" \
        '{schema_version:$sv,command:"validate",subject:"topology",path:$path,
          status:(if $valid == $total then "pass" else "warn" end),
          tail_total:$total,tail_valid_json:$valid}'
      ;;
    agent-mail)
      # Probe liveness endpoint.
      local liveness_url="http://127.0.0.1:8765/health/liveness"
      local http_code
      set +e
      http_code="$(curl -sS -o /dev/null -w "%{http_code}" --max-time 3 "$liveness_url" 2>/dev/null)"
      set -e
      local status="warn"
      if [[ "$http_code" == "200" ]]; then status="pass"; fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg url "$liveness_url" --arg status "$status" --arg code "$http_code" \
        '{schema_version:$sv,command:"validate",subject:"agent-mail",
          liveness_url:$url,status:$status,http_code:$code,
          note:"probe agent-mail HTTP liveness endpoint"}'
      ;;
    "")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",status:"info",reason:"no subject specified",valid_subjects:["row","schema","config","topology","agent-mail"]}'
      ;;
  esac
}

scaffold_cmd_audit() {
  local tail_n=10
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --tail=*) tail_n="${1#--tail=}"; shift ;;
      --tail) tail_n="${2:-10}"; shift 2 ;;
      --json) shift ;;
      -h|--help) scaffold_emit_topic_help audit; return 0 ;;
      *) printf 'ERR: unknown audit arg: %s\n' "$1" >&2; return 64 ;;
    esac
  done
  if command -v cli_emit_audit_tail >/dev/null 2>&1; then
    cli_emit_audit_tail "$SCAFFOLD_AUDIT_LOG" "$SCAFFOLD_SCHEMA_VERSION" "$tail_n"
    return 0
  fi
  if [[ ! -f "$SCAFFOLD_AUDIT_LOG" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg log "$SCAFFOLD_AUDIT_LOG" --argjson tail_n "$tail_n" \
      '{schema_version:$sv,command:"audit",audit_log:$log,tail_n:$tail_n,status:"warn",reason:"audit ledger absent",rows:[],count:0}'
    return 0
  fi
  local rows count
  set +e
  rows="$(tail -n "$tail_n" "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | jq -sc '.' 2>/dev/null)"
  set -e
  if [[ -z "$rows" ]]; then rows='[]'; fi
  count="$(echo "$rows" | jq 'length' 2>/dev/null || echo 0)"
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg log "$SCAFFOLD_AUDIT_LOG" \
    --argjson tail_n "$tail_n" --argjson count "$count" --argjson rows "$rows" \
    '{schema_version:$sv,command:"audit",audit_log:$log,tail_n:$tail_n,count:$count,rows:$rows}'
}

scaffold_cmd_why() {
  local id="${1:-}"
  if [[ -z "$id" ]]; then
    printf 'ERR: why requires <id> argument\n' >&2; return 64
  fi
  # Provenance lookup: search SCAFFOLD_AUDIT_LOG for matching client or check.
  local log_path="$SCAFFOLD_AUDIT_LOG"
  if [[ ! -f "$log_path" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" --arg log "$log_path" \
      '{schema_version:$sv,command:"why",id:$id,status:"unavailable",reason:"audit ledger absent",audit_log:$log}'
    return 0
  fi
  local row
  row="$(grep -E "\"(client|check)\":\"$id\"" "$log_path" 2>/dev/null | tail -1 || true)"
  if [[ -z "$row" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" --arg log "$log_path" \
      '{schema_version:$sv,command:"why",id:$id,status:"not_found",reason:"id not in audit ledger",audit_log:$log}'
    return 0
  fi
  if ! printf '%s' "$row" | jq -e . >/dev/null 2>&1; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" --arg raw "$(printf '%s' "$row" | head -c 512)" \
      '{schema_version:$sv,command:"why",id:$id,status:"unavailable",reason:"matched row is not valid JSON",raw_preview:$raw}'
    return 0
  fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" --argjson row "$row" \
    '{schema_version:$sv,command:"why",id:$id,status:"found",
      provenance:{
        ts:($row.ts // null),
        check:($row.check // null),
        client:($row.client // null),
        verdict:($row.verdict // null),
        blockers:($row.blockers // null)
      },
      row:$row}'
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
python3 - "$@" <<'PY'
import argparse
import json
import os
import shutil
import stat
import subprocess
import sys
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

SCHEMA_VERSION = "recovery-preinstall-audit/v1"
SOURCE_PLAN = ".flywheel/PLANS/recovery-system-2026-05-01/00-PLAN.md"
NTM_BIN = "/Users/josh/.local/bin/ntm"
NTM_CONFIG = "~/.config/ntm/config.toml"
TOPOLOGY = "~/.local/state/flywheel/session-topology.jsonl"
ROSTER = "~/.local/state/flywheel/team-roster.jsonl"
LOOPS_DIR = "~/.flywheel/loops"
AGENT_MAIL_STATE = "~/.local/state/flywheel/agent-mail"
AGENT_MAIL_CLI = "/Users/josh/.local/bin/agent-mail"
AGENT_MAIL_LIVENESS = "http://127.0.0.1:8765/health/liveness"


def now_iso():
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def ep(path):
    return Path(path).expanduser()


def as_abs(path):
    if path is None:
        return None
    try:
        return str(ep(path).resolve(strict=False))
    except OSError:
        return str(ep(path).absolute())


def same_path(left, right):
    return bool(left and right and as_abs(left) == as_abs(right))


def read_jsonl(path):
    rows = []
    p = ep(path)
    if not p.exists():
        return rows
    for line_no, line in enumerate(p.read_text(encoding="utf-8", errors="replace").splitlines(), start=1):
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except json.JSONDecodeError:
            rows.append({"_parse_error": True, "_line": line_no})
            continue
        if isinstance(row, dict):
            row["_line"] = line_no
            rows.append(row)
    return rows


def merge_latest_by_session(rows):
    merged = {}
    for row in rows:
        session = row.get("session")
        if not session:
            continue
        target = merged.setdefault(str(session), {"session": str(session), "_sources": []})
        target["_sources"].append({"line": row.get("_line"), "ts": row.get("effective_at") or row.get("ts")})
        for key, value in row.items():
            if key.startswith("_") or value in (None, "", [], {}):
                continue
            target[key] = value
    return merged


def parse_session_paths(config_path):
    p = ep(config_path)
    if not p.exists():
        return {}, {"exists": False, "path": str(p)}
    lines = p.read_text(encoding="utf-8", errors="replace").splitlines()
    in_table = False
    paths = {}
    for line in lines:
        stripped = line.strip()
        if stripped.startswith("[") and stripped.endswith("]"):
            in_table = stripped == "[session_paths]"
            continue
        if not in_table or "=" not in line:
            continue
        key, value = line.split("=", 1)
        key = key.strip().strip("'\"")
        value = value.split("#", 1)[0].strip().strip("'\"")
        if key and value:
            paths[key] = value
    return paths, {"exists": True, "path": str(p)}


def run_cmd(args, timeout=5, env=None, cwd=None):
    try:
        proc = subprocess.run(args, text=True, capture_output=True, timeout=timeout, env=env, cwd=cwd)
        return {
            "ok": proc.returncode == 0,
            "rc": proc.returncode,
            "stdout": proc.stdout.strip(),
            "stderr": proc.stderr.strip(),
        }
    except FileNotFoundError:
        return {"ok": False, "rc": 127, "stdout": "", "stderr": "command_not_found"}
    except subprocess.TimeoutExpired:
        return {"ok": False, "rc": 124, "stdout": "", "stderr": "timeout"}


def ntm_sessions(ntm_bin):
    result = run_cmd([ntm_bin, "list", "--json"], timeout=8)
    names = []
    parsed = None
    if result["ok"]:
        try:
            parsed = json.loads(result["stdout"] or "{}")
            raw_sessions = parsed if isinstance(parsed, list) else parsed.get("sessions", [])
            for item in raw_sessions:
                if isinstance(item, dict):
                    name = item.get("name") or item.get("session")
                    if name:
                        names.append(str(name))
        except json.JSONDecodeError as exc:
            result["ok"] = False
            result["stderr"] = f"invalid_json: {exc}"
    return names, {"path": ntm_bin, "result": result, "parsed": parsed}


def loop_states(loops_dir):
    states = {}
    base = ep(loops_dir)
    if not base.exists():
        return states
    for path in sorted(base.glob("*.json")):
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
        except Exception as exc:
            payload = {"parse_error": str(exc)}
        session = payload.get("session") if isinstance(payload, dict) else None
        states[session or path.stem] = {"path": str(path), "payload": payload}
    return states


def candidate_projects(config_paths, topology, roster, loops):
    projects = {}
    for session, path in config_paths.items():
        projects.setdefault(as_abs(path), {"repo_path": as_abs(path), "sessions": set(), "sources": set()})
        projects[as_abs(path)]["sessions"].add(session)
        projects[as_abs(path)]["sources"].add("ntm_config")
    for source_name, rows in (("topology", topology), ("team_roster", roster)):
        for session, row in rows.items():
            path = row.get("repo_path") or row.get("agent_mail_project")
            if not path:
                continue
            key = as_abs(path)
            projects.setdefault(key, {"repo_path": key, "sessions": set(), "sources": set()})
            projects[key]["sessions"].add(session)
            projects[key]["sources"].add(source_name)
    for session, row in loops.items():
        payload = row.get("payload") if isinstance(row, dict) else {}
        path = payload.get("repo") or payload.get("repo_path") or payload.get("project_path")
        if not path:
            continue
        key = as_abs(path)
        projects.setdefault(key, {"repo_path": key, "sessions": set(), "sources": set()})
        projects[key]["sessions"].add(session)
        projects[key]["sources"].add("loop_state")
    clean = []
    for item in projects.values():
        if item["repo_path"]:
            clean.append({
                "repo_path": item["repo_path"],
                "sessions": sorted(item["sessions"]),
                "sources": sorted(item["sources"]),
            })
    return sorted(clean, key=lambda x: x["repo_path"])


def score_session(session, executable_path, live_sessions, topology_row, roster_row, loop_row, dispatch_exists, confidence_min):
    topology_path = topology_row.get("repo_path") or topology_row.get("agent_mail_project") if topology_row else None
    roster_path = roster_row.get("repo_path") or roster_row.get("agent_mail_project") if roster_row else None
    topology_match = same_path(executable_path, topology_path)
    roster_match = same_path(executable_path, roster_path)
    score = 0
    reasons = []
    if session in live_sessions:
        score += 20
        reasons.append("ntm_list")
    if executable_path and ep(executable_path).exists():
        score += 20
        reasons.append("executable_path_exists")
    if topology_match:
        score += 20
        reasons.append("topology_match")
    elif topology_row:
        score += 8
        reasons.append("topology_seen")
    if roster_match:
        score += 20
        reasons.append("roster_match")
    elif roster_row:
        score += 8
        reasons.append("roster_seen")
    if loop_row:
        score += 10
        reasons.append("loop_state")
    if dispatch_exists:
        score += 10
        reasons.append("dispatch_log")
    return {
        "session": session,
        "executable_path": as_abs(executable_path) if executable_path else None,
        "topology_match": topology_match,
        "roster_match": roster_match,
        "confidence": min(score, 100),
        "confidence_min": confidence_min,
        "low_confidence": score < confidence_min,
        "evidence": reasons,
        "topology_path": as_abs(topology_path) if topology_path else None,
        "roster_path": as_abs(roster_path) if roster_path else None,
        "live_in_ntm": session in live_sessions,
    }


def check_beads_db(repo_path):
    db = Path(repo_path) / ".beads" / "beads.db"
    if not db.exists():
        return {"path": str(db), "exists": False, "integrity": "missing"}
    sqlite = shutil.which("sqlite3")
    if not sqlite:
        return {"path": str(db), "exists": True, "integrity": "sqlite3_unavailable"}
    result = run_cmd([sqlite, "-readonly", str(db), "PRAGMA integrity_check;"], timeout=10)
    stdout = result.get("stdout", "")
    return {
        "path": str(db),
        "exists": True,
        "integrity": "ok" if result["ok"] and stdout.splitlines()[:1] == ["ok"] else "failed",
        "sqlite_rc": result["rc"],
        "sqlite_stdout": stdout[:400],
        "sqlite_stderr": result.get("stderr", "")[:400],
    }


def dirty_worktree(repo_path, owners):
    git_dir = Path(repo_path) / ".git"
    if not git_dir.exists():
        return {"is_git_repo": False, "dirty_count": 0, "dirty_paths_sample": [], "owner_map": owners}
    result = run_cmd(["git", "-C", repo_path, "status", "--porcelain=v1"], timeout=10)
    paths = []
    if result["ok"]:
        for line in result["stdout"].splitlines():
            if line:
                paths.append(line[3:] if len(line) > 3 else line)
    return {
        "is_git_repo": True,
        "dirty_count": len(paths),
        "dirty_paths_sample": paths[:25],
        "owner_map": owners,
        "status_rc": result["rc"],
    }


def scan_agent_mail_identities(state_dir):
    sessions_dir = ep(state_dir) / "sessions"
    tokens_dir = ep(state_dir) / "tokens"
    identities = []
    if not sessions_dir.exists():
        return identities
    for path in sorted(sessions_dir.glob("*.json")):
        try:
            row = json.loads(path.read_text(encoding="utf-8"))
        except Exception as exc:
            identities.append({"path": str(path), "parse_error": str(exc), "ready": False})
            continue
        identity = row.get("identity_name") or row.get("agent_name") or row.get("name")
        token_path = row.get("token_path")
        if not token_path and identity:
            token_path = str(tokens_dir / f"{identity}.token")
        token = ep(token_path) if token_path else None
        mode = None
        token_exists = bool(token and token.exists())
        if token_exists:
            mode = stat.S_IMODE(token.stat().st_mode)
        ready = bool(identity and token_exists and mode == 0o600 and row.get("status") not in ("inactive", "archived"))
        identities.append({
            "path": str(path),
            "session": row.get("session"),
            "pane": row.get("pane"),
            "identity_name": identity,
            "status": row.get("status"),
            "role": row.get("role"),
            "token_path": str(token) if token else None,
            "token_exists": token_exists,
            "token_mode_octal": format(mode, "04o") if mode is not None else None,
            "ready": ready,
        })
    return identities


def agent_mail_readiness(args):
    health = {"url": args.agent_mail_liveness_url, "ok": False, "status": "unreachable"}
    try:
        with urllib.request.urlopen(args.agent_mail_liveness_url, timeout=3) as resp:
            body = resp.read(4096).decode("utf-8", errors="replace")
            try:
                parsed = json.loads(body)
            except json.JSONDecodeError:
                parsed = {"raw": body}
            health = {"url": args.agent_mail_liveness_url, "ok": 200 <= resp.status < 300, "http_status": resp.status, "payload": parsed}
    except (urllib.error.URLError, TimeoutError, OSError) as exc:
        health["error"] = str(exc)
    env = dict(os.environ)
    env.pop("DATABASE_URL", None)
    cli_result = run_cmd([args.agent_mail_cli, "--version"], timeout=5, env=env)
    if not cli_result["ok"]:
        cli_result = run_cmd([args.agent_mail_cli, "--help"], timeout=5, env=env)
    identities = scan_agent_mail_identities(args.agent_mail_state_dir)
    return {
        "service_liveness": health,
        "cli_without_database_url": cli_result,
        "identity_registry_dir": str(ep(args.agent_mail_state_dir) / "sessions"),
        "identities": identities,
        "ready_identity_count": sum(1 for row in identities if row.get("ready")),
        "identity_count": len(identities),
    }


def repo_owners(repo_path, roster, identities):
    owners = []
    for session, row in roster.items():
        if same_path(repo_path, row.get("repo_path") or row.get("agent_mail_project")):
            owners.append({
                "source": "team_roster",
                "session": session,
                "orchestrator": row.get("orchestrator"),
                "workers": row.get("workers") or row.get("worker_panes") or [],
                "agent_mail_identity": row.get("agent_mail_identity") or row.get("fleet_mail_identity"),
            })
    for identity in identities:
        session = identity.get("session")
        if session and session in roster and same_path(repo_path, roster[session].get("repo_path") or roster[session].get("agent_mail_project")):
            owners.append({
                "source": "agent_mail_identity",
                "session": session,
                "pane": identity.get("pane"),
                "identity_name": identity.get("identity_name"),
                "ready": identity.get("ready"),
            })
    return owners


def recent_tick_receipts(projects, limit):
    names = [
        ".flywheel/last_closeout_receipt.json",
        ".flywheel/runtime/flywheel-loop/last_run.json",
        ".flywheel/runtime/tick/last_run.json",
    ]
    receipts = []
    for project in projects:
        repo = project["repo_path"]
        for rel in names:
            path = Path(repo) / rel
            if not path.exists():
                continue
            try:
                stat_row = path.stat()
                payload = json.loads(path.read_text(encoding="utf-8"))
                receipts.append({
                    "repo_path": repo,
                    "path": str(path),
                    "mtime": datetime.fromtimestamp(stat_row.st_mtime, timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
                    "payload_keys": sorted(payload.keys()) if isinstance(payload, dict) else [],
                })
            except Exception as exc:
                receipts.append({"repo_path": repo, "path": str(path), "error": str(exc)})
    return sorted(receipts, key=lambda x: x.get("mtime", ""), reverse=True)[:limit]


def dispatch_context(projects, line_limit):
    contexts = []
    dispatch_events = {"dispatch_sent", "worker_dispatch", "dispatch", "sent"}
    callback_markers = {"callback", "callback_received", "done", "blocked", "closed", "complete"}
    for project in projects:
        path = Path(project["repo_path"]) / ".flywheel" / "dispatch-log.jsonl"
        rows = read_jsonl(path)
        task_state = {}
        for row in rows:
            task_id = row.get("task_id") or row.get("bead_id") or row.get("bead")
            if not task_id:
                continue
            state = task_state.setdefault(str(task_id), {"task_id": str(task_id), "last_line": row.get("_line"), "last_event": row.get("event"), "has_dispatch": False, "has_callback": False})
            event = str(row.get("event") or row.get("callback_status") or row.get("status") or "").lower()
            if event in dispatch_events or row.get("task_file") or row.get("prompt_path"):
                state["has_dispatch"] = True
            if any(marker in event for marker in callback_markers) or row.get("callback_received_at"):
                state["has_callback"] = True
            state["last_line"] = row.get("_line")
            state["last_event"] = event
        inflight = [row for row in task_state.values() if row["has_dispatch"] and not row["has_callback"]]
        contexts.append({
            "repo_path": project["repo_path"],
            "path": str(path),
            "exists": path.exists(),
            "row_count": len(rows),
            "recent_rows": rows[-line_limit:],
            "in_flight": inflight,
            "in_flight_count": len(inflight),
        })
    return contexts


def build_report(args):
    config_paths, config_meta = parse_session_paths(args.ntm_config)
    live_sessions, ntm_meta = ntm_sessions(args.ntm_bin)
    topology_rows = merge_latest_by_session(read_jsonl(args.topology))
    roster_rows = merge_latest_by_session(read_jsonl(args.team_roster))
    loops = loop_states(args.loops_dir)
    projects = candidate_projects(config_paths, topology_rows, roster_rows, loops)
    dispatch_exists = {
        session: Path(as_abs(path) or "").joinpath(".flywheel/dispatch-log.jsonl").exists()
        for session, path in config_paths.items()
    }
    sessions = sorted(set(live_sessions) | set(config_paths) | set(topology_rows) | set(roster_rows) | set(loops))
    session_rows = []
    for session in sessions:
        exe = config_paths.get(session)
        if not exe:
            exe = (topology_rows.get(session) or {}).get("repo_path") or (roster_rows.get(session) or {}).get("repo_path")
        session_rows.append(score_session(
            session,
            exe,
            live_sessions,
            topology_rows.get(session),
            roster_rows.get(session),
            loops.get(session),
            dispatch_exists.get(session, False),
            args.confidence_min,
        ))
    mail = agent_mail_readiness(args)
    project_rows = []
    for project in projects:
        owners = repo_owners(project["repo_path"], roster_rows, mail["identities"])
        row = dict(project)
        row["beads_db"] = check_beads_db(project["repo_path"])
        row["dirty_worktree"] = dirty_worktree(project["repo_path"], owners)
        project_rows.append(row)
    low = [row for row in session_rows if row["low_confidence"]]
    report = {
        "schema_version": SCHEMA_VERSION,
        "source_plan": SOURCE_PLAN,
        "generated_at": args.now or now_iso(),
        "repo": as_abs(args.repo),
        "selected_session": args.session,
        "confidence_min": args.confidence_min,
        "confidence_per_session": {row["session"]: row["confidence"] for row in session_rows},
        "apply_blocked": bool(low),
        "low_confidence_sessions": [row["session"] for row in low],
        "sources": {
            "ntm_bin": ntm_meta,
            "ntm_config": config_meta,
            "topology": str(ep(args.topology)),
            "team_roster": str(ep(args.team_roster)),
            "loops_dir": str(ep(args.loops_dir)),
            "agent_mail_state_dir": str(ep(args.agent_mail_state_dir)),
        },
        "sessions": session_rows,
        "projects": project_rows,
        "agent_mail": mail,
        "loop_state": loops,
        "tick_receipts": recent_tick_receipts(projects, args.receipt_limit),
        "dispatch_context": dispatch_context(projects, args.dispatch_log_limit),
    }
    return report


def main(argv):
    parser = argparse.ArgumentParser(description="Read-only recovery-system preinstall audit.")
    parser.add_argument("--repo", default="/Users/josh/Developer/flywheel")
    parser.add_argument("--session")
    parser.add_argument("--ntm-bin", default=NTM_BIN)
    parser.add_argument("--ntm-config", default=NTM_CONFIG)
    parser.add_argument("--topology", default=TOPOLOGY)
    parser.add_argument("--team-roster", default=ROSTER)
    parser.add_argument("--loops-dir", default=LOOPS_DIR)
    parser.add_argument("--agent-mail-state-dir", default=AGENT_MAIL_STATE)
    parser.add_argument("--agent-mail-cli", default=AGENT_MAIL_CLI)
    parser.add_argument("--agent-mail-liveness-url", default=AGENT_MAIL_LIVENESS)
    parser.add_argument("--confidence-min", type=int, default=70)
    parser.add_argument("--dispatch-log-limit", type=int, default=8)
    parser.add_argument("--receipt-limit", type=int, default=20)
    parser.add_argument("--now")
    parser.add_argument("--output")
    parser.add_argument("--json", action="store_true", help="Compatibility flag; output is always JSON.")
    parser.add_argument("--pretty", action="store_true")
    args = parser.parse_args(argv)
    report = build_report(args)
    text = json.dumps(report, indent=2 if args.pretty else None, sort_keys=True) + "\n"
    if args.output:
        out = ep(args.output)
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(text, encoding="utf-8")
    sys.stdout.write(text)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
PY
