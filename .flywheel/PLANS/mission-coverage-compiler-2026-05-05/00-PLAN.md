# 00-PLAN - Mission Coverage Compiler

Date: 2026-05-05
Status: integrated revision after multi-model, Donella, and Jeff review
Input: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/00-PLAN-INPUT.md`
Reviews: `01-REVIEW-multi-model.md`, `01-REVIEW-donella.md`, `01-REVIEW-jeff.md`
Disposition: revise and keep
Final primitive count: 5
NEW primitives: 2
COMPOSITION-not-NEW primitives: 3
Counter-thesis disposition: partial

---

## 1. Why This Plan Exists

001. Mobile-eats exposed a planning substrate failure, not a local owner-custody bug.
002. The input packet says the seed belonged in flywheel as its own mission-coverage plan input.
003. The input packet explicitly says not to fold it into fleet-autonomy-v1 watcher scope.
004. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/00-PLAN-INPUT.md:13-16`.
005. The immediate failure was concrete.
006. Watchers were disabled.
007. The loop marker was false.
008. Joshua manually stopped automation after 59 chore commits and 0 mission progress.
009. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/00-PLAN-INPUT.md:18-20`.
010. The deeper failure was not that a bead remained open.
011. The deeper failure was that bead state had become a proxy for mission truth.
012. The active bead DB collapsed to two open beads.
013. That collapse was interpreted as near-completion.
014. It was actually a planning-substrate failure.
015. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/00-PLAN-INPUT.md:22-24`.
016. The compiler exists to end that proxy failure.
017. A bead tracks work.
018. A ready bead claims work is available.
019. A closed bead claims work happened.
020. None of those claims prove mission coverage.
021. Mission coverage requires artifacts, tests, docs, metrics, validators, repo state, and freshness.
022. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/00-PLAN-INPUT.md:26-29`.
023. The three causal terms are non-negotiable.
024. First term: `mission_compression`.
025. Second term: `false_bead_confidence`.
026. Third term: `missing_coverage_ledger`.
027. These are not slogans.
028. They are the causal chain to compile against.
029. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/00-PLAN-INPUT.md:31-33`.
030. The revised plan keeps the input diagnosis.
031. It reduces the implementation shape.
032. It accepts the Jeff counter-thesis in substance.
033. Most substrate already exists.
034. The new thing is not a replacement tracker.
035. The new thing is a deterministic compiler over existing truth surfaces.
036. The compiler is read-only in MVP.
037. JSON is canonical.
038. Markdown is generated.
039. Consumers enforce.
040. The compiler does not own panes.
041. The compiler does not own beads.
042. The compiler does not own loop reenabling.
043. The compiler does not own docs edits.
044. The compiler owns projection authority.
045. Projection authority means: given the inputs, this is the matrix.
046. Projection authority does not mean: take action.
047. This distinction is the center of the revision.
048. Without it, the plan becomes substrate bloat.
049. With it, the plan becomes a thin compositor.
050. This plan is the handoff from review convergence to later beadable work.

## 2. Hard Evidence

051. Seed class 1 is `mission_compression`.
052. Evidence: M1-M4 collapsed to one visible blocker.
053. Compiler obligation: enumerate mission surfaces before selecting work.
054. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/00-PLAN-INPUT.md:37-43`.
055. Seed class 2 is `false_bead_confidence`.
056. Evidence: `br ready=2` looked reassuring while mission proof was missing.
057. Compiler obligation: treat ready and closed counts as claims.
058. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/00-PLAN-INPUT.md:41-43`.
059. Seed class 3 is `parasitic_loop`.
060. Evidence: repeated blocker motion happened without new information.
061. Compiler obligation: make blocker churn reduce coverage confidence.
062. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/00-PLAN-INPUT.md:43`.
063. Seed class 4 is `dirty_tree_drift`.
064. Evidence: 201 dirty entries and 38 unpushed commits.
065. Compiler obligation: start from repo reality and cap unsupported green.
066. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/00-PLAN-INPUT.md:44`.
067. Seed class 5 is `docs_not_load_bearing`.
068. Evidence: docs were not enforced as gates.
069. Compiler obligation: doc proof must sit beside artifact and test proof.
070. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/00-PLAN-INPUT.md:45`.
071. Seed class 6 is `validator_split_brain`.
072. Evidence: SAFE_TO_CLOSE and BLOCK_CLOSE disagreed.
073. Compiler obligation: validator contradiction becomes a typed row conflict.
074. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/00-PLAN-INPUT.md:46`.
075. Seed class 7 is `missing_coverage_ledger`.
076. Evidence: there was no mission surface matrix.
077. Compiler obligation: build the canonical ledger.
078. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/00-PLAN-INPUT.md:47`.
079. The meta-class is bead self-trust.
080. The bead substrate trusted itself without mission grounding.
081. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/00-PLAN-INPUT.md:49-50`.
082. The input proposed nine steps.
083. Freeze.
084. Dirty-tree triage.
085. Matrix compilation.
086. Closed-bead claim audit.
087. Failure ledger mining.
088. Jeff planning.
089. Meadows analysis.
090. Bead regeneration input.
091. Dispatch contract and loop reenable gate.
092. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/00-PLAN-INPUT.md:52-61`.
093. The review lanes agree the nine steps should not become nine new authorities.
094. Multi-model recommends stating the thin-compositor paradigm.
095. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-multi-model.md:409-427`.
096. Donella identifies the invisible structure as `coverage_without_authority`.
097. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-donella.md:430-462`.
098. Jeff says most raw materials already exist and the missing thing is a thin compositor.
099. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:3-34`.
100. Socraticode repo-local survey found the closed-bead artifact scanner already tests missing artifacts, failed commands, non-executable files, invalid schemas, and valid closures.
101. Existing primitive path: `/Users/josh/Developer/flywheel/.flywheel/scripts/closed-bead-artifact-scan.py`.
102. Existing test path: `/Users/josh/Developer/flywheel/tests/closed-bead-artifact-scan.sh`.
103. Socraticode repo-local survey found callback validation doctrine already treats callbacks as claims until validated.
104. Existing primitive path: `/Users/josh/Developer/flywheel/.flywheel/scripts/validate-callback.py`.
105. Existing primitive path: `/Users/josh/Developer/flywheel/.flywheel/scripts/validate-callback-before-close.sh`.
106. Socraticode repo-local survey found idle state and watcher probes already own loop/driver truth.
107. Existing primitive path: `/Users/josh/Developer/flywheel/.flywheel/scripts/idle-state-probe.sh`.
108. Existing primitive path: `/Users/josh/Developer/flywheel/.flywheel/scripts/fleet-watcher-coverage-probe.sh`.
109. Socraticode repo-local survey found mission-anchor dispatch licensing already emits mission-aligned dispatch lists.
110. Existing primitive path: `/Users/josh/Developer/flywheel/.flywheel/scripts/mission-anchor-dispatch-license.sh`.
111. Socraticode repo-local survey found fuckup coverage join already counts missing route and missing mechanism classes.
112. Existing primitive path: `/Users/josh/Developer/flywheel/.flywheel/scripts/fuckup-coverage-join.sh`.
113. Socraticode Jeff-corpus survey found a repeatable pattern.
114. Pattern: read-only first.
115. Pattern: JSON canonical.
116. Pattern: schema validated.
117. Pattern: markdown generated.
118. Pattern: replay tested.
119. Pattern: deterministic output.
120. Pattern: stable reason codes.
121. Jeff review recorded 10 corpus searches and 893496 indexed chunks.
122. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:88-133`.
123. The revised plan follows that pattern.
124. The revised plan does not create beads.
125. The revised plan does not edit source code.
126. The revised plan does not ask Joshua.
127. This file is the only output of the integrate-revisions dispatch.

## 3. Paradigm Shift

128. Old paradigm: the issue graph is the plan of record.
129. Old paradigm: ready work implies useful next work.
130. Old paradigm: closed work implies mission progress.
131. Old paradigm: docs describe reality.
132. Old paradigm: validators can disagree until an operator reconciles them.
133. Old paradigm: loops can resume when the obvious blocker is gone.
134. Mobile-eats falsified that paradigm.
135. A small ready queue did not mean the mission was close.
136. A visible Nango blocker did not mean the rest of the mission was covered.
137. Chore commits did not mean mission progress.
138. Docs did not constrain closure.
139. Validator disagreement did not have a common row to land on.
140. The replacement paradigm is not "make a bigger tracker."
141. The replacement paradigm is "claims require mission proof."
142. The mission coverage matrix is the canonical information-flow surface.
143. It becomes a rule only where named consumers are required to obey it.
144. This directly addresses Donella's invisible structure: `coverage_without_authority`.
145. Information that reaches nobody is scenery.
146. Information that reaches authority but remains optional is advice.
147. Information that authority must obey is a rule.
148. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-donella.md:432-462`.
149. The compiler alone does not get all authority.
150. That would make a monolith.
151. The compiler gets projection authority.
152. Manager-loop gets priority authority.
153. Dispatch validators get dispatch acceptance authority.
154. Closed-bead audit gets closure claim authority.
155. Loop gates get reenable authority.
156. Docs status validators get public-claim authority.
157. This separation satisfies Donella's authority concern without violating Jeff's thin-compositor concern.
158. Donella wants information flows wired to rules.
159. Jeff wants small primitives and existing owners.
160. The synthesis is consumer-specific projections.
161. Manager-loop consumes a summary projection.
162. Dispatch validators consume required row-reference facts.
163. Closed-bead audit consumes mission mapping facts.
164. Loop gates consume freshness and cap facts.
165. Docs status validators consume doc claim facts.
166. The compiler does not send.
167. The compiler does not close.
168. The compiler does not reenable.
169. The compiler does not mutate.
170. The compiler compiles.
171. This is the core correction from the review packet.
172. This also changes the primitive count.
173. The input had six primitives.
174. The revision has five.
175. Three are COMPOSITION-not-NEW.
176. Two are NEW.
177. New substrate is limited to the schema/core and deterministic render/replay harness.
178. Everything else is adapter or projection over existing surfaces.

