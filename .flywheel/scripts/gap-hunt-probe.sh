#!/usr/bin/env bash
set -uo pipefail

VERSION="gap-hunt-probe.v1"
SCRIPT_VERSION="2026-05-03.3"
# 2026-05-03.3: add loop-integrity gap class for active loop markers that
# have driver artifacts but stopped producing loop output closure.
# 2026-05-03.2: narrow bead-without-followup false positives for plan-space
# design/reply/spec beads that mention doctrine terms without claiming a local
# INCIDENTS/AGENTS promotion. Source: gap-hunt-false-positives.jsonl round 1.
REPO_ROOT="${GAP_HUNT_REPO_ROOT:-/Users/josh/Developer/flywheel}"
CLAUDE_ROOT="${GAP_HUNT_CLAUDE_ROOT:-$HOME/.claude}"
STATE_DIR="${GAP_HUNT_STATE_DIR:-$HOME/.local/state/flywheel}"
LEDGER="${GAP_HUNT_LEDGER:-$STATE_DIR/gap-hunt.jsonl}"
BR_BIN="${GAP_HUNT_BR_BIN:-/Users/josh/.cargo/bin/br}"
PARENT_BEAD="${GAP_HUNT_PARENT_BEAD:-flywheel-2xdi}"
AUTO_BEAD_CAP="${GAP_HUNT_AUTO_BEAD_CAP:-3}"
MODE="probe"
DRY_RUN=0
QUIET=0

usage() {
  cat <<'USAGE'
Usage:
  gap-hunt-probe.sh [--json] [--quiet] [--dry-run]
  gap-hunt-probe.sh --doctor [--json] [--quiet] [--dry-run]
  gap-hunt-probe.sh --info [--json]
  gap-hunt-probe.sh --schema
  gap-hunt-probe.sh --examples
  gap-hunt-probe.sh --help

Read-only gap discovery with append-only ledger and capped auto-bead filing.
USAGE
}

examples() {
  cat <<'EXAMPLES'
Examples:
  .flywheel/scripts/gap-hunt-probe.sh --json
  .flywheel/scripts/gap-hunt-probe.sh --doctor --json
  .flywheel/scripts/gap-hunt-probe.sh --dry-run --json
  GAP_HUNT_AUTO_BEAD_CAP=1 .flywheel/scripts/gap-hunt-probe.sh --json
EXAMPLES
}

schema_json() {
  python3 - "$VERSION" <<'PY'
import json
import sys

print(json.dumps({
    "version": sys.argv[1],
    "schema": "flywheel.gap_hunt_probe.v1",
    "required_fields": [
        "version", "ts", "gaps_by_class", "gaps_total",
        "gaps_new_since_last_run", "auto_beads_filed",
        "duration_sec", "warnings",
    ],
    "gap_classes": [
        "wired-but-cold",
        "doctrine-without-measurement",
        "probe-without-receiver",
        "skill-without-jsm-publish",
        "memory-without-cross-link",
        "bead-without-followup",
        "substrate-without-version-probe",
        "cross-source-silos",
        "loop-integrity",
    ],
    "mutation_contract": {
        "discovery": "read-only",
        "ledger": "append-only unless --dry-run",
        "auto_beads": "new gaps only, capped by GAP_HUNT_AUTO_BEAD_CAP default 3, skipped with --dry-run",
    },
}, sort_keys=True))
PY
}

info_json() {
  python3 - "$VERSION" "$SCRIPT_VERSION" "$REPO_ROOT" "$CLAUDE_ROOT" "$STATE_DIR" "$LEDGER" "$BR_BIN" "$PARENT_BEAD" "$AUTO_BEAD_CAP" <<'PY'
import json
import sys

version, script_version, repo, claude, state, ledger, br, parent, cap = sys.argv[1:]
print(json.dumps({
    "success": True,
    "mode": "info",
    "version": version,
    "script_version": script_version,
    "repo_root": repo,
    "claude_root": claude,
    "state_dir": state,
    "ledger": ledger,
    "br_bin": br,
    "parent_bead": parent,
    "auto_bead_cap": int(cap) if cap.isdigit() else 3,
    "gap_classes": [
        "wired-but-cold",
        "doctrine-without-measurement",
        "probe-without-receiver",
        "skill-without-jsm-publish",
        "memory-without-cross-link",
        "bead-without-followup",
        "substrate-without-version-probe",
        "cross-source-silos",
        "loop-integrity",
    ],
    "loop_integrity_signals": [
        "ledger_writes_since_last_tick",
        "pane_state_changed_since_last_tick",
        "receipt_files_written_since_last_tick",
        "callback_received_in_last_2_ticks",
        "fuckup_log_decisions_made_since_last_tick",
    ],
    "read_only_discovery": True,
    "fail_open": True,
}, sort_keys=True))
PY
}

