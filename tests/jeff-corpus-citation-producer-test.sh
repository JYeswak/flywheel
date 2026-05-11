#!/usr/bin/env bash
# Tests for jeff-corpus-citation-producer.py (bead flywheel-dooai).
# Producer is the orch-side companion to flywheel-wbnb's consumer
# (jeff-issue-rubric.py --corpus-scan). Bypasses MCP via stub
# results.jsonl so this test runs without socraticode connectivity.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
PRODUCER="$ROOT/.flywheel/scripts/jeff-corpus-citation-producer.py"
RUBRIC="$ROOT/.flywheel/scripts/jeff-issue-rubric.py"
FIXTURES="$ROOT/.flywheel/audit/flywheel-dooai/fixtures"
TMP="$(mktemp -d -t jeff-corpus-test.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

pass=0; fail=0
ok()  { printf 'PASS %s\n' "$1"; pass=$((pass+1)); }
bad() { printf 'FAIL %s\n' "$1" >&2; fail=$((fail+1)); }
expect_rc() { [[ "$1" == "$2" ]] && ok "$3 rc=$1" || bad "$3 expected_rc=$2 got=$1"; }
expect_jq() { jq -e "$2" "$1" >/dev/null && ok "$3" || { bad "$3"; jq . "$1" >&2 || true; }; }

# --- Sanity ---
[[ -x "$PRODUCER" ]] || { bad "producer not executable: $PRODUCER"; exit 1; }
python3 -c 'import ast; ast.parse(open("'"$PRODUCER"'").read())' && ok "producer syntax ok" || bad "producer syntax broken"

# --- AG3 strict gates ---
"$PRODUCER" --info > "$TMP/info.json"
expect_jq "$TMP/info.json" '.name == "jeff-corpus-citation-producer.py" and .version and (.capabilities|length>=3)' "AG3.1 --info name+version+capabilities"
"$PRODUCER" --schema > "$TMP/schema.json"
expect_jq "$TMP/schema.json" '.input_schema and .output_schema' "AG3.2 --schema input/output"
"$PRODUCER" --examples > "$TMP/examples.json"
expect_jq "$TMP/examples.json" '.examples | length >= 3' "AG3.3 --examples >= 3"
"$PRODUCER" doctor > "$TMP/doctor.json"
expect_jq "$TMP/doctor.json" '.checks | length >= 5' "AG3.4 doctor .checks >= 5"

# --- AG1: extract-terms from a sample draft ---
"$PRODUCER" extract-terms "$FIXTURES/sample-draft.md" --json > "$TMP/terms.json"
expect_jq "$TMP/terms.json" '.primary_repo == null or .primary_repo == "ntm"' "extract-terms primary_repo"
expect_jq "$TMP/terms.json" '.queries | length >= 1' "extract-terms emits queries"
expect_jq "$TMP/terms.json" '.keywords | length >= 3' "extract-terms emits keywords"

# --- AG3: emit citation block from stub MCP results ---
"$PRODUCER" emit --from-results "$FIXTURES/sample-results.jsonl" --draft "$FIXTURES/sample-draft.md" --emit > "$TMP/emitted.md"
grep -q '## Corpus-aware citations' "$TMP/emitted.md" && ok "emit produces citation block header" || bad "emit header missing"
grep -q '### Prior Art' "$TMP/emitted.md" && ok "emit produces Prior Art section" || bad "Prior Art section missing"
grep -q '### Shape Precedent' "$TMP/emitted.md" && ok "emit produces Shape Precedent section" || bad "Shape Precedent missing"
grep -q '### Anti Pattern' "$TMP/emitted.md" && ok "emit produces Anti Pattern section" || bad "Anti Pattern missing"
grep -q '### Same Issue Already Filed' "$TMP/emitted.md" && ok "emit produces Same Issue section" || bad "Same Issue missing"

# --- AG2: --inject mode replaces section in-place ---
cp "$FIXTURES/sample-draft.md" "$TMP/draft-inject.md"
"$PRODUCER" emit --from-results "$FIXTURES/sample-results.jsonl" --draft "$TMP/draft-inject.md" --inject > "$TMP/inject.json"
expect_jq "$TMP/inject.json" '.action == "appended" or .action == "replaced"' "inject reports action"
grep -q '## Corpus-aware citations' "$TMP/draft-inject.md" && ok "inject modified draft in-place" || bad "inject failed to modify draft"

