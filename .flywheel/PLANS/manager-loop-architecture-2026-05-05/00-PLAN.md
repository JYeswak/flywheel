---
schema_version: manager-loop-plan/v1
plan_slug: manager-loop-architecture-2026-05-05
integrated_at: 2026-05-05T17:01:49Z
status: integrated-plan-space
source_reviews:
  - 01-REVIEW-multi-model.md
  - 01-REVIEW-donella.md
  - 01-REVIEW-jeff.md
  - cross-orch-input/skillos-1-2026-05-05T1555Z.md
composite_score: 9.67
donella_leverage_distribution: "#3=1,#4=1,#5=5,#6=4,#8=3,#9=2"
final_primitive_count: 6
ship_first_primitive: A0-manager-state-read-model
callback_cutover_policy: parity-gated
plan_space_only: true
---

# Manager-Loop Architecture For Orchestrators

001. This plan replaces conversational orchestration with a manager loop.
002. It does not replace `bv`, `br`, `ntm`, Agent Mail, doctor, or validation receipts.
003. It composes existing substrate into a shared decision surface.
004. It makes the scoring policy explicit.
005. It keeps callbacks alive until parity is proven.
006. It makes mission-anchor closure the primary stock.
007. It keeps Joshua as exception handler, not routine controller.
008. It is plan-space only.

## 1. Why This Plan Exists

009. Today's failure was not merely that callbacks were noisy.
010. It was that callback noise became the orchestrator's operating environment.
011. Original evidence: 60+ overnight callbacks, 107 watcher cycles, and 2 bead closures.
012. Original evidence: `00-PLAN-INPUT.md:13-15`.
013. Original evidence: `00-PLAN-INPUT.md:21-29`.
014. Donella review named the stock: unresolved work, unresolved failures, invisible callbacks, stale decisions, and founder attention demand.
015. Donella citation: `01-REVIEW-donella.md:4-9`.
016. Donella review named the reinforcing loop: callbacks increase context load; context load reduces stock-level thinking; reduced thinking creates more callbacks.
017. Donella citation: `01-REVIEW-donella.md:4-8`.
018. Multi-model review agreed the callback-as-input architecture is the real bottleneck.
019. Multi-model citation: `01-REVIEW-multi-model.md:61-70`.
020. Jeff review endorsed the counter-thesis that most substrate already exists in fragments.
021. Jeff citation: `01-REVIEW-jeff.md:9-14`.
022. Jeff citation: `01-REVIEW-jeff.md:850-887`.
023. Therefore this plan does not start by inventing a large new authority log.
024. It starts by composing existing ledgers into a manager-state read model.
025. The original plan proposed an ops-log as canonical truth.
026. Original citation: `00-PLAN-INPUT.md:40-54`.
027. Jeff rejected `ops-log.jsonl` as primary authority before ownership is solved.
028. Jeff citation: `01-REVIEW-jeff.md:353-438`.
029. Donella accepted the information-flow move but rejected writer-asserted stock deltas.
030. Donella citation: `01-REVIEW-donella.md:133-141`.
031. Multi-model accepted ops-log direction but required authority, schema, parity, and mission fields.
032. Multi-model citation: `01-REVIEW-multi-model.md:171-240`.
033. Converged thesis: manager-state is the first primitive.
034. Converged thesis: ops-log is a validated mirror and index until it proves parity.
035. Converged thesis: callbacks are compatibility input, not the long-term control path.
036. Converged thesis: the scoring governor is the next invisible structure.
037. Donella citation for scoring governor: `01-REVIEW-donella.md:19-23`.
038. Donella citation for scoring governor risks: `01-REVIEW-donella.md:722-775`.
039. The manager loop must not optimize "top-10 exists."
040. Donella citation: `01-REVIEW-donella.md:60-86`.
041. The manager loop must optimize verified mission-anchor closure per bounded founder attention and context budget.
042. Donella citation: `01-REVIEW-donella.md:676-681`.
043. The manager loop must preserve Jeff substrate ownership.
044. Jeff citation: `01-REVIEW-jeff.md:697-730`.
045. The manager loop must obey canonical CLI scoping from the first shipped primitive.
046. Jeff citation: `01-REVIEW-jeff.md:287-292`.
047. The manager loop must expose robot-mode JSON.
048. Jeff citation: `01-REVIEW-jeff.md:305-312`.
049. The manager loop must preserve the dispatch-delivery receipt contract until a stronger one exists.
050. Donella citation: `01-REVIEW-donella.md:148-155`.
051. Multi-model citation: `01-REVIEW-multi-model.md:547-553`.
052. The manager loop must integrate skillos without folding skillos into this plan.
053. Skillos citation: `cross-orch-input/skillos-1-2026-05-05T1555Z.md:11-19`.
054. Skillos citation: `cross-orch-input/skillos-1-2026-05-05T1555Z.md:21-29`.
055. The layer separation is load-bearing.
056. Fleet-autonomy decides watcher substrate behavior.
057. Manager-loop decides current cross-fleet leverage.
058. skillos decides which skill/capability should apply to work.
059. Skillos citation: `cross-orch-input/skillos-1-2026-05-05T1555Z.md:13-19`.
060. None of the three layers should consume the others.
061. Each layer publishes robot-mode facts for the next layer to compose.
062. The primary stock is verified mission-anchor closure.
063. Secondary stocks are decision debt, validated operational state, callback/log divergence, and founder attention demand.
064. Tertiary stocks are stale dispatches, stale reservations, frozen panes, and unprocessed fuckup classes.
065. The current failed loop is callback overload.
066. The target loop is signal -> ranked decision -> action receipt -> validated stock movement -> scorer correction.
067. Donella citation: `01-REVIEW-donella.md:475-580`.
068. The plan succeeds only if callback traffic falls while mission closure and validation visibility rise.
069. Donella citation: `01-REVIEW-donella.md:944-986`.
070. A quiet orchestrator with invisible failure is not success.
071. A pretty Markdown file that Joshua must interpret is not success.
072. A top-10 list with ten non-mission items is not success.
073. A tick loop with no validated outflow is not success.
074. An ops-log full of untrusted worker claims is not success.
075. Success is a controller that sees current substrate state, chooses mission-licensed leverage, acts with receipts, validates the effect, and improves the scoring policy when it was wrong.

## 2. Atomic Primitives

076. Final primitive count: 6.
077. Each primitive below is atomic and reversible.
078. Each primitive includes Donella leverage point, stock impacted, flow change, loop topology, intervention scope, measurement loop, working-sibling-diff, and atomic-write discipline.
079. The naming uses A0-A5 to avoid confusion with the original M1-M4.

### A0 - Manager-State Read Model

