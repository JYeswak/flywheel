# shellcheck shell=bash
# canonical-cli-helpers.sh — drop-in helper library for canonical-CLI emitters.
#
# Source this from any flywheel script that wants the canonical-cli-scoping
# triad without inlining ~150 lines of boilerplate per surface:
#
#   source "$REPO/.flywheel/lib/canonical-cli-helpers.sh"
#
# The lib carries its own schema version `canonical-cli-helpers/v1`. Helpers
# emit envelopes carrying the *caller's* schema versions; the lib never
# overrides a caller's `<surface>.<command>/v1` schema.
#
# Source bead: flywheel-tiugg (apply spec
# .flywheel/audit/flywheel-jloib.0a/apply-spec.md). Pilot reference dab051e.
#
# Boundary:
#   - READ caller env (no globals owned by the lib except CANONICAL_CLI_HELPERS_VERSION).
#   - WRITE only to paths the caller passes in. Never assume an audit-log path.
#   - DO NOT replace per-surface doctor / repair / validate logic.
#   - ZERO external deps beyond bash, jq, date, shasum.
#
# Bug-prevention defaults (see README "Caveats"):
#   1. Helpers do not assume `set -euo pipefail` is on, but stay robust either way.
#   2. `local` declarations split — one var per `local` line when the second
#      reads the first.
#   3. Enumerator-style helpers end with explicit `return 0`.
#   4. Default braces use `${N:-}` then `[[ -n "$x" ]] || x='{}'` (NEVER `${N:-{}}`).
#   5. Conditional returns use `if/then/elif/fi`, NEVER `[[ ]] && X || Y`.

CANONICAL_CLI_HELPERS_VERSION="canonical-cli-helpers/v1"

# ---------- time + script identity ----------

# cli_iso_now — echo a UTC ISO-8601 timestamp.
cli_iso_now() {
  date -u +'%Y-%m-%dT%H:%M:%SZ'
}

# cli_sha_self <script_path> — echo sha256 of caller script.
# Prints empty string on failure so callers can substitute "" without error.
cli_sha_self() {
  local script_path
  script_path="${1:-}"
  if [[ -z "$script_path" || ! -r "$script_path" ]]; then
    printf '\n'
    return 0
  fi
  shasum -a 256 "$script_path" 2>/dev/null | awk '{print $1}'
  return 0
}

# ---------- audit log primitive ----------

# cli_audit_append <log_path> <action> <status> [<extra_json>]
#
# Appends one canonical JSONL row:
#   {ts, action, status, sha256, ...extra}
#
# Args:
#   log_path    — JSONL audit log path (created with parent dirs if missing)
#   action      — short action name (e.g., "run", "repair_apply")
#   status      — "ok" | "fail" | "refused" | <freeform>
#   extra_json  — optional JSON object string; merged into row. Bad JSON
#                 falls back to "{}" silently so the row is always valid.
#
# Silent on append failure (audit logging never blocks foreground work).
cli_audit_append() {
  local log_path
  local action
  local status
  local extra_json
  log_path="${1:-}"
  action="${2:-}"
  status="${3:-}"
  extra_json="${4:-}"
  if [[ -z "$extra_json" ]]; then
    extra_json='{}'
  fi
  if ! printf '%s' "$extra_json" | jq -e . >/dev/null 2>&1; then
    extra_json='{}'
  fi
  if [[ -z "$log_path" ]]; then
    return 0
  fi
  mkdir -p "$(dirname "$log_path")" 2>/dev/null || true
  local sha
  sha="$(cli_sha_self "${BASH_SOURCE[1]:-$0}")"
  jq -nc \
    --arg ts "$(cli_iso_now)" \
    --arg action "$action" \
    --arg status "$status" \
    --arg sha "$sha" \
    --argjson extra "$extra_json" \
    '{ts:$ts,action:$action,status:$status,sha256:$sha} + $extra' \
    >>"$log_path" 2>/dev/null || true
  return 0
}

