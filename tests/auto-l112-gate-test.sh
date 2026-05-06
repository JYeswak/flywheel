#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
GATE="$REPO_ROOT/.flywheel/scripts/auto-l112-gate.sh"
REAL_HOME="$(dscl . -read "/Users/$(id -un)" NFSHomeDirectory 2>/dev/null | awk '{print $2}' || true)"
REAL_HOME="${REAL_HOME:-/Users/josh}"
TMPDIR_TEST="$(mktemp -d /tmp/auto-l112-gate-test.XXXXXX)"
LEDGER="$TMPDIR_TEST/ledger.jsonl"
BR_LOG="$TMPDIR_TEST/br-create.log"
export AUTO_L112_GATE_LEDGER="$LEDGER"
export AUTO_L112_GATE_BR_CREATE_WRAPPER="$TMPDIR_TEST/fake-br-create"

cat >"$AUTO_L112_GATE_BR_CREATE_WRAPPER" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${BR_LOG:?}"
printf '[{"id":"flywheel-fixmock"}]\n'
EOF
chmod +x "$AUTO_L112_GATE_BR_CREATE_WRAPPER"
export BR_LOG

pass_count=0
SKILL_ROUTES="canonical-cli-scoping=n/a,rust-best-practices=n/a,python-best-practices=n/a,readme-writing=n/a"

expect_rc() {
  local name="$1" want="$2"
  shift 2
  set +e
  HOME="$REAL_HOME" "$@" >"$TMPDIR_TEST/$name.out" 2>"$TMPDIR_TEST/$name.err"
  local got=$?
  set -e
  if [[ "$got" -ne "$want" ]]; then
    echo "FAIL $name expected_rc=$want got_rc=$got" >&2
    cat "$TMPDIR_TEST/$name.out" >&2 || true
    cat "$TMPDIR_TEST/$name.err" >&2 || true
    exit 1
  fi
  pass_count=$((pass_count + 1))
}

envelope() {
  local file="$1" command="$2" expected="$3" timeout="${4:-5}"
  {
    printf 'l112_probe_command=%s\n' "$command"
    printf 'l112_probe_expected=%s\n' "$expected"
    printf 'l112_probe_timeout_sec=%s\n' "$timeout"
    printf 'skill_auto_routes_addressed=%s\n' "$SKILL_ROUTES"
  } >"$file"
}

pass_env="$TMPDIR_TEST/pass.env"
envelope "$pass_env" "printf 'OK\n'" "grep:OK" 5
expect_rc matching_expected 0 "$GATE" --task-id test-pass --callback-envelope-file "$pass_env" --json
jq -e '.status == "pass"' "$TMPDIR_TEST/matching_expected.out" >/dev/null

fail_env="$TMPDIR_TEST/fail.env"
envelope "$fail_env" "printf 'NO\n'" "grep:OK" 5
expect_rc nonmatching_expected 1 "$GATE" --task-id test-fail --callback-envelope-file "$fail_env" --json
jq -e '.status == "fail" and .fix_bead_id == "flywheel-fixmock"' "$TMPDIR_TEST/nonmatching_expected.out" >/dev/null
grep -q -- "test-fail" "$BR_LOG"

malformed_env="$TMPDIR_TEST/malformed.env"
printf 'l112_probe_expected=grep:OK\n' >"$malformed_env"
expect_rc malformed_envelope 2 "$GATE" --task-id test-malformed --callback-envelope-file "$malformed_env" --json
jq -e '.status == "malformed"' "$TMPDIR_TEST/malformed_envelope.out" >/dev/null

invalid_skill_env="$TMPDIR_TEST/invalid-skill.env"
envelope "$invalid_skill_env" "printf 'OK\n'" "grep:OK" 5
printf 'skill_auto_routes_addressed=canonical-cli-scoping=yes\n' >>"$invalid_skill_env"
expect_rc invalid_skill_routes 2 "$GATE" --task-id test-invalid-skill --callback-envelope-file "$invalid_skill_env" --json
jq -e '.status == "malformed" and .failure_class == "missing_or_invalid_l112_probe_fields_or_skill_auto_routes"' "$TMPDIR_TEST/invalid_skill_routes.out" >/dev/null

timeout_env="$TMPDIR_TEST/timeout.env"
envelope "$timeout_env" "sleep 2" "grep:OK" 1
expect_rc timeout_probe 3 "$GATE" --task-id test-timeout --callback-envelope-file "$timeout_env" --json
jq -e '.status == "sandbox_error"' "$TMPDIR_TEST/timeout_probe.out" >/dev/null

network_env="$TMPDIR_TEST/network.env"
envelope "$network_env" "curl https://example.com" "grep:OK" 5
expect_rc network_refused 3 "$GATE" --task-id test-network --callback-envelope-file "$network_env" --json
grep -q -- "sandbox_refused=network_token_denied" "$(jq -r '.stderr_file' "$TMPDIR_TEST/network_refused.out")"

jq -s -e 'length == 6 and all(.[]; has("schema_version") and has("status"))' "$LEDGER" >/dev/null

printf 'PASS auto-l112-gate fixture pass=%s/6 ledger=%s\n' "$pass_count" "$LEDGER"
