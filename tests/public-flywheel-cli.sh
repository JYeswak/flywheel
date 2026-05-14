#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
BIN="$ROOT/bin/flywheel"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/public-flywheel-cli.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
  fi
}

mkdir -p "$TMP/repo"

bash -n "$BIN" && pass "syntax" || fail "syntax"

"$BIN" --examples >"$TMP/examples.json"
assert_jq "$TMP/examples.json" '.command == "examples" and (.examples | length) >= 5' "examples"

"$BIN" quickstart --json >"$TMP/quickstart.json"
assert_jq "$TMP/quickstart.json" '.command == "quickstart" and .status == "ok" and (.steps | length) >= 5' "quickstart"

"$BIN" help repair --json >"$TMP/help.json"
assert_jq "$TMP/help.json" '.command == "help" and .topic == "repair" and (.text | test("dry-run"))' "help_topic"

"$BIN" init --repo "$TMP/repo" --json >"$TMP/init.json"
assert_jq "$TMP/init.json" '.command == "init" and .status == "initialized"' "init"

"$BIN" repair --scope reduced --repo "$TMP/repo" --dry-run --json >"$TMP/repair.json"
assert_jq "$TMP/repair.json" '.command == "repair" and .dry_run == true and (.actual_actions | length) == 0' "repair_dry_run"

"$BIN" validate repo --repo "$TMP/repo" --json >"$TMP/validate-repo.json"
assert_jq "$TMP/validate-repo.json" '.command == "doctor" and .status == "pass"' "validate_repo"

"$BIN" dispatch --repo "$TMP/repo" --simulate --json >"$TMP/dispatch.json"
assert_jq "$TMP/dispatch.json" '.command == "dispatch" and .real_dispatch == false' "dispatch"

"$BIN" validate receipt --repo "$TMP/repo" --file .flywheel/last_closeout_receipt.json --json >"$TMP/validate-receipt.json"
assert_jq "$TMP/validate-receipt.json" '.command == "validate-receipt" and .status == "pass"' "validate_receipt"

"$BIN" audit --repo "$TMP/repo" --json >"$TMP/audit.json"
assert_jq "$TMP/audit.json" '.command == "audit" and .writes_are_repo_local == true and (.mutation_ledgers | length) >= 2' "audit"

"$BIN" why flywheel-dgqp9 --json >"$TMP/why.json"
assert_jq "$TMP/why.json" '.command == "why" and .id == "flywheel-dgqp9" and (.provenance | length) >= 2' "why"

"$BIN" completion bash >"$TMP/completion.bash"
if rg -q 'complete -F _flywheel_completion flywheel' "$TMP/completion.bash"; then
  pass "completion_bash"
else
  fail "completion_bash"
fi

bash "$HOME/.claude/skills/canonical-cli-scoping/scripts/check-cli-scoping.sh" "$BIN" >"$TMP/check-cli.txt"
if rg -q 'Summary: 13 pass, 0 fail' "$TMP/check-cli.txt"; then
  pass "canonical_cli_scoping"
else
  cat "$TMP/check-cli.txt" >&2
  fail "canonical_cli_scoping"
fi

if [[ "$fail_count" -ne 0 ]]; then
  printf 'FAIL public-flywheel-cli pass=%s fail=%s\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'PASS public-flywheel-cli pass=%s fail=0\n' "$pass_count"
