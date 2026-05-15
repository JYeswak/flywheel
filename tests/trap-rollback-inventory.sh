#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/trap-rollback-inventory.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/trap-inventory.XXXXXX")"
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
    jq . "$file" >&2 || true
  fi
}

if bash -n "$SCRIPT"; then
  pass "syntax"
else
  fail "syntax"
fi

"$SCRIPT" --info --json >"$TMP/info.json"
assert_jq "$TMP/info.json" '.name == "trap-rollback-inventory.sh" and .read_only == true and .mutates_state == false and .bead == "flywheel-3kq.1"' "info envelope"

"$SCRIPT" --schema --json >"$TMP/schema.json"
assert_jq "$TMP/schema.json" '.schema_version == "flywheel.trap_rollback_inventory.v1" and (.required | index("scan_scope")) and (.required | index("mutating_like_without_exit_or_err_trap"))' "schema envelope"

"$SCRIPT" --examples --json >"$TMP/examples.json"
assert_jq "$TMP/examples.json" '.examples | length >= 3' "examples envelope"

"$SCRIPT" doctor --json >"$TMP/doctor.json"
assert_jq "$TMP/doctor.json" '.command == "doctor" and .status == "pass"' "doctor envelope"

fixture="$TMP/repo"
mkdir -p "$fixture/scripts"
mkdir -p "$fixture/tests" "$fixture/.flywheel/receipts/demo"
git -C "$fixture" init -q
git -C "$fixture" config user.email test@example.invalid
git -C "$fixture" config user.name "Test User"
cat >"$fixture/scripts/with-trap.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
touch "$tmp"
EOF
cat >"$fixture/scripts/without-trap.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
touch state.txt
EOF
cat >"$fixture/scripts/read-only.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'hello\n'
EOF
cat >"$fixture/scripts/read-only-apply-contract.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
info() {
  jq -nc '{read_only:true,mutates_state:false,canonical_cli:["--apply"]}'
}
case "${1:-}" in
  --info) info ;;
  --apply) printf 'dry contract only\n' ;;
  *) printf 'hello\n' ;;
esac
EOF
cat >"$fixture/scripts/read-only-devnull-probe.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
command -v jq >/dev/null 2>&1
pgrep -f definitely-not-real >/dev/null || true
printf 'quiet\n' >/dev/null
EOF
cat >"$fixture/scripts/comment-only-mutation-text.sh" <<'EOF'
#!/usr/bin/env bash
# Setup note only:
#   git commit --no-verify
#   ln -s ../../.flywheel/hooks/example .git/hooks/pre-commit
set -euo pipefail
printf 'read only\n'
EOF
cat >"$fixture/scripts/quoted-mutation-text.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
echo "operator hint: git commit --no-verify if intentional"
printf '%s\n' 'never run rm -rf from this message'
jq -nc '{items:($xs | split(",") | map(select(length>0)))}'
EOF
cat >"$fixture/tests/mutating-test.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
touch test-state.txt
EOF
cat >"$fixture/.flywheel/receipts/demo/historical-probe.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
touch historical-state.txt
EOF
git -C "$fixture" add scripts
git -C "$fixture" add tests .flywheel/receipts
git -C "$fixture" commit -q -m fixture

"$SCRIPT" scan --repo "$fixture" --json >"$TMP/fixture.json"
assert_jq "$TMP/fixture.json" '.status == "warn" and .scan_scope == "tracked_operational_shell" and .tracked_shell_scripts_scanned == 7 and .mutating_like_scripts == 2 and .mutating_like_with_exit_or_err_trap == 1 and .mutating_like_without_exit_or_err_trap == 1' "fixture counts trap coverage"
assert_jq "$TMP/fixture.json" '.sample_without_trap == ["scripts/without-trap.sh"] and .claim == "inventory_only_not_adoption_complete"' "fixture sample and claim"
assert_jq "$TMP/fixture.json" '(.excluded_non_operational_prefixes | index("tests/")) and (.excluded_non_operational_prefixes | index(".flywheel/receipts/"))' "fixture excludes non-operational prefixes"
assert_jq "$TMP/fixture.json" '.declared_read_only_excluded_count == 1 and .declared_read_only_excluded_sample == ["scripts/read-only-apply-contract.sh"]' "fixture excludes declared read-only apply contract"

if "$SCRIPT" scan --repo "$fixture" --max-without-trap 0 --json >"$TMP/strict.json"; then
  fail "strict threshold fails when trap gap exists"
else
  assert_jq "$TMP/strict.json" '.status == "fail" and .max_without_trap == 0' "strict threshold failure envelope"
fi

"$SCRIPT" scan --repo "$ROOT" --json >"$TMP/live.json"
assert_jq "$TMP/live.json" '.schema_version == "flywheel.trap_rollback_inventory.v1" and .tracked_shell_scripts_scanned > 0 and .mutating_like_scripts > 0 and .claim == "inventory_only_not_adoption_complete"' "live repo inventory envelope"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
