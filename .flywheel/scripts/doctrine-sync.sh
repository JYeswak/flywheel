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
# specific logic stays as TODO markers — see grep '# TODO(canonical-cli-scaffold)'.

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="doctrine-sync/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/doctrine-sync-runs.jsonl}"

# Module-load env vars (also re-resolved in cmd_run for backward compat).
# Visible to canonical-cli stubs which run BEFORE cmd_run dispatches.
FLYWHEEL_ROOT="${FLYWHEEL_ROOT:-/Users/josh/Developer/flywheel}"
CANONICAL_SOURCE="${CANONICAL_SOURCE:-${FLYWHEEL_DOCTRINE_CANONICAL_SOURCE:-$FLYWHEEL_ROOT/templates/flywheel-install/AGENTS.md}}"

scaffold_usage() {
  cat <<'USG'
usage: doctrine-sync.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "doctrine-sync.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "doctrine-sync.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"doctrine-sync.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"doctrine-sync.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"doctrine-sync.sh doctor --json"}'
)"
  if command -v cli_emit_quickstart >/dev/null; then
    cli_emit_quickstart "$SCAFFOLD_SCHEMA_VERSION" "$steps" "doctor,health,repair"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"quickstart",helper_lib_missing:true}'
  fi
}

scaffold_emit_schema() {
  local surface="${1:-default}"
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
    '{schema_version:$sv,command:"schema",surface:$surface,note:"TODO(canonical-cli-scaffold): per-surface schema fill-in"}'
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — default backward-compatible invocation routes to cmd_run.\n' ;;
    doctor)   printf 'topic: doctor — TODO(canonical-cli-scaffold): document doctor checks specific to this surface.\n' ;;
    health)   printf 'topic: health — TODO(canonical-cli-scaffold): document health probes specific to this surface.\n' ;;
    repair)   printf 'topic: repair — TODO(canonical-cli-scaffold): document repair scopes + idempotency contract.\n' ;;
    validate) printf 'topic: validate — TODO(canonical-cli-scaffold): document validation subjects + contracts.\n' ;;
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
            && cli_emit_completion_bash "doctrine-sync" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "doctrine-sync" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  # Probe doctrine-sync substrate: canonical source + flywheel root + deps.
  local checks
  checks="$(jq -cs '.' <(
    if [[ -f "$CANONICAL_SOURCE" ]]; then
      jq -nc --arg p "$CANONICAL_SOURCE" '{check:"canonical_source",path:$p,status:"pass"}'
    else
      jq -nc --arg p "$CANONICAL_SOURCE" '{check:"canonical_source",path:$p,status:"fail",reason:"canonical AGENTS template missing"}'
    fi
    if [[ -d "$FLYWHEEL_ROOT/.flywheel" ]]; then
      jq -nc --arg p "$FLYWHEEL_ROOT/.flywheel" '{check:"flywheel_root",path:$p,status:"pass"}'
    else
      jq -nc --arg p "$FLYWHEEL_ROOT/.flywheel" '{check:"flywheel_root",path:$p,status:"fail",reason:"FLYWHEEL_ROOT not a flywheel-installed repo"}'
    fi
    if [[ -d "$FLYWHEEL_ROOT/.flywheel/rules" ]]; then
      local rule_count
      rule_count="$(find "$FLYWHEEL_ROOT/.flywheel/rules" -maxdepth 1 -name 'L*.md' 2>/dev/null | wc -l | tr -d ' ')"
      jq -nc --argjson n "$rule_count" '{check:"rules_dir",rule_count:$n,status:"pass"}'
    else
      jq -nc '{check:"rules_dir",status:"warn",reason:"rules dir absent — canonical L-rules unavailable"}'
    fi
    if command -v jq >/dev/null 2>&1; then
      jq -nc '{check:"core_deps",status:"pass",found:["jq"]}'
    else
      jq -nc '{check:"core_deps",status:"fail",reason:"jq required"}'
    fi
    if command -v rg >/dev/null 2>&1 || command -v grep >/dev/null 2>&1; then
      jq -nc '{check:"text_search",status:"pass"}'
    else
      jq -nc '{check:"text_search",status:"fail",reason:"rg or grep required"}'
    fi
  ))"
  local fails warns
  fails="$(jq -r '[.[] | select(.status=="fail")] | length' <<<"$checks")"
  warns="$(jq -r '[.[] | select(.status=="warn")] | length' <<<"$checks")"
  local status
  if [[ "$fails" -gt 0 ]]; then
    status="fail"
  elif [[ "$warns" -gt 0 ]]; then
    status="warn"
  else
    status="pass"
  fi
  jq -nc \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    --arg ts "$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg status "$status" \
    --argjson checks "$checks" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$status,checks:$checks}'
}

