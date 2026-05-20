#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage: stale-worktree-detector.sh [--repo PATH] [--age-threshold-days N]
  [--default-branch NAME] [--tier-mapping PATH] (--dry-run|--apply) [--json]
USAGE
}

repo=""
age_threshold_days=7
default_branch=""
tier_mapping="/Users/josh/Developer/zesttube/.flywheel/config/slb-tier-mapping.yaml"
mode=""
json=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      [[ $# -ge 2 ]] || { usage; exit 2; }
      repo=$2
      shift 2
      ;;
    --age-threshold-days)
      [[ $# -ge 2 ]] || { usage; exit 2; }
      age_threshold_days=$2
      shift 2
      ;;
    --default-branch)
      [[ $# -ge 2 ]] || { usage; exit 2; }
      default_branch=$2
      shift 2
      ;;
    --tier-mapping)
      [[ $# -ge 2 ]] || { usage; exit 2; }
      tier_mapping=$2
      shift 2
      ;;
    --dry-run|--apply)
      mode=${1#--}
      shift
      ;;
    --json)
      json=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage
      exit 2
      ;;
  esac
done

if [[ -z $mode ]]; then
  usage
  exit 2
fi

if ! [[ $age_threshold_days =~ ^[0-9]+$ ]]; then
  printf 'age threshold must be a non-negative integer\n' >&2
  exit 2
fi

if [[ -z $repo ]]; then
  repo=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
fi

repo=$(cd "$repo" && pwd -P)
audit_log="${STALE_WORKTREE_DETECTOR_AUDIT_LOG:-$HOME/.local/state/flywheel/stale-worktree-detector.jsonl}"
peer_queue="${STALE_WORKTREE_DETECTOR_PEER_QUEUE:-$HOME/.local/state/flywheel/slb-peer-approval-queue.jsonl}"

REPO="$repo" \
AGE_THRESHOLD_DAYS="$age_threshold_days" \
DEFAULT_BRANCH="$default_branch" \
MODE="$mode" \
JSON_OUTPUT="$json" \
AUDIT_LOG="$audit_log" \
PEER_QUEUE="$peer_queue" \
TIER_MAPPING="$tier_mapping" \
python3 <<'PY'
import datetime as dt
import json
import os
import re
import subprocess
import sys
from pathlib import Path

SCHEMA = "flywheel.stale_worktree_detector.v1"
RECIPE_ID = "git-worktree-remove-sibling-merged-pushed"


def run_git(args, cwd, timeout=20):
    try:
        return subprocess.run(
            ["git", *args],
            cwd=cwd,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
            timeout=timeout,
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        return subprocess.CompletedProcess(["git", *args], 127, "", str(exc))


def resolve_repo(repo):
    result = run_git(["rev-parse", "--show-toplevel"], repo)
    if result.returncode != 0:
        raise SystemExit(f"not a git repository: {repo}")
    return str(Path(result.stdout.strip()).resolve())


def detect_default_branch(repo, explicit):
    if explicit:
        return explicit
    result = run_git(["symbolic-ref", "--quiet", "--short", "refs/remotes/origin/HEAD"], repo)
    if result.returncode == 0 and result.stdout.strip().startswith("origin/"):
        return result.stdout.strip().split("/", 1)[1]
    for candidate in ("main", "master"):
        if run_git(["rev-parse", "--verify", "--quiet", candidate], repo).returncode == 0:
            return candidate
    return "main"


def default_ref(repo, branch):
    if run_git(["rev-parse", "--verify", "--quiet", branch], repo).returncode == 0:
        return branch
    if run_git(["rev-parse", "--verify", "--quiet", f"origin/{branch}"], repo).returncode == 0:
        return f"origin/{branch}"
    return branch


def parse_worktrees(repo):
    result = run_git(["worktree", "list", "--porcelain"], repo)
    if result.returncode != 0:
        raise SystemExit(result.stderr.strip() or "git worktree list failed")
    rows = []
    current = {}
    for line in result.stdout.splitlines():
        if not line:
            if current:
                rows.append(current)
                current = {}
            continue
        key, _, value = line.partition(" ")
        if key == "worktree":
            if current:
                rows.append(current)
            current = {"path": value.strip()}
        elif key == "HEAD":
            current["head"] = value.strip()
        elif key == "branch":
            current["branch_ref"] = value.strip()
            current["branch"] = value.strip().removeprefix("refs/heads/")
        elif key == "detached":
            current["detached"] = True
        elif key == "bare":
            current["bare"] = True
    if current:
        rows.append(current)
    return rows


def commit_age_days(path):
    if not Path(path).exists():
        return None
    result = run_git(["log", "-1", "--format=%ct"], path)
    if result.returncode != 0:
        return None
    try:
        committed = int(result.stdout.strip())
    except ValueError:
        return None
    now = int(dt.datetime.now(dt.timezone.utc).timestamp())
    return max(0, (now - committed) // 86400)


def is_merged(repo, branch, ref):
    if not branch:
        return None
    result = run_git(["branch", "--merged", ref, "--format=%(refname:short)"], repo)
    if result.returncode != 0:
        return None
    return branch in {line.strip() for line in result.stdout.splitlines()}


def is_pushed(repo, branch):
    if not branch:
        return None
    result = run_git(["ls-remote", "--exit-code", "--heads", "origin", branch], repo, timeout=30)
    if result.returncode == 0:
        return True
    if result.returncode == 2:
        return False
    return None


def has_dirty_state(path):
    result = run_git(["status", "--porcelain"], path)
    if result.returncode != 0:
        return True
    return bool(result.stdout.strip())


def path_class(path, repo):
    resolved = str(Path(path).resolve())
    tmpdir = str(Path(os.environ.get("TMPDIR", "/tmp")).resolve())
    if resolved.startswith("/tmp/") or resolved == "/tmp" or resolved.startswith(tmpdir.rstrip("/") + "/"):
        return "tmpdir"
    if re.match(r"^/var/folders/.+/T/", resolved):
        return "tmpdir"
    if re.match(r"^/Users/josh/Developer/[a-z][a-z0-9-]+-[a-z][a-z0-9-]+-[a-z0-9]{5}-[0-9]{6}/?$", resolved):
        return "sibling-suffix"
    repo_parent = str(Path(repo).parent.resolve())
    repo_name = Path(repo).name
    if str(Path(resolved).parent) == repo_parent and Path(resolved).name.startswith(f"{repo_name}-"):
        return "sibling-fresh-clone"
    if not Path(path).exists():
        return "detached"
    return "other"


def load_tier_mapping(path):
    mapping_path = Path(path).expanduser()
    status = "missing"
    routes = {"DISPOSABLE": "8iook", "REVERSIBLE_RECIPE": "daeqx", "PEER_REVIEW": "zesttube-slb"}
    if mapping_path.exists():
        status = "present"
        text = mapping_path.read_text(encoding="utf-8", errors="replace")
        for route in ("8iook", "daeqx", "zesttube-slb"):
            if route not in text:
                status = "present_unverified"
                break
    return {"path": str(mapping_path), "status": status, "routes": routes}


def classify(row, branch_counts, threshold, repo, ref):
    path = str(Path(row["path"]).resolve())
    branch = row.get("branch") or ""
    detached = bool(row.get("detached")) or not branch
    age = commit_age_days(path)
    merged = is_merged(repo, branch, ref)
    pushed = is_pushed(repo, branch)
    dirty = has_dirty_state(path) if Path(path).exists() else True
    pclass = path_class(path, repo)
    reasons = []

    item = {
        "path": path,
        "branch": branch or None,
        "head": row.get("head"),
        "last_commit_age_days": age,
        "merged_to_default_branch": merged,
        "pushed_to_origin": pushed,
        "path_prefix_class": pclass,
        "dirty": dirty,
    }

    if pclass == "tmpdir":
        item.update({"route": "8iook", "command": f"git worktree remove {path}"})
        return "DISPOSABLE", item

    if detached:
        reasons.append("detached_or_missing_branch")
    if dirty:
        reasons.append("worktree_has_uncommitted_changes")
    if branch and branch_counts.get(branch, 0) > 1:
        reasons.append("multiple_worktrees_same_branch")
    if merged is None:
        reasons.append("merged_state_uncertain")
    elif merged is False:
        reasons.append("branch_not_merged")
    if pushed is None:
        reasons.append("pushed_state_uncertain")
    elif pushed is False:
        reasons.append("branch_not_pushed")

    if not reasons and merged and pushed and age is not None and age > threshold and pclass == "sibling-suffix":
        item.update({
            "route": "daeqx",
            "recipe": RECIPE_ID,
            "command": f"git worktree remove {path}",
        })
        return "REVERSIBLE_RECIPE", item

    if reasons or detached or merged is None or pushed is None or dirty:
        item.update({
            "route": "zesttube-slb",
            "context_check": ";".join(reasons or ["requires_peer_context"]),
        })
        return "PEER_REVIEW", item

    item.update({"reason": f"no_safe_route_for_path_class:{pclass}"})
    return "HUMAN_FALLBACK", item


def append_jsonl(path, payload):
    target = Path(path).expanduser()
    target.parent.mkdir(parents=True, exist_ok=True)
    with target.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(payload, separators=(",", ":"), sort_keys=True) + "\n")


repo = resolve_repo(os.environ["REPO"])
threshold = int(os.environ["AGE_THRESHOLD_DAYS"])
mode = os.environ["MODE"]
default_branch = detect_default_branch(repo, os.environ.get("DEFAULT_BRANCH", ""))
ref = default_ref(repo, default_branch)
tier_mapping = load_tier_mapping(os.environ["TIER_MAPPING"])
rows = [row for row in parse_worktrees(repo) if str(Path(row["path"]).resolve()) != repo]
branch_counts = {}
for row in rows:
    branch = row.get("branch")
    if branch:
        branch_counts[branch] = branch_counts.get(branch, 0) + 1

classified = {"DISPOSABLE": [], "REVERSIBLE_RECIPE": [], "PEER_REVIEW": [], "HUMAN_FALLBACK": []}
for row in rows:
    bucket, item = classify(row, branch_counts, threshold, repo, ref)
    classified[bucket].append(item)

submissions = 0
if mode == "apply":
    for bucket in ("DISPOSABLE", "REVERSIBLE_RECIPE", "PEER_REVIEW"):
        for item in classified[bucket]:
            submissions += 1
            event = {
                "schema_version": "flywheel.stale_worktree_detector.submission.v1",
                "ts": dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
                "repo": repo,
                "classification": bucket,
                "route": item.get("route"),
                "path": item["path"],
                "command": item.get("command"),
                "recipe": item.get("recipe"),
                "context_check": item.get("context_check"),
                "execution": "not_executed_detector_routes_only",
            }
            append_jsonl(os.environ["AUDIT_LOG"], event)
            if bucket == "PEER_REVIEW":
                append_jsonl(os.environ["PEER_QUEUE"], event)

envelope = {
    "schema_version": SCHEMA,
    "ts": dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
    "repo": repo,
    "default_branch": default_branch,
    "default_ref": ref,
    "age_threshold_days": threshold,
    "mode": mode,
    "routing_table": tier_mapping,
    "worktrees_total": len(rows),
    "classified": classified,
    "submissions": submissions,
    "audit_log_path": os.environ["AUDIT_LOG"],
}
append_jsonl(os.environ["AUDIT_LOG"], {"event": "probe", **envelope})

if os.environ["JSON_OUTPUT"] == "1":
    print(json.dumps(envelope, separators=(",", ":"), sort_keys=True))
else:
    print(f"# Stale Worktree Detector\n\nrepo: {repo}\ndefault_branch: {default_branch}\nworktrees_total: {len(rows)}\nmode: {mode}\n")
    for bucket, items in classified.items():
        print(f"## {bucket} ({len(items)})")
        for item in items:
            detail = item.get("route") or item.get("reason", "")
            print(f"- {item['path']} [{detail}]")
        print()
PY
