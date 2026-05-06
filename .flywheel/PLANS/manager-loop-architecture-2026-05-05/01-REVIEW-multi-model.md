# 01-REVIEW-multi-model - Manager Loop Architecture

## 0. Execution Note

001. Task: review `00-PLAN-INPUT - Manager-Loop Architecture for Orchestrators`.
002. Required lens: `/planning-workflow` exact-prompt, run at GPT-5.5 Pro parity.
003. External model execution: not used.
004. Reason: Joshua explicitly corrected that this pane is GPT-5.5 and should not call other models.
005. Triangulation method: internal lens matrix, not external CLI fanout.
006. Lenses used: planning-workflow, Donella systems critique, Jeff-compatible substrate critique, Joshua-taste critique.
007. Skills consulted: `planning-workflow`.
008. Skills consulted: `multi-model-triangulation`.
009. Skills consulted: `accretive-cron-orchestration`.
010. Skills consulted: `canonical-cli-scoping`.
011. Skills consulted: `dispatch-tool-contracts`.
012. Skill lookup also surfaced: `log-aggregation`.
013. Skill lookup also surfaced: `loop-enforcement`.
014. Skill lookup also surfaced: `state-management`.
015. Skill lookup also surfaced: `canonical-owner-runtime-state`.
016. Socraticode status: green.
017. Indexed chunks observed: 694.
018. Socraticode query count for this review: 4.
019. Relevant Socraticode hit: `INCIDENTS.md:271-370`, orchestrator observability contract bypass.
020. Relevant Socraticode hit: `INCIDENTS.md:361-460`, decision on partial state.
021. Relevant Socraticode hit: `tests/flywheel-tick-driver.sh:78-159`, tick driver ledger and lock.
022. Relevant Socraticode hit: `tests/jsonl-orphan-migrations-test.sh:178-242`, append failure behavior.
023. Relevant Socraticode hit: `tests/mission-anchor-dispatch-license-test.sh:59-132`, mission anchor dispatch license.
024. Relevant Socraticode hit: `AGENTS.md:2161-2260`, four-state dispatch delivery receipt.
025. Prior review reference: `fleet-autonomy-v1-2026-05-05/01-REVIEW-multi-model.md:8-23`.
026. Prior review reference: `fleet-autonomy-v1-2026-05-05/01-REVIEW-multi-model.md:176-220`.
027. Prior review reference: `fleet-autonomy-v1-2026-05-05/01-REVIEW-multi-model.md:541-552`.
028. Prior review reference: `fleet-autonomy-v1-2026-05-05/01-REVIEW-donella.md:240-276`.
029. Prior review reference: `fleet-autonomy-v1-2026-05-05/01-REVIEW-donella.md:484-515`.
030. Prior review reference: `fleet-autonomy-v1-2026-05-05/01-REVIEW-jeff.md:348-415`.
031. Prior review reference: `fleet-autonomy-v1-2026-05-05/01-REVIEW-jeff.md:1069-1074`.
032. Cross-orch reference: `cross-orch-input/skillos-1-2026-05-05T1525Z.md:37-55`.
033. Cross-orch reference: `cross-orch-input/mobile-eats-1-2026-05-05T1545Z.md:13-31`.
034. Review stance: plan-space only.
035. Source edits made: none.
036. Output artifact only: this review file.
037. Primary question: does the manager loop supersede the fleet-autonomy primitive set?
038. Secondary question: can it be shipped without recreating the same hidden orchestrator bottleneck?
039. Tertiary question: does the plan define enough schema for machine control?
040. Summary answer: yes, with revisions.

## 1. Executive Verdict

041. Verdict: revise.
042. Do not reject.
043. Do not ship as written.
044. Keep the paradigm shift.
045. Revise the migration path.
046. Revise the ops-log schema.
047. Revise tick cadence.
048. Revise the "no other channel" wording.
049. Revise top-10 selection from delta-only to state-plus-delta.
050. Revise "one decision per tick" to exclude safety receipts and mechanical repairs.
051. Composite score after required revisions: 9.62 / 10.
052. Planning-workflow conformance score: 9.8 / 10.
053. Paradigm-soundness score: 9.7 / 10.
054. Joshua-taste score: 9.7 / 10.
055. Public-publishability score after redaction: 9.3 / 10.
056. Composite calculation: average = 9.625, rounded to 9.62.
057. Why not keep unchanged: M1 can lose concurrent JSONL writes if implemented as replace-per-row append.
058. Why not keep unchanged: M2 at 600s can make the control loop too slow.
059. Why not keep unchanged: M3 lacks mission-anchor licensing.
060. Why not keep unchanged: M4 can become another prose mirror unless generated from schema.
061. Why not reject: the central diagnosis is better than the prior fleet-autonomy frame.
062. Why not reject: callbacks as orchestrator input are the actual bottleneck named in the evidence.
063. Why not reject: the ops-log plus tick-loop frame matches current doctrine better than morning-report-first.
064. Why not reject: cross-orch evidence strengthens the plan.
065. Strongest sentence in the plan: orchestrator is no longer a recipient.
066. Most dangerous sentence in the plan: no other channel for orchestrator-visible signals.
067. Corrected sentence: ops-log is the canonical machine-control channel.
068. Corrected sentence: pane callbacks remain a compatibility and human-observation channel during migration.
069. Corrected sentence: callback-derived facts must be mirrored into ops-log before they affect manager decisions.
070. Corrected MVP: dual-write ops-log, read-only queue, manager-state renderer, then tick-mode cutover.
071. Recommended tick interval: 300 seconds for decision ticks.
072. Recommended ingest interval: 60 seconds for event freshness and health updates.
073. Recommended human-render interval: 600 seconds or on demand.
074. Recommended safety path: immediate event-driven handling for critical transport and storage violations.
075. The plan moves leverage from delayed information flow to an active control loop.
076. The plan is closest to Meadows #6 and #5 today.
077. It can become Meadows #3 if mission-anchor delta is in the machine schema.
078. It can touch Meadows #2 only if the fleet stops measuring agent motion as progress.
079. The plan should not claim paradigm change until callbacks/hour drops and mission delta rises.
080. Composite verdict: revise, then ship.