080. Primitive id: A0-manager-state-read-model.
081. Final verdict: ship first.
082. Leverage point: #6 information flows.
083. Secondary leverage point: #5 rules.
084. Stock impacted: shared operational state visible to manager decisions.
085. Secondary stock: founder attention demand.
086. Flow changed: existing ledgers flow into one read-only composed state.
087. Inflow: dispatch-log rows.
088. Inflow: callback validation receipts.
089. Inflow: `bv` robot outputs.
090. Inflow: `br` issue state.
091. Inflow: Agent Mail reservation state.
092. Inflow: `ntm` activity/health surfaces.
093. Inflow: fuckup-log triage.
094. Inflow: doctor JSON.
095. Inflow: Joshua-request JSONL.
096. Inflow: mission-anchor dispatch license output.
097. Outflow: `manager-state.json`.
098. Outflow: `manager-state.md` projection.
099. Outflow: `manager-state --robot-schema`.
100. Loop topology: missing-feedback loop becomes a visible-state loop.
101. Signal: owned ledgers and robot surfaces.
102. Actor: manager-state composer.
103. Response: publish one current state snapshot with source offsets and stale-source warnings.
104. Delay: source-specific freshness windows.
105. Intervention scope: read-only.
106. Intervention scope: no worker behavior changes.
107. Intervention scope: no callback cutover.
108. Intervention scope: no new authority over upstream ledgers.
109. Measurement loop: source coverage percent.
110. Measurement loop: stale source count.
111. Measurement loop: manager-state generation latency.
112. Measurement loop: facts with owner ledger refs.
113. Measurement loop: facts missing validation receipts.
114. Measurement loop: Joshua interventions on items absent from state.
115. Measurement loop: peer agents able to consume robot JSON.
116. Working-sibling-diff: from fleet morning/report surfaces to live manager state.
117. Jeff citation: `01-REVIEW-jeff.md:628-665`.
118. Working-sibling-diff: from `robot-attention` steady-state operator surface to manager-state.
119. Jeff citation: `01-REVIEW-jeff.md:127-141`.
120. Working-sibling-diff: from architecture-health rollups to current decision state.
121. Socraticode citation: `tests/architecture-health-rollup.sh:24-104`.
122. Atomic-write discipline: write JSON to temp, fsync, atomic rename.
123. Atomic-write discipline: render Markdown from JSON only.
124. Atomic-write discipline: include source JSON hash in Markdown.
125. Atomic-write discipline: never edit Markdown by hand.
126. CLI discipline: `flywheel-loop manager state --json`.
127. CLI discipline: `flywheel-loop manager state --markdown`.
128. CLI discipline: `flywheel-loop manager state --robot-schema`.
129. CLI discipline: `flywheel-loop manager validate state --json`.
130. CLI discipline: `flywheel-loop manager why <queue-item-id> --json`.
131. Doctor field: `manager_state_last_generated_at`.
132. Doctor field: `manager_state_source_stale_count`.
133. Doctor field: `manager_state_schema_valid`.
134. Doctor field: `manager_state_markdown_hash_matches_json`.
135. Health field: `manager_state_age_seconds`.
136. Health field: `manager_state_status`.
137. Repair field: regenerate projection from source ledgers.
138. Accepted change: Jeff's read-only first ship.
139. Tag: leverage point #6, stock shared operational state, loop missing feedback.
140. Citation: `01-REVIEW-jeff.md:907-910`.
141. Accepted change: multi-model's JSON-canonical Markdown projection.
142. Tag: leverage point #6, stock founder attention demand, loop surface-trust.
143. Citation: `01-REVIEW-multi-model.md:678-686`.
144. Accepted change: Donella's audit surface, not controller.
145. Tag: leverage point #6, stock founder attention demand, loop human-as-feedback.
146. Citation: `01-REVIEW-donella.md:899-910`.
147. Rejected change for A0: make ops-log primary before manager-state exists.
148. Tag: leverage point #5, stock authority drift, loop validation-governor.
149. Citation: `01-REVIEW-jeff.md:353-438`.
150. Exit criterion: `manager-state.json` explains all active dispatches, stale callbacks, stale panes, reservations, and mission-license gaps without reading pane chat.

### A1 - Ops-Log Compatibility Mirror And Index

151. Primitive id: A1-ops-log-compatibility-mirror.
152. Final verdict: keep, demote, and delay authority.
153. Leverage point: #6 information flows.
154. Secondary leverage point: #5 rules.
155. Secondary leverage point: #4 self-organization when row schemas evolve through validation.
156. Stock impacted: validated operational event history.
157. Secondary stock: callback/log divergence.
158. Flow changed: compatibility callbacks and owned ledgers are mirrored into a normalized index.
159. Inflow: callback imports.
160. Inflow: dispatch-log import.
161. Inflow: worker opt-in mirror rows.
162. Inflow: validator rows.
163. Inflow: doctor observation rows.
164. Inflow: manager decision receipt rows.
165. Inflow: skill usage rows.
166. Outflow: manager-state reads normalized events with source refs.
167. Outflow: parity validator compares mirror against owned ledgers.
168. Loop topology: callback/log divergence loop.
169. Signal: row exists, source exists, validator sees both.
170. Actor: ops-log validator.
171. Response: accept, quarantine, or mark divergence.
172. Delay: write-to-visible target under 5 seconds.
173. Intervention scope: mirror and index, not authority.
174. Intervention scope: no owned ledger is replaced.
175. Intervention scope: no worker callback is removed.
176. Measurement loop: rows written per hour.
177. Measurement loop: rows rejected per hour.
178. Measurement loop: callback/log divergence count.
179. Measurement loop: manual callback import coverage.
180. Measurement loop: source evidence missing count.
181. Measurement loop: row validation latency.
182. Measurement loop: writer schema skew.
183. Measurement loop: row quarantine backlog.
184. Working-sibling-diff: use existing validated JSONL append posture.
185. Multi-model citation: `01-REVIEW-multi-model.md:614-621`.
186. Donella citation: `01-REVIEW-donella.md:220-242`.
187. Jeff citation: `01-REVIEW-jeff.md:789-791`.
188. Atomic-write discipline: each writer uses a single append helper.
189. Atomic-write discipline: helper validates JSON object before append.
190. Atomic-write discipline: helper writes rejected rows to quarantine with reason.
191. Atomic-write discipline: concurrent append uses lock or session shard.
192. Atomic-write discipline: no temp-plus-replace for append-only concurrent write.
193. Atomic-write discipline: every row includes `schema_version`.
194. Atomic-write discipline: every row includes `event_id`.
195. Atomic-write discipline: every row includes `source_ref`.
196. Atomic-write discipline: every row includes `source_hash` where applicable.
197. Atomic-write discipline: every row includes `authority`.
198. Authority values: `claim`, `observation`, `verdict`, `decision`, `mutation`.
199. Unvalidated worker claims may affect attention.
200. Unvalidated worker claims may not affect closure, health, or mission-progress stock.
201. Donella citation: `01-REVIEW-donella.md:830-839`.
202. Stock delta ownership: aggregator computes deltas after validation.
203. Donella citation: `01-REVIEW-donella.md:830-839`.
204. Multi-model citation: `01-REVIEW-multi-model.md:272-279`.
205. Schema minimum: `schema_version`.
206. Schema minimum: `event_id`.
207. Schema minimum: `ts`.
208. Schema minimum: `observed_at`.
209. Schema minimum: `ingested_at`.
210. Schema minimum: `writer_id`.
211. Schema minimum: `writer_role`.
212. Schema minimum: `source_session`.
213. Schema minimum: `source_repo`.
214. Schema minimum: `event_type`.
215. Schema minimum: `authority`.
216. Schema minimum: `validation_state`.
217. Schema minimum: `task_id`.
218. Schema minimum: `bead_id`.
219. Schema minimum: `mission_anchor_id`.
220. Schema minimum: `mission_anchor_evidence_path`.
221. Schema minimum: `skill_invoked`.
222. Schema minimum: `skill_recommendation_ref`.
223. Schema minimum: `stock_delta_computed_ref`.
224. Schema minimum: `evidence_type`.
225. Schema minimum: `evidence_path`.
226. Schema minimum: `evidence_hash`.
227. Schema minimum: `correlation_id`.
228. Schema minimum: `idempotency_key`.
229. Schema minimum: `parent_event_id`.
230. Schema minimum: `details`.
231. Schema minimum: `details_ref`.
232. Schema minimum: `redaction_status`.
233. Skillos integration: include `skill_invoked`.
234. Skillos citation: `cross-orch-input/skillos-1-2026-05-05T1555Z.md:23-29`.
235. Skillos integration: include peer canonical log path at registration time.
236. Skillos citation: `cross-orch-input/skillos-1-2026-05-05T1555Z.md:28-29`.
237. Skill eligibility: require `mission_anchor_evidence_path` for skill invocation rows.
238. Skillos citation: `cross-orch-input/skillos-1-2026-05-05T1555Z.md:30-38`.
239. CLI discipline: `flywheel-loop manager ops-log validate --json`.
240. CLI discipline: `flywheel-loop manager ops-log doctor --json`.
241. CLI discipline: `flywheel-loop manager ops-log repair --dry-run --json`.
242. CLI discipline: `flywheel-loop manager ops-log why <event-id> --json`.
243. Accepted change: every row has schema version, not first-row schema version.
244. Tag: leverage point #5, stock schema-valid rows, loop validation-governor.
245. Citation: `01-REVIEW-multi-model.md:398-400`.
246. Accepted change: callbacks remain until parity.
247. Tag: leverage point #5, stock callback/log divergence, loop migration-governor.
248. Citation: `01-REVIEW-donella.md:888-891`.
249. Citation: `01-REVIEW-jeff.md:936-943`.
250. Somewhat accepted change: call this ops-log.
251. Caveat: name may remain for familiarity, but authority is mirror/index only.
252. Tag: leverage point #6, stock operational event history, loop source-of-truth.
253. Citation: `01-REVIEW-jeff.md:399-407`.
254. Disagreed change: workers stop sending `ntm send` callbacks at M1.
255. Reason: callback delivery has a stronger current receipt than ops-log does.
256. Tag: leverage point #5, stock callback/log divergence, loop migration-governor.
257. Citation: `00-PLAN-INPUT.md:85`.
258. Citation: `01-REVIEW-donella.md:148-155`.
259. Exit criterion: mirror proves zero material divergence for the configured parity window.

