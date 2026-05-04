#!/usr/bin/env bash
set -euo pipefail

python3 - "$@" <<'PY'
import argparse
import json
import os
import re
import subprocess
import sys
from collections import Counter
from datetime import datetime, timedelta, timezone
from pathlib import Path

SCHEMA_VERSION = "bead-quality-mining/v1"
TESTABLE_VERBS = {
    "add", "adds", "block", "blocks", "canonize", "canonizes", "canonicalize", "canonicalizes",
    "cover", "covers", "create", "creates", "detect", "detects", "document", "documents",
    "emit", "emits", "enforce", "enforces", "exist", "exists", "expose", "exposes", "fail", "fails", "flag",
    "flags", "include", "includes", "link", "links", "pass", "passes", "produce", "produces",
    "read", "reads", "reject", "rejects", "require", "requires", "return", "returns", "run",
    "runs", "surface", "surfaces", "support", "supports", "update", "updates", "validate",
    "validates", "warn", "warns", "write", "writes",
}
ARTIFACT_HINT_RE = re.compile(r"(`[^`]+`|\.flywheel/|tests/|scripts/|templates/|README\.md|AGENTS\.md|INCIDENTS\.md|doctor signal|field|JSON|CLI|command|path|file)", re.I)


def parse_ts(value):
    if not value:
        return None
    try:
        return datetime.fromisoformat(str(value).replace("Z", "+00:00"))
    except ValueError:
        return None


def now_utc(value=None):
    return parse_ts(value) or datetime.now(timezone.utc)


def iso(dt):
    return dt.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def run(cmd, cwd, check=False, timeout=30):
    proc = subprocess.run(cmd, cwd=str(cwd), text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False, timeout=timeout)
    if check and proc.returncode != 0:
        raise RuntimeError(f"{' '.join(cmd)} failed: {proc.stderr[:500]}")
    return proc


def load_json(text, default):
    try:
        return json.loads(text)
    except Exception:
        return default


def br_issues(repo, br_bin, status=None, all_issues=False):
    cmd = [br_bin, "list", "--json", "--limit", "0"]
    if all_issues:
        cmd.insert(2, "--all")
    if status:
        cmd.extend(["--status", status])
    proc = run(cmd, repo)
    data = load_json(proc.stdout, [])
    if isinstance(data, dict):
        return data.get("issues") or []
    if isinstance(data, list):
        return data
    return []


def closed_recent(repo, br_bin, since, include_ids):
    issues = br_issues(repo, br_bin, status="closed")
    result = []
    include = set(include_ids or [])
    for issue in issues:
        closed_at = parse_ts(issue.get("closed_at") or issue.get("updated_at"))
        if issue.get("id") in include or (closed_at and closed_at >= since):
            result.append(issue)
    return result


def existing_gap_ids(all_issues, orig_id):
    ids = []
    pattern = f"[{orig_id}.audit-gap]"
    for issue in all_issues:
        if pattern in str(issue.get("title") or ""):
            ids.append(issue.get("id"))
    return sorted(i for i in ids if i)


def ag_issue(kind, code, message, line_no=None, gate_id=None):
    item = {"kind": kind, "code": code, "message": message}
    if line_no is not None:
        item["line"] = line_no
    if gate_id is not None:
        item["gate_id"] = gate_id
    return item


