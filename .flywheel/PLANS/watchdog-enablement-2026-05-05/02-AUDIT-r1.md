---
title: "02-AUDIT-r1 - Watchdog Enablement"
type: plan
created: 2026-05-06
frontmatter_source: scaffold-doc-frontmatter
---

# 02-AUDIT-r1 - Watchdog Enablement

Date: 2026-05-05
Task: audit-r1-watchdog-2026-05-05
Mode: plan-space only
Audited artifact: `.flywheel/PLANS/watchdog-enablement-2026-05-05/00-PLAN.md`
Baseline artifact: `.flywheel/PLANS/watchdog-enablement-2026-05-05/00-PLAN-INPUT.md`
Review inputs:
- `.flywheel/PLANS/watchdog-enablement-2026-05-05/01-REVIEW-multi-model.md`
- `.flywheel/PLANS/watchdog-enablement-2026-05-05/01-REVIEW-donella.md`
- `.flywheel/PLANS/watchdog-enablement-2026-05-05/01-REVIEW-jeff.md`
Research input: `/tmp/research-ntm-auto-respawn-2026-05-05.md`
Skill posture: `/jeff-convergence-audit` broad sweep plus 12-class blunder hunt
Joshua override: must hold structurally
Override meaning: auto-respawn is primary for eligible FROZEN worker panes
Override fallback: notify-only is fallback/refusal only
Composite: 9.6
Verdict: continue-r1

---

## 1. Executive Verdict

Summary count:
Critical findings: 0
High findings: 2
Medium findings: 2
Low findings: 2
Total findings: 6
Verdict: continue-r1
Reason: the plan is directionally correct and close to implementation-ready, but the high findings should be patched in plan-space before r2 bead decomposition.
Not a replan: the core architecture survives.
Not pass-to-r2 yet: two high findings can produce unsafe implementation if copied literally.
Joshua override status: consistent.
Watcher_governance_loop status: structural but needs schema lock before source edits.
Truly-dead detection status: mechanical in source, partial in final plan prose.
Permit gate protected-session status: partial.
Cross-plan layering status: clean.

Primary positive judgment:
The plan does not silently regress to notify-only.
The header states the override directly at `00-PLAN.md:21-22`.
Section 1 repeats the decision at `00-PLAN.md:41-48`.
The Jeff section rejects notify-only as primary at `00-PLAN.md:423-438`.
Appendix C closes the conflict at `00-PLAN.md:861-864`.
The plan therefore satisfies the user's structural override at the thesis level.

Primary blocking judgment:
The fallback executor sentence narrows the required gate set.
W4 first says act-and-respawn requires W0-W3, W6, W8, and L60 at `00-PLAN.md:191`.
The fallback executor then says `ntm respawn` may run if only W0/W2/W6 remain true at `00-PLAN.md:194`.
That local sentence can be copied into implementation as a bypass of W3 threshold, W8 authority, and L60 truth.
This is High H-01.

Second blocking judgment:
The dispatch required alpsinsurance, picoz, and skillos to be explicitly excluded.
The plan denies protected sessions generically at `00-PLAN.md:137`, `00-PLAN.md:170`, `00-PLAN.md:609`, and `00-PLAN.md:623`.
It never names alpsinsurance, picoz, or skillos.
It also permits `protected_session_auto_apply_count` to be nonzero when an encoded permit exists at `00-PLAN.md:560`.
That blurs worker watchdog exclusion with separate peer-orch permit exceptions.
This is High H-02.

Medium judgment:
The final plan relies on the detector's existing mechanical predicate, but it does not inline enough of the predicate for safe bead decomposition.
It says two robot-tail samples and FROZEN class at `00-PLAN.md:131-140`.
It says W1 requires live truth and two samples at `00-PLAN.md:151-156`.
It names 90s detect and 5m act at `00-PLAN.md:182-184`.
It does not restate min delta bytes, sample interval, timer-text identical branch, or age-plus-delta branch.
Those are present in the detector source at `.flywheel/scripts/frozen-pane-detector.sh:25-29`, `.flywheel/scripts/frozen-pane-detector.sh:1160-1175`, and `.flywheel/scripts/frozen-pane-detector.sh:1204-1207`.
This is Medium M-01.

Medium judgment:
W8 is real enough to avoid "aspirational watcher" failure, but its schema is still deferred.
The plan defines authority states at `00-PLAN.md:290-296`.
It defines promotion and demotion signals at `00-PLAN.md:301-317`.
It defines self-health fields at `00-PLAN.md:318-326`.
It then asks whether W8 needs a concrete schema before implementation at `00-PLAN.md:651-652`.
It says Phase 0.3 will define W0 and W8 schemas at `00-PLAN.md:671-672`.
This is acceptable for r1, but source edits must not begin until the schema exists.
This is Medium M-02.

