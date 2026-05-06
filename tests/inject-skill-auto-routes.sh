#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
BIN="${SKILL_AUTO_ROUTES_BIN:-$HOME/.claude/commands/flywheel/_shared/inject-skill-auto-routes.sh}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/skill-auto-routes.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

write_body() {
  local name="$1" text="$2"
  printf '%s\n' "$text" >"$TMP/$name.md"
}

run_case() {
  local name="$1" expected="$2" unexpected="${3:-}"
  "$BIN" "$TMP/$name.md" "$name" >"$TMP/$name.out"
  if rg -q '^## SKILL AUTO-ROUTES$' "$TMP/$name.out" &&
    rg -q "skill_auto_routes_matched=.*${expected}" "$TMP/$name.out"; then
    if [[ -n "$unexpected" ]] && rg -q "^skill_auto_routes_matched=.*${unexpected}" "$TMP/$name.out"; then
      fail "$name unexpected route $unexpected"
    else
      pass "$name routes $expected"
    fi
  else
    fail "$name routes $expected"
  fi
}

assert_contains() {
  local file="$1" pattern="$2" name="$3"
  if rg -q "$pattern" "$file"; then pass "$name"; else fail "$name"; fi
}

assert_same_hash() {
  local file="$1" before after
  before="$(shasum "$file" | awk '{print $1}')"
  "$BIN" "$file" hash-check >"$TMP/hash-check.out"
  after="$(shasum "$file" | awk '{print $1}')"
  if [[ "$before" == "$after" ]]; then pass "input file not mutated"; else fail "input file not mutated"; fi
}

write_body rust 'Touch src/lib.rs and Cargo.toml; run cargo fmt, cargo clippy, and cargo test.'
write_body python 'Modify scripts/thing.py with pyproject.toml, pytest, ruff, black, and type hints.'
write_body cli 'Build an operator CLI subcommand with --help, --json, doctor, health, repair, and flags.'
write_body readme 'Update README.md public docs with Quick Start and limitations.'
write_body multi 'Ship a Rust CLI README: Cargo.toml, src/main.rs, --help, and public-facing README examples.'
write_body zero 'Investigate queue shape and summarize findings without code, flags, docs, or language files.'

run_case rust 'rust-best-practices' 'python-best-practices'
run_case python 'python-best-practices' 'rust-best-practices'
run_case cli 'canonical-cli-scoping' 'rust-best-practices'
run_case readme 'readme-writing' 'python-best-practices'
run_case multi 'canonical-cli-scoping,rust-best-practices,readme-writing'

"$BIN" "$TMP/zero.md" zero >"$TMP/zero.out"
assert_contains "$TMP/zero.out" '^skill_auto_routes=0$' "zero match emits explicit zero"
assert_contains "$TMP/zero.out" 'skill_auto_routes_addressed=canonical-cli-scoping=n/a,rust-best-practices=n/a,python-best-practices=n/a,readme-writing=n/a' "zero match emits callback field"

assert_contains "$TMP/rust.out" 'cargo fmt -- --check' "rust excerpt injected"
assert_contains "$TMP/python.out" 'public function signatures have type hints' "python excerpt injected"
assert_contains "$TMP/cli.out" 'doctor / health / repair triad' "cli excerpt injected"
assert_contains "$TMP/readme.out" 'Quick Start stays copy-pasteable' "readme excerpt injected"
assert_contains "$TMP/multi.out" 'source=/Users/josh/.claude/skills/readme-writing/SKILL.md:120' "multi source cites readme skill"

assert_same_hash "$TMP/multi.md"

SKILL_AUTO_ROUTES_DISABLED=1 "$BIN" "$TMP/cli.md" disabled >"$TMP/disabled.out"
if cmp -s "$TMP/cli.md" "$TMP/disabled.out"; then
  pass "disabled passthrough unchanged"
else
  fail "disabled passthrough unchanged"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
  exit 1
fi

printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
