---
name: blocker-discipline
type: doctrine
created: 2026-05-10
status: active
authority: skillos-1-blocker-closure-with-live-probe-evidence-2026-05-10T20:12Z + flywheel-1-fold-in-2026-05-10T20:20Z
ratified: 2026-05-10T20:30Z (P3-trivial cross-orch via cross-orch-anti-divergence-v1.0.0)
cluster: substrate-hygiene-doctrine-cluster
sisters:
  - repo-hygiene-operational-protocol.md
  - git-repo-discipline.md
  - git-stash-discipline.md
---

# Blocker Discipline (Fleet-Wide)

## Substrate-hygiene doctrine cluster

This doctrine is part of the **substrate-hygiene doctrine cluster** alongside
`repo-hygiene-operational-protocol.md`, `git-repo-discipline.md`, and
`git-stash-discipline.md`. All four share a Meadows-lens diagnosis:
recursive-self-validation failure modes — substrate that nobody verifies
accumulates as silent debt.

- **repo-hygiene-operational-protocol.md** addresses: repo accretion/bloat
  before it becomes a 70k-file cleanup event
- **git-repo-discipline.md** addresses: dirty working trees as unresolved
  decisions
- **git-stash-discipline.md** addresses: stash accumulation as durable storage (paradigm: stash is 24h scratch, not parking lot)
- **blocker-discipline.md** (this doctrine): addresses blocker accumulation as unverified claims (paradigm: blockers are claims, not facts)

Both rely on per-tick orch verification + worker-time discipline + named trauma classes. When you read one, read the other — failure modes overlap.

## Paradigm — blockers are claims, not facts

A blocker is a **CLAIM that conditions prevent forward motion.** Claims must be verified — repeatedly, with live probes, against current state. The Meadows-lens leverage point at play: **#6 strong information flow.** When information flow is weak (a blocker references a stale string field that nobody re-evaluates), the system continues believing a claim that is no longer true.

**Trauma surfaced today (skillos:1 dogfood 2026-05-10T20:08Z):** a blocker referenced `2026-05-09T19:48:40Z plan response handoff` as the unblock action. The handoff path was a string field. Nobody verified the path existed at the referenced timestamp. 24+ hours unverified. When Joshua-direct intervention forced a live probe, conditions had cleared — the blocker was already false.

The fix is not "better blocker hygiene." It's **structurally surface every blocker for re-evaluation**, with verifiable AC and verified-path discipline.

## Worker responsibilities

When filing a blocker, MUST include:

1. **`last_verified_at`** — ISO timestamp of when the blocker conditions were last empirically probed. Initial value: filing timestamp. Updated each time the blocker is re-checked.

2. **`verification_path`** — a runnable command or path that, when re-evaluated, returns true if the blocker is still real. Examples:
   - `df -h /Volumes/foo | awk 'NR==2 {print $5}' | tr -d '%' | awk '$1>=90 {exit 1}'`
   - `[[ -f /Users/josh/.local/state/foo/heartbeat.json ]]`
   - `bash .flywheel/scripts/storage-headroom-watcher.sh doctor --json | jq -e '.score < 0.8'`
   - The point: a deterministic predicate that can be re-run from clean state.

3. **`acceptance_condition`** (AC) — a runnable command/predicate that returns true when the blocker is RESOLVED. Inverse-shaped from `verification_path`. When AC passes, blocker auto-closes with live-probe evidence appended.

4. **`ac_check_interval_ticks`** (optional) — per-blocker override for AC re-evaluation cadence. Default: 4 (every 4 ticks). Suggest higher for slow-clearing classes (storage-pressure ~days), lower for fast-clearing (FD-pressure ~hours).

5. **No "I'll verify later" posture.** If you can't write a verification path right now, DON'T FILE THE BLOCKER. File a `needs-verification-path` task instead.

## Orch responsibilities

Per-tick blocker audit:

0. **Beads-to-blocker bridge.** Before accepting the blocked queue as true
   state, sync every `br status=blocked` row into
   `.flywheel/state/blockers/<bead-id>.json` with
   `.flywheel/scripts/bead-blocker-sync.py`. A blocked Bead without a blocker
   JSON file is itself a blocker-discipline failure, because it cannot be
   rechecked, auto-closed, or escalated by the tick chain.

1. **Stale-blocker auto-escalation.** For each open blocker:
   - Read `last_verified_at`
   - If >24h old: AUTO-ESCALATE
     - Surface in tick output with WARN
     - Send Agent Mail letter to Joshua naming the blocker + stale duration
     - Stale-blocker IS the silent-defer trauma class

