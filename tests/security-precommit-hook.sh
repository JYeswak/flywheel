#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
INSTALLER="$ROOT/.flywheel/scripts/security-precommit-installer.sh"
HOOK="$ROOT/githooks/pre-commit"
FIXTURES="$ROOT/tests/fixtures/security-precommit-hook"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/security-precommit-hook.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0

pass() {
  printf 'PASS %s\n' "$1"
  pass_count=$((pass_count + 1))
}

fail() {
  printf 'FAIL %s\n' "$1" >&2
  exit 1
}

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    jq . "$file" >&2 || true
    fail "$label"
  fi
}

need() {
  command -v "$1" >/dev/null 2>&1 || fail "missing command: $1"
}

make_repo() {
  local repo="$1"
  mkdir -p "$repo/.flywheel/scripts" "$repo/.flywheel/security/v1" "$repo/githooks"
  git -C "$repo" init -q
  git -C "$repo" config user.email fixture@example.test
  git -C "$repo" config user.name "Fixture User"
  cp "$INSTALLER" "$repo/.flywheel/scripts/security-precommit-installer.sh"
  cp "$HOOK" "$repo/githooks/pre-commit"
  cp "$ROOT/.flywheel/security/v1/secret-patterns.json" "$repo/.flywheel/security/v1/secret-patterns.json"
  chmod +x "$repo/.flywheel/scripts/security-precommit-installer.sh" "$repo/githooks/pre-commit"
  printf 'baseline\n' >"$repo/README.md"
  git -C "$repo" add README.md
  git -C "$repo" commit -q -m baseline
}

need git
need jq
need python3

bash -n "$INSTALLER" && pass "installer_syntax"
bash -n "$HOOK" && pass "hook_syntax"
[[ -x "$INSTALLER" ]] || fail "installer_not_executable"
[[ -x "$HOOK" ]] || fail "hook_not_executable"

repo="$TMP/repo"
make_repo "$repo"

"$repo/.flywheel/scripts/security-precommit-installer.sh" install --repo "$repo" --dry-run --json >"$TMP/dry-run.json"
assert_jq "$TMP/dry-run.json" '.status == "dry_run" and .planned_hooks_path == "githooks" and .would_set_hooks_path == true' "dry_run_plans_hook_path"
if git -C "$repo" config --local --get core.hooksPath >/dev/null 2>&1; then
  fail "dry_run_mutated_hooks_path"
else
  pass "dry_run_does_not_mutate_hooks_path"
fi

"$repo/.flywheel/scripts/security-precommit-installer.sh" install --repo "$repo" --apply --json >"$TMP/apply.json"
assert_jq "$TMP/apply.json" '.status == "applied" and .hooks_path == "githooks"' "apply_sets_hooks_path"
[[ "$(git -C "$repo" config --local --get core.hooksPath)" == "githooks" ]] || fail "hooks_path_not_githooks"
pass "fixture_sets_core_hooks_path_after_apply"

mkdir -p "$repo/config"
cp "$FIXTURES/safe/.env.example" "$repo/.env.example"
git -C "$repo" add .env.example
git -C "$repo" commit -q -m "safe env example"
pass "safe_synthetic_env_example_passes"

canary_value="CANARY_TEST_AKIA0000000000000000"
printf 'AWS_ACCESS_KEY_ID=%s\n' "$canary_value" >"$repo/config/leaky.env"
git -C "$repo" add config/leaky.env
set +e
git -C "$repo" commit -m "blocked secret fixture" >"$TMP/blocked.out" 2>"$TMP/blocked.err"
blocked_rc=$?
set -e
[[ "$blocked_rc" -ne 0 ]] || fail "staged_fake_secret_should_block_commit"
grep -q '"class": "aws_access_key_id"' "$TMP/blocked.err" || fail "blocked_output_missing_class"
grep -q '"path": "config/leaky.env"' "$TMP/blocked.err" || fail "blocked_output_missing_path"
if grep -F "$canary_value" "$TMP/blocked.out" "$TMP/blocked.err" >/dev/null; then
  fail "blocked_output_echoed_canary_value"
fi
pass "staged_fake_secret_blocks_commit_class_path_only"
git -C "$repo" reset -q HEAD config/leaky.env

chain_repo="$TMP/chain-repo"
make_repo "$chain_repo"
mkdir -p "$chain_repo/.git/hooks"
cat >"$chain_repo/.git/hooks/pre-commit" <<'SH'
#!/usr/bin/env bash
printf 'chain-ran\n' >>"$CHAIN_MARKER"
SH
chmod +x "$chain_repo/.git/hooks/pre-commit"
CHAIN_MARKER="$TMP/chain.marker" "$chain_repo/.flywheel/scripts/security-precommit-installer.sh" install --repo "$chain_repo" --apply --json >"$TMP/chain-apply.json"
assert_jq "$TMP/chain-apply.json" '.chain_configured == true and (.backup_path | length > 0)' "existing_hook_is_backed_up_and_chained"
printf 'safe\n' >"$chain_repo/safe.txt"
git -C "$chain_repo" add safe.txt
CHAIN_MARKER="$TMP/chain.marker" git -C "$chain_repo" commit -q -m "chain safe"
grep -q 'chain-ran' "$TMP/chain.marker" || fail "chained_hook_did_not_run"
pass "existing_hook_preserved_or_chained_with_backup"

"$repo/.flywheel/scripts/security-precommit-installer.sh" doctor --repo "$repo" --json >"$TMP/doctor.json"
assert_jq "$TMP/doctor.json" '.status == "pass" and .hooks_path == "githooks" and .committed_hook_executable == true' "doctor_reports_installed"

printf 'PASS security-precommit-hook tests=%s\n' "$pass_count"
