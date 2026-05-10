#!/usr/bin/env bash
# Read skill_version from tick.md, compare to canonical design ref version.
# Exit 0: versions match. Exit 1: drift detected.
set -euo pipefail


# ====== BEGIN canonical-cli scaffold (bead flywheel-ws02m) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (TODO markers in stubs need fill-in)
# doctor-mode-tier: scaffolded (bead flywheel-ws02m)
#
# This block was scaffolded by scaffold-canonical-cli.sh. The original
# top-level dispatch is preserved as `cmd_run` (the new main routes
# default invocation through cmd_run for backward compat). Surface-
# specific logic was filled in by bead flywheel-wzjo9.3.8 (no remaining
# scaffold stubs). Smallest surface in wave-2.0c (37 → 760 lines).

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="tick-skill-version-check/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/tick-skill-version-check-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: tick-skill-version-check.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "tick-skill-version-check.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "tick-skill-version-check.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"tick-skill-version-check.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"tick-skill-version-check.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"tick-skill-version-check.sh doctor --json"}'
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
          valid_scopes:["audit-log-rotate","expected-version-prime"],
          mutation_gates:["--apply requires --idempotency-key"]}'
      ;;
    validate)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,
          required:["status","subject"],valid_subjects:["row","schema","config","tick-md"],
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
          provenance_fields:["ts","loaded_version","expected_version","drift"]}'
      ;;
    audit-row|run)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,
          required:["ts","command","schema_version"],
          optional:["loaded_version","expected_version","drift","tick_md_path"],
          purpose:"row shape written to SCAFFOLD_AUDIT_LOG by cmd_run terminal envelopes"}'
      ;;
    default|*)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,
          surfaces:["doctor","health","repair","validate","audit","why","audit-row","default"],
          purpose:"tick.md skill_version drift detector — compares declared skill_version in ~/.claude/commands/flywheel/tick.md to hardcoded EXPECTED_VERSION; substrate-level canonical layer over cmd_run bash logic",
          stable_exit_codes:{"0":"versions match","1":"drift detected OR missing declaration","2":"tick.md not found","3":"refused (--apply without --idempotency-key)","64":"bad args"}}'
      ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  local _runs="${SCAFFOLD_AUDIT_LOG:-${HOME}/.local/state/flywheel/tick-skill-version-check-runs.jsonl}"
  case "$topic" in
    run)
      printf 'topic: run — default backward-compatible invocation routes to cmd_run. Reads skill_version from ~/.claude/commands/flywheel/tick.md, compares to hardcoded EXPECTED_VERSION constant. Exit 0=match, 1=drift, 2=tick.md not found.\n'
      ;;
    doctor)
      printf 'topic: doctor — substrate health probes (tick.md present, design doc present, grep + awk on PATH). Per-version comparison lives in cmd_run.\n'
      ;;
    health)
      printf 'topic: health — recent drift-check summary from %s (recent_count, last_run_ts, age_seconds, distinct loaded_versions seen, drift_count). Warn when ledger absent or stale (>7d — version drift is checked weekly minimum).\n' "$_runs"
      ;;
    repair)
      printf 'topic: repair — read-only by default; mutate with --apply --idempotency-key KEY. Scopes: audit-log-rotate (rotate %s when >5MB), expected-version-prime (read-only probe of EXPECTED_VERSION constant in this script — emits current value).\n' "$_runs"
      ;;
    validate)
      printf 'topic: validate — per-subject contract checks. Subjects: row (--row-json=JSON validates audit-log row schema), schema (--surface=NAME re-emits the schema), config (env: tick.md, design doc, grep/awk on PATH), tick-md (probe tick.md presence + skill_version declaration regex match).\n'
      ;;
    audit)
      printf 'topic: audit — tail %s (default --tail=10). Returns rows[] with ts, loaded_version, expected_version, drift, tick_md_path.\n' "$_runs"
      ;;
    why)
      printf 'topic: why <id> — provenance lookup by loaded_version or tick_md_path basename in the audit log; emits ts/loaded_version/expected_version/drift or status=not_found.\n'
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
            && cli_emit_completion_bash "tick-skill-version-check" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "tick-skill-version-check" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  # 5 named substrate probes for tick-skill-version-check.
  local ts tick_md design_dir design_doc
  ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  tick_md="$HOME/.claude/commands/flywheel/tick.md"
  design_dir="$HOME/.local/state/flywheel/joint-deepdive-2026-05-01"
  design_doc="$design_dir/orch-tick-bead-discipline-design.md"

  local tick_status="fail" tick_reason=""
  if [[ -f "$tick_md" ]]; then tick_status="pass"
  else tick_reason="tick.md not found: $tick_md"; fi

  local design_status="fail" design_reason=""
  if [[ -f "$design_doc" ]]; then design_status="pass"
  else design_status="warn"; design_reason="design doc absent: $design_doc"; fi

  local grep_status="fail" grep_reason=""
  if command -v grep >/dev/null 2>&1; then grep_status="pass"
  else grep_reason="grep not on PATH"; fi

  # Detect skill_version declaration in tick.md (live signal)
  local declared_version=""
  if [[ "$tick_status" == "pass" ]]; then
    declared_version="$(grep -m1 -oE 'skill_version:[[:space:]]*[0-9]+' "$tick_md" 2>/dev/null | grep -oE '[0-9]+' || true)"
  fi
  local declared_status="fail" declared_reason=""
  if [[ -n "$declared_version" ]]; then declared_status="pass"; declared_reason="skill_version=$declared_version declared in tick.md"
  else declared_status="warn"; declared_reason="no skill_version declaration in tick.md"; fi

  # The hardcoded EXPECTED_VERSION constant in cmd_run (probe by grep)
  local expected_version
  expected_version="$(grep -m1 -oE 'EXPECTED_VERSION=[0-9]+' "${BASH_SOURCE[0]}" 2>/dev/null | grep -oE '[0-9]+' || echo unknown)"
  local expected_status="pass" expected_reason="hardcoded EXPECTED_VERSION=$expected_version"

  local overall="pass" s
  for s in "$tick_status" "$grep_status"; do
    if [[ "$s" == "fail" ]]; then overall="fail"; fi
  done
  if [[ "$overall" == "pass" && ( "$design_status" == "warn" || "$declared_status" == "warn" ) ]]; then
    overall="warn"
  fi

  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg overall "$overall" \
    --arg tick "$tick_md" --arg tick_s "$tick_status" --arg tick_r "$tick_reason" \
    --arg design "$design_doc" --arg design_s "$design_status" --arg design_r "$design_reason" \
    --arg grep_s "$grep_status" --arg grep_r "$grep_reason" \
    --arg declared "$declared_version" --arg declared_s "$declared_status" --arg declared_r "$declared_reason" \
    --arg expected "$expected_version" --arg expected_s "$expected_status" --arg expected_r "$expected_reason" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$overall,checks:[
      {name:"tick_md_present",status:$tick_s,path:$tick,reason:$tick_r},
      {name:"design_doc_present",status:$design_s,path:$design,reason:$design_r},
      {name:"grep_on_path",status:$grep_s,reason:$grep_r},
      {name:"tick_md_skill_version_declared",status:$declared_s,value:$declared,reason:$declared_r},
      {name:"expected_version_constant",status:$expected_s,value:$expected,reason:$expected_r}
    ]}'
}

