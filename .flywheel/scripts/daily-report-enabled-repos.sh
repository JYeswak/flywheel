#!/usr/bin/env bash
# flywheel-cli-surface: true
# canonical-cli-scoping: passing
# doctor-mode-tier: upgraded (pilot bead flywheel-jloib via doctor-mode-integration chain)
#
# daily-report-enabled-repos.sh — fan-out daily-report.sh across repos with
# .flywheel/daily-report-config.json#enabled=true.
#
# Backward compat: invoking with no subcommand (or --date / --dry-run /
# --no-notify / --json) preserves the original report-generation behavior.
# New canonical-cli surface is additive: doctor, health, repair, validate,
# audit, why, quickstart, help, completion, plus --info/--schema/--examples.
set -euo pipefail

SCRIPT_VERSION="2026-05-10.2"
SCHEMA_VERSION="daily-report-enabled-repos/v1"

# Resolve symlinks so the lib source path works whether invoked directly or
# through a PATH symlink (the canonical-cli-scoping checker installs a symlink
# in $TMP/bin/).
__SELF_PATH="${BASH_SOURCE[0]}"
while [[ -L "$__SELF_PATH" ]]; do
  __SELF_LINK="$(readlink "$__SELF_PATH")"
  if [[ "$__SELF_LINK" == /* ]]; then
    __SELF_PATH="$__SELF_LINK"
  else
    __SELF_PATH="$(cd "$(dirname "$__SELF_PATH")" && pwd -P)/$__SELF_LINK"
  fi
done
ROOT="$(cd "$(dirname "$__SELF_PATH")/../.." && pwd -P)"
unset __SELF_PATH __SELF_LINK
# canonical-cli-helpers.sh provides cli_iso_now, cli_sha_self, cli_audit_append,
# cli_emit_info, cli_emit_examples, cli_emit_quickstart, cli_emit_completion_*,
# cli_refuse_apply_without_idem_key, cli_dispatch_subcommand_help,
# cli_emit_topic_help. Per-surface logic (cmd_*) stays inline.
# shellcheck source=/dev/null
source "$ROOT/.flywheel/lib/canonical-cli-helpers.sh"

GENERATOR="${FLYWHEEL_DAILY_REPORT_GENERATOR:-$ROOT/.flywheel/scripts/daily-report.sh}"
REPO_ROOTS="${FLYWHEEL_DAILY_REPORT_REPO_ROOTS:-$HOME/Developer}"
AUDIT_LOG="${FLYWHEEL_DAILY_REPORT_AUDIT_LOG:-$HOME/.local/state/flywheel/daily-report-enabled-runs.jsonl}"
STATE_DIR="${FLYWHEEL_DAILY_REPORT_STATE_DIR:-$HOME/.local/state/flywheel}"

# Thin wrappers preserved for any internal callsites; new code should call the
# cli_* helpers directly.
iso_now() { cli_iso_now; }
sha_self() { cli_sha_self "${BASH_SOURCE[0]}"; }

# ---------- canonical-cli-scoping surfaces ----------

usage() {
  cat <<'EOF'
usage: daily-report-enabled-repos.sh [SUBCOMMAND] [OPTIONS]

Fan-out daily-report.sh across repos with daily-report-config.json#enabled=true.

Run modes (default; backward-compatible):
  daily-report-enabled-repos.sh [--date YYYY-MM-DD] [--dry-run] [--no-notify] [--json]
  daily-report-enabled-repos.sh run [...same flags...]

Canonical CLI surfaces:
  doctor [--json]          Probe substrate health (generator path, repo roots, configs)
  health [--json]          Last-run status per enabled repo
  repair --scope <s>       Repair misconfigured repos
                            Default: --dry-run; mutate with --apply --idempotency-key KEY
                            Scopes: state | configs
  validate config [--json] Validate per-repo daily-report-config.json against schema
  audit [--json]           Show recent run history from audit log
  why <repo>               Explain why a specific repo is or is not enabled
  quickstart [--json]      Operator orientation
  help <topic>             Topic help (run | doctor | health | repair | validate)
  completion <shell>       Emit bash or zsh completion

Introspection:
  --info --json            Version, config paths, env vars, dependencies, sha256
  --schema [<surface>]     JSON Schema for output envelopes; --schema alone == default
  --examples --json        Curated workflow examples
  --help / -h              This help

Exit codes:
  0   success
  1   doctor/health/validate found issues; or report generation had failures
  2   one or more checks marked status=fail (strict mode in CI)
  3   refusal: --apply without --idempotency-key
  64  usage error (unknown flag, missing argument)
  65  IO error (path missing or unreadable)

Environment:
  FLYWHEEL_DAILY_REPORT_GENERATOR    Path to daily-report.sh
                                     (default: $ROOT/.flywheel/scripts/daily-report.sh)
  FLYWHEEL_DAILY_REPORT_REPO_ROOTS   Colon-separated repo root directories
                                     (default: ~/Developer)
  FLYWHEEL_DAILY_REPORT_AUDIT_LOG    JSONL audit log path
                                     (default: ~/.local/state/flywheel/daily-report-enabled-runs.jsonl)
  FLYWHEEL_DAILY_REPORT_STATE_DIR    State directory (default: ~/.local/state/flywheel)
EOF
}

emit_info() {
  local extra_paths
  extra_paths="$(jq -nc \
    --arg generator "$GENERATOR" \
    --arg audit_log "$AUDIT_LOG" \
    --arg state_dir "$STATE_DIR" \
    --arg repo_roots "$REPO_ROOTS" \
    '{generator:$generator,audit_log:$audit_log,state_dir:$state_dir,repo_roots:($repo_roots | split(":"))}')"
  cli_emit_info \
    "daily-report-enabled-repos.sh" \
    "$SCRIPT_VERSION" \
    "$SCHEMA_VERSION" \
    "run,doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "FLYWHEEL_DAILY_REPORT_GENERATOR,FLYWHEEL_DAILY_REPORT_REPO_ROOTS,FLYWHEEL_DAILY_REPORT_AUDIT_LOG,FLYWHEEL_DAILY_REPORT_STATE_DIR" \
    "$extra_paths"
}

emit_schema() {
  local surface="${1:-default}"
  case "$surface" in
    default|run)
      jq -nc --arg sv "$SCHEMA_VERSION" '{
        schema_version: $sv,
        command: "run",
        title: "Daily report fan-out result v1",
        type: "object",
        required: ["schema_version","generated","skipped","failed","repos"],
        properties: {
          schema_version: {const: $sv},
          generated: {type: "integer", minimum: 0},
          skipped: {type: "integer", minimum: 0},
          failed: {type: "integer", minimum: 0},
          repos: {type: "array", items: {type: "object", required: ["repo","status"]}}
        }
      }' ;;
    doctor)
      jq -nc '{
        schema_version: "daily-report-enabled-repos.doctor/v1",
        command: "doctor",
        type: "object",
        required: ["status","checks","enabled_repos","generator_executable"],
        properties: {
          status: {enum: ["pass","warn","fail"]},
          enabled_repos: {type: "array", items: {type: "string"}},
          generator_executable: {type: "boolean"},
          checks: {type: "array", items: {type: "object", required: ["name","status"]}}
        }
      }' ;;
    health)
      jq -nc '{
        schema_version: "daily-report-enabled-repos.health/v1",
        command: "health",
        type: "object",
        required: ["status","repos"],
        properties: {
          status: {enum: ["pass","warn","fail"]},
          repos: {type: "array"}
        }
      }' ;;
    repair)
      jq -nc '{
        schema_version: "daily-report-enabled-repos.repair/v1",
        command: "repair",
        type: "object",
        required: ["status","scope","mode","planned_actions"],
        properties: {
          status: {enum: ["dry_run","applied","refused"]},
          mode: {enum: ["dry_run","apply"]},
          scope: {enum: ["state","configs"]},
          idempotency_key: {type: ["string","null"]},
          planned_actions: {type: "array"},
          applied_actions: {type: "array"}
        }
      }' ;;
    validate)
      jq -nc '{
        schema_version: "daily-report-enabled-repos.validate/v1",
        command: "validate",
        type: "object",
        required: ["status","results"],
        properties: {
          status: {enum: ["pass","warn","fail"]},
          results: {type: "array"}
        }
      }' ;;
    audit)
      jq -nc '{
        schema_version: "daily-report-enabled-repos.audit/v1",
        command: "audit",
        type: "object",
        required: ["status","row_count","recent"],
        properties: {
          status: {enum: ["pass","empty","missing"]},
          row_count: {type: "integer"},
          recent: {type: "array"}
        }
      }' ;;
    why)
      jq -nc '{
        schema_version: "daily-report-enabled-repos.why/v1",
        command: "why",
        type: "object",
        required: ["repo","enabled","reason"]
      }' ;;
    quickstart)
      jq -nc '{
        schema_version: "daily-report-enabled-repos.quickstart/v1",
        command: "quickstart",
        type: "object",
        required: ["status","steps"]
      }' ;;
    *)
      echo "ERR: unknown schema surface: $surface" >&2
      return 64
      ;;
  esac
}

emit_examples() {
  cli_emit_examples "daily-report-enabled-repos.examples/v1" \
'{"name":"daily_run","invocation":"daily-report-enabled-repos.sh --json","purpose":"Generate today reports for all enabled repos."}
{"name":"daily_dry_run","invocation":"daily-report-enabled-repos.sh --dry-run --json","purpose":"List repos that would be processed without invoking the generator."}
{"name":"doctor_substrate","invocation":"daily-report-enabled-repos.sh doctor --json","purpose":"Probe substrate health: generator path, repo roots, per-repo configs."}
{"name":"health_recent","invocation":"daily-report-enabled-repos.sh health --json","purpose":"Show last-run status from audit log per enabled repo."}
{"name":"repair_configs_dry_run","invocation":"daily-report-enabled-repos.sh repair --scope configs --dry-run --json","purpose":"Plan config-template propagation to repos missing daily-report-config.json."}
{"name":"repair_state_apply","invocation":"daily-report-enabled-repos.sh repair --scope state --apply --idempotency-key statedir-2026-05-10 --json","purpose":"Create the audit log directory if missing."}
{"name":"validate_config","invocation":"daily-report-enabled-repos.sh validate config --json","purpose":"Validate every enabled repo daily-report-config.json against schema."}
{"name":"why_skip","invocation":"daily-report-enabled-repos.sh why ~/Developer/zesttube","purpose":"Explain why a specific repo is or is not enabled."}
{"name":"audit_recent","invocation":"daily-report-enabled-repos.sh audit --json","purpose":"Show recent run history from audit log."}'
}

emit_quickstart() {
  cli_emit_quickstart "daily-report-enabled-repos.quickstart/v1" \
'{"step":1,"action":"Probe substrate","command":"daily-report-enabled-repos.sh doctor --json"}
{"step":2,"action":"Validate per-repo configs","command":"daily-report-enabled-repos.sh validate config --json"}
{"step":3,"action":"Dry-run a fan-out","command":"daily-report-enabled-repos.sh --dry-run --json"}
{"step":4,"action":"Real fan-out","command":"daily-report-enabled-repos.sh --json"}
{"step":5,"action":"Inspect history","command":"daily-report-enabled-repos.sh audit --json"}
{"step":6,"action":"Repair drift if needed","command":"daily-report-enabled-repos.sh repair --scope configs --dry-run --json"}' \
"If any check fails run repair --scope <s> --dry-run before --apply --idempotency-key,Audit log lives at ~/.local/state/flywheel/daily-report-enabled-runs.jsonl"
}

emit_topic_help() {
  cli_emit_topic_help "${1:-}" "$ROOT/.flywheel/topics/daily-report-enabled-repos.json"
}

emit_completion() {
  local shell="${1:-bash}"
  case "$shell" in
    bash)
      cli_emit_completion_bash "daily-report-enabled-repos.sh" \
        "run,doctor,health,repair,validate,audit,why,quickstart,help,completion" \
        "--info,--schema,--examples,--help,--json,--dry-run,--date,--no-notify"
      ;;
    zsh)
      cli_emit_completion_zsh "daily-report-enabled-repos.sh" \
        "run,doctor,health,repair,validate,audit,why,quickstart,help,completion"
      ;;
    *)
      echo "ERR: completion shell must be bash or zsh" >&2
      return 64
      ;;
  esac
}

# ---------- core helpers ----------

is_enabled_repo() {
  local repo="${1:-}"
  [[ -n "$repo" ]] || return 1
  local config="$repo/.flywheel/daily-report-config.json"
  if [[ -f "$config" ]]; then
    jq -e '.enabled == true' "$config" >/dev/null 2>&1
    return $?
  fi
  [[ "$(cd "$repo" 2>/dev/null && pwd -P)" == "$HOME/Developer/flywheel" ]]
}

list_repos() {
  while IFS=: read -r root; do
    [[ -n "$root" && -d "$root" ]] || continue
    for candidate in "$root" "$root"/* "$root"/*/* "$root"/*/*/*; do
      [[ -d "$candidate/.flywheel" ]] || continue
      cd "$candidate" 2>/dev/null && pwd -P
    done
  done <<<"$REPO_ROOTS" | sort -u
}

list_enabled_repos() {
  while IFS= read -r repo; do
    [[ -n "$repo" ]] || continue
    if is_enabled_repo "$repo"; then printf '%s\n' "$repo"; fi
  done < <(list_repos)
  return 0
}

audit_append() {
  cli_audit_append "$AUDIT_LOG" "$1" "$2" "${3:-}"
}

# ---------- subcommands ----------

cmd_run() {
  local DATE_ARG="" DRY_RUN=0 NOTIFY_FLAG="--notify" JSON_OUT=1
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --date) [[ -n "${2:-}" ]] || { echo "ERR: --date requires YYYY-MM-DD" >&2; exit 64; }
              DATE_ARG="$2"; shift 2 ;;
      --dry-run) DRY_RUN=1; shift ;;
      --no-notify) NOTIFY_FLAG="--no-notify"; shift ;;
      --json) JSON_OUT=1; shift ;;
      *) echo "ERR: unknown run argument: $1" >&2; exit 64 ;;
    esac
  done

  local tmp; tmp="$(mktemp "${TMPDIR:-/tmp}/daily-report-enabled.XXXXXX")"
  trap 'rm -f "$tmp"' RETURN
  local generated=0 skipped=0 failed=0

  while IFS= read -r repo; do
    [[ -n "$repo" ]] || continue
    if ! is_enabled_repo "$repo"; then
      jq -nc --arg repo "$repo" '{repo:$repo,status:"skipped",reason:"daily_report_disabled"}' >>"$tmp"
      skipped=$((skipped + 1))
      continue
    fi
    if [[ "$DRY_RUN" -eq 1 ]]; then
      jq -nc --arg repo "$repo" '{repo:$repo,status:"would_generate"}' >>"$tmp"
      generated=$((generated + 1))
      continue
    fi
    local args=(--repo "$repo" "$NOTIFY_FLAG" --json)
    [[ -z "$DATE_ARG" ]] || args+=(--date "$DATE_ARG")
    if output="$("$GENERATOR" "${args[@]}" 2>&1)"; then
      jq -nc --arg repo "$repo" --argjson result "$output" '{repo:$repo,status:"generated",result:$result}' >>"$tmp"
      generated=$((generated + 1))
    else
      jq -nc --arg repo "$repo" --arg output "$output" '{repo:$repo,status:"failed",error:$output}' >>"$tmp"
      failed=$((failed + 1))
    fi
  done < <(list_repos)

  jq -cs \
    --arg sv "$SCHEMA_VERSION" \
    --arg generated "$generated" \
    --arg skipped "$skipped" \
    --arg failed "$failed" \
    '{schema_version:$sv,command:"run",generated:($generated|tonumber),skipped:($skipped|tonumber),failed:($failed|tonumber),repos:.}' \
    "$tmp"

  audit_append "run" \
    "$([[ "$failed" -eq 0 ]] && echo pass || echo fail)" \
    "$(jq -nc --argjson g "$generated" --argjson s "$skipped" --argjson f "$failed" '{generated:$g,skipped:$s,failed:$f}')"

  [[ "$failed" -eq 0 ]]
}

