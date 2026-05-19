#!/usr/bin/env python3
"""Probe runtime parity without substituting orchestrator shell truth for agent truth."""

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path
from typing import Any


MARKER = "PARITY_PROBE_RESULT "


def run_cmd(args: list[str], timeout: int = 5) -> tuple[int, str]:
    try:
        proc = subprocess.run(args, text=True, capture_output=True, timeout=timeout, check=False)
        return proc.returncode, (proc.stdout or proc.stderr or "").strip()
    except Exception as exc:
        return 127, str(exc)


def command_identity(command: str) -> dict[str, Any]:
    found_path = shutil.which(command)
    if not found_path:
        return {
            "found": False,
            "command_v": None,
            "realpath": None,
            "version": None,
            "help_ok": False,
            "smoke_ok": False,
        }
    realpath = str(Path(found_path).resolve())
    version_rc, version_out = run_cmd([found_path, "--version"])
    help_rc, help_out = run_cmd([found_path, "--help"])
    smoke_ok = version_rc == 0 or help_rc == 0
    return {
        "found": True,
        "command_v": found_path,
        "realpath": realpath,
        "version": (version_out.splitlines()[0] if version_out else None),
        "help_ok": help_rc == 0,
        "help_sample": help_out[:160],
        "smoke_ok": smoke_ok,
    }


def load_callback_ref(callback_ref: str) -> dict[str, Any] | None:
    path = Path(os.path.expanduser(callback_ref))
    raw = path.read_text(encoding="utf-8") if path.exists() else callback_ref
    for line in raw.splitlines():
        if line.startswith(MARKER):
            raw = line[len(MARKER) :]
            break
    try:
        data = json.loads(raw)
    except json.JSONDecodeError:
        return None
    return data if isinstance(data, dict) else None


def codex_probe_prompt(command: str) -> str:
    return "\n".join(
        [
            "PARITY_PROBE: run this in your Codex agent execution context, then callback with one line.",
            f"COMMAND={command}",
            "Use command -v, realpath, --version or --help, and a tiny smoke probe.",
            f"Reply exactly: {MARKER}{{\"runtime\":\"codex\",\"status\":\"responsive\",\"command\":\"{command}\",\"found\":true|false,\"command_v\":\"...\",\"realpath\":\"...\",\"version\":\"...\",\"smoke_ok\":true|false}}",
        ]
    )


def send_codex_probe(ntm: str, session: str, pane: int, command: str) -> tuple[bool, str]:
    prompt = codex_probe_prompt(command)
    proc = subprocess.run(
        [ntm, "send", session, f"--pane={pane}", "--no-cass-check", prompt],
        text=True,
        capture_output=True,
        check=False,
    )
    return proc.returncode == 0, (proc.stdout or proc.stderr or "").strip()


def poll_codex_callback(ntm: str, session: str, pane: int, timeout: int) -> dict[str, Any] | None:
    deadline = time.time() + timeout
    while time.time() < deadline:
        proc = subprocess.run(
            [ntm, "logs", session, f"--panes={pane}"],
            text=True,
            capture_output=True,
            check=False,
        )
        text = proc.stdout or proc.stderr or ""
        for line in reversed(text.splitlines()):
            if MARKER in line:
                marker_text = line.split(MARKER, 1)[1].strip()
                try:
                    data = json.loads(marker_text)
                except json.JSONDecodeError:
                    continue
                if isinstance(data, dict):
                    return data
        time.sleep(1)
    return None


