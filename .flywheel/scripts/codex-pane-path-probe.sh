#!/usr/bin/env bash
# codex-pane-path-probe.sh — bounded validator for the
# flywheel-orx1 acceptance: every codex/claude pane spawned by the
# canonical fleet shape MUST be able to resolve Jeff substrate
# binaries (dcg, br, ntm, cm, jsm) by bare name.
#
# Strategy: probe deterministic sources, not pane env (which macOS
# SIP refuses to disclose via `ps eww` even for own processes):
#   1. tmux server global PATH      (`tmux show-env -g | grep PATH`)
#   2. zsh login startup PATH       (`zsh -lic 'echo $PATH'`)
#   3. worker self-probe            (this script's own `command -v`)
#   4. canonical respawn plist PATH (mobile-eats-flywheel-loop +
#                                    codex-rollout-permission-janitor +
#                                    codex-watchtower-daily)
#
# Owns: bead flywheel-orx1. Stable exit codes:
#   0  — every probed surface contains ~/.local/bin and resolves all
#        five Jeff binaries
#   1  — at least one surface is missing ~/.local/bin OR fails to
#        resolve a Jeff binary
#  64  — usage error
#
# Triad: doctor / info / schema modes; --json default-on for
# robot consumers.

set -uo pipefail

VERSION="codex-pane-path-probe.v1"
SCRIPT_VERSION="2026-05-09.1"

JEFF_BINS=(dcg br ntm cm jsm)
LOCAL_BIN="$HOME/.local/bin"
JSON=0
MODE="probe"

usage() {
  cat <<'USAGE'
Usage:
  codex-pane-path-probe.sh [--json]
  codex-pane-path-probe.sh --doctor [--json]
  codex-pane-path-probe.sh --info [--json]
  codex-pane-path-probe.sh --schema [--json]
  codex-pane-path-probe.sh --help

Bounded validator for the fleet PATH-discipline contract: the canonical
codex/claude pane spawn shape must include ~/.local/bin so all Jeff
substrate binaries (dcg, br, ntm, cm, jsm) are resolvable by bare name.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON=1; shift ;;
    --doctor) MODE="doctor"; shift ;;
    --info) MODE="info"; shift ;;
    --schema) MODE="schema"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "codex-pane-path-probe.sh: unknown arg: $1" >&2; usage >&2; exit 64 ;;
  esac
done

