#!/usr/bin/env bash
set -euo pipefail

PHASE_C_FLEET_VALIDATION_SCRIPT_PATH="${BASH_SOURCE[0]}" python3 - "$@" <<'PY'
from __future__ import annotations

import argparse
import hashlib
import json
import os
import sys
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCHEMA_VERSION = "phase-c-fleet-validation/v1"

CANONICAL_FILES = [
    {
        "id": "codex-goal-activate",
        "rel": ".flywheel/scripts/codex-goal-activate.sh",
    },
    {
        "id": "pane-work-signal-classify",
        "rel": ".flywheel/scripts/pane-work-signal-classify.sh",
    },
    {
        "id": "pane-work-signal-taxonomy-v0.2",
        "rel": ".flywheel/specs/pane-work-signal-taxonomy-v0.2.md",
    },
    {
        "id": "codex-goal-mode-discipline",
        "rel": ".flywheel/doctrine/meta-learnings/codex-goal-mode-discipline.md",
        "alternate_rels": [".flywheel/doctrine/codex-goal-mode-discipline.md"],
    },
]

DOCTRINE_DOCS = [
    ".flywheel/doctrine/auto-push-blocked-worker-discipline.md",
    ".flywheel/doctrine/dcg-worker-freeze-discipline.md",
    ".flywheel/doctrine/dry-run-apply-parity-contract.md",
    ".flywheel/doctrine/runtime-doctrine-separation-discipline.md",
    ".flywheel/doctrine/repo-hygiene-tick-discipline.md",
]

MEMORY_PINS = [
    "feedback_goal_mode_is_codex_usage_limit_workaround",
    "feedback_codex_goal_mode_runtime_enforcement",
    "feedback_auto_push_blocked_worker_abandonment",
    "feedback_dry_run_apply_parity_contract",
]

DEFAULT_FLEET = {
    "mobile-eats": "/Users/josh/Developer/mobile-eats",
    "picoz": "/Users/josh/Developer/polymarket-pico-z",
    "clutterfreespaces": "/Users/josh/Developer/clutterfreespaces",
    "alpsinsurance": "/Users/josh/Developer/alpsinsurance",
    "vrtx": "/Users/josh/Developer/vrtx",
    "terratitle": "/Users/josh/Developer/terratitle",
    "skillos": "/Users/josh/Developer/skillos",
    "flywheel": "/Users/josh/Developer/flywheel",
}

DISPATCHER_SURFACES = [
    ".flywheel/scripts/dispatch.sh",
    ".flywheel/scripts/dispatch-template.md",
    ".flywheel/dispatch-template.md",
    ".flywheel/WORK.md",
    ".flywheel/GOAL.md",
    "AGENTS.md",
]

ATTRIBUTION_MARKERS = [
    "phase-c-allow-divergence",
    "local-divergence",
    "local divergence",
    "expected divergence",
    "local bug-patches",
    "local bug patches",
    "local patch",
    "flywheel-local",
]


def iso_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def repo_root() -> Path:
    script = Path(os.environ.get("PHASE_C_FLEET_VALIDATION_SCRIPT_PATH", "")).resolve()
    if script.name:
        return script.parents[2]
    return Path.cwd().resolve()


ROOT = repo_root()


def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except (FileNotFoundError, UnicodeDecodeError):
        return ""


def sha256(path: Path) -> str | None:
    if not path.exists() or not path.is_file():
        return None
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def has_attribution(path: Path) -> bool:
    text = read_text(path).lower()
    return any(marker in text for marker in ATTRIBUTION_MARKERS)


def canonical_path(canonical_root: Path, row: dict[str, Any]) -> Path:
    return canonical_root / row["rel"]


def target_path(repo: Path, row: dict[str, Any]) -> tuple[Path, str]:
    candidates = [row["rel"], *row.get("alternate_rels", [])]
    for rel in candidates:
        path = repo / rel
        if path.exists():
            return path, rel
    return repo / row["rel"], row["rel"]


