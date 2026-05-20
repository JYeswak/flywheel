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
  local repo="$TMP/$name" out="$TMP/$name.json" timeline rc
  make_repo "$repo" "$claims"
  timeline="$(jq -s '{events:.}' "$repo/.flywheel/dispatch-log.jsonl")"
  set +e
  NTM_TIMELINE_JSON="$timeline" bash "$BIN" --repo "$repo" --json >"$out"
  rc=$?
  set -e
  if [[ "$rc" == "$expected_rc" ]]; then
    pass "$name/rc_$expected_rc"
  else
    fail "$name/rc_expected_$expected_rc got_$rc"
  fi
  if jq -e --arg status "$expected_status" '.status == $status' "$out" >/dev/null; then
    pass "$name/status_$expected_status"
  else
    fail "$name/status_$expected_status"
  fi
  if jq -e --argjson pct "$expected_pct" '.coverage_pct == $pct' "$out" >/dev/null; then
    pass "$name/coverage_$expected_pct"
  else
    fail "$name/coverage_$expected_pct"
  fi
}

assert_case pass_90 45 PASS 0 90
assert_case warn_70 35 WARN 1 70
assert_case fail_50 25 FAIL 2 50

if bash "$CHECKER" "$BIN" >/dev/null; then
  pass "canonical_cli_scoping/invariant"
else
  fail "canonical_cli_scoping/invariant"
fi

printf '\nResults: %d PASS  %d FAIL\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]] || exit 1
