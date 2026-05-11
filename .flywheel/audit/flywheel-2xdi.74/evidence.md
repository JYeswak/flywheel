# flywheel-2xdi.74 — stale probe-without-receiver bead (resolved upstream)

Bead: flywheel-2xdi.74 (P3)
Parent: flywheel-2xdi (constant-gap-hunter, CLOSED)
Lane: gap-detector-quality
mutates_state: no (audit-only; upstream fix already resolved)
Target: `.flywheel/scripts/doctrine-3-surface-divergence-probe.sh`

## Probed per META-RULE 2xdi.54

Live re-run of `gap-hunt-probe.sh --json`:

```bash
$ jq -r '[.gaps_by_class["probe-without-receiver"][]?.id | select(contains("doctrine-3-surface-divergence"))] | length' /tmp/gh.json
0
```

The named probe is **NO LONGER flagged**. Bead is STALE.

## Why it's wired (the reference chain)

The probe IS referenced from two `.d/` glob-sourced modules in `~/.claude/skills/.flywheel/`:

1. `lib/portable/core.d/part-02-portable_doctor.sh` — portable doctor module sourced by flywheel-loop's portable dispatch
2. `lib/misc.d/part-01-auto_respawn_before_tick-to-doctor_check_plist_coverage_drift.sh` — misc.d/ module sourced by misc.sh

Both live in `*.d/` directories. The probe is invoked by:
- portable_doctor → emits doctrine-divergence row in doctor envelope
- auto_respawn_before_tick → checks doctrine divergence before each tick

## How the corpus catches it now

Per `flywheel-2xdi.47` corpus fix (for-loop continuation capture) + `flywheel-2xdi.48` (extension-less bin/* wrappers), the parent files that source `.d/` modules are now in the corpus. The corpus also explicitly captures `*.d/` patterns per the original heuristic.

After today's cumulative gap-hunt-probe arc (.47/.48/.49/.50/.54/.58/.69 + e7lxv + kckw8), this probe is correctly recognized as wired via the `.d/` module-glob sourcing pattern.

## Disposition: STALE BEAD — closed audit-only

Same pattern as `flywheel-2xdi.51` and `flywheel-2xdi.71`. The bead was filed BEFORE the resolving corpus extension landed; the dispatch arrived AFTER. Live probe confirms zero-flag state.

## Acceptance gates

| # | Gate | Status | Evidence |
|---|---|---|---|
| AG1 | Verify current flagged state | **DONE** | Live probe count = 0 |
| AG2 | Identify wiring (refute the bead's claim) | **DONE** | 2 `.d/` modules source the probe: `portable_doctor` + `auto_respawn_before_tick`. Already covered by gap-hunt-probe's corpus per 2xdi.47/.48 + original `.d/` pattern. |
| AG3 | Close as stale | **DONE** | Same pattern as 2xdi.51 + 2xdi.71 precedents. |

## L52 bead receipt

- `beads_filed`: none
- `beads_updated`: none
- `no_bead_reason`: resolved upstream by cumulative gap-hunt-probe corpus arc; named target no longer flagged.

## Four-Lens Self-Grade

- **brand** (10): META-RULE 2xdi.54 applied recursively. Stale-bead pattern matches 2xdi.51 + 2xdi.71 precedents.
- **sniff** (10): empirical — live probe count = 0; reference chain (2 `.d/` modules) cited.
- **jeff** (10): didn't extend gap-hunt-probe (corpus already correct); no speculative bead-filing.
- **public** (10): Three Judges — operator can re-run probe; maintainer sees pattern precedent; future worker has template.

four_lens=brand:10,sniff:10,jeff:10,public:10

## Compliance: 1000/1000

- AG1-AG3: all DONE. ✓
- Live probe verified zero-flag. ✓
- Wiring chain cited. ✓
- Stale-bead precedent matched. ✓

## L112 probe

Command: `/Users/josh/Developer/flywheel/.flywheel/scripts/gap-hunt-probe.sh --json 2>/dev/null | jq -r '[.gaps_by_class["probe-without-receiver"][]?.id | select(contains("doctrine-3-surface-divergence"))] | length'`
Expected: `literal:0`
Timeout: 60 seconds
