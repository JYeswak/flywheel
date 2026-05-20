#!/usr/bin/env python3
"""Group fleet skill discoveries and apply the skillos promotion ladder."""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from collections import Counter, defaultdict
from dataclasses import dataclass
from datetime import datetime, timezone, timedelta
from pathlib import Path
from typing import Any


SCHEMA_VERSION = "skillos-discovery-coordinator/v1"
PULSE_SCHEMA_VERSION = "fleet-skill-pulse/v1"
DEFAULT_DISCOVERIES = Path("~/.local/state/flywheel/skill-discoveries.jsonl").expanduser()
DEFAULT_PULSE = Path("~/.local/state/flywheel/team-pulse.jsonl").expanduser()


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


def parse_ts(value: Any) -> datetime | None:
    if not isinstance(value, str) or not value:
        return None
    try:
        if value.endswith("Z"):
            value = value[:-1] + "+00:00"
        parsed = datetime.fromisoformat(value)
        if parsed.tzinfo is None:
            parsed = parsed.replace(tzinfo=timezone.utc)
        return parsed.astimezone(timezone.utc)
    except ValueError:
        return None


def isoformat(dt: datetime) -> str:
    return dt.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")


def slugify(value: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "-", value.lower()).strip("-")
    return slug or "unnamed"


def normalize_candidate(value: Any) -> str:
    if not isinstance(value, str):
        return ""
    return re.sub(r"\s+", " ", value.strip())


def read_jsonl(path: Path, now: datetime, window_hours: float) -> tuple[list[dict[str, Any]], int]:
    if not path.exists():
        return [], 0
    cutoff = now - timedelta(hours=window_hours)
    rows: list[dict[str, Any]] = []
    invalid = 0
    with path.open("r", encoding="utf-8") as handle:
        for line in handle:
            line = line.strip()
            if not line:
                continue
            try:
                row = json.loads(line)
            except json.JSONDecodeError:
                invalid += 1
                continue
            ts = parse_ts(row.get("ts"))
            if ts is None or ts < cutoff or ts > now + timedelta(minutes=5):
                continue
            candidate = normalize_candidate(row.get("candidate_skill_name"))
            if not candidate:
                invalid += 1
                continue
            row["candidate_skill_name"] = candidate
            rows.append(row)
    return rows, invalid


def br_bin_default() -> str:
    cargo_br = Path.home() / ".cargo/bin/br"
    return str(cargo_br) if cargo_br.exists() else "br"


def parse_br_payload(text: str) -> list[dict[str, Any]]:
    if not text.strip():
        return []
    payload = json.loads(text)
    if isinstance(payload, list):
        return [item for item in payload if isinstance(item, dict)]
    if isinstance(payload, dict):
        if isinstance(payload.get("issues"), list):
            return [item for item in payload["issues"] if isinstance(item, dict)]
        if "id" in payload:
            return [payload]
    return []