cmd_doctor() {
  local checks_tmp; checks_tmp="$(mktemp "${TMPDIR:-/tmp}/dre-doctor.XXXXXX")"
  trap 'rm -f "$checks_tmp"' RETURN

  local status="pass"
  add_check() {
    local name="$1" stat="$2" detail="$3"
    jq -nc --arg n "$name" --arg s "$stat" --arg d "$detail" \
      '{name:$n,status:$s,detail:$d}' >>"$checks_tmp"
    if [[ "$stat" == "fail" ]]; then
      status="fail"
    elif [[ "$stat" == "warn" && "$status" != "fail" ]]; then
      status="warn"
    fi
    return 0
  }

  if [[ -x "$GENERATOR" ]]; then
    add_check generator_executable pass "$GENERATOR"
  elif [[ -f "$GENERATOR" ]]; then
    add_check generator_executable warn "exists but not executable: $GENERATOR"
  else
    add_check generator_executable fail "missing: $GENERATOR"
  fi

  if [[ -d "$(dirname "$AUDIT_LOG")" ]]; then
    add_check audit_log_dir pass "$(dirname "$AUDIT_LOG")"
  else
    add_check audit_log_dir warn "missing dir; repair --scope state will create"
  fi

  local missing_roots=()
  while IFS=: read -r root; do
    [[ -n "$root" ]] || continue
    [[ -d "$root" ]] || missing_roots+=("$root")
  done <<<"$REPO_ROOTS"
  if [[ ${#missing_roots[@]} -eq 0 ]]; then
    add_check repo_roots_readable pass "$REPO_ROOTS"
  else
    add_check repo_roots_readable warn "missing: ${missing_roots[*]}"
  fi

  local enabled_repos_json
  enabled_repos_json="$(list_enabled_repos | jq -R . | jq -cs .)"
  local enabled_count; enabled_count="$(echo "$enabled_repos_json" | jq 'length')"
  if [[ "$enabled_count" -ge 1 ]]; then
    add_check enabled_repos_present pass "count=$enabled_count"
  else
    add_check enabled_repos_present warn "no enabled repos found"
  fi

  while IFS= read -r repo; do
    [[ -n "$repo" ]] || continue
    local cfg="$repo/.flywheel/daily-report-config.json"
    if [[ -f "$cfg" ]]; then
      if jq -e '.enabled == true' "$cfg" >/dev/null 2>&1; then
        add_check "config_$(basename "$repo")" pass "$cfg"
      fi
    elif [[ "$(cd "$repo" 2>/dev/null && pwd -P)" != "$HOME/Developer/flywheel" ]]; then
      add_check "config_$(basename "$repo")" warn "missing config (defaulted to disabled)"
    fi
  done < <(list_enabled_repos)

  jq -cs \
    --arg sv "daily-report-enabled-repos.doctor/v1" \
    --arg status "$status" \
    --argjson enabled_repos "$enabled_repos_json" \
    --argjson generator_exec "$([[ -x "$GENERATOR" ]] && echo true || echo false)" \
    '{schema_version:$sv,command:"doctor",status:$status,generator_executable:$generator_exec,enabled_repos:$enabled_repos,checks:.}' \
    "$checks_tmp"

  [[ "$status" == "pass" ]]
}

cmd_health() {
  local repos_tmp; repos_tmp="$(mktemp "${TMPDIR:-/tmp}/dre-health.XXXXXX")"
  trap 'rm -f "$repos_tmp"' RETURN
  local status="pass"

  local last_run_ts="" last_run_status=""
  if [[ -f "$AUDIT_LOG" ]]; then
    last_run_ts="$(jq -r 'select(.action=="run") | .ts' "$AUDIT_LOG" 2>/dev/null | tail -1 || true)"
    last_run_status="$(jq -r 'select(.action=="run") | .status' "$AUDIT_LOG" 2>/dev/null | tail -1 || true)"
  fi

  while IFS= read -r repo; do
    [[ -n "$repo" ]] || continue
    local report_dir="$repo/.flywheel/reports"
    local today_report; today_report="$report_dir/daily-$(date -u +%Y-%m-%d).md"
    local has_today; has_today="$([[ -f "$today_report" ]] && echo true || echo false)"
    jq -nc --arg repo "$repo" --argjson today "$has_today" --arg report "$today_report" \
      '{repo:$repo,today_report_exists:$today,today_report_path:$report}' >>"$repos_tmp"
    if [[ "$has_today" != "true" ]]; then status="warn"; fi
  done < <(list_enabled_repos)

  jq -cs \
    --arg sv "daily-report-enabled-repos.health/v1" \
    --arg status "$status" \
    --arg last_run_ts "$last_run_ts" \
    --arg last_run_status "$last_run_status" \
    '{schema_version:$sv,command:"health",status:$status,last_run_ts:$last_run_ts,last_run_status:$last_run_status,repos:.}' \
    "$repos_tmp"

  [[ "$status" == "pass" ]]
}

cmd_repair() {
  local SCOPE="" MODE="dry_run" IDEM_KEY=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --scope) [[ -n "${2:-}" ]] || { echo "ERR: --scope requires arg" >&2; exit 64; }
               SCOPE="$2"; shift 2 ;;
      --dry-run) MODE="dry_run"; shift ;;
      --apply) MODE="apply"; shift ;;
      --idempotency-key) [[ -n "${2:-}" ]] || { echo "ERR: --idempotency-key requires arg" >&2; exit 64; }
                          IDEM_KEY="$2"; shift 2 ;;
      --json) shift ;;
      *) echo "ERR: unknown repair arg: $1" >&2; exit 64 ;;
    esac
  done
  case "$SCOPE" in
    state|configs) ;;
    *) echo "ERR: --scope must be state|configs" >&2; exit 64 ;;
  esac
  if [[ "$MODE" == "apply" && -z "$IDEM_KEY" ]]; then
    cli_refuse_apply_without_idem_key "daily-report-enabled-repos.repair/v1" "repair" "$SCOPE"
  fi

  local planned_tmp applied_tmp
  planned_tmp="$(mktemp "${TMPDIR:-/tmp}/dre-repair-planned.XXXXXX")"
  applied_tmp="$(mktemp "${TMPDIR:-/tmp}/dre-repair-applied.XXXXXX")"
  trap 'rm -f "$planned_tmp" "$applied_tmp"' RETURN

  case "$SCOPE" in
    state)
      local audit_dir; audit_dir="$(dirname "$AUDIT_LOG")"
      if [[ ! -d "$audit_dir" ]]; then
        jq -nc --arg dir "$audit_dir" '{action:"mkdir_audit_dir",target:$dir}' >>"$planned_tmp"
        if [[ "$MODE" == "apply" ]]; then
          mkdir -p "$audit_dir"
          jq -nc --arg dir "$audit_dir" '{action:"mkdir_audit_dir",target:$dir,result:"ok"}' >>"$applied_tmp"
        fi
      fi
      ;;
    configs)
      while IFS= read -r repo; do
        [[ -n "$repo" ]] || continue
        local cfg="$repo/.flywheel/daily-report-config.json"
        if [[ ! -f "$cfg" && -d "$repo/.flywheel" ]]; then
          jq -nc --arg repo "$repo" --arg cfg "$cfg" \
            '{action:"propose_config_template",repo:$repo,target:$cfg,template:{enabled:false,note:"daily-report-config.json template — set enabled=true to opt-in"}}' \
            >>"$planned_tmp"
          if [[ "$MODE" == "apply" ]]; then
            jq -nc '{enabled:false,note:"template; set enabled=true to opt-in",created_by:"daily-report-enabled-repos repair --scope configs",created_at:"'"$(iso_now)"'"}' >"$cfg"
            jq -nc --arg repo "$repo" --arg cfg "$cfg" \
              '{action:"propose_config_template",repo:$repo,target:$cfg,result:"ok"}' >>"$applied_tmp"
          fi
        fi
      done < <(list_repos)
      ;;
  esac

  local final_status
  if [[ "$MODE" == "apply" ]]; then
    final_status="applied"
    audit_append "repair" "applied" "$(jq -nc --arg s "$SCOPE" --arg k "$IDEM_KEY" '{scope:$s,idempotency_key:$k}')"
  else
    final_status="dry_run"
  fi

  jq -nc \
    --arg sv "daily-report-enabled-repos.repair/v1" \
    --arg status "$final_status" \
    --arg mode "$MODE" \
    --arg scope "$SCOPE" \
    --arg key "$IDEM_KEY" \
    --slurpfile planned "$planned_tmp" \
    --slurpfile applied "$applied_tmp" \
    '{
      schema_version:$sv,
      command:"repair",
      status:$status,
      mode:$mode,
      scope:$scope,
      idempotency_key:(if $key=="" then null else $key end),
      planned_actions:$planned,
      applied_actions:$applied
    }'
}