# ---------- refusal envelope ----------

# cli_refuse_apply_without_idem_key <schema_version> <command> <scope>
#
# Emits the canonical refusal envelope on stdout and exits 3. Use in repair
# subcommands when --apply was passed without --idempotency-key.
#
# Envelope shape:
#   {schema_version, command, status:"refused", mode:"apply", scope,
#    reason:"--apply requires --idempotency-key"}
cli_refuse_apply_without_idem_key() {
  local schema_version
  local command
  local scope
  schema_version="${1:-canonical-cli-helpers/v1}"
  command="${2:-repair}"
  scope="${3:-}"
  jq -nc \
    --arg sv "$schema_version" \
    --arg cmd "$command" \
    --arg scope "$scope" \
    '{schema_version:$sv,command:$cmd,status:"refused",mode:"apply",scope:$scope,reason:"--apply requires --idempotency-key"}'
  exit 3
}

# ---------- subcommand --help routing ----------

# cli_dispatch_subcommand_help <topic_help_function> <args...>
#
# If first arg is --help or -h, calls topic_help_function with remaining args
# and exits 0. Otherwise returns 0 (caller proceeds with normal dispatch).
#
# Usage in a subcommand parser:
#   cli_dispatch_subcommand_help cmd_repair_help "$@"
cli_dispatch_subcommand_help() {
  local topic_help_fn
  topic_help_fn="${1:-}"
  shift || true
  if [[ -z "$topic_help_fn" ]]; then
    return 0
  fi
  local first
  first="${1:-}"
  if [[ "$first" == "--help" || "$first" == "-h" ]]; then
    shift || true
    "$topic_help_fn" "$@"
    exit 0
  fi
  return 0
}

# ---------- --info envelope generator ----------

# cli_emit_info <name> <version> <schema_version> <subcommands_csv> <env_vars_csv> [<extra_paths_json>]
#
# Emits the canonical --info envelope on stdout:
#   {schema_version, command:"info", name, version, sha256, paths,
#    env_vars, subcommands, dependencies, mutation_requires,
#    canonical_cli_surfaces}
#
# Args:
#   name              — script basename (e.g., "daily-report-enabled-repos.sh")
#   version           — caller-owned semantic version string
#   schema_version    — caller's surface schema (e.g., "<surface>.info/v1")
#   subcommands_csv   — comma-separated subcommand list
#   env_vars_csv      — comma-separated env var names
#   extra_paths_json  — optional JSON object {key:path} to merge into .paths
cli_emit_info() {
  local name
  local version
  local schema_version
  local subcommands_csv
  local env_vars_csv
  local extra_paths_json
  name="${1:-}"
  version="${2:-}"
  schema_version="${3:-canonical-cli-helpers/v1}"
  subcommands_csv="${4:-}"
  env_vars_csv="${5:-}"
  extra_paths_json="${6:-}"
  if [[ -z "$extra_paths_json" ]]; then
    extra_paths_json='{}'
  fi
  if ! printf '%s' "$extra_paths_json" | jq -e . >/dev/null 2>&1; then
    extra_paths_json='{}'
  fi
  local sha
  sha="$(cli_sha_self "${BASH_SOURCE[1]:-$0}")"
  jq -nc \
    --arg sv "$schema_version" \
    --arg name "$name" \
    --arg version "$version" \
    --arg sha "$sha" \
    --arg subs "$subcommands_csv" \
    --arg envs "$env_vars_csv" \
    --argjson extra_paths "$extra_paths_json" \
    '{
      schema_version: $sv,
      command: "info",
      name: $name,
      version: $version,
      sha256: $sha,
      paths: $extra_paths,
      env_vars: ($envs | split(",") | map(select(length>0))),
      subcommands: ($subs | split(",") | map(select(length>0))),
      dependencies: ["bash","jq","date","shasum"],
      mutation_requires: "--apply --idempotency-key (or default --json output)",
      canonical_cli_surfaces: [
        "doctor","health","repair","validate","audit","why",
        "quickstart","help","completion","--info","--schema","--examples"
      ]
    }'
  return 0
}

