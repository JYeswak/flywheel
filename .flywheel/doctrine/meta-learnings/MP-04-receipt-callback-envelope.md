# MP-04 — Receipt-and-callback envelope contract

**Discovered:** 2026-05-18 (original investigation)
**Skills exemplifying:** 5+

## Essence

Callbacks make claims; receipts on disk are the only acceptance criterion. `evidence_path` is a contract, not a label — file MUST exist with schema-versioned envelope. Doctor reports without action = decorative anti-pattern.

## Where it applies

Worker callbacks, orchestrator validation, state machines, dispatch ledgers, audit receipts.

## Adoption signal

State files cite `schema_version`; callback ledger has normalized envelope.

## Exemplar skills (≥5)

- `~/.claude/skills/flywheel-end-to-end/references/CALLBACK-ENVELOPE.md:1` — normalized envelope
- `~/.claude/skills/flywheel-end-to-end/references/ANTI-PATTERNS.md:1` — decorative-doctor + callback-without-receipt
- `~/.claude/skills/orchestrator-validation-discipline/SKILL.md:1` — validate-and-redispatch
- `~/.claude/skills/python-best-practices/SKILL.md:271` — AuditReceipt dataclass
- `~/.claude/skills/artifact-schema-envelope/SKILL.md:1` — schema envelope discipline

## Adoption recipes

**Recipe 1 — Normalized envelope:** `Callback: task_id=X phase=Y tick_class=Z status=done|warn|blocked repo=PATH receipt=PATH|none next_phase=W findings=N`.

**Recipe 2 — schema_version mandatory:** every receipt JSON / state file declares `schema_version` field.

**Recipe 3 — evidence_path verification:** before callback sends, verify `evidence_path` points to extant file. Skill / script asserts this.

## Compliance test

```bash
# State files MUST cite schema_version.
find state -name "*.json" -size +100c | while read f; do
  jq -e '.schema_version // .schemaVersion // empty' "$f" >/dev/null || fail
done
```


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-04 — receipt-and-callback envelope contract:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-04-receipt-callback-envelope.md` for the canonical pattern.
- **MP-20 — cross-orch handoff:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-20-cross-orch-handoff.md` for the canonical pattern.
- **MP-23 — replayable mutation contract:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-23-replayable-mutation-contract.md` for the canonical pattern.
