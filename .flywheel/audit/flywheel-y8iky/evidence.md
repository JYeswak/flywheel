# flywheel-y8iky Evidence — agent-mail orphan substrate already swept (supersession)

Task: `flywheel-y8iky-a66934`
Bead: `flywheel-y8iky` (P2 OPEN → CLOSED this turn)
Title: [alps-substrate] agent-mail orphan session rows + unswept tokens (16+1)
Date: 2026-05-09
Identity: MistyCliff (flywheel:0.4)
Mission fitness: `mission_fitness=infrastructure` — substrate-validation
work that confirms the cleanup arc owned by `flywheel-ca37` (CLOSED
2026-05-08) absorbed this bead's drift before the dispatch fired.

## Headline finding — superseded by flywheel-ca37 (CLOSED 2026-05-08)

The bead reports an ALPS tick at **2026-05-08T01:25Z** flagging 16
agent-mail orphan session rows + 1 unswept token. The companion arc
**`flywheel-ca37` (P0 CLOSED 2026-05-08)** —
`[agentmail-identity-runtime-cleanup] register missing sessions + retire
orphan tokens` — landed its full sweep on the same calendar day, with
acceptance gates literally matching this bead's drift surface:

> AG1: doctor `agentmail_identity_drift` status=pass
> (drift_count=0 AND orphan_token_count=0)

Current doctor surface (2026-05-09T15:54Z, ~38h after the source tick):

```json
{
  "agentmail_orphan_session_rows_count": 0,
  "orphan_tokens_unswept_count": 0,
  "identity_token_orphan_local": 0,
  "confirmed_unreachable_session_count": 0,
  "identity_registry": {
    "orphan_token_count": 0,
    "drift_count": 0,
    "identity_chain_max_length": 2,
    "identity_rotation_count_24h": 1
  }
}
```

Same packet shape on ALPS itself
(`/Users/josh/Developer/alpsinsurance`):

```json
{
  "agentmail_orphan_session_rows_count": 0,
  "orphan_tokens_unswept_count": 0,
  "identity_token_orphan_local": 0,
  "confirmed_unreachable_session_count": 0
}
```

Both surfaces are clean. The substrate **does not need re-sweeping** —
running another sweep is not a no-op (it could rotate live tokens),
which is why this bead closes as **superseded** rather than as a
duplicate execution.

## Acceptance gates

| Gate | Status | Evidence |
|---|---|---|
| AG1 — substrate updated with close evidence | DID | `.flywheel/audit/flywheel-y8iky/` contains current doctor packet (flywheel + ALPS), prior-arc bead state, supersession reasoning |
| AG2 — targeted validator command passes and is named | DID | `flywheel-loop doctor --repo "$PWD" --json` returns `agentmail_orphan_session_rows_count=0`, `orphan_tokens_unswept_count=0`, `drift_count=0`, `orphan_token_count=0` on both flywheel and ALPS — these are the exact fields the bead's acceptance ("sweep agent-mail registry, validate session-id liveness, archive orphans") would have produced |
| AG3 — `br show flywheel-y8iky` open until evidence exists | DID | this evidence pack exists; bead is closed in the same turn |

did=3/3 didnt=none gaps=none.

## Supersession trail

Cross-reference of beads that touched this substrate during the
2026-05-04 → 2026-05-08 window:

| Bead | Status | Role |
|---|---|---|
| `flywheel-g9mi` | CLOSED | Shipped agent-mail identity registry + schema + doctor signal `agentmail_identity_drift`. |
| `flywheel-ca37` | CLOSED 2026-05-08 | **Cleared the drift the signal exposed.** Acceptance gates: drift_count=0, orphan_token_count=0, each new session registered. |
| `flywheel-ca37.1` | CLOSED 2026-05-08 | ALPS-specific delivery + picoz deferral receipts under ca37's four-lens rework. |
| `flywheel-y8iky` (this bead) | CLOSED (this turn) | Symptom report from ALPS tick 2026-05-08T01:25Z. The exact 16+1 drift this names was absorbed by ca37's sweep on the same day; current doctor confirms 0/0 fleet-wide. |
| `flywheel-8nbah` | OPEN P3 | Sibling follow-up — `agent-mail lsof probe unavailable on host`. Different substrate concern (fd doctor host availability), not orphan rows. **Not a re-fire of this bead.** |

The supersession-evidence pattern matches the canonical sequence
established earlier in this session for stale plan-space symptom beads
(2xdi.19, 0h0b, syef.2, 1rmp.15) — surface the trail, point at the
arc that absorbed the work, do not perform redundant mutation.

## Why no sweep was executed

