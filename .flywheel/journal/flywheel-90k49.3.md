---
bead: flywheel-90k49.3
title: add sbh to jeff-binary-version-watchtower (canonical-binary probe + release watch)
worker: MistyCliff (flywheel:0.4)
date: 2026-05-11
status: shipped
priority: P4
mission_fitness: adjacent
parent: flywheel-90k49
sister: flywheel-90k49.1 (formula watch), flywheel-90k49.2 (capability matrix), flywheel-bx592 (install-now-actionable), flywheel-tymgr (deferred memory edit)
---

# Journey: flywheel-90k49.3

## What the bead asked for

Three deliverables, with explicit "no memory edit before load-bearing" constraint:

1. Add `sbh` to watchtower with `sbh --version` probe + upstream release tag check
2. Add `homebrew-sbh` tap to corpus inventory + daily-delta watch
3. Update memory `reference_jeff_substrate_inventory.md`

## What I shipped

### Gate 1: watchtower wire-in
Added `sbh_binary_version_watch` parallel to existing ntm canonical-binary
pattern. Gated on `command -v sbh` — emits `status=not_installed` cleanly
until SBH lands. Fixture env vars (`SBH_VERSION_FIXTURE`, `SBH_RELEASE_FIXTURE`)
for deterministic testing. Wired into rows[]/watchlists/stale[]/counts.

### Gate 2: already done by 90k49.1
Corpus enumeration: `storage_ballast_helper` is in repo-inventory plans.
Daily-delta watch: `homebrew_sbh_formula_watch` (90k49.1) polls Formula/.
No duplicate function added.

### Gate 3: deferred per bead constraint
"No memory edit before SBH is actually load-bearing." Filed
`flywheel-tymgr` (P4) with explicit acceptance: SBH installed + ≥1
flywheel script imports SBH as load-bearing. Linked to 90k49 + bx592.

## Verification

- 11/11 new regression (4 states covered: not_installed, current, behind, ahead via fixtures)
- Sister suites 9/9, 20/20, all green

## L112 probe

    bash .flywheel/scripts/jeff-binary-version-watchtower.sh --dry-run --json \
      | jq -r '.watchlists.sbh_binary_release.status'

Expected today: `literal:not_installed`. Will flip to `ok` after bx592 install lands — that flip IS the success signal for the full chain.

## Pattern note

Convergent application of the watchtower's canonical-binary pattern (ntm).
Not a novel skill emergence — confirming that the existing pattern handles
"gated dependency that's not yet load-bearing" cleanly with `command -v`
gating + fixture support is itself a validation of the abstraction.