Low judgment:
W5 receipt fields omit an explicit `prompt_provenance_source` field even though the plan later requires prompt provenance to be 100 percent.
W4 gives prompt source order at `00-PLAN.md:198-202`.
W5 receipt fields list action, policy, authority, and reason codes at `00-PLAN.md:212-228`.
Success criteria require `prompt_provenance_present_pct` at `00-PLAN.md:573`.
The receipt schema should include the exact source selected.
This is Low L-01.

Low judgment:
Manager-loop consumption is correctly layered, but its path/cadence/schema is not locked.
The plan lists manager-loop summary fields at `00-PLAN.md:238-248`.
Section 8 says manager-loop consumes receipts and governance state at `00-PLAN.md:507`.
Open question 4 asks immediate versus hourly rollup at `00-PLAN.md:657-658`.
This should be resolved in r2 before implementation tasks are split.
This is Low L-02.

Convergence posture:
The r1 audit should not ask Joshua anything.
The r1 audit should not write beads.
The r1 audit should feed a small plan revision.
The plan can converge after these six edits.

---

## 2. Joshua Override Consistency Check

Audit question:
Does any primitive smuggle notify-only back in as the default for safety?
Answer: no.
Overall status: yes.
Important nuance: H-01 is a missing gate on fallback execution, not a notify-only regression.

W0 check:
Primitive: Eligibility Preflight.
Lines: `00-PLAN.md:120-144`.
Action disposition: gate only.
Notify-only statement: only when W0 refuses action at `00-PLAN.md:123`.
Mutation authority: none at `00-PLAN.md:124`.
Override verdict: pass.
Reason: W0 cannot become notify-only default because it has no act authority.
Required r2 change: none for override.

W1 check:
Primitive: Detector / Classifier.
Lines: `00-PLAN.md:146-158`.
Action disposition: classify only.
Notify-only statement: only for non-action classes at `00-PLAN.md:149`.
Allowed action class: FROZEN only at `00-PLAN.md:152`.
Mutation authority: none without W0, W2, W3, W6, and W8 at `00-PLAN.md:156`.
Override verdict: pass.
Reason: W1 routes non-FROZEN to fallback but preserves FROZEN as the only action candidate.
Required r2 change: add more mechanical predicate detail under M-01.

W2 check:
Primitive: Permit Gate.
Lines: `00-PLAN.md:160-175`.
Action disposition: permit gate.
Notify-only statement: only on refusal at `00-PLAN.md:163`.
Worker pane default: eligible only after W0 and W1 pass at `00-PLAN.md:165`.
Protected session default: deny at `00-PLAN.md:170`.
Peer-orch separate track: `00-PLAN.md:171-172`.
Override verdict: pass with permit naming gap.
Reason: W2 denies unsafe targets rather than making notify-only a primary path.
Required r2 change: explicitly name alpsinsurance, picoz, and skillos in worker watchdog exclusion.

W3 check:
Primitive: Threshold / Debounce.
Lines: `00-PLAN.md:177-186`.
Action disposition: timing gate.
Notify-only statement: only before action threshold or on timeout refusal at `00-PLAN.md:180`.
Day-one action threshold: 5m act after 90s detect/log at `00-PLAN.md:182`.
Promotion evidence: 24h dry-run, 20 clean cycles, one canary, zero false positives, zero unknown recoveries, rollback proof at `00-PLAN.md:183`.
Override verdict: pass.
Reason: W3 delays action but does not make notify-only the end state.
Required r2 change: include exact frozen-predicate thresholds with M-01.

W4 check:
Primitive: Execution And Prompt Re-Injection.
Lines: `00-PLAN.md:188-204`.
Action disposition: act-and-respawn at `00-PLAN.md:191`.
Mutation authority: yes, only for eligible worker panes at `00-PLAN.md:192`.
Preferred executor: `ntm --robot-restart-pane` at `00-PLAN.md:193`.
Fallback executor: `ntm respawn` at `00-PLAN.md:194`.
Override verdict: pass on notify-only; high finding on fallback gate.
Reason: W4 is the override's act path.
Problem: fallback line cites only W0/W2/W6, dropping W3/W8/L60 from the local executor condition.
Required r2 change: fallback executor must require full W0-W3/W6/W8/L60 and live source truth.

W5 check:
Primitive: Receipt / Learning Loop.
Lines: `00-PLAN.md:206-250`.
Action disposition: receipt emission.
Required every path: recovery or no-action receipt at `00-PLAN.md:211`.
Override verdict: pass.
Reason: W5 records action and refusal; it does not choose notify-only.
Required r2 change: add explicit prompt provenance field.

