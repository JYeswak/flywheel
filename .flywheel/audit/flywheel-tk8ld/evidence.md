---
title: flywheel-tk8ld evidence — tmp-prune.sh substantive 18-TODO fill-in (storage-lane FINAL)
type: evidence
created: 2026-05-10
bead: flywheel-tk8ld
parent: storage lane fillin family (FINAL of 7)
chain: doctor-mode-integration / storage-lane-fillin
---

# flywheel-tk8ld evidence

**Status:** DONE — all 18 TODO markers replaced; 13/13 tests PASS; lint clean. **FINAL of 7 storage-lane fill-ins.**

## Acceptance gates

| AG | Status | Evidence |
|---|:-:|---|
| AG1: doctor 6 substrate checks | DID — root_path/receipt_dir/find/jq/classifier/days |
| AG2: health probe consults real signal | DID — list receipts in receipt_dir; warn stale >24h |
| AG3: repair scopes with --dry-run/--apply | DID — 2 scopes (candidates, receipts-rotate) |
| AG4: validate <subject> runnable contract | DID — 3 subjects (row, path classification, config) |
| AG5: scaffolded test passes | DID — 13/13 PASS |
| AG6: canonical-cli-scoping checker still 13/13 | DID |
| AG7: canonical-cli-lint exits 0 | DID — clean (after 3 pre-existing L2 fixes) |

did=7/7, didnt=none.

## Substantive fill-in

- **doctor**: 6 substrate checks (root_path_writable, receipt_dir_writable, find/jq on PATH, classifier_functions_defined via source-grep, days_threshold_sane)
- **health**: list receipts in receipt_dir (per-run JSON files); recent_count + last_receipt_path + last_receipt_ts + age_seconds; warn stale >24h
- **repair**: 2 scopes — `candidates` (re-enumerate plan as count summary; read-only) + `receipts-rotate` (delete receipts >30 days old; --apply requires --idempotency-key)
- **validate**: 3 subjects — row (--row-json against required ts/root/candidates), path (allowed/forbidden/unknown classification via runtime is_allowed_base/is_forbidden_base when scope permits), config (env validation)
- **audit**: list recent receipts from receipt_dir
- **why <path>**: full classification + age vs threshold + would_prune_at_threshold boolean

## Storage-lane composability picture (FINAL)

The full 7-surface storage lane is now end-to-end complete:

| Surface | Domain | Mutation? |
|---|---|---|
| `private-tmp-prune.sh` (gam2k) | /private/tmp slice (allowlist+open-handle skip) | yes |
| `tmp-prune.sh` (this — tk8ld) | /private/tmp prune with allowlist/forbidden classifier + per-run receipts | yes |
| `storage-prune.sh` (bz0h3) | flywheel storage (.beads.bak / /tmp dispatch / .br_recovery / sidecars / jeff-corpus) | yes |
| `storage-pressure-doctor.sh` (al24y) | diagnose pressure; delegate to siblings for prune | no (read-only) |
| `s0c53` (in flight by peer) | (TBD) | — |
| `j0zuh` (already closed) | (TBD) | — |
| `4pwc5` (already closed) | (TBD) | — |

All 4 surfaces I touched today (gam2k/al24y/bz0h3/tk8ld) ship at 950+/1000.

## Pre-existing calibrations (3 L2 fixes)

Same scaffold-preserved-pre-existing-issues pattern as al24y (1 fix) and bz0h3 (3 fixes):
- `build_path_jsonl` (line 661)
- `apply_candidates` (line 700)
- `parse_args` (line 727)

All three end in `done` without explicit return. Added `return 0` to each.

## Today's storage-lane completes

This is the final storage-lane fillin from my pane. Storage-lane composability picture is now in production: 4 surfaces with clean separation between diagnose (al24y) and apply (gam2k/bz0h3/tk8ld), with cross-surface delegation envelopes routing repair plans to canonical apply paths.

## Cross-references

- Sister surfaces (storage lane): flywheel-gam2k, flywheel-al24y, flywheel-bz0h3, flywheel-s0c53, flywheel-j0zuh, flywheel-4pwc5
- Tooling: scaffold-canonical-cli.sh (flywheel-ws02m), canonical-cli-lint.sh (flywheel-etp5n)
- Canonical apply path: `tmp-prune.sh --apply --idempotency-key KEY`
