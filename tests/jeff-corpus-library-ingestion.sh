#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
REPOS_JSONL="${JEFF_INTEL_REPOS_JSONL:-$HOME/.local/state/jeff-intel/repos.jsonl}"
PROGRESS_JSONL="${JEFF_INTEL_PROGRESS_JSONL:-$HOME/.local/state/jeff-intel/index-progress.jsonl}"
LEARNINGS_DIR="${JEFF_INTEL_LEARNINGS_DIR:-$HOME/.local/state/jeff-intel/learnings}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/jeff-corpus-library-ingestion.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    printf '  expr=%s file=%s\n' "$expr" "$file" >&2
    jq . "$file" >&2 || true
  fi
}

repo_state_check() {
  jq -s '{
    total:length,
    verified:(map(select(.index_status == "verified_indexed")) | length),
    indexed_at:(map(select((.indexed_at // "") != "")) | length),
    skipped:(map(select(.index_status == "skipped_budget")) | length),
    qdrant_collections:(map(select((.qdrant_collection // "") != "")) | length),
    unique_qdrant_collections:(map(.qdrant_collection // empty) | unique | length)
  }' "$REPOS_JSONL" >"$TMP/repos.json"
  assert_jq "$TMP/repos.json" '.total == 177 and .verified == 177 and .indexed_at == 177 and .skipped == 0' "AG1 verified repo state covers 177 repos"
  assert_jq "$TMP/repos.json" '.qdrant_collections == 177 and .unique_qdrant_collections == 177' "AG2 qdrant collection refs cover 177 unique repos"
}

progress_resume_check() {
  jq -s '{
    verified_rows:(map(select(.event == "index_verified_codebase")) | length),
    started_rows:(map(select(.event == "index_started")) | length),
    has_resume_state:(length > 0)
  }' "$PROGRESS_JSONL" >"$TMP/progress.json"
  assert_jq "$TMP/progress.json" '.has_resume_state == true and .verified_rows > 0 and .started_rows > 0' "AG3 persistent progress supports resume-after-interrupt"
}

learning_artifact_check() {
  find "$LEARNINGS_DIR" -maxdepth 1 -type f -name '*.md' | sort >"$TMP/learnings.txt"
  local count
  count="$(wc -l <"$TMP/learnings.txt" | tr -d ' ')"
  if [ "$count" -ge 10 ]; then
    pass "AG5 ten per-query learning artifacts exist"
  else
    fail "AG5 ten per-query learning artifacts exist"
  fi

  local required_ok=1
  while IFS= read -r path; do
    if ! rg -q '^## What We Found$' "$path" || ! rg -q '^## Gap In Flywheel$' "$path" || ! rg -q '^## Recommended Bead/Memory Action$' "$path"; then
      required_ok=0
      printf '  missing required section: %s\n' "$path" >&2
    fi
  done <"$TMP/learnings.txt"
  if [ "$required_ok" -eq 1 ]; then
    pass "AG5 learning artifacts carry required sections"
  else
    fail "AG5 learning artifacts carry required sections"
  fi

  for fixture in 01-error-handling-patterns.md 06-doctor-signal-patterns.md 10-cli-canonical-scoping.md; do
    test -s "$LEARNINGS_DIR/$fixture" || required_ok=0
  done
  if [ "$required_ok" -eq 1 ]; then
    pass "AG9 fixture query artifacts present"
  else
    fail "AG9 fixture query artifacts present"
  fi
}

derived_beads_check() {
  br list --all --json --limit 0 >"$TMP/beads.json"
  # Shape-tolerant: tolerate both top-level array (legacy br shape) and
  # object-with-issues key (current br 0.2.5 shape). flywheel-keji
  # 2026-05-09: bead-keji rework after br shape drift exposed by
  # flywheel-1lpv 2026-05-04 validation.
  # flywheel-9nhx closeout 2026-05-15: AG6 proves derived beads were filed;
  # they may now be closed, so the query must include all statuses.
  assert_jq "$TMP/beads.json" \
    '[(if type == "object" then .issues else . end)[] | select(((.labels // []) | index("jeff-corpus-derived")) and (.priority <= 1))] | length >= 5' \
    "AG6 five P0/P1 jeff-corpus-derived beads exist"
}

derived_beads_shape_fixture_check() {
  # flywheel-keji fixture: prove the AG6 jq is shape-tolerant on BOTH
  # br list shapes. Uses a tiny synthetic input with a single matching
  # row in each shape.
  cat >"$TMP/beads-array.json" <<'EOF'
[{"id":"f-1","labels":["jeff-corpus-derived"],"priority":0},
 {"id":"f-2","labels":["jeff-corpus-derived"],"priority":1},
 {"id":"f-3","labels":["jeff-corpus-derived"],"priority":1},
 {"id":"f-4","labels":["jeff-corpus-derived"],"priority":1},
 {"id":"f-5","labels":["jeff-corpus-derived"],"priority":0}]
EOF
  cat >"$TMP/beads-object.json" <<'EOF'
{"issues":[{"id":"f-1","labels":["jeff-corpus-derived"],"priority":0},
 {"id":"f-2","labels":["jeff-corpus-derived"],"priority":1},
 {"id":"f-3","labels":["jeff-corpus-derived"],"priority":1},
 {"id":"f-4","labels":["jeff-corpus-derived"],"priority":1},
 {"id":"f-5","labels":["jeff-corpus-derived"],"priority":0}]}
EOF
  assert_jq "$TMP/beads-array.json" \
    '[(if type == "object" then .issues else . end)[] | select(((.labels // []) | index("jeff-corpus-derived")) and (.priority <= 1))] | length == 5' \
    "AG6-fixture array shape (5 matching beads)"
  assert_jq "$TMP/beads-object.json" \
    '[(if type == "object" then .issues else . end)[] | select(((.labels // []) | index("jeff-corpus-derived")) and (.priority <= 1))] | length == 5' \
    "AG6-fixture object-with-issues shape (5 matching beads)"
}

canonical_paths_check() {
  if rg -q '^jeff_intel_state_dir[[:space:]]' "$ROOT/.flywheel/canonical-paths.txt" \
    && rg -q '^jeff_intel_learnings_dir[[:space:]]' "$ROOT/.flywheel/canonical-paths.txt"; then
    pass "AG8 jeff-intel state and learnings canonical paths exist"
  else
    fail "AG8 jeff-intel state and learnings canonical paths exist"
  fi
}

doctor_signal_check() {
  "$ROOT/.flywheel/scripts/jeff-corpus-doctor.sh" --json >"$TMP/doctor.json" 2>/dev/null || true
  assert_jq "$TMP/doctor.json" '.jeff_corpus_indexed_count == 177 and .jeff_corpus_index_target == 177' "AG7 doctor exposes jeff_corpus_indexed_count"
}

main() {
  command -v jq >/dev/null || { printf 'missing jq\n' >&2; exit 69; }
  command -v rg >/dev/null || { printf 'missing rg\n' >&2; exit 69; }
  repo_state_check
  progress_resume_check
  learning_artifact_check
  derived_beads_check
  derived_beads_shape_fixture_check
  canonical_paths_check
  doctor_signal_check
  if [ "$fail_count" -gt 0 ]; then
    printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
    exit 1
  fi
  printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
}

main "$@"