run_probe() {
  python3 - "$VERSION" "$MODE" "$DRY_RUN" "$QUIET" "$REPO_ROOT" "$CLAUDE_ROOT" "$STATE_DIR" "$LEDGER" "$BR_BIN" "$PARENT_BEAD" "$AUTO_BEAD_CAP" <<'PY'
from __future__ import annotations

import json
import os
import re
import subprocess
import sys
import time
from datetime import datetime
from pathlib import Path

VERSION, MODE, DRY_RAW, _QUIET, REPO_RAW, CLAUDE_RAW, STATE_RAW, LEDGER_RAW, BR_RAW, PARENT_BEAD, CAP_RAW = sys.argv[1:]
DRY_RUN = DRY_RAW == "1"
REPO_ROOT = Path(REPO_RAW)
CLAUDE_ROOT = Path(CLAUDE_RAW)
STATE_DIR = Path(STATE_RAW)
LEDGER = Path(LEDGER_RAW)
BR_BIN = Path(BR_RAW)
AUTO_BEAD_CAP = int(CAP_RAW) if CAP_RAW.isdigit() else 3
START = time.time()

GAP_CLASSES = [
    "wired-but-cold",
    "doctrine-without-measurement",
    "probe-without-receiver",
    "skill-without-jsm-publish",
    "memory-without-cross-link",
    "bead-without-followup",
    "substrate-without-version-probe",
    "cross-source-silos",
    "loop-integrity",
]

warnings: list[str] = []
loop_integrity_verdicts: dict[str, dict] = {}


def now_iso() -> str:
    return time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())


def warn(message: str) -> None:
    warnings.append(message)


def append_classifier_divergence(row: dict) -> None:
    log_path = STATE_DIR / "classifier-divergence-log.jsonl"
    log_path.parent.mkdir(parents=True, exist_ok=True)
    payload = json.dumps(row, sort_keys=True, separators=(",", ":")) + "\n"
    append_safe = REPO_ROOT / ".flywheel/scripts/append-safe-write.sh"
    if append_safe.exists() and os.access(append_safe, os.X_OK):
        key = f"{row.get('source')}:{row.get('session')}:{row.get('pane')}:{row.get('old_verdict')}:{row.get('new_verdict')}"
        try:
            subprocess.run(
                [str(append_safe), "--target", str(log_path), "--idempotency-key", key, "--json"],
                input=payload,
                text=True,
                capture_output=True,
                timeout=5,
                check=False,
            )
            return
        except Exception:
            pass
    with log_path.open("a", encoding="utf-8") as handle:
        handle.write(payload)


def warn_on_classifier_divergence(session: str, pane: str, old_state: object, activity_payload: dict, source: str) -> None:
    if os.environ.get("RECENCY_CLASSIFIER_DISABLE") == "1":
        return
    classifier = REPO_ROOT / ".flywheel/scripts/recency-weighted-two-truth-classifier.sh"
    if not classifier.exists():
        return
    old = str(old_state or "UNKNOWN").upper()
    env = os.environ.copy()
    env["RECENCY_CLASSIFIER_ACTIVITY_JSON"] = json.dumps(activity_payload)
    try:
        result = subprocess.run(
            ["bash", str(classifier), "--session", session, "--pane", str(pane), "--json"],
            text=True,
            capture_output=True,
            timeout=8,
            check=False,
            env=env,
        )
        out = json.loads(result.stdout)
    except Exception:
        return
    new = str(out.get("verdict") or "")
    if not new or new == "UNKNOWN" or new == old:
        return
    append_classifier_divergence({
        "ts": now_iso(),
        "source": source,
        "session": session,
        "pane": int(pane) if str(pane).isdigit() else pane,
        "old_verdict": old,
        "new_verdict": new,
        "mode": "warn",
        "used_verdict": "old",
        "classifier": out,
    })


def read_text(path: Path, limit: int = 2_000_000) -> str:
    try:
        with path.open("rb") as fh:
            return fh.read(limit).decode("utf-8", "replace")
    except Exception:
        return ""


def read_json(path: Path) -> dict:
    text = read_text(path, 500_000)
    if not text.strip():
        return {}
    try:
        value = json.loads(text)
        return value if isinstance(value, dict) else {}
    except Exception:
        return {}


def parse_iso_epoch(value: object) -> float | None:
    if value is None:
        return None
    raw = str(value).strip()
    if not raw:
        return None
    try:
        if raw.endswith("Z"):
            raw = raw[:-1] + "+00:00"
        return datetime.fromisoformat(raw).timestamp()
    except Exception:
        return None


def parse_interval_seconds(value: object) -> int:
    raw = str(value or "30m").strip().lower()
    match = re.match(r"^(\d+)\s*([smhd]?)$", raw)
    if not match:
        return 1800
    amount = int(match.group(1))
    unit = match.group(2) or "s"
    scale = {"s": 1, "m": 60, "h": 3600, "d": 86400}.get(unit, 1)
    return max(60, amount * scale)


