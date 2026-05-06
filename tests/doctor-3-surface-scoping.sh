#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
PROBE="$ROOT/.flywheel/scripts/doctrine-3-surface-divergence-probe.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/doctor-3-surface-scoping.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
case_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1"; fail_count=$((fail_count + 1)); }

write_surface() {
  local path="$1"; shift
  mkdir -p "$(dirname "$path")"
  {
    printf '# Doctrine\n\n'
    for rule in "$@"; do
      printf '## %s -- fixture\n\n---\nid: %s\n---\n\n%s body\n\n' "$rule" "$rule" "$rule"
    done
  } >"$path"
}

write_mission_role() {
  local repo="$1" role="$2"
  mkdir -p "$repo/.flywheel"
  printf '# Mission\n\nrepo_role=%s\n' "$role" >"$repo/.flywheel/MISSION.md"
}

run_probe() {
  "$PROBE" --repo "$1" --json
}

assert_case() {
  local file="$1" jq_expr="$2" label="$3"
  case_count=$((case_count + 1))
  if jq -e "$jq_expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

bash -n "$PROBE" && pass "probe syntax" || fail "probe syntax"

origin_green="$TMP/flywheel-origin-green"
write_surface "$origin_green/AGENTS.md" L1 L2 L3 L4
write_surface "$origin_green/.flywheel/AGENTS-CANONICAL.md" L1 L2 L3 L4
write_surface "$origin_green/templates/flywheel-install/AGENTS.md" L1 L2 L3 L4
run_probe "$origin_green" >"$TMP/origin-green.json"
assert_case "$TMP/origin-green.json" \
  '.repo_role == "flywheel_origin" and .repo_role_source == "template_surface_present" and .status == "pass" and .doctrine_3_surface_divergent_count == 0 and .surface_status.template == "active"' \
  "flywheel-origin all three surfaces pass"

origin_missing_template="$TMP/flywheel-origin-missing-template"
write_mission_role "$origin_missing_template" flywheel_origin
write_surface "$origin_missing_template/AGENTS.md" L1 L2 L3 L4
write_surface "$origin_missing_template/.flywheel/AGENTS-CANONICAL.md" L1 L2 L3 L4
run_probe "$origin_missing_template" >"$TMP/origin-missing-template.json" || true
assert_case "$TMP/origin-missing-template.json" \
  '.repo_role == "flywheel_origin" and .repo_role_source == "mission_repo_role" and .status == "fail" and .surface_exists.template == false and .surface_status.template == "missing" and (.missing_in_template == ["L1","L2","L3","L4"])' \
  "flywheel-origin missing template remains fail"

installed_green="$TMP/installed-green"
write_surface "$installed_green/AGENTS.md" L1 L2 L3 L4
write_surface "$installed_green/.flywheel/AGENTS-CANONICAL.md" L1 L2 L3 L4
run_probe "$installed_green" >"$TMP/installed-green.json"
assert_case "$TMP/installed-green.json" \
  '.repo_role == "installed" and .repo_role_source == "default_installed" and .status == "pass" and .doctrine_3_surface_divergent_count == 0 and .surface_exists.template == false and .surface_status.template == "n/a" and .missing_in_template == []' \
  "installed repo missing template is n/a pass"

installed_drift="$TMP/installed-drift"
write_surface "$installed_drift/AGENTS.md" L1 L2
write_surface "$installed_drift/.flywheel/AGENTS-CANONICAL.md" L1 L2 L3
run_probe "$installed_drift" >"$TMP/installed-drift.json" || true
assert_case "$TMP/installed-drift.json" \
  '.repo_role == "installed" and .status == "fail" and .doctrine_3_surface_divergent_count == 1 and .missing_in_agents_md == ["L3"] and .missing_in_template == [] and .surface_status.template == "n/a"' \
  "installed repo root/canonical drift remains fail"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d fixture_cases=%d/4\n' "$pass_count" "$fail_count" "$case_count" >&2
  exit 1
fi

printf 'SUMMARY pass=%d fail=0 fixture_cases=%d/4\n' "$pass_count" "$case_count"