# ---------- --examples envelope generator ----------

# cli_emit_examples <schema_version> <examples_jsonl_string>
#
# examples_jsonl_string: newline-delimited JSON, each
#   {name, invocation, purpose}
#
# Wraps into:
#   {schema_version, command:"examples", examples:[...]}
cli_emit_examples() {
  local schema_version
  local examples_jsonl
  schema_version="${1:-canonical-cli-helpers/v1}"
  examples_jsonl="${2:-}"
  local examples_array
  if [[ -z "$examples_jsonl" ]]; then
    examples_array='[]'
  else
    examples_array="$(printf '%s' "$examples_jsonl" | jq -cs '.' 2>/dev/null)"
    if [[ -z "$examples_array" ]]; then
      examples_array='[]'
    fi
  fi
  jq -nc \
    --arg sv "$schema_version" \
    --argjson examples "$examples_array" \
    '{schema_version:$sv,command:"examples",examples:$examples}'
  return 0
}

# ---------- quickstart envelope generator ----------

# cli_emit_quickstart <schema_version> <steps_jsonl_string> [<next_actions_csv>]
#
# steps_jsonl_string: newline-delimited JSON, each {step, action, command}
# next_actions_csv: comma-separated list (optional)
cli_emit_quickstart() {
  local schema_version
  local steps_jsonl
  local next_actions_csv
  schema_version="${1:-canonical-cli-helpers/v1}"
  steps_jsonl="${2:-}"
  next_actions_csv="${3:-}"
  local steps_array
  if [[ -z "$steps_jsonl" ]]; then
    steps_array='[]'
  else
    steps_array="$(printf '%s' "$steps_jsonl" | jq -cs '.' 2>/dev/null)"
    if [[ -z "$steps_array" ]]; then
      steps_array='[]'
    fi
  fi
  jq -nc \
    --arg sv "$schema_version" \
    --arg actions "$next_actions_csv" \
    --argjson steps "$steps_array" \
    '{
      schema_version:$sv,
      command:"quickstart",
      status:"ok",
      steps:$steps,
      next_actions:($actions | split(",") | map(select(length>0)))
    }'
  return 0
}

# ---------- completion generators ----------

# cli_emit_completion_bash <command_name> <subcommands_csv> <flags_csv>
#
# Emits a bash completion script bound to <command_name> on stdout.
cli_emit_completion_bash() {
  local cmd
  local subs
  local flags
  cmd="${1:-}"
  subs="${2:-}"
  flags="${3:-}"
  if [[ -z "$cmd" ]]; then
    return 0
  fi
  local fn_name
  fn_name="_${cmd//[^A-Za-z0-9_]/_}_completion"
  cat <<EOF
${fn_name}() {
  local cur subs flags opts
  COMPREPLY=()
  cur="\${COMP_WORDS[COMP_CWORD]}"
  subs="$(printf '%s' "$subs" | tr ',' ' ')"
  flags="$(printf '%s' "$flags" | tr ',' ' ')"
  if [[ \${COMP_CWORD} -eq 1 ]]; then
    opts="\$subs \$flags"
    COMPREPLY=( \$(compgen -W "\$opts" -- "\$cur") )
    return 0
  fi
  COMPREPLY=( \$(compgen -W "\$flags" -- "\$cur") )
  return 0
}
complete -F ${fn_name} ${cmd}
EOF
  return 0
}

# cli_emit_completion_zsh <command_name> <subcommands_csv>
#
# Emits a zsh completion script bound to <command_name> on stdout.
cli_emit_completion_zsh() {
  local cmd
  local subs
  cmd="${1:-}"
  subs="${2:-}"
  if [[ -z "$cmd" ]]; then
    return 0
  fi
  local fn_name
  fn_name="_${cmd//[^A-Za-z0-9_]/_}"
  local subs_space
  subs_space="$(printf '%s' "$subs" | tr ',' ' ')"
  cat <<EOF
#compdef ${cmd}
${fn_name}() {
  local -a subs
  subs=(${subs_space})
  _arguments \\
    '1: :->sub' \\
    '*: :->args'
  case \$state in
    sub) compadd -- \$subs --info --schema --examples --help --json --dry-run ;;
  esac
}
compdef ${fn_name} ${cmd}
EOF
  return 0
}

