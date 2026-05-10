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

SCAFFOLD_SCHEMA_VERSION="flywheel-recovery/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/flywheel-recovery-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: flywheel-recovery.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "flywheel-recovery.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "flywheel-recovery.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"flywheel-recovery.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"flywheel-recovery.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"flywheel-recovery.sh doctor --json"}'
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
            && cli_emit_completion_bash "flywheel-recovery" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "flywheel-recovery" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
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
python3 - "$@" <<'PY'
import argparse, fcntl, hashlib, json, os, re, shutil, subprocess, sys, time
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2] if "__file__" in globals() else Path.cwd()
SOURCE_PLAN = "/Users/josh/Developer/flywheel/.flywheel/PLANS/recovery-system-2026-05-01/00-PLAN.md"
MISSION_ANCHOR = "continuous-orchestrator-uptime-self-sustaining-fleet"
L112 = "OK_recovery_session_paths"
TARGETS = [
    "flywheel",
    "alpsinsurance",
    "clutterfreespaces",
    "picoz",
    "skillos",
    "vrtx",
    "zeststream-v2",
    "zesttube",
]
CANONICAL = {
    "flywheel": "/Users/josh/Developer/flywheel",
    "alpsinsurance": "/Users/josh/Developer/alpsinsurance",
    "clutterfreespaces": "/Users/josh/Developer/clutterfreespaces",
    "picoz": "/Users/josh/Developer/polymarket-pico-z",
    "skillos": "/Users/josh/Developer/skillos",
    "vrtx": "/Users/josh/Developer/vrtx",
    "zeststream-v2": "/Users/josh/Developer/zeststream-v2",
    "zesttube": "/Users/josh/Developer/zesttube",
}

def canonical_paths():
    override = os.environ.get("FLYWHEEL_RECOVERY_CANONICAL_JSON", "")
    if not override:
        return dict(CANONICAL)
    try:
        data = json.loads(override)
    except json.JSONDecodeError as exc:
        raise SystemExit(f"invalid FLYWHEEL_RECOVERY_CANONICAL_JSON: {exc}")
    paths = dict(CANONICAL)
    for key, value in data.items():
        if key in TARGETS:
            paths[key] = str(value)
    return paths

def now_iso():
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")

def sha(path):
    p = Path(path).expanduser()
    return hashlib.sha256(p.read_bytes()).hexdigest() if p.exists() else None

def emit(payload, json_mode=True, rc=0):
    print(json.dumps(payload, sort_keys=True, separators=(",", ":")) if json_mode else payload.get("status", "ok"))
    raise SystemExit(rc)

def expand(path):
    return str(Path(str(path)).expanduser())

def same_path(a, b):
    if a is None or b is None:
        return False
    return os.path.abspath(expand(a)) == os.path.abspath(expand(b))

def read_text(path):
    return Path(path).expanduser().read_text(encoding="utf-8")

def table_bounds(lines, table):
    start = None
    heading = f"[{table}]"
    for i, line in enumerate(lines):
        stripped = line.strip()
        if stripped == heading:
            start = i
            break
    if start is None:
        return None, None
    end = len(lines)
    for i in range(start + 1, len(lines)):
        stripped = lines[i].strip()
        if stripped.startswith("[") and stripped.endswith("]"):
            end = i
            break
    return start, end

KEY_RE = re.compile(r'^\s*(?P<key>"[^"]+"|\'[^\']+\'|[A-Za-z0-9_.-]+)\s*=')
ENTRY_RE = re.compile(r'^(?P<prefix>\s*(?P<key>"[^"]+"|\'[^\']+\'|[A-Za-z0-9_.-]+)\s*=\s*)(?P<quote>["\'])(?P<value>.*?)(?P=quote)(?P<suffix>\s*(?:#.*)?)(?P<nl>\n?)$')

def unquote_key(raw):
    raw = raw.strip()
    if (raw.startswith('"') and raw.endswith('"')) or (raw.startswith("'") and raw.endswith("'")):
        return raw[1:-1]
    return raw

def toml_string(value):
    return '"' + str(value).replace("\\", "\\\\").replace('"', '\\"') + '"'