def validate_ag_format(description):
    gates = []
    lines = description.splitlines()
    capture = False
    errors = []
    warnings = []
    seen = set()
    last_gate = None
    for idx, line in enumerate(lines, start=1):
        stripped = line.strip()
        if re.match(r"^#{1,6}\s+.+", stripped) and capture and not re.search(r"acceptance gates?", stripped, re.I):
            break
        if re.search(r"acceptance gates?", stripped, re.I):
            capture = True
            continue
        if capture:
            if not stripped:
                continue
            match = re.match(r"^AG([1-9][0-9]*):\s+(.+)$", stripped)
            if match:
                gate_id = f"AG{match.group(1)}"
                text = match.group(2).strip()
                gate = {"id": gate_id, "number": int(match.group(1)), "text": text, "line": idx}
                gates.append(gate)
                seen.add(gate_id)
                last_gate = gate_id
                words = {w.lower() for w in re.findall(r"[A-Za-z][A-Za-z0-9_-]*", text)}
                if not words.intersection(TESTABLE_VERBS):
                    warnings.append(ag_issue("warning", "ag_without_testable_verb", "AG line lacks a testable verb", idx, gate_id))
                if not ARTIFACT_HINT_RE.search(text):
                    warnings.append(ag_issue("warning", "ag_without_artifact_hint", "AG line lacks an artifact, command, file, path, JSON field, or doctor-signal hint", idx, gate_id))
                continue
            if re.match(r"^(?:[-*]\s*)?AG[0-9]+[A-Za-z][.:)]", stripped):
                errors.append(ag_issue("error", "nested_or_suffix_ag", "AG IDs must be AG1, AG2, ... with no suffixes", idx, last_gate))
                continue
            if re.match(r"^(?:[-*]\s*)?(?:[0-9]+[.)]|AG[0-9]+[.)])\s+", stripped):
                errors.append(ag_issue("error", "noncanonical_ag_numbering", "Use exact `AG<N>: <single-line assertion>` numbering", idx, last_gate))
                continue
            if stripped.startswith(("-", "*")) or line[:1].isspace():
                errors.append(ag_issue("error", "nested_ag_content", "Acceptance gates must be single-line assertions; nested bullets/continuations are not canonical", idx, last_gate))
                continue
            if gates:
                errors.append(ag_issue("error", "ag_continuation_line", "Acceptance gates must not use continuation prose after an AG line", idx, last_gate))
    if not capture:
        errors.append(ag_issue("error", "missing_acceptance_gates_section", "Bead body must include an Acceptance gates section with canonical AG lines"))
    elif not gates:
        errors.append(ag_issue("error", "acceptance_gates_section_without_ag_lines", "Acceptance gates section contains no canonical AG lines"))
    for expected, gate in enumerate(gates, start=1):
        if gate["number"] != expected:
            errors.append(ag_issue("error", "ag_sequence_gap", f"Expected AG{expected}, found {gate['id']}", gate["line"], gate["id"]))
    if len(seen) != len(gates):
        errors.append(ag_issue("error", "duplicate_ag_id", "Duplicate AG IDs are not canonical"))
    status = "pass"
    if errors:
        status = "fail"
    elif warnings:
        status = "warn"
    return {"status": status, "gate_count": len(gates), "gates": gates, "errors": errors, "warnings": warnings}


def parse_ags(description):
    return validate_ag_format(description)["gates"]


def rel_path(repo, text):
    p = Path(os.path.expanduser(text))
    if not p.is_absolute():
        p = repo / p
    return p


def doctor_json(repo, skip_loop=False):
    if skip_loop or os.environ.get("BEAD_QUALITY_MINING_SKIP_FLYWHEEL_DOCTOR") == "1":
        fixture = os.environ.get("BEAD_QUALITY_DOCTOR_JSON_FILE")
        if fixture:
            data = load_json(Path(fixture).read_text(), {})
            return data if isinstance(data, dict) else {}
        return {}
    fixture = os.environ.get("BEAD_QUALITY_DOCTOR_JSON_FILE")
    if fixture:
        data = load_json(Path(fixture).read_text(), {})
        return data if isinstance(data, dict) else {}
    loop = os.environ.get("FLYWHEEL_LOOP_BIN", str(Path.home() / ".claude/skills/.flywheel/bin/flywheel-loop"))
    try:
        proc = run([loop, "doctor", "--repo", str(repo), "--json"], repo, timeout=60)
        data = load_json(proc.stdout, {})
        return data if isinstance(data, dict) else {}
    except Exception:
        return {}


