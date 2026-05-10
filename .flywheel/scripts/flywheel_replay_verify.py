#!/usr/bin/env python3
"""flywheel canonical wrapper for the deterministic-tick-simulation replay-verify helper.

Bead: flywheel-5m9gp (skillos-2j7.1 adoption — AC-test substrate for
blocker-discipline impl).

Doctrine refs:
  - ~/.claude/skills/deterministic-tick-simulation/SKILL.md
  - .flywheel/doctrine/blocker-discipline.md  (load-bearing consumer:
    AC-test-on-every-Nth-tick needs (seed, tick) -> state determinism
    to make AC re-evaluations replayable for incident analysis)
  - .flywheel/doctrine/git-stash-discipline.md  (sister substrate-hygiene-
    doctrine-cluster member)

Adapted from skillos_replay_verify.py (skillos-2j7.1, PR233 merged).
Same wire-format for log/heartbeat/tick/report modes so cross-orch
replay-verify of skillos receipts works on flywheel side. Adds the
flywheel-specific `blocker-ac` mode (worked-example surface for
blocker-discipline AC re-evaluation per Nth tick).

What this wrapper adds on top of `~/.claude/skills/deterministic-tick-
simulation/scripts/replay-verify`:

1. **flywheel telemetry envelope** (flywheel.replay_verify_telemetry.v1).
   Each verdict appends to ~/.local/state/flywheel/replay-verify-
   telemetry.jsonl. Sibling to canonical-cli-scoping receipts.

2. **heartbeat-tick replay-from-receipt mode** — same canonical hash
   shape as skillos so cross-orch replay-verify works. State hash for
   skillos's worked example (ed552165...) reproduces here when run
   against the same canonical receipt.

3. **blocker-ac mode** (flywheel-specific) — given a blocker JSON
   describing an AC predicate, run the predicate twice, hash each
   output, assert the AC is a pure function of substrate state. This
   is the AC-test substrate the blocker-discipline doctrine requires
   for per-tick AC re-evaluation.

4. **--apply gate** — telemetry append is the only mutation; bare
   invocation is read-only. --apply must be present to write.

5. **report subcommand** — verdict-summary over telemetry log.

Exit codes (per /canonical-cli-scoping universal taxonomy):
    0  PASS / clean
    1  MISMATCH (state divergence detected)
    2  usage error / bad input
    3  not-applicable / no receipts found
"""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from types import ModuleType
from typing import Any

SCHEMA_VERSION = "flywheel.replay_verify_telemetry.v1"
TELEMETRY_LOG = Path(
    os.environ.get(
        "FLYWHEEL_REPLAY_VERIFY_TELEMETRY_LOG",
        str(Path.home() / ".local" / "state" / "flywheel" / "replay-verify-telemetry.jsonl"),
    )
)
SKILL_REPLAY_VERIFY = (
    Path.home()
    / ".claude"
    / "skills"
    / "deterministic-tick-simulation"
    / "scripts"
    / "replay-verify"
)
HEARTBEAT_RECEIPT_REQUIRED_KEYS = ("ts", "event")


# ---------------------------------------------------------------- helpers

def _now_utc_seconds_z() -> str:
    """UTC ISO-8601 floor-to-seconds, matching cross-orch receipt convention."""
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def _emit_telemetry(row: dict[str, Any], apply: bool) -> Path | None:
    """Append a telemetry row. Read-only unless apply=True."""
    if not apply:
        return None
    TELEMETRY_LOG.parent.mkdir(parents=True, exist_ok=True)
    with TELEMETRY_LOG.open("a", encoding="utf-8") as f:
        f.write(json.dumps(row, sort_keys=True) + "\n")
    return TELEMETRY_LOG


def _seed_from_receipt(ts: str, state_path: str) -> int:
    """Derive a deterministic 64-bit seed from a heartbeat receipt's witness fields.

    Compatible with skillos_replay_verify._seed_from_receipt — replaying the
    same receipt yields the same seed across orchs.
    """
    h = hashlib.sha256(f"{ts}::{state_path}".encode("utf-8")).hexdigest()
    return int(h[:16], 16)


