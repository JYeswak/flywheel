# Doctrine Forward-Flow Proposal - 2026-05-06

Task: `doctrine-forward-flow-proposal-2026-05-06`
Source report: `.flywheel/reports/canonical-doctrine-drift-2026-05-06.md`
Status: research_complete_blocked_on_joshua_decision

## A. Source data - 36 additive_local lines

All source lines are from `.flywheel/AGENTS-CANONICAL.md`:

01 L11: `Fleet propagation cross-link: `.flywheel/scripts/agents-md-fleet-propagator.sh``
02 L12: `audits installed-repo AGENTS.md drift, and `flywheel-loop doctor --scope`
03 L13: `agents-md-fleet-propagation --json` exposes the drift count, drift repos, and`
04 L14: `last propagation apply health.`
05 L15: ``
06 L1157: `**Counter cross-link:** `.flywheel/scripts/l70-ticks-punted-counter.sh` writes`
07 L1158: ``~/.local/state/flywheel/l70-ticks-punted.jsonl`; `flywheel-loop doctor --scope`
08 L1159: `l70-ticks-punted --json` exposes `l70_ticks_punted_24h`,`
09 L1160: ``l70_ticks_punted_rate_pct`, and `l70_ticks_punted_top_signal`.`
10 L1161: ``.flywheel/scripts/tick-hook-firing-verifier.sh` audits L70 and sibling`
11 L1162: `tick-close hooks with ledger-backed firing evidence; `flywheel-loop doctor`
12 L1163: `--scope tick-hook-firing --json` exposes `tick_hook_primitives_audited`,`
13 L1164: ``tick_hook_primitives_firing`, `tick_hook_primitives_invisibly_broken`, and`
14 L1165: ``tick_hook_primitives_invisibly_broken_names`.`
15 L1166: ``
16 L3129: `- Validator path: `.flywheel/scripts/callback-envelope-schema-validator.sh`;`
17 L3130: `  scoped doctor:`
18 L3131: `  `flywheel-loop doctor --repo <repo> --scope callback-envelope-schema --json`.`
19 L3244: `**Cross-references:** L48 (substrate exhaustion), L57 (loop state marker is not`
20 L3245: `a driver), L70 (same-tick chain-forward), L75 (peer-orch blocker`
21 L3246: `coordination), L80 (DID/DIDNT/GAPS callbacks), L82 (canonical CLI scoping),`
22 L3247: `L101 (continuous fleet productivity), L107 (shared-surface reservations), and`
23 L3248: `L110 (substrate primitives declare self-repair loop).`
24 L3307: `Status is `error` when the daemon is not loaded, when the latest fire is older`
25 L3308: `than two intervals, or when the normalized fire rate is below 50%. Status is`
26 L3309: ``warn` when the normalized fire rate is below 80%.`
27 L3326: `**Cross-references:** L57 (loop-state marker is not driver), L70 (same-tick`
28 L3327: `chain-forward), L102 (META-RULE cache refresh on tick), L110 (substrate`
29 L3328: `self-repair primitive), L111 (quality bar), L115 (peer-orch recovery), and`
30 L3329: `pbt55 `tick-hook-firing-verifier.sh`.`
31 L3362: `Status is `fail` when false recoveries are nonzero, `warn` when the monitor is`
32 L3363: `missing or stale, and `pass` only when recent monitor fire evidence exists.`
33 L3364: ``
34 L3378: `**Cross-references:** L57 (loop-state marker is not driver), L110 (substrate`
35 L3379: `self-repair primitive), L111 (quality bar), L115 (peer-orch recovery), L116`
36 L3380: `(tick is process), and pbt55 `tick-hook-firing-verifier.sh`.`

## B. Per-line forward-flow decision matrix

