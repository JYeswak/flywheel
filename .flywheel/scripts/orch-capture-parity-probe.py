#!/usr/bin/env python3
"""Read-only Joshua-input capture parity probe for orchestrator runtimes."""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import urllib.parse
from collections import defaultdict
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any


SCHEMA_VERSION = "orch-capture-parity/v1"
ACTIVE_CAPTURE_OWNER_BEAD = "flywheel-vk9ox"
ORIGINAL_CAPTURE_MECHANISM_BEAD = "flywheel-xap2"
NON_HUMAN_TRANSCRIPT_PREFIXES = (
    "<command-name>",
    "<command-message>",
    "<task-notification>",
    "Blocker tick watcher fired",
    "CODEX_WATCHTOWER_",
    "PHASE3_FLEET_BROADCAST",
    "This session is being continued from a previous conversation",
)
APPROVED_REMEDIATION_TRACKS = [
    {
        "track": "primary_agent_mail_cross_orch_route",
        "owner_bead": ACTIVE_CAPTURE_OWNER_BEAD,
        "supersedes_owner_bead": ORIGINAL_CAPTURE_MECHANISM_BEAD,
        "mutates": False,
        "note": "Capture Joshua-originated cross-orch input as canonical josh-request rows through the durable coordination channel.",
    },
    {
        "track": "secondary_ntm_send_wrapper_capture",
        "owner_bead": ACTIVE_CAPTURE_OWNER_BEAD,
        "supersedes_owner_bead": ORIGINAL_CAPTURE_MECHANISM_BEAD,
        "mutates": False,
        "note": "Wrap dispatch sends so prompt_hash/source_session/source_pane are captured before pane delivery.",
    },
    {
        "track": "tertiary_pane_tail_poller",
        "owner_bead": ACTIVE_CAPTURE_OWNER_BEAD,
        "supersedes_owner_bead": ORIGINAL_CAPTURE_MECHANISM_BEAD,
        "mutates": False,
        "fragility_note": "Only acceptable with explicit fragility note; pane scrollback alone is not capture proof.",
    },
]


def utc_now() -> datetime:
    return datetime.now(timezone.utc).replace(microsecond=0)


def parse_ts(value: Any) -> datetime | None:
    if not value:
        return None
    text = str(value)
    try:
        if text.endswith("Z"):
            text = text[:-1] + "+00:00"
        parsed = datetime.fromisoformat(text)
        if parsed.tzinfo is None:
            parsed = parsed.replace(tzinfo=timezone.utc)
        return parsed.astimezone(timezone.utc)
    except Exception:
        return None