def list_existing_beads(repo: Path, br_bin: str) -> tuple[list[dict[str, Any]], str | None]:
    try:
        proc = subprocess.run(
            [br_bin, "list", "--json"],
            cwd=str(repo),
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
    except FileNotFoundError as exc:
        return [], f"br_not_found:{exc}"
    if proc.returncode != 0:
        return [], f"br_list_failed:{proc.stderr.strip()}"
    try:
        return parse_br_payload(proc.stdout), None
    except json.JSONDecodeError as exc:
        return [], f"br_list_invalid_json:{exc}"


def find_existing_skill_bead(beads: list[dict[str, Any]], candidate: str) -> dict[str, Any] | None:
    expected = f"[skill-builder] {candidate}".lower()
    marker = f"[skill-builder:{slugify(candidate)}]"
    for bead in beads:
        title = str(bead.get("title", ""))
        status = str(bead.get("status", ""))
        if status.lower() in {"closed", "done", "resolved"}:
            continue
        lower_title = title.lower()
        if lower_title == expected or marker in lower_title:
            return bead
    return None


def consolidated_evidence(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    evidence: list[dict[str, Any]] = []
    for row in rows:
        evidence.append(
            {
                "discovery_id": row.get("discovery_id"),
                "session": row.get("session"),
                "worker_pane": row.get("worker_pane"),
                "task_context": row.get("task_context"),
                "discovery_kind": row.get("discovery_kind"),
                "promotion_signal": row.get("promotion_signal"),
                "evidence": row.get("evidence", {}),
            }
        )
    return evidence


def bead_description(candidate: str, rows: list[dict[str, Any]], idempotency_key: str | None) -> str:
    ids = ", ".join(str(row.get("discovery_id")) for row in rows)
    sessions = ", ".join(sorted({str(row.get("session")) for row in rows if row.get("session")}))
    key_line = f"\nidempotency_key={idempotency_key}" if idempotency_key else ""
    return (
        "Auto-planned by skillos discovery coordinator.\n"
        f"candidate_skill_name={candidate}\n"
        f"sightings={len(rows)}\n"
        f"sessions={sessions}\n"
        f"discovery_ids={ids}\n"
        "source=~/.local/state/flywheel/skill-discoveries.jsonl\n"
        "acceptance=author reusable skill or document no-skill disposition; cite all discovery IDs"
        f"{key_line}"
    )


@dataclass
class CandidatePlan:
    candidate_skill_name: str
    group_key: str
    sighting_count: int
    rows: list[dict[str, Any]]
    existing_bead: dict[str, Any] | None

    def action(self) -> str:
        if self.sighting_count >= 5 and self.existing_bead is not None:
            return "dispatch_worker_needed"
        if self.sighting_count >= 3:
            if self.existing_bead is not None:
                return "skill_builder_bead_exists"
            return "skill_builder_bead_needed"
        if self.sighting_count >= 2:
            return "agent_mail_thread_needed"
        return "log_only"


def plan_candidates(rows: list[dict[str, Any]], beads: list[dict[str, Any]]) -> list[CandidatePlan]:
    grouped: dict[str, list[dict[str, Any]]] = defaultdict(list)
    names: dict[str, str] = {}
    for row in rows:
        candidate = normalize_candidate(row.get("candidate_skill_name"))
        group_key = candidate.lower()
        grouped[group_key].append(row)
        names.setdefault(group_key, candidate)
    plans: list[CandidatePlan] = []
    for group_key, group_rows in grouped.items():
        candidate = names[group_key]
        plans.append(
            CandidatePlan(
                candidate_skill_name=candidate,
                group_key=group_key,
                sighting_count=len(group_rows),
                rows=sorted(group_rows, key=lambda item: str(item.get("ts", ""))),
                existing_bead=find_existing_skill_bead(beads, candidate),
            )
        )
    return sorted(plans, key=lambda plan: (-plan.sighting_count, plan.candidate_skill_name.lower()))


def candidate_to_json(plan: CandidatePlan, br_bin: str, idempotency_key: str | None) -> dict[str, Any]:
    action = plan.action()
    evidence = consolidated_evidence(plan.rows)
    title = f"[skill-builder:{slugify(plan.candidate_skill_name)}] {plan.candidate_skill_name}"
    description = bead_description(plan.candidate_skill_name, plan.rows, idempotency_key)
    obj: dict[str, Any] = {
        "candidate_skill_name": plan.candidate_skill_name,
        "group_key": plan.group_key,
        "match_mode": "exact_normalized",
        "fuzzy_match_used": False,
        "sighting_count": plan.sighting_count,
        "discovery_ids": [row.get("discovery_id") for row in plan.rows],
        "sessions": sorted({str(row.get("session")) for row in plan.rows if row.get("session")}),
        "action": action,
        "pending_action": action not in {"log_only", "skill_builder_bead_exists"},
        "consolidated_evidence": evidence,
    }
    if plan.existing_bead is not None:
        obj["target_bead_id"] = plan.existing_bead.get("id")
        obj["target_bead_status"] = plan.existing_bead.get("status")
    if action == "skill_builder_bead_needed":
        obj["planned_bead"] = {
            "title": title,
            "description": description,
            "br_argv": [
                br_bin,
                "create",
                title,
                "--type",
                "task",
                "--priority",
                "P1",
                "--description",
                description,
                "--json",
                "--dry-run",
            ],
            "would_call_external": ["br"],
        }
    if action == "agent_mail_thread_needed":
        obj["planned_agent_mail_thread"] = f"[skill-discovery] {plan.candidate_skill_name}"
    return obj


def append_jsonl(path: Path, row: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(row, sort_keys=True, separators=(",", ":")) + "\n")


def build_pulse(now: datetime, candidates: list[dict[str, Any]], discovery_count: int, dry_run: bool) -> dict[str, Any]:
    actions = Counter(str(item.get("action")) for item in candidates)
    pending = sum(1 for item in candidates if item.get("pending_action"))
    return {
        "schema_version": PULSE_SCHEMA_VERSION,
        "ts": isoformat(now),
        "event": "fleet_skill_pulse",
        "source": "skillos-discovery-coordinator",
        "session": "skillos",
        "dry_run": dry_run,
        "discovery_count": discovery_count,
        "candidate_count": len(candidates),
        "pending_action_count": pending,
        "actions_count": dict(sorted(actions.items())),
        "top_candidates": [
            {
                "candidate_skill_name": item["candidate_skill_name"],
                "sighting_count": item["sighting_count"],
                "action": item["action"],
                "target_bead_id": item.get("target_bead_id"),
            }
            for item in candidates[:10]
        ],
    }


def create_bead(repo: Path, br_bin: str, plan: CandidatePlan, idempotency_key: str) -> dict[str, Any]:
    title = f"[skill-builder:{slugify(plan.candidate_skill_name)}] {plan.candidate_skill_name}"
    description = bead_description(plan.candidate_skill_name, plan.rows, idempotency_key)
    proc = subprocess.run(
        [
            br_bin,
            "create",
            title,
            "--type",
            "task",
            "--priority",
            "P1",
            "--description",
            description,
            "--json",
        ],
        cwd=str(repo),
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if proc.returncode != 0:
        raise RuntimeError(f"br_create_failed:{proc.stderr.strip()}")
    created = parse_br_payload(proc.stdout)
    if not created:
        raise RuntimeError("br_create_returned_no_issue")
    return created[0]


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Coordinate skillos promotion ladder for fleet skill discoveries.",
        epilog=(
            "Ladder: 1 sighting -> log_only; 2 sightings -> agent_mail_thread_needed; "
            "3 sightings -> skill_builder_bead_needed unless one exists; "
            "5 sightings with an open bead -> dispatch_worker_needed. "
            "Dry-run is the default. Apply mode requires --idempotency-key before creating beads."
        ),
    )
    parser.add_argument("--discoveries", default=os.environ.get("FLYWHEEL_SKILL_DISCOVERY_PATH", str(DEFAULT_DISCOVERIES)))
    parser.add_argument("--pulse", default=os.environ.get("FLYWHEEL_TEAM_PULSE", str(DEFAULT_PULSE)))
    parser.add_argument("--repo", default=os.getcwd())
    parser.add_argument("--window-hours", type=float, default=24.0)
    parser.add_argument("--now", help="Fixture timestamp, ISO-8601")
    parser.add_argument("--br-bin", default=br_bin_default())
    parser.add_argument("--dry-run", action="store_true", default=True)
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--idempotency-key")
    parser.add_argument("--json", action="store_true")
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    dry_run = not args.apply
    now = parse_ts(args.now) if args.now else utc_now()
    if now is None:
        print(json.dumps({"schema_version": SCHEMA_VERSION, "error": "invalid_now"}))
        return 2

    repo = Path(args.repo).expanduser().resolve()
    discoveries_path = Path(args.discoveries).expanduser()
    pulse_path = Path(args.pulse).expanduser()

    rows, invalid_rows = read_jsonl(discoveries_path, now, args.window_hours)
    beads, br_error = list_existing_beads(repo, args.br_bin)
    plans = plan_candidates(rows, beads)
    candidates = [candidate_to_json(plan, args.br_bin, args.idempotency_key) for plan in plans]

    if args.apply and any(item["action"] == "skill_builder_bead_needed" for item in candidates) and not args.idempotency_key:
        error = {
            "schema_version": SCHEMA_VERSION,
            "status": "error",
            "error": "--apply requires --idempotency-key",
            "reason": "idempotency_key_required",
        }
        print(json.dumps(error, indent=2 if args.json else None, sort_keys=True))
        return 1

    mutations = {"beads_created": [], "agent_mail_mutated": False, "ntm_dispatch_mutated": False}
    if args.apply:
        for plan in plans:
            if plan.action() != "skill_builder_bead_needed":
                continue
            created = create_bead(repo, args.br_bin, plan, args.idempotency_key)
            mutations["beads_created"].append({"candidate_skill_name": plan.candidate_skill_name, "bead_id": created.get("id")})
        if mutations["beads_created"]:
            beads, br_error = list_existing_beads(repo, args.br_bin)
            plans = plan_candidates(rows, beads)
            candidates = [candidate_to_json(plan, args.br_bin, args.idempotency_key) for plan in plans]

    pulse_row = build_pulse(now, candidates, len(rows), dry_run)
    append_jsonl(pulse_path, pulse_row)

    output = {
        "schema_version": SCHEMA_VERSION,
        "status": "dry_run" if dry_run else "applied",
        "dry_run": dry_run,
        "repo": str(repo),
        "discoveries_path": str(discoveries_path),
        "pulse_path": str(pulse_path),
        "window_hours": args.window_hours,
        "candidate_count": len(candidates),
        "discovery_count": len(rows),
        "invalid_row_count": invalid_rows,
        "pending_action_count": pulse_row["pending_action_count"],
        "br_probe_error": br_error,
        "candidates": candidates,
        "pulse_row": pulse_row,
        "mutations": mutations,
    }
    print(json.dumps(output, indent=2 if args.json else None, sort_keys=True))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-03-agent-ergonomics-rubric.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-58-agent-tool-theory-of-mind.md`
