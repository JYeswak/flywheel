---
title: "01-REVIEW-multi-model - Mission Coverage Compiler"
type: plan
created: 2026-05-06
frontmatter_source: scaffold-doc-frontmatter
---

## Contents

- [0. Execution Note](#0-execution-note)
- [1. Exact Prompt Application](#1-exact-prompt-application)
- [2. Executive Verdict](#2-executive-verdict)
- [3. Triangulated Lens A - Planning Workflow](#3-triangulated-lens-a-planning-workflow)
- [4. Triangulated Lens B - Systems Architecture](#4-triangulated-lens-b-systems-architecture)
- [5. Triangulated Lens C - Joshua Taste](#5-triangulated-lens-c-joshua-taste)
- [6. Triangulated Lens D - Operator Substrate](#6-triangulated-lens-d-operator-substrate)
- [7. High-Confidence Consensus](#7-high-confidence-consensus)
- [8. Disagreements Worth Resolving](#8-disagreements-worth-resolving)
- [9. Proposed Change 1 - State The Thin-Compositor Paradigm](#9-proposed-change-1-state-the-thin-compositor-paradigm)
- [10. Proposed Change 2 - Split Compiler And Consumers](#10-proposed-change-2-split-compiler-and-consumers)
- [11. Proposed Change 3 - Freeze Row Schema In Revision](#11-proposed-change-3-freeze-row-schema-in-revision)
- [12. Proposed Change 4 - Dirty State Is A Cap, Not A Blackout](#12-proposed-change-4-dirty-state-is-a-cap-not-a-blackout)
- [13. Proposed Change 5 - Make C2 Reuse Existing Closed-Bead Scan](#13-proposed-change-5-make-c2-reuse-existing-closed-bead-scan)
- [14. Proposed Change 6 - Convert C3 Into Normalization](#14-proposed-change-6-convert-c3-into-normalization)
- [15. Proposed Change 7 - Rename C4](#15-proposed-change-7-rename-c4)
- [16. Proposed Change 8 - C5 Emits Contracts, Not Actions](#16-proposed-change-8-c5-emits-contracts-not-actions)
- [17. Proposed Change 9 - Add Scoring Formula](#17-proposed-change-9-add-scoring-formula)
- [18. Proposed Change 10 - Add Freshness Policy](#18-proposed-change-10-add-freshness-policy)
- [19. Proposed Change 11 - Answer Open Questions By Default](#19-proposed-change-11-answer-open-questions-by-default)
- [20. Proposed Change 12 - Expand Canonical CLI Contract](#20-proposed-change-12-expand-canonical-cli-contract)
- [21. Proposed Change 13 - Add Replay Fixture](#21-proposed-change-13-add-replay-fixture)
- [22. Proposed Change 14 - Make Markdown A Renderer](#22-proposed-change-14-make-markdown-a-renderer)
- [23. Proposed Change 15 - Add Explicit Non-Goals](#23-proposed-change-15-add-explicit-non-goals)
- [24. Architecture After Revisions](#24-architecture-after-revisions)
- [25. Publishability Review](#25-publishability-review)
- [26. Joshua-Taste Review](#26-joshua-taste-review)
- [27. Risk Register](#27-risk-register)
- [28. Revised Ship Order](#28-revised-ship-order)
- [29. Final Scorecard](#29-final-scorecard)
- [30. Appendix - Socraticode And Skill Evidence](#30-appendix-socraticode-and-skill-evidence)
# 01-REVIEW-multi-model - Mission Coverage Compiler

## 0. Execution Note

001. Task: review `00-PLAN-INPUT - Mission Coverage Compiler`.
002. Review lane: multi-model triangulation at worker parity.
003. External model calls: not used.
004. Reason: this worker is producing the consolidated lane review locally.
005. Triangulation method: internal four-lens synthesis.
006. Lens A: planning-workflow exact-prompt reviewer.
007. Lens B: systems architecture reviewer.
008. Lens C: Joshua taste and publishability reviewer.
009. Lens D: operator substrate reviewer.
010. Skills consulted: planning-workflow.
011. Skills consulted: multi-model-triangulation.
012. Skills consulted: donella-meadows-systems-thinking.
013. Skills consulted: jeff-planning-enhanced.
014. Skills consulted: jeff-convergence-audit.
015. Skills consulted: canonical-cli-scoping.
016. Skills consulted: accretive-cron-orchestration.
017. Skills consulted: beads-bv and beads-br.
018. Skill search query: `mission coverage doctrine bead audit ledger artifact docs gate validator`.
019. Skill search useful hits: mission-anchor-init, socraticode, flywheel-doctor-author, codebase-audit.
020. Socraticode for Jeff corpus: green.
021. Jeff-corpus indexed chunks observed: 893496.
022. Jeff-corpus query count: 10.
023. Plan input reviewed: `00-PLAN-INPUT.md`.
024. Plan-space only: yes.
025. Source edits made: none.
026. Beads created: none.
027. File reservation held before writing: yes.
028. Primary question: should the plan proceed to revision?
029. Secondary question: does the compiler remain separate from fleet-autonomy-v1?
030. Tertiary question: does it feed manager-loop without replacing it?
031. Answer: revise, keep the paradigm, narrow the implementation surface.
032. Overall multi-model verdict: revise.
033. Composite score after required revisions: 9.58 / 10.
034. Planning-workflow conformance: 9.6 / 10.
035. Paradigm soundness: 9.5 / 10.
036. Joshua taste: 9.7 / 10.
037. Public publishability after redaction: 9.5 / 10.
038. The plan is strong enough to keep.
039. The plan is not yet stable enough to convert to beads.
040. The missing piece is not more ambition.
041. The missing piece is thinner ownership.
042. The compiler should compile.
043. The dispatcher should dispatch.
044. The manager loop should prioritize.
045. The validator should validate.
046. The closed-bead auditor should audit.
047. The current plan sometimes lets the compiler own all five.
048. That is the main revision target.

## 1. Exact Prompt Application

049. The planning-workflow exact prompt asks for best revisions.
050. It asks for better architecture.
051. It asks for changed features.
052. It asks for robustness.
053. It asks for reliability.
054. It asks for usefulness.
055. It asks for detailed rationale.
056. It asks for git-diff style changes against the plan.
057. This review follows that contract.
058. The original plan has enough material to review.
059. It explains why it exists at `00-PLAN-INPUT.md:11-33`.
060. It gives hard evidence at `00-PLAN-INPUT.md:35-66`.
061. It states the paradigm shift at `00-PLAN-INPUT.md:68-97`.
062. It defines six primitives at `00-PLAN-INPUT.md:99-182`.
063. It applies the Donella lens at `00-PLAN-INPUT.md:184-212`.
064. It applies the Jeff lens at `00-PLAN-INPUT.md:214-242`.
065. It relates to fleet-autonomy and manager-loop at `00-PLAN-INPUT.md:244-262`.
066. It integrates cross-orch evidence at `00-PLAN-INPUT.md:264-282`.
067. It sets success criteria at `00-PLAN-INPUT.md:284-316`.
068. It scopes in/out at `00-PLAN-INPUT.md:318-338`.
069. It records open questions at `00-PLAN-INPUT.md:352-362`.
070. It proposes ship order at `00-PLAN-INPUT.md:364-371`.
071. It sets verdict thresholds at `00-PLAN-INPUT.md:373-386`.
072. The plan is self-contained enough for review.
073. It is not self-contained enough for implementation.
074. That is acceptable at this stage.
075. The dispatch requested review, not beads.
076. The plan's strongest move is the bead-as-claim paradigm.
077. That move appears at `00-PLAN-INPUT.md:26-29`.
078. It appears again at `00-PLAN-INPUT.md:81-83`.
079. It appears again in C2 at `00-PLAN-INPUT.md:129-142`.
080. That is coherent.
081. The plan's weakest move is ownership blur.
082. C1 compiles rows.
083. C2 audits closures.
084. C3 mines failures.
085. C4 prepares work.
086. C5 gates dispatch and loop reenable.
087. Those are adjacent but not necessarily one component.
088. The review should keep the conceptual system and split the runtime owners.
089. This is a revision, not rejection.
090. The plan should enter another refinement round before bead conversion.

## 2. Executive Verdict

091. Verdict: revise.
092. Do not keep unchanged.
093. Do not reject.
094. Keep the problem statement.
095. Keep the seven failure classes.
096. Keep the six-primitives frame.
097. Keep the mission coverage matrix.
098. Keep the "closed beads are claims" rule.
099. Keep the manager-loop feed boundary.
100. Keep the fleet-autonomy separation.
101. Revise the compiler ownership model.
102. Revise row schema.
103. Revise verdict taxonomy.
104. Revise C0 from global dirty cap to row-local plus global cap modes.
105. Revise C3 into a failure-normalization adapter, not a new mining universe.
106. Revise C4 to output gap groups, not bead-ready objects.
107. Revise C5 to define consumer contracts, not compiler behavior.
108. Add score calculation.
109. Add freshness policy.
110. Add deterministic ordering.
111. Add stable reason codes.
112. Add replay fixture expectation.
113. Add JSON-first contract.
114. Add markdown-as-renderer contract.
115. Add existing primitive reuse inventory.
116. Add a hard "thin compositor first" MVP.
117. The plan's current composite is 8.9 / 10 before revision.
118. The plan's revised potential is 9.58 / 10.
119. The high score is not generosity.
120. The problem is real.
121. The evidence is concrete.
122. The plan names the right failure class.
123. The plan is pointed at the right leverage tier.
124. The plan is still too expansive as an implementation object.
125. The proper first ship is a read-only compiler.
126. The proper first ship is not a new work planner.
127. The proper first ship is not a new loop controller.
128. The proper first ship is not a bead mutator.
129. The proper first ship is not a docs linter.
130. The proper first ship is not a replacement for `br`.
131. The proper first ship is not a replacement for `bv`.
132. The proper first ship is not a replacement for manager-loop.
133. It is a deterministic projection over existing substrate.
134. That phrase should be added to the plan.
135. Recommended revision title: "Mission Coverage Compiler as Deterministic Projection".
136. Recommended MVP: `mission-coverage compile --repo <path> --json --dry-run`.
137. Recommended output pair: `coverage.json` plus generated `coverage.md`.
138. Recommended proof: mobile-eats replay.
139. Recommended first consumer: manager-loop read-only queue scoring.
140. Recommended second consumer: dispatch contract validator.
141. Recommended third consumer: loop reenable gate.
142. Recommended fourth consumer: closed-bead auditor.
143. This order keeps the compiler from becoming a government.
144. It lets each existing substrate keep its job.

## 3. Triangulated Lens A - Planning Workflow

145. Lens A says the plan is unusually good for a first plan input.
146. It has a clear why.
147. It has hard evidence.
148. It has a paradigm shift.
149. It has primitives.
150. It has scope control.
151. It has success criteria.
152. It has open questions.
153. It has ship order.
154. It has verdict thresholds.
155. It cites the seed source by file and line.
156. It honors the no-bead constraint.
157. It honors plan-space.
158. It does not ask Joshua.
159. It does not prematurely implement.
160. It follows the 85% planning rule.
161. The plan is not yet great by planning-workflow standards.
162. A great plan explains dependencies more explicitly.
163. C0 feeds C1.
164. C1 feeds C2.
165. C2 and C3 feed C4.
166. C1 through C3 feed C5.
167. Manager-loop consumption depends on C1 output.
168. Fleet-autonomy dispatch guarding depends on C5 output.
169. Closed-bead auditing depends on C1 row IDs.
170. The plan implies these dependencies.
171. It does not state them as a dependency graph.
172. Add a dependency graph section.
173. The plan names ship order at `00-PLAN-INPUT.md:364-371`.
174. The ship order is too compressed.
175. Step 2 combines schema freeze and compiler build.
176. That is a real dependency boundary.
177. Schema freeze should precede compiler.
178. Compiler should precede replay fixture pass.
179. Replay fixture should precede consumers.
180. Consumers should precede loop gates.
181. Loop gates should precede fleet rollout.
182. Lens A score: 9.6 after these changes.
183. Lens A verdict: revise.
184. Lens A would not send this to beads yet.
185. Lens A would send it to one more integrate-revisions pass.
186. Lens A would require dependency-aware ship order.
187. Lens A would require a "what not to build" MVP guard.
188. Lens A would require stable row schema.
189. Lens A would require evidence examples.
190. Lens A would require a mobile-eats replay fixture.
191. Lens A would require a rejected-row example.
192. Lens A would require a validator-conflict example.
193. Lens A would require an old-closed-bead example.
194. Lens A would require dirty-tree classification examples.
195. Lens A would require markdown renderer constraints.
196. Lens A would require JSON schema constraints.
197. Lens A would require exit code constraints.
198. Lens A would require freshness constraints.
199. Lens A would require deterministic sorting constraints.
200. Lens A would then approve conversion to beads.

## 4. Triangulated Lens B - Systems Architecture

201. Lens B says the architecture is right but the component boundary is wrong.
202. The desired system is not one compiler with six jobs.
203. The desired system is one compiler plus four consumers.
204. Consumer one: manager-loop.
205. Consumer two: dispatch validator.
206. Consumer three: loop reenable gate.
207. Consumer four: closed-bead auditor.
208. Optional consumer five: docs status drift validator.
209. The compiler should not decide work.
210. It should expose coverage state.
211. The compiler should not mutate beads.
212. It should expose closure claim status.
213. The compiler should not release or enable loops.
214. It should expose eligibility facts.
215. The compiler should not mine every log forever.
216. It should normalize known failure rows into coverage blockers.
217. The plan's C3 risks building a second fuckup-log.
218. That risk is contested against `00-PLAN-INPUT.md:144-155`.
219. The revision should make C3 an adapter over existing logs.
220. The plan's C5 risks building a second dispatcher.
221. That risk is contested against `00-PLAN-INPUT.md:169-182`.
222. The revision should make C5 a contract emitted for dispatchers.
223. The plan's C4 risks creating hidden bead-generation pressure.
224. That risk is contested against `00-PLAN-INPUT.md:157-167`.
225. The revision should make C4 a gap ledger.
226. The plan's C1 is the core.
227. C1 should get more detail, not more neighbors.
228. The row ID must be stable.
229. The row ID must survive markdown rendering.
230. The row ID must survive repo path changes.
231. The row ID should derive from mission surface plus source anchor.
232. The row should carry `surface_id`.
233. The row should carry `source_anchor`.
234. The row should carry `evidence_status`.
235. The row should carry `claim_state`.
236. The row should carry `freshness_state`.
237. The row should carry `grade_cap_reason`.
238. The row should carry `reason_codes`.
239. The row should carry `consumer_actions`.
240. Lens B score: 9.5 after revision.
241. Lens B verdict: revise.

## 5. Triangulated Lens C - Joshua Taste

242. Lens C says the plan mostly sounds like Joshua's substrate.
243. It is direct.
244. It is not vague.
245. It does not ask for permission.
246. It does not over-explain Nango.
247. It recognizes the bead substrate can lie.
248. It recognizes docs must become load-bearing.
249. It recognizes stale loops are not work.
250. It names the seven failure classes.
251. It separates mobile-eats-local from flywheel doctrine.
252. It keeps plan-space clean.
253. It does one questionable Joshua-taste thing.
254. It lets review lanes answer nine open questions without pre-answering enough.
255. Joshua tends to prefer strong recommendations.
256. The plan should answer its own open questions where the evidence is enough.
257. Question 1 should be answered: dirty state is global cap plus row-local evidence cap.
258. Question 2 should be answered: schema freezes in revised plan, not first bead.
259. Question 3 should be answered: proof minimum is artifact plus test for code rows, artifact plus doc for doc rows, all three for load-bearing completion rows.
260. Question 4 should be answered: coverage score is weighted row score with risk caps.
261. Question 5 should be answered: old closed beads get `legacy_unmapped` and do not count until mapped.
262. Question 6 should be answered: validator split brain is both row cap and global warning.
263. Question 7 should be answered: loop reenable needs same-tick or explicitly fresh matrix.
264. Question 8 should be answered: manager-loop consumes JSON summary, humans read markdown.
265. Question 9 should be answered: first owner is flywheel-loop command doctrine; later skill if repeated across repos.
266. Leaving these as open questions weakens the next dispatch.
267. That is contested against `00-PLAN-INPUT.md:352-362`.
268. The revision should change open questions into default answers plus review prompts.
269. Lens C score: 9.7 after revision.
270. Lens C verdict: revise.

## 6. Triangulated Lens D - Operator Substrate

271. Lens D says every new operator primitive must be canonical-cli scoped.
272. The plan knows this at `00-PLAN-INPUT.md:224-236`.
273. The plan names a good CLI shape.
274. The CLI shape is incomplete.
275. It lacks `health`.
276. It lacks `repair`.
277. It lacks `why`.
278. It lacks `audit`.
279. It lacks `quickstart`.
280. It lacks completion.
281. It lacks schema subcommands per command.
282. It lacks universal exit codes.
283. It lacks `--no-color`.
284. It lacks `--no-emoji`.
285. It lacks width control.
286. It lacks deterministic output wording.
287. It lacks markdown renderer boundaries.
288. It lacks robot namespace.
289. It lacks a clear mutation policy for future bead generation.
290. Canonical CLI scoping does not require all future commands in MVP.
291. It does require planning them now.
292. MVP can expose compile, validate, schema, and explain.
293. The plan should name deferred commands as post-MVP.
294. The plan should mark all mutation surfaces out of MVP.
295. The plan should define exit codes.
296. Exit 0: matrix valid and no blocking gaps.
297. Exit 1: valid matrix with blocking gaps.
298. Exit 2: usage error.
299. Exit 3: upstream/substrate unavailable.
300. Exit 4: blocked by dirty-state or explicit gate.
301. Exit 5: schema incompatibility.
302. This is a contested change to `00-PLAN-INPUT.md:224-236`.
303. Lens D score: 9.5 after revision.
304. Lens D verdict: revise.

## 7. High-Confidence Consensus

305. Consensus 1: the problem is real.
306. Evidence: watchers stopped after chore churn at `00-PLAN-INPUT.md:18-20`.
307. Consensus 2: bead counts are insufficient proof.
308. Evidence: `false_bead_confidence` at `00-PLAN-INPUT.md:41-43`.
309. Consensus 3: the matrix is the right central artifact.
310. Evidence: row shape at `00-PLAN-INPUT.md:57-61`.
311. Consensus 4: the compiler must remain separate from fleet-autonomy-v1.
312. Evidence: seed routing cited at `00-PLAN-INPUT.md:13-16`.
313. Consensus 5: the compiler must feed manager-loop.
314. Evidence: cross-plan contract at `00-PLAN-INPUT.md:253-259`.
315. Consensus 6: closed beads must be audited as claims.
316. Evidence: C2 at `00-PLAN-INPUT.md:129-142`.
317. Consensus 7: docs need proof status.
318. Evidence: `docs_not_load_bearing` at `00-PLAN-INPUT.md:44-45`.
319. Consensus 8: validator split brain must become typed.
320. Evidence: `validator_split_brain` at `00-PLAN-INPUT.md:46-47`.
321. Consensus 9: plan-space is correct now.
322. Evidence: constraints at `00-PLAN-INPUT.md:340-350`.
323. Consensus 10: no beads yet.
324. Evidence: plan-level success at `00-PLAN-INPUT.md:286-292`.
325. Consensus 11: the plan needs schema before implementation.
326. Evidence: row schema is currently prose at `00-PLAN-INPUT.md:122-124`.
327. Consensus 12: the implementation should be read-only first.
328. Evidence: Jeff lens mutation discipline at `00-PLAN-INPUT.md:235-236`.
329. Consensus 13: JSON is the canonical machine surface.
330. Evidence: CLI shape at `00-PLAN-INPUT.md:224-233`.
331. Consensus 14: markdown should be generated, not authoritative.
332. Evidence: plan output currently mixes human and machine obligations.
333. Consensus 15: the current ship order is close but too compressed.
334. Evidence: `00-PLAN-INPUT.md:366-371`.

## 8. Disagreements Worth Resolving

335. Disagreement 1: is dirty state a hard global blocker?
336. Planning lens says yes for green verdict.
337. Architecture lens says row-local evidence can still be useful.
338. Synthesis: dirty state globally caps green, row-locally caps affected evidence.
339. This answers `00-PLAN-INPUT.md:354`.
340. Disagreement 2: where does schema freeze happen?
341. Planning lens says before implementation.
342. Operator lens says before CLI contract.
343. Synthesis: schema freezes in revised plan appendix.
344. This answers `00-PLAN-INPUT.md:355`.
345. Disagreement 3: what proof minimum is required?
346. Publishability lens wants artifact plus test plus doc for all claims.
347. Operator lens says row type should determine proof.
348. Synthesis: proof profile is row-kind specific.
349. This answers `00-PLAN-INPUT.md:356`.
350. Disagreement 4: should coverage score be simple?
351. Planning lens likes simple row count.
352. Systems lens rejects row-count gaming.
353. Synthesis: weighted score plus hard caps.
354. This answers `00-PLAN-INPUT.md:357`.
355. Disagreement 5: how to handle old closed beads?
356. Planning lens wants audit-gap rows.
357. Jeff lens wants thin mapping without mutation.
358. Synthesis: `legacy_unmapped` state until mapped.
359. This answers `00-PLAN-INPUT.md:358`.
360. Disagreement 6: validator split brain cap?
361. Donella lens wants global warning.
362. Operator lens wants row cap.
363. Synthesis: both.
364. This answers `00-PLAN-INPUT.md:359`.
365. Disagreement 7: matrix freshness.
366. Cron lens wants same tick for loop reenabling.
367. Publishability lens wants configurable freshness.
368. Synthesis: same tick for reenable, configurable for reports.
369. This answers `00-PLAN-INPUT.md:360`.
370. Disagreement 8: manager-loop input format.
371. Operator lens wants JSON.
372. Human lens wants markdown.
373. Synthesis: JSON canonical, markdown renderer.
374. This answers `00-PLAN-INPUT.md:361`.
375. Disagreement 9: skill ownership.
376. Planning lens wants new skill eventually.
377. Operator lens wants command doctrine first.
378. Synthesis: flywheel-loop command first, skill after recurrence.
379. This answers `00-PLAN-INPUT.md:362`.

## 9. Proposed Change 1 - State The Thin-Compositor Paradigm

380. Finding: the plan says beads become claims, but it does not say the compiler is a projection.
381. Contested lines: `00-PLAN-INPUT.md:81-86`.
382. Risk: the compiler becomes a new owner of state.
383. Recommendation: state that it composes existing substrates.
384. Rationale: Jeff-corpus search found repeated evidence-led thin aggregators.
385. Rationale: `frankenterm` telemetry wraps pure-data rows without changing wire format.
386. Rationale: `frankenlibc` gap ledger parses existing docs and artifacts.
387. Diff:
388. ```diff
389. @@ Paradigm shift
390. - The mission coverage matrix is the plan-of-record audit surface.
391. + The mission coverage matrix is a deterministic projection over existing substrates.
392. + It is not a new work tracker, log store, dispatcher, or bead owner.
393. + Its authority comes from compiling mission rows against evidence already owned elsewhere.
394. ```
395. Impact: prevents substrate duplication.
396. Score effect: +0.12.

## 10. Proposed Change 2 - Split Compiler And Consumers

397. Finding: C5 makes the compiler sound like a dispatch and loop controller.
398. Contested lines: `00-PLAN-INPUT.md:169-182`.
399. Risk: one tool owns too much.
400. Recommendation: add a consumer boundary section.
401. Diff:
402. ```diff
403. @@ Relationship to fleet-autonomy-v1 and manager-loop
404. + Runtime ownership:
405. + - compiler owns read-only coverage projection
406. + - manager-loop owns queue prioritization
407. + - dispatch validators own dispatch acceptance
408. + - loop gates own reenable decisions
409. + - closed-bead auditor owns closure claim disposition
410. ```
411. Rationale: keeps manager-loop as manager and compiler as compiler.
412. Rationale: honors `00-PLAN-INPUT.md:250-251`.
413. Impact: removes ownership blur.
414. Score effect: +0.10.

## 11. Proposed Change 3 - Freeze Row Schema In Revision

415. Finding: row fields are listed, but no schema discipline exists.
416. Contested lines: `00-PLAN-INPUT.md:122-124`.
417. Risk: implementers invent incompatible matrices.
418. Recommendation: define schema v0.1 in revised plan.
419. Diff:
420. ```diff
421. @@ C1 - Mission coverage matrix compiler
422. + Required schema version: mission_coverage_matrix.v0.1.
423. + Required stable row identity: surface_id.
424. + Required reason codes: coverage_missing, evidence_stale, validator_conflict,
425. + legacy_unmapped, dirty_state_cap, doc_gate_missing, test_gate_missing.
426. + Rows sort by phase_order, surface_id.
427. ```
428. Rationale: deterministic compilation needs stable IDs and ordering.
429. Rationale: Socraticode found Jeff-corpus fixtures asserting schema versions and deterministic output.
430. Impact: makes future implementation testable.
431. Score effect: +0.15.

## 12. Proposed Change 4 - Dirty State Is A Cap, Not A Blackout

432. Finding: C0 caps green verdicts but could suppress useful rows.
433. Contested lines: `00-PLAN-INPUT.md:103-113`.
434. Risk: dirty repos produce no actionable coverage signal.
435. Recommendation: classify dirty-state effects.
436. Diff:
437. ```diff
438. @@ C0
439. - green verdicts are capped until dirty entries are classified
440. + green verdicts are capped globally until dirty entries are classified.
441. + Row evidence is capped only when the dirty path overlaps the row artifact,
442. + test proof, doc proof, or source anchor.
443. ```
444. Rationale: keeps matrix useful during triage.
445. Rationale: still prevents false green.
446. Impact: more precise failure reporting.
447. Score effect: +0.06.

## 13. Proposed Change 5 - Make C2 Reuse Existing Closed-Bead Scan

448. Finding: C2 describes an auditor, but not the existing closed-bead scan substrate.
449. Contested lines: `00-PLAN-INPUT.md:129-142`.
450. Risk: duplicate auditor.
451. Recommendation: require adapter over existing scan output first.
452. Diff:
453. ```diff
454. @@ C2
455. + MVP input is existing closed-bead artifact scan output when available.
456. + The compiler normalizes scan reasons into row-level claim_state.
457. + It does not reimplement artifact existence, JSON validity, or executable checks.
458. ```
459. Rationale: reuse before build.
460. Rationale: current flywheel doctrine already has closed-bead claim vocabulary.
461. Impact: smaller build.
462. Score effect: +0.10.

## 14. Proposed Change 6 - Convert C3 Into Normalization

463. Finding: "failure ledger miner" is too broad.
464. Contested lines: `00-PLAN-INPUT.md:144-155`.
465. Risk: endless log-mining scope.
466. Recommendation: normalize known classes first.
467. Diff:
468. ```diff
469. @@ C3
470. - Failure ledger miner
471. + Failure-class normalizer
472. + MVP maps only known failure classes from dispatch-log, fuckup-log,
473. + doctor, and validator surfaces into coverage row blockers.
474. + New class discovery remains owned by existing learning and fuckup substrates.
475. ```
476. Rationale: keeps compiler bounded.
477. Rationale: prevents another incident-promotion ladder.
478. Impact: cuts implementation risk.
479. Score effect: +0.08.

## 15. Proposed Change 7 - Rename C4

480. Finding: "bead regeneration input" pressures implementation too early.
481. Contested lines: `00-PLAN-INPUT.md:157-167`.
482. Risk: plan-space review quietly turns into bead creation.
483. Recommendation: rename C4 to "gap grouping projection."
484. Diff:
485. ```diff
486. @@ C4
487. - Planning and bead regeneration input
488. + Gap grouping projection
489. + The compiler emits gap groups only.
490. + Plan-to-beads remains a later planning workflow after review convergence.
491. ```
492. Rationale: preserves no-bead constraint.
493. Rationale: respects planning-workflow sequencing.
494. Impact: cleaner phase boundary.
495. Score effect: +0.07.

## 16. Proposed Change 8 - C5 Emits Contracts, Not Actions

496. Finding: C5 lists dispatch fields and loop gates as if compiler enforces them.
497. Contested lines: `00-PLAN-INPUT.md:169-182`.
498. Risk: compiler becomes dispatcher.
499. Recommendation: make C5 output consumer contracts.
500. Diff:
501. ```diff
502. @@ C5
503. - Dispatch contract and loop reenable gate
504. + Consumer contract projection
505. + The compiler emits facts and required gates.
506. + Dispatch and loop substrates enforce those gates.
507. ```
508. Rationale: separates projection from control.
509. Impact: cleaner integration with manager-loop.
510. Score effect: +0.09.

## 17. Proposed Change 9 - Add Scoring Formula

511. Finding: success criteria name coverage but no score formula.
512. Contested lines: `00-PLAN-INPUT.md:294-316`.
513. Risk: every reviewer invents score semantics.
514. Recommendation: add initial score.
515. Diff:
516. ```diff
517. @@ Success criteria
518. + coverage_score = sum(row.weight * row.coverage_state_value) / sum(row.weight)
519. + hard caps: dirty_unclassified, validator_conflict, missing_ledger,
520. + stale_evidence, and legacy_unmapped.
521. + row values: covered=1.0, partial=0.5, blocked=0.25, gap=0.0.
522. ```
523. Rationale: measurable.
524. Impact: prevents vibes-based coverage.
525. Score effect: +0.12.

## 18. Proposed Change 10 - Add Freshness Policy

526. Finding: evidence freshness is implied, not specified.
527. Contested lines: `00-PLAN-INPUT.md:304-309`.
528. Risk: stale evidence counts forever.
529. Recommendation: add freshness policy.
530. Diff:
531. ```diff
532. @@ Success criteria
533. + Freshness:
534. + - loop reenable requires same-tick matrix or explicit fresh receipt
535. + - dispatch selection requires matrix generated within the current tick window
536. + - human reports may display older matrices if marked stale
537. ```
538. Rationale: prevents delayed feedback from governing live loops.
539. Impact: better loop safety.
540. Score effect: +0.08.

## 19. Proposed Change 11 - Answer Open Questions By Default

541. Finding: open questions are too open for review lane execution.
542. Contested lines: `00-PLAN-INPUT.md:352-362`.
543. Risk: next reviewers repeat this review instead of refining.
544. Recommendation: convert each to default answer plus review challenge.
545. Diff:
546. ```diff
547. @@ Open questions
548. - Is dirty-state classification a hard global blocker or row-local cap?
549. + Default: global green cap plus row-local evidence cap.
550. + Review challenge: find a counterexample.
551. ```
552. Rationale: Joshua taste favors strong defaults.
553. Impact: better convergence.
554. Score effect: +0.08.

## 20. Proposed Change 12 - Expand Canonical CLI Contract

555. Finding: CLI shape lacks required canonical surfaces.
556. Contested lines: `00-PLAN-INPUT.md:224-236`.
557. Risk: MVP ships as script, not operator substrate.
558. Recommendation: add MVP and post-MVP split.
559. Diff:
560. ```diff
561. @@ Canonical CLI shape
562. + MVP: compile, validate, schema, explain.
563. + Required flags: --json, --markdown, --dry-run, --no-color, --no-emoji.
564. + Post-MVP: doctor, health, repair, audit, why, examples, quickstart, completion.
565. + All outputs carry schema_version and generated_at.
566. ```
567. Rationale: canonical-cli-scoping.
568. Impact: easier acceptance gates.
569. Score effect: +0.10.

## 21. Proposed Change 13 - Add Replay Fixture

570. Finding: mobile-eats is cited as seed but not yet a test fixture.
571. Contested lines: `00-PLAN-INPUT.md:13-24`.
572. Risk: plan cannot prove it catches the originating failure.
573. Recommendation: require replay.
574. Diff:
575. ```diff
576. @@ Ship order
577. + Before any fleet rollout, replay mobile-eats evidence and assert:
578. + mission_compression=true, false_bead_confidence=true,
579. + missing_coverage_ledger=true, and green_verdict=false.
580. ```
581. Rationale: origin failure becomes regression fixture.
582. Impact: strong publishability.
583. Score effect: +0.11.

## 22. Proposed Change 14 - Make Markdown A Renderer

584. Finding: the plan's artifact language mixes JSON and markdown authority.
585. Contested lines: `00-PLAN-INPUT.md:224-236`.
586. Risk: humans edit markdown and diverge from JSON.
587. Recommendation: JSON is canonical.
588. Diff:
589. ```diff
590. @@ Jeff lens
591. + JSON is canonical.
592. + Markdown is generated from JSON.
593. + Markdown carries source matrix hash.
594. + Direct markdown edits are non-authoritative.
595. ```
596. Rationale: Jeff-corpus pattern favors deterministic generated reports.
597. Impact: avoids docs drift.
598. Score effect: +0.06.

## 23. Proposed Change 15 - Add Explicit Non-Goals

599. Finding: out-of-scope is good but not sharp enough for implementation.
600. Contested lines: `00-PLAN-INPUT.md:329-338`.
601. Risk: new substrate accretion.
602. Recommendation: add non-goals.
603. Diff:
604. ```diff
605. @@ Out of scope
606. + Non-goals:
607. + - no new issue database
608. + - no new dispatch scheduler
609. + - no new fuckup-log
610. + - no new docs source of truth
611. + - no automatic bead mutation in MVP
612. ```
613. Rationale: keeps scope tight.
614. Impact: protects plan quality.
615. Score effect: +0.05.

## 24. Architecture After Revisions

616. Revised architecture has five layers.
617. Layer 1: source substrates.
618. Source substrate: MISSION.md.
619. Source substrate: `.beads/issues.jsonl`.
620. Source substrate: closed-bead artifact scan.
621. Source substrate: dispatch-log.
622. Source substrate: fuckup-log.
623. Source substrate: doctor outputs.
624. Source substrate: validator outputs.
625. Source substrate: git status.
626. Layer 2: compiler adapters.
627. Adapter: mission anchor reader.
628. Adapter: bead issue reader.
629. Adapter: closure claim reader.
630. Adapter: failure class reader.
631. Adapter: repo state reader.
632. Layer 3: canonical matrix.
633. Matrix field: schema version.
634. Matrix field: repo identity.
635. Matrix field: generated at.
636. Matrix field: source hashes.
637. Matrix field: rows.
638. Matrix field: summary.
639. Matrix field: caps.
640. Layer 4: renderers.
641. Renderer: JSON canonical.
642. Renderer: Markdown human.
643. Renderer: manager-loop summary.
644. Renderer: dispatch gate summary.
645. Layer 5: consumers.
646. Consumer: manager-loop.
647. Consumer: fleet-autonomy.
648. Consumer: closed-bead audit.
649. Consumer: loop reenable gate.
650. Consumer: review lanes.
651. This architecture preserves existing primitives.
652. It adds one deterministic projection.
653. It does not add another state owner.
654. That is the revision target.

## 25. Publishability Review

655. Public publishability is high after redaction.
656. The story is clear.
657. Problem: work trackers can falsely imply mission completion.
658. Evidence: mobile-eats chore churn.
659. Solution: compile mission coverage from claims and proof.
660. Audience: operators of agentic coding systems.
661. Risk: internal names and client contexts.
662. Redact: Joshua.
663. Redact: mobile-eats.
664. Redact: alpsinsurance.
665. Redact: skillos.
666. Generalize: "repo A", "repo B", "fleet orchestrator".
667. Keep: mission compression.
668. Keep: false bead confidence.
669. Keep: missing coverage ledger.
670. Keep: closed beads are claims.
671. Keep: docs must be load-bearing.
672. Keep: JSON canonical, markdown renderer.
673. Remove: private paths.
674. Remove: Nango owner-custody detail.
675. Remove: internal pane names.
676. With those redactions, public score is 9.5.
677. Without those redactions, public score is 8.3.
678. Publishability does not drive implementation now.
679. It confirms the idea is general.

## 26. Joshua-Taste Review

680. This plan avoids most slop.
681. It does not say "maybe".
682. It does not ask permission.
683. It does not apologize.
684. It does not narrate agent busyness as value.
685. It does not hide behind process.
686. It says bead state can be false.
687. That is good.
688. It does have some abstraction bloat.
689. "Compiler" is a useful noun.
690. "Mission coverage matrix" is a useful noun.
691. "Failure ledger miner" is too expansive.
692. "Planning and bead regeneration input" is too mushy.
693. "Dispatch contract and loop reenable gate" is too much ownership.
694. Joshua-taste revision: shorter names, harder boundaries.
695. Use `gap_projection`.
696. Use `coverage_projection`.
697. Use `claim_audit_adapter`.
698. Use `consumer_contracts`.
699. Do not call a row a "surface" and "mission surface" interchangeably without schema.
700. Pick `surface`.
701. Define it.
702. Do not call "green verdict" without enum.
703. Define verdict enum.
704. Proposed enum: `green`, `yellow`, `red`, `unknown`.
705. Proposed cap enum: `none`, `dirty`, `stale`, `conflict`, `missing_ledger`.
706. This is more Joshua-compatible.

## 27. Risk Register

707. Risk 1: compiler becomes a second planning system.
708. Mitigation: read-only MVP.
709. Risk 2: compiler duplicates closed-bead audit.
710. Mitigation: consume scan output.
711. Risk 3: matrix becomes stale.
712. Mitigation: freshness policy.
713. Risk 4: markdown diverges from JSON.
714. Mitigation: markdown renderer only.
715. Risk 5: row IDs churn.
716. Mitigation: stable surface IDs.
717. Risk 6: scoring gets gamed.
718. Mitigation: hard caps and weighted rows.
719. Risk 7: old closed beads all become noise.
720. Mitigation: `legacy_unmapped` bucket and sample audit.
721. Risk 8: validator split brain stays social.
722. Mitigation: row conflict state.
723. Risk 9: manager-loop consumes too much detail.
724. Mitigation: summary projection.
725. Risk 10: fleet-autonomy blocks on compiler.
726. Mitigation: advisory mode before hard gate.
727. Risk 11: docs proof becomes checkbox.
728. Mitigation: doc proof must cite load-bearing claim.
729. Risk 12: dirty-state cap freezes all progress.
730. Mitigation: row-local cap plus global verdict cap.
731. Risk 13: C3 mines logs forever.
732. Mitigation: known classes only in MVP.
733. Risk 14: no replay.
734. Mitigation: mobile-eats replay fixture.
735. Risk 15: no owner.
736. Mitigation: compiler owner is flywheel-loop command doctrine.

## 28. Revised Ship Order

737. Step 1: integrate this review and the Donella/Jeff reviews.
738. Step 2: freeze schema v0.1 in the plan.
739. Step 3: define row IDs, reason codes, caps, and verdict enum.
740. Step 4: define source adapters.
741. Step 5: define mobile-eats replay fixture.
742. Step 6: implement read-only JSON compiler.
743. Step 7: implement schema validation.
744. Step 8: implement markdown renderer from JSON.
745. Step 9: run replay fixture.
746. Step 10: add closed-bead scan adapter.
747. Step 11: add known failure-class adapter.
748. Step 12: add manager-loop summary projection.
749. Step 13: add dispatch validator projection.
750. Step 14: add loop reenable projection.
751. Step 15: run four-repo audit.
752. Step 16: only then create beads.
753. This order differs from `00-PLAN-INPUT.md:366-371`.
754. It splits schema from build.
755. It splits build from consumers.
756. It delays gates until replay passes.
757. It preserves momentum.

## 29. Final Scorecard

758. Planning-workflow conformance before revision: 9.0.
759. Planning-workflow conformance after revision: 9.6.
760. Paradigm soundness before revision: 9.1.
761. Paradigm soundness after revision: 9.5.
762. Joshua taste before revision: 9.2.
763. Joshua taste after revision: 9.7.
764. Public publishability before redaction: 8.3.
765. Public publishability after revision/redaction: 9.5.
766. Composite after revision: 9.58.
767. Confidence: high.
768. Verdict: revise.
769. Keep/revise/reject: revise.
770. Recommended next phase: integrate revisions.
771. Do not convert to beads yet.
772. Do not ask Joshua.
773. Do not implement source.
774. Do not mutate bead DB.
775. Do not create a new skill yet.
776. Do not merge into fleet-autonomy-v1.
777. Do not merge into manager-loop.
778. Do feed manager-loop after JSON projection exists.
779. Do feed fleet-autonomy after advisory mode works.
780. Do require mobile-eats replay.
781. Do add schema.
782. Do add reason codes.
783. Do add deterministic ordering.
784. Do add CLI exit codes.
785. Do make markdown generated.
786. Do keep the central paradigm.

## 30. Appendix - Socraticode And Skill Evidence

787. Jeff-corpus query 01: read-only compiler, JSON, markdown, schema, doctor, validate, explain, dry-run.
788. Useful hit: `meta_skill/tests/e2e/import_workflow.rs`, dry-run parses and reports without writing.
789. Useful hit: `frankenlibc/scripts/check_validation_dashboard.sh`, dry-run JSON and markdown gate.
790. Useful hit: `remote_compilation_helper` reliability doctor tests, schema and remediation.
791. Jeff-corpus query 02: mission coverage matrix, ledger, artifact, test, doc proof.
792. Useful hit: `franken_node/tests/policy_e2e_evidence_matrix.rs`, matrix rows require evidence and rejection.
793. Useful hit: `franken_engine/docs/claim_to_proof_matrix_v1.json`, claims map to artifacts and verification commands.
794. Useful hit: `frankenlibc/scripts/generate_feature_parity_gap_ledger.py`, machine artifact gap ledger.
795. Jeff-corpus query 03: thin compositor, existing primitives, logs, claims, evidence.
796. Useful hit: `frankenterm` telemetry aggregator, not a wire-format change.
797. Useful hit: `frankensqlite` evidence ownership rerun entrypoints.
798. Jeff-corpus query 04: PageRank, robot triage, br, bv.
799. Useful hit: multiple AGENTS files define `bv --robot-triage` as graph-aware triage.
800. Useful hit: `agent_flywheel_clawdbot` skill says use BV instead of raw beads JSON.
801. Jeff-corpus query 05: canonical CLI, doctor, health, repair, schema, robot JSON.
802. Useful hit: `ntm/docs/robot-api-design.md`, schemas for robot outputs.
803. Useful hit: `coding_agent_session_search/src/lib.rs`, health and doctor JSON.
804. Jeff-corpus query 06: closed issue claim audit, validation, artifact proof.
805. Useful hit: `franken_node/docs/specs/durable_claim_requirements.md`, fail-closed proof gate.
806. Useful hit: `franken_node/scripts/check_proof_carrying_execution_ledger.py`, closed issue proof counts.
807. Jeff-corpus query 07: dispatch/failure ledger reason codes.
808. Useful hit: `franken_networkx` structured log gate rejects missing reason codes.
809. Useful hit: `frankentorch` forensic JSONL coverage summary uses reason codes.
810. Jeff-corpus query 08: state compiler, read-only aggregate, existing substrates.
811. Useful hit: `frankenterm` per-session aggregator wraps existing rows.
812. Useful hit: `frankenterm/scripts/storage_backend_callsites.py`, deterministic callsite plan.
813. Jeff-corpus query 09: markdown report from JSON schema deterministic output.
814. Useful hit: `asupersync/docs/doctor_report_export_contract.md`, deterministic JSON/markdown export.
815. Useful hit: `meta_skill` plan says SKILL.md is generated from structured spec.
816. Jeff-corpus query 10: tests validate schema, fixtures, replay, dry-run no mutation.
817. Useful hit: `eidetic_engine_cli` dry-run fixtures assert no mutation.
818. Useful hit: `asupersync` replay artifact policy requires deterministic repro commands.
819. Donella validation script passed.
820. Skill search returned 15 matches, with mission-anchor-init and socraticode most relevant.
821. This review used those findings to favor deterministic projection over new substrate.
