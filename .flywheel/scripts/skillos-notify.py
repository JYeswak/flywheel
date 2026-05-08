#!/usr/bin/env python3
"""Notify skillos about fleet skill discoveries and maintain thread state."""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCHEMA_VERSION = "skillos-notify/v1"
THREAD_SCHEMA_VERSION = "skill-discovery-thread/v1"
CANONICAL_NTM = Path("/Users/josh/.local/bin/ntm")
DEFAULT_TOPOLOGY = Path("~/.local/state/flywheel/session-topology.jsonl").expanduser()
DEFAULT_THREAD_STATE = Path("~/.local/state/flywheel/skill-discovery-threads.jsonl").expanduser()


SECRET_PATTERNS: list[tuple[str, re.Pattern[str]]] = [
    ("anthropic_key", re.compile(r"sk-ant-[A-Za-z0-9._-]+")),
    ("openai_key", re.compile(r"sk-(?:proj-)?[A-Za-z0-9._-]{20,}")),
    ("xai_key", re.compile(r"xai-[A-Za-z0-9._-]+")),
    ("github_token", re.compile(r"gh(?:p|o|u|s|r|_pat)_[A-Za-z0-9_]+")),
    ("bearer_token", re.compile(r"Bearer\s+[A-Za-z0-9._-]+", re.IGNORECASE)),
    ("agent_mail_token_field", re.compile(r"(registration_token|bearer_token|sender_token)\s*[:=]\s*[A-Za-z0-9._-]+", re.IGNORECASE)),
    ("near_secret_keyword", re.compile(r"(?i)(token|secret|password|api_key|apikey)\s*[:=]\s*[A-Za-z0-9._/-]{16,}")),
]


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


def now_utc() -> datetime:
    return datetime.now(timezone.utc)


def isoformat(value: datetime) -> str:
    return value.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")


def redact(text: str) -> tuple[str, int, list[str]]:
    redacted = text
    classes: list[str] = []
    count = 0
    for name, pattern in SECRET_PATTERNS:
        redacted, changed = pattern.subn(f"[SCRUBBED:{name}]", redacted)
        if changed:
            count += changed
            classes.append(name)
    return redacted, count, sorted(set(classes))


def normalize_candidate(value: str) -> str:
    return re.sub(r"\s+", " ", value.strip())


def slugify(value: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "-", value.lower()).strip("-")
    return slug or "unnamed"


def read_jsonl(path: Path) -> list[dict[str, Any]]:
    if not path.exists():
        return []
    rows: list[dict[str, Any]] = []
    with path.open("r", encoding="utf-8") as handle:
        for line in handle:
            line = line.strip()
            if not line:
                continue
            try:
                value = json.loads(line)
            except json.JSONDecodeError:
                continue
            if isinstance(value, dict):
                rows.append(value)
    return rows


def latest_skillos_target(topology_path: Path) -> tuple[dict[str, Any] | None, str | None]:
    rows = [row for row in read_jsonl(topology_path) if row.get("session") == "skillos"]
    if not rows:
        return None, "skillos_topology_missing"
    rows.sort(key=lambda row: str(row.get("effective_at", row.get("ts", ""))), reverse=True)
    for row in rows:
        pane = row.get("orchestrator_pane") or row.get("callback_pane")
        if pane is None and isinstance(row.get("orchestrator"), dict):
            pane = row["orchestrator"].get("pane")
        if pane is None:
            continue
        try:
            pane_int = int(pane)
        except (TypeError, ValueError):
            continue
        return {
            "session": "skillos",
            "pane": pane_int,
            "effective_at": row.get("effective_at"),
            "source": str(topology_path),
        }, None
    return None, "skillos_topology_missing_pane"