def derive_checks(repo, gate, doctor):
    text = gate["text"]
    checks = []
    seen = set()
    slash_commands = {
        "/flywheel:learn": str(Path.home() / ".claude/commands/flywheel/learn.md"),
        "/flywheel:daily-report": str(Path.home() / ".claude/commands/flywheel/daily-report.md"),
        "/flywheel:worker-tick": str(Path.home() / ".claude/commands/flywheel/worker-tick.md"),
        "/flywheel:status": str(Path.home() / ".claude/commands/flywheel/status.md"),
    }
    for raw in re.findall(r"`([^`]+)`", text):
        if raw in slash_commands:
            token = slash_commands[raw]
            if Path(token).exists() and token not in seen:
                seen.add(token)
                checks.append({"type": "path", "value": token})
            continue
        if raw.startswith("/") or raw.startswith(".") or raw.startswith("tests/") or raw.startswith("scripts/") or "/" in raw:
            token = raw.split()[0].rstrip(".,;:")
            if token and token not in seen:
                seen.add(token)
                checks.append({"type": "path", "value": token})
    for token in re.findall(r"(?<![\w/.-])((?:\.flywheel|tests|scripts|templates|README|AGENTS|INCIDENTS)[A-Za-z0-9_./-]*)", text):
        token = token.rstrip(".,;:")
        if token == "INCIDENTS" and not (repo / token).exists() and (repo / "INCIDENTS.md").exists():
            token = "INCIDENTS.md"
        if token and token not in seen:
            seen.add(token)
            checks.append({"type": "path", "value": token})
    for token in re.findall(r"\b([a-z][a-z0-9_]*(?:_count|_signal|_drift|_gap|_pending|_classes))\b", text):
        if token not in seen and ("doctor" in text.lower() or "signal" in text.lower() or token.endswith("_count")):
            seen.add(token)
            checks.append({"type": "doctor_signal", "value": token})
    if re.search(r"tests?\s*=\s*SKIPPED|tests skipped|SKIPPED", text, re.I):
        checks.append({"type": "tests_skipped", "value": "tests_skipped"})
    return checks


def nested_has_key(obj, key):
    if isinstance(obj, dict):
        if key in obj:
            return True
        return any(nested_has_key(v, key) for v in obj.values())
    if isinstance(obj, list):
        return any(nested_has_key(v, key) for v in obj)
    return False


def trauma_for(gate_text, check):
    lower = gate_text.lower()
    if check["type"] == "doctor_signal":
        return "doctor_signal_not_wired"
    if check["type"] == "tests_skipped" or "skipped" in lower:
        return "tests_skipped"
    if "script" in lower and "line" in lower:
        return "large_script_breakup_unverified"
    if check["type"] == "path":
        return "artifact_missing"
    return "acceptance_gate_unverified"


def evaluate_gate(repo, gate, doctor):
    checks = derive_checks(repo, gate, doctor)
    if not checks:
        return {"status": "pending", "checks": [], "trauma_class": "acceptance_gate_unverified", "reason": "no_mechanical_check_derived"}
    failures = []
    passed = []
    for check in checks:
        if check["type"] == "path":
            p = rel_path(repo, check["value"])
            if p.exists():
                passed.append({**check, "status": "pass", "path": str(p)})
            else:
                failures.append({**check, "status": "fail", "path": str(p), "reason": "path_missing"})
        elif check["type"] == "doctor_signal":
            if nested_has_key(doctor, check["value"]):
                passed.append({**check, "status": "pass"})
            else:
                failures.append({**check, "status": "fail", "reason": "doctor_signal_missing"})
        elif check["type"] == "tests_skipped":
            failures.append({**check, "status": "fail", "reason": "tests_skipped"})
    if failures:
        return {"status": "gap", "checks": passed + failures, "trauma_class": trauma_for(gate["text"], failures[0]), "reason": failures[0]["reason"]}
    return {"status": "full", "checks": passed, "trauma_class": None, "reason": "all_checks_passed"}


def create_gap(repo, br_bin, issue, gate, verdict, dry_run):
    priority = issue.get("priority")
    title = f"[{issue.get('id')}.audit-gap] {gate['id']} {gate['text'][:120]}"
    body = "\n".join([
        f"Parent bead: {issue.get('id')}",
        f"Audit gap: {gate['id']}",
        f"Original gate: {gate['text']}",
        f"Trauma class: `{verdict['trauma_class']}`",
        f"Reason: {verdict['reason']}",
        "",
        "Mechanical checks:",
        json.dumps(verdict["checks"], indent=2, sort_keys=True),
        "",
        "Created by `.flywheel/scripts/bead-quality-mining.sh`.",
    ])
    if dry_run:
        return {"id": None, "title": title, "dry_run": True}
    cmd = [br_bin, "create", title, "--type", "task", "--priority", str(priority if priority is not None else 1), "--description", body, "--parent", str(issue.get("id")), "--labels", "audit-gap,bead-quality-mining", "--json"]
    proc = run(cmd, repo, check=True)
    data = load_json(proc.stdout, {})
    return {"id": data.get("id") or (data.get("issue") or {}).get("id"), "title": title, "dry_run": False}


