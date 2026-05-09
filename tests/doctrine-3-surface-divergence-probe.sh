#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
PROBE="$ROOT/.flywheel/scripts/doctrine-3-surface-divergence-probe.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/doctrine-3-surface-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1"; fail_count=$((fail_count + 1)); }

make_surface() {
  local path="$1"
  shift
  mkdir -p "$(dirname "$path")"
  {
    printf '# Doctrine\n\n'
    for rule in "$@"; do
      printf '## %s — fixture\n\n---\nid: %s\n---\n\nbody\n\n' "$rule" "$rule"
    done
  } >"$path"
}

repo="$TMP/repo"
mkdir -p "$repo/.flywheel" "$repo/templates/flywheel-install"
printf 'repo_role: flywheel_origin\n' >"$repo/.flywheel/MISSION.md"

make_surface "$repo/AGENTS.md" L93 L94 L95
make_surface "$repo/.flywheel/AGENTS-CANONICAL.md" L93 L94 L95 L96
make_surface "$repo/templates/flywheel-install/AGENTS.md" L93 L94

set +e
out="$("$PROBE" --repo "$repo" --json)"
rc=$?
set -e

if [[ "$rc" -eq 1 ]]; then
  pass "drift exits non-zero"
else
  fail "drift exits non-zero"
fi

if jq -e '.doctrine_3_surface_divergent_count == 2 and (.missing_in_agents_md == ["L96"]) and (.missing_in_template == ["L95","L96"]) and (.missing_in_canonical == [])' <<<"$out" >/dev/null; then
  pass "drift payload lists per-surface missing rules"
else
  fail "drift payload lists per-surface missing rules"
  jq . <<<"$out" || true
fi

make_surface "$repo/AGENTS.md" L93 L94 L95 L96
make_surface "$repo/.flywheel/AGENTS-CANONICAL.md" L93 L94 L95 L96
make_surface "$repo/templates/flywheel-install/AGENTS.md" L93 L94 L95 L96

out="$("$PROBE" --repo "$repo" --json)"
if jq -e '.status == "pass" and .doctrine_3_surface_divergent_count == 0 and .exit_code == 0 and .surface_rule_counts.agents_md == 4' <<<"$out" >/dev/null; then
  pass "coherent surfaces pass"
else
  fail "coherent surfaces pass"
  jq . <<<"$out" || true
fi

cat >"$repo/AGENTS.md" <<'EOF'
# Doctrine

<!-- BEGIN-RULES-INDEX -->
| Order | Rule | Status | Shard |
|---:|---|---|---|
| 1 | L93 — fixture | long_term | `.flywheel/rules/L001-L93.md` |
| 2 | L94 — fixture | long_term | `.flywheel/rules/L002-L94.md` |
<!-- END-RULES-INDEX -->
EOF
cp "$repo/AGENTS.md" "$repo/.flywheel/AGENTS-CANONICAL.md"
cp "$repo/AGENTS.md" "$repo/templates/flywheel-install/AGENTS.md"
out="$("$PROBE" --repo "$repo" --json)"
if jq -e '.status == "pass" and .surface_rule_counts.agents_md == 2 and .surface_rule_counts.canonical == 2 and .surface_rule_counts.template == 2' <<<"$out" >/dev/null; then
  pass "generated index rows count as rules"
else
  fail "generated index rows count as rules"
  jq . <<<"$out" || true
fi

fleet="$TMP/fleet"
origin="$fleet/origin"
installed="$fleet/installed"
mkdir -p "$origin/.git" "$origin/.flywheel" "$origin/templates/flywheel-install" "$installed/.git" "$installed/.flywheel"
printf 'repo_role: flywheel_origin\n' >"$origin/.flywheel/MISSION.md"
make_surface "$origin/AGENTS.md" L93 L94 L95 L96
cp "$origin/AGENTS.md" "$origin/.flywheel/AGENTS-CANONICAL.md"
cp "$origin/AGENTS.md" "$origin/templates/flywheel-install/AGENTS.md"
make_surface "$installed/AGENTS.md" L93 L94 L95 L96
cp "$installed/AGENTS.md" "$installed/.flywheel/AGENTS-CANONICAL.md"

out="$(DOCTRINE_3_SURFACE_FLEET_REPOS="$origin,$installed" "$PROBE" --fleet --json)"
if jq -e '.status == "pass" and .fleet_repo_count == 2 and .fleet_mirror_drift_count == 0' <<<"$out" >/dev/null; then
  pass "fleet mode reports zero mirror drift"
else
  fail "fleet mode reports zero mirror drift"
  jq . <<<"$out" || true
fi

printf '\nSummary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