### A2 - Scoring Governor And Top-N Leverage Queue

260. Primitive id: A2-scoring-governor-top-n-queue.
261. Final verdict: keep and make explicit.
262. Leverage point: #3 goals.
263. Secondary leverage point: #6 information flows.
264. Secondary leverage point: #8 negative feedback.
265. Secondary leverage point: #5 rules.
266. Stock impacted: mission-licensed actionable leverage.
267. Secondary stock: decision debt.
268. Secondary stock: scoring opacity.
269. Flow changed: heterogeneous candidates become ranked hypotheses with evidence and counterfactuals.
270. Inflow: `bv --robot-next` and future top-N robot contract.
271. Inflow: active dispatch age and validation state.
272. Inflow: reservation conflicts and stale candidates.
273. Inflow: fuckup-log promotion candidates.
274. Inflow: closed-bead audit gaps.
275. Inflow: Joshua requests.
276. Inflow: mission-anchor dispatch license list.
277. Inflow: skillos skill recommendation surface.
278. Outflow: queue item selected, deferred, rejected, or converted to tool/skill/audit work.
279. Loop topology: scoring opacity reinforcing loop becomes scoring accountability loop.
280. Signal: score components, confidence, mission license, if-wrong cost, outcome.
281. Actor: scoring governor.
282. Response: rank, explain, constrain, and update only by validation receipt.
283. Delay: source freshness and outcome validation.
284. Intervention scope: queue computation and scoring policy only.
285. Intervention scope: no upstream `bv` patch in this plan.
286. Intervention scope: upstream issues may be drafted.
287. Measurement loop: top-N items with mission evidence.
288. Measurement loop: high-score false positive rate.
289. Measurement loop: low-score later-urgent rate.
290. Measurement loop: rank vs validated mission closure.
291. Measurement loop: scorer formula changes with validation receipt.
292. Measurement loop: queue item acted within expected interval.
293. Measurement loop: Joshua acted on non-queue item.
294. Measurement loop: skill recommendation accepted/rejected outcome.
295. Working-sibling-diff: consume `bv` rather than reimplement PageRank.
296. Jeff citation: `01-REVIEW-jeff.md:527-628`.
297. Working-sibling-diff: use mission-anchor dispatch license.
298. Socraticode citation: `tests/mission-anchor-dispatch-license-test.sh:59-132`.
299. Working-sibling-diff: preserve more than top ten in JSON, render top ten in Markdown.
300. Jeff citation: `01-REVIEW-jeff.md:617-626`.
301. Atomic-write discipline: queue JSON is generated to temp and atomic-renamed.
302. Atomic-write discipline: queue item ids are deterministic from source hashes.
303. Atomic-write discipline: scoring version and weights hash are embedded.
304. Atomic-write discipline: every selected item has `selected_item_hash`.
305. Queue item fields: `queue_item_id`.
306. Queue item fields: `rank`.
307. Queue item fields: `kind`.
308. Queue item fields: `source_owner`.
309. Queue item fields: `id`.
310. Queue item fields: `mission_anchor_id`.
311. Queue item fields: `mission_anchor_evidence_path`.
312. Queue item fields: `mission_delta_expected`.
313. Queue item fields: `skill_recommendation_ref`.
314. Queue item fields: `score`.
315. Queue item fields: `score_components`.
316. Queue item fields: `scoring_version`.
317. Queue item fields: `confidence`.
318. Queue item fields: `if_wrong_cost`.
319. Queue item fields: `reversibility`.
320. Queue item fields: `validation_probe`.
321. Queue item fields: `runner_up_reason`.
322. Queue item fields: `ineligibility_reason`.
323. Queue item fields: `suggested_action`.
324. Queue item fields: `evidence_refs`.
325. Queue item fields: `human_required_reason`.
326. Queue item fields: `scorer_should_learn_from_outcome`.
327. Mission eligibility: work items require mission anchor.
328. Substrate exceptions: allowed only with typed `no_mission_anchor_reason`.
329. Substrate exception examples: driver repair, schema repair, storage receipt, callback import, reservation safety.
330. Top-N naming: JSON preserves all eligible candidates; Markdown renders current top ten.
331. Original top-10 always target is revised.
332. Donella citation: `01-REVIEW-donella.md:70-86`.
333. Scoring governor section must precede ship order.
334. Donella citation: `01-REVIEW-donella.md:805-812`.
335. Accepted change: name and contract the scoring governor.
336. Tag: leverage point #3, stock mission-licensed leverage, loop scoring-opacity.
337. Citation: `01-REVIEW-donella.md:859-873`.
338. Accepted change: mission-anchor gate.
339. Tag: leverage point #3, stock verified mission closure, loop mission-value correction.
340. Citation: `01-REVIEW-donella.md:844-854`.
341. Accepted change: deterministic score components instead of vague multi-model blend.
342. Tag: leverage point #5, stock scoring opacity, loop scoring-governor.
343. Citation: `01-REVIEW-multi-model.md:669-677`.
344. Somewhat accepted change: use Donella/Jeff modes.
345. Caveat: modes inform a versioned scoring contract; runtime score is deterministic.
346. Tag: leverage point #5, stock scoring opacity, loop parameter-thrashing.
347. Citation: `01-REVIEW-jeff.md:917-923`.
348. Disagreed change: queue must always contain exactly 10 items.
349. Reason: fewer mission-eligible items is a valid state, not a failure to stuff queue.
350. Tag: leverage point #3, stock mission-licensed leverage, loop perverse feedback.
351. Citation: `00-PLAN-INPUT.md:186-190`.
352. Citation: `01-REVIEW-donella.md:70-86`.
353. Exit criterion: scorer can explain each rank, each skipped candidate, and each outcome update without hidden arithmetic.

