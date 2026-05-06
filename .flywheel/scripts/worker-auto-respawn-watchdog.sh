#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
export WORKER_AUTO_RESPAWN_VERSION="worker-auto-respawn-watchdog.v1.0.0"
export WORKER_AUTO_RESPAWN_SCHEMA="worker-auto-respawn-watchdog.v1"
export WORKER_AUTO_RESPAWN_STATE_DIR="${WORKER_AUTO_RESPAWN_STATE_DIR:-$HOME/.local/state/flywheel}"
export WORKER_AUTO_RESPAWN_TOPOLOGY="${WORKER_AUTO_RESPAWN_TOPOLOGY:-$WORKER_AUTO_RESPAWN_STATE_DIR/session-topology.jsonl}"
export WORKER_AUTO_RESPAWN_ATTEMPTS="${WORKER_AUTO_RESPAWN_ATTEMPTS:-$WORKER_AUTO_RESPAWN_STATE_DIR/auto-respawn-attempts.jsonl}"
export WORKER_AUTO_RESPAWN_FREEZE_DETECTOR="${WORKER_AUTO_RESPAWN_FREEZE_DETECTOR:-$REPO_ROOT/.flywheel/scripts/frozen-pane-detector.sh}"
export WORKER_AUTO_RESPAWN_CODEX_CLASSIFIER="${WORKER_AUTO_RESPAWN_CODEX_CLASSIFIER:-$REPO_ROOT/.flywheel/scripts/codex-template-stuck-detector.sh}"
export WORKER_AUTO_RESPAWN_CAPACITY_AUTO_CONTINUE="${WORKER_AUTO_RESPAWN_CAPACITY_AUTO_CONTINUE:-$REPO_ROOT/.flywheel/scripts/capacity-halt-auto-continue-primitive.sh}"
export WORKER_AUTO_RESPAWN_CAPACITY_LEASE="${WORKER_AUTO_RESPAWN_CAPACITY_LEASE:-$REPO_ROOT/.flywheel/scripts/capacity-halt-lease-primitive.sh}"
export WORKER_AUTO_RESPAWN_CAPACITY_LEASE_TTL_SECONDS="${WORKER_AUTO_RESPAWN_CAPACITY_LEASE_TTL_SECONDS:-90}"
export WORKER_AUTO_RESPAWN_NTM_BIN="${WORKER_AUTO_RESPAWN_NTM_BIN:-/Users/josh/.local/bin/ntm}"
export WORKER_AUTO_RESPAWN_NOTIFY_CMD="${WORKER_AUTO_RESPAWN_NOTIFY_CMD:-/Users/josh/.local/bin/notify}"
export WORKER_AUTO_RESPAWN_SAMPLE_INTERVAL_SECONDS="${WORKER_AUTO_RESPAWN_SAMPLE_INTERVAL_SECONDS:-8}"
export WORKER_AUTO_RESPAWN_SAMPLE_WINDOW_SECONDS="${WORKER_AUTO_RESPAWN_SAMPLE_WINDOW_SECONDS:-16}"
export WORKER_AUTO_RESPAWN_FREEZE_THRESHOLD_SECONDS="${WORKER_AUTO_RESPAWN_FREEZE_THRESHOLD_SECONDS:-300}"
export WORKER_AUTO_RESPAWN_CODEX_WINDOW_SECONDS="${WORKER_AUTO_RESPAWN_CODEX_WINDOW_SECONDS:-8}"
export WORKER_AUTO_RESPAWN_MAX_ATTEMPTS_PER_HOUR="${WORKER_AUTO_RESPAWN_MAX_ATTEMPTS_PER_HOUR:-3}"
export WORKER_AUTO_RESPAWN_MAX_AUTO_CONTINUE_PER_HOUR="${WORKER_AUTO_RESPAWN_MAX_AUTO_CONTINUE_PER_HOUR:-5}"
export WORKER_AUTO_RESPAWN_CHECK_PROTECTED_LIVE="${WORKER_AUTO_RESPAWN_CHECK_PROTECTED_LIVE:-0}"

python3 - "$@" <<'PY'
import argparse, hashlib, json, os, re, subprocess, sys, tempfile, time
from datetime import datetime, timezone
from pathlib import Path

