#!/usr/bin/env bash
# .flywheel/tests/test-pre-write-path-guard.sh
# Regression test for flywheel-16b53.2 — pre-write-path-guard.sh + cli_pre_write_check.
#
# Verifies the Layer-1 prevention primitive blocks the v38e1.5 trauma class
# (flywheel worker writing to peer-canonical skillos paths) while allowing
# legitimate in-repo writes.
#
# AGs (12 total):
#   AG1  guard syntax clean (bash -n)
#   AG2  doctor surface emits canonical envelope
#   AG3  allow case — in-repo path → rc=0 + decision=allow
#   AG4  DENY case — peer-canonical path → rc=1 + decision=deny (TRAUMA CLASS BLOCKED)
#   AG5  per-bead policy override allows additional roots
#   AG6  CLI --allowed-roots override allows ad-hoc roots
#   AG7  default policy file (post-repair) overrides git-toplevel fallback
#   AG8  fallback to git toplevel when no policy exists
#   AG9  missing --path → rc=2 (usage)
#   AG10 ledger row written for every decision (audit trail invariant)
#   AG11 cli_pre_write_check helper returns expected rc (allow=0, deny=1)
#   AG12 v38e1.5 EXACT trauma path simulation (10-file blast-radius repro)

set -uo pipefail

GUARD=/Users/josh/Developer/flywheel/.flywheel/scripts/pre-write-path-guard.sh
HELPER=/Users/josh/Developer/flywheel/.flywheel/lib/canonical-cli-helpers.sh
WORK=$(mktemp -d -t pwg-test.XXXXXX) || { echo "ERR: mktemp failed" >&2; exit 1; }
trap 'find "$WORK" -mindepth 1 -delete 2>/dev/null; rmdir "$WORK" 2>/dev/null || true' EXIT

# Sandbox state-dir + policy dir to test-scratch so prod ledger is untouched.
export PRE_WRITE_PATH_GUARD_POLICY_DIR="$WORK/policy"
export PRE_WRITE_PATH_GUARD_LEDGER="$WORK/ledger.jsonl"
mkdir -p "$PRE_WRITE_PATH_GUARD_POLICY_DIR"

pass=0
fail=0
p() { pass=$((pass+1)); printf 'PASS %s\n' "$1"; }
f() { fail=$((fail+1)); printf 'FAIL %s\n' "$1" >&2; }

# AG1
if bash -n "$GUARD" 2>/dev/null; then p "AG1 guard syntax clean"; else f "AG1 bash -n failed"; fi

# AG2
DOC_OUT=$(bash "$GUARD" doctor --json 2>/dev/null)
SCHEMA=$(printf '%s' "$DOC_OUT" | jq -r '.schema_version' 2>/dev/null)
CMD=$(printf '%s' "$DOC_OUT" | jq -r '.command' 2>/dev/null)
if [[ "$SCHEMA" == "pre-write-path-guard/v1" && "$CMD" == "doctor" ]]; then
  p "AG2 doctor envelope schema=$SCHEMA command=$CMD"
else
  f "AG2 doctor got schema=$SCHEMA command=$CMD"
fi

# AG3 — allow case (in-repo path; git-toplevel fallback)
ALLOW_OUT=$(bash "$GUARD" --path /Users/josh/Developer/flywheel/.flywheel/test-output.md --bead flywheel-test --json 2>/dev/null); rc=$?
DECISION=$(printf '%s' "$ALLOW_OUT" | jq -r '.decision' 2>/dev/null)
if [[ "$rc" -eq 0 && "$DECISION" == "allow" ]]; then
  p "AG3 allow in-repo (rc=0, decision=allow)"
else
  f "AG3 in-repo got rc=$rc decision=$DECISION"
fi

# AG4 — DENY case (TRAUMA): flywheel worker writing to skillos path
DENY_OUT=$(bash "$GUARD" --path /Users/josh/Developer/skillos/.flywheel/doctrine/foo.md --bead flywheel-v38e1.5 --json 2>/dev/null); rc=$?
DECISION=$(printf '%s' "$DENY_OUT" | jq -r '.decision' 2>/dev/null)
REASON=$(printf '%s' "$DENY_OUT" | jq -r '.reason' 2>/dev/null)
if [[ "$rc" -eq 1 && "$DECISION" == "deny" ]] && [[ "$REASON" == *"path_outside_allowlist"* ]]; then
  p "AG4 DENY trauma class (flywheel→skillos): rc=1 decision=deny reason=path_outside_allowlist"
