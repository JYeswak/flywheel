# Cross-session worker borrowing protocol (B06)

Owns: bead `flywheel-cgjo`. Plan source:
`.flywheel/PLANS/team-roster-2026-05-01.md` lines 233+ ("a dispatch
protocol is a separate bead — bd-cross-session-worker-borrow").

This document is **self-contained**: it can be read without the plan
to understand the full protocol surface. The dry-run dispatcher
that implements the surface is
`.flywheel/scripts/cross-session-worker-borrow.sh` (canonical-cli-scoping
triad). The actual borrowing implementation is sibling bead B05's
follow-up — this bead defines the protocol + test surface, not
the live borrow execution.

## Goal

Turn the team-roster fields `available_for_borrow` and
`max_borrow_workers` into a safe, idempotent dispatch protocol that
the flywheel orchestrator can use to borrow an idle worker from
another session for one task without violating session identity,
ownership, or pulse-freshness invariants.

## Vocabulary

| Term | Meaning |
|---|---|
| Requestor | The orchestrator pane that needs a borrowed worker (`flywheel:1` typically). |
| Target session | The session that owns the candidate worker (e.g. `mobile-eats`, `picoz`). |
| Target pane | The worker pane in the target session (e.g. `mobile-eats:0.3`). |
| Borrow request | The signed packet asking the target's orchestrator to lend the worker. |
| Approval | Target orchestrator's positive response with TTL and scope. |
| Release | Mutual handshake closing the borrow at task complete or expiry. |
| Reclaim | Unilateral target-side cancel (worker death, mission change, tier upgrade). |

## State machine

```
                         ┌──────────────┐
                         │   requested  │
                         └──────┬───────┘
                                │
        ┌──────────────┬────────┼────────┬───────────────┐
        ▼              ▼        ▼        ▼               ▼
    refused      timed_out   approved   declined    reclaimed_pre_approve
                                │
                                ▼
                            ┌────────┐
                            │ in_use │
                            └───┬────┘
                                │
            ┌───────────────────┼────────────────────┐
            ▼                   ▼                    ▼
        released          reclaimed_in_use       worker_died
```

Terminal states: `refused | timed_out | declined | reclaimed_pre_approve | released | reclaimed_in_use | worker_died`.
Non-terminal: `requested | approved | in_use`.

Transitions are append-only ledger rows; the most recent row wins
for a given `borrow_id`.

## Idempotency

`borrow_id = sha256("borrow:" + requestor_session + ":" +
target_session + ":" + target_pane + ":" + task_sha256 + ":" +
window_minutes)` truncated to 16 chars.

Same input within `window_minutes` (default 60) yields the same
`borrow_id`. The dispatcher refuses to create a second
`requested` row if a non-terminal row exists for the same
`borrow_id`.

## Eligibility rules (target session)

A target session is eligible iff ALL of:

1. **Fresh pulse**: `~/.local/state/flywheel/team-roster.jsonl`
   most-recent row for the session has `ts` within
   `pulse_max_age_seconds` (default 300s = 5min).
2. **Available for borrow**: that row's `available_for_borrow == true`
   AND `max_borrow_workers > 0` AND
   `currently_borrowed_count < max_borrow_workers`.
3. **Live target pane**: `ntm --robot-activity=<target_session>
   --activity-type=codex,claude` includes the target pane with
   `state ∉ {DEAD, UNKNOWN}` and `pane_pid` resolvable.
4. **Not protected / not client**: target session's roster `tier`
   does NOT match `^client_` and is not in
   `{protected_session_a, protected_session_b}` UNLESS the
   roster row carries `borrow_policy_override == "explicit_lend_ok"`.

Failure of any rule → `state=refused` with `reason` naming the
failed rule.

## Callback routing

A borrowed worker MUST send its DONE callback to the **requesting
orchestrator pane** (e.g. `flywheel:1`), not to its native
session's orchestrator. The dispatch packet built by the
dispatcher includes:

```text
callback_session=<requestor_session>
callback_pane=<requestor_pane>
borrow_id=<id>
borrow_origin_session=<target_session>
borrow_origin_pane=<target_pane>
identity_name=<worker's locked identity name>
```

The worker's identity name is preserved unchanged from the target
session's identity registry — the borrow does not rename the
worker. After release, future dispatches to that pane resume
routing to its native orchestrator.

## Agent Mail + NTM coordination records

Every state transition writes one row to
`~/.local/state/flywheel/cross-session-worker-borrow.jsonl`
(schema_version `cross-session-worker-borrow/v1`):

```json
{
  "schema_version": "cross-session-worker-borrow/v1",
  "ts": "<iso>",
  "borrow_id": "<sha256-short>",
  "state": "requested|approved|in_use|released|refused|...",
  "requestor_session": "<session>",
  "requestor_pane": <int>,
  "target_session": "<session>",
  "target_pane": <int>,
  "task_id": "<task-id>",
  "task_sha256": "<sha256>",
  "ttl_minutes": <int>,
  "reason": "<short>",
  "policy_check": {
    "pulse_age_seconds": <int>,
    "available_for_borrow": <bool>,
    "max_borrow_workers": <int>,
    "currently_borrowed_count": <int>,
    "pane_state": "<state>",
    "tier": "<tier>"
  }
}
```

In addition, the requestor sends a `BORROW_REQUEST` Agent Mail
message to the target's orchestrator at request time and a
`BORROW_RELEASE` at release time. Both messages carry the same
`borrow_id`.

## Refusal reasons (canonical strings)

- `pulse_stale` — target session pulse > pulse_max_age_seconds
- `not_available_for_borrow` — `available_for_borrow == false`
- `at_max_borrow_workers` — already lending
  `max_borrow_workers` workers
- `target_pane_dead` — pane state `DEAD` or `UNKNOWN`
- `protected_session_no_override` — tier matched protected and no
  `borrow_policy_override`
- `client_tier_no_override` — tier matched `client_` and no
  override
- `idempotency_collision` — duplicate request within window
- `worker_death_mid_borrow` — target pane died after `approved`
  but before `released`

## Anti-patterns (forbidden)

- Borrowing without the eligibility check (blind borrow).
- Mutating the borrowed worker's identity (CAAM swap, identity
  rename) for the duration of the borrow.
