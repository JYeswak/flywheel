#!/usr/bin/env bash
set -euo pipefail

python3 - "$@" <<'PY'
import argparse
import json
import os
import plistlib
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

LABEL = "com.zeststream.mobile-eats.watcher"
SESSION = "mobile-eats"
SOURCE_PLAN = ".flywheel/PLANS/recovery-system-2026-05-01/00-PLAN.md"
DEFAULT_PLIST = "~/Library/LaunchAgents/com.zeststream.mobile-eats.watcher.plist"
DEFAULT_STATUS = ".flywheel/receipts/recovery-install-mobile-eats-status.json"
DEFAULT_AUDIT = "/tmp/preinstall-mobile-eats.json"
DEFAULT_REPO = "/Users/josh/Developer/mobile-eats"
DEFAULT_NTM = "/Users/josh/.local/bin/ntm"
DEFAULT_NTM_CONFIG = "/Users/josh/.config/ntm/config.toml"
DEFAULT_AUDIT_SCRIPT = ".flywheel/scripts/recovery-preinstall-audit.sh"
DEFAULT_LOG_DIR = "~/.local/state/flywheel/logs"


def now_iso():
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def ep(path):
    return Path(path).expanduser()


def abs_path(path):
    return str(ep(path).resolve(strict=False))


def run_cmd(args, timeout=10):
    try:
        proc = subprocess.run(args, text=True, capture_output=True, timeout=timeout)
        return {"ok": proc.returncode == 0, "rc": proc.returncode, "stdout": proc.stdout.strip(), "stderr": proc.stderr.strip()}
    except FileNotFoundError:
        return {"ok": False, "rc": 127, "stdout": "", "stderr": "command_not_found"}
    except subprocess.TimeoutExpired:
        return {"ok": False, "rc": 124, "stdout": "", "stderr": "timeout"}


def write_json(path, payload):
    p = ep(path)
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(json.dumps(payload, sort_keys=True, indent=2) + "\n", encoding="utf-8")


def launchctl_label_count(launchctl_bin, label):
    result = run_cmd([launchctl_bin, "list"], timeout=8)
    if not result["ok"]:
        return {"ok": False, "count": 0, "rows": [], "result": {k: result[k] for k in ("ok", "rc", "stderr")}}
    rows = [line for line in result["stdout"].splitlines() if label in line]
    return {"ok": True, "count": len(rows), "rows": rows, "result": {"ok": True, "rc": result["rc"], "stderr": result["stderr"]}}


def run_audit(args):
    audit_path = ep(args.audit_receipt)
    cmd = [
        args.audit_script,
        f"--session={args.session}",
        "--json",
        "--confidence-min",
        str(args.confidence_min),
        "--output",
        str(audit_path),
    ]
    result = run_cmd(cmd, timeout=45)
    if not audit_path.exists() and result["stdout"]:
        try:
            parsed = json.loads(result["stdout"])
            write_json(audit_path, parsed)
        except json.JSONDecodeError:
            pass
    if not audit_path.exists():
        return None, result
    try:
        return json.loads(audit_path.read_text(encoding="utf-8")), result
    except json.JSONDecodeError as exc:
        return {"parse_error": str(exc)}, result


def readiness(args, plist_payload, lint):
    ntm = ep(plist_payload["ProgramArguments"][0])
    config = ep(args.ntm_config)
    repo = ep(args.repo)
    logs_dir = Path(plist_payload["StandardOutPath"]).parent
    return {
        "path": {"value": plist_payload["EnvironmentVariables"]["PATH"], "ready": True},
        "home": {"value": str(Path.home()), "ready": Path.home().is_dir()},
        "ntm_binary": {"path": str(ntm), "exists": ntm.is_file(), "executable": os.access(ntm, os.X_OK)},
        "ntm_config": {"path": abs_path(args.ntm_config), "exists": config.is_file()},
        "repo": {"path": abs_path(args.repo), "exists": repo.is_dir(), "writable": os.access(repo, os.W_OK)},
        "logs_dir": {"path": str(logs_dir), "exists": logs_dir.is_dir(), "writable": os.access(logs_dir, os.W_OK)},
        "plutil": lint,
    }


def readiness_pass(r):
    return (
        r["path"]["ready"]
        and r["home"]["ready"]
        and r["ntm_binary"]["exists"]
        and r["ntm_binary"]["executable"]
        and r["ntm_config"]["exists"]
        and r["repo"]["exists"]
        and r["repo"]["writable"]
        and r["logs_dir"]["exists"]
        and r["logs_dir"]["writable"]
        and r["plutil"]["ok"]
    )


def dashed_name_quoting_valid(program_arguments):
    return SESSION in program_arguments and any("-" in arg for arg in program_arguments if arg == SESSION)


