#!/usr/bin/env bash
# canonical-cli-scoping-allow-large: pbt55 verifier keeps canonical CLI, default primitive spec, doctor, repair, and tests in one portable entrypoint.
set -euo pipefail

exec python3 - "$0" "$@" <<'PY'
import argparse
import json
import os
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

VERSION = "tick-hook-firing-verifier.v1.0.0"
SCHEMA_VERSION = "tick-hook-firing.v1"
DOCTOR_SCHEMA_VERSION = "tick-hook-firing.doctor.v1"
LEDGER_SCHEMA_VERSION = "tick-hook-firing.audit.v1"
CONTRACT_SCHEMA_VERSION = "substrate-loop-contract.v1"

SCRIPT = Path(sys.argv[1]).resolve()
REPO_DEFAULT = SCRIPT.parent.parent.parent
ENV = os.environ
REPO = Path(ENV.get("TICK_HOOK_FIRING_REPO", str(REPO_DEFAULT))).expanduser()
AUDIT_LEDGER = Path(ENV.get("TICK_HOOK_FIRING_AUDIT_LEDGER", str(Path.home() / ".local/state/flywheel/tick-hook-firing-audit.jsonl"))).expanduser()
FUCKUP_LOG = Path(ENV.get("TICK_HOOK_FIRING_FUCKUP_LOG", str(Path.home() / ".local/state/flywheel/fuckup-log.jsonl"))).expanduser()
CONTRACT_LEDGER = Path(ENV.get("TICK_HOOK_FIRING_CONTRACT_LEDGER", str(Path.home() / ".local/state/flywheel/substrate-loop-contract.jsonl"))).expanduser()
TICK_DRIVER_LEDGER = Path(ENV.get("TICK_HOOK_FIRING_TICK_DRIVER_LEDGER", str(Path.home() / ".local/state/flywheel/tick-driver.jsonl"))).expanduser()
JSONL_APPEND_LIB = Path(ENV.get("FLYWHEEL_JSONL_APPEND_LIB", str(Path.home() / ".local/share/flywheel-watchers/lib/jsonl-append.sh"))).expanduser()
NOW = ENV.get("TICK_HOOK_FIRING_NOW", "")


def now_dt() -> datetime:
    if NOW:
        try:
            return datetime.fromisoformat(NOW.replace("Z", "+00:00")).astimezone(timezone.utc)
        except ValueError:
            pass
    return datetime.now(timezone.utc)


def now_iso() -> str:
    return now_dt().strftime("%Y-%m-%dT%H:%M:%SZ")


def parse_ts(value):
    if not value:
        return None
    try:
        return datetime.fromisoformat(str(value).replace("Z", "+00:00")).astimezone(timezone.utc)
    except ValueError:
        return None


def age_sec(ts):
    dt = parse_ts(ts)
    if not dt:
        return None
    return int(max(0, (now_dt() - dt).total_seconds()))


def is_recent(ts, window_sec):
    age = age_sec(ts)
    return age is not None and age <= window_sec


def emit(payload, json_out, text, rc=0):
    if json_out:
        print(json.dumps(payload, sort_keys=True, separators=(",", ":")))
    else:
        print(text)
    return rc


def read_jsonl(path: Path):
    rows = []
    if not path.is_file():
        return rows
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except json.JSONDecodeError:
            continue
        if isinstance(row, dict):
            rows.append(row)
    return rows


def latest_ts_from_ledger(path: Path):
    ts_values = [row.get("ts") for row in read_jsonl(path) if parse_ts(row.get("ts"))]
    if not ts_values:
        return None
    return max(ts_values)


def latest_tick_driver_fire(name):
    latest = None
    latest_dt = None
    for row in read_jsonl(TICK_DRIVER_LEDGER):
        ts = row.get("ts")
        dt = parse_ts(ts)
        if not dt:
            continue
        for primitive in row.get("primitives", []):
            if not isinstance(primitive, dict) or primitive.get("name") != name:
                continue
            if latest_dt is None or dt > latest_dt:
                latest_dt = dt
                latest = {
                    "ts": ts,
                    "status": primitive.get("status"),
                    "exit_status": primitive.get("exit_status"),
                    "fire_id": row.get("fire_id"),
                }
    return latest


