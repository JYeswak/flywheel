#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-/Users/josh/Developer/flywheel}"
ROOT_AGENTS="${DOCTRINE_3_SURFACE_ROOT:-$REPO/AGENTS.md}"
CANONICAL_AGENTS="${DOCTRINE_3_SURFACE_CANONICAL:-$REPO/.flywheel/AGENTS-CANONICAL.md}"
TEMPLATE_AGENTS="${DOCTRINE_3_SURFACE_TEMPLATE:-$REPO/templates/flywheel-install/AGENTS.md}"
JSON_OUT=1
FLEET_MODE=0
FLEET_ROOTS=()

usage() {
  printf '%s\n' "usage: doctrine-3-surface-divergence-probe.sh [--repo PATH] [--fleet] [--root PATH] [--json]"
  printf '%s\n' ""
  printf '%s\n' "Compares L-rule IDs across:"
  printf '%s\n' "  - AGENTS.md"
  printf '%s\n' "  - .flywheel/AGENTS-CANONICAL.md"
  printf '%s\n' "  - templates/flywheel-install/AGENTS.md"
  printf '%s\n' ""
  printf '%s\n' "Fleet mode discovers repos from DOCTRINE_3_SURFACE_FLEET_REPOS,"
  printf '%s\n' "fleet-roster.json, ~/.flywheel/loops, and --root directories."
  printf '%s\n' ""
  printf '%s\n' "Exit 0 when required surfaces carry the same L-rule ID set; exit 1 on drift."
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      [[ -n "${2:-}" ]] || { printf 'ERR: --repo requires PATH\n' >&2; exit 2; }
      REPO="$2"
      ROOT_AGENTS="${DOCTRINE_3_SURFACE_ROOT:-$REPO/AGENTS.md}"
      CANONICAL_AGENTS="${DOCTRINE_3_SURFACE_CANONICAL:-$REPO/.flywheel/AGENTS-CANONICAL.md}"
      TEMPLATE_AGENTS="${DOCTRINE_3_SURFACE_TEMPLATE:-$REPO/templates/flywheel-install/AGENTS.md}"
      shift 2
      ;;
    --fleet)
      FLEET_MODE=1
      shift
      ;;
    --root)
      [[ -n "${2:-}" ]] || { printf 'ERR: --root requires PATH\n' >&2; exit 2; }
      FLEET_ROOTS+=("$2")
      shift 2
      ;;
    --json)
      JSON_OUT=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'ERR: unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

python3 - "$REPO" "$ROOT_AGENTS" "$CANONICAL_AGENTS" "$TEMPLATE_AGENTS" "$FLEET_MODE" "${FLEET_ROOTS[@]}" <<'PY'
import json
import os
import re
import subprocess
import sys
from pathlib import Path

repo_path = Path(sys.argv[1]).expanduser()
root_path = Path(sys.argv[2])
canonical_path = Path(sys.argv[3])
template_path = Path(sys.argv[4])
fleet_mode = sys.argv[5] == "1"
fleet_roots = [Path(item).expanduser() for item in sys.argv[6:]]
heading_pattern = re.compile(r"^## (L[0-9]+)\b")
index_pattern = re.compile(r"^\|\s*[0-9]+\s*\|\s*(L[0-9]+)\s+")


def read_rules(path: Path) -> tuple[set[str], bool]:
    if not path.exists():
        return set(), False
    rules: set[str] = set()
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        match = heading_pattern.match(line) or index_pattern.match(line)
        if match:
            rules.add(match.group(1))
    return rules, True


def mission_repo_role(repo: Path):
    mission = repo / ".flywheel/MISSION.md"
    if not mission.exists():
        return None
    for line in mission.read_text(encoding="utf-8", errors="replace").splitlines():
        match = re.match(r"\s*repo_role\s*[:=]\s*([A-Za-z0-9_-]+)\s*$", line)
        if match and match.group(1) in {"flywheel_origin", "installed"}:
            return match.group(1)
    return None


def origin_marks_flywheel(repo: Path) -> bool:
    try:
        result = subprocess.run(
            ["git", "-C", str(repo), "remote", "get-url", "origin"],
            text=True,
            capture_output=True,
            check=False,
            timeout=2,
        )
    except Exception:
        return False
    return "dicklesworthstone-stack/flywheel" in result.stdout


def detect_repo_role(repo: Path, template: Path) -> tuple[str, str]:
    role = mission_repo_role(repo)
    if role:
        return role, "mission_repo_role"
    if origin_marks_flywheel(repo):
        return "flywheel_origin", "git_remote_origin"
    if template.exists() and repo.name == "flywheel":
        return "flywheel_origin", "repo_name_template_surface"
    return "installed", "default_installed"