### A3 - Manager Tick Driver And Decision Receipts

354. Primitive id: A3-manager-tick-driver.
355. Final verdict: keep, but ship after A0 and A2.
356. Leverage point: #8 negative feedback loop strength.
357. Secondary leverage point: #5 rules.
358. Secondary leverage point: #9 delays.
359. Stock impacted: decision debt.
360. Secondary stock: stale dispatches.
361. Secondary stock: unvalidated decisions.
362. Flow changed: manager-state and queue flow into bounded, receiptful actions.
363. Inflow: manager-state snapshot hash.
364. Inflow: queue snapshot hash.
365. Inflow: previous decision receipt hash.
366. Inflow: tick cursor.
367. Inflow: driver health.
368. Outflow: decision receipt.
369. Outflow: action receipt reference.
370. Outflow: no-op receipt.
371. Outflow: safety-action receipt.
372. Outflow: validation follow-up row.
373. Loop topology: decision-debt balancing loop.
374. Signal: queue pressure and decision debt.
375. Actor: manager tick driver.
376. Response: choose one decision group, execute or dry-run, publish receipt, validate effect.
377. Delay: decision interval and validation interval.
378. Intervention scope: driver process and decision receipts.
379. Intervention scope: does not own upstream mutations.
380. Intervention scope: delegates pane actuation to `ntm`.
381. Intervention scope: delegates reservation repair to Agent Mail.
382. Intervention scope: delegates ranking to A2.
383. Measurement loop: decision debt before tick.
384. Measurement loop: decision debt after tick.
385. Measurement loop: tick latency.
386. Measurement loop: tick overrun count.
387. Measurement loop: duplicate dispatch count.
388. Measurement loop: no-op tick count with reasons.
389. Measurement loop: validated outcome within one interval.
390. Measurement loop: driver last fire fresh within two intervals.
391. Working-sibling-diff: use tick-driver manifest, lock, and ledger patterns.
392. Socraticode citation: `tests/flywheel-tick-driver.sh:78-159`.
393. Working-sibling-diff: L57/L116 forbid marker-only tick claims.
394. Socraticode citation: `AGENTS.md:3241-3340`.
395. Working-sibling-diff: existing dispatch delivery requires four-state receipt.
396. Socraticode citation: `AGENTS.md:2161-2260`.
397. Atomic-write discipline: decision receipt written via temp, fsync, rename.
398. Atomic-write discipline: tick ledger append uses validated JSONL helper.
399. Atomic-write discipline: cursor checkpoints only after publication.
400. Atomic-write discipline: lock prevents overlapping ticks.
401. Atomic-write discipline: skipped-lock writes a receipt.
402. Decision receipt fields: `schema_version=manager_decision_receipt/v1`.
403. Decision receipt fields: `tick_id`.
404. Decision receipt fields: `idempotency_key`.
405. Decision receipt fields: `started_at`.
406. Decision receipt fields: `completed_at`.
407. Decision receipt fields: `input_state_hash`.
408. Decision receipt fields: `queue_hash`.
409. Decision receipt fields: `selected_item_hash`.
410. Decision receipt fields: `previous_receipt_hash`.
411. Decision receipt fields: `decision_group`.
412. Decision receipt fields: `decision`.
413. Decision receipt fields: `rationale`.
414. Decision receipt fields: `evidence_refs`.
415. Decision receipt fields: `dry_run`.
416. Decision receipt fields: `apply`.
417. Decision receipt fields: `actuation_receipt_ref`.
418. Decision receipt fields: `validation_probe_ref`.
419. Decision receipt fields: `rollback_hint`.
420. Decision receipt fields: `next_check_at`.
421. Default cadence: decision tick every 300 seconds.
422. Multi-model citation: `01-REVIEW-multi-model.md:421-490`.
423. Ingest cadence: 60 seconds for source freshness.
424. Render cadence: 600 seconds or on demand for human Markdown.
425. Safety path: event-driven, not interval-bound.
426. One-decision rule: one discretionary decision group per tick.
427. Safety actions, validation imports, state render, and receipt repair are not capped by the discretionary decision limit.
428. Donella citation: `01-REVIEW-donella.md:873-887`.
429. Multi-model citation: `01-REVIEW-multi-model.md:650-657`.
430. Jeff citation: `01-REVIEW-jeff.md:480-494`.
431. Pressure-bounded exception: when stock pressure crosses a declared threshold, the tick may execute a decision group containing multiple homogeneous repairs.
432. Example decision group: import overdue callbacks for one task family.
433. Example decision group: render state and mark stale sources.
434. Example decision group: dispatch one worker.
435. Example decision group: run one safe repair dry-run.
436. Wait is not a decision unless it has `wait_until` and a recheck predicate.
437. Donella citation: `01-REVIEW-donella.md:297-307`.
438. CLI discipline: `flywheel-loop manager tick --dry-run --json`.
439. CLI discipline: `flywheel-loop manager tick --apply --json`.
440. CLI discipline: `flywheel-loop manager tick validate --json`.
441. CLI discipline: `flywheel-loop manager tick why <tick-id> --json`.
442. Doctor field: `manager_tick_last_fire_ts`.
443. Doctor field: `manager_tick_last_exit_status`.
444. Doctor field: `manager_tick_overlap_prevented_count`.
445. Doctor field: `manager_tick_cursor_health`.
446. Repair field: unlock stale tick lock only with receipt and dry-run/apply split.
447. Accepted change: split read, score, decide, execute, validate, publish, checkpoint.
448. Tag: leverage point #8, stock decision debt, loop decision-debt balancing.
449. Citation: `01-REVIEW-donella.md:297-309`.
450. Accepted change: decision receipt.
451. Tag: leverage point #8, stock unvalidated decisions, loop validation-governor.
452. Citation: `01-REVIEW-jeff.md:911-915`.
453. Somewhat accepted change: 600-second tick.
454. Caveat: 600s is render cadence; 300s is decision cadence.
455. Tag: leverage point #9, stock decision debt, loop delay.
456. Citation: `00-PLAN-INPUT.md:100-103`.
457. Citation: `01-REVIEW-multi-model.md:421-490`.
458. Disagreed change: fixed one decision per tick with no exceptions.
459. Reason: urgent stock pressure can exceed one action and safety receipts must not wait.
460. Tag: leverage point #8, stock frozen/stale work, loop decision-debt balancing.
461. Citation: `00-PLAN-INPUT.md:100-103`.
462. Citation: `01-REVIEW-donella.md:121-128`.
463. Exit criterion: every tick either moves a named stock, protects a named stock, or emits a validated no-op reason.

### A4 - Shared Surface Renderer

