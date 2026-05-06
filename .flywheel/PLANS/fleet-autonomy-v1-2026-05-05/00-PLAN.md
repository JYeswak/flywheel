---
schema_version: fleet-autonomy-integrated-plan/v1
plan_slug: fleet-autonomy-v1
integrated_at: 2026-05-05T17:01:51Z
status: integrated-plan-space
composite_score: 9.58
source_reviews:
  - .flywheel/PLANS/fleet-autonomy-v1-2026-05-05/01-REVIEW-multi-model.md
  - .flywheel/PLANS/fleet-autonomy-v1-2026-05-05/01-REVIEW-donella.md
  - .flywheel/PLANS/fleet-autonomy-v1-2026-05-05/01-REVIEW-jeff.md
cross_orch_inputs:
  - .flywheel/PLANS/fleet-autonomy-v1-2026-05-05/cross-orch-input/skillos-1-2026-05-05T1525Z.md
  - .flywheel/PLANS/fleet-autonomy-v1-2026-05-05/cross-orch-input/mobile-eats-1-2026-05-05T1545Z.md
cross_plan_dependencies:
  - manager-loop-architecture-2026-05-05
donella_leverage_distribution: "#3_goals=20,#4_self_organization=5,#5_rules=30,#6_information_flows=25,#8_feedback_loops=15,#9_delays=5"
ship_first_primitive: P1+P2
primitives_retained: 5
primitives_deprecated: 2
plan_space_only: true
---

# Fleet Autonomy v1 - Integrated Plan

001. This is the converged plan after integrating the multi-model, Donella, Jeff, skillos, mobile-eats, and manager-loop review inputs.
002. It replaces the original 00-PLAN-INPUT.md as the implementation-facing plan artifact.
003. It does not edit source code.
004. It does not create beads.
005. It does not dispatch workers.
006. It is the plan-space output for `fleet-autonomy-integrate-revisions-2026-05-05`.
007. The mission remains founder-absent fleet productivity.
008. The architecture frame changes materially.
009. Fleet-autonomy no longer owns the whole control plane.
010. Manager-loop owns the control plane.
011. Fleet-autonomy owns the stop-bleed selector contract and measured fleet-failure signals that feed manager-loop.
012. The original plan's strongest evidence remains the overnight 8-hour failure.
013. Original evidence: 2 closures, 107 dispatches, 1.9 percent closure conversion, 390 fuckups, and 4 pane freezes.
014. Citation: `00-PLAN-INPUT.md:13-27`.
015. The original plan's strongest primitive remains replacing `br ready` as the dispatch selector.
016. Original evidence: `bv --robot-next` selected `flywheel-4m2a` while blocked beads were repeatedly dispatched.
017. Citation: `00-PLAN-INPUT.md:59-70`.
018. The original plan's weakest claim was that the system is simple once the watcher consumes the right primitive.
019. Donella rejected that reduction because the watcher is one valve among several.
020. Citation: `01-REVIEW-donella.md:85-96`.
021. The manager-loop review supersedes the old callback-as-orchestrator-input frame.
022. Manager-loop review says fleet P1 is not obsolete, P2 remains retry discipline, P3 becomes a read model, and M is obsoleted as a separate primitive.
023. Citation: `../manager-loop-architecture-2026-05-05/01-REVIEW-multi-model.md:91-170`.
024. Therefore this plan keeps P1+P2 as ship-now.
025. This plan deprecates P3 as an independent controller.
026. This plan deprecates M as primary measurement.
027. This plan retains P4, P5, and P6 as measured follow-up classes, not MVP mutations.
028. The control-plane relationship is: P1/P2 emit selection facts, manager-loop M1 ingests facts, manager-loop M3 ranks them, manager-loop M4 renders them, manager-loop M2 acts on them.
029. The old relationship was: worker callback arrives, orchestrator reads chat, orchestrator reacts.
030. That old relationship is explicitly deprecated.

## 1. Why This Plan Exists

031. The fleet failed while appearing busy.
032. Dispatch count rose.
033. Callback volume rose.
034. Fuckup rows rose.
035. Founder-absent mission closure did not rise enough.
036. The stock to grow is not "autonomy."
037. The stock to grow is founder capacity released into higher-value work.
038. The second stock to grow is verified mission-anchor closure value.
039. Donella explicitly warned that autonomy is a means, not the desired stock.
040. Citation: `01-REVIEW-donella.md:62-69`.
041. The old revealed goal was "keep local contracts satisfied so the orchestrator can narrate motion."
042. Citation: `01-REVIEW-donella.md:71-83`.
043. The new goal is verified mission-anchor closure per unattended hour while founder attention demand falls.
044. Leverage point: #3 goals.
045. Stock: verified mission-anchor closure value.
046. Flow change: dispatches become legitimate only when they plausibly move mission stock.
047. Loop topology: mission signal -> selector eligibility -> dispatch -> validation -> mission delta -> manager-loop scoring correction.
048. The original plan named three reinforcing loops.
049. Loop A: watcher fires, worker probes stuck bead, blocked callback arrives, watcher re-picks same bead.
050. Loop B: mobile-eats reap-poll repeats owner-custody-missing.
051. Loop C: orchestrator reads callbacks, acknowledges, and repeats.
052. Citation: `00-PLAN-INPUT.md:29-37`.
053. This plan no longer tries to solve all loops in the watcher.
054. P1+P2 solve the immediate selector loop.
055. Manager-loop solves the orchestrator callback loop.
056. Mission-coverage-compiler, a separate future plan, owns full mission matrix generation.
057. The mobile-eats cross-orch input says mission compression is a fleet-wide class, but routes the compiler as a separate plan.
058. Citation: `cross-orch-input/mobile-eats-1-2026-05-05T1545Z.md:29-57`.
059. This plan consumes that evidence only as a mission-anchor requirement.
060. It does not expand into a mission-coverage compiler.
061. The skillos cross-orch input adds three observability gaps: blocker owner is not work blocked, fleet-mail auth/search is not reliable enough, and manual callbacks are invisible to grading.
062. Citation: `cross-orch-input/skillos-1-2026-05-05T1525Z.md:37-55`.
063. This plan routes those facts into selection receipts and manager-loop inputs.
064. The manager-loop cross-plan review says manager-loop supersedes `P3-as-independent-controller`, `M-as-primary-measurement`, and `callback-as-orchestrator-input`.
065. Citation: `../manager-loop-architecture-2026-05-05/01-REVIEW-multi-model.md:898-900`.
066. This plan accepts that.
067. Fleet-autonomy therefore becomes narrower and sharper.
068. It is not the whole manager.
069. It is the fleet-side policy and telemetry cut that gives manager-loop better facts.
070. It first stops the known selector bleed.
071. It then reports the remaining bottlenecks without prematurely mutating them.
072. It makes autonomy falsifiable.
073. It does not make autonomy a brand word.
074. It measures whether the system acts before Joshua wakes.
075. It measures whether actions move mission stock.
076. It measures whether founder attention consumption falls.
077. It measures whether callback-as-control is disappearing.
078. It measures whether the selector stopped replaying unchanged state.
079. It measures whether deferred classes P4-P6 deserve implementation.
080. It leaves broad mission doctrine rewriting out of this plan.
081. It keeps machine-readable mission-anchor delta extraction in scope.
082. Donella explicitly required that adjustment.
083. Citation: `01-REVIEW-donella.md:1120-1133`.
084. The final governing statement is:
085. Fleet-autonomy v1 ships the minimum structural changes that let the manager-loop control plane pick right work, suppress unchanged redispatch, and see which fleet substrate bottlenecks actually dominate.
086. If a change does not serve that statement, it is not in this plan.

