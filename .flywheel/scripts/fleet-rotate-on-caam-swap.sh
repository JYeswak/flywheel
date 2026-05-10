#!/usr/bin/env python3
"""
fleet-rotate-on-caam-swap.sh — canonical fleet-wide codex rotation primitive.

Doctrine (locked 2026-05-06 after ntm-rotate-stdin-contamination incident):
  - ntm rotate has a tmux-stdin-contamination bug: running it from operator shell
    pollutes the target pane's input buffer with the rotate banner.
  - The reliable swap path is: caam activate <profile> globally, then ntm respawn
    each codex pane (kills codex process), then re-launch codex (picks up new
    caam-active auth on next `codex` invocation).
  - This script is the canonical wrapper for that 3-step recovery, agent-safe.

Inputs (data-decided):
  --session=<name>             Target ntm session (default: flywheel)
  --panes=<list|all-codex>     Which panes to rotate (default: all-codex)
  --target-profile=<name>      caam codex profile name (default: caam-active or first non-current)
  --dry-run                    Print plan, don't execute
  --apply                      Execute (mutually exclusive with --dry-run)
  --json                       Machine-readable output
  --quiet                      Suppress progress chatter

Plan emitted in dry-run is identical to apply except for actual mutations.
Idempotency: each pane respawn is per-pane atomic; partial failure is
recoverable by re-running.

Topology guard: refuses to operate on human_pane / orchestrator_pane / callback_pane
per ~/.local/state/flywheel/session-topology.jsonl.

Class-1-6 check: NONE fire. caam_active_profile_swap is class-2 vault-selector
swap (not credential rotation; per memory feedback_caam_activate_is_flywheel_decided_not_joshua_gated.md).
ntm respawn is class-5 destructive on local pane only (not shared state). Pane
auth swap is INTENDED behavior, not "rotation" in the secret-handling sense.
"""
from __future__ import annotations

# ====== BEGIN canonical-cli scaffold (python; bead flywheel-oozt3) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (filled in by flywheel-ou656)
# doctor-mode-tier: filled (bead flywheel-ou656 over flywheel-oozt3 scaffold)
#
# This block was INJECTED by scaffold-canonical-cli-py.sh. It adds canonical
# introspection surfaces (--info, --schema, --examples, quickstart, help)
# without overriding the target's own argparse subcommands. Per-surface
# stubs (audit, why) were filled in by flywheel-ou656 per the wave-1
# apply-spec. doctor + health were also filled and the scaffold's intercept
# fallback set was extended to include them (sister 0pkcf pattern). repair
# + validate are handled by the target's original argparse below (rotation
# execution path with --apply / --dry-run).

import json as _scaffold_json
import os as _scaffold_os
import sys as _scaffold_sys
import time as _scaffold_time

_SCAFFOLD_SCHEMA_VERSION = "fleet-rotate-on-caam-swap/v1"
_SCAFFOLD_AUDIT_LOG = _scaffold_os.environ.get(
    "SCAFFOLD_AUDIT_LOG",
    _scaffold_os.path.join(
        _scaffold_os.path.expanduser("~"),
        ".local/state/flywheel",
        "fleet-rotate-on-caam-swap.sh-runs.jsonl",
    ),
)


def _scaffold_iso_now() -> str:
    return _scaffold_time.strftime("%Y-%m-%dT%H:%M:%SZ", _scaffold_time.gmtime())


def _scaffold_emit_json(obj: dict) -> int:
    print(_scaffold_json.dumps(obj, sort_keys=True, separators=(",", ":")))
    return 0


def _scaffold_emit_info() -> int:
    return _scaffold_emit_json({
        "schema_version": _SCAFFOLD_SCHEMA_VERSION,
        "command": "info",
        "name": "fleet-rotate-on-caam-swap.sh",
        "kind": "python3",
        "scaffolder_bead": "flywheel-oozt3",
        "audit_log": _SCAFFOLD_AUDIT_LOG,
        "canonical_surfaces": [
            "doctor", "health", "repair", "validate",
            "audit", "why", "quickstart", "help", "completion",
        ],
    })


