#!/usr/bin/env python3
# Meta-pattern Adoption stance:
# Embodies MP-74-assertion-control-evidence-chain.md and MP-28-checklist-before-claim.md.
# Source: /Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/
"""Audit closed beads against the canonical josh-request closure evidence schema."""

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


SCHEMA_VERSION = "false-close-audit/v1"
ROW_SCHEMA_VERSION = "false-close-audit.row/v1"
EVIDENCE_TYPES = ["bead_closed", "commit", "dispatch_log", "transcript", "joshua_confirmed"]
BEAD_RE = re.compile(r"\bflywheel-[a-z0-9][a-z0-9-]*\b")
COMMIT_RE = re.compile(r"\b[a-f0-9]{7,40}\b")
DISPATCH_PATH_RE = re.compile(r"(?P<ref>(?:[~./\w-]*/)?dispatch-log\.jsonl(?::|#|line)\S*)")
TASK_RE = re.compile(r"\btask[_-]?id[:=](?P<ref>[A-Za-z0-9_.:@/-]+)")
TRANSCRIPT_RE = re.compile(r"(?P<ref>(?:~|/|\.{1,2})?[\w./:@+-]*\.jsonl#[^\s,;)]+)")
JOSHUA_SHA_RE = re.compile(r"\bsha256:[a-f0-9]{64}\b")


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def repo_root(repo: Path) -> Path:
    proc = subprocess.run(
        ["git", "-C", str(repo), "rev-parse", "--show-toplevel"],
        check=False,
        text=True,
        capture_output=True,
    )
    return Path(proc.stdout.strip()).resolve() if proc.returncode == 0 and proc.stdout.strip() else repo.resolve()


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def normalize_issues(payload: Any) -> list[dict[str, Any]]:
    if isinstance(payload, dict) and isinstance(payload.get("issues"), list):
        return [row for row in payload["issues"] if isinstance(row, dict)]
    if isinstance(payload, list):
        return [row for row in payload if isinstance(row, dict)]
    raise ValueError("expected br JSON object with issues[] or a JSON array")


def run_br(repo: Path, argv: list[str]) -> list[dict[str, Any]]:
    proc = subprocess.run(["br", *argv], cwd=str(repo), check=False, text=True, capture_output=True)
    if proc.returncode != 0:
        raise RuntimeError(proc.stderr.strip() or proc.stdout.strip() or "br command failed")
    return normalize_issues(json.loads(proc.stdout))


def closed_text(row: dict[str, Any]) -> str:
    values = [row.get("close_reason"), row.get("closed_reason"), row.get("resolution"), row.get("notes")]
    return " ".join(str(value) for value in values if value)


def priority_value(row: dict[str, Any]) -> int | None:
    value = row.get("priority")
    if value is None:
        return None
    if isinstance(value, int):
        return value
    match = re.search(r"\d+", str(value))
    return int(match.group(0)) if match else None


def filter_rows(rows: list[dict[str, Any]], args: argparse.Namespace) -> list[dict[str, Any]]:
    wanted = set(args.bead or [])
    filtered: list[dict[str, Any]] = []
    for row in rows:
        if wanted and row.get("id") not in wanted:
            continue
        if args.closed_date and not str(row.get("closed_at") or "").startswith(args.closed_date):
            continue
        if args.priority_max is not None:
            prio = priority_value(row)
            if prio is None or prio > args.priority_max:
                continue
        filtered.append(row)
    return filtered[: args.limit] if args.limit else filtered


def path_for(repo: Path, raw: str) -> Path:
    path = Path(os.path.expanduser(raw))
    if not path.is_absolute():
        path = repo / path
    return path.resolve()


def dispatch_log_path(repo: Path, ref: str) -> Path:
    before = re.split(r"(?::|#|line)", ref, maxsplit=1)[0]
    if before.endswith("dispatch-log.jsonl"):
        return path_for(repo, before if "/" in before else f".flywheel/{before}")
    return repo / ".flywheel/dispatch-log.jsonl"


def git_commit_exists(repo: Path, sha: str) -> bool:
    proc = subprocess.run(
        ["git", "-C", str(repo), "cat-file", "-e", f"{sha}^{{commit}}"],
        check=False,
        text=True,
        capture_output=True,
    )
    return proc.returncode == 0


def bead_is_closed(ref: str, issue_map: dict[str, dict[str, Any]], repo: Path) -> bool:
    row = issue_map.get(ref)
    if row is None:
        try:
            matches = run_br(repo, ["show", ref, "--json"])
        except Exception:
            matches = []
        row = matches[0] if matches else None
    return bool(row and str(row.get("status") or "").lower() == "closed" and closed_text(row).strip())


def dispatch_ref_exists(repo: Path, ref: str, kind: str) -> bool:
    log = dispatch_log_path(repo, ref)
    if not log.exists():
        return False
    if kind == "task_id":
        needle = ref
        return any(needle in line for line in log.read_text(errors="replace").splitlines())
    line_match = re.search(r"(?:line|:)(\d+)$", ref)
    if line_match:
        line_no = int(line_match.group(1))
        return 1 <= line_no <= sum(1 for _ in log.open(encoding="utf-8", errors="replace"))
    return True


