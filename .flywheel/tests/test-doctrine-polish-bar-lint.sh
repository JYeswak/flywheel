#!/usr/bin/env bash
# .flywheel/tests/test-doctrine-polish-bar-lint.sh
# Filed by flywheel-ezz15: lock in doctrine-polish-bar-lint.sh 8-dim rubric.
#
# AG1 — syntax check
# AG2 — canonical-CLI triad (--info / --schema / --doctor / --examples / --help)
# AG3 — scoring a session-shipped doctrine emits valid JSON with 8 dimensions
# AG4 — high-quality fixture scores >= 0.625 (5/8 dims pass)
# AG5 — minimal fixture scores < 0.5 (less than 4/8 dims pass)
# AG6 — --apply-receipts writes to ledger
# AG7 — tick-driver-manifest.json contains doctrine-polish-bar-lint entry
# AG8 — exit codes: 0 ok, 2 usage error
# AG9 — directory input emits JSON array

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/doctrine-polish-bar-lint.sh"
MANIFEST="$ROOT/.flywheel/scripts/tick-driver-manifest.json"

pass=0
fail=0
p() { pass=$((pass+1)); printf 'PASS %s\n' "$1"; }
f() { fail=$((fail+1)); printf 'FAIL %s\n' "$1" >&2; }

# AG1 syntax
if bash -n "$SCRIPT" 2>/dev/null; then
  p "AG1 bash -n syntax"
else
  f "AG1 bash -n syntax"
  exit 1
fi

# AG2 canonical-CLI triad
for surface in --info --schema --examples --help --doctor; do
  if "$SCRIPT" "$surface" >/dev/null 2>&1; then
    : # ok
  else
    f "AG2 surface $surface failed"
  fi
done
p "AG2 canonical-CLI triad (--info/--schema/--examples/--help/--doctor)"

# AG3 score known doctrine + validate JSON shape
result=$("$SCRIPT" "$ROOT/.flywheel/doctrine/forward-link-doctrine-doc-recipe.md" 2>/dev/null)
if echo "$result" | jq -e '.schema_version == "doctrine-polish-bar-lint/v1" and (.dimensions | length == 8) and (.pass_count | type == "number")' >/dev/null; then
  p "AG3 valid JSON with 8 dimensions"
else
  f "AG3 invalid JSON shape: $result"
fi

# AG4 high-quality fixture
TMP="$(mktemp -d -t polish-test.XXXXXX)"
trap '[ -z "$TMP" ] || rm -rf "$TMP"' EXIT
cat >"$TMP/rich.md" <<'EOF'
---
title: Rich Test Doctrine
type: doctrine
---

# Rich Test Doctrine

## TL;DR (what / who / where)

This is the rich-doctrine fixture for testing. It's for operators of the
flywheel substrate working in `.flywheel/` to verify the polish-bar lint
heuristics detect well-formed doctrine docs across all 8 dimensions.

## Why this exists

Failure mode: shipping doctrine docs that don't meet the polish-bar
rubric. Anti-pattern: skipping the orientation paragraph. The trauma class
is "drift" — readers lose context after one re-read.

## Mental model

```mermaid
graph TD
  A[Doctrine doc] --> B[Polish-bar lint]
  B --> C{8 dims pass?}
  C -->|yes| D[Canonical]
  C -->|no| E[Polish follow-up]
```

## How to apply

Walk through each dimension with concrete examples below. The narrative
flow ensures readers internalize the context before drilling into
specifics. Skip the basics — assume the reader knows what `.flywheel/` is
and where its substrate lives, but introduce the polish-bar rubric
explicitly because it's new.

The intent here is to load-bearing test the 8-dim rubric scoring against a
fixture that should clear every dimension cleanly. Each paragraph carries
50-300 words of substantive content, code examples are present, and we
cross-link to sister doctrines explicitly.

## Concrete example

```bash
# Run the polish-bar lint against a doctrine doc
.flywheel/scripts/doctrine-polish-bar-lint.sh .flywheel/doctrine/example.md
# Output: 8-dimension scorecard JSON
```

## Anti-pattern

Don't ship a doctrine doc without anti-pattern call-outs. Gotcha:
readers without anti-pattern guidance default to discovery-by-failure.

## Sister doctrine and beyond

Tip: cross-link to .flywheel/doctrine/forward-link-doctrine-doc-recipe.md
and feedback_canonical_cli_at_dispatch.md. The non-obvious insight is
that polish-bar dimensions are designed to harvest into faqj2's
self-calibration probe.

Beyond the basics: when readers grok the rubric, they internalize the
polish-bar discipline as a checklist rather than an audit step.
EOF

rich_score=$("$SCRIPT" "$TMP/rich.md" 2>/dev/null | jq -r '.overall_score')
if [ "$(echo "$rich_score >= 0.625" | bc -l 2>/dev/null)" = "1" ]; then
  p "AG4 rich fixture scores >= 0.625 (got $rich_score)"
else
  f "AG4 rich fixture scored only $rich_score (expected >= 0.625)"
fi

# AG5 minimal fixture should score low
cat >"$TMP/minimal.md" <<'EOF'
# Bare doc

stuff happens.
EOF
min_score=$("$SCRIPT" "$TMP/minimal.md" 2>/dev/null | jq -r '.overall_score')
if [ "$(echo "$min_score < 0.5" | bc -l 2>/dev/null)" = "1" ]; then
  p "AG5 minimal fixture scores < 0.5 (got $min_score)"
else
  f "AG5 minimal fixture scored $min_score (expected < 0.5)"
fi

# AG6 --apply-receipts writes to ledger
LEDGER_TEST="$TMP/test-ledger.jsonl"
"$SCRIPT" "$TMP/rich.md" --apply-receipts --ledger "$LEDGER_TEST" >/dev/null 2>&1
if [ -f "$LEDGER_TEST" ] && [ "$(wc -l < "$LEDGER_TEST")" -ge 1 ]; then
  p "AG6 --apply-receipts writes to ledger"
else
  f "AG6 ledger not written or empty"
fi

# AG7 tick-driver-manifest entry (primitives array)
if jq -e '.primitives[] | select(.name == "doctrine-polish-bar-lint")' "$MANIFEST" >/dev/null 2>&1; then
  p "AG7 tick-driver-manifest entry present"
else
  f "AG7 tick-driver-manifest entry MISSING"
fi

# AG8 exit codes
"$SCRIPT" --info >/dev/null 2>&1
rc_info=$?
"$SCRIPT" 2>/dev/null
rc_usage=$?
if [ "$rc_info" = "0" ]; then
  p "AG8a --info exits 0"
else
  f "AG8a --info exits $rc_info (expected 0)"
fi
if [ "$rc_usage" = "2" ]; then
  p "AG8b missing arg exits 2"
else
  f "AG8b missing arg exits $rc_usage (expected 2)"
fi

# AG9 directory input → JSON array
dir_result=$("$SCRIPT" "$TMP" 2>/dev/null)
if echo "$dir_result" | jq -e 'type == "array" and length >= 2' >/dev/null 2>&1; then
  p "AG9 directory input emits JSON array"
else
  f "AG9 directory output not array"
fi

printf '\nsummary pass=%d fail=%d\n' "$pass" "$fail"
[ "$fail" -eq 0 ] || exit 1