scaffold_cmd_health() {
  # Health: tail audit log; report last-run age + last status.
  local last_ts="" last_status="" age_seconds=null status="empty" row_count=0
  if [[ -r "$SCAFFOLD_AUDIT_LOG" ]]; then
    row_count="$(wc -l <"$SCAFFOLD_AUDIT_LOG" 2>/dev/null | tr -d ' ')"
    if [[ "${row_count:-0}" -gt 0 ]]; then
      last_ts="$(tail -1 "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | jq -r '.ts // empty' 2>/dev/null)"
      last_status="$(tail -1 "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | jq -r '.status // empty' 2>/dev/null)"
      if [[ -n "$last_ts" ]]; then
        local now_epoch last_epoch
        now_epoch="$(date -u +%s 2>/dev/null)"
        last_epoch="$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$last_ts" +%s 2>/dev/null || date -u -d "$last_ts" +%s 2>/dev/null || echo "")"
        if [[ -n "$now_epoch" && -n "$last_epoch" ]]; then
          age_seconds=$((now_epoch - last_epoch))
        fi
      fi
      if [[ "$last_status" == "ok" || "$last_status" == "pass" || "$last_status" == "applied" ]]; then
        status="ok"
      elif [[ -n "$last_status" ]]; then
        status="degraded"
      else
        status="malformed"
      fi
    fi
  else
    status="not_initialized"
  fi
  jq -nc \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    --arg ts "$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg status "$status" \
    --arg last_ts "$last_ts" \
    --arg last_status "$last_status" \
    --argjson row_count "$row_count" \
    --argjson age_seconds "${age_seconds:-null}" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,row_count:$row_count,last_run_ts:(if $last_ts=="" then null else $last_ts end),last_run_status:(if $last_status=="" then null else $last_status end),last_run_age_seconds:$age_seconds}'
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
  # repair --scope state: ensure SCAFFOLD_AUDIT_LOG parent dir exists.
  local audit_dir planned applied
  audit_dir="$(dirname "$SCAFFOLD_AUDIT_LOG")"
  planned="$(jq -cs '.' <(
    if [[ "$scope" != "state" ]]; then
      jq -nc --arg s "$scope" '{action:"none",reason:"unsupported scope (state only)",scope:$s}'
    else
      if [[ ! -d "$audit_dir" ]]; then
        jq -nc --arg p "$audit_dir" '{action:"mkdir",path:$p,mode:"0755"}'
      fi
    fi
  ))"
  applied='[]'
  if [[ "$mode" == "apply" && "$scope" == "state" ]]; then
    local applied_rows=()
    if [[ ! -d "$audit_dir" ]]; then
      mkdir -p "$audit_dir" && chmod 755 "$audit_dir" 2>/dev/null
      applied_rows+=("$(jq -nc --arg p "$audit_dir" --arg key "$idem_key" '{action:"mkdir",path:$p,mode:"0755",idempotency_key:$key}')")
    fi
    if [[ "${#applied_rows[@]}" -eq 0 ]]; then
      applied='[]'
    else
      applied="$(printf '%s\n' "${applied_rows[@]}" | jq -cs '.')"
    fi
    if command -v cli_audit_append >/dev/null; then
      cli_audit_append "$SCAFFOLD_AUDIT_LOG" "repair_state_apply" "ok" \
        "$(jq -nc --arg key "$idem_key" --argjson actions "$applied" '{idempotency_key:$key,actions:$actions}')"
    fi
  fi
  local status
  if [[ "$mode" == "apply" ]]; then
    status="applied"
  else
    status="dry_run"
  fi
  jq -nc \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    --arg scope "$scope" \
    --arg mode "$mode" \
    --arg idem "$idem_key" \
    --arg status "$status" \
    --argjson planned "$planned" \
    --argjson applied "$applied" \
    '{schema_version:$sv,command:"repair",status:$status,mode:$mode,scope:$scope,idempotency_key:$idem,planned_actions:$planned,applied_actions:$applied}'
}

