# 01-REVIEW-donella - Mission Coverage Compiler

## 0. Source Grounding

001. Reviewer lens: Donella Meadows systems thinking.
002. Verdict: revise.
003. Composite score after revision: 9.70 / 10.
004. Lane authenticity: 9.8 / 10.
005. Cross-lens compatibility: 9.7 / 10.
006. Joshua taste: 9.7 / 10.
007. Publishability: 9.6 / 10.
008. Canonical numbering is the 1999 Meadows leverage point ladder.
009. Constants and parameters are leverage point #12.
010. Buffers are leverage point #11.
011. Material stock-and-flow structure is leverage point #10.
012. Delays are leverage point #9.
013. Negative feedback loops are leverage point #8.
014. Positive feedback loops are leverage point #7.
015. Information flows are leverage point #6.
016. Rules are leverage point #5.
017. Self-organization is leverage point #4.
018. Goals are leverage point #3.
019. Paradigms are leverage point #2.
020. Transcending paradigms is leverage point #1.
021. I use the skill's canonical local references.
022. Stock/flow vocabulary comes from `STOCKS-AND-FLOWS.md`.
023. Feedback loop vocabulary comes from `FEEDBACK-LOOPS.md`.
024. Anti-pattern vocabulary comes from `ANTI-PATTERNS.md`.
025. The local exemplars show information flow, rules, delays, goals, paradigms, and self-organization.
026. The plan under review is `00-PLAN-INPUT.md`.
027. The plan's "why" is `00-PLAN-INPUT.md:11-33`.
028. The plan's evidence table is `00-PLAN-INPUT.md:35-66`.
029. The plan's paradigm shift is `00-PLAN-INPUT.md:68-97`.
030. The six primitives are `00-PLAN-INPUT.md:99-182`.
031. The plan's own Donella lens is `00-PLAN-INPUT.md:184-212`.
032. The plan's relationship boundaries are `00-PLAN-INPUT.md:244-262`.
033. The cross-orch integration is `00-PLAN-INPUT.md:264-282`.
034. The success criteria are `00-PLAN-INPUT.md:284-316`.
035. The verdict thresholds are `00-PLAN-INPUT.md:373-386`.
036. The plan sees a real system.
037. It sees the right stock.
038. It does not yet define the actor that must obey that stock.
039. That is the invisible structure.
040. I name it `coverage_without_authority`.

## 1. Verdict In One Sentence

041. Revise, because the plan correctly identifies the missing coverage ledger but still treats visibility as if it will become authority by itself.
042. Seeing the stock is not the same as controlling the flow.
043. A matrix that no dispatcher must obey is a mirror.
044. A matrix that gates dispatch, closure, and loop reenable is a feedback loop.
045. The plan wants the second.
046. Much of the text still builds the first.
047. This is not a rejection.
048. This is a leverage correction.
049. The highest leverage point is not "add a matrix."
050. The highest leverage point is "change who is allowed to declare mission progress."
051. That is a rule change at leverage point #5.
052. It points toward a goal change at leverage point #3.
053. It may support a paradigm change at leverage point #2.
054. But the plan only earns #2 if future agents stop believing bead state proves mission state.
055. The plan states that belief shift at `00-PLAN-INPUT.md:81-86`.
056. It has not yet wired the belief shift into enough consumers.
057. The revision must make obedience explicit.
058. Obedience means manager-loop consumes coverage.
059. Obedience means dispatch validators reject missing row references.
060. Obedience means closed-bead audit refuses ungrounded closures.
061. Obedience means loop reenable gates require fresh coverage.
062. Obedience means docs claims are downgraded when proof is stale.
063. Without obedience, the matrix becomes another morning report.
064. Morning reports are delayed feedback.
065. Delayed feedback teaches.
066. It does not regulate fast loops.
067. The plan exists because fast loops generated 59 chore commits and 0 mission progress.
068. That evidence is at `00-PLAN-INPUT.md:18-24`.
069. Therefore the plan must design a live feedback loop, not only a report.

## 2. System Boundary

070. System boundary: flywheel-managed repo mission execution.
071. Included: mission anchors.
072. Included: bead state.
073. Included: closed-bead claims.
074. Included: dispatch logs.
075. Included: fuckup logs.
076. Included: doctor outputs.
077. Included: validator outputs.
078. Included: docs claims.
079. Included: tests and artifacts.
080. Included: watcher and loop reenable decisions.
081. Excluded: product feature implementation.
082. Excluded: Nango resolution.
083. Excluded: writing new beads in this plan phase.
084. The stock of interest is not "number of beads."
085. The stock of interest is "mission surfaces with current proof."
086. The plan names this at `00-PLAN-INPUT.md:186-191`.
087. The inflow is verified evidence.
088. The outflow is drift.
089. Drift includes stale evidence.
090. Drift includes code changes.
091. Drift includes doc drift.
092. Drift includes validator contradiction.
093. Drift includes owner-custody blockers.
094. Drift includes dirty repo state.
095. The plan names those outflows at `00-PLAN-INPUT.md:193-194`.
096. The system's current visible goal is not mission proof.
097. The current visible goal is satisfying local work-state proxies.
098. Ready beads are a proxy.
099. Closed beads are a proxy.
100. Dispatch callbacks are a proxy.
101. Chore commits are a proxy.
102. Watcher ticks are a proxy.
103. The mobile-eats failure happened because proxies accumulated while mission proof did not.
104. This is a classic wrong-goal pattern.
105. It is not solved by adding another proxy.
106. It is solved by making the stock visible at the decision point.

