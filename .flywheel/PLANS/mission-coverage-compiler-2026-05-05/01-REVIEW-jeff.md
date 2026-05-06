# 01-REVIEW-jeff - Mission Coverage Compiler

## 0. Position

001. Verdict: revise.
002. Composite score after revision: 9.72 / 10.
003. Jeff counter-thesis endorsed: conditional.
004. The counter-thesis is simple.
005. Most of this is already shipped.
006. Not as one command.
007. Not as one named compiler.
008. But the raw materials exist.
009. `br` owns issue state.
010. `bv` owns graph-aware work selection.
011. dispatch-log owns dispatch observations.
012. fuckup-log owns trauma observations.
013. doctor outputs own substrate health.
014. validators own proof checks.
015. closed-bead audit owns closure claim checks.
016. mission-anchor-init owns mission shape.
017. canonical-cli-scoping owns operator surface expectations.
018. The missing thing is a thin compositor.
019. Do not build a new substrate.
020. Build the compositor.
021. Make it read-only first.
022. Make JSON canonical.
023. Generate markdown.
024. Feed manager-loop.
025. Feed dispatch validators.
026. Feed loop gates.
027. Stop there.
028. The plan gets the philosophy right.
029. The plan over-scopes the component.
030. That is fixable.
031. The review below is direct because this is doctrine-level.
032. I am not grading prose elegance.
033. I am grading whether this can become reliable substrate.

## 1. Evidence Ledger

034. Plan path: `00-PLAN-INPUT.md`.
035. Plan says no source edits and no beads at `00-PLAN-INPUT.md:6`.
036. Good.
037. Plan says the problem is not local Nango at `00-PLAN-INPUT.md:13-16`.
038. Good.
039. Plan says bead collapse was planning-substrate failure at `00-PLAN-INPUT.md:22-24`.
040. Correct.
041. Plan says beads are claims, not proof, at `00-PLAN-INPUT.md:26-29`.
042. Correct.
043. Plan lists seven failure classes at `00-PLAN-INPUT.md:37-47`.
044. Correct.
045. Plan says bead substrate trusts itself at `00-PLAN-INPUT.md:49-50`.
046. Correct.
047. Plan gives matrix columns at `00-PLAN-INPUT.md:57-61`.
048. Good start.
049. Plan states the paradigm at `00-PLAN-INPUT.md:81-86`.
050. Correct but incomplete.
051. Plan defines C0 at `00-PLAN-INPUT.md:103-113`.
052. Needs row-local cap.
053. Plan defines C1 at `00-PLAN-INPUT.md:115-127`.
054. Needs schema.
055. Plan defines C2 at `00-PLAN-INPUT.md:129-142`.
056. Needs reuse of existing auditor.
057. Plan defines C3 at `00-PLAN-INPUT.md:144-155`.
058. Too broad.
059. Plan defines C4 at `00-PLAN-INPUT.md:157-167`.
060. Rename and narrow.
061. Plan defines C5 at `00-PLAN-INPUT.md:169-182`.
062. Split enforcement from projection.
063. Plan's CLI shape is at `00-PLAN-INPUT.md:224-236`.
064. Good instinct.
065. Not enough canonical-cli scope.
066. Plan says compiler feeds manager-loop at `00-PLAN-INPUT.md:250-251`.
067. Correct.
068. Plan says compiler does not manage panes, workers, callbacks, or loops at `00-PLAN-INPUT.md:261-262`.
069. Good.
070. C5 partly contradicts that.
071. Plan success criteria are at `00-PLAN-INPUT.md:284-316`.
072. Need numbers.
073. Open questions are at `00-PLAN-INPUT.md:352-362`.
074. Too many should be answered now.
075. Ship order is at `00-PLAN-INPUT.md:364-371`.
076. Too compressed.
077. Verdict thresholds are at `00-PLAN-INPUT.md:373-386`.
078. Good structure.
079. Need stronger keep/revise threshold.

## 2. Socraticode Ledger