scaffold_cmd_validate() {
  local subject="${1:-canonical_source}"
  if [[ "$subject" == "-h" || "$subject" == "--help" ]]; then
    scaffold_emit_topic_help validate
    return 0
  fi
  shift 2>/dev/null || true
  local results status
  case "$subject" in
    canonical_source)
      # Validate the canonical AGENTS template is well-formed: file exists,
      # contains BEGIN/END canonical block markers, and at least one L-rule entry.
      if [[ ! -f "$CANONICAL_SOURCE" ]]; then
        results="$(jq -nc --arg p "$CANONICAL_SOURCE" '[{check:"file_exists",path:$p,status:"fail",reason:"canonical source missing"}]')"
      else
        local has_begin has_end has_rules
        has_begin="false"; has_end="false"; has_rules="false"
        if grep -q "BEGIN-CANONICAL-FLYWHEEL-DOCTRINE" "$CANONICAL_SOURCE" 2>/dev/null; then has_begin="true"; fi
        if grep -q "END-CANONICAL-FLYWHEEL-DOCTRINE" "$CANONICAL_SOURCE" 2>/dev/null; then has_end="true"; fi
        if grep -qE "L[0-9]+ — " "$CANONICAL_SOURCE" 2>/dev/null; then has_rules="true"; fi
        results="$(jq -nc \
          --arg p "$CANONICAL_SOURCE" \
          --argjson hb "$has_begin" \
          --argjson he "$has_end" \
          --argjson hr "$has_rules" \
          '[
            {check:"file_exists",path:$p,status:"pass"},
            {check:"begin_marker",status:(if $hb then "pass" else "fail" end)},
            {check:"end_marker",status:(if $he then "pass" else "fail" end)},
            {check:"l_rule_entries",status:(if $hr then "pass" else "fail" end)}
          ]')"
      fi
      ;;
    *)
      results="$(jq -nc --arg s "$subject" '[{status:"unsupported",subject:$s,supported:["canonical_source"]}]')"
      ;;
  esac
  local fails
  fails="$(jq -r '[.[] | select(.status=="fail")] | length' <<<"$results")"
  if [[ "$fails" -gt 0 ]]; then
    status="fail"
  else
    status="pass"
  fi
  jq -nc \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    --arg subject "$subject" \
    --arg status "$status" \
    --argjson results "$results" \
    '{schema_version:$sv,command:"validate",subject:$subject,status:$status,results:$results}'
}

scaffold_cmd_audit() {
  if command -v cli_emit_audit_tail >/dev/null; then
    cli_emit_audit_tail "$SCAFFOLD_AUDIT_LOG" "$SCAFFOLD_SCHEMA_VERSION" 20
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg log "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"audit",audit_log:$log,status:"helper_lib_missing"}'
  fi
}

