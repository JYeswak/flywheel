#!/usr/bin/env bash
# tests/stale-in-progress-reaper-carve-out.sh
# Bead flywheel-8ht5f AG4: label-based carve-out tests for the reaper.
# Sibling to tests/stale-in-progress-reaper.sh which covers the
# original commit/callback/assignee classification.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/stale-in-progress-reaper.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/stale-carve-out.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Build a fixture beads.db with labels table populated for a few of the
# fixture beads. The reaper's fetch_label_map() reads this DB directly.
FIXTURE_DB="$TMP/beads.db"
sqlite3 "$FIXTURE_DB" <<'SQL'
CREATE TABLE issues (
  id TEXT PRIMARY KEY,
  title TEXT,
  status TEXT,
  updated_at TEXT,
  priority INTEGER,
  assignee TEXT
);
CREATE TABLE labels (
  issue_id TEXT NOT NULL,
  label TEXT NOT NULL,
  PRIMARY KEY (issue_id, label)
);

-- 5 fixture beads, all in_progress, all old (zero recent activity)
INSERT INTO issues VALUES ('fix-stale-plain',     '[fix] plain stale',         'in_progress','2026-04-01T00:00:00Z',1,'unassigned');
INSERT INTO issues VALUES ('fix-upstream-track',  '[fix] tracks upstream',     'in_progress','2026-04-01T00:00:00Z',1,'');
INSERT INTO issues VALUES ('fix-cross-orch',      '[fix] cross-orch coord',    'in_progress','2026-04-01T00:00:00Z',1,'');
INSERT INTO issues VALUES ('fix-joshua-gated',    '[fix] joshua-gated decision','in_progress','2026-04-01T00:00:00Z',1,'');
INSERT INTO issues VALUES ('fix-defer-gated',     '[fix] defer-gated wait',    'in_progress','2026-04-01T00:00:00Z',1,'');

-- Carve-out labels on 4 of them (the 5th is a "plain stale" control case)
INSERT INTO labels VALUES ('fix-upstream-track', 'upstream-tracker');
INSERT INTO labels VALUES ('fix-cross-orch',     'cross-orch-active');
INSERT INTO labels VALUES ('fix-joshua-gated',   'joshua-gated');
INSERT INTO labels VALUES ('fix-defer-gated',    'defer-gated');
SQL

# br list fixture matching the rows in the DB
cat > "$TMP/br-list.json" <<'EOF'
[
  {"id":"fix-stale-plain","title":"[fix] plain stale","status":"in_progress","assignee":"unassigned","updated_at":"2026-04-01T00:00:00Z","priority":1},
  {"id":"fix-upstream-track","title":"[fix] tracks upstream","status":"in_progress","assignee":"","updated_at":"2026-04-01T00:00:00Z","priority":1},
  {"id":"fix-cross-orch","title":"[fix] cross-orch coord","status":"in_progress","assignee":"","updated_at":"2026-04-01T00:00:00Z","priority":1},
  {"id":"fix-joshua-gated","title":"[fix] joshua-gated decision","status":"in_progress","assignee":"","updated_at":"2026-04-01T00:00:00Z","priority":1},
  {"id":"fix-defer-gated","title":"[fix] defer-gated wait","status":"in_progress","assignee":"","updated_at":"2026-04-01T00:00:00Z","priority":1}
]
EOF

# JSONL append helper (no-op if the canonical lib path doesn't resolve in the test env)
cat > "$TMP/jsonl-append.sh" <<'SH'
fw_jsonl_append_validated() {
  local path="$1" row="$2"
  [[ -n "$row" ]] || return 1
  jq -e . >/dev/null <<<"$row" || return 1
  mkdir -p "$(dirname "$path")"
  printf '%s\n' "$row" >>"$path"
}
SH

# Empty repo for git log probe
mkdir -p "$TMP/repo"
git -C "$TMP/repo" init -q

LEDGER="$TMP/ledger.jsonl"
base_env=(
  "STALE_REAPER_NOW=2026-05-10T05:00:00Z"
  "STALE_REAPER_BR_LIST_FIXTURE=$TMP/br-list.json"
  "STALE_REAPER_DB=$FIXTURE_DB"
  "STALE_REAPER_LEDGER=$LEDGER"
  "FLYWHEEL_JSONL_APPEND_LIB=$TMP/jsonl-append.sh"
)

