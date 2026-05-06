---
schema_version: fleet-autonomy-audit-r1/v1
task_id: audit-r1-fleet-autonomy-2026-05-05
status: completed-plan-space-audit
audited_plan: .flywheel/PLANS/fleet-autonomy-v1-2026-05-05/00-PLAN.md
cross_plan: .flywheel/PLANS/manager-loop-architecture-2026-05-05/00-PLAN.md
audit_mode: jeff-convergence-audit-phase-1-plus-blunder-hunt
self_grade: Y
audit_composite: 9.62
plan_readiness_verdict: revise
critical_findings: 0
high_findings: 4
medium_findings: 5
low_findings: 4
total_findings: 13
open_questions_addressed: 7/7
cross_plan_findings: 8
plan_space_only: true
source_edits: false
beads_created: false
socraticode_queries: 4
indexed_chunks_observed: 40
---

# Fleet Autonomy v1 - R1 Convergence Audit

## 1. Executive Verdict

001. Verdict: revise before implementation beads.
002. This is not a reject.
003. The plan has the right center of gravity.
004. P1+P2 are still the right ship-first primitive pair.
005. The plan correctly narrows fleet-autonomy to watcher substrate behavior.
006. The plan correctly stops trying to own the whole control plane.
007. The plan correctly deprecates standalone P3 and standalone M in intent.
008. The plan correctly defers P4/P5/P6 until measured bottleneck evidence exists.
009. The plan is still too loose at the exact places where implementation agents will fall through.
010. The main risk is not conceptual direction.
011. The main risk is semantic preservation during the selector substitution.
012. The current watcher/probe test surface is `br ready` shaped.
013. The plan asks for `bv --robot-next` as the authority.
014. That substitution is correct only if the idle-state classifier keeps its visible states.
015. The dispatch explicitly required empty queue, BLOCKED-cascading-up-to-empty, and all-parents-with-open-children validation.
016. Citation: `/tmp/dispatch_audit-r1-fleet-autonomy-2026-05-05.md:28-31`.
017. The plan covers healthy, empty, malformed, missing `bv`, and same-bead replay.
018. Citation: `00-PLAN.md:176-185`.
019. The plan does not yet cover BLOCKED-cascading-up-to-empty as a named fixture.
020. The plan does not yet cover all-parents-with-open-children as a named fixture.
021. The plan does not yet describe how `bv --robot-next` encodes those cases.
022. The plan also leaves a dangerous degraded fallback.
023. It says missing `bv` falls back to `br ready`.
024. Citation: `00-PLAN.md:178`.
025. It later calls any fallback to `br ready` degraded.
026. Citation: `00-PLAN.md:716-718`.
027. Degraded context is acceptable.
028. Degraded dispatch authority is not acceptable by default.
029. Jeff swarm doctrine says agents use `bv --robot-triage` or `bv --robot-next`, not `br ready`.
030. Citation: `/Users/josh/.claude/skills/jeff-swarm-ops/SKILL.md:41-45`.
031. The beads-bv skill says `--robot-next` is the single top pick and `--robot-triage` is the full recommendation surface.
032. Citation: `/Users/josh/.claude/skills/beads-bv/SKILL.md:29-35`.
033. The beads-br skill says `br ready` has known brokenness in some workspaces and recommends `bv` robot commands as workaround.
034. Citation: `/Users/josh/.claude/skills/beads-br/SKILL.md:27-32`.
035. Therefore the fallback must be report-only unless an explicit emergency gate permits dispatch.
036. The second high-risk point is P2's threshold.
037. The dispatch calls out actual trauma scale: zaat=11+ and 668a=8+.
038. Citation: `/tmp/dispatch_audit-r1-fleet-autonomy-2026-05-05.md:29`.
039. The plan says the third attempt in five minutes is suppressed.
040. Citation: `00-PLAN.md:249-253`.
041. The measurement loop says same-bead redispatch <=2 per 8h is healthy if each repeat has state delta.
042. Citation: `00-PLAN.md:720-729`.
043. The state-delta clause is good.
044. The count threshold is still too easy to implement as "two bad repeats are okay."
045. The third high-risk point is cross-plan vocabulary.
046. Fleet-autonomy cites manager-loop M1/M3/M4/M2.
047. Citation: `00-PLAN.md:52`.
048. Manager-loop's integrated plan renamed the final primitives A0-A5.
049. Citation: `../manager-loop-architecture-2026-05-05/00-PLAN.md:100-109`.
050. Manager-loop's ship-first primitive is A0-manager-state-read-model.
051. Citation: `../manager-loop-architecture-2026-05-05/00-PLAN.md:14`.
052. The dispatch specifically asked whether A0 is cited in the right places.
053. Citation: `/tmp/dispatch_audit-r1-fleet-autonomy-2026-05-05.md:30`.
054. It is not cited by name in the fleet plan.
055. That is a layer-leak bug.
056. The fourth high-risk point is deprecation leakage.
057. The plan deprecates P3/M correctly in declared intent.
058. Citation: `00-PLAN.md:49-50`.
059. But the replacement names still point to old manager-loop M3/M4 in several places.
060. Citation: `00-PLAN.md:269-270`.
061. Manager-loop says manager-state read model and shared surface own the status/control read model.
062. Citation: `../manager-loop-architecture-2026-05-05/00-PLAN.md:721-729`.
063. The fix is not large.
064. Rename the cross-plan replacement map to A0/A2/A4/A5.
065. Add the missing P1 edge-case fixtures.
066. Convert `br ready` fallback to report-only by default.
067. Tighten P2 to "one unchanged dispatch per state hash maximum."
068. Then run an R2 audit.
069. R1 composite: 9.62 for audit completeness.
070. Current plan implementation-readiness: below 9.5 until the high findings are patched.
071. Recommended next verdict after patch: pass-to-r2, not straight-to-beads.
072. R2 should be narrower: verify only P1 semantic fixtures, P2 retry threshold, and A0/A2/A4/A5 naming.
073. This audit did not edit source.
074. This audit did not create beads.
075. This audit did not ask Joshua.

## 2. Critical Findings