# --- AG2: --inject is REPLACE when section already exists ---
"$PRODUCER" emit --from-results "$FIXTURES/sample-results.jsonl" --draft "$TMP/draft-inject.md" --inject > "$TMP/inject2.json"
expect_jq "$TMP/inject2.json" '.action == "replaced"' "second inject is REPLACE not APPEND"

# --- AG3: round-trip with consumer (categorize_corpus_citations) ---
# Inject the producer's emitted block into a fresh draft + run the rubric's
# corpus-aware scoring to confirm round-trip.
cp "$FIXTURES/sample-draft.md" "$TMP/draft-rt.md"
"$PRODUCER" emit --from-results "$FIXTURES/sample-results.jsonl" --draft "$TMP/draft-rt.md" --inject > /dev/null
# rubric returns rc=4 when same_issue_blocker fires — that's the SUCCESSFUL
# AG4 outcome (consumer detected the already-filed cue). Capture stdout and
# rc separately; only accept rc in {0, 4}.
set +e
RUBRIC_OUT=$("$RUBRIC" --draft "$TMP/draft-rt.md" --corpus-scan --json 2>/dev/null)
rubric_rc=$?
set -e
echo "$RUBRIC_OUT" > "$TMP/rubric.json"
if [[ "$rubric_rc" -eq 0 || "$rubric_rc" -eq 4 ]]; then
  ok "rubric --corpus-scan rc=${rubric_rc} (0=clean, 4=same_issue_blocker)"
else
  bad "rubric --corpus-scan rc=${rubric_rc} (expected 0 or 4)"
fi
# Round-trip critical assertions: rubric sees corpus_scan envelope + categorizes hits
expect_jq "$TMP/rubric.json" '.corpus_scan and (.corpus_scan.categories|type=="object")' "rubric round-trip: corpus_scan envelope present"
# Total citations across buckets > 0
TOTAL_CITES=$(jq -r '[.corpus_scan.categories[]] | add // 0' "$TMP/rubric.json")
[[ "$TOTAL_CITES" -ge 4 ]] && ok "rubric round-trip: total citations >= 4 (got $TOTAL_CITES)" || bad "rubric round-trip: insufficient citations ($TOTAL_CITES)"
# AG4 critical: same_issue_blocker triggered (consumer detected the already-filed cue)
expect_jq "$TMP/rubric.json" '.corpus_scan.same_issue_blocker == true' "AG4 round-trip: same_issue_blocker triggered"
# Same-issue category count >= 1
SAME_ISSUE_COUNT=$(jq -r '.corpus_scan.categories.same_issue_already_filed // 0' "$TMP/rubric.json")
[[ "$SAME_ISSUE_COUNT" -ge 1 ]] && ok "rubric same_issue_already_filed count >= 1 (got $SAME_ISSUE_COUNT)" || bad "rubric same_issue count == 0"

# --- Empty results yields explanatory marker ---
echo '' > "$TMP/empty-results.jsonl"
"$PRODUCER" emit --from-results "$TMP/empty-results.jsonl" --draft "$FIXTURES/sample-draft.md" --emit > "$TMP/empty.md"
grep -q 'no corpus hits' "$TMP/empty.md" && ok "empty results emit explanatory marker" || bad "empty results missing marker"

# --- Doctor health on this substrate ---
"$PRODUCER" doctor > "$TMP/doc.json"
expect_jq "$TMP/doc.json" '.status == "pass" or .status == "warn"' "doctor status pass/warn (not fail)"

# --- AG4: search-same-issues runs without crashing (no network = []) ---
"$PRODUCER" search-same-issues --repo ntm --query 'queued chevron stuck' > "$TMP/same.json" 2>/dev/null || true
expect_jq "$TMP/same.json" '.mode == "search-same-issues" and (.hits | type == "array")' "search-same-issues envelope shape"

printf 'SUMMARY pass=%d fail=%d\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]]