## 3. Stock And Flow Audit - Whole Plan

107. Stock A: mission rows with verified proof.
108. Desired direction: increase.
109. Inflow: evidence mapped to mission row.
110. Outflow: evidence becoming stale or contradicted.
111. Measurement: coverage score and cap reasons.
112. Current plan strength: names the stock.
113. Current plan weakness: no score formula.
114. Contested lines: `00-PLAN-INPUT.md:294-316`.
115. Revision: define weighted coverage score and hard caps.
116. Stock B: ungrounded closed-bead claims.
117. Desired direction: decrease.
118. Inflow: every bead closed without row proof.
119. Outflow: mapped evidence or reopened/audit-gap state.
120. Measurement: `ungrounded_claim_count`.
121. Current plan strength: C2 names the class.
122. Contested lines: `00-PLAN-INPUT.md:129-142`.
123. Revision: use existing closed-bead scan output before building new logic.
124. Stock C: dirty unclassified repo state.
125. Desired direction: decrease.
126. Inflow: untracked, modified, generated, unpushed work.
127. Outflow: typed classification.
128. Measurement: dirty count by class.
129. Current plan strength: C0 names dirty state.
130. Contested lines: `00-PLAN-INPUT.md:103-113`.
131. Revision: global green cap plus row-local evidence cap.
132. Stock D: recurring failure classes.
133. Desired direction: decrease.
134. Inflow: dispatch failures, doctor warnings, validator conflicts.
135. Outflow: routed coverage blocker, tool fix, doctrine rule, or explicit non-action.
136. Measurement: failure-class rows consumed by coverage or existing learning substrate.
137. Current plan strength: C3 names the logs.
138. Contested lines: `00-PLAN-INPUT.md:144-155`.
139. Revision: normalize known classes first.
140. Stock E: automation eligibility.
141. Desired direction: true only when evidence supports it.
142. Inflow: fresh matrix, clean/quarantined repo, watcher probe green, validator agreement.
143. Outflow: stale matrix, dirty state, validator conflict, missing ledger.
144. Measurement: loop eligibility verdict.
145. Current plan strength: C5 names the gates.
146. Contested lines: `00-PLAN-INPUT.md:169-182`.
147. Revision: the compiler emits eligibility facts; loop substrate enforces.
148. Stock F: doc trust.
149. Desired direction: docs claims match proof state.
150. Inflow: docs updated from current matrix.
151. Outflow: stale docs claims.
152. Measurement: docs claim downgrade count.
153. Current plan weakness: docs proof is a column, not yet a docs-status loop.
154. Contested lines: `00-PLAN-INPUT.md:44-45`.
155. Revision: docs claim state must derive from matrix row state.

## 4. Primitive C0 - Freeze And Repo Reality Snapshot

156. C0 is a delays intervention.
157. It shortens the delay between dirty state and dirty-state awareness.
158. It also slows action until feedback arrives.
159. That is leverage point #9.
160. It creates information flow at leverage point #6.
161. The stock is untrusted repo state.
162. The inflow is unclassified changes.
163. The outflow is classification.
164. The plan says the compiler may emit a draft matrix in dirty state.
165. It says green verdicts are capped until dirty entries are classified.
166. Citation: `00-PLAN-INPUT.md:103-113`.
167. I agree with the green cap.
168. I disagree with any interpretation that suppresses row utility.
169. A dirty README should not cap a backend test row unless the README is load-bearing for that row.
170. A dirty generated artifact should not cap all mission surfaces.
171. A dirty source file should cap rows that depend on that file.
172. The missing structure is an overlap map.
173. C0 should output path classes.
174. C0 should output affected row IDs.
175. C0 should output global verdict cap.
176. C0 should output row caps.
177. C0 should not decide which work to do.
178. C0 should not revert files.
179. C0 should not quarantine by itself.
180. C0 should be a sensor.
181. Another substrate can act.
182. Measurement: dirty-unclassified count over time.
183. Corrective loop: dirty state detected, row caps applied, loop reenable denied, classification work selected.
184. Delay hazard: if classification happens only during manual review, churn returns.
185. Required consumer: loop reenable gate.
186. Required consumer: dispatch validator.
187. Revision: C0 must define `dirty_global_cap` and `dirty_row_caps`.
188. Without that, C0 is a warning.
189. With that, C0 is a control signal.

