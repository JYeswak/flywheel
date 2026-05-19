#!/usr/bin/env bash
set -euo pipefail

VERSION="capacity-halt-success-measurement.v1.0.0"
NTM_BIN="${CAPACITY_HALT_SUCCESS_NTM_BIN:-/Users/josh/.local/bin/ntm}"
DELAYS="${CAPACITY_HALT_SUCCESS_DELAYS:-3,6,10}"

python3 - "$VERSION" "$NTM_BIN" "$DELAYS" "$@" <<'PY'
import argparse, hashlib, json, re, subprocess, sys, tempfile, time
from pathlib import Path

VERSION, NTM_BIN, DELAYS_RAW = sys.argv[1:4]
SHA_RE = re.compile(r"^[0-9a-f]{64}$")
PANE_RE = re.compile(r"^[0-9]+$")
CAPACITY_RE = re.compile(r"selected model is at capacity", re.I)

def parse_args():
    p = argparse.ArgumentParser(description="Read-only capacity-halt post-send success measurement.")
    p.add_argument("--info", action="store_true")
    p.add_argument("--examples", action="store_true")
    p.add_argument("--json", action="store_true")
    p.add_argument("--session", default="")
    p.add_argument("--pane", default="")
    p.add_argument("--pre-digest", default="")
    p.add_argument("--quiet", action="store_true")
    p.add_argument("--ntm-bin", default=NTM_BIN)
    p.add_argument("--sample-delays", default=DELAYS_RAW)
    return p.parse_args(sys.argv[4:])

def emit(args, payload, rc):
    if args.json:
        print(json.dumps(payload, sort_keys=True))
    elif not args.quiet:
        print(f"capacity-halt-success-measurement status={payload.get('status')} verdict={payload.get('verdict')} session={payload.get('session', '')} pane={payload.get('pane', '')}")
    raise SystemExit(rc)

def delays(raw):
    try:
        out = [max(0.0, float(x)) for x in raw.split(",") if x.strip() != ""]
    except ValueError:
        return None
    return out if len(out) == 3 else None

def last30(text):
    return "\n".join(text.splitlines()[-30:])

def digest_text(text):
    return hashlib.sha256(last30(text).encode()).hexdigest()

def parse_tail(payload, pane):
    if isinstance(payload.get("panes"), dict):
        pane_payload = payload["panes"].get(str(pane)) or {}
        return "\n".join(pane_payload.get("lines") or []) or str(pane_payload.get("text") or "")
    if isinstance(payload.get("panes"), list):
        for item in payload["panes"]:
            if str(item.get("pane") or item.get("pane_idx")) == str(pane):
                return "\n".join(item.get("lines") or []) or str(item.get("text") or "")
    return ""

def copy_text(args, tmp, idx):
    out = Path(tmp) / f"sample-{idx}.txt"
    proc = subprocess.run([args.ntm_bin, "copy", f"{args.session}:{args.pane}", "-l", "120", "--output", str(out), "--quiet"], text=True, capture_output=True)
    if proc.returncode == 0 and out.exists():
        return out.read_text(errors="replace")
    fallback = subprocess.run([args.ntm_bin, f"--robot-tail={args.session}", f"--panes={args.pane}", "--lines=120"], text=True, capture_output=True)
    if fallback.returncode != 0:
        raise RuntimeError((fallback.stderr or proc.stderr or "tail probe failed")[-300:])
    try:
        return parse_tail(json.loads(fallback.stdout), args.pane)
    except Exception as exc:
        raise RuntimeError(f"tail parse failed: {exc}")