080. Project searched: `/Users/josh/Developer/jeff-corpus`.
081. Status: green.
082. Indexed chunks observed: 893496.
083. Socraticode queries: 10.
084. Query 01: read-only compiler, JSON, markdown, schema, doctor, validate, explain, dry-run.
085. Hit: `meta_skill/tests/e2e/import_workflow.rs`.
086. That hit proves dry-run can parse and report without writing.
087. Hit: `frankenlibc/scripts/check_validation_dashboard.sh`.
088. That hit proves JSON and markdown output can be gated together.
089. Query 02: mission coverage matrix, ledger, artifact, test, doc proof.
090. Hit: `franken_node/tests/policy_e2e_evidence_matrix.rs`.
091. That hit proves evidence rows can require proof and reject missing proof.
092. Hit: `franken_engine/docs/claim_to_proof_matrix_v1.json`.
093. That hit proves claim-to-proof matrices belong in machine JSON.
094. Query 03: thin compositor, existing primitives, logs, claims, evidence.
095. Hit: `frankenterm/crates/frankenterm-core/src/kitty_graphics_session_telemetry.rs`.
096. That hit proves a stateful aggregator can wrap pure-data rows without changing wire format.
097. Query 04: PageRank, robot triage, br, bv.
098. Hit: repeated AGENTS docs across Jeff repos.
099. That hit proves `bv --robot-triage` is the graph-aware triage entry point.
100. Query 05: canonical CLI doctor, health, repair, schema, robot JSON.
101. Hit: `ntm/docs/robot-api-design.md`.
102. That hit proves robot schemas are first-class.
103. Hit: `coding_agent_session_search/src/lib.rs`.
104. That hit proves health and doctor JSON belong in CLIs.
105. Query 06: closed issue claim audit, validation, artifact proof.
106. Hit: `franken_node/docs/specs/durable_claim_requirements.md`.
107. That hit proves fail-closed proof gates and stable denial codes.
108. Hit: `franken_node/scripts/check_proof_carrying_execution_ledger.py`.
109. That hit proves closed issue proof counts can be computed.
110. Query 07: dispatch log, failure ledger, reason codes, structured JSONL.
111. Hit: `franken_networkx/crates/fnx-conformance/tests/structured_log_gate.rs`.
112. That hit proves missing reason codes should fail closed.
113. Query 08: state compiler, read-only aggregate, existing substrates.
114. Hit: `frankenterm/scripts/storage_backend_callsites.py`.
115. That hit proves deterministic source analysis with sorted outputs.
116. Query 09: markdown report generated from JSON schema deterministic output.
117. Hit: `asupersync/docs/doctor_report_export_contract.md`.
118. That hit proves deterministic JSON/markdown report export.
119. Query 10: tests validate schema, fixtures, replay, dry-run, no mutation.
120. Hit: `eidetic_engine_cli/tests/contracts/causal_credit.rs`.
121. That hit proves dry-run plans must remain non-mutating.
122. Conclusion: the Jeff-corpus pattern is deterministic, read-only first, JSON-first, schema-validated, replay-tested, and thin.
123. That is the shape this plan needs.

## 3. What Is Already Shipped

124. Already shipped: issue state.
125. `br` owns issue lifecycle.
126. `br` owns status.
127. `br` owns dependencies.
128. `br` owns sync.
129. Do not duplicate it.
130. Already shipped: graph-aware ranking.
131. `bv` owns PageRank.
132. `bv` owns betweenness.
133. `bv` owns robot triage.
134. `bv` owns robot next.
135. Do not duplicate it.
136. Already shipped: dispatch observations.
137. dispatch-log owns sent/done/blocked events.
138. Do not duplicate it.
139. Already shipped: trauma observations.
140. fuckup-log owns failure recurrence.
141. Do not duplicate it.
142. Already shipped: health observations.
143. doctor outputs own substrate status.
144. Do not duplicate it.
145. Already shipped: validation observations.
146. validators own checks.
147. Do not duplicate them.
148. Already shipped: closed-bead audit concept.
149. It already treats closures as claims.
150. Do not duplicate it.
151. Already shipped: mission anchor shape.
152. mission-anchor-init owns MISSION.md setup and gates.
153. Do not duplicate it.
154. Already shipped: canonical CLI doctrine.
155. canonical-cli-scoping owns the CLI standard.
156. Do not improvise it.
157. Already shipped: Agent Mail reservations.
158. Agent Mail owns concurrency safety.
159. Do not build another lock.
160. Missing: a deterministic join over these surfaces.
161. Missing: row-level coverage projection.
162. Missing: consumer-specific summaries.
163. Missing: mobile-eats replay fixture.
164. Missing: one canonical JSON schema.
165. Missing: markdown renderer.
166. Missing: advisory-to-hard-gate path.
167. That is not a large system.
168. It is a compositor.