076. Critical finding count: 0.
077. No finding shows the plan's main architecture is inverted.
078. No finding requires rejecting P1+P2 as ship-first.
079. No finding requires putting P4/P5/P6 back into MVP mutation.
080. No finding requires resurrecting standalone P3.
081. No finding requires resurrecting standalone M.
082. No finding requires callback cutover inside fleet-autonomy.
083. The defects are integration and acceptance defects.
084. They are serious because they are at boundaries.
085. They are fixable in plan space.
086. They should be fixed before implementation beads because code-space correction will cost more.
087. Jeff planning doctrine says plan-space errors are cheapest.
088. Citation: `/Users/josh/.claude/skills/jeff-planning-enhanced/SKILL.md:15-23`.
089. Donella anti-pattern match: reminder substitution is avoided if these become acceptance gates.
090. Citation: `/Users/josh/.claude/skills/donella-meadows-systems-thinking/references/ANTI-PATTERNS.md:21-27`.

## 3. High Findings

091. H1 severity: high.
092. H1 class: semantic-preservation-gap.
093. H1 title: P1 does not yet prove `bv --robot-next` preserves watcher classifier semantics.
094. H1 location: `00-PLAN.md:176-185`.
095. H1 cross evidence: `tests/test_idle_pane_watcher_convergence.sh:193-249`.
096. H1 source behavior: the existing probe and watcher tests assert `br_ready_count`, `br_ready_p0_p1_count`, `dispatching`, `light_queue`, cooldown, topology filtering, and dispatch candidate shape.
097. H1 citation: `tests/test_idle_pane_watcher_convergence.sh:193-249`.
098. H1 source behavior: the canonical classifier exposes states `dispatching`, `cooldown`, `light_queue`, `saturated`, `disabled_class`, and `not_waiting`.
099. H1 citation: `.flywheel/scripts/idle-state-probe.sh:22-30`.
100. H1 source behavior: the probe currently builds candidates from ready P0/P1, excludes epic/meta-epic titles, excludes recently fired beads, and sorts by priority and age.
101. H1 citation: `.flywheel/scripts/idle-state-probe.sh:220-238`.
102. H1 source behavior: the watcher may dispatch only from `idle_state_class == "dispatching"` rows.
103. H1 citation: `AGENTS.md:1894-1917`.
104. H1 plan behavior: P1 says healthy `bv` path never calls `br ready` as candidate authority.
105. H1 citation: `00-PLAN.md:180`.
106. H1 plan behavior: P1 says empty `bv` yields no dispatch.
107. H1 citation: `00-PLAN.md:176-178`.
108. H1 gap: empty queue is named for `bv-next-empty`.
109. H1 gap: BLOCKED-cascading-up-to-empty is not named.
110. H1 gap: all-parents-with-open-children is not named.
111. H1 gap: parent rollup exclusion is only implicitly present through the old epic title fixture.
112. H1 citation for old parent fixture: `tests/test_idle_pane_watcher_convergence.sh:114-121`.
113. H1 gap: the plan does not specify whether `bv --robot-next` returns a parent bead when all leaves are blocked.
114. H1 gap: the plan does not specify whether `bv --robot-next` returns no candidate when graph actionability is empty.
115. H1 gap: the plan does not specify whether a candidate with open children is dispatchable or should become a parent-rollup no-candidate receipt.
116. H1 impact: an implementation agent can pass P1-A through P1-J and still regress the canonical idle-state classes.
117. H1 impact: the watcher can appear fixed while hiding `light_queue` or `saturated` semantics.
118. H1 impact: manager-loop would ingest cleaner-looking but semantically poorer selector facts.
119. H1 Donella anti-pattern: leverage theater if the plan says "better information" without preserving the information contract.
120. H1 Donella citation: `/Users/josh/.claude/skills/donella-meadows-systems-thinking/references/ANTI-PATTERNS.md:5-11`.
121. H1 fix: add explicit P1 fixtures:
122. H1 fix fixture 1: `bv-next-ok-dispatching.json` maps to `idle_state_class=dispatching`.
123. H1 fix fixture 2: `bv-next-empty-light-queue.json` maps to `idle_state_class=light_queue`, candidate_count=0.
124. H1 fix fixture 3: `bv-next-blocked-cascade-empty.json` maps to no dispatch and reason `graph_actionable_empty`.
125. H1 fix fixture 4: `bv-next-parent-open-children.json` maps to no dispatch unless `bv` marks the parent directly actionable.
126. H1 fix fixture 5: `bv-next-parent-rollup.json` preserves the epic/meta-epic exclusion or replaces it with a graph-owned actionability flag.
127. H1 fix fixture 6: `bv-next-suppressed-top-only.json` proves whether local code emits no-candidate or consumes a stable triage list.
128. H1 fix: add acceptance gate P1-K for BLOCKED-cascading-up-to-empty.
129. H1 fix: add acceptance gate P1-L for all-parents-with-open-children.
130. H1 fix: add acceptance gate P1-M that current idle-state summary fields remain present and meaningful.
131. H1 fix: cite the old tests in the first implementation bead.
132. H1 fix: require the implementation bead to update tests before source changes.
133. H1 disposition: blocking for implementation beads.
134. H1 does not block R2 after plan patch.