def expand_paths(paths: list[Path]) -> list[Path]:
    out: list[Path] = []
    for path in paths:
        raw = str(path)
        if any(token in raw for token in "*?["):
            parent = path.parent
            try:
                out.extend(sorted(parent.glob(path.name)))
            except Exception:
                continue
        else:
            out.append(path)
    return out


def newest_file(paths: list[Path]) -> tuple[Path | None, float | None]:
    best_path: Path | None = None
    best_mtime: float | None = None
    for path in expand_paths(paths):
        try:
            if not path.is_file():
                continue
            mtime = path.stat().st_mtime
        except Exception:
            continue
        if best_mtime is None or mtime > best_mtime:
            best_path = path
            best_mtime = mtime
    return best_path, best_mtime


def signal_from_recent_file(name: str, paths: list[Path], window_seconds: int) -> dict:
    best_path, best_mtime = newest_file(paths)
    if best_path is None or best_mtime is None:
        return {"name": name, "ok": False, "evidence": "no_candidate_file"}
    age = int(time.time() - best_mtime)
    ok = age <= window_seconds
    return {
        "name": name,
        "ok": ok,
        "evidence": f"{best_path} age_sec={age} window_sec={window_seconds}",
    }


def safe_iter_files(root: Path, pattern: str = "*", max_files: int = 5000) -> list[Path]:
    if not root.exists():
        return []
    out: list[Path] = []
    try:
        for path in root.rglob(pattern):
            if path.is_file():
                out.append(path)
                if len(out) >= max_files:
                    warn(f"file scan capped at {max_files} for {root}")
                    break
    except Exception as exc:
        warn(f"scan failed for {root}: {exc}")
    return out


def stable_id(cls: str, name: str) -> str:
    raw = re.sub(r"[^A-Za-z0-9_.-]+", "-", name).strip("-").lower()
    return f"{cls}:{raw[:120]}"


def gap(cls: str, name: str, evidence: str) -> dict:
    return {"id": stable_id(cls, name), "name": name[:160], "evidence": evidence[:300]}


def recent_ledger_text(days: int = 30, max_bytes: int = 4_000_000) -> str:
    cutoff = time.time() - days * 86400
    chunks: list[str] = []
    used = 0
    if not STATE_DIR.exists():
        warn(f"state dir missing: {STATE_DIR}")
        return ""
    for path in sorted(STATE_DIR.glob("*.jsonl")):
        if path.name == LEDGER.name:
            continue
        try:
            if path.stat().st_mtime < cutoff:
                continue
            text = read_text(path, max(0, max_bytes - used))
            chunks.append(path.name + "\n" + text)
            used += len(text)
            if used >= max_bytes:
                warn("recent ledger text capped for cold-wire audit")
                break
        except Exception:
            continue
    return "\n".join(chunks)


def previous_ledger_ids() -> set[str]:
    if not LEDGER.exists():
        return set()
    ids: set[str] = set()
    try:
        for line in LEDGER.read_text(errors="replace").splitlines():
            if not line.strip():
                continue
            try:
                row = json.loads(line)
            except Exception:
                warn("prior gap ledger contains invalid JSON row")
                continue
            ids.update(str(item) for item in row.get("gap_ids") or [])
            for rows in (row.get("gaps_by_class") or {}).values():
                for item in rows or []:
                    if isinstance(item, dict) and item.get("id"):
                        ids.add(str(item["id"]))
    except Exception as exc:
        warn(f"could not read prior gap ledger: {exc}")
        return set()
    return ids


def command_text() -> str:
    files = [
        CLAUDE_ROOT / "commands/flywheel/tick.md",
        CLAUDE_ROOT / "commands/flywheel/status.md",
        CLAUDE_ROOT / "commands/flywheel/synth.md",
        REPO_ROOT / "AGENTS.md",
        REPO_ROOT / "INCIDENTS.md",
        REPO_ROOT / "README.md",
    ]
    return "\n".join(read_text(p, 1_000_000) for p in files)


def probe_wired_but_cold() -> list[dict]:
    ledger_text = recent_ledger_text()
    scripts = []
    scripts.extend(safe_iter_files(CLAUDE_ROOT / "skills", "*.sh", 3000))
    scripts.extend(safe_iter_files(REPO_ROOT / ".flywheel/scripts", "*.sh", 300))
    gaps = []
    for script in sorted(set(scripts)):
        name = script.name
        if name in {"gap-hunt-probe.sh"}:
            continue
        if name not in ledger_text and script.stem not in ledger_text:
            try:
                rel = str(script.relative_to(Path.home()))
            except Exception:
                rel = str(script)
            gaps.append(gap("wired-but-cold", rel, "script not referenced by recent flywheel jsonl ledgers modified in last 30d"))
        if len(gaps) >= 20:
            break
    return gaps