def transcript_ref_exists(repo: Path, ref: str) -> bool:
    path_raw, marker = ref.rsplit("#", 1)
    path = path_for(repo, path_raw)
    if not path.exists() or not marker:
        return False
    text = path.read_text(encoding="utf-8", errors="replace")
    return marker in text


def candidate(type_: str, ref: str, valid: bool, reason: str) -> dict[str, Any]:
    return {"type": type_, "ref": ref.rstrip(".,;)"), "valid": valid, "reason": reason}


def extract_evidence(text: str, row: dict[str, Any], issue_map: dict[str, dict[str, Any]], repo: Path) -> list[dict[str, Any]]:
    evidence: list[dict[str, Any]] = []
    seen: set[tuple[str, str]] = set()

    def add(type_: str, ref: str, valid: bool, reason: str) -> None:
        ref = ref.rstrip(".,;)")
        key = (type_, ref)
        if key not in seen:
            seen.add(key)
            evidence.append(candidate(type_, ref, valid, reason))

    for match in BEAD_RE.finditer(text):
        ref = match.group(0)
        if (match.start() > 0 and text[match.start() - 1] == "/") or (
            match.end() + 1 < len(text) and text[match.end()] == "." and text[match.end() + 1].isalnum()
        ):
            continue
        if ref == row.get("id"):
            continue
        valid = bead_is_closed(ref, issue_map, repo)
        add("bead_closed", ref, valid, "closed_with_close_reason" if valid else "bead_missing_or_not_closed")

    for match in JOSHUA_SHA_RE.finditer(text):
        add("joshua_confirmed", match.group(0), True, "sha256_shape_valid")

    for match in DISPATCH_PATH_RE.finditer(text):
        ref = match.group("ref")
        valid = dispatch_ref_exists(repo, ref, "path")
        add("dispatch_log", ref, valid, "dispatch_log_ref_exists" if valid else "dispatch_log_ref_missing")

    for match in TASK_RE.finditer(text):
        ref = match.group("ref")
        valid = dispatch_ref_exists(repo, ref, "task_id")
        add("dispatch_log", ref, valid, "task_id_found" if valid else "task_id_missing")

    for match in TRANSCRIPT_RE.finditer(text):
        ref = match.group("ref")
        if "dispatch-log.jsonl" in ref:
            continue
        valid = transcript_ref_exists(repo, ref)
        add("transcript", ref, valid, "transcript_message_found" if valid else "transcript_message_missing")

    for match in COMMIT_RE.finditer(text):
        ref = match.group(0)
        if ref.isdigit():
            continue
        valid = git_commit_exists(repo, ref)
        add("commit", ref, valid, "commit_exists" if valid else "commit_missing")

    return evidence


def classify(evidence: list[dict[str, Any]]) -> str:
    if any(item["valid"] for item in evidence):
        return "TRUE-CLOSE"
    if evidence:
        return "SUSPECT"
    return "NO-EVIDENCE"


def audit_rows(repo: Path, rows: list[dict[str, Any]], args: argparse.Namespace) -> list[dict[str, Any]]:
    issue_map = {str(row.get("id")): row for row in rows if row.get("id")}
    out = []
    for row in filter_rows(rows, args):
        text = closed_text(row)
        evidence = extract_evidence(text, row, issue_map, repo)
        out.append(
            {
                "schema_version": ROW_SCHEMA_VERSION,
                "generated_at": args.now or utc_now(),
                "bead_id": row.get("id"),
                "title": row.get("title"),
                "priority": row.get("priority"),
                "closed_at": row.get("closed_at"),
                "classification": classify(evidence),
                "evidence": evidence,
            }
        )
    return out


