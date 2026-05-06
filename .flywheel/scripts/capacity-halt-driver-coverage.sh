#!/usr/bin/env bash
set -euo pipefail

VERSION="capacity-halt-driver-coverage/v1"
LAUNCH_AGENTS_DIR="${CAPACITY_HALT_DRIVER_LAUNCH_AGENTS_DIR:-$HOME/Library/LaunchAgents}"
JSON_OUT=0; QUIET=0; MODE="probe"

usage() {
  cat <<'USAGE'
usage: capacity-halt-driver-coverage.sh [--json] [--quiet] [--launch-agents-dir PATH]
       capacity-halt-driver-coverage.sh --info|--examples|--schema|--help
Read ai.zeststream LaunchAgent plists and classify capacity-halt driver coverage.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_OUT=1; shift ;;
    --quiet) QUIET=1; shift ;;
    --info) MODE="info"; shift ;;
    --examples) MODE="examples"; shift ;;
    --schema) MODE="schema"; shift ;;
    --launch-agents-dir) LAUNCH_AGENTS_DIR="${2:?--launch-agents-dir requires PATH}"; shift 2 ;;
    --launch-agents-dir=*) LAUNCH_AGENTS_DIR="${1#*=}"; shift ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'ERR unknown argument: %s\n' "$1" >&2; usage >&2; exit 64 ;;
  esac
done

case "$MODE" in
  info)
    jq -nc --arg version "$VERSION" --arg dir "$LAUNCH_AGENTS_DIR" '{schema_version:"capacity-halt-driver-coverage.info/v1",name:"capacity-halt-driver-coverage",version:$version,launch_agents_dir:$dir,canonical_cli_flags:["--help","--info","--examples","--schema","--json","--quiet","--launch-agents-dir"],categories:["drives_capacity_halt","drives_queued_not_submitted","monitors_only","unrelated"]}'
    exit 0 ;;
  examples)
    jq -nc '{schema_version:"capacity-halt-driver-coverage.examples/v1",examples:["capacity-halt-driver-coverage.sh --json","capacity-halt-driver-coverage.sh --launch-agents-dir /tmp/LaunchAgents --json","capacity-halt-driver-coverage.sh --quiet"]}'
    exit 0 ;;
  schema)
    jq -nc '{"$schema":"http://json-schema.org/draft-07/schema#","type":"object","required":["schema_version","success","plists_audited_count","classification_counts","plists"],"properties":{"schema_version":{"const":"capacity-halt-driver-coverage/v1"},"success":{"type":"boolean"},"plists_audited_count":{"type":"integer"},"classification_counts":{"type":"object"},"plists":{"type":"array"}}}'
    exit 0 ;;
esac

python3 - "$VERSION" "$LAUNCH_AGENTS_DIR" "$JSON_OUT" "$QUIET" <<'PY'
import datetime as dt, glob, json, os, plistlib, re, sys
from pathlib import Path

version, dir_raw, json_raw, quiet_raw = sys.argv[1:]
root = Path(dir_raw).expanduser()
json_out, quiet = json_raw == "1", quiet_raw == "1"

def iso_mtime(path):
    try:
        return dt.datetime.fromtimestamp(Path(path).stat().st_mtime, dt.timezone.utc).replace(microsecond=0).isoformat().replace("+00:00","Z")
    except Exception:
        return None

def latest_json_ts(path):
    if not path:
        return None, "none"
    p = Path(str(path)).expanduser()
    if not p.exists():
        return None, "missing_log"
    latest = None
    try:
        lines = p.read_text(errors="replace").splitlines()[-200:]
    except Exception:
        return iso_mtime(p), "log_mtime"
    for line in lines:
        try:
            row = json.loads(line)
        except Exception:
            continue
        ts = row.get("ts") if isinstance(row, dict) else None
        if isinstance(ts, str) and (latest is None or ts > latest):
            latest = ts
    return (latest, "json_log") if latest else (iso_mtime(p), "log_mtime")

