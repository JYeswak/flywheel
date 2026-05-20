#!/usr/bin/env bash
# tests/sync-hooks-smoke.sh — smoke test for flywheel-sync-hooks.sh
#
# Verifies:
#   1. --dry-run emits a receipt with no mutations and dashboard_line.
#   2. --apply on dirty WT (unrelated dirty file outside managed paths) REFUSES.
#   3. --apply on clean WT succeeds and installs the canonical hook content.
#   4. hook_opt_out[] entries are honored: opted-out hook is NOT installed.
#   5. fleet-hook-conformance-probe.sh emits valid JSON with fleet_hook_hygiene key.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SYNC_SCRIPT="$REPO_ROOT/.flywheel/scripts/flywheel-sync-hooks.sh"
PROBE_SCRIPT="$REPO_ROOT/.flywheel/scripts/fleet-hook-conformance-probe.sh"
SCHEMA="$REPO_ROOT/.flywheel/schemas/HOOK-MANIFEST.schema.json"

fail() { echo "FAIL: $*" >&2; exit 1; }
pass() { echo "PASS: $*"; }

[[ -x "$SYNC_SCRIPT" ]]  || fail "sync script missing: $SYNC_SCRIPT"
[[ -x "$PROBE_SCRIPT" ]] || fail "probe script missing: $PROBE_SCRIPT"
[[ -f "$SCHEMA" ]]       || fail "schema missing: $SCHEMA"

# ---- syntax checks ----
bash -n "$SYNC_SCRIPT"  || fail "sync script syntax"
bash -n "$PROBE_SCRIPT" || fail "probe script syntax"
pass "syntax + presence"

# ---- schema is valid JSON with the right shape ----
jq -e '
  .schema_version=="http://json-schema.org/draft-07/schema#" or .["$schema"]!=null
  and .title=="Flywheel Hook Manifest"
' "$SCHEMA" >/dev/null || fail "schema shape"
pass "schema shape ok"

# ---- isolated test sandbox ----
SANDBOX="$(mktemp -d)"
trap 'rm -rf "$SANDBOX"' EXIT

# fake consumer repo
CONSUMER="$SANDBOX/fake-consumer"
mkdir -p "$CONSUMER/.flywheel" "$CONSUMER/.git"
( cd "$CONSUMER" && git init -q && git config user.email t@t && git config user.name t \
  && touch .gitkeep && git add .gitkeep && git commit -qm init )

# fake install dir
FAKE_INSTALL="$SANDBOX/fake-claude-hooks"
mkdir -p "$FAKE_INSTALL"

# manifest declaring 2 hooks: one tracked + one opted-out
cat >"$CONSUMER/.flywheel/HOOK-MANIFEST.json" <<EOF
{
  "schema_version": "skillos.hook_manifest.v1",
  "repo": {"name":"fake-consumer","path":"$CONSUMER"},
  "canonical_source": {
    "repo": "$HOME/Developer/flywheel",
    "hook_root": ".flywheel/hooks",
    "sync_command": "/flywheel:sync-hooks"
  },
  "consumer_local_hooks_dir": "$FAKE_INSTALL",
  "tracked_hooks": [
    {
      "id": "pretooluse-bash-respawn-max-context-guard",
      "status": "required",
      "canonical_path": ".flywheel/hooks/pretooluse-bash-respawn-max-context-guard.sh",
      "installed_path": "$FAKE_INSTALL/pretooluse-bash-respawn-max-context-guard.sh",
      "install_mode": "copy"
    },
    {
      "id": "ntm-send-goal-redirect",
      "status": "required",
      "canonical_path": ".flywheel/hooks/ntm-send-goal-redirect.sh",
      "installed_path": "$FAKE_INSTALL/ntm-send-goal-redirect.sh",
      "install_mode": "copy"
    }
  ],
  "hook_opt_out": [
    {"id":"ntm-send-goal-redirect","reason":"smoke test verifies opt-out path"}
  ]
}
EOF

# ---- TEST 1: dry-run produces receipt with dashboard_line ----
(
  cd "$CONSUMER"
  "$SYNC_SCRIPT" --dry-run --quiet >/dev/null 2>&1 || fail "dry-run exit non-zero"
)
LATEST=$(ls -t "$CONSUMER/.flywheel/evidence/sync-hooks-"*.json 2>/dev/null | head -1)
[[ -n "$LATEST" ]] || fail "no dry-run receipt"
jq -e '.mode=="dry-run" and (.dashboard_line|type=="string") and (.per_hook|length>=2)' "$LATEST" >/dev/null \
  || fail "dry-run receipt malformed"