W6 check:
Primitive: Backoff / Storm Control.
Lines: `00-PLAN.md:252-266`.
Action disposition: suppression gate.
Notify-only statement: fallback for over-budget, repeated, rate-limit, and quota at `00-PLAN.md:255`.
Rate-limit never respawns at `00-PLAN.md:261-262`.
Quota never respawns at `00-PLAN.md:263`.
Override verdict: pass.
Reason: W6 suppresses repeated unsafe action; it does not make initial eligible FROZEN worker panes notify-only.
Required r2 change: none for override.

W7 check:
Primitive: Escalation And Notify-Fast.
Lines: `00-PLAN.md:268-282`.
Action disposition: notify-only fallback and escalation only at `00-PLAN.md:271`.
Notify-fast applies when FROZEN but eligibility refuses mutation at `00-PLAN.md:273`.
Notify-fast applies when protected session needs recovery without encoded permit at `00-PLAN.md:274`.
Reason line says eligible FROZEN worker panes take auto-respawn once gates pass at `00-PLAN.md:281`.
Override verdict: pass.
Reason: W7 is correctly a refusal branch.
Required r2 change: clarify protected-worker exclusion versus peer-orch permit exception.

W8 check:
Primitive: Watcher Governance Loop.
Lines: `00-PLAN.md:284-328`.
Action disposition: authority governor.
Notify-only statement: only when W8 demotes or refuses apply authority at `00-PLAN.md:287`.
Initial state: observe at `00-PLAN.md:297`.
Forbidden transitions: `00-PLAN.md:298-300`.
Authority rises with evidence at `00-PLAN.md:301-308`.
Authority falls with bad evidence at `00-PLAN.md:309-317`.
Override verdict: pass.
Reason: W8 controls whether auto-respawn authority may exist; it does not demote eligible FROZEN worker panes to notify-only unless authority is invalid.
Required r2 change: schema lock before source edit.

Section-level check:
Section 6 says Joshua override rejects notify-only as primary at `00-PLAN.md:423`.
Section 6 says auto-respawn is primary live behavior after gates pass at `00-PLAN.md:424`.
Section 6 says notify-only is fallback only at `00-PLAN.md:425`.
Section 6 says notify-only does not apply to an eligible FROZEN worker pane after the action gate is open at `00-PLAN.md:427`.
Section 6 says final decision is auto-respawn, with notify-only as safety fallback at `00-PLAN.md:438`.
Override verdict: pass.

Appendix check:
Appendix C says the only meaningful conflict was notify-only versus auto-respawn at `00-PLAN.md:861`.
Appendix C says Joshua override resolves it at `00-PLAN.md:862`.
Appendix C says notify-only is only a permanent fallback/refusal branch at `00-PLAN.md:863`.
Appendix C says act-and-respawn is available only in W4 and only for eligible worker panes at `00-PLAN.md:864`.
Override verdict: pass.

Finding H-01 detail:
Title: fallback executor drops required gates.
Severity: high.
Evidence: W4 global gate list at `00-PLAN.md:191`.
Evidence: fallback executor narrowed gate list at `00-PLAN.md:194`.
Risk: an implementation bead can treat fallback `ntm respawn` as requiring W0/W2/W6 only.
Impact: W3 action threshold, W8 authority, and L60 no-silent-darkness could be bypassed in fallback.
Why high: fallback paths are where safety bypasses usually happen.
Why not critical: W4's first line states the full gate set, so the plan has an internal correct source.
Required revision: replace fallback sentence with full gate list and a fresh-truth recheck.
Suggested wording: "Fallback executor: `ntm respawn SESSION --panes=PANE --force`, only if robot restart-pane fails and W0-W3, W6, W8, L60, live capture provenance, and source health still pass in a fresh pre-fallback check."

Finding H-02 detail:
Title: protected sessions are denied generically but not explicitly excluded.
Severity: high.
Evidence: W0 requires `protected_session=false` at `00-PLAN.md:137`.
Evidence: W2 says protected session default deny at `00-PLAN.md:170`.
Evidence: success criteria allow protected auto apply count to be nonzero with encoded permit at `00-PLAN.md:560`.
Evidence: out of scope excludes protected client-session auto-recovery at `00-PLAN.md:609`.
Evidence: constraints say protected sessions default deny at `00-PLAN.md:623`.
Missing: no explicit names `alpsinsurance`, `picoz`, or `skillos` appear in the plan.
Source contrast: `peer-orch-respawn-permit.sh` has a protected fallback list including alpsinsurance, picoz, and skillos at `.flywheel/scripts/peer-orch-respawn-permit.sh:103-108`.
Source nuance: the same permit gate has a skillos peer-orch exception at `.flywheel/scripts/peer-orch-respawn-permit.sh:213-215`.
Risk: implementers may conflate worker watchdog authority with peer-orch permit authority.
Impact: protected sessions could be treated as "permitted if encoded" in the worker watchdog path.
Why high: the dispatch specifically requires explicit exclusion.
Why not critical: generic default-deny appears in multiple places.
Required revision: add a named exclusion list for worker auto-respawn.
Suggested wording: "Worker watchdog auto-respawn explicitly excludes protected sessions: alpsinsurance, picoz, skillos, pane 0, human panes, callback panes, and flywheel self-orchestrator. Any skillos peer-orch recovery remains separate L115 permit-gate work and is not worker watchdog apply."

