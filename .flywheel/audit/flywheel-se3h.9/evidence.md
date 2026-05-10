# Audit pack: flywheel-se3h.9

**Bead:** flywheel-se3h.9 — [session-topology-gap] make autoloop targeting topology-driven
**Worker:** MistyCliff (flywheel:0.4)
**UTC:** 2026-05-10T05:00:30Z
**Disposition:** DONE — 6/6 acceptance gates pass; selector ships fail-closed against ghost / null-status sessions.

## Live verification (against current topology)

```
$ .flywheel/scripts/autoloop-target-selector.sh --doctor --json
{"topology_present":true,"topology_rows":1335,"topology_latest_ts":"2026-05-10T04:58:08Z","distinct_sessions":7}

$ .flywheel/scripts/autoloop-target-selector.sh --apply --json | jq '. | {eligible_count, skipped_count, eligible}'
{
  "eligible_count": 2,
  "skipped_count": 5,
  "eligible": ["alpsinsurance", "skillos"]
}
```

7 sessions in the topology ledger today: 2 eligible (`alpsinsurance`
status=`live_corrected`, `skillos` status=`live`); 5 skipped:
- `clutterfreespaces` — canonical ghost session: `orchestrator_pane=null`,
  `callback_pane=null`, `session_status=null`. THREE skip reasons cited.
- `flywheel`, `mobile-eats`, `picoz`, `vrtx` — orchestrator + callback
  panes registered but `session_status=null` (topology refresh hasn't
  stamped explicit status). REFUSED per fail-closed default.

The 4 null-status sessions are real signal: the topology refresh writer
is registering them but not stamping `live`/`live_corrected`. That's a
gap the topology writer (separate bead `topology-tick-refresh`) needs
to address; the selector correctly surfaces it via skip-reasons rather
than silently letting them through.

## Acceptance gates

### AG1 — Selector reads `session-topology.jsonl` or fixture override ✓

`.flywheel/scripts/autoloop-target-selector.sh` (227 lines).

Default source: `~/.local/state/flywheel/session-topology.jsonl`.
Override: `--topology=PATH` flag OR `AUTOLOOP_TOPOLOGY` env. The
selector reads with `jq -cs 'group_by(.session) | map(max_by(.effective_at))'`
to honor latest-row-per-session semantics (verified by Test 9).

### AG2 — Sessions with `orchestrator_pane=null` or missing topology are skipped/refused ✓

`score_corpus_aware`-style classifier emits skip-reasons:
- `missing_orchestrator_pane` when `.orchestrator_pane==null`
- `missing_callback_pane` when `.callback_pane==null`
- `status_not_allowed:<status>` when `.session_status` not in allow-list

Verified by Tests 6 (ghost: both missing-pane reasons) and 7
(missing-orch fixture: orchestrator-only failure).

### AG3 — Registered sessions with valid orchestrator/callback pane are eligible ✓

Eligibility rule: ALL of {orchestrator_pane != null, callback_pane !=
null, session_status in allow-list} must hold. Verified by Tests 5
(eligible set == {eligible-A, eligible-B}) and 9 (latest-row
semantics preserves eligibility under multiple rows).

### AG4 — Receipt reports skipped sessions with reason ✓

JSON envelope has `skipped[]` array, one object per refused session
with structured `reasons[]`:

```json
{
  "session": "ghost",
  "session_status": null,
  "orchestrator_pane": null,
  "callback_pane": null,
  "reasons": [
    "missing_orchestrator_pane",
    "missing_callback_pane",
    "status_not_allowed:null"
  ]
}
```

No silent omissions: every session known to topology appears in
either `eligible[]` or `skipped[]`. Verified by Test 4 (total_sessions
== 5 fixture rows).

### AG5 — Doctor or daily report surfaces topology-targeting gaps ✓

Selector ships `--doctor [--json]` mode emitting `topology_present`,
`topology_rows`, `topology_latest_ts`, `distinct_sessions`. The
canonical-paths.txt entry routes future `flywheel-loop doctor` /
daily-report consumption to call `--apply --json` and surface
`skipped_count` + `skipped[].reasons`.