else
  f "AG4 trauma class NOT blocked: rc=$rc decision=$DECISION reason=$REASON"
fi

# AG5 — per-bead policy override
cat >"$PRE_WRITE_PATH_GUARD_POLICY_DIR/flywheel-cross-repo.txt" <<EOF
# per-bead policy for cross-repo writes (e.g., authorized BV canonical-stamp)
/Users/josh/Developer/flywheel
/Users/josh/Developer/zeststream-brand-voice
EOF
BV_OUT=$(bash "$GUARD" --path /Users/josh/Developer/zeststream-brand-voice/ARCHITECTURE.md --bead flywheel-cross-repo --json 2>/dev/null); rc=$?
DECISION=$(printf '%s' "$BV_OUT" | jq -r '.decision' 2>/dev/null)
POLICY=$(printf '%s' "$BV_OUT" | jq -r '.policy_source' 2>/dev/null)
if [[ "$rc" -eq 0 && "$DECISION" == "allow" && "$POLICY" == "per_bead" ]]; then
  p "AG5 per-bead policy allows BV (rc=0, source=per_bead)"
else
  f "AG5 per-bead policy got rc=$rc decision=$DECISION source=$POLICY"
fi

# AG6 — CLI --allowed-roots override
CLI_OUT=$(bash "$GUARD" --path /tmp/foo.md --bead flywheel-ad-hoc --allowed-roots /tmp --json 2>/dev/null); rc=$?
DECISION=$(printf '%s' "$CLI_OUT" | jq -r '.decision' 2>/dev/null)
POLICY=$(printf '%s' "$CLI_OUT" | jq -r '.policy_source' 2>/dev/null)
if [[ "$rc" -eq 0 && "$DECISION" == "allow" && "$POLICY" == "cli_override" ]]; then
  p "AG6 --allowed-roots override allows /tmp (rc=0, source=cli_override)"
else
  f "AG6 cli override got rc=$rc decision=$DECISION source=$POLICY"
fi

# AG7 — default policy (post-repair)
cat >"$PRE_WRITE_PATH_GUARD_POLICY_DIR/default.txt" <<EOF
# default policy (project-wide)
/Users/josh/Developer/flywheel
EOF
DEF_OUT=$(bash "$GUARD" --path /Users/josh/Developer/flywheel/.flywheel/x.md --bead flywheel-no-per-bead --json 2>/dev/null); rc=$?
POLICY=$(printf '%s' "$DEF_OUT" | jq -r '.policy_source' 2>/dev/null)
if [[ "$rc" -eq 0 && "$POLICY" == "default" ]]; then
  p "AG7 default policy used (source=default)"
else
  f "AG7 default policy got rc=$rc source=$POLICY"
fi

# AG8 — fallback to git toplevel (point policy dir at empty location)
EMPTY_POLICY="$WORK/empty-policy"
mkdir -p "$EMPTY_POLICY"
FALLBACK_OUT=$(PRE_WRITE_PATH_GUARD_POLICY_DIR="$EMPTY_POLICY" bash "$GUARD" --path /Users/josh/Developer/flywheel/.flywheel/y.md --bead flywheel-fallback --json 2>/dev/null); rc=$?
POLICY=$(printf '%s' "$FALLBACK_OUT" | jq -r '.policy_source' 2>/dev/null)
if [[ "$rc" -eq 0 && "$POLICY" == "fallback_git_toplevel" ]]; then
  p "AG8 git-toplevel fallback fires (source=fallback_git_toplevel)"
else
  f "AG8 fallback got rc=$rc source=$POLICY"
fi

# AG9 — missing --path
USAGE_OUT=$(bash "$GUARD" --bead flywheel-x --json 2>&1); rc=$?
if [[ "$rc" -eq 2 ]]; then
  p "AG9 missing --path returns rc=2 (usage)"
else
  f "AG9 missing --path got rc=$rc"
fi

