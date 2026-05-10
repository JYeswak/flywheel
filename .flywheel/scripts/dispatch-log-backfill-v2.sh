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

SCAFFOLD_SCHEMA_VERSION="dispatch-log-backfill-v2/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/dispatch-log-backfill-v2-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: dispatch-log-backfill-v2.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "dispatch-log-backfill-v2.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "dispatch-log-backfill-v2.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"dispatch-log-backfill-v2.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"dispatch-log-backfill-v2.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"dispatch-log-backfill-v2.sh doctor --json"}'
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
            && cli_emit_completion_bash "dispatch-log-backfill-v2" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "dispatch-log-backfill-v2" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  # TODO(canonical-cli-scaffold): probe substrate this script depends on
  # (env vars, paths, external tools) and emit per-check status.
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:"todo",checks:[],note:"TODO(canonical-cli-scaffold): fill in doctor checks"}'
}

scaffold_cmd_health() {
  # TODO(canonical-cli-scaffold): summarize last-run state from audit log.
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{schema_version:$sv,command:"health",ts:$ts,status:"todo",note:"TODO(canonical-cli-scaffold): fill in health probe from audit log"}'
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
  # TODO(canonical-cli-scaffold): per-scope repair actions go here.
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" --arg idem "$idem_key" \
    '{schema_version:$sv,command:"repair",status:"todo",mode:$mode,scope:$scope,idempotency_key:$idem,note:"TODO(canonical-cli-scaffold): fill in repair scope actions"}'
}

scaffold_cmd_validate() {
  # TODO(canonical-cli-scaffold): document validation subjects + contracts.
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    '{schema_version:$sv,command:"validate",status:"todo",note:"TODO(canonical-cli-scaffold): fill in per-subject validation"}'
}

scaffold_cmd_audit() {
  # TODO(canonical-cli-scaffold): tail audit log; emit recent rows.
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg log "$SCAFFOLD_AUDIT_LOG" \
    '{schema_version:$sv,command:"audit",audit_log:$log,status:"todo",note:"TODO(canonical-cli-scaffold): fill in audit tail"}'
}

scaffold_cmd_why() {
  local id="${1:-}"
  if [[ -z "$id" ]]; then
    printf 'ERR: why requires <id> argument\n' >&2; return 64
  fi
  # TODO(canonical-cli-scaffold): explain why <id> is/isn't in scope.
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" \
    '{schema_version:$sv,command:"why",id:$id,status:"todo",note:"TODO(canonical-cli-scaffold): fill in why-id semantics"}'
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
VERSION="dispatch-log-backfill-v2/v1"
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
MODE="dry-run"
JSON_OUT=0
IDEMPOTENCY_KEY=""
RECEIPT_PATH=""
EXPECTED_ANCHOR="${FLYWHEEL_MISSION_ANCHOR:-continuous-orchestrator-uptime-self-sustaining-fleet}"

usage() {
  cat <<'EOF'
usage: dispatch-log-backfill-v2.sh [--repo PATH] [--dry-run|--apply] [--idempotency-key KEY] [--receipt PATH] [--json]

Annotates legacy .flywheel/dispatch-log.jsonl rows into schema_version=2 shape.
Dry-run prints planned row annotations and does not mutate the dispatch log.
Apply requires --idempotency-key and writes an audit receipt.
EOF
}

die() {
  if [ "$JSON_OUT" -eq 1 ]; then
    jq -nc --arg status "error" --arg reason "$1" --arg version "$VERSION" \
      '{schema_version:$version,status:$status,reason:$reason}'
  else
    printf 'ERR: %s\n' "$1" >&2
  fi
  exit "${2:-2}"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo) [ "$#" -ge 2 ] || die "--repo requires PATH"; REPO="$(cd "$2" && pwd -P)"; shift 2 ;;
    --repo=*) REPO="$(cd "${1#*=}" && pwd -P)"; shift ;;
    --dry-run) MODE="dry-run"; shift ;;
    --apply) MODE="apply"; shift ;;
    --idempotency-key) [ "$#" -ge 2 ] || die "--idempotency-key requires KEY"; IDEMPOTENCY_KEY="$2"; shift 2 ;;
    --idempotency-key=*) IDEMPOTENCY_KEY="${1#*=}"; shift ;;
    --receipt) [ "$#" -ge 2 ] || die "--receipt requires PATH"; RECEIPT_PATH="$2"; shift 2 ;;
    --receipt=*) RECEIPT_PATH="${1#*=}"; shift ;;
    --json) JSON_OUT=1; shift ;;
    --help|-h) usage; exit 0 ;;
    --info)
      jq -nc --arg version "$VERSION" --arg repo "$REPO" \
        '{name:"dispatch-log-backfill-v2.sh",version:$version,repo:$repo,default_mode:"dry-run",mutates:"--apply rewrites .flywheel/dispatch-log.jsonl atomically and writes receipt",requires_apply:["--idempotency-key"]}'
      exit 0
      ;;
    *) die "unknown argument: $1" ;;
  esac