scaffold_cmd_why() {
  local id="${1:-}"
  if [[ -z "$id" ]]; then
    printf 'ERR: why requires <id> argument\n' >&2; return 64
  fi
  # <id> is an L-rule id (e.g., "L48", "L153"). Look up canonical body.
  if [[ ! -f "$CANONICAL_SOURCE" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" --arg src "$CANONICAL_SOURCE" \
      '{schema_version:$sv,command:"why",id:$id,status:"unavailable",reason:"canonical source missing",source:$src}'
    return 0
  fi
  local heading=""
  # Match either "## L48 — TITLE" body heading or "| 1 | L48 — TITLE | ..." index row.
  heading="$( { grep -E "^## ${id} (—|--)" "$CANONICAL_SOURCE" 2>/dev/null || true; } | head -1)"
  if [[ -z "$heading" ]]; then
    heading="$( { grep -E "^\| [0-9]+ \| ${id} (—|--)" "$CANONICAL_SOURCE" 2>/dev/null || true; } | head -1)"
  fi
  if [[ -n "$heading" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" --arg src "$CANONICAL_SOURCE" --arg heading "$heading" \
      '{schema_version:$sv,command:"why",id:$id,status:"found",source:$src,heading:$heading}'
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" --arg src "$CANONICAL_SOURCE" \
      '{schema_version:$sv,command:"why",id:$id,status:"not_found",source:$src,note:"L-rule id not found in canonical AGENTS template"}'
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
FLYWHEEL_ROOT="${FLYWHEEL_ROOT:-/Users/josh/Developer/flywheel}"
CANONICAL_SOURCE="${FLYWHEEL_DOCTRINE_CANONICAL_SOURCE:-$FLYWHEEL_ROOT/templates/flywheel-install/AGENTS.md}"
TARGET_REPO="${TARGET_REPO:-$PWD}"
APPLY=0
JSON_OUT=0
IDEMPOTENCY_KEY=""
L_RULES=""

usage() {
  cat <<'USAGE'
usage: doctrine-sync.sh --target-repo PATH [--dry-run|--apply] [--idempotency-key KEY] [--l-rules L29,L35] [--json]

Diffs one flywheel-installed repo against the canonical flywheel AGENTS template.
Default is dry-run. Apply mode appends missing L-rules only and stamps
.flywheel/STATE.json with the current doctrine_version.

Safety:
  - refuses targets without .flywheel/
  - --apply requires --idempotency-key
  - --l-rules limits append/apply to reviewed L-rule ids for wave applies
  - never rewrites existing L-rules
  - one target repo per run
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target-repo|--repo)
      [[ -n "${2:-}" ]] || { echo "ERR: $1 requires PATH" >&2; exit 2; }
      TARGET_REPO="$2"; shift 2 ;;
    --source)
      [[ -n "${2:-}" ]] || { echo "ERR: --source requires PATH" >&2; exit 2; }
      CANONICAL_SOURCE="$2"; shift 2 ;;
    --dry-run)
      APPLY=0; shift ;;
    --apply)
      APPLY=1; shift ;;
    --idempotency-key)
      [[ -n "${2:-}" ]] || { echo "ERR: --idempotency-key requires KEY" >&2; exit 2; }
      IDEMPOTENCY_KEY="$2"; shift 2 ;;
    --l-rules|--rules)
      [[ -n "${2:-}" ]] || { echo "ERR: $1 requires comma-separated L-rule ids" >&2; exit 2; }
      L_RULES="$2"; shift 2 ;;
    --json)
      JSON_OUT=1; shift ;;
    --version-stamp|--print-version)
      python3 - "$CANONICAL_SOURCE" "$FLYWHEEL_ROOT" <<'PY'
import json
import re
import subprocess
import sys
from pathlib import Path

source = Path(sys.argv[1]).expanduser()
root = Path(sys.argv[2]).expanduser()
text = source.read_text(encoding="utf-8")
rules = []
for match in re.finditer(r"(?m)^## (L(\d+))\b.*$", text):
    start = match.start()
    nxt = re.search(r"(?m)^## L\d+\b.*$", text[match.end():])
    end = match.end() + nxt.start() if nxt else len(text)
    body = text[start:end]
    shipped = re.search(r"(?m)^shipped:\s*([0-9]{4}-[0-9]{2}-[0-9]{2})\s*$", body)
    rules.append((int(match.group(2)), match.group(1), shipped.group(1) if shipped else "unknown"))
highest = max(rules, default=(0, "L0", "unknown"))
try:
    sha = subprocess.check_output(["git", "-C", str(root), "rev-parse", "--short", "HEAD"], text=True).strip()
except Exception:
    sha = "unknown"
print(json.dumps({"doctrine_version": f"{highest[2]}.{highest[1]}", "highest_l_rule": highest[1], "shipped": highest[2], "canonical_source": str(source), "canonical_sha": sha}, sort_keys=True))
PY
      exit 0 ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "ERR: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ "$APPLY" -eq 1 && -z "$IDEMPOTENCY_KEY" ]]; then
  echo "ERR: --apply requires --idempotency-key" >&2
  exit 3
fi

if [[ ! -f "$CANONICAL_SOURCE" ]]; then
  echo "ERR: canonical source not found: $CANONICAL_SOURCE" >&2
  exit 2
fi

if ! TARGET_ABS="$(cd "$TARGET_REPO" 2>/dev/null && pwd -P)"; then
  echo "ERR: target repo not found: $TARGET_REPO" >&2
  exit 2
fi

if [[ ! -d "$TARGET_ABS/.flywheel" ]]; then
  echo "ERR: target repo is not flywheel-initialized: $TARGET_ABS" >&2
  exit 2
fi

python3 - "$FLYWHEEL_ROOT" "$CANONICAL_SOURCE" "$TARGET_ABS" "$APPLY" "$IDEMPOTENCY_KEY" "$JSON_OUT" "$L_RULES" <<'PY'
import json
import os
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

root = Path(sys.argv[1]).expanduser()
canonical_source = Path(sys.argv[2]).expanduser()
target = Path(sys.argv[3]).expanduser()
apply = sys.argv[4] == "1"
key = sys.argv[5]
json_out = sys.argv[6] == "1"
allowlist_raw = sys.argv[7].strip()