ENV = os.environ
VERSION = ENV["WORKER_AUTO_RESPAWN_VERSION"]
SCHEMA = ENV["WORKER_AUTO_RESPAWN_SCHEMA"]
TOPOLOGY = Path(ENV["WORKER_AUTO_RESPAWN_TOPOLOGY"])
ATTEMPTS = Path(ENV["WORKER_AUTO_RESPAWN_ATTEMPTS"])
FREEZE = ENV["WORKER_AUTO_RESPAWN_FREEZE_DETECTOR"]
CODEX = ENV["WORKER_AUTO_RESPAWN_CODEX_CLASSIFIER"]
CAPACITY_AUTO_CONTINUE = ENV["WORKER_AUTO_RESPAWN_CAPACITY_AUTO_CONTINUE"]
CAPACITY_LEASE = ENV["WORKER_AUTO_RESPAWN_CAPACITY_LEASE"]
CAPACITY_LEASE_TTL = int(ENV["WORKER_AUTO_RESPAWN_CAPACITY_LEASE_TTL_SECONDS"])
NTM = ENV["WORKER_AUTO_RESPAWN_NTM_BIN"]
NOTIFY = ENV["WORKER_AUTO_RESPAWN_NOTIFY_CMD"]
RESPAWN = ENV.get("WORKER_AUTO_RESPAWN_RESPAWN_CMD", "")
FIXTURES = Path(ENV["WORKER_AUTO_RESPAWN_FIXTURE_DIR"]) if ENV.get("WORKER_AUTO_RESPAWN_FIXTURE_DIR") else None
NOW_OVERRIDE = ENV.get("WORKER_AUTO_RESPAWN_NOW_EPOCH", "")
SAMPLE_INTERVAL = int(ENV["WORKER_AUTO_RESPAWN_SAMPLE_INTERVAL_SECONDS"])
SAMPLE_WINDOW = int(ENV["WORKER_AUTO_RESPAWN_SAMPLE_WINDOW_SECONDS"])
FREEZE_THRESHOLD = int(ENV["WORKER_AUTO_RESPAWN_FREEZE_THRESHOLD_SECONDS"])
CODEX_WINDOW = int(ENV["WORKER_AUTO_RESPAWN_CODEX_WINDOW_SECONDS"])
MAX_ATTEMPTS = int(ENV["WORKER_AUTO_RESPAWN_MAX_ATTEMPTS_PER_HOUR"])
MAX_AUTO_CONTINUE = int(ENV["WORKER_AUTO_RESPAWN_MAX_AUTO_CONTINUE_PER_HOUR"])
CHECK_PROTECTED_LIVE = ENV["WORKER_AUTO_RESPAWN_CHECK_PROTECTED_LIVE"] == "1"

def parse_args():
    p = argparse.ArgumentParser(description="Auto-respawn truly-dead worker panes.")
    p.add_argument("--json", action="store_true")
    p.add_argument("--quiet", action="store_true")
    p.add_argument("--dry-run", action="store_true", default=True)
    p.add_argument("--apply", action="store_true")
    p.add_argument("--session", default="")
    p.add_argument("--pane", default="")
    p.add_argument("--topology", default="")
    p.add_argument("--attempts", default="")
    p.add_argument("--fixture-dir", default="")
    p.add_argument("--info", action="store_true")
    p.add_argument("--examples", action="store_true")
    return p.parse_args()

def now_epoch():
    return int(NOW_OVERRIDE or time.time())

