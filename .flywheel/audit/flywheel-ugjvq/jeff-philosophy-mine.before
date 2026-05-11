#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
export JEFF_PHILOSOPHY_SCRIPT_DIR="$SCRIPT_DIR"

exec python3 - "$@" <<'PY'
import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

VERSION = "jeff-philosophy-mine.v1"
SCHEMA = "jeff-philosophy/v1"

PATTERNS = [
    {
        "pattern_class": "doctor-health-repair-triad",
        "query": "doctor health repair triad implementation",
        "terms": ["doctor", "health", "repair"],
        "our_adoption_status": "EXTEND",
        "adoption_next": "Require doctor/health/repair on new operator substrates.",
    },
    {
        "pattern_class": "idempotency-key-fail-closed",
        "query": "idempotency key fail closed retry replay",
        "terms": ["idempotency", "fail-closed", "replay"],
        "our_adoption_status": "ADOPT",
        "adoption_next": "Use idempotency key + request fingerprint on mutating receipts.",
    },
    {
        "pattern_class": "schema-version-migration",
        "query": "schema version migration compatibility contract",
        "terms": ["schema_version", "migration", "compatibility"],
        "our_adoption_status": "EXTEND",
        "adoption_next": "Pair schema edits with migration receipts and fixtures.",
    },
    {
        "pattern_class": "callback-envelope-shape",
        "query": "callback envelope DONE BLOCKED receipt evidence",
        "terms": ["callback", "receipt", "evidence"],
        "our_adoption_status": "DIVERGE",
        "adoption_next": "Keep DONE/BLOCKED shape but validate it as a typed envelope.",
    },
    {
        "pattern_class": "append-only-audit-log",
        "query": "append only audit jsonl provenance receipt",
        "terms": ["audit", "jsonl", "provenance"],
        "our_adoption_status": "EXTEND",
        "adoption_next": "Attach audit rows to learning and mutation surfaces.",
    },
    {
        "pattern_class": "frontmatter-validation",
        "query": "frontmatter validation parser schema",
        "terms": ["frontmatter", "validation", "schema"],
        "our_adoption_status": "ADOPT",
        "adoption_next": "Structurally validate command, skill, plan, and doctrine metadata.",
    },
    {
        "pattern_class": "testing-fixture-conventions",
        "query": "fixture golden deterministic replay tests",
        "terms": ["fixture", "golden", "deterministic"],
        "our_adoption_status": "ADOPT",
        "adoption_next": "Every validation claim names fixture, replay command, and expected assertion.",
    },
    {
        "pattern_class": "lock-file-convention",
        "query": "lock file owner ttl stale lock metadata",
        "terms": ["lock", "ttl", "stale"],
        "our_adoption_status": "ADOPT",
        "adoption_next": "Standardize lock owner, timeout, stale diagnosis, and release receipts.",
    },
    {
        "pattern_class": "state-machine-modeling",
        "query": "state machine invariant transition model",
        "terms": ["state machine", "transition", "invariant"],
        "our_adoption_status": "ADAPT",
        "adoption_next": "Model high-risk flywheel transitions before implementation.",
    },
    {
        "pattern_class": "failure-taxonomy-reason-codes",
        "query": "failure taxonomy reason codes typed errors",
        "terms": ["failure taxonomy", "reason", "code"],
        "our_adoption_status": "ADAPT",
        "adoption_next": "Use stable reason codes instead of prose-only failures.",
    },
    {
        "pattern_class": "structured-log-contracts",
        "query": "structured logging contract event envelope",
        "terms": ["structured", "logging", "contract"],
        "our_adoption_status": "EXTEND",
        "adoption_next": "Keep agent-readable logs structured with correlation fields.",
    },
    {
        "pattern_class": "provenance-why-audit",
        "query": "why audit provenance trace command",
        "terms": ["why", "audit", "provenance"],
        "our_adoption_status": "ADOPT",
        "adoption_next": "Expose why/audit provenance for derived doctrine and learning artifacts.",
    },
]


def utc_now():
    return time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())


def day_from_ts(ts):
    return ts[:10]


def script_path(name):
    return Path(os.environ.get("JEFF_PHILOSOPHY_SCRIPT_DIR", ".")).expanduser() / name


def default_repo_root():
    return Path(os.environ.get("JEFF_PHILOSOPHY_REPO_ROOT", str(Path.home() / "Developer/jeff-corpus"))).expanduser()