def probe_doctrine_without_measurement(tick_text: str) -> list[dict]:
    sources = [
        (REPO_ROOT / "AGENTS.md", read_text(REPO_ROOT / "AGENTS.md")),
        (CLAUDE_ROOT / "CLAUDE.md", read_text(CLAUDE_ROOT / "CLAUDE.md")),
    ]
    seen: set[str] = set()
    gaps = []
    for path, text in sources:
        for match in re.finditer(r"\b(L\d+|Axiom\s+\d+)\b", text):
            rule = match.group(1).replace(" ", "-")
            if rule in seen:
                continue
            seen.add(rule)
            probe_pattern = rule.lower().replace("-", "[-_ ]?")
            if not re.search(probe_pattern, tick_text, re.I):
                gaps.append(gap("doctrine-without-measurement", rule, f"{path} mentions {match.group(1)} but tick.md has no matching observability hook"))
            if len(gaps) >= 20:
                return gaps
    return gaps


def probe_without_receiver(receivers_text: str) -> list[dict]:
    files = safe_iter_files(REPO_ROOT, "*-probe.sh", 500)
    files.extend(safe_iter_files(CLAUDE_ROOT / "skills", "*-probe.sh", 1000))
    receipt_text = ""
    for path in safe_iter_files(Path.home() / ".local/state/flywheel-loop", "last_tick_*.json", 200):
        receipt_text += "\n" + read_text(path, 200_000)
    combined = receivers_text + "\n" + receipt_text
    gaps = []
    for path in sorted(set(files)):
        if path.name in combined or path.stem in combined:
            continue
        gaps.append(gap("probe-without-receiver", path.name, f"{path} emits probe output but no tick/status/last_tick receiver reference was found"))
        if len(gaps) >= 20:
            break
    return gaps


def probe_skill_without_jsm_publish() -> list[dict]:
    gaps = []
    jsm = Path("/Users/josh/.local/bin/jsm")
    if jsm.exists():
        try:
            result = subprocess.run([str(jsm), "status"], text=True, capture_output=True, timeout=20, check=False)
            status_text = result.stdout + result.stderr
        except Exception as exc:
            warn(f"jsm status failed: {exc}")
            status_text = ""
    else:
        warn("jsm binary unavailable for publish audit")
        status_text = ""
    for skill_md in sorted((CLAUDE_ROOT / "skills").glob("*/SKILL.md")):
        text = read_text(skill_md, 120_000)
        skill = skill_md.parent.name
        localish = any(token in text for token in ("foundation-v0.1", "ZestStream.ai", "status: foundation", "distribution: forbidden"))
        if localish and skill not in status_text and "jsm" not in text.lower():
            gaps.append(gap("skill-without-jsm-publish", skill, f"{skill_md} appears locally authored but has no visible jsm status/metadata reference"))
        if len(gaps) >= 20:
            break
    return gaps


def probe_memory_without_cross_link() -> list[dict]:
    memory_root = CLAUDE_ROOT / "projects/-Users-josh-Developer-flywheel/memory"
    refs = command_text()
    for path in safe_iter_files(REPO_ROOT / ".flywheel/plans", "*.md", 200):
        refs += "\n" + read_text(path, 200_000)
    gaps = []
    for path in sorted(memory_root.glob("*.md")):
        name = path.name
        if name == "MEMORY.md":
            continue
        if name not in refs and path.stem not in refs:
            gaps.append(gap("memory-without-cross-link", name, f"{path} not cited by sampled commands, doctrine, incidents, or recent plan files"))
        if len(gaps) >= 20:
            break
    return gaps


def iter_issue_rows() -> list[dict]:
    path = REPO_ROOT / ".beads/issues.jsonl"
    rows = []
    try:
        for line in path.read_text(errors="replace").splitlines():
            if not line.strip():
                continue
            try:
                value = json.loads(line)
                if isinstance(value, dict):
                    rows.append(value)
            except Exception:
                continue
    except Exception as exc:
        warn(f"could not read bead JSONL: {exc}")
    return rows


def row_text(row: dict) -> str:
    return " ".join(str(row.get(key) or "") for key in ("id", "title", "description", "close_reason", "status"))