def load_discovery(path: Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise ValueError("discovery_json_must_be_object")
    return payload


def latest_thread_record(thread_state: Path, thread_key: str) -> dict[str, Any] | None:
    records = [row for row in read_jsonl(thread_state) if row.get("thread_key") == thread_key]
    if not records:
        return None
    records.sort(key=lambda row: str(row.get("ts", "")), reverse=True)
    return records[0]


def append_jsonl(path: Path, row: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(row, sort_keys=True, separators=(",", ":")) + "\n")


def thread_plan(thread_state: Path, thread_key: str, thread_id: str, args: argparse.Namespace, now: datetime) -> dict[str, Any]:
    last_record = latest_thread_record(thread_state, thread_key)
    archive_reason = None
    if args.skill_shipped:
        archive_reason = "skill_shipped"
    elif args.last_sighting_age_days is not None and args.last_sighting_age_days >= 30:
        archive_reason = "last_sighting_age_days_gte_30"

    if archive_reason:
        return {
            "thread_key": thread_key,
            "thread_id": thread_id,
            "action": "archive",
            "archived": True,
            "archive_reason": archive_reason,
            "existing": last_record is not None,
            "last_sighting_age_days": args.last_sighting_age_days,
            "state_row": {
                "schema_version": THREAD_SCHEMA_VERSION,
                "ts": isoformat(now),
                "thread_key": thread_key,
                "thread_id": thread_id,
                "candidate_skill_name": args.candidate_skill_name,
                "action": "archive",
                "archived": True,
                "archive_reason": archive_reason,
            },
        }

    action = "reuse" if last_record is not None and not last_record.get("archived") else "create"
    return {
        "thread_key": thread_key,
        "thread_id": thread_id,
        "action": action,
        "archived": False,
        "archive_reason": None,
        "existing": last_record is not None,
        "state_row": {
            "schema_version": THREAD_SCHEMA_VERSION,
            "ts": isoformat(now),
            "thread_key": thread_key,
            "thread_id": thread_id,
            "candidate_skill_name": args.candidate_skill_name,
            "action": "create",
            "archived": False,
        },
    }


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Send token-safe skill-discovery notifications to skillos and track deterministic Agent Mail thread keys.",
        epilog=(
            "Dry-run is default. Apply mode sends with /Users/josh/.local/bin/ntm unless "
            "FLYWHEEL_ALLOW_TEST_NTM=1 is set for fixture tests. Agent Mail tokens are never printed; "
            "thread state records carry deterministic keys only."
        ),
    )
    parser.add_argument("--discovery-json")
    parser.add_argument("--candidate-skill-name")
    parser.add_argument("--discovery-id")
    parser.add_argument("--source-session", default="unknown")
    parser.add_argument("--message-note", default="")
    parser.add_argument("--topology", default=str(DEFAULT_TOPOLOGY))
    parser.add_argument("--thread-state", default=str(DEFAULT_THREAD_STATE))
    parser.add_argument("--discovery-ledger")
    parser.add_argument("--now")
    parser.add_argument("--dry-run", action="store_true", default=True)
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--ntm-bin", default=str(CANONICAL_NTM))
    parser.add_argument("--skill-shipped", action="store_true")
    parser.add_argument("--last-sighting-age-days", type=float)
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    now = parse_ts(args.now) if args.now else now_utc()
    if now is None:
        print(json.dumps({"schema_version": SCHEMA_VERSION, "status": "error", "reason": "invalid_now"}))
        return 2

    if args.discovery_json:
        row = load_discovery(Path(args.discovery_json).expanduser())
        args.candidate_skill_name = args.candidate_skill_name or row.get("candidate_skill_name")
        args.discovery_id = args.discovery_id or row.get("discovery_id")
        args.source_session = args.source_session if args.source_session != "unknown" else str(row.get("session", "unknown"))

    if not args.candidate_skill_name or not args.discovery_id:
        print(json.dumps({"schema_version": SCHEMA_VERSION, "status": "error", "reason": "candidate_and_discovery_required"}))
        return 2

    args.candidate_skill_name = normalize_candidate(str(args.candidate_skill_name))
    raw_context = f"{args.candidate_skill_name} {args.discovery_id} {args.source_session} {args.message_note}"
    safe_context, scrub_count, scrub_classes = redact(raw_context)
    safe_candidate, _, _ = redact(args.candidate_skill_name)
    safe_discovery_id, _, _ = redact(str(args.discovery_id))
    safe_source, _, _ = redact(str(args.source_session))
    safe_note, _, _ = redact(str(args.message_note))

    thread_key = f"[skill-discovery] {safe_candidate}"
    thread_id = f"skill-discovery:{slugify(safe_candidate)}"
    thread_state = Path(args.thread_state).expanduser()
    topology = Path(args.topology).expanduser()
    target, target_error = latest_skillos_target(topology)

    agent_mail_thread = thread_plan(thread_state, thread_key, thread_id, args, now)
    message = (
        f"Discovery {safe_discovery_id} from {safe_source}: "
        f"candidate={safe_candidate}; thread={thread_key}; action={agent_mail_thread['action']}."
    )
    if safe_note:
        message = f"{message} note={safe_note}"
    message, msg_scrubs, msg_classes = redact(message)
    scrub_count += msg_scrubs
    scrub_classes = sorted(set(scrub_classes + msg_classes))

    base = {
        "schema_version": SCHEMA_VERSION,
        "dry_run": not args.apply,
        "candidate_skill_name": safe_candidate,
        "discovery_id": safe_discovery_id,
        "source_session": safe_source,
        "message": message,
        "agent_mail_thread": {key: value for key, value in agent_mail_thread.items() if key != "state_row"},
        "token_safety": {
            "scrubbed": scrub_count > 0,
            "raw_token_patterns_found": scrub_count,
            "scrub_classes": scrub_classes,
            "agent_mail_token_echo": False,
        },
        "mutations": {
            "ntm_sent": False,
            "thread_state_appended": False,
            "discoveries_mutated": False,
            "agent_mail_token_echo": False,
        },
    }

    if target is None:
        base.update(
            {
                "status": "skillos_target_unavailable",
                "reason": target_error,
                "target": None,
                "row_left_intact": True,
            }
        )
        print(json.dumps(base, indent=2 if args.json else None, sort_keys=True))
        return 0

    ntm_argv = [str(Path(args.ntm_bin)), "send", target["session"], f"--pane={target['pane']}", message]
    base.update({"target": target, "ntm_argv": ntm_argv})

    if args.apply:
        if Path(args.ntm_bin) != CANONICAL_NTM and os.environ.get("FLYWHEEL_ALLOW_TEST_NTM") != "1":
            base.update({"status": "error", "reason": "ntm_bin_must_be_canonical_absolute_path"})
            print(json.dumps(base, indent=2 if args.json else None, sort_keys=True))
            return 2
        if agent_mail_thread["action"] in {"create", "archive"}:
            append_jsonl(thread_state, agent_mail_thread["state_row"])
            base["mutations"]["thread_state_appended"] = True
        proc = subprocess.run(ntm_argv, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
        base["mutations"]["ntm_sent"] = proc.returncode == 0
        base["ntm_returncode"] = proc.returncode
        base["status"] = "sent" if proc.returncode == 0 else "ntm_send_failed"
        if proc.returncode != 0:
            base["ntm_error"] = redact(proc.stderr.strip())[0]
            print(json.dumps(base, indent=2 if args.json else None, sort_keys=True))
            return 1
    else:
        base["status"] = "dry_run"

    print(json.dumps(base, indent=2 if args.json else None, sort_keys=True))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
