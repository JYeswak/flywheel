#!/usr/bin/env bash
set -euo pipefail

python3 - "$@" <<'PY'
import argparse
import datetime as dt
import hashlib
import json
import os
import re
import shutil
import subprocess
import tarfile
import tempfile
from pathlib import Path

SCHEMA = "flywheel-recovery-baseline/v1"
SOURCE_PLAN = ".flywheel/PLANS/recovery-system-2026-05-01/00-PLAN.md"
PROTECTED_SESSIONS = ["alpsinsurance", "picoz"]
SESSIONS = [
    "flywheel",
    "alpsinsurance",
    "clutterfreespaces",
    "picoz",
    "skillos",
    "vrtx",
    "zeststream-v2",
    "mobile-eats",
]
DEFAULT_REPOS = {
    "flywheel": "/Users/josh/Developer/flywheel",
    "alpsinsurance": "/Users/josh/Developer/alpsinsurance",
    "clutterfreespaces": "/Users/josh/Developer/clutterfreespaces",
    "picoz": "/Users/josh/Developer/polymarket-pico-z",
    "skillos": "/Users/josh/Developer/skillos",
    "vrtx": "/Users/josh/Developer/vrtx",
    "zeststream-v2": "/Users/josh/Developer/zeststream-v2",
    "mobile-eats": "/Users/josh/Developer/mobile-eats",
}


def utc_now():
    override = os.environ.get("FLYWHEEL_RECOVERY_NOW", "")
    if override:
        return override
    return dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def slug_ts(ts):
    return re.sub(r"[^0-9A-Za-z._-]", "", ts.replace(":", "").replace("-", ""))


def ep(path):
    return Path(path).expanduser()


def sha256_file(path):
    p = ep(path)
    if not p.exists() or not p.is_file():
        return None
    h = hashlib.sha256()
    with p.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def copy_file(src, dst):
    srcp = ep(src)
    if not srcp.exists() or not srcp.is_file():
        return None
    dstp = Path(dst)
    dstp.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(srcp, dstp)
    return {
        "source": str(srcp),
        "archive_path": str(dstp),
        "sha256": sha256_file(srcp),
        "bytes": srcp.stat().st_size,
    }


def read_jsonl_latest_by_session(path):
    latest = {}
    p = ep(path)
    if not p.exists():
        return latest
    for line in p.read_text(encoding="utf-8", errors="replace").splitlines():
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except json.JSONDecodeError:
            continue
        if not isinstance(row, dict) or not row.get("session"):
            continue
        session = str(row["session"])
        ts = str(row.get("effective_at") or row.get("ts") or row.get("updated_at") or "")
        old = latest.get(session)
        old_ts = str(old.get("effective_at") or old.get("ts") or old.get("updated_at") or "") if old else ""
        if old is None or ts >= old_ts:
            latest[session] = row
    return latest


def parse_session_paths(path):
    p = ep(path)
    if not p.exists():
        return {}
    values = {}
    in_table = False
    for line in p.read_text(encoding="utf-8", errors="replace").splitlines():
        stripped = line.strip()
        if stripped.startswith("[") and stripped.endswith("]"):
            in_table = stripped == "[session_paths]"
            continue
        if not in_table or "=" not in line:
            continue
        key, value = line.split("=", 1)
        key = key.strip().strip("'\"")
        value = value.split("#", 1)[0].strip().strip("'\"")
        if key and value:
            values[key] = value
    return values


def run_json(args):
    try:
        proc = subprocess.run(args, text=True, capture_output=True, timeout=8)
    except Exception as exc:
        return {"ok": False, "error": str(exc), "payload": None}
    if proc.returncode != 0:
        return {"ok": False, "rc": proc.returncode, "stderr": proc.stderr.strip(), "payload": None}
    try:
        return {"ok": True, "payload": json.loads(proc.stdout or "{}")}
    except json.JSONDecodeError as exc:
        return {"ok": False, "error": f"invalid_json:{exc}", "payload": None}


def token_inventory(paths):
    rows = []
    for base in paths:
        root = ep(base)
        if not root.exists():
            continue
        for path in sorted(root.glob("**/*")):
            if not path.is_file():
                continue
            st = path.stat()
            rows.append({
                "path": str(path),
                "fingerprint": sha256_file(path),
                "bytes": st.st_size,
                "mode": oct(st.st_mode & 0o777),
            })
    return rows