def append_validated(path: Path, row: dict):
    if not JSONL_APPEND_LIB.is_file():
        raise RuntimeError(f"JSONL append primitive missing: {JSONL_APPEND_LIB}")
    row_text = json.dumps(row, sort_keys=True, separators=(",", ":"))
    cmd = 'source "$1"; fw_jsonl_append_validated "$2" "$3"'
    result = subprocess.run(
        ["bash", "-c", cmd, "bash", str(JSONL_APPEND_LIB), str(path), row_text],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or f"append failed rc={result.returncode}")


def default_primitives():
    return [
        {
            "name": "l70-ticks-punted-counter",
            "ledger_path": str(Path.home() / ".local/state/flywheel/l70-ticks-punted.jsonl"),
            "doctor_command": f"{REPO}/.flywheel/scripts/l70-ticks-punted-counter.sh --doctor --json",
            "doctor_last_fired_field": "l70_counter_last_fired_ts",
        },
        {
            "name": "storage-headroom-watcher",
            "ledger_path": str(Path.home() / ".local/state/flywheel/storage-headroom-watcher.jsonl"),
            "doctor_command": f"{REPO}/.flywheel/scripts/storage-headroom-watcher.sh --doctor --json",
            "doctor_last_fired_field": "storage_headroom_watcher_last_fired_ts",
        },
        {
            "name": "agents-md-fleet-propagator",
            "ledger_path": str(Path.home() / ".local/state/flywheel/agents-md-fleet-propagation.jsonl"),
            "doctor_command": f"{REPO}/.flywheel/scripts/agents-md-fleet-propagator.sh --doctor --json",
            "doctor_last_fired_field": "agents_md_fleet_propagator_last_fired_ts",
        },
        {
            "name": "codex-stuck-detector",
            "ledger_path": str(Path.home() / ".local/state/flywheel/codex-stuck-detector.jsonl"),
            "doctor_command": f"{REPO}/.flywheel/scripts/codex-template-stuck-detector.sh --doctor --json",
            "doctor_last_fired_field": "codex_stuck_detector_last_fired_ts",
        },
        {
            "name": "peer-orch-freeze-monitor",
            "ledger_path": str(Path.home() / ".local/state/flywheel/peer-orch-freeze-monitor.jsonl"),
            "doctor_command": f"{REPO}/.flywheel/scripts/peer-orch-freeze-monitor.sh --doctor --json",
            "doctor_last_fired_field": "monitor_last_fire_ts",
        },
    ]


def load_primitives(args):
    raw = None
    if args.primitives_json:
        raw = args.primitives_json
    elif args.primitives_file:
        raw = Path(args.primitives_file).expanduser().read_text(encoding="utf-8")
    elif ENV.get("TICK_HOOK_FIRING_PRIMITIVES_JSON"):
        source = ENV["TICK_HOOK_FIRING_PRIMITIVES_JSON"]
        if Path(source).expanduser().is_file():
            raw = Path(source).expanduser().read_text(encoding="utf-8")
        else:
            raw = source
    if raw is None:
        return default_primitives()
    data = json.loads(raw)
    if not isinstance(data, list):
        raise ValueError("primitive spec must be a JSON array")
    return data


def run_doctor_command(command, field):
    if not command or not field:
        return None, None
    try:
        result = subprocess.run(command, shell=True, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=20)
    except Exception as exc:
        return None, f"doctor_command_error:{exc}"
    try:
        payload = json.loads(result.stdout)
    except json.JSONDecodeError:
        return None, f"doctor_command_non_json:rc={result.returncode}"
    return payload.get(field), None