cmd_validate_config() {
  local results_tmp; results_tmp="$(mktemp "${TMPDIR:-/tmp}/dre-validate.XXXXXX")"
  trap 'rm -f "$results_tmp"' RETURN
  local status="pass"

  while IFS= read -r repo; do
    [[ -n "$repo" ]] || continue
    local cfg="$repo/.flywheel/daily-report-config.json"
    if [[ ! -f "$cfg" ]]; then
      jq -nc --arg repo "$repo" --arg cfg "$cfg" \
        '{repo:$repo,config:$cfg,status:"missing"}' >>"$results_tmp"
      continue
    fi
    if ! jq -e '.enabled | type == "boolean"' "$cfg" >/dev/null 2>&1; then
      jq -nc --arg repo "$repo" --arg cfg "$cfg" \
        '{repo:$repo,config:$cfg,status:"fail",reason:"enabled field missing or not boolean"}' >>"$results_tmp"
      status="fail"
      continue
    fi
    jq -nc --arg repo "$repo" --arg cfg "$cfg" \
      '{repo:$repo,config:$cfg,status:"pass"}' >>"$results_tmp"
  done < <(list_repos)

  jq -cs \
    --arg sv "daily-report-enabled-repos.validate/v1" \
    --arg status "$status" \
    '{schema_version:$sv,command:"validate",scope:"config",status:$status,results:.}' \
    "$results_tmp"

  [[ "$status" == "pass" ]]
}

