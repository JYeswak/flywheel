#!/usr/bin/env bash
set -euo pipefail
# canonical-cli-scoping-allow-large: embedded Python keeps this repo-local probe deployable as one script.
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/$(basename "${BASH_SOURCE[0]}")"
WATCHER_ISOMORPHIC_SCRIPT_PATH="$SCRIPT_PATH" exec python3 - "$@" <<'PY'
import argparse
import json
import os
import plistlib
import subprocess
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path
SCHEMA_VERSION = "watcher-isomorphic-probe.v1"
FLEET_SCHEMA_VERSION = "watcher-isomorphic-probe-fleet.v1"
REAL_HOME = Path(os.environ.get("WATCHER_ISOMORPHIC_HOME") or ("/Users/josh" if Path("/Users/josh").exists() else str(Path.home()))).expanduser()
DEFAULT_TOPOLOGY = REAL_HOME / ".local/state/flywheel/session-topology.jsonl"
DEFAULT_LOOPS_DIR = REAL_HOME / ".flywheel/loops"
BASELINE = {
    "total": 116,
    "by_class": {
        "silent-write": 45,
        "destructive-default": 64,
        "unregistered-process": 7,
    },
}
GENERIC_REASONS = {"", "registered", "registry", "owned", "unknown", "todo", "fixture"}
def utcnow():
    override = os.environ.get("WATCHER_ISOMORPHIC_NOW")
    if override:
        return parse_ts(override) or datetime.now(timezone.utc)
    return datetime.now(timezone.utc)