## 4. Atomic Primitives

179. Final primitive count: 5.
180. Primitive P0: Source Snapshot Adapter.
181. Primitive P1: Coverage Matrix Schema and Compiler Core.
182. Primitive P2: Claim and Failure Normalizer.
183. Primitive P3: Consumer Projection Layer.
184. Primitive P4: Deterministic Renderer and Replay Harness.
185. P0 is COMPOSITION-not-NEW.
186. P1 is NEW.
187. P2 is COMPOSITION-not-NEW.
188. P3 is COMPOSITION-not-NEW.
189. P4 is NEW.
190. This is smaller than the input six-primitives shape.
191. This accepts the Jeff counter-thesis partially.
192. It rejects only the strongest version of the counter-thesis.
193. Not everything already exists.
194. The canonical matrix schema does not exist.
195. The mobile-eats replay harness does not exist.
196. The deterministic renderer for this matrix does not exist.
197. But most data ownership does already exist.
198. So the plan should compose, not replace.

### P0 - Source Snapshot Adapter (COMPOSITION-not-NEW)

199. Type: COMPOSITION-not-NEW.
200. Purpose: collect source snapshots from existing substrates without changing them.
201. Input source: git status and unpushed commit state.
202. Input source: mission anchor state.
203. Input source: bead issue state.
204. Input source: dispatch log.
205. Input source: fuckup log.
206. Input source: doctor outputs.
207. Input source: validator receipts.
208. Input source: closed-bead artifact scan output.
209. Input source: idle/watcher/loop state probes.
210. Existing primitive path: `/Users/josh/Developer/flywheel/.flywheel/scripts/idle-state-probe.sh`.
211. Existing primitive path: `/Users/josh/Developer/flywheel/.flywheel/scripts/fleet-watcher-coverage-probe.sh`.
212. Existing primitive path: `/Users/josh/Developer/flywheel/.flywheel/scripts/mission-anchor-dispatch-license.sh`.
213. Existing primitive path: `/Users/josh/.claude/skills/mission-anchor-init/SKILL.md`.
214. Existing primitive path: `/Users/josh/.claude/skills/beads-br/SKILL.md`.
215. Existing primitive path: `/Users/josh/.claude/skills/beads-bv/SKILL.md`.
216. P0 replaces input C0's "freeze and repo reality snapshot" as a narrower adapter.
217. It does not freeze watchers.
218. It does not quarantine files.
219. It does not repair dirty state.
220. It records facts.
221. It classifies dirty state enough to cap rows.
222. It classifies dirty state enough to cap green verdicts.
223. It emits `repo_state_hash`.
224. It emits `dirty_global_cap`.
225. It emits `dirty_paths`.
226. It emits `dirty_path_class`.
227. It emits `affected_surface_ids`.
228. It emits `unclassified_count`.
229. It emits `watcher_state`.
230. It emits `loop_state`.
231. It emits `source_snapshot_refs`.
232. Dirty state is a global green cap when unclassified.
233. Dirty state is a row-local cap when a dirty path overlaps row evidence.
234. Dirty state is not a blackout for unrelated rows.
235. This integrates multi-model Proposed Change 4.
236. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-multi-model.md:470-487`.
237. This integrates Donella Revision 4.
238. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-donella.md:537-540`.
239. This integrates Jeff C0 critique.
240. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:246-275`.
241. Acceptance gate: P0 can run in dry-run mode on a dirty repo and still emit unaffected row facts.
242. Acceptance gate: P0 caps green when unclassified dirty state exists.
243. Acceptance gate: P0 never mutates the repo.

### P1 - Coverage Matrix Schema and Compiler Core (NEW)

244. Type: NEW.
245. Purpose: produce the canonical mission coverage matrix.
246. This is the actual product primitive.
247. It is not already shipped.
248. It owns schema versioning.
249. It owns row identity.
250. It owns deterministic row ordering.
251. It owns coverage-state computation from normalized inputs.
252. Required schema version: `mission_coverage_matrix.v0.1`.
253. Required top-level field: `schema_version`.
254. Required top-level field: `generated_at`.
255. Required top-level field: `repo_root`.
256. Required top-level field: `repo_id`.
257. Required top-level field: `source_hashes`.
258. Required top-level field: `rows`.
259. Required top-level field: `summary`.
260. Required top-level field: `caps`.
261. Required top-level field: `consumer_projections`.
262. Required top-level field: `determinism`.
263. Required row field: `surface_id`.
264. Required row field: `surface_kind`.
265. Required row field: `phase_order`.
266. Required row field: `source_anchor`.
267. Required row field: `source_hash`.
268. Required row field: `weight`.
269. Required row field: `coverage_state`.
270. Required row field: `claim_state`.
271. Required row field: `freshness_state`.
272. Required row field: `grade_cap_reason`.
273. Required row field: `reason_codes`.
274. Required row field: `evidence_refs`.
275. Required row field: `test_refs`.
276. Required row field: `doc_refs`.
277. Required row field: `bead_refs`.
278. Required row field: `consumer_refs`.
279. Required row field: `last_verified_at`.
280. Required row field: `generated_from`.
281. Rows sort by `phase_order`, then `surface_id`.
282. Empty evidence plus empty gap is invalid.
283. Stable row identity is mandatory.
284. Stable reason codes are mandatory.
285. Required reason code: `coverage_missing`.
286. Required reason code: `evidence_stale`.
287. Required reason code: `validator_conflict`.
288. Required reason code: `legacy_unmapped`.
289. Required reason code: `dirty_state_cap`.
290. Required reason code: `doc_gate_missing`.
291. Required reason code: `test_gate_missing`.
292. Required reason code: `artifact_gate_missing`.
293. Required reason code: `missing_coverage_ledger`.
294. Required reason code: `parasitic_loop`.
295. Required reason code: `false_bead_confidence`.
296. Required reason code: `mission_compression`.
297. Coverage values are boring by design.
298. `covered=1.0`.
299. `partial=0.5`.
300. `blocked=0.25`.
301. `gap=0.0`.
302. Initial score formula: `coverage_score=sum(row.weight*row.value)/sum(row.weight)`.
303. Hard caps override the numeric score.
304. Hard cap: `dirty_unclassified`.
305. Hard cap: `validator_conflict`.
306. Hard cap: `missing_ledger`.
307. Hard cap: `stale_evidence`.
308. Hard cap: `legacy_unmapped`.
309. This integrates multi-model Proposed Change 3 and 9.
310. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-multi-model.md:450-468`.
311. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-multi-model.md:564-580`.
312. This integrates Donella schema and measurement requirements.
313. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-donella.md:526-537`.
314. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-donella.md:594-612`.
315. This integrates Jeff C1, JSON schema, and scoring critique.
316. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:276-305`.
317. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:475-496`.
318. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:536-556`.
319. Acceptance gate: schema validates fixture JSON.
320. Acceptance gate: repeated compile with fixed inputs is deterministic.
321. Acceptance gate: row IDs stay stable across repeated runs.
322. Acceptance gate: missing reason codes fail validation.

