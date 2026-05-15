#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
LOOP="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
NOTIFY="$ROOT/.flywheel/scripts/skillos-notify.py"
TMP="$(mktemp -d -t 5hnh.XXXXXX)"
export TMP
trap 'python3 -c "import os, shutil; shutil.rmtree(os.environ[\"TMP\"], ignore_errors=True)"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

ledger="$TMP/state/skill-discoveries.jsonl"
topology="$TMP/state/session-topology.jsonl"
threads="$TMP/state/threads.jsonl"
mkdir -p "$TMP/state"

export FLYWHEEL_SKILL_DISCOVERY_PATH="$ledger"
export APPEND_SAFE_WRITE="$ROOT/.flywheel/scripts/append-safe-write.sh"

synthetic_bearer="Bearer fixture.synthetic-token-123"
synthetic_registration="registration_token=fixtureabcdefghijklmnopqrstuvwxyz123456"
redacted_evidence="{\"source\":\"fixture\",\"excerpt\":\"[SCRUBBED:bearer_token] [SCRUBBED:registration_token]\"}"

"$LOOP" skill-discovery append \
  --candidate-skill-name token-safe-skill-discovery \
  --discovery-kind skill-search-miss \
  --session flywheel \
  --worker-pane 4 \
  --worker-kind codex \
  --task-context "secret scrub fixture" \
  --evidence-json "$redacted_evidence" \
  --promotion-signal scrubbed_fixture \
  --should-become skill-candidate \
  --json >"$TMP/append.json"
assert_jq "$TMP/append.json" '.dry_run == false and .row.evidence.excerpt == "[SCRUBBED:bearer_token] [SCRUBBED:registration_token]"' "append_stores_redacted_evidence"
if grep -F "$synthetic_bearer" "$ledger" >/dev/null || grep -F "$synthetic_registration" "$ledger" >/dev/null; then
  fail "raw_synthetic_token_absent_from_storage"
else
  pass "raw_synthetic_token_absent_from_storage"
fi

jq -nc '{session:"skillos",effective_at:"2026-05-08T00:00:00Z",orchestrator_pane:4,repo_path:"$HOME/Developer/skillos"}' >"$topology"
"$NOTIFY" \
  --topology "$topology" \
  --thread-state "$threads" \
  --candidate-skill-name token-safe-skill-discovery \
  --discovery-id "$(jq -r '.row.discovery_id' "$TMP/append.json")" \
  --source-session flywheel \
  --message-note "synthetic $synthetic_bearer $synthetic_registration" \
  --dry-run \
  --json >"$TMP/notify.json"
assert_jq "$TMP/notify.json" '.status == "dry_run" and .token_safety.raw_token_patterns_found >= 2 and .token_safety.agent_mail_token_echo == false and (.message | contains("[SCRUBBED:bearer_token]"))' "notify_redacts_token_shaped_message"
if grep -F "$synthetic_bearer" "$TMP/notify.json" >/dev/null || grep -F "$synthetic_registration" "$TMP/notify.json" >/dev/null; then
  fail "raw_synthetic_token_absent_from_notify_output"
else
  pass "raw_synthetic_token_absent_from_notify_output"
fi

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