def utc_now():
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")

def git_sha():
    try:
        return subprocess.check_output(["git", "-C", str(root), "rev-parse", "--short", "HEAD"], text=True).strip()
    except Exception:
        return "unknown"

def parse_rules(path):
    if not path.exists():
        return {}, ""
    text = path.read_text(encoding="utf-8", errors="ignore")
    matches = list(re.finditer(r"(?m)^## (L(\d+))\b.*$", text))
    rules = {}
    for idx, match in enumerate(matches):
        end = matches[idx + 1].start() if idx + 1 < len(matches) else len(text)
        body = text[match.start():end].rstrip() + "\n"
        heading = match.group(0)
        shipped = re.search(r"(?m)^shipped:\s*([0-9]{4}-[0-9]{2}-[0-9]{2})\s*$", body)
        rules[match.group(1)] = {
            "id": match.group(1),
            "number": int(match.group(2)),
            "heading": heading,
            "title": re.sub(r"^##\s+", "", heading),
            "shipped": shipped.group(1) if shipped else None,
            "body": body,
        }
    return rules, text

canonical_rules, _ = parse_rules(canonical_source)
if not canonical_rules:
    raise SystemExit("ERR: canonical source has no L-rule headings")

errors = []
requested_l_rules = []
if allowlist_raw:
    seen = set()
    for token in re.split(r"[,\s]+", allowlist_raw):
        if not token:
            continue
        match = re.fullmatch(r"[Ll](\d+)", token.strip())
        if not match:
            errors.append(f"invalid_l_rule_id:{token}")
            continue
        rid = f"L{int(match.group(1))}"
        if rid not in seen:
            requested_l_rules.append(rid)
            seen.add(rid)
    if not requested_l_rules:
        errors.append("l_rules_allowlist_empty")
    for rid in requested_l_rules:
        if rid not in canonical_rules:
            errors.append(f"l_rule_not_in_canonical:{rid}")

allowed_rule_ids = {rid for rid in requested_l_rules if rid in canonical_rules} if requested_l_rules else set(canonical_rules)

highest = max(canonical_rules.values(), key=lambda row: row["number"])
version_date = highest["shipped"] or datetime.now(timezone.utc).strftime("%Y-%m-%d")
doctrine_version = f"{version_date}.{highest['id']}"
sha = git_sha()
ts = utc_now()
provenance = f"# Pulled from flywheel/templates/flywheel-install/AGENTS.md@{sha}"

surfaces = [
    ("agents_md", target / "AGENTS.md"),
    ("agents_canonical", target / ".flywheel" / "AGENTS-CANONICAL.md"),
]

surface_rows = {}
union_missing = set()
union_missing_all = set()
union_unselected_missing = set()
for name, path in surfaces:
    rules, _ = parse_rules(path)
    missing_all = sorted(set(canonical_rules) - set(rules), key=lambda rid: canonical_rules[rid]["number"])
    missing = sorted(set(allowed_rule_ids) - set(rules), key=lambda rid: canonical_rules[rid]["number"])
    unselected_missing = sorted(set(missing_all) - set(missing), key=lambda rid: canonical_rules[rid]["number"])
    union_missing.update(missing)
    union_missing_all.update(missing_all)
    union_unselected_missing.update(unselected_missing)
    surface_rows[name] = {
        "path": str(path),
        "exists": path.exists(),
        "l_rule_count": len(rules),
        "missing_count": len(missing),
        "missing_l_rules": missing,
        "missing_l_rules_all_count": len(missing_all),
        "missing_l_rules_all": missing_all,
        "unselected_missing_l_rules": unselected_missing,
        "will_append": bool(apply and path.exists() and missing),
    }

state_path = target / ".flywheel" / "STATE.json"
state_exists = state_path.exists()
current_doctrine_version = None
state_error = None
state_payload = {}
if state_exists:
    try:
        state_payload = json.loads(state_path.read_text(encoding="utf-8"))
        if not isinstance(state_payload, dict):
            state_error = "state_json_not_object"
            state_payload = {}
        else:
            current_doctrine_version = state_payload.get("doctrine_version")
    except Exception as exc:
        state_error = f"state_json_parse_failed:{exc}"

receipt_dir = target / ".flywheel" / "receipts" / "doctrine-sync"
receipt_path = receipt_dir / f"{key}.json" if key else None