### P2 - Claim and Failure Normalizer (COMPOSITION-not-NEW)

323. Type: COMPOSITION-not-NEW.
324. Purpose: normalize existing claim and failure surfaces into row states.
325. It replaces input C2 and C3 as one bounded normalizer.
326. It does not own bead closure.
327. It does not own issue state.
328. It does not own fuckup-log promotion.
329. It does not mine unlimited prose.
330. It consumes existing closed-bead scan output when available.
331. Existing primitive path: `/Users/josh/Developer/flywheel/.flywheel/scripts/closed-bead-artifact-scan.py`.
332. Existing primitive path: `/Users/josh/Developer/flywheel/.flywheel/scripts/validate-callback.py`.
333. Existing primitive path: `/Users/josh/Developer/flywheel/.flywheel/scripts/fuckup-coverage-join.sh`.
334. Existing primitive path: `/Users/josh/Developer/flywheel/.flywheel/scripts/doctor-signal-bead-promotion.sh`.
335. Existing primitive path: `/Users/josh/Developer/flywheel/.flywheel/dispatch-log.jsonl`.
336. Existing primitive path: `/Users/josh/.claude/skills/beads-br/SKILL.md`.
337. It maps closure claims to mission rows.
338. It maps closure evidence to `claim_state`.
339. It maps missing artifacts to `artifact_gate_missing`.
340. It maps missing tests to `test_gate_missing`.
341. It maps missing docs to `doc_gate_missing`.
342. It maps validator disagreement to `validator_conflict`.
343. It maps old closed beads to `legacy_unmapped`.
344. It maps proof-valid but mission-unmapped beads to `claim_valid_unmapped`.
345. It maps proof-valid and mission-mapped beads to `claim_valid_mission_mapped`.
346. It handles only seven seed failure classes in MVP.
347. Failure class: `mission_compression`.
348. Failure class: `false_bead_confidence`.
349. Failure class: `parasitic_loop`.
350. Failure class: `dirty_tree_drift`.
351. Failure class: `docs_not_load_bearing`.
352. Failure class: `validator_split_brain`.
353. Failure class: `missing_coverage_ledger`.
354. New class discovery remains owned by existing learning and fuckup substrates.
355. This integrates multi-model Proposed Change 5 and 6.
356. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-multi-model.md:489-525`.
357. This integrates Donella Revision 5 and 6.
358. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-donella.md:541-546`.
359. This integrates Jeff C2 and C3 critique.
360. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:307-357`.
361. Acceptance gate: closed bead with missing artifact cannot raise coverage.
362. Acceptance gate: valid closure without mission row becomes `claim_valid_unmapped`.
363. Acceptance gate: seed failure classes map to row blockers or explicit caps.
364. Acceptance gate: no P2 command mutates beads.

### P3 - Consumer Projection Layer (COMPOSITION-not-NEW)

365. Type: COMPOSITION-not-NEW.
366. Purpose: emit consumer-specific facts without enforcing them inside the compiler.
367. It replaces input C4 and C5 as a projection layer.
368. It also absorbs gap grouping.
369. It does not create beads.
370. It does not send dispatches.
371. It does not reenable loops.
372. It emits facts for consumers that already own authority.
373. Existing primitive path: `/Users/josh/Developer/flywheel/.flywheel/scripts/validate-callback-before-close.sh`.
374. Existing primitive path: `/Users/josh/Developer/flywheel/.flywheel/scripts/mission-anchor-dispatch-license.sh`.
375. Existing primitive path: `/Users/josh/Developer/flywheel/.flywheel/scripts/idle-state-probe.sh`.
376. Existing primitive path: `/Users/josh/Developer/flywheel/.flywheel/scripts/fleet-watcher-coverage-probe.sh`.
377. Existing primitive path: `/Users/josh/.claude/skills/beads-bv/SKILL.md`.
378. Existing primitive path: `/Users/josh/.claude/skills/canonical-cli-scoping/SKILL.md`.
379. Manager-loop projection fields: `coverage_score`.
380. Manager-loop projection fields: `red_cap_reasons`.
381. Manager-loop projection fields: `top_uncovered_rows`.
382. Manager-loop projection fields: `stale_proof_count`.
383. Manager-loop projection fields: `validator_conflict_count`.
384. Manager-loop projection fields: `recommended_consumer_action`.
385. Dispatch projection fields: `mission_row_refs_required`.
386. Dispatch projection fields: `expected_coverage_delta`.
387. Dispatch projection fields: `blocked_reason_codes`.
388. Dispatch projection fields: `would_block`.
389. Dispatch projection fields: `missing_callback_fields`.
390. Closed-bead audit projection fields: `mission_mapped_count`.
391. Closed-bead audit projection fields: `legacy_unmapped_count`.
392. Closed-bead audit projection fields: `ungrounded_closure_count`.
393. Loop projection fields: `matrix_freshness_state`.
394. Loop projection fields: `reenable_allowed`.
395. Loop projection fields: `reenable_blockers`.
396. Docs projection fields: `doc_claim_state`.
397. Docs projection fields: `docs_downgrade_count`.
398. Gap grouping fields: `gap_group`.
399. Gap grouping fields: `row_ids`.
400. Gap grouping fields: `proof_requirements`.
401. Gap grouping fields: `suggested_owner`.
402. Gap groups are not beads.
403. Later planning may turn gap groups into beads.
404. This dispatch does not.
405. This integrates multi-model Proposed Change 2, 7, and 8.
406. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-multi-model.md:429-448`.
407. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-multi-model.md:527-562`.
408. This integrates Donella authority boundary.
409. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-donella.md:430-462`.
410. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-donella.md:614-663`.
411. This integrates Jeff C4, C5, and relationship critique.
412. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:359-409`.
413. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:732-747`.
414. Acceptance gate: manager-loop never parses markdown.
415. Acceptance gate: dispatch advisory can emit `would_block=true`.
416. Acceptance gate: loop projection can emit `reenable_allowed=false`.
417. Acceptance gate: gap groups emit no mutation.

### P4 - Deterministic Renderer and Replay Harness (NEW)

418. Type: NEW.
419. Purpose: make matrix output publishable, replayable, and mechanically testable.
420. JSON remains canonical.
421. Markdown is generated from JSON.
422. Markdown carries matrix hash.
423. Markdown carries `generated_at`.
424. Markdown carries stale warning.
425. Markdown carries top gaps.
426. Markdown carries closed-bead claim summary.
427. Markdown carries validator conflicts.
428. Markdown carries docs downgrades.
429. Markdown carries dispatch advisory summary.
430. Markdown carries loop reenable summary.
431. Markdown is never edited as source of truth.
432. First replay fixture: mobile-eats.
433. Replay expected output: `mission_compression=true`.
434. Replay expected output: `false_bead_confidence=true`.
435. Replay expected output: `parasitic_loop=true`.
436. Replay expected output: `dirty_tree_drift=true`.
437. Replay expected output: `docs_not_load_bearing=true`.
438. Replay expected output: `validator_split_brain=true`.
439. Replay expected output: `missing_coverage_ledger=true`.
440. Replay expected output: `green_verdict=false`.
441. Replay expected output: `coverage_score<0.5`.
442. Replay expected output: `loop_reenable_allowed=false`.
443. Replay expected output: `manager_loop_action=select_coverage_gap`.
444. This integrates multi-model Proposed Change 13 and 14.
445. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-multi-model.md:635-668`.
446. This integrates Jeff markdown and replay critique.
447. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:498-534`.
448. Acceptance gate: replay catches all seven seed classes.
449. Acceptance gate: markdown generated from JSON includes source hash.
450. Acceptance gate: deterministic replay reproduces score and reason codes.
451. Acceptance gate: no renderer writes source.

## 5. Donella Lens Applied

452. Donella verdict: the plan is useful only if information flows into authority.
453. The hidden structure is `coverage_without_authority`.
454. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-donella.md:430-462`.
455. The revised plan makes the authority assignment explicit.
456. Compiler authority: projection.
457. Manager-loop authority: priority.
458. Dispatch validator authority: acceptance.
459. Closed-bead audit authority: closure claim disposition.
460. Loop gate authority: reenable.
461. Docs validator authority: public claim state.
462. This preserves leverage point #6 information flow.
463. This upgrades leverage point #6 into #5 rules where consumers obey it.
464. This shifts #3 goals from ready-bead drainage to mission coverage.
465. This supports #8 negative feedback against false closure.
466. This prevents #7 reinforcing loops from amplifying stale blockers.
467. Primary stock: verified mission rows.
468. Secondary stock: ungrounded closure claims.
469. Secondary stock: dirty repo state.
470. Secondary stock: blocker churn.
471. Secondary stock: validator disagreement.
472. Secondary stock: non-load-bearing docs.
473. Inflow to verified mission rows: artifact proof.
474. Inflow to verified mission rows: test proof.
475. Inflow to verified mission rows: doc proof.
476. Inflow to verified mission rows: mission metric proof.
477. Inflow to verified mission rows: valid closure proof mapped to mission row.
478. Outflow from verified mission rows: stale evidence.
479. Outflow from verified mission rows: code drift.
480. Outflow from verified mission rows: doc drift.
481. Outflow from verified mission rows: validator contradiction.
482. Outflow from verified mission rows: owner-custody blockers.
483. Required measurement 1: coverage score.
484. Required measurement 2: coverage score by row kind.
485. Required measurement 3: hard cap reason counts.
486. Required measurement 4: ungrounded closed-bead claim count.
487. Required measurement 5: legacy unmapped count.
488. Required measurement 6: validator conflict count.
489. Required measurement 7: docs downgrade count.
490. Required measurement 8: stale evidence count.
491. Required measurement 9: dispatches with mission row reference.
492. Required measurement 10: dispatches rejected for missing row reference.
493. Required measurement 11: loop reenable refusals by reason.
494. Required measurement 12: manager-loop top-10 items with coverage score input.
495. Required measurement 13: repeated blocker churn after compiler adoption.
496. Required measurement 14: ready-bead confidence mismatch count.
497. Required measurement 15: mobile-eats replay verdict.
498. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-donella.md:594-612`.
499. Anti-pattern avoided: leverage theater.
500. Reason: named consumers must read projections.
501. Anti-pattern avoided: reminder substitution.
502. Reason: row references and reason codes are machine-readable.
503. Anti-pattern avoided: human-as-feedback-loop.
504. Reason: defaults are answered without Joshua.
505. Anti-pattern avoided: grand reframe without instrumentation.
506. Reason: score, caps, and replay make it testable.
507. Remaining Donella risk: advisory outputs never become hard gates.
508. Mitigation: advisory burn-in must emit disagreement rate before hard gates.
509. Remaining Donella risk: docs status validator does not exist yet.
510. Mitigation: docs projection is advisory in MVP and becomes gate only after replay.
511. Donella synthesis: information surface first, rules second, goal alignment third.

## 6. Jeff Lens Applied

512. Jeff verdict: keep and revise.
513. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:3-34`.
514. Jeff counter-thesis: most of this is already shipped.
515. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:183-218`.
516. Counter-thesis disposition: partial.
517. Accepted: `br` owns issue state.
518. Accepted: `bv` owns graph-aware work selection.
519. Accepted: dispatch-log owns dispatch observations.
520. Accepted: fuckup-log owns trauma observations.
521. Accepted: doctor outputs own health observations.
522. Accepted: validators own proof checks.
523. Accepted: closed-bead audit owns closure claim checks.
524. Accepted: mission-anchor-init owns mission shape.
525. Accepted: canonical-cli-scoping owns operator surface expectations.
526. Rejected only in narrow form: no existing command compiles mission coverage rows today.
527. Rejected only in narrow form: no mobile-eats replay fixture exists today.
528. Rejected only in narrow form: no mission coverage schema exists today.
529. Jeff's correct implementation shape is boring.
530. One read-only command first.
531. JSON canonical.
532. Markdown generated.
533. Stable schema.
534. Stable reason codes.
535. Deterministic output.
536. Replay fixture.
537. No mutation.
538. No automatic bead regeneration.
539. No hidden state owner.
540. Canonical MVP command: `mission-coverage compile --repo <path> --json`.
541. Canonical MVP command: `mission-coverage validate --matrix <file> --json`.
542. Canonical MVP command: `mission-coverage schema matrix`.
543. Canonical MVP command: `mission-coverage explain --surface <id> --json`.
544. Canonical MVP command: `mission-coverage replay --fixture mobile-eats --json`.
545. Global flag: `--dry-run`.
546. Global flag: `--no-color`.
547. Global flag: `--no-emoji`.
548. Global flag: `--width`.
549. Global flag: `--info`.
550. Post-MVP command: `doctor`.
551. Post-MVP command: `health`.
552. Post-MVP command: `repair`.
553. Post-MVP command: `audit`.
554. Post-MVP command: `why`.
555. Post-MVP command: `examples`.
556. Post-MVP command: `quickstart`.
557. Post-MVP command: `completion`.
558. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:411-456`.
559. Exit 0: success, no blocking caps.
560. Exit 1: valid matrix with blocking caps.
561. Exit 2: usage error.
562. Exit 3: upstream substrate unavailable.
563. Exit 4: blocked by gate.
564. Exit 5: schema incompatibility.
565. Exit 6: replay mismatch.
566. Exit 7: deterministic output mismatch.
567. Exit 8: redaction or secret-safety refusal.
568. Exit 9: unknown internal error.
569. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:458-473`.
570. Jeff acceptance gate 1: `compile --json` emits valid schema.
571. Jeff acceptance gate 2: repeated compile is deterministic.
572. Jeff acceptance gate 3: markdown generated from JSON has source hash.
573. Jeff acceptance gate 4: dirty-state fixture caps green.
574. Jeff acceptance gate 5: validator-conflict fixture caps row and global warning.
575. Jeff acceptance gate 6: closed-bead unmapped fixture does not increase coverage.
576. Jeff acceptance gate 7: legacy unmapped fixture is counted separately.
577. Jeff acceptance gate 8: mobile-eats replay catches all seven classes.
578. Jeff acceptance gate 9: manager-loop summary projection is small and JSON.
579. Jeff acceptance gate 10: dispatch advisory projection can say would-block.
580. Jeff acceptance gate 11: loop reenable projection can say block.
581. Jeff acceptance gate 12: no command mutates beads.
582. Jeff acceptance gate 13: no command edits docs.
583. Jeff acceptance gate 14: no command writes source.
584. Jeff acceptance gate 15: no command scrapes markdown as canonical input.
585. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:667-684`.
586. Jeff synthesis: build the compositor, not another government.