# AG10 — ledger invariant
ROWS_BEFORE=$(wc -l <"$PRE_WRITE_PATH_GUARD_LEDGER" 2>/dev/null | tr -d ' ')
ROWS_BEFORE=${ROWS_BEFORE:-0}
bash "$GUARD" --path /Users/josh/Developer/flywheel/.flywheel/ledger-test.md --bead flywheel-ledger --json >/dev/null 2>/dev/null
ROWS_AFTER=$(wc -l <"$PRE_WRITE_PATH_GUARD_LEDGER" 2>/dev/null | tr -d ' ')
if [[ "$ROWS_AFTER" -gt "$ROWS_BEFORE" ]]; then
  p "AG10 ledger row appended (before=$ROWS_BEFORE after=$ROWS_AFTER)"
else
  f "AG10 ledger not appended (before=$ROWS_BEFORE after=$ROWS_AFTER)"
fi

# AG11 — cli_pre_write_check helper integration
HELPER_TEST=$(bash -c "
source '$HELPER'
export PRE_WRITE_PATH_GUARD_POLICY_DIR='$PRE_WRITE_PATH_GUARD_POLICY_DIR'
export PRE_WRITE_PATH_GUARD_LEDGER='$PRE_WRITE_PATH_GUARD_LEDGER'

# allow case
cli_pre_write_check /Users/josh/Developer/flywheel/.flywheel/h1.md flywheel-helper-test
echo \"allow_rc=\$?\"

# deny case
cli_pre_write_check /Users/josh/Developer/skillos/.flywheel/h2.md flywheel-helper-test
echo \"deny_rc=\$?\"
")
ALLOW_RC=$(printf '%s' "$HELPER_TEST" | grep '^allow_rc=' | cut -d= -f2)
DENY_RC=$(printf '%s' "$HELPER_TEST" | grep '^deny_rc=' | cut -d= -f2)
if [[ "$ALLOW_RC" == "0" && "$DENY_RC" == "1" ]]; then
  p "AG11 cli_pre_write_check helper (allow_rc=0, deny_rc=1)"
else
  f "AG11 helper got allow_rc=$ALLOW_RC deny_rc=$DENY_RC"
fi

# AG12 — v38e1.5 EXACT trauma repro (the 10 paths from the incident evidence)
TRAUMA_PATHS=(
  "/Users/josh/Developer/skillos/.flywheel/doctrine/README.md"
  "/Users/josh/Developer/skillos/.flywheel/doctrine/additive-v0.0.2-expansion-after-v0.0.1-under-extraction.md"
  "/Users/josh/Developer/skillos/.flywheel/doctrine/cross-language-audit-as-cousin-scout.md"
  "/Users/josh/Developer/skillos/.flywheel/doctrine/depth-axis-mismatch.md"
  "/Users/josh/Developer/skillos/.flywheel/doctrine/dispatch-assumes-fresh-extraction-but-package-preexists.md"
  "/Users/josh/Developer/skillos/.flywheel/doctrine/dispatch-expectation-vs-audit-verdict-divergence.md"
  "/Users/josh/Developer/skillos/.flywheel/doctrine/dispatch-premise-mismatch.md"
  "/Users/josh/Developer/skillos/.flywheel/doctrine/meta-aggregation-family.md"
  "/Users/josh/Developer/skillos/.flywheel/doctrine/source-project-aggregation-from-n-repos.md"
  "/Users/josh/Developer/skillos/.flywheel/doctrine/substrate-layer-shape-mismatch.md"
)
blocked=0
EMPTY_FOR_TRAUMA="$WORK/empty-trauma-policy"
mkdir -p "$EMPTY_FOR_TRAUMA"
for p_path in "${TRAUMA_PATHS[@]}"; do
  out=$(PRE_WRITE_PATH_GUARD_POLICY_DIR="$EMPTY_FOR_TRAUMA" bash "$GUARD" --path "$p_path" --bead flywheel-v38e1.5 --json 2>/dev/null)
  dec=$(printf '%s' "$out" | jq -r '.decision' 2>/dev/null)
  [[ "$dec" == "deny" ]] && blocked=$((blocked+1))
done
if [[ "$blocked" -eq 10 ]]; then
  p "AG12 v38e1.5 exact trauma repro: 10/10 paths blocked"
else
  f "AG12 v38e1.5 trauma blocked $blocked/10 paths"
fi

printf '\n%d passed, %d failed\n' "$pass" "$fail"
exit "$fail"
