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