scaffold_cmd_health() {
  # Tail SCAFFOLD_AUDIT_LOG. Drift checks are weekly cadence — warn stale >7d.
  local ts log_path tail_n=20 tail_lines total last_ts age_seconds distinct_versions drift_count
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
  distinct_versions="$(printf '%s\n' "$tail_lines" | jq -r '.loaded_version // empty' 2>/dev/null | sort -u | tr '\n' ',' | sed 's/,$//')"
  drift_count="$(printf '%s\n' "$tail_lines" | jq -r 'select(.drift == true) | .ts' 2>/dev/null | grep -c . || echo 0)"
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
  elif [[ "$age_seconds" != "null" && "$age_seconds" -gt 604800 ]]; then
    status="warn"; reason="last drift check >7d ago (weekly cadence missed)"
  fi

  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg status "$status" --arg reason "$reason" \
    --arg log "$log_path" \
    --argjson total "${total:-0}" \
    --arg last_ts "$last_ts" \
    --argjson age "${age_seconds:-null}" \
    --arg versions "$distinct_versions" --argjson drift_count "$drift_count" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,reason:(if $reason == "" then null else $reason end),
      audit_log:$log,recent_runs:$total,
      last_run_ts:(if $last_ts == "" then null else $last_ts end),
      last_run_age_seconds:$age,
      recent_loaded_versions:($versions | split(",") | map(select(length > 0))),
      drift_events_in_tail:$drift_count}'
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
  # Per-scope repair: audit-log-rotate (5MB) + expected-version-prime (read-only).
  local log_path
  log_path="$SCAFFOLD_AUDIT_LOG"
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
    expected-version-prime)
      # Read-only probe of EXPECTED_VERSION constant in cmd_run.
      local expected
      expected="$(grep -m1 -oE 'EXPECTED_VERSION=[0-9]+' "${BASH_SOURCE[0]}" 2>/dev/null | grep -oE '[0-9]+' || echo unknown)"
      local tick_md="$HOME/.claude/commands/flywheel/tick.md"
      local declared
      declared="$(grep -m1 -oE 'skill_version:[[:space:]]*[0-9]+' "$tick_md" 2>/dev/null | grep -oE '[0-9]+' || echo none)"
      local drift="false"
      if [[ -n "$declared" && "$declared" != "none" && "$declared" != "$expected" ]]; then drift="true"; fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" \
        --arg expected "$expected" --arg declared "$declared" --argjson drift "$drift" \
        '{schema_version:$sv,command:"repair",status:"ok",mode:"read_only",scope:$scope,
          expected_version:$expected,declared_version:(if $declared == "none" then null else $declared end),
          drift:$drift,
          note:(if $drift then "DRIFT: declared != expected — ship new tick.md or bump EXPECTED_VERSION" else "match: declared == expected" end)}'
      ;;
    ""|none)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg mode "$mode" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"info",mode:$mode,scope:$scope,reason:"no scope specified",valid_scopes:["audit-log-rotate","expected-version-prime"]}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg mode "$mode" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"refused",mode:$mode,scope:$scope,reason:"unknown scope",valid_scopes:["audit-log-rotate","expected-version-prime"]}'
      return 64
      ;;
  esac
}