464. Primitive id: A4-shared-surface-renderer.
465. Final verdict: keep and shrink.
466. Leverage point: #6 information flows.
467. Secondary leverage point: #8 feedback if corrections update rules.
468. Stock impacted: shared situational awareness.
469. Secondary stock: founder attention demand.
470. Flow changed: manager-state JSON projects into a concise human and robot surface.
471. Inflow: manager-state JSON.
472. Inflow: queue JSON.
473. Inflow: last decision receipts.
474. Inflow: verdict threshold evaluation.
475. Inflow: pending true-human blockers.
476. Outflow: Markdown projection.
477. Outflow: robot JSON.
478. Outflow: stale warnings.
479. Loop topology: surface-trust loop.
480. Signal: state, queue, decisions, thresholds, unknowns.
481. Actor: Joshua, peer orchestrators, and manager tick.
482. Response: exception correction, not routine digestion.
483. Delay: render interval and read interval.
484. Intervention scope: projection only.
485. Intervention scope: not source of truth.
486. Intervention scope: not editable.
487. Measurement loop: Markdown/JSON hash match.
488. Measurement loop: stale surface reads.
489. Measurement loop: Joshua interventions on invisible items.
490. Measurement loop: corrections that changed scorer rules.
491. Measurement loop: true-human blockers closed per day.
492. Measurement loop: false-human blockers auto-routed per day.
493. Working-sibling-diff: use morning report as a view, not a new brain.
494. Jeff citation: `01-REVIEW-jeff.md:570-615`.
495. Multi-model citation: `01-REVIEW-multi-model.md:132-139`.
496. Donella citation: `01-REVIEW-donella.md:412-470`.
497. Atomic-write discipline: render Markdown to temp, fsync, atomic rename.
498. Atomic-write discipline: renderer refuses stale or schema-invalid JSON unless output is explicitly DEGRADED.
499. Atomic-write discipline: output includes `source_json_hash`.
500. Atomic-write discipline: output includes `generated_at`.
501. Atomic-write discipline: output includes `schema_version`.
502. Required sections in Markdown: current verdict.
503. Required sections in Markdown: mission-anchor closure trend.
504. Required sections in Markdown: current top ten or queue insufficiency.
505. Required sections in Markdown: last tick decision and receipt.
506. Required sections in Markdown: last five ticks.
507. Required sections in Markdown: stale or missing sources.
508. Required sections in Markdown: active true-human blockers.
509. Required sections in Markdown: what changed since last render.
510. Required sections in Markdown: autonomous corrections taken.
511. Required sections in Markdown: scorer version and drift warnings.
512. Required sections in Markdown: callback/log parity.
513. Pending Joshua decisions are allowed only with `human_question`.
514. Pending Joshua decisions require `why_not_agent`.
515. Pending Joshua decisions require `probe_ledger_ref`.
516. Pending Joshua decisions require `safe_local_work_remaining`.
517. Pending Joshua decisions require `decision_deadline`.
518. Multi-model citation: `01-REVIEW-multi-model.md:669-678`.
519. CLI discipline: `flywheel-loop manager render --json`.
520. CLI discipline: `flywheel-loop manager render --markdown`.
521. CLI discipline: `flywheel-loop manager render validate --json`.
522. CLI discipline: `flywheel-loop manager render repair --dry-run --json`.
523. Doctor field: `manager_surface_json_valid`.
524. Doctor field: `manager_surface_markdown_current`.
525. Doctor field: `manager_surface_hash_match`.
526. Health field: `manager_surface_age_seconds`.
527. Accepted change: JSON is canonical and Markdown is projection.
528. Tag: leverage point #6, stock shared situational awareness, loop surface-trust.
529. Citation: `01-REVIEW-donella.md:441-453`.
530. Citation: `01-REVIEW-jeff.md:628-665`.
531. Accepted change: human questions are typed and scarce.
532. Tag: leverage point #5, stock founder attention demand, loop human-as-feedback.
533. Citation: `01-REVIEW-multi-model.md:694-703`.
534. Somewhat accepted change: Joshua-readable surface.
535. Caveat: it is an audit and exception surface, not the controller.
536. Tag: leverage point #6, stock founder attention demand, loop surface-trust.
537. Citation: `00-PLAN-INPUT.md:125-138`.
538. Citation: `01-REVIEW-donella.md:899-910`.
539. Disagreed change: Markdown and JSON are peer truth stores.
540. Reason: divergence recreates split-brain.
541. Tag: leverage point #5, stock shared situational awareness, loop surface-trust.
542. Citation: `00-PLAN-INPUT.md:125-138`.
543. Citation: `01-REVIEW-jeff.md:630-665`.
544. Exit criterion: Joshua can read one file and see current state, but no routine action depends on him reading it.

### A5 - Migration And Callback Cutover Governor

545. Primitive id: A5-migration-callback-cutover-governor.
546. Final verdict: keep as gate, not background assumption.
547. Leverage point: #5 rules.
548. Secondary leverage point: #8 negative feedback.
549. Secondary leverage point: #9 delays.
550. Stock impacted: callback/log divergence.
551. Secondary stock: trusted migration evidence.
552. Flow changed: compatibility callbacks and manager-state mirror run in shadow mode until parity gates pass.
553. Inflow: compatibility callbacks.
554. Inflow: dispatch-log rows.
555. Inflow: ops-log mirror rows.
556. Inflow: callback import rows.
557. Inflow: validator verdict rows.
558. Inflow: manager-state source coverage.
559. Outflow: cutover permit or cutover refusal.
560. Loop topology: migration-governor balancing loop.
561. Signal: divergence and coverage metrics.
562. Actor: migration governor.
563. Response: continue shadow mode, import missing callbacks, or permit cutover.
564. Delay: parity window.
565. Intervention scope: migration policy only.
566. Intervention scope: no source callback removal before permit.
567. Measurement loop: parity match rate.
568. Measurement loop: missing callback imports.
569. Measurement loop: material divergence count.
570. Measurement loop: latency from callback to manager-state visibility.
571. Measurement loop: cutover refusals with reasons.
572. Measurement loop: post-cutover regression count.
573. Working-sibling-diff: preserve dispatch callback contract until successor receipt passes.
574. Donella citation: `01-REVIEW-donella.md:148-155`.
575. Jeff citation: `01-REVIEW-jeff.md:936-963`.
576. Multi-model citation: `01-REVIEW-multi-model.md:704-712`.
577. Atomic-write discipline: cutover permit is a JSON receipt.
578. Atomic-write discipline: permit includes source hashes for parity evidence.
579. Atomic-write discipline: callback-dead marker is atomic and reversible by config.
580. Atomic-write discipline: failed imports write quarantine rows.
581. Cutover gate: manager-state sees every DONE/BLOCKED callback.
582. Cutover gate: manager-state sees every reservation conflict.
583. Cutover gate: manager-state sees every fuckup-log blocker.
584. Cutover gate: manager-state sees every stale pane alert.
585. Cutover gate: manager-state sees manual callbacks by task id.
586. Cutover gate: all within two decision ticks.
587. Cutover gate: zero material divergence for N ticks.
588. Cutover gate: zero missing evidence for N ticks.
589. Cutover gate: callback/log latency within target.
590. Cutover gate: manager-state status green or explicit approved degraded cutover.
591. Recommended N: 24h or one replay of the overnight failure corpus.
592. Multi-model citation: `01-REVIEW-multi-model.md:858-865`.
593. Donella citation: `01-REVIEW-donella.md:888-891`.
594. Jeff citation: `01-REVIEW-jeff.md:940-943`.
595. CLI discipline: `flywheel-loop manager migration status --json`.
596. CLI discipline: `flywheel-loop manager migration import-callback --task-id <id> --json`.
597. CLI discipline: `flywheel-loop manager migration cutover --dry-run --json`.
598. CLI discipline: `flywheel-loop manager migration cutover --apply --json`.
599. CLI discipline: `flywheel-loop manager migration rollback --dry-run --json`.
600. Accepted change: add parity gates before killing callbacks.
601. Tag: leverage point #5, stock callback/log divergence, loop migration-governor.
602. Citation: `01-REVIEW-multi-model.md:704-712`.
603. Accepted change: manual callback import is MVP.
604. Tag: leverage point #6, stock trusted operational state, loop callback visibility.
605. Citation: `01-REVIEW-multi-model.md:686-693`.
606. Citation: `cross-orch-input/skillos-1-2026-05-05T1555Z.md:28-29`.
607. Somewhat accepted change: callbacks eventually die.
608. Caveat: only after a stronger manager-state receipt exists.
609. Tag: leverage point #5, stock callback/log divergence, loop migration-governor.
610. Citation: `00-PLAN-INPUT.md:85`.
611. Disagreed change: "no other channel for orchestrator-visible signals" during migration.
612. Reason: dual-write needs a rule for surface precedence, not denial that two surfaces exist.
613. Tag: leverage point #5, stock authority drift, loop migration-governor.
614. Citation: `00-PLAN-INPUT.md:60-63`.
615. Citation: `01-REVIEW-donella.md:34-52`.
616. Exit criterion: callbacks are removed only by a recorded cutover permit that can be audited and rolled back.