## 5. Primitive C1 - Mission Coverage Matrix Compiler

190. C1 is the real center.
191. It is leverage point #6 information flow.
192. It becomes leverage point #5 only when consumers must obey it.
193. It supports leverage point #3 if work selection optimizes coverage.
194. The stock is mission surfaces with evidence state.
195. The inflow is proof.
196. The outflow is drift.
197. The plan's row shape is good.
198. Citation: `00-PLAN-INPUT.md:115-127`.
199. The row shape is incomplete.
200. Missing field: stable `surface_id`.
201. Missing field: `row_kind`.
202. Missing field: `weight`.
203. Missing field: `coverage_state`.
204. Missing field: `claim_state`.
205. Missing field: `freshness_state`.
206. Missing field: `grade_cap_reason`.
207. Missing field: `reason_codes`.
208. Missing field: `source_hashes`.
209. Missing field: `consumer_actions`.
210. Missing field: `last_consumer_seen_at`.
211. Why this matters: a row without a stable ID cannot be a feedback signal.
212. A row without weight cannot prevent row-count gaming.
213. A row without freshness cannot prevent stale proof.
214. A row without consumer actions cannot govern behavior.
215. The plan should not add many columns for aesthetics.
216. It should add only columns required for feedback.
217. Measurement: coverage score by row kind.
218. Measurement: blocked row count by reason.
219. Measurement: unmapped closure count.
220. Measurement: docs downgrade count.
221. Measurement: consumer adoption count.
222. Corrective loop: row gap visible, manager-loop selects gap work, validator checks row proof, row status changes.
223. Missing feedback risk: matrix generated but no consumer reads it.
224. That is the central risk.
225. Invisible structure: coverage without authority.
226. Revision: C1 must name downstream consumers per row or per summary.

## 6. Primitive C2 - Closed-Bead Claim Auditor

227. C2 is leverage point #5 rules.
228. It is also leverage point #8 negative feedback.
229. The rule is simple: closed is not covered.
230. The stock is ungrounded closed-bead claims.
231. The inflow is closure events.
232. The outflow is evidence mapping.
233. The plan gets the principle right.
234. Citation: `00-PLAN-INPUT.md:129-142`.
235. But the plan should not create a parallel audit substrate.
236. Existing flywheel doctrine already treats closed beads as claims.
237. Existing scan logic already has artifact/test/schema/executable checks.
238. The compiler should consume that output.
239. It should add mission row mapping.
240. It should not reimplement artifact existence checks.
241. It should not reimplement JSON validity checks.
242. It should not reimplement executable checks.
243. It should map scan reasons to coverage reasons.
244. Corrective loop: closed claim without proof increases ungrounded count, manager-loop selects audit gap, proof lands, count decreases.
245. Delay hazard: old closed beads may overwhelm the system.
246. The plan asks how to handle old beads at `00-PLAN-INPUT.md:358`.
247. Answer: `legacy_unmapped`.
248. `legacy_unmapped` does not count as coverage.
249. `legacy_unmapped` does not automatically reopen.
250. `legacy_unmapped` is a stock to drain.
251. Measurement: old unmapped closure count by repo.
252. Measurement: new closure ungrounded rate.
253. Rule: new closures have stricter gates than historical closures.
254. This avoids punishing the past while preventing recurrence.

## 7. Primitive C3 - Failure Ledger Miner

255. C3 is the most dangerous primitive as written.
256. Citation: `00-PLAN-INPUT.md:144-155`.
257. It wants to mine dispatch-log, fuckup-log, doctor, and validator failures.
258. That is useful.
259. It is also unbounded.
260. Meadows would ask: what stock does this drain?
261. If the answer is "all failures," it drains nothing.
262. If the answer is "known failure classes that block mission rows," it can drain.
263. The stock is unresolved process failures that affect coverage.
264. The inflow is known failure events.
265. The outflow is row blockers or existing learning-substrate routing.
266. The plan names seven seed classes.
267. That is enough for MVP.
268. Do not mine every log class.
269. Normalize the seven classes first.
270. `mission_compression` maps to missing/underweighted rows.
271. `false_bead_confidence` maps to ungrounded closure/ready claim.
272. `parasitic_loop` maps to repeated blocker without evidence delta.
273. `dirty_tree_drift` maps to C0 caps.
274. `docs_not_load_bearing` maps to doc proof gap.
275. `validator_split_brain` maps to validator conflict.
276. `missing_coverage_ledger` maps to global red verdict.
277. Measurement: count of known failure events consumed into row state.
278. Corrective loop: failure class appears, row/cap changes, dispatcher behavior changes.
279. Missing feedback risk: failure class gets logged but not consumed.
280. Revision: C3 becomes failure-class normalizer.
281. Existing learning substrate keeps promotion and doctrine routing.

## 8. Primitive C4 - Planning And Bead Regeneration Input