run_python() {
  python3 - "$VERSION" "$SCRIPT_VERSION" "$MODE" "$JSON" "$LOCAL_BIN" "${JEFF_BINS[@]}" <<'PY'
from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

(
    VERSION,
    SCRIPT_VERSION,
    MODE,
    JSON_RAW,
    LOCAL_BIN,
    *JEFF_BINS,
) = sys.argv[1:]
JSON_OUT = JSON_RAW == "1" or MODE in ("info", "schema")

JEFF_BINS = list(JEFF_BINS)
RELEVANT_PLISTS = [
    Path.home() / "Library/LaunchAgents/ai.zeststream.mobile-eats-flywheel-loop.plist",
    Path.home() / "Library/LaunchAgents/ai.zeststream.codex-rollout-permission-janitor.plist",
    Path.home() / "Library/LaunchAgents/ai.zeststream.codex-watchtower-daily.plist",
]


def emit(payload: dict) -> int:
    if JSON_OUT:
        sys.stdout.write(json.dumps(payload, sort_keys=True) + "\n")
    else:
        for k in ("status", "verdict"):
            if k in payload:
                sys.stdout.write(f"{k}={payload[k]}\n")
        for surface, sig in (payload.get("surfaces") or {}).items():
            sys.stdout.write(f"  {surface} ok={sig.get('ok')} note={sig.get('note')}\n")
    return 0 if payload.get("status") == "ok" else 1


def info_payload() -> dict:
    return {
        "version": VERSION,
        "script_version": SCRIPT_VERSION,
        "schema_version": "codex-pane-path-probe/v1",
        "surfaces": [
            "tmux_server_global_path",
            "zsh_login_path",
            "worker_self_probe",
            "respawn_plist_path",
        ],
        "jeff_bins": JEFF_BINS,
        "local_bin": LOCAL_BIN,
        "mode": "info",
        "status": "ok",
    }


def schema_payload() -> dict:
    return {
        "version": VERSION,
        "schema_version": "codex-pane-path-probe/v1",
        "surface_record": {
            "fields": ["ok", "note", "path_excerpt"],
        },
        "verdict": {
            "values": ["green", "degraded", "red"],
            "rule": "all surfaces ok → green; any miss → degraded; >=2 misses → red",
        },
        "exit_codes": {"0": "all green", "1": "any failure", "64": "usage"},
        "mode": "schema",
        "status": "ok",
    }


def doctor_payload() -> dict:
    issues = []
    if not Path(LOCAL_BIN).exists():
        issues.append(f"missing_local_bin={LOCAL_BIN}")
    for b in JEFF_BINS:
        if not (Path(LOCAL_BIN) / b).exists() and not shutil.which(b):
            issues.append(f"missing_binary={b}")
    return {
        "version": VERSION,
        "schema_version": "codex-pane-path-probe/v1",
        "mode": "doctor",
        "local_bin_exists": Path(LOCAL_BIN).exists(),
        "issues": issues,
        "status": "ok" if not issues else "degraded",
    }


def tmux_server_path() -> dict:
    try:
        result = subprocess.run(
            ["tmux", "show-env", "-g"],
            text=True,
            capture_output=True,
            timeout=5,
            check=False,
        )
    except Exception as exc:
        return {"ok": False, "note": f"tmux_failed={exc}", "path_excerpt": None}
    if result.returncode != 0:
        return {"ok": False, "note": result.stderr.strip()[:200], "path_excerpt": None}
    path = ""
    for line in result.stdout.splitlines():
        if line.startswith("PATH="):
            path = line[5:]
            break
    excerpt = ":".join(path.split(":")[:8])
    return {
        "ok": LOCAL_BIN in path.split(":"),
        "note": f"local_bin_in_tmux_server_PATH={LOCAL_BIN in path.split(':')}",
        "path_excerpt": excerpt,
    }


def zsh_login_path() -> dict:
    try:
        result = subprocess.run(
            ["zsh", "-lic", "printf '%s' \"$PATH\""],
            text=True,
            capture_output=True,
            timeout=8,
            check=False,
        )
    except Exception as exc:
        return {"ok": False, "note": f"zsh_failed={exc}", "path_excerpt": None}
    path = result.stdout.strip()
    parts = path.split(":")
    excerpt = ":".join(parts[:8])
    return {
        "ok": LOCAL_BIN in parts,
        "note": f"local_bin_in_fresh_zsh_login_PATH={LOCAL_BIN in parts}",
        "path_excerpt": excerpt,
    }


def worker_self_probe() -> dict:
    missing = []
    resolved = {}
    for b in JEFF_BINS:
        path = shutil.which(b)
        resolved[b] = path
        if path is None:
            missing.append(b)
    return {
        "ok": not missing,
        "note": ("all_jeff_binaries_resolved" if not missing
                 else f"missing={','.join(missing)}"),
        "path_excerpt": ":".join(os.environ.get("PATH", "").split(":")[:8]),
        "resolved": resolved,
    }


def respawn_plist_path() -> dict:
    issues = []
    plist_paths = []
    for plist in RELEVANT_PLISTS:
        if not plist.exists():
            issues.append(f"missing={plist.name}")
            continue
        try:
            result = subprocess.run(
                ["plutil", "-extract", "EnvironmentVariables.PATH", "raw", "-o", "-", str(plist)],
                text=True,
                capture_output=True,
                timeout=5,
                check=False,
            )
            if result.returncode != 0:
                issues.append(f"{plist.name}=no_PATH_key")
                continue
            path = result.stdout.strip()
            if LOCAL_BIN not in path.split(":"):
                issues.append(f"{plist.name}=local_bin_missing")
            plist_paths.append({
                "plist": plist.name,
                "path_excerpt": ":".join(path.split(":")[:6]),
            })
        except Exception as exc:
            issues.append(f"{plist.name}=lint_failed={exc}")
    return {
        "ok": not issues,
        "note": ("all_plists_have_local_bin" if not issues
                 else "; ".join(issues)),
        "path_excerpt": json.dumps(plist_paths, sort_keys=True)[:400],
    }


def main() -> int:
    if MODE == "info":
        return emit(info_payload())
    if MODE == "schema":
        return emit(schema_payload())
    if MODE == "doctor":
        return emit(doctor_payload())
    surfaces = {
        "tmux_server_global_path": tmux_server_path(),
        "zsh_login_path": zsh_login_path(),
        "worker_self_probe": worker_self_probe(),
        "respawn_plist_path": respawn_plist_path(),
    }
    failed = [k for k, v in surfaces.items() if not v.get("ok")]
    if not failed:
        verdict = "green"
    elif len(failed) >= 2:
        verdict = "red"
    else:
        verdict = "degraded"
    payload = {
        "version": VERSION,
        "schema_version": "codex-pane-path-probe/v1",
        "mode": "probe",
        "surfaces": surfaces,
        "failed_surfaces": failed,
        "verdict": verdict,
        "ts": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "status": "ok" if not failed else "fail",
    }
    return emit(payload)


sys.exit(main())
PY
}

run_python
exit $?