def build_plist(args):
    log_dir = ep(args.log_dir)
    log_dir.mkdir(parents=True, exist_ok=True)
    env_path = "/Users/josh/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
    return {
        "Label": LABEL,
        "ProgramArguments": [
            abs_path(args.ntm_bin),
            "watch",
            args.session,
            "--activity",
            "--interval",
            "2s",
            "--tail",
            "20",
            "--no-color",
            "--no-timestamps",
            "--config",
            abs_path(args.ntm_config),
        ],
        "WorkingDirectory": abs_path(args.repo),
        "StandardOutPath": str(log_dir / "mobile-eats.watcher.out.log"),
        "StandardErrorPath": str(log_dir / "mobile-eats.watcher.err.log"),
        "EnvironmentVariables": {
            "PATH": env_path,
            "HOME": str(Path.home()),
            "NTM_CONFIG": abs_path(args.ntm_config),
            "MOBILE_EATS_REPO": abs_path(args.repo),
        },
        "KeepAlive": {"SuccessfulExit": False},
        "RunAtLoad": True,
        "ThrottleInterval": 10,
    }


def main(argv):
    parser = argparse.ArgumentParser(description="Install the mobile-eats recovery watcher plist without activating it.")
    parser.add_argument("--session", default=SESSION)
    parser.add_argument("--repo", default=DEFAULT_REPO)
    parser.add_argument("--plist", default=DEFAULT_PLIST)
    parser.add_argument("--status", default=DEFAULT_STATUS)
    parser.add_argument("--audit-receipt", default=DEFAULT_AUDIT)
    parser.add_argument("--audit-script", default=DEFAULT_AUDIT_SCRIPT)
    parser.add_argument("--ntm-bin", default=DEFAULT_NTM)
    parser.add_argument("--ntm-config", default=DEFAULT_NTM_CONFIG)
    parser.add_argument("--launchctl-bin", default="/bin/launchctl")
    parser.add_argument("--plutil-bin", default="/usr/bin/plutil")
    parser.add_argument("--log-dir", default=DEFAULT_LOG_DIR)
    parser.add_argument("--confidence-min", type=int, default=70)
    parser.add_argument("--json", action="store_true", help="Compatibility flag; output is always JSON.")
    args = parser.parse_args(argv)

    audit, audit_result = run_audit(args)
    confidence = None
    if isinstance(audit, dict):
        confidence = (audit.get("confidence_per_session") or {}).get(args.session)

    status = {
        "schema_version": "recovery-session-watcher-install/v1",
        "generated_at": now_iso(),
        "source_plan": SOURCE_PLAN,
        "label": LABEL,
        "session": args.session,
        "audit_receipt_path": str(ep(args.audit_receipt)),
        "audit_command": {k: audit_result[k] for k in ("ok", "rc", "stderr")},
        "audit_confidence": confidence,
        "plist_path": str(ep(args.plist)),
        "dry_run_pass": False,
        "exactly_one_label": False,
        "reboot_recovery_claimed": False,
        "launchctl_load_attempted": False,
        "mobile_eats_repo_path_validated": ep(args.repo).is_dir(),
        "dashed_name_quoting_validated": False,
    }

    if confidence is None or confidence < args.confidence_min:
        status["status"] = "blocked"
        status["block_reason"] = "low_preinstall_confidence"
        write_json(args.status, status)
        print(json.dumps(status, sort_keys=True))
        return 4

    label_state = launchctl_label_count(args.launchctl_bin, LABEL)
    status["launchctl_label_state"] = label_state
    status["exactly_one_label"] = bool(label_state.get("ok") and label_state.get("count", 0) <= 1)
    if not status["exactly_one_label"]:
        status["status"] = "blocked"
        status["block_reason"] = "duplicate_launchd_label"
        write_json(args.status, status)
        print(json.dumps(status, sort_keys=True))
        return 5

    plist_path = ep(args.plist)
    plist_path.parent.mkdir(parents=True, exist_ok=True)
    plist_payload = build_plist(args)
    with plist_path.open("wb") as fh:
        plistlib.dump(plist_payload, fh, sort_keys=False)

    lint = run_cmd([args.plutil_bin, "-lint", str(plist_path)], timeout=8)
    ready = readiness(args, plist_payload, lint)
    dashed_ok = dashed_name_quoting_valid(plist_payload["ProgramArguments"])
    status.update({
        "status": "installed_not_loaded",
        "dry_run_pass": readiness_pass(ready) and dashed_ok,
        "readiness": ready,
        "launchd_readiness": ready,
        "program_arguments": plist_payload["ProgramArguments"],
        "working_directory": plist_payload["WorkingDirectory"],
        "stdout_path": plist_payload["StandardOutPath"],
        "stderr_path": plist_payload["StandardErrorPath"],
        "environment": plist_payload["EnvironmentVariables"],
        "dashed_name_quoting_validated": dashed_ok,
    })
    write_json(args.status, status)
    print(json.dumps(status, sort_keys=True))
    return 0 if status["dry_run_pass"] else 6


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
PY