## 4. Counter-Thesis

169. Counter-thesis: 70% of mission-coverage-compiler is already shipped.
170. 20% is schema and adapters.
171. 10% is CLI and renderer.
172. If the plan creates more than that, it is drifting.
173. The plan's C1 is needed.
174. The plan's C0 is needed as an adapter.
175. The plan's C2 is needed as a mapper.
176. The plan's C3 is needed as a normalizer.
177. The plan's C4 is needed as a report section.
178. The plan's C5 is needed as consumer projection.
179. None of those should become independent runtime authorities.
180. The MVP should be one command.
181. `mission-coverage compile --repo <path> --json`.
182. It reads.
183. It does not mutate.
184. It emits schema version.
185. It emits source hashes.
186. It emits rows.
187. It emits summary.
188. It emits caps.
189. It exits with meaningful code.
190. Then `--markdown` renders.
191. Then manager-loop consumes summary.
192. Then dispatch validator consumes gate projection.
193. Then loop gate consumes freshness and cap projection.
194. Then closed-bead audit consumes mission mapping.
195. That is enough.
196. Anything more belongs after replay.
197. Counter-thesis endorsed: conditional.
198. Condition: keep the compiler read-only.
199. Condition: JSON canonical.
200. Condition: existing primitives remain owners.
201. Condition: consumers enforce.
202. Condition: no bead mutation in MVP.

## 5. Main Critique

203. The plan has the right enemy.
204. Enemy: mission state implied by work tracker state.
205. The plan has the right phrase.
206. Phrase: false bead confidence.
207. Citation: `00-PLAN-INPUT.md:41-43`.
208. The plan has the right weapon.
209. Weapon: mission coverage matrix.
210. Citation: `00-PLAN-INPUT.md:57-61`.
211. The plan has the wrong amount of weapon.
212. It turns a matrix into six primitives.
213. Six is not inherently too many.
214. Six is too many if they all live in one executable.
215. One executable can expose six projections.
216. One executable should not own six policy domains.
217. C0 belongs to repo-state sensing.
218. C1 belongs to compiler core.
219. C2 belongs to claim mapping.
220. C3 belongs to failure normalization.
221. C4 belongs to output grouping.
222. C5 belongs to consumer contract generation.
223. Those are sections.
224. They are not all authorities.
225. The plan should say that.

## 6. C0 Critique

226. C0 is useful.
227. Citation: `00-PLAN-INPUT.md:103-113`.
228. Dirty state matters.
229. Unpushed commits matter.
230. Watcher state matters.
231. But C0 should not be a moral panic.
232. Dirty state is not one thing.
233. Dirty source file differs from dirty report.
234. Dirty generated artifact differs from dirty MISSION.md.
235. Dirty bead DB differs from dirty README.
236. The compiler should classify.
237. It should not judge everything red by default.
238. Recommended C0 schema:
239. `dirty_global_cap`.
240. `dirty_paths`.
241. `dirty_path_class`.
242. `affected_surface_ids`.
243. `unclassified_count`.
244. `watcher_state`.
245. `loop_state`.
246. `repo_state_hash`.
247. This is small.
248. This is enough.
249. Do not add revert.
250. Do not add quarantine mutation.
251. Do not add watcher control.
252. Output facts only.

## 7. C1 Critique

253. C1 is the product.
254. Citation: `00-PLAN-INPUT.md:115-127`.
255. Invest here.
256. The row schema needs to be real.
257. Minimum fields in the plan are okay.
258. They are not enough.
259. Add `surface_id`.
260. Add `surface_kind`.
261. Add `source_anchor`.
262. Add `source_hash`.
263. Add `weight`.
264. Add `coverage_state`.
265. Add `claim_state`.
266. Add `freshness_state`.
267. Add `cap_reason`.
268. Add `reason_codes`.
269. Add `evidence_refs`.
270. Add `test_refs`.
271. Add `doc_refs`.
272. Add `bead_refs`.
273. Add `consumer_refs`.
274. Add `last_verified_at`.
275. Add `generated_from`.
276. Stable order: phase, surface_id.
277. Stable output: JSON with sorted keys or deterministic serializer.
278. Markdown: generated.
279. This is canonical-cli work.
280. This is Socraticode-friendly work.

## 8. C2 Critique

