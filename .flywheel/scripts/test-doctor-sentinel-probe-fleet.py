#!/usr/bin/env python3
"""Fleet-wide sentinel-probe meta-test for flywheel scripts.

Per `.flywheel/doctrine/jsm-meta-lessons-canonical.md` § MP-01.
Mirror of `/Users/josh/Developer/skillos/scripts/tests/test_doctor_sentinel_probe_fleet.py`
adapted to flywheel script layout.

Auto-discovers `.flywheel/scripts/*.py` with subcommand dispatch and probes
each with an unknown sentinel argument. Catches the cass-bug class (parser
silent-fallback) fleet-wide.

Run: python3 .flywheel/scripts/test-doctor-sentinel-probe-fleet.py
Exit: 0 if all reject sentinel; 1 if any silently accept.
JSON: --json for machine-readable.
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
from pathlib import Path

SCRIPTS_DIR = Path(__file__).resolve().parent
SENTINEL = "__sentinel_doctor_probe_xyz123__"

SUBCOMMAND_SIGNATURE = re.compile(r"add_subparsers|dispatch\s*=\s*\{|args\.subcommand")


def has_subcommand_dispatch(path: Path) -> bool:
    try:
        text = path.read_text(encoding="utf-8", errors="ignore")
    except OSError:
        return False
    return bool(SUBCOMMAND_SIGNATURE.search(text))


def probe(script: Path) -> tuple[int, str, str]:
    cmd = ["python3", str(script), SENTINEL, "--help"]
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=10, check=False)
        return result.returncode, result.stdout, result.stderr
    except subprocess.TimeoutExpired:
        return 124, "", "TIMEOUT"
    except Exception as exc:
        return 125, "", f"{type(exc).__name__}: {exc}"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--limit", type=int, default=0)
    args = parser.parse_args()

    candidates = sorted(SCRIPTS_DIR.glob("*.py"))
    if args.limit > 0:
        candidates = candidates[: args.limit]

    eligible = [p for p in candidates if has_subcommand_dispatch(p) and p.name != Path(__file__).name]

    results = {"pass": [], "fail": []}
    for script in eligible:
        rc, stdout, stderr = probe(script)
        combined = (stdout + stderr).lower()
        rejected = (
            rc != 0
            or "unknown subcommand" in combined
            or "invalid choice" in combined
            or ("usage:" in combined and SENTINEL not in combined)
        )
        entry = {"script": script.name, "rc": rc, "rejected": rejected}
        if rejected:
            results["pass"].append(entry)
        else:
            entry["stdout_head"] = stdout[:200]
            results["fail"].append(entry)

    summary = {
        "schema_version": "flywheel.doctor_sentinel_probe_fleet.v1",
        "candidates_total": len(candidates),
        "eligible": len(eligible),
        "pass_count": len(results["pass"]),
        "fail_count": len(results["fail"]),
        "failures": results["fail"],
    }

    if args.json:
        print(json.dumps(summary, indent=2))
    else:
        print(f"# flywheel fleet sentinel-probe: {summary['pass_count']}/{summary['eligible']} pass")
        for f in results["fail"][:10]:
            print(f"  FAIL: {f['script']} rc={f['rc']}")

    return 1 if summary["fail_count"] > 0 else 0


if __name__ == "__main__":
    raise SystemExit(main())
