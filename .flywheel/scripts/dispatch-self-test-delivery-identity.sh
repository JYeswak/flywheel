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

SCAFFOLD_SCHEMA_VERSION="dispatch-self-test-delivery-identity/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/dispatch-self-test-delivery-identity-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: dispatch-self-test-delivery-identity.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "dispatch-self-test-delivery-identity.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "dispatch-self-test-delivery-identity.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"dispatch-self-test-delivery-identity.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"dispatch-self-test-delivery-identity.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"dispatch-self-test-delivery-identity.sh doctor --json"}'
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
            && cli_emit_completion_bash "dispatch-self-test-delivery-identity" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "dispatch-self-test-delivery-identity" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
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
VERSION="dispatch-self-test-delivery-identity/v1"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
DISPATCH_LOG="${DISPATCH_SELF_TEST_DISPATCH_LOG:-$ROOT/.flywheel/dispatch-log.jsonl}"
DELIVERY_LEDGER="${DISPATCH_SELF_TEST_DELIVERY_LEDGER:-$HOME/.local/state/flywheel/dispatch-self-test-delivery-identity.jsonl}"
LOCK_DIR="${DISPATCH_SELF_TEST_LOCK_DIR:-$HOME/.local/state/flywheel/dispatch-self-test-locks}"
CMD="" PACKET="" KEY="" QUIET=0

usage() {
  cat <<'USAGE'
usage: dispatch-self-test-delivery-identity.sh pretest --packet PATH [--dispatch-log PATH] [--lock-dir PATH] [--json] [--quiet]
       dispatch-self-test-delivery-identity.sh verify-identity --idempotency-key KEY --dispatch-log PATH [--json] [--quiet]
       dispatch-self-test-delivery-identity.sh mark-delivered --idempotency-key KEY [--ledger PATH] [--lock-dir PATH] [--json] [--quiet]
       dispatch-self-test-delivery-identity.sh --info|--help|--examples [--json]
USAGE
}

info() {
  jq -nc --arg version "$VERSION" --arg dispatch_log "$DISPATCH_LOG" --arg ledger "$DELIVERY_LEDGER" --arg lock_dir "$LOCK_DIR" '{
    name:"dispatch-self-test-delivery-identity",
    schema_version:$version,
    subcommands:["pretest","verify-identity","mark-delivered"],
    canonical_cli_flags:["--info","--help","--examples","--json","--quiet"],
    verdicts:["proceed","refuse_duplicate","refuse_complete","refuse_in_flight"],
    dispatch_log:$dispatch_log,
    delivery_ledger:$ledger,
    lock_dir:$lock_dir
  }'
}

examples() {
  jq -nc '{examples:[
    "dispatch-self-test-delivery-identity.sh pretest --packet /tmp/dispatch.md --json",
    "dispatch-self-test-delivery-identity.sh verify-identity --idempotency-key sha256:... --dispatch-log .flywheel/dispatch-log.jsonl --json",
    "dispatch-self-test-delivery-identity.sh mark-delivered --idempotency-key sha256:... --json"
  ]}'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    pretest|verify-identity|mark-delivered) CMD="$1"; shift ;;
    --packet) PACKET="${2:?--packet requires PATH}"; shift 2 ;;
    --packet=*) PACKET="${1#*=}"; shift ;;
    --idempotency-key) KEY="${2:?--idempotency-key requires KEY}"; shift 2 ;;
    --idempotency-key=*) KEY="${1#*=}"; shift ;;
    --dispatch-log) DISPATCH_LOG="${2:?--dispatch-log requires PATH}"; shift 2 ;;
    --dispatch-log=*) DISPATCH_LOG="${1#*=}"; shift ;;
    --ledger) DELIVERY_LEDGER="${2:?--ledger requires PATH}"; shift 2 ;;
    --ledger=*) DELIVERY_LEDGER="${1#*=}"; shift ;;
    --lock-dir) LOCK_DIR="${2:?--lock-dir requires PATH}"; shift 2 ;;
    --lock-dir=*) LOCK_DIR="${1#*=}"; shift ;;
    --json) shift ;;
    --quiet) QUIET=1; shift ;;
    --info) info; exit 0 ;;
    --examples) examples; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'ERR unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ -n "$CMD" ]] || { usage >&2; exit 2; }