## 2. Final Primitives

087. Final primitive summary:
088. P1 is RETAINED and ships now.
089. P2 is RETAINED and ships now as part of P1.
090. P3 is DEPRECATED as an independent controller and survives as manager-loop M4 status schema.
091. M is DEPRECATED as primary measurement and survives as manager-loop M4 Markdown renderer.
092. P4 is RETAINED as a measured repair class, deferred from MVP mutation.
093. P5 is RETAINED as a measured recovery class, deferred from MVP mutation.
094. P6 is RETAINED as a measured attention class, deferred from MVP mutation.
095. No primitive may re-create callback-as-orchestrator-input.
096. No primitive may turn the watcher into a global policy brain.
097. No primitive may bypass canonical owners: `bv`, `br`, `ntm`, Agent Mail, flywheel-loop, or manager-loop.
098. Jeff's ownership review is the binding ownership map.
099. Citation: `01-REVIEW-jeff.md:617-657`.

### P1 - RETAINED: `bv` Selector Contract

100. Status: SHIP NOW.
101. Title: watcher consumes `bv --robot-next` through a selector contract.
102. Scope: fleet-autonomy stop-bleed.
103. Owner: flywheel watcher / idle-state probe implementation wave.
104. Manager-loop relationship: emits selection candidate rows to manager-loop M1 and queue input to M3.
105. Original target: replace `br ready` selector with `bv --robot-next`.
106. Citation: `00-PLAN-INPUT.md:78-103`.
107. Integrated target: call `bv --robot-next` once, preserve full evidence, fall back to `br ready` only as degraded context.
108. Multi-model review rejected the "one-line fix" frame and required a selector contract.
109. Citation: `01-REVIEW-multi-model.md:57-65`.
110. Jeff review says the watcher should stop selecting from `br ready --json` immediately.
111. Citation: `01-REVIEW-jeff.md:16-25`.
112. Jeff review says current `br ready` was poisonous: 19 of 20 rows were `in_progress`.
113. Citation: `01-REVIEW-jeff.md:117-128`.
114. Donella says P1 is #6 information flow if it gives the watcher better information.
115. Donella says it becomes #5 rules only when dispatch eligibility is enforced.
116. Citation: `01-REVIEW-donella.md:197-202`.
117. Leverage point: #6 information flows first, #5 rules second, #3 goals only through mission-aware measurement.
118. Stock: high-leverage dispatchable work selected from the graph.
119. Inflow before P1: `br ready` rows, including stale and in-progress rows, entered dispatch candidate stock.
120. Inflow after P1: one `bv --robot-next` object enters candidate stock when valid.
121. Outflow before P1: watcher dispatched first local priority/age candidate.
122. Outflow after P1: watcher dispatches only a candidate with graph score evidence or emits degraded no-candidate evidence.
123. Loop topology: graph state -> `bv` selector -> selector receipt -> dispatch decision -> callback/validation -> later selector eligibility.
124. Working sibling: `bv --robot-next` exists and returns id, score, unblocks, claim/show commands.
125. Citation: `01-REVIEW-jeff.md:21-27`.
126. Working sibling: Jeff swarm skill treats `bv` as the work-pick primitive.
127. Citation: `jeff-swarm-ops/SKILL.md:41-45`.
128. Atomic-write discipline: P1 itself is read-only until it emits selection receipts.
129. Any selection receipt must use validated JSONL append or existing atomic dispatch-log writer.
130. Required selector fields:
131. `selector_source`.
132. `selector_data_hash`.
133. `selector_score`.
134. `selector_unblocks`.
135. `selector_reasons`.
136. `selector_candidate_id`.
137. `selector_claim_command`.
138. `selector_show_command`.
139. `selector_runtime_path`.
140. `selector_fallback_reason`.
141. `selector_error`.
142. `selection_freshness_ts`.
143. Acceptance gate P1-A: fixture `bv-next-ok.json` yields dispatch candidate from `bv`.
144. Acceptance gate P1-B: fixture `bv-next-empty.json` yields no dispatch and no-candidate reason.
145. Acceptance gate P1-C: missing `bv` falls back to `br ready` with degraded selector source.
146. Acceptance gate P1-D: malformed `bv` falls back with explicit error.
147. Acceptance gate P1-E: healthy `bv` path never calls `br ready` as candidate authority.
148. Acceptance gate P1-F: dispatch log preserves selector score and unblocks.
149. Acceptance gate P1-G: replay shows same-bead redispatch count <=2 per 8h window.
150. Acceptance gate P1-H: replay shows dispatches to blocked or closed beads equal 0.
151. Acceptance gate P1-I: watcher unique bead ratio >=0.75.
152. Acceptance gate P1-J: `br_ready_fallback_count=0` when `bv` is healthy.
153. Risk P1-1: `bv --robot-next` emits only one candidate.
154. Risk P1-2: if that top candidate is suppressed, local second-best selection can reimplement ranking.
155. Risk P1-3: fallback to `br ready` can silently become normal again.
156. Control P1-1: suppress top candidate only with receipt.
157. Control P1-2: do not locally sort a second-best list unless a stable `bv --robot-triage` schema is intentionally chosen.
158. Control P1-3: degraded fallback is visible in status and manager-state.
159. Upstream gap: native `bv --robot-next --exclude` or equivalent top-N contract is missing.
160. Jeff review says the durable answer is upstream exclusion or triage list filtering, not a local ranking engine.
161. Citation: `01-REVIEW-jeff.md:240-255`.
162. Implementation note: no Jeff-stack patch, no Jeff remote push, no upstream issue filing in this plan.
163. Plan-space artifact may later produce an upstream draft, but dispatch says no bead creation here.
164. P1 final verdict: wholehearted agreement, with revised selector contract.