## 2. Plan-vs-Prior-Plan Reconciliation

081. The prior multi-model review said revise, with P1+P2 selector contract first.
082. It scored the prior fleet plan at 9.18 after revisions.
083. It said P1 is not a one-line fix.
084. It said P2 depends on a missing exclusion contract.
085. It said full P3 should not block selector stop-bleed.
086. It said full P3 is the strongest goal-facing primitive.
087. It said the morning artifact is useful but not the measurement unit.
088. The manager-loop plan accepts the deeper part of that critique.
089. It replaces "status command as central primitive" with "manager-state as controller output."
090. That is a stronger architecture.
091. But it must still preserve the selector stop-bleed.
092. Fleet P1 remains intact as an input-side stop-bleed.
093. Fleet P1 is not obsolete.
094. Fleet P1 should become a queue input to M3.
095. Fleet P1 should also write `selection_candidate` and `selection_suppressed` ops-log rows.
096. Fleet P1 should still prefer `bv --robot-next` over `br ready`.
097. Fleet P1 should still fail closed if `bv` is healthy but unusable.
098. Fleet P1 should still preserve `bv` score, reason, and data hash.
099. Fleet P2 remains intact as retry-state discipline.
100. Fleet P2 should fold into writer-side event rules.
101. Fleet P2 should not live only inside watcher cooldown.
102. Fleet P2 becomes an ops-log eligibility rule.
103. Fleet P2 row: `redispatch_without_state_delta`.
104. Fleet P2 row: `selection_suppressed`.
105. Fleet P2 row: `retry_after_state_change_required`.
106. Fleet P3 is partly obsoleted.
107. The standalone status primitive is no longer the controller.
108. The status schema is still necessary.
109. Fleet P3 becomes a read model under M4.
110. Fleet P3's strongest fields survive.
111. Surviving P3 fields include closure conversion.
112. Surviving P3 fields include overdue callbacks.
113. Surviving P3 fields include duplicate dispatches.
114. Surviving P3 fields include driver status.
115. Surviving P3 fields include stale pane signals.
116. Surviving P3 fields include reservation health.
117. Surviving P3 fields must add mission-anchor delta.
118. Fleet P4 remains intact as a measured repair class.
119. Fleet P4 is not an MVP mutation.
120. Fleet P4 should not be a watcher-side force-release.
121. Fleet P4 becomes `reservation_stale_candidate` in ops-log.
122. Fleet P4 repair must delegate to Agent Mail.
123. Fleet P4 repair must be dry-run by default.
124. Fleet P5 remains intact as a measured recovery class.
125. Fleet P5 is not an MVP mutation.
126. Fleet P5 becomes `pane_freeze_candidate` and `pane_recovery_receipt`.
127. Fleet P5 repair must route through ntm and the permit gate.
128. Fleet P6 remains intact as an attention class.
129. Fleet P6 is not an independent priority system.
130. Fleet P6 becomes `repair_bead_aging` as a queue signal.
131. Fleet P6 should feed `bv` or a stable graph signal.
132. Fleet M is obsoleted as a separate primitive.
133. Morning report becomes a renderer over manager-state.
134. Morning report should never be the first controller.
135. Morning report still has human value.
136. Morning report must cite the source manager-state hash.
137. Obsoleted primitive: callback-as-orchestrator-input.
138. Obsoleted primitive: morning artifact as primary measurement unit.
139. Obsoleted primitive: standalone status brain separate from manager-state.
140. Preserved primitive: `bv`-based selection.
141. Preserved primitive: retry-after-state-change.
142. Preserved primitive: status schema.
143. Preserved primitive: driver proof.
144. Preserved primitive: dispatch delivery receipt.
145. Preserved primitive: Agent Mail reservation safety.
146. Preserved primitive: ntm pane actuation boundary.
147. Preserved primitive: mission-anchor licensing.
148. Prior Donella review said P3 is information flow until a controller consumes it.
149. Manager-loop answers that by naming the controller.
150. Prior Donella review said morning report is accountability, not autonomy.
151. Manager-loop answers that by moving action into the tick.
152. Prior Donella review said mission anchors must enter schema.
153. Manager-loop does not yet answer that.
154. Prior Jeff review said P3 should not be prose as primary output.
155. Manager-loop can answer that if M4 is generated from JSON.
156. Prior Jeff review said P4/P5/P6 should be parked until status proves bottleneck.
157. Manager-loop should keep that discipline.
158. Prior Jeff review said first cut is P1/P3/M.
159. Manager-loop should reinterpret that as M1/M3/M4 with P1 stop-bleed included.
160. Reconciliation verdict: manager-loop supersedes the control-plane shape, not every fleet primitive.

## 3. Architecture Critique