282. C4 is plan-space.
283. Citation: `00-PLAN-INPUT.md:157-167`.
284. It is not implementation.
285. It must not create beads in this phase.
286. The plan says that.
287. The name still pulls toward beads.
288. Rename it.
289. The stock is coverage gaps grouped for later planning.
290. The inflow is row gaps from C1-C3.
291. The outflow is reviewed implementation work after convergence.
292. The leverage point is #4 self-organization.
293. The system organizes its own next structures.
294. It is also #3 if gap grouping changes what work is selected.
295. Do not call the output "bead candidates" in MVP.
296. Call it "gap groups."
297. A gap group can later become bead input.
298. It should include row IDs.
299. It should include blocked reason codes.
300. It should include suggested owner substrate.
301. It should include required proof.
302. It should include dependency hints.
303. It should include "not actionable yet" when appropriate.
304. Measurement: gap groups converted to reviewed beads after plan convergence.
305. Feedback loop: gap group reviewed, bead created, evidence lands, row improves.
306. Delay hazard: if gap groups are never converted, they become a pile.
307. Required consumer: plan-to-beads workflow after review.
308. Not this dispatch.

## 9. Primitive C5 - Dispatch Contract And Loop Reenable Gate

309. C5 is not one primitive.
310. Citation: `00-PLAN-INPUT.md:169-182`.
311. It combines dispatch contract and loop gate.
312. Those are different actors.
313. Dispatch contract gates workers.
314. Loop reenable gates automation.
315. The compiler should not enforce either directly.
316. It should emit facts both can consume.
317. The stock is automation eligibility.
318. The inflow is fresh proof.
319. The outflow is stale/conflicted proof.
320. The leverage point is #5 rules.
321. It becomes #8 negative feedback when the rule blocks unsafe action.
322. It becomes #9 delay management when it holds loops until fresh feedback.
323. Required dispatch facts: required mission row IDs.
324. Required dispatch facts: expected coverage delta.
325. Required dispatch facts: current cap reasons.
326. Required dispatch facts: proof profile.
327. Required loop facts: matrix freshness.
328. Required loop facts: dirty global cap.
329. Required loop facts: validator conflict count.
330. Required loop facts: missing ledger state.
331. Required loop facts: manual tick proof.
332. Measurement: dispatches with row IDs.
333. Measurement: dispatches rejected for missing row IDs.
334. Measurement: loop reenable refusals by reason.
335. Measurement: loops reenabled with fresh matrix.
336. Revision: split C5 into C5a consumer contract and C5b loop eligibility projection.
337. Or keep C5 but make ownership explicit.
338. Do not let C5 become the hidden controller.

## 10. Loop Topology

339. Current loop R1: ready bead count falls, confidence rises, mission inquiry falls, mission compression increases.
340. This is reinforcing.
341. The plan sees it as `false_bead_confidence`.
342. Citation: `00-PLAN-INPUT.md:41-43`.
343. Correction: compiler exposes uncovered mission rows despite low ready count.
344. Current loop R2: stale blocker repeats, callbacks happen, chore commits happen, loop activity appears justified.
345. The plan sees it as `parasitic_loop`.
346. Citation: `00-PLAN-INPUT.md:43`.
347. Correction: repeated blocker without evidence delta lowers dispatch confidence.
348. Current loop R3: docs claim completion, workers trust docs, missing gates persist, docs stay non-load-bearing.
349. The plan sees it as `docs_not_load_bearing`.
350. Citation: `00-PLAN-INPUT.md:44-45`.
351. Correction: docs claims are downgraded unless matrix proof supports them.
352. Current loop R4: validators disagree, orchestrator decides socially, no shared evidence surface improves.
353. The plan sees it as `validator_split_brain`.
354. Citation: `00-PLAN-INPUT.md:46-47`.
355. Correction: validator conflict becomes row state and global warning.
356. Desired loop B1: row gap appears, manager-loop selects gap work, evidence lands, row coverage rises.
357. Desired loop B2: closed bead lacks proof, auditor marks ungrounded, closure does not raise coverage, proof is added or claim remains separate.
358. Desired loop B3: dirty state overlaps row, row is capped, dispatch is blocked or scoped, dirty state is classified.
359. Desired loop B4: loop reenable checks matrix freshness, stale matrix blocks reenable, fresh compiler run restores eligibility.
360. Desired loop B5: docs claim exceeds proof, docs status downgraded, docs update is selected.
361. Missing loop: coverage row to dispatcher.
362. Missing loop: coverage row to closed-bead close gate.
363. Missing loop: coverage row to docs status drift.
364. Missing loop: coverage row to manager-loop priority score.
365. The plan names these generally.
366. It needs exact consumers.

## 11. Leverage Hierarchy Applied

