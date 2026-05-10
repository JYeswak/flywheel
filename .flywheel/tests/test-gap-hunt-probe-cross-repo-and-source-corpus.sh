#!/usr/bin/env bash
# test-gap-hunt-probe-cross-repo-and-source-corpus.sh
#
# flywheel-8vw0o regression: assert gap-hunt-probe.sh wired-but-cold
# detector recognizes scripts that are alive via:
#
#   1. Sibling-repo references (cross-repo umbrella) — e.g. a script
#      under ~/.claude/skills/.flywheel/ that's referenced only by a
#      sibling repo's tests/unit/<name>.bats. Pre-fix, the probe missed
#      these because it only scanned the primary state-dir ledgers.
#      Signal: flywheel-2xdi.31 (tick_guard.sh false positive).
#
#   2. Runtime-sourced library modules under .d/ glob conventions —
#      e.g. doctor.d/part-01-*.sh, fleet.d/*.sh. These are sourced by
#      `for m in <dir>/*.sh; do source "$m"; done` so the basename
#      never appears in any source line, but the parent dir name (a
#      *.d marker) does. Pre-fix the probe missed these.
#      Signal: flywheel-2xdi.34, flywheel-2xdi.35.
#
# Acceptance gates from the bead body:
#   1. Sibling-repo cross-umbrella references are detected (no false flag)
#   2. Runtime source-line refs detected (basename match)
#   3. Runtime *.d/ parent-dir refs detected (glob-source convention)
#   4. Negative: target with NO references in any corpus is still flagged
#   5. bash -n clean

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
PROBE="${GAP_HUNT_PROBE_BIN:-$ROOT/.flywheel/scripts/gap-hunt-probe.sh}"

pass_count=0
fail_count=0
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

if [[ ! -f "$PROBE" ]]; then
  printf 'SKIP gap-hunt-probe.sh missing at %s\n' "$PROBE"
  exit 77
fi

# T1: bash -n clean
bash -n "$PROBE" && pass "T1 gap-hunt-probe.sh passes bash -n" || fail "T1 syntax error"

# T2: static grep — script source contains the new helpers
grep -q "def runtime_source_corpus" "$PROBE" \
  && grep -q "def sibling_repo_ledger_corpus" "$PROBE" \
  && pass "T2 gap-hunt-probe.sh defines runtime_source_corpus + sibling_repo_ledger_corpus" \
  || fail "T2 helper functions missing"

# T3: static grep — probe_wired_but_cold uses three corpora
grep -q "in_local " "$PROBE" \
  && grep -q "in_sibling " "$PROBE" \
  && grep -q "in_source " "$PROBE" \
  && pass "T3 probe_wired_but_cold checks three corpora (local + sibling + source)" \
  || fail "T3 wired-but-cold detector not using three corpora"

# T4: static grep — probe checks .d parent dir for glob-sourced modules
grep -qE "endswith.*\\.d.*sibling|\\.d.*source_text|parent_name.endswith\\(.\\.d.\\)" "$PROBE" \
  && pass "T4 probe checks *.d parent-dir name against source corpus (glob-source convention)" \
  || fail "T4 parent-dir .d marker check missing"

# Set up isolated fixture
FIXTURE_ROOT="$(mktemp -d -t gap-hunt-8vw0o.XXXXXX)"
trap '
  rm -rf "$FIXTURE_ROOT" 2>/dev/null
' EXIT

mkdir -p "$FIXTURE_ROOT/state" \
         "$FIXTURE_ROOT/claude/skills/.flywheel/scripts" \
         "$FIXTURE_ROOT/claude/skills/.flywheel/lib/doctor.d" \
         "$FIXTURE_ROOT/claude/skills/.flywheel/lib/widget.d" \
         "$FIXTURE_ROOT/claude/skills/.flywheel/data" \
         "$FIXTURE_ROOT/repo/.flywheel/scripts" \
         "$FIXTURE_ROOT/repo/.flywheel/data" \
         "$FIXTURE_ROOT/dev/sibling-a/.flywheel" \
         "$FIXTURE_ROOT/dev/sibling-a/tests/unit" \
         "$FIXTURE_ROOT/dev/sibling-b/.flywheel"

# Empty primary state dir (so primary ledger doesn't help)
touch "$FIXTURE_ROOT/state/empty.jsonl"

# Empty INCIDENTS / AGENTS so other probes don't error
touch "$FIXTURE_ROOT/repo/AGENTS.md" "$FIXTURE_ROOT/repo/INCIDENTS.md" "$FIXTURE_ROOT/repo/README.md"
touch "$FIXTURE_ROOT/claude/CLAUDE.md"

# Three target scripts under skills/.flywheel/scripts/
TARGETS=(
  "alive-via-source-line.sh"
  "alive-via-sibling-test.sh"
  "alive-via-d-glob.sh"
  "cold-with-no-references-vw0o.sh"
)
for t in "${TARGETS[@]}"; do
  cat <<'TARGET' > "$FIXTURE_ROOT/claude/skills/.flywheel/scripts/$t"
