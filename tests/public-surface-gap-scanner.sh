#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/public-surface-gap-scanner.py"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/public-surface-gap-scanner.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

run_capture() {
  local out="$1" err="$2"
  shift 2
  set +e
  "$@" >"$out" 2>"$err"
  local rc=$?
  return "$rc"
}

if python3 -m py_compile "$SCRIPT"; then pass "syntax"; else fail "syntax"; fi

cat >"$TMP/clean.md" <<'EOF'
# Clean

This public surface has no release markers.
EOF

if python3 "$SCRIPT" --repo "$TMP" --file clean.md --release --json >"$TMP/clean.json" \
  && jq -e '.status == "pass" and .undispositioned_count == 0' "$TMP/clean.json" >/dev/null; then
  pass "clean fixture passes release mode"
else
  fail "clean fixture passes release mode"
fi

cat >"$TMP/bad.md" <<'EOF'
# Bad

TODO: wire the missing release step.
EOF

set +e
run_capture "$TMP/bad.json" "$TMP/bad.err" python3 "$SCRIPT" --repo "$TMP" --file bad.md --release --json
bad_rc=$?
set -e
if [[ "$bad_rc" -eq 1 ]] && jq -e '.status == "fail" and .undispositioned_count == 1 and (.errors[]?.code == "undispositioned_public_gap")' "$TMP/bad.json" >/dev/null; then
  pass "undispositioned fixture fails release mode"
else
  fail "undispositioned fixture fails release mode rc=${bad_rc}"
fi

cat >"$TMP/tp.md" <<'EOF'
# TP

TODO TP-020: tracked by the release-blocker registry.
EOF

if python3 "$SCRIPT" --repo "$TMP" --file tp.md --release --json >"$TMP/tp.json" \
  && jq -e '.status == "pass" and .finding_count == 1 and .undispositioned_count == 0' "$TMP/tp.json" >/dev/null; then
  pass "TP-dispositioned marker passes"
else
  fail "TP-dispositioned marker passes"
fi

cat >"$TMP/registry.md" <<'EOF'
# Registry

Known gap tracked by TP-020.
EOF

if python3 "$SCRIPT" --repo "$TMP" --file registry.md --release --json >"$TMP/registry.json" \
  && jq -e '.status == "pass" and .finding_count == 1 and .undispositioned_count == 0' "$TMP/registry.json" >/dev/null; then
  pass "registry-dispositioned marker passes"
else
  fail "registry-dispositioned marker passes"
fi

cat >"$TMP/non-release.md" <<'EOF'
# Non Release

This missing fixture is non-release documentation.
EOF

if python3 "$SCRIPT" --repo "$TMP" --file non-release.md --release --json >"$TMP/non-release.json" \
  && jq -e '.status == "pass" and .finding_count == 1 and .undispositioned_count == 0' "$TMP/non-release.json" >/dev/null; then
  pass "non-release marker passes"
else
  fail "non-release marker passes"
fi

cat >"$TMP/code.sh" <<'EOF'
#!/usr/bin/env bash
missing=()
echo "${missing[*]}"
EOF

if python3 "$SCRIPT" --repo "$TMP" --file code.sh --release --json >"$TMP/code.json" \
  && jq -e '.status == "pass" and .finding_count == 0' "$TMP/code.json" >/dev/null; then
  pass "code missing variable ignored"
else
  fail "code missing variable ignored"
fi

if python3 "$SCRIPT" --repo "$ROOT" --release --json >"$TMP/live.json" \
  && jq -e '.status == "pass" and .file_count >= 48 and .undispositioned_count == 0' "$TMP/live.json" >/dev/null; then
  pass "live public surfaces pass release scan"
else
  fail "live public surfaces pass release scan"
  jq '.undispositioned' "$TMP/live.json" >&2 || true
fi

for required_path in \
  docs/runbooks/release-cutover-authorization.md \
  docs/runbooks/upstream-substrate-adoption.md \
  docs/evidence/publication-evidence.md \
  docs/evidence/publication-blocker-coverage.md \
  docs/evidence/asupersync-gated-adoption.md \
  .github/workflows/site.yml; do
  if jq -e --arg path "$required_path" '.files | index($path)' "$TMP/live.json" >/dev/null; then
    pass "default scan includes ${required_path}"
  else
    fail "default scan includes ${required_path}"
  fi
done

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