161. The architecture is directionally sound.
162. Ops-log plus tick-loop is the right missing substrate.
163. It converts callbacks from conversational interruption into data.
164. It gives Joshua and the orchestrator one shared surface.
165. It reduces context-window contention.
166. It gives validators a stable target.
167. It lets worker panes finish without needing orchestrator attention per callback.
168. It makes top-10 leverage explicit.
169. It enables historical measurement.
170. It creates a path to offline replay.
171. The architecture breaks if ops-log becomes a global hot file with unsafe append semantics.
172. The architecture breaks if every writer writes by its own ad hoc JSON shape.
173. The architecture breaks if manager-loop reads only deltas.
174. The architecture breaks if top-10 is computed from stale delta without current substrate truth.
175. The architecture breaks if callbacks are killed before parity is proven.
176. The architecture breaks if 600s decision ticks are the only response path.
177. The architecture breaks if one-decision-per-tick delays safety repairs.
178. The architecture breaks if M4 is hand-written prose.
179. The architecture breaks if mission anchors remain a human-only field.
180. The architecture breaks if `details` becomes a garbage bag.
181. The plan says workers append to `ops-log.jsonl`.
182. Good.
183. The plan says watchers append.
184. Good.
185. The plan says validators append.
186. Good.
187. The plan says doctor appends.
188. Good, but only if doctor rows are clearly distinguished from facts.
189. Doctor rows should be observations.
190. Worker rows should be claims.
191. Validator rows should be verdicts.
192. Integrator rows should be accepted state transitions.
193. Manager rows should be decisions.
194. Repair rows should be mutations.
195. The schema must encode those role differences.
196. Without role separation, all rows look equally authoritative.
197. That recreates the callback problem in JSONL form.
198. The plan says orchestrator no longer receives callbacks.
199. That is the right end state.
200. The plan should not make it M1.
201. The plan should make it M2.5 or M5 after parity.
202. Compatibility callbacks should continue while row parity is measured.
203. The compatibility channel should be ignored by manager decisions once mirrored.
204. The manager should never need pane scrollback for ordinary state.
205. Pane scrollback should remain a diagnostic channel.
206. Agent Mail should remain a coordination channel.
207. Beads should remain issue state.
208. `bv` should remain graph priority.
209. Ops-log should become event ingestion and manager memory.
210. Manager-state should become the rendered control surface.
211. The plan says top-10 queue blends Donella and Jeff weights.
212. Good as a planning note.
213. Dangerous as a runtime phrase.
214. Runtime scoring should be deterministic and versioned.
215. Multi-lens scoring can inform the weights.
216. The queue should expose its scoring version.
217. The queue should expose each feature contribution.
218. The queue should expose why an item is ineligible.
219. The queue should expose why a lower-ranked item was selected.
220. The tick loop should write `manager_decision/v1`.
221. The tick loop should write `manager_noop/v1`.
222. The tick loop should write `manager_deferred/v1`.
223. The tick loop should write `manager_safety_action/v1`.
224. The tick loop should never hide a degraded condition behind no-op.
225. The architecture should prefer shard-plus-aggregate over single global append.
226. Per-session shards reduce contention.
227. Per-session shards make replay easier.
228. Per-session shards make bad writer quarantine easier.
229. A global aggregate can be generated or indexed.
230. A global file can still exist as a view.
231. If single global file is chosen, a lock is mandatory.
232. Append must use the existing validated JSONL append posture.
233. `os.replace` per row is wrong for concurrent append unless wrapped in a full read-lock-write transaction.
234. The repo already has append helper tests.
235. The plan should reuse that pattern.
236. The tick loop should hold a lock.
237. Tick overlap must be impossible.
238. The tick driver test already asserts lock skip.
239. Use that as the reference pattern.
240. Architecture verdict: sound core, underspecified substrate.

## 4. Schema Audit

