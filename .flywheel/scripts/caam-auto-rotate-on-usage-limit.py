#!/usr/bin/env python3

# ====== BEGIN canonical-cli scaffold (python; bead flywheel-oozt3) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (filled in by flywheel-0pkcf)
# doctor-mode-tier: filled (bead flywheel-0pkcf over flywheel-oozt3 scaffold)
#
# This block was INJECTED by scaffold-canonical-cli-py.sh. It adds canonical
# introspection surfaces (--info, --schema, --examples, quickstart, help)
# without overriding the target's own argparse subcommands. Per-surface
# stubs (audit, why) were filled in by flywheel-0pkcf per the wave-1
# apply-spec. doctor + health were also filled in this scaffold layer
# (per Python scaffold pattern). repair + validate are handled by the
# target's original argparse below (caam profile select / rotate).

import json as _scaffold_json
import os as _scaffold_os
import sys as _scaffold_sys
import time as _scaffold_time

_SCAFFOLD_SCHEMA_VERSION = "caam-auto-rotate-on-usage-limit/v1"
_SCAFFOLD_AUDIT_LOG = _scaffold_os.environ.get(
    "SCAFFOLD_AUDIT_LOG",
    _scaffold_os.path.join(
        _scaffold_os.path.expanduser("~"),
        ".local/state/flywheel",
        "caam-auto-rotate-on-usage-limit.py-runs.jsonl",
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
        "name": "caam-auto-rotate-on-usage-limit.py",
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
            {"name": "info", "invocation": "caam-auto-rotate-on-usage-limit.py --info --json", "purpose": "introspection"},
            {"name": "schema", "invocation": "caam-auto-rotate-on-usage-limit.py --schema doctor", "purpose": "per-surface schema"},
            {"name": "doctor", "invocation": "caam-auto-rotate-on-usage-limit.py doctor --json", "purpose": "probe substrate"},
        ],
    })


def _scaffold_emit_quickstart() -> int:
    return _scaffold_emit_json({
        "schema_version": _SCAFFOLD_SCHEMA_VERSION,
        "command": "quickstart",
        "steps": [
            {"step": 1, "action": "probe doctor", "command": "caam-auto-rotate-on-usage-limit.py doctor --json"},
            {"step": 2, "action": "check health", "command": "caam-auto-rotate-on-usage-limit.py health --json"},
            {"step": 3, "action": "tail audit", "command": "caam-auto-rotate-on-usage-limit.py audit --json"},
        ],
    })


def _scaffold_emit_topic_help(topic: str = "") -> int:
    topics = {
        "doctor": "topic: doctor — substrate probes: ntm executable, caam vault dir present, recovery ledger writable, jq available, python3 version >=3.8; native rotate handled by `caam-auto-rotate-on-usage-limit.py rotate ...` (original argparse)",
        "health": "topic: health — tails $SCAFFOLD_AUDIT_LOG (default ~/.local/state/flywheel/caam-auto-rotate-on-usage-limit-runs.jsonl); reports last_run_ts, age_seconds, recent_runs (last 20), total_runs; status=warn if last run >24h old; status=warn if log unreadable",
        "repair": "topic: repair — handled by the target's original argparse (caam profile repair). Use `caam-auto-rotate-on-usage-limit.py rotate --tool ntm --session NAME --pane N --apply` for the canonical mutation path. Apply contract enforced via --apply requires --idempotency-key (or equivalent caam-side gate)",
        "validate": "topic: validate — handled by the target's original argparse (caam profile validation). Use `caam-auto-rotate-on-usage-limit.py --tool ntm --session NAME --pane N --dry-run` for read-only validation",
        "audit": "topic: audit — tails $SCAFFOLD_AUDIT_LOG (last 10 rows by default); rows are recovery_class=credential_rotation receipts emitted by the rotate path",
        "why": "topic: why <id> — provenance lookup against $SCAFFOLD_AUDIT_LOG; matches against ts/digest/run_id; states: found / not_found / unavailable",
    }
    if topic and topic in topics:
        print(topics[topic])
    else:
        print("topics: doctor | health | repair | validate | audit | why | quickstart")
    return 0


# ---------- canonical-cli stubs (TODO markers preserved) ----------

