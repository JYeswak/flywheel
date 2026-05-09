#!/usr/bin/env python3
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
               "examples": [".flywheel/scripts/caam-auto-rotate-on-usage-limit.sh --session flywheel --pane 2 --digest <sha256> --dry-run --json", ".flywheel/scripts/caam-auto-rotate-on-usage-limit.sh --session flywheel --pane 2 --digest <sha256> --apply --json"]}
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