def classify_primitive(spec, window_sec):
    name = spec.get("name") or spec.get("primitive")
    ledger_path = Path(str(spec.get("ledger_path") or spec.get("ledger") or "")).expanduser()
    doctor_field = spec.get("doctor_last_fired_field") or spec.get("doctor_field")
    doctor_ts, doctor_error = run_doctor_command(spec.get("doctor_command"), doctor_field)
    tick_driver_fire = latest_tick_driver_fire(name)
    tick_driver_ts = tick_driver_fire.get("ts") if tick_driver_fire else None
    tick_driver_status = tick_driver_fire.get("status") if tick_driver_fire else None
    ledger_exists = ledger_path.is_file()
    last_event_ts = latest_ts_from_ledger(ledger_path) if ledger_exists else None
    last_event_age = age_sec(last_event_ts)
    doctor_age = age_sec(doctor_ts)
    tick_driver_age = age_sec(tick_driver_ts)

    if ledger_exists and is_recent(last_event_ts, window_sec):
        classification = "firing"
        root_cause = "ledger_recent"
    elif tick_driver_status == "ok" and is_recent(tick_driver_ts, window_sec):
        classification = "firing"
        root_cause = "tick_driver_recent"
    elif tick_driver_ts and is_recent(tick_driver_ts, window_sec):
        classification = "suspicious"
        root_cause = f"tick_driver_recent_status_{tick_driver_status}"
    elif ledger_exists and last_event_ts:
        classification = "stale"
        root_cause = "ledger_stale"
    elif is_recent(doctor_ts, window_sec):
        classification = "suspicious"
        root_cause = "doctor_recent_but_ledger_missing"
    else:
        classification = "invisibly_broken"
        root_cause = "ledger_missing_or_no_recent_rows"
        if doctor_error:
            root_cause = f"{root_cause};{doctor_error}"

    return {
        "schema_version": LEDGER_SCHEMA_VERSION,
        "ts": now_iso(),
        "primitive": name,
        "ledger_path": str(ledger_path),
        "ledger_exists": ledger_exists,
        "last_event_ts": last_event_ts,
        "last_event_age_sec": last_event_age,
        "doctor_last_fired_ts": doctor_ts,
        "doctor_last_fired_age_sec": doctor_age,
        "tick_driver_ledger_path": str(TICK_DRIVER_LEDGER),
        "tick_driver_last_fire_ts": tick_driver_ts,
        "tick_driver_last_fire_age_sec": tick_driver_age,
        "tick_driver_status": tick_driver_status,
        "classification": classification,
        "root_cause": root_cause,
    }


def fuckup_row(row):
    return {
        "schema_version": "flywheel-fuckup-log.v1",
        "ts": now_iso(),
        "class": "tick-hook-not-firing",
        "trauma_class": "tick-hook-not-firing",
        "severity": "high" if row["classification"] == "invisibly_broken" else "medium",
        "what_happened": f"tick hook primitive {row['primitive']} classified {row['classification']}",
        "primitive": row["primitive"],
        "ledger_path": row["ledger_path"],
        "last_event_ts": row["last_event_ts"],
        "classification": row["classification"],
        "root_cause": row["root_cause"],
        "should_become": "bead",
    }


def audit_payload(args):
    rows = [classify_primitive(spec, args.window_sec) for spec in load_primitives(args)]
    broken = [r for r in rows if r["classification"] == "invisibly_broken"]
    stale = [r for r in rows if r["classification"] == "stale"]
    suspicious = [r for r in rows if r["classification"] == "suspicious"]
    firing = [r for r in rows if r["classification"] == "firing"]
    status = "error" if broken else ("warn" if stale or suspicious else "pass")
    return {
        "schema_version": DOCTOR_SCHEMA_VERSION,
        "status": status,
        "ts": now_iso(),
        "repo": str(REPO),
        "audit_ledger_path": str(AUDIT_LEDGER),
        "fuckup_log_path": str(FUCKUP_LOG),
        "tick_driver_ledger_path": str(TICK_DRIVER_LEDGER),
        "tick_hook_primitives_audited": len(rows),
        "tick_hook_primitives_firing": len(firing),
        "tick_hook_primitives_invisibly_broken": len(broken),
        "tick_hook_primitives_invisibly_broken_names": [r["primitive"] for r in broken],
        "tick_hook_primitives_stale": len(stale),
        "tick_hook_primitives_suspicious": len(suspicious),
        "primitive_rows": rows,
    }