---

## 3. Watcher_governance_loop Structural Verification

Audit question:
Is watcher_governance_loop structural, or merely a paragraph?
Answer: structural enough for r1, partial until schema is locked.
Status: partial.

Structural evidence 1:
The plan names the watcher as a subsystem with authority at `00-PLAN.md:99-107`.
It says the watcher can drift, fail, or become its own freeze risk at `00-PLAN.md:103-105`.
It says watcher health is a first-class stock at `00-PLAN.md:106`.
It lists driver freshness, last fire time, last exit, false recovery count, unknown recovery count, permit refusals, rollback proof, and manager-loop consumption at `00-PLAN.md:107`.
This is not pure aspiration.

Structural evidence 2:
The plan promotes W8 as a new primitive at `00-PLAN.md:116-118`.
It defines W8 purpose as "who watches the watchdog" at `00-PLAN.md:289`.
It defines authority states at `00-PLAN.md:290-296`.
It defines initial state observe at `00-PLAN.md:297`.
It forbids direct disabled-to-worker-apply at `00-PLAN.md:298`.
It forbids observe-to-peer-orch-apply at `00-PLAN.md:299`.
It forbids canary-to-worker-apply without zero false positives and manager-loop consumption at `00-PLAN.md:300`.
These are rules, not vibes.

Structural evidence 3:
The plan defines authority-rise conditions at `00-PLAN.md:301-308`.
The conditions include clean dry-run cycles, successful canary apply, zero false positives, zero unknown recoveries, driver proof, rollback proof, and manager-loop consumption.
This creates a promotion loop.

Structural evidence 4:
The plan defines authority-fall conditions at `00-PLAN.md:309-317`.
The conditions include false recovery, unknown recovery, degraded-truth apply, stale driver, missing receipt, budget exhaustion, stale last fire, and manager-loop inability to consume summary.
This creates a demotion loop.

Structural evidence 5:
The plan defines self-health fields at `00-PLAN.md:318-326`.
Fields include watchdog_last_fire_ts, watchdog_driver_verified, last exit status, apply enabled, authority state, false recovery count, unknown recovery count, and marker-only count.
Those fields are machine-shape candidates.

Structural evidence 6:
The Donella section names W8 as watcher_governance_loop at `00-PLAN.md:399-404`.
It says W8 authorizes, holds, or demotes the watcher at `00-PLAN.md:404`.
That directly addresses Donella D03.

Structural evidence 7:
Success criteria require watchdog_last_fire_ts to be <= 2 cadence windows old at `00-PLAN.md:564`.
They require watchdog_driver_verified before apply at `00-PLAN.md:565`.
They require explicit watchdog_authority_state at `00-PLAN.md:566`.
They require manager-loop consumption before worker expansion at `00-PLAN.md:567`.
This ties W8 to rollout.

Structural evidence 8:
Ship order requires W0 and W8 schemas at `00-PLAN.md:671-672`.
Ship order requires rollback proof at `00-PLAN.md:673-674`.
Ship order requires manager-loop dry-run summary at `00-PLAN.md:677-678`.
Ship order requires exposing budget, false-positive, unknown, protected, and authority metrics at `00-PLAN.md:689-690`.
This creates implementation staging.

Structural evidence 9:
Verdict thresholds classify W8 prose-without-schema as yellow at `00-PLAN.md:726`.
They classify watchdog apply without W8 authority state as red at `00-PLAN.md:748`.
This is an enforcement posture.

Socraticode corroboration:
L57 says loop state markers are not drivers.
Search surfaced `AGENTS.md:451-550` and templates with driver proof requirements.
L117 says peer orchestrator freeze monitor is a driver and requires monitor last fire, mttr, false recovery, permit refusals, recoveries, and monitor_alive.
Search surfaced `AGENTS.md:3151-3250`.
These local rules align with W8.

Skill corroboration:
Donella anti-pattern "Grand-Reframe Without Instrumentation" forbids paradigm shifts without a measurement loop.
W8 provides measurement fields.
Donella anti-pattern "Reminder Substitution" pushes validators and probes instead of prose.
W8 still needs the schema/validator to fully clear that anti-pattern.

