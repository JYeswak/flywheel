# flywheel-wzjo9.4 — apply-spec

## Identity

**Bead:** flywheel-wzjo9.4
**Wave label:** wave-2.0d
**Parent:** flywheel-wzjo9 (doctor-mode-lane-2 recovery decomposition)
**Sister lane:** flywheel-war3i + flywheel-1fk5f (dispatch lane wave-2 exemplar)

## Scope

Wave 2.0d covers the 2 remaining recovery-lane needs-work surfaces: npm-install-guard.sh and the flywheel.bak-2026-04-28-pre-3fail-fix legacy backup.

**Surfaces (       2 total):**
- `npm-install-guard.sh`
- `flywheel.bak-2026-04-28-pre-3fail-fix`

## Per-surface deliverables (each surface in this wave)

1. **Detect interpreter:** `head -1 <surface>` to pick bash vs python scaffolder
2. **Dry-run scaffold:** `scaffold-canonical-cli.sh <surface> --json` (or `-py.sh` for python). Verify receipt: `verb_collision_detected` + `colliding_verbs` + `bypass_flags` populated correctly.
3. **Apply with idempotency-key:** `scaffold-canonical-cli.sh <surface> --apply --idempotency-key=wzjo9.4-pilot --json`
4. **Substantive 18-TODO fillin** per sister-fillin shape (vc3zs/1fk5f.3/1fk5f.6 pattern):
   - scaffold_emit_schema: per-surface schemas (doctor/health/repair/validate/audit/why/audit-row/default)
   - scaffold_emit_topic_help: single-printf bodies per topic (gl7om SIGPIPE discipline)
   - scaffold_cmd_doctor: ≥5 named substrate probes
   - scaffold_cmd_health: tail SCAFFOLD_AUDIT_LOG with stale>24h warn
   - scaffold_cmd_repair: 2 surface-specific scopes + canonical refusal contract
   - scaffold_cmd_validate: 3 subjects (row, schema, config)
   - scaffold_cmd_audit: cli_emit_audit_tail (path-then-schema positional order per b9dfv)
   - scaffold_cmd_why: provenance lookup (found / not_found / unavailable)
5. **cmd_run wiring:** call cli_audit_append at terminal envelopes so audit log accretes
6. **Test additions:** extend baseline 15-test scaffold to ≥19 with 4-5 fillin-specific assertions

## Acceptance gates (per surface)

- **AG1:** 18 TODO markers replaced with substantive (non-stub) implementations
- **AG2:** `bash -n` clean (or `python3 -c "import ast; ast.parse(...)"` for python)
- **AG3:** canonical-cli-lint clean (0 violations across L1-L8)
- **AG4:** canonical-cli scaffold-test 13/13 (or 15/15 or 20/20) PASS
- **AG5:** each surface returns concrete data — doctor 5+ named probes, health binds to audit log, validate enforces row schema, repair has scope-specific actions, why has provenance lookup

## Validation predicate (per surface, strict)

```bash
cd /Users/josh/Developer/flywheel
bash -n <surface> \
  && grep -c 'TODO(canonical-cli-scaffold)' <surface> | grep -qx 0 \
  && .flywheel/scripts/canonical-cli-lint.sh <surface> \
  && bash tests/<basename>-canonical-cli.sh \
  && echo "AG1-5 PASS"
```

## Estimated wall-time

60–120 min total (~30–60 min per surface × 2 surfaces)

If any single surface exceeds 1h budget, decompose further per natural-unit META-RULE.

## Cross-refs

- Parent: flywheel-wzjo9 (decomposition author)
- Sister-lane exemplar: flywheel-war3i (scaffolder) + flywheel-1fk5f.{1..8} (fillins — 8/8 closed avg 974/1000)
- Scaffolder: scaffold-canonical-cli.sh (flywheel-ws02m + flywheel-hoqq8 apply-gate fix + flywheel-sacan verb-collision detection)
- Python sibling: scaffold-canonical-cli-py.sh (flywheel-oozt3)
- Helper lib: .flywheel/lib/canonical-cli-helpers.sh (flywheel-tiugg + b9dfv)
- Fillin exemplars (sister fillins, closed): vc3zs, tfgt3, 5kjez, bqvpa, x882q, q71jb, 39vhm, hpirw, 1fk5f.3, 1fk5f.6

## Doctrine pointers (apply where relevant)

- SIGPIPE/pipefail multi-printf trap → single-printf topic_help bodies
- `local var1 var2=""` only initializes var2 → `local var1="" var2=""`
- `cli_emit_audit_tail` signature: (path, schema, limit) — path first
- Apply-gate fires BEFORE side-effects (flywheel-hoqq8 structural invariant)
- Verb-collision bypass for surfaces with own argparse (flywheel-sacan; scaffolder emits bypass automatically when collision detected)
