#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)"
cd "$ROOT"

TMP="$(mktemp -d "${TMPDIR:-/tmp}/flywheel-1ebor-l112.XXXXXX")"
trap '/Users/josh/.local/bin/flywheel-cleanup-scratch --apply --json "$TMP" >/dev/null 2>&1 || true' EXIT

bash -n .flywheel/scripts/sync-canonical-doctrine.sh

mkdir -p "$TMP/source/.flywheel/rules" "$TMP/empty-docs" "$TMP/empty-scripts" "$TMP/empty-launchd" "$TMP/dev/shardless/.flywheel"
: >"$TMP/source/AGENTS.md"
for i in $(seq 1 142); do
  printf 'line %03d\n' "$i" >>"$TMP/source/AGENTS.md"
done
cp "$TMP/source/AGENTS.md" "$TMP/dev/shardless/.flywheel/AGENTS-CANONICAL.md"
for i in $(seq 1 101); do
  printf '# L%03d fixture\n' "$i" >"$TMP/source/.flywheel/rules/L$(printf '%03d' "$i")-fixture.md"
done
printf '{"fixture":true}\n' >"$TMP/source/.flywheel/rules/MANIFEST.json"

set +e
SYNC_CANONICAL_SOURCE="$TMP/source/AGENTS.md" \
SYNC_RULES_SOURCE_DIR="$TMP/source/.flywheel/rules" \
SYNC_DOCTRINE_DOCS_SOURCE_DIR="$TMP/empty-docs" \
SYNC_SHARED_SCRIPT_SOURCE_DIR="$TMP/empty-scripts" \
SYNC_LAUNCHD_TEMPLATE_SOURCE_DIR="$TMP/empty-launchd" \
SYNC_STORAGE_OVERRIDE_SCHEMA_SOURCE="$TMP/missing-storage.json" \
SYNC_IDENTITY_DEFERRAL_SCHEMA_SOURCE="$TMP/missing-identity.json" \
SYNC_BEAD_QUALITY_MINING_SOURCE="$TMP/missing-bead.sh" \
SYNC_SECURITY_SETTINGS_DENY_SOURCE="$TMP/missing-security.json" \
SYNC_CANONICAL_LEDGER_DISABLE=1 \
  .flywheel/scripts/sync-canonical-doctrine.sh --dry-run --root "$TMP/dev" --json >"$TMP/shardless.json"
rc=$?
set -e
[[ "$rc" -eq 1 ]]
jq -e '.rule_shard_drift_count == 1 and .rule_shard_drift.details[0].canonical_lines == 142 and .rule_shard_drift.details[0].rule_shards == 0' \
  "$TMP/shardless.json" >/dev/null

SYNC_CANONICAL_SOURCE="$TMP/source/AGENTS.md" \
SYNC_RULES_SOURCE_DIR="$TMP/source/.flywheel/rules" \
SYNC_DOCTRINE_DOCS_SOURCE_DIR="$TMP/empty-docs" \
SYNC_SHARED_SCRIPT_SOURCE_DIR="$TMP/empty-scripts" \
SYNC_LAUNCHD_TEMPLATE_SOURCE_DIR="$TMP/empty-launchd" \
SYNC_STORAGE_OVERRIDE_SCHEMA_SOURCE="$TMP/missing-storage.json" \
SYNC_IDENTITY_DEFERRAL_SCHEMA_SOURCE="$TMP/missing-identity.json" \
SYNC_BEAD_QUALITY_MINING_SOURCE="$TMP/missing-bead.sh" \
SYNC_SECURITY_SETTINGS_DENY_SOURCE="$TMP/missing-security.json" \
SYNC_CANONICAL_LEDGER_DISABLE=1 \
  .flywheel/scripts/sync-canonical-doctrine.sh --apply --root "$TMP/dev" --json >"$TMP/apply.json"
jq -e '.rule_shard_drift_count == 0' "$TMP/apply.json" >/dev/null

printf 'OK_rule_shard_detector\n'
