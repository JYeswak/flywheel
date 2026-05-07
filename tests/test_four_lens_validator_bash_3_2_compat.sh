#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
VALIDATOR="$ROOT/.flywheel/scripts/validate-callback-before-close.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/four-lens-bash32.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

need() {
  command -v "$1" >/dev/null 2>&1 || {
    fail "missing_command_$1"
    exit 1
  }
}

need jq
need br

if /bin/bash --version | head -1 | grep -q 'version 3\.2\.'; then
  pass "bin_bash_is_3_2"
else
  fail "bin_bash_is_3_2"
fi

bash -n "$VALIDATOR" && pass "validator_syntax" || fail "validator_syntax"

repo="$TMP/repo"
mkdir -p "$repo"
git -C "$repo" init -q
(cd "$repo" && br init --prefix test >/dev/null)
bead="$(cd "$repo" && br create "bash 3.2 validator fixture" --priority 1 --type task --description "fixture" --json | jq -r '.id')"

good="$TMP/good.md"
cat >"$good" <<EOF
# Evidence

did=5/5 didnt=none gaps=none tests=PASS

Acceptance gates:
- gate 1 passed with receipt line 12
- gate 2 passed with \`$VALIDATOR\`
- gate 3 passed with \`tests/test_four_lens_validator_bash_3_2_compat.sh\`
- br dep cycles: No dependency cycles detected.

Files:
- \`$VALIDATOR\`
- \`tests/test_four_lens_validator_bash_3_2_compat.sh\`
- \`tests/validate-callback-before-close.sh\`

Run:
\`\`\`bash
/bin/bash tests/test_four_lens_validator_bash_3_2_compat.sh
\`\`\`

Contract version: four-lens-close-validator/v1.
Four-Lens Self-Grade: brand voice pass; Joshua sniff pass; Jeff doctrine pass; public publishability pass for Three Judges.
Outcome: Bash 3.2 validation proof prevents close-gate crashes on macOS default shells.
Result: close path stays blocked until evidence is specific, executable, and public-grade.
Operator note: direct /bin/bash invocation exercises the compatibility path, not Homebrew bash.
Receipt note: this fixture has enough evidence lines to satisfy the public readability floor.
EOF

set +e
/bin/bash "$VALIDATOR" --repo "$repo" --bead "$bead" --evidence "$good" --json >"$TMP/good.json" 2>"$TMP/good.err"
good_rc=$?
set -e

[[ "$good_rc" -eq 0 ]] && pass "good_fixture_exit_zero" || fail "good_fixture_exit_zero_rc_$good_rc"
[[ ! -s "$TMP/good.err" ]] && pass "good_fixture_no_stderr" || fail "good_fixture_no_stderr"
assert_jq "$TMP/good.json" '.verdict == "SAFE_TO_CLOSE" and .four_lens.public.status == "pass"' "good_fixture_safe_to_close"

bad="$TMP/bad-no-bar.md"
cat >"$bad" <<EOF
# Evidence

did=5/5 didnt=none gaps=none tests=PASS

Acceptance gates:
- gate 1 passed with receipt line 12
- gate 2 passed with \`$VALIDATOR\`
- gate 3 passed with \`tests/test_four_lens_validator_bash_3_2_compat.sh\`
- br dep cycles: No dependency cycles detected.

Files:
- \`$VALIDATOR\`
- \`tests/test_four_lens_validator_bash_3_2_compat.sh\`
- \`tests/validate-callback-before-close.sh\`

Run:
\`\`\`bash
/bin/bash tests/test_four_lens_validator_bash_3_2_compat.sh
\`\`\`

Outcome: Bash 3.2 validation proof prevents close-gate crashes on macOS default shells.
Result: this intentionally omits the self-grade language so the public lens must fail.
Operator note: the fixture remains otherwise detailed enough to isolate no_bar_self_grade.
Receipt note: missing bar text, not missing evidence thickness, is the expected blocker.
EOF

set +e
/bin/bash "$VALIDATOR" --repo "$repo" --bead "$bead" --evidence "$bad" --json >"$TMP/bad.json" 2>"$TMP/bad.err"
bad_rc=$?
set -e

[[ "$bad_rc" -ne 0 ]] && pass "bad_fixture_exit_nonzero" || fail "bad_fixture_exit_nonzero"
[[ ! -s "$TMP/bad.err" ]] && pass "bad_fixture_no_stderr" || fail "bad_fixture_no_stderr"
assert_jq "$TMP/bad.json" '.verdict == "BLOCK_CLOSE" and .four_lens.public.status == "fail" and (.failures[] | contains("no_bar_self_grade"))' "bad_fixture_public_lens_blocks"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 && "$pass_count" -ge 8 ]]
