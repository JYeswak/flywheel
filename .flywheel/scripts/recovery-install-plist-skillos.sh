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

LABEL = "com.zeststream.skillos.watcher"
SESSION = "skillos"
SOURCE_PLAN = ".flywheel/PLANS/recovery-system-2026-05-01/00-PLAN.md"
DEFAULT_PLIST = "~/Library/LaunchAgents/com.zeststream.skillos.watcher.plist"
DEFAULT_STATUS = "/tmp/recovery-install-skillos-status.json"
DEFAULT_AUDIT = "/tmp/preinstall-skillos.json"
DEFAULT_REPO = "/Users/josh/Developer/skillos"
DEFAULT_NTM = "/Users/josh/.local/bin/ntm"
DEFAULT_NTM_CONFIG = "/Users/josh/.config/ntm/config.toml"
DEFAULT_AUDIT_SCRIPT = ".flywheel/scripts/recovery-preinstall-audit.sh"
DEFAULT_JSM = "/Users/josh/.local/bin/jsm"
DEFAULT_LOG_DIR = "~/.local/state/flywheel/logs"
DEFAULT_SKILLS_FLYWHEEL = "~/.claude/skills/.flywheel"


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
        return {"ok": False, "count": 0, "rows": [], "result": result}
    rows = [line for line in result["stdout"].splitlines() if label in line]
    return {"ok": True, "count": len(rows), "rows": rows, "result": result}


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


def skill_authoring_health(args):
    skills = ep(args.skills_flywheel)
    repo = ep(args.repo)
    jsm = ep(args.jsm_bin)
    return {
        "ok": skills.is_dir() and os.access(skills, os.R_OK) and repo.is_dir() and os.access(repo, os.W_OK) and jsm.is_file() and os.access(jsm, os.X_OK),
        "flywheel_skills_path": str(skills),
        "flywheel_skills_readable": skills.is_dir() and os.access(skills, os.R_OK),
        "skillos_repo": str(repo),
        "skillos_repo_writable": repo.is_dir() and os.access(repo, os.W_OK),
        "jsm_cli_path": str(jsm),
        "jsm_cli_available": jsm.is_file() and os.access(jsm, os.X_OK),
    }


def build_plist(args):
    log_dir = ep(args.log_dir)
    log_dir.mkdir(parents=True, exist_ok=True)
    env_path = "/Users/josh/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
    return {
        "Label": LABEL,
        "ProgramArguments": [
            abs_path(args.ntm_bin),
            "--config",
            abs_path(args.ntm_config),
            "watch",
            args.session,
            "--no-color",
            "--interval",
            "5s",
        ],
        "WorkingDirectory": abs_path(args.repo),
        "StandardOutPath": str(log_dir / "skillos.watcher.out.log"),
        "StandardErrorPath": str(log_dir / "skillos.watcher.err.log"),
        "EnvironmentVariables": {
            "PATH": env_path,
            "HOME": str(Path.home()),
            "NTM_CONFIG": abs_path(args.ntm_config),
            "SKILLOS_REPO": abs_path(args.repo),
        },
        "KeepAlive": True,
        "RunAtLoad": True,
    }


def main(argv):
    parser = argparse.ArgumentParser(description="Install the skillos recovery watcher plist without activating it.")
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
    parser.add_argument("--jsm-bin", default=DEFAULT_JSM)
    parser.add_argument("--skills-flywheel", default=DEFAULT_SKILLS_FLYWHEEL)
    parser.add_argument("--log-dir", default=DEFAULT_LOG_DIR)
    parser.add_argument("--confidence-min", type=int, default=70)
    parser.add_argument("--json", action="store_true", help="Compatibility flag; output is always JSON.")
    args = parser.parse_args(argv)

    audit, audit_result = run_audit(args)
    confidence = None
    if isinstance(audit, dict):
        confidence = (audit.get("confidence_per_session") or {}).get(args.session)

    status = {
        "schema_version": "recovery.skillos_watcher_install.v1",
        "generated_at": now_iso(),
        "source_plan": SOURCE_PLAN,
        "label": LABEL,
        "session": args.session,
        "audit_receipt_path": str(ep(args.audit_receipt)),
        "audit_command": audit_result,
        "audit_confidence": confidence,
        "plist_path": str(ep(args.plist)),
        "dry_run_pass": False,
        "exactly_one_label": False,
        "reboot_recovery_claimed": False,
        "skill_authoring_health": skill_authoring_health(args),
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
    readiness = {
        "path": {"value": plist_payload["EnvironmentVariables"]["PATH"], "ready": True},
        "home": {"value": str(Path.home()), "ready": Path.home().is_dir()},
        "binary": {"value": plist_payload["ProgramArguments"][0], "ready": ep(plist_payload["ProgramArguments"][0]).is_file()},
        "config": {"value": abs_path(args.ntm_config), "ready": ep(args.ntm_config).is_file()},
        "repo": {"value": abs_path(args.repo), "ready": ep(args.repo).is_dir() and os.access(ep(args.repo), os.W_OK)},
        "plutil": lint,
    }
    status.update({
        "status": "installed_not_loaded",
        "dry_run_pass": bool(lint["ok"] and all(item["ready"] for key, item in readiness.items() if key != "plutil")),
        "launchd_readiness": readiness,
        "program_arguments": plist_payload["ProgramArguments"],
        "working_directory": plist_payload["WorkingDirectory"],
        "stdout_path": plist_payload["StandardOutPath"],
        "stderr_path": plist_payload["StandardErrorPath"],
    })
    write_json(args.status, status)
    print(json.dumps(status, sort_keys=True))
    return 0 if status["dry_run_pass"] else 6


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
PY
