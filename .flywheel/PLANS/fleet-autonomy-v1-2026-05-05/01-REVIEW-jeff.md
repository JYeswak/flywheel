---
title: "Jeff Review - Fleet Autonomy v1"
type: plan
created: 2026-05-06
frontmatter_source: scaffold-doc-frontmatter
---

## Contents

- [0. Position](#0-position)
- [1. Socraticode Ledger](#1-socraticode-ledger)
- [2. The 5-Line Fix That Should Already Be Deployed](#2-the-5-line-fix-that-should-already-be-deployed)
- [3. Canonical CLI Scoping Audit - Overview](#3-canonical-cli-scoping-audit-overview)
- [4. P1 Audit - Replace Watcher `br ready` With `bv --robot-next`](#4-p1-audit-replace-watcher-br-ready-with-bv-robot-next)
- [5. P2 Audit - Divergent Loop Self-Assert And Cooldown](#5-p2-audit-divergent-loop-self-assert-and-cooldown)
- [6. P3 Audit - `flywheel-loop status`](#6-p3-audit-flywheel-loop-status)
- [7. P4 Audit - Cross-Orchestrator Reservation TTL](#7-p4-audit-cross-orchestrator-reservation-ttl)
- [8. P5 Audit - Pane Freeze Auto-Respawn](#8-p5-audit-pane-freeze-auto-respawn)
- [9. P6 Audit - Repair-Bead Aging](#9-p6-audit-repair-bead-aging)
- [10. M Audit - Morning Ritual Artifact](#10-m-audit-morning-ritual-artifact)
- [11. Substrate Ownership Review](#11-substrate-ownership-review)
- [12. Upstream Issue Draft - `bv --robot-next` Exclusions](#12-upstream-issue-draft-bv-robot-next-exclusions)
- [13. Upstream Issue Draft - `br ready` Status Semantics](#13-upstream-issue-draft-br-ready-status-semantics)
- [14. Upstream Issue Draft - ntm Send Receipt Primitive](#14-upstream-issue-draft-ntm-send-receipt-primitive)
- [15. Working-Sibling Diff](#15-working-sibling-diff)
- [16. Atomic Write And Contract Audit](#16-atomic-write-and-contract-audit)
- [17. Specific Revisions - Git-Diff Style Change 01](#17-specific-revisions-git-diff-style-change-01)
- [18. Specific Revisions - Git-Diff Style Change 02](#18-specific-revisions-git-diff-style-change-02)
- [19. Specific Revisions - Git-Diff Style Change 03](#19-specific-revisions-git-diff-style-change-03)
- [20. Specific Revisions - Git-Diff Style Change 04](#20-specific-revisions-git-diff-style-change-04)
- [21. Specific Revisions - Git-Diff Style Change 05](#21-specific-revisions-git-diff-style-change-05)
- [22. Specific Revisions - Git-Diff Style Change 06](#22-specific-revisions-git-diff-style-change-06)
- [23. Specific Revisions - Git-Diff Style Change 07](#23-specific-revisions-git-diff-style-change-07)
- [24. Specific Revisions - Git-Diff Style Change 08](#24-specific-revisions-git-diff-style-change-08)
- [25. Minimum Viable Cut](#25-minimum-viable-cut)
- [26. Verdict](#26-verdict)
```diff
diff --git a/.flywheel/scripts/idle-state-probe.sh b/.flywheel/scripts/idle-state-probe.sh
@@
-      ready_raw="$(cd "$REPO" && "$br_cli" ready --json 2>"$ready_err")" || ready_rc=$?
+      if command -v bv >/dev/null 2>&1; then
+        ready_raw="$(cd "$REPO" && bv --robot-next 2>"$ready_err" | jq -c 'if .id then [{id:.id,title:.title,priority:0,score:.score,unblocks:.unblocks,selection_source:"bv --robot-next"}] else [] end')" || ready_rc=$?
+      else
+        ready_raw="$(cd "$REPO" && "$br_cli" ready --json 2>"$ready_err")" || ready_rc=$?
+      fi
```

# Jeff Review - Fleet Autonomy v1

## 0. Position

01. Verdict: revise, do not reject.
02. The plan is directionally right about the primary bleed.
03. The plan is too willing to bolt system behavior onto the watcher.
04. The watcher should stop selecting from `br ready --json` immediately.
05. The durable solution should be pushed into canonical robot primitives.
06. `bv --robot-next` is the correct current robot primitive for "one next bead."
07. `br ready --json` is an actionability list, not a graph-aware selector.
08. The live repository proves the mismatch today.
09. `bv --robot-next` selected `flywheel-4m2a`.
10. `bv --robot-next` returned `score=0.33456081980305574`.
11. `bv --robot-next` returned `unblocks=1`.
12. `bv --robot-next` returned claim/show commands.
13. `br ready --json` returned 20 rows.
14. `br ready --json` returned 19 `in_progress` rows and 1 `open` row.
15. A ready command that emits mostly `in_progress` rows is not a safe dispatch source.
16. The current watcher then filters by priority and age.
17. The current watcher ignores PageRank.
18. The current watcher ignores betweenness.
19. The current watcher ignores unblock count.
20. The current watcher ignores Jeff's swarm guidance to use `bv`.
21. The current watcher violates the skill-level anti-pattern explicitly.
22. Skill citation: `jeff-swarm-ops/SKILL.md:41-45` says agents use `bv --robot-triage`, not `br ready`.
23. Skill citation: `jeff-swarm-ops/SKILL.md:105-111` says a replacement agent picks up via `bv --robot-next`.
24. Skill citation: `jeff-swarm-ops/SKILL.md:121-125` names "Using `br ready` not `bv`" as an anti-pattern.
25. Skill citation: `beads-bv/SKILL.md:14-21` says robot mode only and never bare `bv`.
26. Skill citation: `beads-bv/SKILL.md:29-35` defines `--robot-next` as the one-thing answer.
27. Skill citation: `beads-bv/SKILL.md:103-119` says PageRank and betweenness are the relevant prioritization signals.
28. Skill citation: `beads-br/SKILL.md:27-32` already records `br ready` fragility and the `bv` workaround.
29. Skill citation: `canonical-cli-scoping/SKILL.md:12-14` says operator tools must be inspectable, healable, explainable, and observable.
30. Skill citation: `canonical-cli-scoping/SKILL.md:20-34` defines the doctor, health, repair, validate, audit, why, and upstream-report surface.
31. Skill citation: `canonical-cli-scoping/SKILL.md:177-187` requires `--json` and schema discipline.
32. Skill citation: `canonical-cli-scoping/SKILL.md:199-210` requires dry-run, idempotency, audit, Agent Mail locking, and atomic writes for shared-state mutation.
33. Skill citation: `jeff-issue-chain/SKILL.md:27-34` defines the upstream issue draft body shape.
34. Skill citation: `jeff-issue-chain/SKILL.md:36-40` says do not submit PRs or patches to Jeff repos and do not file duplicates.
35. Skill citation: `jeff-issue-chain/SKILL.md:42-46` calibrates the direct, file-line-cited filing voice.
36. Skill citation: `jeff-planning-enhanced/SKILL.md:9-23` is the cost model: plan space 1x, bead space 5x, code space 25x.
37. Skill citation: `jeff-planning-enhanced/SKILL.md:94-106` rejects implementation before convergence and plans without beads.
38. Skill citation: `accretive-cron-orchestration/SKILL.md:51-64` names the sweep loop and its dispatch lane.
39. Skill citation: `accretive-cron-orchestration/SKILL.md:76-91` gives the zero-value tick escalation ladder.
40. Skill citation: `accretive-cron-orchestration/SKILL.md:102-106` forbids narrative "standing by" and forces productive lanes.

## 1. Socraticode Ledger

01. Project searched: `/Users/josh/Developer/jeff-corpus`.
02. Socraticode status before critique: green.
03. Indexed chunks observed: 893496.
04. Query count: 10.
05. Query 01: `bv --robot-next implementation returns id score unblocks claim command PageRank recommendation`.
06. Query 02: `br ready implementation blocked status dependencies actionable issues SQL ready query`.
07. Query 03: `bv actionable recipe robot plan skip blocked ready issues PageRank graph ranking`.
08. Query 04: `atomic write temp file fsync os.replace jsonl append validated ledger receipt`.
09. Query 05: `agent mail file reservation ttl force release stale reservation lock expiration`.
10. Query 06: `ntm robot snapshot robot attention robot send ack tail structured state canonical robot mode`.
11. Query 07: `ntm work triage assign bv integration work next robot beads list claim close`.
12. Query 08: `flywheel loop driver writeback launchd ntm send prompt driver receipt`.
13. Query 09: `fw_jsonl_append_validated append validated jsonl schema receipt atomic ledger`.
14. Query 10: `upstream-report issue draft CLI file line citations reproduce expected observed tracking bead`.
15. Hit A: `beads_viewer/cmd/bv/main.go:439-461`.
16. Hit A local chunk hash: `337c40f5dbada09f792ee2b1521d7e59737fcd594c7b3bd68864c0718949f471`.
17. Hit A proves `--robot-next`, `--robot-triage`, `--robot-plan`, and related robot flags are first-class in `bv`.
18. Hit B: `beads_viewer/cmd/bv/main.go:2586-2718`.
19. Hit B local chunk hash: `757d82a6b123aeb8fc5aff82667ec7434399cb97e6f91a44c48629cc293923db`.
20. Hit B proves `--robot-next` waits for phase 2 graph metrics and emits id, title, score, reasons, unblocks, claim command, and show command.
21. Hit C: `beads_rust/src/cli/commands/ready.rs:1-181`.
22. Hit C local chunk hash: `ca5ea8f7ff0043d2d3e0052ecaaddf3bfc36970b28f00e3e9d5f298f16ef06e7`.
23. Hit C proves `br ready` is a readiness query with filters and sort policy, not a PageRank selector.
24. Hit D: `ntm/internal/robot/attention_contract.go:1-57`.
25. Hit D local chunk hash: `66802d3025a78f4497add23265bd9d97ce5d30aeae25edc038a90d3ad39a3674`.
26. Hit D proves ntm's robot contract says the LLM is the driver and ntm is sensing/actuation substrate.
27. Hit E: `mcp_agent_mail_rust/crates/mcp-agent-mail-tools/src/reservations.rs:1055-1261`.
28. Hit E local chunk hash: `ee93cdb3b196b6a11ffcc256f97d78d904648fa086cb3382db41ec8190c9511e`.
29. Hit E proves stale reservation force-release already owns multi-signal safety and atomic conflict handling.
30. Hit F: `jeffreysprompts.com/crates/jfp/src/storage/jsonl.rs:34-99`.
31. Hit F local chunk hash: `35252dd7c3c3e5b9e3c4348d741efab7cd6674ab6f3c5e3901c944e8ab28502d`.
32. Hit F proves Jeff-style JSONL export uses temp file, flush, fsync, and rename.
33. Hit G: `agentic_coding_flywheel_setup/scripts/lib/autofix.sh:465-510`.
34. Hit G local chunk hash: `75b9cc3556c58d87f0ec397882560f7728eb4c1d005030b252d5a83b21f1c348`.
35. Hit G proves shell append helpers should use temp files, fsync file, rename, and fsync directory.
36. Local flywheel hit H: `.flywheel/scripts/idle-state-probe.sh:158-190`.
37. Hit H proves the current watcher reads `br ready --json`.
38. Local flywheel hit I: `.flywheel/scripts/idle-state-probe.sh:220-232`.
39. Hit I proves the current candidate selector filters priority and epic, dedupes recently fired beads, then sorts by priority and `created_at`.
40. Local flywheel hit J: `.flywheel/scripts/idle-state-probe.sh:270-271`.
41. Hit J proves the dispatch candidate is simply `$candidates[0].id`.
42. Local flywheel hit K: `.flywheel/scripts/idle-pane-auto-dispatch.sh:264-269`.
43. Hit K proves cooldown files are append-only via `printf >>`, not atomic append.
44. Local flywheel hit L: `.flywheel/scripts/idle-pane-auto-dispatch.sh:271-288`.
45. Hit L proves dispatch log append already uses `fw_jsonl_append_validated` when present.
46. Local flywheel hit M: `.flywheel/scripts/idle-pane-auto-dispatch.sh:372-417`.
47. Hit M proves delivery receipt exists but is assembled from ntm tail/activity probes instead of a single canonical send-ack primitive.
48. Live probe N: `bv --robot-next` produced `flywheel-4m2a`.
49. Live probe N proves the plan's proposed target bead is still current at 2026-05-05T15:36:46Z.
50. Live probe O: `br ready --json` status histogram was `in_progress=19, open=1`.
51. Live probe O proves `br ready` is not safe enough for the dispatcher's current interpretation.
52. My read: the five-line local patch is justified as a stop-bleed.
53. My read: the five-line patch is not the long-term architecture.
54. My read: the long-term architecture is `bv` for graph-aware selection, `br` for issue persistence and actionability, `ntm` for actuation, Agent Mail for reservations, and flywheel for policy.
55. The critique below grades each plan primitive against that boundary.

## 2. The 5-Line Fix That Should Already Be Deployed

01. The highest-leverage current bug is not P2, P3, P4, P5, P6, or M.
02. The highest-leverage current bug is the dispatcher's selector.
03. The dispatcher's selector chooses from `br ready --json`.
04. Jeff's stack already has `bv --robot-next`.
05. Jeff's swarm skill explicitly says replacement agents pick work with `bv --robot-next`.
06. The live `br ready --json` data is actively poisonous for the current watcher.
07. Nineteen of twenty rows were `in_progress`.
08. If a selector treats that as ready work, it redispatches ownership already in flight.
09. That matches the overnight symptom.
10. The plan says watcher repeatedly dispatched blocked/stale beads.
11. The observed code says it could also dispatch in-progress beads.
12. The five-line fix converts `bv --robot-next` into the shape the current probe already consumes.
13. It preserves the fallback to `br ready --json`.
14. It does not patch Jeff repos.
15. It does not invent a new ranking algorithm.
16. It does not require a schema migration.
17. It does not require an agent restart beyond the next watcher tick.
18. It should include `selection_source`.
19. It should include `score`.
20. It should include `unblocks`.
21. It should not silently erase `bv` reasoning.
22. The proposed diff is intentionally tiny because this is a bleed stop.
23. The proposed diff is intentionally not the permanent issue resolution.
24. The permanent issue resolution should make the selector's upstream contracts explicit.
25. The permanent issue resolution should file the `bv`/`br` gaps below.
26. The permanent issue resolution should remove the fallback once `bv --robot-next` has the filters the watcher needs.
27. The current `br ready` fallback should be treated as degraded mode.
28. Degraded mode should emit `selection_source=br ready --json`.
29. Degraded mode should emit a warning in the dispatch log.
30. Degraded mode should not pretend the graph score is available.
31. The dispatch log should carry `selection_score=null` in degraded mode.
32. The dispatch log should carry `selection_unblocks=null` in degraded mode.
33. The dispatch log should carry `selection_reason=graph_selector_unavailable`.
34. The five-line fix should be deployed behind the existing idle-state probe test harness.
35. The test should provide a fake `bv --robot-next` JSON object.
36. The test should assert candidate id equals the `bv` id.
37. The test should assert selection source equals `bv --robot-next`.
38. The test should assert `br ready` is not called when `bv` succeeds.
39. The fallback test should assert `br ready` is called when `bv` is absent.
40. The malformed `bv` test should assert degraded mode logs why it fell back.
41. The current script already has a ready fixture input path.
42. Do not grow the script much further.
43. The file is already large enough that canonical-cli-scoping file-length discipline should constrain edits.
44. If this fix takes more than about 30 lines including tests, the design is drifting.
45. The Jeff-compatible move is the small local adapter plus upstream contract issue.

## 3. Canonical CLI Scoping Audit - Overview

01. I audited each primitive against the `canonical-cli-scoping` standard.
02. The audit dimensions are P1 through P6 plus M.
03. The standard is not "does the idea sound useful."
04. The standard is "does the primitive have the operator surface to survive unattended operation."
05. The required surfaces are doctor, health, repair, validate, audit, why, schema, dry-run, idempotency, and upstream-report where wrapping another substrate.
06. Shared-state mutation requires Agent Mail or equivalent locking.
07. Shared-state mutation requires atomic writes.
08. Shared-state mutation requires backup or restore path.
09. CLI output must be structured.
10. CLI output must have stable schema.
11. CLI output must have operator-readable provenance.
12. Adapter CLIs must distinguish their own bugs from upstream bugs.
13. Adapter CLIs must generate upstream issue drafts.
14. This matters because the plan proposes a fleet autonomy substrate, not a one-off script.
15. If the fleet loop is an operator substrate, it cannot hide behind "script worked once."
16. The current plan is strongest where it replaces one wrong primitive with one existing right primitive.
17. The current plan is weakest where it proposes policy inside the watcher.
18. The watcher is not the right home for every control loop.
19. The watcher is a consumer of canonical robot signals.
20. `bv` owns graph-aware selection.
21. `br` owns bead storage and readiness.
22. `ntm` owns pane observation and actuation.
23. Agent Mail owns file reservations.
24. flywheel-loop owns policy, receipts, and mission-state accounting.
25. A plan that keeps those boundaries is Jeff-compatible.
26. A plan that turns the watcher into a special-purpose brain is not.
27. The plan should be cut down to a minimum viable subset.
28. The minimum viable subset is three primitives.
29. First primitive: replace watcher selection with `bv --robot-next`.
30. Second primitive: make selection/cooldown receiptful and queryable through status.
31. Third primitive: generate the morning/status artifact from the same status row.
32. P4, P5, and P6 should be reframed as upstream-owned or adjacent-substrate work.
33. P4 is primarily Agent Mail and ntm lock ownership.
34. P5 is primarily ntm pane health and actuation.
35. P6 is primarily `bv` alerts, label attention, and stale-work scoring.
36. M should be a report over P3, not a separate new brain.
37. The plan is too broad for the first cut.
38. The night had 390 fuckups.
39. A 390-fuckup night is not a signal to add six independent mechanisms at once.
40. It is a signal to fix the wrong selector and instrument its effects.

## 4. P1 Audit - Replace Watcher `br ready` With `bv --robot-next`

01. P1 is the core correct move.
02. P1 should ship first.
03. P1 is backed by skills.
04. P1 is backed by Socraticode.
05. P1 is backed by the live probe.
06. P1 passes the Jeff swarm rule.
07. P1 passes the graph-aware triage rule.
08. P1 passes the "use existing primitive" rule.
09. P1 does not fully pass canonical-cli-scoping yet.
10. P1 is currently described as a watcher change, not a CLI surface.
11. P1 needs a doctor signal.
12. P1 needs a health signal.
13. P1 needs a repair or degraded-mode story.
14. P1 needs a schema for selector receipts.
15. P1 needs `why <dispatch-id>` or equivalent provenance.
16. P1 needs test fixtures for `bv` success, `bv` no actionable item, malformed JSON, and fallback.
17. P1 needs to include the `bv` `data_hash`.
18. P1 needs to include the selected bead id.
19. P1 needs to include score.
20. P1 needs to include unblocks.
21. P1 needs to include reasons.
22. P1 needs to include claim command.
23. P1 needs to include show command.
24. P1 needs to include source version if available.
25. P1 needs to include runtime path to `bv`.
26. P1 needs to include fallback reason when not using `bv`.
27. P1 should not parse human output.
28. P1 should not call bare `bv`.
29. P1 should not call `br ready` unless `bv` is unavailable or invalid.
30. P1 should not silently downgrade.
31. P1 should not sort `bv` output again by priority/age.
32. P1 should not erase the `score` from the dispatch log.
33. P1 should not choose another bead after `bv` has chosen one unless a cooldown/exclusion says no.
34. If a cooldown says no, the primitive should either ask `bv` for the next candidate with exclusions or log `no_candidate_after_cooldown`.
35. Today `bv --robot-next` does not expose an exclusion flag in the cited code.
36. That is an upstream `bv` issue draft, not a reason to keep using `br ready`.
37. P1 currently conflicts with local cooldown behavior.
38. The watcher dedupe uses `bead-fired`.
39. The watcher dedupe assumes it can filter a list of candidates.
40. `bv --robot-next` returns only one candidate.
41. If that candidate is in cooldown, the watcher cannot safely pick second-best unless `bv` exposes second-best.
42. The temporary local answer is "skip dispatch and log why" when the top `bv` candidate is in cooldown.
43. The durable answer is `bv --robot-next --exclude <id>` or `bv --robot-triage` plus canonical selection on its ranked list.
44. `bv --robot-triage` already has richer output.
45. `bv --robot-next` is lower latency and easier to consume.
46. I prefer `bv --robot-next --exclude` as the upstream contract.
47. If Jeff prefers triage list filtering, we should follow that architecture.
48. P1 should include a local issue draft but no upstream push.
49. P1 should include a flywheel tracking bead if we actually file upstream later.
50. P1 should include a dogfood receipt after deploying.
51. P1's canonical-cli score: partial.
52. P1's Jeff-stack score: high.
53. P1's operational urgency: critical.
54. P1's implementation risk: low.
55. P1's rollback risk: low, because fallback to `br ready` can remain for one release.
56. P1's hidden risk: a single-candidate primitive plus local cooldown can starve the dispatch loop.
57. P1's hidden risk should be addressed with a skip receipt, not with reimplementing ranking.
58. P1 should be the first bead in the minimum viable cut.
59. P1 should close only after the next night proves dispatch concentration drops.
60. P1 should not be declared complete because the code compiles.
61. P1's acceptance evidence should include dispatch-log before/after.
62. P1's acceptance evidence should include unique bead dispatch count.
63. P1's acceptance evidence should include repeat-dispatch rate.
64. P1's acceptance evidence should include top selected bead ids and scores.
65. P1's acceptance evidence should include zero `br ready` fallback events when `bv` is healthy.
66. P1 should not count `br ready` rows as "queue depth" after selection moves to `bv`.
67. Queue depth and next-work selection are distinct.
68. Queue depth can still use `br list` or `br ready` for reporting.
69. Dispatch choice should use `bv`.
70. P1 final recommendation: ship the stop-bleed now, then file upstream contract issue for exclusions/cooldown.

## 5. P2 Audit - Divergent Loop Self-Assert And Cooldown

01. P2 names a real symptom.
02. P2 should not live primarily inside the watcher.
03. P2 says the system should notice repeated dispatches of the same bead.
04. That is a status/accounting concern.
05. That is also a `bv` selection contract concern.
06. The plan frames cooldown as a local watcher fix.
07. Local cooldown already exists in `idle-pane-auto-dispatch.sh`.
08. Local cooldown is currently written with `printf >>`.
09. That violates the atomic-write posture for shared operational state.
10. Local cooldown does not explain why a bead was skipped.
11. Local cooldown does not emit schemaed selection receipts by itself.
12. Local cooldown does not talk to `bv`.
13. Local cooldown cannot ask for the second-best graph candidate.
14. Local cooldown can only suppress the top pick.
15. Suppressing the top pick without a second pick is better than repeated bad dispatch.
16. Suppressing the top pick without a second pick is not fleet autonomy.
17. P2 should be split into two layers.
18. Layer 1: local stop-bleed cooldown receipt.
19. Layer 2: upstream `bv` exclusion or "next after" contract.
20. Layer 1 should be tiny.
21. Layer 1 should use `fw_jsonl_append_validated` or the existing atomic append library.
22. Layer 1 should write `selection_suppressed` rows.
23. Layer 1 should include bead id.
24. Layer 1 should include selection source.
25. Layer 1 should include cooldown source.
26. Layer 1 should include elapsed seconds.
27. Layer 1 should include retry_after seconds.
28. Layer 1 should include `would_have_dispatched=false`.
29. Layer 1 should include `upstream_gap=bv_missing_exclude`.
30. Layer 1 should not mutate bead state.
31. Layer 1 should not label beads as blocked.
32. Layer 1 should not create repair beads.
33. Layer 1 should not claim ownership.
34. Layer 2 belongs upstream.
35. Layer 2 should be phrased as an issue, not as a patch.
36. Layer 2 should say "robot-next cannot express exclusion/cooldown."
37. Layer 2 should show the consumer behavior that breaks.
38. Layer 2 should cite `bv` output contract file lines.
39. Layer 2 should cite local watcher consumer file lines.
40. Layer 2 should include a tracking bead if filed.
41. P2 as written risks becoming "policy in the watcher."
42. Policy in the watcher is brittle.
43. Policy in the watcher is hard to inspect.
44. Policy in the watcher makes every future selector bug local.
45. Jeff-style substrate wants reusable primitives.
46. The right primitive is `bv` exposing exclusion or top-N ranked output.
47. The right primitive may be `bv --robot-triage` with a stable schema.
48. The wrong primitive is a bash sort over `br ready`.
49. The plan should explicitly demote P2 from feature to guardrail.
50. P2 canonical-cli score: weak as written.
51. P2 Jeff-stack score: moderate if split correctly.
52. P2 operational urgency: high, but subordinate to P1.
53. P2 implementation risk: medium because it can hide work if wrong.
54. P2 rollback risk: medium because cooldown bugs look like healthy quiet.
55. P2 hidden risk: "no dispatch" becomes the new silent failure.
56. P2 must therefore include a visible status field.
57. P2 should report `suppressed_by_cooldown_count`.
58. P2 should report `top_pick_in_cooldown_count`.
59. P2 should report `seconds_until_retry`.
60. P2 should trigger DEGRADED after two ticks with the same suppressed top pick.
61. P2 should not auto-ask Joshua.
62. P2 should auto-file or update an upstream tracking bead only after recurrence threshold.
63. P2 should be measured against reduced duplicate dispatches, not against reduced dispatches total.
64. P2 should not be shipped before P1.
65. P2 should be shipped with P3, because a cooldown without status is quiet failure.
66. P2 final recommendation: keep a local skip receipt, file upstream `bv` issue, do not implement local second-best ranking.

## 6. P3 Audit - `flywheel-loop status`

01. P3 is the plan's best structural primitive.
02. P3 turns scattered logs into an operator-facing CLI.
03. P3 fits canonical-cli-scoping directly.
04. P3 should be named and scoped as `flywheel-loop status`.
05. P3 must support `--json`.
06. P3 should support `--watch -i N`.
07. P3 should support `--since`.
08. P3 should support `--session`.
09. P3 should support `--repo`.
10. P3 should support `--why <dispatch-id>` or make `why` a sibling command.
11. P3 should not be a Markdown-only report.
12. P3 should have a schema.
13. P3 should validate its own input logs.
14. P3 should call out missing logs as degraded.
15. P3 should not crash if one substrate is missing.
16. P3 should distinguish `NO_DATA`, `STALE_DATA`, `UPSTREAM_BUG`, and `OK`.
17. P3 should include selector health.
18. P3 should include `bv` health.
19. P3 should include `br` health.
20. P3 should include ntm health.
21. P3 should include Agent Mail reservation health.
22. P3 should include dispatch rate.
23. P3 should include closure rate.
24. P3 should include duplicate-dispatch rate.
25. P3 should include overdue callback count.
26. P3 should include fuckup count by trauma class.
27. P3 should include top selected bead ids.
28. P3 should include top suppressed bead ids.
29. P3 should include `selection_source` distribution.
30. P3 should include `br_ready_fallback_count`.
31. P3 should include `delivery_receipt` pass/fail distribution.
32. P3 should include panes waiting/busy/stale.
33. P3 should include `driver_status`, per L57.
34. P3 should include `marker_only` loop warnings.
35. P3 should include the morning ritual summary in data form.
36. P3 should not generate prose as its primary output.
37. P3 can generate Markdown as a formatter over JSON.
38. P3 should reuse `fw_jsonl_append_validated` for any history row.
39. P3 should not write status history unless the operator asks or the tick owns the closeout.
40. P3 should not create beads directly on every status run.
41. P3 should support `--doctor` only if it maps to existing doctor semantics.
42. Better: keep `doctor` as existing command, add `status`.
43. P3 should make the plan measurable.
44. P3 is how P1 and P2 prove their effect.
45. P3 is how P4-P6 avoid premature implementation.
46. P3 should reveal whether stale reservations are real bottlenecks.
47. P3 should reveal whether frozen panes are real bottlenecks.
48. P3 should reveal whether repair beads are aging.
49. P3 should not assume those are the top bottlenecks before measuring.
50. P3 canonical-cli score: strong if implemented as real CLI surface.
51. P3 Jeff-stack score: high.
52. P3 operational urgency: high.
53. P3 implementation risk: medium because status aggregation can become a monolith.
54. P3 file-length risk: high if added to the existing large flywheel-loop script.
55. P3 should be a thin dispatch subcommand with helpers.
56. P3 should honor canonical-cli-scoping file thresholds.
57. P3 should ship fixture tests against sample dispatch logs.
58. P3 should ship fixture tests against missing ntm.
59. P3 should ship fixture tests against malformed JSONL.
60. P3 should ship fixture tests against no `bv`.
61. P3 should ship fixture tests against healthy `bv`.
62. P3 should return nonzero only for degraded/critical status per schema.
63. P3 should not treat "no callbacks" as healthy if dispatches are active.
64. P3 should not treat "no dispatches" as healthy if ready graph has work.
65. P3 should not be a replacement for doctor.
66. P3 final recommendation: include in minimum viable cut, but define schema first.

## 7. P4 Audit - Cross-Orchestrator Reservation TTL

01. P4 identifies a real concurrency class.
02. P4 is not primarily a watcher feature.
03. P4 belongs to Agent Mail reservation semantics and ntm orchestration.
04. The Socraticode hit proves Agent Mail already has force-release safeguards.
05. Agent Mail force-release validates holder inactivity.
06. Agent Mail force-release checks mail activity.
07. Agent Mail force-release checks filesystem activity.
08. Agent Mail force-release checks git activity.
09. Agent Mail force-release checks expiry.
10. Agent Mail force-release refuses active reservations.
11. Agent Mail force-release uses an atomic release with the observed `expires_ts`.
12. That is the right safety shape.
13. The watcher should not reimplement stale reservation logic.
14. The watcher should not parse reservation JSON artifacts directly.
15. The watcher should not force-release anything without the Agent Mail primitive.
16. The watcher should surface reservation conflicts.
17. The watcher should hand off stale-release decisions to Agent Mail.
18. The watcher can call Agent Mail's force-release only through an explicit repair path.
19. That repair path must be dry-run by default.
20. That repair path must be audit-logged.
21. That repair path must include holder, path, stale reasons, and previous expiry.
22. That repair path must include a notify policy.
23. That repair path must not hide in automatic dispatch selection.
24. The plan's P4 needs a clearer owner boundary.
25. If P4 means "watcher looks for stale reservations and force releases them," reject that shape.
26. If P4 means "status reports stale reservation candidates and repair command delegates to Agent Mail," accept that shape.
27. If P4 means "ntm lock namespace integrates with Agent Mail leases," file upstream/adjacent design bead.
28. P4 should not block P1.
29. P4 should not be part of the first patch unless status shows reservations are the dominant bottleneck.
30. P4 should produce a contract like `flywheel-loop repair reservations --dry-run`.
31. P4 should produce `planned_actions`.
32. P4 should produce `blocked_by`.
33. P4 should require `--apply`.
34. P4 should require an idempotency key for repeated release attempts.
35. P4 should write audit rows atomically.
36. P4 should include a rollback story only in the sense that release can be re-reserved.
37. P4 should not directly mutate Agent Mail DB.
38. P4 should not shell-grep the archive.
39. P4 should not infer from silence alone.
40. P4 should honor L51 dispatch reservations.
41. P4 should honor L53 if a reservation blocker stops dispatch.
42. P4 should honor L54 if declaring blocked.
43. P4 canonical-cli score: poor as written.
44. P4 canonical-cli score can become good if reframed as status+repair wrapper.
45. P4 Jeff-stack score: medium.
46. P4 operational urgency: unproven from the supplied telemetry.
47. P4 implementation risk: high if implemented locally.
48. P4 hidden risk: automatic force-release can break live work.
49. P4 hidden risk is exactly why Agent Mail's four-signal heuristic matters.
50. P4 final recommendation: park from MVP; expose status now, repair later through Agent Mail only.

## 8. P5 Audit - Pane Freeze Auto-Respawn

01. P5 identifies a plausible fleet autonomy gap.
02. P5 is not primarily a watcher selection feature.
03. P5 belongs to ntm's pane health and actuation contract.
04. The ntm robot contract says ntm is the nervous system.
05. The operator loop is snapshot, events, digest, wait, attention, act, loop.
06. A pane respawn is actuation.
07. A pane freeze is sensing plus diagnosis.
08. The watcher should not bypass ntm's actuation semantics.
09. The watcher should not decide a pane is dead from one stale scrollback sample.
10. The watcher should not respawn a pane without preserving work context.
11. The watcher should not respawn a pane without reservation cleanup or transfer.
12. The watcher should not respawn a pane without callback/fuckup logging.
13. The watcher should not respawn a pane without a receipt visible to status.
14. P5 needs a `ntm` or flywheel repair primitive.
15. P5 needs a dry-run.
16. P5 needs a permit gate.
17. P5 needs idempotency.
18. P5 needs a "why this pane is frozen" trace.
19. P5 needs a "what was preserved" receipt.
20. P5 needs a "what was lost" receipt.
21. P5 needs to re-read AGENTS and dispatch context after respawn.
22. P5 needs to avoid duplicate dispatch to the same bead.
23. P5 needs to release or transfer file reservations.
24. P5 needs to log a fuckup if a pane was truly frozen.
25. P5 needs to report if the pane was merely waiting behind a placeholder.
26. Accretive cron skill already warns that placeholders can be mistaken for activity.
27. Skill citation: `accretive-cron-orchestration/SKILL.md:102-106` says probe before hold.
28. P5 should include probe-before-respawn.
29. P5 should include ntm activity check.
30. P5 should include source health from ntm.
31. P5 should include last output timestamp.
32. P5 should include process liveness if ntm exposes it.
33. P5 should include recent send receipts.
34. P5 should include recent Agent Mail activity.
35. P5 should include active reservations.
36. P5 should not be shipped from the same bead as P1.
37. P5 should not be considered proved by overnight overdue callbacks alone.
38. Overdue callbacks may be frozen panes.
39. Overdue callbacks may be bad dispatches.
40. Overdue callbacks may be missing callback contract enforcement.
41. P1 and P3 should reduce the ambiguity before P5.
42. P5 canonical-cli score: weak as written.
43. P5 canonical-cli score can be strong as `ntm`/flywheel repair.
44. P5 Jeff-stack score: medium if routed through ntm.
45. P5 operational urgency: plausible, not first.
46. P5 implementation risk: high.
47. P5 hidden risk: auto-respawn can erase exactly the evidence needed to diagnose failures.
48. P5 hidden risk: auto-respawn can cause duplicate workers.
49. P5 hidden risk: auto-respawn can strand reservations.
50. P5 final recommendation: status first, repair dry-run second, auto-apply only after repeated safe receipts.

## 9. P6 Audit - Repair-Bead Aging

01. P6 names a real systems smell.
02. Repair beads aging means the system has learned but not closed the loop.
03. That is a status, triage, and graph-prioritization problem.
04. It is not primarily a watcher-dispatch problem.
05. `bv` already has `--robot-alerts`.
06. `bv` already has `--robot-label-attention`.
07. `bv` already has `--robot-priority`.
08. `bv` already has `--robot-history`.
09. `bv` already has graph metrics.
10. Repair-bead aging should feed `bv` scoring or alerts.
11. Repair-bead aging should not become a second local priority engine.
12. The watcher should consume one canonical next-work signal.
13. That next-work signal should understand aging if aging matters.
14. Therefore P6 belongs upstream in `bv` or in bead metadata conventions.
15. A local status report can surface repair-age counts now.
16. A local status report can group repair beads by age.
17. A local status report can show oldest repair bead.
18. A local status report can show repair beads with recurring trauma classes.
19. A local status report can show repair beads that unblock many beads.
20. A local status report should not reorder dispatch selection itself.
21. P6 needs a clear bead label convention.
22. P6 needs a clear "repair bead" detection rule.
23. P6 needs a clear source of created_at/updated_at/closed_at.
24. P6 needs a graph-aware interpretation.
25. P6 should consider dependencies, not just age.
26. P6 should not punish a repair bead blocked by a parent dependency.
27. P6 should not conflate "old" with "important."
28. P6 should not conflate "P0" with "unblocking."
29. P6 should not create a new repair bead for every old repair bead.
30. P6 should not spam fuckup logs with chronic known debt.
31. P6 can update status as an attention signal.
32. P6 can file an upstream `bv --robot-alerts` enhancement if missing.
33. P6 can add a local query to the morning report after P3 exists.
34. P6 should not be in MVP.
35. P6 canonical-cli score: poor as an independent watcher change.
36. P6 canonical-cli score: moderate as a `flywheel-loop status` field.
37. P6 canonical-cli score: high if upstreamed into `bv` alert/label attention.
38. P6 Jeff-stack score: medium.
39. P6 operational urgency: lower than P1-P3.
40. P6 implementation risk: medium.
41. P6 hidden risk: more priority signals means less trust in the one robot selector.
42. P6 final recommendation: report now, upstream scoring later, do not make it a dispatch override.

## 10. M Audit - Morning Ritual Artifact

01. M is useful if it is a view over real status.
02. M is harmful if it is another manually interpreted digest.
03. Morning ritual should not be separate from `flywheel-loop status`.
04. Morning ritual should be `status --format markdown` or a daily formatter over status JSON.
05. Morning ritual should include `bv --agent-brief` if available.
06. `bv` source exposes an agent brief flag in the same command family.
07. Morning ritual should include unique dispatches.
08. Morning ritual should include closures.
09. Morning ritual should include repeat-dispatch rate.
10. Morning ritual should include overdue callback count.
11. Morning ritual should include top trauma classes.
12. Morning ritual should include selector fallback count.
13. Morning ritual should include top suppressed candidates.
14. Morning ritual should include driver status.
15. Morning ritual should include loop marker-only warnings.
16. Morning ritual should include stale reservation candidates.
17. Morning ritual should include frozen pane candidates.
18. Morning ritual should include repair-bead aging summary.
19. Morning ritual should include "what changed since yesterday."
20. Morning ritual should include exact next three recommended actions.
21. Morning ritual should not include fluffy narrative.
22. Morning ritual should not include raw transcript dumps.
23. Morning ritual should not require Joshua to inspect six files.
24. Morning ritual should link to the dispatch log row range.
25. Morning ritual should link to the status JSON row.
26. Morning ritual should link to new fuckup-log rows.
27. Morning ritual should link to upstream issue drafts if produced.
28. Morning ritual should be generated atomically.
29. Morning ritual should be idempotent for the same window.
30. Morning ritual should be regenerated cleanly.
31. Morning ritual should have a stable path.
32. Morning ritual should have a schemaed metadata header.
33. Morning ritual should report if inputs were stale.
34. Morning ritual should report if Socraticode was unavailable.
35. Morning ritual should report if `bv` was unavailable.
36. Morning ritual should report if Agent Mail was unavailable.
37. Morning ritual should not file upstream issues automatically.
38. Morning ritual can include issue draft paths.
39. Morning ritual can include "ready to file after duplicate search."
40. M canonical-cli score: partial as written.
41. M canonical-cli score: strong if formatter over P3.
42. M Jeff-stack score: high if it reduces operator load.
43. M operational urgency: useful but not before P1.
44. M implementation risk: low if purely read-only.
45. M hidden risk: summary theater.
46. M final recommendation: ship after P3 schema, not as a separate planning primitive.

## 11. Substrate Ownership Review

01. Ownership line 01: `br` owns issue records.
02. Ownership line 02: `br` owns issue status changes.
03. Ownership line 03: `br` owns dependency edges.
04. Ownership line 04: `br` owns ready/actionable filtering.
05. Ownership line 05: `bv` owns graph-aware selection.
06. Ownership line 06: `bv` owns PageRank and betweenness ranking.
07. Ownership line 07: `bv` owns label attention and graph alerts.
08. Ownership line 08: `ntm` owns pane observation.
09. Ownership line 09: `ntm` owns pane actuation.
10. Ownership line 10: `ntm` owns robot send/interrupt/wait/snapshot contracts.
11. Ownership line 11: Agent Mail owns file reservations.
12. Ownership line 12: Agent Mail owns stale reservation force-release.
13. Ownership line 13: flywheel-loop owns mission policy.
14. Ownership line 14: flywheel-loop owns tick receipts.
15. Ownership line 15: flywheel-loop owns closeout receipts.
16. Ownership line 16: flywheel-loop owns status aggregation over its own logs.
17. Ownership line 17: watcher owns idle detection and dispatch trigger.
18. Ownership line 18: watcher should not own global ranking.
19. Ownership line 19: watcher should not own stale reservation semantics.
20. Ownership line 20: watcher should not own pane resurrection semantics.
21. Ownership line 21: watcher should not own repair-bead scoring.
22. Ownership line 22: watcher should consume canonical robot primitives.
23. Ownership line 23: watcher should emit receipts.
24. Ownership line 24: watcher should fail visibly.
25. Ownership line 25: watcher should be easy to replace.
26. P1 respects ownership if it uses `bv`.
27. P1 violates ownership if it re-sorts graph work locally.
28. P2 respects ownership if it logs suppression and asks `bv` for exclusions.
29. P2 violates ownership if it builds a new local ranking engine.
30. P3 respects ownership if it reports across substrates without mutating them.
31. P3 violates ownership if it silently repairs upstream state.
32. P4 respects ownership if it delegates to Agent Mail.
33. P4 violates ownership if it force-releases from local files.
34. P5 respects ownership if it delegates to ntm.
35. P5 violates ownership if it kills/respawns panes directly from watcher logic.
36. P6 respects ownership if it reports or upstreams to `bv`.
37. P6 violates ownership if it adds another dispatch override list.
38. M respects ownership if it formats P3.
39. M violates ownership if it becomes another independent status substrate.
40. The plan should say these boundaries explicitly.
41. Without the boundaries, future workers will implement locally.
42. Local implementation will work for one night.
43. Local implementation will rot for every future swarm.
44. Jeff-compatible architecture means reusable primitives.
45. Joshua-compatible taste means small local stop-bleeds plus upstream issue chain.

## 12. Upstream Issue Draft - `bv --robot-next` Exclusions

01. Draft status: do not file yet.
02. Duplicate search required before filing.
03. Target repo: `Dicklesworthstone/beads_viewer` if that is Jeff's active upstream for `bv`.
04. Proposed title: `robot-next cannot express cooldown/exclusion candidates`.
05. Title follows `jeff-issue-chain` because it states the observed contract gap, not a prescriptive implementation.
06. What happened: a consumer that dispatches one worker at a time needs the top graph candidate unless that bead was just dispatched or reserved.
07. What happened: `bv --robot-next` emits only one candidate.
08. What happened: when that one candidate is temporarily ineligible, the consumer cannot request the next graph-ranked candidate without falling back to local ranking.
09. Repro command 01: `cd /Users/josh/Developer/flywheel`.
10. Repro command 02: `bv --robot-next`.
11. Repro observed: JSON includes `id`, `title`, `score`, `reasons`, `unblocks`, `claim_command`, and `show_command`.
12. Repro missing: no `--exclude <id>`.
13. Repro missing: no `--limit N` top-N ranked list in the minimal next command.
14. Repro missing: no `cooldown` or `skip_recent` input.
15. Expected vs observed expected: a robot consumer can ask for next-best actionable graph candidate after excluding a bead id.
16. Expected vs observed observed: the consumer must either dispatch a cooled-down bead, skip dispatch, or reimplement selection from a different output.
17. File-line citation 01: `beads_viewer/cmd/bv/main.go:461` defines `--robot-next`.
18. File-line citation 02: `beads_viewer/cmd/bv/main.go:2664-2718` emits exactly one top pick.
19. File-line citation 03: `.flywheel/scripts/idle-state-probe.sh:197-232` shows the local cooldown/exclusion consumer.
20. Cost citation: fleet autonomy overnight saw repeated dispatches to non-useful beads, 107 dispatches, 2 closures, 390 fuckups, and 188 `fleet-propagation-failed` rows.
21. Tracking: create flywheel tracking bead only if filed.
22. Out of scope: not asking Jeff to adopt flywheel's cooldown policy.
23. Out of scope: not asking for a patch from our side.
24. Out of scope: not asking `bv` to own Agent Mail reservations.
25. Suggested acceptable shapes: `bv --robot-next --exclude id1 --exclude id2`.
26. Suggested acceptable shapes: `bv --robot-triage --limit N` with stable top-picks schema.
27. Suggested acceptable shapes: `bv --robot-next --input-filter-json <file>`.
28. Wording note: call these possible shapes, not demands.
29. Relationship note: cite that we will locally skip and log while waiting.
30. Filing gate: run `gh issue list --repo Dicklesworthstone/beads_viewer --search "robot-next exclude cooldown"`.

## 13. Upstream Issue Draft - `br ready` Status Semantics

01. Draft status: do not file yet.
02. Duplicate search required before filing.
03. Target repo: `Dicklesworthstone/beads_rust`.
04. Proposed title: `ready JSON includes in-progress rows in flywheel repo`.
05. What happened: `br ready --json` in `/Users/josh/Developer/flywheel` returned 20 rows.
06. What happened: 19 rows had `status=in_progress`.
07. What happened: 1 row had `status=open`.
08. Why this matters: consumers reasonably interpret "ready" as "can be claimed now."
09. Why this matters: dispatch loops can redispatch already-owned work.
10. Repro command 01: `cd /Users/josh/Developer/flywheel`.
11. Repro command 02: `br ready --json | jq -c '[.[].status] | group_by(.) | map({status: .[0], count: length})'`.
12. Observed output: `[{"status":"in_progress","count":19},{"status":"open","count":1}]`.
13. Expected vs observed expected: either `ready` excludes in-progress rows by default or JSON includes a clear "ready but already claimed" field that consumers can filter.
14. Expected vs observed observed: output rows were named ready but mostly in progress.
15. File-line citation 01: `beads_rust/src/cli/commands/ready.rs:1-4` documents open, unblocked, not deferred, not pinned, not ephemeral.
16. File-line citation 02: `beads_rust/src/cli/commands/ready.rs:128-140` constructs readiness filters.
17. File-line citation 03: `beads_rust/src/cli/commands/ready.rs:157-181` reads ready issues and external blockers.
18. Cost citation: flywheel watcher consumed `br ready --json` as dispatch input and contributed to repeat dispatch failures.
19. Tracking: create flywheel tracking bead only if filed.
20. Out of scope: not asking `br ready` to become PageRank-aware.
21. Out of scope: not asking `br` to consume `bv` internally.
22. Out of scope: not asking Jeff to tune flywheel priorities.
23. Important nuance: `br ready` can stay actionability-oriented.
24. Important nuance: `bv` should stay graph-aware selector.
25. Ask: clarify or fix the default status filter for robot-safe ready output.
26. Filing gate: run `gh issue list --repo Dicklesworthstone/beads_rust --search "ready in_progress json"`.

## 14. Upstream Issue Draft - ntm Send Receipt Primitive

01. Draft status: do not file yet.
02. Duplicate search required before filing.
03. Target repo: `Dicklesworthstone/ntm`.
04. Proposed title: `send plus delivery receipt requires multi-probe reconstruction`.
05. What happened: flywheel dispatcher calls ntm send, then reconstructs delivery from tail and activity probes.
06. What happened: this creates a local receipt contract outside ntm.
07. Why this matters: auto-dispatch needs to know transport accepted, prompt visible, prompt submitted, and work started.
08. Why this matters: every consumer should not reassemble this from scrollback.
09. Repro file-line citation 01: `.flywheel/scripts/idle-pane-auto-dispatch.sh:372-417`.
10. Repro file-line citation 02: `ntm/internal/robot/attention_contract.go:18-27`.
11. Expected vs observed expected: robot actuation can return or correlate a stable send receipt.
12. Expected vs observed observed: consumer does tail/activity correlation.
13. Cost citation: dispatch callback overdue and propagation failure dominate the overnight failure report.
14. Tracking: create flywheel tracking bead only if filed.
15. Out of scope: not asking ntm to own flywheel policy.
16. Out of scope: not asking for direct pane process management.
17. Possible shape: `ntm send --robot --track` returns receipt id and post-send state.
18. Possible shape: `ntm --robot-events` emits an actuation receipt that callers can correlate.
19. Filing gate: run `gh issue list --repo Dicklesworthstone/ntm --search "send receipt robot track"`.
20. This issue is lower priority than the `bv` and `br` drafts.

## 15. Working-Sibling Diff

01. Sibling pattern 01: `bv --robot-next` already exists.
02. Current flywheel watcher ignores it.
03. Diff: existing primitive selects with graph score; local watcher selects with priority and age.
04. Sibling pattern 02: `bv --robot-triage` waits for phase 2 graph metrics.
05. Current watcher does not wait for graph metrics.
06. Diff: existing primitive encodes "what matters"; local watcher encodes "what sorted first."
07. Sibling pattern 03: `beads-br` skill says `br ready` can be broken and suggests `bv`.
08. Current watcher depends on `br ready`.
09. Diff: skill wisdom has already converged; code has not absorbed it.
10. Sibling pattern 04: Agent Mail force-release uses four stale signals and atomic release.
11. P4 plan risks local TTL release behavior.
12. Diff: existing primitive is safety-heavy; proposed local watcher path is risk-heavy unless constrained.
13. Sibling pattern 05: ntm robot contract centers snapshot/events/attention/actuation.
14. P5 plan risks direct respawn behavior from the watcher.
15. Diff: existing primitive separates sensing and actuation; plan needs to follow that boundary.
16. Sibling pattern 06: Jeff JSONL storage uses temp write, flush, fsync, rename.
17. Current cooldown files use direct append.
18. Diff: dispatch log is already hardened, cooldown is not.
19. Sibling pattern 07: `fw_jsonl_append_validated` exists and is already used for dispatch log.
20. Current cooldown state bypasses it.
21. Diff: use the local hardened primitive instead of adding another file-write style.
22. Sibling pattern 08: `accretive-cron-orchestration` uses stocks and grade ladder.
23. P3 can expose those stocks instead of inventing a new morning report.
24. Diff: measured control loop already exists as doctrine; status should surface it.
25. Sibling pattern 09: L57 says loop markers are not drivers.
26. P3 must include driver proof.
27. Diff: status that omits driver proof would repeat known trauma.
28. Sibling pattern 10: `jeff-issue-chain` requires issue drafts with file-line citations.
29. This review includes drafts, but correctly does not file them.
30. Diff: issue chain is relationship substrate, not a dumping ground.
31. Sibling pattern 11: `canonical-cli-scoping` says adapter upstream-report belongs in wrappers.
32. P1/P2 should produce draft upstream reports rather than local permanent hacks.
33. Diff: local patch is allowed only as stop-bleed.
34. Sibling pattern 12: `jeff-planning-enhanced` says planning artifacts should converge before implementation.
35. The current plan has too many primitives for first deployment.
36. Diff: revise by cutting the plan, not by adding implementation beads for all six.
37. Sibling pattern 13: `beads-bv` has label attention and alerts.
38. P6 wants repair-bead aging.
39. Diff: add to `bv` alert/attention if needed, do not hand-roll watcher priority.
40. Sibling pattern 14: `bv --agent-brief` exists in the same family of robot affordances.
41. M should reuse that as an input.
42. Diff: morning artifact should compose, not invent.
43. Sibling pattern 15: current dispatch receipt already has schema version `dispatch-delivery-receipt/v1`.
44. P3 can use that instead of designing from scratch.
45. Diff: status should aggregate existing receipt rows.
46. Sibling pattern 16: local flywheel file-length discipline warns against monolithic script growth.
47. P3 should not add hundreds of lines to `flywheel-loop`.
48. Diff: implement thin command plus helper library.
49. Sibling pattern 17: Agent Mail file reservations exist and were used for this review artifact.
50. Future multi-file implementation beads must reserve files before editing.
51. Diff: review-only artifact needed one reservation; implementation will need more.
52. Sibling pattern 18: Socraticode corpus already contains Jeff's primitives.
53. The plan's future dispatches must keep citing those primitives.
54. Diff: no more "go build watcher magic" without survey.
55. Sibling pattern 19: `br` is non-invasive and explicit sync oriented.
56. Any plan that assumes `br` mutates git or syncs automatically is wrong.
57. Diff: bead state changes must be explicit and receiptful.
58. Sibling pattern 20: ntm attention contract says transport parity matters.
59. Dispatch receipt should not be shell-only.
60. Diff: upstream ntm receipt issue may be valuable after P1-P3.

## 16. Atomic Write And Contract Audit

01. Contract rule: shared-state mutation requires atomic write.
02. Contract rule: shared-state mutation requires audit.
03. Contract rule: shared-state mutation requires idempotency.
04. Contract rule: shared-state mutation requires Agent Mail or equivalent lock if cross-process.
05. P1 mutates no shared state if it only reads `bv`.
06. P1 does mutate dispatch receipts indirectly through existing dispatcher.
07. P1 must ensure new selection fields flow into validated dispatch log rows.
08. P1 should not add another ad hoc state file.
09. P1 should not write raw selection JSON without validation.
10. P2 mutates cooldown state.
11. P2 currently depends on cooldown files that use direct append.
12. P2 must either convert cooldown state to validated JSONL or keep it ephemeral.
13. P2 should not increase reliance on non-atomic `bead-fired`.
14. P2 should make cooldown append atomic.
15. P2 should fsync the temp file.
16. P2 should fsync the containing directory where feasible.
17. P2 should record schema version.
18. P2 should record idempotency key.
19. P2 should record event type.
20. P2 should record bead id.
21. P2 should record pane.
22. P2 should record dispatch id.
23. P2 should record source.
24. P2 should record retry time.
25. P3 is read-heavy.
26. P3 should validate JSONL before summarizing.
27. P3 should tolerate malformed rows by surfacing degraded status.
28. P3 should not rewrite logs.
29. P3 should only write a status snapshot through validated JSONL if persistence is required.
30. P3 should write Markdown reports atomically.
31. P3 should not partially overwrite morning artifact.
32. P4 mutates reservation state if repair applies.
33. P4 must delegate mutation to Agent Mail.
34. P4 must not mutate reservation artifacts itself.
35. P4 must include a dry-run that only lists planned force-release calls.
36. P4 must include an apply gate.
37. P4 must include stale reasons returned by Agent Mail.
38. P4 must include force-release idempotency semantics.
39. P5 mutates live pane state.
40. P5 is the most dangerous mutator.
41. P5 must have dry-run.
42. P5 must have explain.
43. P5 must have idempotency.
44. P5 must have audit.
45. P5 must have rollback/preservation receipt.
46. P5 must have Agent Mail reservation handling.
47. P5 must have ntm actuation receipts.
48. P5 must not be a background kill path.
49. P6 should be read-only in MVP.
50. P6 should not mutate priorities automatically.
51. P6 should not mutate labels automatically.
52. P6 can file or update a bead only behind explicit apply.
53. M writes Markdown.
54. M must write via temp file plus fsync/rename.
55. M must include the source status row hash.
56. M must be idempotent for the window.
57. M must avoid partial files.
58. The current dispatch log is the strongest local pattern.
59. The current cooldown append is the weakest local pattern.
60. The plan should explicitly upgrade cooldown writes before relying on P2.
61. The plan should not create more non-atomic append files.
62. The plan should reuse `fw_jsonl_append_validated`.
63. The plan should define `selection-receipt/v1`.
64. The plan should define `status-summary/v1`.
65. The plan should define `morning-report/v1` metadata.
66. The plan should not define schemas in prose only.
67. The plan should include test fixtures for each schema.
68. The plan should include malformed-row tests.
69. The plan should include concurrent append tests if shell support exists.
70. The plan should include one rollback drill for P5 before auto-respawn.

## 17. Specific Revisions - Git-Diff Style Change 01

01. Change 01 title: make `bv --robot-next` the primary selector.
02. Target: `.flywheel/scripts/idle-state-probe.sh`.
03. Before: resolve `br`, call `br ready --json`, normalize ready list.
04. After: resolve `bv`, call `bv --robot-next`, normalize one candidate into existing candidate shape.
05. Fallback: call `br ready --json` only when `bv` is unavailable or invalid.
06. Add field: `selection_source`.
07. Add field: `selection_score`.
08. Add field: `selection_unblocks`.
09. Add field: `selection_data_hash`.
10. Add field: `selection_reasons`.
11. Add field: `selection_error` when degraded.
12. Do not sort `bv` output by priority/created_at.
13. Do not erase claim command.
14. Do not treat `br ready` count as candidate authority.
15. Acceptance: fixture `bv-next-ok.json` yields dispatch candidate from `bv`.
16. Acceptance: fixture `bv-next-empty.json` yields no dispatch and healthy no-candidate reason.
17. Acceptance: missing `bv` uses `br ready` degraded path.
18. Acceptance: malformed `bv` uses degraded path and logs error.
19. Acceptance: live probe selects `flywheel-4m2a` while current graph state holds.
20. This is the first implementation bead.

## 18. Specific Revisions - Git-Diff Style Change 02

01. Change 02 title: make cooldown a receipt, not hidden policy.
02. Target: `.flywheel/scripts/idle-pane-auto-dispatch.sh`.
03. Before: append pane and bead cooldowns with `printf >>`.
04. After: write `selection_suppressed` and `cooldown_recorded` rows through validated JSONL.
05. Before: cooldown suppresses local candidate list.
06. After: cooldown suppression is visible in status.
07. Add schema: `dispatch-selection-receipt/v1`.
08. Add field: `candidate_id`.
09. Add field: `candidate_source`.
10. Add field: `candidate_score`.
11. Add field: `suppressed`.
12. Add field: `suppression_reason`.
13. Add field: `retry_after_seconds`.
14. Add field: `upstream_gap`.
15. Add field: `dispatch_id`.
16. Add field: `pane`.
17. Add field: `idempotency_key`.
18. Do not choose second-best locally.
19. If top `bv` candidate is cooled down, skip dispatch and log visible DEGRADED status.
20. This should ship with P3, not alone.

## 19. Specific Revisions - Git-Diff Style Change 03

01. Change 03 title: define `flywheel-loop status --json`.
02. Target: flywheel-loop CLI surface, preferably helper-backed.
03. Before: humans read scattered dispatch logs, fuckup logs, ntm state, and plan files.
04. After: one command emits `status-summary/v1`.
05. Include: `generated_at`.
06. Include: `repo`.
07. Include: `session`.
08. Include: `driver_status`.
09. Include: `dispatches_last_window`.
10. Include: `closures_last_window`.
11. Include: `repeat_dispatch_rate`.
12. Include: `overdue_callbacks`.
13. Include: `fuckups_by_class`.
14. Include: `selection_sources`.
15. Include: `br_ready_fallback_count`.
16. Include: `suppressed_top_pick_count`.
17. Include: `stale_reservation_candidates`.
18. Include: `frozen_pane_candidates`.
19. Include: `repair_bead_age_summary`.
20. Include: `health`.
21. Add formatter: `--format markdown`.
22. Add watch: `--watch -i N`.
23. Add why: either `flywheel-loop why <dispatch-id>` or `status --why`.
24. Do not mutate state.
25. Do not create beads.
26. Tests: missing log.
27. Tests: malformed row.
28. Tests: healthy status.
29. Tests: degraded selector.
30. This is the second MVP bead.

## 20. Specific Revisions - Git-Diff Style Change 04

01. Change 04 title: convert morning ritual into status formatter.
02. Target: `.flywheel/` reporting script or status formatter.
03. Before: plan says morning artifact as a separate primitive.
04. After: `flywheel-loop status --since yesterday --format markdown > morning.md.tmp && atomic rename`.
05. Include: source status hash.
06. Include: window start/end.
07. Include: top three actions.
08. Include: selector health.
09. Include: graph next pick.
10. Include: repeated dispatches.
11. Include: overdue callbacks.
12. Include: top trauma classes.
13. Include: driver status.
14. Include: upstream issue drafts.
15. Include: "safe to ignore" section for low-priority noise.
16. Exclude: transcript dumps.
17. Exclude: generic praise.
18. Exclude: manual interpretation without source row.
19. Tests: idempotent regeneration.
20. This is the third MVP bead.

## 21. Specific Revisions - Git-Diff Style Change 05

01. Change 05 title: park P4 behind status evidence.
02. Target: plan, not implementation.
03. Before: P4 appears as an equal first-wave primitive.
04. After: P4 is a follow-up only if status proves stale reservations are top bottleneck.
05. Add issue/bead wording: "delegate stale reservation repair to Agent Mail."
06. Add acceptance: no direct DB mutation.
07. Add acceptance: dry-run by default.
08. Add acceptance: Agent Mail stale reasons included.
09. Add acceptance: force-release conflict handled.
10. Add acceptance: audit row emitted.
11. Do not include P4 in minimum viable cut.
12. Do not implement local TTL parser.
13. Do not add watcher auto-release.
14. Do not call this fleet autonomy until the repair path is safe.
15. This revision lowers blast radius.

## 22. Specific Revisions - Git-Diff Style Change 06

01. Change 06 title: route P5 through ntm.
02. Target: plan and future ntm/flywheel repair bead.
03. Before: pane freeze auto-respawn is a watcher idea.
04. After: pane freeze is ntm robot health plus repair actuation.
05. Add precondition: ntm snapshot says stale.
06. Add precondition: activity says frozen or unknown.
07. Add precondition: probe-before-respawn fails.
08. Add precondition: no recent Agent Mail or file activity.
09. Add precondition: active reservations are released/transferred safely.
10. Add dry-run.
11. Add explain.
12. Add audit.
13. Add idempotency.
14. Add preservation receipt.
15. Do not auto-apply until repeated safe receipts exist.
16. Do not include P5 in minimum viable cut.
17. This revision prevents evidence-destroying automation.

## 23. Specific Revisions - Git-Diff Style Change 07

01. Change 07 title: route P6 through `bv` alerts and status.
02. Target: plan and future upstream issue if needed.
03. Before: repair-bead aging is a watcher primitive.
04. After: status reports repair-bead aging; `bv` owns whether aging changes graph attention.
05. Add status field: `repair_beads.count`.
06. Add status field: `repair_beads.oldest`.
07. Add status field: `repair_beads.blocking_count`.
08. Add status field: `repair_beads.by_trauma_class`.
09. Add status field: `repair_beads.with_no_progress`.
10. Add upstream draft only if `bv --robot-alerts` cannot surface this.
11. Do not override dispatch selection locally.
12. Do not mutate priority automatically.
13. Do not mutate labels automatically.
14. Do not include P6 in MVP.
15. This revision keeps one ranking brain.

## 24. Specific Revisions - Git-Diff Style Change 08

01. Change 08 title: add upstream-report drafts, not upstream pushes.
02. Target: plan artifacts.
03. Before: plan asserts some upstream gaps but does not fully separate local patch from upstream relationship.
04. After: add `.flywheel/PLANS/.../upstream-drafts/` with issue drafts.
05. Draft 01: `bv robot-next exclusions`.
06. Draft 02: `br ready status semantics`.
07. Draft 03: `ntm send receipt`.
08. Each draft uses the issue-chain body order.
09. Each draft includes reproduction commands.
10. Each draft includes expected vs observed.
11. Each draft includes file-line citations.
12. Each draft includes cost citation.
13. Each draft includes tracking placeholder.
14. Each draft says out of scope.
15. Each draft says duplicate search required.
16. No draft is filed from this lane.
17. No Jeff repo is patched from this lane.
18. This keeps relationship quality intact.

## 25. Minimum Viable Cut

01. Minimum viable subset count: 3.
02. MVP item 01: replace watcher selection with `bv --robot-next`.
03. MVP item 02: add selection/cooldown receipts and `flywheel-loop status --json`.
04. MVP item 03: generate morning artifact from status JSON.
05. MVP explicitly excludes P4.
06. MVP explicitly excludes P5.
07. MVP explicitly excludes P6 as a dispatch override.
08. MVP includes P6 only as a status field if cheap.
09. MVP includes upstream issue drafts but no filing.
10. MVP includes tests for selector behavior.
11. MVP includes tests for status aggregation.
12. MVP includes tests for morning report idempotence.
13. MVP includes L112-style artifact validation.
14. MVP includes line-count/file-length discipline.
15. MVP includes Agent Mail reservations for implementation files.
16. MVP success metric 01: repeat dispatches per unique bead decrease materially.
17. MVP success metric 02: `br_ready_fallback_count=0` when `bv` is healthy.
18. MVP success metric 03: closure rate improves or at least bad dispatches drop.
19. MVP success metric 04: status can explain every skipped dispatch.
20. MVP success metric 05: morning report names exact next three actions.
21. MVP failure metric 01: top `bv` candidate repeatedly suppressed with no alternative for more than two ticks.
22. MVP failure metric 02: no dispatch occurs and status cannot explain why.
23. MVP failure metric 03: malformed logs make status crash.
24. MVP failure metric 04: morning report is prose-only.
25. MVP failure metric 05: P4/P5/P6 get implemented before P1/P3 evidence.
26. MVP should be one tight wave.
27. MVP should not try to solve all 390 fuckups.
28. MVP should solve the wrong-work selector and make the next 390 visible.
29. MVP should take the night from silent failure to inspected control loop.
30. MVP should then let the next plan-space pass decide P4-P6 order.

## 26. Verdict

01. Verdict: revise.
02. `bv` replacement endorsed: conditional yes.
03. Conditional means "use `bv --robot-next` immediately for selection."
04. Conditional means "do not turn the watcher into a new priority engine."
05. Conditional means "file upstream drafts for missing exclusion and ready-status semantics."
06. Conditional means "measure before implementing P4-P6."
07. The plan's strongest claim is correct: `br ready` should not be the dispatch selector.
08. The plan's weakest move is treating every observed bottleneck as a watcher primitive.
09. Jeff's stack already divides those responsibilities.
10. Follow that division.
11. Deploy the five-line stop-bleed.
12. Add selector receipts.
13. Add status.
14. Generate the morning report from status.
15. Park stale reservations behind Agent Mail repair.
16. Park pane respawn behind ntm repair.
17. Park repair-bead aging behind `bv` alerts/status.
18. Draft upstream issues, do not file until duplicate search.
19. Do not patch Jeff repos.
20. Do not push to Jeff remotes.
21. Do not ship a broad six-primitive control system without measuring the first repair.
22. The night failed because the loop could not distinguish "available work" from "right work."
23. `bv` already encodes right-work selection.
24. The watcher should consume it.
25. The status command should make the consumption auditable.
26. That is the Jeff-compatible version of this plan.
27. That is also the Joshua-taste version: small sharp fix, explicit ownership, no local forever-hacks.
28. Self-grade: 9.6.
29. Jeff authenticity: 9.6.
30. Donella compatibility: 9.5.
31. Joshua taste: 9.6.
32. Public score: 9.5.
33. Proposed changes count: 8.
34. Working sibling diffs count: 20.
35. Socraticode queries: 10.
36. Indexed chunks observed: 893496.
37. Skills consulted: jeff-swarm-ops, jeff-planning-enhanced, jeff-issue-chain, beads-bv, beads-br, canonical-cli-scoping, accretive-cron-orchestration, ntm, socraticode, agent-mail.
38. No bead filed from this lane because this is a plan-space review artifact and upstream drafts are explicitly not filed.
39. L112 probe expectation: file exists, line count exceeds 600, contains canonical-cli-scoping or robot terms, contains bv/br ready terms.
40. Final answer: revise and ship P1/P3/M as the first cut.