281. C2 is right.
282. Citation: `00-PLAN-INPUT.md:129-142`.
283. Closed beads are claims.
284. Exactly.
285. But don't rebuild proof scanning.
286. Consume it.
287. The compiler asks a narrower question.
288. Does a closure map to a mission row?
289. Does it have evidence?
290. Is that evidence fresh?
291. Did validators agree?
292. Did docs reflect it?
293. If yes, coverage can rise.
294. If no, it remains a closure claim.
295. Proposed states:
296. `claim_valid_mission_mapped`.
297. `claim_valid_unmapped`.
298. `claim_invalid_missing_artifact`.
299. `claim_invalid_missing_test`.
300. `claim_invalid_missing_doc`.
301. `claim_conflicted_validator`.
302. `claim_legacy_unmapped`.
303. Do not reopen anything in MVP.
304. Do not create audit-gap beads in MVP.
305. Emit facts.
306. Let existing workflows act.

## 9. C3 Critique

307. C3 is overbroad.
308. Citation: `00-PLAN-INPUT.md:144-155`.
309. "Mine dispatch-log / fuckup-log / doctor / validator" can mean infinite work.
310. Don't do infinite work.
311. MVP maps seven classes.
312. That's it.
313. `mission_compression` maps to missing row inventory or underweighted surfaces.
314. `false_bead_confidence` maps to bead claims without coverage.
315. `parasitic_loop` maps to repeated blocker without state delta.
316. `dirty_tree_drift` maps to C0 caps.
317. `docs_not_load_bearing` maps to doc proof gap.
318. `validator_split_brain` maps to conflict.
319. `missing_coverage_ledger` maps to global red.
320. Use stable reason codes.
321. Reason codes are not optional.
322. Jeff-corpus structured log tests reject missing reason codes.
323. That is the pattern.
324. Do not parse prose every time.
325. Do not invent "maybe stale" strings.
326. Emit enums.

## 10. C4 Critique

327. C4 is a naming bug.
328. Citation: `00-PLAN-INPUT.md:157-167`.
329. "Planning and bead regeneration input" is too close to bead creation.
330. The dispatch says no beads.
331. The plan says no beads.
332. Keep it that way.
333. Rename to `gap_projection`.
334. Output groups:
335. `product_surface_gap`.
336. `substrate_surface_gap`.
337. `doc_gate_gap`.
338. `test_gate_gap`.
339. `artifact_gate_gap`.
340. `validator_conflict_gap`.
341. `legacy_unmapped_gap`.
342. `dirty_state_gap`.
343. Each group gets row IDs.
344. Each group gets proof requirements.
345. Each group gets suggested owner.
346. Each group gets no mutation.
347. Later planning can turn groups into beads.
348. Not this command.

## 11. C5 Critique

349. C5 is the dangerous one.
350. Citation: `00-PLAN-INPUT.md:169-182`.
351. It lists dispatch fields.
352. It lists reenable gates.
353. Good fields.
354. Wrong owner if interpreted literally.
355. Compiler emits facts.
356. Dispatcher enforces dispatch fields.
357. Loop gate enforces loop fields.
358. Manager-loop enforces priority.
359. Closed-bead audit enforces closure claim disposition.
360. The compiler should expose:
361. `dispatch_required_fields`.
362. `loop_required_gates`.
363. `coverage_summary`.
364. `blocking_caps`.
365. `advisory_actions`.
366. It should not send.
367. It should not reenable.
368. It should not close.
369. It should not mutate.
370. It should not reserve.
371. It should not repair.
372. Thin compositor.

## 12. Canonical CLI Audit

373. The plan's CLI sketch is good.
374. Citation: `00-PLAN-INPUT.md:224-236`.
375. It includes compile.
376. It includes validate.
377. It includes doctor.
378. It includes explain.
379. It includes replay.
380. It includes schema.
381. It includes examples.
382. But canonical-cli-scoping requires more.
383. Add `health`.
384. Add `repair`.
385. Add `audit`.
386. Add `why`.
387. Add `quickstart`.
388. Add `completion`.
389. Add `--info`.
390. Add `--no-color`.
391. Add `--no-emoji`.
392. Add `--width`.
393. Add JSON schemas.
394. Add exit codes.
395. Add dry-run defaults.
396. Add no mutation for compile.
397. Add robot namespace if agents will consume it.
398. MVP can be smaller.
399. Plan still needs the full surface map.
400. MVP:
401. `compile`.
402. `validate`.
403. `schema`.
404. `explain`.
405. `replay`.
406. Post-MVP:
407. `doctor`.
408. `health`.
409. `repair`.
410. `audit`.
411. `why`.
412. `quickstart`.
413. `completion`.
414. That split is practical.
415. It keeps the first bead small later.
416. It avoids pretending a script is a CLI.