Finding M-02 detail:
Title: W8 structural model lacks concrete schema before r2.
Severity: medium.
Evidence: W8 field list at `00-PLAN.md:318-326`.
Evidence: open question asks whether W8 needs concrete schema before implementation at `00-PLAN.md:651-652`.
Evidence: Phase 0.3 defers schema definition at `00-PLAN.md:671-672`.
Risk: implementation beads could each invent a different authority row.
Impact: manager-loop and watchdog could disagree about authority state.
Why medium: the plan explicitly requires schema before source edits.
Required r2 revision: add W8 schema name, required fields, allowed enum transitions, and validator command.
Recommended schema name: `watchdog-authority-state/v1`.
Recommended validator command: `.flywheel/scripts/frozen-pane-detector-fleet.sh validate authority --json` or a clearly named equivalent in the later implementation plan.
Recommended invariant: no apply branch reads env-only authority; it must read a validated state row.

Watcher_governance_loop conclusion:
The loop is real in plan structure.
It is not yet fully machine-checkable.
It should continue r1 for schema lock.
It should not block the overall architecture.

---

## 4. Truly-Dead Detection Criteria Audit

Audit question:
Are truly-dead detection criteria mechanical rather than heuristic?
Answer: partially.
The source substrate is mechanical.
The final plan should carry more of that mechanical detail.
Status: partial.

Plan positive evidence:
W0 requires healthy source health at `00-PLAN.md:127`.
W0 requires L60 5/5 at `00-PLAN.md:128`.
W0 requires live capture provenance at `00-PLAN.md:129`.
W0 requires fresh capture timestamp at `00-PLAN.md:130`.
W0 requires two robot-tail samples at `00-PLAN.md:131`.
W0 requires class_candidate=FROZEN at `00-PLAN.md:140`.
W1 allows only FROZEN action at `00-PLAN.md:152`.
W1 separates WATCH, UNKNOWN, template prompts, post-completion buffer, queued-not-submitted, rate-limit, quota, and degraded truth at `00-PLAN.md:153`.
W1 requires healthy source, live capture provenance, fresh timestamp, and two samples at `00-PLAN.md:154`.
W1 says W1 cannot mutate without W0, W2, W3, W6, and W8 at `00-PLAN.md:156`.
Constraints block UNKNOWN at `00-PLAN.md:633`.
Constraints block WATCH at `00-PLAN.md:634`.
Constraints block template prompt at `00-PLAN.md:635`.
Constraints block post-completion buffer at `00-PLAN.md:636`.
Constraints route queued-not-submitted to its own non-respawn branch at `00-PLAN.md:637`.
Constraints block rate-limit at `00-PLAN.md:638`.
Constraints block quota at `00-PLAN.md:639`.
Red thresholds repeat these exclusions at `00-PLAN.md:734-742`.

Source positive evidence:
Detector default threshold is 90 seconds at `.flywheel/scripts/frozen-pane-detector.sh:25`.
Queued threshold is 60 seconds at `.flywheel/scripts/frozen-pane-detector.sh:26`.
Queued timer drift is 60 seconds at `.flywheel/scripts/frozen-pane-detector.sh:27`.
Minimum live delta is 100 bytes at `.flywheel/scripts/frozen-pane-detector.sh:28`.
Sample interval is 1 second at `.flywheel/scripts/frozen-pane-detector.sh:29`.
The detector exposes these as options at `.flywheel/scripts/frozen-pane-detector.sh:81-86`.
The detector recognizes queued-not-submitted with WAITING or waiting_background plus codex chevron, queued prompt, age threshold, low live delta, and timer drift at `.flywheel/scripts/frozen-pane-detector.sh:1160-1163`.
The detector separates template stubs at `.flywheel/scripts/frozen-pane-detector.sh:1166-1171`.
The detector marks timer-text-identical plus low delta as FROZEN at `.flywheel/scripts/frozen-pane-detector.sh:1172-1175`.
The detector marks age greater than threshold plus low live delta as FROZEN at `.flywheel/scripts/frozen-pane-detector.sh:1204-1207`.
The detector emits samples, delta bytes, cache delta, status, verdict, reason, sample timestamps, and sample pair directory at `.flywheel/scripts/frozen-pane-detector.sh:1216-1249`.
The detector writes sample pairs at `.flywheel/scripts/frozen-pane-detector.sh:158-168`.
The detector dry-run lists planned actions without mutation at `.flywheel/scripts/frozen-pane-detector.sh:759-766`.

Research positive evidence:
The original baseline plan included min delta and sample interval detail from research at `00-PLAN-INPUT.md:149-155`.
The final plan compressed that detail.
Compression is acceptable in a narrative plan, but risky before bead decomposition.

Heuristic-language search:
Search for `seems` in `00-PLAN.md` found no vague "seems frozen" action language.
Search for `appears` found no action predicate using "appears frozen."
Search for `if it seems frozen` found none.
The problem is omission of numeric predicate details, not vague language.

