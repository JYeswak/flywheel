#!/usr/bin/env bash
set -euo pipefail

python3 - "$@" <<'PY'
import argparse
import json
import os
import re
import statistics
import subprocess
import sys
import tempfile
from datetime import datetime, timedelta, timezone
from pathlib import Path

SCHEMA_VERSION = "architecture-health-rollup/v1"
PERIODS = {"24h": 24, "7d": 168, "30d": 720, "90d": 2160}
DEFAULT_IDENTITY_DIR = Path.home() / ".local/state/flywheel/orch-worker-identity"
DEFAULT_STATE_DIR = Path.home() / ".flywheel/fleet-perf"
DEFAULT_FUCKUP_LOG = Path.home() / ".local/state/flywheel/fuckup-log.jsonl"


def iso_now():
    return datetime.now(timezone.utc)


def iso(dt):
    return dt.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def parse_ts(value):
    if not value:
        return None
    try:
        return datetime.fromisoformat(str(value).replace("Z", "+00:00")).astimezone(timezone.utc)
    except Exception:
        return None


def read_jsonl(path):
    rows = []
    path = Path(path).expanduser()
    if not path.exists():
        return rows
    for line_no, line in enumerate(path.read_text(encoding="utf-8", errors="ignore").splitlines(), start=1):
        if not line.strip():
            continue
        try:
            row = json.loads(line)
            if isinstance(row, dict):
                row["_source_line"] = line_no
                rows.append(row)
        except Exception:
            continue
    return rows


def read_json(path):
    try:
        data = json.loads(Path(path).read_text(encoding="utf-8", errors="ignore"))
        return data if isinstance(data, dict) else None
    except Exception:
        return None


def event_ts(row):
    for key in ("ts", "callback_received_at", "validated_at", "closed_at", "updated_at", "created_at"):
        parsed = parse_ts(row.get(key))
        if parsed:
            return parsed
    return None


def in_window(row, start, end):
    ts = event_ts(row)
    return ts is not None and start <= ts <= end


def task_text(row):
    return " ".join(str(row.get(k, "")) for k in ("task_summary", "task_file", "title", "description", "callback_status", "status", "notes"))


def work_type(text):
    t = text.lower()
    if any(s in t for s in ("l-rule", "doctrine", "agents.md", "canonical")):
        return "doctrine"
    if any(s in t for s in ("probe", "doctor", "status", "slo")):
        return "probe"
    if "skill" in t:
        return "skill"
    if any(s in t for s in ("recovery", "respawn", "frozen")):
        return "recovery"
    if any(s in t for s in ("dispatch", "worker", "orchestrator")):
        return "coordination"
    return "other"


def leverage_weight(text):
    t = text.lower()
    if any(s in t for s in ("paradigm", "mission", "l98", "l99", "l-rule", "doctrine")):
        return 5
    if any(s in t for s in ("rule", "gate", "doctor", "status", "probe", "skill")):
        return 4
    if any(s in t for s in ("threshold", "cadence", "fixture", "test")):
        return 2
    return 1


def dispatch_rows(rows, start, end):
    out = []
    for row in rows:
        if not in_window(row, start, end):
            continue
        ev = str(row.get("event", ""))
        if ev.startswith("callback"):
            continue
        if row.get("task_id") and (row.get("task_file") or row.get("task_summary") or row.get("to") or row.get("pane") is not None):
            out.append(row)
    return out


def callback_rows(rows, start, end):
    out = []
    for row in rows:
        if not in_window(row, start, end):
            continue
        ev = str(row.get("event", ""))
        if ev.startswith("callback") or row.get("callback_received_at"):
            out.append(row)
    return out


def dispatch_rework_counts(dispatches):
    task_counts = {}
    for row in dispatches:
        task_id = row.get("task_id")
        if not task_id:
            continue
        key = str(task_id)
        task_counts[key] = task_counts.get(key, 0) + 1
    redispatched_task_ids = sum(1 for count in task_counts.values() if count > 1)
    redispatch_rows = sum(count - 1 for count in task_counts.values() if count > 1)
    return len(task_counts), redispatched_task_ids, redispatch_rows