def now_iso():
    return datetime.fromtimestamp(now_epoch(), timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

def read_jsonl(path):
    rows = []
    try:
        for line in path.read_text().splitlines():
            if not line.strip():
                continue
            try:
                row = json.loads(line)
            except json.JSONDecodeError:
                continue
            if isinstance(row, dict):
                rows.append(row)
    except FileNotFoundError:
        pass
    return rows

def emit(payload, args, rc=0):
    if args.json:
        print(json.dumps(payload, sort_keys=True))
    elif payload.get("mode") == "info":
        recoveries = payload.get("recoveries") or {}
        print(f"worker-auto-respawn-watchdog mode=info version={payload.get('version')} auto_continue={recoveries.get('model_at_capacity_halt', 'none')} worker_scope_only={payload.get('worker_scope_only')}")
    elif not args.quiet:
        print(f"worker-auto-respawn-watchdog status={payload.get('status')} checked={payload.get('targets_checked', 0)} respawned={payload.get('auto_respawns_fired', 0)} continued={payload.get('auto_continues_fired', 0)} notified={payload.get('notify_fallbacks_fired', 0)}")
    raise SystemExit(rc)

def info(args):
    payload = {
        "schema_version": SCHEMA, "success": True, "mode": "info", "version": VERSION,
        "primitive": "worker-auto-respawn-watchdog", "topology_file": str(TOPOLOGY),
        "attempts_file": str(ATTEMPTS), "freeze_detector": FREEZE,
        "code_classifier": CODEX, "capacity_auto_continue": CAPACITY_AUTO_CONTINUE,
        "capacity_lease": CAPACITY_LEASE, "notify_cmd": NOTIFY, "worker_scope_only": True,
        "detector_contract": {"captures": 3, "window_seconds": SAMPLE_WINDOW, "freeze_threshold_seconds": FREEZE_THRESHOLD},
        "budget": {"max_attempts_per_hour": MAX_ATTEMPTS, "max_auto_continue_per_hour": MAX_AUTO_CONTINUE},
        "capacity_halt_recovery_fields": ["attempted", "sent", "recovered"],
        "capacity_halt_authorization_fields": ["pane_role", "authorization_outcome", "topology_source_ts"],
        "capacity_halt_budget_fields": ["per_pane_count_window", "fleet_count_window", "budget_outcome"],
        "recoveries": {"model_at_capacity_halt": "auto_continue"},
        "exit_codes": {"0": "no-action-needed", "1": "auto-action-fired", "2": "notify-fallback-fired", "3": "probe-error"},
    }
    emit(payload, args, 0)

def examples():
    print("worker-auto-respawn-watchdog.sh --dry-run --json")
    print("worker-auto-respawn-watchdog.sh --apply --json --quiet")
    print("WORKER_AUTO_RESPAWN_MAX_AUTO_CONTINUE_PER_HOUR=5 worker-auto-respawn-watchdog.sh --apply --json")
    print("WORKER_AUTO_RESPAWN_FIXTURE_DIR=/tmp/fixtures worker-auto-respawn-watchdog.sh --apply --json")
    raise SystemExit(0)

def latest_topologies():
    if not TOPOLOGY.exists() or TOPOLOGY.stat().st_size == 0:
        return None
    latest = {}
    for row in read_jsonl(TOPOLOGY):
        session = row.get("session")
        if not session:
            continue
        prev = latest.get(session)
        ts = str(row.get("effective_at") or row.get("ts") or "")
        if prev is None or ts >= str(prev.get("effective_at") or prev.get("ts") or ""):
            latest[str(session)] = row
    return [latest[k] for k in sorted(latest)]

def target_rows(rows, session_filter, pane_filter):
    out = []
    for row in rows:
        session = str(row.get("session"))
        protected = []
        roles = []
        for role, key in (("orchestrator", "orchestrator_pane"), ("human", "human_pane"), ("callback", "callback_pane")):
            if row.get(key) is not None:
                pane = str(row[key])
                if pane not in protected:
                    protected.append(pane)
                    roles.append({"session": session, "pane": pane, "role": role, "effective_at": row.get("effective_at") or row.get("ts")})
        for pane in row.get("worker_panes") or []:
            pane = str(pane)
            if pane not in protected:
                out.append({"session": session, "pane": pane, "role": "worker", "effective_at": row.get("effective_at") or row.get("ts")})
        out.extend(roles)
    return [t for t in out if (not session_filter or t["session"] == session_filter) and (not pane_filter or t["pane"] == pane_filter)]

def fixture_path(session, pane):
    if not FIXTURES:
        return None
    path = FIXTURES / f"{session}-{pane}.json"
    return path if path.exists() else None

def classify_fixture(session, pane, path):
    try:
        fx = json.loads(path.read_text())
    except Exception as exc:
        return {"success": False, "source": "fixture", "session": session, "pane": pane, "classifier": "probe_error", "subclass": "probe_error", "truly_dead": False, "error": str(exc)}
    if fx.get("force_probe_error"):
        return {"success": False, "source": "fixture", "session": session, "pane": pane, "classifier": "probe_error", "subclass": "probe_error", "truly_dead": False, "error": "fixture_forced_probe_error"}
    raw = str(fx.get("classifier") or fx.get("subclass") or fx.get("status") or fx.get("verdict") or "alive").lower()
    dead = raw in {"truly_dead", "input_deaf", "post_completion"}
    classifier = "recoverable_halt" if raw == "model_at_capacity_halt" else "truly_dead" if dead else raw
    digest = str(fx.get("scrollback_digest") or hashlib.sha256(json.dumps(fx, sort_keys=True).encode()).hexdigest())
    return {"success": True, "source": "fixture", "session": session, "pane": pane, "classifier": classifier, "subclass": raw, "truly_dead": dead, "freeze_age_seconds": int(fx.get("freeze_age_seconds") or fx.get("age_seconds") or 0), "freeze_status": raw, "fixture_path": str(path), "scrollback_digest": digest, "basis": ["fixture"]}

class LiveProbe:
    def __init__(self, targets):
        self.tmp = tempfile.TemporaryDirectory(prefix="worker-auto-respawn-watchdog.")
        self.samples = {(t["session"], t["pane"]): [] for t in targets}
        for idx in range(3):
            for session, pane in list(self.samples):
                self.samples[(session, pane)].append(self.copy_text(session, pane))
            if idx < 2 and self.samples:
                time.sleep(SAMPLE_INTERVAL)
    def copy_text(self, session, pane):
        path = Path(self.tmp.name) / f"copy-{session}-{pane}-{len(self.samples.get((session, pane), []))}.txt"
        proc = subprocess.run([NTM, "copy", f"{session}:{pane}", "-l", "120", "--output", str(path), "--quiet"], text=True, capture_output=True)
        if proc.returncode == 0 and path.exists():
            return path.read_text(errors="replace")
        fallback = subprocess.run([NTM, f"--robot-tail={session}", f"--panes={pane}", "--lines=120"], text=True, capture_output=True)
        try:
            payload = json.loads(fallback.stdout)
            return "\n".join(payload.get("panes", {}).get(str(pane), {}).get("lines", []))
        except Exception:
            return ""

WORKING_RE = re.compile(r"(?:Working|Waiting for background terminal)\s*\((?:(\d+)h\s*)?(?:(\d+)m\s*)?(\d+)s", re.I)
PROMPT_RE = re.compile(r"^\s*›\s+\S", re.M)
CHEVRON_ONLY_RE = re.compile(r"^\s*›\s*$", re.M)
CAPACITY_HALT_RE = re.compile(r"(selected model is at capacity|please try a different model)", re.I)

def spinner_seconds(text):
    best = 0
    for h, m, s in WORKING_RE.findall(text):
        best = max(best, int(h or 0) * 3600 + int(m or 0) * 60 + int(s or 0))
    return best

def ready_prompt_visible(text):
    return PROMPT_RE.search("\n".join(text.splitlines()[-12:])) is not None

def capacity_halt_visible(text):
    tail = "\n".join(text.splitlines()[-50:])
    return CAPACITY_HALT_RE.search(tail) is not None and CHEVRON_ONLY_RE.search(tail) is not None

def classify_live(probe, session, pane):
    samples = probe.samples.get((session, pane), [])
    if len(samples) != 3 or not all(s.strip() for s in samples):
        return {"success": False, "source": "live", "session": session, "pane": pane, "classifier": "probe_error", "subclass": "probe_error", "truly_dead": False, "error": "live_capture_failed"}
    hashes = [hashlib.sha256(s.encode()).hexdigest() for s in samples]
    stable = len(set(hashes)) == 1
    age = max(spinner_seconds(s) for s in samples)
    prompt_visible = ready_prompt_visible(samples[-1])
    if stable and capacity_halt_visible(samples[-1]):
        digest = hashlib.sha256("\n".join(samples[-1].splitlines()[-30:]).encode()).hexdigest()
        return {
            "success": True,
            "source": "live", "session": session, "pane": pane,
            "classifier": "recoverable_halt", "subclass": "model_at_capacity_halt",
            "truly_dead": False, "freeze_age_seconds": age,
            "hash_stable": stable, "ready_prompt_visible": True,
            "hashes": hashes, "scrollback_digest": digest, "basis": ["capacity-halt-stable-chevron"],
        }
    dead = stable and age >= FREEZE_THRESHOLD and not prompt_visible
    subclass = "post_completion" if dead else "prompt_ready_not_dead" if prompt_visible else "alive"
    return {
        "success": True,
        "source": "live", "session": session, "pane": pane,
        "classifier": "truly_dead" if dead else "not_truly_dead", "subclass": subclass,
        "truly_dead": dead, "freeze_age_seconds": age,
        "hash_stable": stable, "ready_prompt_visible": prompt_visible,
        "hashes": hashes, "basis": ["multi-frame-hash-diff"] if dead else [],
    }

def attempt_count(session, pane, action="respawn_attempt"):
    cutoff = now_epoch() - 3600
    return sum(1 for r in read_jsonl(ATTEMPTS)
               if r.get("action") == action
               and r.get("session") == session
               and str(r.get("pane")) == str(pane)
               and int(r.get("epoch") or 0) >= cutoff)

def append_attempt(session, pane, attempt, reason, action="respawn_attempt", recovery_attempted=None, details=None):
    ATTEMPTS.parent.mkdir(parents=True, exist_ok=True)
    row = {"ts": now_iso(), "epoch": now_epoch(), "action": action, "session": session, "pane": int(pane) if str(pane).isdigit() else pane, "attempt_number": attempt, "reason": reason, "source": "worker-auto-respawn-watchdog"}
    if recovery_attempted:
        row["recovery_attempted"] = recovery_attempted
    if details:
        row.update(details)
    with ATTEMPTS.open("a") as handle:
        handle.write(json.dumps(row, sort_keys=True) + "\n")

def call_respawn(session, pane, reason):
    if RESPAWN:
        return subprocess.run([RESPAWN, session, str(pane), reason]).returncode
    msg = f'/flywheel:respawn {session} --panes={pane} --reason "{reason}" --bead flywheel-wire-watchdog-auto-respawn-not-notify-o-a1d67342'
    return subprocess.run([NTM, "send", "flywheel", "--pane=1", "--no-cass-check", msg]).returncode

def call_notify(title, body):
    return subprocess.run([NOTIFY, "--priority", "1", "--sound", "siren", title, body]).returncode

def capacity_auto_continue(session, pane, digest):
    env = os.environ.copy()
    env["CAPACITY_HALT_AUTO_CONTINUE_LEASE"] = CAPACITY_LEASE
    env["CAPACITY_HALT_AUTO_CONTINUE_NTM_BIN"] = NTM
    cmd = [
        CAPACITY_AUTO_CONTINUE,
        "--session", session,
        "--pane", str(pane),
        "--digest", digest,
        "--ttl", str(CAPACITY_LEASE_TTL),
        "--apply",
        "--json",
    ]
    try:
        proc = subprocess.run(cmd, text=True, capture_output=True, env=env)
        payload = json.loads(proc.stdout) if proc.stdout.strip().startswith("{") else {"status": "non_json", "stdout": proc.stdout[-500:], "stderr": proc.stderr[-500:]}
        return {"rc": proc.returncode, "payload": payload}
    except Exception as exc:
        return {"rc": 3, "payload": {"status": "error", "error": str(exc)}}

def authorization_details(primitive):
    payload = primitive.get("payload") or {}; auth_payload = (payload.get("authorization") or {}).get("payload") or {}
    return {"pane_role": payload.get("pane_role") or auth_payload.get("role") or "unknown",
            "authorization_outcome": payload.get("authorization_outcome") or auth_payload.get("status"),
            "topology_source_ts": payload.get("topology_source_ts") or auth_payload.get("topology_source_ts")}

def budget_details(primitive):
    payload = primitive.get("payload") or {}; budget = payload.get("budget") or {}
    return {"per_pane_count_window": payload.get("per_pane_count_window", budget.get("per_pane_count_window")),
            "fleet_count_window": payload.get("fleet_count_window", budget.get("fleet_count_window")),
            "budget_outcome": payload.get("budget_outcome") or budget.get("budget_outcome") or budget.get("status")}

def classify(probe, session, pane):
    fx = fixture_path(session, pane)
    return classify_fixture(session, pane, fx) if fx else classify_live(probe, session, pane)

def process_target(args, probe, target):
    session, pane, role = target["session"], target["pane"], target["role"]
    if role != "worker" and not CHECK_PROTECTED_LIVE and not fixture_path(session, pane):
        return {"session": session, "pane": pane, "role": role, "action": "protected_skipped", "worker_scope_only": True, "truly_dead": False, "classification": {"source": "skipped"}}
    cls = classify(probe, session, pane)
    attempts = attempt_count(session, pane)
    auto_continue_attempts = attempt_count(session, pane, "auto_continue_attempt")
    action, reason, action_rc = "none", "not_truly_dead", 0
    if not cls.get("success"):
        action, reason = "probe_error", cls.get("error", "probe_error")
    elif cls.get("subclass") == "model_at_capacity_halt" and role != "worker":
        action, reason = ("would_notify" if not args.apply else "notify_fallback_fired"), f"{role}_pane_auto_continue_refused_worker_scope_only"
        if args.apply:
            action_rc = call_notify("Worker auto-continue refused protected pane", f"{session}:{pane} classified model_at_capacity_halt but role={role}; manual intervention required")
    elif cls.get("subclass") == "model_at_capacity_halt" and auto_continue_attempts >= MAX_AUTO_CONTINUE:
        action, reason = ("would_notify" if not args.apply else "notify_fallback_fired"), "auto_continue_budget_exhausted"
        if args.apply:
            action_rc = call_notify("Auto-continue budget exhausted", f"{session}:{pane} reached {auto_continue_attempts} capacity-halt attempts in the last hour; manual intervention required")
    elif cls.get("subclass") == "model_at_capacity_halt":
        action, reason = ("would_auto_continue" if not args.apply else "auto_continue_fired"), "model_at_capacity_halt_auto_continue"
        if args.apply:
            digest = cls.get("scrollback_digest") or hashlib.sha256(f"{session}:{pane}:model_at_capacity_halt".encode()).hexdigest()
            primitive = capacity_auto_continue(session, pane, digest)
            cls["capacity_auto_continue"] = primitive
            auth_details = authorization_details(primitive)
            budget_fields = budget_details(primitive)
            if primitive["rc"] in {5, 6, 7}:
                refusal_counts = dict({"attempted": False, "sent": False, "recovered": False}, **auth_details, **budget_fields)
                append_attempt(session, pane, auto_continue_attempts + 1, auth_details["authorization_outcome"] or "auto_continue_authorization_refused", "auto_continue_authorization_refusal", "auto_continue", refusal_counts)
                cls["capacity_halt_recovery"] = refusal_counts
                return {"session": session, "pane": pane, "role": role, "worker_scope_only": True, "action": "auto_continue_authorization_refused", "reason": auth_details["authorization_outcome"] or "auto_continue_authorization_refused", "attempts_last_hour": attempts, "auto_continue_attempts_last_hour": auto_continue_attempts, "max_attempts_per_hour": MAX_ATTEMPTS, "max_auto_continue_per_hour": MAX_AUTO_CONTINUE, "action_rc": primitive["rc"], "truly_dead": False, "classification": cls, "capacity_auto_continue": primitive}
            if primitive["rc"] == 8:
                refusal_counts = dict({"attempted": False, "sent": False, "recovered": False}, **auth_details, **budget_fields)
                append_attempt(session, pane, auto_continue_attempts + 1, budget_fields["budget_outcome"] or "auto_continue_budget_exhausted", "auto_continue_budget_exhausted", "auto_continue", refusal_counts)
                cls["capacity_halt_recovery"] = refusal_counts
                return {"session": session, "pane": pane, "role": role, "worker_scope_only": True, "action": "auto_continue_budget_exhausted", "reason": budget_fields["budget_outcome"] or "auto_continue_budget_exhausted", "attempts_last_hour": attempts, "auto_continue_attempts_last_hour": auto_continue_attempts, "max_attempts_per_hour": MAX_ATTEMPTS, "max_auto_continue_per_hour": MAX_AUTO_CONTINUE, "action_rc": 8, "truly_dead": False, "classification": cls, "capacity_auto_continue": primitive}
            if primitive["rc"] == 2:
                return {"session": session, "pane": pane, "role": role, "worker_scope_only": True, "action": "auto_continue_lease_held", "reason": "capacity_halt_duplicate_lease_held", "attempts_last_hour": attempts, "auto_continue_attempts_last_hour": auto_continue_attempts, "max_attempts_per_hour": MAX_ATTEMPTS, "max_auto_continue_per_hour": MAX_AUTO_CONTINUE, "action_rc": 0, "truly_dead": False, "classification": cls, "capacity_auto_continue": primitive}
            if primitive["rc"] == 4:
                return {"session": session, "pane": pane, "role": role, "worker_scope_only": True, "action": "probe_error", "reason": "auto_continue_transport_timeout", "attempts_last_hour": attempts, "auto_continue_attempts_last_hour": auto_continue_attempts, "max_attempts_per_hour": MAX_ATTEMPTS, "max_auto_continue_per_hour": MAX_AUTO_CONTINUE, "action_rc": 4, "truly_dead": False, "classification": cls, "capacity_auto_continue": primitive}
            if primitive["rc"] not in {0, 1}:
                return {"session": session, "pane": pane, "role": role, "worker_scope_only": True, "action": "probe_error", "reason": "auto_continue_primitive_failed", "attempts_last_hour": attempts, "auto_continue_attempts_last_hour": auto_continue_attempts, "max_attempts_per_hour": MAX_ATTEMPTS, "max_auto_continue_per_hour": MAX_AUTO_CONTINUE, "action_rc": primitive["rc"], "truly_dead": False, "classification": cls, "capacity_auto_continue": primitive}
            primitive_payload = primitive.get("payload") or {}
            recovery_counts = {
                "attempted": True,
                "sent": bool(primitive_payload.get("sent")),
                "recovered": bool(primitive_payload.get("recovered")),
                "success_measurement_verdict": ((primitive_payload.get("success_measurement") or {}).get("payload") or {}).get("verdict"),
                **auth_details,
                **budget_fields,
            }
            append_attempt(session, pane, auto_continue_attempts + 1, reason, "auto_continue_attempt", "auto_continue", recovery_counts)
            cls["capacity_halt_recovery"] = recovery_counts
            action_rc = primitive["rc"]
    elif cls.get("truly_dead") and role != "worker":
        action, reason = ("would_notify" if not args.apply else "notify_fallback_fired"), f"{role}_pane_respawn_refused_worker_scope_only"
        if args.apply:
            action_rc = call_notify("Worker auto-respawn refused protected pane", f"{session}:{pane} classified truly_dead but role={role}; manual intervention required")
    elif cls.get("truly_dead") and attempts >= MAX_ATTEMPTS:
        action, reason = ("would_notify" if not args.apply else "notify_fallback_fired"), "auto_respawn_budget_exhausted"
        if args.apply:
            action_rc = call_notify("Auto-respawn budget exhausted", f"{session}:{pane} reached {attempts} attempts in the last hour; manual intervention required")
    elif cls.get("truly_dead"):
        action, reason = ("would_auto_respawn" if not args.apply else "auto_respawn_fired"), "truly_dead_worker_auto_respawn"
        if args.apply:
            append_attempt(session, pane, attempts + 1, reason)
            action_rc = call_respawn(session, pane, reason)
    return {"session": session, "pane": pane, "role": role, "worker_scope_only": role == "worker", "action": action, "reason": reason, "attempts_last_hour": attempts, "auto_continue_attempts_last_hour": auto_continue_attempts, "max_attempts_per_hour": MAX_ATTEMPTS, "max_auto_continue_per_hour": MAX_AUTO_CONTINUE, "action_rc": action_rc, "truly_dead": bool(cls.get("truly_dead")), "classification": cls}

def main():
    global TOPOLOGY, ATTEMPTS, FIXTURES
    args = parse_args()
    if args.topology:
        TOPOLOGY = Path(args.topology)
    if args.attempts:
        ATTEMPTS = Path(args.attempts)
    if args.fixture_dir:
        FIXTURES = Path(args.fixture_dir)
    if args.examples:
        examples()
    if args.info:
        info(args)
    rows = latest_topologies()
    if rows is None:
        emit({"schema_version": SCHEMA, "success": False, "status": "probe_error", "ts": now_iso(), "reason": "topology_lookup_failed", "targets_checked": 0, "auto_respawns_fired": 0, "notify_fallbacks_fired": 0, "actions": [], "results": []}, args, 3)
    targets = target_rows(rows, args.session, args.pane)
    live_targets = [t for t in targets if not fixture_path(t["session"], t["pane"]) and (t["role"] == "worker" or CHECK_PROTECTED_LIVE)]
    probe = LiveProbe(live_targets)
    results = [process_target(args, probe, t) for t in targets]
    actions = [r for r in results if r["action"] not in {"none", "protected_skipped"}]
    payload = {
        "schema_version": SCHEMA, "version": VERSION, "success": True, "ts": now_iso(),
        "dry_run": not args.apply, "apply": args.apply, "topology_file": str(TOPOLOGY),
        "attempts_file": str(ATTEMPTS), "detector_contract": {"captures": 3, "window_seconds": SAMPLE_WINDOW},
        "targets_checked": len(results), "workers_checked": sum(1 for r in results if r["role"] == "worker"),
        "protected_refusals": sum(1 for r in results if r["role"] != "worker" and r["action"] in {"would_notify", "notify_fallback_fired"}),
        "auto_respawns_fired": sum(1 for r in results if r["action"] == "auto_respawn_fired"),
        "auto_continues_fired": sum(1 for r in results if r["action"] == "auto_continue_fired"),
        "auto_continue_lease_refusals": sum(1 for r in results if r["action"] == "auto_continue_lease_held"),
        "auto_continue_authorization_refusals": sum(1 for r in results if r["action"] == "auto_continue_authorization_refused"),
        "auto_continue_budget_refusals": sum(1 for r in results if r["action"] == "auto_continue_budget_exhausted"),
        "capacity_halt_recovery_attempted": sum(1 for r in results if (r.get("classification") or {}).get("capacity_halt_recovery", {}).get("attempted") is True),
        "capacity_halt_recovery_sent": sum(1 for r in results if (r.get("classification") or {}).get("capacity_halt_recovery", {}).get("sent") is True),
        "capacity_halt_recovery_recovered": sum(1 for r in results if (r.get("classification") or {}).get("capacity_halt_recovery", {}).get("recovered") is True),
        "notify_fallbacks_fired": sum(1 for r in results if r["action"] == "notify_fallback_fired"),
        "would_auto_respawns": sum(1 for r in results if r["action"] == "would_auto_respawn"),
        "would_auto_continues": sum(1 for r in results if r["action"] == "would_auto_continue"),
        "would_notify_fallbacks": sum(1 for r in results if r["action"] == "would_notify"),
        "probe_errors": sum(1 for r in results if r["action"] == "probe_error"),
        "actions": actions, "results": results,
    }
    payload["status"] = "probe_error" if payload["probe_errors"] else "notify_fallback_fired" if payload["notify_fallbacks_fired"] else "auto_respawn_fired" if payload["auto_respawns_fired"] else "auto_continue_fired" if payload["auto_continues_fired"] else "auto_continue_lease_held" if payload["auto_continue_lease_refusals"] else "auto_continue_authorization_refused" if payload["auto_continue_authorization_refusals"] else "auto_continue_budget_exhausted" if payload["auto_continue_budget_refusals"] else "dry_run_actions_planned" if payload["would_auto_respawns"] + payload["would_auto_continues"] + payload["would_notify_fallbacks"] else "no_action_needed"
    rc = 0
    if args.apply:
        rc = 3 if payload["probe_errors"] or payload["auto_continue_authorization_refusals"] else 2 if payload["notify_fallbacks_fired"] or payload["auto_continue_budget_refusals"] else 1 if payload["auto_respawns_fired"] or payload["auto_continues_fired"] else 0
    emit(payload, args, rc)

if __name__ == "__main__":
    main()
PY
