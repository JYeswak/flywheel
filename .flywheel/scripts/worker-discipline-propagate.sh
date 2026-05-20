#!/usr/bin/env bash
set -euo pipefail

WORKER_DISCIPLINE_PROPAGATE_SCRIPT_PATH="${BASH_SOURCE[0]}" python3 - "$@" <<'PY'
from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCHEMA_VERSION = "worker-discipline-propagate/v1"
AUTH_TOKEN = "JOSHUA_SKILLOS_CANONICALIZED"


def iso_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def script_root() -> Path:
    script = Path(os.environ.get("WORKER_DISCIPLINE_PROPAGATE_SCRIPT_PATH", "")).resolve()
    if script.name:
        return script.parents[2]
    return Path.cwd().resolve()


ROOT = script_root()
SKILLOS_ROOT = Path("/Users/josh/Developer/skillos")

DOCTRINES = [
    {
        "id": "auto-push-blocked-worker-discipline",
        "target": ".flywheel/doctrine/auto-push-blocked-worker-discipline.md",
        "sources": [ROOT / ".flywheel/doctrine/auto-push-blocked-worker-discipline.md"],
    },
    {
        "id": "codex-goal-mode-discipline",
        "target": ".flywheel/doctrine/codex-goal-mode-discipline.md",
        "sources": [
            ROOT / ".flywheel/doctrine/codex-goal-mode-discipline.md",
            SKILLOS_ROOT / ".flywheel/doctrine/meta-learnings/codex-goal-mode-discipline.md",
        ],
        "alternate_targets": [
            ".flywheel/doctrine/meta-learnings/codex-goal-mode-discipline.md",
        ],
    },
    {
        "id": "dry-run-apply-parity-contract",
        "target": ".flywheel/doctrine/dry-run-apply-parity-contract.md",
        "sources": [ROOT / ".flywheel/doctrine/dry-run-apply-parity-contract.md"],
    },
    {
        "id": "dcg-worker-freeze-discipline",
        "target": ".flywheel/doctrine/dcg-worker-freeze-discipline.md",
        "sources": [ROOT / ".flywheel/doctrine/dcg-worker-freeze-discipline.md"],
    },
    {
        "id": "runtime-doctrine-separation-discipline",
        "target": ".flywheel/doctrine/runtime-doctrine-separation-discipline.md",
        "sources": [ROOT / ".flywheel/doctrine/runtime-doctrine-separation-discipline.md"],
    },
    {
        "id": "repo-hygiene-tick-discipline",
        "target": ".flywheel/doctrine/repo-hygiene-tick-discipline.md",
        "sources": [ROOT / ".flywheel/doctrine/repo-hygiene-tick-discipline.md"],
    },
]

MEMORY_PINS = [
    "feedback_goal_mode_is_codex_usage_limit_workaround",
    "feedback_codex_goal_mode_runtime_enforcement",
    "feedback_auto_push_blocked_worker_abandonment",
    "feedback_dry_run_apply_parity_contract",
]

DEFAULT_FLEET = {
    "flywheel": "/Users/josh/Developer/flywheel",
    "skillos": "/Users/josh/Developer/skillos",
    "mobile-eats": "/Users/josh/Developer/mobile-eats",
    "picoz": "/Users/josh/Developer/polymarket-pico-z",
    "clutterfreespaces": "/Users/josh/Developer/clutterfreespaces",
    "alpsinsurance": "/Users/josh/Developer/alpsinsurance",
    "vrtx": "/Users/josh/Developer/vrtx",
    "zesttube": "/Users/josh/Developer/zesttube",
}

HOOK_FILES = [
    ".flywheel/scripts/dispatch-template.md",
    ".flywheel/dispatch-template.md",
    ".flywheel/worker-tick.md",
    ".flywheel/WORKER-TICK.md",
    ".flywheel/WORK.md",
    ".flywheel/GOAL.md",
    "AGENTS.md",
    ".flywheel/AGENTS-CANONICAL.md",
]


