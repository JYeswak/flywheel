# flywheel-wzjo9.2.2 — apply-spec

## Identity

**Bead:** flywheel-wzjo9.2.2
**Wave label:** wave-2.0b-b (sub-bead b of 9 in wave-2.0b — recovery infrastructure)
**Parent (wave):** flywheel-wzjo9.2
**Grandparent (lane):** flywheel-wzjo9

## Surface

| Attribute | Value |
|---|---|
| Name | `recovery-baseline-snapshot.sh` |
| Path | `.flywheel/scripts/recovery-baseline-snapshot.sh` |
| Lines | 334 |
| Interpreter | bash |
| Priority | P2 |
| canonical_cli_scoping_status | `missing` |

## Scope

Single-surface scaffold + 18-TODO substantive fillin following the canonical sister-fillin shape (wzjo9.1.x + 1fk5f.x pattern).

## Deliverables

1. **Dry-run scaffold:** `scaffold-canonical-cli.sh .flywheel/scripts/recovery-baseline-snapshot.sh --json`
2. **Apply with idempotency-key:** `scaffold-canonical-cli.sh .flywheel/scripts/recovery-baseline-snapshot.sh --apply --idempotency-key=flywheel-wzjo9.2.2-pilot --json`
3. **Substantive 18-TODO fillin** (replace all functional `# TODO(canonical-cli-scaffold)` markers):
   - scaffold_emit_schema per-surface schemas
   - scaffold_emit_topic_help single-printf bodies (gl7om SIGPIPE discipline)
   - scaffold_cmd_doctor ≥5 named substrate probes
   - scaffold_cmd_health tail SCAFFOLD_AUDIT_LOG; warn stale >24h
   - scaffold_cmd_repair 2 surface-specific scopes + canonical refusal
   - scaffold_cmd_validate 3 subjects (row/schema/config) + optional 4th surface-specific subject
   - scaffold_cmd_audit cli_emit_audit_tail (path-then-schema)
   - scaffold_cmd_why provenance lookup (found/not_found/unavailable)
4. **cmd_run wiring:** optional — call cli_audit_append at terminal envelopes if cmd_run has clear terminal points
5. **Test additions:** extend baseline 15-test scaffold to ≥19

## Acceptance gates

- **AG1:** 18 TODO markers replaced
- **AG2:** `bash -n` clean
- **AG3:** `canonical-cli-lint` clean (0 L1-L8 violations)
- **AG4:** scaffold-test PASS (≥13/13, prefer 20/20)
- **AG5:** each canonical surface returns concrete data

## Validation predicate (strict)

```bash
cd /Users/josh/Developer/flywheel
bash -n .flywheel/scripts/recovery-baseline-snapshot.sh \
  && grep -c 'TODO(canonical-cli-scaffold)' .flywheel/scripts/recovery-baseline-snapshot.sh | grep -qx 0 \
  && .flywheel/scripts/canonical-cli-lint.sh .flywheel/scripts/recovery-baseline-snapshot.sh \
  && bash tests/recovery-baseline-snapshot-canonical-cli.sh \
  && echo "AG1-5 PASS"
```

## Estimated wall-time

30-60 min (longer for 519-line recovery-preinstall-audit.sh; shorter for 84-line recovery-baseline-status.sh).

## Cross-refs

- Parent (wave): flywheel-wzjo9.2 (wave-2.0b, 9 surfaces)
- Lane: flywheel-wzjo9 (recovery)
- Sister wave-2.0a fillins (avg 978): wzjo9.1.{1,2,3,6,8}
- Sister-lane exemplar: flywheel-1fk5f.{1..8} (avg 974)
- Scaffolder: .flywheel/scripts/scaffold-canonical-cli.sh (with hoqq8 apply-gate fix + sacan verb-collision detection)
- Helper lib: .flywheel/lib/canonical-cli-helpers.sh

## Doctrine pointers

- SIGPIPE/pipefail multi-printf trap → single-printf topic_help
- `cli_emit_audit_tail` signature: (path, schema, limit) — path first
- Apply-gate fires BEFORE side-effects (flywheel-hoqq8 invariant)
- Verb-collision bypass auto-emitted when collision detected (flywheel-sacan)
