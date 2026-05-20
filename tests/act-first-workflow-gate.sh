#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
CLASSIFIER="$ROOT/.flywheel/scripts/act-workflow-classify.sh"
HOOK="$ROOT/.flywheel/hooks/gh-pr-create-act-gate.sh"
DISABLE="$ROOT/.flywheel/scripts/gha-auto-disable-on-local-green.sh"

fail() { printf 'FAIL %s\n' "$*" >&2; exit 1; }
pass() { printf 'PASS %s\n' "$*"; }

TMP="$(mktemp -d -t act-first-gate.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

repo="$TMP/repo"
mkdir -p "$repo/.github/workflows" "$repo/.flywheel/state"
git -C "$repo" init -q

cat >"$repo/.github/workflows/ci.yml" <<'YAML'
name: CI
on:
  pull_request:
jobs:
  test:
    runs-on: ubuntu-22.04
    steps:
      - run: true
YAML

cat >"$repo/.github/workflows/deploy.yml" <<'YAML'
name: Deploy
on:
  workflow_dispatch:
permissions:
  pages: write
jobs:
  deploy:
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/deploy-pages@v4
YAML

"$CLASSIFIER" --repo "$repo" --write --json >"$TMP/classification.json"
jq -e '
  .generated_from_bead == "flywheel-ic6td"
  and any(.workflows[]; .path == ".github/workflows/ci.yml" and .classification == "act-compatible")
  and any(.workflows[]; .path == ".github/workflows/deploy.yml" and .classification == "GHA-only")
' "$TMP/classification.json" >/dev/null || fail "classification shape"
pass "classification distinguishes act-compatible and GHA-only"

event="$(jq -nc --arg cwd "$repo" '{tool_name:"Bash",cwd:$cwd,tool_input:{command:"gh pr create --title t --body b"}}')"
set +e
ACT_GREEN_RECEIPTS="$TMP/receipts.jsonl" "$HOOK" <<<"$event" >"$TMP/hook.out" 2>"$TMP/hook.err"
rc=$?
set -e
[[ "$rc" -eq 2 ]] || fail "hook should block missing receipt rc=$rc"
grep -q 'requires a <24h green local act receipt' "$TMP/hook.err" || fail "hook block message"
pass "gh pr create blocks without local act receipt"

jq -nc --arg repo "$repo" --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  '{schema_version:"flywheel.act_green_receipt.v1",repo:$repo,workflow:".github/workflows/ci.yml",status:"pass",ts:$ts}' >"$TMP/receipts.jsonl"
ACT_GREEN_RECEIPTS="$TMP/receipts.jsonl" "$HOOK" <<<"$event" >/dev/null
pass "gh pr create allows recent green act receipt"

override_event="$(jq -nc --arg cwd "$repo" '{tool_name:"Bash",cwd:$cwd,tool_input:{command:"gh pr create --skip-act-gate=\"fixture override\" --title t --body b"}}')"
ACT_GREEN_RECEIPTS="$TMP/missing.jsonl" ACT_GATE_OVERRIDES="$TMP/overrides.jsonl" "$HOOK" <<<"$override_event" >/dev/null
jq -e '.reason == "fixture override"' "$TMP/overrides.jsonl" >/dev/null || fail "override logged"
pass "override logs audit reason"

cat >"$TMP/runs.json" <<'JSON'
[
  {"databaseId":105,"workflowName":"CI","status":"completed","conclusion":"failure","createdAt":"2026-05-20T20:05:00Z"},
  {"databaseId":104,"workflowName":"CI","status":"completed","conclusion":"failure","createdAt":"2026-05-20T20:04:00Z"},
  {"databaseId":103,"workflowName":"CI","status":"completed","conclusion":"failure","createdAt":"2026-05-20T20:03:00Z"},
  {"databaseId":102,"workflowName":"CI","status":"completed","conclusion":"failure","createdAt":"2026-05-20T20:02:00Z"},
  {"databaseId":101,"workflowName":"CI","status":"completed","conclusion":"failure","createdAt":"2026-05-20T20:01:00Z"}
]
JSON

auto_out="$(ACT_GREEN_RECEIPTS="$TMP/receipts.jsonl" GHA_AUTO_DISABLE_LEDGER="$TMP/disable-ledger.jsonl" \
  "$DISABLE" --repo "$repo" --runs-json "$TMP/runs.json" --classification "$TMP/classification.json" --threshold 5 --json)"
jq -e '.status == "would_disable" and (.actions[0].workflow == "CI") and (.actions[0].workflow_dispatch_preserved == true)' <<<"$auto_out" >/dev/null \
  || fail "auto-disable candidate output"
pass "auto-disable receiver detects N=5 failures with local green evidence"

apply_out="$(ACT_GREEN_RECEIPTS="$TMP/receipts.jsonl" GHA_AUTO_DISABLE_LEDGER="$TMP/disable-ledger.jsonl" \
  "$DISABLE" --repo "$repo" --runs-json "$TMP/runs.json" --classification "$TMP/classification.json" --threshold 5 --apply --json)"
jq -e '.status == "disabled" and (.actions[0].apply_status == "workflow_dispatch_only")' <<<"$apply_out" >/dev/null \
  || fail "auto-disable apply output"
grep -q 'workflow_dispatch:' "$repo/.github/workflows/ci.yml" || fail "workflow_dispatch preserved"
if grep -q 'pull_request:' "$repo/.github/workflows/ci.yml"; then
  fail "pull_request trigger should be removed by auto-disable apply"
fi
pass "auto-disable apply leaves workflow_dispatch only"

printf 'SUMMARY pass=6 fail=0\n'
