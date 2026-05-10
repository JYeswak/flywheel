---
title: "Fleet Coherence Signal Quality Report"
type: plan
created: 2026-05-08
frontmatter_source: scaffold-doc-frontmatter
---

# Fleet Coherence Signal Quality Report

- Generated: `2026-05-08T19:38:27Z`
- Window: `24h` (`2026-05-07T19:38:27Z` through `2026-05-08T19:38:27Z`)
- Events: `/Users/josh/.local/state/flywheel/fleet-coherence/fleet-coherence-events-v2.jsonl`
- Latest snapshot: `/Users/josh/.local/state/flywheel/fleet-coherence/fleet-coherence-latest.json`
- Suppressions: `/Users/josh/Developer/flywheel/.flywheel/fixtures/fleet-coherence-suppressions-v2.jsonl`

## Summary

| metric | value |
|---|---:|
| shadow rows | 0 |
| malformed rows | 0 |
| invalid timestamp rows | 0 |
| p95 scan time | n/a |
| p95 status time | n/a |
| suppression rows | 5 |

## Rows Per Class

| class | rows | open | closed | suppressed | would_l61 | would_bead | false-positive notes |
|---|---:|---:|---:|---:|---:|---:|---|
| `none` | 0 | 0 | 0 | 0 | 0 | 0 | no rows in window |

## Dedupe Resend Behavior

| metric | value |
|---|---:|
| dedupe keys observed | 0 |
| unique dedupe keys | 0 |
| duplicate rows | 0 |
| resend_after rows | 0 |

Duplicate keys: none observed

## Shadow Side Effects

| side effect | rows detected |
|---|---:|
| real L61 sends | 0 |
| bead filing | 0 |
| topology mutation | 0 |

No real L61 sends, bead filing, or topology mutation were detected in the selected shadow rows.

## Latest Snapshot

- `schema_version`: `fleet-coherence-latest/v1`
- `generated_at`: `2026-05-07T16:50:42Z`

## Phase 2a Decision

Final go/no-go: **Phase 2a: BLOCKED**

Blocked by: `no_shadow_events`, `scan_timing_missing`, `status_timing_missing`.

Close evidence:
- `socraticode_queries=1 indexed_chunks_observed=10`
- Targeted validator: `tests/fleet-coherence-quality-report.sh`