def project_memory_path(repo: Path, orch: str) -> Path:
    local = repo / ".claude-memory/MEMORY.md"
    if local.exists() or local.parent.exists():
        return local
    explicit = os.environ.get("PHASE_C_MEMORY_ROOT")
    if explicit:
        root = Path(explicit).expanduser()
        named = root / orch / "MEMORY.md"
        if named.exists() or named.parent.exists():
            return named
        return root / str(repo).replace("/", "-") / "memory/MEMORY.md"
    return Path.home() / ".claude/projects" / str(repo).replace("/", "-") / "memory/MEMORY.md"


def load_fleet(args: argparse.Namespace) -> dict[str, str]:
    raw = os.environ.get("PHASE_C_FLEET_JSON", "")
    fleet = DEFAULT_FLEET.copy()
    if raw:
        fleet = {str(k): str(v) for k, v in json.loads(raw).items()}
    for item in args.repo or []:
        if "=" not in item:
            raise SystemExit(f"--repo expects name=/path, got {item!r}")
        name, path = item.split("=", 1)
        fleet[name] = path
    return fleet


def phase_a_probe(orch: str, repo: Path, canonical_root: Path) -> dict[str, Any]:
    files = []
    findings = []
    counts = Counter()
    for row in CANONICAL_FILES:
        source = canonical_path(canonical_root, row)
        target, target_rel = target_path(repo, row)
        source_hash = sha256(source)
        target_hash = sha256(target)
        exists = target_hash is not None
        status = "missing"
        attributed = False
        if not source_hash:
            status = "canonical_missing"
            counts["canonical_missing"] += 1
            findings.append({"class": "canonical_missing", "orch": orch, "file": row["rel"], "severity": "blocker"})
        elif not exists:
            counts["missing"] += 1
            findings.append({"class": "file_missing", "orch": orch, "file": row["rel"], "severity": "gap"})
        elif source_hash == target_hash:
            status = "match"
            counts["matches"] += 1
        else:
            attributed = has_attribution(target)
            if attributed:
                status = "mismatch_attributed"
                counts["allowed_divergences"] += 1
                findings.append({"class": "shasum_mismatch_attributed", "orch": orch, "file": target_rel, "severity": "allowed"})
            else:
                status = "mismatch_unattributed"
                counts["mismatches"] += 1
                findings.append({"class": "shasum_mismatch_unattributed", "orch": orch, "file": target_rel, "severity": "gap"})
        files.append(
            {
                "id": row["id"],
                "expected_path": row["rel"],
                "target_path": target_rel,
                "present": exists,
                "status": status,
                "sha256": target_hash,
                "canonical_sha256": source_hash,
                "divergence_attributed": attributed,
            }
        )
    conforming = counts["matches"] + counts["allowed_divergences"]
    expected = len(CANONICAL_FILES)
    pct = round(conforming / expected, 4) if expected else 0.0
    return {
        "expected": expected,
        "present": sum(1 for row in files if row["present"]),
        "shasum_matches": counts["matches"],
        "allowed_divergences": counts["allowed_divergences"],
        "missing": counts["missing"],
        "mismatches": counts["mismatches"],
        "canonical_missing": counts["canonical_missing"],
        "conformance_pct": pct,
        "files": files,
        "findings": findings,
    }


def phase_b_probe(repo: Path) -> dict[str, Any]:
    checked = []
    combined = ""
    for rel in DISPATCHER_SURFACES:
        path = repo / rel
        if path.exists() and path.is_file():
            checked.append(rel)
            combined += "\n" + read_text(path)
    low = combined.lower()
    has_activation = "codex-goal-activate.sh" in low or "codex-goal-activate" in low
    has_route_source = "route_source" in low or "route-source" in low or "route source" in low
    has_topology = "session-topology" in low or "worker_kinds" in low or "agent_type" in low
    status = "integrated" if has_activation and (has_route_source or has_topology) else "pending"
    pct = 1.0 if status == "integrated" else 0.0
    return {
        "status": status,
        "conformance_pct": pct,
        "files_checked": checked,
        "checks": {
            "codex_goal_activation_route": has_activation,
            "route_source_logged_or_topology_detected": has_route_source or has_topology,
        },
    }


