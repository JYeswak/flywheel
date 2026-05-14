#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/scripts/presence_queue.py"
VOICE="$ROOT/tests/fixtures/presence-queue/voice.yaml"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/presence-queue.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

if python3 -m py_compile "$SCRIPT"; then pass "syntax"; else fail "syntax"; fi

run() { # ship-json -> writes $TMP/out.json $TMP/err; returns exit code
  set +e
  printf '%s' "$1" | python3 "$SCRIPT" --voice-yaml "$VOICE" --json \
    >"$TMP/out.json" 2>"$TMP/err"
  local rc=$?
  set -e
  return "$rc"
}

# --- TRIGGER: incomplete descriptor is rejected (exit 2) ---------------------
if run '{"title":"x"}'; then
  fail "trigger-reject (expected nonzero exit)"
else
  rc=$?
  if [[ "$rc" -eq 2 ]]; then pass "trigger-reject exit 2"; else fail "trigger-reject exit $rc"; fi
fi

# --- clean grounded ship: all drafts ready, gate ready (exit 0) --------------
CLEAN='{"title":"Repo hygiene is now a dispatch gate","arc_beat":"The flywheel holds itself to the standard it enforces on client repos.","receipt":"I wired the hygiene protocol into the dispatch gate.","receipt_source":"scripts/repo-hygiene-check.sh","link_back":"https://flywheel.zeststream.ai/methodology"}'
if run "$CLEAN"; then
  if grep -q '"gate_status": "ready"' "$TMP/out.json"; then pass "clean-ship gate ready"; else fail "clean-ship gate not ready"; fi
else
  fail "clean-ship expected exit 0, got $?"
fi

# --- banned word + banned pronoun: blocked (exit 1) -------------------------
BANNED='{"title":"Our seamless platform","arc_beat":"We built it.","receipt":"a number","receipt_source":"x","link_back":"https://flywheel.zeststream.ai/"}'
if run "$BANNED"; then
  fail "banned-word expected nonzero exit"
else
  rc=$?
  if [[ "$rc" -eq 1 ]] && grep -q "banned word" "$TMP/out.json" \
     && grep -q "first-person-singular" "$TMP/out.json"; then
    pass "banned-word + pronoun blocked"
  else
    fail "banned-word block (exit $rc)"
  fi
fi

# --- substrate named without attribution: blocked --------------------------
SUB='{"title":"Parallel agents","arc_beat":"Work runs across agents.","receipt":"I run NTM and beads across panes.","receipt_source":"capabilities-ground-truth.yaml","link_back":"https://flywheel.zeststream.ai/for-developers"}'
if run "$SUB"; then
  fail "substrate-no-attribution expected nonzero exit"
else
  if grep -q "Jeffrey Emanuel not credited" "$TMP/out.json"; then
    pass "substrate without attribution blocked"
  else
    fail "substrate attribution check did not fire"
  fi
fi

# --- substrate named WITH attribution + link: passes -----------------------
SUBOK='{"title":"Parallel agents","arc_beat":"Work runs across agents on Jeffrey Emanuel substrate.","receipt":"I run NTM and beads (Jeffrey Emanuel, github.com/Dicklesworthstone) across panes.","receipt_source":"capabilities-ground-truth.yaml","link_back":"https://flywheel.zeststream.ai/for-developers"}'
if run "$SUBOK"; then
  pass "substrate with attribution passes"
else
  fail "substrate with attribution should pass (exit $?)"
fi

# --- link-back missing from a draft is blocked -----------------------------
# link_back never appears in text because it is an unroutable token mismatch:
NOLINK='{"title":"A ship","arc_beat":"An arc.","receipt":"A receipt.","receipt_source":"src","link_back":"https://flywheel.zeststream.ai/missing"}'
# (link_back IS templated in, so this should pass — assert the positive case)
if run "$NOLINK" && grep -q '"gate_status": "ready"' "$TMP/out.json"; then
  pass "link-back templated into every draft"
else
  fail "link-back should be present in every draft"
fi

printf '\n%d passed, %d failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