def create_format_gap(repo, br_bin, issue, report, dry_run):
    priority = issue.get("priority")
    title = f"[{issue.get('id')}.audit-gap] AG format noncanonical"
    body = "\n".join([
        f"Parent bead: {issue.get('id')}",
        "Audit gap: acceptance-gate format",
        "Trauma class: `noncanonical_acceptance_gate_format`",
        "Reason: canonical AG parser found malformed acceptance gates",
        "",
        "Format report:",
        json.dumps(report, indent=2, sort_keys=True),
        "",
        "Created by `.flywheel/scripts/bead-quality-mining.sh`.",
    ])
    if dry_run:
        return {"id": None, "title": title, "dry_run": True}
    cmd = [br_bin, "create", title, "--type", "task", "--priority", str(priority if priority is not None else 1), "--description", body, "--parent", str(issue.get("id")), "--labels", "audit-gap,bead-quality-mining,ag-format", "--json"]
    proc = run(cmd, repo, check=True)
    data = load_json(proc.stdout, {})
    return {"id": data.get("id") or (data.get("issue") or {}).get("id"), "title": title, "dry_run": False}


def update_notes(repo, br_bin, issue_id, status, gap_ids, dry_run, at):
    notes = f"audit_status={status}; audit_run_at={iso(at)}; gap_beads={','.join(gap_ids) if gap_ids else 'none'}"
    if dry_run:
        return notes
    run([br_bin, "update", issue_id, "--notes", notes, "--json"], repo, check=True)
    return notes