done

[ -d "$REPO/.flywheel" ] || die "repo_missing_flywheel"
LOG_PATH="$REPO/.flywheel/dispatch-log.jsonl"
[ -f "$LOG_PATH" ] || die "dispatch_log_missing" 1

if [ "$MODE" = "apply" ] && [ -z "$IDEMPOTENCY_KEY" ]; then
  die "idempotency_key_required"
fi

if [ -z "$RECEIPT_PATH" ]; then
  safe_key="${IDEMPOTENCY_KEY:-dry-run}"
  safe_key="$(printf '%s' "$safe_key" | tr -cs 'A-Za-z0-9._-' '-')"
  RECEIPT_PATH="$REPO/.flywheel/receipts/dispatch-log-backfill-${safe_key}.json"
fi

TMPDIR_BACKFILL="$(mktemp -d -t u1x3.XXXXXX)"
trap 'rm -rf "$TMPDIR_BACKFILL"' EXIT
SUMMARY="$TMPDIR_BACKFILL/summary.json"
NEW_LOG="$TMPDIR_BACKFILL/dispatch-log.jsonl"

python3 - "$LOG_PATH" "$NEW_LOG" "$VERSION" "$MODE" "$IDEMPOTENCY_KEY" "$EXPECTED_ANCHOR" >"$SUMMARY" <<'PY'
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

log_path = Path(sys.argv[1])
new_log_path = Path(sys.argv[2])
version = sys.argv[3]
mode = sys.argv[4]
key = sys.argv[5]
mission_anchor = sys.argv[6]

now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

def is_v2(row):
    return str(row.get("schema_version", "")) == "2"

def first_str(row, *names, default=""):
    for name in names:
        value = row.get(name)
        if value is not None and str(value).strip():
            return str(value).strip()
    return default

def infer_session(row):
    direct = first_str(row, "session", "target_session")
    if direct:
        return direct
    for name in ("dispatched_to", "to", "target"):
        value = first_str(row, name)
        if ":" in value:
            return value.split(":", 1)[0]
    return "legacy"

def infer_pane(row):
    for name in ("pane", "target_pane", "topology_resolved_pane", "callback_pane"):
        value = row.get(name)
        if isinstance(value, int) and not isinstance(value, bool):
            return value
        if isinstance(value, str) and value.isdigit():
            return int(value)
    for name in ("dispatched_to", "to", "target"):
        value = first_str(row, name)
        match = re.search(r":([0-9]+)\b", value)
        if match:
            return int(match.group(1))
    return 0

def short_summary(row, line):
    value = first_str(row, "task_summary", "summary", "task", "bead_id", "bead", default=f"legacy dispatch row {line}")
    return value[:100] or f"legacy dispatch row {line}"

def task_file(row, line):
    value = first_str(row, "task_file", "dispatch_file", "file")
    if value.startswith("/"):
        return value
    return f"/tmp/legacy-dispatch-log-line-{line}.md"

def agent_type(row):
    value = first_str(row, "agent_type").lower()
    if value in {"codex", "claude", "gemini", "other"}:
        return value
    joined = " ".join(str(row.get(name, "")) for name in ("to", "agent", "agent_type", "worker_substrate")).lower()
    if "codex" in joined:
        return "codex"
    if "claude" in joined:
        return "claude"
    if "gemini" in joined:
        return "gemini"
    return "other"

def pane_state_source(row):
    value = first_str(row, "pane_state_source")
    if value in {"ntm_health", "ntm_copy", "raw_capture", "none"}:
        return value
    return "none"

def iso_or_now(row):
    value = first_str(row, "ts", "timestamp", "created_at")
    return value or now