367. #12 parameter changes are not enough.
368. A threshold on ready beads will not solve mission compression.
369. A lower loop interval will not solve false bead confidence.
370. #11 buffers are secondary.
371. More worker panes will not solve ungrounded closure.
372. #10 structure matters.
373. The matrix changes the structure connecting mission surfaces to evidence.
374. #9 delays matter.
375. Dirty-tree and matrix freshness reduce stale action.
376. #8 negative feedback matters.
377. The closed-bead auditor pushes back against false closure.
378. #7 positive feedback must be damped.
379. Stale blocker loops must stop amplifying activity.
380. #6 information flow is the first strong intervention.
381. The matrix gives the dispatcher truth it lacked.
382. #5 rules are where the plan should focus revision.
383. Dispatch and close gates must obey the matrix.
384. #4 self-organization appears in gap grouping and failure normalization.
385. #3 goals appears when work selection optimizes mission coverage.
386. #2 paradigm appears when beads are claims, not proof.
387. #1 is not needed.
388. The plan should not pretend transcendence is required.
389. The most defensible leverage point stack is #6 -> #5 -> #3.
390. The current plan claims #2 in spirit.
391. It earns #2 only after rules and goals are wired.

## 12. The Invisible Structure This Plan Misses

392. Mandatory section: the invisible structure is `coverage_without_authority`.
393. The plan assumes a matrix, once present, will discipline the system.
394. That is not how systems behave.
395. Information that does not reach authority is scenery.
396. Information that reaches authority but is optional is advice.
397. Information that authority must obey is a rule.
398. The current plan creates information.
399. It gestures at rules.
400. It does not fully assign authority.
401. Who can declare a mission row covered?
402. Who can declare a closed bead mission-valid?
403. Who can reenable a loop?
404. Who can waive stale evidence?
405. Who can downgrade docs claims?
406. Who can map old closed beads?
407. Who can accept validator split brain?
408. The plan has answers implied across C1-C5.
409. It needs them explicit.
410. A compiler without authority is a report.
411. A compiler with too much authority is a monolith.
412. The right answer is not "give the compiler all authority."
413. The right answer is "name the authority of each consumer."
414. Manager-loop owns priority authority.
415. Dispatch validator owns dispatch acceptance authority.
416. Closed-bead audit owns closure claim authority.
417. Loop gate owns reenable authority.
418. Docs status validator owns public claim authority.
419. Compiler owns projection authority.
420. Projection authority means "given inputs, this is the deterministic matrix."
421. It does not mean "take action."
422. This is the missing architecture.

## 13. Anti-Pattern Audit

423. Anti-pattern: leverage theater.
424. Risk: high if the matrix is not consumed.
425. Evidence: plan says compiler must flow into packets/gates at `00-PLAN-INPUT.md:209-212`.
426. Revision: name consumers and required contract fields.
427. Anti-pattern: parameter thrashing.
428. Risk: medium.
429. Evidence: open questions about freshness and score at `00-PLAN-INPUT.md:354-362`.
430. Revision: avoid starting with thresholds alone.
431. Anti-pattern: reminder substitution.
432. Risk: high if dispatch fields are prose-only.
433. Evidence: C5 lists fields at `00-PLAN-INPUT.md:176-182`.
434. Revision: validator must mechanically reject missing row references.
435. Anti-pattern: human-as-feedback-loop.
436. Risk: medium.
437. Evidence: plan asks review lanes to answer questions without Joshua.
438. Good.
439. Remaining risk: future waivers could route to Joshua.
440. Revision: define waiver classes.
441. Anti-pattern: source-laundering.
442. Risk: low.
443. Evidence: plan cites seed by line.
444. Anti-pattern: grand reframe without instrumentation.
445. Risk: medium.
446. Evidence: paradigm shift at `00-PLAN-INPUT.md:68-97`.
447. Revision: score, caps, consumer metrics.

## 14. Open Questions - My Answers

448. Question 1: dirty-state classification.
449. Answer: global green cap plus row-local caps.
450. Question source: `00-PLAN-INPUT.md:354`.
451. Question 2: schema freeze.
452. Answer: freeze schema in the revised plan.
453. Question source: `00-PLAN-INPUT.md:355`.
454. Question 3: proof set.
455. Answer: proof profile by row kind.
456. Code row: artifact plus test.
457. Docs row: doc claim plus source proof.
458. Load-bearing completion row: artifact plus test plus doc.
459. Question source: `00-PLAN-INPUT.md:356`.
460. Question 4: score.
461. Answer: weighted row score with hard caps.
462. Question source: `00-PLAN-INPUT.md:357`.
463. Question 5: old beads.
464. Answer: `legacy_unmapped`; no coverage credit, no automatic reopen.
465. Question source: `00-PLAN-INPUT.md:358`.
466. Question 6: validator split brain.
467. Answer: row cap and global warning.
468. Question source: `00-PLAN-INPUT.md:359`.
469. Question 7: freshness.
470. Answer: same tick for loop reenable; current tick window for dispatch; stale label for reports.
471. Question source: `00-PLAN-INPUT.md:360`.
472. Question 8: manager-loop consumption.
473. Answer: JSON summary projection.
474. Markdown is human.
475. Question source: `00-PLAN-INPUT.md:361`.
476. Question 9: skill ownership.
477. Answer: flywheel-loop command doctrine first; skill after recurrence.
478. Question source: `00-PLAN-INPUT.md:362`.