# ---------- schema dispatcher (jloib.0d-followup #1) ----------

# cli_emit_schema_dispatch <surface> <schema_map_file>
#
# JSON-driven schema dispatch. Replaces the per-script `case "$surface" in
# default|run) ;; doctor) ;; ...` block.
#
# schema_map_file: JSON {<surface>: <schema-body-object>, ...}.
# The body object is emitted as-is (it already carries its own
# `schema_version`, `command`, `required`, `properties`, etc.).
#
# Surface "default" is honored as an alias for "run" when no exact match.
#
# Exit codes:
#   0  matched + emitted
#   64 schema map missing/unreadable/malformed, or surface unknown
cli_emit_schema_dispatch() {
  local surface
  local schema_map_file
  surface="${1:-default}"
  schema_map_file="${2:-}"
  if [[ -z "$schema_map_file" || ! -r "$schema_map_file" ]]; then
    printf 'ERR: schema map missing or unreadable: %s\n' "$schema_map_file" >&2
    return 64
  fi
  if ! jq -e . "$schema_map_file" >/dev/null 2>&1; then
    printf 'ERR: schema map is not valid JSON: %s\n' "$schema_map_file" >&2
    return 64
  fi
  local body
  body="$(jq -c --arg s "$surface" '.[$s] // empty' "$schema_map_file")"
  if [[ -z "$body" && "$surface" == "default" ]]; then
    body="$(jq -c '.run // empty' "$schema_map_file")"
  fi
  if [[ -z "$body" ]]; then
    printf 'ERR: unknown schema surface: %s\n' "$surface" >&2
    return 64
  fi
  printf '%s\n' "$body"
  return 0
}

# ---------- per-command help routing (jloib.0d-followup #2) ----------

# cli_route_command_help <command> <topic_help_function> <args...>
#
# Routes when the FIRST ARG is `--help` or `-h` — i.e., the user typed
# `<cli> <command> --help`. Calls the topic help function with <command>
# as its single argument and exits 0.
#
# This complements `cli_dispatch_subcommand_help` (which fires after the
# subcommand parser has stripped the subcommand) by hoisting the route
# decision to the dispatch case statement:
#
#   doctor)  shift; cli_route_command_help doctor cmd_topic_help "$@"
#            cmd_doctor "$@"; exit $? ;;
#
# Bare invocation without --help returns 0 and the caller proceeds.
cli_route_command_help() {
  local command
  local topic_help_fn
  command="${1:-}"
  topic_help_fn="${2:-}"
  shift 2 || true
  if [[ -z "$command" || -z "$topic_help_fn" ]]; then
    return 0
  fi
  local first
  first="${1:-}"
  if [[ "$first" == "--help" || "$first" == "-h" ]]; then
    "$topic_help_fn" "$command"
    exit 0
  fi
  return 0
}

# ---------- audit log tail (jloib.0d-followup #3) ----------