def session_for(label, text):
    m = re.search(r"--session[ =]([A-Za-z0-9._-]+)", text) or re.search(r'select\(\.session=="([^"]+)"\)', text)
    if m:
        return m.group(1)
    for prefix in ("mobile-eats","skillos","flywheel","vrtx","alps"):
        if f"{prefix}-codex-stuck-detector" in label:
            return "alpsinsurance" if prefix == "alps" else prefix
    return "all" if "--session all" in text or "worker-auto-respawn-watchdog.sh" in text else None

def classify(text):
    caps, chain = [], []
    if "worker-auto-respawn-watchdog.sh" in text:
        caps.append("drives_capacity_halt"); chain += ["worker-auto-respawn-watchdog.sh","capacity-halt-auto-continue-primitive.sh"]
    if "capacity-halt-auto-continue-primitive.sh" in text:
        caps.append("drives_capacity_halt"); chain.append("capacity-halt-auto-continue-primitive.sh")
    if "codex-queued-not-submitted-bare-enter-primitive.sh" in text:
        caps.append("drives_queued_not_submitted"); chain.append("codex-queued-not-submitted-bare-enter-primitive.sh")
    if "codex-template-stuck-detector.sh" in text and "--auto-recover" in text:
        caps += ["drives_capacity_halt","drives_queued_not_submitted"]
        chain += ["codex-template-stuck-detector.sh","capacity-halt-auto-continue-primitive.sh","codex-queued-not-submitted-bare-enter-primitive.sh"]
    caps = list(dict.fromkeys(caps)); chain = list(dict.fromkeys(chain))
    if "drives_capacity_halt" in caps:
        cat = "drives_capacity_halt"
    elif "drives_queued_not_submitted" in caps:
        cat = "drives_queued_not_submitted"
    elif re.search(r"(codex-template-stuck-detector|frozen-pane-detector|idle-pane-auto-dispatch|ntm-fleet-health|continuous-productivity|flywheel-loop)", text):
        cat = "monitors_only"
    else:
        cat = "unrelated"
    return cat, caps, chain

rows = []
for path in sorted(glob.glob(str(root / "ai.zeststream.*.plist"))):
    try:
        with open(path, "rb") as fh:
            data = plistlib.load(fh)
        args = data.get("ProgramArguments") or []
        label = data.get("Label") or Path(path).stem
        text = " ".join(str(x) for x in args)
        category, caps, chain = classify(text)
        last_ts, last_src = latest_json_ts(data.get("StandardOutPath"))
        rows.append({
            "label": label, "path": path, "category": category, "capabilities": caps,
            "invocation_chain": chain, "target_session": session_for(label, text),
            "last_fire_ts": last_ts, "last_fire_source": last_src,
            "program_arguments": args, "start_interval": data.get("StartInterval"),
            "stdout_path": data.get("StandardOutPath"), "stderr_path": data.get("StandardErrorPath"),
        })
    except Exception as exc:
        rows.append({"label": Path(path).stem, "path": path, "category": "unrelated", "capabilities": [], "invocation_chain": [], "parse_error": str(exc), "program_arguments": []})

counts = {k: 0 for k in ["drives_capacity_halt","drives_queued_not_submitted","monitors_only","unrelated"]}
cap_counts = {"drives_capacity_halt": 0, "drives_queued_not_submitted": 0}
for row in rows:
    counts[row["category"]] = counts.get(row["category"], 0) + 1
    for cap in cap_counts:
        cap_counts[cap] += 1 if cap in row.get("capabilities", []) else 0
payload = {
    "schema_version": version, "success": True, "launch_agents_dir": str(root),
    "plists_audited_count": len(rows), "classification_counts": counts,
    "capability_counts": cap_counts, "plists": rows,
    "capacity_halt_driver_sessions": sorted({r.get("target_session") for r in rows if "drives_capacity_halt" in r.get("capabilities", []) and r.get("target_session")}),
    "queued_not_submitted_driver_sessions": sorted({r.get("target_session") for r in rows if "drives_queued_not_submitted" in r.get("capabilities", []) and r.get("target_session")}),
}
if json_out:
    print(json.dumps(payload, sort_keys=True, separators=(",", ":")))
elif not quiet:
    print(f"capacity-halt-driver-coverage plists={len(rows)} capacity={cap_counts['drives_capacity_halt']} queued={cap_counts['drives_queued_not_submitted']} monitors={counts['monitors_only']} unrelated={counts['unrelated']}")
PY
