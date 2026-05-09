#!/usr/bin/env bash
# tests/identity_py_parity_fixture.sh
#
# Behavior-parity fixture for ~/.claude/skills/.flywheel/lib/portable/identity.d/identity.py
# (1098 lines, allow-large 2.7x cited in flywheel-hzsro audit pack).
#
# Bead: flywheel-cg1i9 (Phase 3 of flywheel-hzsro split-plan: file 2/3 fixture).
# Plan: .flywheel/audit/flywheel-hzsro/split-plan.md File 2 (1098 → 6 sub-modules
# via re-export pattern).
#
# Phase-3 scope: capture the JSON output shape this script produces under a
# controlled fixture environment so the post-split version (identity.py +
# 5 new sibling modules with re-export of the public API) can be verified
# against the same shape. Records pass/fail, not byte-equivalence — exact
# bytes will differ across runs because timestamps and project keys vary.
#
# Companion: split-plan File 2 caveat about identity.py being a callable
# module (re-export pattern needed to preserve caller imports — 32+
# call-sites would otherwise need updating).
#
# Mirrors tests/loop_driver_doctor_json_parity_fixture.sh from Phase 1
# (flywheel-n5wa5).
#
# Usage:
#   bash tests/identity_py_parity_fixture.sh
#   bash tests/identity_py_parity_fixture.sh --record-baseline   # write a fresh baseline
#   bash tests/identity_py_parity_fixture.sh --check-shape       # default: shape-parity only

set -euo pipefail

SCRIPT_PATH="${IDENTITY_PY_PATH:-$HOME/.claude/skills/.flywheel/lib/portable/identity.d/identity.py}"
[[ -f "$SCRIPT_PATH" ]] || { echo "FAIL target script missing: $SCRIPT_PATH" >&2; exit 1; }

mode="check-shape"
case "${1:-}" in
  --record-baseline) mode="record-baseline";;
  --check-shape|"") mode="check-shape";;
  *) echo "usage: $0 [--record-baseline|--check-shape]" >&2; exit 2;;
esac

TMP="$(mktemp -d -t identity-py-fixture.XXXXXX)"
trap 'find "$TMP" -mindepth 1 -delete 2>/dev/null; rmdir "$TMP" 2>/dev/null || true' EXIT

# Build a minimal fixture environment isolated from real identity registry.
# - HOME is overridden so save_row()/all_rows() touch ONLY $TMP state dirs.
# - FLYWHEEL_SESSION_TOPOLOGY points at a synthetic empty topology.
mkdir -p "$TMP/.local/state/flywheel/agent-mail/sessions" \
         "$TMP/.local/state/flywheel/agent-mail/tokens"
synth_topology="$TMP/session-topology.jsonl"
: >"$synth_topology"

run_isolated() {
  HOME="$TMP" \
  FLYWHEEL_SESSION_TOPOLOGY="$synth_topology" \
  python3 "$SCRIPT_PATH" "$@"
}

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" >/dev/null 2>&1 <"$file"; then
    printf 'PASS %s\n' "$label"
  else
    printf 'FAIL %s\n' "$label" >&2
    printf '  filter=%s\n' "$filter" >&2
    jq . <"$file" >&2 2>/dev/null || cat "$file" >&2
    return 1
  fi
}

# --- Surface 1: --schema (static) ---
schema_out="$TMP/schema.json"
set +e
run_isolated --schema >"$schema_out" 2>"$TMP/schema.err"
schema_rc=$?
set -e
if [[ "$schema_rc" -ne 0 ]]; then
  echo "FAIL --schema rc=$schema_rc" >&2
  cat "$TMP/schema.err" >&2
  exit 1
fi
assert_jq "$schema_out" '.["$id"] // .id // ."$schema" // empty | length > 0' "--schema emits valid JSON envelope"

