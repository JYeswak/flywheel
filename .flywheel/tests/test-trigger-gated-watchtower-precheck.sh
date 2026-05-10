#!/usr/bin/env bash
# test-trigger-gated-watchtower-precheck.sh (AG3 for flywheel-lh64t)
#
# Asserts:
#   1. dispatch-trigger-gated-precheck refuses (rc=6) for a bead body that
#      declares external_trigger_watchtower=frankenterm_release while the
#      watchtower says public_no_release.
#   2. The same bead body passes (rc=0) when the watchtower says released.
#   3. A bead WITHOUT the structured field but WITH prose-trigger signals
#      passes (rc=0) but emits a warning naming the missing field.
#   4. A clean bead passes (rc=0) with no warnings.
#   5. The status emitted in (1) carries reason_code=trigger_not_yet_fired.
#   6. The introspection trio (info/examples/schema) all exit 0.
#
# Sister: flywheel-g6xaw (parent), flywheel-ubrb5 (watchtower author).
# Doctrine: .flywheel/doctrine/trigger-gated-bead-precheck.md

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
PRECHECK="$ROOT/.flywheel/scripts/dispatch-trigger-gated-precheck.sh"
[[ -x "$PRECHECK" ]] || { echo "FAIL: precheck script not executable: $PRECHECK" >&2; exit 1; }

TMP="$(mktemp -d -t test-trigger-gated.XXXXXX)"
trap 'find "$TMP" -mindepth 1 -delete 2>/dev/null; rmdir "$TMP" 2>/dev/null || true' EXIT

# --- fixtures ---
cat >"$TMP/bead-gated.txt" <<'BODY'
This bead waits on FrankenTerm v0.1.
external_trigger_watchtower=frankenterm_release
Operational trigger is a future FrankenTerm v0.1+ release announcement.
Acceptance:
- AG1: gh repo view shows latestRelease.tagName matching v0.1.0 or higher.
BODY

cat >"$TMP/bead-prose-only.txt" <<'BODY'
This bead has only prose-trigger language.
Operational trigger is a future thing release announcement.
BODY

cat >"$TMP/bead-clean.txt" <<'BODY'
This bead just edits a file.
Acceptance: AG1 file modified, AG2 test passes.
BODY

cat >"$TMP/wt-public-no-release.json" <<'JSON'
{"watchlists":{"frankenterm_release":{"status":"public_no_release","rows":[]}}}
JSON

cat >"$TMP/wt-released.json" <<'JSON'
{"watchlists":{"frankenterm_release":{"status":"released","rows":[{"latest_release":"v0.1.0"}]}}}
JSON

fail=0
report_fail() { echo "FAIL[$1]: $2" >&2; fail=$((fail+1)); }

# --- (1) gated + public_no_release => rc=6 ---
set +e
out1="$("$PRECHECK" validate --bead-body-file "$TMP/bead-gated.txt" --watchtower-json-fixture "$TMP/wt-public-no-release.json" --json 2>/dev/null)"
rc1=$?
set -e
if [[ "$rc1" -ne 6 ]]; then
  report_fail 1 "expected rc=6 (trigger_not_yet_fired) got rc=$rc1; out=$out1"
fi
status1="$(jq -r '.status' <<<"$out1")"
reason1="$(jq -r '.reason_code' <<<"$out1")"
[[ "$status1" == "trigger_not_yet_fired" ]] || report_fail 1 "expected status=trigger_not_yet_fired got $status1"
[[ "$reason1" == "trigger_not_yet_fired" ]] || report_fail 5 "expected reason_code=trigger_not_yet_fired got $reason1"

# --- (2) gated + released => rc=0 ---
set +e
out2="$("$PRECHECK" validate --bead-body-file "$TMP/bead-gated.txt" --watchtower-json-fixture "$TMP/wt-released.json" --json 2>/dev/null)"
rc2=$?
set -e
[[ "$rc2" -eq 0 ]] || report_fail 2 "expected rc=0 (trigger has fired) got rc=$rc2; out=$out2"
status2="$(jq -r '.status' <<<"$out2")"
[[ "$status2" == "ok" ]] || report_fail 2 "expected status=ok got $status2"

# --- (3) prose-only => rc=0 with warning ---
set +e
out3="$("$PRECHECK" validate --bead-body-file "$TMP/bead-prose-only.txt" --watchtower-json-fixture "$TMP/wt-public-no-release.json" --json 2>/dev/null)"
rc3=$?
set -e
[[ "$rc3" -eq 0 ]] || report_fail 3 "expected rc=0 for prose-only got rc=$rc3"
warn3="$(jq -r '.warnings[]' <<<"$out3" 2>/dev/null || echo)"
[[ "$warn3" == *"prose-trigger-detected-but-no-external_trigger_watchtower-field"* ]] \
  || report_fail 3 "expected warning naming missing field; got: $warn3"

# --- (4) clean bead => rc=0, no warnings, no signals ---
set +e
out4="$("$PRECHECK" validate --bead-body-file "$TMP/bead-clean.txt" --watchtower-json-fixture "$TMP/wt-public-no-release.json" --json 2>/dev/null)"
rc4=$?
set -e
[[ "$rc4" -eq 0 ]] || report_fail 4 "expected rc=0 for clean bead got rc=$rc4"
warns4_count="$(jq -r '.warnings | length' <<<"$out4")"
signals4_count="$(jq -r '.prose_signals | length' <<<"$out4")"
[[ "$warns4_count" -eq 0 ]] || report_fail 4 "expected no warnings; got $warns4_count"
[[ "$signals4_count" -eq 0 ]] || report_fail 4 "expected no prose signals; got $signals4_count"

# --- (6) introspection trio ---
"$PRECHECK" info >/dev/null || report_fail 6 "info command failed"
"$PRECHECK" examples >/dev/null || report_fail 6 "examples command failed"
"$PRECHECK" schema | jq -e .title >/dev/null || report_fail 6 "schema command did not emit valid JSON with .title"
"$PRECHECK" doctor --json >/dev/null || report_fail 6 "doctor command failed"
"$PRECHECK" health --bead-body-file "$TMP/bead-gated.txt" --watchtower-json-fixture "$TMP/wt-released.json" --json >/dev/null \
  || report_fail 6 "health command failed for ok case"

# --- (7) build-dispatch-packet integration: refuses without flag, allows with flag ---
BUILDER="$ROOT/.flywheel/scripts/build-dispatch-packet.sh"
if [[ -x "$BUILDER" ]]; then
  : # build-dispatch-packet integration smoke is exercised via test-build-dispatch-packet.sh
  : # — this regression test scopes to the precheck unit per its bead.
fi

if [[ "$fail" -gt 0 ]]; then
  echo "FAIL: $fail assertion(s) failed" >&2
  exit 1
fi
echo "PASS test-trigger-gated-watchtower-precheck (6 assertion groups)"
exit 0
