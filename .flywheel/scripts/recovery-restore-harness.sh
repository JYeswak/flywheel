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

SCAFFOLD_SCHEMA_VERSION="recovery-restore-harness/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/recovery-restore-harness-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: recovery-restore-harness.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "recovery-restore-harness.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "recovery-restore-harness.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"recovery-restore-harness.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"recovery-restore-harness.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"recovery-restore-harness.sh doctor --json"}'
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
            && cli_emit_completion_bash "recovery-restore-harness" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "recovery-restore-harness" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
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
import argparse
import json
import os
import shutil
import tarfile
import tempfile
from pathlib import Path
from datetime import datetime, timezone

SCHEMA = "flywheel-recovery-restore/v1"
PROTECTED = ["alpsinsurance", "picoz"]
SOURCE_PLAN = ".flywheel/PLANS/recovery-system-2026-05-01/00-PLAN.md"


def utc_now():
    override = os.environ.get("FLYWHEEL_RECOVERY_NOW", "")
    if override:
        return override
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def slug_ts(ts):
    return ts.replace("-", "").replace(":", "").replace("+", "").replace("Z", "Z")


def ep(path):
    return Path(path).expanduser()


def latest_manifest(snapshot_dir):
    manifests = sorted(ep(snapshot_dir).glob("baseline-*.manifest.json"), key=lambda p: p.stat().st_mtime, reverse=True)
    if not manifests:
        raise SystemExit("no baseline manifest found")
    return manifests[0]


def load_manifest(path):
    p = ep(path)
    data = json.loads(p.read_text(encoding="utf-8"))
    data["_manifest_path"] = str(p)
    return data


def approval_present(args):
    if os.environ.get("FLYWHEEL_RECOVERY_RESTORE_APPROVAL") == "JOSHUA_APPROVED":
        return True
    sentinel = ep(args.approval_file)
    return sentinel.is_file() and sentinel.read_text(encoding="utf-8", errors="replace").strip() == "JOSHUA_APPROVED"


def build_plan(manifest, args):
    actions = []
    conflicts = []
    skipped = []
    for session in manifest.get("sessions", []):
        name = session.get("session")
        protected = bool(session.get("protected")) or name in PROTECTED
        target = ep(args.restore_root) / str(name)
        source = session.get("archive_root")
        if protected and not args.restore_protected:
            skipped.append({"session": name, "reason": "protected_session_restore_blocked"})
            action = "audit_only"
        else:
            action = "restore_session_state"
        if target.exists() and any(target.iterdir()):
            conflicts.append({"session": name, "path": str(target), "reason": "target_not_empty"})
        actions.append({
            "session": name,
            "protected": protected,
            "checkpoint_ready": bool(session.get("checkpoint_ready")),
            "action": action,
            "source_archive_root": source,
            "target_path": str(target),
        })
    return {
        "schema_version": SCHEMA,
        "created_at": utc_now(),
        "mode": "apply" if args.apply else "dry-run",
        "source_plan": SOURCE_PLAN,
        "manifest_path": manifest.get("_manifest_path"),
        "tarball_path": manifest.get("paths", {}).get("tarball"),
        "idempotency_key": args.idempotency_key,
        "restore_root": str(ep(args.restore_root)),
        "protected_sessions_restore_blocked": skipped,
        "conflicts": conflicts,
        "actions": actions,
    }


def copytree_contents(src, dst):
    dst.mkdir(parents=True, exist_ok=True)
    for item in src.iterdir():
        target = dst / item.name
        if item.is_dir():
            if target.exists():
                shutil.rmtree(target)
            shutil.copytree(item, target)
        else:
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(item, target)


def apply_restore(plan, args):
    tarball = ep(plan["tarball_path"])
    if not tarball.is_file():
        plan["status"] = "fail"
        plan["error"] = "tarball_missing"
        return plan, 1
    with tempfile.TemporaryDirectory(prefix="recovery-restore.") as tmp:
        root = Path(tmp)
        with tarfile.open(tarball, "r:gz") as tf:
            tf.extractall(root)
        for action in plan["actions"]:
            if action["action"] != "restore_session_state":
                continue
            source = root / action["source_archive_root"]
            target = ep(action["target_path"])
            if not source.exists():
                action["applied"] = False
                action["apply_error"] = "source_missing"
                continue
            copytree_contents(source, target)
            action["applied"] = True
    plan["status"] = "applied"
    return plan, 0


def write_receipt(plan, args):
    receipt_dir = ep(args.receipt_dir)
    receipt_dir.mkdir(parents=True, exist_ok=True)
    safe_key = "".join(ch if ch.isalnum() or ch in "._-" else "_" for ch in args.idempotency_key)
    path = receipt_dir / f"{slug_ts(plan['created_at'])}-{safe_key}.json"
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(json.dumps(plan, sort_keys=True, indent=2) + "\n", encoding="utf-8")
    os.replace(tmp, path)
    plan["receipt_path"] = str(path)
    return path


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true", default=True)
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--restore-protected", action="store_true")
    parser.add_argument("--idempotency-key")
    parser.add_argument("--manifest")
    parser.add_argument("--snapshot-dir", default=os.environ.get("FLYWHEEL_RECOVERY_SNAPSHOT_DIR", "~/.flywheel/recovery/snapshots"))
    parser.add_argument("--restore-root", default=os.environ.get("FLYWHEEL_RECOVERY_RESTORE_ROOT", "~/.flywheel/recovery/restored-state"))
    parser.add_argument("--receipt-dir", default=os.environ.get("FLYWHEEL_RECOVERY_RESTORE_RECEIPT_DIR", "~/.flywheel/recovery/restore-receipts"))
    parser.add_argument("--approval-file", default=os.environ.get("FLYWHEEL_RECOVERY_APPROVAL_FILE", "~/.flywheel/recovery/JOSHUA_APPROVED_RESTORE"))
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    if args.apply:
        args.dry_run = False
    manifest_path = args.manifest or latest_manifest(args.snapshot_dir)
    manifest = load_manifest(manifest_path)
    plan = build_plan(manifest, args)
    if args.apply and not args.idempotency_key:
        plan.update({"status": "rejected", "error": "--apply requires --idempotency-key"})
        print(json.dumps(plan, sort_keys=True, separators=(",", ":")))
        raise SystemExit(2)
    if args.apply and not approval_present(args):
        plan.update({"status": "rejected", "error": "--apply requires Joshua approval token"})
        print(json.dumps(plan, sort_keys=True, separators=(",", ":")))
        raise SystemExit(3)
    rc = 0
    if args.apply:
        plan, rc = apply_restore(plan, args)
        receipt = write_receipt(plan, args)
        plan["receipt_path"] = str(receipt)
    else:
        plan["status"] = "planned"
    print(json.dumps(plan, sort_keys=True, separators=(",", ":")) if args.json or True else plan["status"])
    raise SystemExit(rc)


if __name__ == "__main__":
    main()
PY

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-92-reversible-recovery-ladder.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-45-reversible-cleanup-bundle.md`