python3 - "$CMD" "$PACKET" "$KEY" "$DISPATCH_LOG" "$DELIVERY_LEDGER" "$LOCK_DIR" "$QUIET" <<'PY'
import hashlib, json, re, sys
from datetime import datetime, timezone
from pathlib import Path

VERSION = "dispatch-self-test-delivery-identity/v1"
cmd, packet, key, dispatch_log, delivery_ledger, lock_dir, quiet = sys.argv[1:8]
def ts():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
def norm_key(value):
    value = str(value or "").strip().strip("`'\"")
    if re.fullmatch(r"sha256:[0-9a-f]{64}", value):
        return value
    if re.fullmatch(r"[0-9a-f]{64}", value):
        return "sha256:" + value
    return None
def out(verdict, key_value, prior, reason, extra=None, rc=0):
    payload = {
        "schema_version": VERSION,
        "ts": ts(),
        "idempotency_key": key_value,
        "verdict": verdict,
        "prior_dispatch": prior,
        "reason": reason,
    }
    if extra:
        payload.update(extra)
    if quiet != "1":
        print(json.dumps(payload, separators=(",", ":")))
    raise SystemExit(rc)
def packet_identity(path):
    p = Path(path)
    if not p.exists() or not p.is_file():
        out("refuse_duplicate", None, None, f"malformed dispatch packet: not readable: {path}", rc=2)
    text = p.read_text(encoding="utf-8", errors="replace")
    if not text.strip():
        out("refuse_duplicate", None, None, "malformed dispatch packet: empty", rc=2)
    task = re.search(r"(?im)^(?:task[ _-]?id|Task ID):\s*`?([^`\n]+?)`?\s*$", text)
    target = re.search(r"(?im)^To:\s*([^\n]+?)\s*$", text)
    if not task or not target:
        out("refuse_duplicate", None, None, "malformed dispatch packet: missing Task ID or To", rc=2)
    explicit = re.search(r"(?i)\bidempotency[_-]?key\b\s*[:=]\s*`?([A-Za-z0-9:._-]+)`?", text)
    if explicit:
        parsed = norm_key(explicit.group(1))
        if not parsed:
            out("refuse_duplicate", None, None, "malformed dispatch packet: invalid idempotency_key", rc=2)
        return parsed, task.group(1).strip(), text
    basis = "\n".join([task.group(1).strip(), target.group(1).strip(), text])
    return "sha256:" + hashlib.sha256(basis.encode("utf-8")).hexdigest(), task.group(1).strip(), text
def iter_rows(path):
    p = Path(path).expanduser()
    if not p.exists():
        return
    with p.open(encoding="utf-8", errors="replace") as handle:
        for line_no, line in enumerate(handle, 1):
            if not line.strip():
                continue
            try:
                row = json.loads(line)
            except Exception:
                continue
            yield line_no, row
def has_key(obj, key_value):
    if isinstance(obj, dict):
        for k, v in obj.items():
            if k in {"idempotency_key", "dispatch_identity_key", "delivery_identity_key", "packet_hash", "replay_detection_hash"} and norm_key(v) == key_value:
                return True
            if has_key(v, key_value):
                return True
    elif isinstance(obj, list):
        return any(has_key(v, key_value) for v in obj)
    return False
