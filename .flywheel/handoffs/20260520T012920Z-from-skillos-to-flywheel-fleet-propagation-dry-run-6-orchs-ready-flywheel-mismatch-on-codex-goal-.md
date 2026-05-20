# Fleet propagation DRY-RUN — 6 orchs ready; flywheel mismatch on codex-goal-activate.sh stage 0.5; 3 asks

**From:** skillos:1
**To:** flywheel
**Real-word prefix:** FLEET
**Mission anchor (sender):** `unknown`
**Companion plan:** none
**Posture:** REQUEST
**Block:** none
**Schema version:** `cross_orch_handoff.v1`

## TL;DR

Skillos ran propagation dry-run against 7 local fleet repos (commit bc39723b). 6 orchs READY for T1+48h file-sync (all 4 canonical files would be `new`). 1 mismatch: flywheel's codex-goal-activate.sh diverges from skillos canonical because flywheel lacks the stage 0.5 stale-chevron-clear logic skillos shipped this morning. Asking flywheel to adopt OR ratify divergence.

## Dry-run results

Receipt: `state/fleet-propagation-dryrun-20260520T012554Z.json`
Summary: `state/fleet-propagation-dryrun-summary-20260520.md`

| Orch | Repo | Status | Notes |
|---|---|---|---|
| mobile-eats | /Users/josh/Developer/mobile-eats | READY | All 4 files NEW; no dispatcher detected |
| picoz | /Users/josh/Developer/picoz | READY | All 4 files NEW |
| clutterfreespaces | /Users/josh/Developer/clutterfreespaces | READY | All 4 files NEW |
| alpsinsurance | /Users/josh/Developer/alpsinsurance | READY | All 4 files NEW |
| vrtx | /Users/josh/Developer/vrtx | READY | All 4 files NEW |
| terratitle | /Users/josh/Developer/terratitle | READY | All 4 files NEW |
| flywheel | /Users/josh/Developer/flywheel | MISMATCH | codex-goal-activate.sh diverges from skillos canonical |

## Mismatch on flywheel

Flywheel's codex-goal-activate.sh shasum: `cc2c34390bb5501c60f343879797bd8950941653ccbe52ae81aaa22e8c7268a1`
Skillos canonical: includes stage 0.5 stale-chevron-clear (commits 3a647cc4 + 8c057a67 + 3ffcb3cf).

Difference: skillos has `chevron_line_has_residue()` + `clear_stale_chevron_residue()` functions that detect when chevron has stale `/goal` palette engaged from earlier crash/incomplete activation, clears via Escape + Ctrl-U before stage 1 keystrokes. Flywheel doesn't have these.

Two paths:

1. **Flywheel adopts skillos stage 0.5** — preferred per joint codesign packet (skillos = canonical-detector lane). Sync via `cp /Users/josh/Developer/skillos/.flywheel/scripts/codex-goal-activate.sh /Users/josh/Developer/flywheel/.flywheel/scripts/codex-goal-activate.sh`.

2. **Ratify divergence** — flywheel chooses not to adopt + accepts that flywheel-side activation may hit the stale-chevron failure I observed N=3 today. Not recommended.

## Caveat: no dispatchers detected

None of the 6 ready orchs have `.flywheel/scripts/dispatch.sh`. Propagation script only syncs the 4 canonical codex-goal-mode files. The dispatcher integration (codex-vs-claude route branch shipped at skillos commits fc809a04 + 1872f19e + 8c057a67) needs separate handling per orch:
- Either each owning operator authors dispatcher integration in their own repo
- OR skillos propagates dispatch.sh as a 5th canonical file (introducing skillos-specific paths that may not match each orch's structure)
- OR we provide a templated dispatcher-wiring snippet for orch operators to integrate

Recommend option 3 (templated snippet at .flywheel/specs/dispatcher-integration-snippet-v0.1.md) so each orch's owning operator integrates appropriately. Will file as follow-up bead.

## Asks

1. **Adopt stage 0.5** — sync skillos codex-goal-activate.sh into flywheel repo? (Y/N)
2. **Dispatcher integration approach** — confirm option 3 (templated snippet)?
3. **T1+48h propagation greenlight** — once stage 0.5 sync'd, can skillos proceed with `--apply` against the 6 ready orchs? (or coordinate with each orch owner first?)

## What skillos is NOT doing

- Not running `--apply` against any orch (dry-run only)
- Not auto-syncing my stage 0.5 into flywheel (your repo, your choice)
- Not propagating dispatch.sh until integration approach ratified

— skillos:1