# cli_emit_audit_tail <audit_log_path> <schema_version> [<limit>]
#
# Emits the canonical `audit` envelope:
#   {schema_version, command:"audit", status, row_count, recent:[...]}
#
# status enum:
#   "pass"   — audit log present + at least one row
#   "empty"  — file exists but no rows
#   "missing"— file does not exist
#
# Default limit: 20.
cli_emit_audit_tail() {
  local audit_log
  local schema_version
  local limit
  audit_log="${1:-}"
  schema_version="${2:-canonical-cli-helpers.audit/v1}"
  limit="${3:-20}"
  if [[ -z "$audit_log" || ! -r "$audit_log" ]]; then
    jq -nc --arg sv "$schema_version" \
      '{schema_version:$sv,command:"audit",status:"missing",row_count:0,recent:[]}'
    return 0
  fi
  local row_count
  row_count="$(wc -l <"$audit_log" 2>/dev/null | tr -d ' ')"
  if [[ -z "$row_count" || "$row_count" == "0" ]]; then
    jq -nc --arg sv "$schema_version" \
      '{schema_version:$sv,command:"audit",status:"empty",row_count:0,recent:[]}'
    return 0
  fi
  local recent
  recent="$(tail -n "$limit" "$audit_log" 2>/dev/null | jq -cs '.' 2>/dev/null)"
  if [[ -z "$recent" ]]; then
    recent='[]'
  fi
  jq -nc \
    --arg sv "$schema_version" \
    --argjson rc "$row_count" \
    --argjson rows "$recent" \
    '{schema_version:$sv,command:"audit",status:"pass",row_count:$rc,recent:$rows}'
  return 0
}

# ---------- cross-orch canonical-cli receipt (flywheel-4wxn6) ----------

# Cross-orch state directory holding the receipt schema sidecar + per-orch
# receipt files. Both flywheel:1 and skillos:1 write here so each side can
# scan the other's verdicts without traversing repo boundaries.
CANONICAL_CLI_CROSS_ORCH_STATE_DIR="${CANONICAL_CLI_CROSS_ORCH_STATE_DIR:-$HOME/.local/state/canonical-cli-scoping}"
CANONICAL_CLI_CROSS_ORCH_SCHEMA_PATH="${CANONICAL_CLI_CROSS_ORCH_SCHEMA_PATH:-$CANONICAL_CLI_CROSS_ORCH_STATE_DIR/schema/receipt.schema.json}"

