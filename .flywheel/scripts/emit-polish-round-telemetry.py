#!/usr/bin/env python3
import argparse
import difflib
import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

DEFAULT_VALIDATOR = Path("/Users/josh/.claude/skills/dueling-idea-wizards/scripts/validate-delta.py")


def iso_now():
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def read_json(path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        return None
    except json.JSONDecodeError as exc:
        raise SystemExit(f"invalid_json:{path}:{exc}") from exc


def validate_delta_streams(paths, validator):
    if not paths:
        return
    command = [sys.executable, str(validator), *[str(path) for path in paths]]
    completed = subprocess.run(command, check=False, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if completed.returncode != 0:
        detail = completed.stderr.strip() or completed.stdout.strip() or "delta_validation_failed"
        raise SystemExit(detail)


def count_delta_streams(paths):
    counts = {"adds": 0, "edits": 0, "kills": 0}
    for path in paths:
        payload = read_json(path)
        for delta in payload.get("deltas", []):
            op = delta.get("op")
            if op == "ADD":
                counts["adds"] += 1
            elif op == "EDIT":
                counts["edits"] += 1
            elif op == "KILL":
                counts["kills"] += 1
    return counts


def nonempty_lines(path):
    if not path.is_file():
        return []
    return [line.rstrip("\n") for line in path.read_text(encoding="utf-8", errors="replace").splitlines() if line.strip()]


def count_text_diff(previous_path, current_path):
    previous = nonempty_lines(previous_path)
    current = nonempty_lines(current_path)
    counts = {"adds": 0, "edits": 0, "kills": 0}
    matcher = difflib.SequenceMatcher(a=previous, b=current, autojunk=False)
    for tag, i1, i2, j1, j2 in matcher.get_opcodes():
        old_count = i2 - i1
        new_count = j2 - j1
        if tag == "insert":
            counts["adds"] += new_count
        elif tag == "delete":
            counts["kills"] += old_count
        elif tag == "replace":
            paired = min(old_count, new_count)
            counts["edits"] += paired
            counts["kills"] += max(0, old_count - paired)
            counts["adds"] += max(0, new_count - paired)
    return counts


def state_open_findings(plan_dir):
    state = read_json(plan_dir / "STATE.json")
    if not isinstance(state, dict):
        return 0
    for key in ("open_findings_after", "open_findings_count", "audit_findings_open_count"):
        value = state.get(key)
        if isinstance(value, int):
            return value
    by_sev = state.get("audit_findings_by_severity")
    if isinstance(by_sev, dict):
        return sum(int(value) for value in by_sev.values() if isinstance(value, int))
    value = state.get("audit_findings_count")
    return int(value) if isinstance(value, int) else 0


def build_artifact(args):
    repo = Path(args.repo).resolve()
    plan_dir = repo / ".flywheel" / "plans" / args.plan_slug
    if not plan_dir.is_dir():
        raise SystemExit(f"plan_dir_missing:{plan_dir}")
    validator = Path(args.validator).expanduser()
    if args.delta_stream and not validator.is_file():
        raise SystemExit(f"delta_validator_missing:{validator}")

    delta_paths = [Path(path).expanduser() for path in args.delta_stream]
    validate_delta_streams(delta_paths, validator)
    if delta_paths:
        counts = count_delta_streams(delta_paths)
    else:
        current = Path(args.current_md).expanduser() if args.current_md else plan_dir / f"05-POLISH-r{args.round}.md"
        previous = Path(args.previous_md).expanduser() if args.previous_md else plan_dir / f"05-POLISH-r{args.round - 1}.md"
        counts = count_text_diff(previous, current)

    total = counts["adds"] + counts["edits"] + counts["kills"]
    open_findings = args.open_findings_after
    if open_findings is None:
        open_findings = state_open_findings(plan_dir)
    return {
        "round": args.round,
        "ts": args.now or iso_now(),
        "deltas": {
            "adds": counts["adds"],
            "edits": counts["edits"],
            "kills": counts["kills"],
            "total_changes": total,
        },
        "open_findings_after": int(open_findings),
        "stability": {
            "kills_gte_adds": counts["kills"] >= counts["adds"],
            "no_new_deltas": counts["adds"] == 0,
        },
    }


def parse_args(argv):
    parser = argparse.ArgumentParser(description="Emit Phase 5 polish convergence telemetry.")
    parser.add_argument("--repo", default=".", help="repository root")
    parser.add_argument("--plan-slug", required=True, help="plan slug under .flywheel/plans")
    parser.add_argument("--round", required=True, type=int, help="polish round number")
    parser.add_argument("--delta-stream", action="append", default=[], help="validated dueling-idea-wizards delta JSON")
    parser.add_argument("--previous-md", help="previous polish markdown artifact for text diff fallback")
    parser.add_argument("--current-md", help="current polish markdown artifact for text diff fallback")
    parser.add_argument("--open-findings-after", type=int, help="open findings after this round")
    parser.add_argument("--validator", default=str(DEFAULT_VALIDATOR), help="dueling-idea-wizards delta validator")
    parser.add_argument("--out", help="output path; defaults to plan dir 05-POLISH-rN.json")
    parser.add_argument("--now", help="override ISO timestamp")
    parser.add_argument("--json", action="store_true", help="print artifact JSON")
    args = parser.parse_args(argv)
    if args.round < 1:
        parser.error("--round must be >= 1")
    return args


def main(argv):
    args = parse_args(argv)
    artifact = build_artifact(args)
    repo = Path(args.repo).resolve()
    out = Path(args.out).expanduser() if args.out else repo / ".flywheel" / "plans" / args.plan_slug / f"05-POLISH-r{args.round}.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(artifact, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    if args.json:
        print(json.dumps({**artifact, "artifact_path": str(out)}, sort_keys=True, separators=(",", ":")))
    else:
        print(str(out))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