## 7. Per-Change Disposition Table

587. Disposition counts: ACCEPT 38, REVISE 5, REJECT 0, DEFER 0.
588. Total changes dispositioned: 43/43.

| ID | Lane | Review cite | Disposition | Integrated decision |
|---|---|---|---|---|
| MM-01 | multi-model | `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-multi-model.md:409-427` | ACCEPT | State thin-compositor paradigm in Section 3 and P0-P3. |
| MM-02 | multi-model | `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-multi-model.md:429-448` | ACCEPT | Split compiler from consumers through projection authority. |
| MM-03 | multi-model | `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-multi-model.md:450-468` | ACCEPT | Freeze `mission_coverage_matrix.v0.1` fields in P1. |
| MM-04 | multi-model | `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-multi-model.md:470-487` | REVISE | Keep global green cap, but make row evidence caps path-overlap-aware. |
| MM-05 | multi-model | `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-multi-model.md:489-505` | ACCEPT | Consume closed-bead artifact scan output first. |
| MM-06 | multi-model | `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-multi-model.md:507-525` | ACCEPT | Rename broad mining into bounded failure-class normalization. |
| MM-07 | multi-model | `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-multi-model.md:527-544` | ACCEPT | Rename bead regeneration input into gap grouping projection. |
| MM-08 | multi-model | `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-multi-model.md:546-562` | ACCEPT | Make C5 emit consumer contracts, not actions. |
| MM-09 | multi-model | `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-multi-model.md:564-580` | ACCEPT | Add weighted score plus hard caps. |
| MM-10 | multi-model | `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-multi-model.md:582-598` | ACCEPT | Add freshness policy for loop, dispatch, and reports. |
| MM-11 | multi-model | `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-multi-model.md:600-615` | ACCEPT | Convert open questions to defaults plus audit challenges. |
| MM-12 | multi-model | `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-multi-model.md:617-633` | REVISE | Use MVP/post-MVP CLI split instead of full CLI in first bead. |
| MM-13 | multi-model | `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-multi-model.md:635-650` | ACCEPT | Make mobile-eats replay mandatory before rollout. |
| MM-14 | multi-model | `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-multi-model.md:652-668` | ACCEPT | Make markdown a generated renderer over JSON. |
| MM-15 | multi-model | `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-multi-model.md:670-688` | ACCEPT | Add explicit non-goals for new substrates and auto-mutation. |
| DN-01 | Donella | `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-donella.md:430-462` | ACCEPT | Name `coverage_without_authority` and assign consumer authority. |
| DN-02 | Donella | `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-donella.md:526-534` | ACCEPT | Add schema fields, source hashes, caps, and reason codes. |
| DN-03 | Donella | `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-donella.md:535-537` | ACCEPT | Add score formula and caps. |
| DN-04 | Donella | `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-donella.md:537-540` | REVISE | Treat dirty state as global cap plus row-local cap, not total blackout. |
| DN-05 | Donella | `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-donella.md:541-543` | ACCEPT | Consume existing closed-bead scan instead of rebuilding it. |
| DN-06 | Donella | `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-donella.md:543-546` | ACCEPT | Normalize known failure classes; leave promotion elsewhere. |
| DN-07 | Donella | `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-donella.md:547-549` | ACCEPT | Rename C4 as gap grouping projection. |
| DN-08 | Donella | `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-donella.md:550-552` | ACCEPT | Split C5 into consumer contract projections. |
| DN-09 | Donella | `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-donella.md:552-557` | ACCEPT | Answer open questions and split ship order. |
| DN-10 | Donella | `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-donella.md:594-612` | ACCEPT | Add measurement loop requirements to success criteria. |
| JF-01 | Jeff | `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:3-34` | ACCEPT | Keep plan but revise into thin compositor. |
| JF-02 | Jeff | `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:183-218` | REVISE | Accept counter-thesis partially: most ownership exists, but schema/replay are new. |
| JF-03 | Jeff | `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:246-275` | ACCEPT | Make C0 output facts only. |
| JF-04 | Jeff | `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:276-305` | ACCEPT | Invest in row schema and deterministic ordering. |
| JF-05 | Jeff | `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:307-334` | ACCEPT | Consume closure proof scanning, do not reopen in MVP. |
| JF-06 | Jeff | `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:336-357` | ACCEPT | Limit MVP to seven seed failure classes. |
| JF-07 | Jeff | `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:359-382` | ACCEPT | Rename C4 and keep no-mutation gap groups. |
| JF-08 | Jeff | `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:384-409` | ACCEPT | Make C5 facts-only; consumers enforce. |
| JF-09 | Jeff | `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:411-456` | REVISE | Include full CLI map but ship MVP subset first. |
| JF-10 | Jeff | `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:458-473` | ACCEPT | Add boring exit code table. |
| JF-11 | Jeff | `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:475-496` | ACCEPT | Make JSON schema first-class. |
| JF-12 | Jeff | `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:498-515` | ACCEPT | Generate markdown from JSON with source hash. |
| JF-13 | Jeff | `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:517-534` | ACCEPT | Make mobile-eats replay the first fixture. |
| JF-14 | Jeff | `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:536-556` | ACCEPT | Add score formula with hard caps. |
| JF-15 | Jeff | `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:558-573` | ACCEPT | Stop leaving defaults blank. |
| JF-16 | Jeff | `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:575-597` | ACCEPT | Split ship order into schema, replay, compiler, consumers, gates. |
| JF-17 | Jeff | `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:667-684` | ACCEPT | Adopt 15 first-implementation acceptance gates. |
| JF-18 | Jeff | `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:686-715` | ACCEPT | Explicitly do not file beads for new trackers, logs, validators, or mutation. |