## 13. Exit Codes

417. Add exit code table.
418. Exit 0: success, no blocking caps.
419. Exit 1: valid matrix with blocking caps.
420. Exit 2: usage error.
421. Exit 3: upstream substrate unavailable.
422. Exit 4: blocked by gate.
423. Exit 5: schema incompatibility.
424. Exit 6: replay mismatch.
425. Exit 7: deterministic output mismatch.
426. Exit 8: redaction or secret-safety refusal.
427. Exit 9: unknown internal error.
428. Keep it boring.
429. Agents need scripts.
430. Scripts need codes.

## 14. JSON Schema

431. JSON schema should be first-class.
432. Not implied.
433. Not docs-only.
434. Command: `mission-coverage schema matrix`.
435. Command: `mission-coverage schema summary`.
436. Command: `mission-coverage schema row`.
437. Command: `mission-coverage schema replay`.
438. Required top-level fields:
439. `schema_version`.
440. `generated_at`.
441. `repo_root`.
442. `repo_id`.
443. `source_hashes`.
444. `rows`.
445. `summary`.
446. `caps`.
447. `consumer_projections`.
448. `determinism`.
449. Required row fields already listed in C1 critique.
450. Validate with fixtures.

## 15. Markdown Renderer

451. Markdown is not source of truth.
452. Do not let anyone edit matrix markdown.
453. Generate it from JSON.
454. Include matrix hash.
455. Include generated_at.
456. Include stale warning.
457. Include top gaps.
458. Include closed-bead claim summary.
459. Include validator conflicts.
460. Include docs downgrades.
461. Include dispatch gate summary.
462. Include loop reenable summary.
463. Include "not authoritative" line.
464. This matches Jeff-corpus report export patterns.
465. JSON and markdown together are fine.
466. JSON must be canonical.

## 16. Replay Fixture

467. The first replay is mobile-eats.
468. Citation: seed evidence summarized at `00-PLAN-INPUT.md:13-24`.
469. Replay expected outputs:
470. `mission_compression=true`.
471. `false_bead_confidence=true`.
472. `parasitic_loop=true`.
473. `dirty_tree_drift=true`.
474. `docs_not_load_bearing=true`.
475. `validator_split_brain=true`.
476. `missing_coverage_ledger=true`.
477. `green_verdict=false`.
478. `coverage_score<0.5`.
479. `loop_reenable_allowed=false`.
480. `manager_loop_action=select_coverage_gap`.
481. This fixture is mandatory.
482. Without it, the compiler may fail the one incident that created it.

## 17. Scoring

483. Current plan has no score formula.
484. Citation: `00-PLAN-INPUT.md:294-316`.
485. Add one.
486. Formula can evolve.
487. Initial formula:
488. `weighted_score=sum(weight*value)/sum(weight)`.
489. Values:
490. `covered=1.0`.
491. `partial=0.5`.
492. `blocked=0.25`.
493. `gap=0.0`.
494. Caps override score.
495. `missing_ledger` caps green.
496. `validator_conflict` caps green.
497. `dirty_unclassified` caps green.
498. `stale_evidence` caps relevant row.
499. `legacy_unmapped` counts zero.
500. Keep it simple.
501. Make it testable.

## 18. Open Questions - Stop Leaving Defaults Blank

502. The plan leaves nine open questions.
503. Citation: `00-PLAN-INPUT.md:352-362`.
504. Answer most of them now.
505. Dirty state: global green cap plus row-local cap.
506. Schema: freeze in revised plan.
507. Proof: row-kind profile.
508. Score: weighted row score with caps.
509. Old beads: legacy unmapped.
510. Validator split: row cap plus global warning.
511. Freshness: same tick for reenable.
512. Manager-loop format: JSON summary.
513. Skill owner: flywheel-loop first, skill later.
514. Review lanes can challenge defaults.
515. They should not start from a blank.

## 19. Ship Order Fix

