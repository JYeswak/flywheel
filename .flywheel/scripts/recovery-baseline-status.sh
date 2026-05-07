#!/usr/bin/env bash
set -euo pipefail

python3 - "$@" <<'PY'
import argparse
import json
import os
import subprocess
from pathlib import Path

LABEL = "com.zeststream.recovery.nightly-snapshot"
PROTECTED = ["alpsinsurance", "picoz"]


def ep(path):
    return Path(path).expanduser()


def latest_manifest(snapshot_dir):
    manifests = sorted(ep(snapshot_dir).glob("baseline-*.manifest.json"), key=lambda p: p.stat().st_mtime, reverse=True)
    if not manifests:
        return None, None
    try:
        payload = json.loads(manifests[0].read_text(encoding="utf-8"))
    except Exception:
        payload = {}
    return manifests[0], payload


def label_active(launchctl_bin, label):
    try:
        proc = subprocess.run([launchctl_bin, "list"], text=True, capture_output=True, timeout=5)
    except Exception:
        return False
    if proc.returncode != 0:
        return False
    return any(line.strip().endswith(label) or label in line.split() for line in proc.stdout.splitlines())


def latest_drill(drill_dir):
    drills = sorted(ep(drill_dir).glob("drill-*.json"), key=lambda p: p.stat().st_mtime, reverse=True)
    for path in drills:
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
        except Exception:
            continue
        if payload.get("status") == "pass":
            return payload.get("created_at") or payload.get("ts")
    return None


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--snapshot-dir", default=os.environ.get("FLYWHEEL_RECOVERY_SNAPSHOT_DIR", "~/.flywheel/recovery/snapshots"))
    parser.add_argument("--drill-dir", default=os.environ.get("FLYWHEEL_RECOVERY_DRILL_DIR", "~/.flywheel/recovery/drills"))
    parser.add_argument("--launchctl-bin", default=os.environ.get("FLYWHEEL_RECOVERY_LAUNCHCTL_BIN", "/bin/launchctl"))
    parser.add_argument("--plist", default=os.environ.get("FLYWHEEL_RECOVERY_NIGHTLY_PLIST", "~/Library/LaunchAgents/com.zeststream.recovery.nightly-snapshot.plist"))
    args = parser.parse_args()
    manifest_path, manifest = latest_manifest(args.snapshot_dir)
    payload = {
        "schema_version": "flywheel-recovery-baseline-status/v1",
        "status": "pass",
        "last_baseline_snapshot_ts": manifest.get("created_at") if manifest else None,
        "last_baseline_snapshot_manifest_path": str(manifest_path) if manifest_path else None,
        "nightly_snapshot_label": LABEL,
        "nightly_snapshot_label_active": label_active(args.launchctl_bin, LABEL),
        "nightly_snapshot_plist_path": str(ep(args.plist)),
        "nightly_snapshot_plist_exists": ep(args.plist).is_file(),
        "last_drill_pass_ts": latest_drill(args.drill_dir),
        "protected_sessions_restore_blocked": PROTECTED,
    }
    if args.json:
        print(json.dumps(payload, sort_keys=True, separators=(",", ":")))
    else:
        print(
            "Recovery baseline: last_snapshot={last_baseline_snapshot_ts} nightly_active={nightly_snapshot_label_active} "
            "last_drill={last_drill_pass_ts} protected_blocked={protected_sessions_restore_blocked}".format(**payload)
        )


if __name__ == "__main__":
    main()
PY