## 3. Ship Order

617. Ship order is final for this integrated plan.
618. Step 0: Freeze the integrated plan as `00-PLAN.md`.
619. Step 1: A0 manager-state read model.
620. Step 2: A2 scoring governor and queue in read-only mode.
621. Step 3: A4 shared surface renderer over A0 and A2.
622. Step 4: A1 ops-log compatibility mirror/index in shadow mode.
623. Step 5: A5 migration and callback parity governor.
624. Step 6: A3 manager tick driver in dry-run mode.
625. Step 7: A3 manager tick driver in apply mode for one discretionary decision group per tick.
626. Step 8: A5 cutover permit if parity gates pass.
627. Step 9: Callback cutover.
628. Step 10: Re-evaluate fleet-autonomy P4-P6 as measured repair paths.
629. Step 11: Draft upstream issues only where manager-state proves a missing stable robot contract.
630. Step 12: Run convergence audit.
631. Ship-first rationale: Jeff's counter-thesis says existing substrate covers much of the plan.
632. Jeff citation: `01-REVIEW-jeff.md:850-887`.
633. Ship-first rationale: A0 proves visibility without changing worker behavior.
634. Ship-first rationale: A0 is low-risk and immediately useful.
635. Ship-first rationale: A0 gives Joshua the surface while preserving existing callbacks.
636. Ship-second rationale: A2 is where values enter the system.
637. Ship-second rationale: if the scoring governor is opaque, the plan fails even with a perfect log.
638. Donella citation: `01-REVIEW-donella.md:722-775`.
639. Ship-third rationale: A4 makes the read model usable without making it authority.
640. Ship-fourth rationale: A1 mirror/index becomes safer after A0/A2 define what consumers need.
641. Ship-fifth rationale: A5 measures the migration instead of assuming it.
642. Ship-sixth rationale: A3 tick actuation is only safe when state, scorer, surface, and parity gates exist.
643. Deferred: new ops-log as primary authority.
644. Jeff citation: `01-REVIEW-jeff.md:991-999`.
645. Deferred: callback death.
646. Jeff citation: `01-REVIEW-jeff.md:991-999`.
647. Deferred: automatic reservation force release.
648. Deferred: automatic pane respawn.
649. Deferred: automatic repair-bead priority overrides.
650. Deferred: upstream patches.
651. Deferred: fleet-wide command center across every repo.
652. Deferred: skillos mission-lock content.
653. Skillos citation: `cross-orch-input/skillos-1-2026-05-05T1555Z.md:56-61`.
654. Reversibility: A0 can be deleted without state mutation.
655. Reversibility: A2 can be disabled by ignoring its queue output.
656. Reversibility: A4 can be regenerated from JSON.
657. Reversibility: A1 can be rebuilt from owned ledgers.
658. Reversibility: A5 can refuse cutover and keep callbacks.
659. Reversibility: A3 can remain dry-run or be stopped by driver config.
660. Gate after each step: `doctor`.
661. Gate after each step: `health`.
662. Gate after each step: `validate`.
663. Gate after each step: replay fixture.
664. Gate after each step: source-hash proof.
665. Gate after each step: no undocumented authority transfer.
666. Gate after each step: no source edits outside the owned primitive.
667. Gate after each step: no degradation of existing callbacks.
668. First replay fixture: overnight 60+ callbacks.
669. Second replay fixture: skillos manual callback gap.
670. Third replay fixture: mobile-eats mission compression.
671. Multi-model citation: `01-REVIEW-multi-model.md:696-704`.
672. Ship-order verdict: composer first, scorer second, renderer third, mirror fourth, migration fifth, actuator sixth.

## 4. Cross-Plan Reconciliation

673. This plan explicitly deprecates parts of fleet-autonomy-v1.
674. Deprecated: fleet-autonomy P3 as an independent controller.
675. Reason: manager-state read model and shared surface own the status/control read model.
676. Multi-model citation: `01-REVIEW-multi-model.md:106-117`.
677. Deprecated: fleet-autonomy M as primary measurement.
678. Reason: morning report is a projection over manager-state, not a separate primitive.
679. Multi-model citation: `01-REVIEW-multi-model.md:132-139`.
680. Deprecated: callback-as-orchestrator-input.
681. Reason: callbacks become compatibility input and then non-control-path evidence.
682. Multi-model citation: `01-REVIEW-multi-model.md:137-147`.
683. Preserved: fleet-autonomy P1 `bv` selector replacement.
684. Reason: A2 consumes `bv` as a ranking substrate.
685. Multi-model citation: `01-REVIEW-multi-model.md:92-99`.
686. Preserved: fleet-autonomy P2 retry-state discipline.
687. Reason: A2/A5 use retry-after-state-change and divergence gates.
688. Multi-model citation: `01-REVIEW-multi-model.md:99-105`.
689. Preserved: fleet-autonomy P3 schema fields.
690. Reason: closure conversion, overdue callbacks, driver status, and mission delta remain manager-state fields.
691. Multi-model citation: `01-REVIEW-multi-model.md:110-117`.
692. Preserved: fleet-autonomy P4 reservation repair concern.
693. Reason: surfaced as status and repair candidate; mutation remains Agent Mail-owned.
694. Multi-model citation: `01-REVIEW-multi-model.md:118-123`.
695. Preserved: fleet-autonomy P5 pane freeze concern.
696. Reason: surfaced as status and repair candidate; actuation remains ntm-owned.
697. Multi-model citation: `01-REVIEW-multi-model.md:124-127`.
698. Preserved: fleet-autonomy P6 repair-bead aging concern.
699. Reason: surfaced as queue signal; priority ownership remains `bv` or explicit manager scoring contract.
700. Multi-model citation: `01-REVIEW-multi-model.md:128-131`.
701. Layer separation: fleet-autonomy remains substrate selection and watcher safety.
702. Layer separation: manager-loop is cross-substrate decision flow.
703. Layer separation: skillos is capability control plane.
704. Skillos citation: `cross-orch-input/skillos-1-2026-05-05T1555Z.md:11-19`.
705. The manager loop does not absorb skillos.
706. The manager loop accepts `skill_invoked` and skill recommendation refs as integration fields.
707. Skillos citation: `cross-orch-input/skillos-1-2026-05-05T1555Z.md:23-29`.
708. The manager loop does not absorb mission-coverage compiler.
709. It requires mission anchor refs; compiler owns the richer matrix.
710. Multi-model citation: `01-REVIEW-multi-model.md:817-820`.
711. Cross-plan verdict: manager-loop obsoletes control-plane shape, not every fleet primitive.
712. Multi-model citation: `01-REVIEW-multi-model.md:160`.