def agent_probe_from_runtime(args: argparse.Namespace) -> tuple[dict[str, Any], dict[str, Any]]:
    if args.callback_ref:
        data = load_callback_ref(args.callback_ref)
        if data is None:
            return (
                {
                    "runtime": args.runtime,
                    "status": "unknown",
                    "command": args.command,
                    "found": False,
                    "smoke_ok": False,
                    "probe_transport": "callback_ref",
                    "callback_received": False,
                },
                {"send_attempted": False, "callback_source": args.callback_ref},
            )
        data.setdefault("runtime", args.runtime)
        data.setdefault("probe_transport", "callback_ref")
        data.setdefault("callback_received", True)
        return data, {"send_attempted": False, "callback_source": args.callback_ref}

    if args.runtime == "codex":
        sent, send_output = send_codex_probe(args.ntm, args.session, args.pane, args.command)
        if not sent:
            return (
                {
                    "runtime": "codex",
                    "status": "unknown",
                    "command": args.command,
                    "found": False,
                    "smoke_ok": False,
                    "probe_transport": "ntm_send",
                    "callback_received": False,
                },
                {"send_attempted": True, "send_output": send_output},
            )
        data = poll_codex_callback(args.ntm, args.session, args.pane, args.timeout)
        if data is None:
            return (
                {
                    "runtime": "codex",
                    "status": "unresponsive",
                    "command": args.command,
                    "found": False,
                    "smoke_ok": False,
                    "probe_transport": "ntm_send",
                    "callback_received": False,
                },
                {"send_attempted": True, "send_output": send_output},
            )
        data.setdefault("runtime", "codex")
        data.setdefault("probe_transport", "ntm_send")
        data.setdefault("callback_received", True)
        return data, {"send_attempted": True, "send_output": send_output}

    if args.runtime == "claude":
        data = command_identity(args.command)
        data.update(
            {
                "runtime": "claude",
                "status": "responsive",
                "command": args.command,
                "probe_transport": "claude_bash_context",
                "callback_received": True,
            }
        )
        return data, {"send_attempted": False, "callback_source": "claude_bash_context"}

    raise ValueError(f"unsupported runtime: {args.runtime}")


def context_drift(agent: dict[str, Any], shell: dict[str, Any]) -> bool:
    agent_status = agent.get("status")
    if agent_status == "unresponsive":
        return False
    if bool(agent.get("found")) != bool(shell.get("found")):
        return True
    if agent.get("realpath") and shell.get("realpath") and agent.get("realpath") != shell.get("realpath"):
        return True
    agent_smoke = bool(agent.get("smoke_ok"))
    shell_smoke = bool(shell.get("smoke_ok"))
    return bool(agent.get("found")) and agent_smoke != shell_smoke