# cli_emit_canonical_receipt <orch> <surface> <score> <dimensions_json> <evidence_json> [<spec_version>] [<ts>]
#
# Implements P2 of the cross-orch-anti-divergence-v1 protocol set
# (ratified 2026-05-10T16:48Z; ref:
# .flywheel/handoffs/2026-05-10T164800Z-from-flywheel-1-to-skillos-1-protocols-v1-ratification.md).
#
# Writes a 13-dimension receipt to
# `~/.local/state/canonical-cli-scoping/receipts/<orch>/<surface>-<ts>.json`
# matching the agreed schema sidecar at
# `~/.local/state/canonical-cli-scoping/schema/receipt.schema.json`.
#
# Pre-write validation:
#   1. dimensions_json: 13 keys exactly, each value PASS|FAIL|NA.
#   2. evidence_json: must contain doctor_path, ci_run_url, test_count.
#   3. score: 0..13.
#   4. orch: matches `^[a-z][a-z0-9_-]*:[0-9]+$`.
#
# Args:
#   orch              — orchestrator identity (e.g., "flywheel:1")
#   surface           — surface name (script basename or skill name)
#   score             — integer 0..13 (PASS+NA count out of 13)
#   dimensions_json   — JSON object with all 13 dimensions
#   evidence_json     — JSON object with doctor_path, ci_run_url, test_count
#   spec_version      — optional; default "canonical-cli-scoping/v1"
#   ts                — optional; default cli_iso_now
#
# Echoes the canonical receipt path on stdout. Exit codes:
#   0  ok (receipt written + validated)
#   2  validation error (invalid args or schema mismatch)
#   3  helper-lib unavailable / missing dependency
cli_emit_canonical_receipt() {
  local orch
  local surface
  local score
  local dimensions_json
  local evidence_json
  local spec_version
  local ts
  orch="${1:-}"
  surface="${2:-}"
  score="${3:-}"
  dimensions_json="${4:-}"
  evidence_json="${5:-}"
  spec_version="${6:-canonical-cli-scoping/v1}"
  ts="${7:-$(cli_iso_now)}"

  if ! command -v jq >/dev/null 2>&1; then
    printf 'ERR: cli_emit_canonical_receipt requires jq\n' >&2
    return 3
  fi

  if [[ -z "$orch" || -z "$surface" || -z "$score" || -z "$dimensions_json" || -z "$evidence_json" ]]; then
    printf 'ERR: cli_emit_canonical_receipt requires <orch> <surface> <score> <dimensions_json> <evidence_json>\n' >&2
    return 2
  fi

  if ! [[ "$orch" =~ ^[a-z][a-z0-9_-]*:[0-9]+$ ]]; then
    printf 'ERR: orch must match ^[a-z][a-z0-9_-]*:[0-9]+$ (got %s)\n' "$orch" >&2
    return 2
  fi

  if ! [[ "$score" =~ ^[0-9]+$ ]] || [[ "$score" -lt 0 || "$score" -gt 13 ]]; then
    printf 'ERR: score must be integer 0..13 (got %s)\n' "$score" >&2
    return 2
  fi

  if ! printf '%s' "$dimensions_json" | jq -e . >/dev/null 2>&1; then
    printf 'ERR: dimensions_json is not valid JSON\n' >&2
    return 2
  fi
  if ! printf '%s' "$evidence_json" | jq -e . >/dev/null 2>&1; then
    printf 'ERR: evidence_json is not valid JSON\n' >&2
    return 2
  fi

  local required_dims
  required_dims='["doctor_health_repair_triad","validate_audit_why_subsidiary","info_examples_quickstart_help_completion","json_everywhere","exit_code_taxonomy","format_text_json_toon","dry_run_explain_on_mutating_ops","per_adapter_scoping","upstream_report","cross_repo_resolvable","deps_buildable_graceful_failure","errJSON_exit_pair","doctor_namespace_named_subsystems"]'

  local missing
  missing="$(jq -nc --argjson dims "$dimensions_json" --argjson required "$required_dims" \
    '$required - ($dims | keys)' 2>/dev/null)"
  if [[ "$missing" != "[]" ]]; then
    printf 'ERR: dimensions_json missing keys: %s\n' "$missing" >&2
    return 2
  fi

  local extra
  extra="$(jq -nc --argjson dims "$dimensions_json" --argjson required "$required_dims" \
    '($dims | keys) - $required' 2>/dev/null)"
  if [[ "$extra" != "[]" ]]; then
    printf 'ERR: dimensions_json has unknown keys: %s\n' "$extra" >&2
    return 2
  fi

  local invalid_verdicts
  invalid_verdicts="$(jq -nc --argjson dims "$dimensions_json" \
    '[$dims | to_entries[] | select(.value as $v | ["PASS","FAIL","NA"] | index($v) | not)] | map(.key)' 2>/dev/null)"
  if [[ "$invalid_verdicts" != "[]" ]]; then
    printf 'ERR: dimensions with non-PASS|FAIL|NA values: %s\n' "$invalid_verdicts" >&2
    return 2
  fi

  local missing_evidence
  missing_evidence="$(jq -nc --argjson ev "$evidence_json" \
    '["doctor_path","ci_run_url","test_count"] - ($ev | keys)' 2>/dev/null)"
  if [[ "$missing_evidence" != "[]" ]]; then
    printf 'ERR: evidence_json missing keys: %s\n' "$missing_evidence" >&2
    return 2
  fi

  local receipts_dir
  receipts_dir="$CANONICAL_CLI_CROSS_ORCH_STATE_DIR/receipts/$orch"
  mkdir -p "$receipts_dir" 2>/dev/null || true

  local ts_token
  ts_token="$(printf '%s' "$ts" | tr -d ':-')"
  local receipt_path
  receipt_path="$receipts_dir/${surface}-${ts_token}.json"

  local receipt_body
  receipt_body="$(jq -nc \
    --arg orch "$orch" \
    --arg surface "$surface" \
    --arg spec_version "$spec_version" \
    --arg ts "$ts" \
    --argjson score "$score" \
    --argjson dimensions "$dimensions_json" \
    --argjson evidence "$evidence_json" \
    '{
      schema_version: "cross-orch-canonical-cli-receipt/v1",
      orch: $orch,
      surface: $surface,
      spec_version: $spec_version,
      score: $score,
      dimensions: $dimensions,
      evidence: $evidence,
      ts: $ts
    }')"

  printf '%s\n' "$receipt_body" >"$receipt_path"
  printf '%s\n' "$receipt_path"
  return 0
}