def run(cmd: list[str], cwd: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(cmd, cwd=str(cwd), text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)


def load_fleet() -> dict[str, str]:
    raw = os.environ.get("WORKER_DISCIPLINE_FLEET_JSON", "")
    if raw:
        data = json.loads(raw)
        return {str(k): str(v) for k, v in data.items()}
    return DEFAULT_FLEET


def resolve_target(name: str) -> Path:
    fleet = load_fleet()
    if name not in fleet:
        raise SystemExit(f"unknown target orch: {name}")
    return Path(fleet[name]).expanduser().resolve()


def source_for(row: dict[str, Any]) -> Path | None:
    for source in row["sources"]:
        source = Path(source)
        if source.exists():
            return source
    return None


def doctrine_present(repo: Path, row: dict[str, Any]) -> tuple[bool, str | None]:
    candidates = [row["target"], *row.get("alternate_targets", [])]
    for rel in candidates:
        path = repo / rel
        if path.exists():
            return True, rel
    return False, None


def project_memory_path(repo: Path, orch: str) -> Path:
    local = repo / ".claude-memory/MEMORY.md"
    if local.exists() or local.parent.exists():
        return local

    explicit = os.environ.get("WORKER_DISCIPLINE_MEMORY_ROOT")
    if explicit:
        root = Path(explicit).expanduser()
        named = root / orch / "MEMORY.md"
        if named.exists() or named.parent.exists():
            return named
        escaped = str(repo).replace("/", "-")
        return root / escaped / "memory/MEMORY.md"

    escaped = str(repo).replace("/", "-")
    return Path.home() / ".claude/projects" / escaped / "memory/MEMORY.md"


def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except FileNotFoundError:
        return ""


def hook_probe(repo: Path) -> dict[str, Any]:
    files = []
    combined = ""
    for rel in HOOK_FILES:
        path = repo / rel
        if path.exists() and path.is_file():
            text = read_text(path)
            files.append(rel)
            combined += "\n" + text
    low = combined.lower()
    checks = {
        "activation_primitive": ("codex-goal-activate" in low) or ("/goal" in combined),
        "post_callback_auto_push_verify": ("auto_push_status" in low)
        or ("auto-push status" in low)
        or ("auto_push" in low and "callback" in low),
        "never_stash_other_wip": ("never stash" in low and ("wip" in low or "other worker" in low)),
        "dry_run_apply_parity": ("dry-run/apply" in low) or ("dry-run" in low and "apply" in low and "same" in low),
        "dcg_recovery": ("dcg" in low and ("pre-authorized" in low or "pre-authorized-scopes" in low)),
        "runtime_doctrine_separation": ("runtime" in low and "doctrine" in low and "separation" in low),
    }
    return {"files_checked": files, "checks": checks}


def compute_plan(orch: str, repo: Path) -> dict[str, Any]:
    doctrines = []
    actions = []
    gaps = []
    for row in DOCTRINES:
        present, existing_rel = doctrine_present(repo, row)
        source = source_for(row)
        status = "present" if present else "missing"
        item = {
            "id": row["id"],
            "target": row["target"],
            "status": status,
            "existing_path": existing_rel,
            "source": str(source) if source else None,
        }
        doctrines.append(item)
        if not present:
            if source:
                actions.append({"type": "copy_doctrine", "id": row["id"], "source": str(source), "target": str(repo / row["target"])})
            else:
                gaps.append({"type": "missing_source", "id": row["id"], "target": row["target"]})

    memory_path = project_memory_path(repo, orch)
    memory_text = read_text(memory_path)
    memory = {
        "path": str(memory_path),
        "exists": memory_path.exists(),
        "pins": [],
    }
    for pin in MEMORY_PINS:
        present = pin in memory_text
        memory["pins"].append({"pin": pin, "status": "present" if present else "missing"})
        if not present:
            actions.append({"type": "append_memory_pin", "pin": pin, "target": str(memory_path)})

    hooks = hook_probe(repo)
    for name, ok in hooks["checks"].items():
        if not ok:
            gaps.append({"type": "missing_absorption_hook", "hook": name})

    return {
        "schema_version": SCHEMA_VERSION,
        "ts": iso_now(),
        "target_orch": orch,
        "target_repo": str(repo),
        "doctrines": doctrines,
        "memory": memory,
        "hooks": hooks,
        "planned_actions": actions,
        "propagation_gaps": gaps,
        "complete": not actions and not gaps,
    }


def is_real_cross_orch(repo: Path) -> bool:
    if repo == ROOT:
        return False
    text = str(repo)
    return text.startswith("/Users/josh/Developer/") or text.startswith("/Users/josh/Desktop/")


def apply_allowed(repo: Path) -> tuple[bool, str | None]:
    if not is_real_cross_orch(repo):
        return True, None
    if os.environ.get("WORKER_DISCIPLINE_CROSS_ORCH_APPLY_AUTH") == AUTH_TOKEN:
        return True, None
    return False, "real_cross_orch_apply_requires_joshua_and_skillos_canonicalization_gate"


def append_memory_pin(path: Path, pin: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    existing = read_text(path)
    if pin in existing:
        return
    prefix = "" if existing.endswith("\n") or not existing else "\n"
    with path.open("a", encoding="utf-8") as handle:
        handle.write(prefix + f"- [{pin}]({pin}.md) — propagated worker-discipline pin\n")


def apply_plan(repo: Path, plan: dict[str, Any]) -> list[str]:
    changed: list[str] = []
    allowed, reason = apply_allowed(repo)
    if not allowed:
        plan["apply_refused_reason"] = reason
        return changed

    for action in plan["planned_actions"]:
        if action["type"] == "copy_doctrine":
            target = Path(action["target"])
            source = Path(action["source"])
            target.parent.mkdir(parents=True, exist_ok=True)
            if target.exists() and target.read_bytes() == source.read_bytes():
                continue
            shutil.copy2(source, target)
            changed.append(str(target))
        elif action["type"] == "append_memory_pin":
            target = Path(action["target"])
            before = read_text(target)
            append_memory_pin(target, action["pin"])
            if read_text(target) != before:
                changed.append(str(target))

    repo_changed = [path for path in changed if Path(path).resolve().is_relative_to(repo)]
    if repo_changed and (repo / ".git").exists():
        rels = [str(Path(path).resolve().relative_to(repo)) for path in repo_changed]
        run(["git", "add", *rels], repo)
        msg = "docs(worker-discipline): absorb propagated doctrine package"
        commit = run(["git", "commit", "-m", msg], repo)
        plan["git_commit"] = {
            "attempted": True,
            "returncode": commit.returncode,
            "stdout": commit.stdout.strip(),
            "stderr": commit.stderr.strip(),
        }
    return changed


def main() -> int:
    parser = argparse.ArgumentParser(description="Plan or apply worker-discipline doctrine propagation for one orch.")
    parser.add_argument("--target-orch", required=True, help="Fleet orch name, e.g. flywheel, skillos, picoz.")
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--dry-run", action="store_true", help="Emit the propagation plan without mutation.")
    mode.add_argument("--apply", action="store_true", help="Apply the computed plan; real cross-orch targets require explicit auth env.")
    parser.add_argument("--json", action="store_true", help="Emit JSON.")
    args = parser.parse_args()

    dry_run = not args.apply
    repo = resolve_target(args.target_orch)
    plan = compute_plan(args.target_orch, repo)
    plan["dry_run"] = dry_run
    plan["mode"] = "dry-run" if dry_run else "apply"
    plan["mutated_files"] = []

    if args.apply:
        plan["mutated_files"] = apply_plan(repo, plan)
        after = compute_plan(args.target_orch, repo)
        plan["post_apply_complete"] = after["complete"]
        plan["post_apply_gaps"] = after["propagation_gaps"]

    if args.json:
        print(json.dumps(plan, sort_keys=True))
    else:
        print(f"{args.target_orch}: actions={len(plan['planned_actions'])} gaps={len(plan['propagation_gaps'])} mode={plan['mode']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
PY