def ts_text(value: datetime | None) -> str | None:
    if value is None:
        return None
    return value.astimezone(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def read_jsonl(path: Path) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    if not path.exists():
        return rows
    for line in path.read_text(errors="replace").splitlines():
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except json.JSONDecodeError:
            continue
        if isinstance(row, dict):
            rows.append(row)
    return rows


def read_json(path: Path) -> dict[str, Any] | None:
    if not path.exists():
        return None
    try:
        data = json.loads(path.read_text(errors="replace"))
    except json.JSONDecodeError:
        return None
    return data if isinstance(data, dict) else None


def read_json_array(path: Path) -> list[dict[str, Any]]:
    if not path.exists():
        return []
    try:
        data = json.loads(path.read_text(errors="replace"))
    except json.JSONDecodeError:
        return []
    if not isinstance(data, list):
        return []
    return [item for item in data if isinstance(item, dict)]


def claude_project_dir_for_repo(projects_root: Path, repo_path: Any) -> Path | None:
    text = str(repo_path or "").strip()
    if not text.startswith("/"):
        return None
    candidates = [projects_root / text.replace("/", "-")]
    try:
        resolved = str(Path(text).resolve())
    except OSError:
        resolved = text
    resolved_candidate = projects_root / resolved.replace("/", "-")
    if resolved_candidate not in candidates:
        candidates.append(resolved_candidate)
    for candidate in candidates:
        if candidate.exists():
            return candidate
    return candidates[0]


def prompt_text_from_transcript_row(row: dict[str, Any]) -> str | None:
    if row.get("type") != "user":
        return None
    message = row.get("message")
    if not isinstance(message, dict) or message.get("role") != "user":
        return None
    content = message.get("content")
    if not isinstance(content, str):
        return None
    stripped = content.strip()
    if "<local-command-caveat>" in content or "<local-command-stdout>" in content:
        return None
    if any(stripped.startswith(prefix) for prefix in NON_HUMAN_TRANSCRIPT_PREFIXES):
        return None
    return stripped


def latest_claude_prompt_for_repo(projects_root: Path, repo_path: Any) -> dict[str, Any] | None:
    project_dir = claude_project_dir_for_repo(projects_root, repo_path)
    if project_dir is None or not project_dir.exists():
        return None
    latest: dict[str, Any] | None = None
    latest_ts: datetime | None = None
    for transcript in sorted(project_dir.glob("*.jsonl")):
        try:
            lines = transcript.read_text(errors="replace").splitlines()
        except OSError:
            continue
        for line in lines:
            if not line.strip():
                continue
            try:
                row = json.loads(line)
            except json.JSONDecodeError:
                continue
            if not isinstance(row, dict) or row.get("isSidechain") is True:
                continue
            text = prompt_text_from_transcript_row(row)
            if text is None:
                continue
            ts = parse_ts(row.get("timestamp"))
            if ts is None:
                continue
            if latest_ts is None or ts > latest_ts:
                latest_ts = ts
                latest = {
                    "timestamp": ts_text(ts),
                    "source_message_id": row.get("uuid") or row.get("message_id") or row.get("sessionId"),
                    "transcript_path": str(transcript),
                    "excerpt": " ".join(text.split())[:240],
                }
    return latest


def user_prompt_submit_hook_registered(settings: dict[str, Any] | None) -> bool:
    if not settings:
        return False
    hooks = settings.get("hooks")
    if not isinstance(hooks, dict):
        return False
    groups = hooks.get("UserPromptSubmit")
    if not isinstance(groups, list):
        return False
    for group in groups:
        if not isinstance(group, dict):
            continue
        for hook in group.get("hooks") or []:
            if not isinstance(hook, dict):
                continue
            command = str(hook.get("command") or "")
            if "josh-request-capture.sh" in command:
                return True
    return False


def path_from_wezterm_cwd(value: Any) -> str:
    text = str(value or "")
    if text.startswith("file://"):
        parsed = urllib.parse.urlparse(text)
        return urllib.parse.unquote(parsed.path)
    return text


def wezterm_matches_session(pane: dict[str, Any], session: str) -> bool:
    session_lc = session.lower()
    title = str(pane.get("title") or pane.get("window_title") or "").lower()
    tab_title = str(pane.get("tab_title") or "").lower()
    cwd = path_from_wezterm_cwd(pane.get("cwd")).lower()
    return (
        session_lc in title
        or session_lc in tab_title
        or cwd.endswith(f"/{session_lc}")
        or f"/{session_lc}/" in cwd
        or (session_lc == "flywheel" and ("/.flywheel" in cwd or ".flywheel" in title))
    )


def summarize_wezterm_pane(pane: dict[str, Any]) -> dict[str, Any]:
    return {
        "pane_id": pane.get("pane_id"),
        "window_id": pane.get("window_id"),
        "tab_id": pane.get("tab_id"),
        "title": pane.get("title") or pane.get("window_title") or "",
        "cwd": path_from_wezterm_cwd(pane.get("cwd")),
        "tty_name": pane.get("tty_name"),
        "is_active": bool(pane.get("is_active")),
    }


def load_wezterm_panes(path: Path | None, *, enabled: bool, timeout_seconds: float) -> tuple[str, list[dict[str, Any]], list[dict[str, Any]]]:
    if path is not None:
        return ("fixture", read_json_array(path), [])
    if not enabled:
        return ("disabled", [], [])
    try:
        proc = subprocess.run(
            ["wezterm", "cli", "list", "--format", "json"],
            check=False,
            capture_output=True,
            text=True,
            timeout=timeout_seconds,
        )
    except FileNotFoundError:
        return (
            "unavailable",
            [],
            [{"code": "wezterm_unavailable", "message": "wezterm binary not found"}],
        )
    except subprocess.TimeoutExpired:
        return (
            "timeout",
            [],
            [{"code": "wezterm_list_timeout", "message": "wezterm cli list timed out"}],
        )
    if proc.returncode != 0:
        return (
            "error",
            [],
            [{"code": "wezterm_list_failed", "message": (proc.stderr or "").strip()[:240]}],
        )
    try:
        data = json.loads(proc.stdout)
    except json.JSONDecodeError:
        return (
            "invalid_json",
            [],
            [{"code": "wezterm_list_invalid_json", "message": "wezterm cli list returned invalid JSON"}],
        )
    if not isinstance(data, list):
        return (
            "invalid_shape",
            [],
            [{"code": "wezterm_list_invalid_shape", "message": "wezterm cli list did not return an array"}],
        )
    return ("wezterm", [item for item in data if isinstance(item, dict)], [])


def latest_topology_rows(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    latest: dict[str, dict[str, Any]] = {}
    for row in rows:
        session = str(row.get("session") or "").strip()
        if not session:
            continue
        previous = latest.get(session)
        row_ts = parse_ts(row.get("effective_at") or row.get("ts"))
        prev_ts = parse_ts(previous.get("effective_at") or previous.get("ts")) if previous else None
        if previous is None or (row_ts or datetime.min.replace(tzinfo=timezone.utc)) >= (prev_ts or datetime.min.replace(tzinfo=timezone.utc)):
            latest[session] = row
    return [latest[key] for key in sorted(latest)]


def latest_team_roster_rows(rows: list[dict[str, Any]]) -> dict[str, dict[str, Any]]:
    latest: dict[str, dict[str, Any]] = {}
    for row in rows:
        session = str(row.get("session") or "").strip()
        if not session:
            continue
        previous = latest.get(session)
        row_ts = parse_ts(row.get("ts") or row.get("effective_at"))
        prev_ts = parse_ts(previous.get("ts") or previous.get("effective_at")) if previous else None
        if previous is None or (row_ts or datetime.min.replace(tzinfo=timezone.utc)) >= (prev_ts or datetime.min.replace(tzinfo=timezone.utc)):
            latest[session] = row
    return latest


def roster_orchestrator_value(row: dict[str, Any] | None, key: str) -> Any:
    if not row:
        return None
    orchestrator = row.get("orchestrator")
    if isinstance(orchestrator, dict):
        return orchestrator.get(key)
    return None


def roster_event(row: dict[str, Any] | None) -> str | None:
    if not row:
        return None
    value = row.get("event") or row.get("status")
    return str(value) if value else None


def roster_participation(row: dict[str, Any] | None) -> str:
    event = str(roster_event(row) or "").lower()
    if event in {"session_dormant", "dormant"}:
        return "dormant"
    if event in {"session_active", "active"}:
        return "active"
    return "unknown"


def runtime_for(row: dict[str, Any], roster_row: dict[str, Any] | None = None) -> str:
    return str(row.get("orchestrator_kind") or row.get("runtime") or row.get("kind") or roster_orchestrator_value(roster_row, "kind") or "unknown")


def pane_for(row: dict[str, Any], roster_row: dict[str, Any] | None = None) -> int | None:
    pane = row.get("orchestrator_pane")
    if pane is None:
        pane = roster_orchestrator_value(roster_row, "pane")
    try:
        return int(pane)
    except Exception:
        return None


def explicit_non_participating(row: dict[str, Any]) -> bool:
    value = row.get("capture_participation", row.get("orch_capture_participation"))
    if isinstance(value, bool):
        return value is False
    return str(value or "").lower() in {"non_participating", "none", "disabled", "false"}


def capture_rows_by_session(rows: list[dict[str, Any]]) -> dict[str, list[dict[str, Any]]]:
    grouped: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for row in rows:
        session = str(row.get("source_session") or row.get("session") or "").strip()
        if session:
            grouped[session].append(row)
    for session_rows in grouped.values():
        session_rows.sort(key=lambda item: parse_ts(item.get("captured_at") or item.get("ts")) or datetime.min.replace(tzinfo=timezone.utc))
    return grouped


def coord_ts_by_session(rows: list[dict[str, Any]]) -> dict[str, datetime]:
    by_session: dict[str, datetime] = {}
    keys = ("source_session", "session", "target_session", "origin_session", "sender")
    for row in rows:
        ts = parse_ts(row.get("ts") or row.get("created_at") or row.get("effective_at"))
        if ts is None:
            continue
        sessions = set()
        for key in keys:
            value = row.get(key)
            if not value:
                continue
            text = str(value)
            sessions.add(text.split(":", 1)[0])
        for session in sessions:
            if session and (session not in by_session or ts > by_session[session]):
                by_session[session] = ts
    return by_session


def duplicate_groups(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    grouped: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for row in rows:
        key = row.get("prompt_hash") or row.get("source_message_id")
        if key:
            grouped[str(key)].append(row)
    duplicates = []
    for key, items in grouped.items():
        if len(items) > 1:
            duplicates.append({"dedupe_key": key, "count": len(items), "ids": [item.get("id") for item in items]})
    return duplicates


def has_agent_context_evidence(row: dict[str, Any]) -> bool:
    refs = row.get("capture_evidence_refs") or row.get("evidence_refs") or []
    if isinstance(refs, str):
        refs = [refs]
    for ref in refs:
        text = json.dumps(ref, sort_keys=True) if isinstance(ref, dict) else str(ref)
        lowered = text.lower()
        if "agent_context" in lowered or "agent-context" in lowered or "callback" in lowered:
            return True
    return False


def has_pane_scrollback_only(row: dict[str, Any]) -> bool:
    values = [row.get("capture_path"), row.get("capture_proof"), row.get("capture_source")]
    refs = row.get("capture_evidence_refs") or row.get("evidence_refs") or []
    if isinstance(refs, list):
        values.extend(refs)
    elif refs:
        values.append(refs)
    text = " ".join(json.dumps(value, sort_keys=True) if isinstance(value, dict) else str(value) for value in values if value)
    lowered = text.lower()
    return "pane_scrollback" in lowered or "scrollback" in lowered or "tmux capture" in lowered


def latest_capture_ts(rows: list[dict[str, Any]]) -> datetime | None:
    values = [parse_ts(row.get("captured_at") or row.get("ts")) for row in rows]
    values = [value for value in values if value is not None]
    return max(values) if values else None


def capture_substrate_payload(
    *,
    settings_path: Path,
    request_path: Path,
    request_rows: list[dict[str, Any]],
    now: datetime,
    stale_cutoff: datetime,
) -> dict[str, Any]:
    settings = read_json(settings_path)
    latest_ts = latest_capture_ts(request_rows)
    warnings: list[dict[str, Any]] = []
    hook_registered = user_prompt_submit_hook_registered(settings)
    if not hook_registered:
        warnings.append(
            {
                "code": "claude_user_prompt_submit_capture_hook_missing",
                "message": "Claude UserPromptSubmit hook does not include josh-request-capture.sh",
            }
        )
    if not request_path.exists():
        warnings.append(
            {
                "code": "josh_requests_log_missing",
                "message": "canonical josh-requests JSONL log is missing",
            }
        )
    elif latest_ts is None:
        warnings.append(
            {
                "code": "josh_requests_log_empty_or_unparseable",
                "message": "canonical josh-requests JSONL log has no parseable capture timestamps",
            }
        )
    elif latest_ts < stale_cutoff:
        warnings.append(
            {
                "code": "josh_requests_log_stale",
                "message": "canonical josh-requests JSONL log has no fresh capture row",
            }
        )
    latest_age_hours = None
    if latest_ts is not None:
        latest_age_hours = round((now - latest_ts).total_seconds() / 3600, 3)
    return {
        "status": "warn" if warnings else "pass",
        "claude_settings_path": str(settings_path),
        "claude_settings_exists": settings_path.exists(),
        "claude_user_prompt_submit_hook_registered": hook_registered,
        "josh_requests_path": str(request_path),
        "josh_requests_log_exists": request_path.exists(),
        "latest_capture_ts": ts_text(latest_ts),
        "latest_capture_age_hours": latest_age_hours,
        "stale_after_hours": round((now - stale_cutoff).total_seconds() / 3600, 3),
        "warnings": warnings,
    }


def evidence_for_capture(path: Path, rows: list[dict[str, Any]]) -> list[str]:
    refs = []
    for row in rows[-3:]:
        row_id = row.get("id") or row.get("source_message_id") or row.get("prompt_hash")
        if row_id:
            refs.append(f"{path}#{row_id}")
    return refs


def classify_row(
    topo: dict[str, Any],
    *,
    request_path: Path,
    team_roster_path: Path,
    team_roster_row: dict[str, Any] | None,
    wezterm_panes: list[dict[str, Any]],
    latest_transcript_prompt: dict[str, Any] | None,
    capture_rows: list[dict[str, Any]],
    coord_seen_ts: datetime | None,
    stale_cutoff: datetime,
) -> dict[str, Any]:
    session = str(topo.get("session"))
    runtime = runtime_for(topo, team_roster_row)
    pane = pane_for(topo, team_roster_row)
    team_roster_event = roster_event(team_roster_row)
    team_roster_participation = roster_participation(team_roster_row)
    capture_ts = latest_capture_ts(capture_rows)
    latest_prompt_ts = parse_ts(latest_transcript_prompt.get("timestamp")) if latest_transcript_prompt else None
    matching_wezterm_panes = [summarize_wezterm_pane(pane) for pane in wezterm_panes if wezterm_matches_session(pane, session)]
    duplicate_rows = duplicate_groups(capture_rows)
    last_seen = max([ts for ts in [capture_ts, coord_seen_ts, latest_prompt_ts] if ts is not None], default=None)
    evidence_refs: list[str] = []
    capture_path: str | None = None
    state = "captured"
    gap_reason: str | None = None

    if team_roster_participation == "dormant":
        state = "non_participating"
        gap_reason = "team_roster_session_dormant"
        capture_path = None
        evidence_refs = [f"{team_roster_path}:session={session};event={team_roster_event}"]
    elif explicit_non_participating(topo):
        state = "non_participating"
        gap_reason = str(topo.get("capture_non_participation_reason") or "explicit_non_participating")
        capture_path = None
        evidence_refs = [str(topo.get("capture_evidence_ref") or "topology:capture_participation=non_participating")]
    elif capture_rows:
        state = "captured"
        capture_path = str(request_path)
        evidence_refs = evidence_for_capture(request_path, capture_rows)
        if capture_ts is not None and latest_prompt_ts is not None and latest_prompt_ts > capture_ts:
            state = "stale_capture"
            gap_reason = "latest_transcript_prompt_uncaptured"
            prompt_ref = latest_transcript_prompt.get("transcript_path")
            prompt_id = latest_transcript_prompt.get("source_message_id")
            if prompt_ref and prompt_id:
                evidence_refs.append(f"{prompt_ref}#{prompt_id}")
        elif capture_ts is not None and capture_ts < stale_cutoff and latest_prompt_ts is not None and capture_ts >= latest_prompt_ts:
            gap_reason = "no_new_prompt_since_capture"
        elif capture_ts is not None and capture_ts < stale_cutoff:
            state = "stale_capture"
            gap_reason = "stale_capture_row"
        elif duplicate_rows:
            gap_reason = "duplicate_capture_rows_non_blocking"
    elif runtime == "codex" and has_agent_context_evidence(topo):
        state = "captured"
        capture_path = str(topo.get("capture_path") or "agent_context_callback")
        evidence_refs = [str(ref) for ref in (topo.get("capture_evidence_refs") or topo.get("evidence_refs") or [])]
        capture_ts = parse_ts(topo.get("capture_ts") or topo.get("effective_at") or topo.get("ts"))
    else:
        state = "capture_gap"
        capture_path = str(topo.get("capture_path") or "") or None
        if has_pane_scrollback_only(topo):
            gap_reason = "pane_scrollback_not_canonical_capture"
        else:
            gap_reason = "missing_canonical_capture"
        evidence_refs = [f"{request_path}:no row for source_session={session}"]

    return {
        "session": session,
        "pane": pane,
        "runtime": runtime,
        "participation_state": state,
        "capture_path": capture_path,
        "last_capture_ts": ts_text(capture_ts),
        "latest_transcript_prompt_ts": ts_text(latest_prompt_ts),
        "latest_transcript_prompt": latest_transcript_prompt,
        "last_josh_input_seen_ts": ts_text(last_seen),
        "gap_reason": gap_reason,
        "evidence_refs": evidence_refs,
        "duplicate_capture_groups": duplicate_rows,
        "team_roster_event": team_roster_event,
        "team_roster_participation": team_roster_participation,
        "wezterm_live": bool(matching_wezterm_panes),
        "wezterm_panes": matching_wezterm_panes,
        "remediation_options": APPROVED_REMEDIATION_TRACKS if state in {"capture_gap", "stale_capture"} else [],
    }


def schema_payload() -> dict[str, Any]:
    return {
        "schema_version": SCHEMA_VERSION,
        "row_required_fields": [
            "session",
            "pane",
            "runtime",
            "participation_state",
            "capture_path",
            "last_capture_ts",
            "latest_transcript_prompt_ts",
            "latest_transcript_prompt",
            "last_josh_input_seen_ts",
            "gap_reason",
            "evidence_refs",
            "team_roster_event",
            "team_roster_participation",
            "wezterm_live",
            "wezterm_panes",
        ],
        "participation_state_enum": ["captured", "capture_gap", "stale_capture", "non_participating"],
        "gap_reason_examples": [
            "missing_canonical_capture",
            "pane_scrollback_not_canonical_capture",
            "stale_capture_row",
            "latest_transcript_prompt_uncaptured",
            "no_new_prompt_since_capture",
            "duplicate_capture_rows",
            "team_roster_session_dormant",
        ],
    }


def examples_payload() -> dict[str, Any]:
    return {
        "schema_version": SCHEMA_VERSION,
        "active_owner_bead": ACTIVE_CAPTURE_OWNER_BEAD,
        "original_mechanism_bead": ORIGINAL_CAPTURE_MECHANISM_BEAD,
        "examples": [
            "orch-capture-parity-probe.py --json",
            "orch-capture-parity-probe.py --topology fixtures/topology.jsonl --josh-requests fixtures/josh-requests.jsonl --doctor --json",
            "orch-capture-parity-probe.py --schema --json",
        ],
        "xap2_boundary": f"This probe defines the rule/signal contract; {ORIGINAL_CAPTURE_MECHANISM_BEAD} shipped the first capture mechanism.",
        "active_owner_boundary": f"{ACTIVE_CAPTURE_OWNER_BEAD} owns live duplicate/missing capture cleanup until the probe is green.",
    }


def main() -> int:
    parser = argparse.ArgumentParser(prog="orch-capture-parity-probe")
    parser.add_argument("--topology", default=os.environ.get("FLYWHEEL_SESSION_TOPOLOGY", "~/.local/state/flywheel/session-topology.jsonl"))
    parser.add_argument("--josh-requests", default=os.environ.get("FLYWHEEL_JOSH_REQUESTS_LOG", "~/.local/state/flywheel/josh-requests.jsonl"))
    parser.add_argument("--coordination-log", default=os.environ.get("FLYWHEEL_CROSS_ORCH_COORDINATION_LOG", "~/.local/state/flywheel/cross-orch-coordination.jsonl"))
    parser.add_argument("--team-roster", default=os.environ.get("TEAM_ROSTER", "~/.local/state/flywheel/team-roster.jsonl"))
    parser.add_argument("--claude-settings", default=os.environ.get("FLYWHEEL_CLAUDE_SETTINGS", "~/.claude/settings.json"))
    parser.add_argument("--claude-projects-root", default=os.environ.get("FLYWHEEL_CLAUDE_PROJECTS_ROOT", "~/.claude/projects"))
    parser.add_argument("--wezterm-list", default=os.environ.get("FLYWHEEL_ORCH_CAPTURE_WEZTERM_LIST"))
    parser.add_argument("--disable-wezterm", action="store_true")
    parser.add_argument("--stale-hours", type=float, default=float(os.environ.get("FLYWHEEL_ORCH_CAPTURE_STALE_HOURS", "24")))
    parser.add_argument("--now")
    parser.add_argument("--doctor", action="store_true")
    parser.add_argument("--strict", action="store_true")
    parser.add_argument("--schema", action="store_true")
    parser.add_argument("--examples", action="store_true")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    if args.schema:
        print(json.dumps(schema_payload(), sort_keys=True, separators=(",", ":") if args.json else None))
        return 0
    if args.examples:
        print(json.dumps(examples_payload(), sort_keys=True, separators=(",", ":") if args.json else None))
        return 0

    topology_path = Path(os.path.expanduser(args.topology)).resolve()
    request_path = Path(os.path.expanduser(args.josh_requests)).resolve()
    coord_path = Path(os.path.expanduser(args.coordination_log)).resolve()
    team_roster_path = Path(os.path.expanduser(args.team_roster)).resolve()
    claude_settings_path = Path(os.path.expanduser(args.claude_settings)).resolve()
    claude_projects_root = Path(os.path.expanduser(args.claude_projects_root)).resolve()
    wezterm_list_path = Path(os.path.expanduser(args.wezterm_list)).resolve() if args.wezterm_list else None
    now = parse_ts(args.now) if args.now else utc_now()
    assert now is not None
    stale_cutoff = now - timedelta(hours=args.stale_hours)

    topology_rows = latest_topology_rows(read_jsonl(topology_path))
    request_rows = read_jsonl(request_path)
    requests_by_session = capture_rows_by_session(request_rows)
    coord_seen = coord_ts_by_session(read_jsonl(coord_path))
    roster_by_session = latest_team_roster_rows(read_jsonl(team_roster_path))
    wezterm_enabled = not args.disable_wezterm and os.environ.get("FLYWHEEL_ORCH_CAPTURE_WEZTERM", "1") != "0"
    wezterm_source, wezterm_panes, wezterm_warnings = load_wezterm_panes(
        wezterm_list_path,
        enabled=wezterm_enabled,
        timeout_seconds=float(os.environ.get("FLYWHEEL_ORCH_CAPTURE_WEZTERM_TIMEOUT_SECONDS", "2")),
    )
    latest_prompts_by_session = {
        str(topo.get("session")): latest_claude_prompt_for_repo(claude_projects_root, topo.get("repo_path"))
        for topo in topology_rows
    }
    rows = [
        classify_row(
            topo,
            request_path=request_path,
            team_roster_path=team_roster_path,
            team_roster_row=roster_by_session.get(str(topo.get("session"))),
            wezterm_panes=wezterm_panes,
            latest_transcript_prompt=latest_prompts_by_session.get(str(topo.get("session"))),
            capture_rows=requests_by_session.get(str(topo.get("session")), []),
            coord_seen_ts=coord_seen.get(str(topo.get("session"))),
            stale_cutoff=stale_cutoff,
        )
        for topo in topology_rows
    ]
    gap_rows = [row for row in rows if row["participation_state"] in {"capture_gap", "stale_capture"}]
    capture_substrate = capture_substrate_payload(
        settings_path=claude_settings_path,
        request_path=request_path,
        request_rows=request_rows,
        now=now,
        stale_cutoff=stale_cutoff,
    )
    substrate_warning = capture_substrate["status"] != "pass"
    payload = {
        "schema_version": SCHEMA_VERSION,
        "generated_at": ts_text(now),
        "topology_path": str(topology_path),
        "josh_requests_path": str(request_path),
        "coordination_log_path": str(coord_path),
        "team_roster_path": str(team_roster_path),
        "claude_settings_path": str(claude_settings_path),
        "claude_projects_root": str(claude_projects_root),
        "capture_substrate": capture_substrate,
        "wezterm_visibility": {
            "source": wezterm_source,
            "enabled": wezterm_enabled or wezterm_list_path is not None,
            "pane_count": len(wezterm_panes),
            "warnings": wezterm_warnings,
        },
        "checked_orchestrators_count": len(rows),
        "orchs_with_capture_gap_count": len(gap_rows),
        "rows": rows,
        "status": "warn" if gap_rows or substrate_warning else "pass",
        "threshold": ">=1",
        "gate_behavior": "warn normally; fail under --strict or hard L71 rollout",
        "duplicate_capture_policy": "prompt_hash or source_message_id is the dedupe key; repeated prompts must link to the existing row, not create duplicates",
        "approved_remediation_tracks": APPROVED_REMEDIATION_TRACKS,
        "xap2_integration": f"flywheel-erkx defines the rule/signal contract; {ORIGINAL_CAPTURE_MECHANISM_BEAD} shipped the first capture mechanism; {ACTIVE_CAPTURE_OWNER_BEAD} owns current live gap cleanup",
        "active_owner_bead": ACTIVE_CAPTURE_OWNER_BEAD,
        "original_mechanism_bead": ORIGINAL_CAPTURE_MECHANISM_BEAD,
        "doctor": args.doctor,
    }
    print(json.dumps(payload, sort_keys=True, separators=(",", ":") if args.json else None))
    if args.strict and (gap_rows or substrate_warning):
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