#!/usr/bin/env bash
echo "fixture target"
TARGET
  chmod +x "$FIXTURE_ROOT/claude/skills/.flywheel/scripts/$t"
done

# T5 setup: alive-via-source-line is sourced by another shell script
cat <<'TARGET' > "$FIXTURE_ROOT/claude/skills/.flywheel/scripts/sources-the-target.sh"
#!/usr/bin/env bash
source "/path/to/alive-via-source-line.sh"
TARGET

# T6 setup: alive-via-sibling-test gets a .bats test in sibling-a
cat <<TARGET > "$FIXTURE_ROOT/dev/sibling-a/tests/unit/alive-via-sibling-test.bats"
#!/usr/bin/env bats
@test "fixture" { :; }
TARGET

# Sibling dispatch-log can stay empty; the .bats name corpus is enough
touch "$FIXTURE_ROOT/dev/sibling-a/.flywheel/dispatch-log.jsonl"
touch "$FIXTURE_ROOT/dev/sibling-b/.flywheel/dispatch-log.jsonl"

# T7 setup: alive-via-d-glob.sh — actually create a .d sibling alongside
# it AND a host script that glob-sources it via .d directory pattern.
mv "$FIXTURE_ROOT/claude/skills/.flywheel/scripts/alive-via-d-glob.sh" \
   "$FIXTURE_ROOT/claude/skills/.flywheel/lib/widget.d/alive-via-d-glob.sh"
cat <<'TARGET' > "$FIXTURE_ROOT/claude/skills/.flywheel/scripts/widget-host.sh"
#!/usr/bin/env bash
_widget_dir="${BASH_SOURCE[0]%/*}/widget.d"
for m in "${_widget_dir}"/*.sh; do
  source "${m}"
done
TARGET

# Make all fixture files appear recently modified
find "$FIXTURE_ROOT" -type f -exec touch {} +

# Run the probe with environment redirected to fixture
ENV_PROBE() {
  GAP_HUNT_REPO_ROOT="$FIXTURE_ROOT/repo" \
    GAP_HUNT_CLAUDE_ROOT="$FIXTURE_ROOT/claude" \
    GAP_HUNT_STATE_DIR="$FIXTURE_ROOT/state" \
    GAP_HUNT_LEDGER="$FIXTURE_ROOT/state/gap-hunt.jsonl" \
    GAP_HUNT_DEV_ROOT="$FIXTURE_ROOT/dev" \
    GAP_HUNT_SUBSTRATE_REGISTRY="$FIXTURE_ROOT/claude/skills/.flywheel/data/substrate-registry.json" \
    "$PROBE" --dry-run --json --quiet 2>/dev/null
}

OUT="$(ENV_PROBE)"
if [[ -z "$OUT" ]] || ! jq -e . >/dev/null 2>&1 <<<"$OUT"; then
  fail "T5-T8 probe did not return JSON; raw output: $OUT"
else
  COLD_IDS="$(printf '%s' "$OUT" | jq -r '.gap_ids[] | select(test("wired-but-cold:"))' 2>/dev/null)"

  # T5: alive-via-source-line is NOT cold (caught by source corpus name match)
  if grep -q "alive-via-source-line" <<<"$COLD_IDS"; then
    fail "T5 alive-via-source-line.sh falsely flagged cold: $COLD_IDS"
  else
    pass "T5 source-line ref catches alive-via-source-line.sh (basename in source line)"
  fi

  # T6: alive-via-sibling-test is NOT cold (caught by sibling-repo name corpus)
  if grep -q "alive-via-sibling-test" <<<"$COLD_IDS"; then
    fail "T6 alive-via-sibling-test.sh falsely flagged cold: $COLD_IDS"
  else
    pass "T6 sibling-repo test fixture name corpus catches alive-via-sibling-test.sh"
  fi

  # T7: alive-via-d-glob is NOT cold (caught by *.d/ parent-dir convention)
  if grep -q "alive-via-d-glob" <<<"$COLD_IDS"; then
    fail "T7 alive-via-d-glob.sh falsely flagged cold: $COLD_IDS"
  else
    pass "T7 *.d glob-source convention catches widget.d/alive-via-d-glob.sh"
  fi

  # T8: cold-with-no-references IS still cold (negative test). gap_ids may
  # truncate long paths; match the unique portion 'cold-w' present in the
  # script basename.
  if grep -q "cold-w" <<<"$COLD_IDS"; then
    pass "T8 negative — script with no refs in any corpus is still flagged cold"
  else
    fail "T8 negative — cold-with-no-references should still flag, but did not. cold_ids: $COLD_IDS"
  fi
fi

printf '\n=== test-gap-hunt-probe-cross-repo-and-source-corpus.sh ===\n'
printf 'pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]] && exit 0 || exit 1