cmd_audit() {
  if [[ ! -f "$AUDIT_LOG" ]]; then
    jq -nc --arg sv "daily-report-enabled-repos.audit/v1" \
      '{schema_version:$sv,command:"audit",status:"missing",row_count:0,recent:[]}'
    return 0
  fi
  local row_count; row_count="$(wc -l <"$AUDIT_LOG" | tr -d ' ')"
  if [[ "$row_count" -eq 0 ]]; then
    jq -nc --arg sv "daily-report-enabled-repos.audit/v1" \
      '{schema_version:$sv,command:"audit",status:"empty",row_count:0,recent:[]}'
    return 0
  fi
  local recent; recent="$(tail -20 "$AUDIT_LOG" | jq -cs '.')"
  jq -nc \
    --arg sv "daily-report-enabled-repos.audit/v1" \
    --argjson rc "$row_count" \
    --argjson recent "$recent" \
    '{schema_version:$sv,command:"audit",status:"pass",row_count:$rc,recent:$recent}'
}

cmd_why() {
  local target="${1:-}"
  [[ -n "$target" ]] || { echo "ERR: why requires <repo>" >&2; exit 64; }
  local abs; abs="$(cd "$target" 2>/dev/null && pwd -P || echo "")"
  if [[ -z "$abs" ]]; then
    jq -nc --arg sv "daily-report-enabled-repos.why/v1" --arg t "$target" \
      '{schema_version:$sv,command:"why",repo:$t,enabled:false,reason:"path does not resolve"}'
    return 1
  fi
  local has_flywheel="false" has_config="false" reason=""
  if [[ -d "$abs/.flywheel" ]]; then has_flywheel=true; fi
  if [[ -f "$abs/.flywheel/daily-report-config.json" ]]; then
    has_config=true
    if jq -e '.enabled == true' "$abs/.flywheel/daily-report-config.json" >/dev/null 2>&1; then
      reason="config.enabled=true"
    elif jq -e '.enabled == false' "$abs/.flywheel/daily-report-config.json" >/dev/null 2>&1; then
      reason="config.enabled=false"
    else
      reason="config.enabled missing or invalid"
    fi
  elif [[ "$abs" == "$HOME/Developer/flywheel" ]]; then
    reason="default-enabled (canonical flywheel repo)"
  else
    reason="no .flywheel/daily-report-config.json (defaulted to disabled)"
  fi
  local enabled="false"
  if [[ "$has_flywheel" == "true" ]] && is_enabled_repo "$abs"; then
    enabled="true"
  fi
  jq -nc \
    --arg sv "daily-report-enabled-repos.why/v1" \
    --arg repo "$abs" \
    --argjson has_flywheel "$has_flywheel" \
    --argjson has_config "$has_config" \
    --argjson enabled "$enabled" \
    --arg reason "$reason" \
    '{schema_version:$sv,command:"why",repo:$repo,has_flywheel:$has_flywheel,has_config:$has_config,enabled:$enabled,reason:$reason}'
}

