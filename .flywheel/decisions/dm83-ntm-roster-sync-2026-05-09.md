# Decision: NTM upstream session metadata sync (B08)

Bead: `flywheel-dm83`
Date: 2026-05-09
Status: **DECIDED — AVOID full replacement; ADOPT-LITE complementary**
Plan source:
`/Users/josh/Developer/flywheel/.flywheel/PLANS/team-roster-2026-05-01.md`
Sister: `flywheel-cgjo` (B06 borrow protocol, CLOSED 2026-05-09)
Probe evidence: `.flywheel/audit/flywheel-dm83/ntm-probe-evidence.txt`

## Verdict

**AVOID** replacing `~/.local/state/flywheel/team-roster.jsonl` with NTM
upstream session metadata as the borrowing source of truth.
**ADOPT-LITE** NTM `activity <session> --json` as the complementary
live-pane oracle (this is already how the borrow dispatcher computes
`pane_state`; no migration needed).
**EXTEND** is **deferred** until Jeffrey Emanuel adds the missing
semantic fields to NTM upstream — track via the existing
`jeffrey-comment-watchtower` (bead `flywheel-d6tz0`); do **not**
file a new Jeffrey issue today.

## Surface comparison

| Field needed by team-roster | team-roster.jsonl | ntm sessions | ntm activity | ntm checkpoint | ntm agents |
|---|---|---|---|---|---|
| `session` | yes | yes | yes | yes | n/a |
| `repo_path` / `working_dir` | yes | yes | no | yes | n/a |
| `domain` | yes | no | no | no | no |
| `client` | yes | no | no | no | no |
| `tier` (active_*/client_*/protected_*) | yes | no | no | no | no |
| `orchestrator{pane,kind,model,role}` | yes | partial (pane+kind) | partial (pane+kind) | yes (pane+kind) | n/a |
| `worker_panes[] / workers[]` | yes | yes | yes | yes | n/a |
| `current_mission` | yes | no | no | no | no |
| `agent_mail_identity` / `fleet_mail_identity` | yes | no | no | no | no |
| `loop_active` / `loop_tier` | yes | no | no | no | no |
| `available_for_borrow` | yes | **no** | no | no | no |
| `max_borrow_workers` | yes | **no** | no | no | no |
| `borrow_policy_override` | yes | **no** | no | no | no |
| Append-only audit semantics | yes (one row per `session_active`) | no (state-shot, overwrites) | no (live snapshot) | no (named overwrites) | n/a |
| Per-pane real-time state (THINKING/WAITING/...) | no | no | **yes** | scrollback only | n/a |

`ntm sessions list --json` returns `count:0` on this fleet (the surface
is opt-in via `ntm sessions save`, not auto-populated). NTM checkpoint
captures full session snapshots but is checkpoint-style (overwrites
named entries), not append-only audit-grade. NTM agents is a
capability *catalog*, not a session-state surface.

## Why AVOID full replacement

1. **Borrowing semantics absent upstream.** `available_for_borrow`,
   `max_borrow_workers`, and `borrow_policy_override` are flywheel-
   specific fields. Replacing the source of truth would silently
   drop the borrowing protocol's substrate (B06 / `flywheel-cgjo`).
2. **Append-only audit lost.** `team-roster.jsonl` is
   one-row-per-event. NTM `sessions save` and `checkpoint save`
   are state-shot files that overwrite. Migrating would convert
   "what was true at T=now" into "what is true now," losing the
   reconstructable timeline that L80 closed-bead-audit-mining
   depends on.
3. **Mission anchor / tier / client metadata absent upstream.** No
   NTM surface carries `current_mission`, `tier`, `client`, or
   `domain`. These are load-bearing for routing decisions
   (cross-orch dispatch policy, doctrine-tier selection,
   fleet-roster sync between client and internal sessions).
4. **Joshua-confirmed pane lock-in not first-class upstream.**
   Identity locking via `~/.local/state/flywheel/orch-worker-identity/`
   is a flywheel substrate; NTM has no equivalent
   pane-identity-lock primitive today.

