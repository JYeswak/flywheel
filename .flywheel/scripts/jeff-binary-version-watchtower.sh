#!/usr/bin/env bash
set -euo pipefail

python3 - "$@" <<'PY'
import argparse
import datetime as dt
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

VERSION = "jeff-binary-version-watchtower.v1"
DEFAULT_REPO_ROOT = Path("/Users/josh/Developer/flywheel")
DEFAULT_STATE_DIR = Path.home() / ".local/state/flywheel"

TOOLS = [
    {"name": "dcg", "repo": "destructive_command_guard", "commands": [["dcg", "--version"]], "manifest": "Cargo.toml"},
    {"name": "ntm", "repo": "ntm", "commands": [["ntm", "version"]], "manifest": ""},
    {"name": "br", "repo": "beads_rust", "commands": [["br", "--version"], ["br", "version"]], "manifest": "Cargo.toml"},
    {"name": "cm", "repo": "coding_agent_session_search", "commands": [["cm", "--version"]], "manifest": "Cargo.toml"},
    {"name": "mcp-agent-mail", "repo": "mcp_agent_mail", "commands": [["agent-mail", "--version"], ["agent-mail", "version"]], "manifest": "pyproject.toml"},
    {"name": "frankensqlite", "repo": "frankensqlite", "commands": [["fsqlite", "--version"]], "manifest": "crates/fsqlite/Cargo.toml"},
    {"name": "jsm", "repo": "meta_skill", "commands": [["jsm", "--version"]], "manifest": "Cargo.toml"},
]


def iso_now():
    return dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def parse_ts(value):
    if not value:
        return None
    try:
        return dt.datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None


def run_cmd(args, cwd=None, timeout=8):
    try:
        proc = subprocess.run(args, cwd=cwd, text=True, capture_output=True, timeout=timeout)
        return proc.returncode, (proc.stdout + proc.stderr).strip()
    except Exception as exc:
        return 127, str(exc)


def version_tuple(value):
    if not value:
        return ()
    match = re.search(r"v?(\d+(?:\.\d+){0,3})", value)
    if not match:
        return ()
    return tuple(int(part) for part in match.group(1).split("."))


def normalize_version(value):
    if not value:
        return None
    match = re.search(r"v?(\d+(?:\.\d+){0,3}(?:[-+][A-Za-z0-9._-]+)?)", value)
    if not match:
        return value.strip().splitlines()[0][:80] if value.strip() else None
    return match.group(1)


def relation(current, latest):
    c = version_tuple(current)
    l = version_tuple(latest)
    if not c or not l:
        return "unknown"
    if c < l:
        return "behind"
    if c > l:
        return "ahead"
    return "current"


def priority_for(published_at):
    published = parse_ts(published_at)
    if not published:
        return "P1"
    age_hours = (dt.datetime.now(dt.timezone.utc) - published.astimezone(dt.timezone.utc)).total_seconds() / 3600
    if age_hours >= 24:
        return "P0"
    if age_hours >= 1:
        return "P1"
    return "P2"


def command_path(command):
    path = shutil.which(command)
    return path or ""


def installed_from_command(tool):
    for args in tool["commands"]:
        if not command_path(args[0]):
            continue
        code, output = run_cmd(args)
        version = normalize_version(output)
        if code == 0 and version:
            return version, output.splitlines()[0][:160], command_path(args[0])
    return None, "", command_path(tool["commands"][0][0])


def manifest_version(repo_path, manifest):
    if not manifest:
        return None
    path = repo_path / manifest
    if not path.exists():
        return None
    text = path.read_text(errors="replace")
    if path.name in {"Cargo.toml", "pyproject.toml"}:
        match = re.search(r'(?m)^version\s*=\s*"([^"]+)"', text)
        return match.group(1) if match else None
    if path.name == "package.json":
        try:
            return json.loads(text).get("version")
        except Exception:
            return None
    return None


def latest_from_fixture(fixture, tool):
    row = fixture.get(tool["name"]) or fixture.get(tool["repo"]) or {}
    if not row:
        return None
    return {
        "latest_version": normalize_version(str(row.get("latest_version") or row.get("tag") or "")),
        "latest_tag": str(row.get("latest_tag") or row.get("tag") or row.get("latest_version") or ""),
        "published_at": row.get("published_at"),
        "source": "fixture",
    }


def fetch_tags(repo_path, no_fetch):
    if repo_path.is_dir() and (repo_path / ".git").exists() and not no_fetch:
        run_cmd(["git", "fetch", "--tags", "--quiet", "--prune"], cwd=repo_path, timeout=30)