241. Current proposed fields: `ts`.
242. Keep `ts`.
243. Add `observed_at`.
244. Add `ingested_at`.
245. Current proposed field: `writer`.
246. Keep but split it.
247. Add `writer_id`.
248. Add `writer_role`.
249. Add `source_session`.
250. Add `source_repo`.
251. Add `source_pane`.
252. Current proposed field: `event`.
253. Keep but rename to `event_type`.
254. Add `schema_version`.
255. Add `event_id`.
256. Add `idempotency_key`.
257. Add `sequence`.
258. Add `parent_event_id`.
259. Add `correlation_id`.
260. Add `run_id`.
261. Add `tick_id`.
262. Current proposed field: `task_id`.
263. Keep.
264. Add `dispatch_id`.
265. Add `callback_id`.
266. Current proposed field: `bead_id`.
267. Keep.
268. Add `bead_ids`.
269. Add `linked_request_ids`.
270. Add `mission_anchor_id`.
271. Add `mission_anchor_evidence_path`.
272. Current proposed field: `stock_delta`.
273. Keep but make it typed.
274. `stock_delta` should be an object, not prose.
275. `stock_delta.stock` should be enum.
276. `stock_delta.direction` should be enum.
277. `stock_delta.amount` should be numeric or null.
278. `stock_delta.unit` should be enum.
279. `stock_delta.confidence` should be enum.
280. Current proposed field: `evidence_path`.
281. Keep.
282. Add `evidence_type`.
283. Add `evidence_hash`.
284. Add `evidence_summary`.
285. Add `redaction_status`.
286. Current proposed field: `trauma_class`.
287. Keep.
288. Add `severity`.
289. Add `status`.
290. Add `verdict`.
291. Add `blocker_class`.
292. Add `blocker_owner`.
293. Add `work_blocked`.
294. Add `safe_local_work_remaining`.
295. Current proposed field: `details`.
296. Keep only as bounded object or string.
297. The 200-character cap is good for inline details.
298. Add `details_ref` for larger artifacts.
299. Add `source_contract`.
300. Add `consumer_contract`.
301. Add `valid_until`.
302. Add `expires_at`.
303. Add `lease_id` for reservation events.
304. Add `files_reserved`.
305. Add `files_released`.
306. Add `delivery_receipt`.
307. Add `transport_accepted`.
308. Add `prompt_visible_in_target`.
309. Add `prompt_submitted`.
310. Add `work_started`.
311. Add `callback_received`.
312. Add `callback_validated`.
313. Add `validator_name`.
314. Add `validator_version`.
315. Add `validation_receipt_path`.
316. Add `action_allowed`.
317. Add `action_taken`.
318. Add `dry_run`.
319. Add `apply`.
320. Add `reversible`.
321. Add `rollback_ref`.
322. Add `manager_read_offset`.
323. Add `manager_decision_id`.
324. Add `queue_item_id`.
325. Add `queue_rank`.
326. Add `leverage_score`.
327. Add `score_features`.
328. Add `ineligibility_reason`.
329. Add `staleness_seconds`.
330. Add `dedupe_key`.
331. Add `fingerprint`.
332. Add `previous_fingerprint`.
333. Add `state_hash`.
334. Add `previous_state_hash`.
335. Add `schema_valid`.
336. Add `parse_error_ref` for malformed rows.
337. Minimum viable schema row:
338. `schema_version`.
339. `event_id`.
340. `ts`.
341. `observed_at`.
342. `ingested_at`.
343. `writer_id`.
344. `writer_role`.
345. `source_session`.
346. `source_repo`.
347. `event_type`.
348. `status`.
349. `severity`.
350. `task_id`.
351. `bead_id`.
352. `mission_anchor_id`.
353. `mission_anchor_evidence_path`.
354. `stock_delta`.
355. `evidence_type`.
356. `evidence_path`.
357. `evidence_hash`.
358. `correlation_id`.
359. `idempotency_key`.
360. `parent_event_id`.
361. `details`.
362. `details_ref`.
363. `redaction_status`.
364. Minimum viable event types:
365. `worker_claim`.
366. `callback_received`.
367. `callback_validated`.
368. `dispatch_sent`.
369. `delivery_receipt`.
370. `selection_candidate`.
371. `selection_suppressed`.
372. `reservation_conflict`.
373. `reservation_released`.
374. `pane_freeze_candidate`.
375. `pane_recovery_receipt`.
376. `doctor_observation`.
377. `validator_verdict`.
378. `manager_queue_rendered`.
379. `manager_decision`.
380. `manager_noop`.
381. `manager_state_rendered`.
382. `joshua_request_captured`.
383. `fuckup_logged`.
384. Missing field class: authority.
385. A row must say whether it is claim, observation, verdict, or decision.
386. Missing field class: provenance.
387. A row must say where the fact came from.
388. Missing field class: causality.
389. A row must link to parent event and correlation id.
390. Missing field class: mission.
391. A row must map to mission anchor or explicitly say why it cannot.
392. Missing field class: validation.
393. A row must distinguish unvalidated worker claims from accepted state.
394. Missing field class: idempotency.
395. Replayed rows must not double-count.
396. Missing field class: redaction.
397. Secret-bearing context must never become ops-log details.
398. Overspecified item: schema-version first row.
399. Better: every row has `schema_version`.
400. Better: file header can also exist, but consumers cannot require it.
401. Overspecified item: `os.replace` per row.
402. Better: validated append with lock or shard writer.
403. Overspecified item: `details <= 200` for all information.
404. Better: inline details <=200 plus `details_ref`.
405. Overspecified item: stock delta as impact assertion only.
406. Better: allow typed stock deltas with confidence.
407. Schema verdict: promising but not shippable as written.
408. Minimum viable acceptance: schema validator rejects unknown authority rows.
409. Minimum viable acceptance: malformed row does not crash manager tick.
410. Minimum viable acceptance: unknown event type degrades, does not disappear.
411. Minimum viable acceptance: worker claim cannot become manager fact without validation.
412. Minimum viable acceptance: every queue item traces to evidence.
413. Minimum viable acceptance: every decision writes a replayable row.
414. Minimum viable acceptance: every human question has `why_not_agent`.
415. Minimum viable acceptance: every mission-bearing row has an anchor.
416. Minimum viable acceptance: every non-mission row has a no-anchor reason.
417. Minimum viable acceptance: every manager-state render names source offsets.
418. Minimum viable acceptance: every row is valid JSON object.
419. Minimum viable acceptance: JSONL append failure is visible and non-fatal where appropriate.
420. Schema verdict: revise before any writer ships.

## 5. Tick Interval Analysis

421. Plan default: 600 seconds.
422. Plan bounds: 60 to 1800 seconds.
423. Recommended default decision tick: 300 seconds.
424. Recommended ingest tick: 60 seconds.
425. Recommended human-render tick: 600 seconds.
426. Recommended urgent path: event-driven, not interval-bound.
427. The plan evidence says 60+ callbacks arrived overnight.
428. A 600s decision loop can make only 6 discretionary decisions per hour.
429. In an eight-hour night, that is 48 decisions.
430. That may sound sufficient.
431. It is insufficient when one decision can be a no-op or safety diagnosis.
432. It is insufficient when top-10 contains multiple independent high-leverage repairs.
433. It is insufficient when a dispatch needs early validation within minutes.
434. It is insufficient when pane delivery receipt fails immediately.
435. It is insufficient when storage/headroom warning is yellow but safe local work remains.
436. It is insufficient when a reservation collision blocks multiple workers.
437. It is insufficient when Joshua requests are captured mid-cycle.
438. 600s also recreates morning-report delay at a smaller scale.
439. 600s is acceptable for human render.
440. 600s is too slow for manager decision.
441. 60s is acceptable for ingest and freshness.
442. 60s is too fast for discretionary strategic decisions if each tick can dispatch new work.
443. 60s risks thrash.
444. 60s risks context churn.
445. 60s risks repeated selection before evidence returns.
446. 300s is the better default.
447. 300s gives 12 decision opportunities per hour.
448. 300s aligns with prior status-history five-minute posture.
449. 300s gives enough time for workers to start, validate, or fail delivery.
450. 300s gives the manager room to coalesce duplicate events.
451. 300s is short enough to catch bad loops before a night is lost.
452. 300s should be adjustable by load.
453. Lower bound remains 60s.
454. Upper bound remains 1800s for paused or low-load sessions.
455. The tick should be adaptive.
456. If queue has safety-critical events, act now.
457. If queue has only low-priority hygiene, wait up to 600 or 1800.
458. If callbacks/hour exceeds threshold, shorten ingest and decision ticks.
459. If duplicate events dominate, lengthen decision tick but run coalescer.
460. If top queue stale age exceeds 2 ticks, force a manager decision.
461. If no mission delta for 4 ticks while dispatches continue, mark DEGRADED.
462. If no mission delta for 8 ticks while dispatches continue, mark BROKEN.
463. If a delivery receipt is false or unknown, do not wait 300 seconds.
464. If a pane is frozen, do not wait for a discretionary tick to log it.
465. If a reservation expires, status can surface it before repair applies.
466. If storage is yellow, route safe non-growth work rather than halt.
467. Tick loop should not be a scheduler-only loop.
468. Tick loop should be a controller.
469. Controller loops need sensing delay, decision delay, actuation delay, and validation delay.
470. The plan names decision delay only.
471. Add `ingest_latency_seconds`.
472. Add `queue_refresh_latency_seconds`.
473. Add `decision_latency_seconds`.
474. Add `actuation_latency_seconds`.
475. Add `validation_latency_seconds`.
476. Add `render_latency_seconds`.
477. Tick success metric should include P95 write-to-visible under 5s.
478. Tick success metric should include P95 event-to-queue under 60s.
479. Tick success metric should include P95 queue-to-decision under 300s for P0/P1.
480. Tick success metric should include no stale top-10 older than 2 decision ticks.
481. Tick success metric should include no safety event delayed by discretionary tick.
482. Tick interval verdict: revise default from 600 to 300.
483. Tick interval verdict: keep 600 for human render.
484. Tick interval verdict: add 60s ingest.
485. Tick interval verdict: add immediate safety path.
486. Tick interval verdict: keep 60 to 1800 bounds.
487. Tick interval verdict: add adaptive policy.
488. Tick interval verdict: never count interval as autonomy proof.
489. Tick interval recommendation for callback: 300 seconds.
490. Tick interval self-score: 9.7 / 10.

