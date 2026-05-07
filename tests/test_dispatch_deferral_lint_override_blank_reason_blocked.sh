#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/dispatch-deferral-lint.sh"
TMP="$(mktemp -d -t deferral-lint-override.XXXXXX)"
trap 'rm -r "$TMP"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

jq -nc '{idle_worker_count:1,ready_work_count:1,pagerank_alignment:true,doctor_alignment:true,selected_action:"dispatch flywheel-next-ready"}' >"$TMP/signals.json"

cat >"$TMP/bare.md" <<'DRAFT'
evidence_missing
Should I dispatch after you confirm the missing evidence?
DRAFT

set +e
"$SCRIPT" --draft "$TMP/bare.md" --signals "$TMP/signals.json" --json >"$TMP/bare.json"
bare_rc=$?
set -e
[ "$bare_rc" -ne 0 ] || fail "bare evidence_missing should fail"
jq -e '.status == "fail" and .reason == "evidence_missing_named_datum_required"' "$TMP/bare.json" >/dev/null || fail "bare evidence_missing reason mismatch"

cat >"$TMP/named.md" <<'DRAFT'
evidence_missing=joshua_blocker_class_assignment
Should I dispatch after resolving evidence_missing=joshua_blocker_class_assignment?
DRAFT

"$SCRIPT" --draft "$TMP/named.md" --signals "$TMP/signals.json" --json >"$TMP/named.json"
jq -e '.status == "pass" and .reason == "question_allowed_with_named_override" and .override_present == true' "$TMP/named.json" >/dev/null || fail "named evidence_missing should pass"

cat >"$TMP/tie.md" <<'DRAFT'
tie_between=flywheel-a,flywheel-b
Which bead should take the only idle pane?
DRAFT

set +e
"$SCRIPT" --draft "$TMP/tie.md" --signals "$TMP/signals.json" --json >"$TMP/tie.json"
tie_rc=$?
set -e
[ "$tie_rc" -ne 0 ] || fail "tie_between without reason should fail"
jq -e '.reason == "tie_between_reason_required"' "$TMP/tie.json" >/dev/null || fail "tie_between reason mismatch"

cat >"$TMP/joshua.md" <<'DRAFT'
requires_joshua_decision=true reason="secret-rotation-or-new-credential-creation"
Should I pause for the credential rotation?
DRAFT

"$SCRIPT" --draft "$TMP/joshua.md" --signals "$TMP/signals.json" --json >"$TMP/joshua.json"
jq -e '.status == "pass" and .override_present == true' "$TMP/joshua.json" >/dev/null || fail "requires_joshua_decision true blocker class should pass"

printf 'PASS: dispatch deferral lint requires named override reasons\n'