def run_doctor(args):
    payload = audit_payload(args)
    append_error = None
    if args.apply:
        try:
            for row in payload["primitive_rows"]:
                append_validated(AUDIT_LEDGER, row)
                if row["classification"] in {"invisibly_broken", "stale"}:
                    append_validated(FUCKUP_LOG, fuckup_row(row))
        except Exception as exc:
            append_error = str(exc)
    payload["dry_run"] = not args.apply
    payload["apply"] = args.apply
    payload["audit_rows_written"] = len(payload["primitive_rows"]) if args.apply and append_error is None else 0
    if append_error:
        payload["append_error"] = append_error
        return emit(payload, args.json, f"FAIL append_error={append_error}", 3)
    rc = 1 if payload["status"] == "error" else 0
    return emit(payload, args.json, f"status={payload['status']} audited={payload['tick_hook_primitives_audited']} broken={payload['tick_hook_primitives_invisibly_broken']}", rc)


def run_health(args):
    rc = 0
    while True:
        payload = audit_payload(args)
        health = "green" if payload["status"] == "pass" else ("degraded" if payload["status"] == "warn" else "critical")
        payload["health"] = health
        rc = 0 if health == "green" else (1 if health == "degraded" else 3)
        emit(payload, args.json, f"health={health} broken={payload['tick_hook_primitives_invisibly_broken']}", rc)
        if not args.watch:
            break
        time.sleep(args.interval)
    return rc


def contract_row():
    return {
        "primitive_name": "tick-hook-firing-verifier",
        "declares_loop": "yes",
        "self_repair_action": "tick-hook-firing-verifier.sh repair --scope all --apply",
        "measurement_field": "tick_hook_primitives_invisibly_broken",
        "escalation_path": "fuckup-log:class=tick-hook-not-firing",
        "schema_version": CONTRACT_SCHEMA_VERSION,
        "bootstrap_seed_v1": "pbt55 verifies recently shipped tick hooks have ledger-backed firing evidence",
        "ts": now_iso(),
    }


def run_repair(args):
    planned = []
    actual = []
    if args.scope in {"ledger", "all"}:
        planned.append({"action": "ensure_directory", "path": str(AUDIT_LEDGER.parent)})
    if args.scope in {"substrate-contract", "all"}:
        planned.append({"action": "append_substrate_loop_contract_self_row", "path": str(CONTRACT_LEDGER), "primitive": "tick-hook-firing-verifier"})
    if args.apply:
        if args.scope in {"ledger", "all"}:
            AUDIT_LEDGER.parent.mkdir(parents=True, exist_ok=True)
            actual.append({"action": "ensured_directory", "path": str(AUDIT_LEDGER.parent)})
        if args.scope in {"substrate-contract", "all"}:
            append_validated(CONTRACT_LEDGER, contract_row())
            actual.append({"action": "appended_substrate_loop_contract_self_row", "path": str(CONTRACT_LEDGER)})
    payload = {
        "schema_version": f"{SCHEMA_VERSION}.repair",
        "status": "pass",
        "scope": args.scope,
        "dry_run": not args.apply,
        "apply": args.apply,
        "planned_actions": planned,
        "actual_actions": actual,
    }
    return emit(payload, args.json, f"repair scope={args.scope} apply={args.apply}", 0)


def run_validate(args):
    rows = read_jsonl(AUDIT_LEDGER)
    invalid = [
        row for row in rows
        if not row.get("primitive") or row.get("classification") not in {"firing", "stale", "invisibly_broken", "suspicious"}
    ]
    payload = {
        "schema_version": f"{SCHEMA_VERSION}.validate",
        "status": "pass" if not invalid else "fail",
        "target": args.validate_target,
        "rows_checked": len(rows),
        "invalid_rows": len(invalid),
    }
    return emit(payload, args.json, f"validate status={payload['status']} rows={len(rows)}", 0 if not invalid else 1)


def run_audit(args):
    rows = read_jsonl(AUDIT_LEDGER)
    payload = {
        "schema_version": f"{SCHEMA_VERSION}.audit",
        "audit_ledger_path": str(AUDIT_LEDGER),
        "rows_seen_count": len(rows),
        "recent_rows": rows[-20:],
    }
    return emit(payload, args.json, f"audit rows_seen_count={len(rows)}", 0)


