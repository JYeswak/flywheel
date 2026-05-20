#!/usr/bin/env bash
set -euo pipefail

python3 - "$@" <<'PY'
import argparse
import json
import os
import plistlib
import subprocess
import sys
import tempfile
from datetime import datetime, timedelta, timezone
from pathlib import Path

DEFAULT_PATH = "/Users/josh/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
SCHEMA = "flywheel-cron/v1"


def now():
    return datetime.now(timezone.utc).replace(microsecond=0)


def iso(dt):
    return dt.isoformat().replace("+00:00", "Z")


def ep(path):
    return Path(path).expanduser()


def path_str(path):
    return str(ep(path).resolve(strict=False))


def state_root():
    return ep(os.environ.get("FLYWHEEL_CRON_STATE_DIR", "~/.local/state/flywheel"))


def launchagents_dir():
    return ep(os.environ.get("FLYWHEEL_CRON_LAUNCHAGENTS_DIR", "~/Library/LaunchAgents"))


def registry_path():
    return ep(os.environ.get("FLYWHEEL_CRON_REGISTRY_PATH", "~/.local/state/flywheel/substrate-registry.jsonl"))


def log_dir():
    return ep(os.environ.get("FLYWHEEL_CRON_LOG_DIR", "~/.local/state/flywheel/logs"))


def stop_dir():
    return ep(os.environ.get("FLYWHEEL_CRON_STOP_DIR", "~/.flywheel"))


def sanitize_label(label):
    return "".join(ch if ch.isalnum() or ch in "._-" else "-" for ch in label)


def plist_path(label):
    return launchagents_dir() / f"{label}.plist"


def stop_path(label):
    return stop_dir() / f"STOP-{sanitize_label(label)}"


def run(args):
    try:
        proc = subprocess.run(args, text=True, capture_output=True, timeout=10)
        return {"ok": proc.returncode == 0, "rc": proc.returncode, "stdout": proc.stdout.strip(), "stderr": proc.stderr.strip()}
    except FileNotFoundError:
        return {"ok": False, "rc": 127, "stdout": "", "stderr": "command_not_found"}
    except subprocess.TimeoutExpired:
        return {"ok": False, "rc": 124, "stdout": "", "stderr": "timeout"}


def lint_plist_bytes(data):
    with tempfile.NamedTemporaryFile(suffix=".plist", delete=False) as fh:
        fh.write(data)
        tmp = fh.name
    try:
        result = run(["/usr/bin/plutil", "-lint", tmp])
        result["path"] = tmp
        return result
    finally:
        try:
            os.unlink(tmp)
        except FileNotFoundError:
            pass


def plist_xml(payload):
    return plistlib.dumps(payload, sort_keys=False)


def validate_command(command):
    p = ep(command)
    if not p.exists():
        return "command_missing"
    if not p.is_file():
        return "command_not_file"
    if not os.access(p, os.X_OK):
        return "command_not_executable"
    try:
        first = p.read_text(encoding="utf-8", errors="ignore").splitlines()[0]
    except IndexError:
        return "command_missing_shebang"
    except OSError:
        return "command_unreadable"
    if not first.startswith("#!"):
        return "command_missing_shebang"
    return None


def build_plist(args):
    logs = log_dir()
    stdout = logs / f"{args.label}.stdout.log"
    stderr = logs / f"{args.label}.stderr.log"
    payload = {
        "Label": args.label,
        "ProgramArguments": [path_str(args.command)] + list(args.arg or []),
        "StandardOutPath": str(stdout),
        "StandardErrorPath": str(stderr),
        "EnvironmentVariables": {
            "PATH": args.path,
            "HOME": str(Path.home()),
            "FLYWHEEL_CRON_STOP": str(stop_path(args.label)),
            "FLYWHEEL_CRON_LABEL": args.label,
            "FLYWHEEL_CRON_OWNER": args.owner,
        },
        "RunAtLoad": bool(args.run_at_load),
        "TimeOut": int(args.max_runtime),
        "Disabled": not bool(args.enable),
    }
    if args.working_dir:
        payload["WorkingDirectory"] = path_str(args.working_dir)
    if args.interval:
        payload["StartInterval"] = int(args.interval)
    if args.hour is not None or args.minute is not None:
        payload["StartCalendarInterval"] = {
            "Hour": int(args.hour or 0),
            "Minute": int(args.minute or 0),
        }
    if args.keep_alive:
        payload["KeepAlive"] = {"SuccessfulExit": False}
    return payload


