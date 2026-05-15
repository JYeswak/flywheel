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

SCAFFOLD_SCHEMA_VERSION="agentmail-identity-canonical-validator/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/agentmail-identity-canonical-validator-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: agentmail-identity-canonical-validator.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "agentmail-identity-canonical-validator.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "agentmail-identity-canonical-validator.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"agentmail-identity-canonical-validator.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"agentmail-identity-canonical-validator.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"agentmail-identity-canonical-validator.sh doctor --json"}'
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
            && cli_emit_completion_bash "agentmail-identity-canonical-validator" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "agentmail-identity-canonical-validator" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
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
  # shellcheck disable=SC2317 # scaffold_main exits; retained for generated scaffold consistency.
  exit $?
fi
# ====== END canonical-cli scaffold ======
VERSION="agentmail-identity-canonical-validator.v1.0.0"
SCHEMA_VERSION="agentmail-identity-canonical-validator.v1"
TOPOLOGY="${AICV_TOPOLOGY:-$HOME/.local/state/flywheel/session-topology.jsonl}"
IDENTITY_TOKENS="${AICV_IDENTITY_TOKENS:-$HOME/.local/state/flywheel/identity-tokens.jsonl}"
TOKEN_DIR="${AICV_TOKEN_DIR:-${FLYWHEEL_FLEET_MAIL_TOKEN_VAULT:-$HOME/.local/state/flywheel/fleet-mail-tokens}}"
JSON_OUT=0
QUIET=0
APPLY=0
STRICT=0
MODE="check"

usage() { printf '%s\n' 'usage: agentmail-identity-canonical-validator.sh [--json] [--quiet] [--apply] [--strict] [--topology PATH] [--identity-tokens PATH] [--token-dir DIR]' 'Exit codes: 0=canonical/advisory, 1=strict drift, 2=malformed-state, 3=read-error.'; }

examples() {
  cat <<'EOF'
agentmail-identity-canonical-validator.sh --json
agentmail-identity-canonical-validator.sh --strict --json
agentmail-identity-canonical-validator.sh --topology /tmp/topology.jsonl --token-dir /tmp/tokens --strict --json
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_OUT=1; shift ;;
    --quiet) QUIET=1; shift ;;
    --apply) APPLY=1; shift ;;
    --strict|--enforce) STRICT=1; shift ;;
    --topology) TOPOLOGY="${2:?--topology requires PATH}"; shift 2 ;;
    --identity-tokens) IDENTITY_TOKENS="${2:?--identity-tokens requires PATH}"; shift 2 ;;
    --token-dir) TOKEN_DIR="${2:?--token-dir requires DIR}"; shift 2 ;;
    --info) MODE="info"; shift ;;
    --examples) MODE="examples"; shift ;;
    --help|-h) MODE="help"; shift ;;
    *) printf 'unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ "$MODE" == "help" ]]; then usage; exit 0; fi
if [[ "$MODE" == "examples" ]]; then examples; exit 0; fi
if [[ "$MODE" == "info" ]]; then
  jq -nc --arg version "$VERSION" --arg schema "$SCHEMA_VERSION" \
    '{name:"agentmail-identity-canonical-validator",version:$version,schema_version:$schema,read_only:true,mutates_state:false,canonical_cli:["--info","--help","--examples","--json","--quiet","--apply"],exit_codes:{"0":"canonical or live advisory report","1":"strict drift detected","2":"malformed-state","3":"read-error"},strict_flag:"--strict",identity_primary_key:"session:pane:fleet_mail_project_key"}'
  exit 0
fi

set +e
payload="$(
  python3 - "$TOPOLOGY" "$IDENTITY_TOKENS" "$TOKEN_DIR" "$APPLY" "$STRICT" "$VERSION" "$SCHEMA_VERSION" <<'PY'
import json
import re
import sys
from pathlib import Path

topology_path, identity_path, token_dir_raw, apply_raw, strict_raw, version, schema = sys.argv[1:]
token_dir = Path(token_dir_raw).expanduser()
apply = apply_raw == "1"
strict = strict_raw == "1"

def read_jsonl(path_raw, required=True):
    path = Path(path_raw).expanduser()
    if not path.exists():
        if required:
            raise FileNotFoundError(str(path))
        return [], str(path)
    rows = []
    for idx, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except json.JSONDecodeError as exc:
            raise ValueError(f"{path}:{idx}: {exc}") from exc
        if isinstance(row, dict):
            rows.append(row)
    return rows, str(path)

def latest_by_session(rows):
    latest = {}
    for row in rows:
        session = row.get("session")
        if not session:
            continue
        prev = latest.get(session)
        if prev is None or str(row.get("effective_at") or "") >= str(prev.get("effective_at") or ""):
            latest[session] = row
    return latest