Line 01: source `.flywheel/AGENTS-CANONICAL.md:11`; topic fleet propagation pointer; origin `flywheel-doctrine-drift-propagation-19-of-291-2026-05-06`; decision PROMOTE; target `~/.claude/skills/.flywheel/bin/flywheel-doctrine-sync.README.md`. Reasoning: this makes the fleet propagation audit path discoverable from the upstream sync docs. It is not flywheel-repo-only because every installed repo depends on the same propagation signal. Donella: #6 information flows.
Line 02: source `:12`; topic doctor scope for fleet propagation; origin same; decision PROMOTE; target same. Reasoning: the doctor invocation is the machine path for the information flow. Upstream docs should teach operators to query the same signal instead of local grep. Donella: #6 information flows.
Line 03: source `:13`; topic exposed drift fields; origin same; decision PROMOTE; target same. Reasoning: field names are operational contract, not commentary. Promoting them lets peer sessions consume the signal consistently. Donella: #5 rules plus #6 information flows.
Line 04: source `:14`; topic apply-health field; origin same; decision PROMOTE; target same. Reasoning: apply health is the feedback loop that prevents silent drift accumulation. It belongs with doctrine sync upstream docs. Donella: #8 negative feedback loop strength.
Line 05: source `:15`; topic paragraph boundary; origin same; decision PROMOTE; target same. Reasoning: promote only as part of the five-line paragraph so the target diff remains readable. No standalone semantic weight. Donella: other/readability.
Line 06: source `:1157`; topic L70 counter script; origin `flywheel-7lby` plus tick-hook verifier work; decision PROMOTE; target `~/.claude/skills/.flywheel/LOOP.md`. Reasoning: L70 no-punt is loop behavior, and the counter is the upstream loop contract's measurement path. Keeping it local hides the outflow from sibling sessions. Donella: #6 information flows.
Line 07: source `:1158`; topic L70 ledger path; origin same; decision PROMOTE; target same. Reasoning: the ledger is the stock history for punted ticks. Upstream loop docs need the durable path for audit and repair. Donella: #6 information flows.
Line 08: source `:1159`; topic scoped doctor command; origin same; decision PROMOTE; target same. Reasoning: this is the consumer query, not prose. It lets operators and workers verify the stock without knowing the implementation. Donella: #6 information flows.
Line 09: source `:1160`; topic L70 rate fields; origin same; decision PROMOTE; target same. Reasoning: field names are a routing contract for status and close gates. Promoting prevents schema rediscovery in each repo. Donella: #5 rules.
Line 10: source `:1161`; topic tick-hook verifier script; origin pbt55/tick-hook firing verifier; decision PROMOTE; target same. Reasoning: this closes the "script exists but never fires" class at loop level. It generalizes beyond flywheel. Donella: #8 feedback loop strength.
Line 11: source `:1162`; topic ledger-backed firing evidence; origin same; decision PROMOTE; target same. Reasoning: evidence source is the important distinction from prose-only tick hooks. Upstream should carry that test of reality. Donella: #6 information flows.
Line 12: source `:1163`; topic tick-hook doctor scope; origin same; decision PROMOTE; target same. Reasoning: the doctor scope is the canonical query for invisible hook breakage. Promote with the adjacent field names. Donella: #6 information flows.
Line 13: source `:1164`; topic tick-hook firing fields; origin same; decision PROMOTE; target same. Reasoning: these fields are the machine contract for firing evidence. They should not remain hidden in a local snapshot. Donella: #5 rules.
Line 14: source `:1165`; topic invisibly broken names field; origin same; decision PROMOTE; target same. Reasoning: naming broken primitives is the repair route. Promote to upstream loop docs. Donella: #6 information flows.
Line 15: source `:1166`; topic paragraph boundary; origin same; decision PROMOTE; target same. Reasoning: retain as part of the L70 counter paragraph. It carries no separate rule. Donella: other/readability.
Line 16: source `:3129`; topic callback envelope validator path; origin `flywheel-g4zy`/L111 callback envelope gate; decision PROMOTE; target `~/.claude/skills/.flywheel/LOOP.md`. Reasoning: validator path is the executable surface for the quality callback contract. Upstream loop docs should point at the gate. Donella: #5 rules.
Line 17: source `:3130`; topic scoped doctor label; origin same; decision PROMOTE; target same. Reasoning: the label joins the validator to a status query. It is small but needed for discoverability. Donella: #6 information flows.
Line 18: source `:3131`; topic callback-envelope-schema doctor command; origin same; decision PROMOTE; target same. Reasoning: this is the reusable verification command for all repos. Promote because it is an upstream operator contract. Donella: #6 information flows.
Line 19: source `:3244`; topic L115 descriptive crossrefs; origin canonical doctrine drift local snapshot; decision KEEP_LOCAL. Reasoning: the root source already carries the same cross-reference IDs, and this line only expands names. Promote only if Joshua chooses a style-normalization batch. Donella: other/readability.
Line 20: source `:3245`; topic L115 descriptive crossrefs; origin same; decision KEEP_LOCAL. Reasoning: descriptive wrapping improves local readability but does not add a new routing signal. It is an anti-keeplocal candidate if style clarity becomes the goal. Donella: other/readability.
Line 21: source `:3246`; topic L115 descriptive crossrefs; origin same; decision KEEP_LOCAL. Reasoning: IDs already route to the relevant rules. The added names are useful but not urgent upstream skill-source material. Donella: other/readability.
Line 22: source `:3247`; topic L115 descriptive crossrefs; origin same; decision KEEP_LOCAL. Reasoning: this line expands labels without changing the recovery permit contract. Keep local until a three-surface wording pass is approved. Donella: other/readability.
Line 23: source `:3248`; topic L115 descriptive crossrefs; origin same; decision KEEP_LOCAL. Reasoning: same as above; it is readability, not a missing information flow. Mark for optional style batch. Donella: other/readability.
Line 24: source `:3307`; topic L116 tick-driver error threshold; origin `flywheel-2h6le` tick driver process work; decision PROMOTE; target `~/.claude/skills/.flywheel/LOOP.md`. Reasoning: this adds threshold semantics absent from the compact field list. Upstream loop docs need pass/warn/error criteria, not just field names. Donella: #5 rules.
Line 25: source `:3308`; topic L116 stale/fire-rate thresholds; origin same; decision PROMOTE; target same. Reasoning: the 50% threshold makes driver liveness measurable. It changes routing from judgment to rule. Donella: #5 rules.
Line 26: source `:3309`; topic L116 warning threshold; origin same; decision PROMOTE; target same. Reasoning: the 80% warning threshold creates an early correction loop. Promote with lines 24-25. Donella: #8 feedback loop strength.
Line 27: source `:3326`; topic L116 descriptive crossrefs; origin local snapshot style pass; decision KEEP_LOCAL. Reasoning: the compact root IDs already exist. This is valuable only if canonical style policy prefers named crossrefs. Donella: other/readability.
Line 28: source `:3327`; topic L116 descriptive crossrefs; origin same; decision KEEP_LOCAL. Reasoning: no new executable signal is introduced. Defer to a style batch rather than mix with operational promotion. Donella: other/readability.
Line 29: source `:3328`; topic L116 descriptive crossrefs; origin same; decision KEEP_LOCAL. Reasoning: readability expansion only. It should not block the operational status-threshold promotion. Donella: other/readability.
Line 30: source `:3329`; topic L116 pbt55 descriptive crossref; origin same; decision KEEP_LOCAL. Reasoning: the pbt55 reference is already present upstream in compact form. Keep local until style normalization is approved. Donella: other/readability.
Line 31: source `:3362`; topic L117 monitor fail/warn/pass status; origin `flywheel-3e5c7` peer-orch freeze monitor; decision PROMOTE; target `~/.claude/skills/.flywheel/LOOP.md`. Reasoning: these status rules are operational and generalize across peer sessions. They turn monitor output into a close/status gate. Donella: #5 rules.
Line 32: source `:3363`; topic L117 stale monitor status; origin same; decision PROMOTE; target same. Reasoning: stale monitor evidence is the key hidden-state failure class. Promote to keep peer recovery from relying on pane presence. Donella: #6 information flows.
Line 33: source `:3364`; topic paragraph boundary; origin same; decision PROMOTE; target same. Reasoning: promote as part of the L117 status paragraph only. No independent semantics. Donella: other/readability.
Line 34: source `:3378`; topic L117 descriptive crossrefs; origin local snapshot style pass; decision KEEP_LOCAL. Reasoning: same ID set exists upstream in compact form. Do not promote descriptive style while the approved batch is operational. Donella: other/readability.
Line 35: source `:3379`; topic L117 descriptive crossrefs; origin same; decision KEEP_LOCAL. Reasoning: it names already-linked rules but adds no machine route. Keep local pending style policy. Donella: other/readability.
Line 36: source `:3380`; topic L117 descriptive crossrefs; origin same; decision KEEP_LOCAL. Reasoning: readability-only pbt55 reference expansion. Optional style normalization can revisit. Donella: other/readability.