## 5. Changes Integrated

713. Wholeheartedly agree count: 18.
714. Somewhat agree count: 8.
715. Disagree count: 6.

### Wholeheartedly Agree

716. Wholeheartedly agree 01: make verified mission-anchor closure the goal.
717. Tag: leverage point #3; stock verified mission closure; loop mission-value correction.
718. Citation: `01-REVIEW-donella.md:812-821`.
719. Wholeheartedly agree 02: name the scoring governor.
720. Tag: leverage point #3; stock scoring opacity; loop scoring-opacity.
721. Citation: `01-REVIEW-donella.md:859-873`.
722. Wholeheartedly agree 03: require mission-anchor evidence before work enters top rank.
723. Tag: leverage point #3; stock mission-licensed leverage; loop mission-value correction.
724. Citation: `01-REVIEW-donella.md:844-854`.
725. Wholeheartedly agree 04: keep callbacks during parity.
726. Tag: leverage point #5; stock callback/log divergence; loop migration-governor.
727. Citation: `01-REVIEW-jeff.md:936-943`.
728. Wholeheartedly agree 05: ship read-only manager-state first.
729. Tag: leverage point #6; stock shared operational state; loop missing feedback.
730. Citation: `01-REVIEW-jeff.md:907-910`.
731. Wholeheartedly agree 06: demote ops-log from primary authority.
732. Tag: leverage point #5; stock authority drift; loop validation-governor.
733. Citation: `01-REVIEW-jeff.md:353-438`.
734. Wholeheartedly agree 07: JSON canonical, Markdown projection.
735. Tag: leverage point #6; stock shared situational awareness; loop surface-trust.
736. Citation: `01-REVIEW-donella.md:441-453`.
737. Wholeheartedly agree 08: every row has per-row schema_version.
738. Tag: leverage point #5; stock schema-valid events; loop validation-governor.
739. Citation: `01-REVIEW-multi-model.md:398-400`.
740. Wholeheartedly agree 09: writers do not assert stock impact.
741. Tag: leverage point #5; stock validated mission stock; loop validation-governor.
742. Citation: `01-REVIEW-donella.md:830-839`.
743. Wholeheartedly agree 10: decision receipts are mandatory.
744. Tag: leverage point #8; stock unvalidated decisions; loop decision-debt balancing.
745. Citation: `01-REVIEW-jeff.md:911-915`.
746. Wholeheartedly agree 11: one decision group, not one uncategorized action.
747. Tag: leverage point #8; stock decision debt; loop decision-debt balancing.
748. Citation: `01-REVIEW-jeff.md:480-494`.
749. Wholeheartedly agree 12: 300-second decision cadence.
750. Tag: leverage point #9; stock decision debt; loop delay.
751. Citation: `01-REVIEW-multi-model.md:421-490`.
752. Wholeheartedly agree 13: render fewer than ten items when fewer qualify.
753. Tag: leverage point #3; stock mission-licensed leverage; loop perverse feedback.
754. Citation: `01-REVIEW-donella.md:70-86`.
755. Wholeheartedly agree 14: import manual callbacks.
756. Tag: leverage point #6; stock trusted operational state; loop callback visibility.
757. Citation: `01-REVIEW-multi-model.md:686-693`.
758. Wholeheartedly agree 15: skillos remains separate but integrated.
759. Tag: leverage point #5; stock layer-boundary integrity; loop scope creep.
760. Citation: `cross-orch-input/skillos-1-2026-05-05T1555Z.md:11-19`.
761. Wholeheartedly agree 16: expose score components and confidence.
762. Tag: leverage point #6; stock scoring opacity; loop scoring accountability.
763. Citation: `01-REVIEW-donella.md:376-390`.
764. Wholeheartedly agree 17: require doctor/health/repair from first manager primitive.
765. Tag: leverage point #5; stock operator repairability; loop maintenance feedback.
766. Citation: `01-REVIEW-jeff.md:933-935`.
767. Wholeheartedly agree 18: replay fixtures are acceptance gates.
768. Tag: leverage point #8; stock validated behavior; loop learning feedback.
769. Citation: `01-REVIEW-multi-model.md:696-704`.

### Somewhat Agree

770. Somewhat agree 01: keep the `ops-log` name.
771. Caveat: the name may remain, but authority is mirror/index only until parity.
772. Tag: leverage point #6; stock operational event history; loop source-of-truth.
773. Citation: `01-REVIEW-multi-model.md:181-195`.
774. Somewhat agree 02: default one decision per tick.
775. Caveat: one discretionary decision group; safety and receipt actions are exempt.
776. Tag: leverage point #8; stock decision debt; loop decision-debt balancing.
777. Citation: `01-REVIEW-donella.md:121-128`.
778. Somewhat agree 03: top-10 queue.
779. Caveat: JSON keeps all eligible candidates; Markdown renders top ten or fewer.
780. Tag: leverage point #6; stock actionable candidates; loop ranking feedback.
781. Citation: `01-REVIEW-jeff.md:617-626`.
782. Somewhat agree 04: use Donella/Jeff scoring modes.
783. Caveat: modes become documented scoring versions, not runtime model vibes.
784. Tag: leverage point #5; stock scoring opacity; loop scoring-governor.
785. Citation: `01-REVIEW-jeff.md:917-923`.
786. Somewhat agree 05: 600-second interval.
787. Caveat: 600s is human render cadence, not decision cadence.
788. Tag: leverage point #9; stock stale decisions; loop delay.
789. Citation: `00-PLAN-INPUT.md:100-103`.
790. Somewhat agree 06: worker writes to ops-log.
791. Caveat: worker writes are claims unless validated or imported from owner ledgers.
792. Tag: leverage point #5; stock trusted operational state; loop validation-governor.
793. Citation: `01-REVIEW-donella.md:133-141`.
794. Somewhat agree 07: M4 replaces morning ritual.
795. Caveat: it replaces morning ritual as separate primitive, not as human-readable projection.
796. Tag: leverage point #6; stock founder attention demand; loop surface-trust.
797. Citation: `00-PLAN-INPUT.md:125-138`.
798. Somewhat agree 08: CALLBACKS_DEAD end state.
799. Caveat: end state only after stronger receipts and rollback path.
800. Tag: leverage point #5; stock callback/log divergence; loop migration-governor.
801. Citation: `01-REVIEW-jeff.md:961-963`.

### Disagree

802. Disagree 01: ship ops-log as first primary authority.
803. Reason: owner ledgers already exist; primary authority would centralize corruption before repairability exists.
804. Tag: leverage point #5; stock authority drift; loop validation-governor.
805. Citation: `01-REVIEW-jeff.md:353-438`.
806. Disagree 02: kill xpane callbacks in M1.
807. Reason: callback delivery currently has stronger proof than new mirror rows.
808. Tag: leverage point #5; stock callback/log divergence; loop migration-governor.
809. Citation: `00-PLAN-INPUT.md:85`.
810. Citation: `01-REVIEW-donella.md:148-155`.
811. Disagree 03: allow writers to assert stock_delta as impact.
812. Reason: this recreates callback self-certification in JSON.
813. Tag: leverage point #5; stock validated mission stock; loop validation-governor.
814. Citation: `00-PLAN-INPUT.md:72-83`.
815. Citation: `01-REVIEW-donella.md:133-141`.
816. Disagree 04: fixed exactly ten top queue items.
817. Reason: ten non-mission items are worse than three mission-licensed items.
818. Tag: leverage point #3; stock mission-licensed leverage; loop perverse feedback.
819. Citation: `00-PLAN-INPUT.md:186-190`.
820. Citation: `01-REVIEW-donella.md:70-86`.
821. Disagree 05: Markdown and JSON as peer truth.
822. Reason: peer truth stores recreate validator split-brain.
823. Tag: leverage point #5; stock shared situational awareness; loop surface-trust.
824. Citation: `00-PLAN-INPUT.md:125-138`.
825. Citation: `01-REVIEW-jeff.md:630-665`.
826. Disagree 06: fold skillos thesis into manager-loop.
827. Reason: that instantiates mission compression and violates layer separation.
828. Tag: leverage point #5; stock layer-boundary integrity; loop scope creep.
829. Citation: `cross-orch-input/skillos-1-2026-05-05T1555Z.md:5-19`.

