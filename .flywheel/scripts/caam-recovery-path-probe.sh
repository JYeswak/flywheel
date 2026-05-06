#!/usr/bin/env bash
set -euo pipefail

usage(){ printf '%s\n' \
"usage: caam-recovery-path-probe.sh [--json|--quiet]" \
"       caam-recovery-path-probe.sh --info [--json]" \
"       caam-recovery-path-probe.sh --examples [--json]" \
"       caam-recovery-path-probe.sh --help"; }
info(){ jq -nc '{name:"caam-recovery-path-probe.sh",schema:"caam.recovery_path_probe.v1",verbs:["--info","--help","--examples","--json","--quiet"],read_only:true}'; }
examples(){ jq -nc '{examples:["caam-recovery-path-probe.sh --json","CAAM_PROBE_LOG_DIRS=/tmp/caam-logs caam-recovery-path-probe.sh --json","CAAM_PROBE_LAUNCH_AGENTS_DIR=/tmp/empty CAAM_PROBE_LAUNCHCTL_LIST=/tmp/empty-list caam-recovery-path-probe.sh --json"]}'; }

json=0; quiet=0; mode=run
while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h) usage; exit 0 ;;
    --info) mode=info; shift ;;
    --examples) mode=examples; shift ;;
    --json) json=1; shift ;;
    --quiet) quiet=1; shift ;;
    *) printf 'unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ "$mode" == info ]]; then
  [[ "$json" -eq 1 ]] && info || info | jq -r '"name=\(.name)\nschema=\(.schema)\nverbs=\(.verbs|join(","))\nread_only=\(.read_only)"'
  exit 0
fi
if [[ "$mode" == examples ]]; then
  [[ "$json" -eq 1 ]] && examples || examples | jq -r '.examples[]'
  exit 0
fi

probe_json="$(
python3 - <<'PY'
import json, os, pathlib, re, subprocess
from datetime import datetime, timedelta, timezone

home = pathlib.Path(os.environ.get("HOME", "~")).expanduser()
expected = ["com.caam.daemon", "com.caam.auth-agent", "com.caam.auth-coordinator"]

def read_text(path):
    try:
        return pathlib.Path(path).expanduser().read_text(errors="replace")
    except Exception:
        return ""

def run_text(cmd):
    try:
        return subprocess.run(cmd, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=5).stdout
    except Exception:
        return ""

def parse_now():
    raw = os.environ.get("CAAM_PROBE_NOW")
    if raw:
        return datetime.fromisoformat(raw.replace("Z", "+00:00"))
    return datetime.now().astimezone()

def parse_line_ts(line):
    m = re.search(r"time=([0-9T:.\-+Z]+)", line)
    if m:
        try:
            return datetime.fromisoformat(m.group(1).replace("Z", "+00:00"))
        except Exception:
            pass
    m = re.search(r"\[(?:caam-[^]]+)\]\s+(\d{4})/(\d{2})/(\d{2})\s+(\d{2}):(\d{2}):(\d{2})", line)
    if m:
        y, mo, d, h, mi, s = map(int, m.groups())
        return datetime(y, mo, d, h, mi, s).astimezone()
    return None

la_dir = pathlib.Path(os.environ.get("CAAM_PROBE_LAUNCH_AGENTS_DIR", home / "Library/LaunchAgents")).expanduser()
plist_paths = {label: la_dir / f"{label}.plist" for label in expected}
plist_existing = [str(path) for path in plist_paths.values() if path.exists()]

if os.environ.get("CAAM_PROBE_LAUNCHCTL_LIST"):
    launch_text = read_text(os.environ["CAAM_PROBE_LAUNCHCTL_LIST"])
    launch_src = os.environ["CAAM_PROBE_LAUNCHCTL_LIST"]
else:
    launch_text = run_text(["launchctl", "list"])
    launch_src = "launchctl list"
loaded = [label for label in expected if label in launch_text and plist_paths[label].exists()]

profiles = []
profile_src = None
profile_raw = ""
if os.environ.get("CAAM_PROBE_CAAM_LS_JSON"):
    profile_src = os.environ["CAAM_PROBE_CAAM_LS_JSON"]
    profile_raw = read_text(profile_src)
