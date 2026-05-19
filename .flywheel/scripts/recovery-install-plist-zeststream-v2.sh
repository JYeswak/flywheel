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

SESSION = "zeststream-v2"
LABEL = "com.zeststream.zeststream-v2.watcher"
SOURCE_PLAN = ".flywheel/PLANS/recovery-system-2026-05-01/00-PLAN.md"
DEFAULT_REPO = "/Users/josh/Developer/zeststream-v2"
DEFAULT_PLIST = "~/Library/LaunchAgents/com.zeststream.zeststream-v2.watcher.plist"
DEFAULT_STATUS = ".flywheel/receipts/recovery-install-zeststream-v2-status.json"
DEFAULT_AUDIT = "/tmp/preinstall-zeststream-v2.json"
DEFAULT_AUDIT_SCRIPT = ".flywheel/scripts/recovery-preinstall-audit.sh"
DEFAULT_NTM = "/Users/josh/.local/bin/ntm"
DEFAULT_NTM_CONFIG = "/Users/josh/.config/ntm/config.toml"
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
    if not audit_path.exists() and result.get("stdout"):
        try:
            write_json(audit_path, json.loads(result["stdout"]))
        except json.JSONDecodeError:
            pass
    if not audit_path.exists():
        return None, result
    try:
        return json.loads(audit_path.read_text(encoding="utf-8")), result
    except json.JSONDecodeError as exc:
        return {"parse_error": str(exc)}, result


def compact_command_result(result):
    compact = dict(result)
    stdout = compact.get("stdout") or ""
    compact["stdout_bytes"] = len(stdout.encode("utf-8"))
    compact["stdout"] = "[see audit_receipt_path]" if stdout else ""
    return compact


def launchctl_probe(args):
    result = run_cmd([args.launchctl_bin, "list"], timeout=8)
    rows = []
    if result["ok"]:
        rows = [line for line in result["stdout"].splitlines() if LABEL in line]
    probe_path = ep(args.launchctl_probe_path)
    probe_path.parent.mkdir(parents=True, exist_ok=True)
    probe_path.write_text("\n".join(rows) + ("\n" if rows else ""), encoding="utf-8")
    return {"ok": result["ok"], "count": len(rows), "rows": rows, "result": result, "path": str(probe_path)}


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
        "StandardOutPath": str(log_dir / "zeststream-v2-watcher.stdout.log"),
        "StandardErrorPath": str(log_dir / "zeststream-v2-watcher.stderr.log"),
        "EnvironmentVariables": {
            "PATH": env_path,
            "HOME": str(Path.home()),
            "NTM_CONFIG": abs_path(args.ntm_config),
            "ZESTSTREAM_V2_REPO": abs_path(args.repo),
        },
        "KeepAlive": {"SuccessfulExit": False},
        "RunAtLoad": True,
        "ThrottleInterval": 10,
    }


def dashed_name_valid(plist_payload, lint_ok):
    return bool(
        lint_ok
        and plist_payload["Label"] == LABEL
        and plist_payload["ProgramArguments"][2] == SESSION
        and plist_payload["WorkingDirectory"].endswith("/zeststream-v2")
        and "zeststream-v2-watcher.stdout.log" in plist_payload["StandardOutPath"]
        and "zeststream-v2-watcher.stderr.log" in plist_payload["StandardErrorPath"]
    )


