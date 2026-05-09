#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/skills-best-practices-health.py"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/skills-best-practices-health.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_jq() {
  local file="$1" filter="$2" label="$3"
  jq -e "$filter" "$file" >/dev/null || {
    printf 'FAIL: %s\n' "$label" >&2
    jq . "$file" >&2 || true
    exit 1
  }
  printf 'PASS: %s\n' "$label"
}

python3 -m py_compile "$SCRIPT"

"$SCRIPT" --schema --json >"$TMP/schema.json"
assert_jq "$TMP/schema.json" '.schema_version == "skills-best-practices-doctor/v1" and (.status_values | index("degraded"))' "schema exposes doctor status values"

fixture="$TMP/skills"
mkdir -p "$fixture/canonical-cli-scoping" "$fixture/python-best-practices" "$fixture/reference-only"
cat >"$fixture/canonical-cli-scoping/SKILL.md" <<'EOF'
---
name: canonical-cli-scoping
description: fixture
---

# Fixture
EOF
cat >"$fixture/python-best-practices/SKILL.md" <<'EOF'
---
name: python-best-practices
description: fixture
---

# Fixture
EOF

before="$(find "$fixture" -type f | sort)"
"$SCRIPT" --doctor --json --skills-root "$fixture" \
  --expected-skill canonical-cli-scoping \
  --expected-skill python-best-practices \
  --expected-skill missing-load-bearing >"$TMP/degraded.json"
after="$(find "$fixture" -type f | sort)"
[[ "$before" == "$after" ]] || fail "doctor mutated skills fixture"
assert_jq "$TMP/degraded.json" '
  .status == "degraded"
  and .skill_dir_count == 2
  and .readable_skill_md_count == 2
  and .skipped_non_skill_dir_count == 1
  and (.missing_expected_skills | index("missing-load-bearing"))
  and .bead_recommendation.recommended == true
  and .read_only == true
  and (.mutated_paths | length) == 0
' "doctor reports degraded fixture without mutation"

if "$SCRIPT" --doctor --json --skills-root "$TMP/no-such-root" >"$TMP/blocked.json"; then
  fail "missing root should exit non-zero"
fi
assert_jq "$TMP/blocked.json" '.status == "blocked" and .bead_recommendation.priority == "P1"' "missing root blocks with bead recommendation"

printf 'OK skills-best-practices health probe\n'