## 6. Migration Risk Register

491. Migration risk 01: M1 ops-log ships without consumers.
492. Impact: rows accumulate but no behavior changes.
493. Mitigation: ship read-only M3 queue immediately after M1.
494. Reversibility: disable writers, leave callbacks as source.
495. Migration risk 02: M1 schema churn breaks early consumers.
496. Impact: validator drift and split-brain.
497. Mitigation: version every row and ship schema validator first.
498. Reversibility: freeze accepted schema at `ops-log/event/v1`.
499. Migration risk 03: M1 concurrent append loses rows.
500. Impact: manager decisions on partial state.
501. Mitigation: per-session shards or locked validated append.
502. Reversibility: replay compatibility callbacks into log after fix.
503. Migration risk 04: M1 global file becomes a contention hotspot.
504. Impact: writer failures and delayed visibility.
505. Mitigation: shard by session plus aggregate read model.
506. Reversibility: rebuild aggregate from shards.
507. Migration risk 05: M1 details leaks secrets.
508. Impact: transcript/state secret exposure.
509. Mitigation: redaction contract and `details_ref` with scrubbed artifacts.
510. Reversibility: rotate only if confirmed leak; otherwise scrub log view.
511. Migration risk 06: M1 worker claims counted as facts.
512. Impact: false completion and hidden failure.
513. Mitigation: authority field and validation gating.
514. Reversibility: reclassify old rows as unvalidated claims.
515. Migration risk 07: M2 ships before M3.
516. Impact: tick makes decisions without leverage queue.
517. Mitigation: do not ship M2 before read-only M3.
518. Reversibility: stop driver plist and revert to manual orchestrator decisions.
519. Migration risk 08: M2 one-decision rule blocks urgent repairs.
520. Impact: safety events wait behind discretionary work.
521. Mitigation: separate safety lane from discretionary lane.
522. Reversibility: set manager mode to observe-only.
523. Migration risk 09: M2 600s cadence is too slow.
524. Impact: bad loops persist for hours.
525. Mitigation: use 300s decision, 60s ingest, urgent event path.
526. Reversibility: change config; no source rollback needed.
527. Migration risk 10: M3 top-10 ranks non-mission work.
528. Impact: mobile-eats failure repeats.
529. Mitigation: mission-anchor license required for queue eligibility.
530. Reversibility: mark queue version deprecated and recompute.
531. Migration risk 11: M3 creates a second priority brain beside `bv`.
532. Impact: selectors disagree.
533. Mitigation: M3 consumes `bv` outputs and adds cross-substrate blockers.
534. Reversibility: switch queue weights to `bv`-only until resolved.
535. Migration risk 12: M3 ranks stale delta instead of current state.
536. Impact: stale work selected.
537. Mitigation: compute from snapshot plus delta.
538. Reversibility: recompute queue from source ledgers.
539. Migration risk 13: M4 manager-state becomes another hand-authored report.
540. Impact: prose drift and split-brain.
541. Mitigation: render from JSON only and cite source offsets.
542. Reversibility: delete renderer output; keep JSON state.
543. Migration risk 14: M4 pending human decisions become a dumping ground.
544. Impact: Joshua gets reinserted as scheduler.
545. Mitigation: every human question requires `why_not_agent`.
546. Reversibility: auto-close invalid human questions with no-bead reason.
547. Migration risk 15: callbacks are killed too early.
548. Impact: missed worker evidence during migration.
549. Mitigation: dual-write until parity and callback-grade coverage pass.
550. Reversibility: re-enable compatibility callback parsing.
551. Migration risk 16: manual callbacks remain invisible.
552. Impact: skillos callback-grade gap persists.
553. Mitigation: import manual callbacks by task id into ops-log.
554. Reversibility: backfill from pane/capture artifacts.
555. Migration risk 17: validator split-brain persists.
556. Impact: SAFE_TO_CLOSE and BLOCK_CLOSE disagree.
557. Mitigation: validators write verdict rows with authority and version.
558. Reversibility: manager ignores untrusted validator versions.
559. Migration risk 18: manager loop hides behind active markers.
560. Impact: L57 repeats.
561. Mitigation: driver proof and `manager_tick_last_fire_ts` in state.
562. Reversibility: mark manager loop marker-only and stop claiming active.
563. M1 without M2: useful only if dual-written and validated.
564. M1 without M3: telemetry, not autonomy.
565. M1 without M4: machine-only, poor human usability.
566. M1 without callbacks: unsafe.
567. M2 without M1: reject.
568. M2 without M3: reject.
569. M2 without M4: possible for headless test only.
570. M3 without M2: strongly recommended.
571. M4 without M3: weak, likely prose report.
572. M4 without M1: should render existing status only, not manager-state.
573. Ship order should be M0, M1, M3, M4, M2, then callback cutover.
574. M0 is missing from the plan.
575. M0 should be compatibility and schema gates.
576. M0 includes schema validator.
577. M0 includes append helper choice.
578. M0 includes dual-write policy.
579. M0 includes parity metrics.
580. Migration verdict: reversible if cut into gates; risky if shipped as a monolith.