# --- Surface 2: --examples (static) ---
ex_out="$TMP/examples.txt"
set +e
run_isolated --examples >"$ex_out" 2>"$TMP/examples.err"
ex_rc=$?
set -e
[[ "$ex_rc" -eq 0 ]] || { echo "FAIL --examples rc=$ex_rc" >&2; cat "$TMP/examples.err" >&2; exit 1; }
if grep -q -- "--register" "$ex_out" \
  && grep -q -- "--preallocate-workers" "$ex_out" \
  && grep -q -- "--doctor" "$ex_out"; then
  echo "PASS --examples cites --register, --preallocate-workers, --doctor"
else
  echo "FAIL --examples missing one of --register / --preallocate-workers / --doctor" >&2
  cat "$ex_out" >&2
  exit 1
fi

# --- Surface 3: resolve (default) under fixture HOME ---
# Fresh-resolve path returns the 17-key fixture row from the empty-registry
# branch (lines 449-467 of identity.py).
resolve_out="$TMP/resolve.json"
set +e
run_isolated --session fixture-session --pane 99 --json >"$resolve_out" 2>"$TMP/resolve.err"
resolve_rc=$?
set -e
[[ "$resolve_rc" -eq 0 ]] || { echo "FAIL resolve rc=$resolve_rc" >&2; cat "$TMP/resolve.err" >&2; exit 1; }

# Required top-level keys for fresh-resolve (empty registry + empty topology)
required_resolve_keys=(
  schema_version
  session
  pane
  role
  identity_name
  token_path
  token_sha256
  registered_ts
  last_used_ts
  fleet_mail_project_key
  predecessor_identity
  rotation_reason
  status
  identity_resolved
  agent_mail_ready
  proposed_identity
  joshua_disposes_required
)
missing=()
for k in "${required_resolve_keys[@]}"; do
  if ! jq -e --arg k "$k" 'has($k)' >/dev/null 2>&1 <"$resolve_out"; then
    missing+=("$k")
  fi
done
if [[ "${#missing[@]}" -gt 0 ]]; then
  echo "FAIL resolve missing keys: ${missing[*]}" >&2
  jq . <"$resolve_out" >&2 || cat "$resolve_out" >&2
  exit 1
fi
echo "PASS resolve emits 17 fresh-resolve top-level keys"

assert_jq "$resolve_out" '.schema_version | startswith("agent-mail-identity-registry/")' "resolve schema_version starts with agent-mail-identity-registry/"
assert_jq "$resolve_out" '.session == "fixture-session" and .pane == 99' "resolve echoes session+pane"
assert_jq "$resolve_out" '.status == "needs_registration"' "resolve fresh-empty status=needs_registration"
assert_jq "$resolve_out" '.joshua_disposes_required == true' "resolve fresh-empty requires joshua_disposes"

# --- Surface 4: --doctor under fixture HOME (empty registry → known shape) ---
doctor_out="$TMP/doctor.json"
set +e
run_isolated --doctor --json >"$doctor_out" 2>"$TMP/doctor.err"
doctor_rc=$?
set -e
[[ "$doctor_rc" -eq 0 ]] || { echo "FAIL --doctor rc=$doctor_rc" >&2; cat "$TMP/doctor.err" >&2; exit 1; }
assert_jq "$doctor_out" '.schema_version | length > 0' "--doctor emits schema_version"
assert_jq "$doctor_out" 'has("rows") and (.rows | type == "array")' "--doctor emits rows array"

# --- baseline recording ---
if [[ "$mode" == "record-baseline" ]]; then
  baseline="$HOME/.claude/skills/.flywheel/lib/portable/identity.d/identity.parity-baseline.json"
  jq -n \
    --slurpfile resolve "$resolve_out" \
    --slurpfile doctor "$doctor_out" \
    '{resolve:$resolve[0],doctor:$doctor[0]}' >"$baseline"
  echo "RECORDED baseline: $baseline"
fi

echo "PASS rc=0 across --schema / --examples / resolve / --doctor under fixture env"
echo "identity.py shape-parity fixture passed"