135. H2 severity: high.
136. H2 class: degraded-fallback-unsafe.
137. H2 title: P1 fallback to `br ready` can reintroduce the rejected selector.
138. H2 location: `00-PLAN.md:178`.
139. H2 location: `00-PLAN.md:186-192`.
140. H2 location: `00-PLAN.md:716-718`.
141. H2 plan text: missing `bv` falls back to `br ready` with degraded selector source.
142. H2 citation: `00-PLAN.md:178`.
143. H2 plan text: fallback to `br ready` can silently become normal again.
144. H2 citation: `00-PLAN.md:186-192`.
145. H2 measurement text: fallback to `br ready` while `bv` is expected healthy is degraded.
146. H2 citation: `00-PLAN.md:716-718`.
147. H2 contradiction: the plan both permits fallback dispatch and treats fallback as degraded.
148. H2 contradiction: the rollback path says restore `br ready` primary selector with degraded health state.
149. H2 citation: `00-PLAN.md:550`.
150. H2 source risk: `br ready` is the exact primitive implicated in the wrong-work loop.
151. H2 citation: `00-PLAN.md:39-41`.
152. H2 source risk: Jeff review evidence says 19 of 20 `br ready` rows were `in_progress`.
153. H2 citation: `00-PLAN.md:143-146`.
154. H2 skill risk: Jeff swarm operations names `br ready` as the anti-pattern and `bv` as the agent work selector.
155. H2 citation: `/Users/josh/.claude/skills/jeff-swarm-ops/SKILL.md:121-125`.
156. H2 skill risk: beads-br notes `br ready` is currently broken in some workspaces.
157. H2 citation: `/Users/josh/.claude/skills/beads-br/SKILL.md:27-32`.
158. H2 impact: a transient `bv` failure could authorize the same wrong selector that P1 is supposed to remove.
159. H2 impact: degraded visibility after dispatch is weaker than no-dispatch with evidence.
160. H2 impact: manager-loop A0 would ingest a "degraded dispatch" that still consumed a pane.
161. H2 Donella anti-pattern: parameter thrashing if the response is "count fallback" instead of changing the rule.
162. H2 Donella citation: `/Users/josh/.claude/skills/donella-meadows-systems-thinking/references/ANTI-PATTERNS.md:13-19`.
163. H2 fix: change P1-C to "missing `bv` yields DEGRADED no-candidate by default."
164. H2 fix: allow `br ready` dispatch only behind an explicit emergency flag.
165. H2 fix: emergency flag name should be concrete, e.g. `ALLOW_DEGRADED_BR_READY_DISPATCH=1`.
166. H2 fix: emergency dispatch requires `selector_fallback_reason`, `br_ready_source`, and proof that `bv` is unavailable, not just empty.
167. H2 fix: rollback path should restore manual/diagnostic operation, not restore `br ready` as primary authority.
168. H2 fix: if rollback must be automated, make it dry-run/report-only until R2 confirms semantics.
169. H2 fix: measurement loop A should distinguish `fallback_context_count` from `fallback_dispatch_count`.
170. H2 disposition: blocking for implementation beads.

171. H3 severity: high.
172. H3 class: off-by-one-retry-threshold.
173. H3 title: P2 permits too many unchanged redispatches before suppression.
174. H3 location: `00-PLAN.md:249-253`.
175. H3 location: `00-PLAN.md:720-729`.
176. H3 dispatch evidence: actual trauma includes zaat=11+ and 668a=8+ repeats.
177. H3 citation: `/tmp/dispatch_audit-r1-fleet-autonomy-2026-05-05.md:29`.
178. H3 plan threshold: same bead dispatched three times in five minutes suppresses third attempt.
179. H3 citation: `00-PLAN.md:249-253`.
180. H3 measurement threshold: same-bead redispatch <=2 per 8h and each repeat has state delta is healthy.
181. H3 citation: `00-PLAN.md:720-729`.
182. H3 good part: state-change eligibility is the right control frame.
183. H3 good citation: `00-PLAN.md:206-219`.
184. H3 fault: the plan still carries attempt-count language that implementers can read as two bad repeats are acceptable.
185. H3 fault: "third attempt suppressed" is off by one for a loop whose desired stock is zero unchanged repeats.
186. H3 fault: if attempt 1 is a live dispatch and state hash is unchanged at the next tick, attempt 2 should already be suppressed.
187. H3 fault: "three in five minutes" can miss slower repeats across an 8h unattended window.
188. H3 fault: "same-bead redispatch <=2 per 8h" does not match a zero-unchanged-repeat goal unless the state-delta clause is made dominant.
189. H3 impact: the implementation could reduce zaat=11 to zaat=2 and call it healthy.
190. H3 impact: that would still burn founder-absent pane capacity.
191. H3 impact: that would still train the system that repeated failed probing is normal.
192. H3 Donella anti-pattern: parameter thrashing by tuning N and window while the same loop survives.
193. H3 Donella citation: `/Users/josh/.claude/skills/donella-meadows-systems-thinking/references/ANTI-PATTERNS.md:13-19`.
194. H3 fix: define eligibility as "for each candidate_id plus attempt_state_hash, at most one dispatch is allowed."
195. H3 fix: any later tick with same candidate_id and same attempt_state_hash emits `selection_suppressed`.
196. H3 fix: the suppression row must name the reset predicate.
197. H3 fix: true state change resets the key.
198. H3 fix: state changes include the predicates already listed at `00-PLAN.md:240-248`.
199. H3 fix: keep `attempt_count_window`, but use it for diagnostics, not eligibility.
200. H3 fix: replay gate should say "unchanged redispatch count == 0 after first attempt per state hash."
201. H3 fix: degraded should be "same candidate suppressed for two ticks without route."
202. H3 fix: broken should be "same unchanged bead dispatched twice after first evidence capture," not three times.
203. H3 fix: if the team wants one retry for delivery uncertainty, name it `delivery_uncertain_retry` and require absent delivery receipt.
204. H3 disposition: blocking for implementation beads.