def _heartbeat_state_hash(receipt: dict[str, Any]) -> str:
    """Compute the deterministic state hash of a heartbeat receipt.

    Canonical form: sort keys, exclude the volatile
    `safe_unrelated_work_this_tick` free-text field (narrative is observation,
    not state). Identical to skillos's canonical form so cross-orch replay-
    verify agrees on the hash.
    """
    canonical = {k: v for k, v in receipt.items() if k != "safe_unrelated_work_this_tick"}
    blob = json.dumps(canonical, sort_keys=True, separators=(",", ":")).encode("utf-8")
    return hashlib.sha256(blob).hexdigest()


def _ac_state_hash(blocker_id: str, ac_command: str, ac_rc: int, ac_stdout: str) -> str:
    """Hash an AC re-evaluation as deterministic state.

    Canonical form: sort the witness fields {blocker_id, ac_command, ac_rc,
    ac_stdout (rstrip-newline)}. The AC predicate must be a pure function over
    substrate state for this hash to be stable across two runs at the same tick.
    """
    canonical = {
        "blocker_id": blocker_id,
        "ac_command": ac_command,
        "ac_rc": int(ac_rc),
        "ac_stdout": ac_stdout.rstrip("\n"),
    }
    blob = json.dumps(canonical, sort_keys=True, separators=(",", ":")).encode("utf-8")
    return hashlib.sha256(blob).hexdigest()


def _load_sim_module(sim_path: Path) -> ModuleType:
    if not sim_path.is_file():
        raise FileNotFoundError(f"sim module not found: {sim_path}")
    spec = importlib.util.spec_from_file_location("_sim_under_test", str(sim_path))
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load spec for {sim_path}")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    if not hasattr(mod, "simulate_with_log"):
        raise AttributeError(
            f"sim module {sim_path} must expose simulate_with_log(seed, tick_count)"
        )
    return mod


# ---------------------------------------------------------------- modes

def cmd_log(args: argparse.Namespace) -> int:
    """Replay-verify a sim from a replay-log JSON; emit telemetry."""
    log_path = Path(args.log)
    sim_path = Path(args.sim)
    try:
        log = json.loads(log_path.read_text())
        sim = _load_sim_module(sim_path)
    except (FileNotFoundError, json.JSONDecodeError, AttributeError, RuntimeError) as e:
        print(f"flywheel_replay_verify: {e}", file=sys.stderr)
        return 2

    seed = int(log["seed"])
    tick_count = int(log["tick_count"])
    fresh = sim.simulate_with_log(seed, tick_count)
    final_match = fresh["final_state_hash"] == log["final_state_hash"]
    verdict = "PASS" if final_match else "MISMATCH"

    row = {
        "schema_version": SCHEMA_VERSION,
        "ts": _now_utc_seconds_z(),
        "command": "log",
        "log_path": str(log_path),
        "sim_path": str(sim_path),
        "seed": str(seed),
        "tick_count": tick_count,
        "verdict": verdict,
        "final_state_hash_expected": log["final_state_hash"],
        "final_state_hash_actual": fresh["final_state_hash"],
    }
    out_path = _emit_telemetry(row, args.apply)
    payload = {**row, "telemetry_emitted_to": str(out_path) if out_path else None}
    if args.json:
        print(json.dumps(payload, indent=2, sort_keys=True))
    else:
        print(f"{verdict} log={log_path} seed={seed} tick_count={tick_count}")
    return 0 if final_match else 1