Finding M-01 detail:
Title: final plan does not carry enough mechanical FROZEN predicate detail.
Severity: medium.
Evidence: W0 two samples and FROZEN candidate at `00-PLAN.md:131-140`.
Evidence: W1 live truth and two samples at `00-PLAN.md:151-156`.
Evidence: W3 90s detect/log and 5m act at `00-PLAN.md:182-184`.
Missing in final plan: `min_delta_bytes=100`.
Missing in final plan: sample interval seconds.
Missing in final plan: timer-text-identical two-sample branch.
Missing in final plan: age_gt_threshold_and_live_delta_lt_min branch.
Missing in final plan: required recorded reason values for FROZEN.
Why medium: the detector source has the mechanical criteria, but implementers should not need to rediscover them.
Required revision: add a "Mechanical FROZEN predicate" subsection under W1 or W3.
Suggested fields:
`sample_count=2`.
`sample_interval_seconds=1`.
`min_delta_bytes=100`.
`detect_threshold_seconds=90`.
`act_threshold_seconds=300 for first canary`.
`allowed_frozen_reasons=["timer-text-identical-2-samples","age_gt_threshold_and_live_delta_lt_min"]`.
`blocked_reasons=["robot_tail_first_sample_failed","robot_tail_second_sample_failed","state_since_untrusted_no_scrollback_delta","template_stub_prompt_detected","queued_prompt_not_submitted","post_respawn_residue_without_new_truth"]`.
`capture_provenance="live"`.
`capture_collected_at_fresh=true`.
`source_health="healthy"`.
`L60_signals_present=5/5`.

Truly-dead conclusion:
The plan is mechanically grounded.
The source is strong.
The final artifact should be patched so r2 workers inherit exact predicates.

---

## 5. Permit-Gate Default-Deny Verification

Audit question:
Are protected sessions excluded, and are alpsinsurance, picoz, and skillos explicitly excluded?
Answer: partial.

Plan positive evidence:
W0 requires target_kind=worker at `00-PLAN.md:132`.
W0 requires target_not_pane0 at `00-PLAN.md:133`.
W0 requires target_not_human at `00-PLAN.md:134`.
W0 requires target_not_callback at `00-PLAN.md:135`.
W0 requires target_not_self_orchestrator at `00-PLAN.md:136`.
W0 requires protected_session=false at `00-PLAN.md:137`.
W2 says worker pane is eligible only after W0 and W1 pass at `00-PLAN.md:165`.
W2 denies pane 0 at `00-PLAN.md:166`.
W2 denies human pane at `00-PLAN.md:167`.
W2 denies callback pane at `00-PLAN.md:168`.
W2 denies self-orchestrator at `00-PLAN.md:169`.
W2 denies protected session at `00-PLAN.md:170`.
W2 routes peer-orch separately at `00-PLAN.md:171-172`.
The plan keeps protected sessions default-deny at `00-PLAN.md:422`.
Success criteria require protected session auto apply count zero unless encoded permit exists at `00-PLAN.md:560`.
Out-of-scope excludes protected client-session auto-recovery at `00-PLAN.md:609`.
Constraints say protected sessions default deny at `00-PLAN.md:623`.
Red thresholds fail apply touching protected session without encoded permit at `00-PLAN.md:732`.

Source positive evidence:
The peer-orch permit gate extracts protected sessions from kill-recover-drill or falls back to alpsinsurance, picoz, and skillos at `.flywheel/scripts/peer-orch-respawn-permit.sh:103-108`.
The peer-orch permit gate refuses protected sessions unless the target is skillos at `.flywheel/scripts/peer-orch-respawn-permit.sh:213-215`.
The peer-orch permit gate separately refuses human and callback panes at `.flywheel/scripts/peer-orch-respawn-permit.sh:209-212`.
The peer-orch permit gate refuses self-orch recovery at `.flywheel/scripts/peer-orch-respawn-permit.sh:207-208`.
This is a separate peer-orch track, not worker auto-respawn.

Gap:
The final plan does not contain the literal strings `alpsinsurance`, `picoz`, or `skillos`.
The dispatch explicitly required those names.
The plan's generic protected-session language is strong but not enough for this audit.
The success criterion "unless explicit encoded permit exists" is too broad when read in the worker watchdog context.
It should split worker protected auto-apply from peer-orch permit apply.

Required revision:
Add named protected-session exclusion under W0 or W2.
Add a metric split:
`worker_protected_session_auto_apply_count=0`.
`peer_orch_permit_apply_count` is separate.
`skillos_peer_orch_exception_count` is separate if L115 permits it.
Add a red threshold:
`worker watchdog apply can touch alpsinsurance/picoz/skillos`.
Add an out-of-scope line:
`worker watchdog auto-respawn for alpsinsurance, picoz, and skillos`.

