#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/sync-canonical-doctrine.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/sync-canonical-owner-source.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

source_repo="$TMP/source"
no_manifest="$TMP/repos/no-manifest"
blocked="$TMP/repos/blocked"

mkdir -p "$source_repo/.flywheel" "$no_manifest/.flywheel" "$blocked/.flywheel"
cat >"$source_repo/AGENTS.md" <<'AGENTS'
# Canonical Fixture

## L1
alpha

## L2
beta
AGENTS
cat >"$source_repo/.flywheel/ownership.json" <<'JSON'
{
  "schema_version": "flywheel.canonical_ownership.v1",
  "canonical_owner_class": "flywheel",
  "owned_canonical_paths": [
    {"path": "AGENTS.md", "owner_class": "flywheel"},
    {"path": ".flywheel/AGENTS-CANONICAL.md", "owner_class": "flywheel"}
  ]
}
JSON

cat >"$no_manifest/AGENTS.md" <<'AGENTS'
# Target Fixture

<!-- BEGIN-CANONICAL-FLYWHEEL-DOCTRINE -->
## L1
alpha
<!-- END-CANONICAL-FLYWHEEL-DOCTRINE -->
AGENTS
cat >"$no_manifest/.flywheel/AGENTS-CANONICAL.md" <<'AGENTS'
# Target Fixture

## L1
alpha
AGENTS

cat >"$blocked/AGENTS.md" <<'AGENTS'
# Blocked Fixture

<!-- BEGIN-CANONICAL-FLYWHEEL-DOCTRINE -->
## L1
alpha
<!-- END-CANONICAL-FLYWHEEL-DOCTRINE -->
AGENTS
cat >"$blocked/.flywheel/AGENTS-CANONICAL.md" <<'AGENTS'
# Blocked Fixture

## L1
alpha
AGENTS
cat >"$blocked/.flywheel/ownership.json" <<'JSON'
{
  "schema_version": "flywheel.canonical_ownership.v1",
  "canonical_owner_class": "skillos",
  "owned_canonical_paths": [
    {"path": "AGENTS.md", "owner_class": "skillos"},
    {"path": ".flywheel/AGENTS-CANONICAL.md", "owner_class": "skillos"}
  ]
}
JSON

env_base=(
  "SYNC_CANONICAL_SOURCE=$source_repo/AGENTS.md"
  "SYNC_GENERATED_MIRRORS_DISABLE=1"
  "SYNC_CANONICAL_LEDGER_DISABLE=1"
  "SYNC_STORAGE_OVERRIDE_SCHEMA_SOURCE=$TMP/missing-storage.json"
  "SYNC_IDENTITY_DEFERRAL_SCHEMA_SOURCE=$TMP/missing-identity.json"
  "SYNC_BEAD_QUALITY_MINING_SOURCE=$TMP/missing-bead-quality.sh"
  "SYNC_DOCTRINE_DOCS_SOURCE_DIR=$TMP/missing-doctrine"
  "SYNC_RULES_SOURCE_DIR=$TMP/missing-rules"
  "SYNC_SHARED_SCRIPT_SOURCE_DIR=$TMP/missing-scripts"
  "SYNC_LAUNCHD_TEMPLATE_SOURCE_DIR=$TMP/missing-launchd"
  "SYNC_SECURITY_SETTINGS_DENY_SOURCE=$TMP/missing-security.json"
)

if env "${env_base[@]}" "$SCRIPT" --check --json --root "$no_manifest" >"$TMP/no-manifest-check.json"; then
  :
fi
if jq -e '.ownership_blocked_count == 0 and .canonical_drifted_count == 1 and .root_drifted_count == 1' "$TMP/no-manifest-check.json" >/dev/null; then
  pass "source manifest authorizes Flywheel-owned substrate when target manifest is absent"
else
  fail "no-manifest check did not use source ownership authority"
fi

env "${env_base[@]}" "$SCRIPT" --apply --idempotency-key=source-authority-test --json --root "$no_manifest" >"$TMP/no-manifest-apply.json"
if jq -e '.status == "ok" and .ownership_blocked_count == 0 and .errors_count == 0 and .canonical_synced_count == 1 and .root_synced_count == 1' "$TMP/no-manifest-apply.json" >/dev/null; then
  pass "source manifest authority applies Flywheel-owned substrate"
else
  fail "no-manifest apply did not sync without ownership blocks"
fi
if rg -q '^## L2$' "$no_manifest/.flywheel/AGENTS-CANONICAL.md" && rg -q '^## L2$' "$no_manifest/AGENTS.md"; then
  pass "no-manifest repo received canonical AGENTS surfaces"
else
  fail "no-manifest repo did not receive canonical AGENTS surfaces"
fi

if env "${env_base[@]}" "$SCRIPT" --check --json --root "$blocked" >"$TMP/blocked-check.json"; then
  :
fi
if jq -e '.ownership_blocked_count >= 1 and ([((.ownership_gate.details // [])[]).blocked_by] | index("ownership_class_mismatch") != null)' "$TMP/blocked-check.json" >/dev/null; then
  pass "explicit target ownership still blocks Flywheel propagation"
else
  fail "explicit non-Flywheel target ownership did not block propagation"
fi
if ! rg -q '^## L2$' "$blocked/.flywheel/AGENTS-CANONICAL.md"; then
  pass "blocked repo was not mutated by check mode"
else
  fail "blocked repo mutated unexpectedly"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
