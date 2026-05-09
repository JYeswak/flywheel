---
ts: 2026-05-09T14:15:00Z
from: mobile-eats:1 (orchestrator)
to: flywheel:1 (fleet doctrine custodian)
type: l-rule-promotion-handoff
priority: medium
authorization: joshua-direct 2026-05-09T14:10Z ("yes - let pane 1 flywheel know and continue on your mission")
---

# L151 promoted in mobile-eats: SCHEMA-CHANGES-VIA-CANONICAL-MIGRATE-NEVER-MCP-APPLY

**TL;DR**: New L-rule landed in `~/Developer/mobile-eats/AGENTS.md` + sharded body at
`.flywheel/rules/L102-L151-schema-changes-via-canonical-migrate-never-mcp-apply.md`. Trauma class
`substrate-bypass`. Authorized by Joshua direct ("yes - let pane 1 flywheel know and continue").
Fleet-wide canonicalization recommended via doctrine-sync.

## Origin

mobile-eats Phase A iterate-with-founders sprint 2026-05-09 surfaced two intersecting trauma
events that converge on the same root cause:

1. **2026-05-09T05:08Z** — pane 2 codex authored ph1-005..010 + freshness mat-view + R5 substrate
   migrations manually per ph0-008 retrofit pattern. Workers wrote SQL directly without running
   `pnpm db:generate`. `_journal.json` stayed at 20 entries while on-disk SQL grew to 60+.
   `make migrate-live` exited 0 but applied nothing to `bsvatvfsqblsibblzlij` (orchestrator
   discovered via Supabase MCP `list_tables` showing 25 tables not 35+).
2. **2026-05-09T07:55Z** — orchestrator (mobile-eats:1, this pane) used Supabase MCP
   `apply_migration` directly to enable RLS on `__drizzle_migrations__` (responding to a
   security advisory). Authored matching Drizzle SQL file after-the-fact. Substrate-bypass:
   live state mutated before journal/migrations directory caught up.

Pane 2 cc Opus (after respawn-as-cc) reconciled both via 41-orphan journal walk + idempotent
DO-block guards on CREATE TYPE statements (commits 9139e96 + e87bd71). Pane 2 filed bead `odri`
documenting the trauma class with the doctrine fix proposal:

> "dispatch packets that author SQL must include 'apply via pnpm db:generate then pnpm db:migrate'
> as the only canonical path, never supabase MCP apply_migration directly"

Joshua-direct authorization 2026-05-09T14:10Z to promote to L-rule.

## Rule body (canonical at L151 in mobile-eats AGENTS.md + shard file)

```
All schema mutations (CREATE TABLE, ALTER TABLE, CREATE TYPE, CREATE INDEX,
ALTER POLICY, REVOKE/GRANT, RLS ENABLE/DISABLE) MUST flow through the
project's canonical migration toolchain — Drizzle migrate via the
Infisical-injected runner at `scripts/operator/run-with-infisical.sh`.
Workers and orchestrators MUST NOT use Supabase MCP `apply_migration`,
MCP `execute_sql` for DDL, or any out-of-band substrate path that mutates
schema without simultaneously updating the local `_journal.json` plus the
`db/migrations/*.sql` directory.
```

Full body at: `~/Developer/mobile-eats/.flywheel/rules/L102-L151-schema-changes-via-canonical-migrate-never-mcp-apply.md`

## Why this is fleet-wide concern not mobile-eats-specific

Any ZestStream service using Supabase + Drizzle (mobile-eats today; ALPS today; ZestStream-itself;
future projects) is exposed to the same trauma class. Supabase MCP exposes `apply_migration` +
DDL-capable `execute_sql` to ANY agent with auth. Without doctrine, workers default to whichever
tool surface is convenient — and that's MCP for one-shot fixes vs the canonical Drizzle flow
which has more steps. The shorter path is wrong.

Canonical flow (per L151) preserves single-source-of-truth. Supabase MCP `apply_migration` does
not update Drizzle's `_journal.json` and DOES update the `__drizzle_migrations__` row — but
under a different `hash` (Supabase computes its own) than what Drizzle would compute on next
migrate run. Result: future `pnpm db:migrate` either skips silently OR fails on duplicate-object
when re-running the (already-applied-out-of-band) migration.

## Recommended fleet-wide propagation

Per the established `flywheel-doctrine-sync` pattern (per L93/L99-class doctrine):

1. **Sync L151 to flywheel canonical AGENTS.md** at `~/Developer/flywheel/AGENTS.md` index plus
   sharded body at `~/Developer/flywheel/.flywheel/rules/L<count>-L151-...md`
2. **Propagate to all flywheel-installed repos** via existing doctrine-sync mechanism:
   - `~/Developer/skillos/`
   - `~/Developer/alpsinsurance/`
   - `~/Developer/picoz/` / `polymarket-pico-z/`
   - `~/Developer/vrtx/`
   - `~/Developer/zesttube/`
   - `~/Developer/zeststream-v2/`
   - `~/Developer/frankensuite/` (if applicable)
   - any other Supabase-using project
3. **Update worker-dispatch templates** (skillos packs, etc.) to include the canonical
   Drizzle-migrate phrasing in any dispatch packet that authors SQL or mutates schema
4. **Doctor probe**: optional — a fleet-wide `flywheel-doctor` check that scans
   recent commits for `apply_migration` / `execute_sql` DDL patterns and surfaces violations
   as fuckup-log rows for L52 issues-to-beads compliance
5. **Update Supabase MCP server-side guidance** (via the canonical wrapper at
   `~/.flywheel/bin/infisical-safe`-equivalent for Supabase MCP if one exists, OR a
   pre-tool-use hook) to refuse `apply_migration` calls without an accompanying
   `db/migrations/*.sql` file path argument

## What this handoff does NOT do

- mobile-eats:1 does NOT modify flywheel AGENTS.md directly (per L48 binary-mod halt; flywheel
  doctrine canonicalization is owned by flywheel:1)
- mobile-eats:1 does NOT propagate to skillos/alps/etc. directly (cross-repo doctrine
  propagation owned by flywheel:1)
- This handoff just announces the rule + provides the canonical body for sync

## Mobile-eats local status

- L151 file at `~/Developer/mobile-eats/.flywheel/rules/L102-L151-...md` ✓
- L151 indexed in `~/Developer/mobile-eats/AGENTS.md` END-RULES-INDEX ✓
- Commit `1c2dd88` ✓
- Bead `odri` will close when flywheel-canonical sync confirms; bead `ugl1` already closed by pane 2
- Pre-existing AGENTS.md duplicate index footer issue (8 duplicates) cleaned up as side benefit
  of the replace_all edit — net file is shorter (3589 deletions) + better-formed

## Joshua context

Mobile-eats Phase A is feature-complete + live-validated against `bsvatvfsqblsibblzlij`. 71
real Missoula trucks seeded; both centerpiece moats (§5.5 owner toolkit + §11.5 close-loop)
shipped; AI Concierge (Haiku 4.5 + 20/20 eval) live; Drive Feature MVP live; R5 retention
engine live. Phase B (sharing surface) shipped Gap 2 (`/share/[slug]` thin preview) +
Gap 1 (`/drives/share/[token]`) + Gap 3 (`/now/[token]` owner-update broadcasts). 15
security advisors cleared, 5 remaining (none P0). Joshua + Chanel about to start
iterate-with-founders testing. ZestStream platform architecture (one house) directive
ratified — shared `@zeststream/*` packages will house cross-cutting concerns from day 1.

No urgent action requested from flywheel:1; the doctrine-sync cadence handles propagation
on its normal pulse.

— mobile-eats:1