## 7. Specific Revisions

581. Revision 01 title: add M0 migration guardrail.
582. Before: `M1 -> M2 -> M3 -> M4` begins with ops-log and no explicit compatibility gate.
583. After: `M0 -> M1 -> M3 -> M4 -> M2 -> callback cutover`.
584. Diff:
585. `+ M0: schema validator, append helper, dual-write policy, callback parity, rollback switch.`
586. `+ M0 acceptance: manager ignores ops-log until validator passes 24h or one manual replay.`
587. `+ M0 acceptance: no worker loses callback path during migration.`
588. Why: plan-space cost is cheap; callback loss in code-space is expensive.
589. Revision 02 title: replace global replace-per-row append.
590. Before: `atomic-write temp+fsync+os.replace per row`.
591. After: `validated append with lock, or per-session shard plus aggregate view`.
592. Diff:
593. `- Writer appends by temp file and os.replace per row.`
594. `+ Writer calls ops-log-append with flock, jq validation, fsync, and rejected-row capture.`
595. `+ Alternative: writer appends to ops-log/<source_session>.jsonl, manager aggregates by offset.`
596. Why: replace-per-row on an append log risks lost writes under concurrency.
597. Revision 03 title: give every row authority.
598. Before: rows contain `writer` and `event`.
599. After: rows contain `writer_role`, `event_type`, `authority`, and `validation_state`.
600. Diff:
601. `+ authority: claim | observation | verdict | decision | mutation`
602. `+ validation_state: unvalidated | validated | rejected | superseded`
603. `+ validator_name`
604. `+ validation_receipt_path`
605. Why: worker claims are not manager facts.
606. Revision 04 title: add mission-anchor licensing.
607. Before: top-10 queue uses graph and operational blockers.
608. After: top-10 eligibility requires mission anchor or explicit substrate-exception reason.
609. Diff:
610. `+ mission_anchor_id`
611. `+ mission_anchor_evidence_path`
612. `+ no_mission_anchor_reason`
613. `+ mission_delta_expected`
614. Why: mobile-eats proved beads can look ready while mission coverage is false.
615. Revision 05 title: split cadence into ingest, decision, and render.
616. Before: one loop sleeps N, default 600s.
617. After: ingest 60s, decision 300s, render 600s, urgent path immediate.
618. Diff:
619. `- sleep default 600s`
620. `+ ingest_interval_seconds=60`
621. `+ decision_interval_seconds=300`
622. `+ render_interval_seconds=600`
623. `+ urgent_event_path=immediate`
624. Why: 600s is suitable for human summaries, not active control.
625. Revision 06 title: scope the one-decision rule.
626. Before: one decision per tick.
627. After: one discretionary work decision per tick, safety and receipts are not capped.
628. Diff:
629. `- Exactly one decision per tick.`
630. `+ Exactly one discretionary work-dispatch decision per decision tick.`
631. `+ Safety actions, validation receipts, imports, and state renders may run within budget.`
632. Why: a single safety event must not wait behind a strategic dispatch.
633. Revision 07 title: compute top-10 from snapshot plus delta.
634. Before: read delta since last tick.
635. After: read delta, refresh current state, then rank.
636. Diff:
637. `+ queue_inputs.delta_rows_since_offset`
638. `+ queue_inputs.current_bead_graph`
639. `+ queue_inputs.current_dispatch_state`
640. `+ queue_inputs.current_reservations`
641. `+ queue_inputs.current_driver_health`
642. `+ queue_inputs.current_mission_coverage`
643. Why: delta-only managers make stale decisions.
644. Revision 08 title: version deterministic queue scoring.
645. Before: Donella vs Jeff weights and multi-model blend.
646. After: deterministic scoring version with feature contributions.
647. Diff:
648. `+ scoring_version: manager-queue/v1`
649. `+ features: {mission_delta, unblock_count, stale_callback_risk, safety_severity, evidence_freshness}`
650. `+ feature_weights_hash`
651. `+ ineligibility_reason`
652. Why: runtime cannot depend on vague model-blend language.
653. Revision 09 title: render M4 only from JSON state.
654. Before: `manager-loop-state.md` plus `.json`.
655. After: JSON source of truth, Markdown derived.
656. Diff:
657. `+ manager-loop-state.json is canonical.`
658. `+ manager-loop-state.md includes source_json_hash and generated_at.`
659. `+ manual edits to manager-loop-state.md are invalid.`
660. Why: report drift is the old failure mode.
661. Revision 10 title: import manual callbacks.
662. Before: ops-log writers cover automated workers.
663. After: callback import handles pane/manual/user callbacks by task id.
664. Diff:
665. `+ ops-log import-callback --task-id <id> --evidence <path>`
666. `+ callback_imported event_type`
667. `+ row_found=false becomes DEGRADED until imported or explicitly waived.`
668. Why: skillos reproduced manual callback invisibility.
669. Revision 11 title: make human questions scarce and typed.
670. Before: pending Joshua decisions section exists.
671. After: each item requires agent-exhaustion fields.
672. Diff:
673. `+ human_question`
674. `+ why_not_agent`
675. `+ probe_ledger_ref`
676. `+ safe_local_work_remaining`
677. `+ decision_deadline`
678. Why: manager-state must not become a queue of avoidable asks.
679. Revision 12 title: add parity gates before killing callbacks.
680. Before: M1 kills xpane callbacks as orchestrator input.
681. After: callbacks remain until ops-log parity passes.
682. Diff:
683. `+ callback_parity.window_hours=24`
684. `+ callback_parity.required_match_rate>=0.98`
685. `+ callback_parity.manual_callback_import_coverage=true`
686. `+ callback_parity.cutover_requires_manager_state_green=true`
687. Why: migration should be boring and reversible.
688. Revision 13 title: add ops-log doctor and repair.
689. Before: scope includes doctor/health/repair after migration.
690. After: schema and writer doctor ship before broad adoption.
691. Diff:
692. `+ flywheel-loop ops-log doctor --json`
693. `+ flywheel-loop ops-log validate --since <window> --json`
694. `+ flywheel-loop ops-log repair --dry-run --json`
695. Why: canonical CLI scoping requires health and repair for operator state.
696. Revision 14 title: add replay test as acceptance.
697. Before: success criteria focus on runtime metrics.
698. After: manager tick must replay from fixture logs.
699. Diff:
700. `+ fixture: overnight-60-callbacks.jsonl`
701. `+ fixture: skillos-manual-callback-gap.jsonl`
702. `+ fixture: mobile-eats-mission-compression.jsonl`
703. `+ expected: top-10 queue and manager decision stable across replay`
704. Why: a control loop without replay is not auditable.
705. Revision 15 title: keep P4/P5/P6 out of MVP mutations.
706. Before: migration re-evaluates after M1-M4.
707. After: M1-M4 may surface P4/P5/P6, not mutate them.
708. Diff:
709. `+ P4 in MVP: status row only.`
710. `+ P5 in MVP: candidate row only.`
711. `+ P6 in MVP: queue signal only.`
712. `+ Repair apply paths require separate design.`
713. Why: manager loop should measure before it automates dangerous mutations.
714. Revision count: 15.
715. Required minimum revisions: 8.
716. Revision verdict: sufficient.
717. These revisions keep the plan's spirit.
718. They remove the race conditions.
719. They preserve migration safety.
720. They make cross-orch evidence load-bearing.