def validation_rows(validation_dir, start, end):
    rows = []
    root = Path(validation_dir).expanduser()
    if not root.exists():
        return rows
    for path in root.rglob("*.json"):
        row = read_json(path)
        if not row:
            continue
        row["_path"] = str(path)
        ts = event_ts(row) or parse_ts(row.get("checked_at"))
        if ts and start <= ts <= end:
            rows.append(row)
    return rows


def verdict_counts(rows):
    passed = failed = invalid = 0
    for row in rows:
        text = " ".join(str(row.get(k, "")) for k in ("verdict", "status", "decision", "result")).lower()
        if any(s in text for s in ("fail", "blocked", "invalid", "reject")):
            failed += 1
        elif any(s in text for s in ("pass", "safe", "done", "ok", "no-bead-receipt")):
            passed += 1
        else:
            invalid += 1
    return passed, failed, invalid


def closed_beads(path, start, end):
    rows = []
    for row in read_jsonl(path):
        if str(row.get("status", "")).lower() == "closed" and in_window(row, start, end):
            rows.append(row)
    return rows


def incident_commit_count(repo, start):
    paths = ["INCIDENTS.md", ".flywheel/INCIDENTS.md", ".flywheel/fuckup-log"]
    cmd = ["git", "-C", str(repo), "log", "--since", iso(start), "--format=%H", "--"] + paths
    try:
        out = subprocess.check_output(cmd, text=True, stderr=subprocess.DEVNULL)
        return len([line for line in out.splitlines() if line.strip()])
    except Exception:
        return 0


def load_identities(identity_dir):
    identities = []
    root = Path(identity_dir).expanduser()
    if not root.exists():
        return identities
    for path in sorted(root.glob("*.json")):
        manifest = read_json(path)
        if not manifest:
            continue
        session = manifest.get("session") or path.stem
        for worker in manifest.get("workers", []) or []:
            pane = worker.get("pane")
            registry = read_json(worker.get("registry_source") or "") or {}
            project = registry.get("fleet_mail_project_key") or manifest.get("fleet_mail_project_key") or "unknown"
            identities.append({
                "agent_id": f"{session}:{pane}:{project}",
                "session": session,
                "pane": pane,
                "project": project,
                "current_identity": worker.get("fleet_mail_identity"),
                "registration_status": worker.get("registration_status"),
            })
    return identities


def skill_citation_count(rows):
    total = 0
    for row in rows:
        txt = json.dumps(row, sort_keys=True).lower()
        total += len(re.findall(r"skills?_consulted|skills? cited|skill:", txt))
    return total


def structural_fix_count(dispatches, callbacks, incident_commits, closed):
    text_rows = dispatches + callbacks + closed
    hits = sum(1 for row in text_rows if leverage_weight(task_text(row)) >= 4)
    return hits + incident_commits


def safe_ratio(num, den):
    return round(num / den, 4) if den else 0


def median(values):
    return round(statistics.median(values), 4) if values else 0


def detect_agent_shaming(reports_dir, start, end):
    patterns = [
        r"\bbest agents?\b",
        r"\bworst agents?\b",
        r"\bagent leaderboard\b",
        r"\bperformance review of named agents?\b",
    ]
    hits = []
    root = Path(reports_dir).expanduser()
    if not root.exists():
        return hits
    for path in root.rglob("*"):
        if not path.is_file() or path.suffix.lower() not in {".md", ".json", ".txt"}:
            continue
        mtime = datetime.fromtimestamp(path.stat().st_mtime, timezone.utc)
        if not (start <= mtime <= end):
            continue
        text = path.read_text(encoding="utf-8", errors="ignore").lower()
        if any(re.search(p, text) for p in patterns):
            hits.append(str(path))
    return hits


