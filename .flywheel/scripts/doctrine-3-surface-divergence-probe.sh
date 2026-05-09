#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-/Users/josh/Developer/flywheel}"
ROOT_AGENTS="${DOCTRINE_3_SURFACE_ROOT:-$REPO/AGENTS.md}"
CANONICAL_AGENTS="${DOCTRINE_3_SURFACE_CANONICAL:-$REPO/.flywheel/AGENTS-CANONICAL.md}"
TEMPLATE_AGENTS="${DOCTRINE_3_SURFACE_TEMPLATE:-$REPO/templates/flywheel-install/AGENTS.md}"
JSON_OUT=1

usage() {
  printf '%s\n' "usage: doctrine-3-surface-divergence-probe.sh [--repo PATH] [--json]"
  printf '%s\n' ""
  printf '%s\n' "Compares L-rule IDs across:"
  printf '%s\n' "  - AGENTS.md"
  printf '%s\n' "  - .flywheel/AGENTS-CANONICAL.md"
  printf '%s\n' "  - templates/flywheel-install/AGENTS.md"
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

python3 - "$REPO" "$ROOT_AGENTS" "$CANONICAL_AGENTS" "$TEMPLATE_AGENTS" <<'PY'
import json
import re
import subprocess
import sys
from pathlib import Path

repo_path = Path(sys.argv[1]).expanduser()
root_path = Path(sys.argv[2])
canonical_path = Path(sys.argv[3])
template_path = Path(sys.argv[4])
surfaces = {
    "agents_md": root_path,
    "canonical": canonical_path,
    "template": template_path,
}
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
    if template.exists():
        return "flywheel_origin", "template_surface_present"
    role = mission_repo_role(repo)
    if role:
        return role, "mission_repo_role"
    if origin_marks_flywheel(repo):
        return "flywheel_origin", "git_remote_origin"
    return "installed", "default_installed"


repo_role, repo_role_source = detect_repo_role(repo_path, template_path)
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

payload = {
    "schema_version": "doctrine-3-surface-divergence/v1",
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
print(json.dumps(payload, separators=(",", ":")))
sys.exit(exit_code)
PY
