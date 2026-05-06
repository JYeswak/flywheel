# Fuckup log — skillos cross-session watcher dispatch with no callback closure
# date: 2026-05-04T04:00Z
# trauma_class: cross-session-dispatch-no-callback-closure
# severity: high (recurring, Joshua flagged 4× across session)

## What happened
1. Joshua launched flywheel-side watcher v4-generic for skillos session at 03:02Z (per his explicit request "we should get our v4 watcher turned on in skillos and mobile-eats")
2. Watcher correctly dispatched 3 P0 beads from skillos repo to skillos:p2: e2n, xxf, s7v
3. Each dispatch correctly wrote `br update --status in_progress` BEFORE ntm send (atomic)
4. Codex worker on skillos:p2 actually worked through them (visible in dispatch-log + skillos branch state)
5. Worker emitted DONE callbacks (per worker contract), with envelope pointing to `skillos --pane=1` (the skillos orch)
6. **skillos orch pane 1 has NOT processed/closed those beads** — they sit `in_progress` indefinitely
7. **flywheel orch never sees the DONE** — callbacks stayed within skillos session per envelope contract
8. From flywheel's view, skillos:p2 appears idle (worker done, no new dispatch); from skillos's view, beads stay open
9. Joshua repeatedly asks "skillos is idle - why" because flywheel orch (where I run) genuinely has no signal

## Root causes (4 layers, all required for the fuckup)

### RC1: cross-session watcher launched without callback-receiver liveness check
The watcher I built (idle-pane-auto-dispatch-generic.sh) writes callback envelopes pointing to `<session> --pane=<orch_pane>`. It does NOT verify the orch pane is alive and processing callbacks. If skillos orch is offline/idle/asleep, beads accumulate `in_progress` forever.

### RC2: orchestrator-scope-boundary memory was applied incompletely
Memory `feedback_orchestrator_scope_boundary.md` says "flywheel orch only re-dispatches flywheel-session tasks; mobile-eats/skillos/alps own their own." I read this as "infrastructure deployment is OK, just don't pick the work" — but launching a watcher that drives skillos's dispatch IS picking the work, just at one remove. Joshua was right the first time when I started to back off.

### RC3: stale-error scrollback false-positive masks "actually idle" from "actually working" — for both classes
Same trauma class as flywheel-pp1g. ntm classifier reads `failed_text` from worker evidence/output left in scrollback above the prompt. Pane appears ERROR even when truly idle (real here) AND when truly working. Both axes of misclassification create the appearance of "idle" from outside.

### RC4: br query schema fragility — jq filter silently failed
My jq `.title[0:60]` assumed object-array shape; skillos br returned different shape. Silent fail returned empty list. I concluded "no work remaining" when in fact 3 beads were stuck in_progress. Should have used `--no-pager` or checked exit code.

## Why this is "proper fuckup worthy" (Joshua's framing)
- Recurring (4 user prompts about skillos idle)
- Each "fix" was a point-patch (manual ping, then auto-nudge, then redispatch) without addressing root architecture
- The supervision-mesh plan I just launched (flywheel-plan orchestrator-workforce-supervision-2026-05-04) is the right framing — but its INPUT data is now incomplete because Lane A didn't see THIS failure class
- I built infrastructure (cross-session watcher) that violated the scope-boundary memory in effect, not just letter

## Immediate corrective actions
1. SHUT DOWN cross-session watchers (skillos PID 66256, mobile-eats PID 66369). They are the wrong topology.
2. File flywheel-supervision-plan addendum: add cross-session-callback-closure failure class to Lane A taxonomy retroactively.
3. Per scope boundary memory: skillos's own orch must run skillos's watcher. Joshua-side: this requires `flywheel-loop` infrastructure to be installed in skillos session/repo, with skillos orch claiming pane 1.
4. The 3 stuck beads (e2n, xxf, s7v) need skillos orch to close them — file a no-bead receipt in flywheel pointing to skillos handoff requirement.

## Promotion candidate (doctrine ladder)
- Promote `cross-session-dispatch-no-callback-closure` to AGENTS.md L## as a canonical anti-pattern
- Add to `feedback_orchestrator_scope_boundary.md`: "infrastructure deployment IS picking the work — watchers, daemons, and recovery loops that drive a remote session's dispatch must be deployed FROM that session, not pushed in from flywheel orch"
- Source-(a) skill: `/flywheel:supervisor` once built MUST gate cross-session probe on remote-orch-alive verification