def doctrine_probe(repo: Path) -> dict[str, Any]:
    rows = []
    for rel in DOCTRINE_DOCS:
        rows.append({"path": rel, "present": (repo / rel).exists()})
    present = sum(1 for row in rows if row["present"])
    return {
        "expected": len(rows),
        "present": present,
        "conformance_pct": round(present / len(rows), 4) if rows else 0.0,
        "files": rows,
    }


def memory_probe(orch: str, repo: Path) -> dict[str, Any]:
    path = project_memory_path(repo, orch)
    text = read_text(path)
    rows = [{"pin": pin, "present": pin in text} for pin in MEMORY_PINS]
    present = sum(1 for row in rows if row["present"])
    return {
        "path": str(path),
        "exists": path.exists(),
        "expected": len(rows),
        "present": present,
        "conformance_pct": round(present / len(rows), 4) if rows else 0.0,
        "pins": rows,
    }


def probe_orch(orch: str, repo_path: str, canonical_root: Path, ts: str) -> dict[str, Any]:
    repo = Path(repo_path).expanduser().resolve()
    phase_a = phase_a_probe(orch, repo, canonical_root)
    phase_b = phase_b_probe(repo)
    doctrine = doctrine_probe(repo)
    memory = memory_probe(orch, repo)
    findings = list(phase_a["findings"])
    if not repo.exists():
        findings.append({"class": "repo_missing", "orch": orch, "repo": str(repo), "severity": "blocker"})
    return {
        "schema_version": SCHEMA_VERSION,
        "ts": ts,
        "orch": orch,
        "repo": str(repo),
        "repo_exists": repo.exists(),
        "phase_a_files": phase_a,
        "phase_b_dispatcher_integration": phase_b,
        "doctrine_propagation": doctrine,
        "memory_pins": memory,
        "overall_conformance_pct": phase_a["conformance_pct"],
        "divergence_findings": findings,
    }


def avg(rows: list[dict[str, Any]], path: list[str]) -> float:
    values = []
    for row in rows:
        current: Any = row
        for key in path:
            current = current[key]
        values.append(float(current))
    return round(sum(values) / len(values), 4) if values else 0.0


def rollup(rows: list[dict[str, Any]], canonical_root: Path, ts: str) -> dict[str, Any]:
    classes: Counter[str] = Counter()
    for row in rows:
        for finding in row["divergence_findings"]:
            classes[finding["class"]] += 1
    return {
        "schema_version": SCHEMA_VERSION,
        "ts": ts,
        "canonical_root": str(canonical_root),
        "fleet_size": len(rows),
        "fleet_conformance_avg": avg(rows, ["overall_conformance_pct"]),
        "phase_a_avg": avg(rows, ["phase_a_files", "conformance_pct"]),
        "phase_b_avg": avg(rows, ["phase_b_dispatcher_integration", "conformance_pct"]),
        "doctrine_avg": avg(rows, ["doctrine_propagation", "conformance_pct"]),
        "memory_avg": avg(rows, ["memory_pins", "conformance_pct"]),
        "top_divergence_classes": [
            {"class": name, "count": count} for name, count in classes.most_common()
        ],
    }


