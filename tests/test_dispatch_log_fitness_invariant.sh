#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
BIN="$ROOT/.flywheel/scripts/dispatch-log-fitness-invariant.sh"
CHECKER="$HOME/.claude/skills/canonical-cli-scoping/scripts/check-cli-scoping.sh"

case "${1:-}" in
  doctor|health|completion)
    if [[ "${2:-}" == "--help" || "${2:-}" == "-h" ]]; then
      printf 'usage: %s [doctor|health|completion --help] [--help]\n' "$(basename "$0")"
      exit 0
    fi
    ;;
  --help|-h|--info|--examples|quickstart|help)
    printf 'usage: %s\n' "$(basename "$0")"
    exit 0
    ;;
esac

TMP="$(mktemp -d "${TMPDIR:-/tmp}/dispatch-log-fitness-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

make_repo() {
  local repo="$1" with_claim="$2"
  mkdir -p "$repo/.flywheel"
  : >"$repo/.flywheel/dispatch-log.jsonl"
  local i
  for i in $(seq 1 50); do
    if (( i <= with_claim )); then
      jq -nc --arg id "row-$i" '{task_id:$id,mission_fitness_claim:"claim",mission_fitness_class:"direct",callback_received_at:null}' >>"$repo/.flywheel/dispatch-log.jsonl"
    else
      jq -nc --arg id "row-$i" '{task_id:$id,callback_received_at:null}' >>"$repo/.flywheel/dispatch-log.jsonl"
    fi
  done
}

assert_case() {
  local name="$1" claims="$2" expected_status="$3" expected_rc="$4" expected_pct="$5"
  local repo="$TMP/$name" out="$TMP/$name.json" rc
  make_repo "$repo" "$claims"
  set +e
  bash "$BIN" --repo "$repo" --json >"$out"
  rc=$?
  set -e
  [[ "$rc" == "$expected_rc" ]] && pass "$name/rc_$expected_rc" || fail "$name/rc_expected_$expected_rc got_$rc"
  jq -e --arg status "$expected_status" '.status == $status' "$out" >/dev/null && pass "$name/status_$expected_status" || fail "$name/status_$expected_status"
  jq -e --argjson pct "$expected_pct" '.coverage_pct == $pct' "$out" >/dev/null && pass "$name/coverage_$expected_pct" || fail "$name/coverage_$expected_pct"
}

assert_case pass_90 45 PASS 0 90
assert_case warn_70 35 WARN 1 70
assert_case fail_50 25 FAIL 2 50

bash "$CHECKER" "$BIN" >/dev/null && pass "canonical_cli_scoping/invariant" || fail "canonical_cli_scoping/invariant"

printf '\nResults: %d PASS  %d FAIL\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]] || exit 1