def parse_session_paths(text):
    lines = text.splitlines(keepends=True)
    start, end = table_bounds(lines, "session_paths")
    if start is None:
        return {}, []
    values, duplicates = {}, []
    for line in lines[start + 1:end]:
        m = ENTRY_RE.match(line)
        if not m:
            continue
        key = unquote_key(m.group("key"))
        if key in values:
            duplicates.append(key)
        values[key] = m.group("value")
    return values, duplicates

def render_session_paths(text, changes):
    lines = text.splitlines(keepends=True)
    start, end = table_bounds(lines, "session_paths")
    if start is None:
        if lines and not lines[-1].endswith("\n"):
            lines[-1] += "\n"
        lines.extend(["\n", "[session_paths]\n"])
        start, end = len(lines) - 1, len(lines)
    seen = set()
    for i in range(start + 1, end):
        m = ENTRY_RE.match(lines[i])
        if not m:
            continue
        key = unquote_key(m.group("key"))
        if key not in changes:
            continue
        nl = m.group("nl") or "\n"
        lines[i] = f'{m.group("prefix")}{toml_string(changes[key])}{m.group("suffix")}{nl}'
        seen.add(key)
    additions = [f'{toml_string(k)} = {toml_string(v)}\n' for k, v in changes.items() if k not in seen]
    if additions:
        insert_at = end
        while insert_at > start + 1 and lines[insert_at - 1].strip() == "":
            insert_at -= 1
        lines[insert_at:insert_at] = additions
    rendered = "".join(lines)
    parsed, duplicates = parse_session_paths(rendered)
    missing = [k for k, v in changes.items() if not same_path(parsed.get(k), v)]
    if duplicates or missing:
        raise ValueError(f"session_paths_roundtrip_failed duplicates={duplicates} missing={missing}")
    return rendered

def latest_topology(path):
    p = Path(path).expanduser()
    latest = {}
    if not p.exists():
        return latest
    for line in p.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except json.JSONDecodeError:
            continue
        if not isinstance(row, dict) or not row.get("session"):
            continue
        ts = row.get("effective_at") or row.get("ts") or ""
        prev = latest.get(row["session"])
        if prev is None or ts > (prev.get("effective_at") or prev.get("ts") or ""):
            latest[str(row["session"])] = row
    return latest

def run_ntm(ntm, args):
    proc = subprocess.run([ntm, *args], text=True, capture_output=True)
    return proc.returncode, proc.stdout, proc.stderr

def ntm_sessions(ntm):
    rc, out, _ = run_ntm(ntm, ["list", "--json"])
    if rc != 0:
        return []
    try:
        payload = json.loads(out or "{}")
    except json.JSONDecodeError:
        return []
    sessions = payload if isinstance(payload, list) else payload.get("sessions", [])
    return [str(s.get("name") or s.get("session")) for s in sessions if isinstance(s, dict) and (s.get("name") or s.get("session"))]

def build_report(args):
    config = Path(args.config).expanduser()
    text = read_text(config)
    current, duplicates = parse_session_paths(text)
    topo = latest_topology(args.topology)
    live = ntm_sessions(args.ntm_bin)
    targets = []
    desired_paths = canonical_paths()
    for session in TARGETS:
        desired = desired_paths[session]
        exists = Path(desired).expanduser().is_dir()
        evidence = ["target_allowlist", "canonical_map"]
        if session in topo:
            evidence.append("topology")
        if session in live:
            evidence.append("ntm_list")
        if current.get(session):
            evidence.append("config")
        confidence = "high" if exists else "low"
        status = "ready" if confidence == "high" else "blocked_missing_path"
        targets.append({
            "session": session,
            "current_path": current.get(session),
            "desired_path": desired,
            "confidence": confidence,
            "protected": False,
            "status": status,
            "evidence": evidence,
            "desired_path_exists": exists,
        })
    return {
        "schema_version": "flywheel-recovery-preinstall-report.v1",
        "generated_at": args.now or now_iso(),
        "source_plan_path": SOURCE_PLAN,
        "config_path": str(config),
        "topology_path": str(Path(args.topology).expanduser()),
        "live_sessions": live,
        "session_paths_duplicate_keys": duplicates,
        "normalization_candidates": [{
            "from_session": "alps-insurance",
            "to_session": "alpsinsurance",
            "current_path": current.get("alps-insurance"),
            "action": "leave_alias_unmodified",
        }] if current.get("alps-insurance") else [],
        "targets": targets,
    }