2. **AC re-evaluation cadence.** Every Nth tick (where N defaults to 4 or per-blocker `ac_check_interval_ticks` override):
   - Run the blocker's `acceptance_condition` command
   - If AC passes: auto-close blocker with live-probe evidence
   - If AC fails Nth time consecutively: escalate to Joshua

3. **Path verification on every plan-response reference.** When a blocker body references a path-shaped string (matches `[/~][a-zA-Z0-9_./-]+`), orch tick MUST verify the path exists. If the path doesn't exist or the timestamp doesn't match: flag as `string-field-not-verified-path` trauma class violation; auto-escalate.

4. **Live-probe evidence capture.** When AC passes and blocker auto-closes, the live probe's stdout MUST be appended to `escalations.jsonl` (or repo-equivalent ledger). Audit trail is mandatory: future-self should be able to verify why the blocker closed without re-running the probe.

5. **Per-tick blocker audit signal.** Tick output includes:
   - Total open blockers (N)
   - Stale blockers (last_verified_at > 24h)
   - Escalated blockers (AC failed Nth consecutive)
   - Auto-closed blockers this tick (with live-probe evidence)

## Named trauma classes

### `silent-defer` (skillos-credit, 2026-05-10T20:08Z)

**Symptom:** blocker referenced unverified condition for 24h+; orch never re-probed; Joshua intervention required to surface staleness.

**Root cause:** delay 9 (unbounded blocker recheck) + balancing loop 8 (weak signal propagation) interact to produce information stagnation. The orch tick reads the blocker's STRING field and treats it as truth without verification.

**Fix:** mandatory `last_verified_at` field + 24h auto-escalate. Worker-time + orch-time discipline.

**Detection:** orch tick scans open blockers for `last_verified_at` field; flags any older than 24h.

### `string-field-not-verified-path` (skillos-credit, 2026-05-10T20:08Z)

**Symptom:** plan-response references a path/artifact in a string field but orch never verified the path resolves; blocker stays open referencing nonexistent or stale path.

**Root cause:** absence of mechanical path-verification in orch tick.

**Fix:** orch tick path-resolves every path-shaped string in blocker bodies; flags any unresolvable.

**Detection:** orch tick regex-extracts paths from blocker body, runs `[[ -e <path> ]]` per match, flags failures.

## Live-probe evidence shape

When AC passes and blocker auto-closes, append to `escalations.jsonl`:

```json
{
  "ts": "<UTC>",
  "event": "blocker_auto_closed",
  "blocker_id": "<id>",
  "ac_command": "<exact command run>",
  "ac_stdout": "<captured output>",
  "ac_exit_code": 0,
  "live_probe_at": "<UTC>",
  "previous_last_verified_at": "<UTC>",
  "delta_seconds": "<int>",
  "auto_closer": "orch:<pane>"
}
```

Manual closure (worker-initiated, not AC-triggered) appends similarly with `"event": "blocker_manually_closed"`.

## Pre-migration gate (Rust P3)

Before substrate-rewrite proposals (substrate-rewrite-rust-v1 P3 at T+144h), all coordinating flywheel-installed repos must satisfy:

- Zero stale blockers (`last_verified_at` <24h for ALL open blockers)
- Zero `silent-defer` trauma class violations
- Zero `string-field-not-verified-path` violations

This is gate-condition stricter than "blocker count under N" because even one silent-defer can hide load-bearing failure mode.

## Cross-references

- `.flywheel/doctrine/git-stash-discipline.md` — sister doctrine in substrate-hygiene cluster
- `~/.claude/skills/git-stash-janitor/SKILL.md` — adjacent triage flow for stash accumulation
- skillos memory `feedback_no_silent_defer_flywheel_substrate_memory_rule` — substrate-discovery source
- L57 (loop-state-marker-not-driver) — adjacent class
- Cross-orch P1 ratification 2026-05-10T20:30Z (this doctrine)

## Implementation status

Doctrine drafted; awaits implementation pass to wire orch-tick blocker audit. Filed as separate workstream (parallel to flywheel-pynxp git-stash impl).


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-17 — secret emission discipline:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-17-secret-emission-discipline.md` for the canonical pattern.
- **MP-29 — production safety guardrails:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-29-production-safety-guardrails.md` for the canonical pattern.
- **MP-30 — human-gated invasiveness:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-30-human-gated-invasiveness.md` for the canonical pattern.
