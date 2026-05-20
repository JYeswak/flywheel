#!/usr/bin/env bash
# tests/respawn-max-context-guard-smoke.sh
#
# Smoke test for ~/.claude/hooks/pretooluse-bash-respawn-max-context-guard.sh
#
# Strategy: the hook honors $NTM_BIN. We point it at a fake ntm shim whose
# --robot-tail output we control. We invoke the hook directly with synthetic
# PreToolUse JSON on stdin and assert:
#   (1) REFUSAL when scrollback contains "100% context used"
#   (2) ALLOW + ledger append when --force-max-context-override is present
#   (3) ALLOW when scrollback is clean
#   (4) ALLOW (exit 0) when command is not `ntm respawn`
#   (5) FAIL-OPEN when probe shim crashes
#
# Exit 0 on all-pass; non-zero on any failure.

set -euo pipefail

HOOK="/Users/josh/.claude/hooks/pretooluse-bash-respawn-max-context-guard.sh"
[[ -x "$HOOK" ]] || { echo "FAIL: hook not executable at $HOOK"; exit 1; }

TMPDIR=$(mktemp -d -t respawn-guard-smoke.XXXXXX)
trap 'rm -rf "$TMPDIR"' EXIT

# Use isolated ledger
export HOME_REAL="$HOME"
export HOME="$TMPDIR/home"
mkdir -p "$HOME/.local/state/flywheel"
LEDGER="$HOME/.local/state/flywheel/respawn-max-context-overrides.jsonl"

# Build fake ntm shim
SHIM_DIR="$TMPDIR/bin"
mkdir -p "$SHIM_DIR"
SHIM="$SHIM_DIR/ntm"

make_shim() {
  local mode="$1"
  case "$mode" in
    max-context)
      cat > "$SHIM" <<'EOF'
#!/usr/bin/env bash
# Always returns scrollback containing "100% context used"
cat <<JSON
{"panes":{"1":{"lines":["some chatter","compacting context","100% context used. Auto-compact pending."]}}}
JSON
EOF
      ;;
    clean)
      cat > "$SHIM" <<'EOF'
#!/usr/bin/env bash
cat <<JSON
{"panes":{"1":{"lines":["codex>","Working on bead foo-123","done."]}}}
JSON
EOF
      ;;
    crash)
      cat > "$SHIM" <<'EOF'
#!/usr/bin/env bash
echo "ntm: catastrophic failure" >&2
exit 99
EOF
      ;;
  esac
  chmod +x "$SHIM"
}

export NTM_BIN="$SHIM"

mkjson() {
  # $1 = command string
  jq -nc --arg cmd "$1" '{tool_name:"Bash", tool_input:{command:$cmd}}'
}

run_hook() {
  local payload="$1"
  set +e
  out=$(printf '%s' "$payload" | "$HOOK" 2>&1)
  rc=$?
  set -e
  echo "$out"
  return $rc
}

FAILS=0
pass() { echo "  PASS: $1"; }
fail() { echo "  FAIL: $1"; FAILS=$((FAILS+1)); }

echo "== Test 1: REFUSAL on max-context scrollback =="
make_shim max-context
payload=$(mkjson "ntm respawn zesttube --panes=1 --force")
set +e
output=$(printf '%s' "$payload" | "$HOOK" 2>&1)
rc=$?
set -e
if [[ $rc -eq 2 ]] && echo "$output" | grep -q "BLOCKED"; then
  pass "exit 2 + BLOCKED message"
else
  fail "expected exit 2 + BLOCKED; got rc=$rc output=$output"
fi

echo "== Test 2: ALLOW + ledger on --force-max-context-override =="
make_shim max-context
rm -f "$LEDGER"
payload=$(mkjson 'ntm respawn zesttube --panes=1 --force --force-max-context-override="smoke-test"')
set +e
output=$(printf '%s' "$payload" | "$HOOK" 2>&1)
rc=$?
set -e
if [[ $rc -eq 0 ]]; then
  pass "exit 0 with override"
else
  fail "expected exit 0 with override; got rc=$rc output=$output"
fi
if [[ -s "$LEDGER" ]] && grep -q "smoke-test" "$LEDGER"; then
  pass "override logged to ledger"
else
  fail "ledger missing or no smoke-test entry (ledger=$LEDGER)"
fi

echo "== Test 3: ALLOW on clean scrollback =="
make_shim clean
payload=$(mkjson "ntm respawn flywheel --panes=2")
set +e
output=$(printf '%s' "$payload" | "$HOOK" 2>&1)
rc=$?
set -e
if [[ $rc -eq 0 ]]; then
  pass "exit 0 on clean scrollback"
else
  fail "expected exit 0 on clean; got rc=$rc output=$output"
fi

echo "== Test 4: PASS-THROUGH on non-respawn command =="
make_shim max-context
payload=$(mkjson "ls -la /tmp")
set +e
output=$(printf '%s' "$payload" | "$HOOK" 2>&1)
rc=$?
set -e
if [[ $rc -eq 0 ]]; then
  pass "exit 0 on non-respawn"
else
  fail "expected exit 0 on non-respawn; got rc=$rc output=$output"
fi

echo "== Test 5: FAIL-OPEN when probe crashes =="
make_shim crash
payload=$(mkjson "ntm respawn zesttube --panes=1 --force")
set +e
output=$(printf '%s' "$payload" | "$HOOK" 2>&1)
rc=$?
set -e
if [[ $rc -eq 0 ]]; then
  pass "exit 0 on probe crash (fail-open)"
else
  fail "expected fail-open exit 0; got rc=$rc output=$output"
fi

echo ""
if [[ $FAILS -eq 0 ]]; then
  echo "All smoke checks PASSED."
  exit 0
else
  echo "$FAILS smoke check(s) FAILED."
  exit 1
fi