def latest_from_git(repo_path):
    if not ((repo_path / ".git").exists()):
        return None
    code, output = run_cmd(
        ["git", "for-each-ref", "--format=%(refname:short)|%(creatordate:iso-strict)", "refs/tags"],
        cwd=repo_path,
        timeout=10,
    )
    if code != 0:
        return None
    candidates = []
    for line in output.splitlines():
        tag, _, created = line.partition("|")
        parsed = version_tuple(tag)
        if parsed:
            candidates.append((parsed, tag, created))
    if not candidates:
        return None
    _parsed, tag, created = sorted(candidates, key=lambda item: item[0])[-1]
    return {
        "latest_version": normalize_version(tag),
        "latest_tag": tag,
        "published_at": created or None,
        "source": "git_tags",
    }


def existing_open_bead(repo_root, title, br_bin):
    code, output = run_cmd([br_bin, "list", "--json"], cwd=repo_root, timeout=10)
    if code != 0:
        return ""
    try:
        data = json.loads(output)
    except Exception:
        return ""
    rows = data if isinstance(data, list) else data.get("issues", [])
    for row in rows:
        if row.get("status") != "closed" and row.get("title") == title:
            return row.get("id", "")
    return ""


def create_bead(repo_root, row, br_bin, dry_run):
    title = f"[jeff-substrate-version-drift] {row['name']} installed {row['installed_version'] or 'unknown'} latest {row['latest_version'] or 'unknown'}"
    existing = existing_open_bead(repo_root, title, br_bin)
    if existing:
        return {"action": "skipped", "reason": "existing_bead", "bead_id": existing, "title": title}
    priority = priority_for(row.get("published_at"))
    description = (
        "Auto-filed by jeff-binary-version-watchtower.sh.\n\n"
        f"Tool: {row['name']}\n"
        f"Repo: Dicklesworthstone/{row['repo']}\n"
        f"Installed: {row.get('installed_version') or 'unknown'} at {row.get('binary_path') or 'missing'}\n"
        f"Latest: {row.get('latest_version') or 'unknown'} ({row.get('latest_tag') or 'unknown'}) published_at={row.get('published_at') or 'unknown'}\n"
        f"Relation: {row.get('relation')}\n\n"
        "Acceptance gates:\n"
        "- Upgrade or intentionally pin this substrate version with a receipt.\n"
        "- Re-run .flywheel/scripts/jeff-binary-version-watchtower.sh --json and verify this tool no longer reports relation=behind.\n"
        "- Record installed version evidence and any behavior-breaking follow-up bead.\n"
    )
    if dry_run:
        return {"action": "planned", "priority": priority, "title": title}
    code, output = run_cmd(
        [br_bin, "create", title, "--type", "bug", "--priority", priority, "--description", description, "--json"],
        cwd=repo_root,
        timeout=15,
    )
    if code != 0:
        return {"action": "error", "reason": "br_create_failed", "priority": priority, "title": title, "raw": output[:400]}
    try:
        data = json.loads(output)
        bead_id = data.get("id") or data.get("issue", {}).get("id")
    except Exception:
        bead_id = ""
    return {"action": "created", "priority": priority, "title": title, "bead_id": bead_id}


