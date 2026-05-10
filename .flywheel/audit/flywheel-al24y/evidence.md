---
title: flywheel-al24y evidence — storage-pressure-doctor.sh substantive 18-TODO fill-in
type: evidence
created: 2026-05-10
bead: flywheel-al24y
parent: storage lane fillin family (gam2k+s0c53+j0zuh siblings)
chain: doctor-mode-integration / storage-lane-fillin
---

# flywheel-al24y evidence

**Status:** DONE — all 18 canonical-cli-scaffold TODO markers replaced; 13/13 canonical-CLI tests PASS; lint clean.

## Acceptance gates

| AG | Status | Evidence |
|---|:-:|---|
| AG1: doctor returns substantive checks (≥3 dimensions) | DID — 6 checks |
| AG2: health probe consults real signal | DID — tail tmp-prune ledger; warn stale >24h |
| AG3: repair scopes with --dry-run/--apply discipline | DID — 2 scopes (stale-prune, runs-log-rotate) |
| AG4: validate <subject> has runnable contract | DID — 3 subjects (probe, row, config) |
| AG5: scaffolded test passes | DID — 13/13 PASS |
| AG6: canonical-cli-scoping checker still 13/13 | DID |
| AG7: canonical-cli-lint exits 0 | DID — clean (after L2 fix on pre-existing parse_args) |

did=7/7, didnt=none.

## Substantive fill-in

- **doctor**: 6 substrate checks (storage-probe executable, df/jq on PATH, tmp-prune ledger readable, runs ledger writable, flywheel root resolvable)
- **health**: tail tmp-prune ledger; recent_count + last_prune_ts + age_seconds; warn stale >24h
- **repair**: 2 scopes — `stale-prune` (plan-only points at canonical `private-tmp-prune.sh` from sister bead gam2k) + `runs-log-rotate` (5MB threshold)
- **validate**: 3 subjects — probe (storage-probe output schema), row (tmp-prune ledger row), config (env validation)
- **audit**: tail runs ledger with --tail=N
- **why <path>**: 2-tier provenance — tmp-prune ledger lookup + filesystem existence/size

## Sister calibration

L2 violation on pre-existing `parse_args` function (line 732, predates scaffold). Added explicit `return 0`. Linter clean post-fix.

## Sibling pattern

Family of three storage-lane fill-ins:
- `gam2k` (private-tmp-prune.sh) — shipped 950
- `al24y` (this — storage-pressure-doctor.sh)
- s0c53 / j0zuh (peer panes)

The recommendation chain: `repair --scope stale-prune` plan envelope on this surface points at the canonical mutation path on gam2k's surface — clean separation of "I diagnose" vs "I prune." Composability across surfaces.

## Cross-references

- Sister surfaces (storage lane): flywheel-gam2k, flywheel-s0c53, flywheel-j0zuh
- Tooling: scaffold-canonical-cli.sh (flywheel-ws02m), canonical-cli-lint.sh (flywheel-etp5n)
- Direct delegate: `.flywheel/scripts/storage-probe.sh`
- Delegate-target: `.flywheel/scripts/private-tmp-prune.sh` (canonical apply path)