def markdown_report(payload: dict[str, Any]) -> str:
    roll = payload["fleet_rollup"]
    lines = [
        "# Phase C Fleet Validation",
        "",
        f"- `ts`: `{payload['ts']}`",
        f"- `canonical_root`: `{roll['canonical_root']}`",
        f"- `fleet_conformance_avg`: `{roll['fleet_conformance_avg']}`",
        f"- `phase_a_avg`: `{roll['phase_a_avg']}`",
        f"- `phase_b_avg`: `{roll['phase_b_avg']}`",
        f"- `doctrine_avg`: `{roll['doctrine_avg']}`",
        f"- `memory_avg`: `{roll['memory_avg']}`",
        "",
        "| orch | phase_a | phase_b | doctrine | memory | findings |",
        "|---|---:|---:|---:|---:|---:|",
    ]
    for row in payload["orch_envelopes"]:
        lines.append(
            "| {orch} | {a:.4f} | {b:.4f} | {d:.4f} | {m:.4f} | {f} |".format(
                orch=row["orch"],
                a=row["phase_a_files"]["conformance_pct"],
                b=row["phase_b_dispatcher_integration"]["conformance_pct"],
                d=row["doctrine_propagation"]["conformance_pct"],
                m=row["memory_pins"]["conformance_pct"],
                f=len(row["divergence_findings"]),
            )
        )
    lines.extend(["", "## Divergences", ""])
    any_findings = False
    for row in payload["orch_envelopes"]:
        for finding in row["divergence_findings"]:
            any_findings = True
            lines.append(
                f"- `{row['orch']}` `{finding['class']}` `{finding.get('file', finding.get('repo', ''))}` severity=`{finding['severity']}`"
            )
    if not any_findings:
        lines.append("- none")
    lines.extend(["", "## JSON", "", "```json", json.dumps(payload, indent=2, sort_keys=True), "```", ""])
    return "\n".join(lines)


def handoff(payload: dict[str, Any]) -> str:
    roll = payload["fleet_rollup"]
    lines = [
        "# Phase C Fleet Validation Handoff",
        "",
        "to: skillos:1",
        "from: flywheel:worker",
        f"task_id: flywheel-ee6hg",
        f"ts: {payload['ts']}",
        "",
        "## Rollup",
        "",
        f"- fleet_conformance_avg: `{roll['fleet_conformance_avg']}`",
        f"- phase_a_avg: `{roll['phase_a_avg']}`",
        f"- phase_b_avg: `{roll['phase_b_avg']}`",
        f"- doctrine_avg: `{roll['doctrine_avg']}`",
        f"- memory_avg: `{roll['memory_avg']}`",
        "",
        "## Divergences",
        "",
    ]
    findings = []
    for row in payload["orch_envelopes"]:
        for finding in row["divergence_findings"]:
            findings.append({"orch": row["orch"], **finding})
    if findings:
        for finding in findings:
            lines.append(
                f"- `{finding['orch']}` `{finding['class']}` `{finding.get('file', finding.get('repo', ''))}` severity=`{finding['severity']}`"
            )
    else:
        lines.append("- none")
    lines.extend(
        [
            "",
            "## Requested SkillOS Follow-Up",
            "",
            "- Absorb unexpected Phase C divergence classes into the SkillOS propagation lane.",
            "- Keep Phase B dispatcher integration operator-paced; do not overwrite local dispatchers.",
            "",
            "## Envelope",
            "",
            "```json",
            json.dumps({"fleet_rollup": roll, "divergences": findings}, indent=2, sort_keys=True),
            "```",
            "",
        ]
    )
    return "\n".join(lines)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--fleet-default", action="store_true", help="probe the built-in 8-orch fleet")
    parser.add_argument("--repo", action="append", help="add or override fleet entry as name=/path")
    parser.add_argument("--canonical-root", default=os.environ.get("PHASE_C_CANONICAL_ROOT", "/Users/josh/Developer/skillos"))
    parser.add_argument("--timestamp", default=os.environ.get("PHASE_C_TIMESTAMP", ""))
    parser.add_argument("--report", help="write markdown audit report")
    parser.add_argument("--handoff", help="write markdown handoff to skillos")
    parser.add_argument("--json", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    ts = args.timestamp or iso_now()
    canonical_root = Path(args.canonical_root).expanduser().resolve()
    fleet = load_fleet(args)
    rows = [probe_orch(name, path, canonical_root, ts) for name, path in fleet.items()]
    payload = {
        "schema_version": SCHEMA_VERSION,
        "ts": ts,
        "orch_envelopes": rows,
        "fleet_rollup": rollup(rows, canonical_root, ts),
    }
    if args.report:
        path = Path(args.report)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(markdown_report(payload), encoding="utf-8")
    if args.handoff:
        path = Path(args.handoff)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(handoff(payload), encoding="utf-8")
    if args.json:
        print(json.dumps(payload, sort_keys=True))
    else:
        print(markdown_report(payload))
    return 0


if __name__ == "__main__":
    sys.exit(main())
PY