def load_or_build_report(args):
    report = Path(args.report).expanduser()
    if report.exists():
        return json.loads(report.read_text(encoding="utf-8"))
    data = build_report(args)
    report.parent.mkdir(parents=True, exist_ok=True)
    report.write_text(json.dumps(data, sort_keys=True, indent=2) + "\n", encoding="utf-8")
    return data

def repair_plan(config_text, report):
    current, duplicates = parse_session_paths(config_text)
    blockers, changes, failure_modes = [], {}, []
    for item in report.get("targets", []):
        session = item.get("session")
        if session not in TARGETS:
            continue
        desired = item.get("desired_path")
        old = current.get(session)
        if item.get("confidence") != "high" or not desired:
            blockers.append({"session": session, "reason": "low_confidence", "desired_path": desired})
            continue
        if item.get("protected") and not same_path(old, desired):
            blockers.append({"session": session, "reason": "protected_session", "desired_path": desired, "current_path": old})
            continue
        if not same_path(old, desired):
            changes[session] = desired
            if old and not Path(expand(old)).exists():
                failure_modes.append({"session": session, "mode": "stale_path", "current_path": old, "desired_path": desired})
            elif old:
                failure_modes.append({"session": session, "mode": "wrong_repo_path", "current_path": old, "desired_path": desired})
    for key in duplicates:
        blockers.append({"session": key, "reason": "duplicate_session_path_key"})
    return changes, blockers, failure_modes

def validate_config(args, config_path=None, report=None):
    config_path = str(Path(config_path or args.config).expanduser())
    text = read_text(config_path)
    paths, duplicates = parse_session_paths(text)
    missing = []
    if report:
        for item in report.get("targets", []):
            if item.get("confidence") == "high" and not same_path(paths.get(item.get("session")), item.get("desired_path")):
                missing.append(item.get("session"))
    rc, out, err = run_ntm(args.ntm_bin, ["--config", config_path, "config", "validate", "--json"])
    list_rc, list_out, list_err = run_ntm(args.ntm_bin, ["--config", config_path, "list", "--json"])
    validate_text = f"{out}\n{err}"
    known_schema_drift = rc != 0 and list_rc == 0 and "unknown field(s)" in validate_text
    ntm_ok = rc == 0 or known_schema_drift
    ok = not duplicates and not missing and ntm_ok
    return {
        "status": "pass" if ok else "fail",
        "config_path": config_path,
        "session_paths_duplicate_keys": duplicates,
        "unconverged_sessions": missing,
        "ntm_config_validate_rc": rc,
        "ntm_config_validate_status": "ok" if rc == 0 else "known_schema_drift_warn" if known_schema_drift else "fail",
        "ntm_config_validate_stdout": out.strip()[:1000],
        "ntm_config_validate_stderr": err.strip()[:1000],
        "ntm_list_rc": list_rc,
        "ntm_list_stdout": list_out.strip()[:1000],
        "ntm_list_stderr": list_err.strip()[:1000],
    }

def append_jsonl(path, row):
    target = Path(path).expanduser()
    target.parent.mkdir(parents=True, exist_ok=True)
    lock = target.with_suffix(target.suffix + ".lock")
    with lock.open("a+") as handle:
        fcntl.flock(handle.fileno(), fcntl.LOCK_EX)
        with target.open("a", encoding="utf-8") as out:
            out.write(json.dumps(row, sort_keys=True, separators=(",", ":")) + "\n")
            out.flush()
            os.fsync(out.fileno())

def common(args, status):
    return {
        "schema_version": "flywheel-recovery.result.v1",
        "status": status,
        "source_plan_path": SOURCE_PLAN,
        "mission_anchor": MISSION_ANCHOR,
        "l112_observed": L112,
        "config_path": str(Path(args.config).expanduser()),
        "report_path": str(Path(args.report).expanduser()),
        "audit_path": str(Path(args.audit).expanduser()),
    }

