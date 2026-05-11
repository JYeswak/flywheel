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

echo "PASS test_ntm_send_with_josh_req_capture_canonical_cli (4/4)"
