#!/usr/bin/env bash
set -euo pipefail

ROOT="${FLEET_L_RULE_LAG_ROOT:-/Users/josh/Developer}"
SOURCE="${FLEET_L_RULE_LAG_SOURCE:-/Users/josh/Developer/flywheel/.flywheel/AGENTS-CANONICAL.md}"
LOOPS_DIR="${FLEET_L_RULE_LAG_LOOPS_DIR:-$HOME/.flywheel/loops}"

usage() {
  printf '%s\n' "usage: fleet-l-rule-lag-probe.sh [--root PATH] [--source PATH] [--json]"
  printf '%s\n' "Reports repos whose root AGENTS.md is missing L-rules present in canonical doctrine."
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root)
      [[ -n "${2:-}" ]] || { printf 'ERR: --root requires PATH\n' >&2; exit 2; }
      ROOT="$2"
      shift 2
      ;;
    --source)
      [[ -n "${2:-}" ]] || { printf 'ERR: --source requires PATH\n' >&2; exit 2; }
      SOURCE="$2"
      shift 2
      ;;
    --json)
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

python3 - "$ROOT" "$SOURCE" "$LOOPS_DIR" <<'PY'
import json
import re
import sys
from pathlib import Path

root = Path(sys.argv[1]).expanduser()
source = Path(sys.argv[2]).expanduser()
loops_dir = Path(sys.argv[3]).expanduser()
pattern = re.compile(r"^## (L[0-9]+)\b")


def read_rules(path: Path) -> set[str]:
    if not path.exists():
        return set()
    rules: set[str] = set()
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        match = pattern.match(line)
        if match:
            rules.add(match.group(1))
    return rules


def sort_rules(items: set[str]) -> list[str]:
    return sorted(items, key=lambda item: int(item[1:]))


def loop_repos() -> set[Path]:
    repos: set[Path] = set()
    if loops_dir.exists():
        for loop_file in loops_dir.glob("*.json"):
            try:
                data = json.loads(loop_file.read_text(encoding="utf-8"))
            except Exception:
                continue
            raw = data.get("repo_path") or data.get("repo") or data.get("project_path")
            if raw:
                repos.add(Path(str(raw)).expanduser())
    return repos


repos = loop_repos()
if root.exists():
    for candidate in root.iterdir():
        if not candidate.is_dir():
            continue
        if (candidate / ".flywheel" / "loop.json").exists() or (
            candidate / ".flywheel" / "AGENTS-CANONICAL.md"
        ).exists():
            repos.add(candidate)

source_rules = read_rules(source)
rows = []
for repo in sorted(repos, key=lambda item: str(item)):
    if not repo.exists():
        continue
    agents = repo / "AGENTS.md"
    target_rules = read_rules(agents)
    missing = sort_rules(source_rules - target_rules)
    if missing:
        rows.append(
            {
                "repo": str(repo),
                "agents_md": str(agents),
                "missing_rules": missing,
                "missing_count": len(missing),
                "target_rule_count": len(target_rules),
            }
        )

payload = {
    "schema_version": "fleet-l-rule-lag/v1",
    "status": "pass" if not rows else "fail",
    "source": str(source),
    "source_rule_count": len(source_rules),
    "repos_checked": len([repo for repo in repos if repo.exists()]),
    "fleet_repo_l_rule_lag_count": len(rows),
    "lagging_repos": rows,
    "exit_code": 0 if not rows else 1,
}
print(json.dumps(payload, separators=(",", ":")))
sys.exit(payload["exit_code"])
PY
