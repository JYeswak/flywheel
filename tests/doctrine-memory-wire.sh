#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
AGENTS="$ROOT/AGENTS.md"
AGENTS_CANONICAL="$ROOT/.flywheel/AGENTS-CANONICAL.md"
AGENTS_TEMPLATE="$ROOT/templates/flywheel-install/AGENTS.md"
RULES_DIR="$ROOT/.flywheel/rules"
README="$ROOT/README.md"
CONTRIBUTING="$ROOT/CONTRIBUTING.md"
CANONICAL="$ROOT/.flywheel/canonical-paths.txt"
MEMORY_DIR="$HOME/.claude/projects/-Users-josh-Developer-flywheel/memory"
MEMORY_INDEX="$MEMORY_DIR/MEMORY.md"
MEMORY_NOTE="$MEMORY_DIR/feedback_validate_redispatch_foundational_discipline.md"
SKILL="$HOME/.claude/skills/orchestrator-validation-discipline/SKILL.md"
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

doctrine_has() {
  local pattern="$1" label="$2"
  if rg -n --fixed-strings "$pattern" "$AGENTS" "$RULES_DIR" >/dev/null; then
    pass "$label"
  else
    fail "$label missing pattern=$pattern doctrine_surfaces=$AGENTS,$RULES_DIR"
  fi
}

doctrine_regex() {
  local pattern="$1" label="$2"
  if rg -n "$pattern" "$AGENTS" "$RULES_DIR" >/dev/null; then
    pass "$label"
  else
    fail "$label missing regex=$pattern doctrine_surfaces=$AGENTS,$RULES_DIR"
  fi
}

if [[ -f "$SKILL" ]]; then
  pass "B10_AG5 skill present"
else
  fail "B10_AG5 skill present"
fi
if [[ -f "$SECURITY_SKILL_DRAFT" ]]; then
  pass "B10_SECURITY skill draft present"
else
  fail "B10_SECURITY skill draft present"
fi
if [[ -f "$MEMORY_NOTE" ]]; then
  pass "B10_AG4 memory note present"
else
  fail "B10_AG4 memory note present"
fi

doctrine_regex '^## L71 — VALIDATE-AND-REDISPATCH-DISCIPLINE$' "B10_AG2 L71 heading"
doctrine_has 'id: L71' "B10_AG2 id"
doctrine_has 'status: long_term' "B10_AG2 long-term status after B12 smoke"
doctrine_has 'review_due: 2026-11-03' "B10_AG2 review_due present"
doctrine_has 'trauma_class: orchestrator-skipped-callback-validation' "B10_AG2 trauma_class present"
doctrine_has '**Forbidden outputs:**' "B10_AG2 forbidden outputs present"
doctrine_has '**Evidence:**' "B10_AG2 evidence present"
doctrine_has '**Companion rules:**' "B10_AG2 companion rules present"

for file in "$AGENTS" "$AGENTS_CANONICAL" "$AGENTS_TEMPLATE"; do
  regex "$file" 'L[0-9]+-L74-agent-security-deny-rules-canonical\.md' "B10_SECURITY L74 index $(basename "$file")"
done
doctrine_regex '^## L74 — AGENT-SECURITY-DENY-RULES-CANONICAL$' "B10_SECURITY L74 heading shard"
doctrine_has 'id: L74' "B10_SECURITY L74 id shard"
doctrine_has 'agent-security-control/v1' "B10_SECURITY L74 schema marker shard"
doctrine_has 'security-control' "B10_SECURITY L74 security-control marker shard"
doctrine_has 'canonical-security-allow' "B10_SECURITY L74 override marker shard"

for ref in L60 L69 L70 flywheel-1z65 flywheel-7lby feedback_orchestrator_validates_callbacks.md feedback_worker_verify_callback_delivered.md feedback_low_bead_threshold_work_hunt.md; do
  doctrine_has "$ref" "B10_AG6 AGENTS cites $ref"
done

for bead in flywheel-0wbf flywheel-hf58 flywheel-8xrn flywheel-i8b6 flywheel-zdva flywheel-u2dr flywheel-f589; do
  doctrine_has "$bead" "B10_AG1 executable proof cites $bead"
done

has "$README" "Validate before claiming." "B10_AG3 README public validation principle"
has "$README" "CONTRIBUTING.md" "B10_AG3 README contributor handoff"
has "$CONTRIBUTING" "Worker callbacks are claims until validated." "B10_AG3 CONTRIBUTING callback validation"
has "$CONTRIBUTING" "validation=<command-or-receipt>" "B10_AG3 CONTRIBUTING validation field"
has "$CONTRIBUTING" "Do not include secrets" "B10_SECURITY CONTRIBUTING safety boundary"
has "$RULES_DIR/L028-L74-agent-security-deny-rules-canonical.md" "agent-security-control/v1" "B10_SECURITY rule schema marker"
has "$RULES_DIR/L028-L74-agent-security-deny-rules-canonical.md" "security-control" "B10_SECURITY rule security-control marker"
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

for file in "$AGENTS" "$MEMORY_NOTE" "$SKILL"; do
  if [[ "$file" == "$AGENTS" ]]; then
    doctrine_has "$PRIMITIVE" "B10_AG7 primitive drift check $(basename "$file")"
  else
    has "$file" "$PRIMITIVE" "B10_AG7 primitive drift check $(basename "$file")"
  fi
done
has "$README" "Validate before claiming." "B10_AG7 public README drift check validation principle"
has "$CONTRIBUTING" "Worker callbacks are claims until validated." "B10_AG7 CONTRIBUTING validation drift check"

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