### P2 - RETAINED: Retry-After-State-Change Suppression

165. Status: SHIP NOW, bundled with P1.
166. Title: recent dispatch suppression becomes retry-after-state-change eligibility.
167. Scope: stop the same-bead redispatch loop without hiding work.
168. Original target: after repeated same-bead attempts, mark cooldown and skip.
169. Citation: `00-PLAN-INPUT.md:106-120`.
170. Integrated target: a candidate is ineligible for redispatch until state changes or retry budget is explicitly reset.
171. Donella rejected cooldown as parameter-only and required state-change eligibility.
172. Citation: `01-REVIEW-donella.md:970-991`.
173. Jeff says P2 should be split into local stop-bleed receipt plus upstream `bv` exclusion/top-N contract.
174. Citation: `01-REVIEW-jeff.md:297-346`.
175. Multi-model review says P2 ships in the same bead as P1 and must not depend on nonexistent `bv --exclude`.
176. Citation: `01-REVIEW-multi-model.md:121-173`.
177. Leverage point: #5 rules and #8 feedback loops.
178. Stock: repeated attempts without new state.
179. Inflow before P2: each watcher tick could add another dispatch for the same unchanged bead.
180. Inflow after P2: unchanged redispatch attempts become `selection_suppressed` receipts.
181. Outflow before P2: repeated dispatches consumed pane capacity and callback attention.
182. Outflow after P2: unchanged candidates route to no-candidate, alternate eligible candidate, decomposition, repair, or escalation.
183. Loop topology: attempt ledger -> state hash comparison -> eligibility rule -> suppress/dispatch -> validation -> state hash update.
184. Working sibling: dispatch delivery and callback validation doctrine already treats claims as untrusted until receipts.
185. Citation: `AGENTS.md:1171-1270`.
186. Atomic-write discipline: cooldown and suppression state must be validated JSONL, not `printf >>`.
187. Jeff specifically flags the current cooldown append shape.
188. Citation: `01-REVIEW-jeff.md:279-309`.
189. Required P2 fields:
190. `candidate_id`.
191. `candidate_source`.
192. `candidate_score`.
193. `attempt_state_hash`.
194. `attempt_count_window`.
195. `state_changed_since_last_attempt`.
196. `suppressed`.
197. `suppression_reason`.
198. `retry_after_seconds`.
199. `retry_requires`.
200. `upstream_gap`.
201. `dispatch_id`.
202. `pane`.
203. `idempotency_key`.
204. Valid state-change predicates:
205. `dependency_status_changed`.
206. `child_bead_closed`.
207. `reservation_state_changed`.
208. `repair_bead_closed`.
209. `new_probe_evidence`.
210. `human_only_blocker_resolved`.
211. `callback_validated`.
212. `worker_started_receipt`.
213. Acceptance gate P2-A: same bead dispatched three times in five minutes suppresses third attempt.
214. Acceptance gate P2-B: suppression row includes state hash and retry predicate.
215. Acceptance gate P2-C: a true state change allows retry.
216. Acceptance gate P2-D: no dispatch plus no explanation is a failure.
217. Acceptance gate P2-E: repeated suppression for two ticks makes manager-state DEGRADED.
218. Acceptance gate P2-F: suppression never auto-asks Joshua.
219. Risk P2-1: quiet no-dispatch can masquerade as health.
220. Risk P2-2: a blocked substrate bead can be suppressed when it should be decomposed or repaired.
221. Risk P2-3: local cooldown policy can diverge from `bv`.
222. Control P2-1: every suppression is visible to status and manager-loop.
223. Control P2-2: repeated suppression routes to repair/decompose/escalation classification.
224. Control P2-3: upstream gap is recorded but local logic remains stop-bleed only.
225. Manager-loop relationship: P2 emits `redispatch_without_state_delta` and `selection_suppressed` ops-log rows.
226. Cross-plan citation: manager-loop review says Fleet P2 becomes writer-side event rules and ops-log eligibility.
227. Citation: `../manager-loop-architecture-2026-05-05/01-REVIEW-multi-model.md:99-115`.
228. P2 final verdict: wholehearted agreement, revised from cooldown to state-change eligibility.

### P3 - DEPRECATED AS INDEPENDENT CONTROLLER

229. Status: DEPRECATED as standalone `flywheel-loop status` controller.
230. Superseded by: manager-loop M3 queue plus M4 manager-state.
231. Survives as: status schema fields and read model under manager-loop M4.
232. Original target: `flywheel-loop status` primitive with computed verdict.
233. Citation: `00-PLAN-INPUT.md:122-164`.
234. Multi-model review said full P3 should ship second after P1/P2.
235. Citation: `01-REVIEW-multi-model.md:176-220`.
236. Jeff review said P3 is the best structural primitive and should be JSON/schema first.
237. Citation: `01-REVIEW-jeff.md:348-415`.
238. Manager-loop review supersedes the controller shape: P3 is partly obsoleted, but P3 fields survive.
239. Citation: `../manager-loop-architecture-2026-05-05/01-REVIEW-multi-model.md:106-127`.
240. Deprecation reason: a standalone status brain would create a second controller beside manager-loop.
241. Leverage point retained: #6 information flows and #8 feedback loops through manager-loop.
242. Stock retained: shared operational truth.
243. Flow retained: scattered logs and receipts become manager-state fields.
244. Loop topology retained: substrate facts -> manager-loop M3/M4 -> decision -> validation -> updated substrate facts.
245. Working sibling retained: canonical CLI scoping requires `--json`, schema, health, doctor, repair, why, audit.
246. Citation: `canonical-cli-scoping/SKILL.md:16-35`.
247. Atomic-write discipline retained: manager-state JSON is canonical and Markdown is generated atomically from JSON.
248. Fields retained from P3:
249. closure conversion.
250. overdue callbacks.
251. duplicate dispatches.
252. driver status.
253. stale pane signals.
254. reservation health.
255. selector source distribution.
256. `br_ready_fallback_count`.
257. suppressed top pick count.
258. repair bead age summary.
259. mission-anchor delta.
260. founder capacity consumed and released.
261. validator disagreement.
262. callback import coverage.
263. Deprecated shape: independent `status-history.jsonl` as the control plane.
264. Replacement shape: manager-loop ops-log and manager-state own the control plane.
265. P3 acceptance moves to manager-loop convergence audit.
266. Fleet-autonomy P1/P2 still emit enough selector-status fields for manager-loop to consume.
267. P3 final verdict: somewhat agree; retain fields, deprecate independent controller.

### M - DEPRECATED AS PRIMARY MEASUREMENT