def repo_map(args):
    repos = dict(DEFAULT_REPOS)
    raw = os.environ.get("FLYWHEEL_RECOVERY_REPO_MAP_JSON", "")
    if raw:
        repos.update({str(k): str(v) for k, v in json.loads(raw).items()})
    config_paths = parse_session_paths(args.ntm_config)
    for session, path in config_paths.items():
        if session in repos:
            repos[session] = path
    return repos


def plist_path(args, session):
    return str(Path(args.launchagents_dir).expanduser() / f"com.zeststream.{session}.watcher.plist")


def add_session(stage, args, session, repos, topology, roster):
    safe = session.replace("/", "_")
    repo = ep(repos[session])
    session_dir = stage / "sessions" / safe
    session_dir.mkdir(parents=True, exist_ok=True)
    files = {}
    copied = copy_file(repo / ".beads/issues.jsonl", session_dir / ".beads/issues.jsonl")
    if copied:
        files["beads_issues"] = copied
    copied = copy_file(repo / ".flywheel/dispatch-log.jsonl", session_dir / ".flywheel/dispatch-log.jsonl")
    if copied:
        files["dispatch_log"] = copied
    state_docs = {}
    for name in ("MISSION.md", "GOAL.md", "STATE.md"):
        copied = copy_file(repo / ".flywheel" / name, session_dir / ".flywheel" / name)
        state_docs[name] = bool(copied)
        if copied:
            files[name] = copied
    plist = plist_path(args, session)
    copied = copy_file(plist, session_dir / "launchd" / Path(plist).name)
    if copied:
        files["watcher_plist"] = copied
    readiness = {
        "repo_exists": repo.is_dir(),
        "beads_issues_present": (repo / ".beads/issues.jsonl").is_file(),
        "dispatch_log_present": (repo / ".flywheel/dispatch-log.jsonl").is_file(),
        "state_docs_ready": all(state_docs.values()),
        "watcher_plist_present": ep(plist).is_file(),
    }
    return {
        "session": session,
        "repo_path": str(repo),
        "protected": session in PROTECTED_SESSIONS,
        "checkpoint_ready": all(readiness.values()),
        "readiness": readiness,
        "topology": topology.get(session),
        "team_roster": roster.get(session),
        "archive_root": f"sessions/{safe}",
        "files": files,
    }