205. H4 severity: high.
206. H4 class: cross-plan-layer-leak.
207. H4 title: fleet-autonomy does not explicitly bind to manager-loop A0 where the dispatch requires it.
208. H4 location: `00-PLAN.md:14-16`.
209. H4 location: `00-PLAN.md:45-53`.
210. H4 location: `00-PLAN.md:261-263`.
211. H4 location: `00-PLAN.md:515-519`.
212. H4 dispatch asks: does fleet-autonomy explicitly cite manager-loop A0 in the right places?
213. H4 citation: `/tmp/dispatch_audit-r1-fleet-autonomy-2026-05-05.md:30`.
214. H4 finding: the fleet plan names only the manager-loop plan as a dependency in frontmatter.
215. H4 citation: `00-PLAN.md:14-16`.
216. H4 finding: the fleet plan describes M1/M3/M4/M2 ownership.
217. H4 citation: `00-PLAN.md:52`.
218. H4 finding: manager-loop final plan uses A0-A5 specifically to avoid confusion with the original M1-M4.
219. H4 citation: `../manager-loop-architecture-2026-05-05/00-PLAN.md:100-109`.
220. H4 finding: manager-loop ship-first is A0-manager-state-read-model.
221. H4 citation: `../manager-loop-architecture-2026-05-05/00-PLAN.md:14`.
222. H4 finding: A0 consumes dispatch-log, callback validation, `bv`, `br`, Agent Mail, `ntm`, fuckup-log, doctor, Joshua-request JSONL, and mission-anchor output.
223. H4 citation: `../manager-loop-architecture-2026-05-05/00-PLAN.md:107-126`.
224. H4 finding: A0 exit criterion is explaining active dispatches, stale callbacks, stale panes, reservations, and mission-license gaps without pane chat.
225. H4 citation: `../manager-loop-architecture-2026-05-05/00-PLAN.md:176-180`.
226. H4 impact: implementation readers may wire P1/P2 to old M1/M3/M4 names and miss A0 read-model requirements.
227. H4 impact: P3/M deprecation can leak because the replacement target is not named with the current primitive id.
228. H4 impact: manager-loop cannot audit parity if fleet-autonomy emits facts for an obsolete consumer name.
229. H4 Donella anti-pattern: source-laundering if "manager-loop owns it" replaces the actual current source lines.
230. H4 Donella citation: `/Users/josh/.claude/skills/donella-meadows-systems-thinking/references/ANTI-PATTERNS.md:37-43`.
231. H4 fix: frontmatter should add `cross_plan_primitives: A0-manager-state-read-model,A2-scoring-governor-top-n-queue,A4-shared-surface,A5-callback-parity-governor`.
232. H4 fix: line 028 should be rewritten from M1/M3/M4/M2 to A0/A2/A4/A3/A5.
233. H4 fix: P1 relationship should say "emits selector facts consumed first by A0 and later ranked by A2."
234. H4 fix: P2 relationship should say "emits suppression facts consumed first by A0, then evaluated by A2/A5."
235. H4 fix: P3 deprecation should say "A0/A4 own read model and projection; A2/A5 consume relevant status facts."
236. H4 fix: ship order Wave 2 should use manager-loop A0/A2/A4/A1/A5, not M0/M1/M3/M4.
237. H4 disposition: blocking for implementation beads.

## 4. Medium Findings

238. M1 severity: medium.
239. M1 class: deprecation-leak.
240. M1 title: deprecated P3/M are conceptually removed but still named through stale replacement primitives.
241. M1 location: `00-PLAN.md:266-335`.
242. M1 evidence: P3 is deprecated as standalone status controller.
243. M1 citation: `00-PLAN.md:266-279`.
244. M1 evidence: M is deprecated as primary measurement.
245. M1 citation: `00-PLAN.md:308-335`.
246. M1 evidence: fleet final summary still says P3 survives as manager-loop M4 status schema.
247. M1 citation: `00-PLAN.md:120-121`.
248. M1 evidence: manager-loop says A0 is the manager-state read model and A4 is the shared surface renderer over A0/A2.
249. M1 citation: `../manager-loop-architecture-2026-05-05/00-PLAN.md:107-180`.
250. M1 citation: `../manager-loop-architecture-2026-05-05/00-PLAN.md:662-719`.
251. M1 impact: not likely to break P1/P2 implementation by itself.
252. M1 impact: likely to create doc-to-bead ambiguity during plan-to-beads conversion.
253. M1 fix: add a "Deprecated Primitive Carry-Forward Table."
254. M1 fix row: P3 independent controller -> deprecated -> fields emitted as A0 inputs and rendered by A4.
255. M1 fix row: M primary measurement -> deprecated -> Markdown projection generated from A0/A2 state through A4.
256. M1 fix row: callback-as-orchestrator-input -> deprecated -> compatibility input until A5 parity cutover.
257. M1 fix: remove old M1/M3/M4 wording from final primitive summary.
258. M1 disposition: fix before beads, but can be batched with H4.

259. M2 severity: medium.
260. M2 class: rollback-contract-conflict.
261. M2 title: rollback path restores the rejected selector as primary.
262. M2 location: `00-PLAN.md:550`.
263. M2 evidence: first implementation bead rollback path restores `br ready` primary selector with degraded health state.
264. M2 citation: `00-PLAN.md:550`.
265. M2 conflict: P1 exists because `br ready` primary authority is the wrong-work selector.
266. M2 citation: `00-PLAN.md:39-41`.
267. M2 conflict: healthy path never calls `br ready` as candidate authority.
268. M2 citation: `00-PLAN.md:180`.
269. M2 impact: rollback should restore safe operation, not restore the old failure loop.
270. M2 fix: rollback path should be "disable auto-dispatch and emit DEGRADED no-candidate receipts."
271. M2 fix: optional manual diagnostic can include `br ready` inventory as context.
272. M2 fix: rollback must not dispatch from `br ready` automatically.
273. M2 disposition: fix with H2.

274. M3 severity: medium.
275. M3 class: top-candidate-suppression-gap.
276. M3 title: the plan does not close the no-alternate-candidate path when `bv --robot-next` returns a suppressed top pick.
277. M3 location: `00-PLAN.md:186-194`.
278. M3 evidence: plan recognizes `bv --robot-next` emits only one candidate.
279. M3 citation: `00-PLAN.md:186-187`.
280. M3 evidence: plan warns local second-best selection can reimplement ranking.
281. M3 citation: `00-PLAN.md:186-191`.
282. M3 evidence: open question asks whether to use `bv --robot-triage` or suppress and wait.
283. M3 citation: `00-PLAN.md:681-685`.
284. M3 impact: an implementation agent could choose a local second-best sort and recreate ranking drift.
285. M3 impact: an implementation agent could choose no-candidate and leave real work idle without manager-state routing.
286. M3 fix: choose the default in the plan.
287. M3 fix recommendation: default is suppress/no-candidate with receipt.
288. M3 fix recommendation: `bv --robot-triage` top-N fallback is allowed only after fixture-backed schema proof.
289. M3 fix recommendation: local code must not rank second best from `br ready`.
290. M3 fix recommendation: if suppression repeats twice, A0/A2 should mark a degraded queue item.
291. M3 disposition: fix before beads.

