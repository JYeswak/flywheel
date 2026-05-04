# Canonical Fleet META-RULEs

Last-updated: 2026-05-04T18:30:00Z
Source-of-truth: flywheel:1 (RubyCastle@LavenderGlen) — `/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/`
Fleet-shared mirror (this dir): `/Users/josh/.flywheel/canonical-meta-rules/`

Sister orchs MUST sync at tick start via `./sync.sh` (or symlink-cache locally).

## Rules

1. **feedback_single_capture_misses_freeze.md**
   Multi-frame capture (≥2 frames, ≥5s gap) required before classifying alive/dead. Single-frame "frozen pane" reads miss real freezes.

2. **feedback_xpane_recovery_recommendations_must_verify_canonical_flags_and_protections.md**
   Before any XPANE recovery directive: verify (a) `<script> --help | grep -- --$FLAG` exists, (b) target session not in `~/.claude/skills/.flywheel/scripts/kill-recover-drill.sh` PROTECTED_SESSIONS (alpsinsurance/picoz/skillos).

3. **feedback_calling_in_sick_policy_flywheel_owns_orch_failures.md**
   Workers handled by detector. ORCH failures escalate to flywheel:1 direct recovery; flywheel:1 fails → peer-triage broadcast; Joshua only when mesh fails.

4. **feedback_flywheel_owns_continuous_productivity_no_downtime_unless_josh_blocker.md**
   flywheel:1 owns fleet productivity continuously. Peer-orch idle >5min + workers WAITING + non-empty findings = productivity-escalation xpane SAME TICK. 9-source always-available-work hierarchy. True Josh-blocker = Pushover+mac-alert. NEVER silent.

## How to consume

- At tick start, every orch should `bash /Users/josh/.flywheel/canonical-meta-rules/sync.sh` to fetch latest into local cache.
- Local cache lives at `<repo>/.flywheel/META-RULE-CACHE.md` (mtime probed by fleet doctor).

---
# feedback_calling_in_sick_policy_flywheel_owns_orch_failures.md

---
name: Calling-in-sick policy — flywheel:1 owns orchestrator failures fleet-wide
description: META-RULE 2026-05-04. Joshua's calling-in-sick directive: "we all have to help one another succeed". Worker failures handled by frozen-pane-detector + idle-watcher (per session). Orchestrator failures escalate to flywheel:1 directly. If flywheel:1 fails, broadcast to all sister orchs for peer-triage; first responder takes ownership. Joshua-notify only when entire mesh fails.
type: feedback
originSessionId: 9d43f07f-8673-4f45-90a3-92aa4aa9d284
---
When a worker pane fails, the canonical detect+respawn primitives handle it within the failed pane's session. But when an ORCHESTRATOR pane fails, the session has no live owner to coordinate its own recovery. This is the gap Joshua surfaced 2026-05-04 by flagging mobile-eats:1 frozen.

**The doctrine — calling-in-sick policy:**

1. **Worker frozen** → frozen-pane-detector + idle-pane-auto-dispatch handle within session
2. **Orchestrator frozen** → escalate to **flywheel:1** for direct recovery (this is my job)
3. **Flywheel:1 fails** → broadcast to all sister orchs (alps:1, mobile-eats:1, vrtx:1, skillos:1) for peer-triage; first responder takes ownership
4. **Entire mesh fails** → Joshua-notify (only)

The frame Joshua gave: "calling-in-sick policy — we all have to help one another succeed". An orchestrator can't recover itself; the fleet covers for each other. flywheel:1 is the operations VP responsible for orch-class outages first; sister orchs are second-line; Joshua is the founder you only escalate to when the company-wide on-call has failed.

**Why:** 2026-05-04 — mobile-eats:1 froze at "Working (1m 01s)" loading skills. Pane 2 was actively working but had no orchestrator to send DONE callbacks to. No automation existed to detect+recover an orch-class pane. Joshua spotted it before any flywheel mechanism. Per the architecture-health paradigm, founder-detected-before-fleet-detected = the system failed; flywheel:1 must own orch-class failures going forward.

**How to apply:**

