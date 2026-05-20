#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/phase-c-fleet-validation.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/phase-c-fleet-validation.XXXXXX")"
ASSERTIONS=0

cleanup() {
  rm -rf "$TMP"
}
trap cleanup EXIT

fail() {
  printf 'ASSERTION FAILED: %s\n' "$1" >&2
  exit 1
}

pass() {
  ASSERTIONS=$((ASSERTIONS + 1))
}

assert_jq() {
  local file="$1" query="$2" label="$3"
  jq -e "$query" "$file" >/dev/null || fail "$label"
  pass
}

write_canonical() {
  local root="$1"
  mkdir -p \
    "$root/.flywheel/scripts" \
    "$root/.flywheel/specs" \
    "$root/.flywheel/doctrine/meta-learnings"
  printf '#!/usr/bin/env bash\nprintf activate\\n\n' >"$root/.flywheel/scripts/codex-goal-activate.sh"
  printf '#!/usr/bin/env bash\nprintf classify\\n\n' >"$root/.flywheel/scripts/pane-work-signal-classify.sh"
  printf '# taxonomy\n' >"$root/.flywheel/specs/pane-work-signal-taxonomy-v0.2.md"
  printf '# discipline\n' >"$root/.flywheel/doctrine/meta-learnings/codex-goal-mode-discipline.md"
}

copy_canonical() {
  local canonical="$1" repo="$2"
  mkdir -p \
    "$repo/.flywheel/scripts" \
    "$repo/.flywheel/specs" \
    "$repo/.flywheel/doctrine/meta-learnings"
  cp "$canonical/.flywheel/scripts/codex-goal-activate.sh" "$repo/.flywheel/scripts/codex-goal-activate.sh"
  cp "$canonical/.flywheel/scripts/pane-work-signal-classify.sh" "$repo/.flywheel/scripts/pane-work-signal-classify.sh"
  cp "$canonical/.flywheel/specs/pane-work-signal-taxonomy-v0.2.md" "$repo/.flywheel/specs/pane-work-signal-taxonomy-v0.2.md"
  cp "$canonical/.flywheel/doctrine/meta-learnings/codex-goal-mode-discipline.md" "$repo/.flywheel/doctrine/meta-learnings/codex-goal-mode-discipline.md"
}

fleet_json() {
  python3 - "$@" <<'PY'
import json
import sys
print(json.dumps(dict(item.split("=", 1) for item in sys.argv[1:])))
PY
}

canonical="$TMP/skillos"
write_canonical "$canonical"

match_repo="$TMP/match"
copy_canonical "$canonical" "$match_repo"
PHASE_C_FLEET_JSON="$(fleet_json "match=$match_repo")" "$SCRIPT" --canonical-root "$canonical" --json >"$TMP/match.json"
assert_jq "$TMP/match.json" '.orch_envelopes[0].overall_conformance_pct == 1' "4/4 shasum match scores 1.0"
assert_jq "$TMP/match.json" '.fleet_rollup.fleet_conformance_avg == 1' "rollup scores matching fleet as 1.0"

empty_repo="$TMP/empty"
mkdir -p "$empty_repo"
PHASE_C_FLEET_JSON="$(fleet_json "empty=$empty_repo")" "$SCRIPT" --canonical-root "$canonical" --json >"$TMP/empty.json"
assert_jq "$TMP/empty.json" '.orch_envelopes[0].overall_conformance_pct == 0' "0/4 files scores 0.0"

allowed_repo="$TMP/allowed"
copy_canonical "$canonical" "$allowed_repo"
printf '\n# phase-c-allow-divergence: synthetic local patch\n' >>"$allowed_repo/.flywheel/scripts/codex-goal-activate.sh"
PHASE_C_FLEET_JSON="$(fleet_json "allowed=$allowed_repo")" "$SCRIPT" --canonical-root "$canonical" --json >"$TMP/allowed.json"
assert_jq "$TMP/allowed.json" '.orch_envelopes[0].phase_a_files.allowed_divergences == 1' "attributed mismatch flagged as allowed"
assert_jq "$TMP/allowed.json" '.orch_envelopes[0].divergence_findings[] | select(.class=="shasum_mismatch_attributed" and .severity=="allowed")' "allowed mismatch has divergence row"

bad_repo="$TMP/bad"
copy_canonical "$canonical" "$bad_repo"
printf '\n# unattributed local change\n' >>"$bad_repo/.flywheel/scripts/codex-goal-activate.sh"
PHASE_C_FLEET_JSON="$(fleet_json "bad=$bad_repo")" "$SCRIPT" --canonical-root "$canonical" --json >"$TMP/bad.json"
assert_jq "$TMP/bad.json" '.orch_envelopes[0].divergence_findings[] | select(.class=="shasum_mismatch_unattributed" and .severity=="gap")' "unattributed mismatch is divergence finding"

handoff="$TMP/handoff.md"
report="$TMP/report.md"
PHASE_C_FLEET_JSON="$(fleet_json "bad=$bad_repo" "empty=$empty_repo")" "$SCRIPT" \
  --canonical-root "$canonical" \
  --report "$report" \
  --handoff "$handoff" \
  --json >"$TMP/rollup.json"
assert_jq "$TMP/rollup.json" '.schema_version == "phase-c-fleet-validation/v1" and (.orch_envelopes | length == 2) and (.fleet_rollup.top_divergence_classes | length >= 1)' "JSON rollup parseable and complete"
rg -q 'shasum_mismatch_unattributed' "$handoff" || fail "handoff enumerates divergences"
pass
test -s "$report" || fail "report written"
pass

printf 'PASS phase-c-fleet-validation-smoke assertions=%s\n' "$ASSERTIONS"
