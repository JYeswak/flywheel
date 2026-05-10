## worker-pane-not-waiting-integrate-blocker

Date: 2026-05-09

Promotion Action: NEW

Class: `worker-pane-not-waiting-integrate-blocker`

Event Count: 6 events in 7 days

Severity: low

Cost: INTEGRATE phase pre-flight checks worker pane state before
running the callback reap. When a worker pane is not in WAITING
state (e.g., THINKING/working on an in-flight task), INTEGRATE
aborts and reports `worker-pane-not-waiting-integrate-blocker`.
Re-tries every ~5 minutes until the pane settles, generating a
trauma-class storm in the fuckup-log (5 of 6 observed events
occurred within a 20-minute window during a Nango Railway worker
session on 2026-05-04T01:20-01:40Z).

Root Cause: INTEGRATE prelude treats worker-pane busy-state as a
HARD blocker rather than a wait-and-retry signal. The legitimate
case (worker is mid-task) and the pathological case (worker stuck)
are conflated; the INTEGRATE phase punts in both rather than
distinguishing.

Forever-Rule: INTEGRATE prelude MUST distinguish three worker-pane
states before declaring a blocker:

1. **WAITING**: pane is idle and ready for callback reap → proceed.
2. **THINKING/working with recent activity** (`ntm activity` shows
   forward progress within the cadence window): legitimate in-flight
   task → defer INTEGRATE one cadence (5 min), do NOT emit a
   blocker fuckup.
3. **THINKING/working with NO recent activity** (stuck/frozen): emit
   `worker-pane-not-waiting-integrate-blocker` AND a `frozen-pane`
   probe to trigger respawn workflow.

Storm protection: rate-limit the trauma-class emission to once per
30 minutes per (session, pane) tuple to prevent the 5-events-in-20-
min storm pattern observed.

Fix Applied/Status: NEW layer-2 INCIDENTS entry from
`/flywheel:learn --promote worker-pane-not-waiting-integrate-blocker`
([flywheel-1kdfk]). Worker-side contract codified; INTEGRATE prelude
should be patched to implement the three-state distinction
(separate orch follow-up). Storm-protection rate-limit recommended
for the fuckup-log emitter.

Evidence:
- `~/.local/state/flywheel/fuckup-log.jsonl` lines 399, 401, 403,
  407, 410, 414 (durable copy at
  `.flywheel/audit/flywheel-1kdfk/fuckup-evidence.jsonl`).
- 6 events all on 2026-05-04T01:11-01:40Z; 5 of them during a
  Nango Railway worker session on pane 2; all `severity:low`.
- Pattern: "INTEGRATE prelude blocked because pane 2 was [THINKING|
  not WAITING] while Nango Railway worker continued".
- Doctrine: integrate-prelude-blocked sibling section (already in
  canonical INCIDENTS); this entry is the worker-pane-state-specific
  variant.
- Bead: `flywheel-1kdfk`.