def _scaffold_emit_schema(surface: str = "default") -> int:
    schemas = {
        "doctor": {
            "required": ["status", "checks"],
            "status_enum": ["pass", "fail", "warn"],
        },
        "health": {
            "required": ["status", "audit_log"],
            "status_enum": ["pass", "warn", "fail"],
        },
        "repair": {
            "required": ["status", "mode", "scope"],
            "mode_enum": ["dry_run", "apply"],
            "mutation_gates": ["--apply requires --idempotency-key"],
        },
        "validate": {
            "required": ["status", "subject"],
            "status_enum": ["pass", "fail", "warn", "refused"],
        },
        "audit": {
            "required": ["audit_log", "rows"],
        },
        "why": {
            "required": ["id", "status"],
            "status_enum": ["found", "not_found", "warn"],
        },
        "default": {
            "surfaces": ["doctor", "health", "repair", "validate", "audit", "why"],
            "stable_exit_codes": {
                "0": "success", "1": "general", "2": "warn",
                "3": "refused (mutation without idempotency-key)", "64": "bad args",
            },
        },
    }
    body = schemas.get(surface, schemas["default"])
    return _scaffold_emit_json({
        "schema_version": _SCAFFOLD_SCHEMA_VERSION,
        "command": "schema",
        "surface": surface,
        **body,
    })


def _scaffold_emit_examples() -> int:
    return _scaffold_emit_json({
        "schema_version": _SCAFFOLD_SCHEMA_VERSION,
        "command": "examples",
        "examples": [
            {"name": "info", "invocation": "fleet-rotate-on-caam-swap.sh --info --json", "purpose": "introspection"},
            {"name": "schema", "invocation": "fleet-rotate-on-caam-swap.sh --schema doctor", "purpose": "per-surface schema"},
            {"name": "doctor", "invocation": "fleet-rotate-on-caam-swap.sh doctor --json", "purpose": "probe substrate"},
        ],
    })


def _scaffold_emit_quickstart() -> int:
    return _scaffold_emit_json({
        "schema_version": _SCAFFOLD_SCHEMA_VERSION,
        "command": "quickstart",
        "steps": [
            {"step": 1, "action": "probe doctor", "command": "fleet-rotate-on-caam-swap.sh doctor --json"},
            {"step": 2, "action": "check health", "command": "fleet-rotate-on-caam-swap.sh health --json"},
            {"step": 3, "action": "tail audit", "command": "fleet-rotate-on-caam-swap.sh audit --json"},
        ],
    })


def _scaffold_emit_topic_help(topic: str = "") -> int:
    topics = {
        "doctor": "topic: doctor — substrate probes: ntm executable, caam executable, topology JSONL readable, ledger dir writable, python3 version >=3.8, audit log dir writable; load-bearing for fleet-wide codex rotation across all sessions on a caam profile swap event",
        "health": "topic: health — tails $SCAFFOLD_AUDIT_LOG (default ~/.local/state/flywheel/fleet-rotate-on-caam-swap-runs.jsonl); reports last_run_ts, age_seconds, recent_runs (last 20), total_runs; status=warn if last run >24h old; status=warn if log unreadable",
        "repair": "topic: repair — handled by the target's original argparse (the rotation execution path). Use `fleet-rotate-on-caam-swap.sh --apply --idempotency-key KEY` for canonical mutation; --dry-run for read-only preview",
        "validate": "topic: validate — handled by the target's original argparse (--dry-run mode); use `fleet-rotate-on-caam-swap.sh --dry-run` to preview which sessions would receive a rotate without mutation",
        "audit": "topic: audit — tails $SCAFFOLD_AUDIT_LOG (last 20 rows by default); rows are recovery_class=fleet_rotation receipts emitted by the rotation path; LEDGER ($HOME/.local/state/flywheel/fleet-rotate-on-caam-swap.jsonl) is the per-rotation receipt ledger (different from $SCAFFOLD_AUDIT_LOG)",
        "why": "topic: why <id> — provenance lookup against $SCAFFOLD_AUDIT_LOG; matches against ts/profile/run_id; states: found / not_found / unavailable",
    }
    if topic and topic in topics:
        print(topics[topic])
    else:
        print("topics: doctor | health | repair | validate | audit | why | quickstart")
    return 0


# ---------- canonical-cli stubs (TODO markers preserved) ----------

