---
title: flywheel-bz0h3 evidence — storage-prune.sh substantive 18-TODO fill-in
type: evidence
created: 2026-05-10
bead: flywheel-bz0h3
parent: storage lane fillin family
chain: doctor-mode-integration / storage-lane-fillin
---

# flywheel-bz0h3 evidence

**Status:** DONE — all 18 canonical-cli-scaffold TODO markers replaced; 13/13 tests PASS; lint clean (after 3 pre-existing L2 fixes).

## Acceptance gates

| AG | Status | Evidence |
|---|:-:|---|
| AG1: doctor 6 substrate checks | DID — repo/find/jq/runs_log/jeff_corpus/days_threshold |
| AG2: health probe consults real signal | DID — tail runs ledger; warn stale >7 days |
| AG3: repair scopes with --dry-run/--apply | DID — 2 scopes (candidates, runs-log-rotate) |
| AG4: validate <subject> runnable contract | DID — 3 subjects (plan, path classification, config) |
| AG5: scaffolded test passes | DID — 13/13 PASS |
| AG6: canonical-cli-scoping checker still 13/13 | DID |
| AG7: canonical-cli-lint exits 0 | DID — clean (after 3 L2 fixes on pre-existing functions) |

did=7/7, didnt=none.

## Substantive fill-in

- **doctor**: 6 substrate checks (flywheel_repo_resolvable, find/jq on PATH, runs ledger writable, jeff_corpus_dir resolvable-or-absent-OK, days_threshold sane)
- **health**: tail runs ledger (recent_count, last_run_ts, **last_apply_ts** distinct from last_run_ts, age_seconds); warn stale >7 days
- **repair**: 2 scopes — `candidates` (re-enumerate plan as count summary; read-only) + `runs-log-rotate` (5MB threshold)
- **validate**: 3 subjects — plan (--plan-json against required), path (5-class classification: .beads.bak / dispatch-artifact / br_recovery / sidecar / jeff-corpus / not-prunable), config (env validation)
- **audit**: tail runs ledger
- **why <path>**: full classification + age vs threshold (uses 14-day threshold for jeff-corpus paths, 7-day for others); emits `would_prune_at_threshold` boolean

## Cross-surface delegation pattern (continued from al24y)

This surface owns the **canonical apply path** for general flywheel storage pruning (`storage-prune.sh --apply --idempotency-key KEY`). al24y's `repair --scope stale-prune` plan envelope points at this. gam2k owns the more-specific `/private/tmp` slice. Three storage-lane surfaces, three different mutation domains, with clean cross-references.

## Pre-existing calibrations (3 L2 fixes)

Three functions predated the canonical-cli scaffold and shared the same enumerator-missing-return-zero pattern:
- `br_recovery_candidates` (line 575)
- `apply_plan` (line 657)
- `parse_args` (line 705)

All three end in `done` (loop terminator) without explicit return. Added `return 0` to each. Sister to today's other "scaffold preserved pre-existing L2 issues" pattern (al24y caught one, this caught three).

## Sibling pattern

6th of 7 storage-lane fill-ins:
- gam2k (private-tmp-prune.sh) — shipped 950
- al24y (storage-pressure-doctor.sh) — shipped 950
- bz0h3 (this — storage-prune.sh)
- s0c53, j0zuh, 4pwc5 (peer panes; varying status)

## Cross-references

- Sister surfaces (storage lane): flywheel-gam2k, flywheel-al24y, flywheel-s0c53, flywheel-j0zuh, flywheel-4pwc5
- Tooling: scaffold-canonical-cli.sh (flywheel-ws02m), canonical-cli-lint.sh (flywheel-etp5n)
- Cross-surface delegation: al24y's `repair --scope stale-prune` → this surface's canonical apply path