def bead_followup_false_positive_reason(row: dict) -> str | None:
    text = row_text(row).lower()
    # Narrow suppressions from gap-hunt-false-positives.jsonl 2026-05-03.
    # These are plan/reply/spec outputs where doctrine words describe target
    # concepts, not completed local INCIDENTS/AGENTS promotion work.
    suppressions = [
        (
            "plan-space-cross-link-design",
            [
                "perp-cross-link-recovery-plan",
                "cross-link wave-execution doc done",
                "perp_cross_link_design.md",
            ],
        ),
        (
            "mkdir-lock-fallback-plan",
            [
                "flock-missing-on-host-mkdir-lock-fallback",
                "plan-space doc",
                "mkdir_lock_pattern_plan.md",
            ],
        ),
        (
            "external-issue-reply-draft",
            [
                "ntm#113",
                "reply",
                "ntm113-reply-draft.md",
            ],
        ),
        (
            "recover-pane-command-spec",
            [
                "/flywheel:recover-pane",
                "slash command spec done",
                "recov_pane_command_design.md",
            ],
        ),
    ]
    for reason, needles in suppressions:
        if all(needle in text for needle in needles):
            return reason
    return None


def probe_bead_without_followup() -> list[dict]:
    incidents = read_text(REPO_ROOT / "INCIDENTS.md", 2_000_000)
    gaps = []
    surfaced_hits = 0
    latest_by_id: dict[str, dict] = {}
    for row in iter_issue_rows():
        rid = str(row.get("id") or "")
        if rid:
            latest_by_id[rid] = row
    for rid, row in sorted(latest_by_id.items()):
        text = row_text(row)
        if str(row.get("status") or "") != "closed":
            continue
        if not re.search(r"\b(doctrine|canonical|promote|promotion)\b", text, re.I):
            continue
        if bead_followup_false_positive_reason(row):
            surfaced_hits += 1
            if surfaced_hits >= 20:
                break
            continue
        if rid not in incidents:
            gaps.append(gap("bead-without-followup", rid, f"closed bead claims doctrine/canonical/promotion work but {rid} is not cited in INCIDENTS.md"))
            surfaced_hits += 1
            if surfaced_hits >= 20:
                break
    return gaps


def probe_substrate_without_version_probe(receivers_text: str) -> list[dict]:
    memory = read_text(CLAUDE_ROOT / "projects/-Users-josh-Developer-flywheel/memory/reference_jeff_substrate_inventory.md", 500_000)
    upgrade_log = read_text(STATE_DIR / "jeff-substrate-upgrades.jsonl", 500_000)
    version_probe_text = receivers_text + "\n" + upgrade_log
    binaries = []
    for line in memory.splitlines():
        match = re.match(r"\|\s*`?([^`|]+?)`?\s*\|\s*Dicklesworthstone/", line)
        if match:
            binaries.append(match.group(1).strip())
    gaps = []
    for binary in binaries:
        tokens = [binary, binary.replace(" ", "-"), binary.split()[0]]
        if not any(token and token in version_probe_text for token in tokens):
            gaps.append(gap("substrate-without-version-probe", binary, "binary appears in reference_jeff_substrate_inventory.md but no sampled version-probe/tick/upgrade ledger reference was found"))
    return gaps


def probe_cross_source_silos(receivers_text: str) -> list[dict]:
    gaps = []
    for path in sorted(STATE_DIR.glob("*.jsonl")):
        name = path.name
        if name in {"gap-hunt.jsonl"}:
            continue
        if name not in receivers_text and path.stem not in receivers_text:
            gaps.append(gap("cross-source-silos", name, f"{path} ledger exists but is not referenced by sampled tick/status/synth/doctrine surfaces"))
        if len(gaps) >= 20:
            break
    return gaps


def active_loop_markers() -> list[dict]:
    loops_dir = Path.home() / ".flywheel/loops"
    markers: list[dict] = []
    for path in sorted(loops_dir.glob("*.json")):
        data = read_json(path)
        if data.get("active") is not True:
            continue
        data["_marker_path"] = str(path)
        if not data.get("project"):
            data["project"] = path.stem
        markers.append(data)
    return markers


def latest_jsonl_row(path: Path, predicate) -> dict:
    latest: dict = {}
    latest_epoch: float | None = None
    try:
        lines = path.read_text(errors="replace").splitlines()
    except Exception:
        return {}
    for line in lines:
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except Exception:
            continue
        if not isinstance(row, dict) or not predicate(row):
            continue
        epoch = parse_iso_epoch(row.get("effective_at") or row.get("ts") or row.get("callback_received_at"))
        if latest_epoch is None or (epoch is not None and epoch >= latest_epoch):
            latest = row
            latest_epoch = epoch
    return latest


def latest_topology(session: str) -> dict:
    path = STATE_DIR / "session-topology.jsonl"
    return latest_jsonl_row(path, lambda row: str(row.get("session") or "") == session)


def repo_for_marker(marker: dict) -> Path:
    repo = str(marker.get("repo") or "").strip()
    if repo:
        return Path(repo)
    project = str(marker.get("project") or "").strip()
    return Path("/Users/josh/Developer") / project


def session_for_marker(marker: dict) -> str:
    return str(marker.get("session") or marker.get("project") or "").strip()