## 15. Specific Revisions Required

479. Revision 1: add authority boundary.
480. Target: after `00-PLAN-INPUT.md:250-251`.
481. Text: compiler projects; consumers enforce.
482. Revision 2: add schema v0.1.
483. Target: after `00-PLAN-INPUT.md:122-124`.
484. Text: stable row IDs, reason codes, caps, freshness, source hashes.
485. Revision 3: add score formula.
486. Target: after `00-PLAN-INPUT.md:294-302`.
487. Text: weighted score plus hard caps.
488. Revision 4: revise C0.
489. Target: `00-PLAN-INPUT.md:103-113`.
490. Text: global cap and row-local caps.
491. Revision 5: revise C2.
492. Target: `00-PLAN-INPUT.md:129-142`.
493. Text: consume existing closed-bead scan.
494. Revision 6: revise C3.
495. Target: `00-PLAN-INPUT.md:144-155`.
496. Text: normalize known classes; do not own learning.
497. Revision 7: rename C4.
498. Target: `00-PLAN-INPUT.md:157-167`.
499. Text: gap grouping projection.
500. Revision 8: split C5 authority.
501. Target: `00-PLAN-INPUT.md:169-182`.
502. Text: consumer contract projection.
503. Revision 9: answer open questions.
504. Target: `00-PLAN-INPUT.md:352-362`.
505. Text: default answers plus review challenge.
506. Revision 10: revise ship order.
507. Target: `00-PLAN-INPUT.md:364-371`.
508. Text: schema, replay, compiler, renderer, consumers, gates.

## 16. Proposed Donella Diff

509. ```diff
510. @@ Paradigm shift
511. - The mission coverage matrix is the plan-of-record audit surface.
512. + The mission coverage matrix is the canonical information-flow surface.
513. + It becomes a rule only where named consumers are required to obey it.
514. + Named consumers: manager-loop, dispatch validators, closed-bead audit,
515. + loop reenable gates, and docs status validators.
516. ```
517. ```diff
518. @@ C1
519. + Every row must include surface_id, row_kind, weight, coverage_state,
520. + claim_state, freshness_state, grade_cap_reason, reason_codes,
521. + source_hashes, and consumer_actions.
522. ```
523. ```diff
524. @@ C3
525. - Failure ledger miner
526. + Failure-class normalizer
527. + MVP handles the seven seed classes only.
528. + New class promotion remains in existing learning/fuckup substrates.
529. ```
530. ```diff
531. @@ C5
532. - Dispatch contract and loop reenable gate
533. + Consumer contract projection
534. + Compiler emits facts; consumer substrates enforce gates.
535. ```
536. ```diff
537. @@ Success criteria
538. + The plan succeeds only when at least one live consumer rejects or reprioritizes
539. + work based on compiler output during replay.
540. ```

## 17. Measurement Loop Requirements

541. Required measure 1: coverage score.
542. Required measure 2: coverage score by row kind.
543. Required measure 3: hard cap reason counts.
544. Required measure 4: ungrounded closed-bead claim count.
545. Required measure 5: legacy unmapped count.
546. Required measure 6: validator conflict count.
547. Required measure 7: docs downgrade count.
548. Required measure 8: stale evidence count.
549. Required measure 9: dispatches with mission row reference.
550. Required measure 10: dispatches rejected for missing row reference.
551. Required measure 11: loop reenable refusals by reason.
552. Required measure 12: manager-loop top-10 items with coverage score input.
553. Required measure 13: repeated blocker churn after compiler adoption.
554. Required measure 14: ready-bead confidence mismatch count.
555. Required measure 15: mobile-eats replay verdict.
556. These measures should be in the revised plan.
557. Without them, high-leverage claims are unmeasured.

## 18. Relationship To Manager-Loop

558. Manager-loop is the controller.
559. Mission coverage compiler is an information surface.
560. The plan says compiler feeds manager-loop at `00-PLAN-INPUT.md:250-251`.
561. Keep that.
562. Strengthen it.
563. Manager-loop should not parse markdown.
564. Manager-loop should consume JSON summary.
565. Summary fields: coverage score.
566. Summary fields: red cap reasons.
567. Summary fields: top uncovered rows.
568. Summary fields: stale proof count.
569. Summary fields: validator conflict count.
570. Summary fields: recommended consumer action.
571. Manager-loop decides priority.
572. Compiler does not decide priority.
573. This preserves authority boundaries.
574. This makes information flow live.

## 19. Relationship To Fleet-Autonomy