# ---------- main dispatch ----------

main() {
  if [[ $# -eq 0 ]]; then
    cmd_run; exit $?
  fi

  case "$1" in
    -h|--help) usage; exit 0 ;;
    --info)
      shift
      case "${1:-}" in --json|"") emit_info; exit 0 ;;
                       *) echo "ERR: --info accepts only --json" >&2; exit 64 ;;
      esac ;;
    --schema)
      shift
      emit_schema "${1:-default}"; exit $? ;;
    --examples)
      shift
      emit_examples; exit 0 ;;

    run) shift
      case "${1:-}" in --help|-h) emit_topic_help run; exit 0 ;; esac
      cmd_run "$@"; exit $? ;;
    doctor) shift
      case "${1:-}" in --help|-h) emit_topic_help doctor; exit 0 ;; esac
      while [[ $# -gt 0 ]]; do case "$1" in --json) shift;; *) echo "ERR: unknown doctor arg $1" >&2; exit 64;; esac; done
      cmd_doctor; exit $? ;;
    health) shift
      case "${1:-}" in --help|-h) emit_topic_help health; exit 0 ;; esac
      while [[ $# -gt 0 ]]; do case "$1" in --json) shift;; *) echo "ERR: unknown health arg $1" >&2; exit 64;; esac; done
      cmd_health; exit $? ;;
    repair) shift
      case "${1:-}" in --help|-h) emit_topic_help repair; exit 0 ;; esac
      cmd_repair "$@"; exit $? ;;
    validate)
      shift
      case "${1:-}" in
        --help|-h) emit_topic_help validate; exit 0 ;;
        config) shift
                case "${1:-}" in --help|-h) emit_topic_help validate; exit 0 ;; esac
                cmd_validate_config "$@"; exit $? ;;
        *) echo "ERR: validate requires 'config'" >&2; exit 64 ;;
      esac ;;
    audit) shift
      case "${1:-}" in --help|-h) emit_topic_help audit; exit 0 ;; esac
      while [[ $# -gt 0 ]]; do case "$1" in --json) shift;; *) echo "ERR: unknown audit arg $1" >&2; exit 64;; esac; done
      cmd_audit; exit $? ;;
    why) shift
      case "${1:-}" in --help|-h) emit_topic_help why; exit 0 ;; esac
      cmd_why "$@"; exit $? ;;
    quickstart) shift
      case "${1:-}" in --help|-h) emit_topic_help quickstart 2>/dev/null || usage; exit 0 ;; esac
      emit_quickstart; exit 0 ;;
    help) shift; emit_topic_help "${1:-}"; exit 0 ;;
    completion) shift
      case "${1:-}" in --help|-h|"") usage; exit 0 ;; esac
      emit_completion "${1:-bash}"; exit $? ;;

    # backward-compat: if first arg looks like an old flag, treat as run mode
    --date|--dry-run|--no-notify|--json) cmd_run "$@"; exit $? ;;

    *)
      echo "ERR: unknown subcommand or argument: $1" >&2
      usage >&2
      exit 64 ;;
  esac
}

main "$@"