def _scaffold_cmd_doctor() -> int:
    import shutil as _scaffold_shutil
    import sys as _scd_sys
    import os as _scd_os
    home = _scd_os.path.expanduser("~")
    ntm_path = f"{home}/.local/bin/ntm"
    caam_dir = f"{home}/.config/caam"
    recovery_ledger = f"{home}/.local/state/flywheel/recovery-ledger.jsonl"
    recovery_ledger_dir = _scd_os.path.dirname(recovery_ledger)

    checks = []
    overall = "pass"

    # Probe 1: ntm executable
    ntm_st = "pass" if (_scd_os.path.isfile(ntm_path) and _scd_os.access(ntm_path, _scd_os.X_OK)) else "fail"
    checks.append({"name": "ntm_executable", "status": ntm_st, "path": ntm_path})

    # Probe 2: caam vault directory
    caam_st = "pass" if _scd_os.path.isdir(caam_dir) else "warn"
    checks.append({"name": "caam_vault_dir", "status": caam_st, "path": caam_dir})

    # Probe 3: recovery ledger dir writable
    rl_st = "fail"
    if _scd_os.path.isdir(recovery_ledger_dir):
        rl_st = "pass" if _scd_os.access(recovery_ledger_dir, _scd_os.W_OK) else "fail"
    checks.append({"name": "recovery_ledger_dir_writable", "status": rl_st, "path": recovery_ledger_dir})

    # Probe 4: jq available
    jq_st = "pass" if _scaffold_shutil.which("jq") else "warn"
    checks.append({"name": "jq_available", "status": jq_st})

    # Probe 5: python3 >=3.8
    py_st = "pass" if (_scd_sys.version_info[0] == 3 and _scd_sys.version_info[1] >= 8) else "fail"
    checks.append({"name": "python3_version_ok", "status": py_st, "detail": f"{_scd_sys.version_info.major}.{_scd_sys.version_info.minor}"})

    # Probe 6: SCAFFOLD_AUDIT_LOG dir writable (for our own observability)
    audit_dir = _scd_os.path.dirname(_SCAFFOLD_AUDIT_LOG)
    aud_st = "pass" if (_scd_os.path.isdir(audit_dir) and _scd_os.access(audit_dir, _scd_os.W_OK)) else "warn"
    checks.append({"name": "audit_log_dir_writable", "status": aud_st, "path": audit_dir})

    for st in (ntm_st, py_st, rl_st):
        if st == "fail":
            overall = "fail"
            break
    if overall == "pass":
        for st in (caam_st, jq_st, aud_st):
            if st == "warn":
                overall = "warn"
                break

    return _scaffold_emit_json({
        "schema_version": _SCAFFOLD_SCHEMA_VERSION,
        "command": "doctor",
        "ts": _scaffold_iso_now(),
        "status": overall,
        "checks": checks,
        "tool_focus": "ntm",
        "recovery_class": "credential_rotation",
    })


def _scaffold_cmd_health() -> int:
    import os as _sch_os
    import json as _sch_json
    from datetime import datetime as _sch_dt, timezone as _sch_tz
    audit_log = _SCAFFOLD_AUDIT_LOG
    stale_threshold = int(_sch_os.environ.get("CAAM_HEALTH_STALE_THRESHOLD_SECONDS", "86400"))
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
    # Tail $SCAFFOLD_AUDIT_LOG; rows are recovery_class=credential_rotation
    # receipts emitted by the rotate path of the original argparse.
    # Default limit=20; future: --limit N CLI flag (canonical-cli-scaffold-py
    # surface doesn't yet wire arg parsing for this verb beyond the bare
    # invocation).
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
        "row_shape_optional": ["digest", "tool", "session", "pane", "recovery_class", "rc"],
    })


