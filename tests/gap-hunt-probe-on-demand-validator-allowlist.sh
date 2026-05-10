#!/usr/bin/env bash
# tests/gap-hunt-probe-on-demand-validator-allowlist.sh
# Bead flywheel-2fw7v: regression coverage for the on-demand validator
# allowlist added to gap-hunt-probe's probe_wired_but_cold() heuristic.
#
# The probe now consults the substrate-registry.json (kind=validator/
# scaffold-test/self-test/audit/scaffold rows) AND a path-glob fallback
# (skill-packs/*/validate.sh) before flagging a script as cold. This test
# exercises both paths with isolated fixtures.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
PROBE="${GAP_HUNT_PROBE_PATH:-$ROOT/.flywheel/scripts/gap-hunt-probe.sh}"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: probe exists + bash -n syntax-checks + has the new allowlist hook
if [[ -x "$PROBE" ]] && bash -n "$PROBE" 2>/dev/null \
  && grep -q "on_demand_script_allowlist" "$PROBE" \
  && grep -q "_ON_DEMAND_VALIDATOR_KINDS" "$PROBE"; then
  pass "gap-hunt-probe.sh exists, syntax ok, on_demand_script_allowlist hook present"
else
  fail "gap-hunt-probe.sh missing or allowlist hook absent at $PROBE"
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

# Build an isolated fixture: empty STATE_DIR (no ledger text) +
# fake substrate-registry naming the validator + fake skills root with
# the candidate validator script.
FIXTURE="$(mktemp -d -t flywheel-2fw7v-fixture.XXXXXX)"
trap 'rm -rf "$FIXTURE"' EXIT
mkdir -p "$FIXTURE/state-dir"
mkdir -p "$FIXTURE/.claude/skills/.flywheel/data/skill-packs/test-pack"
mkdir -p "$FIXTURE/.claude/skills/.flywheel/data/skill-packs/registry-only-pack"
mkdir -p "$FIXTURE/.claude/skills/.flywheel/scripts"
mkdir -p "$FIXTURE/repo/.flywheel/scripts"

# Glob-fallback validator (matches skill-packs/*/validate.sh)
cat >"$FIXTURE/.claude/skills/.flywheel/data/skill-packs/test-pack/validate.sh" <<'EOF'
#!/usr/bin/env bash
echo "OK glob-fallback test-pack validator"
EOF
chmod +x "$FIXTURE/.claude/skills/.flywheel/data/skill-packs/test-pack/validate.sh"

# Registry-only validator (named with 'audit.sh' so it does NOT match the
# skill-packs/*/validate.sh glob — must be reached via registry path)
cat >"$FIXTURE/.claude/skills/.flywheel/data/skill-packs/registry-only-pack/audit.sh" <<'EOF'
#!/usr/bin/env bash
echo "OK registry-only audit"
EOF
chmod +x "$FIXTURE/.claude/skills/.flywheel/data/skill-packs/registry-only-pack/audit.sh"

# Genuine cold script (does NOT match any allowlist criterion)
cat >"$FIXTURE/.claude/skills/.flywheel/scripts/genuinely-cold.sh" <<'EOF'
#!/usr/bin/env bash
echo "this script is genuinely cold-by-drift"
EOF
chmod +x "$FIXTURE/.claude/skills/.flywheel/scripts/genuinely-cold.sh"

# Substrate registry: nest a kind=audit row pointing at the
# registry-only-pack/audit.sh path (using absolute fixture path).
cat >"$FIXTURE/.claude/skills/.flywheel/data/substrate-registry.json" <<EOF
{
  "registryVersion": "1.0.0",
  "specVersion": "substrate-registry.v1",
  "substrates": [
    {
      "name": "registry-only-pack",
      "kind": "skill-pack",
      "components": [
        {
          "name": "registry-only-pack-audit",
          "kind": "audit",
          "where": "$FIXTURE/.claude/skills/.flywheel/data/skill-packs/registry-only-pack/audit.sh"
        }
      ]
    }
  ]
}
EOF