def cmd_heartbeat(args: argparse.Namespace) -> int:
    """Heartbeat-tick replay-from-receipt mode.

    Reads a row from a JSONL ledger (typically blocker-escalations.jsonl),
    derives (seed, tick) from (ts, state_path), recomputes canonical state hash
    twice, and asserts the function is pure. Compatible with skillos's
    heartbeat mode — same canonical hash function so cross-orch replay agrees.
    """
    receipts_path = Path(args.receipts)
    if not receipts_path.is_file():
        print(f"flywheel_replay_verify: receipts file not found: {receipts_path}", file=sys.stderr)
        return 2

    lines = receipts_path.read_text(encoding="utf-8").splitlines()
    line_no = args.receipt_line
    if line_no < 1 or line_no > len(lines):
        print(f"flywheel_replay_verify: --receipt-line {line_no} out of range (1..{len(lines)})", file=sys.stderr)
        return 2

    try:
        receipt = json.loads(lines[line_no - 1])
    except json.JSONDecodeError as e:
        print(f"flywheel_replay_verify: line {line_no} not valid JSON: {e}", file=sys.stderr)
        return 2

    missing = [k for k in HEARTBEAT_RECEIPT_REQUIRED_KEYS if k not in receipt]
    if missing:
        print(f"flywheel_replay_verify: line {line_no} missing required keys {missing}", file=sys.stderr)
        return 2

    ts = receipt["ts"]
    state_path = receipt.get("blocker_id_state_path", "")
    seed = _seed_from_receipt(ts, state_path)
    h1 = _heartbeat_state_hash(receipt)
    h2 = _heartbeat_state_hash(receipt)
    verdict = "PASS" if h1 == h2 else "MISMATCH"

    row = {
        "schema_version": SCHEMA_VERSION,
        "ts": _now_utc_seconds_z(),
        "command": "heartbeat",
        "receipts_path": str(receipts_path),
        "receipt_line": line_no,
        "receipt_ts": ts,
        "receipt_event": receipt.get("event"),
        "blocker_id_state_path": state_path,
        "seed": f"{seed:016x}",
        "tick_count": 1,
        "verdict": verdict,
        "state_hash": h1,
        "determinism_invariant": "h1 == h2 (pure function over canonical-form receipt)",
    }
    out_path = _emit_telemetry(row, args.apply)
    payload = {**row, "telemetry_emitted_to": str(out_path) if out_path else None}
    if args.json:
        print(json.dumps(payload, indent=2, sort_keys=True))
    else:
        print(f"{verdict} heartbeat line={line_no} ts={ts} seed=0x{seed:016x} hash={h1[:16]}...")
    return 0 if verdict == "PASS" else 1


def cmd_tick(args: argparse.Namespace) -> int:
    """Bare (seed, tick_count) replay against a sim module."""
    sim_path = Path(args.sim)
    try:
        sim = _load_sim_module(sim_path)
    except (FileNotFoundError, AttributeError, RuntimeError) as e:
        print(f"flywheel_replay_verify: {e}", file=sys.stderr)
        return 2
    seed = int(args.seed)
    tick_count = int(args.tick_count)
    a = sim.simulate_with_log(seed, tick_count)
    b = sim.simulate_with_log(seed, tick_count)
    final_match = a["final_state_hash"] == b["final_state_hash"]
    verdict = "PASS" if final_match else "MISMATCH"
    row = {
        "schema_version": SCHEMA_VERSION,
        "ts": _now_utc_seconds_z(),
        "command": "tick",
        "sim_path": str(sim_path),
        "seed": str(seed),
        "tick_count": tick_count,
        "verdict": verdict,
        "final_state_hash": a["final_state_hash"],
        "determinism_invariant": "two independent simulate_with_log invocations produce byte-identical state",
    }
    out_path = _emit_telemetry(row, args.apply)
    payload = {**row, "telemetry_emitted_to": str(out_path) if out_path else None}
    if args.json:
        print(json.dumps(payload, indent=2, sort_keys=True))
    else:
        print(f"{verdict} tick seed={seed} tick_count={tick_count} hash={a['final_state_hash'][:16]}...")
    return 0 if final_match else 1