def cmd_status(args):
    report = build_report(args)
    if args.write_report:
        p = Path(args.report).expanduser()
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(json.dumps(report, sort_keys=True, indent=2) + "\n", encoding="utf-8")
    out = common(args, "ok")
    out.update(report)
    emit(out, args.json, 0)

def cmd_repair(args):
    if args.scope != "session-paths":
        emit({"status": "usage_error", "error": "only --scope session-paths is supported"}, args.json, 2)
    if args.apply == args.dry_run:
        emit({"status": "usage_error", "error": "choose exactly one of --dry-run or --apply"}, args.json, 2)
    report = load_or_build_report(args)
    config = Path(args.config).expanduser()
    before = read_text(config)
    old_sha = sha(config)
    changes, blockers, modes = repair_plan(before, report)
    base = common(args, "blocked" if blockers else "planned")
    idempotency_key = args.idempotency_key or hashlib.sha256(json.dumps({"old_sha": old_sha, "changes": changes}, sort_keys=True).encode()).hexdigest()
    base.update({
        "dry_run": args.dry_run,
        "apply": args.apply,
        "idempotency_key": idempotency_key,
        "planned_changes": [{"session": k, "new_path": v} for k, v in sorted(changes.items())],
        "blockers": blockers,
        "failure_modes_covered": modes,
    })
    if blockers:
        emit(base, args.json, 4)
    if args.dry_run:
        emit(base, args.json, 0)
    if not changes:
        base["status"] = "noop"
        base["post_repair_validation"] = validate_config(args, report=report)
        emit(base, args.json, 0 if base["post_repair_validation"]["status"] == "pass" else 1)
    rendered = render_session_paths(before, changes)
    stamp = (args.now or now_iso()).replace(":", "").replace("-", "")
    backup = config.with_name(config.name + f".bak.recovery-session-paths.{stamp}")
    shutil.copy2(config, backup)
    config.write_text(rendered, encoding="utf-8")
    new_sha = sha(config)
    validation = validate_config(args, report=report)
    if validation["status"] != "pass":
        shutil.copy2(backup, config)
        base.update({"status": "failed_validation_rolled_back", "backup_path": str(backup), "old_sha256": old_sha, "new_sha256": new_sha, "post_repair_validation": validation})
        emit(base, args.json, 1)
    audit = {
        "schema_version": "flywheel-recovery.session-path-repair.audit.v1",
        "ts": args.now or now_iso(),
        "status": "applied",
        "source_plan_path": SOURCE_PLAN,
        "mission_anchor": MISSION_ANCHOR,
        "l112_observed": L112,
        "idempotency_key": idempotency_key,
        "config_path": str(config),
        "old_sha256": old_sha,
        "new_sha256": new_sha,
        "backup_path": str(backup),
        "sessions_changed": sorted(changes),
        "failure_modes_covered": modes,
    }
    append_jsonl(args.audit, audit)
    base.update({"status": "applied", "backup_path": str(backup), "old_sha256": old_sha, "new_sha256": new_sha, "post_repair_validation": validation, "audit_row_written": True})
    emit(base, args.json, 0)

def cmd_validate(args):
    if args.thing != "config":
        emit({"status": "usage_error", "error": "only validate config is supported"}, args.json, 2)
    report = load_or_build_report(args)
    out = common(args, "pass")
    out.update(validate_config(args, report=report))
    emit(out, args.json, 0 if out["status"] == "pass" else 1)

def cmd_doctor(args):
    report = load_or_build_report(args)
    config_text = read_text(args.config)
    changes, blockers, _ = repair_plan(config_text, report)
    validation = validate_config(args, report=report)
    status = "ok" if validation["status"] == "pass" else "warn" if changes and not blockers else "fail"
    out = common(args, status)
    out.update({"planned_change_count": len(changes), "blockers": blockers, "validation": validation})
    emit(out, args.json, 0 if status in {"ok", "warn"} else 1)