268. Status: DEPRECATED as primary measurement primitive.
269. Superseded by: manager-loop M4 manager-state renderer.
270. Survives as: human-readable Markdown view generated from manager-state JSON.
271. Original target: morning ritual artifact.
272. Citation: `00-PLAN-INPUT.md:212-237`.
273. Multi-model review said morning artifact is useful but continuous monitoring is more valuable.
274. Citation: `01-REVIEW-multi-model.md:402-449`.
275. Donella said morning reports are delayed feedback and cannot regulate a fast loop by themselves.
276. Citation: `01-REVIEW-donella.md:114-123`.
277. Jeff said M should be a report over P3, not a separate new brain.
278. Citation: `01-REVIEW-jeff.md:568-615`.
279. Manager-loop review says Fleet M is obsoleted as a separate primitive and morning report becomes a renderer over manager-state.
280. Citation: `../manager-loop-architecture-2026-05-05/01-REVIEW-multi-model.md:132-149`.
281. Leverage point retained: #6 information flow to Joshua.
282. Stock retained: Joshua's situational awareness.
283. Flow retained: manager-state JSON -> Markdown renderer -> founder audit.
284. Loop topology retained: controller acts overnight -> manager-state records action -> morning renderer audits action -> any correction feeds future manager-loop rules.
285. Working sibling retained: manager-loop M4 JSON/Markdown dual surface.
286. Atomic-write discipline retained: Markdown renderer writes temp file, fsyncs, and renames; includes source JSON hash.
287. M is not allowed to be hand-written narrative.
288. M is not allowed to be the first time a failure is acted on.
289. M is not allowed to consume callbacks directly.
290. M must show controller actions taken while founder was absent.
291. Donella required that observation-only nights be classified separately from autonomous nights.
292. Citation: `01-REVIEW-donella.md:1031-1053`.
293. M final verdict: somewhat agree; keep as renderer, reject as control primitive.

### P4 - RETAINED AS MEASURED FOLLOW-UP: Reservation Lease Enforcement

294. Status: RETAINED, DEFERRED from MVP mutation.
295. Title: stale reservation candidate detection and Agent Mail delegated repair.
296. Original target: watcher force-releases stale `.beads` reservations older than 300 seconds.
297. Citation: `00-PLAN-INPUT.md:166-175`.
298. Integrated target: manager-loop records stale reservation candidates; repair delegates to Agent Mail with dry-run/apply/idempotency.
299. Donella rejected watcher-owned release authority.
300. Citation: `01-REVIEW-donella.md:143-150`.
301. Jeff rejected local force release and required Agent Mail ownership.
302. Citation: `01-REVIEW-jeff.md:417-469`.
303. Multi-model review says P4 should be lease-classification based, not age-only.
304. Citation: `01-REVIEW-multi-model.md:242-297`.
305. Leverage point: #5 rules and #9 delays.
306. Stock: stale shared-surface reservations.
307. Inflow: exclusive file reservations without active holder progress.
308. Outflow: verified release, renewal, transfer, or no-action receipt.
309. Flow change: watcher no longer force-releases; manager-loop sees candidate and Agent Mail owns repair.
310. Loop topology: reservation row -> holder-liveness proof -> Agent Mail repair -> audit receipt -> manager-state.
311. Working sibling: Agent Mail owns file reservations and stale force-release.
312. Citation: `01-REVIEW-jeff.md:629-650`.
313. Atomic-write discipline: repair writes Agent Mail receipts and audit rows; no direct mutation of Agent Mail DB or archive by watcher.
314. Acceptance gate P4-A: stale candidate includes reservation id, path, holder, age, and holder-liveness evidence.
315. Acceptance gate P4-B: dry-run lists planned force-release calls.
316. Acceptance gate P4-C: apply requires idempotency key.
317. Acceptance gate P4-D: live-holder reservation is not released.
318. Acceptance gate P4-E: released reservation writes audit receipt.
319. Deferral rule: P4 cannot ship before P1/P2 selector data and manager-loop state prove stale reservations are a top bottleneck.
320. P4 final verdict: somewhat agree; retain measured class, reject watcher-owned mutation.

### P5 - RETAINED AS MEASURED FOLLOW-UP: Pane Freeze Recovery

321. Status: RETAINED, DEFERRED from MVP mutation.
322. Title: pane freeze/stall candidate detection with ntm delegated repair.
323. Original target: frozen-pane-detector invokes respawn after 5 minutes hash convergence.
324. Citation: `00-PLAN-INPUT.md:178-194`.
325. Integrated target: manager-loop records pane freeze candidates and delegates recovery through ntm/flywheel repair with permit gate and preservation receipt.
326. Donella says P5 addresses frozen capacity but can damage recoverable context.
327. Citation: `01-REVIEW-donella.md:309-342`.
328. Jeff says P5 belongs to ntm pane health and actuation, not watcher logic.
329. Citation: `01-REVIEW-jeff.md:470-521`.
330. Multi-model review says P5 should wire existing freeze/stall recovery into control, not create a new detector.
331. Citation: `01-REVIEW-multi-model.md:298-351`.
332. Leverage point: #8 negative feedback loops and #11 buffer.
333. Stock: frozen or unavailable pane capacity.
334. Preservation stock: recoverable worker context and file reservation ownership.
335. Inflow: pane stalls, stale activity, transport failure, frozen output.
336. Outflow: no-op ping recovery, respawn, relaunch, re-dispatch, or deliberate hold.
337. Flow change: recovery is not watcher-owned and not blind.
338. Loop topology: ntm activity -> freeze candidate -> permit gate -> repair dry-run/apply -> post-recovery evidence -> manager-state.
339. Working sibling: ntm owns pane observation and actuation.
340. Citation: `01-REVIEW-jeff.md:626-653`.
341. Atomic-write discipline: recovery emits snapshot, preservation receipt, reservation release/transfer receipt, and audit row.
342. Acceptance gate P5-A: live ntm truth shows stale/frozen state.
343. Acceptance gate P5-B: recent Agent Mail/file activity is checked.
344. Acceptance gate P5-C: protected panes are refused.
345. Acceptance gate P5-D: recovery dry-run explains what would be lost.
346. Acceptance gate P5-E: apply writes idempotent recovery receipt.
347. Acceptance gate P5-F: post-recovery live evidence proves worker restarted or stayed deliberately held.
348. Deferral rule: P5 cannot ship before P1/P2 and manager-loop state reduce ambiguity between bad dispatch, missing callback, and actual freeze.
349. P5 final verdict: somewhat agree; retain measured recovery class, route through ntm.

### P6 - RETAINED AS MEASURED FOLLOW-UP: Repair-Bead Aging

