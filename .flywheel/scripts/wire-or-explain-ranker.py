#!/usr/bin/env python3
# canonical-cli-scoping-allow-large: reviewed compatibility surface; Cluster C owns package split after wave-0 CLI parity.
from __future__ import annotations

import argparse
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

SURFACE = "The Zest Sorter"
VERSION = "wire-or-explain-ranker/v1"
DEFAULT_REPO = "/Users/josh/Developer/flywheel"
UNRESOLVED_STATES = {"unwired", "questionably_wired"}
CLASS_WEIGHTS: dict[str, dict[str, float]] = {
    "state": {"unwired": 80, "questionably_wired": 35},
    "artifact_class": {
        "worker_branch": 28,
        "skill_candidate": 24,
        "dispatch_packet": 18,
        "bead": 16,
        "callback": 14,
        "finding": 10,
        "ledger_rebuild": 8,
        "other": 4,
    },
    "blocking_scope": {"fleet": 55, "tick": 34, "mission": 28, "skill_triage": 22, "local": 16, "none": 0},
    "locality": {"fleet": 30, "local": 22, "cross_orch": -30},
    "actionability": {"auto_fire_trigger": 16, "consumer": 12, "verification_probe": 8, "none_consumer_penalty": -24},
}


class RankerError(ValueError):
    def __init__(self, reason_code: str, message: str) -> None:
        super().__init__(message)
        self.reason_code = reason_code


def emit(data: dict[str, Any], rc: int = 0) -> int:
    print(json.dumps(data, sort_keys=True, indent=2))
    return rc


def parse_time(value: Any) -> datetime:
    if not isinstance(value, str) or not value:
        return datetime.fromtimestamp(0, tz=timezone.utc)
    text = value.replace("Z", "+00:00")
    try:
        dt = datetime.fromisoformat(text)
    except ValueError:
        return datetime.fromtimestamp(0, tz=timezone.utc)
    return dt if dt.tzinfo else dt.replace(tzinfo=timezone.utc)


def as_num(value: Any) -> float:
    if isinstance(value, bool):
        return 0.0
    if isinstance(value, (int, float)):
        return float(value)
    if isinstance(value, str):
        try:
            return float(value)
        except ValueError:
            return 0.0
    if isinstance(value, list):
        return float(len(value))
    return 0.0


def nested(row: dict[str, Any], key: str) -> Any:
    for container in (row, row.get("metadata"), row.get("payload")):
        if isinstance(container, dict) and key in container:
            return container[key]
    return None


def meaningful(value: Any) -> bool:
    return value not in (None, "", "NONE", "none", [], {})


def read_rows(path: Path) -> list[dict[str, Any]]:
    if not path.exists():
        raise RankerError("ledger_missing", f"ledger not found: {path}")
    rows: list[dict[str, Any]] = []
    try:
        with path.open("r", encoding="utf-8") as fh:
            for line_no, line in enumerate(fh, start=1):
                text = line.strip()
                if not text:
                    continue
                value = json.loads(text)
                if not isinstance(value, dict):
                    raise RankerError("ledger_row_not_object", f"row {line_no} is not an object")
                rows.append(value)
    except json.JSONDecodeError as exc:
        raise RankerError("ledger_parse_failed", f"invalid JSONL at line {line_no}: {exc}") from exc
    except OSError as exc:
        raise RankerError("ledger_read_failed", str(exc)) from exc
    if not rows:
        raise RankerError("ledger_empty", f"ledger has no rows: {path}")
    return rows


def br_ready_context(path_text: str | None) -> dict[str, Any]:
    if not path_text:
        return {"status": "not_requested", "count": 0}
    path = Path(path_text)
    if not path.exists():
        return {"status": "missing", "count": 0, "path": str(path)}
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        return {"status": "invalid", "count": 0, "path": str(path), "reason": str(exc)}
    count = len(value) if isinstance(value, list) else len(value.get("items", [])) if isinstance(value, dict) else 0
    return {"status": "loaded", "count": count, "path": str(path)}


def bounded_top(rows: list[dict[str, Any]], limit: int, key) -> list[dict[str, Any]]:
    if limit <= 0:
        return []
    selected: list[tuple[tuple[Any, ...], int, dict[str, Any]]] = []
    for idx, row in enumerate(rows):
        candidate = (key(row), idx, row)
        pos = 0
        while pos < len(selected) and selected[pos][:2] <= candidate[:2]:
            pos += 1
        if pos < limit:
            selected.insert(pos, candidate)
            if len(selected) > limit:
                selected.pop()
    return [row for _, _, row in selected]