575. Fleet-autonomy is execution substrate.
576. Mission coverage compiler is mission truth substrate.
577. The seed says not to fold the plan into fleet-autonomy.
578. The plan preserves that at `00-PLAN-INPUT.md:241-242`.
579. Keep it.
580. Fleet-autonomy should call compiler in advisory mode first.
581. Advisory mode records what would have been blocked.
582. After replay and four-repo audit, fleet-autonomy can hard-gate.
583. This avoids freezing the fleet on a new unproven matrix.
584. It also avoids ignoring the matrix.
585. Measurement: advisory disagreement rate.
586. If advisory disagreement rate is high and correct, hard gate becomes safe.
587. If advisory disagreement rate is noisy, revise.

## 20. Relationship To Closed-Bead Audit

588. Closed-bead audit already owns artifact claim validation.
589. Compiler should not steal that job.
590. Compiler should ask a narrower question.
591. Does the validated closure map to a mission row?
592. If yes, it can raise row coverage.
593. If no, it remains a valid work closure but not mission proof.
594. That distinction is crucial.
595. A bead can be technically done and mission-irrelevant.
596. The system must be able to say that.
597. This is the antidote to false bead confidence.
598. Citation: `00-PLAN-INPUT.md:41-43`.

## 21. Relationship To Docs

599. Docs are a stock of public or operator belief.
600. The plan correctly says docs were not load-bearing.
601. Citation: `00-PLAN-INPUT.md:44-45`.
602. A doc claim should be allowed only in states.
603. State 1: observed.
604. State 2: target.
605. State 3: degraded.
606. State 4: stale.
607. State 5: unsupported.
608. Mission coverage compiler can compute doc claim state.
609. Docs status validator should enforce wording.
610. The compiler should not edit docs in MVP.
611. It should emit doc downgrade facts.
612. That is enough.

## 22. Relationship To Beads

613. Beads are useful.
614. Beads are not proof.
615. The plan says this.
616. Citation: `00-PLAN-INPUT.md:26-29`.
617. Good.
618. Beads are part of the graph.
619. `bv` can rank graph work.
620. `br` can track issue state.
621. Mission coverage compiler should not replace either.
622. It should annotate what mission rows beads claim.
623. It should reveal where no bead exists.
624. It should reveal where too many beads closed without proof.
625. It should reveal where old beads are legacy unmapped.
626. That is a high-leverage information flow.

## 23. Success Criteria Revision

627. The current success criteria are directionally right.
628. Citation: `00-PLAN-INPUT.md:284-316`.
629. They are not yet mechanical enough.
630. Add: mobile-eats replay catches all seven seed classes.
631. Add: JSON schema validates.
632. Add: markdown renderer includes matrix hash.
633. Add: deterministic run output stable except generated timestamp.
634. Add: row IDs stable across repeated runs.
635. Add: old closed beads produce `legacy_unmapped`.
636. Add: validator split brain creates conflict row.
637. Add: dirty overlap creates row cap.
638. Add: manager-loop summary includes top uncovered rows.
639. Add: dispatch advisory records would-block events.
640. Add: loop reenable refuses stale matrix.
641. These are measurement loops.
642. These make the plan real.

## 24. Revised Verdict Thresholds

643. Proceed if revised plan names consumers.
644. Proceed if revised plan freezes schema.
645. Proceed if revised plan answers open questions.
646. Proceed if revised plan keeps read-only MVP.
647. Proceed if revised plan includes replay fixture.
648. Proceed if revised plan makes JSON canonical.
649. Proceed if revised plan makes markdown generated.
650. Hold if compiler still owns dispatch decisions.
651. Hold if compiler still owns bead mutation.
652. Hold if C3 still mines unlimited logs.
653. Hold if C5 still mixes projection and enforcement.
654. Hold if score formula remains absent.
655. Reject if matrix is optional advice.
656. Reject if row IDs are unstable.
657. Reject if closed beads count as proof by default.
658. Reject if manager-loop must scrape markdown.
659. Reject if no consumer can reject work based on output.

## 25. What I Would Keep

660. Keep the diagnosis.
661. Keep the phrase mission compression.
662. Keep the phrase false bead confidence.
663. Keep the phrase missing coverage ledger.
664. Keep the bead-as-claim paradigm.
665. Keep the row columns as a base.
666. Keep plan-space.
667. Keep no beads now.
668. Keep the fleet-autonomy boundary.
669. Keep the manager-loop boundary.
670. Keep Donella and Jeff lenses.
671. Keep the six primitive count if renamed.
672. Keep closed-bead audit.
673. Keep failure class mapping.
674. Keep loop reenable gates.
675. Keep the ship order idea.
676. Keep the verdict thresholds idea.

## 26. What I Would Change

677. Change "matrix is the plan-of-record audit surface" to "matrix is canonical information-flow surface."
678. Change "failure ledger miner" to "failure-class normalizer."
679. Change "planning and bead regeneration input" to "gap grouping projection."
680. Change "dispatch contract and loop reenable gate" to "consumer contract projection."
681. Add authority boundary.
682. Add schema.
683. Add row IDs.
684. Add reason codes.
685. Add score formula.
686. Add freshness policy.
687. Add deterministic ordering.
688. Add mobile-eats replay.
689. Add consumer adoption metrics.
690. Add docs claim states.
691. Add advisory-to-hard-gate path.
692. Add old bead legacy state.