Recovery sequence flywheel:1 executes when an orch is frozen:
1. **Multi-frame hash test** confirm freeze (per `feedback_single_capture_misses_freeze.md`)
2. **Snapshot capture** — `ntm --robot-tail --lines=200 > /tmp/<session>-pane1-snapshot.<iso>.json`
3. **Work-loss audit** — check `git status --porcelain` in the session's repo; working-tree files persist through respawn (only ephemeral pane state lost: in-flight tool calls, unsent messages)
4. **Verify NOT in PROTECTED_SESSIONS** — `grep PROTECTED_SESSIONS ~/.claude/skills/.flywheel/scripts/kill-recover-drill.sh`. If protected (alps/picoz/skillos), evidence-based override gate per CoralRaven 2026-05-04 sequence (snapshot + work-loss=zero + Joshua/operator-authorized)
5. **Respawn** — `ntm respawn <session> --panes=1 --force`
6. **Relaunch codex** — `yes | ntm send <session> --pane=1 --no-cass-check "codex --dangerously-bypass-approvals-and-sandbox"` (yes-pipe is the R3-gate workaround until ntm ships --force-non-interactive)
7. **Verify boot** — capture-tail confirms chevron + correct repo header
8. **Send recovery xpane** — context the new orch needs: snapshot path, what was lost (ephemeral only), what survived (working tree), recommended reorient (STATE.md + handoffs + dispatch-log tail)

For step 3 — the watcher (currently in flight via pane 4 worker-recovery-slo bead) MUST emit orch-class alerts to flywheel:1 explicitly, distinguishing orch failures from worker failures. Worker alerts go to the session's own orch; orch alerts go to flywheel:1.

**Forbidden:**
- Joshua-notifying for orch failures unless flywheel:1 + sister orchs ALL failed
- Treating an orch-class freeze the same as a worker freeze (different escalation path)
- Single-frame validation of orch freeze (must use multi-frame hash test)
- Recovery without snapshot + work-loss audit
- Crossing PROTECTED_SESSIONS without evidence-based override gate

**Cross-references:**
- L75 peer-orch-blocker-coordination
- L91 dispatch-delivery-four-state-receipt
- L95 worker-stall-recovery-protocol (worker scope; this rule extends to orch scope)
- `feedback_single_capture_misses_freeze.md`
- `feedback_xpane_recovery_recommendations_must_verify_canonical_flags_and_protections.md`
- `project_self_sustaining_company_paradigm_2026_05_04.md` (architecture-health frame)
- Pending L99 worker-recovery-slo-180s (queued — will extend with orch-class lane)

---
# feedback_flywheel_owns_continuous_productivity_no_downtime_unless_josh_blocker.md

---
name: Flywheel:1 owns continuous fleet productivity — no downtime unless TRUE Josh-blocker
description: META-RULE 2026-05-04. flywheel:1 keeps every fleet session productive. If a session is idle, flywheel:1 either dispatches via xpane or escalates to Josh ONLY when blocker requires Josh-personal-action. Skills library + L-rules + canonical docs always have work findable. Joshua-notify path is for true blockers, NEVER for "session is quiet today."
type: feedback
originSessionId: 9d43f07f-8673-4f45-90a3-92aa4aa9d284
---
Joshua's directive 2026-05-04: "part of flywheel role is to keep all projects productive, unless they are truly blocked by something I need to get involved in, and in that case, I need to be notified immediately so I can tune in and unblock. There should be no downtime unless true josh blockers are in place - there is always work to be done - our skills library and L rules Blocker report set that."

This is the operational extension of the calling-in-sick policy. Companion to `feedback_calling_in_sick_policy_flywheel_owns_orch_failures.md` (orch failures) — this rule covers idle-but-not-failed.

**Three states a fleet session can be in:**

1. **Productive** — workers THINKING + commits flowing + callbacks landing. flywheel:1 monitors, no action.
2. **Idle-with-work-available** — workers WAITING + br ready empty/low + no Josh-blocker. **flywheel:1 OWNS THIS.** xpane the orch with concrete bead-filing instructions OR escalate to Joshua-notify if structural gap blocks bead-filing itself. Default: there is ALWAYS work — skills library, L-rules audit, canonical doc backfill, doctor findings, fuckup-log promotion, gap-hunt findings.
3. **True Josh-blocker** — substrate corrupted, security/PHI decision, paradigm-level shift, destructive op needing approval. flywheel:1 IMMEDIATELY notifies Joshua via Pushover/mac-alert/inline ack. NEVER let a Josh-blocker sit silent.

**Forbidden orchestrator output:**
- "Session X is idle and waiting for next work" — flywheel:1 must convert that into a dispatch OR an escalation, not a status update
- "Doctor reported N findings, awaiting analysis" — findings ARE the work; convert to beads
- "br ready is empty" reported as terminal state — empty br ready is flywheel:1's CUE TO FILE BEADS
- Joshua-notify for "session has been quiet" — that's flywheel:1's job to fix
- Silent on a true Josh-blocker — escalate IMMEDIATELY with explicit unblock-action