def locality(row: dict[str, Any], local_session: str, local_repo: str) -> str:
    scope = str(row.get("blocking_scope") or "").lower()
    if scope == "fleet":
        return "fleet"
    owning = str(row.get("owning_orch") or "")
    session = str(row.get("session_id") or "")
    repo = str(row.get("ship_repo") or "")
    if session == local_session or owning.startswith(local_session) or repo == local_repo:
        return "local"
    return "cross_orch"


def route(row: dict[str, Any]) -> dict[str, str]:
    artifact = str(row.get("artifact_class") or "other")
    consumer = str(row.get("consumer") or "NONE")
    if artifact == "skill_candidate":
        return {"target": consumer if consumer != "NONE" else "skillos", "kind": "skill_candidate", "action": "route_to_skillos"}
    if consumer == "NONE":
        return {"target": str(row.get("owner") or "flywheel:1"), "kind": "owner_triage", "action": "assign_consumer_or_defer"}
    return {"target": consumer, "kind": artifact, "action": "drain_consumer"}


def score_row(row: dict[str, Any], now: datetime, local_session: str, local_repo: str) -> dict[str, Any]:
    state = str(row.get("state") or "")
    artifact = str(row.get("artifact_class") or "other")
    scope = str(row.get("blocking_scope") or "none")
    loc = locality(row, local_session, local_repo)
    age_hours = max(0.0, (now - parse_time(row.get("timestamp"))).total_seconds() / 3600)
    dependency_count = as_num(nested(row, "dependency_count")) + as_num(nested(row, "downstream_blockers"))
    ship_cost = as_num(nested(row, "ship_cost"))
    downstream_cost = as_num(nested(row, "downstream_cost")) + dependency_count * 4 + ship_cost
    actionability = 0.0
    if meaningful(row.get("auto_fire_trigger")):
        actionability += CLASS_WEIGHTS["actionability"]["auto_fire_trigger"]
    if meaningful(row.get("consumer")):
        actionability += CLASS_WEIGHTS["actionability"]["consumer"]
    else:
        actionability += CLASS_WEIGHTS["actionability"]["none_consumer_penalty"]
    if meaningful(row.get("verification_probe")):
        actionability += CLASS_WEIGHTS["actionability"]["verification_probe"]
    components = {
        "state": CLASS_WEIGHTS["state"].get(state, 0),
        "artifact_class": CLASS_WEIGHTS["artifact_class"].get(artifact, CLASS_WEIGHTS["artifact_class"]["other"]),
        "blocking_scope": CLASS_WEIGHTS["blocking_scope"].get(scope, 0),
        "locality": CLASS_WEIGHTS["locality"][loc],
        "age": min(age_hours, 720) / 12,
        "downstream_cost": downstream_cost,
        "actionability": actionability,
    }
    score = round(sum(components.values()), 3)
    bucket = 0 if loc == "fleet" else 1 if loc == "local" else 2
    return {
        "identity_key": row.get("identity_key") or row.get("row_id") or row.get("target") or "unknown",
        "state": state,
        "artifact_class": artifact,
        "blocking_scope": scope,
        "session_id": row.get("session_id"),
        "owning_orch": row.get("owning_orch"),
        "consumer": row.get("consumer"),
        "owner": row.get("owner"),
        "timestamp": row.get("timestamp"),
        "age_hours": round(age_hours, 3),
        "dependency_count": dependency_count,
        "ship_cost": ship_cost,
        "downstream_cost": downstream_cost,
        "locality": loc,
        "rank_bucket": bucket,
        "score": score,
        "score_components": components,
        "route": route(row),
    }


