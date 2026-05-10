---
title: flywheel-5kjez evidence — dispatch-delivery-verify.sh substantive 18-TODO fill-in
type: evidence
created: 2026-05-10
bead: flywheel-5kjez
parent: flywheel-wgitr (decomposition family — sub-bead 6 of 8)
chain: doctor-mode-integration / dispatch-lane-fillin
---

# flywheel-5kjez evidence

**Status:** DONE — all 18 TODO markers replaced; 15/15 tests PASS; lint clean.

## Acceptance gates

| AG | Status | Evidence |
|---|:-:|---|
| AG1: doctor 5 substrate checks | DID — ntm/jq/ledger/fuckup_log/probes |
| AG2: health probe consults real signal | DID — recent verified/failed counts; warn on >50% failure or stale >24h |
| AG3: repair scopes with --dry-run/--apply | DID — 2 scopes (re-verify, ledger-rotate) |
| AG4: validate <subject> runnable contract | DID — 3 subjects (row, task-id ledger lookup, config) |
| AG5: scaffolded test passes | DID — 15/15 PASS (2 above standard 13/13 baseline) |
| AG6: canonical-cli-scoping checker still 13/13 | DID |
| AG7: canonical-cli-lint exits 0 | DID — clean, no pre-existing L2 issues |

did=7/7, didnt=none.

## Substantive fill-in

- **doctor**: 5 substrate checks (ntm executable, jq on PATH, ledger writable, fuckup_log writable, ntm history/activity/changes/conflicts subcommands present)
- **health**: tail ledger; recent_count + **verified_count + failed_count** distinct + last_run_ts + freshness; warn when >50% failure rate OR stale >24h
- **repair**: 2 scopes — `re-verify` (count recent unverified, last failed task; plan-only points at canonical run path) + `ledger-rotate` (5MB threshold)
- **validate**: 3 subjects — row (against ts/task_id/session/pane/verified), task-id (ledger lookup; emits verified boolean from row), config (env validation)
- **audit**: tail ledger
- **why <task_id>**: ledger lookup; emit verification provenance (verified, reason, matched_at_line) or status=not_in_ledger

## Live signal surfaced

`repair --scope re-verify` immediately surfaced **`recent_unverified_count: 1`** on real ledger data — there's a recent unverified task. Substantive fill-in catching real fleet state, sister to vc3zs's surfacing pattern.

## Family progress

This is sub-bead **6 of 8** from the wgitr decomposition I filed early today (vc3zs was 1 of 8 closed earlier; this is 6 of 8). The decomposition is producing through-line value: each sub-bead ships at ~25 min wall clock, all hit 950+/1000 compliance.

## Cross-references

- Parent: `flywheel-wgitr` (decomposition family)
- Sister sub-bead closed today: `flywheel-vc3zs` (dispatch-and-log.sh)
- Tooling: scaffold-canonical-cli.sh (flywheel-ws02m), canonical-cli-lint.sh (flywheel-etp5n)
- Subject ledger: `~/.local/state/flywheel/dispatch-delivery-verify-ledger.jsonl`