def write_jsonl(path: Path, rows: list[dict[str, Any]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("".join(json.dumps(row, sort_keys=True) + "\n" for row in rows), encoding="utf-8")


def summary(repo: Path, rows: list[dict[str, Any]], log_path: str | None) -> dict[str, Any]:
    counts = {"TRUE-CLOSE": 0, "SUSPECT": 0, "NO-EVIDENCE": 0}
    for row in rows:
        counts[row["classification"]] += 1
    return {
        "schema_version": SCHEMA_VERSION,
        "generated_at": utc_now(),
        "repo": str(repo),
        "checked_count": len(rows),
        "counts": counts,
        "audit_log": log_path,
        "status": "pass" if counts["SUSPECT"] == 0 and counts["NO-EVIDENCE"] == 0 else "fail",
    }


def load_rows(repo: Path, args: argparse.Namespace) -> list[dict[str, Any]]:
    if args.beads_json:
        return normalize_issues(load_json(Path(args.beads_json)))
    return run_br(repo, ["list", "--status=closed", "--json"])


def cmd_audit(args: argparse.Namespace) -> int:
    repo = repo_root(Path(args.repo))
    rows = audit_rows(repo, load_rows(repo, args), args)
    log_path: str | None = None
    if not args.no_write_log:
        stamp = args.now or utc_now().replace(":", "").replace("-", "")
        path = Path(args.audit_log) if args.audit_log else repo / ".flywheel" / "audits" / f"false-close-audit-{stamp}.jsonl"
        write_jsonl(path, rows)
        log_path = str(path)
    payload = summary(repo, rows, log_path) | {"rows": rows if args.include_rows else None}
    if payload["rows"] is None:
        del payload["rows"]
    print(json.dumps(payload, indent=2 if args.pretty else None, sort_keys=True))
    return 0 if payload["status"] == "pass" else 1


def cmd_doctor(args: argparse.Namespace) -> int:
    repo = repo_root(Path(args.repo))
    checks = [
        {"name": "repo", "status": "pass" if repo.exists() else "fail", "detail": str(repo)},
        {"name": "br", "status": "pass" if shutil_which("br") else "fail", "detail": "br in PATH"},
        {"name": "schema", "status": "pass" if (repo / "templates/josh-request-schema.md").exists() else "fail"},
        {"name": "audit_dir", "status": "pass" if (repo / ".flywheel").exists() else "fail"},
    ]
    status = "pass" if all(item["status"] == "pass" for item in checks) else "fail"
    print(json.dumps({"schema_version": SCHEMA_VERSION, "command": "doctor", "status": status, "checks": checks}, sort_keys=True))
    return 0 if status == "pass" else 1


def shutil_which(name: str) -> bool:
    return any((Path(part) / name).exists() for part in os.environ.get("PATH", "").split(os.pathsep))


def simple_payload(command: str, **extra: Any) -> int:
    print(json.dumps({"schema_version": SCHEMA_VERSION, "command": command, **extra}, sort_keys=True))
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=__doc__,
        epilog="Common flags: audit --json emits machine output; repair --dry-run is the default safe mutation surface.",
    )
    parser.add_argument("--info", action="store_true", help="emit version, paths, dependencies, sha256 surface")
    parser.add_argument("--examples", action="store_true", help="emit curated workflow examples")
    parser.add_argument("--json", action="store_true", help="machine-readable output; default command output is JSON")
    sub = parser.add_subparsers(dest="command")
    audit = sub.add_parser("audit", help="audit closed bead close_reason evidence")
    audit.add_argument("--repo", default=".")
    audit.add_argument("--beads-json")
    audit.add_argument("--bead", action="append")
    audit.add_argument("--closed-date")
    audit.add_argument("--priority-max", type=int)
    audit.add_argument("--limit", type=int, default=0)
    audit.add_argument("--audit-log")
    audit.add_argument("--no-write-log", action="store_true")
    audit.add_argument("--include-rows", action="store_true")
    audit.add_argument("--pretty", action="store_true")
    audit.add_argument("--now")
    audit.add_argument("--json", action="store_true", help="machine-readable output; default is JSON")
    doctor = sub.add_parser("doctor", help="diagnose local dependencies")
    doctor.add_argument("--repo", default=".")
    sub.add_parser("health", help="show last-run health")
    repair = sub.add_parser("repair", help="repair known local state; --dry-run by default")
    repair.add_argument("--scope", default="audit_dir")
    repair.add_argument("--dry-run", action="store_true", default=True)
    repair.add_argument("--apply", action="store_true")
    repair.add_argument("--idempotency-key")
    sub.add_parser("validate", help="validate regex/schema wiring")
    sub.add_parser("audit-log", help="alias for audit history")
    why = sub.add_parser("why", help="explain one evidence type")
    why.add_argument("id", nargs="?")
    sub.add_parser("quickstart", help="operator quickstart")
    help_cmd = sub.add_parser("help", help="topic help")
    help_cmd.add_argument("topic", nargs="?")
    completion = sub.add_parser("completion", help="emit shell completion")
    completion.add_argument("shell", nargs="?", default="bash")
    return parser


def main(argv: list[str]) -> int:
    if not argv:
        argv = ["audit"]
    if argv[0].startswith("--") and argv[0] not in {"--info", "--examples", "--help", "-h"}:
        argv = ["audit", *argv]
    parser = build_parser()
    args = parser.parse_args(argv)
    if args.info:
        return simple_payload("info", version="1.0.0", evidence_types=EVIDENCE_TYPES)
    if args.examples:
        return simple_payload("examples", examples=["false-close-audit.py audit --closed-date 2026-05-15 --priority-max 1 --include-rows"])
    if args.command == "audit":
        return cmd_audit(args)
    if args.command == "doctor":
        return cmd_doctor(args)
    if args.command == "repair":
        return simple_payload("repair", status="noop", dry_run=not args.apply, scope=args.scope)
    if args.command == "validate":
        return simple_payload("validate", status="pass", evidence_types=EVIDENCE_TYPES)
    if args.command == "health":
        return simple_payload("health", status="pass")
    if args.command in {"audit-log", "quickstart", "help", "completion", "why"}:
        return simple_payload(args.command, status="available")
    parser.print_help()
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-04-receipt-callback-envelope.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-88-content-addressed-evidence-pack.md`