def backfill(row, line):
    session = infer_session(row)
    pane = infer_pane(row)
    task_id = first_str(row, "task_id", "dispatch_id", "id", default=f"legacy-line-{line}")
    updated = dict(row)
    updated.update({
        "schema_version": 2,
        "task_id": task_id,
        "ts": iso_or_now(row),
        "from": first_str(row, "from", default="legacy-dispatch-log"),
        "to": first_str(row, "to", default=f"{session}:{pane}"),
        "pane": pane,
        "session": session,
        "task_summary": short_summary(row, line),
        "task_file": task_file(row, line),
        "agent_type": agent_type(row),
        "pane_state_source": pane_state_source(row),
        "mission_anchor": first_str(row, "mission_anchor", default=mission_anchor),
        "mission_fitness_claim": first_str(row, "mission_fitness_claim", default="legacy backfill: row predates dispatch-log v2 contract"),
        "mission_fitness_class": first_str(row, "mission_fitness_class", default="unknown"),
        "idempotency_token": first_str(row, "idempotency_token", default=f"{key or 'dry-run'}:{task_id}:{line}"),
        "callback_received_at": row.get("callback_received_at", None),
        "dispatch_skill_version": first_str(row, "dispatch_skill_version", default="legacy"),
        "backfilled": True,
        "backfill_schema_version": version,
        "backfill_source_line": line,
    })
    if key:
        updated["backfill_idempotency_key"] = key
    return updated

planned = []
output_lines = []
malformed = 0
already_v2 = 0
already_keyed = 0

for line_no, raw in enumerate(log_path.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
    if not raw.strip():
        output_lines.append(raw)
        continue
    try:
        row = json.loads(raw)
    except json.JSONDecodeError:
        malformed += 1
        output_lines.append(raw)
        continue
    if not isinstance(row, dict):
        output_lines.append(raw)
        continue
    if is_v2(row):
        already_v2 += 1
        output_lines.append(json.dumps(row, sort_keys=True, separators=(",", ":")))
        continue
    if key and row.get("backfill_idempotency_key") == key:
        already_keyed += 1
        output_lines.append(json.dumps(row, sort_keys=True, separators=(",", ":")))
        continue
    new_row = backfill(row, line_no)
    planned.append({
        "line": line_no,
        "task_id": new_row["task_id"],
        "session": new_row["session"],
        "pane": new_row["pane"],
        "dispatch_skill_version": new_row["dispatch_skill_version"],
    })
    output_lines.append(json.dumps(new_row, sort_keys=True, separators=(",", ":")))

new_log_path.write_text("\n".join(output_lines) + ("\n" if output_lines else ""), encoding="utf-8")

summary = {
    "schema_version": version,
    "mode": mode,
    "status": "ok",
    "dispatch_log": str(log_path),
    "checked": len(output_lines),
    "planned_annotations": planned,
    "planned_annotations_count": len(planned),
    "already_v2_count": already_v2,
    "already_keyed_count": already_keyed,
    "malformed_skipped_count": malformed,
    "mutated": False,
}
if key:
    summary["idempotency_key"] = key
print(json.dumps(summary, sort_keys=True))
PY

if [ "$MODE" = "apply" ]; then
  tmp_log="$(mktemp "${LOG_PATH}.XXXXXX")"
  cp "$NEW_LOG" "$tmp_log"
  mv "$tmp_log" "$LOG_PATH"
  mkdir -p "$(dirname "$RECEIPT_PATH")"
  jq --arg ts "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" --arg receipt "$RECEIPT_PATH" \
    '. + {mutated:true, applied_at:$ts, audit_receipt_path:$receipt}' "$SUMMARY" >"$RECEIPT_PATH"
  cp "$RECEIPT_PATH" "$SUMMARY"
fi

if [ "$JSON_OUT" -eq 1 ]; then
  cat "$SUMMARY"
else
  jq -r '
    "mode=\(.mode) planned_annotations=\(.planned_annotations_count) already_v2=\(.already_v2_count) malformed_skipped=\(.malformed_skipped_count) mutated=\(.mutated)",
    (.planned_annotations[]? | "line=\(.line) task_id=\(.task_id) session=\(.session) pane=\(.pane) dispatch_skill_version=\(.dispatch_skill_version)")
  ' "$SUMMARY"
fi
