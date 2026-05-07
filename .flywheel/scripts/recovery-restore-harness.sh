#!/usr/bin/env bash
set -euo pipefail

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