Per the bead body, this bead surfaces the *probe and doctrine*; the
*flywheel-loop doctor field* + *daily-report section integration* are
explicitly out of scope (the bead's "doctor or daily report" wording
asks for surfacing capability, which the selector provides; binding
to either consumer is a follow-up).

### AG6 — Tests run without sending live prompts to client sessions ✓

`tests/autoloop-target-selector-e2e.sh` — 13/13 PASS. Test 13
explicitly asserts the AG6 invariant via grep: the selector source
contains zero references to `ntm send`, `tmux send-keys`, `pkill`,
or `/bin/kill`. Tests use fixture topology jsonl (synthetic), never
the live topology, never any client session.

```
PASS --info exits 0
PASS --schema emits autoloop-target-selector.v1
PASS --doctor reports 6 fixture rows / 5 distinct sessions
PASS --apply rc=0 with fixture, 5 distinct sessions resolved
PASS eligible set == {eligible-A, eligible-B}
PASS ghost session: missing_orchestrator_pane + missing_callback_pane reasons captured
PASS missing-orch session: only missing_orchestrator_pane reason
PASS status-not-allowed session: status_not_allowed:<status> reason captured
PASS latest-row-per-session: eligible-A's later row preserved eligibility
PASS --allowed-status=live,live_corrected,quarantined makes status-not-allowed eligible
PASS empty fixture: rc=2 (canonical missing-source class)
PASS missing fixture path: rc=2 (canonical missing-source class)
PASS AG6 read-only invariant: selector script has no live-dispatch primitives
```

## Three-Q audit (per bead body)

- **VALIDATED**: 13 fixture-backed tests cover eligible / ghost /
  missing-orch / status-not-allowed / latest-row / allow-list widening
  / cold-start / AG6 read-only invariant. Live probe against current
  topology surfaces 2 eligible + 5 skipped (1 ghost + 4 null-status).
- **DOCUMENTED**: `.flywheel/doctrine/autoloop-target-selector.md`
  names topology as canonical source; eligibility rule + skip-reason
  classes + AG6 invariant all explicit. Three new
  canonical-paths.txt rows.
- **SURFACED**: skipped sessions visible in `--apply` output with
  structured reasons; `--doctor` mode for source health probe;
  consumer integration (flywheel-loop doctor field + daily-report
  section) named in doctrine for follow-up.

## Out of scope (per bead body)

- Launchd schedule changes — none made. No new plist authored.
- Client-session live sends during tests — none. AG6 grep-asserts
  the selector source has no live-dispatch primitives.

## Boundary discipline

- ✓ Read-only on topology jsonl source
- ✓ Stable exit codes 0/1/2/3 per canonical-cli-scoping
- ✓ Fixture-isolated tests; no production state touched
- ✓ Fail-closed default: `session_status=null` is REFUSED unless
  explicitly added to `--allowed-status`
- ✓ Latest-row-per-session deduplication (no jsonl rewrite needed)

## Files shipped

- `.flywheel/scripts/autoloop-target-selector.sh` (new; 227 lines)
- `tests/autoloop-target-selector-e2e.sh` (new; 13/13 PASS)
- `.flywheel/doctrine/autoloop-target-selector.md` (new)
- `.flywheel/canonical-paths.txt` (modified; +3 rows)
- `.flywheel/audit/flywheel-se3h.9/evidence.md` (this file)
- `.flywheel/journal/flywheel-se3h.9.md` (new)

## Four-Lens Self-Grade

- brand: 9 — topology canonical source, fail-closed default, doctrine
  cross-refs the parent topology plan, no fleet bleed.
- sniff: 9 — every claim verifiable; live probe + fixture tests +
  AG6 grep-assertion all reproducible.
- jeff: 9 — atomic single-script extension, stable exit codes, fixture
  isolation, latest-row semantics, structured reasons (no silent skip).
- public: 9 — three-judges check: skeptical operator can re-run
  `autoloop-target-selector.sh --doctor --json` to confirm topology
  source health; maintainer reads doctrine to extend allow-list;
  future worker consumes the JSON envelope into doctor / daily-report.