Permit conclusion:
Default-deny exists.
Explicit exclusion does not.
Status is partial until names and metric split land.

---

## 6. Cross-Plan Layering Verification

Audit question:
Does watchdog remain substrate-layer without conflicting with manager-loop, fleet-autonomy, or mission-coverage?
Answer: yes.

Layer evidence:
Section 8 says watchdog is substrate-layer at `00-PLAN.md:503`.
It says watchdog sits below manager-loop, fleet-autonomy, and mission-coverage at `00-PLAN.md:504`.
It says watchdog does not choose mission work at `00-PLAN.md:505`.
It says watchdog keeps worker capacity alive and safe so mission work can continue at `00-PLAN.md:506`.
It says manager-loop consumes watchdog receipts and governance state at `00-PLAN.md:507`.
It says fleet-autonomy consumes recovery SLO and storm-control state at `00-PLAN.md:508`.
It says mission-coverage consumes capacity indirectly by proving completed work maps to mission outcomes at `00-PLAN.md:509`.
It lists shared vocabulary at `00-PLAN.md:510-520`.
It says watchdog ships before broad manager-loop apply at `00-PLAN.md:521`.
It says watchdog ships before fleet-autonomy assumes continuous dispatch capacity at `00-PLAN.md:522`.
It says watchdog receipts become manager-loop summaries, not pane-message flood at `00-PLAN.md:523`.
It keeps peer-orch recovery separate at `00-PLAN.md:524`.
It defines ordering at `00-PLAN.md:525-529`.

No manager-loop conflict:
The plan gives manager-loop a consumer role.
It does not let watchdog choose next mission action.
It does not replace manager-loop escalation.
It does not add new manager-loop implementation logic, which is out of scope at `00-PLAN.md:611`.

No fleet-autonomy conflict:
The plan gives fleet-autonomy recovery SLO and storm-control state.
It does not let watchdog choose fleet work.
It does not bypass fleet-autonomy's mission or capacity frame.
It strengthens fleet-autonomy by preventing false assumptions about continuous dispatch capacity.

No mission-coverage conflict:
The plan gives mission-coverage capacity but no mission scoring.
It does not change mission surface definitions.
It does not modify mission-coverage logic, which is out of scope at `00-PLAN.md:612`.

Cross-plan issue:
No high or medium conflict found.
Low L-02 remains: manager-loop summary path/cadence/schema should be locked before implementation.

Cross-plan conclusion:
Layering is clean.
Status: yes.

---

## 7. Blunder-Hunt 12-Class Checklist

Checklist class 01: Objective mismatch.
Result: pass.
Evidence: plan goal is no silent darkness and worker recovery SLO at `00-PLAN.md:97`.
Evidence: success criteria include manual_respawn_count_7d, MTTR, success rate, false positives, unknown recoveries, protected apply count, receipts, and L60 at `00-PLAN.md:554-573`.
Finding: none.

Checklist class 02: Hidden reversal of Joshua override.
Result: pass.
Evidence: auto-respawn is primary at `00-PLAN.md:21-22`.
Evidence: notify-only fallback only at `00-PLAN.md:423-438`.
Evidence: Appendix C resolves notify-only versus auto-respawn at `00-PLAN.md:861-864`.
Finding: none.

Checklist class 03: Missing gate or bypass path.
Result: fail-high.
Finding: H-01.
Evidence: full W4 gate at `00-PLAN.md:191`.
Evidence: fallback executor line omits W3/W8/L60 at `00-PLAN.md:194`.
Required action: patch fallback executor gate language.

Checklist class 04: Wrong default.
Result: partial.
Evidence: initial W8 state is observe at `00-PLAN.md:297`.
Evidence: protected sessions default deny at `00-PLAN.md:623`.
Evidence: fleet wrapper is disabled/default observe in current source at `.flywheel/scripts/frozen-pane-detector-fleet.sh:58`.
Finding: H-02 due explicit protected session names missing and metric loophole.

Checklist class 05: Detection ambiguity.
Result: partial.
Evidence: plan separates FROZEN, WATCH, UNKNOWN, template, queued, rate-limit, quota, and degraded truth at `00-PLAN.md:153`.
Evidence: constraints block non-FROZEN classes at `00-PLAN.md:633-639`.
Finding: M-01 because numeric predicate details are compressed out of final plan.

Checklist class 06: Race, storm, or repeated action.
Result: pass.
Evidence: W6 allows first respawn per pane per hour only at `00-PLAN.md:258`.
Evidence: second same-pane respawn escalates at `00-PLAN.md:259`.
Evidence: global cap is four respawns per session per hour at `00-PLAN.md:260`.
Evidence: red threshold catches second same-pane respawn without escalation at `00-PLAN.md:745`.
Finding: none.