if apply:
    if receipt_path and receipt_path.exists():
        errors.append(f"idempotency_key_replay:{receipt_path}")
    for name, row in surface_rows.items():
        if not row["exists"]:
            errors.append(f"surface_missing:{name}:{row['path']}")
    if state_error:
        errors.append(state_error)

appended = {}
state_updated = False
state_should_update = current_doctrine_version != doctrine_version and (
    not requested_l_rules or not union_unselected_missing
)
if apply and not errors:
    for name, path in surfaces:
        missing = surface_rows[name]["missing_l_rules"]
        appended[name] = len(missing)
        if not missing:
            continue
        with path.open("a", encoding="utf-8") as fh:
            fh.write("\n\n")
            for rid in missing:
                fh.write(canonical_rules[rid]["body"].rstrip())
                fh.write("\n\n")
            fh.write(provenance)
            fh.write("\n")
    receipt_dir.mkdir(parents=True, exist_ok=True)
    if state_should_update:
        state_payload["doctrine_version"] = doctrine_version
        state_payload["doctrine_version_source"] = "flywheel/templates/flywheel-install/AGENTS.md"
        state_payload["doctrine_version_sha"] = sha
        state_payload["doctrine_version_updated_at"] = ts
        tmp_state = state_path.with_suffix(state_path.suffix + ".tmp")
        tmp_state.write_text(json.dumps(state_payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
        tmp_state.replace(state_path)
        state_updated = True

missing_bodies = [
    {
        "id": rid,
        "heading": canonical_rules[rid]["heading"],
        "body": canonical_rules[rid]["body"],
    }
    for rid in sorted(union_missing, key=lambda rid: canonical_rules[rid]["number"])
]

status = "ERROR" if errors else (
    "APPLIED" if apply and (union_missing or state_should_update)
    else ("DRIFT" if union_missing or (not requested_l_rules and current_doctrine_version != doctrine_version) else "CURRENT")
)
payload = {
    "schema_version": "flywheel.doctrine_sync.v1",
    "generated_at": ts,
    "mode": "apply" if apply else "dry-run",
    "apply": apply,
    "target_repo": str(target),
    "canonical_source": str(canonical_source),
    "canonical_sha": sha,
    "highest_l_rule": highest["id"],
    "proposed_doctrine_version": doctrine_version,
    "current_doctrine_version": current_doctrine_version,
    "status": status,
    "soft_violation": (
        "doctrine_behind_canonical_outside_allowlist" if requested_l_rules and union_unselected_missing
        else ("doctrine_behind_canonical" if current_doctrine_version != doctrine_version else None)
    ),
    "l_rules_allowlist": requested_l_rules,
    "l_rules_allowlist_active": bool(requested_l_rules),
    "surfaces": surface_rows,
    "missing_l_rules": sorted(union_missing, key=lambda rid: canonical_rules[rid]["number"]),
    "missing_l_rules_count": len(union_missing),
    "missing_l_rules_all": sorted(union_missing_all, key=lambda rid: canonical_rules[rid]["number"]),
    "missing_l_rules_all_count": len(union_missing_all),
    "unselected_missing_l_rules": sorted(union_unselected_missing, key=lambda rid: canonical_rules[rid]["number"]),
    "unselected_missing_l_rules_count": len(union_unselected_missing),
    "missing_l_rule_bodies": missing_bodies,
    "state_json": {
        "path": str(state_path),
        "exists": state_exists,
        "current_doctrine_version": current_doctrine_version,
        "proposed_doctrine_version": doctrine_version,
        "will_update": bool(apply and state_should_update),
        "updated": state_updated,
        "error": state_error,
    },
    "provenance_footer": provenance,
    "receipt_path": str(receipt_path) if receipt_path else None,
    "errors": errors,
    "appended": appended,
}

if apply and not errors and receipt_path:
    receipt_path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")

if json_out:
    print(json.dumps(payload, sort_keys=True, separators=(",", ":")))
else:
    scope = ",".join(requested_l_rules) if requested_l_rules else "all"
    print(f"doctrine-sync target={target} status={status} scope={scope} missing_l_rules={len(union_missing)} current={current_doctrine_version or 'null'} proposed={doctrine_version}")
    if union_missing:
        print("missing: " + ",".join(payload["missing_l_rules"]))
    if not apply:
        print("dry-run; pass --apply --idempotency-key <key> to append missing rules and stamp STATE.json")

if errors:
    raise SystemExit(4)
PY