- Routing the DONE callback to the target session's orchestrator
  instead of the requestor.
- Skipping the `BORROW_RELEASE` step on task complete (leaks
  ownership).
- Borrowing across sessions whose roster tiers are both `client_*`
  (cross-client work without explicit policy approval).

## Test surface

The dispatcher's fixture-mode tests cover:

| # | Scenario | Expected |
|---|---|---|
| T1 | Duplicate request within window | second call returns same `borrow_id`, state remains `requested` (idempotent) |
| T2 | Stale pulse (target ts > 300s old) | state=`refused` reason=`pulse_stale` |
| T3 | Protected/client tier with no override | state=`refused` reason=`client_tier_no_override` or `protected_session_no_override` |
| T4 | Worker death mid-borrow | state=`worker_death_mid_borrow` (terminal) |
| T5 | Release-on-complete | full lifecycle: requested → approved → in_use → released |

Fixtures live at `.flywheel/audit/flywheel-cgjo/fixtures/*.jsonl`
(roster-row + pane-state input combinations) and the dispatcher's
`--from-fixture <path>` flag drives them.

## Surfaced state

Daily report consumes the borrow ledger via:

```bash
jq -s 'group_by(.state) | map({state: .[0].state, count: length})' \
  ~/.local/state/flywheel/cross-session-worker-borrow.jsonl
```

A future bead can wire this into `daily-report.py` as a "Borrowing
Activity" section. This bead's `surfaced=yes` is satisfied by the
ledger existing, the schema being machine-readable, and the
dispatcher's `--list --json` reporting the same shape.

## Out of scope (this bead)

- The actual live borrow execution flow (B05 follow-up).
- Multi-hop borrowing (A borrows from B, then C borrows from A's
  borrowed worker).
- Dynamic tier-policy negotiation (policies are static via
  `borrow_policy_override` field).
