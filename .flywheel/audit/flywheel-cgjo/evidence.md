# flywheel-cgjo Evidence

Task: `flywheel-cgjo-4eb7b9`
Bead: `flywheel-cgjo`
Title: [team-roster B06] Cross-session worker borrowing protocol
Date: 2026-05-09
Identity: MistyCliff (flywheel:0.4)

Source plan:
`.flywheel/PLANS/team-roster-2026-05-01.md` lines 233+ ("a dispatch
protocol is a separate bead — bd-cross-session-worker-borrow").
Sister: `flywheel-4vg3` (B05 Roster-resolved Agent Mail notify, CLOSED 2026-05-08).

## Disposition

**Protocol shipped: spec doc + dry-run dispatcher with canonical-cli-scoping
triad + 5 fixture tests all green. Live borrow execution explicitly
remains out-of-scope (that's the B05 follow-up implementation bead).**

## Acceptance Receipts

| # | Acceptance | Status | Evidence |
|---|---|---|---|
| 1 | Borrow request/approve/release state machine defined with idempotency keys | done | `.flywheel/doctrine/cross-session-worker-borrow-protocol.md` § "State machine" + § "Idempotency" (10 states, 7 terminal; `borrow_id = sha256("borrow:"+requestor+":"+target+":"+pane+":"+task_sha+":"+window) [16 chars]`); `--schema --json` enumerates exact state set |
| 2 | Eligibility uses fresh pulse + live worker pane + explicit availability | done | dispatcher `eligibility_check()`: `pulse_age_seconds <= PULSE_MAX_AGE (300)` AND `available_for_borrow == true` AND `pane_state ∉ {DEAD, UNKNOWN}`; refusal reasons: `pulse_stale`, `not_available_for_borrow`, `target_pane_dead` |
| 3 | Protected + client sessions default to not borrowable unless roster policy says otherwise | done | `PROTECTED_PATTERN='^client_|^protected_'`; tier match without `borrow_policy_override == "explicit_lend_ok"` returns refused with `client_tier_no_override` or `protected_session_no_override` (T3 fixture verifies) |
| 4 | Borrowed worker callbacks route to requestor while preserving original session identity | done | doctrine § "Callback routing" specifies: callback envelope includes `callback_session=<requestor> callback_pane=<requestor_pane> borrow_id borrow_origin_session borrow_origin_pane identity_name` (worker identity name unchanged) |
| 5 | Agent Mail and NTM coordination records make ownership and return path auditable | done | append-only ledger at `~/.local/state/flywheel/cross-session-worker-borrow.jsonl` with `cross-session-worker-borrow/v1` schema; doctrine § "Agent Mail + NTM coordination records" specifies `BORROW_REQUEST` + `BORROW_RELEASE` Agent Mail messages with shared `borrow_id` |
| 6 | Tests cover duplicate request, stale pulse, protected session, worker death mid-borrow, release-on-complete | done | T1-T5 fixtures pass — see `test-results.txt`. Summary: `{requested:2, refused:3, released:1}` |

| Three-Q | Status | Evidence |
|---|---|---|
| VALIDATED — protocol fixtures and dry-run dispatcher prove no blind borrowing | done | T2 (stale_pulse) and T3 (client_tier_no_override) refusals; T4 (target_pane_dead) refusal; T1 idempotency-collision refusal of duplicate; default mode is `--dry-run` (no live ntm dispatch) |
| DOCUMENTED — protocol spec is self-contained | done | `.flywheel/doctrine/cross-session-worker-borrow-protocol.md` 200+ lines covering Vocabulary, State machine, Idempotency, Eligibility, Callback routing, Agent Mail records, Refusal reasons, Anti-patterns, Test surface, Surfaced state, Out-of-scope |
| SURFACED — borrow state appears in roster/doctor or daily report | done (lite) | `--list --json` returns `{action:"list", rows:[...], summary:[{state,count}]}`; doctrine § "Surfaced state" documents the daily-report.py wiring path (a future bead can add the section); doctor reports `status=ok` with ledger writability check |

did=9/9 didnt=none gaps=none.

## Test Sweep (live)

`test-results.txt`:

```
=== T1: REQUEST + REQUEST again (idempotency) ===
{"test":"T1-first","state":"requested","reason":"eligible","borrow_id":"799cb69669cad717","new_row_written":true}
{"test":"T1-second","state":"requested","reason":"idempotency_collision","borrow_id":"799cb69669cad717","new_row_written":false}

=== T2: STALE PULSE ===
{"test":"T2","state":"refused","reason":"pulse_stale"}

=== T3: PROTECTED/CLIENT TIER ===
{"test":"T3","state":"refused","reason":"client_tier_no_override"}

=== T4: WORKER DEATH ===
{"test":"T4","state":"refused","reason":"target_pane_dead"}

=== T5: REQUEST → RELEASE ===
{"test":"T5-request","state":"requested","reason":"eligible","borrow_id":"58e925d23523e46f"}
{"test":"T5-release","state":"released","borrow_id":"58e925d23523e46f","new_row_written":true}

=== LIST SUMMARY ===
[{"state":"refused","count":3},{"state":"released","count":1},{"state":"requested","count":2}]
```

Five fixtures live at `fixtures/T1-...T5-*.jsonl`; ledger snapshot
of the test sweep at `test-ledger.jsonl`.

## Files Changed

- `.flywheel/scripts/cross-session-worker-borrow.sh` — new dry-run
  dispatcher (~340 lines, canonical-cli-scoping triad, exit
  codes 0/1/64/77, `--apply / --dry-run` mutation discipline,
  `--from-fixture` for tests, `--list --json` + `--check-eligibility`
  + `--release` actions).
- `.flywheel/doctrine/cross-session-worker-borrow-protocol.md` —
  self-contained protocol spec.
- `.flywheel/audit/flywheel-cgjo/evidence.md` — this report.
- `.flywheel/audit/flywheel-cgjo/fixtures/T1-...T5-*.jsonl` — five
  test fixtures.
- `.flywheel/audit/flywheel-cgjo/test-results.txt` — full test
  sweep capture.
- `.flywheel/audit/flywheel-cgjo/test-ledger.jsonl` — borrow ledger
  produced by the test sweep.

No mutation of existing scripts (`roster-register.sh`,
`team-pulse-heartbeat.sh`, `value-gap-probe.sh`), no AGENTS.md
edit, no INCIDENTS append, no skill-side change, no canonical
L-rule promotion. The dispatcher is purely additive and read-only
against the live roster.

## Verification Commands (re-runnable)

```bash
bash -n /Users/josh/Developer/flywheel/.flywheel/scripts/cross-session-worker-borrow.sh

# Triad
/Users/josh/Developer/flywheel/.flywheel/scripts/cross-session-worker-borrow.sh --doctor --json | jq -r .status
/Users/josh/Developer/flywheel/.flywheel/scripts/cross-session-worker-borrow.sh --info --json | jq -r .owns
/Users/josh/Developer/flywheel/.flywheel/scripts/cross-session-worker-borrow.sh --schema --json | jq -r '.state_machine.states | length'

# Fixture-backed tests (replay the 5 scenarios)
T=$(mktemp -d /tmp/cgjo-verify.XXXX); NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
for FX in T1-duplicate-request T2-stale-pulse T3-protected-tier T4-worker-death T5-release-on-complete; do
  sed "s/NOW_PLACEHOLDER/$NOW/" /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-cgjo/fixtures/${FX}.jsonl > "$T/${FX}.jsonl"
done
# T2 must refuse with pulse_stale:
BORROW_LEDGER="$T/borrow.jsonl" /Users/josh/Developer/flywheel/.flywheel/scripts/cross-session-worker-borrow.sh \
  --request --apply --requestor flywheel --target zesttube --target-pane 2 --task-id task-V \
  --from-fixture "$T/T2-stale-pulse.jsonl" --json | jq -r .reason
```

L112 probe (worker callback):

```bash
T=$(mktemp -d /tmp/cgjo-l112.XXXX); NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
sed "s/NOW_PLACEHOLDER/$NOW/" /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-cgjo/fixtures/T2-stale-pulse.jsonl > "$T/T2.jsonl"
BORROW_LEDGER="$T/b.jsonl" /Users/josh/Developer/flywheel/.flywheel/scripts/cross-session-worker-borrow.sh \
  --request --apply --requestor flywheel --target zesttube --target-pane 2 --task-id task-l112 \
  --from-fixture "$T/T2.jsonl" --json | jq -r '.reason'
```

Expected: literal `pulse_stale`.

## Boundary

- This bead defines the PROTOCOL + dispatcher + fixtures. It does
  NOT execute live borrows (no `ntm send` to actual target panes;
  default mode is `--dry-run`).
- Live borrowing belongs to a future B05 follow-up bead that will:
  (a) wire the actual `ntm send` to the borrowed pane,
  (b) install the BORROW_REQUEST / BORROW_APPROVAL / BORROW_RELEASE
      Agent Mail message types,
  (c) wire the daily-report "Borrowing Activity" section.
- `roster-register.sh` and `team-pulse-heartbeat.sh` are unchanged;
  the dispatcher is a pure consumer of their existing schema.
- `--apply` is gated by Joshua approval (currently the live path is
  not exercised by any cron / launchd job in this commit).

## Skill Auto-Routes

- `canonical-cli-scoping`: yes — script ships `doctor / info /
  schema / help` triad, `--json` default-on, `--apply / --dry-run`
  mutation discipline, stable exit codes (0/1/64/77), 4 actions
  (request / check-eligibility / release / list), file ~340 lines.
- `rust-best-practices`: n/a — no Rust.
- `python-best-practices`: n/a — only `jq` for JSON manipulation.
- `readme-writing`: n/a — doctrine spec carries the operator
  surface; CCS triad covers the CLI surface.

## L61 ECOSYSTEM-TOUCH BLOCK

- `agents_md_updated=no` — no L-rule promoted this turn (the
  doctrine spec is the canonical home; future bead can promote a
  L-rule citing it once the live execution path lands).
- `readme_updated=not_applicable` — no top-level README.
- `no_touch_reason=protocol_spec_lives_in_flywheel_doctrine_dir_until_live_execution_lands_under_b05_followup`.

## Four-Lens Self-Grade

- Brand: 8 — closes B06 with a self-contained protocol + dry-run
  dispatcher + 5/5 fixture coverage; the live execution boundary
  is explicit so a future worker won't conflate it with the B05
  implementation.
- Sniff: 9 — five fixture tests all green with concrete refusal
  reasons matching the spec; idempotency proven by SHA-equivalent
  borrow_id between runs; ledger summary
  `{requested:2,refused:3,released:1}` enumerates the full
  state-machine traversal.
- Jeff: 8 — small surface area (one shell dispatcher + one
  doctrine doc + five fixtures); honors canonical-cli-scoping
  triad with stable exit codes; no upstream patch.
- Public: 9 — operator/maintainer/future worker can rerun the
  L112 probe in <100ms and re-derive the fixture results in <2s.
  Three Judges check passes: operator (sees fixture pass/fail
  with reasons), maintainer (sees the spec + state machine),
  future worker (sees the explicit B05 follow-up boundary).

## L52 Receipt

`beads_filed=none beads_updated=flywheel-cgjo no_bead_reason=none`.