## 8. Cross-Orch Evidence Integration

721. skillos evidence: blocker path ownership differs from local work blocked.
722. Source: `cross-orch-input/skillos-1-2026-05-05T1525Z.md:39-43`.
723. Plan implication: ops-log rows need `blocker_owner`.
724. Plan implication: ops-log rows need `work_blocked`.
725. Plan implication: ops-log rows need `safe_local_work_remaining`.
726. Plan implication: manager queue should not halt a repo because one blocker path is external.
727. skillos evidence: fleet-mail auth/search blocks durable plan-response detection.
728. Source: `cross-orch-input/skillos-1-2026-05-05T1525Z.md:45-49`.
729. Plan implication: manager loop cannot rely on mail search as the only peer receipt.
730. Plan implication: peer dispatch receipt must write ops-log or import path.
731. skillos evidence: callback grader cannot see manual callbacks by task id.
732. Source: `cross-orch-input/skillos-1-2026-05-05T1525Z.md:51-55`.
733. Plan implication: manual callback import is MVP, not future polish.
734. Plan implication: callback-grade row_found=false should become a manager-state degraded reason.
735. Plan implication: M4 must include validator disagreement.
736. mobile-eats evidence: active bead DB collapsed to two open beads but mission was not complete.
737. Source: `cross-orch-input/mobile-eats-1-2026-05-05T1545Z.md:13-16`.
738. Plan implication: top-10 queue must not trust bead ready state alone.
739. Plan implication: mission coverage matrix or mission anchors must gate selection.
740. mobile-eats evidence: mission compression class exists.
741. Source: `cross-orch-input/mobile-eats-1-2026-05-05T1545Z.md:21-27`.
742. Plan implication: ops-log must encode `mission_anchor_id`.
743. Plan implication: manager-state must show mission coverage gaps.
744. Plan implication: closure count without mission delta should not be OK.
745. mobile-eats evidence: validator split-brain exists.
746. Source: `cross-orch-input/mobile-eats-1-2026-05-05T1545Z.md:24-27`.
747. Plan implication: validator rows need authority and version.
748. Plan implication: manager should report contradictory verdicts as degraded.
749. mobile-eats evidence: docs not load-bearing.
750. Source: `cross-orch-input/mobile-eats-1-2026-05-05T1545Z.md:25`.
751. Plan implication: manager queue should include doc/test/artifact coverage fields only when they are gates.
752. mobile-eats evidence: dirty tree drift tolerated.
753. Source: `cross-orch-input/mobile-eats-1-2026-05-05T1545Z.md:24`.
754. Plan implication: manager-state should show dirty tree drift as a stock.
755. Plan implication: dirty tree drift should reduce dispatch eligibility.
756. skillos reshapes the plan from callback aggregation to authority modeling.
757. mobile-eats reshapes the plan from work selection to mission-grounded work selection.
758. Together, they make M1 insufficient without schema authority and mission anchor fields.
759. Together, they make M3 insufficient without mission coverage.
760. Together, they make M4 insufficient without validator conflict display.
761. Together, they make M2 unsafe without safe-local-work routing.
762. Cross-orch evidence also confirms the prior Donella critique.
763. The visible goal had become keeping local contracts satisfied.
764. The manager loop must redefine goal as mission-value movement plus founder-capacity protection.
765. Cross-orch evidence also confirms the prior Jeff critique.
766. Existing substrates already own pieces of the problem.
767. Agent Mail owns reservation semantics.
768. ntm owns pane transport and actuation.
769. `bv` owns graph attention.
770. Beads own issue lifecycle.
771. Ops-log should not usurp those owners.
772. Ops-log should compose their facts.
773. Manager loop should make a decision over their facts.
774. M4 should expose the decision and evidence.
775. The plan should name cross-orch writer contracts.
776. skillos writer contract: blocker ownership, callback-grade, storage/headroom halt contract.
777. mobile-eats writer contract: mission coverage, dirty tree drift, validator split-brain.
778. flywheel writer contract: manager decisions, queue render, callback import.
779. watcher writer contract: selection candidate, suppressed selection, dispatch sent.
780. worker writer contract: worker claim and evidence path.
781. validator writer contract: verdict and receipt.
782. doctor writer contract: observation and recommended action.
783. integrator writer contract: accepted mutation or rejected claim.
784. Cross-orch integration verdict: the manager-loop plan is strengthened, but its schema must grow.
785. Cross-orch risk: adding all fields at once can overbuild.
786. Cross-orch mitigation: define core event/v1 and specialized nested objects.
787. Cross-orch risk: manager-state becomes fleet-wide command center too early.
788. Cross-orch mitigation: start with flywheel session, then one peer replay.
789. Cross-orch risk: mobile-eats mission coverage belongs in separate compiler plan.
790. Cross-orch mitigation: manager loop only requires anchor refs; compiler owns matrix generation.
791. Cross-orch risk: skillos auth/search is a separate substrate issue.
792. Cross-orch mitigation: do not block M1; require import path and degraded signal.
793. Cross-orch conclusion: manager loop is the right integration surface.
794. Cross-orch conclusion: manager loop must be evidence-first, not message-first.
795. Cross-orch conclusion: manager loop must be mission-licensed, not bead-ready licensed.
796. Cross-orch conclusion: manager loop must make validator disagreement visible.
797. Cross-orch conclusion: manager loop must permit safe local work under external blockers.
798. Cross-orch conclusion: manager loop must preserve peer ownership boundaries.
799. Cross-orch conclusion: manager loop must not become a new monolith.
800. Cross-orch evidence score: 9.8 / 10.