## C. Aggregate decision counts

- PROMOTE count: 24
- KEEP_LOCAL count: 12
- DEFER count: 0
- Total addressed: 36

## D. PROMOTE batch design

- `~/.claude/skills/.flywheel/bin/flywheel-doctrine-sync.README.md`: lines 01-05.
- `~/.claude/skills/.flywheel/LOOP.md`: lines 06-18, 24-26, 31-33.

## E. KEEP_LOCAL rationale audit

KEEP_LOCAL lines: 19-23, 27-30, 34-36. Every KEEP_LOCAL is a descriptive cross-reference expansion where the upstream/root source already has the same L-rule IDs. None are truly flywheel-tooling-specific; they are "not-yet-generalized style" rather than "must remain local." Anti-keeplocal candidate: if Joshua wants canonical doctrine to prefer named crossrefs over compact IDs, promote all 12 in a separate style-only three-surface pass.

## F. DEFER queue

No line is DEFER. Follow-up bead candidate if desired: `flywheel-canonical-crossref-style-normalization-2026-05-06`, evidence needed = Joshua style decision plus a three-surface diff receipt proving named crossrefs across root, canonical snapshot, and template.

## G. Donella analysis

PROMOTE is dominated by Meadows #6 information flows and #5 rules: the useful lines expose doctor scopes, ledgers, threshold fields, and validator paths to the actors who need to route work. The additive-local pattern says substrate evolution is currently local-first: working rules land in flywheel surfaces, then require a later forward-flow step before the skill source can teach sibling repos. Recommendation: keep local-first experimentation, but add a same-day "forward-flow proposal or explicit no-promote" closeout whenever canonical drift research finds additive operational lines.

## H. Recommended PROMOTE batch + Joshua-decision-needed

Recommended batch: promote the 24 operational lines into the two upstream skill-source docs above, keeping the 12 descriptive cross-reference expansions out of the operational batch. Joshua-decision-needed: true, because this changes upstream skill-source guidance and future repo behavior.

## I. Dry-run forward-flow script

Dry-run artifact: `/tmp/doctrine-forward-flow-dry-run-2026-05-06.sh`. It is print-only and emits proposed grouped diffs for the two target files without writing to either target.
