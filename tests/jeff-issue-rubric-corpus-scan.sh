#!/usr/bin/env bash
# tests/jeff-issue-rubric-corpus-scan.sh
# E2E for the corpus-aware extension to .flywheel/scripts/jeff-issue-rubric.py
# Bead flywheel-wbnb AG6.
# NOT set -e — these tests deliberately exercise non-zero exit codes
# from the rubric (rc=1 axis fail, rc=4 same-issue blocker).
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
RUBRIC="$ROOT/.flywheel/scripts/jeff-issue-rubric.py"
TMPDIR="$(mktemp -d -t jdr-corpus.XXXXXX)"
trap 'rm -rf "$TMPDIR"' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Fixture A: prior-art match (Jeff already solved similar elsewhere).
# Carefully avoids prescriptive trigger words so all 8 axes hit high.
cat > "$TMPDIR/draft-prior-art.md" <<'EOF'
# Issue draft: ntm worktree contract gap

Tracking bead: flywheel-wbnb.

## Bug reality
Observed: ntm rejects the agent worktree branch in current contract.
Expected: branch resolution accepts the canonical agent worktree.
Repro: ```bash
ntm worktree status --agent foo
```
At commit Dicklesworthstone/ntm@7d1fc78e — leakage_count grows silent on this path.

## Duplicate search
Ran `gh issue list --repo Dicklesworthstone/ntm --search "worktree agent contract"`. Returned no visible duplicate.

## Source trace
- Dicklesworthstone/ntm/internal/worktree/list.go:42
- Dicklesworthstone/ntm/internal/worktree/list.go:88
- Dicklesworthstone/ntm/internal/worktree/parse.go:13
- Dicklesworthstone/ntm/internal/worktree/parse.go:55
At pushedAt 2026-05-09.

## Prior art
Prior art: Jeff already solved a similar contract in Dicklesworthstone/franken_engine
at `engine/internal/coord.rs:181` — non-prescriptive cross-ref.

## Shape precedent
Jeff's API convention: matches the pattern in Dicklesworthstone/asupersync
where `worktree.go:24` uses branch-fallback resolution.

## Anti-pattern note
Jeff explicitly rejected basename-only keying in Dicklesworthstone/beads
(see `internal/key.go:91`). This contract gap is consistent with that rejection.

## Out of scope
Out of scope: any rename of the worktree surface.
Not asking for code from Jeff.
EOF

# Fixture B: zero corpus citations (the canonical "unscanned" case)
cat > "$TMPDIR/draft-zero-citations.md" <<'EOF'
# Issue draft: noisy hostile entitled tone

Tracking bead: flywheel-wbnb.

Observed: behavior X is broken.
Expected: behavior Y.
Repro: ```bash
something
```
@commit abc123 — silent leakage.

## Duplicate search
Ran `gh issue list --search "X"`. No visible duplicate.

## Source trace
- some/file.go:12
- other/file.go:99
- third/file.go:200
- fourth/file.go:55
At commit abc123.

## Out of scope
Not asking for a PR. Out of scope: anything else.
EOF

# Fixture C: same-issue-already-filed (AG4 hard blocker)
cat > "$TMPDIR/draft-same-issue.md" <<'EOF'
# Issue draft: amend-don't-file scenario

Tracking bead: flywheel-wbnb.

## Bug reality
Observed: behavior X
Expected: behavior Y
Repro: ```bash
something
```
At commit Dicklesworthstone/ntm@abc123 — silent leakage_count rising.

## Duplicate search
Ran `gh issue list --search "X"`. No visible duplicate.

## Source trace
- Dicklesworthstone/ntm/internal/x.go:12
- Dicklesworthstone/ntm/internal/x.go:99
- Dicklesworthstone/ntm/internal/y.go:200
- Dicklesworthstone/ntm/internal/y.go:55
At commit abc123.

## Existing issue
See also issue #135 in Dicklesworthstone/ntm — already filed against this
contract gap, prior art there.

## Out of scope
Out of scope: rename. Not asking for a PR.
EOF

# Test 1: schema reflects 8 axes
if "$RUBRIC" --schema 2>&1 | python3 -c '
import json, sys
d=json.load(sys.stdin)
assert len(d["axes"])==8, f"expected 8 axes got {len(d['"'"'axes'"'"'])}"
assert "corpus_aware" in d["axes"], "corpus_aware missing"
assert "8_high" in d["decision_policy"], "8_high not in decision_policy"
assert "4" in d["exit_codes"], "exit code 4 not documented"
print("ok")
' >/dev/null 2>&1; then
  pass "schema reflects 8 axes + 8_high policy + exit code 4"
else
  fail "schema introspection"
fi