def activity(args):
    proc = subprocess.run([args.ntm_bin, f"--robot-activity={args.session}"], text=True, capture_output=True)
    if proc.returncode != 0:
        return {"ok": False, "error": proc.stderr[-300:]}
    try:
        payload = json.loads(proc.stdout)
    except Exception as exc:
        return {"ok": False, "error": f"activity parse failed: {exc}"}
    states, velocities = [], []
    for item in payload.get("agents") or payload.get("panes") or []:
        if str(item.get("pane_idx") or item.get("pane") or "") != str(args.pane):
            continue
        states.append(str(item.get("state") or item.get("activity") or "").upper())
        for key in ("velocity", "chars_per_second", "bytes_per_second"):
            try:
                velocities.append(float(item.get(key) or 0))
            except (TypeError, ValueError):
                pass
    return {"ok": True, "states": states, "velocity_positive": any(v > 0 for v in velocities), "raw": payload}

def info(args):
    emit(args, {
        "schema_version": "capacity-halt-success-measurement.info.v1",
        "name": "capacity-halt-success-measurement",
        "version": VERSION,
        "ntm_bin": args.ntm_bin,
        "default_sample_delays": DELAYS_RAW,
        "read_only": True,
        "verbs": ["--info", "--help", "--examples", "--json", "--session", "--pane", "--pre-digest", "--quiet"],
        "exit_codes": {"0": "success", "1": "failure", "2": "inconclusive", "3": "malformed", "4": "probe-error"},
    }, 0)

def examples(args):
    emit(args, {"schema_version": "capacity-halt-success-measurement.examples.v1", "examples": [
        {"name": "measure", "command": "capacity-halt-success-measurement.sh --session flywheel --pane 3 --pre-digest <sha256> --json"},
        {"name": "quiet", "command": "capacity-halt-success-measurement.sh --session flywheel --pane 3 --pre-digest <sha256> --quiet"},
    ]}, 0)

def main():
    args = parse_args()
    if args.info:
        info(args)
    if args.examples:
        examples(args)
    ds = delays(args.sample_delays)
    if not args.session or not PANE_RE.match(args.pane) or not SHA_RE.match(args.pre_digest) or ds is None:
        emit(args, {"schema_version": "capacity-halt-success-measurement.result.v1", "status": "malformed", "verdict": "inconclusive", "session": args.session, "pane": args.pane, "reason": "session_numeric_pane_pre_digest_three_delays_required"}, 3)
    samples, activities = [], [activity(args)]
    with tempfile.TemporaryDirectory(prefix="capacity-halt-success.") as tmp:
        prev = 0.0
        for idx, target in enumerate(ds, 1):
            time.sleep(max(0.0, target - prev))
            prev = target
            try:
                text = copy_text(args, tmp, idx)
            except Exception as exc:
                emit(args, {"schema_version": "capacity-halt-success-measurement.result.v1", "status": "inconclusive", "verdict": "inconclusive", "session": args.session, "pane": args.pane, "reason": "probe_error", "error": str(exc), "samples": samples}, 4)
            samples.append({"idx": idx, "delay_seconds": target, "digest": digest_text(text), "capacity_text_present": bool(CAPACITY_RE.search(last30(text)))})
            activities.append(activity(args))
    final = samples[-1]
    output_delta = final["digest"] != args.pre_digest
    text_gone = not final["capacity_text_present"]
    states = [s for a in activities if a.get("ok") for s in a.get("states", [])]
    activity_transition = "WAITING" in states and "THINKING" in states
    velocity_positive = any(a.get("velocity_positive") for a in activities if a.get("ok"))
    success = output_delta or text_gone or activity_transition or velocity_positive
    payload = {
        "schema_version": "capacity-halt-success-measurement.result.v1",
        "status": "success" if success else "failure",
        "verdict": "success" if success else "failure",
        "session": args.session,
        "pane": args.pane,
        "pre_digest": args.pre_digest,
        "samples": samples,
        "criteria": {"output_delta": output_delta, "capacity_text_gone": text_gone, "activity_transition": activity_transition, "velocity_positive": velocity_positive},
        "read_only": True,
    }
    emit(args, payload, 0 if success else 1)

if __name__ == "__main__":
    main()
PY

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-60-measured-performance-budget-loop.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-87-binding-constraint-capacity-score.md`