def evaluate(args):
    repo_root = Path(args.repo_root)
    developer_root = Path(args.developer_root)
    state_dir = Path(args.state_dir)
    fixture = {}
    if args.fixture:
        fixture = json.loads(Path(args.fixture).read_text())
    rows = []
    warnings = []
    for tool in TOOLS:
        repo_path = developer_root / tool["repo"]
        latest = latest_from_fixture(fixture, tool)
        if not latest:
            fetch_tags(repo_path, args.no_fetch)
            latest = latest_from_git(repo_path)
        if not latest:
            manifest_latest = manifest_version(repo_path, tool["manifest"])
            if manifest_latest:
                latest = {"latest_version": manifest_latest, "latest_tag": f"manifest:{manifest_latest}", "published_at": None, "source": "repo_manifest"}
                warnings.append(f"latest_from_manifest_no_tags:{tool['name']}")
            else:
                latest = {"latest_version": None, "latest_tag": None, "published_at": None, "source": "unavailable"}
                warnings.append(f"latest_unavailable:{tool['name']}")
        installed, raw, binary_path = installed_from_command(tool)
        if not installed:
            installed = manifest_version(repo_path, tool["manifest"])
            raw = "manifest_fallback" if installed else "missing"
        rel = relation(installed, latest.get("latest_version"))
        status = "ok" if rel in {"current", "ahead"} else ("stale" if rel == "behind" else "unknown")
        rows.append({
            "name": tool["name"],
            "repo": tool["repo"],
            "repo_path": str(repo_path),
            "binary_path": binary_path,
            "installed_version": installed,
            "installed_raw": raw,
            "latest_version": latest.get("latest_version"),
            "latest_tag": latest.get("latest_tag"),
            "published_at": latest.get("published_at"),
            "latest_source": latest.get("source"),
            "relation": rel,
            "status": status,
        })
    stale = [r for r in rows if r["relation"] == "behind"]
    promotions = []
    if args.apply or args.dry_run:
        for row in stale:
            promotions.append(create_bead(repo_root, row, args.br_bin, args.dry_run or not args.apply))
    result = {
        "schema_version": VERSION,
        "checked_at": args.now or iso_now(),
        "status": "fail" if stale else ("warn" if any(r["status"] == "unknown" for r in rows) else "pass"),
        "cadence": "hourly",
        "canonical_binary_count": len(TOOLS),
        "stale_count": len(stale),
        "unknown_count": sum(1 for r in rows if r["status"] == "unknown"),
        "highest_priority": (sorted([priority_for(r.get("published_at")) for r in stale]) or [None])[0],
        "rows": rows,
        "stale": stale,
        "promotions": promotions,
        "warnings": warnings,
        "state_dir": str(state_dir),
    }
    if args.apply and not args.dry_run:
        state_dir.mkdir(parents=True, exist_ok=True)
        ledger = state_dir / "jeff-binary-version-watchtower.jsonl"
        with ledger.open("a") as fh:
            fh.write(json.dumps(result, separators=(",", ":")) + "\n")
        result["ledger"] = str(ledger)
    return result


def main():
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("command", nargs="?", default="run")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--fixture", default=os.environ.get("JEFF_BINARY_WATCHTOWER_FIXTURE"))
    parser.add_argument("--state-dir", default=os.environ.get("JEFF_BINARY_WATCHTOWER_STATE_DIR", str(DEFAULT_STATE_DIR)))
    parser.add_argument("--repo-root", default=os.environ.get("JEFF_BINARY_WATCHTOWER_REPO_ROOT", str(DEFAULT_REPO_ROOT)))
    parser.add_argument("--developer-root", default=os.environ.get("JEFF_BINARY_WATCHTOWER_DEVELOPER_ROOT", str(Path.home() / "Developer")))
    parser.add_argument("--br-bin", default=os.environ.get("BR_BIN", "br"))
    parser.add_argument("--now")
    parser.add_argument("--no-fetch", action="store_true", default=os.environ.get("JEFF_BINARY_WATCHTOWER_NO_FETCH", "0") in {"1", "true", "TRUE", "yes"})
    parser.add_argument("--help", "-h", action="store_true")
    args = parser.parse_args()

    if args.help or args.command == "help":
        print("Usage: jeff-binary-version-watchtower.sh [doctor|health|run] [--json] [--dry-run|--apply] [--fixture PATH] [--no-fetch]")
        print("       jeff-binary-version-watchtower.sh --info|--examples|completion")
        return 0
    if args.command == "--info":
        print(json.dumps({"command": "jeff-binary-version-watchtower", "version": VERSION, "canonical_binaries": [t["name"] for t in TOOLS], "mutates": ["optional br beads with --apply", "ledger append with --apply"]}))
        return 0
    if args.command == "--examples":
        print(".flywheel/scripts/jeff-binary-version-watchtower.sh --dry-run --json")
        print(".flywheel/scripts/jeff-binary-version-watchtower.sh --apply --json")
        return 0
    if args.command == "completion":
        print('complete -W "doctor health run --json --dry-run --apply --fixture --info --examples completion --help" jeff-binary-version-watchtower.sh')
        return 0
    if args.command in {"doctor", "health"} and not args.apply:
        args.dry_run = True
    result = evaluate(args)
    if args.json or args.command in {"doctor", "health", "run"}:
        print(json.dumps(result, separators=(",", ":")))
    else:
        print(f"jeff-binary-version-watchtower status={result['status']} stale={result['stale_count']}")
    return 1 if result["status"] == "fail" and args.command in {"doctor", "health"} else 0


if __name__ == "__main__":
    raise SystemExit(main())
PY