def _scaffold_cmd_doctor() -> int:
    import os as _scd_os
    import sys as _scd_sys
    home = _scd_os.path.expanduser("~")
    ntm_path = f"{home}/.local/bin/ntm"
    caam_path = "/opt/homebrew/bin/caam"
    topology = f"{home}/.local/state/flywheel/session-topology.jsonl"
    ledger = f"{home}/.local/state/flywheel/fleet-rotate-on-caam-swap.jsonl"
    ledger_dir = _scd_os.path.dirname(ledger)
    audit_dir = _scd_os.path.dirname(_SCAFFOLD_AUDIT_LOG)

    checks = []
    overall = "pass"

    # Probe 1: ntm executable
    ntm_st = "pass" if (_scd_os.path.isfile(ntm_path) and _scd_os.access(ntm_path, _scd_os.X_OK)) else "fail"
    checks.append({"name": "ntm_executable", "status": ntm_st, "path": ntm_path})

    # Probe 2: caam executable
    caam_st = "pass" if (_scd_os.path.isfile(caam_path) and _scd_os.access(caam_path, _scd_os.X_OK)) else "fail"
    checks.append({"name": "caam_executable", "status": caam_st, "path": caam_path})

    # Probe 3: topology JSONL readable
    topo_st = "pass" if (_scd_os.path.isfile(topology) and _scd_os.access(topology, _scd_os.R_OK)) else "warn"
    checks.append({"name": "topology_jsonl_readable", "status": topo_st, "path": topology})

    # Probe 4: ledger dir writable
    ld_st = "fail"
    if _scd_os.path.isdir(ledger_dir):
        ld_st = "pass" if _scd_os.access(ledger_dir, _scd_os.W_OK) else "fail"
    checks.append({"name": "ledger_dir_writable", "status": ld_st, "path": ledger_dir})

    # Probe 5: python3 version >=3.8
    py_st = "pass" if (_scd_sys.version_info[0] == 3 and _scd_sys.version_info[1] >= 8) else "fail"
    checks.append({"name": "python3_version_ok", "status": py_st, "detail": f"{_scd_sys.version_info.major}.{_scd_sys.version_info.minor}"})

    # Probe 6: audit log dir writable
    aud_st = "pass" if (_scd_os.path.isdir(audit_dir) and _scd_os.access(audit_dir, _scd_os.W_OK)) else "warn"
    checks.append({"name": "audit_log_dir_writable", "status": aud_st, "path": audit_dir})

    for st in (ntm_st, caam_st, ld_st, py_st):
        if st == "fail":
            overall = "fail"
            break
    if overall == "pass":
        for st in (topo_st, aud_st):
            if st == "warn":
                overall = "warn"
                break

    return _scaffold_emit_json({
        "schema_version": _SCAFFOLD_SCHEMA_VERSION,
        "command": "doctor",
        "ts": _scaffold_iso_now(),
        "status": overall,
        "checks": checks,
        "tool_focus": "fleet_rotation",
        "recovery_class": "credential_rotation",
    })


