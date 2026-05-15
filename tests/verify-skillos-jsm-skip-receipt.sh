#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/verify-skillos-jsm-skip-receipt.py"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

PASS=0
FAIL=0
pass() { printf 'PASS: %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { printf 'FAIL: %s\n' "$1" >&2; FAIL=$((FAIL + 1)); }

skill="$TMP/agent-ergonomics-and-agent-intuitiveness-maximization-for-cli-tools"
mkdir -p "$skill"
cat > "$skill/SKILL.md" <<'EOF'
---
name: agent-ergonomics-max
---
# Fixture
EOF

cat > "$TMP/jsm" <<'EOF'
#!/usr/bin/env bash
cat <<'OUT'
Validating skill at: /tmp/agent-ergonomics-and-agent-intuitiveness-maximization-for-cli-tools
Validation failed with 2 error(s):
- Directory name 'agent-ergonomics-and-agent-intuitiveness-maximization-for-cli-tools' must match skill name 'agent-ergonomics-max'.
- Skill package has 190 files, exceeding limit of 50.
Error: Invalid skill package: Skill validation failed. Resolve errors and try again.
OUT
exit 1
EOF
chmod +x "$TMP/jsm"

cat > "$TMP/receipt-ok.json" <<'EOF'
{
  "schema_version": "skillos.jsm_validate_skip_receipt.v1",
  "skip_decision": "explicit_skip_jsm_validate_for_this_skill_v1",
  "skill_dir": "agent-ergonomics-and-agent-intuitiveness-maximization-for-cli-tools",
  "fail_codes_addressed": [
    "JSM_VALIDATE_FAIL_DIR_NAME_MISMATCH (fixture)",
    "JSM_VALIDATE_FAIL_FILE_COUNT_OVER_50 (fixture)"
  ],
  "skip_scope": {
    "applies_to": "jsm validate + jsm push for this skill"
  },
  "cross_references": {
    "flywheel_blockers": ["flywheel-75m9o"]
  }
}
EOF

if "$SCRIPT" --receipt "$TMP/receipt-ok.json" --skill-dir "$skill" --jsm-bin "$TMP/jsm" --json \
  | jq -e '.status == "pass" and (.covered_codes | length == 2)' >/dev/null; then
  pass "valid skip receipt covers current JSM failures"
else
  fail "valid skip receipt covers current JSM failures"
fi

jq 'del(.fail_codes_addressed[1])' "$TMP/receipt-ok.json" > "$TMP/receipt-missing-code.json"
out="$("$SCRIPT" --receipt "$TMP/receipt-missing-code.json" --skill-dir "$skill" --jsm-bin "$TMP/jsm" --json || true)"
if jq -e '.status == "fail" and any(.errors[]; .code == "JSM_FAILURE_NOT_COVERED")' >/dev/null <<<"$out"; then
  pass "missing covered failure code fails"
else
  fail "missing covered failure code fails"
fi

jq '.cross_references.flywheel_blockers=[]' "$TMP/receipt-ok.json" > "$TMP/receipt-no-bead.json"
out="$("$SCRIPT" --receipt "$TMP/receipt-no-bead.json" --skill-dir "$skill" --jsm-bin "$TMP/jsm" --json || true)"
if jq -e '.status == "fail" and any(.errors[]; .code == "BEAD_REF_MISSING")' >/dev/null <<<"$out"; then
  pass "missing flywheel blocker reference fails"
else
  fail "missing flywheel blocker reference fails"
fi

cat > "$TMP/jsm-pass" <<'EOF'
#!/usr/bin/env bash
echo "ok"
exit 0
EOF
chmod +x "$TMP/jsm-pass"
out="$("$SCRIPT" --receipt "$TMP/receipt-ok.json" --skill-dir "$skill" --jsm-bin "$TMP/jsm-pass" --json || true)"
if jq -e '.status == "fail" and any(.errors[]; .code == "JSM_VALIDATE_UNEXPECTED_PASS")' >/dev/null <<<"$out"; then
  pass "stale skip receipt fails if jsm validate passes"
else
  fail "stale skip receipt fails if jsm validate passes"
fi

printf '\nSUMMARY pass=%d fail=%d\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
