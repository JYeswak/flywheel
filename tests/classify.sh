#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/scripts/classify.py"
FIXTURE="$ROOT/fixtures/classify/source"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/flywheel-classify.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

if python3 -m py_compile "$SCRIPT"; then
  pass "syntax"
else
  fail "syntax"
fi

if python3 "$SCRIPT" --self-test --json >"$TMP/self-test.json" \
  && jq -e '.status == "pass" and .total_files == 22 and .null_class_count == 0 and .class_counts.engine == 9 and .class_counts.overlay == 6 and .class_counts."engine-after-rewrite" == 7' "$TMP/self-test.json" >/dev/null; then
  pass "self-test fixture contract"
else
  fail "self-test fixture contract"
fi

if python3 "$SCRIPT" --root "$FIXTURE" --output "$TMP/classification.jsonl" --json >"$TMP/summary.json" \
  && jq -e '.status == "pass" and .total_files == 22 and .null_class_count == 0' "$TMP/summary.json" >/dev/null \
  && [[ "$(wc -l <"$TMP/classification.jsonl" | tr -d ' ')" == "22" ]] \
  && jq -e 'all(.class; . != null)' "$TMP/classification.jsonl" >/dev/null; then
  pass "classification jsonl covers every fixture file"
else
  fail "classification jsonl covers every fixture file"
fi

if jq -s -e '[.[].class] | sort | unique == ["engine", "engine-after-rewrite", "overlay"]' "$TMP/classification.jsonl" >/dev/null; then
  pass "classification jsonl emits all classes"
else
  fail "classification jsonl emits all classes"
fi

if jq -s -e '
  any(.[]; .path == "README.md" and .class == "engine-after-rewrite")
  and any(.[]; .path == "ARCHITECTURE.md" and .class == "engine")
  and any(.[]; .path == "site/assets/loop-map.svg" and .class == "engine")
  and all(.[]; (.path | startswith(".flywheel/extraction/") | not))
' "$TMP/classification.jsonl" >/dev/null; then
  pass "public root docs and svg remain export candidates while generated extraction is skipped"
else
  fail "public root docs and svg remain export candidates while generated extraction is skipped"
fi

if python3 "$ROOT/scripts/depersonalize.py" --scan-table --root "$ROOT/fixtures/classify" --json >"$TMP/depersonalize.json" \
  && jq -e '.status == "pass" and (.findings | length == 0)' "$TMP/depersonalize.json" >/dev/null; then
  pass "fixture depersonalization clean"
else
  fail "fixture depersonalization clean"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
