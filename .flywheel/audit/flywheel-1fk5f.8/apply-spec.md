# flywheel-1fk5f.8 — apply-spec

## Identity

**Bead:** flywheel-1fk5f.8
**Parent:** flywheel-1fk5f (wave-2 fillin parent)
**Sister:** flywheel-war3i (wave-2 scaffolder; CLOSED)
**Surface:** `.flywheel/scripts/ntm-pane-sidecar-respawn.sh`
**Test scaffold:** `tests/ntm-pane-sidecar-respawn-canonical-cli.sh`
**Wave:** lane 1.2 (dispatch lane wave 2)

## Scope

Substantive fill-in of the 18 `# TODO(canonical-cli-scaffold)` markers
that war3i scaffolded into this surface. Same shape as wgitr (wave-1
fillin) and the closed sister fillins (vc3zs, mae86, 4pwc5, dulh3,
gl7om, 39vhm, dsrq1).

## Pre-fill state

- TODO count: 18 functional markers
- Canonical-cli checker: 13/13 PASS (war3i baseline)
- Surface tests: 15/15 PASS (war3i baseline)
- canonical-cli-lint: clean (war3i baseline)

## Post-fill targets (5 AGs)

- **AG1**: 18 TODO markers replaced with substantive (non-stub) impls.
- **AG2**: `bash -n` clean.
- **AG3**: canonical-cli-lint clean.
- **AG4**: canonical-cli scaffold-test 13/13 PASS.
- **AG5**: each surface returns concrete data — doctor 5+ named probes,
  health/audit/why bind to real audit log via `cli_audit_append` in
  cmd_run, validate enforces row schema, repair has scope-specific
  actions (audit_log_dir / audit_log_truncate / none).

## Per-surface fillin shape (from sister fillins)

1. **Module-scope vars** (lift from cmd_run if needed): SCAFFOLD_AUDIT_LOG,
   any state paths the canonical surfaces must resolve before cmd_run runs.
2. **`scaffold_emit_schema audit-row|run|*`** — surface-specific schemas.
3. **`scaffold_emit_topic_help`** — single-printf bodies per topic
   (gl7om SIGPIPE/pipefail discipline).
4. **`scaffold_cmd_doctor`** — ≥5 named substrate probes.
5. **`scaffold_cmd_health`** — tail audit log + canonical status enum.
6. **`scaffold_cmd_repair --scope ...`** — dry-run planned_actions;
   apply with --idempotency-key.
7. **`scaffold_cmd_validate <subject>`** — per-subject schema check.
8. **`scaffold_cmd_audit`** — `cli_emit_audit_tail` (path-then-schema
   positional order).
9. **`scaffold_cmd_why <id>`** — found|not_found|unavailable
   provenance lookup.
10. **cmd_run wiring** — call `cli_audit_append` at terminal envelopes
    so the audit log accretes.
11. **Test additions** — extend the 15-assertion scaffold test to ≥19
    by adding 4-6 fillin assertions matching sister-fillin pattern.

## Validation predicate (one-shot)

```bash
cd /Users/josh/Developer/flywheel
bash -n .flywheel/scripts/ntm-pane-sidecar-respawn.sh \
  && grep -c 'TODO(canonical-cli-scaffold)' .flywheel/scripts/ntm-pane-sidecar-respawn.sh | grep -qx 0 \
  && bash ~/.claude/skills/canonical-cli-scoping/scripts/check-cli-scoping.sh .flywheel/scripts/ntm-pane-sidecar-respawn.sh \
  && .flywheel/scripts/canonical-cli-lint.sh .flywheel/scripts/ntm-pane-sidecar-respawn.sh \
  && bash tests/ntm-pane-sidecar-respawn-canonical-cli.sh \
  && echo "AG1-5 PASS"
```

## Estimated wall-time

30-60 min (per parent bead estimate split 8 ways: 4-8h ÷ 8).

## Cross-refs

- Parent: flywheel-1fk5f
- Scaffolder author: flywheel-war3i (CLOSED)
- Helper lib: `.flywheel/lib/canonical-cli-helpers.sh` (flywheel-tiugg + b9dfv)
- Sister fillin exemplars: vc3zs, mae86, 4pwc5, dulh3, gl7om, 39vhm, dsrq1
- Doctrine pointers (apply where relevant):
  - SIGPIPE/pipefail multi-printf trap → single-printf topic_help
  - `local var1 var2=\"\"` only initializes var2 → `local var1=\"\" var2=\"\"`
  - `cli_emit_audit_tail` signature: (path, schema, limit) — path first
