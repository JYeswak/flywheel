#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
CLASSIFIER="$ROOT/.flywheel/scripts/skill-scoping-classifier.sh"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

pass=0
fail=0

ok() {
  local name="$1"
  shift
  if "$@"; then
    pass=$((pass + 1))
    printf 'ok %d - %s\n' "$pass" "$name"
  else
    fail=$((fail + 1))
    printf 'not ok %d - %s\n' "$((pass + fail))" "$name"
  fi
}

ok_jq() {
  local name="$1"
  local expr="$2"
  local file="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass=$((pass + 1))
    printf 'ok %d - %s\n' "$pass" "$name"
  else
    fail=$((fail + 1))
    printf 'not ok %d - %s\n' "$((pass + fail))" "$name"
  fi
}

skills="$TMPDIR/skills"
mkdir -p "$skills/tight" "$skills/medium-trigger" "$skills/medium-path" "$skills/broad"

cat >"$skills/tight/SKILL.md" <<'EOF'
---
name: tight
description: "Use when editing payment code. Triggers: payments, invoices."
triggers:
  - payments
applies_to:
  - packages/payments/**
---
# Tight
EOF

cat >"$skills/medium-trigger/SKILL.md" <<'EOF'
---
name: medium-trigger
description: "Use when working on invoices."
triggers:
  - invoice workflow
---
# Medium Trigger
EOF

cat >"$skills/medium-path/SKILL.md" <<'EOF'
---
name: medium-path
description: "Helper for local docs."
applies_to:
  - docs/**
---
# Medium Path
EOF

cat >"$skills/broad/SKILL.md" <<'EOF'
---
name: broad
description: "General helper."
---
# Broad
EOF

out="$TMPDIR/classified.jsonl"
summary="$TMPDIR/summary.json"
"$CLASSIFIER" --skills-root "$skills" --flywheel-db "$TMPDIR/missing.db" --output "$out" --summary 2>"$summary"

ok "classifier is executable" test -x "$CLASSIFIER"
ok "emits one row per skill" test "$(wc -l <"$out" | tr -d ' ')" -eq 4
ok_jq "tight classified TIGHT" 'select(.skill=="tight") | .classification == "TIGHT"' "$out"
ok_jq "trigger-only classified MEDIUM" 'select(.skill=="medium-trigger") | .classification == "MEDIUM" and .trigger_keywords_present == true and .path_scope_present == false' "$out"
ok_jq "path-only classified MEDIUM" 'select(.skill=="medium-path") | .classification == "MEDIUM" and .trigger_keywords_present == false and .path_scope_present == true' "$out"
ok_jq "broad classified BROAD" 'select(.skill=="broad") | .classification == "BROAD" and .trigger_keywords_present == false and .path_scope_present == false' "$out"
ok_jq "reasons include missing path" 'select(.skill=="medium-trigger") | (.reasons | index("missing-path-scope")) != null' "$out"
ok_jq "description token estimate emitted" 'select(.skill=="tight") | .estimated_description_tokens > 0' "$out"
ok_jq "summary counts match fixture" '.total == 4 and .counts.TIGHT == 1 and .counts.MEDIUM == 2 and .counts.BROAD == 1' "$summary"
ok_jq "summary projects context savings" '.projected_saved_tokens_per_session_if_non_tight_scoped > 0' "$summary"

printf 'SUMMARY pass=%d fail=%d\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]]
