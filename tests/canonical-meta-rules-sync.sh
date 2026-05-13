#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SYNC="$HOME/.flywheel/canonical-meta-rules/sync.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/canonical-meta-rules-sync.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

write_canonical() {
  cat >"$TMP/canonical.md" <<'EOF'
## L1 -- ONE

---
id: L1
title: One
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: fixture
---

one

## L2 -- TWO

two

## L3 -- THREE

three

## L4 -- FOUR

four
EOF
}

write_surface() {
  local path="$1"; shift
  mkdir -p "$(dirname "$path")"
  : >"$path"
  for rule in "$@"; do
    printf '## %s -- fixture\n\n%s body\n\n' "$rule" "$rule" >>"$path"
  done
}

make_repo() {
  local repo="$1"
  mkdir -p "$repo/.flywheel" "$repo/templates/flywheel-install"
}

run_check() {
  CANONICAL_META_RULES_SOURCE_AGENTS="$TMP/canonical.md" "$SYNC" --check-three-surface --target "$1" --json
}

run_apply() {
  CANONICAL_META_RULES_SOURCE_AGENTS="$TMP/canonical.md" "$SYNC" --apply-three-surface --target "$1" --json
}

write_canonical
chmod +x "$SYNC"

bash -n "$SYNC" && pass "sync script syntax" || fail "sync script syntax"

make_repo "$TMP/green"
write_surface "$TMP/green/AGENTS.md" L1 L2 L3 L4
write_surface "$TMP/green/.flywheel/AGENTS-CANONICAL.md" L1 L2 L3 L4
write_surface "$TMP/green/templates/flywheel-install/AGENTS.md" L1 L2 L3 L4
run_check "$TMP/green" >"$TMP/green.json"
assert_jq "$TMP/green.json" '.status == "pass" and .drift_count == 0 and .missing_rules_count == 0' "green drift is zero"
assert_jq "$TMP/green.json" '.root_rule_count == 4 and .canonical_rule_count == 4 and .template_rule_count == 4' "green counts all three surfaces"

make_repo "$TMP/root-missing"
write_surface "$TMP/root-missing/AGENTS.md" L1
write_surface "$TMP/root-missing/.flywheel/AGENTS-CANONICAL.md" L1 L2 L3 L4
write_surface "$TMP/root-missing/templates/flywheel-install/AGENTS.md" L1 L2 L3 L4
run_check "$TMP/root-missing" >"$TMP/root-missing.json" || true
assert_jq "$TMP/root-missing.json" '.status == "drift" and .drift_count == 3' "missing three root rules reports drift 3"
assert_jq "$TMP/root-missing.json" '.missing_in_agents_md == ["L2","L3","L4"] and .missing_in_canonical == [] and .missing_in_template == []' "missing arrays identify root-only drift"

make_repo "$TMP/apply"
write_surface "$TMP/apply/AGENTS.md" L1 L900
write_surface "$TMP/apply/.flywheel/AGENTS-CANONICAL.md" L1 L2 L3 L4
write_surface "$TMP/apply/templates/flywheel-install/AGENTS.md" L1 L2 L3 L4
run_apply "$TMP/apply" >"$TMP/apply1.json"
assert_jq "$TMP/apply1.json" '.status == "pass" and .pre_drift_count == 3 and .post_drift_count == 0 and (.updated_surfaces | index("agents_md"))' "apply backfills root drift"
rg -q '^## L900' "$TMP/apply/AGENTS.md" && pass "apply preserves local rule" || fail "apply preserves local rule"
run_apply "$TMP/apply" >"$TMP/apply2.json"
assert_jq "$TMP/apply2.json" '.status == "pass" and .applied == false and .pre_drift_count == 0 and .post_drift_count == 0' "apply is idempotent"

make_repo "$TMP/dirty"
write_surface "$TMP/dirty/AGENTS.md" L1
write_surface "$TMP/dirty/.flywheel/AGENTS-CANONICAL.md" L1 L2 L3 L4
write_surface "$TMP/dirty/templates/flywheel-install/AGENTS.md" L1 L2 L3 L4
git -C "$TMP/dirty" init -q
git -C "$TMP/dirty" -c user.name=fixture -c user.email=fixture@example.com add AGENTS.md .flywheel/AGENTS-CANONICAL.md templates/flywheel-install/AGENTS.md
git -C "$TMP/dirty" -c user.name=fixture -c user.email=fixture@example.com commit -qm init
printf 'dirty\n' >>"$TMP/dirty/AGENTS.md"
run_apply "$TMP/dirty" >"$TMP/dirty.json" 2>/dev/null && fail "dirty apply should fail" || pass "dirty apply exits nonzero"
assert_jq "$TMP/dirty.json" '.status == "blocked" and (.blocked_by | index("dirty_target_surfaces")) and .applied == false' "apply refuses dirty target surfaces"

CANONICAL_META_RULES_SOURCE_AGENTS="$TMP/canonical.md" \
"$SYNC" --fleet-check-three-surface --fleet-repo "green:$TMP/green" --fleet-repo "root-missing:$TMP/root-missing" --json >"$TMP/fleet.json" || true
assert_jq "$TMP/fleet.json" '.fleet_three_surface_drift_per_session.green == 0 and .fleet_three_surface_drift_per_session["root-missing"] == 3' "fleet check exposes per-session drift map"
assert_jq "$TMP/fleet.json" '.fleet_three_surface_drift_total_count == 3 and .fleet_three_surface_drift_max_count == 3 and .fleet_three_surface_drift_worst_session == "root-missing"' "fleet composite per-session math is correct"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