## 9. Open Questions For Human Decision

801. Human question 01: should the canonical ops-log be global or session-sharded?
802. Recommendation: session-sharded with generated aggregate view.
803. Why human decision: this affects operator UX and log path conventions.
804. Agent recommendation confidence: high.
805. Human question 02: should compatibility callbacks remain visible to Joshua during migration?
806. Recommendation: yes, but manager decisions ignore them unless imported.
807. Why human decision: this affects Joshua's live pane-reading habit.
808. Agent recommendation confidence: high.
809. Human question 03: is 300s acceptable as the default manager decision tick?
810. Recommendation: yes.
811. Why human decision: cadence is taste plus operational risk.
812. Agent recommendation confidence: high.
813. Human question 04: should mission-anchor gating be required for every queue item?
814. Recommendation: require it for work items; allow typed substrate exceptions.
815. Why human decision: too strict a gate can block real substrate repairs.
816. Agent recommendation confidence: medium-high.
817. Human question 05: should manager-loop own fleet-wide top-10 immediately?
818. Recommendation: no.
819. Recommendation detail: start with flywheel session plus one peer replay.
820. Why human decision: fleet-wide command center changes operating rhythm.
821. Agent recommendation confidence: high.
822. Human question 06: should M4 Markdown be editable?
823. Recommendation: no.
824. Recommendation detail: Markdown should be generated from JSON with hash.
825. Why human decision: editable status pages can be convenient but invite drift.
826. Agent recommendation confidence: high.
827. Human question 07: what is the minimum parity window before callback cutover?
828. Recommendation: 24h or one complete manual replay of overnight failure.
829. Why human decision: urgency may justify shorter supervised cutover.
830. Agent recommendation confidence: medium.
831. Human question 08: should safety actions bypass one-decision-per-tick?
832. Recommendation: yes.
833. Why human decision: this weakens the simplicity of the plan but protects operations.
834. Agent recommendation confidence: high.
835. Human question 09: should the first implementation use JSONL or SQLite?
836. Recommendation: JSONL shards first, SQLite index later if query cost hurts.
837. Why human decision: SQLite is stronger for queries but heavier for writer rollout.
838. Agent recommendation confidence: medium-high.
839. Human question 10: should manager-state include callback volume?
840. Recommendation: yes, but as thrash risk, not progress.
841. Why human decision: public narrative may prefer less callback-centric display.
842. Agent recommendation confidence: high.
843. Questions that should not be asked of Joshua:
844. Do we kill callbacks immediately?
845. Answer: no.
846. Do we ship M2 before M1/M3?
847. Answer: no.
848. Do we let worker claims count as facts?
849. Answer: no.
850. Do we implement P4 force-release locally?
851. Answer: no.
852. Do we implement P5 auto-respawn locally from watcher logic?
853. Answer: no.
854. Do we let top-10 rely on `br ready` alone?
855. Answer: no.
856. Do we make morning report the control primitive?
857. Answer: no.
858. Do we run external model CLIs for this review?
859. Answer: no.
860. Final human decision list is intentionally short.
861. Most plan changes are agent-resolvable.
862. The only real taste decision is cadence and surface style.
863. The only real architecture decision is log topology.
864. The only real migration decision is cutover window.
865. Open question verdict: four true decisions, six recommendations already strong.
866. Manager-loop final verdict: revise.
867. Manager-loop final score: 9.62 / 10.
868. Obsoletes fleet-autonomy primitives: `P3-as-independent-controller`, `M-as-primary-measurement`, `callback-as-orchestrator-input`.
869. Preserves fleet-autonomy primitives: `P1`, `P2`, `P4`, `P5`, `P6`, and P3 schema fields as manager-state inputs.
870. Proposed changes: 15.
871. Migration risks named: 18.
872. Tick interval recommendation: 300 seconds.
873. Required line-count lower bound: satisfied by design.
874. Required plan-space-only constraint: satisfied.
875. Required prior-review reconciliation: satisfied.
876. Required schema audit: satisfied.
877. Required architecture critique: satisfied.
878. Required cross-orch evidence integration: satisfied.
879. Required open questions: satisfied.
880. Self-grade: Y.
