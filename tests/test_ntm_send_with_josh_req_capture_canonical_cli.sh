#!/usr/bin/env bash
# Canonical-CLI smoke test for ntm-send-with-josh-req-capture.sh
# (bead flywheel-2xdi.158 — wire the wrapper into the test-callsite corpus so
# the wired-but-cold detector recognizes it via tests/ auto-allowlist + the
# 8th flywheel_script_bodies_index corpus).
#
# The wrapper is a Codex-runtime parity tool for ntm send + josh_request_id
# capture (schema-v2 JSONL side-effect). It is invoked on-demand by Codex
# workers when a dispatch packet carries a non-null josh_request_id. This
# smoke test exercises the read-only canonical-cli surface (--info, --schema,
# --doctor, --help) so a regression in those four flags is caught.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/ntm-send-with-josh-req-capture.sh"

if [[ ! -x "$SCRIPT" ]]; then
  echo "FAIL ntm-send-with-josh-req-capture.sh missing or not executable at $SCRIPT" >&2
  exit 2
fi

TMP="$(mktemp -d -t ntm-jrc.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

# AG1: --info --json returns parseable JSON with version + schema_version
"$SCRIPT" --info --json >"$TMP/info.json" 2>"$TMP/info.err"
if ! jq -e '.version and .schema_version' "$TMP/info.json" >/dev/null 2>&1; then
  echo "FAIL --info --json missing version or schema_version" >&2
  cat "$TMP/info.json" "$TMP/info.err" >&2
  exit 1
fi
echo "PASS AG1 --info --json returns version + schema_version"

# AG2: --schema --json returns row_required_fields contract
"$SCRIPT" --schema --json >"$TMP/schema.json" 2>"$TMP/schema.err"
if ! jq -e '.schema_version and (.row_required_fields | type == "array")' "$TMP/schema.json" >/dev/null 2>&1; then
  echo "FAIL --schema --json missing required structure" >&2
  cat "$TMP/schema.json" "$TMP/schema.err" >&2
  exit 1
fi
echo "PASS AG2 --schema --json returns row_required_fields"

# AG3: --doctor --json returns mode + ntm_bin self-health
"$SCRIPT" --doctor --json >"$TMP/doctor.json" 2>"$TMP/doctor.err" || true
if ! jq -e '.mode == "doctor" and (.ntm_bin | type == "string")' "$TMP/doctor.json" >/dev/null 2>&1; then
  echo "FAIL --doctor --json missing mode or ntm_bin" >&2
  cat "$TMP/doctor.json" "$TMP/doctor.err" >&2
  exit 1
fi
echo "PASS AG3 --doctor --json returns mode + ntm_bin path"

# AG4: --help emits usage banner with the 5 canonical flags/subcommands
"$SCRIPT" --help >"$TMP/help.txt" 2>&1 || true
for flag in "send" "--capture-only" "--doctor" "--info" "--schema"; do
  if ! grep -q -- "$flag" "$TMP/help.txt"; then
    echo "FAIL --help missing $flag" >&2
    cat "$TMP/help.txt" >&2
    exit 1
  fi
done
echo "PASS AG4 --help mentions send + --capture-only + --doctor + --info + --schema"

# AG5: terse operator requests such as "check it" are request-shaped.
state_dir="$TMP/state"
state_file="$state_dir/josh-requests.jsonl"
JOSH_REQUEST_STATE_DIR="$state_dir" \
JOSH_REQUEST_STATE_FILE="$state_file" \
JOSH_REQUEST_NOW="2026-05-11T20:44:34Z" \
  "$SCRIPT" --capture-only --json --session alpsinsurance --pane 7 --from "fixture-check-it" "check it" >"$TMP/check-it.json" 2>"$TMP/check-it.err"
if ! jq -e '.capture == "captured" and (.id | test("^jr-2026-05-11T204434Z"))' "$TMP/check-it.json" >/dev/null 2>&1; then
  echo "FAIL --capture-only did not capture terse check request" >&2
  cat "$TMP/check-it.json" "$TMP/check-it.err" >&2
  exit 1
fi
if ! jq -e '.source_session == "alpsinsurance" and .source_pane == 7 and .source_message_id == "fixture-check-it" and .sanitized_excerpt == "check it"' "$state_file" >/dev/null 2>&1; then
  echo "FAIL captured row missing expected check-it provenance" >&2
  cat "$state_file" >&2
  exit 1
fi
echo "PASS AG5 --capture-only captures terse check requests"

# AG6: current plain-language operator verbs stay aligned with transcript capture.
JOSH_REQUEST_STATE_DIR="$state_dir" \
JOSH_REQUEST_STATE_FILE="$state_file" \
JOSH_REQUEST_NOW="2026-05-15T04:04:02Z" \
  "$SCRIPT" --capture-only --json --session mobile-eats --pane 14 --from "fixture-deploy" \
  "deploy it on vercel at mobile-eats.zeststream.ai so I can look at it and teste - give me a set of instructions" >"$TMP/deploy.json" 2>"$TMP/deploy.err"
JOSH_REQUEST_STATE_DIR="$state_dir" \
JOSH_REQUEST_STATE_FILE="$state_file" \
JOSH_REQUEST_NOW="2026-05-15T04:10:19Z" \
  "$SCRIPT" --capture-only --json --session clutterfreespaces --pane 12 --from "fixture-continue" \
  "actually if we're scoring that high - just continue the show" >"$TMP/continue.json" 2>"$TMP/continue.err"
JOSH_REQUEST_STATE_DIR="$state_dir" \
JOSH_REQUEST_STATE_FILE="$state_file" \
JOSH_REQUEST_NOW="2026-05-15T04:08:00Z" \
  "$SCRIPT" --capture-only --json --session flywheel --pane 2 --from "fixture-do-you" \
  "do you have the goal set to call you back at pane 0 now and then to keep you involved and updated?" >"$TMP/do-you.json" 2>"$TMP/do-you.err"
for name in deploy continue do-you; do
  if ! jq -e '.capture == "captured"' "$TMP/$name.json" >/dev/null 2>&1; then
    echo "FAIL --capture-only did not capture $name operator request" >&2
    cat "$TMP/$name.json" "$TMP/$name.err" >&2
    exit 1
  fi
done
echo "PASS AG6 --capture-only captures current plain-language operator verbs"

echo "PASS test_ntm_send_with_josh_req_capture_canonical_cli (6/6)"