def main(argv):
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", default=".")
    parser.add_argument("--since-hours", type=float, default=48.0)
    parser.add_argument("--include-id", action="append", default=[])
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--doctor", action="store_true")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--now")
    parser.add_argument("--br-bin", default=os.environ.get("BR_BIN", "br"))
    parser.add_argument("--scan-open-ag-format", action="store_true", help="also scan open/in-progress beads for noncanonical AG format and create parented audit-gap beads")
    args = parser.parse_args(argv)

    repo = Path(args.repo).resolve()
    now = now_utc(args.now)
    since = now - timedelta(hours=args.since_hours)
    doctor = doctor_json(repo, skip_loop=args.doctor)
    issues = closed_recent(repo, args.br_bin, since, args.include_id)
    all_issues = br_issues(repo, args.br_bin, all_issues=True)

    rows = []
    top = Counter()
    gap_beads = []
    pending_count = 0
    gap_count = 0
    ag_format_gap_count = 0
    ag_format_warning_count = 0
    open_format_rows = []

    for issue in issues:
        existing = existing_gap_ids(all_issues, issue.get("id"))
        if existing:
            rows.append({"bead_id": issue.get("id"), "audit_status": "gap_pending", "gap_beads": existing, "idempotent_existing": True, "gates": []})
            gap_count += 1
            gap_beads.extend(existing)
            continue
        ag_report = validate_ag_format(issue.get("description") or "")
        ag_format_warning_count += len(ag_report["warnings"])
        if ag_report["errors"]:
            top["noncanonical_acceptance_gate_format"] += 1
            created = create_format_gap(repo, args.br_bin, issue, ag_report, args.dry_run or args.doctor)
            new_gap_ids = []
            if created["id"]:
                new_gap_ids.append(created["id"])
                gap_beads.append(created["id"])
            elif created["dry_run"]:
                new_gap_ids.append("DRY_RUN")
            ag_format_gap_count += 1
            gap_count += 1
            notes = update_notes(repo, args.br_bin, issue.get("id"), "gap_pending", [g for g in new_gap_ids if g != "DRY_RUN"], args.dry_run or args.doctor, now)
            rows.append({"bead_id": issue.get("id"), "audit_status": "gap_pending", "gap_beads": new_gap_ids, "notes": notes, "ag_format": ag_report, "gates": []})
            continue
        gates = ag_report["gates"]
        gate_results = []
        new_gap_ids = []
        for gate in gates:
            verdict = evaluate_gate(repo, gate, doctor)
            gate_results.append({"gate": gate, "verdict": verdict})
            if verdict["status"] == "pending":
                pending_count += 1
            if verdict["status"] == "gap":
                top[verdict["trauma_class"]] += 1
                created = create_gap(repo, args.br_bin, issue, gate, verdict, args.dry_run or args.doctor)
                if created["id"]:
                    new_gap_ids.append(created["id"])
                    gap_beads.append(created["id"])
                elif created["dry_run"]:
                    new_gap_ids.append("DRY_RUN")
        if new_gap_ids:
            audit_status = "gap_pending"
            gap_count += 1
        elif any(item["verdict"]["status"] == "pending" for item in gate_results):
            audit_status = "partial"
        else:
            audit_status = "full"
        notes = update_notes(repo, args.br_bin, issue.get("id"), audit_status, [g for g in new_gap_ids if g != "DRY_RUN"], args.dry_run or args.doctor, now)
        rows.append({"bead_id": issue.get("id"), "audit_status": audit_status, "gap_beads": new_gap_ids, "notes": notes, "ag_format": ag_report, "gates": gate_results})

    if args.scan_open_ag_format:
        open_statuses = {"open", "in_progress"}
        for issue in all_issues:
            if str(issue.get("status") or "") not in open_statuses:
                continue
            if "audit-gap" in (issue.get("labels") or []):
                continue
            existing = existing_gap_ids(all_issues, issue.get("id"))
            if existing:
                open_format_rows.append({"bead_id": issue.get("id"), "audit_status": "gap_pending", "gap_beads": existing, "idempotent_existing": True})
                continue
            ag_report = validate_ag_format(issue.get("description") or "")
            ag_format_warning_count += len(ag_report["warnings"])
            if ag_report["errors"]:
                top["noncanonical_acceptance_gate_format"] += 1
                created = create_format_gap(repo, args.br_bin, issue, ag_report, args.dry_run or args.doctor)
                new_gap_ids = []
                if created["id"]:
                    new_gap_ids.append(created["id"])
                    gap_beads.append(created["id"])
                elif created["dry_run"]:
                    new_gap_ids.append("DRY_RUN")
                ag_format_gap_count += 1
                open_format_rows.append({"bead_id": issue.get("id"), "audit_status": "gap_pending", "gap_beads": new_gap_ids, "ag_format": ag_report})
            elif ag_report["warnings"]:
                open_format_rows.append({"bead_id": issue.get("id"), "audit_status": "format_warn", "gap_beads": [], "ag_format": ag_report})

    payload = {
        "schema_version": SCHEMA_VERSION,
        "checked_at": iso(now),
        "repo": str(repo),
        "since_hours": args.since_hours,
        "closed_beads_checked": len(issues),
        "closed_bead_audit_pending_count": pending_count,
        "closed_bead_audit_gap_count": gap_count,
        "ag_format_gap_count": ag_format_gap_count,
        "ag_format_warning_count": ag_format_warning_count,
        "audit_gap_top_classes": [{"trauma_class": k, "count": v} for k, v in top.most_common(3)],
        "gap_beads": gap_beads,
        "rows": rows,
        "open_ag_format_rows": open_format_rows,
        "signals": [
            {
                "name": "closed_bead_audit_pending_count",
                "producer": ".flywheel/scripts/bead-quality-mining.sh --doctor --json",
                "measurement": "recent closed bead acceptance gates with no mechanical check derivable",
                "consumer": "flywheel-loop doctor; /flywheel:learn --bead-quality-mining",
                "threshold": "fail when >2",
            },
            {
                "name": "closed_bead_audit_gap_count",
                "producer": ".flywheel/scripts/bead-quality-mining.sh",
                "measurement": "recent closed beads with audit-created or existing audit-gap beads",
                "consumer": "flywheel-loop doctor",
                "threshold": "warn when >0",
            },
            {
                "name": "audit_gap_top_classes",
                "producer": ".flywheel/scripts/bead-quality-mining.sh",
                "measurement": "top trauma classes among audit gaps",
                "consumer": "/flywheel:learn review",
                "threshold": "informational top 3",
            },
        ],
    }
    if args.json or args.doctor:
        print(json.dumps(payload, sort_keys=True, separators=(",", ":")))
    else:
        print(f"closed_bead_audit_pending_count={pending_count} closed_bead_audit_gap_count={gap_count} gap_beads={','.join(gap_beads) if gap_beads else 'none'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
PY