# verify nothing installed yet
[[ ! -f "$FAKE_INSTALL/pretooluse-bash-respawn-max-context-guard.sh" ]] || fail "dry-run mutated install dir"
pass "dry-run receipt + no mutations"

# ---- TEST 2: --apply on DIRTY WT refuses ----
echo "unrelated dirty" > "$CONSUMER/unrelated.txt"
( cd "$CONSUMER" && git add unrelated.txt )  # staged but not committed
set +e
(
  cd "$CONSUMER"
  "$SYNC_SCRIPT" --apply --quiet >/dev/null 2>&1
)
RC=$?
set -e
[[ "$RC" == "3" ]] || fail "expected --apply refusal exit 3, got $RC"
LATEST=$(ls -t "$CONSUMER/.flywheel/evidence/sync-hooks-"*.json | head -1)
jq -e '.mode=="apply-refused" and (.refusal_reason|length>0) and (.dirty_files|length>0)' "$LATEST" >/dev/null \
  || fail "refusal receipt malformed"
[[ ! -f "$FAKE_INSTALL/pretooluse-bash-respawn-max-context-guard.sh" ]] || fail "refused --apply still mutated"
pass "dirty-WT --apply refused (exit 3) + no mutation"

# ---- TEST 3: clean WT --apply succeeds ----
( cd "$CONSUMER" && git reset -q HEAD unrelated.txt && rm -f unrelated.txt )
(
  cd "$CONSUMER"
  "$SYNC_SCRIPT" --apply --quiet >/dev/null 2>&1 || fail "clean-WT --apply non-zero"
)
LATEST=$(ls -t "$CONSUMER/.flywheel/evidence/sync-hooks-"*.json | head -1)
jq -e '.mode=="apply" and (.summary.applied_count>=1)' "$LATEST" >/dev/null \
  || fail "apply receipt malformed (no applied)"
[[ -f "$FAKE_INSTALL/pretooluse-bash-respawn-max-context-guard.sh" ]] \
  || fail "tracked hook not installed"

# verify content matches canonical
CANON_SHA=$(shasum -a 256 "$REPO_ROOT/.flywheel/hooks/pretooluse-bash-respawn-max-context-guard.sh" | awk '{print $1}')
INST_SHA=$(shasum -a 256  "$FAKE_INSTALL/pretooluse-bash-respawn-max-context-guard.sh" | awk '{print $1}')
[[ "$CANON_SHA" == "$INST_SHA" ]] || fail "installed sha != canonical sha"

# ---- TEST 4: opted-out hook NOT installed ----
[[ ! -f "$FAKE_INSTALL/ntm-send-goal-redirect.sh" ]] \
  || fail "opted-out hook was installed (should have been skipped)"
jq -e '.opt_out[] | select(.id=="ntm-send-goal-redirect") | .reason | length>0' "$LATEST" >/dev/null \
  || fail "opt-out not recorded in receipt"
pass "clean --apply installed required hook + honored opt-out"

# ---- TEST 5: probe emits valid JSON (scope to sandbox; full fleet probe is slow) ----
# Put the fake consumer under a fleet-root the probe will scan in <1s.
PROBE_FLEET="$SANDBOX/fleet"
mkdir -p "$PROBE_FLEET"
cp -R "$CONSUMER" "$PROBE_FLEET/fake-consumer"
PROBE_OUT="$(FLEET_ROOT="$PROBE_FLEET" "$PROBE_SCRIPT" 2>/dev/null)"
echo "$PROBE_OUT" | jq -e '.fleet_hook_hygiene.summary.total_repos | type=="number"' >/dev/null \
  || fail "probe JSON shape"
DASH_LINE="$(FLEET_ROOT="$PROBE_FLEET" "$PROBE_SCRIPT" --dashboard 2>/dev/null)"
echo "$DASH_LINE" | grep -q 'Hook hygiene' || fail "dashboard line missing keyword"
pass "probe JSON + dashboard line ok"

echo ""
echo "ALL TESTS PASSED"
