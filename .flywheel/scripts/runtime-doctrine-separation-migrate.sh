#!/usr/bin/env bash
# Per-repo .flywheel runtime-vs-doctrine separation probe/migration.
set -euo pipefail

RUNTIME_DOCTRINE_SCRIPT_PATH="${BASH_SOURCE[0]}" python3 - "$@" <<'PY'
from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
import tarfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCHEMA_VERSION = "runtime_doctrine_separation_migrate.v1"
RUNTIME_CLASSES = ("runtime", "state", "evidence")
DOCTRINE_CLASSES = ("doctrine", "specs", "scripts", "dispatches", "handoffs")
MIXED_CLASSES = ("validation", "brand-candidates", "audits")
SECRETS_CLASS = "private"


def iso_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def run(cmd: list[str], cwd: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(cmd, cwd=str(cwd), text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)


def git(repo: Path, args: list[str]) -> str:
    proc = run(["git", *args], repo)
    if proc.returncode != 0:
        return ""
    return proc.stdout


def rel(class_name: str) -> str:
    return f".flywheel/{class_name}"


def state_root(repo: Path) -> Path:
    return Path.home() / ".local/state/flywheel" / repo.name


def tracked_files(repo: Path, pathspec: str = ".flywheel") -> list[str]:
    out = git(repo, ["ls-files", pathspec])
    return [line for line in out.splitlines() if line.strip()]


def file_size(repo: Path, relative: str) -> int:
    path = repo / relative
    if path.exists() and path.is_file():
        return path.stat().st_size
    return 0


def tracked_bytes(repo: Path, files: list[str]) -> int:
    return sum(file_size(repo, item) for item in files)


def path_status(repo: Path, class_name: str) -> dict[str, Any]:
    path = repo / rel(class_name)
    tracked = tracked_files(repo, rel(class_name))
    target = state_root(repo) / class_name
    return {
        "class": class_name,
        "path": rel(class_name),
        "exists": path.exists() or path.is_symlink(),
        "is_symlink": path.is_symlink(),
        "symlink_target": os.readlink(path) if path.is_symlink() else None,
        "target": str(target),
        "tracked_files": len(tracked),
        "tracked_bytes": tracked_bytes(repo, tracked),
    }


def mixed_report(repo: Path) -> list[dict[str, Any]]:
    pending = []
    for class_name in MIXED_CLASSES:
        tracked = tracked_files(repo, rel(class_name))
        if not tracked:
            continue
        pending.append(
            {
                "class": class_name,
                "path": rel(class_name),
                "tracked_files": len(tracked),
                "tracked_bytes": tracked_bytes(repo, tracked),
                "operator_action": "review class-specific retention before untracking or rotating",
                "files": [
                    {"path": item, "bytes": file_size(repo, item)}
                    for item in tracked[:100]
                ],
                "truncated": len(tracked) > 100,
            }
        )
    return pending


def secret_incidents(repo: Path) -> list[dict[str, Any]]:
    incidents = []
    for item in tracked_files(repo, rel(SECRETS_CLASS)):
        incidents.append(
            {
                "class": "tracked-secret-surface",
                "path": item,
                "severity": "incident",
                "action": "refuse migration; remove tracked secret material through the security incident path",
            }
        )
    return incidents


def is_migrated(repo: Path, class_name: str) -> bool:
    path = repo / rel(class_name)
    target = state_root(repo) / class_name
    return path.is_symlink() and Path(os.readlink(path)).expanduser() == target


def ensure_gitignore(repo: Path, class_name: str, apply: bool) -> dict[str, Any]:
    gitignore = repo / ".gitignore"
    pattern = f"/.flywheel/{class_name}"
    existing = gitignore.read_text(encoding="utf-8").splitlines() if gitignore.exists() else []
    present = pattern in existing
    if apply and not present:
        with gitignore.open("a", encoding="utf-8") as handle:
            if existing and existing[-1] != "":
                handle.write("\n")
            handle.write(f"{pattern}\n")
    return {"pattern": pattern, "already_present": present, "added": apply and not present}


def copy_contents(source: Path, target: Path) -> None:
    target.mkdir(parents=True, exist_ok=True)
    if not source.exists() or source.is_symlink():
        return
    shutil.copytree(source, target, dirs_exist_ok=True, symlinks=True, copy_function=shutil.copy2)


def create_backup(repo: Path, classes: list[str], ts_compact: str) -> Path:
    root = state_root(repo)
    root.mkdir(parents=True, exist_ok=True)
    backup = root / f"migration-backup-{ts_compact}.tar.gz"
    with tarfile.open(backup, "w:gz") as tar:
        for class_name in classes:
            path = repo / rel(class_name)
            if path.exists() and not path.is_symlink():
                tar.add(path, arcname=rel(class_name))
    return backup


def remove_in_repo_path(path: Path) -> None:
    if path.is_symlink() or path.is_file():
        path.unlink()
    elif path.is_dir():
        shutil.rmtree(path)


def migrate_runtime(repo: Path, class_name: str, apply: bool) -> dict[str, Any]:
    source = repo / rel(class_name)
    target = state_root(repo) / class_name
    tracked_before = tracked_files(repo, rel(class_name))
    migrated = is_migrated(repo, class_name)
    planned = (source.exists() or source.is_symlink() or bool(tracked_before)) and not migrated
    action: dict[str, Any] = {
        "class": class_name,
        "path": rel(class_name),
        "target": str(target),
        "tracked_files_before": len(tracked_before),
        "tracked_bytes_before": tracked_bytes(repo, tracked_before),
        "already_migrated": migrated,
        "planned": planned,
        "applied": False,
    }
    if not planned:
        action["gitignore"] = ensure_gitignore(repo, class_name, apply)
        action["tracked_files_after"] = len(tracked_files(repo, rel(class_name)))
        return action
    if not apply:
        action["gitignore"] = ensure_gitignore(repo, class_name, False)
        action["tracked_files_after"] = 0
        return action

    copy_contents(source, target)
    rm = run(["git", "rm", "--cached", "-r", "--ignore-unmatch", rel(class_name)], repo)
    action["git_rm_cached_rc"] = rm.returncode
    if rm.stderr.strip():
        action["git_rm_cached_stderr"] = rm.stderr.strip()
    if rm.returncode != 0:
        action["applied"] = False
        action["error"] = "git rm --cached failed"
        return action

    action["gitignore"] = ensure_gitignore(repo, class_name, True)
    if source.exists() or source.is_symlink():
        remove_in_repo_path(source)
    source.parent.mkdir(parents=True, exist_ok=True)
    os.symlink(target, source, target_is_directory=True)
    action["applied"] = True
    action["tracked_files_after"] = len(tracked_files(repo, rel(class_name)))
    action["symlink_target"] = os.readlink(source)
    return action


def build_envelope(repo: Path, mode: str) -> dict[str, Any]:
    tracked_before = tracked_files(repo, ".flywheel")
    runtime_before = {class_name: path_status(repo, class_name) for class_name in RUNTIME_CLASSES}
    mixed = mixed_report(repo)
    incidents = secret_incidents(repo)
    outcome = "incident" if incidents else ("mixed-needs-operator" if mixed else "ok")
    return {
        "schema_version": SCHEMA_VERSION,
        "ts": iso_now(),
        "repo": str(repo),
        "mode": mode,
        "outcome": outcome,
        "runtime_migrated": [],
        "tracked_files_before": len(tracked_before),
        "tracked_files_after": len(tracked_before),
        "bytes_recovered": 0,
        "secrets_incidents": incidents,
        "mixed_classes_pending_review": mixed,
        "runtime_classes": runtime_before,
        "doctrine_classes": [path_status(repo, class_name) for class_name in DOCTRINE_CLASSES],
    }


def migrate(repo: Path, mode: str) -> dict[str, Any]:
    repo = repo.expanduser().resolve()
    if run(["git", "rev-parse", "--is-inside-work-tree"], repo).returncode != 0:
        return {
            "schema_version": SCHEMA_VERSION,
            "ts": iso_now(),
            "repo": str(repo),
            "mode": mode,
            "outcome": "incident",
            "runtime_migrated": [],
            "tracked_files_before": 0,
            "tracked_files_after": 0,
            "bytes_recovered": 0,
            "secrets_incidents": [{"class": "not-git-repo", "path": str(repo)}],
            "mixed_classes_pending_review": [],
        }
    apply = mode == "apply"
    envelope = build_envelope(repo, mode)
    if envelope["secrets_incidents"]:
        return envelope

    planned_classes = [
        class_name
        for class_name in RUNTIME_CLASSES
        if (repo / rel(class_name)).exists() and not is_migrated(repo, class_name)
    ]
    if apply and planned_classes:
        compact = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
        envelope["backup_path"] = str(create_backup(repo, planned_classes, compact))

    actions = []
    for class_name in RUNTIME_CLASSES:
        action = migrate_runtime(repo, class_name, apply)
        actions.append(action)
        if action.get("planned") and (not apply or action.get("applied")):
            envelope["runtime_migrated"].append(rel(class_name))
            envelope["bytes_recovered"] += int(action.get("tracked_bytes_before", 0))

    envelope["runtime_actions"] = actions
    tracked_after = tracked_files(repo, ".flywheel")
    if apply:
        envelope["tracked_files_after"] = len(tracked_after)
    else:
        would_untrack = sum(int(action.get("tracked_files_before", 0)) for action in actions if action.get("planned"))
        envelope["tracked_files_after"] = max(0, envelope["tracked_files_before"] - would_untrack)
    return envelope


def main() -> int:
    parser = argparse.ArgumentParser(description="Separate .flywheel runtime state from tracked doctrine.")
    parser.add_argument("--repo", default=os.getcwd(), help="Repository path.")
    parser.add_argument("--dry-run", action="store_true", help="Probe and plan only.")
    parser.add_argument("--apply", action="store_true", help="Apply migration to the target repo.")
    parser.add_argument("--json", action="store_true", help="Emit JSON envelope.")
    args = parser.parse_args()

    if args.apply and args.dry_run:
        print("ERROR: choose exactly one of --dry-run or --apply", file=sys.stderr)
        return 2
    mode = "apply" if args.apply else "dry-run"
    envelope = migrate(Path(args.repo), mode)
    if args.json:
        print(json.dumps(envelope, sort_keys=True))
    else:
        print(f"{envelope['repo']}: {envelope['outcome']} mode={envelope['mode']} migrated={len(envelope['runtime_migrated'])}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
PY