else:
    profile_src = "caam ls claude --json"
    profile_raw = run_text(["caam", "ls", "claude", "--json"]) or run_text(["caam", "list", "claude", "--json"])
try:
    parsed = json.loads(profile_raw) if profile_raw.strip() else {}
    profiles = parsed.get("profiles", []) if isinstance(parsed, dict) else []
except Exception:
    profiles = []
total = len(profiles)
expired = 0
ok = 0
for p in profiles:
    status = str(((p.get("health") or {}).get("status") or p.get("status") or "")).lower()
    if status in {"critical", "expired"}:
        expired += 1
    if status in {"ok", "healthy"}:
        ok += 1

log_path = None
if os.environ.get("CAAM_PROBE_ROTATION_LOG"):
    p = pathlib.Path(os.environ["CAAM_PROBE_ROTATION_LOG"]).expanduser()
    log_path = p if p.exists() else None
else:
    dirs_raw = os.environ.get("CAAM_PROBE_LOG_DIRS")
    dirs = [pathlib.Path(x).expanduser() for x in dirs_raw.split(":")] if dirs_raw else [
        home / ".local/state/caam", home / ".local/share/caam", home / "Library/Logs/caam"
    ]
    candidates = []
    for d in dirs:
        if d.exists():
            candidates.extend([p for p in d.rglob("*.log") if p.is_file()])
    candidates.sort(key=lambda p: (("coordinator" in p.name.lower()) or ("rotation" in p.name.lower()), p.stat().st_mtime), reverse=True)
    log_path = candidates[0] if candidates else None

now = parse_now()
cutoff = now - timedelta(hours=24)
lines_24h = []
if log_path:
    for line in read_text(log_path).splitlines():
        ts = parse_line_ts(line)
        if ts and ts >= cutoff:
            lines_24h.append(line)

def count(pred):
    return sum(1 for line in lines_24h if pred(line.lower()))

det429 = count(lambda s: ("429" in s or "rate limit" in s or "hit your limit" in s) and ("anthropic" in s or "claude" in s or "limit" in s))
rot_events = count(lambda s: "rotat" in s or "auto-switch" in s or "switching" in s or "activate" in s)
rot_success = count(lambda s: ("success" in s or "rotated" in s or "activated" in s or "switched" in s) and ("rotat" in s or "activat" in s or "switch" in s))
skillos_live = any(re.search(r"skillos-23fj|diagnostic helper|rotation test|auth detect|daemon trigger", line, re.I) for line in lines_24h)

if det429 > 0 and rot_events > 0 and rot_success > 0:
    score, verdict = 1.0, "rotation_path_healthy"
elif det429 > 0 and rot_events == 0:
    score, verdict = 0.0, "rotation_path_broken"
else:
    score, verdict = 0.5, "rotation_path_unverified"

evidence = [launch_src, profile_src] + plist_existing
if log_path:
    evidence.append(str(log_path))

print(json.dumps({
    "ts": now.astimezone(timezone.utc).isoformat().replace("+00:00", "Z"),
    "caam_plists_loaded": loaded,
    "caam_plists_loaded_count": len(loaded),
    "profiles_total": total,
    "profiles_expired": expired,
    "profiles_ok": ok,
    "rotation_log_path": str(log_path) if log_path else None,
    "rotation_events_last_24h": rot_events,
    "rotation_429_detections_last_24h": det429,
    "rotation_success_last_24h": rot_success,
    "auto_rotation_health_score": score,
    "verdict": verdict,
    "skillos_23fj_progress_inferred": bool(skillos_live),
    "evidence_paths": evidence,
}, sort_keys=True))
PY
)"

if [[ "$quiet" -eq 1 ]]; then
  jq -r '.verdict' <<<"$probe_json"
elif [[ "$json" -eq 1 ]]; then
  jq . <<<"$probe_json"
else
  jq -r '"verdict=\(.verdict)\nauto_rotation_health_score=\(.auto_rotation_health_score)\nprofiles_expired=\(.profiles_expired)/\(.profiles_total)\nrotation_429_detections_last_24h=\(.rotation_429_detections_last_24h)\nrotation_events_last_24h=\(.rotation_events_last_24h)"' <<<"$probe_json"
fi