## 6. Open Questions Punted To Convergence Audit

830. Open questions for audit count: 7.
831. Audit question 01: JSONL shards or SQLite index after shadow mode?
832. Default before audit: JSONL mirror/index from owner ledgers.
833. Audit evidence needed: query latency and corruption/repair rate after replay.
834. Audit question 02: exact parity window N before callback cutover.
835. Default before audit: 24h or one complete overnight replay.
836. Audit evidence needed: callback/log divergence distribution.
837. Audit question 03: exact scoring weights for `manager-queue/v1`.
838. Default before audit: deterministic weights with visible components.
839. Audit evidence needed: rank vs validated mission closure.
840. Audit question 04: which upstream `bv` robot top-N contract is needed?
841. Default before audit: draft issue only; no patch.
842. Jeff citation: `01-REVIEW-jeff.md:1010-1017`.
843. Audit question 05: how broad should fleet-wide manager-state be in v1?
844. Default before audit: flywheel session plus one peer replay.
845. Audit evidence needed: source coverage and cross-session divergence.
846. Audit question 06: whether ops-log becomes authority after parity.
847. Default before audit: no; owner ledgers remain authority.
848. Audit evidence needed: repairability, validation backlog, and operator clarity.
849. Audit question 07: how skillos recommendations affect score.
850. Default before audit: skillos recommendation is a feature, not a gate.
851. Audit evidence needed: skill recommendation outcome quality.
852. Questions not punted: kill callbacks immediately.
853. Answer: no.
854. Questions not punted: make Markdown editable.
855. Answer: no.
856. Questions not punted: let worker claims count as closure.
857. Answer: no.
858. Questions not punted: ship tick apply mode before read-only state and scorer.
859. Answer: no.
860. Questions not punted: use external model fanout for integration.
861. Answer: no.

## 7. Verdict Thresholds And Measurement Loops

862. Verdict thresholds use Donella terms: stock, flow, loop, delay, rule, goal.
863. HEALTHY means the manager loop is reducing the right stocks.
864. DEGRADED means one stock is rising or one loop is delayed but repair path exists.
865. BROKEN means a control loop is absent, stale, contradictory, or optimizing the wrong goal.
866. Primary stock: verified mission-anchor closure.
867. Primary HEALTHY: mission-anchor closure trend positive over the active window.
868. Primary DEGRADED: mission-anchor closure flat for 4 decision ticks while dispatches continue.
869. Primary BROKEN: mission-anchor closure zero for 8 decision ticks while dispatches continue.
870. Secondary stock: decision debt.
871. HEALTHY: top unhandled decision age <= 2 decision intervals.
872. DEGRADED: top unhandled decision age > 2 intervals.
873. BROKEN: top unhandled decision age > 4 intervals or queue cannot explain no action.
874. Secondary stock: callback/log divergence.
875. HEALTHY: zero material divergence in parity window.
876. DEGRADED: divergence exists but import or validation path is active.
877. BROKEN: divergence blocks closure, cutover, or truth classification.
878. Secondary stock: validation backlog.
879. HEALTHY: worker claims validated or rejected within one interval.
880. DEGRADED: backlog exceeds one interval.
881. BROKEN: unvalidated claims affect closure or health stock.
882. Secondary stock: source freshness.
883. HEALTHY: all required sources fresh within two intervals.
884. DEGRADED: one source stale with fallback.
885. BROKEN: driver, dispatch-log, validation, or mission-license source stale without fallback.
886. Secondary stock: founder attention demand.
887. HEALTHY: zero routine human questions and only typed true-human blockers.
888. DEGRADED: routine question attempted but auto-routed before asking.
889. BROKEN: manager-state asks Joshua for a decision with no `why_not_agent`.
890. Secondary stock: scoring opacity.
891. HEALTHY: every selected item has score components and outcome feedback.
892. DEGRADED: score explanation missing for non-selected runner-up.
893. BROKEN: score formula changed without receipt or mission gate bypassed.
894. Secondary stock: surface trust.
895. HEALTHY: Markdown hash matches JSON and JSON schema validates.
896. DEGRADED: Markdown stale but JSON valid.
897. BROKEN: Markdown and JSON disagree materially.
898. Measurement loop A: callback overload.
899. Goal: pane callback traffic stops being the control input.
900. Signal: received callbacks per hour.
901. Actor: migration governor.
902. Response: import, mirror, reject, or cutover.
903. Target: <1 callback/hour after cutover while mission closure remains visible.
904. Measurement loop B: mission-value correction.
905. Goal: verified mission-anchor closure rises.
906. Signal: mission delta per decision tick.
907. Actor: scoring governor and tick driver.
908. Response: penalize non-mission work, dispatch mission-licensed unblockers, or explain substrate exception.
909. Target: positive mission delta over active window.
910. Measurement loop C: scoring accountability.
911. Goal: scoring mistakes teach the system.
912. Signal: rank vs outcome error.
913. Actor: scoring governor.
914. Response: validation receipt updates weights, tests, or upstream issue draft.
915. Target: high-score false positive rate falling.
916. Measurement loop D: driver proof.
917. Goal: tick is process, not document.
918. Signal: driver fire ledger and tick receipt freshness.
919. Actor: tick driver doctor.
920. Response: DEGRADED/BROKEN, repair lock, or stop apply mode.
921. Target: last fire fresher than two intervals.
922. Measurement loop E: migration safety.
923. Goal: callback cutover loses no truth.
924. Signal: material divergence.
925. Actor: migration governor.
926. Response: continue shadow mode, import missing callbacks, refuse cutover.
927. Target: zero material divergence for parity window.
928. Measurement loop F: source repairability.
929. Goal: manager primitive is inspectable and repairable.
930. Signal: doctor/health/repair/validate/audit/why coverage.
931. Actor: canonical CLI checks and operator.
932. Response: repair, regenerate, quarantine, or downgrade.
933. Target: every manager sub-surface has JSON, schema, why, and dry-run repair where mutating.
934. Final verdict: revise, integrated.
935. Final composite: 9.67.
936. Planning-workflow conformance: 9.8.
937. Donella authenticity: 9.7.
938. Jeff substrate compatibility: 9.7.
939. Joshua taste: 9.7.
940. Publishability after redaction: 9.45.
941. Ship first primitive: A0-manager-state-read-model.
942. Final deprecations: fleet-autonomy P3 independent controller, fleet-autonomy M primary measurement, callback-as-orchestrator-input.
943. Final preserved primitives: `bv` selection, retry-after-state-change, status schema fields, driver proof, dispatch delivery receipt, Agent Mail reservation safety, ntm pane actuation boundary, mission-anchor licensing.
944. L112 expected string: OK_manager_loop_integrate.