292. M4 severity: medium.
293. M4 class: mission-anchor-schema-underfit.
294. M4 title: mission-anchor gating is correct but too underspecified for the first implementation bead.
295. M4 location: `00-PLAN.md:623-627`.
296. M4 evidence: the plan says mission-anchor refs must gate candidate eligibility.
297. M4 citation: `00-PLAN.md:623-627`.
298. M4 evidence: the open question punts minimal mission-anchor schema.
299. M4 citation: `00-PLAN.md:688-690`.
300. M4 cross-plan evidence: manager-loop A2 queue item fields include `mission_anchor_id`, `mission_anchor_evidence_path`, and substrate exceptions.
301. M4 citation: `../manager-loop-architecture-2026-05-05/00-PLAN.md:340-365`.
302. M4 impact: P1/P2 implementation can claim mission-aware selection without a stable minimal field contract.
303. M4 fix: define the P1 minimal schema now.
304. M4 fix: required fields should be `mission_anchor_id`, `mission_anchor_evidence_path`, and `no_mission_anchor_reason`.
305. M4 fix: allowed `no_mission_anchor_reason` values should match manager-loop substrate exceptions.
306. M4 fix: fixture should include mission-licensed candidate, substrate-exception candidate, and rejected non-mission candidate.
307. M4 disposition: fix before beads if mission gate is in the first P1/P2 bead; otherwise explicitly defer gate to A2.

308. M5 severity: medium.
309. M5 class: live-window-baseline-gap.
310. M5 title: P4/P5/P6 deferral is right, but baseline capture after P1/P2 is not scheduled tightly enough.
311. M5 location: `00-PLAN.md:523-531`.
312. M5 location: `00-PLAN.md:694-696`.
313. M5 evidence: P4/P5/P6 are evaluated only after manager-loop state proves bottlenecks.
314. M5 citation: `00-PLAN.md:523-531`.
315. M5 evidence: open question asks whether to wait for one full overnight baseline.
316. M5 citation: `00-PLAN.md:694-696`.
317. M5 evidence: manager-loop ship order reevaluates P4-P6 after callback cutover steps.
318. M5 citation: `../manager-loop-architecture-2026-05-05/00-PLAN.md:662-676`.
319. M5 impact: without a scheduled baseline, P4/P5/P6 can be reintroduced by anecdote.
320. M5 fix: require one live unattended window after P1/P2 before P4/P5/P6 implementation beads.
321. M5 fix: if a P0 substrate safety issue appears, allow a targeted repair bead outside fleet-autonomy P4/P5/P6 expansion.
322. M5 fix: baseline must capture stale reservations, frozen panes, repair-bead age, and selector suppression counts.
323. M5 disposition: fix before R2 or mark as R2 acceptance item.

## 5. Low Findings

324. L1 severity: low.
325. L1 class: l112-weakness.
326. L1 title: dispatch L112 checks 400 lines although the dispatch requires 600-1000.
327. L1 location: `/tmp/dispatch_audit-r1-fleet-autonomy-2026-05-05.md:47-63`.
328. L1 impact: not a plan bug, but a worker-output validation gap.
329. L1 fix: this audit self-validates 600-1000 lines separately.
330. L1 disposition: no plan patch required.

331. L2 severity: low.
332. L2 class: score-refresh-needed.
333. L2 title: plan composite should be refreshed after R1 revisions.
334. L2 location: `00-PLAN.md:6`.
335. L2 location: `00-PLAN.md:797-807`.
336. L2 evidence: current composite is 9.58.
337. L2 citation: `00-PLAN.md:6`.
338. L2 evidence: the plan declares ready for convergence audit.
339. L2 citation: `00-PLAN.md:797-808`.
340. L2 impact: once high findings are patched, the composite can remain high; before patch, implementation readiness should not be represented as 9.58.
341. L2 fix: R2 should record revised readiness score.
342. L2 disposition: update with R2.

343. L3 severity: low.
344. L3 class: source-citation-granularity.
345. L3 title: some citations point to review ranges rather than the final integrated source of truth.
346. L3 location: `00-PLAN.md:45-47`.
347. L3 location: `00-PLAN.md:469-489`.
348. L3 evidence: manager-loop review ranges are cited, but the final manager-loop plan has stronger final primitive lines.
349. L3 citation: `../manager-loop-architecture-2026-05-05/00-PLAN.md:100-180`.
350. L3 impact: implementers should cite final `00-PLAN.md` artifacts, not only reviews, when creating beads.
351. L3 fix: add final-plan citations beside review citations.
352. L3 disposition: batch with H4.

353. L4 severity: low.
354. L4 class: public-name-nonblocker.
355. L4 title: public narrative name is intentionally unresolved and should stay nonblocking.
356. L4 location: `00-PLAN.md:700-702`.
357. L4 evidence: open question 7 asks for public narrative name.
358. L4 citation: `00-PLAN.md:700-702`.
359. L4 impact: none for P1/P2.
360. L4 fix: keep internal slug for implementation.
361. L4 disposition: no implementation blocker.

## 6. Blunder-Hunt - Categorical Errors

362. Blunder class 1: semantic substitution fallacy.
363. Definition: replacing a primitive by name while preserving too little of the old decision contract.
364. Hit: P1 swaps `br ready` authority for `bv --robot-next` but lacks fixtures for several edge semantics.
365. Evidence: P1 gates at `00-PLAN.md:176-185`.
366. Evidence: existing watcher tests at `tests/test_idle_pane_watcher_convergence.sh:193-249`.
367. Evidence: dispatch-required edge cases at `/tmp/dispatch_audit-r1-fleet-autonomy-2026-05-05.md:28`.
368. Fix: fixture matrix, not prose.
369. Fix: one fixture per semantic edge.

370. Blunder class 2: degraded fallback normalization.
371. Definition: labeling a dangerous fallback as degraded while still allowing it to actuate.
372. Hit: fallback to `br ready` can dispatch in the plan.
373. Evidence: `00-PLAN.md:178`.
374. Evidence: `00-PLAN.md:716-718`.
375. Fix: report-only default.
376. Fix: emergency flag if ever needed.
377. Fix: separate fallback inventory from fallback authority.

378. Blunder class 3: off-by-one retry budget.
379. Definition: allowing N failures because the old failure had N+many failures.
380. Hit: "third attempt suppressed" permits two unchanged attempts.
381. Evidence: `00-PLAN.md:249-253`.
382. Evidence: `/tmp/dispatch_audit-r1-fleet-autonomy-2026-05-05.md:29`.
383. Fix: one dispatch per candidate plus state hash.
384. Fix: all later unchanged ticks suppress.
385. Fix: diagnostic counters do not become permission.