def lookup(path, key_value):
    prior = None
    for line_no, row in iter_rows(path) or []:
        if not has_key(row, key_value):
            continue
        if prior is None:
            prior = {"task_id": None, "ts": None, "callback_received_at": None, "callback_delivery_verified": False}
        prior["task_id"] = row.get("task_id") or prior["task_id"]
        prior["ts"] = row.get("ts") or row.get("created_ts") or prior["ts"]
        if row.get("callback_received_at"):
            prior["callback_received_at"] = row.get("callback_received_at")
        if row.get("event") == "callback_received" or row.get("status") == "DONE":
            prior["callback_received_at"] = row.get("ts") or row.get("created_ts") or prior["callback_received_at"]
        if row.get("callback_delivery_verified") is True or row.get("event") == "callback_delivery_verified":
            prior["callback_delivery_verified"] = True
        prior["dispatch_log_ref"] = f"{path}#L{line_no}"
    return prior
def verdict_for(prior):
    if prior is None:
        return "proceed", "dispatch identity not present in dispatch log"
    if prior.get("callback_received_at") and prior.get("callback_delivery_verified") is True:
        return "refuse_complete", "prior dispatch completed and delivery was verified"
    if not prior.get("task_id") and not prior.get("ts"):
        return "refuse_duplicate", "prior identity row exists but cannot be classified"
    return "refuse_in_flight", "prior dispatch exists without verified callback delivery"
def lock_path(key_value, prefix=""):
    safe = key_value.replace("sha256:", "")
    return Path(lock_dir).expanduser() / f"{prefix}{safe}.lock"
if cmd == "verify-identity":
    k = norm_key(key)
    if not k:
        out("refuse_duplicate", None, None, "invalid idempotency_key", rc=2)
    prior = lookup(dispatch_log, k)
    verdict, reason = verdict_for(prior)
    out(verdict, k, prior, reason)
if cmd == "pretest":
    k, task_id, body = packet_identity(packet)
    prior = lookup(dispatch_log, k)
    verdict, reason = verdict_for(prior)
    if verdict != "proceed":
        out(verdict, k, prior, reason, rc=1)
    Path(lock_dir).expanduser().mkdir(parents=True, exist_ok=True)
    lp = lock_path(k)
    try:
        lp.mkdir()
        (lp / "packet").write_text(packet + "\n", encoding="utf-8")
        (lp / "task_id").write_text(task_id + "\n", encoding="utf-8")
    except FileExistsError:
        out("refuse_in_flight", k, None, "dispatch identity lock already held", {"lock_path": str(lp)}, rc=1)
    out("proceed", k, None, reason, {"lock_path": str(lp)})
if cmd == "mark-delivered":
    k = norm_key(key)
    if not k:
        out("refuse_duplicate", None, None, "invalid idempotency_key", rc=2)
    prior = lookup(delivery_ledger, k)
    if prior and prior.get("callback_delivery_verified"):
        out("refuse_complete", k, prior, "delivery already confirmed", {"ledger_written": False})
    Path(delivery_ledger).expanduser().parent.mkdir(parents=True, exist_ok=True)
    Path(lock_dir).expanduser().mkdir(parents=True, exist_ok=True)
    mlp = lock_path(k, "mark-")
    try:
        mlp.mkdir()
    except FileExistsError:
        out("refuse_in_flight", k, None, "delivery confirmation lock already held", {"ledger_written": False}, rc=1)
    try:
        prior = lookup(delivery_ledger, k)
        if prior and prior.get("callback_delivery_verified"):
            out("refuse_complete", k, prior, "delivery already confirmed", {"ledger_written": False})
        row = {"schema_version": VERSION, "event": "delivery_confirmed", "ts": ts(), "idempotency_key": k, "callback_delivery_verified": True}
        with Path(delivery_ledger).expanduser().open("a", encoding="utf-8") as handle:
            handle.write(json.dumps(row, separators=(",", ":")) + "\n")
        pre_lock = lock_path(k)
        if pre_lock.exists():
            for child in pre_lock.iterdir():
                child.unlink()
            pre_lock.rmdir()
        out("proceed", k, None, "delivery confirmed event appended", {"ledger_written": True, "ledger": delivery_ledger})
    finally:
        if mlp.exists():
            mlp.rmdir()

out("refuse_duplicate", None, None, f"unknown command: {cmd}", rc=2)
PY
