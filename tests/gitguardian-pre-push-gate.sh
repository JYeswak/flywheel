#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/gitguardian-pre-push-gate.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/gitguardian-pre-push-gate.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass=0
fail=0

ok() {
  local name="$1"
  shift
  if "$@"; then
    pass=$((pass + 1))
    printf 'ok %d - %s\n' "$pass" "$name"
  else
    fail=$((fail + 1))
    printf 'not ok %d - %s\n' "$((pass + fail))" "$name"
  fi
}

ok_jq() {
  local name="$1" expr="$2" file="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass=$((pass + 1))
    printf 'ok %d - %s\n' "$pass" "$name"
  else
    fail=$((fail + 1))
    printf 'not ok %d - %s\n' "$((pass + fail))" "$name"
    jq . "$file" >&2 || true
  fi
}

make_repo() {
  local dir="$1" content="$2"
  mkdir -p "$dir"
  git -C "$dir" init -q
  git -C "$dir" config user.email "fixture@example.invalid"
  git -C "$dir" config user.name "Fixture"
  printf 'baseline\n' >"$dir/README.md"
  git -C "$dir" add README.md
  git -C "$dir" commit -q -m baseline
  printf '%s\n' "$content" >"$dir/payload.txt"
  git -C "$dir" add payload.txt
  git -C "$dir" commit -q -m payload
}

FAKE_INFISICAL="$TMP/infisical-load"
cat >"$FAKE_INFISICAL" <<'SH'
#!/usr/bin/env bash
[[ "${1:-}" == "--status" ]] || exit 2
exit 0
SH
chmod +x "$FAKE_INFISICAL"

GOOD_LOADER="$TMP/load-good"
cat >"$GOOD_LOADER" <<'SH'
#!/usr/bin/env bash
[[ "${1:-}" == "GITGUARDIAN_API_KEY" ]] || exit 2
printf '%s' 'fixture_gitguardian_api_key'
SH
chmod +x "$GOOD_LOADER"

MISSING_LOADER="$TMP/load-missing"
cat >"$MISSING_LOADER" <<'SH'
#!/usr/bin/env bash
exit 1
SH
chmod +x "$MISSING_LOADER"

FAKE_GGSHIELD="$TMP/ggshield"
CALLS="$TMP/ggshield-calls.jsonl"
export CALLS
cat >"$FAKE_GGSHIELD" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
[[ -n "${GITGUARDIAN_API_KEY:-}" ]] || exit 90
out=""
prev=""
for arg in "$@"; do
  if [[ "$prev" == "-o" || "$prev" == "--output" ]]; then
    out="$arg"
  fi
  prev="$arg"
done
[[ -n "$out" ]] || exit 91
python3 - "$CALLS" "$@" <<'PY'
import json
import os
import sys
with open(sys.argv[1], "a", encoding="utf-8") as handle:
    handle.write(json.dumps({"argv": sys.argv[2:]}, sort_keys=True) + "\n")
PY
case "${FAKE_GGSHIELD_RESULT:-clean}" in
  clean)
    printf '{"incidents":[]}\n' >"$out"
    exit 0
    ;;
  leak)
    printf '{"incidents":[{"severity":"critical"},{"severity":"high"}]}\n' >"$out"
    exit 1
    ;;
  error)
    printf '{"error":"server"}\n' >"$out"
    exit 2
    ;;
  *)
    exit 92
    ;;
esac
SH
chmod +x "$FAKE_GGSHIELD"

CLEAN_REPO="$TMP/clean-repo"
LEAK_REPO="$TMP/leak-repo"
make_repo "$CLEAN_REPO" "ordinary config only"
make_repo "$LEAK_REPO" "synthetic fixture only: AKIATESTFAKEKEY00000"

ok "script syntax" bash -n "$SCRIPT"
ok "fixture syntax" bash -n "$0"
ok "gate script executable" test -x "$SCRIPT"