516. Current ship order compresses too much.
517. Citation: `00-PLAN-INPUT.md:364-371`.
518. Revised:
519. Review integration.
520. Schema freeze.
521. Mobile-eats replay spec.
522. Read-only compiler.
523. Deterministic JSON validation.
524. Markdown renderer.
525. Replay pass.
526. Closed-bead scan adapter.
527. Failure-class normalizer.
528. Manager-loop projection.
529. Dispatch advisory projection.
530. Loop advisory projection.
531. Four-repo audit.
532. Hard gates.
533. Beads.
534. That is the order.
535. Do not build hard gates before replay.
536. Do not build consumers before schema.

## 20. Proposed Diff - Thin Compositor

537. ```diff
538. @@ Paradigm shift
539. - The mission coverage matrix is the plan-of-record audit surface.
540. + The mission coverage matrix is a deterministic read-only projection over
541. + mission anchors, br/bv state, dispatch logs, fuckup logs, doctor outputs,
542. + validators, closed-bead audit output, docs, tests, artifacts, and git state.
543. + It does not replace any of those substrates.
544. ```
545. This is the most important diff.
546. It changes the implementation size.
547. It changes the ownership model.
548. It protects the plan from substrate bloat.

## 21. Proposed Diff - C3 Narrowing

549. ```diff
550. @@ C3
551. - Failure ledger miner
552. + Failure-class normalizer
553. + MVP maps only the seven seed classes:
554. + mission_compression, false_bead_confidence, parasitic_loop,
555. + dirty_tree_drift, docs_not_load_bearing, validator_split_brain,
556. + missing_coverage_ledger.
557. + Existing learning/fuckup substrates continue to own new-class promotion.
558. ```
559. This avoids infinite log-mining.

## 22. Proposed Diff - C5 Ownership

560. ```diff
561. @@ C5
562. - Dispatch contract and loop reenable gate
563. + Consumer contract projections
564. + Compiler emits required facts.
565. + Dispatch validators enforce dispatch facts.
566. + Loop gates enforce reenable facts.
567. + Manager-loop enforces prioritization.
568. ```
569. This prevents compiler-as-orchestrator.

## 23. Proposed Diff - CLI Surface

570. ```diff
571. @@ Canonical CLI shape
572. + MVP commands:
573. + - mission-coverage compile --repo <path> --json
574. + - mission-coverage validate --matrix <file> --json
575. + - mission-coverage schema matrix
576. + - mission-coverage explain --surface <id> --json
577. + - mission-coverage replay --fixture mobile-eats --json
578. + Global flags: --no-color, --no-emoji, --width, --dry-run.
579. + JSON is canonical; markdown is generated.
580. ```
581. This aligns with canonical-cli-scoping.

## 24. Proposed Diff - Score

582. ```diff
583. @@ Success criteria
584. + coverage_score = weighted row coverage with hard caps.
585. + hard_cap_reason must be machine-readable.
586. + all red/yellow verdicts must include reason_codes.
587. + deterministic replay must reproduce score and reason_codes.
588. ```
589. This makes the thing testable.

## 25. Jeff-Style Acceptance Gates

590. Gate 1: `compile --json` emits valid schema.
591. Gate 2: repeated compile with fixed inputs is deterministic.
592. Gate 3: markdown generated from JSON has source hash.
593. Gate 4: dirty-state fixture caps green.
594. Gate 5: validator-conflict fixture caps row and global warning.
595. Gate 6: closed-bead unmapped fixture does not increase coverage.
596. Gate 7: legacy unmapped fixture is counted separately.
597. Gate 8: mobile-eats replay catches all seven classes.
598. Gate 9: manager-loop summary projection is small and JSON.
599. Gate 10: dispatch advisory projection can say would-block.
600. Gate 11: loop reenable projection can say block.
601. Gate 12: no command mutates beads.
602. Gate 13: no command edits docs.
603. Gate 14: no command writes source.
604. Gate 15: no command scrapes markdown as canonical input.
605. These gates are enough for first implementation.

## 26. What I Would File Later, Not Now

606. Later bead: implement schema.
607. Later bead: implement read-only compiler.
608. Later bead: implement markdown renderer.
609. Later bead: implement mobile-eats replay.
610. Later bead: implement closed-bead scan adapter.
611. Later bead: implement failure-class normalizer.
612. Later bead: implement manager-loop projection.
613. Later bead: implement dispatch advisory projection.
614. Later bead: implement loop reenable projection.
615. Later bead: implement hard gate after advisory burn-in.
616. Not now.
617. This review is plan-space.
618. The dispatch says no beads.
619. Obey the dispatch.