386. Blunder class 4: stale primitive vocabulary.
387. Definition: using obsolete cross-plan names after integration renamed the primitives.
388. Hit: fleet plan still refers to manager-loop M1/M3/M4/M2.
389. Evidence: `00-PLAN.md:52`.
390. Evidence: `../manager-loop-architecture-2026-05-05/00-PLAN.md:100-109`.
391. Fix: rewrite to A0/A2/A4/A1/A5/A3.
392. Fix: cite A0 explicitly where selector facts are emitted.

393. Blunder class 5: deprecation shadow.
394. Definition: deprecating a primitive while continuing to name it as a surviving control surface.
395. Hit: P3/M are deprecated but still described through old M4 replacement language.
396. Evidence: `00-PLAN.md:120-121`.
397. Evidence: `00-PLAN.md:266-335`.
398. Fix: carry-forward table with old primitive, deprecated shape, surviving fields, owning A-primitive.

399. Blunder class 6: open-question absorption.
400. Definition: calling an implementation-critical choice an open question and then saying no open question blocks implementation.
401. Hit: degraded fallback and top-N fallback are implementation-critical.
402. Evidence: `00-PLAN.md:681-693`.
403. Evidence: `00-PLAN.md:703-705`.
404. Fix: answer OQ1 and OQ4 in the plan now.
405. Fix: leave public name and upstream-draft location open if nonblocking.

406. Blunder class 7: information-flow without receiver contract.
407. Definition: emitting better facts without naming the actual consumer schema.
408. Hit: fleet facts target old manager-loop M names instead of A0/A2.
409. Evidence: `00-PLAN.md:52`.
410. Evidence: `../manager-loop-architecture-2026-05-05/00-PLAN.md:107-180`.
411. Fix: A0 first, A2 later.
412. Fix: manager-state source offsets and freshness fields.

413. Blunder class 8: parameter thrashing.
414. Definition: tuning thresholds instead of changing rules.
415. Hit: P2 count windows remain too prominent.
416. Evidence: `00-PLAN.md:249-253`.
417. Donella citation: `/Users/josh/.claude/skills/donella-meadows-systems-thinking/references/ANTI-PATTERNS.md:13-19`.
418. Fix: retry-after-state-change as a hard eligibility rule.
419. Fix: attempts/window as observability only.

420. Blunder class 9: source-owner blur.
421. Definition: watcher plan describes effects owned by `bv`, `br`, Agent Mail, `ntm`, or manager-loop without exact boundaries.
422. Hit: P4/P5/P6 are mostly handled well, but P1 fallback and P3/M replacement still blur authority.
423. Evidence: `00-PLAN.md:337-427`.
424. Evidence: `00-PLAN.md:266-335`.
425. Fix: keep P4/P5/P6 deferral language.
426. Fix: sharpen P1/P3/M receiver language.

427. Blunder class 10: measurement-before-actuation gap.
428. Definition: saying "measure after live window" without making the measurement capture an acceptance gate.
429. Hit: P4/P5/P6 baseline is open.
430. Evidence: `00-PLAN.md:694-696`.
431. Fix: require first unattended P1/P2 window receipt before P4/P5/P6 beads.

## 7. Convergence Call

432. R1 convergence result: not converged.
433. Reason: high findings remain and touch implementation boundaries.
434. Required zero-round standard: two consecutive zero rounds after targeted fixes.
435. Jeff convergence citation: `/Users/josh/.claude/skills/jeff-convergence-audit/SKILL.md:133-143`.
436. Recommended action: revise the plan, then run R2 targeted audit.
437. R2 scope should be narrow.
438. R2 target 1: P1 semantic fixture matrix.
439. R2 target 2: P2 one-dispatch-per-state-hash rule.
440. R2 target 3: A0/A2/A4/A5 cross-plan rewrite.
441. R2 target 4: deprecated primitive carry-forward table.
442. R2 target 5: fallback report-only default.
443. Do not create implementation beads before those edits.
444. Do not expand into P4/P5/P6 in R2.
445. Do not file upstream issues in R2 unless the plan specifically asks for upstream draft location.
446. Do not ask Joshua for tactical choices.
447. Answerable choices are in the artifacts.
448. P1/P2 remain the ship-first pair.
449. H1-H4 do not change that.
450. H1 changes the acceptance fixture matrix.
451. H2 changes fallback authority.
452. H3 changes retry threshold semantics.
453. H4 changes cross-plan primitive names and receiver contract.
454. Medium findings are batchable with high fixes.
455. Low findings do not block R2.
456. Current plan if implemented as-is could reduce wrong-work loops but still preserve enough old behavior to fail unattended work.
457. Current plan after fixes should be strong enough for bead decomposition.
458. The best next artifact is `00-PLAN.md` revision, not a new source patch.
459. The plan's strongest untouched strength is the P1/P2 combined ship order.
460. Citation: `00-PLAN.md:496-553`.
461. The plan's strongest untouched strength is P4/P5/P6 deferral.
462. Citation: `00-PLAN.md:523-531`.
463. The plan's strongest untouched strength is manager-loop ownership of callback cutover.
464. Citation: `00-PLAN.md:520-522`.
465. The plan's weakest remaining boundary is `br ready` fallback.
466. Citation: `00-PLAN.md:178`.
467. The plan's weakest remaining receiver contract is old M-name vocabulary.
468. Citation: `00-PLAN.md:52`.
469. The plan's weakest remaining replay gate is third-attempt suppression.
470. Citation: `00-PLAN.md:249-253`.
471. Convergence call: revise.
472. Next audit verdict target: pass-to-r2.
473. Bead conversion target: only after R2 finds zero high findings.

## 8. Open Questions Promoted From Integrate-Revisions

474. Open question count from plan: 7.
475. Citation: `00-PLAN.md:679-705`.

476. OQ1 question: should local fallback use `bv --robot-triage` top picks, or suppress and wait until upstream exclusion exists?
477. OQ1 citation: `00-PLAN.md:681-685`.
478. OQ1 audit answer: default suppress and emit no-candidate.
479. OQ1 audit answer: allow `bv --robot-triage` only after fixture-backed schema proof.
480. OQ1 audit answer: do not locally rank from `br ready`.
481. OQ1 severity if left open: medium.
482. OQ1 related finding: M3.
483. OQ1 plan patch: convert to decision, not open question.