# Run dry scan
env "${base_env[@]}" "$SCRIPT" --repo "$TMP/repo" --json > "$TMP/dry.json" 2>&1
RC=$?

# Test 1: 5 total, 1 stale (only fix-stale-plain), 4 carved-out
if [[ "$RC" -eq 0 ]] && jq -e '
  .total_in_progress == 5
  and .stale_count == 1
  and .carved_out_count == 4
  and .active_count == 0
' "$TMP/dry.json" >/dev/null 2>&1; then
  pass "5 fixture beads: 1 stale + 4 carved-out + 0 active"
else
  fail "fixture counts wrong: $(jq -c '{total: .total_in_progress, stale: .stale_count, carved: .carved_out_count, active: .active_count}' "$TMP/dry.json" 2>&1)"
fi

# Test 2: stale candidate is the only un-labeled bead
if jq -e '
  .candidates as $c
  | ($c | length) == 1 and ($c[0].bead_id == "fix-stale-plain")
' "$TMP/dry.json" >/dev/null 2>&1; then
  pass "only fix-stale-plain is a STALE candidate (no carve-out label)"
else
  fail "stale candidate id mismatch: $(jq -c '.candidates' "$TMP/dry.json")"
fi

# Test 3: each carve-out label correctly protects its bead
for label_id_pair in \
  "upstream-tracker:fix-upstream-track" \
  "cross-orch-active:fix-cross-orch" \
  "joshua-gated:fix-joshua-gated" \
  "defer-gated:fix-defer-gated"
do
  label="${label_id_pair%%:*}"
  id="${label_id_pair#*:}"
  if jq -e --arg id "$id" --arg lbl "$label" '
    .classified
    | map(select(.bead_id == $id))
    | (length == 1)
      and (.[0].classification == "CARVED_OUT")
      and (.[0].carve_out_labels_matched | index($lbl) != null)
  ' "$TMP/dry.json" >/dev/null 2>&1; then
    pass "carve-out label '$label' protects $id"
  else
    fail "carve-out '$label' on $id failed: $(jq -c --arg id "$id" '.classified | map(select(.bead_id == $id))' "$TMP/dry.json")"
  fi
done

# Test 4: carve_out_labels list in output equals canonical default
if jq -e '
  .carve_out_labels == ["upstream-tracker","cross-orch-active","joshua-gated","defer-gated"]
' "$TMP/dry.json" >/dev/null 2>&1; then
  pass "carve_out_labels default == canonical 4-label list"
else
  fail "carve_out_labels mismatch: $(jq -c .carve_out_labels "$TMP/dry.json")"
fi

# Test 5: carved_out_preview entries carry the matched-label list
if jq -e '
  .carved_out_preview
  | length == 4
  and (map(.carve_out_labels_matched | length > 0) | all)
' "$TMP/dry.json" >/dev/null 2>&1; then
  pass "carved_out_preview entries carry matched label lists"
else
  fail "carved_out_preview shape: $(jq -c .carved_out_preview "$TMP/dry.json")"
fi

# Test 6: STALE_REAPER_CARVE_OUTS env override widens or shrinks list
env "${base_env[@]}" "STALE_REAPER_CARVE_OUTS=joshua-gated" "$SCRIPT" --repo "$TMP/repo" --json > "$TMP/narrowed.json" 2>&1
if jq -e '
  .carved_out_count == 1
  and .stale_count == 4
  and .carve_out_labels == ["joshua-gated"]
' "$TMP/narrowed.json" >/dev/null 2>&1; then
  pass "STALE_REAPER_CARVE_OUTS=joshua-gated narrows protection (3 previously-protected become STALE)"
else
  fail "narrowed carve-out: $(jq -c '{carved: .carved_out_count, stale: .stale_count, lbl: .carve_out_labels}' "$TMP/narrowed.json")"
fi

# Test 7: ledger empty after dry-run (read-only invariant)
if [[ ! -s "$LEDGER" ]]; then
  pass "dry-run does not write ledger (read-only invariant)"
else
  fail "ledger written during dry-run: $(wc -l < "$LEDGER") lines"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