def rank(path: Path, *, top: int, now_text: str | None, br_ready: str | None, local_session: str, local_repo: str) -> dict[str, Any]:
    now = parse_time(now_text) if now_text else datetime.now(timezone.utc)
    rows = read_rows(path)
    unresolved = [score_row(row, now, local_session, local_repo) for row in rows if row.get("state") in UNRESOLVED_STATES]
    unresolved.sort(key=lambda row: (row["rank_bucket"], -row["score"], row["identity_key"]))
    for idx, row in enumerate(unresolved, start=1):
        row["rank"] = idx
    by_state: dict[str, int] = {}
    by_scope: dict[str, int] = {}
    for row in unresolved:
        by_state[row["state"]] = by_state.get(row["state"], 0) + 1
        by_scope[row["blocking_scope"]] = by_scope.get(row["blocking_scope"], 0) + 1
    return {
        "schema_version": VERSION,
        "surface": SURFACE,
        "status": "pass",
        "ledger": str(path),
        "class_weights": CLASS_WEIGHTS,
        "summary": {
            "total_rows": len(rows),
            "unresolved_count": len(unresolved),
            "by_state": by_state,
            "by_blocking_scope": by_scope,
            "top_n": top,
        },
        "br_ready_context": br_ready_context(br_ready),
        "unresolved": unresolved,
        "top": {
            "oldest": bounded_top(unresolved, top, lambda row: (-row["age_hours"], -row["score"], row["identity_key"])),
            "downstream_cost": bounded_top(unresolved, top, lambda row: (-row["downstream_cost"], -row["dependency_count"], -row["ship_cost"], -row["age_hours"], row["identity_key"])),
            "blocking_scope": bounded_top(unresolved, top, lambda row: (-row["score_components"]["blocking_scope"], row["rank_bucket"], -row["score"], row["identity_key"])),
            "actionability": bounded_top(unresolved, top, lambda row: (-row["score_components"]["actionability"], row["rank_bucket"], -row["score"], row["identity_key"])),
        },
    }


def info() -> dict[str, Any]:
    return {
        "name": "wire-or-explain-ranker",
        "surface": SURFACE,
        "schema_version": VERSION,
        "class_weights": CLASS_WEIGHTS,
        "weight_notes": [
            "fleet blocking scope gets the first rank bucket",
            "local rows outrank cross-orch rows unless the cross-orch row is fleet scoped",
            "skill_candidate rows use the same backlog and route to skillos",
            "br ready JSON is optional context and never required for ranking",
        ],
    }


def doctor(args: argparse.Namespace) -> tuple[dict[str, Any], int]:
    errors: list[dict[str, Any]] = []
    path = Path(args.ledger)
    if path.exists() and args.stale_hours >= 0:
        age_hours = (datetime.now(timezone.utc).timestamp() - path.stat().st_mtime) / 3600
        if age_hours > args.stale_hours:
            errors.append({"reason_code": "ledger_stale", "age_hours": round(age_hours, 3), "stale_hours": args.stale_hours})
    try:
        ranked = rank(path, top=args.top, now_text=args.now, br_ready=args.br_ready, local_session=args.local_session, local_repo=args.local_repo)
    except RankerError as exc:
        errors.append({"reason_code": exc.reason_code, "message": str(exc)})
        return {"schema_version": VERSION, "surface": SURFACE, "command": "doctor", "status": "error", "errors": errors}, 1
    status = "error" if errors else "pass"
    return {
        "schema_version": VERSION,
        "surface": SURFACE,
        "command": "doctor",
        "status": status,
        "errors": errors,
        "unresolved_count": ranked["summary"]["unresolved_count"],
        "top_actions": ranked["unresolved"][: args.top],
    }, 1 if errors else 0


def schema() -> dict[str, Any]:
    return {
        "schema_version": "wire-or-explain-ranker/schema/v1",
        "required_output_fields": ["schema_version", "surface", "status", "class_weights", "summary", "unresolved", "top"],
        "top_slices": ["oldest", "downstream_cost", "blocking_scope", "actionability"],
    }

def validate(args: argparse.Namespace) -> tuple[dict[str, Any], int]:
    if not args.ledger:
        return {
            "schema_version": VERSION,
            "surface": SURFACE,
            "command": "validate",
            "success": False,
            "status": "usage_error",
            "reason_code": "ledger_required",
        }, 2
    try:
        rows = read_rows(Path(args.ledger))
    except RankerError as exc:
        return {"schema_version": VERSION, "surface": SURFACE, "command": "validate", "success": False, "status": "fail", "reason_code": exc.reason_code, "message": str(exc)}, 1
    missing_identity = [idx for idx, row in enumerate(rows, 1) if not meaningful(row.get("identity_key") or row.get("row_id") or row.get("target"))]
    success = not missing_identity
    return {
        "schema_version": VERSION,
        "surface": SURFACE,
        "command": "validate",
        "success": success,
        "status": "pass" if success else "fail",
        "ledger": args.ledger,
        "row_count": len(rows),
        "checks": [
            {"name": "ledger_readable", "status": "pass"},
            {"name": "rank_identity_available", "status": "pass" if success else "fail", "missing_rows": missing_identity[:10]},
        ],
    }, 0 if success else 1