484. OQ2 question: what exact manager-loop callback parity threshold replaces provisional 0.98?
485. OQ2 citation: `00-PLAN.md:685-687`.
486. OQ2 audit answer: fleet-autonomy should not set the numeric parity threshold.
487. OQ2 audit answer: manager-loop A5 owns parity and cutover.
488. OQ2 cross-plan citation: `../manager-loop-architecture-2026-05-05/00-PLAN.md:660-674`.
489. OQ2 audit answer: fleet plan must name A5 as owner and require no callback death before A5 permit.
490. OQ2 severity if left open: low for P1/P2, high if callback cutover enters scope.
491. OQ2 plan patch: replace M0/M1 wording with A5 parity governor reference.

492. OQ3 question: what is the minimal mission-anchor schema before mission-coverage-compiler ships?
493. OQ3 citation: `00-PLAN.md:688-690`.
494. OQ3 audit answer: use minimal A2-compatible fields.
495. OQ3 required field: `mission_anchor_id`.
496. OQ3 required field: `mission_anchor_evidence_path`.
497. OQ3 required field: `no_mission_anchor_reason`.
498. OQ3 cross-plan citation: `../manager-loop-architecture-2026-05-05/00-PLAN.md:340-365`.
499. OQ3 severity if left open: medium if mission gate enters P1/P2 bead.
500. OQ3 plan patch: either define minimal schema or explicitly defer mission gate to A2.

501. OQ4 question: should P1 degraded fallback ever dispatch from `br ready`, or only report DEGRADED?
502. OQ4 citation: `00-PLAN.md:691-693`.
503. OQ4 audit answer: only report DEGRADED by default.
504. OQ4 audit answer: emergency dispatch from `br ready` requires explicit env gate and receipt.
505. OQ4 audit answer: rollback should disable auto-dispatch, not restore `br ready`.
506. OQ4 severity if left open: high.
507. OQ4 related finding: H2.
508. OQ4 plan patch: close now.

509. OQ5 question: should P4/P5/P6 become beads immediately after status proves bottleneck, or wait for one full overnight baseline?
510. OQ5 citation: `00-PLAN.md:694-696`.
511. OQ5 audit answer: wait for one unattended P1/P2 baseline unless there is a P0 substrate safety issue.
512. OQ5 audit answer: baseline must include reservation, pane, repair-age, selector, and suppression fields.
513. OQ5 severity if left open: medium.
514. OQ5 related finding: M5.
515. OQ5 plan patch: make baseline receipt part of Wave 4-6 gates.

516. OQ6 question: should upstream drafts live in this plan directory or a separate upstream-drafts substrate?
517. OQ6 citation: `00-PLAN.md:697-699`.
518. OQ6 audit answer: use a separate upstream-drafts substrate if a draft is later produced.
519. OQ6 canonical-cli support: upstream-report drafts should be explicit artifacts, not auto-filed.
520. OQ6 citation: `/Users/josh/.claude/skills/canonical-cli-scoping/SKILL.md:166-173`.
521. OQ6 severity if left open: low.
522. OQ6 plan patch: not needed for P1/P2; optional note under deferred upstream gaps.

523. OQ7 question: what is the public narrative name for this narrowed plan?
524. OQ7 citation: `00-PLAN.md:700-702`.
525. OQ7 audit answer: nonblocking.
526. OQ7 audit answer: use `fleet-autonomy-v1` internally.
527. OQ7 severity if left open: low.
528. OQ7 plan patch: none required before implementation.

529. Open-question summary: OQ1 and OQ4 must be closed before beads.
530. Open-question summary: OQ2 must be rerouted to A5 by name.
531. Open-question summary: OQ3 must be minimal schema or explicit defer.
532. Open-question summary: OQ5 must become a baseline gate.
533. Open-question summary: OQ6 and OQ7 are nonblocking.
534. Open-question summary: 7 of 7 addressed.

## 9. Cross-Plan Coherence Audit

535. Cross-plan finding count: 8.

536. CP1 severity: high.
537. CP1 class: missing-A0-explicit-dependency.
538. CP1 finding: fleet-autonomy frontmatter names the manager-loop plan but not A0.
539. CP1 fleet citation: `00-PLAN.md:14-16`.
540. CP1 manager citation: `../manager-loop-architecture-2026-05-05/00-PLAN.md:14`.
541. CP1 manager citation: `../manager-loop-architecture-2026-05-05/00-PLAN.md:107-180`.
542. CP1 fix: add A0 as explicit cross-plan primitive dependency.

543. CP2 severity: high.
544. CP2 class: stale-manager-primitive-map.
545. CP2 finding: fleet plan says P1/P2 emit to M1/M3/M4/M2, but manager-loop final ship order is A0, A2, A4, A1, A5, A3.
546. CP2 fleet citation: `00-PLAN.md:52`.
547. CP2 manager citation: `../manager-loop-architecture-2026-05-05/00-PLAN.md:662-674`.
548. CP2 fix: rewrite the control-plane relationship in A-primitive terms.

549. CP3 severity: medium.
550. CP3 class: P3-owner-naming-drift.
551. CP3 finding: fleet P3 says manager-loop M3/M4 supersede it; manager-loop reconciliation says manager-state read model and shared surface own the read model.
552. CP3 fleet citation: `00-PLAN.md:266-306`.
553. CP3 manager citation: `../manager-loop-architecture-2026-05-05/00-PLAN.md:721-741`.
554. CP3 fix: P3 fields survive as A0 inputs and A4 projection fields.

555. CP4 severity: medium.
556. CP4 class: M-owner-naming-drift.
557. CP4 finding: fleet M says M4 renderer owns Markdown; manager-loop uses A4 shared surface over A0/A2 in final ship order.
558. CP4 fleet citation: `00-PLAN.md:308-335`.
559. CP4 manager citation: `../manager-loop-architecture-2026-05-05/00-PLAN.md:662-719`.
560. CP4 fix: call the surviving artifact A4-generated Markdown projection with A0 source hash.

561. CP5 severity: pass.
562. CP5 class: P1-preservation-coherent.
563. CP5 finding: manager-loop preserves fleet P1.
564. CP5 fleet citation: `00-PLAN.md:131-197`.
565. CP5 manager citation: `../manager-loop-architecture-2026-05-05/00-PLAN.md:733-735`.
566. CP5 note: coherence is good once A0/A2 names are inserted.