# ---------- topic help dispatcher ----------

# cli_emit_topic_help <topic> <topic_map_file>
#
# topic_map_file: JSON {<topic>:"<help text>", ...}
#
# Empty topic shows the topic list. Unknown topic prints the topic list and
# exits 0 (so callers can route help <bad-topic> without crashing).
cli_emit_topic_help() {
  local topic
  local topic_map_file
  topic="${1:-}"
  topic_map_file="${2:-}"
  if [[ -z "$topic_map_file" || ! -r "$topic_map_file" ]]; then
    printf 'ERR: topic map missing or unreadable: %s\n' "$topic_map_file" >&2
    return 64
  fi
  if ! jq -e . "$topic_map_file" >/dev/null 2>&1; then
    printf 'ERR: topic map is not valid JSON: %s\n' "$topic_map_file" >&2
    return 64
  fi
  if [[ -z "$topic" ]]; then
    jq -r 'keys | join(" | ") | "Topics: " + .' "$topic_map_file"
    return 0
  fi
  local body
  body="$(jq -r --arg t "$topic" '.[$t] // empty' "$topic_map_file")"
  if [[ -z "$body" ]]; then
    jq -r 'keys | join(" | ") | "Unknown topic. Topics: " + .' "$topic_map_file"
    return 0
  fi
  printf '%s\n' "$body"
  return 0
}

# ----------------------------------------------------------------------
# cli_pre_write_check — Layer-1 PREVENTION wrapper around the
# pre-write-path-guard.sh primitive (bead flywheel-16b53.2).
#
# Caller pattern (wrap any absolute-path write before the Write tool runs):
#
#   cli_pre_write_check "$abs_path" "$FLYWHEEL_CURRENT_BEAD" || return $?
#
# Returns:
#   0 — allow (proposed path is under the bead's OWNED_WRITE_ROOTS allowlist)
#   1 — deny  (caller MUST abort the write)
#   2 — usage / arg error
#   3 — missing or malformed policy
#   4 — realpath failed
#
# Bypass for testing/CI: set FLYWHEEL_PRE_WRITE_CHECK_DISABLED=1 (never use
# in production; the guard exists precisely because workers have drifted into
# peer-canonical paths before — see flywheel-16b53 trauma evidence).
#
# Sister primitives:
#   - .flywheel/scripts/cd-realpath-wrapper.sh (cd-time prevention)
#   - .flywheel/scripts/clobber-recovery.sh    (post-clobber recovery)
# ----------------------------------------------------------------------
cli_pre_write_check() {
  local path
  local bead
  path="${1:-}"
  bead="${2:-${FLYWHEEL_CURRENT_BEAD:-unknown}}"
  if [[ -z "$path" ]]; then
    printf 'ERR: cli_pre_write_check requires PATH as first arg\n' >&2
    return 2
  fi
  if [[ "${FLYWHEEL_PRE_WRITE_CHECK_DISABLED:-0}" == "1" ]]; then
    return 0
  fi
  local guard
  guard="${PRE_WRITE_PATH_GUARD:-/Users/josh/Developer/flywheel/.flywheel/scripts/pre-write-path-guard.sh}"
  if [[ ! -x "$guard" ]]; then
    # Guard missing is itself a policy failure — refuse the write rather than
    # silently allow.
    printf 'ERR: pre-write-path-guard.sh not executable at %s\n' "$guard" >&2
    return 3
  fi
  bash "$guard" --path "$path" --bead "$bead" --apply --json >/dev/null
  return $?
}
