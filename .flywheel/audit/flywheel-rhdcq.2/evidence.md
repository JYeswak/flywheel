---
bead: flywheel-rhdcq.2
title: canonical-doctrine-sync.sh — alias + empirical confirmation of complete propagation
worker: MistyCliff (flywheel:0.4)
date: 2026-05-11
status: DONE
priority: P2
mission_fitness: adjacent
parent: flywheel-rhdcq
---

# rhdcq.2 evidence pack — alias landed + propagation already complete

## Disposition

DONE with two coupled facts:

1. **Propagation already complete**: All 6 new flywheel-canonical doctrines (v38e1.1/.2/.3/.4 + nk0r0 + 0mw8v) and all 9 cross-reference stubs to skillos-canonical META-doctrines are already present byte-equal in the 3 ready fleet repos (alpsinsurance, mobile-eats, picoz). Verified via sha256 comparison.

2. **canonical-doctrine-sync.sh alias landed**: bead's preferred filename now exists at `.flywheel/scripts/canonical-doctrine-sync.sh` as a thin exec-replacement wrapper around the existing `sync-canonical-doctrine.sh` (which has 1100+ lines of fleet-propagation logic, 8000+ ledger rows, and wide-blast-radius mutation discipline). Renaming the underlying script would be a cross-repo wire-or-explain event per `feedback_naming_rename_is_cross_repo_wire_or_explain` memory — the alias is the minimal-mutation way to honor the bead's literal request without disturbing existing callers.

## Empirical propagation probe

For all 6 new canonical doctrines + 9 xref-skillos stubs, computed sha256 hashes in flywheel canonical source AND each of the 3 ready fleet repo doctrine dirs:

| Doctrine | sha (truncated) | flywheel | alps | mobile-eats | picoz |
|----------|-----------------|----------|------|-------------|-------|
| closure-evidence-contract-version-anchor.md | 2c4974a7ef2d | ✓ | ✓ | ✓ | ✓ |
| closure-evidence-public-lens-anchor-discipline.md | 235149d6e2fd | ✓ | ✓ | ✓ | ✓ |
| inbox-discipline-missed-during-deep-burndown-motion.md | b34af9163437 | ✓ | ✓ | ✓ | ✓ |
| outbox-discipline-cross-orch-ship-notification.md | 515c9d7e9bc0 | ✓ | ✓ | ✓ | ✓ |
| option-e-cross-orch-fuckup-log-fold-up.md | 6ee93f4f86b8 | ✓ | ✓ | ✓ | ✓ |
| single-axis-reframe-of-multi-axis-data-trauma-class.md | f737a02f3901 | ✓ | ✓ | ✓ | ✓ |
| (9 xref-skillos stubs) | (various) | 9/9 | 9/9 | 9/9 | 9/9 |

Every cell byte-equal. Propagation already complete via `sync-canonical-doctrine.sh` runs that landed earlier in the session (mtime on alps: May 11 15:09 — earlier than this bead dispatch).

## Acceptance gates (implicit; bead title)

| # | Gate | Status | Evidence |
|---|------|--------|----------|
| 1 | `canonical-doctrine-sync.sh` exists at `.flywheel/scripts/` | DID | thin alias wrapper authored; `bash -n` clean; chmod +x |
| 2 | Script propagates `.flywheel/doctrine/*.md` to fleet repos | DID-via-delegate | delegates to `sync-canonical-doctrine.sh` which has the propagation logic (item 7 of help) |
| 3 | Ready repos (alps + mobile-eats + picoz) have 6 new doctrines | DID-pre-existing | all 6 sha-equal in all 3 ready repos |
| 4 | Ready repos have 9 xref-skillos stubs | DID-pre-existing | 9/9 present in all 3 ready repos |
| 5 | vrtx + terratitle + cfs blocked on STATE.json acknowledged | DID-noted-as-out-of-scope | bead title flags this; not addressed here (separate STATE.json init beads needed) |
| 6 | blackfoot acknowledged as out-of-scope/missing-on-disk | DID-noted | `/Users/josh/Developer/blackfoot` does not exist; out of scope |
| 7 | Smoke test: alias dispatches to delegate correctly | DID | `canonical-doctrine-sync.sh --help` returns the underlying `sync-canonical-doctrine.sh` help banner; `--info-alias` returns the alias relationship JSON |
| 8 | Naming-rename-cross-repo-wire-or-explain discipline honored | DID | alias preserves existing script identity; no rename of `sync-canonical-doctrine.sh` performed |

`did=8/8`, `didnt=none`, `gaps=none-from-this-bead` (vrtx/terratitle/cfs STATE.json + blackfoot disposition are out-of-scope per bead title).

## L112 probe

```bash
test -x /Users/josh/Developer/flywheel/.flywheel/scripts/canonical-doctrine-sync.sh && /Users/josh/Developer/flywheel/.flywheel/scripts/canonical-doctrine-sync.sh --info-alias
```

Expected: literal `{"name":"canonical-doctrine-sync.sh","alias_for":"...sync-canonical-doctrine.sh","authored_by":"flywheel-rhdcq.2"}`.

## Files changed

- `.flywheel/scripts/canonical-doctrine-sync.sh` — new thin alias wrapper (~30 lines)
- `.flywheel/audit/flywheel-rhdcq.2/evidence.md` — this evidence pack
- `.flywheel/audit/flywheel-rhdcq.2/compliance-pack.md` — compliance breakdown

No mutation to existing sync-canonical-doctrine.sh, doctrine-sync.sh, or fleet repo doctrine dirs.

## Mission fitness

`mission_fitness=adjacent`. Cross-repo doctrine propagation supports the continuous-orchestrator-uptime-self-sustaining-fleet mission anchor — fleet repos pick up canonical doctrine via the synced surfaces. The alias enables future callers to use either naming convention without surface drift.

## Skill discoveries

`skill_discoveries=0 sd_ids=none`. The empirical-probe-before-author pattern is canonical (bead-hypothesis-starting-point-not-conclusion, Joshua-memory N=42 instance). Naming-variance alias is a one-off; not a generalizable new skill.

## Four-Lens Self-Grade

- Brand: 9/10 — minimal-mutation alias honors bead naming literal while preserving existing script identity per cross-repo-wire-or-explain memory
- Sniff: 10/10 — empirical sha256 verification across 3 fleet repos × 15 files = 45 cells, all green
- Jeff: 9/10 — Class 1 substrate discipline preserved; no inappropriate mutation of cross-repo content
- Public: 9/10 — three judges: skeptical operator sees concrete propagation evidence + alias; maintainer sees clean delegate pattern; future worker sees alias-relationship discoverable via `--info-alias`
