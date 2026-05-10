# flywheel-wzjo9.4.2 — apply-spec

## Identity

**Bead:** flywheel-wzjo9.4.2
**Wave label:** wave-2.0d-b (sub-bead b of 2 in wave-2.0d — recovery lane cleanup)
**Parent (wave):** flywheel-wzjo9.4
**Grandparent (lane):** flywheel-wzjo9

## Surface

| Attribute | Value |
|---|---|
| Name | `flywheel.bak-2026-04-28-pre-3fail-fix` |
| Path | `/Users/josh/.claude/skills/.flywheel/bin/flywheel.bak-2026-04-28-pre-3fail-fix` |
| Lines | 2301 |
| Interpreter | bash |
| Priority | P2 |
| Location | skill bin (LEGACY BACKUP) |

## Special note — RECOMMENDED HOLD-BACK

**LEGACY BACKUP SURFACE:** This is a 2026-04-28 backup of the main `flywheel` CLI taken before the "3fail-fix" change. It is the **second legacy backup encountered in the recovery lane** — sister wzjo9.1.5 (`flywheel.bak-2026-04-28-pre-substrate-intake`, 2346 lines) was held back pending Joshua confirmation by the same rationale.

**Recommended disposition:** **DEFER pending Joshua confirmation.** Legacy backups are operator-side decisions, not substrate-shaped surfaces:
- They exist as point-in-time recovery snapshots, not active code paths
- Scaffolding 2301 lines (largest in recovery lane) into a canonical surface would expand to ~6500-7000 lines for a file that may never be invoked again
- The doctrine question is whether legacy backups should receive canonical scaffolding AT ALL — Joshua's call

**If Joshua approves canonical scaffolding:**
- Apply hybrid producer variant doctrine (wzjo9.3.4) since the active `flywheel` CLI is multi-feature
- Expect ~3-5x expansion → 6900-11500 lines (largest surface in any lane)
- Effort estimate: 90-120 min (2-3x sister-fillin baseline due to surface size)

**If Joshua confirms hold-back:**
- Close this bead with `disposition=joshua-deferred-legacy-backup`
- File matches sister wzjo9.1.5 disposition — both legacy backups deferred consistently

## Scope (if Joshua approves)

Single-surface scaffold + 18-TODO substantive fillin following the hybrid-producer variant pattern (wzjo9.3.4 exemplar).

## Deliverables (if Joshua approves)

1. Dry-run scaffold
2. Apply with idempotency-key
3. Substantive 18-TODO fillin (hybrid-producer variant — file + DB + events)
4. Test additions: extend baseline 13-test scaffold to 20

## Acceptance gates (if Joshua approves)

- AG1-5: standard sister-fillin shape

## Estimated wall-time

**Disposition pending Joshua confirmation.** If approved: 90-120 min (largest surface in recovery lane). If deferred: 0 min (close as `joshua-deferred-legacy-backup`).

## Cross-refs

- Parent (wave): flywheel-wzjo9.4
- Sister legacy backup (deferred): flywheel-wzjo9.1.5 (`flywheel.bak-2026-04-28-pre-substrate-intake`, 2346 lines)
- Lane: flywheel-wzjo9
- Closest pattern match (if scaffolded): wzjo9.3.4 (hybrid producer)

## Doctrine question for Joshua

Should legacy backup files (`flywheel.bak-YYYY-MM-DD-pre-*`) receive canonical-CLI scaffolding? Or should they be excluded from canonical-CLI coverage on the basis that they are inert recovery snapshots, not active substrate?

Sister wave-2.0d-a (npm-install-guard.sh, wzjo9.4.1) can ship independently of this decision.