def rotate_snapshots(snapshot_dir, current_manifest):
    manifests = sorted(Path(snapshot_dir).glob("baseline-*.manifest.json"), key=lambda p: p.stat().st_mtime, reverse=True)
    daily_keep = set(manifests[:14])
    weekly_keep = set()
    seen_weeks = set()
    for path in manifests[14:]:
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
            created = payload.get("created_at", "")
            day = dt.datetime.fromisoformat(created.replace("Z", "+00:00")).isocalendar()[:2]
        except Exception:
            day = ("unknown", path.name)
        if day not in seen_weeks and len(weekly_keep) < 8:
            weekly_keep.add(path)
            seen_weeks.add(day)
    keep = daily_keep | weekly_keep | {Path(current_manifest)}
    pruned = []
    for manifest in manifests:
        if manifest in keep:
            continue
        stem = manifest.name.replace(".manifest.json", "")
        tarball = manifest.with_name(f"{stem}.tar.gz")
        for candidate in (manifest, tarball):
            try:
                candidate.unlink()
                pruned.append(str(candidate))
            except FileNotFoundError:
                pass
    return pruned


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--trigger", default="manual", choices=["manual", "nightly", "pre-reboot", "post-reboot", "drill"])
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--snapshot-dir", default=os.environ.get("FLYWHEEL_RECOVERY_SNAPSHOT_DIR", "~/.flywheel/recovery/snapshots"))
    parser.add_argument("--state-dir", default=os.environ.get("FLYWHEEL_RECOVERY_STATE_DIR", "~/.local/state/flywheel"))
    parser.add_argument("--ntm-config", default=os.environ.get("FLYWHEEL_RECOVERY_NTM_CONFIG", "~/.config/ntm/config.toml"))
    parser.add_argument("--launchagents-dir", default=os.environ.get("FLYWHEEL_RECOVERY_LAUNCHAGENTS_DIR", "~/Library/LaunchAgents"))
    parser.add_argument("--agent-mail-token-dir", action="append", default=os.environ.get("FLYWHEEL_RECOVERY_AGENT_MAIL_TOKEN_DIRS", "~/.local/state/flywheel/agent-mail/tokens:~/.local/state/flywheel/agent-mail-tokens").split(":"))
    args = parser.parse_args()

    ts = utc_now()
    suffix = slug_ts(ts)
    snapshot_dir = ep(args.snapshot_dir)
    snapshot_dir.mkdir(parents=True, exist_ok=True)
    tarball = snapshot_dir / f"baseline-{suffix}.tar.gz"
    manifest = snapshot_dir / f"baseline-{suffix}.manifest.json"
    tmp_tarball = tarball.with_suffix(tarball.suffix + ".tmp")
    tmp_manifest = manifest.with_suffix(manifest.suffix + ".tmp")
    topology_path = Path(args.state_dir).expanduser() / "session-topology.jsonl"
    roster_path = Path(args.state_dir).expanduser() / "team-roster.jsonl"
    topology = read_jsonl_latest_by_session(topology_path)
    roster = read_jsonl_latest_by_session(roster_path)
    repos = repo_map(args)

    with tempfile.TemporaryDirectory(prefix="recovery-baseline-stage.") as tmp:
        stage = Path(tmp)
        global_dir = stage / "global"
        global_dir.mkdir(parents=True, exist_ok=True)
        globals_copied = {}
        for label, path in {
            "ntm_config": args.ntm_config,
            "session_topology": topology_path,
            "team_roster": roster_path,
        }.items():
            copied = copy_file(path, global_dir / f"{label}{Path(path).suffix or '.txt'}")
            if copied:
                globals_copied[label] = copied
        token_rows = token_inventory(args.agent_mail_token_dir)
        token_path = global_dir / "agent-mail-token-inventory.json"
        token_path.write_text(json.dumps(token_rows, sort_keys=True, indent=2) + "\n", encoding="utf-8")
        sessions = [add_session(stage, args, session, repos, topology, roster) for session in SESSIONS]
        payload = {
            "schema_version": SCHEMA,
            "created_at": ts,
            "trigger": args.trigger,
            "source_plan": SOURCE_PLAN,
            "source_plan_path": str((Path.cwd() / SOURCE_PLAN).resolve()),
            "excluded_sessions": [{"session": "zesttube", "reason": "B11.1 deferred low audit confidence; follow-up flywheel-4scjn"}],
            "protected_sessions_restore_blocked": PROTECTED_SESSIONS,
            "fleet": {
                "sessions_expected": len(SESSIONS),
                "sessions_recorded": len(sessions),
                "checkpoint_ready_count": sum(1 for s in sessions if s["checkpoint_ready"]),
                "protected_policy_version": "recovery-system-2026-05-01/B12",
            },
            "paths": {
                "tarball": str(tarball),
                "manifest": str(manifest),
                "snapshot_dir": str(snapshot_dir),
                "state_dir": str(ep(args.state_dir)),
            },
            "global_files": globals_copied,
            "agent_mail_tokens": token_rows,
            "sessions": sessions,
            "retention": {"daily_keep": 14, "weekly_keep": 8, "pruned": []},
        }
        (stage / "manifest.json").write_text(json.dumps(payload, sort_keys=True, indent=2) + "\n", encoding="utf-8")
        with tarfile.open(tmp_tarball, "w:gz") as tf:
            tf.add(stage, arcname=".")
        payload["paths"]["tarball_sha256"] = sha256_file(tmp_tarball)
        tmp_manifest.write_text(json.dumps(payload, sort_keys=True, indent=2) + "\n", encoding="utf-8")
    os.replace(tmp_tarball, tarball)
    os.replace(tmp_manifest, manifest)
    payload = json.loads(manifest.read_text(encoding="utf-8"))
    payload["retention"]["pruned"] = rotate_snapshots(snapshot_dir, manifest)
    tmp_manifest.write_text(json.dumps(payload, sort_keys=True, indent=2) + "\n", encoding="utf-8")
    os.replace(tmp_manifest, manifest)
    if args.json:
        print(json.dumps(payload, sort_keys=True, separators=(",", ":")))
    else:
        print(str(manifest))


if __name__ == "__main__":
    main()
PY
