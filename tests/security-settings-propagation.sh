#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SYNC="$ROOT/.flywheel/scripts/sync-canonical-doctrine.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/flywheel-security-settings.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/source/.flywheel/security/v1" \
  "$TMP/source/empty-docs" \
  "$TMP/source/empty-scripts" \
  "$TMP/source/empty-launchd" \
  "$TMP/loops" \
  "$TMP/repos/sample/.flywheel" \
  "$TMP/repos/sample/.claude"

cat >"$TMP/source/AGENTS.md" <<'AGENTS'
# Canonical Fixture

## L999 - Fixture Rule
AGENTS

cat >"$TMP/repos/sample/.flywheel/AGENTS-CANONICAL.md" <<'AGENTS'
# Canonical Fixture

## L999 - Fixture Rule
AGENTS

cat >"$TMP/repos/sample/AGENTS.md" <<'AGENTS'
# Sample Repo

<!-- BEGIN-CANONICAL-FLYWHEEL-DOCTRINE -->
# Canonical Fixture

## L999 - Fixture Rule
<!-- END-CANONICAL-FLYWHEEL-DOCTRINE -->
AGENTS

cat >"$TMP/source/.flywheel/security/v1/claude-settings-deny.json" <<'JSON'
{
  "control_schema_version": "agent-security-control/v1",
  "managed_block_id": "agent-security-deny/v1",
  "permissions": {
    "deny": [
      "Read(**/.env*)",
      "Bash(curl http://*)"
    ]
  }
}
JSON

cat >"$TMP/repos/sample/.claude/settings.json" <<'JSON'
{
  "env": {
    "SAFE_FLAG": "kept"
  },
  "permissions": {
    "allow": [
      "Bash(echo:*)"
    ],
    "ask": [
      "Bash(git status:*)"
    ],
    "deny": [
      "Read(local-only-secret)"
    ]
  },
  "theme": "dark"
}
JSON

run_sync() {
  SYNC_CANONICAL_LEDGER_DISABLE=1 \
  SYNC_CANONICAL_LOOPS_DIR="$TMP/loops" \
  SYNC_STORAGE_OVERRIDE_SCHEMA_SOURCE="$TMP/source/missing-storage.schema.json" \
  SYNC_IDENTITY_DEFERRAL_SCHEMA_SOURCE="$TMP/source/missing-identity.schema.json" \
  SYNC_BEAD_QUALITY_MINING_SOURCE="$TMP/source/missing-bead-quality.sh" \
  SYNC_DOCTRINE_DOCS_SOURCE_DIR="$TMP/source/empty-docs" \
  SYNC_SHARED_SCRIPT_SOURCE_DIR="$TMP/source/empty-scripts" \
  SYNC_LAUNCHD_TEMPLATE_SOURCE_DIR="$TMP/source/empty-launchd" \
  SYNC_SECURITY_SETTINGS_DENY_SOURCE="$TMP/source/.flywheel/security/v1/claude-settings-deny.json" \
    "$SYNC" "$@"
}

set +e
run_sync --dry-run --json --source "$TMP/source/AGENTS.md" --root "$TMP/repos" >"$TMP/dry-run.json"
dry_rc=$?
set -e
[[ "$dry_rc" -eq 1 ]]
jq -e 'has("security_settings_drift") and .security.settings_deny.drifted_count == 1' "$TMP/dry-run.json" >/dev/null

run_sync --apply --json --source "$TMP/source/AGENTS.md" --root "$TMP/repos" >"$TMP/apply.json"
jq -e '
  .env.SAFE_FLAG == "kept" and
  .theme == "dark" and
  .permissions.allow == ["Bash(echo:*)"] and
  .permissions.ask == ["Bash(git status:*)"] and
  (.permissions.deny | index("Read(local-only-secret)")) and
  (.permissions.deny | index("Read(**/.env*)")) and
  (.permissions.deny | index("Bash(curl http://*)")) and
  .flywheel_security.schema_version == "security-settings-sync/v1"
' "$TMP/repos/sample/.claude/settings.json" >/dev/null
find "$TMP/repos/sample/.claude" -maxdepth 1 -name 'settings.json.bak.*' -type f | grep -q .

run_sync --apply --json --source "$TMP/source/AGENTS.md" --root "$TMP/repos" >"$TMP/reapply.json"
jq -e '.security_settings_drift.drifted_count == 0 and .security_settings_synced_count == 0' "$TMP/reapply.json" >/dev/null