scaffold_cmd_validate() {
  # Per-subject contract checks. Subjects: row, schema, config, tick-md.
  local subject="" row_json="" surface_arg=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --row-json=*) row_json="${1#--row-json=}"; subject="row"; shift ;;
      --row-json) row_json="${2:-}"; subject="row"; shift 2 ;;
      --surface=*) surface_arg="${1#--surface=}"; subject="schema"; shift ;;
      --surface) surface_arg="${2:-}"; subject="schema"; shift 2 ;;
      --config) subject="config"; shift ;;
      --tick-md) subject="tick-md"; shift ;;
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
      local tick_md="$HOME/.claude/commands/flywheel/tick.md"
      local design_doc="$HOME/.local/state/flywheel/joint-deepdive-2026-05-01/orch-tick-bead-discipline-design.md"
      local missing=()
      [[ -f "$tick_md" ]] || missing+=("tick_md:$tick_md")
      [[ -f "$design_doc" ]] || missing+=("design_doc:$design_doc (warn)")
      command -v grep >/dev/null 2>&1 || missing+=("grep:not_on_path")
      local missing_json
      if [[ ${#missing[@]} -eq 0 ]]; then
        missing_json='[]'
      else
        missing_json="$(printf '%s\n' "${missing[@]}" | jq -R . | jq -sc .)"
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        --arg tick "$tick_md" --arg design "$design_doc" \
        --argjson missing "$missing_json" \
        '{schema_version:$sv,command:"validate",subject:"config",
          status:(if ($missing | length) == 0 then "pass" else "fail" end),
          tick_md:$tick,design_doc:$design,missing:$missing}'
      ;;
    tick-md)
      # Probe tick.md presence + skill_version declaration shape.
      local tick_md2="$HOME/.claude/commands/flywheel/tick.md"
      if [[ ! -f "$tick_md2" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg path "$tick_md2" \
          '{schema_version:$sv,command:"validate",subject:"tick-md",status:"fail",reason:"tick.md not found",path:$path}'
        return 0
      fi
      local declared
      declared="$(grep -m1 -oE 'skill_version:[[:space:]]*[0-9]+' "$tick_md2" 2>/dev/null | grep -oE '[0-9]+' || echo "")"
      local has_declaration="true"
      if [[ -z "$declared" ]]; then has_declaration="false"; declared="null"; fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg path "$tick_md2" \
        --argjson has "$has_declaration" --arg declared "$declared" \
        '{schema_version:$sv,command:"validate",subject:"tick-md",path:$path,
          status:(if $has then "pass" else "warn" end),
          has_skill_version_declaration:$has,
          declared_version:(if $declared == "null" then null else $declared end)}'
      ;;
    "")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",status:"info",reason:"no subject specified",valid_subjects:["row","schema","config","tick-md"]}'
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
  # Provenance lookup: search SCAFFOLD_AUDIT_LOG for matching loaded_version or tick_md_path basename.
  local log_path="$SCAFFOLD_AUDIT_LOG"
  if [[ ! -f "$log_path" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" --arg log "$log_path" \
      '{schema_version:$sv,command:"why",id:$id,status:"unavailable",reason:"audit ledger absent",audit_log:$log}'
    return 0
  fi
  local row
  row="$(grep -E "\"(loaded_version|tick_md_path)\":\"[^\"]*$id[^\"]*\"" "$log_path" 2>/dev/null | tail -1 || true)"
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
        loaded_version:($row.loaded_version // null),
        expected_version:($row.expected_version // null),
        drift:($row.drift // null),
        tick_md_path:($row.tick_md_path // null)
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
TICK_MD="$HOME/.claude/commands/flywheel/tick.md"
DESIGN_DIR="$HOME/.local/state/flywheel/joint-deepdive-2026-05-01"
DESIGN_DOC="$DESIGN_DIR/orch-tick-bead-discipline-design.md"

if [ ! -f "$TICK_MD" ]; then
  echo "ERROR: $TICK_MD not found" >&2
  exit 2
fi

if [ ! -f "$DESIGN_DOC" ]; then
  echo "WARN: design ref not found: $DESIGN_DOC" >&2
fi

LOADED_VERSION=$(grep -m1 -oE 'skill_version:[[:space:]]*[0-9]+' "$TICK_MD" | grep -oE '[0-9]+' || true)

if [ -z "$LOADED_VERSION" ]; then
  echo "WARN: tick.md has no skill_version declaration"
  echo "  Run: edit ~/.claude/commands/flywheel/tick.md and add: <!-- skill_version: N -->"
  exit 1
fi

# Canonical version is hardcoded in this validator — bump when shipping new tick.md.
EXPECTED_VERSION=2

if [ "$LOADED_VERSION" -eq "$EXPECTED_VERSION" ]; then
  echo "OK: tick.md skill_version=$LOADED_VERSION matches expected"
  exit 0
fi

echo "DRIFT: tick.md skill_version=$LOADED_VERSION but expected=$EXPECTED_VERSION"
echo "  Ship new tick.md or bump EXPECTED_VERSION in this validator after design+impl land."
exit 1