def main(argv):
    parser = argparse.ArgumentParser(description="Install the zeststream-v2 recovery watcher plist without activating it.")
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
    parser.add_argument("--launchctl-probe-path", default="/tmp/zeststream-v2-watcher-launchctl-labels.txt")
    parser.add_argument("--confidence-min", type=int, default=20)
    parser.add_argument("--json", action="store_true", help="Compatibility flag; output is always JSON.")
    args = parser.parse_args(argv)

    audit, audit_result = run_audit(args)
    confidence = None
    default_threshold_confidence = None
    if isinstance(audit, dict):
        confidence = (audit.get("confidence_per_session") or {}).get(args.session)
        for row in audit.get("sessions", []):
            if row.get("session") == args.session:
                default_threshold_confidence = row.get("confidence_min")
    low_confidence = confidence is None or confidence < args.confidence_min

    status = {
        "schema_version": "recovery-session-watcher-install/v1",
        "source_plan": SOURCE_PLAN,
        "generated_at": now_iso(),
        "session": args.session,
        "label": LABEL,
        "plist_path": str(ep(args.plist)),
        "audit_receipt_path": str(ep(args.audit_receipt)),
        "audit_command": compact_command_result(audit_result),
        "audit_confidence": confidence,
        "audit_confidence_min_used": args.confidence_min,
        "audit_default_confidence_min_observed": default_threshold_confidence,
        "audit_low_confidence": low_confidence,
        "dry_run_pass": False,
        "exactly_one_label": False,
        "launchctl_load_attempted": False,
        "reboot_recovery_claimed": False,
        "zeststream_v2_repo_path_validated": False,
        "dashed_name_quoting_validated": False,
    }
    if low_confidence:
        status["status"] = "blocked"
        status["block_reason"] = "low_preinstall_confidence"
        write_json(args.status, status)
        print(json.dumps(status, sort_keys=True))
        return 4

    label_probe = launchctl_probe(args)
    status["loaded_label_count"] = label_probe["count"]
    status["launchctl_list_probe_path"] = label_probe["path"]
    status["exactly_one_label"] = bool(label_probe["ok"] and label_probe["count"] <= 1)
    if not status["exactly_one_label"]:
        status["status"] = "blocked"
        status["block_reason"] = "duplicate_launchd_label"
        status["launchctl_label_rows"] = label_probe["rows"]
        write_json(args.status, status)
        print(json.dumps(status, sort_keys=True))
        return 5

    plist_path = ep(args.plist)
    plist_path.parent.mkdir(parents=True, exist_ok=True)
    plist_payload = build_plist(args)
    with plist_path.open("wb") as fh:
        plistlib.dump(plist_payload, fh, sort_keys=False)

    lint = run_cmd([args.plutil_bin, "-lint", str(plist_path)], timeout=8)
    repo_path = ep(args.repo)
    logs_dir = ep(args.log_dir)
    readiness = {
        "path": plist_payload["EnvironmentVariables"]["PATH"],
        "home": {"path": str(Path.home()), "exists": Path.home().is_dir()},
        "ntm_binary": {"path": plist_payload["ProgramArguments"][0], "executable": os.access(plist_payload["ProgramArguments"][0], os.X_OK)},
        "ntm_config": {"path": abs_path(args.ntm_config), "exists": ep(args.ntm_config).is_file()},
        "repo": {"path": abs_path(args.repo), "exists": repo_path.is_dir(), "writable": os.access(repo_path, os.W_OK)},
        "logs_dir": {"path": str(logs_dir), "exists": logs_dir.is_dir()},
        "stdout_path": plist_payload["StandardOutPath"],
        "stderr_path": plist_payload["StandardErrorPath"],
    }
    dashed_ok = dashed_name_valid(plist_payload, lint["ok"])
    status.update({
        "status": "installed_not_loaded",
        "plutil_lint": "OK" if lint["ok"] else "FAIL",
        "plutil_result": lint,
        "program_arguments": plist_payload["ProgramArguments"],
        "working_directory": plist_payload["WorkingDirectory"],
        "readiness": readiness,
        "zeststream_v2_repo_path_validated": bool(readiness["repo"]["exists"] and readiness["repo"]["writable"]),
        "dashed_name_quoting_validated": dashed_ok,
        "dry_run_pass": bool(
            lint["ok"]
            and dashed_ok
            and readiness["home"]["exists"]
            and readiness["ntm_binary"]["executable"]
            and readiness["ntm_config"]["exists"]
            and readiness["repo"]["exists"]
            and readiness["logs_dir"]["exists"]
        ),
    })
    write_json(args.status, status)
    print(json.dumps(status, sort_keys=True))
    return 0 if status["dry_run_pass"] else 6


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
PY

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-92-reversible-recovery-ladder.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-45-reversible-cleanup-bundle.md`