def registry_row(args, lifecycle_state, plist):
    return {
        "ts": iso(now()),
        "schema_version": "substrate-registry/launchd/v1",
        "label": args.label,
        "kind": "launchd",
        "plist_path": str(plist),
        "owner": args.owner,
        "purpose": args.purpose,
        "expected_dispatch_class": "deterministic_cron",
        "dispatch_transport": "launchd",
        "orchestrator_required": False,
        "lifecycle_state": lifecycle_state,
        "registered_by": "flywheel-cron",
        "review_due": iso(now() + timedelta(days=int(args.review_days))),
        "stop_sentinel_path": str(stop_path(args.label)),
        "stdout_path": str(log_dir() / f"{args.label}.stdout.log"),
        "stderr_path": str(log_dir() / f"{args.label}.stderr.log"),
        "max_runtime_seconds": int(args.max_runtime),
        "evidence": [str(plist), path_str(args.command)],
    }


def emit(payload, rc=0):
    print(json.dumps(payload, sort_keys=True))
    return rc


def append_registry(row):
    path = registry_path()
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as fh:
        fh.write(json.dumps(row, sort_keys=True) + "\n")


def register(args):
    reason = validate_command(args.command)
    if reason:
        return emit({
            "schema_version": SCHEMA,
            "command": "register",
            "status": "refused",
            "reason_code": reason,
            "command_path": args.command,
            "dry_run": args.dry_run,
        }, 4)

    plist = plist_path(args.label)
    payload = build_plist(args)
    xml = plist_xml(payload)
    lint = lint_plist_bytes(xml)
    row = registry_row(args, "planned" if args.dry_run else "applied_disabled", plist)
    out = {
        "schema_version": SCHEMA,
        "command": "register",
        "status": "dry_run" if args.dry_run else "applied",
        "dry_run": args.dry_run,
        "label": args.label,
        "plist_path": str(plist),
        "planned_plist": payload,
        "planned_plist_content": xml.decode("utf-8"),
        "plutil_validated": lint["ok"],
        "plutil": lint,
        "registry_row": row,
        "registry_path": str(registry_path()),
        "stop_sentinel_path": str(stop_path(args.label)),
        "stdout_path": row["stdout_path"],
        "stderr_path": row["stderr_path"],
        "EnvironmentVariables.PATH": payload["EnvironmentVariables"]["PATH"],
        "launchctl_load_attempted": False,
    }
    if args.dry_run:
        return emit(out, 0 if lint["ok"] else 5)

    launchagents_dir().mkdir(parents=True, exist_ok=True)
    log_dir().mkdir(parents=True, exist_ok=True)
    stop_dir().mkdir(parents=True, exist_ok=True)
    plist.write_bytes(xml)
    lint_written = run(["/usr/bin/plutil", "-lint", str(plist)])
    out["plutil_written"] = lint_written
    out["plutil_validated"] = bool(lint["ok"] and lint_written["ok"])
    if not lint_written["ok"]:
        out["status"] = "failed"
        out["reason_code"] = "plutil_lint_failed"
        return emit(out, 5)
    append_registry(row)
    out["registry_written"] = True
    return emit(out)


def latest_registry(label):
    path = registry_path()
    latest = None
    if not path.exists():
        return None
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except json.JSONDecodeError:
            continue
        if row.get("kind") == "launchd" and row.get("label") == label:
            latest = row
    return latest


