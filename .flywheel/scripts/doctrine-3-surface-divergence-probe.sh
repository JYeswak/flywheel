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
  printf '%s\n' "Exit 0 when all three surfaces carry the same L-rule ID set; exit 1 on drift."
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

python3 - "$ROOT_AGENTS" "$CANONICAL_AGENTS" "$TEMPLATE_AGENTS" <<'PY'
import json
import re
import sys
from pathlib import Path

root_path = Path(sys.argv[1])
canonical_path = Path(sys.argv[2])
template_path = Path(sys.argv[3])
surfaces = {
    "agents_md": root_path,
    "canonical": canonical_path,
    "template": template_path,
}
pattern = re.compile(r"^## (L[0-9]+)\b")


def read_rules(path: Path) -> tuple[set[str], bool]:
    if not path.exists():
        return set(), False
    rules: set[str] = set()
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        match = pattern.match(line)
        if match:
            rules.add(match.group(1))
    return rules, True


rule_sets: dict[str, set[str]] = {}
exists: dict[str, bool] = {}
for name, path in surfaces.items():
    rules, present = read_rules(path)
    rule_sets[name] = rules
    exists[name] = present

union = set().union(*rule_sets.values())
missing = {
    name: sorted(union - rules, key=lambda item: int(item[1:]))
    for name, rules in rule_sets.items()
}
divergent = sorted(
    {rule for rule in union if any(rule not in rules for rules in rule_sets.values())},
    key=lambda item: int(item[1:]),
)
exit_code = 1 if divergent or not all(exists.values()) else 0

payload = {
    "schema_version": "doctrine-3-surface-divergence/v1",
    "status": "pass" if exit_code == 0 else "fail",
    "doctrine_3_surface_divergent_count": len(divergent),
    "divergent_rules": divergent,
    "missing_in_agents_md": missing["agents_md"],
    "missing_in_template": missing["template"],
    "missing_in_canonical": missing["canonical"],
    "surface_rule_counts": {name: len(rules) for name, rules in rule_sets.items()},
    "surface_exists": exists,
    "surfaces": {name: str(path) for name, path in surfaces.items()},
    "exit_code": exit_code,
}
print(json.dumps(payload, separators=(",", ":")))
sys.exit(exit_code)
PY