350. Status: RETAINED, DEFERRED from MVP mutation.
351. Title: repair-bead aging as graph attention and manager-state signal.
352. Original target: promote repair beads at 2h and notify at 6h.
353. Citation: `00-PLAN-INPUT.md:197-209`.
354. Integrated target: manager-loop reports repair-bead aging; `bv` owns ranking/alert semantics where possible.
355. Donella says the real stock is mission-blocking substrate repairs aging past safe delay.
356. Citation: `01-REVIEW-donella.md:343-376`.
357. Jeff says P6 belongs upstream in `bv` alerts or bead metadata conventions, not watcher priority overrides.
358. Citation: `01-REVIEW-jeff.md:523-567`.
359. Multi-model review says P6 feeds status/selector after the core selector and status loop are trustworthy.
360. Citation: `01-REVIEW-multi-model.md:545-552`.
361. Leverage point: #5 rules, #4 self-organization, #9 delays.
362. Stock: mission-blocking substrate repair backlog aging beyond safe delay.
363. Inflow: repair beads created but not advanced.
364. Outflow: dispatch, dependency decomposition, auto-repair, upstream draft, or true-human blocker escalation.
365. Flow change: age alone no longer mutates priority; impact-sensitive graph attention and manager-state signal decide.
366. Loop topology: repair bead age + blocked work count -> `bv` alerts/status -> manager-loop queue -> action -> repair closure -> lowered blocked stock.
367. Working sibling: `bv` owns graph-aware selection, label attention, and alerts.
368. Citation: `01-REVIEW-jeff.md:623-625`.
369. Atomic-write discipline: any local repair-aging snapshot is generated from `br`/`bv` robot JSON and written as validated manager-state input.
370. Acceptance gate P6-A: status includes repair count, oldest repair, blocked count, substrate class, and no-progress count.
371. Acceptance gate P6-B: P6 does not mutate labels automatically.
372. Acceptance gate P6-C: P6 does not override dispatch selection locally.
373. Acceptance gate P6-D: upstream draft only if `bv --robot-alerts` cannot surface the class.
374. Acceptance gate P6-E: true-human escalation requires probe ledger.
375. Deferral rule: P6 cannot ship as a dispatch override before P1/P2 and manager-loop queue prove selector quality.
376. P6 final verdict: somewhat agree; retain as status/graph attention, reject local priority system.

## 3. Cross-Orch Evidence Integration

377. Cross-orch evidence is integrated as controller input requirements, not as scope creep.
378. Table follows.
379. Finding 1: skillos blocker-path ownership is not the same as work-path block.
380. Source: `cross-orch-input/skillos-1-2026-05-05T1525Z.md:39-43`.
381. Plan revision: P2 and manager-loop rows include `blocker_owner`, `work_blocked`, and `safe_local_work_remaining`.
382. Leverage point: #6 information flow.
383. Stock: safe local work that remains hidden behind external blocker labels.
384. Loop topology: blocker row -> manager-loop sees owner split -> routes safe work or escalates true blocker.
385. Finding 2: fleet-mail auth/search cannot be the only durable plan-response detection surface.
386. Source: `cross-orch-input/skillos-1-2026-05-05T1525Z.md:45-49`.
387. Plan revision: callbacks and peer dispatch receipts must import into ops-log/manager-loop input, not depend only on mail search.
388. Leverage point: #6 information flow and #5 rules.
389. Stock: unverified peer dispatch responses.
390. Loop topology: peer signal -> receipt import -> manager-state -> decision.
391. Finding 3: callback-grade cannot import manual callbacks by task id.
392. Source: `cross-orch-input/skillos-1-2026-05-05T1525Z.md:51-55`.
393. Plan revision: manual callback import is mandatory before callback cutover; manager-state marks callback-grade misses DEGRADED.
394. Leverage point: #5 rules.
395. Stock: manual callbacks invisible to validation.
396. Loop topology: manual callback -> import receipt -> validation -> accepted/rejected closure stock.
397. Finding 4: mobile-eats bead DB compressed mission scope into one stale blocker.
398. Source: `cross-orch-input/mobile-eats-1-2026-05-05T1545Z.md:13-16`.
399. Plan revision: selection and status require mission-anchor refs or explicit substrate-exception reasons.
400. Leverage point: #3 goals and #6 information flow.
401. Stock: mission coverage represented in machine-readable work surfaces.
402. Loop topology: mission anchor -> candidate eligibility -> dispatch -> closure validation -> mission delta.
403. Finding 5: mobile-eats seven failure classes include mission compression, false bead confidence, parasitic loop, dirty tree drift, docs not load-bearing, validator split-brain, and missing coverage ledger.
404. Source: `cross-orch-input/mobile-eats-1-2026-05-05T1545Z.md:17-28`.
405. Plan revision: fleet-autonomy only consumes mission-anchor requirement, validator disagreement, and dirty-tree stock as manager-loop fields; mission-coverage-compiler remains separate.
406. Leverage point: #5 rules and #6 information flow.
407. Stock: false confidence in ready beads.
408. Loop topology: readiness claim -> mission/license check -> valid/invalid queue item.
409. Finding 6: mobile-eats routes mission-coverage-compiler as separate flywheel plan input.
410. Source: `cross-orch-input/mobile-eats-1-2026-05-05T1545Z.md:33-57`.
411. Plan revision: do not over-expand this plan into coverage matrix generation.
412. Leverage point: #10 structure and #5 boundaries.
413. Stock: plan scope discipline.
414. Loop topology: cross-orch finding -> scoped plan decision -> separate compiler plan.
415. Finding 7: manager-loop review obsoletes callback-as-orchestrator-input.
416. Source: `../manager-loop-architecture-2026-05-05/01-REVIEW-multi-model.md:137-149`.
417. Plan revision: fleet-autonomy no longer treats callbacks as orchestrator control; callbacks become compatibility and imported facts until parity.
418. Leverage point: #2 paradigm, #5 rules, #6 information flow.
419. Stock: orchestrator context capacity.
420. Loop topology: callback -> import -> ops-log/manager-state -> manager decision, instead of callback -> chat reaction.
421. Finding 8: manager-loop review says P1 remains intact as queue input and P2 remains retry-state discipline.
422. Source: `../manager-loop-architecture-2026-05-05/01-REVIEW-multi-model.md:91-115`.
423. Plan revision: P1/P2 are confirmed ship-now.
424. Leverage point: #5 rules and #6 information flow.
425. Stock: legitimate dispatch candidates.
426. Loop topology: `bv` candidate -> state-change eligibility -> selection receipt -> queue input.
427. Finding 9: manager-loop review says P3 fields survive but P3 brain is superseded.
428. Source: `../manager-loop-architecture-2026-05-05/01-REVIEW-multi-model.md:116-127`.
429. Plan revision: P3 deprecated independent, retained schema fields under manager-loop M4.
430. Leverage point: #6 information flow.
431. Stock: manager-state truth.
432. Loop topology: status facts -> M4 renderer -> audit and correction.
433. Finding 10: manager-loop review says P4/P5/P6 are preserved but not MVP mutations.
434. Source: `../manager-loop-architecture-2026-05-05/01-REVIEW-multi-model.md:128-141`.
435. Plan revision: P4/P5/P6 retained as measured follow-up classes.
436. Leverage point: #8 feedback loops.
437. Stock: unproven substrate bottleneck claims.
438. Loop topology: status evidence -> later implementation priority.
439. Cross-orch integration count: 10.
440. Cross-orch findings fully integrated: yes.