def lifecycle(args, action):
    plist = plist_path(args.label)
    uid = os.getuid()
    mutations = {
        "remove": [{"action": "delete_plist", "path": str(plist)}],
        "pause": [{"action": "set_plist_disabled", "path": str(plist), "Disabled": True}],
        "resume": [{"action": "set_plist_disabled", "path": str(plist), "Disabled": False}],
    }[action]
    launchctl = {
        "remove": ["launchctl", "bootout", f"gui/{uid}/{args.label}"],
        "pause": ["launchctl", "bootout", f"gui/{uid}/{args.label}"],
        "resume": ["launchctl", "bootstrap", f"gui/{uid}", str(plist)],
    }[action]
    return emit({
        "schema_version": SCHEMA,
        "command": action,
        "status": "dry_run" if args.dry_run else "planned",
        "dry_run": args.dry_run,
        "label": args.label,
        "plist_path": str(plist),
        "launchctl_action": {"argv": launchctl},
        "plist_mutations": mutations,
        "mutation_applied": False,
    })


def list_jobs(args):
    path = registry_path()
    rows = []
    if path.exists():
        for line in path.read_text(encoding="utf-8").splitlines():
            if not line.strip():
                continue
            try:
                row = json.loads(line)
            except json.JSONDecodeError:
                continue
            if row.get("kind") == "launchd":
                rows.append(row)
    return emit({"schema_version": SCHEMA, "command": "list", "registry_path": str(path), "jobs": rows, "count": len(rows)})


def status(args):
    row = latest_registry(args.label)
    plist = Path(row["plist_path"]) if row and row.get("plist_path") else plist_path(args.label)
    loaded = False
    result = run(["launchctl", "list"])
    if result["ok"]:
        loaded = any(args.label in line for line in result["stdout"].splitlines())
    return emit({
        "schema_version": SCHEMA,
        "command": "status",
        "label": args.label,
        "registered": row is not None,
        "registry_row": row,
        "plist_path": str(plist),
        "plist_exists": plist.exists(),
        "launchctl_loaded": loaded,
        "launchctl_probe": {"ok": result["ok"], "rc": result["rc"]},
    })


def logs(args):
    row = latest_registry(args.label) or {}
    return emit({
        "schema_version": SCHEMA,
        "command": "logs",
        "label": args.label,
        "stdout_path": row.get("stdout_path", str(log_dir() / f"{args.label}.stdout.log")),
        "stderr_path": row.get("stderr_path", str(log_dir() / f"{args.label}.stderr.log")),
    })


def main(argv):
    parser = argparse.ArgumentParser(description="flywheel launchd cron lifecycle contract")
    sub = parser.add_subparsers(dest="cmd", required=True)

    reg = sub.add_parser("register")
    reg.add_argument("--label", required=True)
    reg.add_argument("--owner", required=True)
    reg.add_argument("--command", required=True)
    reg.add_argument("--arg", action="append")
    reg.add_argument("--working-dir")
    reg.add_argument("--interval", type=int)
    reg.add_argument("--hour", type=int)
    reg.add_argument("--minute", type=int)
    reg.add_argument("--purpose", default="flywheel-managed deterministic launchd job")
    reg.add_argument("--path", default=DEFAULT_PATH)
    reg.add_argument("--max-runtime", type=int, default=300)
    reg.add_argument("--review-days", type=int, default=180)
    reg.add_argument("--run-at-load", action="store_true", default=True)
    reg.add_argument("--no-run-at-load", dest="run_at_load", action="store_false")
    reg.add_argument("--keep-alive", action="store_true")
    reg.add_argument("--enable", action="store_true", help="Write plist enabled. Default is disabled for safe install.")
    reg.add_argument("--dry-run", action="store_true")
    reg.add_argument("--json", action="store_true")

    for name in ("remove", "pause", "resume", "status", "logs"):
        p = sub.add_parser(name)
        p.add_argument("--label", required=True)
        p.add_argument("--dry-run", action="store_true")
        p.add_argument("--json", action="store_true")
    lp = sub.add_parser("list")
    lp.add_argument("--json", action="store_true")

    args = parser.parse_args(argv)
    if args.cmd == "register":
        return register(args)
    if args.cmd in ("remove", "pause", "resume"):
        return lifecycle(args, args.cmd)
    if args.cmd == "list":
        return list_jobs(args)
    if args.cmd == "status":
        return status(args)
    if args.cmd == "logs":
        return logs(args)
    raise SystemExit(2)


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
PY

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