def default_state_dir():
    return Path(os.environ.get("JEFF_PHILOSOPHY_STATE_DIR", str(Path.home() / ".local/state/jeff-philosophy"))).expanduser()


def append_jsonl(path, row):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as fh:
        fh.write(json.dumps(row, sort_keys=True, separators=(",", ":")) + "\n")


def atomic_write_text(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(prefix=path.name + ".", suffix=".tmp", dir=str(path.parent))
    with os.fdopen(fd, "w", encoding="utf-8") as fh:
        fh.write(text)
        fh.flush()
        os.fsync(fh.fileno())
    Path(tmp).replace(path)


def atomic_write_jsonl(path, rows):
    text = "".join(json.dumps(row, sort_keys=True, separators=(",", ":")) + "\n" for row in rows)
    atomic_write_text(path, text)


def run(cmd, timeout=120, cwd=None):
    try:
        proc = subprocess.run(
            cmd,
            cwd=str(cwd) if cwd else None,
            encoding="utf-8",
            errors="replace",
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=timeout,
            check=False,
        )
        return proc.returncode, proc.stdout, proc.stderr
    except subprocess.TimeoutExpired as exc:
        return 124, exc.stdout or "", exc.stderr or "timeout"


def repo_for_path(root, path):
    try:
        rel = Path(path).resolve().relative_to(root.resolve())
    except Exception:
        return "unknown"
    return rel.parts[0] if rel.parts else "unknown"


def line_ref(root, path, line):
    try:
        rel = Path(path).resolve().relative_to(root.resolve())
    except Exception:
        rel = Path(path)
    return f"{rel}:{line}"


def collect_evidence(root, pattern, limit, timeout):
    if not root.exists():
        return [], "repo_root_missing"
    rg = shutil.which("rg")
    if not rg:
        return [], "rg_missing"
    cmd = [
        rg,
        "--no-config",
        "-n",
        "--with-filename",
        "--color",
        "never",
        "--max-count",
        "2",
        "--max-filesize",
        "512K",
    ]
    for term in pattern["terms"]:
        cmd.extend(["-e", term])
    cmd.append(str(root))
    rc, out, err = run(cmd, timeout=timeout)
    if rc not in (0, 1):
        return [], f"rg_failed:{err.strip()[:120]}"
    seen = set()
    evidence = []
    for raw in out.splitlines():
        parts = raw.split(":", 2)
        if len(parts) < 3:
            continue
        file_path, line, snippet = parts
        repo = repo_for_path(root, file_path)
        if repo in seen:
            continue
        seen.add(repo)
        evidence.append(
            {
                "repo": repo,
                "file_line": line_ref(root, file_path, line),
                "snippet": re.sub(r"\s+", " ", snippet).strip()[:220],
            }
        )
        if len(evidence) >= limit:
            break
    return evidence, None


def pattern_rows(args, selected_patterns):
    rows = []
    for pattern in selected_patterns:
        evidence, error = collect_evidence(args.repo_root, pattern, args.evidence_limit, args.search_timeout)
        rows.append(
            {
                "schema_version": "jeff-philosophy-pattern/v1",
                "generated_at": args.now or utc_now(),
                "pattern_class": pattern["pattern_class"],
                "query": pattern["query"],
                "terms": pattern["terms"],
                "repos_using_it": sorted({item["repo"] for item in evidence}),
                "evidence_repo_count": len({item["repo"] for item in evidence}),
                "evidence": evidence,
                "our_adoption_status": pattern["our_adoption_status"],
                "adoption_next": pattern["adoption_next"],
                "source": "jeff-corpus-rg-fanout",
                "error": error,
            }
        )
    return rows


def render_deep_mine_report(rows, args):
    complete = [row for row in rows if row["evidence_repo_count"] >= args.min_repos]
    lines = [
        "# Jeff Philosophy Deep Mine Findings",
        "",
        f"- generated_at: {args.now or utc_now()}",
        f"- repo_root: {args.repo_root}",
        f"- patterns: {len(rows)}",
        f"- complete_patterns: {len(complete)}",
        f"- min_repos: {args.min_repos}",
        "",
        "## Pattern Summary",
        "",
        "| pattern_class | adoption | evidence_repos | status |",
        "|---|---|---:|---|",
    ]
    for row in rows:
        status = "pass" if row["evidence_repo_count"] >= args.min_repos else "fail"
        lines.append(f"| `{row['pattern_class']}` | {row['our_adoption_status']} | {row['evidence_repo_count']} | {status} |")
    for row in rows:
        lines.extend(["", f"## {row['pattern_class']}", ""])
        lines.append(f"- query: `{row['query']}`")
        lines.append(f"- adoption_next: {row['adoption_next']}")
        if row.get("error"):
            lines.append(f"- search_error: {row['error']}")
        lines.extend(["", "| repo | file:line | evidence |", "|---|---|---|"])
        for item in row["evidence"]:
            snippet = item["snippet"].replace("|", "\\|")
            lines.append(f"| `{item['repo']}` | `{item['file_line']}` | {snippet} |")
    return "\n".join(lines) + "\n"


def selected_pattern_specs(args):
    if not args.pattern_name:
        return PATTERNS
    wanted = args.pattern_name.lower()
    matches = [p for p in PATTERNS if p["pattern_class"].lower() == wanted]
    if not matches:
        matches = [p for p in PATTERNS if wanted in p["pattern_class"].lower()]
    return matches


def deep_mine(args):
    specs = selected_pattern_specs(args)
    if not specs:
        return {"schema_version": SCHEMA, "version": VERSION, "command": args.command, "status": "fail", "error": "pattern_not_found", "pattern": args.pattern_name}
    rows = pattern_rows(args, specs)
    complete = [row for row in rows if row["evidence_repo_count"] >= args.min_repos]
    status = "pass" if len(complete) == len(rows) and (args.pattern_name or len(rows) >= args.min_patterns) else "fail"
    report_text = render_deep_mine_report(rows, args)
    if not args.dry_run:
        atomic_write_jsonl(args.output_jsonl, rows)
        atomic_write_text(args.report_path, report_text)
        append_jsonl(args.audit_log, {"schema_version": "jeff-philosophy-audit/v1", "ts": args.now or utc_now(), "command": args.command, "status": status, "patterns": len(rows), "report_path": str(args.report_path), "output_jsonl": str(args.output_jsonl)})
    return {
        "schema_version": "jeff-philosophy-deep-mine-run/v1",
        "version": VERSION,
        "command": args.command,
        "status": status,
        "dry_run": args.dry_run,
        "repo_root": str(args.repo_root),
        "pattern_count": len(rows),
        "complete_pattern_count": len(complete),
        "min_repos": args.min_repos,
        "output_jsonl": str(args.output_jsonl),
        "report_path": str(args.report_path),
        "patterns": [{"pattern_class": row["pattern_class"], "evidence_repo_count": row["evidence_repo_count"]} for row in rows],
    }


def daily_snapshot(args):
    daily_bin = args.daily_diff_bin
    if not daily_bin.exists():
        return {"schema_version": SCHEMA, "version": VERSION, "command": "daily-snapshot", "status": "fail", "error": "daily_diff_missing", "daily_diff_bin": str(daily_bin)}
    day = day_from_ts(args.now or utc_now())
    snapshot_dir = args.state_dir / "daily-snapshots"
    snapshot_path = snapshot_dir / f"{day}.md"
    cmd = [str(daily_bin), "--repo-root", str(args.repo_root), "--reports-dir", str(snapshot_dir), "--json"]
    if args.now:
        cmd.extend(["--now", args.now])
    if args.dry_run:
        cmd.append("--dry-run")
    if args.skip_fetch:
        cmd.append("--skip-fetch")
    rc, out, err = run(cmd, timeout=args.daily_timeout)
    try:
        payload = json.loads(out)
    except Exception:
        payload = {"status": "fail", "error": "daily_diff_invalid_json", "stdout": out[:400], "stderr": err[:400]}
    status = "pass" if rc == 0 and payload.get("status") == "pass" else "fail"
    report_path = Path(payload.get("report_path", ""))
    if status == "pass" and not args.dry_run:
        if report_path.exists():
            atomic_write_text(snapshot_path, report_path.read_text(encoding="utf-8"))
        else:
            status = "fail"
            payload["error"] = "daily_report_missing"
        append_jsonl(args.audit_log, {"schema_version": "jeff-philosophy-audit/v1", "ts": args.now or utc_now(), "command": "daily-snapshot", "status": status, "snapshot_path": str(snapshot_path), "daily_report_path": str(report_path)})
    return {
        "schema_version": "jeff-philosophy-daily-snapshot-run/v1",
        "version": VERSION,
        "command": "daily-snapshot",
        "status": status,
        "dry_run": args.dry_run,
        "snapshot_path": str(snapshot_path if not args.dry_run else report_path),
        "daily_diff": payload,
    }


def info(args):
    return {
        "schema_version": "jeff-philosophy-info/v1",
        "version": VERSION,
        "status": "pass",
        "repo_root": str(args.repo_root),
        "state_dir": str(args.state_dir),
        "output_jsonl": str(args.output_jsonl),
        "report_path": str(args.report_path),
        "daily_diff_bin": str(args.daily_diff_bin),
        "audit_log": str(args.audit_log),
        "commands": ["doctor", "health", "repair", "validate", "audit", "why", "schema", "deep-mine", "daily-snapshot", "pattern", "completion"],
    }


def schema(args):
    return {
        "schema_version": "jeff-philosophy/schema/v1",
        "version": VERSION,
        "status": "pass",
        "pattern_schema": "jeff-philosophy-pattern/v1",
        "deep_mine_required_fields": ["pattern_class", "repos_using_it", "evidence", "our_adoption_status"],
        "daily_snapshot_required_fields": ["snapshot_path", "daily_diff"],
        "verdict_enum": ["ADOPT", "ADAPT", "EXTEND", "DIVERGE"],
        "commands": ["doctor", "health", "repair", "validate", "audit", "why", "schema", "deep-mine", "daily-snapshot", "pattern", "completion"],
    }


def patterns_summary(args):
    rows = []
    if args.output_jsonl.exists():
        for line in args.output_jsonl.read_text(encoding="utf-8").splitlines():
            if line.strip():
                rows.append(json.loads(line))
    complete = [row for row in rows if row.get("evidence_repo_count", 0) >= 3]
    snapshot_dir = args.state_dir / "daily-snapshots"
    snapshots = []
    if snapshot_dir.exists():
        snapshots = sorted(snapshot_dir.glob("[0-9][0-9][0-9][0-9]-*.md")) or sorted(snapshot_dir.glob("*.md"))
    return {
        "pattern_count": len(rows),
        "complete_pattern_count": len(complete),
        "latest_snapshot_path": str(snapshots[-1]) if snapshots else None,
    }


def doctor(args):
    summary = patterns_summary(args)
    checks = {
        "repo_root_exists": args.repo_root.exists(),
        "daily_diff_bin_exists": args.daily_diff_bin.exists(),
        "patterns_jsonl_exists": args.output_jsonl.exists(),
        "state_dir_exists": args.state_dir.exists(),
        "rg_available": shutil.which("rg") is not None,
    }
    status = "pass" if checks["repo_root_exists"] and checks["daily_diff_bin_exists"] and checks["rg_available"] else "fail"
    return {"schema_version": "jeff-philosophy-doctor/v1", "version": VERSION, "command": "doctor", "status": status, "checks": checks, **summary}


def health(args):
    doc = doctor(args)
    return {"schema_version": "jeff-philosophy-health/v1", "version": VERSION, "command": "health", "status": doc["status"], "summary": doc["checks"]}


def repair(args):
    actions = [
        {"action": "mkdir_state_dir", "path": str(args.state_dir), "needed": not args.state_dir.exists()},
        {"action": "mkdir_daily_snapshot_dir", "path": str(args.state_dir / "daily-snapshots"), "needed": not (args.state_dir / "daily-snapshots").exists()},
    ]
    if args.apply:
        args.state_dir.mkdir(parents=True, exist_ok=True)
        (args.state_dir / "daily-snapshots").mkdir(parents=True, exist_ok=True)
        append_jsonl(args.audit_log, {"schema_version": "jeff-philosophy-audit/v1", "ts": args.now or utc_now(), "command": "repair", "status": "pass", "dry_run": False})
    return {"schema_version": "jeff-philosophy-repair/v1", "version": VERSION, "command": "repair", "status": "pass", "dry_run": not args.apply, "actions": actions}


def validate(args):
    if args.target in ("all", "patterns"):
        if not args.output_jsonl.exists():
            return {"schema_version": "jeff-philosophy-validate/v1", "version": VERSION, "command": "validate", "target": args.target, "status": "fail", "error": "patterns_jsonl_missing", "path": str(args.output_jsonl)}
        rows = [json.loads(line) for line in args.output_jsonl.read_text(encoding="utf-8").splitlines() if line.strip()]
        complete = [row for row in rows if row.get("evidence_repo_count", 0) >= args.min_repos]
        status = "pass" if rows and len(complete) == len(rows) else "fail"
        return {"schema_version": "jeff-philosophy-validate/v1", "version": VERSION, "command": "validate", "target": args.target, "status": status, "rows": len(rows), "complete_rows": len(complete), "min_repos": args.min_repos}
    return {"schema_version": "jeff-philosophy-validate/v1", "version": VERSION, "command": "validate", "target": args.target, "status": "pass"}


def audit(args):
    rows = []
    if args.audit_log.exists():
        for line in args.audit_log.read_text(encoding="utf-8").splitlines()[-args.limit :]:
            if line.strip():
                rows.append(json.loads(line))
    return {"schema_version": "jeff-philosophy-audit-read/v1", "version": VERSION, "command": "audit", "status": "pass", "audit_log": str(args.audit_log), "rows": rows}


def why(args):
    if not args.output_jsonl.exists():
        return {"schema_version": "jeff-philosophy-why/v1", "version": VERSION, "command": "why", "status": "fail", "error": "patterns_jsonl_missing", "pattern": args.pattern_name}
    wanted = args.pattern_name.lower()
    for line in args.output_jsonl.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        row = json.loads(line)
        if row.get("pattern_class", "").lower() == wanted:
            return {"schema_version": "jeff-philosophy-why/v1", "version": VERSION, "command": "why", "status": "pass", "pattern": row}
    return {"schema_version": "jeff-philosophy-why/v1", "version": VERSION, "command": "why", "status": "fail", "error": "pattern_not_found", "pattern": args.pattern_name}


def examples(args):
    text = "\n".join(
        [
            "jeff-philosophy-mine.sh doctor --json",
            "jeff-philosophy-mine.sh --deep-mine --json",
            "jeff-philosophy-mine.sh --daily-snapshot --skip-fetch --json",
            "jeff-philosophy-mine.sh --pattern doctor-health-repair-triad --json",
            "jeff-philosophy-mine.sh validate patterns --json",
        ]
    )
    return {"schema_version": "jeff-philosophy-examples/v1", "version": VERSION, "status": "pass", "examples": text.splitlines()} if args.json else text


def quickstart(args):
    text = "Run doctor first, then --deep-mine to refresh patterns.jsonl, then --daily-snapshot for the morning Jeff learning report."
    return {"schema_version": "jeff-philosophy-quickstart/v1", "version": VERSION, "status": "pass", "text": text} if args.json else text


def completion(args):
    words = "doctor health repair validate audit why schema info examples quickstart deep-mine daily-snapshot pattern completion"
    if args.shell == "fish":
        text = "complete -c jeff-philosophy-mine.sh -f -a '" + words + "'"
    else:
        text = "_jeff_philosophy_mine() { COMPREPLY=( $(compgen -W '" + words + "' -- \"${COMP_WORDS[COMP_CWORD]}\") ); }\ncomplete -F _jeff_philosophy_mine jeff-philosophy-mine.sh"
    return {"schema_version": "jeff-philosophy-completion/v1", "version": VERSION, "status": "pass", "shell": args.shell, "completion": text} if args.json else text


def normalize_argv(argv):
    if not argv:
        return ["doctor"]
    flag_commands = {
        "--deep-mine": "deep-mine",
        "--daily-snapshot": "daily-snapshot",
        "--doctor": "doctor",
        "--health": "health",
        "--repair": "repair",
        "--validate": "validate",
        "--audit": "audit",
        "--schema": "schema",
        "--info": "info",
        "--examples": "examples",
        "--quickstart": "quickstart",
        "--completion": "completion",
    }
    if argv[0] == "--pattern":
        return ["pattern", *argv[1:]]
    if argv[0] in flag_commands:
        return [flag_commands[argv[0]], *argv[1:]]
    for idx, arg in enumerate(argv):
        if arg == "--pattern":
            return ["pattern", *argv[:idx], *argv[idx + 1 :]]
        if arg in flag_commands:
            return [flag_commands[arg], *argv[:idx], *argv[idx + 1 :]]
    return argv


def add_common(parser):
    parser.add_argument("--repo-root", type=Path, default=default_repo_root())
    parser.add_argument("--state-dir", type=Path, default=default_state_dir())
    parser.add_argument("--output-jsonl", type=Path)
    parser.add_argument("--report-path", type=Path, default=Path("/tmp/jeff-philosophy-deep-mine_findings.md"))
    parser.add_argument("--daily-diff-bin", type=Path, default=Path(os.environ.get("JEFF_PHILOSOPHY_DAILY_DIFF_BIN", str(script_path("jeff-daily-diff.sh")))).expanduser())
    parser.add_argument("--now", default=os.environ.get("JEFF_PHILOSOPHY_NOW", ""))
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--no-color", action="store_true")
    parser.add_argument("--no-emoji", action="store_true")
    parser.add_argument("--width", type=int, default=100)


def parse_args(argv):
    parser = argparse.ArgumentParser(description="Mine Jeff corpus philosophy patterns and daily learning snapshots.")
    sub = parser.add_subparsers(dest="command")
    for name in ["doctor", "health", "schema", "info", "examples", "quickstart", "audit"]:
        sp = sub.add_parser(name)
        add_common(sp)
        if name == "audit":
            sp.add_argument("--limit", type=int, default=20)
    sp = sub.add_parser("deep-mine")
    add_common(sp)
    sp.add_argument("--dry-run", action="store_true")
    sp.add_argument("--min-repos", type=int, default=3)
    sp.add_argument("--min-patterns", type=int, default=10)
    sp.add_argument("--evidence-limit", type=int, default=3)
    sp.add_argument("--search-timeout", type=int, default=20)
    sp.add_argument("--pattern-name", default="")
    sp = sub.add_parser("pattern")
    add_common(sp)
    sp.add_argument("pattern_name")
    sp.add_argument("--dry-run", action="store_true")
    sp.add_argument("--min-repos", type=int, default=3)
    sp.add_argument("--min-patterns", type=int, default=1)
    sp.add_argument("--evidence-limit", type=int, default=3)
    sp.add_argument("--search-timeout", type=int, default=20)
    sp = sub.add_parser("daily-snapshot")
    add_common(sp)
    sp.add_argument("--dry-run", action="store_true")
    sp.add_argument("--skip-fetch", action="store_true")
    sp.add_argument("--daily-timeout", type=int, default=300)
    sp = sub.add_parser("repair")
    add_common(sp)
    sp.add_argument("--dry-run", action="store_true")
    sp.add_argument("--apply", action="store_true")
    sp = sub.add_parser("validate")
    add_common(sp)
    sp.add_argument("target", nargs="?", default="patterns", choices=["patterns", "daily-snapshot", "all"])
    sp.add_argument("--min-repos", type=int, default=3)
    sp = sub.add_parser("why")
    add_common(sp)
    sp.add_argument("pattern_name")
    sp = sub.add_parser("completion")
    add_common(sp)
    sp.add_argument("shell", nargs="?", default="bash", choices=["bash", "zsh", "fish"])
    args = parser.parse_args(normalize_argv(argv))
    if not args.command:
        args.command = "doctor"
    args.repo_root = args.repo_root.expanduser()
    args.state_dir = args.state_dir.expanduser()
    args.output_jsonl = (args.output_jsonl or args.state_dir / "patterns.jsonl").expanduser()
    args.report_path = args.report_path.expanduser()
    args.audit_log = args.state_dir / "audit.jsonl"
    return args


def emit(payload, json_out):
    if isinstance(payload, str):
        print(payload)
        return
    if json_out:
        print(json.dumps(payload, sort_keys=True, separators=(",", ":")))
    else:
        print(f"{payload.get('command', 'jeff-philosophy')} status={payload.get('status', 'unknown')}")


args = parse_args(sys.argv[1:])
handlers = {
    "doctor": doctor,
    "health": health,
    "repair": repair,
    "validate": validate,
    "audit": audit,
    "why": why,
    "schema": schema,
    "info": info,
    "examples": examples,
    "quickstart": quickstart,
    "completion": completion,
    "deep-mine": deep_mine,
    "pattern": deep_mine,
    "daily-snapshot": daily_snapshot,
}
payload = handlers[args.command](args)
emit(payload, getattr(args, "json", False))
if isinstance(payload, dict) and payload.get("status") == "fail":
    sys.exit(1)
PY