def active_topology(row):
    status = str(row.get("session_status") or "")
    if "metadata_only" in status or "out_of_fleet" in status:
        return False
    return row.get("orchestrator_pane") is not None or bool(row.get("worker_panes") or [])

def identity_of(row):
    return row.get("fleet_mail_identity") or row.get("agent_mail_identity") or ""

def primary_key(row):
    pk = row.get("identity_primary_key") if isinstance(row.get("identity_primary_key"), dict) else {}
    return (
        str(pk.get("session") or row.get("session") or ""),
        str(pk.get("pane") if pk.get("pane") is not None else row.get("pane") if row.get("pane") is not None else ""),
        str(pk.get("fleet_mail_project_key") or row.get("fleet_mail_project_key") or row.get("project") or ""),
    )

def add(drifts, dtype, enforced, **fields):
    row = {"type": dtype, "enforced": bool(enforced)}
    row.update(fields)
    drifts.append(row)

try:
    topology_rows, topology_file = read_jsonl(topology_path)
    identity_rows, identity_file = read_jsonl(identity_path, required=False)
    if not token_dir.exists() or not token_dir.is_dir():
        raise FileNotFoundError(str(token_dir))
    token_names = {p.name[:-6] for p in token_dir.glob("*.token") if p.is_file()}
except FileNotFoundError as exc:
    print(json.dumps({"success": False, "status": "read_error", "read_error": str(exc), "schema_version": schema}))
    raise SystemExit(3)
except ValueError as exc:
    print(json.dumps({"success": False, "status": "malformed_state", "error": str(exc), "schema_version": schema}))
    raise SystemExit(2)

drifts = []
latest = latest_by_session(topology_rows)
active_rows = [r for r in latest.values() if active_topology(r)]
declared = {}
for row in active_rows:
    session = str(row.get("session") or "")
    identity = identity_of(row)
    if not identity:
        add(drifts, "missing_fleet_mail_identity", strict, session=session)
        continue
    declared.setdefault(identity, []).append(session)
    if identity not in token_names:
        add(drifts, "missing_token", strict, session=session, identity=identity, expected_token=f"{identity}.token")

for identity, sessions in declared.items():
    if len(set(sessions)) > 1:
        add(drifts, "duplicate_identity", True, identity=identity, sessions=sorted(set(sessions)))

for token in sorted(token_names - set(declared)):
    add(drifts, "orphan_token", strict, identity=token)

current_by_key = {}
bad_event = re.compile(r"overwrite|mutation|non_append|status_overwrite", re.I)
for row in identity_rows:
    event_text = " ".join(str(row.get(k) or "") for k in ("event", "action", "status", "update_kind"))
    if bad_event.search(event_text):
        add(drifts, "non_append_only", True, identity=row.get("identity") or row.get("identity_name"), event=event_text.strip())
    status = str(row.get("status") or "active")
    if status in {"inactive", "archived", "superseded", "retired"}:
        continue
    key = primary_key(row)
    identity = row.get("identity") or row.get("identity_name")
    if key != ("", "", "") and identity:
        current_by_key.setdefault(key, set()).add(str(identity))

for key, identities in current_by_key.items():
    if len(identities) > 1:
        add(drifts, "non_append_only", True, primary_key=":".join(key), identities=sorted(identities))

enforced = [d for d in drifts if d["enforced"]]
success = not enforced
result = {
    "schema_version": schema,
    "version": version,
    "success": success,
    "status": "canonical" if success and not drifts else ("advisory_drift" if success else "drift"),
    "strict": strict,
    "apply": apply,
    "read_only": True,
    "read_only_verified": True,
    "topology_path": topology_file,
    "identity_tokens_path": identity_file,
    "token_dir": str(token_dir),
    "sessions_checked": len(active_rows),
    "declared_identity_count": len(declared),
    "token_count": len(token_names),
    "drift_count": len(drifts),
    "enforced_drift_count": len(enforced),
    "drift_types": sorted({d["type"] for d in drifts}),
    "drifts": drifts,
}
print(json.dumps(result, separators=(",", ":")))
raise SystemExit(0 if success else 1)
PY
)"
rc=$?
set -e

if [[ "$JSON_OUT" -eq 1 ]]; then
  printf '%s\n' "$payload"
elif [[ "$QUIET" -eq 0 ]]; then
  printf '%s\n' "$payload" | jq -r '"agentmail_identity status=\(.status) success=\(.success) drift_count=\(.drift_count // 0) enforced=\(.enforced_drift_count // 0)"'
fi
exit "$rc"