CLEAN_OUT="$TMP/clean.json"
CLEAN_LEDGER="$TMP/clean-ledger.jsonl"
"$SCRIPT" --json --repo "$CLEAN_REPO" --commit-range HEAD~1..HEAD \
  --ledger "$CLEAN_LEDGER" \
  --infisical-status "$FAKE_INFISICAL" \
  --secret-loader "$GOOD_LOADER" \
  --ggshield-bin "$FAKE_GGSHIELD" >"$CLEAN_OUT"
ok_jq "clean diff allows push" '.status == "clean" and .exit_code == 0 and .finding_count == 0' "$CLEAN_OUT"
ok "clean diff writes no leak ledger" test ! -e "$CLEAN_LEDGER"
ok_jq "clean command uses commit-range scan" '.argv | index("commit-range") != null' "$CALLS"

LEAK_OUT="$TMP/leak.json"
LEAK_LEDGER="$TMP/leak-ledger.jsonl"
set +e
FAKE_GGSHIELD_RESULT=leak "$SCRIPT" --json --repo "$LEAK_REPO" --commit-range HEAD~1..HEAD \
  --ledger "$LEAK_LEDGER" \
  --infisical-status "$FAKE_INFISICAL" \
  --secret-loader "$GOOD_LOADER" \
  --ggshield-bin "$FAKE_GGSHIELD" >"$LEAK_OUT"
leak_rc=$?
set -e
ok "leak diff blocks push" test "$leak_rc" -eq 1
ok_jq "leak JSON is structured" '.status == "blocked" and .reason == "secret_leak_detected" and .finding_count == 2 and .severity == "critical" and .exit_code == 1' "$LEAK_OUT"
ok_jq "leak ledger records required fields" '.event == "secret_leak_detected" and .finding_count == 2 and .severity == "critical" and (.branch | length > 0) and .commit_range == "HEAD~1..HEAD"' "$LEAK_LEDGER"

MISSING_OUT="$TMP/missing.json"
set +e
"$SCRIPT" --json --repo "$CLEAN_REPO" --commit-range HEAD~1..HEAD \
  --ledger "$TMP/missing-ledger.jsonl" \
  --infisical-status "$FAKE_INFISICAL" \
  --secret-loader "$MISSING_LOADER" \
  --ggshield-bin "$FAKE_GGSHIELD" >"$MISSING_OUT"
missing_rc=$?
set -e
ok "missing API key fails closed" test "$missing_rc" -eq 1
ok_jq "missing key reason is explicit" '.status == "blocked" and .reason == "gitguardian_api_key_unavailable" and .exit_code == 1' "$MISSING_OUT"

ERROR_OUT="$TMP/error.json"
set +e
FAKE_GGSHIELD_RESULT=error "$SCRIPT" --json --repo "$CLEAN_REPO" --commit-range HEAD~1..HEAD \
  --ledger "$TMP/error-ledger.jsonl" \
  --infisical-status "$FAKE_INFISICAL" \
  --secret-loader "$GOOD_LOADER" \
  --ggshield-bin "$FAKE_GGSHIELD" >"$ERROR_OUT"
error_rc=$?
set -e
ok "ggshield error fails closed" test "$error_rc" -eq 1
ok_jq "ggshield error reason is fail-closed" '.status == "blocked" and .reason == "ggshield_failed_closed"' "$ERROR_OUT"

if rg -q 'fixture_gitguardian_api_key|AKIATESTFAKEKEY00000' "$TMP"/*.json "$TMP"/*.jsonl 2>/dev/null; then
  fail=$((fail + 1))
  printf 'not ok %d - outputs do not echo fixture secrets\n' "$((pass + fail))"
else
  pass=$((pass + 1))
  printf 'ok %d - outputs do not echo fixture secrets\n' "$pass"
fi

printf 'SUMMARY pass=%d fail=%d\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]]