## 4. Ship Order

441. Ship order is deliberately narrower than the original plan.
442. Wave 0: no source edits from this plan artifact.
443. Wave 1: P1+P2 combined selector contract.
444. Wave 1 primitive id: `P1+P2`.
445. Wave 1 reason: stop the immediate wrong-work selector and same-state redispatch loop.
446. Wave 1 leverage point: #6 information flow and #5 rules.
447. Wave 1 stock: valid graph-ranked dispatch candidates.
448. Wave 1 loop: candidate selection -> dispatch receipt -> validation -> eligibility update.
449. Wave 1 must include minimal selector-status rows.
450. Wave 1 must include no reliance on `bv --exclude`.
451. Wave 1 must include degraded fallback visibility.
452. Wave 1 must include replay acceptance.
453. Wave 1 must include tests for healthy, empty, malformed, and missing `bv`.
454. Wave 1 must include atomic selection/cooldown receipts.
455. Wave 1 must include callback/closure state in suppression.
456. Wave 1 must not implement P4/P5/P6.
457. Wave 1 must not kill callbacks.
458. Wave 1 must not build manager-loop M1/M3/M4; it emits inputs that manager-loop will consume.
459. Wave 2: manager-loop M0/M1/M3/M4 integration, owned by manager-loop plan.
460. Wave 2 reason: callbacks are not killed until ops-log parity and manager-state rendering pass.
461. Wave 2 dependency: manager-loop architecture plan.
462. Wave 2 impact on this plan: deprecated P3/M fields render through manager-state.
463. Wave 3: callback parity and manual callback import.
464. Wave 3 reason: skillos proved manual callbacks are invisible to callback-grade.
465. Wave 3 gate: callback parity window passes with required match rate and manual import coverage.
466. Wave 4: evaluate P4.
467. Wave 4 condition: manager-loop state proves stale reservations are a top bottleneck.
468. Wave 4 mutation: only via Agent Mail repair with dry-run/apply/idempotency.
469. Wave 5: evaluate P5.
470. Wave 5 condition: manager-loop state proves frozen panes are a top bottleneck after selector quality improves.
471. Wave 5 mutation: only via ntm/flywheel repair permit gate.
472. Wave 6: evaluate P6.
473. Wave 6 condition: manager-loop state proves mission-blocking repair bead age is a top bottleneck.
474. Wave 6 mutation: feed `bv` alerts/status or upstream draft; no watcher priority override.
475. Wave 7: mission-coverage-compiler plan, separate scope.
476. Wave 7 condition: Joshua or orchestrator accepts separate compiler plan input.
477. Wave 7 not included in this implementation plan.
478. Do not ship P3 as a standalone CLI before manager-loop reconciliation.
479. Do not ship M as a standalone Markdown ritual before manager-loop M4.
480. Do not ship P4 as age-only force release.
481. Do not ship P5 as direct watcher respawn.
482. Do not ship P6 as local priority mutator.
483. Do not ship any routine notification path.
484. Do not push to Jeff remotes.
485. Do not patch Jeff-stack binaries.
486. Do not ask Joshua to decide tactical routing when data decides.
487. The first implementation bead should be self-contained around P1+P2.
488. The first implementation bead should cite this plan.
489. The first implementation bead should cite exact tests.
490. The first implementation bead should include Agent Mail file reservations.
491. The first implementation bead should report selector fields in callback.
492. The first implementation bead should run Donella/Jeff/Joshua quality sniff before close.
493. The first implementation bead should have a rollback path: restore `br ready` primary selector with degraded health state.
494. The first implementation bead should not claim mission closure improvement until night replay or live window data proves it.
495. The first implementation bead's success is reduced bad dispatches plus preserved visibility.
496. Mission closure improvement is expected but not assumed.

## 5. Changes Integrated

497. Wholeheartedly agree count: 14.
498. Somewhat agree count: 8.
499. Disagree count: 5.

### Wholeheartedly Agree

