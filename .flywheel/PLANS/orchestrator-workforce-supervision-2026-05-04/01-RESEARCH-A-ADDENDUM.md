# Lane A ADDENDUM — cross-session-dispatch-no-callback-closure
# Added 2026-05-04T04:05Z by orchestrator after live fuckup observed mid-plan

## NEW failure class (must be incorporated into Phase 2 REFINE synthesis)

### cross-session-dispatch-no-callback-closure
- **Symptoms:** flywheel orch dispatches work to remote-session worker pane (skillos:p2, mobile-eats:p2, etc.) via cross-session watcher; worker completes the bead; callback envelope points to remote orch pane (e.g. `skillos --pane=1`) per scope-boundary doctrine; remote orch is NOT running flywheel-loop driver, so callback message lands but never gets processed/closed; bead remains `in_progress` forever; flywheel orch (where I live) NEVER sees DONE because callback didn't come to flywheel; remote pane appears idle to Joshua because no further dispatch happens.
- **Signal sources:** ntm robot-activity shows remote pane WAITING/THINKING/ERROR depending on stale-text state; br list --status=in_progress in REMOTE repo shows accumulated stuck beads; dispatch-log in flywheel shows the dispatch happened; NO matching callback_received_at in dispatch-log.
- **Current detection:** none (silent failure)
- **Current recovery:** Joshua observation + manual diagnosis
- **Target detection:** flywheel orch must verify remote orch flywheel-loop-driver liveness BEFORE dispatching cross-session work; doctor signal `cross_session_callback_orphan_count` (count of cross-session dispatches in last 24h with no matching callback within expected window)
- **Target recovery:** if remote orch is dead, refuse to dispatch cross-session work; if dispatched and callback overdue, file gap-bead in flywheel marking the orphan + skillos-handoff bead
- **Criticality:** P0 (recurring; masks all downstream supervision signals; observed 4× today)
- **Observed frequency:** 3 dispatches today (skillos-e2n 03:23Z, skillos-xxf 03:36Z, skillos-s7v 03:50Z) all stuck

## Architecture implication for Phase 2 REFINE
Layer 1 (SIGNAL COLLECTION) must include `remote_session_orch_alive` probe per non-flywheel session. Layer 4 (AUTO-RECOVERY) must include "if remote orch dead, do NOT auto-dispatch cross-session work; refuse and surface to Joshua."

## Cross-reference
- flywheel-b8zm (P0 bug) — full root cause analysis, 5 AGs
- .flywheel/fuckup-log/2026-05-04T04-00Z-skillos-cross-session-no-callback-closure.md
- ~/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_orchestrator_scope_boundary.md (memory needs amending — infrastructure deployment IS picking work)

## Three-judges retroactive score for Lane A original
- **Jeff:** Lane A failure-mode catalog had 12 classes but missed cross-session-dispatch-no-callback-closure because Lane A worker only had today's IN-flywheel-session evidence; would say "your taxonomy was incomplete because input data was incomplete" — fair.
- **Donella:** the missing failure class is exactly a "delayed feedback loop" trauma — Joshua complained 4× before the loop closed (dispatch → no-callback → orch-blind → user-noticed → diagnosis); Lane A's stocks/flows analysis didn't name "callback-debt" stock with cross-session inflow.
- **Josh:** Lane A draft wasn't published anywhere visible to me until callback; the addendum-after-the-fact pattern is exactly the gap the supervision-mesh is meant to close (orch must KNOW its own work isn't completing).