def scan_repo(repo: Path, root_override: Path | None = None, canonical_override: Path | None = None, template_override: Path | None = None) -> dict:
    root = root_override or repo / "AGENTS.md"
    canonical = canonical_override or repo / ".flywheel/AGENTS-CANONICAL.md"
    template = template_override or repo / "templates/flywheel-install/AGENTS.md"
    surfaces = {
        "agents_md": root,
        "canonical": canonical,
        "template": template,
    }
    repo_role, repo_role_source = detect_repo_role(repo, template)
    required = {
        "agents_md": True,
        "canonical": True,
        "template": repo_role == "flywheel_origin",
    }

    rule_sets: dict[str, set[str]] = {}
    exists: dict[str, bool] = {}
    for name, path in surfaces.items():
        rules, present = read_rules(path)
        rule_sets[name] = rules
        exists[name] = present

    active_sets = [rules for name, rules in rule_sets.items() if required[name]]
    union = set().union(*active_sets) if active_sets else set()
    missing = {
        name: sorted(union - rules, key=lambda item: int(item[1:])) if required[name] else []
        for name, rules in rule_sets.items()
    }
    divergent = sorted(
        {
            rule
            for rule in union
            if any(rule not in rules for name, rules in rule_sets.items() if required[name])
        },
        key=lambda item: int(item[1:]),
    )
    missing_required_surface = any((not exists[name]) for name in required if required[name])
    exit_code = 1 if divergent or missing_required_surface else 0
    return {
        "schema_version": "doctrine-3-surface-divergence/v1",
        "repo": str(repo),
        "repo_role": repo_role,
        "repo_role_source": repo_role_source,
        "status": "pass" if exit_code == 0 else "fail",
        "doctrine_3_surface_divergent_count": len(divergent),
        "divergent_rules": divergent,
        "missing_in_agents_md": missing["agents_md"],
        "missing_in_template": missing["template"],
        "missing_in_canonical": missing["canonical"],
        "surface_rule_counts": {name: len(rules) for name, rules in rule_sets.items()},
        "surface_exists": exists,
        "surface_status": {
            name: ("missing" if required[name] and not exists[name] else "active" if required[name] else "n/a")
            for name in surfaces
        },
        "surfaces": {
            name: {
                "path": str(path),
                "exists": exists[name],
                "active": required[name],
                "status": "missing" if required[name] and not exists[name] else "active" if required[name] else "n/a",
                "rule_count": len(rule_sets[name]),
                "missing_rules": missing[name],
                "missing_count": len(missing[name]),
            }
            for name, path in surfaces.items()
        },
        "exit_code": exit_code,
    }


def split_repos(value: str) -> list[Path]:
    parts = re.split(r"[,:]", value)
    return [Path(part).expanduser() for part in parts if part.strip()]


def repos_from_roster(path: Path) -> list[Path]:
    if not path.exists():
        return []
    try:
        data = json.loads(path.read_text())
    except Exception:
        return []
    if isinstance(data, list):
        rows = data
    elif isinstance(data, dict):
        rows = data.get("members") or data.get("repos") or data.get("projects") or data.get("sessions") or []
    else:
        rows = []
    repos: list[Path] = []
    for row in rows:
        if isinstance(row, str):
            repos.append(Path(row).expanduser())
        elif isinstance(row, dict):
            value = row.get("repo_realpath") or row.get("repo") or row.get("path") or row.get("project_key") or row.get("repo_path")
            if isinstance(value, str) and value:
                repos.append(Path(value).expanduser())
    return repos


def repos_from_loops(path: Path) -> list[Path]:
    if not path.is_dir():
        return []
    repos: list[Path] = []
    for item in sorted(path.glob("*.json")):
        try:
            data = json.loads(item.read_text())
        except Exception:
            continue
        value = data.get("repo_realpath") or data.get("repo_path") or data.get("repo") or data.get("project_path")
        if isinstance(value, str) and value:
            repos.append(Path(value).expanduser())
    return repos


def repos_from_root(root: Path) -> list[Path]:
    if not root.is_dir():
        return []
    repos: list[Path] = []
    base_depth = len(root.resolve().parts)
    for current, dirs, files in os.walk(root):
        path = Path(current)
        depth = len(path.resolve().parts) - base_depth
        if depth > 4:
            dirs[:] = []
            continue
        if ".git" in dirs and (path / ".flywheel/AGENTS-CANONICAL.md").exists():
            repos.append(path)
            dirs[:] = [item for item in dirs if item not in {".git", "node_modules", ".venv", "vendor"}]
        else:
            dirs[:] = [item for item in dirs if item not in {".git", "node_modules", ".venv", "vendor", "Library"}]
    return repos


def fleet_repos() -> list[Path]:
    repos: list[Path] = []
    env_repos = os.environ.get("DOCTRINE_3_SURFACE_FLEET_REPOS", "")
    if env_repos:
        repos.extend(split_repos(env_repos))
        return unique_existing_repos(repos)
    roster = Path(os.environ.get("DOCTRINE_3_SURFACE_FLEET_ROSTER", str(Path.home() / ".local/state/flywheel/fleet-roster.json"))).expanduser()
    loops = Path(os.environ.get("DOCTRINE_3_SURFACE_LOOPS_DIR", str(Path.home() / ".flywheel/loops"))).expanduser()
    repos.extend(repos_from_roster(roster))
    repos.extend(repos_from_loops(loops))
    roots = fleet_roots or [Path(os.environ.get("DOCTRINE_3_SURFACE_FLEET_ROOT", str(Path.home() / "Developer"))).expanduser()]
    for root in roots:
        repos.extend(repos_from_root(root))
    return unique_existing_repos(repos)


def unique_existing_repos(repos: list[Path]) -> list[Path]:
    seen: set[str] = set()
    unique: list[Path] = []
    for repo in repos:
        try:
            resolved = str(repo.resolve())
        except Exception:
            resolved = str(repo)
        if resolved in seen or not Path(resolved).is_dir():
            continue
        seen.add(resolved)
        unique.append(Path(resolved))
    return unique


if fleet_mode:
    results = [scan_repo(repo) for repo in fleet_repos()]
    violations = [row for row in results if row["exit_code"] != 0]
    payload = {
        "schema_version": "doctrine-3-surface-divergence-fleet/v1",
        "status": "pass" if not violations else "fail",
        "fleet_repo_count": len(results),
        "fleet_mirror_drift_count": len(violations),
        "violating_repos": [row["repo"] for row in violations],
        "repos": results,
        "exit_code": 0 if not violations else 1,
    }
    print(json.dumps(payload, separators=(",", ":")))
    sys.exit(payload["exit_code"])

payload = scan_repo(repo_path, root_path, canonical_path, template_path)
print(json.dumps(payload, separators=(",", ":")))
sys.exit(payload["exit_code"])
PY