Checklist class 07: Idempotency and lease safety.
Result: pass with no new finding.
Evidence: W4 transaction includes lease at `00-PLAN.md:197`.
Evidence: W5 receipt fields include idempotency key at `00-PLAN.md:219`.
Evidence: detector source computes idempotency from content hash at `.flywheel/scripts/frozen-pane-detector.sh:745-749`.
Evidence: detector source acquires and releases recovery lease at `.flywheel/scripts/frozen-pane-detector.sh:769-804`.
Finding: none.

Checklist class 08: Receipt and observability gap.
Result: pass-low.
Evidence: W5 requires recovery or no-action receipt at `00-PLAN.md:211`.
Evidence: W5 no-action fields are listed at `00-PLAN.md:229-237`.
Evidence: manager-loop fields are listed at `00-PLAN.md:238-248`.
Finding: L-01 and L-02.

Checklist class 09: Rollback and reversibility.
Result: pass.
Evidence: W8 authority rises with rollback proof at `00-PLAN.md:307`.
Evidence: success criteria require rollback_probe_passed at `00-PLAN.md:568`.
Evidence: Phase 0.4 proves rollback with STOP file and LaunchAgent disable/unload at `00-PLAN.md:673-674`.
Evidence: red thresholds fail apply without W8 authority state at `00-PLAN.md:748`.
Finding: none.

Checklist class 10: Protected or destructive target safety.
Result: fail-high.
Finding: H-02.
Evidence: generic default-deny is present at `00-PLAN.md:137`, `00-PLAN.md:170`, and `00-PLAN.md:623`.
Evidence: explicit target names are absent.
Evidence: success criteria allow protected auto-apply with encoded permit at `00-PLAN.md:560`.
Required action: name alpsinsurance, picoz, skillos and split worker versus peer-orch metrics.

Checklist class 11: Schema and machine-checkability.
Result: partial.
Finding: M-02.
Evidence: W8 fields exist at `00-PLAN.md:318-326`.
Evidence: W8 schema is still an audit question at `00-PLAN.md:651-652`.
Evidence: Phase 0.3 promises schema later at `00-PLAN.md:671-672`.
Required action: lock schema before implementation.

Checklist class 12: Canary and acceptance evidence.
Result: pass.
Evidence: W3 requires 24h dry-run, 20 clean cycles, one canary, zero false positives, zero unknown recoveries, and rollback proof before threshold tightening at `00-PLAN.md:183`.
Evidence: success criteria require 20 dry-run cycles and rollback proof at `00-PLAN.md:708-714`.
Evidence: ship order has 24h dry-run, manager-loop summary, zero degraded-truth apply, one worker canary, and rollback after canary at `00-PLAN.md:675-688`.
Finding: none.

Checklist conclusion:
The plan passes the strategic audit.
The plan fails two concrete safety details that are fixable without replan.
The plan should continue r1.

---

## 8. Convergence Call

Convergence verdict: continue-r1.
Reason: the plan is close, but r2 implementation should not inherit the high findings.
Composite after audit: 9.6.
Expected composite after small patch: 9.8.

Required patch set before r2:
Patch 1: fix W4 fallback executor gate language.
Patch 2: add named protected-session exclusions for alpsinsurance, picoz, and skillos in worker watchdog scope.
Patch 3: split protected worker metrics from peer-orch permit metrics.
Patch 4: add mechanical FROZEN predicate fields from the existing detector.
Patch 5: add W8 schema name and required fields or promote Phase 0.3 to a hard pre-implementation gate.
Patch 6: add prompt provenance source and manager-loop summary path/cadence to receipt contract.

No Joshua question needed.
No source edit needed in this audit.
No bead write needed in this audit.
No ntm source churn needed.
No Codex upgrade dependency.
No second detector.
No new respawner.

Final judgment on Joshua override:
The override holds structurally.
Auto-respawn remains primary for eligible FROZEN worker panes.
Notify-only remains fallback/refusal only.
The audit found no notify-only creep.

Final judgment on watcher_governance_loop:
The loop is structural, not merely aspirational.
It has authority states, promotion signals, demotion signals, self-health fields, success criteria, and ship order.
It needs schema lock before source edits.

Final judgment on truly-dead detection:
Detector source is mechanical.
Plan prose should carry the exact constants and reason values.

Final judgment on permit gate:
Default-deny is present.
Explicit protected-session names are missing.
Worker watchdog and peer-orch permit metrics need a cleaner split.

Final judgment on cross-plan layering:
Clean.
Watchdog stays substrate-layer.
Manager-loop consumes.
Fleet-autonomy consumes SLO/storm state.
Mission-coverage consumes capacity indirectly.

Audit closeout:
Verdict: continue-r1.
New critical: 0.
New high: 2.
New medium: 2.
New low: 2.
Total findings: 6.
Self-grade: A.
Composite: 9.6.