## 27. What I Would Not Build

693. Do not build a new issue tracker.
694. Do not build a new dispatcher.
695. Do not build a new manager loop.
696. Do not build a new fuckup-log.
697. Do not build a new docs editor.
698. Do not build a new bead mutator.
699. Do not build a new priority graph.
700. Do not build a second closed-bead artifact scanner.
701. Do not build a broad log miner.
702. Do not build a human report first.
703. Build the projection.
704. Make consumers obey it.

## 28. Final Donella Score

705. Lane authenticity: 9.8.
706. Cross-lens compatibility: 9.7.
707. Joshua taste: 9.7.
708. Publishability: 9.6.
709. Average: 9.70.
710. Verdict: revise.
711. Invisible structure named: `coverage_without_authority`.
712. Highest leverage point currently achieved: #6 information flow.
713. Highest leverage point available after revision: #5 rules.
714. Highest leverage point possible after adoption: #3 system goal.
715. Paradigm claim possible only after behavior changes: #2.
716. The plan should stop claiming paradigm and start earning it.
717. That means measurement.
718. That means consumer authority.
719. That means refusal paths.
720. That means no green verdict by implication.

## 29. Review-Lane Callback Values

721. donella_composite=9.70.
722. donella_verdict=revise.
723. donella_invisible_structure_named=coverage_without_authority.
724. total_donella_required_changes=10.
725. leverage_distribution=#2=1,#3=2,#4=2,#5=4,#6=5,#8=3,#9=2,#10=1.
726. stock_count=6.
727. feedback_loops_named=9.
728. anti_patterns_flagged=5.
729. open_questions_answered=9.
730. confidence=high.

## 30. Appendix - Line Citations For Contested Changes

731. Why plan exists: `00-PLAN-INPUT.md:11-33`.
732. Watcher stop evidence: `00-PLAN-INPUT.md:18-20`.
733. Bead collapse evidence: `00-PLAN-INPUT.md:22-24`.
734. Mission compression class: `00-PLAN-INPUT.md:41`.
735. False bead confidence class: `00-PLAN-INPUT.md:42`.
736. Parasitic loop class: `00-PLAN-INPUT.md:43`.
737. Dirty tree drift class: `00-PLAN-INPUT.md:44`.
738. Docs not load-bearing class: `00-PLAN-INPUT.md:45`.
739. Validator split brain class: `00-PLAN-INPUT.md:46`.
740. Missing coverage ledger class: `00-PLAN-INPUT.md:47`.
741. Meta-class: `00-PLAN-INPUT.md:49-50`.
742. Matrix shape: `00-PLAN-INPUT.md:57-61`.
743. Paradigm shift: `00-PLAN-INPUT.md:79-86`.
744. Loop consequence: `00-PLAN-INPUT.md:95-97`.
745. C0: `00-PLAN-INPUT.md:103-113`.
746. C1: `00-PLAN-INPUT.md:115-127`.
747. C2: `00-PLAN-INPUT.md:129-142`.
748. C3: `00-PLAN-INPUT.md:144-155`.
749. C4: `00-PLAN-INPUT.md:157-167`.
750. C5: `00-PLAN-INPUT.md:169-182`.
751. Plan Donella lens: `00-PLAN-INPUT.md:184-212`.
752. Plan Jeff lens: `00-PLAN-INPUT.md:214-242`.
753. Manager-loop boundary: `00-PLAN-INPUT.md:250-251`.
754. Cross-plan contract: `00-PLAN-INPUT.md:253-259`.
755. Cross-orch mobile-eats: `00-PLAN-INPUT.md:266-267`.
756. Cross-orch skillos: `00-PLAN-INPUT.md:273-275`.
757. Cross-orch alpsinsurance: `00-PLAN-INPUT.md:277-278`.
758. Success criteria: `00-PLAN-INPUT.md:284-316`.
759. Scope: `00-PLAN-INPUT.md:318-338`.
760. Constraints: `00-PLAN-INPUT.md:340-350`.
761. Open questions: `00-PLAN-INPUT.md:352-362`.
762. Ship order: `00-PLAN-INPUT.md:364-371`.
763. Verdict thresholds: `00-PLAN-INPUT.md:373-386`.

## 31. Closing

764. The plan is worth saving.
765. The evidence is strong.
766. The stock is named.
767. The loops are visible.
768. The leverage point hierarchy is mostly right.
769. The main correction is authority.
770. Do not let the compiler become another passive dashboard.
771. Do not let the compiler become another omnipotent substrate.
772. Let it compile.
773. Let the consumers obey.
774. Let the metrics prove whether obedience changes the stock.
775. Then the plan will have earned its paradigm language.