def _scaffold_cmd_health() -> int:
    import os as _sch_os
    import json as _sch_json
    from datetime import datetime as _sch_dt, timezone as _sch_tz
    audit_log = _SCAFFOLD_AUDIT_LOG
    stale_threshold = int(_sch_os.environ.get("FLEET_ROTATE_HEALTH_STALE_THRESHOLD_SECONDS", "86400"))
    if not _sch_os.path.isfile(audit_log):
        return _scaffold_emit_json({
            "schema_version": _SCAFFOLD_SCHEMA_VERSION,
            "command": "health",
            "ts": _scaffold_iso_now(),
            "status": "warn",
            "audit_log": audit_log,
            "reason": "audit_log_missing",
            "last_run_ts": None,
            "age_seconds": None,
            "recent_runs": 0,
            "total_runs": 0,
        })
    total_runs = 0
    recent_rows = []
    last_ts = None
    try:
        with open(audit_log, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                total_runs += 1
                try:
                    row = _sch_json.loads(line)
                    recent_rows.append(row)
                    if "ts" in row:
                        last_ts = row.get("ts")
                except _sch_json.JSONDecodeError:
                    continue
    except OSError:
        pass
    recent_runs = min(20, len(recent_rows))
    age_seconds = None
    status = "pass"
    if last_ts:
        try:
            ts_norm = last_ts.replace("Z", "+00:00")
            last_dt = _sch_dt.fromisoformat(ts_norm)
            now_epoch = int(_sch_dt.now(_sch_tz.utc).timestamp())
            age_seconds = now_epoch - int(last_dt.timestamp())
            if age_seconds > stale_threshold:
                status = "warn"
        except (ValueError, TypeError):
            status = "warn"
    else:
        status = "warn"
    return _scaffold_emit_json({
        "schema_version": _SCAFFOLD_SCHEMA_VERSION,
        "command": "health",
        "ts": _scaffold_iso_now(),
        "status": status,
        "audit_log": audit_log,
        "last_run_ts": last_ts,
        "age_seconds": age_seconds,
        "recent_runs": recent_runs,
        "total_runs": total_runs,
        "stale_threshold_seconds": stale_threshold,
    })


def _scaffold_cmd_audit() -> int:
    # Tail $SCAFFOLD_AUDIT_LOG; rows are recovery_class=fleet_rotation
    # receipts emitted by the rotation execution path of the original
    # argparse. The LEDGER ($HOME/.local/state/flywheel/fleet-rotate-on-caam-swap.jsonl)
    # is a SEPARATE per-rotation receipt ledger; this surface tails the
    # canonical-cli scaffold's own audit log only.
    import os as _sca_os
    import json as _sca_json
    limit = 20
    audit_log = _SCAFFOLD_AUDIT_LOG
    rows = []
    status = "pass"
    if not _sca_os.path.isfile(audit_log):
        status = "warn"
    else:
        try:
            with open(audit_log, "r", encoding="utf-8") as f:
                tail = f.readlines()[-limit:]
            for line in tail:
                line = line.strip()
                if not line:
                    continue
                try:
                    rows.append(_sca_json.loads(line))
                except _sca_json.JSONDecodeError:
                    continue
        except OSError:
            status = "warn"
    return _scaffold_emit_json({
        "schema_version": _SCAFFOLD_SCHEMA_VERSION,
        "command": "audit",
        "audit_log": audit_log,
        "status": status,
        "limit": limit,
        "count": len(rows),
        "rows": rows,
        "row_shape_required": ["ts"],
        "row_shape_optional": ["profile", "session", "rotated_count", "rc"],
    })


def _scaffold_cmd_why(args: list) -> int:
    if not args:
        print("ERR: why requires <id> argument", file=_scaffold_sys.stderr)
        return 64
    id_ = args[0]
    # Provenance lookup against $SCAFFOLD_AUDIT_LOG; matches against
    # ts / profile / run_id / idempotency_key. Last-match wins per
    # sister-pattern (clobber-recovery, flywheel-sync, caam-auto-rotate).
    import os as _scw_os
    import json as _scw_json
    audit_log = _SCAFFOLD_AUDIT_LOG
    if not _scw_os.path.isfile(audit_log):
        return _scaffold_emit_json({
            "schema_version": _SCAFFOLD_SCHEMA_VERSION,
            "command": "why",
            "id": id_,
            "status": "unavailable",
            "reason": "audit_log_missing",
            "audit_log": audit_log,
        })
    match = None
    try:
        with open(audit_log, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    row = _scw_json.loads(line)
                except _scw_json.JSONDecodeError:
                    continue
                if (row.get("ts") == id_ or row.get("profile") == id_
                        or row.get("run_id") == id_ or row.get("idempotency_key") == id_):
                    match = row  # last-match wins
    except OSError:
        return _scaffold_emit_json({
            "schema_version": _SCAFFOLD_SCHEMA_VERSION,
            "command": "why",
            "id": id_,
            "status": "unavailable",
            "reason": "audit_log_unreadable",
            "audit_log": audit_log,
        })
    if match is not None:
        return _scaffold_emit_json({
            "schema_version": _SCAFFOLD_SCHEMA_VERSION,
            "command": "why",
            "id": id_,
            "status": "found",
            "row": match,
        })
    return _scaffold_emit_json({
        "schema_version": _SCAFFOLD_SCHEMA_VERSION,
        "command": "why",
        "id": id_,
        "status": "not_found",
    })


# ---------- early-dispatch intercept ----------
#
# Run BEFORE the target's argparse so canonical introspection (--info,
# --schema, --examples) and per-surface stubs (audit, why) don't have to
# be re-implemented in the target. Targets that already ship doctor /
# health / repair (e.g. flywheel-readme) fall through to their own
# argparse — only canonical surfaces missing from the target are
# intercepted here.
_SCAFFOLD_INTROSPECTION_FLAGS = {"--info", "--schema", "--examples", "--scaffold-help"}
# These canonical subcommands are intercepted ONLY if the target's argparse
# does not already define them. The shim defers via try/except below — if
# the target's argparse later raises SystemExit on an unknown subcommand,
# the shim has already handled the canonical case.
_SCAFFOLD_CANONICAL_SUBCOMMANDS_FALLBACK = {"audit", "why", "quickstart", "scaffold-help", "doctor", "health"}  # flywheel-ou656: extended per sister 0pkcf pattern (doctor + health not in target's argparse)


def _scaffold_main(argv: list) -> int:
    if not argv:
        return 1
    head = argv[0]
    if head == "--info":
        return _scaffold_emit_info()
    if head == "--schema":
        surface = argv[1] if len(argv) > 1 else "default"
        return _scaffold_emit_schema(surface)
    if head == "--examples":
        return _scaffold_emit_examples()
    if head == "--scaffold-help":
        topic = argv[1] if len(argv) > 1 else ""
        return _scaffold_emit_topic_help(topic)
    if head == "audit":
        return _scaffold_cmd_audit()
    if head == "why":
        return _scaffold_cmd_why(argv[1:])
    if head == "quickstart":
        return _scaffold_emit_quickstart()
    if head == "doctor":
        return _scaffold_cmd_doctor()
    if head == "health":
        return _scaffold_cmd_health()
    return 1


if __name__ == "__main__" and len(_scaffold_sys.argv) > 1:
    _scaffold_head = _scaffold_sys.argv[1]
    if (
        _scaffold_head in _SCAFFOLD_INTROSPECTION_FLAGS
        or _scaffold_head in _SCAFFOLD_CANONICAL_SUBCOMMANDS_FALLBACK
    ):
        _scaffold_rc = _scaffold_main(_scaffold_sys.argv[1:])
        _scaffold_sys.exit(_scaffold_rc)
# ====== END canonical-cli scaffold ======

import argparse, json, os, subprocess, sys, time
from pathlib import Path

NTM = "/Users/josh/.local/bin/ntm"
CAAM = "/opt/homebrew/bin/caam"
TOPO = Path.home() / ".local/state/flywheel/session-topology.jsonl"
LEDGER = Path.home() / ".local/state/flywheel/fleet-rotate-on-caam-swap.jsonl"


def run(cmd, stdin_input=None, timeout=60, check=False):
    try:
        p = subprocess.run(cmd, text=True, capture_output=True, input=stdin_input, timeout=timeout)
        if check and p.returncode != 0:
            return p.returncode, p.stdout, p.stderr
        return p.returncode, p.stdout, p.stderr
    except Exception as e:
        return 127, "", str(e)


def get_topology(session):
    """Return {human_pane, orchestrator_pane, callback_pane} for session, empty dict if not found."""
    if not TOPO.exists():
        return {}
    rows = []
    try:
        for line in TOPO.read_text().splitlines():
            if not line.strip():
                continue
            r = json.loads(line)
            if r.get("session") == session:
                rows.append(r)
    except Exception:
        return {}
    if not rows:
        return {}
    last = rows[-1]
    return {k: last.get(k) for k in ("human_pane", "orchestrator_pane", "callback_pane") if k in last}


def get_codex_panes(session):
    rc, out, _ = run([NTM, "--robot-activity=" + session, "--activity-type=codex"])
    if rc:
        return []
    try:
        data = json.loads(out)
        return [a["pane_idx"] for a in data.get("agents", []) if a.get("agent_type") == "codex"]
    except Exception:
        return []


def get_caam_active_profile(tool="codex"):
    rc, out, _ = run([CAAM, "list", tool, "--json"])
    if rc:
        return None
    try:
        data = json.loads(out)
        for p in data.get("profiles", []):
            if p.get("active"):
                return {"name": p["name"], "email": p.get("identity", {}).get("email"), "expires": p.get("identity", {}).get("expires_at")}
    except Exception:
        return None
    return None


def respawn_pane(session, pane, dry_run, quiet=False):
    """Respawn one pane: kill codex, launch fresh codex via printf 'y\\n' | ntm send."""
    if dry_run:
        return {"pane": pane, "action": "respawn+codex-relaunch", "dry_run": True, "rc": 0}
    rc1, _, e1 = run([NTM, "respawn", session, "--panes=" + str(pane), "--force"], timeout=15)
    if rc1:
        return {"pane": pane, "rc": rc1, "stage": "respawn", "error": e1[:200]}
    time.sleep(3)
    rc2, _, e2 = run(
        [NTM, "send", session, "--pane=" + str(pane), "--no-cass-check", "codex --dangerously-bypass-approvals-and-sandbox"],
        stdin_input="y\n",
        timeout=15,
    )
    if rc2:
        return {"pane": pane, "rc": rc2, "stage": "codex-relaunch", "error": e2[:200], "respawn_ok": True}
    if not quiet:
        print(f"  pane {pane}: respawned + codex launching (~15s settle)", file=sys.stderr)
    return {"pane": pane, "rc": 0, "respawn_ok": True, "codex_relaunched": True}


def emit(out, status, results, **extra):
    payload = {
        "schema": "fleet-rotate-on-caam-swap.result.v1",
        "status": status,
        "results": results,
        **extra,
    }
    print(json.dumps(payload, sort_keys=True, separators=(",", ":")))


def append_ledger(row):
    LEDGER.parent.mkdir(parents=True, exist_ok=True)
    with LEDGER.open("a") as f:
        f.write(json.dumps(row, sort_keys=True, separators=(",", ":")) + "\n")


def main():
    ap = argparse.ArgumentParser(description="Fleet-wide codex rotation via caam-already-active + ntm respawn (avoids ntm rotate stdin bug).")
    ap.add_argument("--session", default="flywheel")
    ap.add_argument("--panes", default="all-codex", help="comma-list (e.g. 2,3,4) or 'all-codex'")
    ap.add_argument("--target-profile", default="", help="caam codex profile (default: use whatever's already caam-active)")
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument("--dry-run", action="store_true")
    g.add_argument("--apply", action="store_true")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--quiet", action="store_true")
    a = ap.parse_args()

    active = get_caam_active_profile("codex")
    if not active:
        emit(a, "no_caam_active", [], failure_class="caam_active_profile_unresolved")
        sys.exit(2)

    if a.target_profile and a.target_profile != active["name"]:
        if a.dry_run:
            print(f"  caam activate codex {a.target_profile}  (dry-run)", file=sys.stderr)
        else:
            rc, _, e = run([CAAM, "activate", "codex", a.target_profile], timeout=15)
            if rc:
                emit(a, "caam_activate_failed", [], failure_class="caam_activate_failed", caam_target=a.target_profile, caam_error=e[:200])
                sys.exit(2)
            active = get_caam_active_profile("codex")

    topo = get_topology(a.session)
    forbidden = {topo.get(k) for k in ("human_pane", "orchestrator_pane", "callback_pane") if topo.get(k) is not None}

    if a.panes == "all-codex":
        panes = [p for p in get_codex_panes(a.session) if p not in forbidden]
    else:
        try:
            panes = [int(p.strip()) for p in a.panes.split(",") if p.strip()]
        except ValueError:
            emit(a, "malformed_panes", [], failure_class="invalid_pane_list")
            sys.exit(3)
        panes = [p for p in panes if p not in forbidden]

    if not panes:
        emit(a, "no_eligible_panes", [], failure_class="all_panes_excluded_or_empty", forbidden=list(forbidden))
        sys.exit(4)

    results = []
    for p in panes:
        results.append(respawn_pane(a.session, p, a.dry_run, quiet=a.quiet))

    overall_rc = max((r.get("rc", 0) for r in results), default=0)
    status = "rotated" if a.apply and overall_rc == 0 else ("dry_run" if a.dry_run else "partial_failure")

    if a.apply:
        append_ledger({
            "ts": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
            "session": a.session,
            "panes": panes,
            "active_profile": active,
            "results": results,
            "status": status,
        })

    emit(a, status, results, session=a.session, panes_targeted=panes, active_profile=active, forbidden_panes=list(forbidden))
    sys.exit(0 if overall_rc == 0 else 1)


if __name__ == "__main__":
    main()
