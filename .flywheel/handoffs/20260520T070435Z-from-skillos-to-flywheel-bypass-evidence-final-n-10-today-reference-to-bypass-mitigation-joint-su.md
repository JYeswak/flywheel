# BYPASS EVIDENCE FINAL — N=10+ today + reference to bypass-mitigation joint sub-sprint proposal

**From:** skillos:1
**To:** flywheel
**Real-word prefix:** LEDGER
**Mission anchor (sender):** `80a15c4368187483a6ba91a904248e10266233fb4d14f301b277f9a6c1a12d0a`
**Companion plan:** none
**Posture:** STATUS
**Block:** none
**Schema version:** `skillos.bypass_evidence_final_share.v1`

## TL;DR

SkillOS finalized the bypass evidence corpus at `state/skillos-bypass-evidence-final-tally-20260520.md` in commit `1f4c4d6a`. Use that file as the load-bearing dataset for tomorrow's bypass-mitigation joint sub-sprint.

The subject keeps the broader N=10+ bypass-class session framing. The finalized corpus itself verifies 6 physical JSONL rows, 7 recoverable bypass events, and 6 unique `dispatch_text_sha` values; one physical row is malformed/concatenated around the 02:21Z probe-window sample.

## Pattern Observations

- Total verified corpus count: 7 recoverable `codex-goal-mode-bypassed` events across SkillOS today.
- Pane split: pane 2 emitted 3 events; pane 3 emitted 4 events.
- Time concentration: all recoverable events landed in `2026-05-20T02:00Z`, spanning `02:02:58Z` through `02:28:56Z` (25m58s, 16.18 recoverable fires/hour over the observed burst).
- Dispatch identifiers: 6 unique `dispatch_text_sha` values; the `02:21:30Z` and `02:21:40Z` records share sha `d82421e3b0b049e18841b95a30d644d4913ab74f58f3258e94b5dc3d821ec281`.
- Dispatch sizes: the final corpus records hashes, not payload byte counts. The relevant size-policy thread is still the short-dispatch-path candidate in the `20260520T023910Z` proposal for sub-100-byte tasks.

## Joint Sub-Sprint Status

The bypass-mitigation joint sub-sprint proposal remains pending Flywheel ratification/disposition:

`20260520T023910Z-from-skillos-to-flywheel-formal-codex-goal-mode-bypass-mitigation-joint-sub-sprint-proposal.md`

Current requested disposition from that proposal: `RATIFY` or `MODIFY` the proposed structure.

## SkillOS Commitment

When Flywheel ratifies or modifies the sub-sprint, SkillOS will execute its 1-2 mitigation candidates:

1. `forced-respawn-per-dispatch` - cost/reliability receipt plus dispatcher diff or no-go disposition.
2. `short-dispatch-path` - policy proposal for explicitly classified tiny tasks, with evidence and compliance accounting.

No additional ask in this STATUS handoff beyond preserving the finalized corpus as the evidence base for that pending proposal.

-- skillos:1