# Test 2: prior-art fixture passes (auto_post)
RA="$("$RUBRIC" --draft="$TMPDIR/draft-prior-art.md" --corpus-scan --json 2>/dev/null)"
RC=$?
if [[ "$RC" -eq 0 ]] \
  && jq -e '.decision == "auto_post" and .high_axes_count == 8 and .corpus_scan.same_issue_blocker == false' <<<"$RA" >/dev/null; then
  pass "prior-art fixture: rc=0, auto_post, all 8 high, no same-issue blocker"
else
  fail "prior-art fixture (rc=$RC): $(jq -c '{status, decision, high_axes_count, blocker:.corpus_scan.same_issue_blocker}' <<<"$RA")"
fi

# Test 3: prior-art fixture has corpus categories filled
if jq -e '
  .corpus_scan.categories.prior_art >= 1
  and .corpus_scan.categories.shape_precedent >= 1
  and .corpus_scan.categories.anti_pattern >= 1
  and .corpus_scan.categories.same_issue_already_filed == 0
' <<<"$RA" >/dev/null; then
  pass "prior-art fixture: 3 categories populated, same_issue=0"
else
  fail "prior-art fixture: categories=$(jq -c .corpus_scan.categories <<<"$RA")"
fi

# Test 4: prior-art fixture emits citation block markdown
if jq -e '.corpus_scan.citation_block_md | contains("Corpus-aware citations") and contains("Prior Art") and contains("Shape Precedent") and contains("Anti Pattern")' <<<"$RA" >/dev/null; then
  pass "prior-art fixture: citation_block_md includes 3 headed sections"
else
  fail "citation_block_md missing sections"
fi

# Test 5: zero-citations fixture FAILS corpus_aware axis
RB="$("$RUBRIC" --draft="$TMPDIR/draft-zero-citations.md" --corpus-scan --json 2>/dev/null)"
RC=$?
if [[ "$RC" -ne 0 ]] \
  && jq -e '.hard_fail_axes | index("corpus_aware") != null' <<<"$RB" >/dev/null; then
  pass "zero-citations fixture: rc!=0, corpus_aware in hard_fail_axes"
else
  fail "zero-citations fixture (rc=$RC): hard_fail=$(jq -c .hard_fail_axes <<<"$RB")"
fi

# Test 6: same-issue fixture exits with code 4 (AG4 blocker)
"$RUBRIC" --draft="$TMPDIR/draft-same-issue.md" --corpus-scan --json > "$TMPDIR/same-issue.json" 2>/dev/null && RC=0 || RC=$?
if [[ "$RC" -eq 4 ]] \
  && jq -e '.corpus_scan.same_issue_blocker == true and .corpus_scan.categories.same_issue_already_filed >= 1' < "$TMPDIR/same-issue.json" >/dev/null; then
  pass "same-issue fixture: exit=4 (AG4 hard blocker triggered)"
else
  fail "same-issue fixture (rc=$RC): blocker=$(jq -c .corpus_scan <<<"$(cat $TMPDIR/same-issue.json)")"
fi

# Test 7: doctor signal reports unscanned drafts
DOC_OUT="$TMPDIR/doctor.json"
"$RUBRIC" --doctor --draft-glob="$TMPDIR/draft-*.md" --json > "$DOC_OUT" 2>&1 || true
if jq -e '
  (.signals | map(.name) | index("jeff_drafts_unscanned_count") != null)
  and (.jeff_drafts_unscanned_count == 1)
  and (.top_unscanned_drafts | length == 1)
  and (.top_unscanned_drafts[0].draft_path | endswith("draft-zero-citations.md"))
' "$DOC_OUT" >/dev/null; then
  pass "doctor: jeff_drafts_unscanned_count=1 (only the zero-citations fixture)"
else
  fail "doctor signal mismatch: $(jq -c '{count: .jeff_drafts_unscanned_count, top: (.top_unscanned_drafts | map(.draft_path))}' "$DOC_OUT")"
fi

# Test 8: --corpus-scan flag is harmless when omitted (backwards-compat)
if "$RUBRIC" --draft="$TMPDIR/draft-prior-art.md" --json > "$TMPDIR/no-flag.json" 2>/dev/null; then
  if jq -e '.corpus_scan.categories.prior_art >= 1' "$TMPDIR/no-flag.json" >/dev/null; then
    pass "corpus_scan output is always present (backwards-compat for callers w/o --corpus-scan)"
  else
    fail "corpus_scan key missing without --corpus-scan flag"
  fi
else
  fail "rubric run without --corpus-scan returned non-zero unexpectedly"
fi

# Test 9: --corpus-scan AG4 blocker only fires when flag is set
"$RUBRIC" --draft="$TMPDIR/draft-same-issue.md" --json > "$TMPDIR/no-flag-same.json" 2>/dev/null && RC=0 || RC=$?
if [[ "$RC" -ne 4 ]]; then
  pass "AG4 blocker (rc=4) gated by --corpus-scan flag (rc=$RC without flag)"
else
  fail "rc=4 fired without --corpus-scan flag (should not)"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