def pane_key(value: object) -> str:
    raw = str(value or "").strip()
    try:
        return str(int(raw))
    except Exception:
        return raw


def worker_panes(marker: dict, topology: dict) -> set[str]:
    panes: set[str] = set()
    for item in topology.get("worker_panes") or []:
        if isinstance(item, dict):
            panes.add(pane_key(item.get("pane") or item.get("pane_idx")))
        else:
            panes.add(pane_key(item))
    if marker.get("worker_pane") is not None:
        panes.add(pane_key(marker.get("worker_pane")))
    return {pane for pane in panes if pane}


def signal_pane_state(marker: dict, interval_seconds: int) -> dict:
    session = session_for_marker(marker)
    if not session:
        return {"name": "pane_state_changed_since_last_tick", "ok": False, "evidence": "no_session"}
    ntm = Path("/Users/josh/.local/bin/ntm")
    if not ntm.exists():
        return {"name": "pane_state_changed_since_last_tick", "ok": False, "evidence": "ntm_missing"}
    try:
        result = subprocess.run(
            [str(ntm), f"--robot-activity={session}", "--activity-type=codex,claude"],
            text=True,
            capture_output=True,
            timeout=10,
            check=False,
        )
    except Exception as exc:
        return {"name": "pane_state_changed_since_last_tick", "ok": False, "evidence": f"ntm_failed={exc}"}
    if result.returncode != 0:
        return {"name": "pane_state_changed_since_last_tick", "ok": False, "evidence": result.stderr.strip()[:180]}
    try:
        payload = json.loads(result.stdout)
    except Exception:
        return {"name": "pane_state_changed_since_last_tick", "ok": False, "evidence": "robot_activity_non_json"}
    agents = payload.get("agents") or []
    topology = latest_topology(session)
    panes = worker_panes(marker, topology)
    orch = pane_key(topology.get("orchestrator_pane") or marker.get("orchestrator_pane"))
    recent: list[str] = []
    considered = 0
    now = time.time()
    for agent in agents:
        if not isinstance(agent, dict):
            continue
        pane = pane_key(agent.get("pane") or agent.get("pane_idx"))
        if not pane:
            continue
        if panes and pane not in panes:
            continue
        if not panes and orch and pane == orch:
            continue
        considered += 1
        warn_on_classifier_divergence(session, pane, agent.get("state"), payload, "gap-hunt-probe.sh")
        since = parse_iso_epoch(agent.get("state_since"))
        if since is not None and now - since <= interval_seconds:
            recent.append(f"pane={pane} state={agent.get('state')} age_sec={int(now - since)}")
    if recent:
        return {"name": "pane_state_changed_since_last_tick", "ok": True, "evidence": "; ".join(recent[:3])}
    return {
        "name": "pane_state_changed_since_last_tick",
        "ok": False,
        "evidence": f"no_recent_worker_state considered={considered} window_sec={interval_seconds}",
    }


def loop_candidate_paths(project: str, repo: Path, kind: str) -> list[Path]:
    local_state = Path.home() / ".local/state"
    local_logs = Path.home() / ".local/logs"
    flywheel_loop = local_state / "flywheel-loop"
    paths = [
        flywheel_loop / f"last_tick_{project}.json",
        local_state / f"{project}-flywheel-loop/last_run.json",
        local_logs / f"{project}-flywheel-loop.jsonl",
    ]
    if kind == "receipt":
        paths.extend([
            repo / ".flywheel/ticks/*.json",
            repo / ".flywheel/last_closeout_receipt.json",
            local_state / f"{project}-receipt-bridge.jsonl",
            local_state / f"{project}-flywheel-loop/receipt.json",
        ])
    if project == "flywheel":
        paths.extend([
            STATE_DIR / "gap-hunt.jsonl",
            STATE_DIR / "ntm-fleet-health.jsonl",
            repo / ".flywheel/dispatch-log.jsonl",
        ])
    return paths


def newest_callback_signal(project: str, repo: Path, window_seconds: int) -> dict:
    log_paths = [
        repo / ".flywheel/dispatch-log.jsonl",
        STATE_DIR / "dispatch-log.jsonl",
    ]
    newest: tuple[Path | None, float | None] = (None, None)
    for path in log_paths:
        try:
            lines = path.read_text(errors="replace").splitlines()
        except Exception:
            continue
        for line in lines:
            if not line.strip():
                continue
            try:
                row = json.loads(line)
            except Exception:
                continue
            if not isinstance(row, dict):
                continue
            if row.get("repo") and repo.exists() and str(row.get("repo")) != str(repo):
                continue
            if row.get("session") and project != "flywheel" and str(row.get("session")) != project:
                continue
            epoch = parse_iso_epoch(row.get("callback_received_at"))
            if epoch is None:
                continue
            if newest[1] is None or epoch > newest[1]:
                newest = (path, epoch)
    if newest[0] is None or newest[1] is None:
        return {"name": "callback_received_in_last_2_ticks", "ok": False, "evidence": "no_callback_received_at"}
    age = int(time.time() - newest[1])
    return {
        "name": "callback_received_in_last_2_ticks",
        "ok": age <= window_seconds,
        "evidence": f"{newest[0]} callback_age_sec={age} window_sec={window_seconds}",
    }