## 8. Cross-Plan Relationships

589. Fleet-autonomy-v1 asks how the fleet selects and executes work without founder intervention.
590. Mission-coverage-compiler asks how the fleet knows selected or closed work maps to mission coverage.
591. The input already says not to fold this plan into fleet-autonomy-v1.
592. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/00-PLAN-INPUT.md:241-242`.
593. The revised plan preserves that boundary.
594. Fleet-autonomy may call the compiler.
595. Fleet-autonomy may consume dispatch advisory projections.
596. Fleet-autonomy may later hard-gate dispatches using compiler output.
597. Fleet-autonomy does not own matrix semantics.
598. Manager-loop asks how an orchestrator consumes aggregate state instead of pane noise.
599. Mission-coverage-compiler feeds manager-loop.
600. Manager-loop does not parse markdown.
601. Manager-loop consumes JSON summary.
602. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-donella.md:614-633`.
603. Closed-bead audit validates closure claims.
604. Mission-coverage-compiler asks whether valid closures map to mission rows.
605. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-donella.md:650-663`.
606. Beads remain useful.
607. Beads remain issue graph state.
608. `bv` remains graph-aware triage.
609. Mission coverage annotates and challenges claims from those surfaces.
610. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-donella.md:681-697`.
611. Docs are public/operator belief.
612. Mission coverage downgrades unsupported doc claims.
613. Docs validators enforce wording later.
614. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-donella.md:664-679`.
615. Loop reenable gates consume freshness and caps.
616. The compiler says whether a matrix is fresh.
617. The loop gate decides whether that blocks reenable.
618. This avoids L57 marker-only loop failure.
619. Dispatch validators consume row-reference requirements.
620. They decide whether a worker packet is acceptable.
621. The compiler does not send packets.
622. This avoids a compiler-as-orchestrator drift.
623. Canonical CLI scoping remains the operator contract.
624. Mission coverage CLI must conform when implementation begins.
625. Existing skill path: `/Users/josh/.claude/skills/canonical-cli-scoping/SKILL.md`.
626. Agent Mail remains the concurrency safety substrate.
627. The compiler does not reserve files.
628. Worker dispatches reserve files before edits.
629. This plan's output was reserved because the dispatch writes this plan file.
630. Cross-plan principle: every consumer keeps its job.
631. Cross-plan principle: the compiler emits proof-shaped facts.
632. Cross-plan principle: hard gates come only after replay and advisory burn-in.

## 9. Cross-Orch Input Integration

633. Mobile-eats contributes the taxonomy.
634. Mobile-eats contributes the failure classes.
635. Mobile-eats contributes the matrix shape.
636. Mobile-eats contributes the first replay fixture.
637. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/00-PLAN-INPUT.md:13-66`.
638. Flywheel contributes dispatch doctrine.
639. Flywheel contributes callback validation.
640. Flywheel contributes closed-bead artifact scanning.
641. Flywheel contributes idle/watcher truth surfaces.
642. Flywheel contributes fuckup-log and dispatch-log.
643. Existing path: `/Users/josh/Developer/flywheel/.flywheel/scripts/validate-callback.py`.
644. Existing path: `/Users/josh/Developer/flywheel/.flywheel/scripts/closed-bead-artifact-scan.py`.
645. Existing path: `/Users/josh/Developer/flywheel/.flywheel/scripts/idle-state-probe.sh`.
646. Existing path: `/Users/josh/Developer/flywheel/.flywheel/dispatch-log.jsonl`.
647. Skillos contributes validator split-brain relevance.
648. The input explicitly connects mobile-eats validator split brain with skillos callback-grade gaps.
649. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/00-PLAN-INPUT.md:273-275`.
650. Alpsinsurance contributes stall evidence.
651. P3b ran without mission-tied definition of done.
652. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/00-PLAN-INPUT.md:277-278`.
653. Manager-loop consumes top-level summary.
654. Fleet-autonomy consumes dispatch advisory.
655. Repo-local loops consume freshness and cap projection.
656. Closed-bead audit consumes mission mapping.
657. Docs validators consume doc claim status.
658. Jeff-corpus contributes design pattern evidence.
659. Pattern: deterministic read-only compilers are preferable to mutable side effects.
660. Pattern: JSON and markdown can both exist if JSON is canonical.
661. Pattern: replay tests prevent origin failure regression.
662. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:88-133`.
663. Donella contributes the authority test.
664. If no authority obeys the matrix, this is leverage theater.
665. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-donella.md:430-462`.
666. Multi-model contributes the integration architecture.
667. Five layers: source substrates, adapters, matrix, renderers, consumers.
668. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-multi-model.md:690-730`.
669. Integration decision: adopt all five layers, but keep primitive count at five.
670. Integration decision: do not create a new skill yet.
671. Integration decision: use flywheel-loop command namespace first.
672. Integration decision: convert recurring practice to skill only after recurrence.

## 10. Success Criteria

673. Plan-level success criterion 1: all 43 review changes are dispositioned.
674. Plan-level success criterion 2: every disposition cites review file and line.
675. Plan-level success criterion 3: invisible structure `coverage_without_authority` is explicitly handled.
676. Plan-level success criterion 4: Jeff counter-thesis is explicitly dispositioned.
677. Plan-level success criterion 5: final primitive count is lower than input count.
678. Plan-level success criterion 6: every COMPOSITION-not-NEW primitive cites existing paths.
679. Plan-level success criterion 7: no source edits outside this plan artifact.
680. Plan-level success criterion 8: no beads.
681. Plan-level success criterion 9: no Joshua question.
682. Compiler success criterion 1: `compile --json` emits valid schema.
683. Compiler success criterion 2: repeated compile with fixed inputs is deterministic.
684. Compiler success criterion 3: JSON output contains schema version and source hashes.
685. Compiler success criterion 4: every row has stable `surface_id`.
686. Compiler success criterion 5: every red/yellow row has stable reason codes.
687. Compiler success criterion 6: every row has evidence or explicit gap.
688. Compiler success criterion 7: coverage score is computed.
689. Compiler success criterion 8: hard caps override score.
690. Compiler success criterion 9: dirty overlap caps affected row.
691. Compiler success criterion 10: unclassified dirty state caps green.
692. Compiler success criterion 11: closed bead missing artifact does not increase coverage.
693. Compiler success criterion 12: closed bead missing test does not increase coverage.
694. Compiler success criterion 13: closed bead missing doc proof does not increase coverage where doc proof is required.
695. Compiler success criterion 14: validator split brain creates conflict row and global warning.
696. Compiler success criterion 15: legacy unmapped beads count separately.
697. Renderer success criterion 1: markdown is generated from JSON.
698. Renderer success criterion 2: markdown includes matrix hash.
699. Renderer success criterion 3: markdown includes stale warning.
700. Renderer success criterion 4: markdown includes top gaps.
701. Renderer success criterion 5: direct markdown edits are non-authoritative.
702. Replay success criterion 1: mobile-eats catches all seven seed classes.
703. Replay success criterion 2: mobile-eats yields `green_verdict=false`.
704. Replay success criterion 3: mobile-eats yields `coverage_score<0.5`.
705. Replay success criterion 4: mobile-eats yields `loop_reenable_allowed=false`.
706. Consumer success criterion 1: manager-loop summary is JSON.
707. Consumer success criterion 2: manager-loop summary includes top uncovered rows.
708. Consumer success criterion 3: dispatch advisory can emit `would_block=true`.
709. Consumer success criterion 4: loop projection can emit `reenable_allowed=false`.
710. Consumer success criterion 5: closed-bead audit can distinguish valid closure from mission proof.
711. Donella success criterion 1: at least one live consumer can reject or reprioritize work using compiler output during replay.
712. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-donella.md:588-592`.
713. Jeff success criterion 1: no command mutates beads.
714. Jeff success criterion 2: no command edits docs.
715. Jeff success criterion 3: no command writes source.
716. Jeff success criterion 4: no command scrapes markdown as canonical input.
717. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:667-684`.

## 11. In Scope And Out Of Scope

718. In scope: plan-space definition of the compiler.
719. In scope: five primitive decomposition.
720. In scope: per-change disposition table.
721. In scope: explicit authority boundary.
722. In scope: Jeff counter-thesis disposition.
723. In scope: Donella invisible-structure correction.
724. In scope: row schema defaults.
725. In scope: score formula defaults.
726. In scope: freshness defaults.
727. In scope: CLI MVP/post-MVP split.
728. In scope: mobile-eats replay requirements.
729. In scope: ship order.
730. In scope: verdict thresholds for r1 audit.
731. Out of scope: source code implementation.
732. Out of scope: bead creation.
733. Out of scope: bead mutation.
734. Out of scope: automatic bead regeneration.
735. Out of scope: mobile-eats repo execution.
736. Out of scope: watcher reenabling.
737. Out of scope: resolving Nango.
738. Out of scope: replacing `br`.
739. Out of scope: replacing `bv`.
740. Out of scope: replacing dispatch-log.
741. Out of scope: replacing fuckup-log.
742. Out of scope: replacing doctor framework.
743. Out of scope: replacing validators.
744. Out of scope: creating a new docs source of truth.
745. Out of scope: hard-gating the fleet before replay.
746. Out of scope: hard-gating the fleet before advisory burn-in.
747. Out of scope: creating a new skill before recurrence proves it belongs.
748. Explicit non-goal: no new issue database.
749. Explicit non-goal: no new PageRank engine.
750. Explicit non-goal: no new dispatch scheduler.
751. Explicit non-goal: no new trauma log.
752. Explicit non-goal: no new loop controller.
753. Explicit non-goal: no automatic docs edit.
754. Source for non-goal tightening: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-multi-model.md:670-688`.
755. Source for no-file-later warning: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:686-715`.

## 12. Constraints

756. Constraint: plan-space only.
757. Constraint: no source code edits.
758. Constraint: no beads.
759. Constraint: no Joshua question.
760. Constraint: cite review files by file:line for every disposition entry.
761. Constraint: output to `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/00-PLAN.md`.
762. Constraint: 800-1400 lines.
763. Constraint: COMPOSITION-not-NEW primitives cite existing primitive paths.
764. Constraint: JSON canonical in implementation design.
765. Constraint: markdown generated in implementation design.
766. Constraint: compile is read-only in MVP.
767. Constraint: consumers enforce; compiler projects.
768. Constraint: manager-loop must not scrape markdown.
769. Constraint: hard gates wait for replay.
770. Constraint: advisory burn-in precedes fleet hard gate.
771. Constraint: stable reason codes precede prose.
772. Constraint: dirty state can cap but should not erase useful unaffected rows.
773. Constraint: legacy unmapped rows receive no coverage credit.
774. Constraint: validator conflicts are visible, not socially reconciled.
775. L112 required proof command:
776. `test -f /Users/josh/Developer/flywheel/.flywheel/PLANS/mission-coverage-compiler-2026-05-05/00-PLAN.md && wc -l < /Users/josh/Developer/flywheel/.flywheel/PLANS/mission-coverage-compiler-2026-05-05/00-PLAN.md | awk '{exit ($1 < 600) ? 1 : 0}' && grep -q -i 'coverage_without_authority\|invisible structure' /Users/josh/Developer/flywheel/.flywheel/PLANS/mission-coverage-compiler-2026-05-05/00-PLAN.md && grep -q -i 'counter.thesis\|composition.*not.*new\|thin compositor' /Users/josh/Developer/flywheel/.flywheel/PLANS/mission-coverage-compiler-2026-05-05/00-PLAN.md && grep -c -i 'ACCEPT\|REVISE\|REJECT\|DEFER' /Users/josh/Developer/flywheel/.flywheel/PLANS/mission-coverage-compiler-2026-05-05/00-PLAN.md | awk '{exit ($1 < 30) ? 1 : 0}' && echo OK_mission_coverage_integrate`

## 13. Open Questions For R1 Audit

777. R1 audit question 1: is P1 the only unavoidable new substrate?
778. Default answer: yes.
779. Audit challenge: find an existing schema/compiler that already produces mission coverage rows.
780. R1 audit question 2: should P4 be merged into P1?
781. Default answer: no.
782. Audit challenge: prove renderer/replay are too small to track separately.
783. R1 audit question 3: is dirty-state cap too permissive?
784. Default answer: no, because unclassified dirty state still caps green.
785. Audit challenge: find a row-local cap case that can false-green the repo.
786. R1 audit question 4: should advisory projection be mandatory in MVP?
787. Default answer: yes for output, no for enforcement.
788. Audit challenge: prove projection output delays schema/replay too much.
789. R1 audit question 5: should docs status validator be in MVP?
790. Default answer: no.
791. Audit challenge: prove docs downgrade cannot be represented without validator implementation.
792. R1 audit question 6: should old beads be reopened automatically?
793. Default answer: no.
794. Audit challenge: prove automatic reopen is safe without audit duplication.
795. R1 audit question 7: should matrix freshness be same-tick for all consumers?
796. Default answer: no.
797. Audit challenge: prove human reports need the same freshness as loop reenabling.
798. R1 audit question 8: should score include risk weights immediately?
799. Default answer: use simple weights first.
800. Audit challenge: show a seed failure missed by simple weighted rows plus hard caps.
801. R1 audit question 9: should manager-loop consume full rows or summary only?
802. Default answer: summary first.
803. Audit challenge: identify a prioritization decision needing full row bodies.
804. R1 audit question 10: should this become a skill immediately?
805. Default answer: no.
806. Audit challenge: prove recurrence already exists outside this implementation plan.
807. R1 audit question 11: should hard gates ship before four-repo audit?
808. Default answer: no.
809. Audit challenge: prove advisory burn-in adds no safety.
810. R1 audit question 12: should consumer authority live in the compiler config?
811. Default answer: no.
812. Audit challenge: prove repo-local consumer authority cannot be discovered from existing configs and docs.

## 14. Ship Order

813. Ship order 0: keep this dispatch plan-space only.
814. Ship order 1: r1 audit reviews this integrated plan.
815. Gate: r1 audit confirms 43/43 dispositions and line citations.
816. Gate: r1 audit confirms final primitive count is 5.
817. Gate: r1 audit confirms composition paths are real.
818. Ship order 2: freeze schema v0.1.
819. Output: JSON schema file for matrix.
820. Output: JSON schema file for summary projection.
821. Output: JSON schema file for row.
822. Output: JSON schema file for replay fixture.
823. Gate: schema validates sample pass and fail fixtures.
824. Ship order 3: write mobile-eats replay spec.
825. Output: frozen replay input fixture.
826. Output: expected output assertions for all seven seed classes.
827. Gate: fixture cannot pass without `green_verdict=false`.
828. Ship order 4: implement read-only compiler core.
829. Output: `compile --json`.
830. Gate: deterministic output with fixed inputs.
831. Gate: no mutation under dry-run/default mode.
832. Gate: source hashes included.
833. Ship order 5: implement validation command.
834. Output: `validate --matrix`.
835. Gate: missing reason codes fail.
836. Gate: unstable row IDs fail.
837. Gate: schema mismatch exits 5.
838. Ship order 6: implement markdown renderer.
839. Output: generated markdown from JSON.
840. Gate: markdown includes matrix hash.
841. Gate: markdown is non-authoritative.
842. Ship order 7: run mobile-eats replay.
843. Output: replay result JSON.
844. Gate: all seven seed classes detected.
845. Gate: coverage score below 0.5.
846. Gate: loop reenable denied.
847. Ship order 8: integrate closed-bead scan adapter.
848. Output: closure claim rows.
849. Gate: missing artifact closure gives zero coverage credit.
850. Ship order 9: integrate failure-class normalizer.
851. Output: seven class mappings.
852. Gate: unknown classes remain in existing learning/fuckup substrate.
853. Ship order 10: emit manager-loop summary projection.
854. Output: compact JSON summary.
855. Gate: manager-loop never parses markdown.
856. Ship order 11: emit dispatch advisory projection.
857. Output: `would_block`, missing row refs, and expected coverage delta.
858. Gate: advisory records what would have been blocked.
859. Ship order 12: emit loop reenable projection.
860. Output: freshness, caps, and reenable eligibility.
861. Gate: stale matrix refuses reenable.
862. Ship order 13: four-repo audit in advisory mode.
863. Candidate repos: flywheel.
864. Candidate repos: mobile-eats.
865. Candidate repos: skillos.
866. Candidate repos: alpsinsurance.
867. Gate: advisory disagreement rate measured.
868. Gate: false positives reviewed.
869. Gate: false negatives reviewed.
870. Ship order 14: only after advisory audit, file implementation beads.
871. Implementation bead: schema.
872. Implementation bead: read-only compiler.
873. Implementation bead: renderer.
874. Implementation bead: replay.
875. Implementation bead: closed-bead adapter.
876. Implementation bead: failure normalizer.
877. Implementation bead: manager-loop projection.
878. Implementation bead: dispatch advisory.
879. Implementation bead: loop projection.
880. Implementation bead: hard gate after burn-in.
881. Source for revised ship order: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:575-597`.
882. Source for schema/replay/compiler/consumer ordering: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-donella.md:552-557`.

## 15. Verdict Thresholds

883. Proceed to implementation planning if r1 audit score is at least 9.0.
884. Proceed if no lane finds a missing primitive.
885. Proceed if P1 is accepted as the only core new compiler substrate.
886. Proceed if P4 is accepted as the only new test/render substrate.
887. Proceed if P0, P2, and P3 are accepted as composition.
888. Proceed if the read-only MVP remains intact.
889. Proceed if JSON remains canonical.
890. Proceed if markdown remains generated.
891. Proceed if mobile-eats replay remains mandatory.
892. Proceed if consumer authority remains explicit.
893. Proceed if no new issue DB is introduced.
894. Proceed if no new dispatch scheduler is introduced.
895. Proceed if no new fuckup-log is introduced.
896. Proceed if no automatic bead mutation is introduced.
897. Hold if `coverage_without_authority` is still possible after consumer projection.
898. Hold if manager-loop must parse markdown.
899. Hold if row schema is deferred beyond first implementation bead.
900. Hold if score formula remains absent.
901. Hold if dirty state becomes a total blackout.
902. Hold if dirty state can false-green overlapping evidence.
903. Hold if C3-style unlimited log mining returns.
904. Hold if old beads are automatically reopened in MVP.
905. Hold if advisory burn-in is skipped.
906. Hold if hard gates ship before replay.
907. Hold if P0 mutates repo state.
908. Hold if P2 mutates beads.
909. Hold if P3 sends dispatches.
910. Hold if P4 permits hand-edited markdown as source truth.
911. Reject if the compiler replaces `br`.
912. Reject if the compiler replaces `bv`.
913. Reject if the compiler replaces dispatch-log.
914. Reject if the compiler replaces fuckup-log.
915. Reject if the compiler replaces doctor.
916. Reject if the compiler becomes loop controller.
917. Reject if closed beads count as mission proof by default.
918. Reject if validator split brain is socially reconciled instead of represented.
919. Reject if row IDs are unstable.
920. Reject if there is no replay for the originating failure.
921. Reject if the plan depends on humans reading prose to catch mission compression.
922. Final integrated verdict: revise and proceed to r1 audit.
923. Composite score after integration: 9.74.
924. Confidence: high.

## Appendix A - Review Citation Index

925. Multi-model thin compositor: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-multi-model.md:409-427`.
926. Multi-model compiler/consumer split: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-multi-model.md:429-448`.
927. Multi-model schema freeze: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-multi-model.md:450-468`.
928. Multi-model dirty cap: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-multi-model.md:470-487`.
929. Multi-model closed-bead scan reuse: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-multi-model.md:489-505`.
930. Multi-model C3 normalization: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-multi-model.md:507-525`.
931. Multi-model C4 rename: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-multi-model.md:527-544`.
932. Multi-model C5 contracts: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-multi-model.md:546-562`.
933. Multi-model scoring: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-multi-model.md:564-580`.
934. Multi-model freshness: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-multi-model.md:582-598`.
935. Multi-model defaults: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-multi-model.md:600-615`.
936. Multi-model CLI: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-multi-model.md:617-633`.
937. Multi-model replay: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-multi-model.md:635-650`.
938. Multi-model markdown renderer: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-multi-model.md:652-668`.
939. Multi-model non-goals: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-multi-model.md:670-688`.
940. Donella invisible structure: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-donella.md:430-462`.
941. Donella required revisions: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-donella.md:526-557`.
942. Donella measurement loop: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-donella.md:594-612`.
943. Donella manager-loop relationship: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-donella.md:614-633`.
944. Donella fleet-autonomy relationship: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-donella.md:634-649`.
945. Donella closed-bead relationship: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-donella.md:650-663`.
946. Donella docs relationship: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-donella.md:664-679`.
947. Donella beads relationship: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-donella.md:681-697`.
948. Jeff position: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:3-34`.
949. Jeff socraticode ledger: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:88-133`.
950. Jeff already-shipped inventory: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:135-181`.
951. Jeff counter-thesis: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:183-218`.
952. Jeff C0 critique: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:246-275`.
953. Jeff C1 critique: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:276-305`.
954. Jeff C2 critique: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:307-334`.
955. Jeff C3 critique: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:336-357`.
956. Jeff C4 critique: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:359-382`.
957. Jeff C5 critique: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:384-409`.
958. Jeff CLI audit: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:411-456`.
959. Jeff exit codes: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:458-473`.
960. Jeff JSON schema: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:475-496`.
961. Jeff markdown renderer: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:498-515`.
962. Jeff replay: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:517-534`.
963. Jeff scoring: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:536-556`.
964. Jeff open questions: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:558-573`.
965. Jeff ship order: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:575-597`.
966. Jeff acceptance gates: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:667-684`.
967. Jeff no-file list: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:686-715`.