567. CP6 severity: pass-with-fix.
568. CP6 class: P2-preservation-coherent-but-threshold-needs-tightening.
569. CP6 finding: manager-loop preserves retry-state discipline, but fleet threshold needs one-dispatch-per-state-hash wording.
570. CP6 fleet citation: `00-PLAN.md:199-264`.
571. CP6 manager citation: `../manager-loop-architecture-2026-05-05/00-PLAN.md:736-738`.
572. CP6 fix: tie suppression rows to A0 ingestion and A2/A5 evaluation.

573. CP7 severity: pass.
574. CP7 class: P4-P6-deferral-coherent.
575. CP7 finding: fleet defers P4/P5/P6 and manager-loop preserves them as status/repair candidates.
576. CP7 fleet citation: `00-PLAN.md:337-427`.
577. CP7 manager citation: `../manager-loop-architecture-2026-05-05/00-PLAN.md:742-750`.
578. CP7 note: add first-live-window baseline gate, but the layer boundary is correct.

579. CP8 severity: pass-with-fix.
580. CP8 class: callback-cutover-owned-by-manager-loop.
581. CP8 finding: fleet correctly refuses callback death, but should name A5 explicitly.
582. CP8 fleet citation: `00-PLAN.md:520-522`.
583. CP8 manager citation: `../manager-loop-architecture-2026-05-05/00-PLAN.md:660-674`.
584. CP8 fix: replace "manager-loop M0/M1" with A5 parity governor and A1 mirror/index where applicable.

585. Cross-plan conclusion: manager-loop and fleet-autonomy are directionally coherent.
586. Cross-plan conclusion: the coherence is not yet implementation-safe because fleet uses stale manager-loop primitive names.
587. Cross-plan conclusion: the missing A0 citation is a true R1 high finding.
588. Cross-plan conclusion: deprecation declarations are correct in intent and incomplete in replacement mapping.
589. Cross-plan conclusion: P1/P2 remain fleet-owned substrate behavior.
590. Cross-plan conclusion: A0/A2/A4/A5 own read model, scoring, projection, and callback parity.
591. Cross-plan conclusion: A3 actuation comes later and should not appear in fleet P1/P2 implementation.
592. Cross-plan conclusion: skillos and mission-coverage compiler remain outside this plan.
593. Cross-plan conclusion: after naming fixes, layer separation should pass R2.

## 10. Required Plan Patch Checklist For R2

594. Patch 1: add explicit A0 dependency to frontmatter.
595. Patch 2: rewrite line 028 relationship to A0/A2/A4/A5/A3 terms.
596. Patch 3: rewrite P1 manager-loop relationship as A0 first, A2 later.
597. Patch 4: rewrite P2 manager-loop relationship as A0 suppression facts plus A2/A5 evaluation.
598. Patch 5: change P1-C from `br ready` dispatch fallback to DEGRADED no-candidate fallback.
599. Patch 6: add emergency flag if fallback dispatch is kept at all.
600. Patch 7: replace rollback-to-`br ready` with rollback-to-disabled-auto-dispatch.
601. Patch 8: add P1-K BLOCKED-cascading-up-to-empty fixture.
602. Patch 9: add P1-L all-parents-with-open-children fixture.
603. Patch 10: add P1-M idle-state-summary semantic preservation fixture.
604. Patch 11: define parent-rollup semantics through `bv` actionability, not title strings alone.
605. Patch 12: change P2 eligibility to one dispatch per candidate plus state hash.
606. Patch 13: make attempt windows diagnostic only.
607. Patch 14: define delivery-uncertain retry as a named exception if needed.
608. Patch 15: add deprecated primitive carry-forward table.
609. Patch 16: define minimal mission-anchor schema or explicitly defer mission gate to A2.
610. Patch 17: answer OQ1 and OQ4 in text.
611. Patch 18: reroute OQ2 to A5.
612. Patch 19: turn OQ5 into first-live-window baseline gate.
613. Patch 20: update composite/readiness score after patches.

## 11. R2 Acceptance Probe

614. R2 should grep for `A0-manager-state-read-model`.
615. R2 should grep for `A2-scoring-governor-top-n-queue`.
616. R2 should grep for `A4`.
617. R2 should grep for `A5`.
618. R2 should grep for `BLOCKED-cascading-up-to-empty`.
619. R2 should grep for `all-parents-with-open-children`.
620. R2 should grep for `one dispatch per candidate_id plus attempt_state_hash`.
621. R2 should grep for `DEGRADED no-candidate`.
622. R2 should grep for absence of `restore br ready primary selector`.
623. R2 should confirm `br ready` appears only as diagnostic inventory or explicit emergency-gated fallback.
624. R2 should confirm P3/M are not called active primitives.
625. R2 should confirm callbacks are not killed before A5 parity.
626. R2 should confirm P4/P5/P6 remain measured follow-up classes.
627. R2 should confirm first-live-window baseline gates Waves 4-6.
628. R2 should confirm no Joshua question is introduced.
629. R2 should confirm no bead creation happened.
630. R2 should confirm no source edits happened.

## 12. Final Audit Receipt

631. Critical findings: 0.
632. High findings: 4.
633. Medium findings: 5.
634. Low findings: 4.
635. Total findings: 13.
636. Verdict: revise.
637. Blunder classes hit: semantic-preservation-gap, degraded-fallback-unsafe, off-by-one-retry-threshold, cross-plan-layer-leak, deprecation-leak, open-question-absorption, parameter-thrashing, source-owner-blur.
638. Open questions addressed: 7/7.
639. Cross-plan findings: 8.
640. Composite: 9.62.
641. Plan-space only: yes.
642. Source edits: no.
643. Beads created: no.
644. Skills consulted: jeff-convergence-audit.
645. Skills consulted: jeff-swarm-ops.
646. Skills consulted: jeff-planning-enhanced.
647. Skills consulted: donella-meadows-systems-thinking.
648. Skills consulted: beads-bv.
649. Skills consulted: beads-br.
650. Skills consulted: canonical-cli-scoping.
651. Skills consulted: multi-pass-bug-hunting.
652. Socraticode queries: 4.
653. Indexed chunks observed: 40.
654. Audit path: `/Users/josh/Developer/flywheel/.flywheel/PLANS/fleet-autonomy-v1-2026-05-05/02-AUDIT-r1.md`.
655. L112 expected: OK_audit_r1_fleet_autonomy.
656. End.