def build_period(args, period, now):
    hours = PERIODS[period]
    end = now
    start = end - timedelta(hours=hours)
    prev_start = start - timedelta(hours=hours)
    dispatch_log = Path(args.dispatch_log).expanduser()
    all_dispatch_rows = read_jsonl(dispatch_log)
    dispatches = dispatch_rows(all_dispatch_rows, start, end)
    callbacks = callback_rows(all_dispatch_rows, start, end)
    prev_dispatches = dispatch_rows(all_dispatch_rows, prev_start, start)
    prev_callbacks = callback_rows(all_dispatch_rows, prev_start, start)
    validations = validation_rows(args.validation_dir, start, end)
    valid_pass, valid_fail, valid_unknown = verdict_counts(validations)
    fuckups = [r for r in read_jsonl(args.fuckup_log) if in_window(r, start, end)]
    closed = closed_beads(args.beads_jsonl, start, end)
    incident_commits = incident_commit_count(args.repo, start)
    identities = load_identities(args.identity_dir)
    shaming_hits = detect_agent_shaming(args.reports_dir, start, end)

    by_task = {str(row.get("task_id")): row for row in dispatches if row.get("task_id")}
    callback_task_ids = {str(row.get("task_id")) for row in callbacks if row.get("task_id")}
    callback_task_ids |= {str(row.get("dispatch_id")) for row in callbacks if row.get("dispatch_id")}
    callbacks_for_dispatches = sum(1 for task_id in by_task if task_id in callback_task_ids)
    unique_dispatch_task_ids, redispatched_task_ids, redispatch_rows = dispatch_rework_counts(dispatches)
    reliability = safe_ratio(callbacks_for_dispatches, len(by_task))
    faithfulness = safe_ratio(valid_pass, valid_pass + valid_fail + valid_unknown)
    skill_citations = skill_citation_count(dispatches + callbacks + validations)
    structural_fixes = structural_fix_count(dispatches, callbacks, incident_commits, closed)
    rework_event_count = valid_fail + redispatch_rows
    rework_ratio = round(rework_event_count / max(len(dispatches), 1), 4)
    architecture_debt_observation_ratio = safe_ratio(len(fuckups), max(len(dispatches), 1))
    founder_dispose_mentions = sum(1 for row in dispatches + callbacks if "joshua-dispose" in json.dumps(row).lower() or "founder" in json.dumps(row).lower())
    founder_dispose_pct = round(100 * founder_dispose_mentions / max(len(dispatches) + len(callbacks), 1), 2)
    leverage_now = safe_ratio(structural_fixes + skill_citations, max(len(dispatches), 1))
    prev_structural = structural_fix_count(prev_dispatches, prev_callbacks, 0, [])
    prev_skill = skill_citation_count(prev_dispatches + prev_callbacks)
    leverage_prev = safe_ratio(prev_structural + prev_skill, max(len(prev_dispatches), 1))
    leverage_trend_pct = 0 if leverage_prev == 0 else round(100 * (leverage_now - leverage_prev) / leverage_prev, 2)
    coordination_clean = safe_ratio(
        sum(1 for row in dispatches + callbacks if "coord" in task_text(row).lower() or "cross-orch" in json.dumps(row).lower()),
        max(len(dispatches) + len(callbacks), 1),
    )

    per_agent = []
    reliability_values = []
    for ident in identities:
        pane_dispatches = [row for row in dispatches if str(row.get("session") or "flywheel") == ident["session"] and str(row.get("pane")) == str(ident["pane"])]
        pane_tasks = {str(row.get("task_id")) for row in pane_dispatches if row.get("task_id")}
        pane_callbacks = sum(1 for task_id in pane_tasks if task_id in callback_task_ids)
        pane_reliability = safe_ratio(pane_callbacks, len(pane_tasks))
        reliability_values.append(pane_reliability)
        per_agent.append({
            "agent_id": ident["agent_id"],
            "session": ident["session"],
            "pane": ident["pane"],
            "project": ident["project"],
            "current_identity_pointer": ident["current_identity"],
            "registration_status": ident["registration_status"],
            "vectors": {
                "reliability": pane_reliability,
                "faithfulness": faithfulness,
                "leverage": safe_ratio(sum(leverage_weight(task_text(row)) for row in pane_dispatches), max(len(pane_dispatches), 1)),
                "reuse": safe_ratio(skill_citation_count(pane_dispatches), max(len(pane_dispatches), 1)),
                "coordination": coordination_clean,
                "drift_authoring": safe_ratio(structural_fixes, max(len(fuckups), 1)),
            },
        })

    metric_contracts = [
        {"metric": "reliability", "trend": True, "cohort": True, "counterfactual": "callback delivery can improve while validation quality worsens; paired with faithfulness"},
        {"metric": "faithfulness", "trend": True, "cohort": True, "counterfactual": "validation pass rate can rise by doing easier work; paired with leverage weighting"},
        {"metric": "leverage", "trend": True, "cohort": True, "counterfactual": "throughput without doctrine/skill/probe changes is vanity work"},
        {"metric": "reuse", "trend": True, "cohort": True, "counterfactual": "one-off artifacts evaporate if not cited by later dispatches"},
        {"metric": "coordination", "trend": True, "cohort": True, "counterfactual": "more messages can mean confusion unless callbacks close cleanly"},
        {"metric": "drift_authoring", "trend": True, "cohort": True, "counterfactual": "fuckups without structural fixes indicate architecture debt"},
        {"metric": "founder_dispose_pct", "trend": True, "cohort": True, "counterfactual": "flat or rising founder decisions means company-outgrowing-founder is failing"},
        {"metric": "rework_ratio", "trend": True, "cohort": True, "counterfactual": "fast completion can hide rework unless validation failures and duplicate dispatch attempts are counted"},
        {"metric": "architecture_debt_observation_ratio", "trend": True, "cohort": True, "counterfactual": "rework can look low while unresolved architecture-debt observations accumulate"},
    ]
    unpaired = sum(1 for item in metric_contracts if not (item["trend"] and item["cohort"] and item["counterfactual"]))
    status = "green"
    if shaming_hits or unpaired > 0 or rework_ratio > 1 or architecture_debt_observation_ratio > 1 or founder_dispose_pct > 50:
        status = "red"
    elif rework_ratio > 0.3 or architecture_debt_observation_ratio > 0.3 or founder_dispose_pct > 20 or valid_fail > valid_pass:
        status = "yellow"

    work_types = {}
    for row in dispatches:
        wt = work_type(task_text(row))
        work_types.setdefault(wt, {"count": 0, "weight": 0})
        work_types[wt]["count"] += 1
        work_types[wt]["weight"] += leverage_weight(task_text(row))

    payload = {
        "schema_version": SCHEMA_VERSION,
        "period": period,
        "window_hours": hours,
        "generated_at": iso(now),
        "window_start": iso(start),
        "window_end": iso(end),
        "status": status,
        "architecture_health_status": status,
        "dashboard_line": f"Architecture Health: {status} | leverage_trend={leverage_trend_pct:+.0f}%/30d | rework_ratio={rework_ratio:.2f} | debt_observation_ratio={architecture_debt_observation_ratio:.2f} | founder_dispose_pct={founder_dispose_pct:.0f}%",
        "architecture_health_metric_unpaired_count": unpaired,
        "agent_shaming_report_detected": bool(shaming_hits),
        "agent_shaming_report_paths": shaming_hits,
        "learning_loop_closed": "yes" if structural_fixes > 0 or status == "green" else "no",
        "source_counts": {
            "dispatches": len(dispatches),
            "callbacks": len(callbacks),
            "validation_receipts": len(validations),
            "validation_pass": valid_pass,
            "validation_fail": valid_fail,
            "validation_unknown": valid_unknown,
            "fuckup_rows": len(fuckups),
            "architecture_debt_observation_rows": len(fuckups),
            "unique_dispatch_task_ids": unique_dispatch_task_ids,
            "redispatched_task_ids": redispatched_task_ids,
            "redispatch_rows": redispatch_rows,
            "rework_event_count": rework_event_count,
            "closed_beads": len(closed),
            "incident_commits": incident_commits,
            "identity_vectors": len(per_agent),
        },
        "fleet_metrics": {
            "reliability": reliability,
            "faithfulness": faithfulness,
            "leverage": leverage_now,
            "reuse": safe_ratio(skill_citations, max(len(dispatches), 1)),
            "coordination": coordination_clean,
            "drift_authoring": safe_ratio(structural_fixes, max(len(fuckups), 1)),
            "rework_ratio": rework_ratio,
            "architecture_debt_observation_ratio": architecture_debt_observation_ratio,
            "founder_dispose_pct": founder_dispose_pct,
            "leverage_trend_30d_pct": leverage_trend_pct,
        },
        "cohort_comparisons": {
            "this_orch": args.session,
            "fleet_median_reliability": median(reliability_values),
            "this_orch_vs_fleet_median_reliability": round(reliability - median(reliability_values), 4),
            "work_type_weighted": work_types,
        },
        "identity_vectors": per_agent,
        "metric_contracts": metric_contracts,
        "candidate_l_rules": [] if status == "green" else ["architecture-health-threshold-crossing"],
        "candidate_skill_promotions": [] if skill_citations else ["skill-citation-required-for-rollups"],
        "candidate_probe_additions": [] if not shaming_hits else ["agent-shaming-report-detector"],
        "report_policy": {
            "agent_shaming_reports_forbidden": True,
            "individual_rankings_emitted": False,
            "route_findings_to": ["doctrine", "skills", "probes"],
        },
    }
    return payload