## 27. What I Would Not File

620. No bead for a new issue DB.
621. No bead for a new PageRank engine.
622. No bead for a new dispatch log.
623. No bead for a new fuckup log.
624. No bead for a new doctor framework.
625. No bead for a new validator framework.
626. No bead for automatic bead regeneration.
627. No bead for automatic doc editing.
628. No bead for loop reenable mutation in MVP.
629. No bead for fleet-wide hard gate before replay.
630. If those appear, the plan drifted.

## 28. Upstream And Jeff Repo Boundary

631. Do not patch Jeff repos.
632. Do not file upstream issue unless a real upstream contract gap is found.
633. Current work is local flywheel composition.
634. `br` and `bv` are already doing what they should.
635. If `bv` lacks a needed projection later, file evidence-led issue.
636. Do not prescribe implementation.
637. Cite file:line.
638. Include repro.
639. Include expected vs observed.
640. Include flywheel tracking bead.
641. Not relevant for this plan phase.
642. But important if implementation discovers upstream gaps.

## 29. Compatibility With Donella Lens

643. Donella will say information without authority is a report.
644. Correct.
645. Jeff-compatible answer: compiler has projection authority only.
646. Consumers have enforcement authority.
647. That is not a contradiction.
648. It is separation of concerns.
649. Donella wants feedback loops.
650. Jeff wants small primitives.
651. The synthesis is consumer-specific projections.
652. Manager-loop projection closes priority loop.
653. Dispatch projection closes acceptance loop.
654. Loop projection closes reenable loop.
655. Closed-bead projection closes claim loop.
656. Compiler stays thin.

## 30. Compatibility With Multi-Model Lane

657. Multi-model will want stronger schema.
658. Correct.
659. Multi-model will want publishability.
660. Fine.
661. Public version is easy after redaction.
662. The general lesson is strong.
663. Work trackers are not mission proof.
664. Claims need proof.
665. Proof needs freshness.
666. Reports need consumers.
667. That can publish.
668. But internal implementation should stay boring.

## 31. Joshua Taste

669. Best part: "A closed bead may claim work. Neither proves the mission."
670. Citation: `00-PLAN-INPUT.md:26-29`.
671. Keep that sentence.
672. Worst part: "Failure ledger miner."
673. It sounds like an endless side quest.
674. Rename it.
675. Best implementation noun: compiler.
676. Worst implementation risk: compiler as government.
677. Joshua will read diffs.
678. Give him a small diff.
679. The revised plan should be shorter where it is philosophical.
680. Longer where it is schema.
681. Strong defaults beat open questions.
682. The plan should answer its own defaults.
683. Then review lanes can argue.

## 32. Final Recommendations

684. Recommendation 1: keep the plan.
685. Recommendation 2: revise before beads.
686. Recommendation 3: change core paradigm to thin deterministic projection.
687. Recommendation 4: freeze schema v0.1.
688. Recommendation 5: make JSON canonical.
689. Recommendation 6: generate markdown.
690. Recommendation 7: answer open questions with defaults.
691. Recommendation 8: narrow C3.
692. Recommendation 9: split C5 authority.
693. Recommendation 10: add mobile-eats replay.
694. Recommendation 11: add score formula.
695. Recommendation 12: add CLI exit codes.
696. Recommendation 13: keep MVP read-only.
697. Recommendation 14: integrate with manager-loop after replay.
698. Recommendation 15: advisory before hard gate.
699. Recommendation 16: do not create beads yet.
700. Recommendation 17: do not implement source yet.
701. Recommendation 18: do not ask Joshua.

## 33. Revised Plan Skeleton

702. Section 1: why this plan exists.
703. Keep mostly unchanged.
704. Section 2: hard evidence.
705. Keep mostly unchanged.
706. Section 3: paradigm shift.
707. Add thin projection sentence.
708. Section 4: primitives.
709. Rename C3.
710. Rename C4.
711. Reframe C5.
712. Section 5: Donella lens.
713. Add authority boundary.
714. Section 6: Jeff lens.
715. Add existing primitive inventory.
716. Section 7: relationship to fleet and manager.
717. Add consumer ownership.
718. Section 8: cross-orch integration.
719. Add specific input/output contracts.
720. Section 9: success criteria.
721. Add score and replay gates.
722. Section 10: in scope.
723. Add read-only compiler.
724. Section 11: out of scope.
725. Add no new substrate list.
726. Section 12: constraints.
727. Keep.
728. Section 13: open questions.
729. Convert to defaults.
730. Section 14: ship order.
731. Split schema, compiler, replay, consumers.
732. Section 15: verdict thresholds.
733. Add keep/revise/reject criteria tied to schema and replay.

