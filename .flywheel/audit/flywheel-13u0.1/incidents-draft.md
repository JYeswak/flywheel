# Draft INCIDENTS Entry: sidecar-processed-ledger-blindness

Target file if approved: `/Users/josh/Developer/flywheel/INCIDENTS.md`

Do not apply this draft without Joshua/orchestrator approval.

## sidecar-processed-ledger-blindness

Date: 2026-05-09

Promotion Action: DRAFT ONLY

Class: `sidecar-processed-ledger-blindness`

Severity: medium

Cost: Operator-facing unprocessed counts kept reporting drained fuckup rows as
live backlog. The raw event log stayed append-only by design, but list, probe,
tick, and learn surfaces that read only raw JSONL recreated phantom backlog and
caused repeated drain work.

Root Cause: Processed state lived in the canonical sidecar
`/Users/josh/.local/state/flywheel/fuckup-processed.jsonl`, while some
consumers still filtered only raw `fuckup-log.jsonl` rows. Immutable evidence
storage and mutable processing state were split correctly, but readers did not
join both sources.

Forever-Rule: Any UI, probe, list command, tick step, learn flow, or dashboard
that reports unprocessed event counts must consume the canonical processed-state
sidecar, not raw JSONL alone. Raw append-only logs remain evidence; the
operator-facing backlog is the raw event stream left-anti-joined against
`/Users/josh/.local/state/flywheel/fuckup-processed.jsonl`.

Fix Applied/Status: DRAFT from bead `flywheel-13u0.1`. Prior fixes already
landed in `flywheel-17g9` and `flywheel-5bq7`; this draft records the shared
incident class so future gap-hunt or promotion scans route to one durable
pattern instead of rediscovering sidecar blindness.

Evidence:
- Bead `flywheel-17g9`: patched `flywheel-loop fuckup list --unprocessed` to
  honor `~/.local/state/flywheel/fuckup-processed.jsonl`; close reason reports
  pre-equivalent count 54 and post-fix count 0.
- Bead `flywheel-5bq7`: patched `/flywheel:tick` and `/flywheel:learn`
  unprocessed-fuckup counting to join against the sidecar; close reason reports
  40 unprocessed via the new query versus 144 via the old query.
- Receipt path cited by `flywheel-17g9`: `/tmp/flywheel-17g9_findings.md`
  (not present at dispatch time, but preserved as the original closeout receipt
  path in the bead close reason and dispatch log).
- Current processed-state sidecar:
  `/Users/josh/.local/state/flywheel/fuckup-processed.jsonl`.
- Regression coverage: `tests/flywheel-loop-core.sh` test
  `T3.5 fuckup list --unprocessed honors processed sidecar`.