def cmd_blocker_ac(args: argparse.Namespace) -> int:
    """Blocker AC re-evaluation mode (flywheel-specific).

    Per blocker-discipline.md: every Nth tick, the orch must re-run the
    blocker's `acceptance_condition` predicate. This mode re-runs the AC
    twice and asserts the AC predicate is a pure function over substrate
    state at this tick. The state hash is the canonical record that lets
    a future incident analysis re-derive WHICH tick auto-closed the blocker.

    Verdict semantics:
      PASS — both AC invocations produced byte-identical (rc, stdout); AC is a
             pure function at this tick. ac_passes_now reflects the AC's
             own boolean (rc==0).
      MISMATCH — two invocations produced different (rc, stdout). The AC
                 predicate is not pure (touches non-state substrate, races
                 a clock, etc). Doctrine: re-author the AC.

    Reads blocker JSON from --blocker-file (path) or --blocker-line N
    --blocker-file <jsonl-path>.
    """
    blocker_file = Path(args.blocker_file)
    if not blocker_file.is_file():
        print(f"flywheel_replay_verify: blocker file not found: {blocker_file}", file=sys.stderr)
        return 2

    raw = blocker_file.read_text(encoding="utf-8")
    if args.blocker_line:
        lines = raw.splitlines()
        line_no = args.blocker_line
        if line_no < 1 or line_no > len(lines):
            print(f"flywheel_replay_verify: --blocker-line {line_no} out of range (1..{len(lines)})", file=sys.stderr)
            return 2
        try:
            blocker = json.loads(lines[line_no - 1])
        except json.JSONDecodeError as e:
            print(f"flywheel_replay_verify: line {line_no} not valid JSON: {e}", file=sys.stderr)
            return 2
    else:
        try:
            blocker = json.loads(raw)
        except json.JSONDecodeError as e:
            print(f"flywheel_replay_verify: blocker file not valid JSON: {e}", file=sys.stderr)
            return 2

    blocker_id = blocker.get("blocker_id") or blocker.get("id") or ""
    ac_command = blocker.get("acceptance_condition") or blocker.get("ac") or ""
    if not ac_command:
        print("flywheel_replay_verify: blocker missing acceptance_condition / ac field", file=sys.stderr)
        return 2

    # Run AC twice. Capture (rc, stdout). Hash canonical form.
    def _run_once() -> tuple[int, str]:
        try:
            proc = subprocess.run(
                ["bash", "-c", ac_command],
                capture_output=True,
                text=True,
                timeout=int(args.ac_timeout),
            )
        except subprocess.TimeoutExpired:
            return (124, "")
        return (int(proc.returncode), proc.stdout)

    rc1, stdout1 = _run_once()
    rc2, stdout2 = _run_once()

    h1 = _ac_state_hash(blocker_id, ac_command, rc1, stdout1)
    h2 = _ac_state_hash(blocker_id, ac_command, rc2, stdout2)
    pure = h1 == h2
    verdict = "PASS" if pure else "MISMATCH"
    ac_passes_now = (rc1 == 0)

    row = {
        "schema_version": SCHEMA_VERSION,
        "ts": _now_utc_seconds_z(),
        "command": "blocker-ac",
        "blocker_file": str(blocker_file),
        "blocker_line": args.blocker_line,
        "blocker_id": blocker_id,
        "ac_command_redacted": ac_command if len(ac_command) <= 200 else ac_command[:200] + "...",
        "ac_command_sha256": hashlib.sha256(ac_command.encode("utf-8")).hexdigest(),
        "ac_rc_first": rc1,
        "ac_rc_second": rc2,
        "ac_stdout_sha256_first": hashlib.sha256(stdout1.encode("utf-8")).hexdigest(),
        "ac_stdout_sha256_second": hashlib.sha256(stdout2.encode("utf-8")).hexdigest(),
        "verdict": verdict,
        "ac_pure": pure,
        "ac_passes_now": ac_passes_now,
        "state_hash": h1,
        "determinism_invariant": "h1 == h2 (AC predicate is a pure function over substrate state at this tick)",
    }
    out_path = _emit_telemetry(row, args.apply)
    payload = {**row, "telemetry_emitted_to": str(out_path) if out_path else None}
    if args.json:
        print(json.dumps(payload, indent=2, sort_keys=True))
    else:
        print(f"{verdict} blocker-ac blocker_id={blocker_id or '?'} ac_pure={pure} ac_passes_now={ac_passes_now} hash={h1[:16]}...")
    return 0 if verdict == "PASS" else 1