**The always-available work hierarchy** (in order of preference when finding work for an idle peer orch):

1. Doctor errors[] → fix-bead per error
2. fuckup_triage candidates → promotion-bead
3. closed_bead_audit_pending → reopen-or-close evaluation bead
4. canonical_drift / fleet_repo_l_rule_lag → backfill-bead
5. Recent commits without README/AGENTS.md update (L61) → ecosystem-touch bead
6. INCIDENTS.md unprocessed events → promotion bead
7. Skill citation graph gaps (skills referenced but never cited back) → audit bead
8. Gap-hunt-probe findings → structural-fix bead
9. Mission-anchor doctrine drift → mission-lock refresh bead

If ALL nine return zero, then session is genuinely caught up — surface to Joshua as "session at zero-backlog state, recommend new mission anchor or rest."

**Why:** 2026-05-04 — skillos and mobile-eats both went idle multiple times today with workers WAITING + audit findings unfiled + br ready empty + orchs producing reports instead of beads. Joshua flagged irritation. The pattern: orch converts work-INTO-reports instead of reports-INTO-work. flywheel:1 must catch this same-tick and inject dispatch instructions. Per architecture-health frame (project_self_sustaining_company_paradigm): NOT agent-shaming — orchestrators are doing what their loops told them; the gate is what's missing.

**How to apply:**
- /flywheel:status dashboard surfaces fleet-wide `idle_with_work_available_count` per session
- Threshold: any peer-orch session at idle >5min with workers WAITING + non-empty findings = flywheel:1 sends productivity-escalation xpane same tick
- Escalation packet template: 3 concrete bead-filing instructions + ETA + "stop reading reports, start filing beads" tone
- True Josh-blocker path: Pushover notification + mac-alert + inline ack message; NEVER queue silently
- Doctor probe: `peer_orch_idle_with_work_available_count` per-session, 5min threshold; flywheel:1's escalation is the response
- Memory-lock the always-available-work hierarchy; orchs internalize OR flywheel:1 dispatches it for them

**Forbidden:**
- Treating "session is idle" as a status worth reporting to Joshua
- Letting any peer orch sit >5min with workers WAITING + findings unfiled
- Joshua-notify for anything resolvable by xpane productivity-escalation
- Silent Josh-blockers (any blocker truly requiring Josh action MUST trigger immediate notify with explicit unblock spec)

**Cross-references:**
- L70 same-tick chain-forward
- L75 peer-orch-blocker-coordination
- L92 audit-findings-route-by-data
- `feedback_calling_in_sick_policy_flywheel_owns_orch_failures.md` (orch crashed → flywheel recovers)
- `feedback_low_bead_threshold_work_hunt.md` (sibling — already-existing rule on work-hunt vs notify)
- `project_self_sustaining_company_paradigm_2026_05_04.md` (architecture-health frame)

---
# feedback_single_capture_misses_freeze.md

---
name: Single-frame capture misses frozen panes
description: META-RULE 2026-05-04. ONE capture proves "alive words on screen", not "pane is moving". Frozen panes show identical content across multiple captures with stale timer values. Always do multi-frame hash-diff before classifying alive/dead.
type: feedback
originSessionId: 9d43f07f-8673-4f45-90a3-92aa4aa9d284
---
When validating a pane is alive vs frozen, a single `ntm --robot-tail` capture is INSUFFICIENT. Frozen Codex panes show real text (chevron, work spinner, "Waiting for background terminal Xm Ys") that LOOKS alive at a single moment. The freeze-signal is **invariance across time** — same byte content, same timer value, no scroll progress.

**Why:** 2026-05-04 — Joshua reported alps:2 dead. I checked once, saw `codex_working` + chevron + 13m21s spinner, called it alive. Joshua: "look at the capture again — it'll show the exact same thing twice or three times." Three captures over 16s = identical hash `c2be881f0d60`. The 13m21s timer never advanced. Pane was frozen exactly as Joshua said.

This is the L91/L95 sibling: L91 catches first-tick non-start, L95 catches stall-recovery, but pane-WAS-working-now-stuck-mid-task between captures has its own validation requirement.

**How to apply:**
- Before classifying any pane as alive based on capture: take ≥2 captures with ≥5s gap and hash-diff
- Identical hash + capture_provenance=live + agent state THINKING/working = candidate-frozen
- Particularly suspect: timer values that don't advance (`Xm Ys` where Y is constant)
- Frozen-pane-detector v2 (`.flywheel/scripts/frozen-pane-detector.sh`) already does this with byte-delta sampling — TRUST IT over single ntm activity row
- For ad-hoc debug: `A=$(ntm --robot-tail | shasum); sleep 6; B=$(ntm --robot-tail | shasum); [ "$A" = "$B" ]`