def cmd_audit(args):
    p = Path(args.audit).expanduser()
    rows = []
    if p.exists():
        rows = [json.loads(line) for line in p.read_text(encoding="utf-8").splitlines() if line.strip()][-20:]
    out = common(args, "ok")
    out["rows"] = rows
    emit(out, args.json, 0)

def cmd_info(args):
    emit({"schema_version": "flywheel-recovery.info.v1", "name": "flywheel-recovery.sh", "commands": ["status", "health", "doctor", "repair", "validate", "audit", "why", "quickstart", "completion"], "source_plan_path": SOURCE_PLAN, "mission_anchor": MISSION_ANCHOR, "l112_observed": L112}, args.json, 0)

def cmd_text(args, name):
    payload = {"status": "ok", "topic": name, "examples": ["flywheel-recovery.sh status --json", "flywheel-recovery.sh repair --scope session-paths --dry-run --json", "flywheel-recovery.sh repair --scope session-paths --apply --json", "flywheel-recovery.sh validate config --json"], "source_plan_path": SOURCE_PLAN}
    emit(payload, args.json, 0)

def main():
    argv = []
    raw = sys.argv[1:]
    skip_next = False
    for i, arg in enumerate(raw):
        if skip_next:
            skip_next = False
            continue
        if arg in {"--json", "--no-color", "--no-emoji"}:
            continue
        if arg == "--width":
            skip_next = True
            continue
        argv.append(arg)
    p = argparse.ArgumentParser(description="Flywheel recovery status, repair, and validation helpers.")
    p.add_argument("--json", action="store_true", default=True)
    p.add_argument("--config", default=os.environ.get("FLYWHEEL_RECOVERY_NTM_CONFIG", "~/.config/ntm/config.toml"))
    p.add_argument("--topology", default=os.environ.get("FLYWHEEL_RECOVERY_TOPOLOGY", "~/.local/state/flywheel/session-topology.jsonl"))
    p.add_argument("--report", default=os.environ.get("FLYWHEEL_RECOVERY_PREINSTALL_REPORT", "/tmp/flywheel-recovery-preinstall-report.json"))
    p.add_argument("--audit", default=os.environ.get("FLYWHEEL_RECOVERY_AUDIT", "~/.local/state/flywheel-recovery/audit.jsonl"))
    p.add_argument("--ntm-bin", default=os.environ.get("NTM_BIN", "/Users/josh/.local/bin/ntm"))
    p.add_argument("--now", default="")
    p.add_argument("--info", action="store_true")
    p.add_argument("--examples", action="store_true")
    sub = p.add_subparsers(dest="cmd")
    status = sub.add_parser("status"); status.add_argument("--write-report", action="store_true", default=True); status.add_argument("--no-write-report", dest="write_report", action="store_false")
    for name in ["health", "doctor"]:
        sp = sub.add_parser(name); sp.add_argument("--scope", default="session-paths")
    rep = sub.add_parser("repair"); rep.add_argument("--scope", required=True); rep.add_argument("--dry-run", action="store_true"); rep.add_argument("--apply", action="store_true"); rep.add_argument("--idempotency-key", default="")
    val = sub.add_parser("validate"); val.add_argument("thing")
    sub.add_parser("audit"); why = sub.add_parser("why"); why.add_argument("id", nargs="?")
    sub.add_parser("quickstart"); help_p = sub.add_parser("help"); help_p.add_argument("topic", nargs="?")
    comp = sub.add_parser("completion"); comp.add_argument("shell", nargs="?")
    args = p.parse_args(argv)
    if args.info:
        cmd_info(args)
    if args.examples:
        cmd_text(args, "examples")
    if args.cmd == "status":
        cmd_status(args)
    if args.cmd in {"health", "doctor"}:
        cmd_doctor(args)
    if args.cmd == "repair":
        cmd_repair(args)
    if args.cmd == "validate":
        cmd_validate(args)
    if args.cmd == "audit":
        cmd_audit(args)
    if args.cmd in {"why", "quickstart", "help", "completion"}:
        cmd_text(args, args.cmd)
    p.print_help(sys.stderr)
    raise SystemExit(2)

if __name__ == "__main__":
    main()
PY