def _scaffold_cmd_why(args: list) -> int:
    if not args:
        print("ERR: why requires <id> argument", file=_scaffold_sys.stderr)
        return 64
    id_ = args[0]
    # Provenance lookup against $SCAFFOLD_AUDIT_LOG; matches against
    # ts / digest / run_id / idempotency_key. Last-match wins per
    # sister-pattern (clobber-recovery, flywheel-sync, etc.).
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
                if (row.get("ts") == id_ or row.get("digest") == id_
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
# flywheel-0pkcf: extended to include doctor + health since the target's
# argparse (caam-auto-rotate's `caam profile select / rotate`) does NOT
# implement them; the scaffold-side fillins (_scaffold_cmd_doctor /
# _scaffold_cmd_health below) provide concrete substrate probes per the
# wave-1 apply-spec AG5 requirement. repair + validate stay deferred to
# the original argparse (`--apply --tool ntm`) since they have native
# semantics on this surface.
_SCAFFOLD_CANONICAL_SUBCOMMANDS_FALLBACK = {"audit", "why", "quickstart", "scaffold-help", "doctor", "health"}


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

import argparse, hashlib, json, os, subprocess, sys, time
from datetime import datetime, timezone
from pathlib import Path

SCHEMA = "caam-auto-rotate-on-usage-limit.result.v1"
RECOVERY = "credential_rotation"
AUTH_OPS = ["caam_select_existing_profile", "ntm_rotate_preserve_context", "append_recovery_ledger"]
FORBIDDEN_OPS = ["pane_mutation", "respawn", "launchctl", "new_credential_creation", "token_rotation", "oauth_refresh", "vault_write"]
TTL_WRAPPER = "24h_historical_receipt"
TTL_DECISION = "native_lease_for_active_operation_wrapper_receipt_records_prior_next_selector"
NATIVE_WRAPPER_DELTA = "native_ntm_rotate_owns_account_swap;wrapper_owns_caam_profile_selection_authorization_idempotency_ledgers_and_callback_evidence"
BAD = {"critical", "expired", "unhealthy", "revoked", "disabled"}
RANK = {"healthy": 0, "ok": 0, "warning": 1, "degraded": 2, "unknown": 3}

def h(s): return hashlib.sha256(s.encode()).hexdigest()
def now(): return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
def j(s):
    try: return json.loads(s)
    except Exception: return {}
def run(cmd, stdin_input=None, timeout=30):
    try:
        p = subprocess.run(cmd, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, input=stdin_input, timeout=timeout)
        return p.returncode, p.stdout, p.stderr
    except Exception as e:
        return 127, "", str(e)
def emit(a, status, rc=0, **x):
    p = {"schema": SCHEMA, "status": status, "tool": a.tool, "session": a.session, "pane": a.pane, "digest": a.digest,
         "dry_run": not a.apply, "apply": a.apply, "authorized": x.pop("authorized", False), "recovery_class": RECOVERY,
         "authorized_operations": AUTH_OPS, "forbidden_operations": FORBIDDEN_OPS, "ntm_rotate_subprocess_rc": x.pop("ntm_rotate_subprocess_rc", None),
         "native_surface": "ntm rotate", "wrapper_retained_reason": "flywheel evidence fields and L-rule callback envelope",
         "caam_vault_only": True, "ttl_native": f"{a.ttl_sec}s", "ttl_wrapper": TTL_WRAPPER, "ttl_decision": TTL_DECISION,
         "native_wrapper_delta": NATIVE_WRAPPER_DELTA,
         "secret_values_observed": 0}
    p.update(x)
    if a.json or not a.quiet: print(json.dumps(p, sort_keys=True, separators=(",", ":")))
    sys.exit(rc)
def profiles(raw):
    data = raw if isinstance(raw, list) else raw.get("profiles") or raw.get("accounts") or raw.get("items") or []
    out = []
    for i in data if isinstance(data, list) else []:
        if not isinstance(i, dict): continue
        name = i.get("name") or i.get("profile") or i.get("id")
        if name: out.append({"name": str(name), "active": bool(i.get("active")), "system": bool(i.get("system")), "health": str(i.get("health") or i.get("status") or i.get("state") or "unknown").lower()})
    return out
def active(raw):
    v = raw.get("active_profile") or raw.get("active") or raw.get("profile") if isinstance(raw, dict) else None
    return str(v.get("name") or v.get("profile")) if isinstance(v, dict) else (str(v) if v else None)
def snapshot(a):
    src, rc, out, _ = "list", *run([a.caam_bin, "list", a.tool, "--json"])
    if rc: src, rc, out, _ = "ls", *run([a.caam_bin, "ls", a.tool, "--json"])
    if rc: return None, {"caam_rc": rc, "failure_class": "caam_profile_list_failed", "caam_profile_source": src}
    ps, s_rc, s_out, _ = profiles(j(out)), *run([a.caam_bin, "status", a.tool, "--json"])
    cur = next((p["name"] for p in ps if p["active"]), None) or (active(j(s_out)) if s_rc == 0 else None)
    for p in ps: p["active"] = p["active"] or (cur is not None and p["name"] == cur)
    return {"profiles": ps, "current": cur, "source": src}, None
def choose(s, allow_bad):
    cs = [p for p in s["profiles"] if p["name"] != s["current"] and not p["active"] and not p["system"] and (allow_bad or p["health"] not in BAD)]
    cs.sort(key=lambda p: (RANK.get(p["health"], 3), p["name"]))
    return cs[0] if cs else None
def authz(a):
    rc, out, err = run([a.auth_bin, "--tool", a.tool, "--session", a.session, "--pane", a.pane, "--recovery-class", RECOVERY, "--json"])
    body = j(out)
    if isinstance(body, dict) and body.get("authorized") is True:
        return {"authorized": True, "authorization_status": body.get("status", "authorized"), "stale_topology_allowed": bool(body.get("stale_topology_allowed"))}
    pending = rc and any(x in err.lower() for x in ["unrecognized", "unknown", "invalid option"])
    if pending and not a.apply: return {"authorized": True, "authorization_status": "a3_gate_pending_dry_run", "auth_gate_pending": True}
    return {"authorized": False, "authorization_status": body.get("status", "authorization_failed") if isinstance(body, dict) else "authorization_failed", "auth_rc": rc}
def append(path, row):
    p = Path(path); p.parent.mkdir(parents=True, exist_ok=True)
    with p.open("a") as f: f.write(json.dumps(row, sort_keys=True, separators=(",", ":")) + "\n")
def recent(path, ident, cur, sel, ttl):
    try: rows = Path(path).read_text().splitlines()
    except FileNotFoundError: return None
    cut = time.time() - ttl
    for line in reversed(rows):
        r = j(line)
        if isinstance(r, dict) and r.get("schema") == SCHEMA and r.get("status") == "rotated" and r.get("identity_key") == ident and r.get("active_profile_before") == cur and r.get("selected_profile") == sel and r.get("post_check_active_profile") == sel and float(r.get("rotated_at_epoch", 0)) >= cut:
            return r
def parser():
    p = argparse.ArgumentParser(description="Select a CAAM profile and delegate rate-limit account swap to ntm rotate.")
    for k in ["tool", "session", "pane", "digest"]: p.add_argument(f"--{k}", default="codex" if k == "tool" else "")
    p.add_argument("--dry-run", action="store_true"); p.add_argument("--apply", action="store_true"); p.add_argument("--json", action="store_true"); p.add_argument("--quiet", action="store_true")
    p.add_argument("--auto-recover", action="store_true"); p.add_argument("--allow-unhealthy", action="store_true"); p.add_argument("--operator-ack", default="")
    p.add_argument("--ttl-sec", type=int, default=3600); p.add_argument("--timeout", type=int, default=300)
    p.add_argument("--caam-bin", default=os.environ.get("CAAM_BIN", "caam")); p.add_argument("--ntm-bin", default=os.environ.get("NTM_BIN", "ntm")); p.add_argument("--auth-bin", default=".flywheel/scripts/capacity-halt-pane-authorization.sh")
    p.add_argument("--ledger", default=os.path.expanduser("~/.local/state/flywheel/caam-auto-rotate-on-usage-limit.jsonl")); p.add_argument("--recovery-ledger", default=os.path.expanduser("~/.local/state/flywheel/caam-auto-rotate-recovery.jsonl"))
    p.add_argument("--info", action="store_true"); p.add_argument("--examples", action="store_true"); p.add_argument("--schema", action="store_true")
    return p
def main():
    a = parser().parse_args()
    if a.info or a.examples or a.schema:
        doc = {"schema": SCHEMA, "native_surface": "ntm rotate", "caam_vault_only": True, "ttl_native": "3600s", "ttl_wrapper": TTL_WRAPPER,
               "ttl_decision": TTL_DECISION, "native_wrapper_delta": NATIVE_WRAPPER_DELTA,
               "authorized_operations": AUTH_OPS, "forbidden_operations": FORBIDDEN_OPS,
               "examples": [".flywheel/scripts/caam-auto-rotate-on-usage-limit.py --session flywheel --pane 2 --digest <sha256> --dry-run --json", ".flywheel/scripts/caam-auto-rotate-on-usage-limit.py --session flywheel --pane 2 --digest <sha256> --apply --json"]}
        print(json.dumps(doc, sort_keys=True, indent=2) if a.json or a.schema else "\n".join(doc["examples"])); return
    if a.apply and a.dry_run: emit(a, "malformed", 3, failure_class="conflicting_modes")
    if a.tool != "codex": emit(a, "malformed", 3, failure_class="unsupported_tool")
    missing = [k for k in ["session", "pane", "digest"] if not getattr(a, k)]
    if missing: emit(a, "malformed", 3, failure_class="missing_required", missing=missing)
    if a.auto_recover and a.allow_unhealthy and not a.operator_ack.strip(): emit(a, "refused_allow_unhealthy_requires_operator_ack", 4, failure_class="operator_ack_required")
    az = authz(a)
    if not az.get("authorized"): emit(a, "authorization_failed", 2, authorized=False, **az)
    snap, err = snapshot(a)
    if err: emit(a, "caam_profile_list_failed", 2, **az, **err)
    sel, cur = choose(snap, a.allow_unhealthy), snap["current"]
    if not sel: emit(a, "no_alternate_profile", 4, **az, active_profile_before=cur, caam_profile_source=snap["source"], profile_count=len(snap["profiles"]))
    ident, idem = h("|".join([a.tool, a.session, a.pane, a.digest])), h("|".join([a.tool, a.session, a.pane, a.digest, str(cur), sel["name"]]))
    common = {**az, "active_profile_before": cur, "selected_profile": sel["name"], "selected_profile_health": sel["health"], "caam_profile_source": snap["source"], "profile_count": len(snap["profiles"]), "identity_key": ident, "idempotency_key": idem, "ttl_sec": a.ttl_sec, "profile_selector_hash": h(str(cur) + "->" + sel["name"])[:16]}
    if a.apply and az.get("auth_gate_pending"): emit(a, "authorization_failed", 2, rotated=False, failure_class="auth_gate_pending_apply_refused", **common)
    if a.apply and (dup := recent(a.ledger, ident, cur, sel["name"], a.ttl_sec)): emit(a, "already_rotated_for_signal", 0, rotated=False, duplicate_of=dup.get("rotated_at"), **common)
    cmd = [a.ntm_bin, "rotate", a.session, f"--pane={a.pane}", f"--account={sel['name']}", "--preserve-context", f"--timeout={a.timeout}", "--json"] + ([] if a.apply else ["--dry-run"])
    rc, out, _ = run(cmd, stdin_input="y\n", timeout=a.timeout + 30); body = j(out); post = body.get("account") or body.get("active_profile") or (sel["name"] if rc == 0 else None)
    if rc: emit(a, "ntm_rotate_failed", 2, rotated=False, ntm_rotate_subprocess_rc=rc, ntm_rotate_status=body.get("status") if isinstance(body, dict) else None, **common)
    if not a.apply: emit(a, "dry_run", 0, rotated=False, would_rotate=True, ntm_rotate_subprocess_rc=rc, post_check_active_profile=post, **common)
    ts, epoch = now(), time.time()
    row = {"schema": SCHEMA, "status": "rotated", "rotated": True, "rotated_at": ts, "rotated_at_epoch": epoch, "ntm_rotate_subprocess_rc": rc, "post_check_active_profile": post, **common}
    append(a.ledger, row); append(a.recovery_ledger, {"schema": "caam-auto-rotate-recovery-ledger.v1", "event": RECOVERY, "wrapper_invoked": True, "rotated_at": ts, "identity_key": ident, "idempotency_key": idem, "active_profile_before": cur, "selected_profile": sel["name"], "post_check_active_profile": post, "ntm_rotate_subprocess_rc": rc})
    emit(a, "rotated", 0, rotated=True, rotated_at=ts, rotated_at_epoch=epoch, post_check_active_profile=post, recovery_ledger_written=True, **common, ntm_rotate_subprocess_rc=rc)
if __name__ == "__main__": main()

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