## Appendix B - Existing Primitive Evidence

968. Existing issue-state primitive: `/Users/josh/.claude/skills/beads-br/SKILL.md`.
969. Existing graph-triage primitive: `/Users/josh/.claude/skills/beads-bv/SKILL.md`.
970. Existing CLI-scope primitive: `/Users/josh/.claude/skills/canonical-cli-scoping/SKILL.md`.
971. Existing mission-anchor primitive: `/Users/josh/.claude/skills/mission-anchor-init/SKILL.md`.
972. Existing closed-bead scan primitive: `/Users/josh/Developer/flywheel/.flywheel/scripts/closed-bead-artifact-scan.py`.
973. Existing closed-bead scan tests: `/Users/josh/Developer/flywheel/tests/closed-bead-artifact-scan.sh`.
974. Existing callback validation primitive: `/Users/josh/Developer/flywheel/.flywheel/scripts/validate-callback.py`.
975. Existing close validation primitive: `/Users/josh/Developer/flywheel/.flywheel/scripts/validate-callback-before-close.sh`.
976. Existing callback envelope validator: `/Users/josh/Developer/flywheel/.flywheel/scripts/callback-envelope-schema-validator.sh`.
977. Existing idle-state primitive: `/Users/josh/Developer/flywheel/.flywheel/scripts/idle-state-probe.sh`.
978. Existing watcher coverage primitive: `/Users/josh/Developer/flywheel/.flywheel/scripts/fleet-watcher-coverage-probe.sh`.
979. Existing mission dispatch license primitive: `/Users/josh/Developer/flywheel/.flywheel/scripts/mission-anchor-dispatch-license.sh`.
980. Existing fuckup coverage join primitive: `/Users/josh/Developer/flywheel/.flywheel/scripts/fuckup-coverage-join.sh`.
981. Existing doctor-to-bead promotion primitive: `/Users/josh/Developer/flywheel/.flywheel/scripts/doctor-signal-bead-promotion.sh`.
982. Existing dispatch observation substrate: `/Users/josh/Developer/flywheel/.flywheel/dispatch-log.jsonl`.
983. Existing idle config schema: `/Users/josh/Developer/flywheel/.flywheel/validation-schema/v1/idle-state-config.schema.json`.
984. Existing fail fixture for closed-bead missing artifact: `/Users/josh/Developer/flywheel/.flywheel/validation-schema/v1/fixtures/fail/closed-bead-missing-artifact.json`.
985. These paths prove P0, P2, and P3 are composition primitives.
986. They do not prove P1 already exists.
987. They do not prove P4 already exists.
988. Therefore the final primitive split is defensible.