def callback_source(repo: Path, args: argparse.Namespace, agent: dict[str, Any], shell: dict[str, Any], drift: bool) -> Path:
    status = "pass"
    failures: list[str] = []
    if agent.get("status") == "unresponsive":
        status = "unknown"
        failures.append("runtime_unresponsive")
    elif drift:
        status = "fail"
        failures.append("context_drift")
    elif not agent.get("found") or not agent.get("smoke_ok"):
        status = "fail"
        failures.append("agent_probe_failed")

    # flywheel-fmik0 (2026-05-11) calibration: upstream validate-callback.py taxonomy
    # evolved to require `evidence_redacted` field in callback envelopes. B11 fixture
    # parity probes do NOT touch evidence-class files (artifact_paths=[], no
    # files_reserved), so the semantically-correct value is `n/a`. Without this
    # field the validator returns failure_classes=["evidence_redaction_missing"],
    # which the probe then surfaces as top-level status=fail and rc=1. Same
    # calibration class as flywheel-uijqq (B12_AG2). Memory rule:
    # feedback_calibrate_test_to_actual_contract_before_filing_upstream.
    raw = {
        "status": status,
        "failure_classes": failures,
        "evidence_redacted": "n/a",
        "callback_ref": {
            "transport": "ntm" if args.runtime == "codex" else "manual_fixture",
            "session": args.session,
            "pane": args.pane,
            "kind": "TIMEOUT" if status == "unknown" else "DONE",
            "received_at": args.received_at,
            "raw_ref": f"{MARKER}{json.dumps(agent, sort_keys=True)}",
        },
        "evidence": [
            {"type": "command", "ref": f"command -v {args.command}"},
            {"type": "command", "ref": f"realpath $(command -v {args.command})"},
            {"type": "command", "ref": f"{args.command} --version || {args.command} --help"},
        ],
        "artifact_paths": [],
        "runtime_context": {
            "agent_context": {
                "status": "unresponsive" if agent.get("status") == "unresponsive" else "responsive",
                "probe_ref": agent.get("probe_transport") or args.runtime,
                "resolved_tools": [args.command] if agent.get("found") else [],
            },
            "orchestrator_shell_context": {
                "status": "responsive",
                "probe_ref": "orchestrator_shell_command_identity",
                "resolved_tools": [args.command] if shell.get("found") else [],
            },
            "timeout": agent.get("status") == "unresponsive",
            "timeout_seconds": args.timeout if agent.get("status") == "unresponsive" else 0,
            "context_drift": drift,
        },
        "bead_actions": [{"action": "no_bead_reason", "reason": "B11 fixture parity validation only"}],
        "learn_route": {"route": "review", "reason": "runtime parity validation receipt"},
    }
    target = Path(tempfile.mkstemp(prefix="agent-context-parity-callback-", suffix=".json")[1])
    target.write_text(json.dumps(raw, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return target


def validate_callback(repo: Path, dispatch_id: str, callback_file: Path) -> tuple[int, dict[str, Any]]:
    validator = repo / ".flywheel/scripts/validate-callback.py"
    proc = subprocess.run(
        [
            sys.executable,
            str(validator),
            "--repo",
            str(repo),
            "--dispatch-id",
            dispatch_id,
            "--callback-ref",
            str(callback_file),
            "--json",
        ],
        text=True,
        capture_output=True,
        check=False,
    )
    try:
        payload = json.loads(proc.stdout)
    except json.JSONDecodeError:
        payload = {"status": "fail", "failure_classes": ["validate_callback_output_invalid"], "raw": proc.stdout or proc.stderr}
    return proc.returncode, payload


def main() -> int:
    parser = argparse.ArgumentParser(prog="agent-context-parity-probe")
    parser.add_argument("--repo", default=".")
    parser.add_argument("--runtime", choices=["codex", "claude"], required=True)
    parser.add_argument("--session", default="flywheel")
    parser.add_argument("--pane", type=int, default=0)
    parser.add_argument("--command", required=True)
    parser.add_argument("--callback-ref")
    parser.add_argument("--ntm", default="/Users/josh/.local/bin/ntm")
    parser.add_argument("--timeout", type=int, default=90)
    parser.add_argument("--received-at", default="2026-05-03T23:59:00Z")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    repo = Path(args.repo).expanduser().resolve()
    shell = command_identity(args.command)
    agent, transport = agent_probe_from_runtime(args)
    drift = context_drift(agent, shell)
    callback_file = callback_source(repo, args, agent, shell, drift)
    try:
        validation_rc, validation = validate_callback(repo, f"b11-{args.runtime}-{args.command}", callback_file)
    finally:
        callback_file.unlink(missing_ok=True)

    status = validation.get("status", "fail")
    payload = {
        "command": "agent-context-parity-probe",
        "runtime": args.runtime,
        "session": args.session,
        "pane": args.pane,
        "tool": args.command,
        "agent_context": agent,
        "orchestrator_shell_context": shell,
        "context_drift": drift,
        "transport": transport,
        "validation": validation,
        "validation_rc": validation_rc,
        "q03g_integration": "fixture-compatible; live matrix owned by flywheel-q03g",
        "status": status,
    }
    print(json.dumps(payload, indent=None if args.json else 2, sort_keys=True))
    if status == "pass" and validation_rc == 0:
        return 0
    if status == "unknown":
        return 3
    return 1


if __name__ == "__main__":
    raise SystemExit(main())

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-02-conformance-fixtures.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-68-schema-executable-validator-pair.md`