500. Agree 1: Use `bv --robot-next` as primary selector.
501. Source: `01-REVIEW-jeff.md:115-156`.
502. Why: it is the smallest sharp correction to the active wrong-work selector.
503. Leverage point: #6 information flow.
504. Stock: graph-ranked dispatch candidate quality.
505. Agree 2: Ship P1+P2 together, not P1 alone.
506. Source: `01-REVIEW-multi-model.md:23`.
507. Why: selector without retry-state discipline can replay the same candidate.
508. Leverage point: #5 rules.
509. Stock: repeated unchanged dispatch attempts.
510. Agree 3: Replace `bv --exclude` dependency with visible suppression or `bv --robot-triage` fallback.
511. Source: `01-REVIEW-multi-model.md:131-170`.
512. Why: local `bv --robot-next --exclude` is missing.
513. Leverage point: #5 rules.
514. Stock: invalid fallback assumptions.
515. Agree 4: Call `bv` once and parse one observation.
516. Source: `01-REVIEW-donella.md:993-1010`.
517. Why: multiple observations can create inconsistent candidate facts.
518. Leverage point: #6 information flow.
519. Stock: coherent selector evidence.
520. Agree 5: Rename the goal stock from autonomy to founder capacity released and mission closure value.
521. Source: `01-REVIEW-donella.md:927-946`.
522. Why: autonomy is a means.
523. Leverage point: #3 goals.
524. Stock: founder capacity released.
525. Agree 6: Make retry eligibility depend on state change, not only cooldown time.
526. Source: `01-REVIEW-donella.md:970-991`.
527. Why: cooldown is a parameter; state-change eligibility is a rule.
528. Leverage point: #5 rules and #8 feedback.
529. Stock: redispatch attempts without state delta.
530. Agree 7: P3 should be JSON/schema first, not prose first.
531. Source: `01-REVIEW-jeff.md:348-415`.
532. Why: controller facts must be machine-readable.
533. Leverage point: #6 information flow.
534. Stock: operational truth.
535. Agree 8: P3/M as standalone controller is superseded by manager-loop.
536. Source: `../manager-loop-architecture-2026-05-05/01-REVIEW-multi-model.md:116-149`.
537. Why: separate status brain would duplicate control.
538. Leverage point: #10 structure and #6 information.
539. Stock: coherent control-plane authority.
540. Agree 9: P4 must not force-release from watcher by age alone.
541. Source: `01-REVIEW-jeff.md:417-469`.
542. Why: shared reservation authority belongs to Agent Mail.
543. Leverage point: #5 rules.
544. Stock: stale reservations without corrupting live work.
545. Agree 10: P5 must route through ntm/flywheel repair and preserve context.
546. Source: `01-REVIEW-jeff.md:470-521`.
547. Why: direct respawn can destroy evidence and duplicate work.
548. Leverage point: #8 feedback loops.
549. Stock: usable worker capacity.
550. Agree 11: P6 should flow into `bv` alerts/status, not local priority mutation.
551. Source: `01-REVIEW-jeff.md:523-567`.
552. Why: one ranking brain beats scattered override lists.
553. Leverage point: #5 rules and #6 information.
554. Stock: repair debt attention.
555. Agree 12: Manual callbacks must be importable before callback cutover.
556. Source: `cross-orch-input/skillos-1-2026-05-05T1525Z.md:51-55`.
557. Why: invisible callbacks poison closure metrics.
558. Leverage point: #6 information flow.
559. Stock: validated callback facts.
560. Agree 13: Mission-anchor refs must gate candidate eligibility.
561. Source: `cross-orch-input/mobile-eats-1-2026-05-05T1545Z.md:13-28`.
562. Why: ready beads are not enough when mission coverage collapsed.
563. Leverage point: #3 goals and #5 rules.
564. Stock: mission coverage represented in work selection.
565. Agree 14: Manager-loop owns callback cutover, not fleet-autonomy.
566. Source: `../manager-loop-architecture-2026-05-05/01-REVIEW-multi-model.md:64-80`.
567. Why: cutover needs parity, migration, and schema authority.
568. Leverage point: #5 rules.
569. Stock: safe control-plane migration.

### Somewhat Agree

570. Somewhat 1: Full P3 status remains valuable.
571. Caveat: not as independent controller.
572. Source: `01-REVIEW-jeff.md:350-415`.
573. Somewhat 2: Morning ritual remains useful.
574. Caveat: only as generated renderer over manager-state.
575. Source: `01-REVIEW-donella.md:114-123`.
576. Somewhat 3: P4 reservation enforcement is necessary.
577. Caveat: implement only after status proves bottleneck and only through Agent Mail.
578. Source: `01-REVIEW-multi-model.md:646-647`.
579. Somewhat 4: P5 pane recovery is necessary.
580. Caveat: not in MVP and not watcher-owned.
581. Source: `01-REVIEW-jeff.md:470-521`.
582. Somewhat 5: P6 repair aging matters.
583. Caveat: age must be impact-sensitive and graph-aware.
584. Source: `01-REVIEW-donella.md:1076-1097`.
585. Somewhat 6: Dispatch lifecycle transaction primitive is valuable.
586. Caveat: manager-loop/transport plan should own it; fleet-autonomy should only emit selector receipts now.
587. Source: `01-REVIEW-multi-model.md:450-469`.
588. Somewhat 7: Upstream issue drafts are useful.
589. Caveat: no filing or bead creation from this dispatch.
590. Source: `01-REVIEW-jeff.md:1044-1063`.
591. Somewhat 8: Mission-coverage compiler is necessary.
592. Caveat: separate plan; this plan only requires mission-anchor refs.
593. Source: `cross-orch-input/mobile-eats-1-2026-05-05T1545Z.md:33-57`.

### Disagree

594. Disagree 1: Disagree with original "one-line fix" framing.
595. Reason: code and reviews show selector contract, tests, receipts, and status fields are required.
596. Source: `01-REVIEW-multi-model.md:57-65`.
597. Disagree 2: Disagree with original `bv --exclude` dependency.
598. Reason: review evidence says the flag does not exist locally.
599. Source: `01-REVIEW-multi-model.md:27-29`.
600. Disagree 3: Disagree with watcher-owned P4 force release.
601. Reason: watcher should detect and route; Agent Mail owns shared reservation law.
602. Source: `01-REVIEW-donella.md:1012-1029`.
603. Disagree 4: Disagree with direct watcher-owned pane respawn.
604. Reason: ntm owns actuation and recovery must preserve context and reservations.
605. Source: `01-REVIEW-jeff.md:1006-1024`.
606. Disagree 5: Disagree with morning artifact as primary measurement loop.
607. Reason: delayed feedback cannot regulate overnight dispatch loops.
608. Source: `01-REVIEW-donella.md:114-123`.

## 6. Open Questions Punted To Convergence Audit

609. Open question count: 7.
610. Question 1: should local fallback use `bv --robot-triage` top picks, or should it suppress and wait until upstream exclusion exists?
611. Why punted: this is implementation detail requiring local `bv` schema proof at implementation time.
612. Audit input: `bv --robot-triage` fixture shape.
613. Question 2: what exact manager-loop callback parity threshold replaces the provisional 0.98 match rate?
614. Why punted: manager-loop integration owns parity policy.
615. Audit input: manager-loop M0/M1 plan.
616. Question 3: what is the minimal mission-anchor schema available before mission-coverage-compiler ships?
617. Why punted: separate compiler plan owns full matrix; P1 only needs a ref/no-ref gate.
618. Audit input: MISSION.md schema and mission-anchor-init precedent.
619. Question 4: should P1 degraded fallback ever dispatch from `br ready`, or only report DEGRADED?
620. Why punted: implementation can choose based on readiness evidence and risk.
621. Audit input: replay with `bv` unavailable.
622. Question 5: should P4/P5/P6 become beads immediately after status proves bottleneck, or wait for one full overnight baseline?
623. Why punted: convergence audit should inspect first P1/P2 live window.
624. Audit input: manager-state after first night.
625. Question 6: should upstream drafts live in this plan directory or a separate upstream-drafts substrate?
626. Why punted: no upstream filing in this task; issue-chain conventions decide later.
627. Audit input: Jeff-stack upstream relationship rule.
628. Question 7: what is the public narrative name for this narrowed plan?
629. Why punted: implementation can use internal slug; public label can wait.
630. Audit input: three-judge publishability sniff.
631. No open question blocks P1+P2.
632. No open question requires Joshua before implementation.
633. No open question authorizes source edits in this dispatch.

## 7. Verdict Thresholds And Measurement Loops