def atomic_write(path, payload):
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(prefix=f".{path.name}.", suffix=".tmp", dir=str(path.parent))
    with os.fdopen(fd, "w", encoding="utf-8") as handle:
        json.dump(payload, handle, sort_keys=True, indent=2)
        handle.write("\n")
    os.replace(tmp, path)


def print_payload(payload, as_json):
    if as_json:
        print(json.dumps(payload, sort_keys=True, separators=(",", ":")))
    else:
        print(payload.get("dashboard_line", json.dumps(payload, sort_keys=True)))


def schema():
    return {
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        "schema_version": SCHEMA_VERSION,
        "required": ["schema_version", "period", "architecture_health_status", "fleet_metrics", "metric_contracts"],
        "properties": {
            "architecture_health_status": {"enum": ["green", "yellow", "red"]},
            "architecture_health_metric_unpaired_count": {"type": "integer"},
            "agent_shaming_report_detected": {"type": "boolean"},
        },
    }


def main(argv):
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", default=os.getcwd())
    parser.add_argument("--session", default="flywheel")
    parser.add_argument("--period", choices=list(PERIODS) + ["all"], default="30d")
    parser.add_argument("--dispatch-log", default=".flywheel/dispatch-log.jsonl")
    parser.add_argument("--validation-dir", default=".flywheel/validation-receipts")
    parser.add_argument("--beads-jsonl", default=".beads/issues.jsonl")
    parser.add_argument("--fuckup-log", default=str(DEFAULT_FUCKUP_LOG))
    parser.add_argument("--identity-dir", default=str(DEFAULT_IDENTITY_DIR))
    parser.add_argument("--reports-dir", default=".flywheel/reports")
    parser.add_argument("--state-dir", default=str(DEFAULT_STATE_DIR))
    parser.add_argument("--now")
    parser.add_argument("--write", action="store_true")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--info", action="store_true")
    parser.add_argument("--schema", action="store_true")
    parser.add_argument("--examples", action="store_true")
    args = parser.parse_args(argv)

    if args.info:
        print_payload({"schema_version": "canonical-cli-info/v1", "name": "architecture-health-rollup", "summary": "Fleet architecture-health rollup with anti-agent-shaming metric contracts.", "dry_run_default": True, "write_requires": "--write", "periods": list(PERIODS)}, args.json)
        return 0
    if args.schema:
        print_payload(schema(), True)
        return 0
    if args.examples:
        print_payload({"examples": [
            ".flywheel/scripts/architecture-health-rollup.sh --period 30d --json",
            ".flywheel/scripts/architecture-health-rollup.sh --period all --write --json",
            "jq '.fleet_metrics,.candidate_l_rules' ~/.flywheel/fleet-perf/7d.json",
        ]}, args.json)
        return 0

    args.repo = str(Path(args.repo).expanduser().resolve())
    base = Path(args.repo)
    for attr in ("dispatch_log", "validation_dir", "beads_jsonl", "reports_dir"):
        value = Path(getattr(args, attr)).expanduser()
        if not value.is_absolute():
            value = base / value
        setattr(args, attr, str(value))
    now = parse_ts(args.now) if args.now else iso_now()
    periods = list(PERIODS) if args.period == "all" else [args.period]
    payloads = {period: build_period(args, period, now) for period in periods}
    if args.write:
        state_dir = Path(args.state_dir).expanduser()
        for period, payload in payloads.items():
            atomic_write(state_dir / f"{period}.json", payload)
    if args.period == "all":
        out = {
            "schema_version": "architecture-health-rollup-run/v1",
            "generated_at": iso(now),
            "mode": "write" if args.write else "dry-run",
            "state_dir": str(Path(args.state_dir).expanduser()),
            "periods": payloads,
            "dashboard_line": payloads["30d"]["dashboard_line"],
        }
        print_payload(out, args.json)
    else:
        print_payload(payloads[args.period], args.json)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
PY

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-02-conformance-fixtures.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-68-schema-executable-validator-pair.md`