def jsonl_rows_since(path: Path, since_epoch: float, needles: list[str] | None = None) -> list[dict]:
    rows: list[dict] = []
    try:
        lines = path.read_text(errors="replace").splitlines()
    except Exception:
        return rows
    for line in lines:
        if not line.strip():
            continue
        if needles and not any(needle and needle in line for needle in needles):
            continue
        try:
            row = json.loads(line)
        except Exception:
            continue
        if not isinstance(row, dict):
            continue
        epoch = parse_iso_epoch(row.get("processed_at") or row.get("callback_received_at") or row.get("ts") or row.get("created_at"))
        if epoch is not None and epoch >= since_epoch:
            rows.append(row)
    return rows


def row_matches_loop_project(row: dict, project: str, repo: Path) -> bool:
    for key in ("session", "project"):
        value = str(row.get(key) or "")
        if value == project:
            return True
    for key in ("git_repo", "repo"):
        value = str(row.get(key) or "")
        if value and value == str(repo):
            return True
    if project == "flywheel":
        return False
    encoded = json.dumps(row, sort_keys=True)
    return project in encoded or str(repo) in encoded


def signal_fuckup_decisions(project: str, repo: Path, interval_seconds: int) -> dict:
    since = time.time() - interval_seconds
    processed = [
        row for row in jsonl_rows_since(STATE_DIR / "fuckup-processed.jsonl", since)
        if row_matches_loop_project(row, project, repo)
    ]
    if processed:
        return {
            "name": "fuckup_log_decisions_made_since_last_tick",
            "ok": True,
            "evidence": f"processed_rows={len(processed)} window_sec={interval_seconds}",
        }
    callback_decisions = 0
    for row in jsonl_rows_since(repo / ".flywheel/dispatch-log.jsonl", since):
        if not row.get("callback_received_at"):
            continue
        if row.get("no_bead_reason") or row.get("beads_filed") or row.get("beads_updated"):
            callback_decisions += 1
    if callback_decisions:
        return {
            "name": "fuckup_log_decisions_made_since_last_tick",
            "ok": True,
            "evidence": f"callback_decision_rows={callback_decisions} window_sec={interval_seconds}",
        }
    recent_fuckups = [
        row for row in jsonl_rows_since(STATE_DIR / "fuckup-log.jsonl", since)
        if row_matches_loop_project(row, project, repo)
    ]
    if not recent_fuckups:
        return {
            "name": "fuckup_log_decisions_made_since_last_tick",
            "ok": True,
            "evidence": f"no_recent_project_fuckups_to_decide window_sec={interval_seconds}",
        }
    return {
        "name": "fuckup_log_decisions_made_since_last_tick",
        "ok": False,
        "evidence": f"recent_project_fuckups_without_processed_row={len(recent_fuckups)}",
    }


def classify_loop(marker: dict) -> dict:
    project = str(marker.get("project") or "").strip()
    repo = repo_for_marker(marker)
    interval = parse_interval_seconds(marker.get("interval"))
    signals = [
        signal_from_recent_file(
            "ledger_writes_since_last_tick",
            loop_candidate_paths(project, repo, "ledger"),
            interval,
        ),
        signal_pane_state(marker, interval),
        signal_from_recent_file(
            "receipt_files_written_since_last_tick",
            loop_candidate_paths(project, repo, "receipt"),
            interval,
        ),
        newest_callback_signal(project, repo, interval * 2),
        signal_fuckup_decisions(project, repo, interval),
    ]
    failed = [str(item["name"]) for item in signals if not item.get("ok")]
    verdict = "HEALTHY"
    if len(failed) >= 3:
        verdict = "DEAD"
    elif failed:
        verdict = "LIMPING"
    return {
        "project": project,
        "session": session_for_marker(marker),
        "repo": str(repo),
        "interval_seconds": interval,
        "verdict": verdict,
        "failed_signals": failed,
        "signals": {str(item["name"]): item for item in signals},
        "marker": str(marker.get("_marker_path") or ""),
    }


def probe_loop_integrity() -> list[dict]:
    gaps = []
    for marker in active_loop_markers():
        result = classify_loop(marker)
        project = result["project"]
        loop_integrity_verdicts[project] = result
        if result["verdict"] == "HEALTHY":
            continue
        failed = ",".join(result["failed_signals"])
        evidence = f"verdict={result['verdict']} failed_signals={failed} marker={result['marker']}"
        gaps.append(gap("loop-integrity", project, evidence))
    return gaps