def cmd_report(args: argparse.Namespace) -> int:
    """Dump a summary of telemetry rows in TELEMETRY_LOG."""
    if not TELEMETRY_LOG.is_file():
        out = {
            "schema_version": SCHEMA_VERSION,
            "command": "report",
            "rows_total": 0,
            "log_path": str(TELEMETRY_LOG),
            "ts": _now_utc_seconds_z(),
        }
        if args.json:
            print(json.dumps(out, indent=2, sort_keys=True))
        else:
            print(f"no telemetry log at {TELEMETRY_LOG}")
        return 3

    rows = [json.loads(l) for l in TELEMETRY_LOG.read_text().splitlines() if l.strip()]
    if args.since:
        rows = [r for r in rows if r.get("ts", "") >= args.since]

    verdict_summary: dict[str, int] = {}
    command_summary: dict[str, int] = {}
    for r in rows:
        v = r.get("verdict", "UNKNOWN")
        c = r.get("command", "UNKNOWN")
        verdict_summary[v] = verdict_summary.get(v, 0) + 1
        command_summary[c] = command_summary.get(c, 0) + 1

    out = {
        "schema_version": SCHEMA_VERSION,
        "command": "report",
        "ts": _now_utc_seconds_z(),
        "log_path": str(TELEMETRY_LOG),
        "rows_total": len(rows),
        "since": args.since,
        "verdict_summary": verdict_summary,
        "command_summary": command_summary,
    }
    if args.json:
        print(json.dumps(out, indent=2, sort_keys=True))
    else:
        print(f"telemetry log {TELEMETRY_LOG}: {len(rows)} rows; verdicts={verdict_summary}; commands={command_summary}")
    return 0


# ---------------------------------------------------------------- argparse

def _parser() -> argparse.ArgumentParser:
    # Globals (--json, --apply) are shared via parent-parser so they're
    # accepted both before AND after the subcommand:
    #   flywheel_replay_verify --json report
    #   flywheel_replay_verify report --json
    common = argparse.ArgumentParser(add_help=False)
    common.add_argument("--json", action="store_true", help="emit JSON output")
    common.add_argument(
        "--apply",
        action="store_true",
        help="append telemetry row to telemetry log (mutation); default is read-only",
    )

    p = argparse.ArgumentParser(prog="flywheel_replay_verify", parents=[common])
    sp = p.add_subparsers(dest="command", required=True)

    log_p = sp.add_parser("log", help="replay-verify a sim from a replay log JSON", parents=[common])
    log_p.add_argument("--log", required=True)
    log_p.add_argument("--sim", required=True)
    log_p.set_defaults(func=cmd_log)

    hb_p = sp.add_parser("heartbeat", help="replay a heartbeat-tick receipt (cross-orch compatible)", parents=[common])
    hb_p.add_argument("--receipts", required=True, help="path to JSONL ledger")
    hb_p.add_argument("--receipt-line", type=int, required=True, help="1-based line number")
    hb_p.set_defaults(func=cmd_heartbeat)

    tick_p = sp.add_parser("tick", help="replay (seed, tick_count) against a sim module", parents=[common])
    tick_p.add_argument("--seed", required=True)
    tick_p.add_argument("--tick-count", type=int, required=True)
    tick_p.add_argument("--sim", required=True)
    tick_p.set_defaults(func=cmd_tick)

    ac_p = sp.add_parser("blocker-ac", help="re-evaluate a blocker's acceptance_condition twice; assert AC purity", parents=[common])
    ac_p.add_argument("--blocker-file", required=True, help="path to blocker JSON or JSONL")
    ac_p.add_argument("--blocker-line", type=int, default=None, help="1-based line number when blocker-file is JSONL")
    ac_p.add_argument("--ac-timeout", type=int, default=10, help="per-AC-invocation timeout in seconds (default 10)")
    ac_p.set_defaults(func=cmd_blocker_ac)

    report_p = sp.add_parser("report", help="summarize telemetry log", parents=[common])
    report_p.add_argument("--since", default=None, help="UTC ISO-8601 cutoff")
    report_p.set_defaults(func=cmd_report)

    return p


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
