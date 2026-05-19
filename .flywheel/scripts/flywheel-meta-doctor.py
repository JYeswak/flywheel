#!/usr/bin/env python3
"""Flywheel meta-doctor — runs all jsm-meta-lesson mechanical checks.

Per `.flywheel/doctrine/jsm-meta-lessons-canonical.md`.
Mirror of skillos `scripts/skillos_meta_doctor.py`.

Subcommands: doctor | health | info | examples
Exit: 0=pass, 1=fail, 2=usage, 3=missing-check-script
"""
from __future__ import annotations

import argparse
import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCRIPTS = ROOT / ".flywheel" / "scripts"

CHECKS = [
    {
        "name": "doctor_sentinel_probe_fleet",
        "script": SCRIPTS / "test-doctor-sentinel-probe-fleet.py",
        "pattern_ref": "MP-01",
    },
    {
        "name": "state_schema_version_coverage",
        "script": SCRIPTS / "test-state-schema-version-coverage.py",
        "pattern_ref": "MP-04",
    },
    {
        "name": "callback_evidence_path_extant",
        "script": SCRIPTS / "test-callback-evidence-path-extant.py",
        "pattern_ref": "MP-04",
    },
]
SCHEMA_VERSION = "flywheel.meta_doctor.v1"


def cmd_info(_args) -> int:
    print(json.dumps({
        "schema_version": SCHEMA_VERSION,
        "name": "flywheel_meta_doctor",
        "purpose": "Run all jsm-meta-lesson mechanical checks for flywheel repo",
        "checks": [{"name": c["name"], "pattern_ref": c["pattern_ref"]} for c in CHECKS],
        "doctrine_ref": ".flywheel/doctrine/jsm-meta-lessons-canonical.md",
    }, indent=2))
    return 0


def cmd_examples(_args) -> int:
    print(json.dumps({
        "schema_version": SCHEMA_VERSION,
        "examples": [
            ".flywheel/scripts/flywheel-meta-doctor.py doctor",
            ".flywheel/scripts/flywheel-meta-doctor.py doctor --json",
            ".flywheel/scripts/flywheel-meta-doctor.py health",
        ],
    }, indent=2))
    return 0


def cmd_health(args) -> int:
    missing = [c for c in CHECKS if not c["script"].exists()]
    status = "fail" if missing else "ok"
    if args.json:
        print(json.dumps({"schema_version": SCHEMA_VERSION, "status": status, "missing": [c["name"] for c in missing]}, indent=2))
    else:
        print(f"flywheel meta-doctor health: {status} ({len(CHECKS) - len(missing)}/{len(CHECKS)})")
    return 3 if missing else 0


def cmd_doctor(args) -> int:
    results = []
    overall_pass = True
    for check in CHECKS:
        if not check["script"].exists():
            results.append({"name": check["name"], "status": "missing", "exit_code": 3})
            overall_pass = False
            continue
        proc = subprocess.run(["python3", str(check["script"]), "--json"],
                              capture_output=True, text=True, timeout=120, check=False)
        try:
            output = json.loads(proc.stdout) if proc.stdout.strip() else {}
        except json.JSONDecodeError:
            output = {"raw": proc.stdout[:200]}
        results.append({
            "name": check["name"],
            "status": "pass" if proc.returncode == 0 else "fail",
            "exit_code": proc.returncode,
            "pattern_ref": check["pattern_ref"],
            "summary": output,
        })
        if proc.returncode != 0:
            overall_pass = False

    payload = {
        "schema_version": SCHEMA_VERSION,
        "status": "pass" if overall_pass else "fail",
        "checks_passed": sum(1 for r in results if r["status"] == "pass"),
        "checks_total": len(CHECKS),
        "results": results,
    }

    if args.json:
        print(json.dumps(payload, indent=2))
    else:
        print(f"# flywheel meta-doctor — {payload['status']}")
        print(f"  {payload['checks_passed']}/{payload['checks_total']} passed")
        for r in results:
            sigil = "✓" if r["status"] == "pass" else "✗"
            print(f"  {sigil} {r['name']} (exit {r['exit_code']}) — {r.get('pattern_ref', '')}")

    return 0 if overall_pass else 1


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--info", action="store_true")
    p.add_argument("--examples", action="store_true")
    sub = p.add_subparsers(dest="subcommand")
    d = sub.add_parser("doctor")
    d.add_argument("--json", action="store_true")
    h = sub.add_parser("health")
    h.add_argument("--json", action="store_true")
    sub.add_parser("info")
    sub.add_parser("examples")
    args = p.parse_args()

    if args.info or args.subcommand == "info":
        return cmd_info(args)
    if args.examples or args.subcommand == "examples":
        return cmd_examples(args)
    if args.subcommand == "health":
        return cmd_health(args)
    if args.subcommand == "doctor":
        return cmd_doctor(args)
    p.print_help()
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
