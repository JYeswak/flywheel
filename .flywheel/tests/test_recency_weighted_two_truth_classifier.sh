#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/recency-weighted-two-truth-classifier.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/recency-classifier-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass=0
fail=0
cases=0

ok() { printf 'PASS %s\n' "$1"; pass=$((pass + 1)); }
bad() { printf 'FAIL %s\n' "$1" >&2; fail=$((fail + 1)); }

assert_verdict() {
  local name="$1" expected="$2" text="$3" out
  cases=$((cases + 1))
  if out="$(printf '%s\n' "$text" | "$SCRIPT" --json)"; then
    if jq -e --arg v "$expected" '.verdict == $v' >/dev/null <<<"$out"; then
      ok "$name"
    else
      bad "$name expected=$expected out=$out"
    fi
  else
    bad "$name classifier exited non-zero"
  fi
}

assert_not_error() {
  local name="$1" text="$2" out
  cases=$((cases + 1))
  if out="$(printf '%s\n' "$text" | "$SCRIPT" --json)" && jq -e '.verdict != "ERROR"' >/dev/null <<<"$out"; then
    ok "$name"
  else
    bad "$name out=${out:-}"
  fi
}

bash -n "$SCRIPT" && ok "script syntax" || bad "script syntax"
"$SCRIPT" --info --json | jq -e '.name == "recency_weighted_two_truth_classifier"' >/dev/null && ok "info json" || bad "info json"
"$SCRIPT" --check --json | jq -e '.status == "pass"' >/dev/null && ok "self check" || bad "self check"

assert_verdict "stale failed_text yields waiting" "WAITING" $'failed_text old tool output\napi_error old output\n❯ '
assert_verdict "stale api_error plus fresh working" "THINKING" $'api_error old output\n❯ \nWorking (1s • esc to interrupt)'
assert_verdict "fresh fatal below chevron" "ERROR" $'❯ \npanic: invariant failed'

assert_verdict "old working above callback chevron" "WAITING" $'Working (24s • esc to interrupt)\nDONE task callback delivered\n❯ '
assert_verdict "old esc marker above idle prompt" "WAITING" $'esc to interrupt\nbypass permissions on\n❯ '
assert_verdict "fresh working below prompt chrome" "THINKING" $'❯ \nWorking (2s • esc to interrupt)'

assert_verdict "chevron plus fresh working timer" "THINKING" $'❯ \nWorking (5s • esc to interrupt)'
assert_verdict "background terminal means thinking" "THINKING" $'❯ \nWaiting for background terminal (12s)'
assert_verdict "plain chevron means waiting" "WAITING" $'conversation complete\n❯ '

assert_not_error "stale error above frozen template not decisive" $'ERROR failed_text old\nUse /help for commands\n❯ '
assert_verdict "post callback spinner is thinking" "THINKING" $'DONE callback delivered\n❯ \nWorking (2m 05s • esc to interrupt)'
assert_verdict "newest fatal error wins" "ERROR" $'ERROR failed_text old\nUse /help for commands\nfatal: process exited'

snapshot="/tmp/flywheel-pane4-snapshot.20260506T172543Z.json"
if [[ -s "$snapshot" ]]; then
  cases=$((cases + 1))
  jq -r '.panes["4"].lines[]?' "$snapshot" >"$TMP/pane4.txt"
  out="$("$SCRIPT" --json <"$TMP/pane4.txt")"
  if jq -e '.verdict | IN("WAITING","THINKING","ERROR","UNKNOWN")' >/dev/null <<<"$out"; then
    ok "real pane4 snapshot taxonomy"
  else
    bad "real pane4 snapshot taxonomy out=$out"
  fi
fi

cat >"$TMP/ntm" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
case "$1" in
  --robot-tail=fixture)
    jq -nc '{success:true,panes:{"2":{lines:["failed_text old","❯ "]}}}'
    ;;
  --robot-activity=fixture)
    jq -nc '{agents:[{pane_idx:2,state:"ERROR"}]}'
    ;;
  *)
    echo "unexpected $*" >&2
    exit 2
    ;;
esac
SH
chmod +x "$TMP/ntm"
cases=$((cases + 1))
out="$(RECENCY_CLASSIFIER_NTM_BIN="$TMP/ntm" "$SCRIPT" --session fixture --pane 2 --json)"
if jq -e '.verdict == "WAITING" and .robot_activity_verdict == "ERROR"' >/dev/null <<<"$out"; then
  ok "session pane two truth mode"
else
  bad "session pane two truth mode out=$out"
fi

if [[ "$fail" -ne 0 ]]; then
  printf 'RESULT pass=%s fail=%s test_cases=%s\n' "$pass" "$fail" "$cases" >&2
  exit 1
fi
printf 'RESULT pass=%s fail=%s test_cases=%s\n' "$pass" "$fail" "$cases"
