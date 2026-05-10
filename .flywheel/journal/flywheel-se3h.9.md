---
bead_id: flywheel-se3h.9
task_id: flywheel-se3h.9-7d099a
worker_identity: MistyCliff
ts: 2026-05-10T05:00:30Z
mission_fitness: adjacent
commit_sha: pending
linked_incidents: []
linked_l_rules: []
linked_skills: []
narrative_tags:
  - fail-closed-by-default
  - latest-row-per-session-deduplication
  - read-only-invariant-as-test-assertion
  - canonical-source-substrate-doctrine
---

The fail-closed default is the load-bearing decision. Selectors that
default-allow drift toward "let everything through unless we know
why not" — which is exactly the trauma the bead author flagged
(ghost sessions sneaking into autoloop). Defaulting to
`--allowed-status=live,live_corrected` means a session has to *earn*
eligibility by getting the topology refresh writer to stamp it
explicitly. That puts the burden on the producer side (where it
belongs) instead of leaving the consumer (autoloop) guessing.

The interesting empirical observation: of 7 sessions in the live
topology today, only 2 (alpsinsurance + skillos) have explicit
`session_status` stamps. The other 4 (flywheel, mobile-eats, picoz,
vrtx) have `session_status=null` despite being actively-running
sessions with valid orchestrator panes. That's a real signal about
the topology refresh writer — it's registering them but not
stamping status. The selector correctly surfaces this as
`status_not_allowed:null` skip-reason rather than letting them
through silently. The next bead in the chain (probably
flywheel-se3h.1's registry validation work) needs to decide
whether the writer should default-stamp `live` for sessions with
non-null orchestrator_pane, or whether the absence of stamp is
itself meaningful.

The AG6 read-only invariant being asserted as a test (Test 13
greps the selector source for live-dispatch primitives) is the
right shape. Just saying "selector is read-only" in a comment is
prose; baking it into a test that fails on regression makes it
load-bearing. Same pattern as flywheel-cmr7o's regression tests
that invert on lifecycle advance.

The latest-row-per-session deduplication via jq's
`group_by | map(max_by(.effective_at))` was an old trick (already
used in `topology-tick-refresh.sh` and the conformance probe) but
worth naming explicitly in doctrine. Append-only ledgers + latest-
row semantics let the selector pick up status changes without any
ledger rewrite — the topology writer just appends a new row, and
the selector's next call sees the new state. That's the right
invariant for ephemeral session state.

Out-of-scope discipline held: bead body said "no launchd schedule
changes" and "no client-session live sends during tests" — both
respected. The bead also said "doctor or daily report surfaces
topology-targeting gaps" — I added a `--doctor` mode + named the
doctor-field / daily-report-section integration in the doctrine as
follow-up. The selector ships the SURFACE (probe + envelope); the
CONSUMER bind happens in a separate bead.