def audit(args: argparse.Namespace) -> tuple[dict[str, Any], int]:
    if not args.ledger:
        return {"schema_version": VERSION, "surface": SURFACE, "command": "audit", "success": False, "status": "usage_error", "reason_code": "ledger_required"}, 2
    try:
        rows = read_rows(Path(args.ledger))
    except RankerError as exc:
        return {"schema_version": VERSION, "surface": SURFACE, "command": "audit", "success": False, "status": "fail", "reason_code": exc.reason_code, "message": str(exc)}, 1
    recent = [
        {
            "identity_key": row.get("identity_key") or row.get("row_id") or row.get("target"),
            "timestamp": row.get("timestamp"),
            "state": row.get("state"),
            "artifact_class": row.get("artifact_class"),
            "blocking_scope": row.get("blocking_scope"),
            "consumer": row.get("consumer"),
        }
        for row in rows[-args.limit :]
    ]
    return {"schema_version": VERSION, "surface": SURFACE, "command": "audit", "success": True, "status": "pass", "ledger": args.ledger, "row_count": len(rows), "recent": recent}, 0


def repair(args: argparse.Namespace) -> tuple[dict[str, Any], int]:
    if args.apply and not args.idempotency_key:
        return {"schema_version": VERSION, "surface": SURFACE, "command": "repair", "success": False, "status": "blocked", "reason_code": "apply_requires_idempotency_key"}, 4
    if not args.ledger:
        return {
            "schema_version": VERSION,
            "surface": SURFACE,
            "command": "repair",
            "success": False,
            "status": "dry_run",
            "scope": args.scope,
            "dry_run": not args.apply,
            "planned_actions": [{"action": "provide_ledger", "reason_code": "ledger_required_for_repair_probe"}],
            "actual_actions": [],
            "would_write": [],
            "would_delete": [],
            "would_call_external": [],
            "blocked_by": ["ledger_required"],
        }, 2
    try:
        ranked = rank(Path(args.ledger), top=args.top, now_text=args.now, br_ready=args.br_ready, local_session=args.local_session, local_repo=args.local_repo)
    except RankerError as exc:
        return {"schema_version": VERSION, "surface": SURFACE, "command": "repair", "success": False, "status": "fail", "reason_code": exc.reason_code, "message": str(exc)}, 1
    planned = [
        {
            "action": row["route"]["action"],
            "identity_key": row["identity_key"],
            "target": row["route"]["target"],
            "score": row["score"],
        }
        for row in ranked["unresolved"][: args.top]
    ]
    return {
        "schema_version": VERSION,
        "surface": SURFACE,
        "command": "repair",
        "success": True,
        "status": "applied" if args.apply else "dry_run",
        "scope": args.scope,
        "dry_run": not args.apply,
        "explain": args.explain,
        "idempotency_key": args.idempotency_key,
        "planned_actions": planned,
        "actual_actions": [] if not args.apply else [{"action": "no_mutation", "reason": "ranker repair emits route plan only"}],
        "would_write": [],
        "would_delete": [],
        "would_call_external": [],
        "blocked_by": [],
    }, 0


def add_output_flags(sp: argparse.ArgumentParser) -> None:
    sp.add_argument("--json", action="store_true", default=argparse.SUPPRESS)
    sp.add_argument("--no-color", action="store_true", default=argparse.SUPPRESS)
    sp.add_argument("--no-emoji", action="store_true", default=argparse.SUPPRESS)
    sp.add_argument("--width", type=int, default=argparse.SUPPRESS)


def add_rank_context(sp: argparse.ArgumentParser, *, ledger_required: bool) -> None:
    sp.add_argument("--ledger", required=ledger_required)
    sp.add_argument("--top", type=int, default=5)
    sp.add_argument("--now")
    sp.add_argument("--br-ready")
    sp.add_argument("--local-session", default="flywheel")
    sp.add_argument("--local-repo", default=DEFAULT_REPO)
    add_output_flags(sp)


def parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description=f"{SURFACE}: rank unresolved wire-or-explain ledger rows")
    p.add_argument("--info", action="store_true")
    add_output_flags(p)
    sub = p.add_subparsers(dest="command")
    for name in ("rank", "doctor", "health"):
        sp = sub.add_parser(name)
        add_rank_context(sp, ledger_required=True)
        if name in {"doctor", "health"}:
            sp.add_argument("--stale-hours", type=float, default=168)
    why = sub.add_parser("why")
    why.add_argument("identity_key")
    why.add_argument("--ledger", required=True)
    why.add_argument("--now")
    why.add_argument("--local-session", default="flywheel")
    why.add_argument("--local-repo", default=DEFAULT_REPO)
    add_output_flags(why)
    for name in ("validate", "audit", "repair"):
        sp = sub.add_parser(name)
        add_rank_context(sp, ledger_required=False)
        sp.add_argument("--dry-run", action="store_true")
        sp.add_argument("--apply", action="store_true")
        sp.add_argument("--scope", default="ranker")
        sp.add_argument("--idempotency-key")
        sp.add_argument("--explain", action="store_true")
        sp.add_argument("--limit", type=int, default=10)
    schema_p = sub.add_parser("schema")
    schema_p.add_argument("schema_command", nargs="?", default="rank")
    add_output_flags(schema_p)
    quickstart_p = sub.add_parser("quickstart")
    add_output_flags(quickstart_p)
    comp = sub.add_parser("completion")
    comp.add_argument("shell", nargs="?", default="bash", choices=["bash", "zsh"])
    help_cmd = sub.add_parser("help")
    help_cmd.add_argument("topic", nargs="?", default="ranker")
    add_output_flags(help_cmd)
    return p


def main(argv: list[str]) -> int:
    args = parser().parse_args(argv)
    for attr, default in (("json", False), ("no_color", False), ("no_emoji", False), ("width", None)):
        if not hasattr(args, attr):
            setattr(args, attr, default)
    if args.info:
        data = info()
        data["commands"] = ["rank", "doctor", "health", "validate", "audit", "why", "repair", "schema", "quickstart", "completion"]
        data["output_controls"] = ["--json", "--no-color", "--no-emoji", "--width"]
        return emit(data)
    if args.command in (None, "rank"):
        if not getattr(args, "ledger", None):
            return emit({"schema_version": VERSION, "surface": SURFACE, "status": "error", "reason_code": "ledger_required"}, 2)
        try:
            return emit(rank(Path(args.ledger), top=args.top, now_text=args.now, br_ready=args.br_ready, local_session=args.local_session, local_repo=args.local_repo))
        except RankerError as exc:
            return emit({"schema_version": VERSION, "surface": SURFACE, "status": "error", "reason_code": exc.reason_code, "message": str(exc)}, 1)
    if args.command in {"doctor", "health"}:
        data, rc = doctor(args)
        if args.command == "health":
            data["command"] = "health"
            data["status"] = "healthy" if rc == 0 else "degraded"
        return emit(data, rc)
    if args.command == "why":
        try:
            ranked = rank(Path(args.ledger), top=9999, now_text=args.now, br_ready=None, local_session=args.local_session, local_repo=args.local_repo)
        except RankerError as exc:
            return emit({"schema_version": VERSION, "surface": SURFACE, "status": "error", "reason_code": exc.reason_code, "message": str(exc)}, 1)
        hit = next((row for row in ranked["unresolved"] if row["identity_key"] == args.identity_key), None)
        return emit({"schema_version": VERSION, "surface": SURFACE, "found": hit is not None, "row": hit})
    if args.command == "schema":
        return emit(schema())
    if args.command == "quickstart":
        return emit({
            "surface": SURFACE,
            "commands": [
                "wire-or-explain-ranker.py --info --json",
                "wire-or-explain-ranker.py rank --ledger ledger.jsonl --json",
                "wire-or-explain-ranker.py validate --ledger ledger.jsonl --json",
                "wire-or-explain-ranker.py repair --ledger ledger.jsonl --dry-run --json",
            ],
        })
    if args.command == "validate":
        data, rc = validate(args)
        return emit(data, rc)
    if args.command == "audit":
        data, rc = audit(args)
        return emit(data, rc)
    if args.command == "repair":
        data, rc = repair(args)
        return emit(data, rc)
    if args.command == "completion":
        commands = "rank doctor health validate audit why repair schema quickstart completion help"
        flags = "--ledger --top --now --br-ready --local-session --local-repo --stale-hours --json --no-color --no-emoji --width --dry-run --apply --scope --idempotency-key --explain --limit --info"
        if args.shell == "zsh":
            print(f"#compdef {Path(sys.argv[0]).name}")
            print("local -a commands")
            print(f"commands=({commands})")
            print("_describe 'command' commands")
            print(f"compadd -- {flags}")
        else:
            print(f"complete -W '{commands} {flags}' {Path(sys.argv[0]).name}")
        return 0
    if args.command == "help":
        return emit({"surface": SURFACE, "topic": args.topic, "commands": ["rank", "doctor", "health", "validate", "audit", "why", "repair", "schema", "quickstart", "completion"]})
    return 2


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
