# Journey entry — flywheel-wzjo9.1.4

**Bead**: P0 wave-2.0a-d (parent: flywheel-wzjo9.1, grandparent: flywheel-wzjo9)
**Surface**: `~/.claude/skills/.flywheel/bin/flywheel-verdict` (verdict-recording CLI)
**Sister exemplars**: flywheel-1fk5f.{1..8} avg 974/1000
**Result**: 32/32 regression PASS + 100 sister assertions clean; 1000/1000

## Arc

1. **Inspect** — read 415-line original; identified that the surface ALREADY implements all canonical verbs (doctor/health/repair/validate/audit/why/quickstart/completion) natively. Verb-collision case.
2. **Scaffold (pre-bead)** — already applied via `scaffold-canonical-cli.sh --apply --idempotency-key=flywheel-wzjo9.1.4-pilot` → 256 lines added, 18 TODOs, backup at `.bak.scaffold-20260510T211505742665000Z-33634`.
3. **Test baseline** — `tests/flywheel-verdict-canonical-cli.sh` showed `pass=9 fail=13` — UNUSUAL for a sister fillin. Investigation: scaffold's intercept routed canonical args to TODO stubs returning `flywheel-verdict/v1` envelopes, but tests assert `flywheel-verdict.canonical.v1` (original schema). The intercept was hijacking working surfaces.
4. **Helper-lib gap discovered** — `--info` returned `helper_lib_missing:true`. Cause: scaffolder's `_SCAFFOLD_REPO_ROOT/../..` = `~/.claude/skills/`, and `~/.claude/skills/.flywheel/lib/` lacked `canonical-cli-helpers.sh`. Fix: `cp .flywheel/lib/canonical-cli-helpers.sh ~/.claude/skills/.flywheel/lib/`. Filed as skill discovery #1.
5. **Restructure decision** — sister fillins (1fk5f.{1..8}) were on targets WITHOUT verb collision and used substantive-duplicate stubs. For verb-collision targets like this one, the right pattern is **delegate, not duplicate**. Required moving original cmd_*/emit_* ABOVE the scaffold intercept so bash function resolution succeeds. Filed as skill discovery #2.
6. **Rewrite** — full restructure: bash-4 re-exec at top, then state init + helper-lib source + ALL helpers + ALL original cmd_*/emit_*, then scaffold delegates that call those originals, then intercept, then original argparse for the record path.
7. **Substantive fillin** — augmented stubs with NEW substantive content beyond pure delegation:
   - `emit_schema` 8 per-surface schemas (was 1 generic) — doctor/health/repair/validate/audit/why/record/audit-row + default
   - `doctor_payload` 9 named probes (was 6) — added `dependency:sqlite3`, `audit_log_writable`, `helper_lib_loaded`
   - `cmd_health` `audit_log_stale` boolean (stat-based mtime >24h check; macOS + Linux paths)
   - `cmd_repair` new `--scope audit-log` (was just state|dirs)
   - `cmd_why` multi-resolution (found / not_found / unavailable) with subject-specific explanations
   - `cli_audit_append` wired at 6 terminal envelopes (doctor, health, repair, validate, record dry-run, record actual)
   - `--info` envelope carries new `.paths.audit_log` field
8. **Test extension** — added 10 NEW assertions: info-audit-log-path, doctor-9-probes, health-audit-stale, repair-scope-audit-log, repair-apply-refused (rc=3) + refusal-envelope shape, why-multi-resolution, cli-audit-append-wired-doctor, cli-audit-append-wired-record, schema-audit-row. Fixed 2 test scaffold bugs:
   - `canonical_checker` hardcoded `Summary: 4 pass, 0 fail` (actual: 13/13)
   - `repair_refusal_envelope` jq precedence: `.status == "X" and .reason | test(...)` parsed as `((.status == "X" and .reason) | test(...))` instead of `.status == "X" and (.reason | test(...))`
9. **Lint pass** — `canonical-cli-lint.sh` initially flagged `cmd_health_loop` L2: infinite-loop function with no explicit `return 0`. Added the return. Lint exit 0.
10. **Verify** — all 32 in-bead PASS + sister regressions: 23/23 yy9qi + 24/24 ukbej + 19/19 f0e77 + 17/17 stash + 17/17 7228o = 100 sister assertions clean.

## Discoveries

1. **scaffolder-helper-lib-needs-deployed-companion** — scaffolding a target outside the flywheel repo (e.g., `~/.claude/skills/.flywheel/bin/*`) requires the helper lib deployed at the corresponding `_SCAFFOLD_REPO_ROOT/.flywheel/lib/` location. Without it, three helper functions no-op silently. Symmetric with template-install discipline.

2. **verb-collision-fillin-via-delegate-not-duplicate** — when the target ALREADY implements canonical verbs natively, scaffold stubs should DELEGATE (call original `cmd_*` / `emit_*`), not DUPLICATE. Requires restructure so originals are defined before the scaffold intercept fires. Sister fillins were duplicate-style because their targets had no canonical surface; verb-collision targets need this variant.

## Cross-orch unblock

Wave-2.0a sub-bead d closes; remaining sub-beads {a,b,c,e,f,g,h,i} of wave-2.0a are independent (different surfaces). The delegate pattern documented here applies to any other verb-collision surface in the wave.

## Pattern emerged

For canonical-cli scaffolding:
- **No verb collision** → scaffold stubs hold substantive logic (sister 1fk5f.{1..8})
- **Verb collision** → scaffold stubs delegate; original is lifted above intercept (this bead)
- **Helper lib** → must be deployed at `_SCAFFOLD_REPO_ROOT/.flywheel/lib/` for the helper functions to be live