# Test 2: glob-fallback validator is NOT flagged
RESULT_JSON="$("$PROBE" --dry-run --json \
  GAP_HUNT_STATE_DIR="$FIXTURE/state-dir" \
  GAP_HUNT_CLAUDE_ROOT="$FIXTURE/.claude" \
  GAP_HUNT_REPO_ROOT="$FIXTURE/repo" \
  GAP_HUNT_LEDGER="$FIXTURE/state-dir/gap-hunt.jsonl" \
  GAP_HUNT_SUBSTRATE_REGISTRY="$FIXTURE/.claude/skills/.flywheel/data/substrate-registry.json" \
  2>/dev/null || true)"
# Note: the probe reads env vars from os.environ, so we need to invoke under env.
RESULT_JSON="$(env \
  GAP_HUNT_STATE_DIR="$FIXTURE/state-dir" \
  GAP_HUNT_CLAUDE_ROOT="$FIXTURE/.claude" \
  GAP_HUNT_REPO_ROOT="$FIXTURE/repo" \
  GAP_HUNT_LEDGER="$FIXTURE/state-dir/gap-hunt.jsonl" \
  GAP_HUNT_SUBSTRATE_REGISTRY="$FIXTURE/.claude/skills/.flywheel/data/substrate-registry.json" \
  "$PROBE" --dry-run --json 2>/dev/null || true)"
if [[ -z "$RESULT_JSON" ]]; then
  fail "probe produced empty output under fixture env"
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

if jq -e '.gaps_by_class["wired-but-cold"] // [] | map(.name) | any(. | test("test-pack/validate.sh")) | not' >/dev/null 2>&1 <<<"$RESULT_JSON"; then
  pass "glob-fallback validator (skill-packs/test-pack/validate.sh) NOT flagged as cold"
else
  fail "glob-fallback validator flagged; got: $(jq -r '.gaps_by_class["wired-but-cold"] // [] | map(.name) | join(",")' <<<"$RESULT_JSON")"
fi

# Test 3: registry-only audit (kind=audit, custom path) is NOT flagged
if jq -e '.gaps_by_class["wired-but-cold"] // [] | map(.name) | any(. | test("registry-only-pack/audit.sh")) | not' >/dev/null 2>&1 <<<"$RESULT_JSON"; then
  pass "registry-only audit (kind=audit, where:) NOT flagged as cold"
else
  fail "registry-only audit flagged; got: $(jq -r '.gaps_by_class["wired-but-cold"] // [] | map(.name) | join(",")' <<<"$RESULT_JSON")"
fi

# Test 4: genuinely-cold script IS flagged (negative control)
if jq -e '.gaps_by_class["wired-but-cold"] // [] | map(.name) | any(. | test("genuinely-cold.sh"))' >/dev/null 2>&1 <<<"$RESULT_JSON"; then
  pass "genuinely-cold script IS flagged (negative control)"
else
  fail "genuinely-cold script not flagged — allowlist may be too broad; got: $(jq -r '.gaps_by_class["wired-but-cold"] // [] | map(.name) | join(",")' <<<"$RESULT_JSON")"
fi

# Test 5: live probe (no fixture) produces 0 pack validators in
# wired-but-cold output. Regression guard for the production fix.
LIVE_JSON="$("$PROBE" --dry-run --json 2>/dev/null || true)"
if [[ -n "$LIVE_JSON" ]]; then
  pack_validator_count="$(jq -r '.gaps_by_class["wired-but-cold"] // [] | map(.name) | map(select(test("skill-packs/.*/validate\\.sh"))) | length' <<<"$LIVE_JSON")"
  if [[ "$pack_validator_count" == "0" ]]; then
    pass "live probe: 0 pack validators flagged (was 18/20 before fix)"
  else
    fail "live probe: $pack_validator_count pack validators still flagged"
  fi
else
  fail "live probe produced empty output"
fi

# Test 6: vmc7r two-pass corpus + dispatch-log inclusion still work
# (regression guard for upstream fix)
if grep -q "Two-pass design" "$PROBE" \
  && grep -q "name corpus, ALWAYS COMPLETE" "$PROBE" \
  && grep -q "repo-local dispatch-log.jsonl" "$PROBE"; then
  pass "vmc7r two-pass corpus + dispatch-log inclusion preserved"
else
  fail "vmc7r upstream fix regressed in source"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
