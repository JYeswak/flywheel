#!/usr/bin/env bash
# tests/flywheel-docs-canonical-cli.sh
#
# Regression test for flywheel-mv2th (Phase 1 of flywheel-38u3d):
# `flywheel docs init` subcommand + 5-archetype project-type detection.
#
# Substrate class: ~/.claude/skills/.flywheel is Class 1 (Joshua-unmanaged)
# per substrate-boundary-three-class-taxonomy. Direct mutation + paired
# jsm-import-ready patch artifact discipline applies; this test validates
# the mutation didn't break the surface contract.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
FW="$HOME/.claude/skills/.flywheel/bin/flywheel"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

TMP="$(mktemp -d -t flywheel-docs.XXXXXX)"

# Test 1: syntax
if bash -n "$FW" 2>/dev/null; then pass "syntax"; else fail "syntax"; fi

# Test 2: --help enumerates docs subcommand
if "$FW" --help 2>&1 | grep -qE "docs <subcommand>"; then
  pass "--help enumerates docs subcommand"
else fail "docs not in --help"; fi

# Test 3: docs --help shows usage
if "$FW" docs --help 2>&1 | grep -qE "init.*archetype"; then
  pass "docs --help shows init + archetype info"
else fail "docs --help missing key content"; fi

# Test 4: docs init --help shows usage
if "$FW" docs init --help 2>&1 | grep -qE "init.*archetype"; then
  pass "docs init --help shows usage"
else fail "docs init --help missing"; fi

# Test 5: docs init --target /nonexistent returns unknown
out="$("$FW" docs init --target /tmp/nonexistent-dir-2xdi-test 2>&1)"
if printf '%s' "$out" | jq -e '.archetype == "unknown"' >/dev/null 2>&1; then
  pass "docs init on nonexistent dir returns archetype=unknown"
else fail "docs init nonexistent dir: $out"; fi

# Test 6: docs init schema_version stable
if printf '%s' "$out" | jq -e '.schema_version == "flywheel/v1"' >/dev/null 2>&1; then
  pass "docs init emits schema_version=flywheel/v1"
else fail "schema_version mismatch"; fi

# Test 7: rust-lib detection (synthetic fixture)
mkdir -p "$TMP/rust-lib/src"
cat > "$TMP/rust-lib/Cargo.toml" <<'CARGO'
[package]
name = "test-crate"
version = "0.1.0"

[lib]
CARGO
touch "$TMP/rust-lib/src/lib.rs"
arch="$("$FW" docs init --target "$TMP/rust-lib" 2>&1 | jq -r '.archetype')"
if [[ "$arch" == "rust-lib" ]]; then
  pass "rust-lib archetype detected (Cargo.toml + src/lib.rs)"
else fail "rust-lib detection: got $arch"; fi

# Test 8: python-lib detection
mkdir -p "$TMP/python-lib"
cat > "$TMP/python-lib/pyproject.toml" <<'PY'
[project]
name = "test-pylib"
version = "0.1.0"
dependencies = ["numpy"]
PY
arch="$("$FW" docs init --target "$TMP/python-lib" 2>&1 | jq -r '.archetype')"
if [[ "$arch" == "python-lib" ]]; then
  pass "python-lib archetype detected (pyproject.toml, no web deps)"
else fail "python-lib detection: got $arch"; fi

# Test 9: ts-lib detection
mkdir -p "$TMP/ts-lib"
cat > "$TMP/ts-lib/package.json" <<'PKG'
{
  "name": "test-tslib",
  "version": "0.1.0",
  "main": "dist/index.js",
  "exports": "./dist/index.js"
}
PKG
arch="$("$FW" docs init --target "$TMP/ts-lib" 2>&1 | jq -r '.archetype')"
if [[ "$arch" == "ts-lib" ]]; then
  pass "ts-lib archetype detected (package.json with main/exports)"
else fail "ts-lib detection: got $arch"; fi

# Test 10: frontend-spa detection (React)
mkdir -p "$TMP/frontend-spa"
cat > "$TMP/frontend-spa/package.json" <<'PKG'
{
  "name": "test-spa",
  "version": "0.1.0",
  "dependencies": { "react": "^18.0.0", "react-dom": "^18.0.0" }
}
PKG
arch="$("$FW" docs init --target "$TMP/frontend-spa" 2>&1 | jq -r '.archetype')"
if [[ "$arch" == "frontend-spa" ]]; then
  pass "frontend-spa archetype detected (React dep)"
else fail "frontend-spa detection: got $arch"; fi

# Test 11: backend-service detection (Express)
mkdir -p "$TMP/backend-service"
cat > "$TMP/backend-service/package.json" <<'PKG'
{
  "name": "test-backend",
  "version": "0.1.0",
  "dependencies": { "express": "^4.0.0" }
}
PKG
arch="$("$FW" docs init --target "$TMP/backend-service" 2>&1 | jq -r '.archetype')"
if [[ "$arch" == "backend-service" ]]; then
  pass "backend-service archetype detected (Express dep)"
else fail "backend-service detection: got $arch"; fi

# Test 12: --archetype override works
arch="$("$FW" docs init --target "$TMP/rust-lib" --archetype custom-override 2>&1 | jq -r '.archetype')"
if [[ "$arch" == "custom-override" ]]; then
  pass "--archetype override skips detection"
else fail "--archetype override: got $arch"; fi

# Test 13: unknown args rejected
out="$("$FW" docs init --bogus 2>&1 | head -1)"
if printf '%s' "$out" | grep -qiE "ERR:|unknown"; then
  pass "unknown docs init arg rejected"
else fail "unknown arg silently accepted: $out"; fi

# Test 14: docs init mutates_state=false (Phase 1 detection-only)
out="$("$FW" docs init --target "$TMP/rust-lib" 2>&1)"
if printf '%s' "$out" | jq -e '.mutates_state == false' >/dev/null 2>&1; then
  pass "Phase 1 mutates_state=false (detection-only)"
else fail "mutates_state assertion: $out"; fi

# Test 15: cites parent + phase + next_phase
if printf '%s' "$out" | jq -e '.parent_bead == "flywheel-38u3d" and .phase_bead == "flywheel-mv2th" and (.next_phase | startswith("flywheel-ti46c"))' >/dev/null 2>&1; then
  pass "docs init JSON cites parent + phase + next_phase chain"
else fail "phase-chain citation missing"; fi

# Test 16: existing canonical subcommands still work (no regression)
for sub in doctor health audit; do
  if "$FW" "$sub" --json >/dev/null 2>&1; then
    pass "existing subcommand $sub still works (no regression)"
  else fail "existing subcommand $sub broken"; fi
done

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
