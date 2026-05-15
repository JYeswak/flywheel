#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/jeff-daily-corpus-diff-render.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/jeff-diff-render.XXXXXX")"
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
    jq . "$file" >&2 || true
  fi
}

if bash -n "$SCRIPT"; then
  pass "syntax"
else
  fail "syntax"
fi

if "$SCRIPT" --info | grep -Fq 'doctor|--doctor'; then
  pass "info/help advertises doctor"
else
  fail "info/help advertises doctor"
fi

if "$SCRIPT" --examples | grep -Fq 'jeff-daily-corpus-diff-render.sh doctor'; then
  pass "examples include doctor"
else
  fail "examples include doctor"
fi

"$SCRIPT" doctor >"$TMP/doctor-warn.json"
assert_jq "$TMP/doctor-warn.json" '.schema_version == "jeff-daily-diff-render.doctor.v1" and .command == "doctor" and .status == "warn" and .mode == "read_only" and .mutates == false and ([.checks[] | select(.name == "input_snapshot_readable").status][0] == "warn")' "doctor warns without input"

cat >"$TMP/snapshot.json" <<'EOF'
{
  "ts_completed": "2026-05-15T14:18:00Z",
  "since": "2026-05-14T14:18:00Z",
  "owner": "Dicklesworthstone",
  "repo_count": 1,
  "total_commits": 3,
  "total_issues": 1,
  "total_releases": 0,
  "total_prs": 1,
  "repos": [
    {
      "repo": "fixture-repo",
      "commits": [
        {"sha": "abc1", "message": "one", "author": "fixture"},
        {"sha": "abc2", "message": "two", "author": "fixture"},
        {"sha": "abc3", "message": "three", "author": "fixture"}
      ],
      "issues": [{"number": 1, "title": "fixture issue", "url": "https://example.invalid/1", "state": "open", "ts": "2026-05-15T14:18:00Z"}],
      "releases": [],
      "prs": [{"number": 2, "title": "fixture pr", "url": "https://example.invalid/2", "ts": "2026-05-15T14:18:00Z"}]
    }
  ]
}
EOF

"$SCRIPT" --in="$TMP/snapshot.json" --out="$TMP/report.md" doctor >"$TMP/doctor-pass.json"
assert_jq "$TMP/doctor-pass.json" '.status == "pass" and ([.checks[] | select(.name == "input_snapshot_readable").status][0] == "pass")' "doctor passes with readable input"

"$SCRIPT" --apply --in="$TMP/snapshot.json" --out="$TMP/report.md" >"$TMP/render.out"
if rg -q '^# Jeffrey Emanuel corpus — daily diff for 2026-05-15' "$TMP/report.md" && rg -q 'fixture-repo' "$TMP/report.md"; then
  pass "render fixture markdown"
else
  fail "render fixture markdown"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