def run_why(args):
    rows = read_jsonl(AUDIT_LEDGER)
    latest = None
    for row in rows:
        if row.get("primitive") == args.why_id or row.get("classification") == args.why_id:
            latest = row
    explanations = {
        "firing": "ledger exists and latest ledger row is within the freshness window",
        "stale": "ledger exists, but the latest row is older than the freshness window",
        "suspicious": "doctor reports a recent last_fired_ts, but no ledger evidence backs it",
        "invisibly_broken": "no recent ledger row and no acceptable ledger-backed evidence that the hook fired",
    }
    payload = {
        "schema_version": f"{SCHEMA_VERSION}.why",
        "id": args.why_id,
        "explanation": explanations.get(args.why_id, "latest matching audit row is returned when present"),
        "latest_match": latest,
    }
    return emit(payload, args.json, f"why id={args.why_id}", 0)


def schema_payload(topic):
    if topic == "doctor":
        return {
            "schema_version": DOCTOR_SCHEMA_VERSION,
            "required": [
                "tick_hook_primitives_audited",
                "tick_hook_primitives_firing",
                "tick_hook_primitives_invisibly_broken",
                "tick_hook_primitives_invisibly_broken_names",
            ],
        }
    if topic == "audit":
        return {
            "schema_version": LEDGER_SCHEMA_VERSION,
            "required": ["ts", "primitive", "ledger_path", "ledger_exists", "last_event_ts", "last_event_age_sec", "classification", "root_cause"],
        }
    if topic == "contract":
        return {"schema_version": CONTRACT_SCHEMA_VERSION, "required": ["primitive_name", "declares_loop", "self_repair_action", "measurement_field", "escalation_path", "schema_version", "bootstrap_seed_v1"]}
    return {"schema_version": SCHEMA_VERSION, "classifications": ["firing", "stale", "invisibly_broken", "suspicious"]}


def info_payload():
    return {
        "name": "tick-hook-firing-verifier.sh",
        "version": VERSION,
        "schema_version": SCHEMA_VERSION,
        "repo": str(REPO),
        "audit_ledger": str(AUDIT_LEDGER),
        "fuckup_log": str(FUCKUP_LOG),
        "contract_ledger": str(CONTRACT_LEDGER),
        "tick_driver_ledger": str(TICK_DRIVER_LEDGER),
        "jsonl_append_lib": str(JSONL_APPEND_LIB),
        "exit_codes": {"0": "pass/green", "1": "doctor found invisibly broken hooks or validation failed", "2": "usage error", "3": "validated append failed"},
    }


def examples():
    return [
        "tick-hook-firing-verifier.sh --doctor --json",
        "tick-hook-firing-verifier.sh --doctor --apply --json",
        "tick-hook-firing-verifier.sh repair --scope substrate-contract --apply --json",
        "tick-hook-firing-verifier.sh validate ledger --json",
    ]


def quickstart():
    return [
        "Run --doctor --json to classify tick hooks without writing.",
        "Run --doctor --apply --json at tick close to write audit rows and tick-hook-not-firing fuckup rows.",
        "Keep ~/.local/state/flywheel/tick-driver.jsonl available; it is consumed as L116 process evidence.",
        "Use TICK_HOOK_FIRING_PRIMITIVES_JSON or --primitives-file for fixture/custom primitive sets.",
        "Wire flywheel-loop doctor --scope tick-hook-firing --json to expose the fleet summary.",
    ]


def completion(shell):
    if shell == "bash":
        return """_tick_hook_firing_verifier_completion() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  COMPREPLY=( $(compgen -W "--doctor doctor health repair validate audit why schema --scope --dry-run --apply --json --watch --interval --window-sec --primitives-file --primitives-json --info --examples quickstart help completion" -- "$cur") )
}
complete -F _tick_hook_firing_verifier_completion tick-hook-firing-verifier.sh
"""
    if shell == "zsh":
        return "compadd -- --doctor doctor health repair validate audit why schema --scope --dry-run --apply --json --watch --interval --window-sec --primitives-file --primitives-json --info --examples quickstart help completion\n"
    raise ValueError("completion shell must be bash or zsh")


def usage():
    return """usage:
  tick-hook-firing-verifier.sh --doctor [--apply|--dry-run] [--json]
  tick-hook-firing-verifier.sh doctor [--apply|--dry-run] [--json]
  tick-hook-firing-verifier.sh health [--watch] [--interval N] [--json]
  tick-hook-firing-verifier.sh repair --scope ledger|substrate-contract|all [--dry-run|--apply] [--json]
  tick-hook-firing-verifier.sh validate ledger [--json]
  tick-hook-firing-verifier.sh audit [--json]
  tick-hook-firing-verifier.sh why ID [--json]
  tick-hook-firing-verifier.sh schema classification|doctor|audit|contract [--json]
  tick-hook-firing-verifier.sh --info|--examples|quickstart|help TOPIC|completion bash|zsh
"""