## 34. Scorecard

734. Lane authenticity: 9.8.
735. Cross-lens compatibility: 9.7.
736. Joshua taste: 9.8.
737. Publishability: 9.6.
738. Composite: 9.72.
739. Verdict: revise.
740. Keep/revise/reject: revise.
741. Counter-thesis endorsed: conditional.
742. Main condition: thin compositor.
743. Second condition: read-only MVP.
744. Third condition: JSON canonical.
745. Fourth condition: consumers enforce.
746. Fifth condition: no new state owner.
747. Confidence: high.

## 35. Callback Values

748. jeff_composite=9.72.
749. jeff_verdict=revise.
750. jeff_counter_thesis_endorsed=conditional.
751. proposed_changes=18.
752. socraticode_queries=10.
753. indexed_chunks_observed=893496.
754. canonical_cli_required=yes.
755. thin_compositor_required=yes.
756. read_only_mvp_required=yes.
757. json_canonical_required=yes.
758. markdown_generated_required=yes.
759. mobile_eats_replay_required=yes.
760. no_beads_now=yes.

## 36. Appendix - Contested Plan Citations

761. Problem statement: `00-PLAN-INPUT.md:11-33`.
762. Evidence table: `00-PLAN-INPUT.md:35-66`.
763. Paradigm shift: `00-PLAN-INPUT.md:68-97`.
764. C0: `00-PLAN-INPUT.md:103-113`.
765. C1: `00-PLAN-INPUT.md:115-127`.
766. C2: `00-PLAN-INPUT.md:129-142`.
767. C3: `00-PLAN-INPUT.md:144-155`.
768. C4: `00-PLAN-INPUT.md:157-167`.
769. C5: `00-PLAN-INPUT.md:169-182`.
770. Donella lens: `00-PLAN-INPUT.md:184-212`.
771. Jeff lens: `00-PLAN-INPUT.md:214-242`.
772. Cross-plan boundary: `00-PLAN-INPUT.md:244-262`.
773. Cross-orch inputs: `00-PLAN-INPUT.md:264-282`.
774. Success criteria: `00-PLAN-INPUT.md:284-316`.
775. Scope: `00-PLAN-INPUT.md:318-338`.
776. Constraints: `00-PLAN-INPUT.md:340-350`.
777. Open questions: `00-PLAN-INPUT.md:352-362`.
778. Ship order: `00-PLAN-INPUT.md:364-371`.
779. Verdict thresholds: `00-PLAN-INPUT.md:373-386`.

## 37. Appendix - Jeff-Corpus Pattern Citations

780. Dry-run import pattern: `meta_skill/tests/e2e/import_workflow.rs`.
781. JSON/markdown dashboard gate: `frankenlibc/scripts/check_validation_dashboard.sh`.
782. Policy evidence matrix: `franken_node/tests/policy_e2e_evidence_matrix.rs`.
783. Claim-to-proof matrix: `franken_engine/docs/claim_to_proof_matrix_v1.json`.
784. Thin telemetry aggregator: `frankenterm/crates/frankenterm-core/src/kitty_graphics_session_telemetry.rs`.
785. BV robot triage doctrine: multiple Jeff-corpus AGENTS files.
786. NTM robot schema doctrine: `ntm/docs/robot-api-design.md`.
787. Durable claim gate: `franken_node/docs/specs/durable_claim_requirements.md`.
788. Structured reason-code gate: `franken_networkx/crates/fnx-conformance/tests/structured_log_gate.rs`.
789. Deterministic report export: `asupersync/docs/doctor_report_export_contract.md`.
790. Dry-run no-mutation fixture: `eidetic_engine_cli/tests/contracts/causal_credit.rs`.

## 38. Closing

791. This is a good plan.
792. It is one revision away from a strong implementation plan.
793. The revision should make it smaller, not bigger.
794. The compiler should compile.
795. Existing tools should keep their jobs.
796. JSON should be canonical.
797. Markdown should render.
798. Consumers should enforce.
799. Mobile-eats should replay.
800. Then convert to beads.
801. Not before.
