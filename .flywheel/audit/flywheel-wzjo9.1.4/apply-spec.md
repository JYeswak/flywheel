# flywheel-wzjo9.1.4 — apply-spec

## Identity

**Bead:** flywheel-wzjo9.1.4
**Wave label:** wave-2.0a-d (sub-bead d of 9 in wave-2.0a)
**Parent (wave):** flywheel-wzjo9.1
**Grandparent (lane):** flywheel-wzjo9

## Surface

| Attribute | Value |
|---|---|
| Name | `flywheel-verdict` |
| Path | `/Users/josh/.claude/skills/.flywheel/bin/flywheel-verdict` |
| Lines | 415 |
| Interpreter | bash (`#!/usr/bin/env bash`) |
| Priority | P0 |
| canonical_cli_scoping_status | `partial` |
| world_class_doctor_score_estimate | 625 |
| has_doctor | true |

## Scope

Single-surface scaffold + 18-TODO substantive fillin following the canonical sister-fillin shape (vc3zs / 1fk5f.3 / 1fk5f.6 pattern).

## Deliverables

1. **Dry-run scaffold:** `scaffold-canonical-cli.sh /Users/josh/.claude/skills/.flywheel/bin/flywheel-verdict --json`. Verify receipt: `verb_collision_detected` + `colliding_verbs` + `bypass_flags` populated correctly.
2. **Apply with idempotency-key:** `scaffold-canonical-cli.sh /Users/josh/.claude/skills/.flywheel/bin/flywheel-verdict --apply --idempotency-key=flywheel-wzjo9.1.4-pilot --json`
3. **Substantive 18-TODO fillin** (replace all functional `# TODO(canonical-cli-scaffold)` markers):
   - `scaffold_emit_schema` per-surface schemas (doctor / health / repair / validate / audit / why / audit-row / default)
   - `scaffold_emit_topic_help` single-printf bodies per topic (gl7om SIGPIPE/pipefail discipline)
   - `scaffold_cmd_doctor` ≥5 named substrate probes
   - `scaffold_cmd_health` tail SCAFFOLD_AUDIT_LOG with stale>24h warn
   - `scaffold_cmd_repair` 2 surface-specific scopes + canonical refusal contract
   - `scaffold_cmd_validate` 3 subjects (row, schema, config)
   - `scaffold_cmd_audit` cli_emit_audit_tail (path-then-schema positional order)
   - `scaffold_cmd_why` provenance lookup (found / not_found / unavailable)
4. **cmd_run wiring:** call `cli_audit_append` at terminal envelopes so audit log accretes
5. **Test additions:** extend baseline 15-test scaffold to ≥19 with 4-5 fillin-specific assertions

## Acceptance gates

- **AG1:** 18 TODO markers replaced with substantive (non-stub) implementations
- **AG2:** `bash -n /Users/josh/.claude/skills/.flywheel/bin/flywheel-verdict` exits 0
- **AG3:** `canonical-cli-lint.sh /Users/josh/.claude/skills/.flywheel/bin/flywheel-verdict` exits 0 (no L1-L8 violations)
- **AG4:** `tests/flywheel-verdict-canonical-cli.sh` SUMMARY pass=N fail=0 (N>=13)
- **AG5:** Each canonical surface returns concrete data:
  - doctor: 5+ named probes, status pass/fail/warn
  - health: binds to audit log, reports recent_runs + last_run_ts + age_seconds
  - repair: scope-specific actions (not "todo")
  - validate: enforces per-subject schema (not "todo")
  - audit: tails ledger via cli_emit_audit_tail
  - why: provenance from audit log

## Validation predicate (strict, one-shot)

```bash
cd /Users/josh/Developer/flywheel
bash -n /Users/josh/.claude/skills/.flywheel/bin/flywheel-verdict \
  && grep -c 'TODO(canonical-cli-scaffold)' /Users/josh/.claude/skills/.flywheel/bin/flywheel-verdict | grep -qx 0 \
  && .flywheel/scripts/canonical-cli-lint.sh /Users/josh/.claude/skills/.flywheel/bin/flywheel-verdict \
  && bash tests/flywheel-verdict-canonical-cli.sh \
  && echo "AG1-5 PASS"
```

## Estimated wall-time

30-60 min. If exceeded, decompose further per natural-unit META-RULE (e.g., split the 18 TODOs across 2 ticks if the surface's domain has natural complexity, but most surfaces fit within budget).

## Cross-refs

- Parent (wave): flywheel-wzjo9.1 (wave-2.0a — 9 surfaces total)
- Lane: flywheel-wzjo9 (recovery lane, 4 waves)
- Sister-lane exemplar: flywheel-1fk5f.{1..8} (dispatch-lane wave-2 fillins — 8/8 closed avg 974/1000; scores 1000/950/960/1000/960/960/960/1000)
- Scaffolder: `.flywheel/scripts/scaffold-canonical-cli.sh` (with flywheel-hoqq8 apply-gate fix + flywheel-sacan verb-collision detection)
- Helper lib: `.flywheel/lib/canonical-cli-helpers.sh` (flywheel-tiugg + b9dfv)
- Fillin exemplars (sister fillins, closed): vc3zs, tfgt3, 5kjez, bqvpa, x882q, q71jb, 39vhm, hpirw, 1fk5f.3, 1fk5f.6

## Doctrine pointers

- SIGPIPE/pipefail multi-printf trap → single-printf topic_help bodies
- `local var1 var2=""` only initializes var2 → `local var1="" var2=""`
- `cli_emit_audit_tail` signature: `(path, schema, limit)` — path first
- Apply-gate fires BEFORE side-effects (flywheel-hoqq8 structural invariant)
- Verb-collision bypass auto-emitted by scaffolder when collision detected (flywheel-sacan)