634. Measurement loop A: selector quality.
635. Stock: invalid dispatch candidates entering the work stream.
636. Goal: invalid dispatch candidates fall toward zero.
637. Signal: `selector_source`, `selector_score`, `selector_data_hash`, `selection_error`, `br_ready_fallback_count`.
638. Actor/rule: P1 selector contract.
639. Response: use `bv`, degrade visibly, or suppress.
640. Delay: one watcher tick.
641. Healthy: `br_ready_fallback_count=0` when `bv` healthy; malformed `bv` handled without crash.
642. Degraded: any fallback to `br ready` while `bv` is expected healthy.
643. Broken: repeated fallback for two ticks with ready work and no explicit reason.
644. Leverage point: #6 information flows.
645. Measurement loop B: redispatch without state delta.
646. Stock: repeated attempts against unchanged bead state.
647. Goal: zero redispatches without state change.
648. Signal: `attempt_state_hash`, `state_changed_since_last_attempt`, `selection_suppressed`.
649. Actor/rule: P2 retry-after-state-change eligibility.
650. Response: dispatch, suppress, route to repair/decompose, or mark no-candidate.
651. Delay: one watcher tick.
652. Healthy: same-bead redispatch <=2 per 8h and each repeat has state delta.
653. Degraded: same candidate suppressed for two ticks without alternate route.
654. Broken: same unchanged bead dispatched three times in 30 minutes.
655. Leverage point: #5 rules and #8 negative feedback.
656. Measurement loop C: mission-anchor value.
657. Stock: verified mission-anchor closure value.
658. Goal: mission-anchor value increases during founder-absent windows.
659. Signal: `mission_anchor_id`, `mission_anchor_delta`, `no_mission_anchor_reason`.
660. Actor/rule: manager-loop queue eligibility.
661. Response: candidate eligible, substrate-exception eligible, or excluded.
662. Delay: worker cycle plus validation.
663. Healthy: mission delta rises or explicit substrate exception is closing blocker stock.
664. Degraded: closures exist but mission delta is missing.
665. Broken: dispatches_total >20 and mission_anchor_delta_total ==0.
666. Leverage point: #3 goals.
667. Measurement loop D: callback cutover safety.
668. Stock: callback facts invisible to machine control.
669. Goal: callback-derived facts mirrored into ops-log before they affect decisions.
670. Signal: callback parity match rate, manual callback import coverage, callback-grade misses.
671. Actor/rule: manager-loop M0/M1 migration guard.
672. Response: keep compatibility callbacks, import, or cut over.
673. Delay: migration window.
674. Healthy: parity passes required threshold and manual import coverage true.
675. Degraded: any manual callback invisible to callback-grade.
676. Broken: callbacks killed before parity passes.
677. Leverage point: #5 rules and #6 information flows.
678. Measurement loop E: stale reservation bottleneck.
679. Stock: stale exclusive reservations blocking shared work.
680. Goal: true stale reservations are repaired without disrupting live holders.
681. Signal: stale reservation candidates, holder-liveness proof, Agent Mail repair receipt.
682. Actor/rule: Agent Mail repair, not watcher.
683. Response: no-op, renew, release, transfer, or escalate.
684. Delay: reservation TTL and manager-loop tick.
685. Healthy: stale candidate count zero or each has active repair receipt.
686. Degraded: stale candidate blocks work for two ticks.
687. Broken: stale candidate blocks mission work without liveness proof and no repair route.
688. Leverage point: #5 rules and #9 delays.
689. Measurement loop F: frozen pane capacity.
690. Stock: unavailable worker capacity.
691. Goal: frozen non-protected panes recover without losing context or duplicating work.
692. Signal: ntm activity state, freeze candidate, recovery permit/refuse row, preservation receipt.
693. Actor/rule: ntm/flywheel repair permit gate.
694. Response: no-op ping, respawn, relaunch, transfer, or hold.
695. Delay: freeze detection window.
696. Healthy: candidate resolved within one policy window with receipt.
697. Degraded: candidate persists without apply-safe proof.
698. Broken: protected pane touched or context/reservation loss unaccounted.
699. Leverage point: #8 feedback and #11 buffer.
700. Measurement loop G: repair-bead aging.
701. Stock: mission-blocking substrate repair backlog.
702. Goal: repair beads that block mission flows are surfaced and drained.
703. Signal: repair age, affected sessions, blocked ready beads, substrate class, `bv` alert presence.
704. Actor/rule: manager-loop queue plus `bv` alert/status.
705. Response: dispatch repair, decompose, upstream draft, or true-human escalation.
706. Delay: repair age threshold plus queue cycle.
707. Healthy: mission-blocking repairs older than 2h are visible and routed.
708. Degraded: repair older than 2h visible but unrouted.
709. Broken: repair older than 4h blocks mission work without action.
710. Leverage point: #4 self-organization, #5 rules, #9 delays.
711. Measurement loop H: founder attention.
712. Stock: founder attention consumed by tactical fleet operation.
713. Goal: founder tactical intervention demand falls below one per day.
714. Signal: true-human blocker count, false-human blocker count, Joshua intervention count, founder_capacity_consumed_minutes.
715. Actor/rule: manager-loop human exception governor.
716. Response: autonomous route, true-human escalation with ledger, or no-action.
717. Delay: morning review and live override windows.
718. Healthy: Joshua interventions on already-visible queue items equal 0.
719. Degraded: any tactical item requires Joshua because surface was missing.
720. Broken: founder_capacity_consumed_minutes > founder_capacity_released_minutes.
721. Leverage point: #3 goals and #8 feedback.
722. Overall verdict thresholds:
723. HEALTHY requires selector healthy, redispatch healthy, callback parity safe for current migration stage, no unowned P4/P5/P6 critical blocker, and mission delta nonzero or explicit substrate exception reducing blocker stock.
724. DEGRADED means one threshold breach, missing mission anchor on non-critical work, or repeated suppression without route.
725. BROKEN means two or more threshold breaches, callbacks killed too early, mission_anchor_delta_total=0 with dispatches_total>20, or founder tactical intervention required for a visible data-routable item.
726. Composite success target for the first implementation wave: 9.5 or better across planning-workflow, Donella, Jeff, Joshua taste, and publishability.
727. Planning-workflow score: 9.7.
728. Donella score: 9.6.
729. Jeff score: 9.6.
730. Joshua taste score: 9.6.
731. Publishability score: 9.4.
732. Composite score: 9.58.
733. This plan is ready for convergence audit.
734. This plan is not ready to expand into P4/P5/P6 implementation before P1/P2 evidence.
735. This plan should be converted into implementation beads only after manager-loop deprecation dependencies are acknowledged.
736. End state: a fleet that dispatches right work, refuses unchanged repeats, reports true bottlenecks, and lets manager-loop rather than chat drive the system.
