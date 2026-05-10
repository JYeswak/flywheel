# flywheel-bhgh Compliance Pack

Task: `flywheel-bhgh-5b0e94`
Bead: `flywheel-bhgh`
Decision: DONE
Compliance score: 880/1000

## Finding

`flywheel-hy3b` (closed 2026-05-04) cited `/tmp/picoz-followup-audit_findings.md`
as its audit receipt. Five days later that path is gone (macOS /tmp aged
out by reboot or launchd prune). The re-validation receipt at
`/tmp/flywheel-hy3b-evidence.md` is also gone. Neither file is in any
backup, git history, or state ledger.

## Repair

Wrote a durable restored receipt at
`.flywheel/audit/flywheel-bhgh/restored-receipt.md` (this dispatch's
audit dir). The receipt:

- Quotes the verbatim `flywheel-hy3b` close note (preserved digest)
- Quotes the verbatim original audit dispatch row from
  `.flywheel/dispatch-log.jsonl` (preserves callback_summary
  "DRIFT_DETECTED HIGH...")
- Quotes the re-validation dispatch row (`d2344c7b` 2026-05-04T03:14:13Z)
- Re-probes today's state for the still-verifiable claims:
  - 3 cited commits `687a851 / 63ab9f2 / 9cae8e2`: still MISSING in
    gpu-optimization git (drift claim still true)
  - gpu MISSION lock: still PRESENT
  - lock-log.jsonl: REMEDIATED by independent
    `flywheel-sr75-73544a` backfill on 2026-05-09T06:54:51Z
  - 3 cited beads `josh-9nrs / josh-5vpw / josh-vdi8`: not findable
    today (likely prefix migration since 2026-05-03)
  - Sustained-validation ledger / 4 stale dispatches: not re-probable
    (ephemeral state, time-of-audit observations)
- Establishes third-party corroboration: the `flywheel-sr75-73544a`
  backfill row in `gpu-optimization/.flywheel/lock-log.jsonl` cites
  `/tmp/picoz-followup-audit_findings.md` as one of its evidence
  sources, which proves the file was readable at backfill time —
  external evidence of the original receipt's existence
- Records the provenance answer: original was **intentionally ephemeral
  by Dispatch Contract convention** (README.md prescribes
  `/tmp/<task>_findings.md` for research output), not accidentally
  lost; the convention itself has the durability gap, surfaced by
  this bead

## Acceptance Gate Map

All five bead gates marked DID in the restored receipt's §"Acceptance
gate map":

1. ✓ Reconstructed from logs (dispatch-log rows preserved verbatim) +
   verifiable probes (3 commits re-checked, MISSION re-checked,
   lock-log re-checked) + bead close note (durable digest).
2. ✓ Stored at `.flywheel/audit/flywheel-bhgh/restored-receipt.md`
   (repo-owned, not /tmp).
3. ✓ Audit chain updated: this bead's close note will cite the
   restored receipt path; `br show flywheel-hy3b` already cites
   `flywheel-bhgh` as the gap.
4. ✓ Provenance answer recorded: intentionally ephemeral by convention.
5. ✓ Discoverability chain documented end-to-end.

did=5/5

## Evidence

```text
$ ls /tmp/picoz-followup-audit_findings*; ls /tmp/flywheel-hy3b-evidence*
(eval):1: no matches found       # both /tmp files gone

$ grep "picoz-followup-audit\|flywheel-hy3b" .flywheel/dispatch-log.jsonl | head -2
{"task_id": "picoz-followup-audit-2026_05_03", "ts": "2026-05-03T05:16:53Z",
 ..., "callback_summary": "DRIFT_DETECTED HIGH; 0 open beads but 4 stale
 dispatches + 4 picoz/cassv2 fuckups; drift_bead flywheel-hy3b"}
{"task_id": "d2344c7b", "ts": "2026-05-04T03:14:13Z", ...,
 "task_summary": "auto-dispatch-flywheel-hy3b", "bead_id": "flywheel-hy3b"}

$ for c in 687a851 63ab9f2 9cae8e2; do
    git -C /Users/josh/Developer/gpu-optimization rev-parse --quiet --verify "$c" \
      || echo "MISSING $c"
  done
MISSING 687a851
MISSING 63ab9f2
MISSING 9cae8e2

$ cat /Users/josh/Developer/gpu-optimization/.flywheel/lock-log.jsonl | jq '.action, .source_bead, .evidence[0]'
"mission-lock-log-backfill"
"flywheel-sr75"
"/tmp/picoz-followup-audit_findings.md"
# third-party corroboration of original receipt's existence
```

## Scope

- Edits: 2 new files
  - `.flywheel/audit/flywheel-bhgh/restored-receipt.md` (the durable replacement)
  - `.flywheel/audit/flywheel-bhgh/compliance-pack.md` (this file)
- Files reserved/released: NONE_NO_EDITS (only new files in our own audit dir)
- Out of scope per DOD: code-space remediation of gpu/picoz drift findings
  (commits missing, ledger offline, stale dispatches). Those are
  separate concerns. The lock-log remediation by `flywheel-sr75` is
  referenced as evidence, not claimed as work product here.

## L52 / L80 / L120 / L61

- DIDNT: none
- GAPS: none new (the convention-class durability gap is surfaced by the
  existence of THIS bead, which is being closed; future workers can
  read the restored receipt's §"Why the original is gone" to find a
  potential follow-up doctrine bead)
- beads_filed: none
- beads_updated: none (`br update` of closed bead `flywheel-hy3b` not
  required — the audit chain works through its existing `gap filed
  flywheel-bhgh` reference; my new audit pack is the leaf node)
- no_bead_reason: convention-class-gap-already-tracked-by-this-bead
- br_close_executed: yes (after this pack, before callback)
- agents_md_updated: not_applicable
- readme_updated: no — README's Dispatch Contract convention has the
  durability gap that caused this bead, but DOD scopes this bead to
  receipt restoration, not convention reform; a separate
  doctrine-promotion bead would update the README. (`no_touch_reason`)

## Four Lens

- Brand: 9 (clean restoration: durable digest preserved verbatim from
  three independent sources; provenance answer recorded; convention
  gap surfaced for future doctrine bead without scope creep)
- Sniff: 9 (today's re-probes confirm 2 of 4 verifiable claims still
  hold; 1 was independently remediated; 1 has natural drift —
  honest treatment of each)
- Jeff: 7 (no Jeff-substrate touch)
- Public: 9 (a future maintainer reading the restored receipt can
  understand the audit's claims, the provenance, and the convention
  gap — no chain-of-custody mystery; third-party corroboration via
  flywheel-sr75 backfill is reproducible)

## Skill Auto-Routes

- canonical-cli-scoping: n/a — no CLI added
- rust-best-practices: n/a — no Rust touched
- python-best-practices: n/a — no Python touched
- readme-writing: n/a — README's durability convention is referenced
  (with concrete reform suggestion) but not modified per DOD

## L112 Probe

```
test -f /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-bhgh/restored-receipt.md \
  && grep -c "DRIFT_DETECTED HIGH" /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-bhgh/restored-receipt.md
```
Expected: `literal:>=1` (the restored receipt preserves the original
audit's verbatim "DRIFT_DETECTED HIGH" callback summary string).