def build_parser():
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("command", nargs="?", default="")
    parser.add_argument("subcommand", nargs="?", default="")
    parser.add_argument("--doctor", action="store_true")
    parser.add_argument("--health", action="store_true")
    parser.add_argument("--repair", action="store_true")
    parser.add_argument("--info", action="store_true")
    parser.add_argument("--examples", action="store_true")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--watch", action="store_true")
    parser.add_argument("--interval", "-i", type=float, default=60)
    parser.add_argument("--window-sec", type=int, default=86400)
    parser.add_argument("--scope", choices=["ledger", "substrate-contract", "all"], default="ledger")
    parser.add_argument("--primitives-file", default="")
    parser.add_argument("--primitives-json", default="")
    parser.add_argument("--repo", default="")
    parser.add_argument("--audit-ledger", default="")
    parser.add_argument("--fuckup-log", default="")
    parser.add_argument("--contract-ledger", default="")
    parser.add_argument("--tick-driver-ledger", default="")
    parser.add_argument("--no-color", action="store_true")
    parser.add_argument("--no-emoji", action="store_true")
    parser.add_argument("--explain", action="store_true")
    parser.add_argument("--idempotency-key", default="")
    parser.add_argument("--width", default="")
    return parser


def main(argv):
    if not argv:
        argv = ["doctor"]
    if any(arg in {"--help", "-h"} for arg in argv):
        print(usage(), end="")
        return 0
    args = build_parser().parse_args(argv)
    global REPO, AUDIT_LEDGER, FUCKUP_LOG, CONTRACT_LEDGER, TICK_DRIVER_LEDGER
    if args.repo:
        REPO = Path(args.repo).expanduser()
    if args.audit_ledger:
        AUDIT_LEDGER = Path(args.audit_ledger).expanduser()
    if args.fuckup_log:
        FUCKUP_LOG = Path(args.fuckup_log).expanduser()
    if args.contract_ledger:
        CONTRACT_LEDGER = Path(args.contract_ledger).expanduser()
    if args.tick_driver_ledger:
        TICK_DRIVER_LEDGER = Path(args.tick_driver_ledger).expanduser()

    mode = args.command
    if args.doctor:
        mode = "doctor"
    elif args.health:
        mode = "health"
    elif args.repair:
        mode = "repair"
    elif args.info:
        mode = "info"
    elif args.examples:
        mode = "examples"
    if mode in {"doctor", ""}:
        return run_doctor(args)
    if mode == "health":
        return run_health(args)
    if mode == "repair":
        return run_repair(args)
    if mode == "validate":
        args.validate_target = args.subcommand or "ledger"
        return run_validate(args)
    if mode == "audit":
        return run_audit(args)
    if mode == "why":
        args.why_id = args.subcommand
        if not args.why_id:
            print("ERR: why requires ID", file=sys.stderr)
            return 2
        return run_why(args)
    if mode == "schema":
        payload = schema_payload(args.subcommand or "classification")
        return emit(payload, args.json, f"schema_version={payload['schema_version']}", 0)
    if mode == "info":
        return emit(info_payload(), args.json, f"tick-hook-firing-verifier {VERSION}", 0)
    if mode == "examples":
        return emit({"schema_version": SCHEMA_VERSION, "examples": examples()}, args.json, "\n".join(examples()), 0)
    if mode == "quickstart":
        return emit({"schema_version": SCHEMA_VERSION, "steps": quickstart()}, args.json, "\n".join(quickstart()), 0)
    if mode == "help":
        print(usage(), end="")
        return 0
    if mode == "completion":
        try:
            print(completion(args.subcommand), end="")
            return 0
        except ValueError as exc:
            print(f"ERR: {exc}", file=sys.stderr)
            return 2
    print(f"ERR: unknown mode: {mode}", file=sys.stderr)
    return 2


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[2:]))
PY