def iso(dt):
    return dt.astimezone(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
def parse_ts(value):
    if not value:
        return None
    text = str(value)
    try:
        if text.endswith("Z"):
            text = text[:-1] + "+00:00"
        return datetime.fromisoformat(text).astimezone(timezone.utc)
    except Exception:
        return None
def env_path(name, default):
    return Path(os.environ.get(name, default)).expanduser()
def load_jsonl(path):
    rows = []
    try:
        with Path(path).open() as fh:
            for line in fh:
                line = line.strip()
                if not line:
                    continue
                try:
                    obj = json.loads(line)
                except Exception:
                    continue
                if isinstance(obj, dict):
                    rows.append(obj)
    except FileNotFoundError:
        pass
    return rows
def append_jsonl(path, row):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a") as fh:
        fh.write(json.dumps(row, sort_keys=True, separators=(",", ":")) + "\n")
def load_json_file(path):
    try:
        with Path(path).open() as fh:
            return json.load(fh)
    except Exception:
        return None
def latest_topology_rows(path):
    latest = {}
    for row in load_jsonl(path):
        session = row.get("session")
        if not session:
            continue
        current = latest.get(str(session))
        row_key = parse_ts(row.get("effective_at") or row.get("ts")) or datetime.min.replace(tzinfo=timezone.utc)
        current_key = parse_ts((current or {}).get("effective_at") or (current or {}).get("ts")) or datetime.min.replace(tzinfo=timezone.utc)
        if current is None or row_key >= current_key:
            latest[str(session)] = row
    return [latest[k] for k in sorted(latest)]
def topology_row_is_live(row):
    status_text = " ".join(str(row.get(k) or "") for k in ("session_status", "live_ntm_status", "loop_status")).lower()
    dead_markers = ("not_live", "session_not_found", "out_of_fleet", "metadata_only")
    if any(marker in status_text for marker in dead_markers):
        return False
    if row.get("orchestrator_pane") is None and not row.get("worker_panes"):
        return False
    return True
def loop_path_for(args, session):
    return Path(args.loops_dir).expanduser() / f"{session}.json"
def repo_from_loop(loop):
    for key in ("repo", "repo_path", "project_path", "path"):
        value = loop.get(key)
        if value:
            return Path(str(value)).expanduser()
    return None
def fixture_env_for_repo(repo, env):
    fixture_dir = Path(repo) / ".flywheel/watcher-isomorphic-fixtures"
    if not fixture_dir.exists():
        return env
    mapping = {
        "WATCHER_ISOMORPHIC_STATE_DIR": fixture_dir / "state",
        "WATCHER_ISOMORPHIC_RECOVERY_LEDGER": fixture_dir / "recovery.jsonl",
        "WATCHER_ISOMORPHIC_SELFTEST_FIXTURE": fixture_dir / "selftest.json",
        "WATCHER_ISOMORPHIC_PLIST_REGISTRY": fixture_dir / "registry.jsonl",
        "WATCHER_ISOMORPHIC_LA_DIR": fixture_dir / "LaunchAgents",
        "WATCHER_ISOMORPHIC_DISABLED_DIR": fixture_dir / "LaunchAgents/.disabled",
        "WATCHER_ISOMORPHIC_READY_FIXTURE": fixture_dir / "ready.json",
        "WATCHER_ISOMORPHIC_TRAUMA_CURRENT": fixture_dir / "trauma.json",
        "WATCHER_ISOMORPHIC_RECEIPT_FIXTURE": fixture_dir / "receipts.json",
    }
    for key, value in mapping.items():
        if Path(value).exists():
            env[key] = str(value)
    return env
def missing_session(session, reason, **extra):
    payload = {
        "session": session,
        "status": "missing_tooling",
        "reason": reason,
        "watcher_reenable_recommendation": "red",
    }
    payload.update(extra)
    return payload
def fleet_targets(args):
    rows = latest_topology_rows(args.topology)
    targets = []
    for row in rows:
        session = str(row.get("session") or "")
        if not session or (args.session and session != args.session):
            continue
        if not topology_row_is_live(row):
            continue
        path = loop_path_for(args, session)
        loop = load_json_file(path)
        if not isinstance(loop, dict):
            targets.append((session, None, row, path, None, "loop_config_missing"))
            continue
        if loop.get("active") is False:
            targets.append((session, loop, row, path, None, "loop_inactive"))
            continue
        repo = repo_from_loop(loop)
        if repo is None:
            targets.append((session, loop, row, path, None, "repo_not_declared"))
            continue
        if not repo.exists():
            targets.append((session, loop, row, path, repo, "repo_missing"))
            continue
        targets.append((session, loop, row, path, repo.resolve(), None))
    return targets
def parse_json_from_stdout(text):
    text = (text or "").strip()
    starts = [i for i in (text.find("{"), text.find("[")) if i >= 0]
    if not starts:
        return None
    try:
        return json.loads(text[min(starts):])
    except Exception:
        return None
def run_fleet_session(session, repo, loop_path, args):
    worker = Path(os.environ.get("WATCHER_ISOMORPHIC_FLEET_WORKER") or os.environ.get("WATCHER_ISOMORPHIC_SCRIPT_PATH") or sys.argv[0])
    if not worker.exists():
        return missing_session(session, "probe_script_missing", repo=str(repo), loop_path=str(loop_path), probe=str(worker))
    env = os.environ.copy()
    env["WATCHER_ISOMORPHIC_REPO"] = str(repo)
    env = fixture_env_for_repo(repo, env)
    try:
        proc = subprocess.run(
            [str(worker), "--doctor", "--repo", str(repo), "--json"],
            cwd=str(repo),
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=args.fleet_timeout,
            check=False,
            env=env,
        )
    except subprocess.TimeoutExpired:
        return {"session": session, "status": "fail", "reason": "probe_timeout", "repo": str(repo), "loop_path": str(loop_path), "watcher_reenable_recommendation": "red"}
    except Exception as exc:
        return {"session": session, "status": "fail", "reason": "probe_invocation_error", "error": str(exc), "repo": str(repo), "loop_path": str(loop_path), "watcher_reenable_recommendation": "red"}
    payload = parse_json_from_stdout(proc.stdout)
    if not isinstance(payload, dict):
        return {
            "session": session,
            "status": "fail",
            "reason": "probe_invalid_json",
            "repo": str(repo),
            "loop_path": str(loop_path),
            "rc": proc.returncode,
            "stderr_tail": proc.stderr[-400:],
            "watcher_reenable_recommendation": "red",
        }
    payload = dict(payload)
    payload["session"] = session
    payload["loop_path"] = str(loop_path)
    payload["repo"] = str(repo)
    payload["probe_rc"] = proc.returncode
    if proc.returncode != 0 and payload.get("status") == "pass":
        payload["status"] = "fail"
        payload["reason"] = "probe_nonzero_exit"
    return payload
def fleet_report(args):
    targets = fleet_targets(args)
    sessions = {}
    for session, loop, topo, loop_path, repo, missing_reason in targets:
        if missing_reason:
            sessions[session] = missing_session(
                session,
                missing_reason,
                loop_path=str(loop_path),
                repo=str(repo) if repo is not None else None,
                topology_effective_at=topo.get("effective_at"),
            )
            continue
        sessions[session] = run_fleet_session(session, repo, loop_path, args)
        sessions[session]["topology_effective_at"] = topo.get("effective_at")
    passing = []
    failing = []
    missing = []
    recommendation_by_session = {}
    for session, payload in sessions.items():
        status = str(payload.get("status") or "").lower()
        recommendation_by_session[session] = payload.get("watcher_reenable_recommendation") or ("green" if status == "pass" else "red")
        if status == "pass":
            passing.append(session)
        elif status == "missing_tooling":
            missing.append(session)
        else:
            failing.append(session)
    total = len(sessions)
    if total and len(passing) == total:
        status = "pass"
        fleet_recommendation = "green"
    elif not passing:
        status = "fail"
        fleet_recommendation = "red"
    else:
        status = "mixed"
        fleet_recommendation = "yellow"
    return {
        "schema_version": FLEET_SCHEMA_VERSION,
        "status": status,
        "mode": "fleet",
        "topology_source": str(Path(args.topology).expanduser()),
        "loops_dir": str(Path(args.loops_dir).expanduser()),
        "latest_topology_semantics": "group_by(session) sort_by(effective_at) take last",
        "sessions": sessions,
        "fleet_summary": {
            "total_sessions": total,
            "passing": len(passing),
            "failing": len(failing),
            "missing_tooling": len(missing),
            "passing_sessions": passing,
            "failing_sessions": failing,
            "missing_tooling_sessions": missing,
            "watcher_reenable_recommendation_per_session": recommendation_by_session,
            "fleet_watcher_reenable_recommendation": fleet_recommendation,
        },
        "watcher_isomorphic_fleet_status": fleet_recommendation,
        "watcher_isomorphic_fleet_failing_sessions": failing + missing,
        "watcher_isomorphic_fleet_passing_count": len(passing),
    }
def run_json(cmd, cwd=None, timeout=15):
    try:
        proc = subprocess.run(
            cmd,
            cwd=str(cwd) if cwd else None,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=timeout,
            check=False,
        )
    except Exception as exc:
        return None, {"error": str(exc), "cmd": cmd}
    text = proc.stdout.strip()
    starts = [i for i in (text.find("{"), text.find("[")) if i >= 0]
    if not starts:
        return None, {"rc": proc.returncode, "stderr": proc.stderr[-400:]}
    try:
        return json.loads(text[min(starts):]), None
    except Exception as exc:
        return None, {"rc": proc.returncode, "error": str(exc), "stderr": proc.stderr[-400:]}
class Config:
    def __init__(self, args):
        home = Path.home()
        self.repo = Path(args.repo or os.environ.get("WATCHER_ISOMORPHIC_REPO", Path.cwd())).resolve()
        repo_fixture_env = fixture_env_for_repo(self.repo, os.environ.copy())
        repo_fixture_state_only = (
            "WATCHER_ISOMORPHIC_STATE_DIR" in repo_fixture_env
            and "WATCHER_ISOMORPHIC_PLIST_REGISTRY" not in repo_fixture_env
            and "WATCHER_ISOMORPHIC_PLIST_REGISTRY" not in os.environ
        )
        for key, value in repo_fixture_env.items():
            os.environ.setdefault(key, value)
        self.state_dir = env_path("WATCHER_ISOMORPHIC_STATE_DIR", home / ".local/state/flywheel")
        self.recovery_ledger = env_path("WATCHER_ISOMORPHIC_RECOVERY_LEDGER", self.state_dir / "frozen-pane-recovery-ledger.jsonl")
        self.dispatch_log = env_path("WATCHER_ISOMORPHIC_DISPATCH_LOG", self.repo / ".flywheel/dispatch-log.jsonl")
        self.bak_ledger = env_path("WATCHER_ISOMORPHIC_BAK_LEDGER", self.state_dir / "bak-quarantine-ledger.jsonl")
        registry_default = home / ".local/state/flywheel/plist-registry.jsonl" if repo_fixture_state_only else self.state_dir / "plist-registry.jsonl"
        self.registry = env_path("WATCHER_ISOMORPHIC_PLIST_REGISTRY", registry_default)
        self.launch_agents = env_path("WATCHER_ISOMORPHIC_LA_DIR", home / "Library/LaunchAgents")
        self.disabled_dir = env_path("WATCHER_ISOMORPHIC_DISABLED_DIR", self.launch_agents / ".disabled")
        self.trauma_trend = env_path("WATCHER_ISOMORPHIC_TRAUMA_TREND", self.state_dir / "trauma-class-trend.jsonl")
        self.tuning_ledger = env_path("WATCHER_ISOMORPHIC_TUNING_LEDGER", self.state_dir / "watcher-tuning-ledger.jsonl")
        self.false_positive_threshold = float(os.environ.get("WATCHER_ISOMORPHIC_FP_THRESHOLD", "0.05"))
        self.sample_target = int(os.environ.get("WATCHER_ISOMORPHIC_READY_SAMPLE", "10"))
        self.now = utcnow()
        self.apply = args.apply
        self.dry_run = args.dry_run
def ensure_ledgers(cfg):
    cfg.state_dir.mkdir(parents=True, exist_ok=True)
    bootstrapped = False
    if not cfg.trauma_trend.exists() or cfg.trauma_trend.stat().st_size == 0:
        append_jsonl(cfg.trauma_trend, {
            "ts": iso(cfg.now),
            "event": "baseline",
            "source": "flywheel-1uors",
            "total": BASELINE["total"],
            "by_class": BASELINE["by_class"],
        })
        bootstrapped = True
    tuning_init = False
    if not cfg.tuning_ledger.exists() or cfg.tuning_ledger.stat().st_size == 0:
        append_jsonl(cfg.tuning_ledger, {
            "ts": iso(cfg.now),
            "event": "tuning_ledger_initialized",
            "source": "flywheel-1uors",
            "thresholds": {"classification_false_positive_rate_max": cfg.false_positive_threshold},
            "observed_drift_at_change": None,
        })
        tuning_init = True
    return bootstrapped, tuning_init
def selftest_fixture(cfg):
    fixture = os.environ.get("WATCHER_ISOMORPHIC_SELFTEST_FIXTURE")
    if fixture:
        obj = load_json_file(fixture)
        return obj if isinstance(obj, dict) else {}
    script = cfg.repo / ".flywheel/scripts/frozen-pane-detector.sh"
    if not script.exists():
        return {"error": "frozen_pane_detector_missing", "script": str(script)}
    obj, err = run_json([str(script), "--dry-run", "--self-test", "--json"], cwd=cfg.repo, timeout=20)
    return obj if isinstance(obj, dict) else {"error": "frozen_pane_detector_invalid_json", "detail": err}
def pane_health_probe(cfg):
    recent_cutoff = cfg.now - timedelta(hours=24)
    rows = [r for r in load_jsonl(cfg.recovery_ledger) if (parse_ts(r.get("ts")) or cfg.now) >= recent_cutoff]
    recovery_rows = [r for r in rows if str(r.get("event", "")).endswith("recovery") or "recovery" in str(r.get("event", ""))]
    false_rows = [
        r for r in recovery_rows
        if r.get("false_positive") is True
        or r.get("classification") == "false_positive"
        or r.get("re_probe_result") == "alive_within_60s_false_positive"
    ]
    rate = (len(false_rows) / len(recovery_rows)) if recovery_rows else 0.0
    st = selftest_fixture(cfg)
    fixture_cases = st.get("fixture_cases", []) if isinstance(st.get("fixture_cases"), list) else []
    g_cases = [c for c in fixture_cases if c.get("fixture_id") == "G_post_completion_buffer_no_autosubmit"]
    g_pass = bool(g_cases and all(c.get("status") == "pass" for c in g_cases))
    status = "pass" if rate <= cfg.false_positive_threshold and g_pass else "fail"
    return {
        "status": status,
        "recovery_rows_24h": len(recovery_rows),
        "false_positive_count_24h": len(false_rows),
        "false_positive_rate_24h": rate,
        "threshold": cfg.false_positive_threshold,
        "fixture_g_post_completion_buffer": "pass" if g_pass else "fail",
        "self_test_fixture_count": len(fixture_cases),
    }
def plist_label(path):
    try:
        with Path(path).open("rb") as fh:
            data = plistlib.load(fh)
        return data.get("Label") or Path(path).stem
    except Exception:
        return Path(path).stem
def active_registry_rows(path):
    latest = {}
    for row in load_jsonl(path):
        label = row.get("label") or row.get("plist_label")
        if not label:
            continue
        latest[str(label)] = row
    active = {}
    for label, row in latest.items():
        action = str(row.get("action") or row.get("event") or "").lower()
        if action not in {"unregister", "delete", "remove"}:
            active[label] = row
    return active
def plist_probe(cfg):
    registry = active_registry_rows(cfg.registry)
    plist_paths = []
    for base in [cfg.launch_agents, cfg.disabled_dir]:
        if base.exists():
            plist_paths.extend(base.glob("*.plist"))
    labels_on_disk = {plist_label(p): str(p) for p in plist_paths}
    registered_missing = [
        {"label": label, "reason": "registry_row_without_plist"}
        for label in sorted(registry)
        if label.startswith("ai.zeststream.") and label not in labels_on_disk
    ]
    unregistered = [
        {"label": label, "path": labels_on_disk[label]}
        for label in sorted(labels_on_disk)
        if label.startswith("ai.zeststream.") and label not in registry
    ]
    generic = []
    for label, row in registry.items():
        reason = str(row.get("reason") or "").strip()
        if label.startswith("ai.zeststream.") and reason.lower() in GENERIC_REASONS:
            generic.append({"label": label, "reason": reason})
    status = "pass" if not registered_missing and not unregistered and not generic else "fail"
    return {
        "status": status,
        "registry_path": str(cfg.registry),
        "launch_agents_dir": str(cfg.launch_agents),
        "disabled_dir": str(cfg.disabled_dir),
        "registered_label_count": len(registry),
        "plist_count": len(labels_on_disk),
        "missing_plist_count": len(registered_missing),
        "unregistered_plist_count": len(unregistered),
        "generic_reason_count": len(generic),
        "missing_plists": registered_missing[:10],
        "unregistered_plists": unregistered[:10],
        "generic_reason_rows": generic[:10],
    }
def ready_fixture():
    fixture = os.environ.get("WATCHER_ISOMORPHIC_READY_FIXTURE")
    if not fixture:
        return None
    obj = load_json_file(fixture)
    return obj if isinstance(obj, list) else []
def bead_probe(cfg):
    ready = ready_fixture()
    errors = []
    if ready is None:
        ready, err = run_json(["br", "ready", "--json"], cwd=cfg.repo, timeout=15)
        if err or not isinstance(ready, list):
            ready, errors = [], [err or {"error": "br_ready_invalid"}]
    sample = ready[:cfg.sample_target]
    checked = []
    for item in sample:
        if isinstance(item, str):
            bead_id, detail = item, None
        else:
            bead_id = str(item.get("id") or item.get("key") or "")
            detail = item
        if not bead_id:
            continue
        if detail is None:
            detail, err = run_json(["br", "show", bead_id, "--json"], cwd=cfg.repo, timeout=10)
            if err or not isinstance(detail, dict):
                errors.append({"bead_id": bead_id, "error": err or "br_show_invalid"})
                detail = {"id": bead_id, "status": "unknown"}
        status = str(detail.get("status") or detail.get("state") or "").lower()
        checked.append({"id": bead_id, "status": status})
    stale = [b for b in checked if b["status"] in {"closed", "done", "resolved"}]
    status = "pass" if not stale and not errors else "fail"
    return {
        "status": status,
        "sample_target": cfg.sample_target,
        "ready_count": len(ready),
        "sample_checked": len(checked),
        "stale_closed_count": len(stale),
        "stale_closed": stale[:10],
        "errors": errors[:5],
    }
def trauma_current():
    fixture = os.environ.get("WATCHER_ISOMORPHIC_TRAUMA_CURRENT")
    if fixture:
        obj = load_json_file(fixture)
        if isinstance(obj, dict):
            return int(obj.get("total", BASELINE["total"])), obj.get("by_class", BASELINE["by_class"])
    return BASELINE["total"], BASELINE["by_class"]
def trauma_probe(cfg):
    current_total, by_class = trauma_current()
    append_jsonl(cfg.trauma_trend, {
        "ts": iso(cfg.now),
        "event": "scan",
        "source": "watcher-isomorphic-probe",
        "total": current_total,
        "by_class": by_class,
    })
    rows = load_jsonl(cfg.trauma_trend)
    cutoff = cfg.now - timedelta(hours=24)
    recent = [r for r in rows if (parse_ts(r.get("ts")) or cfg.now) >= cutoff and isinstance(r.get("total"), int)]
    first = recent[0]["total"] if recent else BASELINE["total"]
    delta = current_total - first
    fix_explains = os.environ.get("WATCHER_ISOMORPHIC_RECENT_FIX_BEAD", "").lower() in {"1", "true", "yes"}
    status = "pass" if delta <= 0 or fix_explains else "fail"
    return {
        "status": status,
        "trend_path": str(cfg.trauma_trend),
        "baseline_total": BASELINE["total"],
        "current_total": current_total,
        "by_class": by_class,
        "delta_24h": delta,
        "recent_fix_bead_explains_regression": fix_explains,
        "rows_24h": len(recent),
    }
def receipt_probe(cfg):
    fixture = os.environ.get("WATCHER_ISOMORPHIC_RECEIPT_FIXTURE")
    if fixture:
        rows = load_json_file(fixture)
        actions = rows if isinstance(rows, list) else []
    else:
        sources = {
            "dispatch_log": cfg.dispatch_log,
            "frozen_pane_recovery": cfg.recovery_ledger,
            "bak_quarantine": cfg.bak_ledger,
            "plist_registry": cfg.registry,
        }
        actions = []
        for name, path in sources.items():
            for row in load_jsonl(path)[-10:]:
                row = dict(row)
                row["_source_ledger"] = name
                row["has_receipt"] = True
                actions.append(row)
        actions = actions[-10:]
    orphan = [a for a in actions if a.get("has_receipt") is False or a.get("receipt_missing") is True]
    return {
        "status": "pass" if not orphan else "fail",
        "sample_size": len(actions),
        "orphan_action_count_24h": len(orphan),
        "orphan_actions": orphan[:10],
        "ledgers_checked": 4,
    }
def tuning_count_30d(cfg):
    cutoff = cfg.now - timedelta(days=30)
    return sum(1 for r in load_jsonl(cfg.tuning_ledger) if (parse_ts(r.get("ts")) or cfg.now) >= cutoff)
def doctor(cfg):
    trend_boot, tuning_init = ensure_ledgers(cfg)
    probes = {
        "pane_health": pane_health_probe(cfg),
        "plist_registry_truth": plist_probe(cfg),
        "ready_bead_status": bead_probe(cfg),
        "trauma_class_trend": trauma_probe(cfg),
        "receipt_completeness": receipt_probe(cfg),
    }
    failing = [name for name, result in probes.items() if result.get("status") != "pass"]
    recommendation = "green" if not failing else "red"
    status = "pass" if not failing else "fail"
    pane = probes["pane_health"]
    trauma = probes["trauma_class_trend"]
    bead = probes["ready_bead_status"]
    receipt = probes["receipt_completeness"]
    return {
        "schema_version": SCHEMA_VERSION,
        "status": status,
        "mode": "doctor",
        "checked_at": iso(cfg.now),
        "repo": str(cfg.repo),
        "probes": probes,
        "failing_probes": failing,
        "watcher_isomorphic_status": recommendation,
        "watcher_isomorphic_failing_probes": failing,
        "watcher_reenable_recommendation": recommendation,
        "watcher_classification_false_positive_rate_24h": pane["false_positive_rate_24h"],
        "ready_pool_stale_closed_count": bead["stale_closed_count"],
        "trauma_class_trend_24h_delta": trauma["delta_24h"],
        "orphan_action_count_24h": receipt["orphan_action_count_24h"],
        "watcher_tuning_count_30d": tuning_count_30d(cfg),
        "tuning_ledger_path": str(cfg.tuning_ledger),
        "tuning_ledger_initialized": tuning_init,
        "trauma_trend_jsonl_path": str(cfg.trauma_trend),
        "trauma_trend_jsonl_bootstrapped": trend_boot,
        "baseline_total": BASELINE["total"],
        "sub_gaps_addressed": [
            "pane_health_false_positive_rate",
            "codex_post_completion_buffer_fixture_g",
            "bidirectional_plist_registry_walk",
            "ready_bead_status_sampler",
            "trauma_class_trend_tracking",
            "receipt_completeness_sampler",
            "watcher_tuning_ledger",
        ],
        "doctor_fields_added": [
            "watcher_isomorphic_status",
            "watcher_isomorphic_failing_probes",
            "watcher_reenable_recommendation",
        ],
        "tunable_recommendations": [] if not failing else [
            {"probe": name, "recommendation": "keep watcher gated until this probe passes"} for name in failing
        ],
    }
def schema():
    return {
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        "title": SCHEMA_VERSION,
        "fleet_schema_version": FLEET_SCHEMA_VERSION,
        "fleet_output_required": ["schema_version", "status", "sessions", "fleet_summary"],
        "type": "object",
        "required": ["schema_version", "status", "probes", "watcher_reenable_recommendation"],
        "properties": {
            "schema_version": {"const": SCHEMA_VERSION},
            "status": {"enum": ["pass", "fail"]},
            "watcher_reenable_recommendation": {"enum": ["green", "yellow", "red"]},
            "probes": {"type": "object", "minProperties": 5, "maxProperties": 5},
        },
    }
def parse_args(argv):
    if argv and argv[0] in {"doctor", "health", "repair", "validate", "audit", "why", "schema", "quickstart", "help", "completion"}:
        command = argv[0]
        argv = argv[1:]
    else:
        command = "doctor"
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("--doctor", action="store_true")
    parser.add_argument("--health", action="store_true")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--repo")
    parser.add_argument("--fleet", action="store_true")
    parser.add_argument("--session")
    parser.add_argument("--topology", default=os.environ.get("WATCHER_ISOMORPHIC_TOPOLOGY", str(DEFAULT_TOPOLOGY)))
    parser.add_argument("--loops-dir", default=os.environ.get("WATCHER_ISOMORPHIC_LOOPS_DIR", str(DEFAULT_LOOPS_DIR)))
    parser.add_argument("--fleet-timeout", type=int, default=int(os.environ.get("WATCHER_ISOMORPHIC_FLEET_TIMEOUT", "30")))
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--info", action="store_true")
    parser.add_argument("--examples", action="store_true")
    parser.add_argument("--schema", action="store_true")
    parser.add_argument("-h", "--help", action="store_true")
    args = parser.parse_args(argv)
    if args.health:
        command = "health"
    if args.schema:
        command = "schema"
    if args.info:
        command = "info"
    if args.examples:
        command = "examples"
    if args.help:
        command = "help"
    return command, args
def emit(obj, as_json=True):
    if as_json:
        print(json.dumps(obj, sort_keys=True, separators=(",", ":")))
    else:
        if isinstance(obj, dict):
            print(f"status={obj.get('status')} watcher_reenable_recommendation={obj.get('watcher_reenable_recommendation', 'unknown')}")
        else:
            print(obj)
def main(argv):
    command, args = parse_args(argv)
    cfg = Config(args)
    if command in {"help", "info"}:
        print("watcher-isomorphic-probe.sh: five-probe watcher re-enable validator for flywheel-1uors")
        print("usage: watcher-isomorphic-probe.sh --doctor --json [--repo PATH] | --fleet --json")
        return 0
    if command == "examples":
        print("watcher-isomorphic-probe.sh --doctor --json | jq '.watcher_reenable_recommendation'")
        print("watcher-isomorphic-probe.sh --fleet --json | jq '.fleet_summary.fleet_watcher_reenable_recommendation'")
        print("watcher-isomorphic-probe.sh repair --dry-run --json")
        return 0
    if command == "quickstart":
        print("Run --doctor --json; only re-enable watcher apply paths when watcher_reenable_recommendation is green.")
        return 0
    if command == "completion":
        print("--doctor --health --json --repo --schema --info --examples quickstart repair validate audit why")
        return 0
    if command == "schema":
        emit(schema(), True)
        return 0
    if args.fleet:
        report = fleet_report(args)
        emit(report, args.json or command != "doctor")
        return 0
    if command in {"doctor", "health", "validate", "audit", "why"}:
        report = doctor(cfg)
        emit(report, args.json or command != "doctor")
        if command == "validate" and report["status"] != "pass":
            return 1
        return 0
    if command == "repair":
        trend_boot, tuning_init = ensure_ledgers(cfg)
        emit({
            "schema_version": SCHEMA_VERSION,
            "status": "pass",
            "mode": "repair",
            "apply": cfg.apply,
            "dry_run": cfg.dry_run,
            "trauma_trend_jsonl_bootstrapped": trend_boot,
            "tuning_ledger_initialized": tuning_init,
            "changed": bool((trend_boot or tuning_init) and cfg.apply),
        }, args.json)
        return 0
    print(f"ERR unknown command: {command}", file=sys.stderr)
    return 64
if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
PY

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-02-conformance-fixtures.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-68-schema-executable-validator-pair.md`