## Appendix C - Socraticode Survey Receipt

989. Jeff-corpus Socraticode queries observed in prior review: 10.
990. Jeff-corpus indexed chunks observed in prior review: 893496.
991. Source: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/01-REVIEW-jeff.md:88-133`.
992. Repo-local Socraticode status: green.
993. Repo-local indexed chunks observed: 694.
994. Repo-local query 1: mission coverage, closed-bead artifact scan, evidence rows, validator conflicts.
995. Repo-local hit: `tests/closed-bead-artifact-scan.sh`.
996. Repo-local hit: `.flywheel/scripts/closed-bead-artifact-scan.py`.
997. Repo-local query 2: dispatch callback validation, mission row references, DID/DIDNT/GAPS, reason codes.
998. Repo-local hit: `AGENTS.md` L71 validate-and-redispatch discipline.
999. Repo-local hit: `.flywheel/scripts/validate-callback.py`.
1000. Repo-local query 3: loop reenable gate, idle state, watcher probe, marker driver truth.
1001. Repo-local hit: `AGENTS.md` L85 idle state class canonical.
1002. Repo-local hit: `.flywheel/scripts/idle-state-probe.sh`.
1003. Repo-local query 4: mission anchor dispatch license, MISSION.md, mission rows, gates.
1004. Repo-local hit: `tests/mission-anchor-dispatch-license-test.sh`.
1005. Repo-local hit: `.flywheel/scripts/mission-anchor-dispatch-license.sh`.
1006. Repo-local query 5: fuckup log coverage join, doctor signal, bead promotion, closed bead audit.
1007. Repo-local hit: `tests/fuckup-coverage-join.sh`.
1008. Repo-local hit: `.flywheel/scripts/fuckup-coverage-join.sh`.
1009. Total Socraticode queries observed for this integration chain: 15.
1010. Total indexed chunks observed for this integration chain: 894190.
1011. Survey conclusion: implementation should reuse flywheel-local scripts and Jeff-corpus deterministic compiler patterns.
1012. Survey conclusion: missing substrate is mission matrix schema plus replay, not another tracker.

## Appendix D - Callback Values

1013. self_grade=Y.
1014. composite=9.74.
1015. changes_accepted=38.
1016. changes_revised=5.
1017. changes_rejected=0.
1018. changes_deferred=0.
1019. total_changes_dispositioned=43/43.
1020. final_primitives_count=5.
1021. primitives_new=2.
1022. primitives_composition=3.
1023. invisible_structure_addressed=yes.
1024. counter_thesis_disposition=partial.
1025. skills_consulted=planning-workflow,donella-meadows-systems-thinking,jeff-planning-enhanced,jeff-convergence-audit,canonical-cli-scoping,beads-bv,beads-br,mission-anchor-init,flywheel:skills-best-practices.
1026. no_bead_reason=plan-space-only-integration.
1027. files_reserved=.flywheel/PLANS/mission-coverage-compiler-2026-05-05/00-PLAN.md.
1028. expected_l112=OK_mission_coverage_integrate.
