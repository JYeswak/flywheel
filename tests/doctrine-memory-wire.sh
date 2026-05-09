#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
AGENTS="$ROOT/AGENTS.md"
AGENTS_CANONICAL="$ROOT/.flywheel/AGENTS-CANONICAL.md"
AGENTS_TEMPLATE="$ROOT/templates/flywheel-install/AGENTS.md"
README="$ROOT/README.md"
CANONICAL="$ROOT/.flywheel/canonical-paths.txt"
MEMORY_DIR="/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory"
MEMORY_INDEX="$MEMORY_DIR/MEMORY.md"
MEMORY_NOTE="$MEMORY_DIR/feedback_validate_redispatch_foundational_discipline.md"
SKILL="/Users/josh/.claude/skills/orchestrator-validation-discipline/SKILL.md"
SECURITY_SKILL_DRAFT="$ROOT/.flywheel/PLANS/agent-security-controls-fleet-wide-2026-05-04/skill-draft-agent-security-control.md"
PRIMITIVE="validate-and-redispatch discipline"

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1"; fail_count=$((fail_count + 1)); }

has() {
  local file="$1" pattern="$2" label="$3"
  if rg -n --fixed-strings "$pattern" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label missing pattern=$pattern file=$file"
  fi
}

regex() {
  local file="$1" pattern="$2" label="$3"
  if rg -n "$pattern" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label missing regex=$pattern file=$file"
  fi
}

test -f "$SKILL" && pass "B10_AG5 skill present" || fail "B10_AG5 skill present"
test -f "$SECURITY_SKILL_DRAFT" && pass "B10_SECURITY skill draft present" || fail "B10_SECURITY skill draft present"
test -f "$MEMORY_NOTE" && pass "B10_AG4 memory note present" || fail "B10_AG4 memory note present"

regex "$AGENTS" '^## L71 — VALIDATE-AND-REDISPATCH-DISCIPLINE$' "B10_AG2 L71 heading"
has "$AGENTS" 'id: L71' "B10_AG2 id"
has "$AGENTS" 'status: long_term' "B10_AG2 long-term status after B12 smoke"
has "$AGENTS" 'review_due: 2026-11-03' "B10_AG2 review_due present"
has "$AGENTS" 'trauma_class: orchestrator-skipped-callback-validation' "B10_AG2 trauma_class present"
has "$AGENTS" '**Forbidden outputs:**' "B10_AG2 forbidden outputs present"
has "$AGENTS" '**Evidence:**' "B10_AG2 evidence present"
has "$AGENTS" '**Companion rules:**' "B10_AG2 companion rules present"

for file in "$AGENTS" "$AGENTS_CANONICAL" "$AGENTS_TEMPLATE"; do
  regex "$file" '^## L74 — AGENT-SECURITY-DENY-RULES-CANONICAL$' "B10_SECURITY L74 heading $(basename "$file")"
  has "$file" 'id: L74' "B10_SECURITY L74 id $(basename "$file")"
  has "$file" 'agent-security-control/v1' "B10_SECURITY L74 schema marker $(basename "$file")"
  has "$file" 'security-control' "B10_SECURITY L74 security-control marker $(basename "$file")"
  has "$file" 'canonical-security-allow' "B10_SECURITY L74 override marker $(basename "$file")"
done

for ref in L60 L69 L70 flywheel-1z65 flywheel-7lby feedback_orchestrator_validates_callbacks.md feedback_worker_verify_callback_delivered.md feedback_low_bead_threshold_work_hunt.md; do
  has "$AGENTS" "$ref" "B10_AG6 AGENTS cites $ref"
done

for bead in flywheel-0wbf flywheel-hf58 flywheel-8xrn flywheel-i8b6 flywheel-zdva flywheel-u2dr flywheel-f589; do
  has "$AGENTS" "$bead" "B10_AG1 executable proof cites $bead"
done

has "$README" "$PRIMITIVE" "B10_AG3 README primitive"
has "$README" "orchestrator-validation-discipline/SKILL.md" "B10_AG3 README skill link"
has "$README" "agent-security-control/v1" "B10_SECURITY README schema marker"
has "$README" "security-control" "B10_SECURITY README security-control marker"
has "$MEMORY_INDEX" "feedback_validate_redispatch_foundational_discipline.md" "B10_AG4 memory index link"
has "$MEMORY_NOTE" "$PRIMITIVE" "B10_AG4 memory primitive"
has "$MEMORY_NOTE" "00-PLAN.md" "B10_AG4 memory plan artifact"
has "$MEMORY_NOTE" ".flywheel/validation-receipts/" "B10_AG4 memory validation receipt evidence"

for needle in "description:" "Exact Pattern" "Anti-Patterns" "Tests And Fixtures" "validate-callback.py" "validation-fix-bead.py" "closed-bead-artifact-scan.py" "verify-callback-delivery.sh"; do
  has "$SKILL" "$needle" "B10_AG5 skill contains $needle"
done

has "$CANONICAL" "l71_validate_redispatch_discipline" "B10_AG7 canonical L-rule path"
has "$CANONICAL" "orchestrator_validation_discipline_skill" "B10_AG7 canonical skill path"
has "$CANONICAL" "validate_redispatch_discipline_memory" "B10_AG7 canonical memory path"
has "$CANONICAL" "agent_security_control_schema_v1" "B10_SECURITY canonical schema path"
has "$CANONICAL" "agent_security_control_deny_template" "B10_SECURITY canonical deny template path"
has "$CANONICAL" "agent_security_control_doctrine_l74" "B10_SECURITY canonical L74 path"
has "$CANONICAL" "agent_security_control_skill_draft" "B10_SECURITY canonical skill draft path"

for file in "$AGENTS" "$README" "$MEMORY_NOTE" "$SKILL"; do
  has "$file" "$PRIMITIVE" "B10_AG7 primitive drift check $(basename "$file")"
done

if "$ROOT/.flywheel/scripts/sync-canonical-doctrine.sh" --dry-run --json --root "$ROOT" >/tmp/doctrine-memory-wire-sync.json 2>/tmp/doctrine-memory-wire-sync.err || true; then
  if jq -e '.root_drifted_count == 0 and .canonical_drifted_count == 0 and .errors_count == 0' /tmp/doctrine-memory-wire-sync.json >/dev/null; then
    pass "B10 sync-canonical-doctrine dry-run source/root check"
  else
    fail "B10 sync-canonical-doctrine dry-run source/root check"
    cat /tmp/doctrine-memory-wire-sync.err || true
    cat /tmp/doctrine-memory-wire-sync.json || true
  fi
else
  fail "B10 sync-canonical-doctrine dry-run source/root check"
  cat /tmp/doctrine-memory-wire-sync.err || true
  cat /tmp/doctrine-memory-wire-sync.json || true
fi

printf '\nSummary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