**Forbidden:**
- Declaring a pane alive on single-capture evidence when Joshua reports frozen
- Using `state=THINKING` alone as alive-signal (THINKING + frozen content = stuck)
- Trusting "Xm Ys" elapsed timers as proof-of-progress

**Cross-references:**
- L85 idle-state-class-canonical
- L87 stale-error-text-auto-ping-recovery
- L91 dispatch-delivery-four-state-receipt
- L95 worker-stall-recovery-protocol
- `feedback_orchestrator_is_the_killer_not_codex.md` (sibling — single-frame misread of ERROR)
- `.flywheel/scripts/frozen-pane-detector.sh` (canonical detector, byte-delta sampling)

---
# feedback_xpane_recovery_recommendations_must_verify_canonical_flags_and_protections.md

---
name: XPANE recovery recommendations must verify canonical flags + protected-sessions
description: META-RULE 2026-05-04. Before sending an XPANE recovery directive to a peer orch, verify (1) the recommended command's flag exists in the canonical script, AND (2) the target session is not in kill-recover-drill.sh PROTECTED_SESSIONS. Failed both for alps:2 today; CoralRaven correctly refused.
type: feedback
originSessionId: 9d43f07f-8673-4f45-90a3-92aa4aa9d284
---
When sending an XPANE peer-orch coordination packet that recommends a recovery command, the orchestrator MUST verify before sending:

1. **Canonical flag check.** The recommended command's argument must exist in the script. Run `<script> --help 2>&1 | grep <flag>` or read the argv parser BEFORE recommending. Recommending wrong flags wastes peer-orch cycles and triggers a doctrine-conflict callback that has to be unwound.

2. **Protected-sessions guard.** Check `~/.claude/skills/flywheel/_shared/kill-recover-drill.sh` (or wherever PROTECTED_SESSIONS is defined). Sessions like `alpsinsurance`, `picoz`, `skillos` are protected by canonical doctrine — `/flywheel:respawn` and other recovery primitives reject them by design. Recommending respawn on a protected session is doctrinally invalid even when the symptom (frozen pane) is real.

**Why:** 2026-05-04 — sent alpsinsurance:1 (CoralRaven) an XPANE recommending `frozen-pane-detector.sh --apply --session=alpsinsurance --panes=2`. Two failures:
- Actual flag is `--auto-recover`, not `--apply`. CoralRaven hit "ERROR: unknown argument".
- Even with the right flag, alpsinsurance is in PROTECTED_SESSIONS. The detector self-protects; the canonical /flywheel:respawn skill explicitly refuses active-client sessions. CoralRaven correctly refused the directive on doctrine grounds.

The recovery requires Joshua-driven or operator-pane-0 directly — orchestrators cannot cross the protected-session line. This is correct doctrine (active client sessions need human-confirmed recovery, not orchestrator-automated).

**How to apply:**
- Before any XPANE recovery directive, execute pre-flight:
  ```bash
  # 1. Flag check
  $SCRIPT --help 2>&1 | grep -- "--$FLAG" || abort "wrong flag"
  # 2. Protected sessions check
  grep -E "PROTECTED_SESSIONS=.*$TARGET_SESSION" ~/.claude/skills/flywheel/_shared/kill-recover-drill.sh && abort "protected; route to Joshua/operator"
  ```
- If target session is protected, the XPANE handoff converts to a Joshua-notify packet: "alps:2 frozen, your call (or operator-pane-0 with explicit override). Detector v2 self-blocks on protected sessions by design."
- Detector v3 candidate (per CoralRaven's routing): `--evidence-source=joshua-confirmed --force-recover` flag with multi-frame-hash-test override of `state_since_untrusted` gate. Belongs in next worker-recovery-slo bead.

**Forbidden:**
- Sending recovery commands to peer orchs without flag verification
- Recommending automated recovery on PROTECTED_SESSIONS sessions
- Treating "no callback yet" as proof of work in progress when peer orch already raised DOCTRINE_CONFLICT

**Cross-references:**
- L75 peer-orch-blocker-coordination
- L91 dispatch-delivery-four-state-receipt (canonical-flag-check is a pre-flight cousin)
- `~/.claude/skills/flywheel/_shared/kill-recover-drill.sh` (PROTECTED_SESSIONS source)
- `feedback_single_capture_misses_freeze.md` (today's sibling — both about freeze recovery)