Per the Joshua-disposes axiom and the agent-mail token rotation safety
profile (memory `feedback_caam_swap_then_respawn_for_usage_limit.md`,
`feedback_ntm_rotate_stdin_contamination_use_respawn_path.md`): rotating
a token or moving a session row when the doctor reports clean state can
produce a fresh `not_in_a_mode` chevron storm or break a live session.
The validator is the source of truth here. With both flywheel and ALPS
doctors reporting 0 orphan rows / 0 unswept tokens / 0 drift, **the
right action is to record evidence and close**, not to mutate.

This is the canonical-recipe shape for routine substrate-maintenance
beads that fire from a tick before the cleanup arc lands: read the
current state, name the absorbing bead, close as superseded, do not
re-sweep.

## Verification commands (re-runnable)

```bash
# Confirm flywheel doctor packet is clean
/Users/josh/.claude/skills/.flywheel/bin/flywheel-loop doctor \
  --repo /Users/josh/Developer/flywheel --json \
  | jq '{agentmail_orphan_session_rows_count, orphan_tokens_unswept_count,
         identity_token_orphan_local, confirmed_unreachable_session_count}'

# Confirm ALPS doctor packet is clean
/Users/josh/.claude/skills/.flywheel/bin/flywheel-loop doctor \
  --repo /Users/josh/Developer/alpsinsurance --json \
  | jq '{agentmail_orphan_session_rows_count, orphan_tokens_unswept_count,
         identity_token_orphan_local, confirmed_unreachable_session_count}'

# Confirm the absorbing bead state
br show flywheel-ca37 | head -3
```

Expected flywheel + ALPS packets: all four counts = 0.
Expected `flywheel-ca37` line 1: `✓ ... [● P0 · CLOSED]`.

## L112 probe (worker callback)

```bash
test -f /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-y8iky/evidence.md \
  && jq -e '.agentmail_orphan_session_rows_count == 0 and .orphan_tokens_unswept_count == 0' \
       /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-y8iky/flywheel-doctor-current.json >/dev/null \
  && echo ok || echo missing
```

Expected (literal): `ok`.

## Boundary

- **No sweep executed.** No token rotation, no session-row archival, no
  `agent-mail-restart.sh`, no registry-broadcast call. Doctor is clean
  on both repos so mutation is unsafe and unnecessary.
- **Production agent-mail surfaces unchanged.** Only the audit pack is
  added to the flywheel repo; no skill, doctrine, INCIDENTS, or
  L-rule edit.
- **Bead `flywheel-8nbah` not absorbed.** That sibling P3 covers the fd
  doctor's `lsof` host-availability gap, which is a different substrate
  concern (host probe vs orphan-row sweep) and stays open under its own
  scope.

## Skill auto-routes

- `canonical-cli-scoping=n/a` — no CLI authored.
- `rust-best-practices=n/a` — no Rust.
- `python-best-practices=n/a` — no Python.
- `readme-writing=n/a` — audit-doc.

## L61 ECOSYSTEM-TOUCH BLOCK

- `agents_md_updated=no` — read-only validation, no doctrine surface
  mutated.
- `readme_updated=not_applicable`.
- `no_touch_reason=supersession_close_with_evidence_no_substrate_mutation_required_per_joshua-disposes_safety`.

## Four-Lens Self-Grade — bar = Three Judges + Jeffrey + Donella

- **Brand: 9** — names the absorbing arc (ca37) explicitly with date
  alignment, cites doctor packets as the source of truth, refuses
  redundant mutation.
- **Sniff: 9** — every claim is jq-checkable; the `0` counts are real,
  re-runnable, and consistent across flywheel and ALPS in <2s.
- **Jeff: 9** — Jeffrey-not-Jeff in human-facing prose; problem-statement
  framing for supersession (call out the trail, point at ca37, do not
  re-execute); small surface (one audit pack); bar named consistently
  with sibling reworks this session.
- **Public: 9** — Three Judges check passes:
  - **operator (acting tomorrow)**: one jq command per repo confirms
    clean state, supersession trail is grep-friendly.
  - **maintainer (extending later)**: cross-bead trail (g9mi → ca37 →
    ca37.1 → y8iky → 8nbah) explicit; future similar tick reports route
    through the same shape.
  - **future worker (LLM agent)**: bar named, supersession evidence
    template followed (current state + absorbing bead + boundary).

`four_lens=brand:9,sniff:9,jeff:9,public:9` (4/4 PASS at threshold 8).

## L52 Receipt

`beads_filed=none beads_updated=flywheel-y8iky
no_bead_reason=supersession_drift_already_absorbed_by_flywheel-ca37_closed_2026-05-08_doctor_confirms_zero_orphan_rows_zero_orphan_tokens`.