def create_bead(item: dict) -> str | None:
    if DRY_RUN:
        return None
    if not BR_BIN.exists():
        warn(f"br unavailable at {BR_BIN}; auto-bead skipped")
        return None
    cls = item["id"].split(":", 1)[0]
    title = f"[gap-{cls}] {item['name']}"[:180]
    description = (
        f"Auto-filed by gap-hunt-probe. Parent={PARENT_BEAD}.\\n\\n"
        f"Class: {cls}\\n"
        f"Gap id: {item['id']}\\n"
        f"Evidence: {item['evidence']}\\n"
    )
    cmd = [
        str(BR_BIN), "create",
        "--priority", "3",
        "--type", "task",
        "--parent", PARENT_BEAD,
        "--title", title,
        "--description", description,
        "--json",
    ]
    try:
        result = subprocess.run(cmd, cwd=str(REPO_ROOT), text=True, capture_output=True, timeout=20, check=False)
    except Exception as exc:
        warn(f"br create failed for {item['id']}: {exc}")
        return None
    if result.returncode != 0:
        warn(f"br create failed for {item['id']}: {result.stderr.strip()[:180]}")
        return None
    try:
        payload = json.loads(result.stdout)
        if isinstance(payload, dict):
            return str(payload.get("id") or "")
    except Exception:
        pass
    match = re.search(r"flywheel-[A-Za-z0-9_.-]+", result.stdout)
    return match.group(0) if match else None


def main() -> None:
    tick_text = read_text(CLAUDE_ROOT / "commands/flywheel/tick.md", 1_500_000)
    receivers_text = command_text()
    gaps_by_class = {cls: [] for cls in GAP_CLASSES}
    probes = [
        ("wired-but-cold", lambda: probe_wired_but_cold()),
        ("doctrine-without-measurement", lambda: probe_doctrine_without_measurement(tick_text)),
        ("probe-without-receiver", lambda: probe_without_receiver(receivers_text)),
        ("skill-without-jsm-publish", lambda: probe_skill_without_jsm_publish()),
        ("memory-without-cross-link", lambda: probe_memory_without_cross_link()),
        ("bead-without-followup", lambda: probe_bead_without_followup()),
        ("substrate-without-version-probe", lambda: probe_substrate_without_version_probe(receivers_text)),
        ("cross-source-silos", lambda: probe_cross_source_silos(receivers_text)),
        ("loop-integrity", lambda: probe_loop_integrity()),
    ]
    for cls, fn in probes:
        try:
            gaps_by_class[cls] = fn()
        except Exception as exc:
            warn(f"{cls} probe failed: {exc}")
            gaps_by_class[cls] = []

    current_ids = [item["id"] for rows in gaps_by_class.values() for item in rows]
    prior_ids = previous_ledger_ids()
    new_items = [item for rows in gaps_by_class.values() for item in rows if item["id"] not in prior_ids]
    auto_beads: list[str] = []
    for item in new_items[:AUTO_BEAD_CAP]:
        bead_id = create_bead(item)
        if bead_id:
            auto_beads.append(bead_id)

    distribution = {cls: len(rows) for cls, rows in gaps_by_class.items()}
    payload = {
        "version": VERSION,
        "ts": now_iso(),
        "mode": MODE,
        "dry_run": DRY_RUN,
        "gaps_by_class": gaps_by_class,
        "gaps_total": len(current_ids),
        "gaps_new_since_last_run": len(new_items),
        "gap_class_distribution": distribution,
        "gap_ids": current_ids,
        "loop_integrity_verdicts": loop_integrity_verdicts,
        "auto_beads_filed": auto_beads,
        "duration_sec": round(time.time() - START, 3),
        "warnings": warnings,
    }

    if not DRY_RUN:
        try:
            LEDGER.parent.mkdir(parents=True, exist_ok=True)
            with LEDGER.open("a", encoding="utf-8") as fh:
                fh.write(json.dumps(payload, sort_keys=True) + "\n")
        except Exception as exc:
            payload["warnings"].append(f"ledger append failed: {exc}")

    print(json.dumps(payload, sort_keys=True))


main()
PY
}

main() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --help|-h)
        usage
        exit 0
        ;;
      --json)
        shift
        ;;
      --doctor|--health)
        MODE="${1#--}"
        shift
        ;;
      --info)
        info_json
        exit 0
        ;;
      --schema)
        schema_json
        exit 0
        ;;
      --examples)
        examples
        exit 0
        ;;
      --quiet)
        QUIET=1
        shift
        ;;
      --dry-run)
        DRY_RUN=1
        shift
        ;;
      *)
        printf 'ERROR: unknown argument: %s\n' "$1" >&2
        usage >&2
        exit 2
        ;;
    esac
  done

  run_probe
}

main "$@"