## Why ADOPT-LITE for activity

NTM `activity <session> --json` is **already** the live-pane oracle:

- `flywheel-cgjo` borrow dispatcher consumes
  `agents[].state` and `agents[].agent_type` to gate
  `target_pane_dead`.
- `flywheel-d6tz0` jeffrey-comment-watchtower runs alongside but
  not on top of `ntm activity`.
- The complementary roles are clean: NTM owns *now*, team-roster
  owns *append-only event-log + policy*.

No migration is needed. The status quo is the right shape.

## When to revisit (EXTEND path)

Re-evaluate this decision if Jeffrey ships any of:

1. A `borrow_*` field family on `ntm activity` / `ntm sessions`
   (would make ADOPT viable for borrowing semantics).
2. Append-only `ntm history` or `ntm audit-log` covering
   session-active events (would make ADOPT viable for audit
   semantics).
3. `ntm coordinator` mission-anchor / tier / client metadata
   (would make ADOPT viable for routing decisions).

**Tracking surface:** `flywheel-d6tz0`'s
`jeffrey-comment-watchtower` will fire `JEFFREY_COMMENT_NEW`
within 15 min if Jeffrey comments on any NTM issue introducing
these fields, AND the daily `jeff-intel-digest-actionable.sh`
(bead `flywheel-1lpv.3`) will surface any merged commit that
mutates the ntm sources/sessions schema. Either fires this
decision back into `revisit_required` state.

## Backwards-compatible sync path (defined for forward-readiness)

When EXTEND becomes viable, the migration shape is:

```text
Phase 1 (read-side dual-source): roster-register.sh writes BOTH
  ~/.local/state/flywheel/team-roster.jsonl AND `ntm sessions save`,
  with a SHA cross-reference field linking the two surfaces.

Phase 2 (consumer dual-source): borrow dispatcher and any other
  consumer reads BOTH surfaces; mismatches log fuckup-row class
  `roster-substrate-divergence`.

Phase 3 (cut-over after N days clean parity): consumers read NTM
  only; team-roster.jsonl is preserved as historical archive but
  no longer written.

Phase 4 (sunset): rotate team-roster.jsonl to read-only after
  M months of clean cut-over.
```

Each phase is its own future bead; **none filed today** per
acceptance #5 ("File implementation follow-ups only after a
concrete upstream surface exists").

## No-bead-reason for follow-ups

Acceptance #5 explicitly says: file implementation follow-ups
**only after a concrete upstream surface exists**. NTM does not
expose `available_for_borrow / max_borrow_workers /
borrow_policy_override / tier / client / current_mission`
upstream today. Therefore: **no implementation beads filed this
turn**. Re-evaluate when one of the EXTEND triggers fires.

`L52 receipt: beads_filed=none beads_updated=flywheel-dm83
no_bead_reason=acceptance_5_explicitly_blocks_implementation_followups_until_concrete_upstream_surface_exists`.

## Three-Q

- **VALIDATED:** live `ntm sessions list/show/activity/checkpoint/agents`
  probes captured at
  `.flywheel/audit/flywheel-dm83/ntm-probe-evidence.txt` 2026-05-09T14:13Z.
- **DOCUMENTED:** this decision record (self-contained, cites plan
  + probe evidence + sister beads).
- **SURFACED:** decision record landed at
  `.flywheel/decisions/dm83-ntm-roster-sync-2026-05-09.md`;
  no beads updated except this one (closed with
  no-bead-reason).

## Out-of-scope (this bead)

- Replacing team-roster.jsonl before NTM has equivalent confirmed
  semantics (acceptance §"Out of scope").
- Filing a Jeffrey issue today asking for the missing fields
  (would violate the "NEVER auto-file Jeff issues without research"
  meta-rule and acceptance #5).
- Building the dual-source sync code (Phase 1 of the migration
  shape above) — that lives in a future bead once an EXTEND
  trigger fires.
