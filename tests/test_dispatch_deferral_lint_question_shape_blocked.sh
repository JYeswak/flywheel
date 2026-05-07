#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/dispatch-deferral-lint.sh"
TMP="$(mktemp -d -t deferral-lint-question.XXXXXX)"
trap 'rm -r "$TMP"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

cat >"$TMP/draft.md" <<'DRAFT'
PageRank and doctor agree on the next audit lane.
Want me to dispatch the next worker now?
DRAFT

jq -nc '{
  idle_worker_count: 2,
  ready_work_count: 5,
  pagerank_alignment: true,
  doctor_alignment: true,
  selected_action: "dispatch flywheel-next-ready through /flywheel:dispatch"
}' >"$TMP/signals.json"

set +e
"$SCRIPT" --draft "$TMP/draft.md" --signals "$TMP/signals.json" --receipt "$TMP/receipt.json" --json >"$TMP/out.json"
rc=$?
set -e

[ "$rc" -ne 0 ] || fail "question-shaped draft should fail when data answers"
jq -e '
  .status == "fail"
  and .reason == "data_backed_deferral_violation"
  and .question_shape == true
  and .data_answers == true
  and .idle_worker_count == 2
  and .ready_work_count == 5
' "$TMP/out.json" >/dev/null || fail "missing data_backed_deferral_violation"
cmp "$TMP/out.json" "$TMP/receipt.json" >/dev/null || fail "receipt should match JSON output"

printf 'PASS: dispatch deferral lint blocks question-shaped draft\n'
