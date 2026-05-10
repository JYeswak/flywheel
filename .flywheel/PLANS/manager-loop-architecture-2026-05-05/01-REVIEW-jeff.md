---
title: "Jeff Review: Manager-Loop Architecture"
type: plan
created: 2026-05-06
frontmatter_source: scaffold-doc-frontmatter
---

doctor_json="$(flywheel-loop doctor --json)"
triage_json="$(bv --robot-triage --limit 20)"
attention_json="$(ntm robot-attention --profile=operator --json)"
manager_json="$(jq -nc --argjson doctor "$doctor_json" --argjson triage "$triage_json" --argjson attention "$attention_json" -f .flywheel/jq/manager-state-v1.jq)"
fw_jsonl_append_validated .flywheel/dispatch-log.jsonl "$(jq -c '.decision_receipt' <<<"$manager_json")"

# Jeff Review: Manager-Loop Architecture

J001. Verdict: revise.
J002. Counter-thesis: endorsed.
J003. Existing substrate coverage: 82 percent.
J004. Minimum viable subset: 3 primitives.
J005. Proposed change count: 8.
J006. Working sibling diffs: 12.
J007. Upstream issue drafts: 2.
J008. Socraticode queries: 12.
J009. Indexed chunks observed: 893496.
J010. Review path: `.flywheel/PLANS/manager-loop-architecture-2026-05-05/01-REVIEW-jeff.md`.
J011. The plan names the right failure.
J012. The plan overbuilds the remedy.
J013. The real failure is not "missing ops-log."
J014. The real failure is "no composed manager-state from owned ledgers."
J015. That distinction matters.
J016. Jeff's stack already has issue ledgers.
J017. Jeff's stack already has dispatch ledgers.
J018. Jeff's stack already has trauma ledgers.
J019. Jeff's stack already has reservation ledgers.
J020. Jeff's stack already has pane attention ledgers.
J021. Jeff's stack already has graph-aware work ranking.
J022. Jeff's stack already has robot-mode consumption surfaces.
J023. New substrate is only justified at the missing composition boundary.
J024. `ops-log.jsonl` as primary truth fails that test.
J025. `manager-state --json` passes that test.
J026. `manager-decide --dry-run --json` passes that test.
J027. `manager-report --format markdown --atomic` passes that test.
J028. The plan should shrink around those.
J029. Do not kill callbacks before parity.
J030. Do not move all workers to a new log before the bridge exists.
J031. Do not teach every writer a new schema unless one owner can repair it.
J032. Do not create "top-10" as a second bead ranking engine.
J033. Let `bv` own bead ranking.
J034. Let `br` own issue persistence.
J035. Let Agent Mail own reservations and mailbox state.
J036. Let `ntm` own sensing and actuation.
J037. Let `flywheel-loop` own orchestration policy.
J038. Let the manager surface compose, not replace.
J039. The 5-line composition above solves the first 70 percent.
J040. It reads current doctor state.
J041. It reads current `bv` priority state.
J042. It reads current `ntm` attention state.
J043. It emits a composed manager state.
J044. It writes one decision receipt to the existing dispatch ledger.
J045. That is the architectural center.
J046. Everything else is migration discipline.
J047. The proposal's strongest insight is the conversational-orchestrator failure.
J048. The proposal's weakest move is replacing conversation with another universal bus.
J049. A universal bus is not automatically better than a message bus.
J050. A universal bus becomes worse when every subsystem has to learn it.
J051. Good substrate has one owner.
J052. `ops-log` has too many proposed writers.
J053. Workers write it.
J054. Watchers write it.
J055. Validators write it.
J056. Doctor writes it.
J057. Integrator writes it.
J058. That is five owners on day one.
J059. Five owners means five repair paths.
J060. Five repair paths means no repair path.
J061. Canonical substrate is not "the file everyone writes."
J062. Canonical substrate is "the primitive everyone can inspect and repair."
J063. The plan needs that standard.
J064. The canonical-cli-scoping skill says canonical tools must be inspectable.
J065. The same skill says they must be healable.
J066. The same skill says they must be explainable.
J067. The same skill says they must be observable.
J068. `ntm`, `br`, and `cm` are cited there as models.
J069. A new manager primitive must match that bar.
J070. A new flat JSONL file does not match it by itself.

## Evidence Ledger

J071. Mandatory skills read: `jeff-swarm-ops`.
J072. Mandatory skills read: `jeff-planning-enhanced`.
J073. Mandatory skills read: `jeff-issue-chain`.
J074. Mandatory skills read: `jeff-convergence-audit`.
J075. Mandatory skills read: `dicklesworthstone-stack`.
J076. Mandatory skills read: `beads-bv`.
J077. Mandatory skills read: `beads-br`.
J078. Mandatory skills read: `beads-workflow`.
J079. Mandatory skills read: `canonical-cli-scoping`.
J080. Mandatory skills read: `accretive-cron-orchestration`.
J081. Mandatory skills read: `agent-mail`.
J082. Mandatory skills read: `ntm`.
J083. Mandatory skills read: `socraticode`.
J084. Skill search run: `ops log canonical primitive doctor health repair tick aggregator pagerank watcher contract`.
J085. Skill search result was noisy.
J086. Useful matches still pointed to Socraticode.
J087. Useful matches still pointed to flywheel doctor patterns.
J088. Useful matches still pointed to dispatch contracts.
J089. Useful matches still pointed to uptime and tracker patterns.
J090. Socraticode project: `/Users/josh/Developer/jeff-corpus`.
J091. Socraticode status: indexed.
J092. Socraticode chunks observed: 893496.
J093. Socraticode graph files observed: 41597.
J094. Socraticode graph edges observed: 16376.
J095. Socraticode query count: 12.
J096. Query 1: manager loop status json top 10 queue robot mode orchestrator state dispatch log.
J097. Query 2: ops log jsonl append validated atomic fsync rename dispatch event ledger receipt.
J098. Query 3: fw_jsonl_append_validated dispatch log tick summary flywheel loop jsonl writer.
J099. Query 4: ntm robot snapshot events attention feed operator loop cursor actuation send receipt manager state.
J100. Query 5: ntm work triage next alerts assign bv integration recommendation top picks PageRank.
J101. Query 6: bv robot triage top picks recommendations score unblocks PageRank output schema robot next.
J102. Query 7: beads viewer robot alerts label attention priority stale blockers graph health top recommendations.
J103. Query 8: agent mail reservations locks ttl force release stale reservation robot state file reservation conflict.
J104. Query 9: doctor health repair cli canonical validate audit why upstream report json schema robot mode.
J105. Query 10: morning report manager state markdown json top queue daily brief tick summary status dashboard.
J106. Query 11: top k queue one lever queue leverage queue scoring stock impact urgency cost dashboard report.
J107. Query 12: callback log manager aggregator worker progress callbacks message bus ops log orchestrator loop.
J108. Core corpus hit: `ntm/docs/attention-feed-contract.md:1-100`.
J109. Hash: `d034f26f66b10d0d7ac51b6d3121b7a141790baa18af1750cbcb1bef184e6a0a`.
J110. That document says the LLM is the driver.
J111. That document says `ntm` is the nervous system.
J112. That document explicitly does not make `ntm` the planner.
J113. That matters because manager policy belongs in `flywheel-loop`.
J114. Core corpus hit: `ntm/internal/robot/attention_contract.go:1-76`.
J115. Hash: `c36a24bd6b50ed379442c426687bf203e6c0629bf84a01badcf86d4e19eec7f3`.
J116. The contract encodes the operator loop.
J117. Snapshot.
J118. Events.
J119. Digest.
J120. Attention.
J121. Act.
J122. Wait.
J123. Repeat.
J124. That is enough sensing for manager-state.
J125. Core corpus hit: `ntm/internal/robot/robot.go:2054-2098`.
J126. Hash: `d8476b1129fa11594da311f0947217046a33b37ee15c7cac08a1ac7b51caf553`.
J127. `robot-attention` is the steady-state operator surface.
J128. `robot-digest` and `robot-overlay` also exist.
J129. The plan should consume these.
J130. The plan should not reconstruct pane state from callbacks.
J131. Core corpus hit: `ntm/internal/robot/attention_feed.go:27-48`.
J132. Hash: `68119a19080deb86ac4f1751ed2096324af60965e297a58bcea1062fc9c6d4a0`.
J133. There is an append/replay attention store.
J134. There are cursors.
J135. There are replay windows.
J136. That is already an event feed.
J137. A new ops-log must not shadow it.
J138. Core corpus hit: `ntm/internal/bv/client.go:153-187`.
J139. Hash: `63db169adf8c1a6ddcc2eed95fb6d35abeef4611f5390db97407705590f7e3a2`.
J140. `ntm` already calls `bv --robot-triage`.
J141. Default recommendation limit is 20.
J142. Optional ready filtering exists.
J143. That is a working top-N substrate.
J144. Core corpus hit: `ntm/internal/bv/triage.go:206-220`.
J145. Hash: `5014a85404f8fb4d88e7129136f55a5091b92ad2d765e0ec976b5e9fdc8060c1`.
J146. `GetNextRecommendation` exists.
J147. It is already the "next best work" function.
J148. A manager queue should consume that.
J149. A manager queue should not reimplement it.
J150. Core corpus hit: `ntm/internal/coordinator/assign.go:108-172`.
J151. Hash: `cb05c5914745474f9534b1a09cf61d907d3359bafd872ec5d39773100938f6a8`.
J152. Auto-assignment already uses bv recommendations.
J153. It emits events.
J154. It removes recommendations after success.
J155. That is a close working sibling.
J156. Core corpus hit: `ntm/internal/robot/adapters/work_coordination.go:65-72`.
J157. Hash: `175d4fb812d94011dc76f2fa7934d6a0fa1e4a39386d01604b55429f3acdd8e2`.
J158. `WorkTriage` captures top recommendation.
J159. It captures ready counts.
J160. It captures quick wins.
J161. It captures blockers.
J162. That covers part of M3 now.
J163. Core corpus hit: `beads_viewer/README.md:181-280`.
J164. Hash: `eb0daa71fc1ff46c130a90542bf0495a9d0aeb2c5f260ec63b29c3207f9aa660`.
J165. `bv --robot-triage` returns top picks.
J166. It returns recommendations.
J167. It returns quick wins.
J168. It returns blockers to clear.
J169. It returns project health.
J170. It returns commands.
J171. That is most of the proposed top-10 queue.
J172. Core corpus hit: `beads_viewer/README.md:1081-1180`.
J173. Hash: `a2de25c9dbbf657537926090f83a29bcb9448537db353f9dfa6c035a76bc4daa`.
J174. Existing impact score weights include PageRank.
J175. Existing impact score weights include betweenness.
J176. Existing impact score weights include blocker ratio.
J177. Existing impact score weights include staleness.
J178. Existing impact score weights include priority boost.
J179. That should be the Jeff-mode base score.
J180. Core corpus hit: `beads_viewer/pkg/drift/drift.go:456-520`.
J181. Hash: `ae68d5bcaa1052bf0b092e09cc3dde0faaf8744ac703267357b2f31c4c8d23ee`.
J182. Blocking cascades already compute downstream effects.
J183. That covers the "unblocks" signal.
J184. Do not rebuild cascade math in the manager.
J185. Core corpus hit: `agentic_coding_flywheel_setup/scripts/lib/autofix.sh:465-510`.
J186. Hash: `762e96d5c0bc2ffc18aa7c38737881d6093743c05078bdb69fd75dd74f69adef`.
J187. `append_atomic` uses temp.
J188. It copies prior state.
J189. It appends.
J190. It fsyncs.
J191. It renames.
J192. It fsyncs the directory.
J193. This is the write discipline the plan must inherit.
J194. Core corpus hit: `franken_engine/.../proof_artifact.rs:756-798`.
J195. Hash: `1cf340e425292842e82e2874601445f2f7f211b722596eff7279c2e8f48c7c5e`.
J196. Event lines are validated before persistence.
J197. Serialization is validated.
J198. Line validation is explicit.
J199. Large writes need locking.
J200. Manager decision receipts should follow that level.
J201. Core corpus hit: `franken_node/.../decision_receipt.rs:273-398`.
J202. Hash: `3a8ed97f99511850c37220da5745b137f95668063dfee26e4e78a069e536276c`.
J203. Receipts contain input hashes.
J204. Receipts contain output hashes.
J205. Receipts contain decisions.
J206. Receipts contain rationale.
J207. Receipts contain evidence references.
J208. Receipts contain rollback data.
J209. Receipts contain previous hashes.
J210. The manager loop needs that shape.
J211. Core corpus hit: `franken_node/reviews/franken_node__cod_3_review.md:91-115`.
J212. Hash: `91eefc9bac525f0fd5d26091f568d8373dbd990b206a5b1dc60f9edb426718a4`.
J213. The review warns about locking the wrong inode.
J214. Stable sidecar locks are safer.
J215. That warning applies directly to a multi-writer ops-log.
J216. Core corpus hit: `mcp_agent_mail_rust/.../reservations.rs:1054-1153`.
J217. Hash: `10ce0eb1f882494c02b13248e0459ce39a61dada2a34b9360e2993c2fd1b394e`.
J218. Agent Mail has reservation release logic.
J219. It handles conflicts.
J220. It has durable ownership.
J221. Core corpus hit: `mcp_agent_mail_rust/.../reservations.rs:1234-1333`.
J222. Hash: `a65294b485bcce0aa65ce5f4da13b6b8c7bf591264333a9a7f875a634e37588a`.
J223. Agent Mail force-release validates inactivity.
J224. That is the reservation substrate.
J225. Do not mirror it into `ops-log` as authority.

## Skill Citations

J226. `jeff-swarm-ops/SKILL.md:20-24` requires bead polish and convergence before launch.
J227. That argues against shipping M1-M4 as a broad architecture.
J228. `jeff-swarm-ops/SKILL.md:41-45` says use `bv --robot-triage`, not `br ready`.
J229. That directly constrains M3.
J230. `jeff-swarm-ops/SKILL.md:57-66` defines the human tending cadence.
J231. M4 should be a cadence renderer, not a new process.
J232. `jeff-swarm-ops/SKILL.md:95-103` uses Agent Mail and reservations for stuck swarms.
J233. That constrains reservation ownership.
J234. `jeff-swarm-ops/SKILL.md:105-111` says replacement agents use `bv --robot-next`.
J235. That constrains worker redispatch.
J236. `jeff-swarm-ops/SKILL.md:121-125` names bare `br ready` as an anti-pattern.
J237. M3 must not regress to `br ready`.
J238. `jeff-planning-enhanced/SKILL.md:9-23` gives the cost model.
J239. Plan-space is cheap.
J240. Beads are costlier.
J241. Code is much costlier.
J242. This review should stop the expensive version.
J243. `jeff-planning-enhanced/SKILL.md:40-51` requires iterative convergence.
J244. This plan has not converged around substrate ownership yet.
J245. `jeff-planning-enhanced/SKILL.md:94-106` warns about implementation before convergence.
J246. M1 implementation now would be premature.
J247. `jeff-issue-chain/SKILL.md:27-34` defines upstream issue bodies.
J248. Draft issues below follow that evidence-first shape.
J249. `jeff-issue-chain/SKILL.md:36-40` says no PRs and no patches to upstream.
J250. This review files drafts only.
J251. `jeff-issue-chain/SKILL.md:42-46` requires direct evidence-led voice.
J252. That is the review style here.
J253. `jeff-convergence-audit/SKILL.md:24-42` requires skills library baseline before phase 1.
J254. Done.
J255. `jeff-convergence-audit/SKILL.md:133-143` requires two zero rounds for convergence.
J256. This plan has not reached that.
J257. `beads-bv/SKILL.md:12-21` says robot mode is mandatory.
J258. That applies to M3 and M4.
J259. `beads-bv/SKILL.md:29-35` names `--robot-triage`, `--robot-next`, `--robot-plan`, and insights.
J260. M3 should compose those.
J261. `beads-bv/SKILL.md:103-119` gives the decision matrix.
J262. M3 should reuse it.
J263. `beads-br/SKILL.md:12-22` says non-invasive, JSON, sync explicit, no cycles.
J264. M3 must not make `br` a ranking engine.
J265. `beads-br/SKILL.md:27-32` says `br ready` is broken for this use.
J266. Use `bv --robot-triage`.
J267. `beads-workflow/SKILL.md:20-34` says validate dep cycles and use `bv --robot-next`.
J268. That belongs in manager-state preflight.
J269. `beads-workflow/SKILL.md:193-207` integrates Agent Mail.
J270. That belongs in M3 input.
J271. `canonical-cli-scoping/SKILL.md:12-14` sets the inspectable-healable-explainable-observable bar.
J272. That is the audit standard here.
J273. `canonical-cli-scoping/SKILL.md:20-34` requires doctor, health, repair, validate, audit, why, info, examples, quickstart, help, completion, upstream-report, and adapter scoping.
J274. M1-M4 currently do not meet it.
J275. `canonical-cli-scoping/SKILL.md:177-187` requires output and schema discipline.
J276. M4 must have stable JSON.
J277. `canonical-cli-scoping/SKILL.md:199-210` requires dry-run, explain, idempotency, audit, Agent Mail, atomic writes, and backups.
J278. M2 and M4 must inherit that.
J279. `accretive-cron-orchestration/SKILL.md:28-40` names missing information flow and missing stocks.
J280. This plan correctly targets information flow.
J281. `accretive-cron-orchestration/SKILL.md:51-64` already defines sweep loops.
J282. M2 must use that loop shape.
J283. `accretive-cron-orchestration/SKILL.md:76-91` defines setpoints and grade ladder.
J284. M4 health should reuse those thresholds.
J285. `accretive-cron-orchestration/SKILL.md:142-146` defines state and log surfaces.
J286. M4 is a state surface, not a new truth store.
J287. `agent-mail/SKILL.md:79-107` says reserve before edit and release at completion.
J288. M3 should read reservation state from Agent Mail.
J289. `agent-mail/SKILL.md:127-151` covers doctor and repair.
J290. Manager should delegate reservation repair to Agent Mail.
J291. `ntm/SKILL.md:22-27` says robot mode and discovery schema matter.
J292. M4 must expose robot mode.
J293. `ntm/SKILL.md:138-157` already has work triage, alerts, search, impact, next, and graph.
J294. M3 must not duplicate those.
J295. `ntm/SKILL.md:160-177` has mail, locks, coordinator digest, conflicts, and enable.
J296. Manager should consume them.
J297. `ntm/SKILL.md:240-255` lists canonical robot surfaces.
J298. M4 must be shaped for that ecosystem.
J299. `socraticode/SKILL.md:11-18` requires K>=10 and query count reporting.
J300. Done.

## The Composition

J301. The first five lines are intentionally small.
J302. They do not create a new daemon.
J303. They do not create a new writer contract.
J304. They do not alter worker callbacks.
J305. They do not move reservation authority.
J306. They do not move bead ranking authority.
J307. They do not ask `ntm` to become a planner.
J308. They read the owned sources.
J309. They compose a manager state.
J310. They append a decision receipt.
J311. That is the missing primitive.
J312. It should become `flywheel-loop manager-state --json`.
J313. It should become `flywheel-loop manager-decide --dry-run --json`.
J314. It should become `flywheel-loop manager-report --format markdown`.
J315. It should not become `manager-loop` as a separate top-level CLI.
J316. The noun is already `flywheel-loop`.
J317. The verb can be `manager`.
J318. The surface can be grouped.
J319. Proposed command: `flywheel-loop manager state --json`.
J320. Proposed command: `flywheel-loop manager decide --dry-run --json`.
J321. Proposed command: `flywheel-loop manager apply --idempotency-key <key> --json`.
J322. Proposed command: `flywheel-loop manager report --format markdown --atomic`.
J323. Proposed command: `flywheel-loop manager doctor --json`.
J324. Proposed command: `flywheel-loop manager validate --strict --json`.
J325. Proposed command: `flywheel-loop manager repair --dry-run --json`.
J326. That command family can satisfy canonical-cli-scoping.
J327. The proposed `ops-log` cannot satisfy it until ownership is solved.
J328. The correct first implementation is read-only.
J329. Read-only manager-state gives Joshua immediate value.
J330. Read-only manager-state gives orchestrator immediate value.
J331. Read-only manager-state gives reviewers a stable object.
J332. Read-only manager-state gives migration evidence.
J333. A new writer path gives everyone risk first.
J334. Jeff would take the read-only cut.

## M1 Audit: Canonical ops-log

J335. M1 current verdict: reject as written.
J336. M1 acceptable revision: virtual read model or compatibility mirror only.
J337. M1 unacceptable revision: new primary canonical log with many writers.
J338. Current proposed path: `~/.local/state/flywheel/ops-log.jsonl`.
J339. Existing sibling path: `.flywheel/dispatch-log.jsonl`.
J340. Existing sibling path: `~/.local/state/flywheel/fuckup-log.jsonl`.
J341. Existing sibling path: Agent Mail archive.
J342. Existing sibling path: Agent Mail reservations.
J343. Existing sibling path: `ntm` attention feed.
J344. Existing sibling path: `br` bead DB.
J345. Existing sibling path: `bv` robot outputs.
J346. Existing sibling path: `flywheel-loop doctor --json`.
J347. M1 asks every actor to append rows.
J348. That makes the ops-log a coordination surface.
J349. It also makes it a corruption surface.
J350. Corruption in a global log blocks the manager.
J351. Corruption in a local owned ledger is isolated.
J352. Isolation matters more than file count.
J353. M1 doctor score: missing.
J354. It proposes no `ops-log doctor`.
J355. M1 health score: missing.
J356. It proposes no health criteria for lag, corruption, or writer drift.
J357. M1 repair score: missing.
J358. It proposes no repair path for truncated JSONL.
J359. M1 validate score: partial.
J360. It names schema and `fw_jsonl_append_validated`.
J361. It does not define strict schema evolution.
J362. M1 audit score: missing.
J363. It does not explain how to audit duplicate event authority.
J364. M1 why score: missing.
J365. It does not explain why an event is in ops-log instead of its owned ledger.
J366. M1 `--info` score: missing.
J367. M1 `--examples` score: missing.
J368. M1 quickstart score: missing.
J369. M1 help score: missing.
J370. M1 completion score: missing.
J371. M1 `--json` score: partial only through file format.
J372. M1 `--robot-*` score: missing.
J373. M1 canonical-cli-scoping grade: D.
J374. The grade is not because JSONL is bad.
J375. The grade is because owner and repair are undefined.
J376. A JSONL file can be excellent substrate.
J377. Jeff's stack uses them repeatedly.
J378. A JSONL file with five writer classes and no repair verb is not substrate.
J379. M1 should be rewritten as `manager-state` reading owned ledgers.
J380. If an ops-log name remains, it must be marked derived.
J381. Derived logs can be regenerated.
J382. Derived logs can be deleted.
J383. Derived logs cannot be source of truth.
J384. The plan says "no other channel for orchestrator-visible signals."
J385. That line should be removed.
J386. The orchestrator should read canonical channels through a composer.
J387. Workers should keep sending existing callbacks until parity.
J388. Worker callbacks can be normalized into dispatch-log rows.
J389. Agent Mail messages can be summarized into manager-state.
J390. Fuckup rows can be summarized into manager-state.
J391. Reservation rows can be summarized into manager-state.
J392. Pane attention rows can be summarized into manager-state.
J393. The manager should never require all sources to adopt one row schema.
J394. M1 detail cap of 200 chars is sensible.
J395. It should apply to manager summaries, not source ledgers.
J396. M1 stock_delta is dangerous as writer-asserted impact.
J397. Writers should report facts.
J398. The manager should compute stock deltas.
J399. Otherwise every worker becomes a metrics authority.
J400. That creates score inflation.
J401. It creates inconsistent closure semantics.
J402. It creates no single repair location.
J403. M1 schema versioning is necessary.
J404. First row schema version is not sufficient.
J405. Every row needs `schema_version`.
J406. Every row needs `event_id`.
J407. Every row needs `source_ledger`.
J408. Every derived row needs `source_hash`.
J409. Every decision row needs `input_hash`.
J410. Every mutating decision needs an idempotency key.
J411. M1 should not be first ship.
J412. First ship should be read-only manager-state.
J413. M1 can come later as an index.
J414. M1 can come later as a projection.
J415. M1 can come later as `ops-log view`.
J416. M1 cannot come first as authority.

## M2 Audit: Tick-Driven Orchestrator Loop

J417. M2 current verdict: revise.
J418. The tick driver is directionally correct.
J419. The loop shape exists in accretive-cron-orchestration.
J420. The driver must not be a new hand-rolled `while True` script.
J421. It should be a `flywheel-loop manager tick` command.
J422. It should be called by the existing driver substrate.
J423. It should respect L57 driver proof.
J424. Tick receipts without driver proof are markers.
J425. Markers are not drivers.
J426. M2 must prove prompt delivery or external driver actuation.
J427. M2 doctor score: partial.
J428. The plan asks for a triad later.
J429. The triad must be part of the primitive definition, not step 6.
J430. M2 health score: partial.
J431. It has interval bounds.
J432. It lacks stale-driver classification.
J433. M2 repair score: missing.
J434. It lacks repair for stuck tick locks.
J435. It lacks repair for long-running tick overlap.
J436. It lacks repair for corrupt tick cursor.
J437. M2 validate score: missing.
J438. It lacks validation for decision schema.
J439. It lacks validation for idempotency.
J440. It lacks validation for evidence paths.
J441. M2 audit score: partial.
J442. It writes tick summaries.
J443. It does not define a receipt chain.
J444. M2 why score: missing.
J445. Each decision needs a `why`.
J446. The `why` must link to queue item evidence.
J447. M2 `--info` score: missing.
J448. M2 `--examples` score: missing.
J449. M2 quickstart score: missing.
J450. M2 help score: missing.
J451. M2 completion score: missing.
J452. M2 `--json` score: missing.
J453. M2 `--robot-*` score: missing.
J454. M2 canonical-cli-scoping grade: C.
J455. It is closer than M1.
J456. It names the right control loop.
J457. It lacks command surface.
J458. One decision per tick is a good default.
J459. It prevents whack-a-mole.
J460. It preserves reviewability.
J461. It makes idempotency easier.
J462. It is not always enough.
J463. The rule should be "one decision group per tick."
J464. A decision group can contain independent no-op observations.
J465. A decision group can contain one dispatch.
J466. A decision group can contain one escalation.
J467. A decision group can contain one closeout.
J468. It should not contain five unrelated dispatches.
J469. It should not contain a dispatch and an irreversible repair.
J470. It should not contain a retry storm.
J471. The tick interval default of 600 seconds is plausible.
J472. It should be measured, not asserted.
J473. Health should report tick latency.
J474. Health should report time since last successful tick.
J475. Health should report decision age.
J476. Health should report input staleness by source.
J477. Health should report driver proof.
J478. Health should report lock owner.
J479. Health should report skipped ticks.
J480. Health should report overlapping tick prevention.
J481. Repair should clear stale locks only after proof.
J482. Repair should rebuild derived state from ledgers.
J483. Repair should never delete source ledgers.
J484. Repair should emit a repair receipt.
J485. Tick summaries should append to dispatch-log.
J486. Tick summaries should not require ops-log.
J487. Tick summaries can render into M4.
J488. Tick summaries can include the top 10.
J489. Tick summaries should include chosen action.
J490. Tick summaries should include skipped alternatives.
J491. Skipped alternatives matter.
J492. They prevent "newest message wins" from reappearing.
J493. Execute should be split from decide.
J494. `decide --dry-run` should be default.
J495. `apply` should require idempotency.
J496. `apply` should require evidence hashes.
J497. `apply` should emit the receipt before or atomically with action.
J498. If action is `ntm send`, use `ntm` tracking receipt.
J499. If action is reservation repair, call Agent Mail.
J500. If action is bead update, call `br --json`.
J501. If action is work ranking, call `bv --robot-*`.
J502. M2 should be the coordinator, not the owner of every action.

## M3 Audit: Top-10 Leverage Queue

J503. M3 current verdict: revise.
J504. M3 is the most useful primitive in the plan.
J505. M3 is also the easiest place to duplicate `bv`.
J506. `bv` already computes top recommendations.
J507. `bv` already computes impact.
J508. `bv` already computes blockers.
J509. `bv` already computes quick wins.
J510. `bv` already computes project health.
J511. `ntm` already wraps `bv` for coordination.
J512. The manager queue should compose fleet-level items.
J513. It should not recompute repo-level graph scores.
J514. M3 doctor score: missing.
J515. Queue doctor must report source freshness.
J516. Queue doctor must report missing repo indexes.
J517. Queue doctor must report invalid `bv` output.
J518. Queue doctor must report stale Agent Mail reservations.
J519. Queue doctor must report stale dispatch rows.
J520. M3 health score: partial.
J521. The plan names top-10 refreshed per tick.
J522. It lacks freshness thresholds.
J523. It lacks confidence thresholds.
J524. It lacks source-specific staleness.
J525. M3 repair score: missing.
J526. It lacks repair for missing `bv` cache.
J527. It lacks repair for broken bead DB sync.
J528. It lacks repair for missing Agent Mail project registration.
J529. M3 validate score: partial.
J530. It names output fields.
J531. It does not specify schema version.
J532. It does not specify score component schema.
J533. It does not specify evidence refs.
J534. M3 audit score: missing.
J535. Queue audits need explainable ranks.
J536. Queue audits need old-rank/new-rank diffs.
J537. Queue audits need "why not selected" records.
J538. M3 why score: missing.
J539. Each queue item needs `why`.
J540. Each queue item needs `why_not_higher`.
J541. Each queue item needs `why_not_lower`.
J542. M3 `--info` score: missing.
J543. M3 `--examples` score: missing.
J544. M3 quickstart score: missing.
J545. M3 help score: missing.
J546. M3 completion score: missing.
J547. M3 `--json` score: partial.
J548. It names JSON output.
J549. M3 `--robot-*` score: missing.
J550. It must expose robot schema.
J551. M3 canonical-cli-scoping grade: C+.
J552. It can become an A by demoting itself.
J553. The score formula should start with `bv`.
J554. The manager should annotate, not replace.
J555. Per-repo bead candidate comes from `bv --robot-triage`.
J556. Cross-repo dispatch age comes from dispatch-log.
J557. Trauma promotion candidate comes from fuckup-log or doctor JSON.
J558. Reservation risk comes from Agent Mail.
J559. Pane freeze risk comes from `ntm` attention.
J560. Joshua request comes from the Joshua request ledger.
J561. Audit gap comes from flywheel doctor JSON.
J562. Each source keeps authority.
J563. The manager only ranks across sources.
J564. The queue item type should be explicit.
J565. Type `bead_next`.
J566. Type `dispatch_overdue`.
J567. Type `fuckup_promotion`.
J568. Type `reservation_expiring`.
J569. Type `pane_frozen`.
J570. Type `audit_gap`.
J571. Type `joshua_request`.
J572. Type `human_blocker`.
J573. Every type needs an owning action primitive.
J574. `bead_next` owner is `bv` plus `br`.
J575. `dispatch_overdue` owner is `flywheel-loop`.
J576. `fuckup_promotion` owner is `flywheel-loop doctor` and INCIDENTS ladder.
J577. `reservation_expiring` owner is Agent Mail.
J578. `pane_frozen` owner is `ntm`.
J579. `audit_gap` owner is `flywheel-loop doctor`.
J580. `joshua_request` owner is the requests ledger.
J581. `human_blocker` owner is escalation ladder.
J582. The plan's Donella-mode and Jeff-mode names are unnecessary.
J583. One score is enough.
J584. The score can expose components.
J585. Component `impact_score` can come from `bv`.
J586. Component `age_score` can come from dispatch age.
J587. Component `urgency_score` can come from overdue thresholds.
J588. Component `confidence_score` can come from evidence completeness.
J589. Component `cost_score` can be estimated from action type.
J590. Component `risk_score` can penalize missing evidence.
J591. Component `mission_anchor_score` can be mandatory where required.
J592. The formula should be boring.
J593. Boring scores can be debugged.
J594. Pluggable scoring can be added later.
J595. Pluggable scoring on day one becomes policy drift.
J596. Top-10 size is fine as a renderer default.
J597. The decision engine should accept `--limit`.
J598. The robot output should include all candidates or a cursor.
J599. The markdown surface can show ten.
J600. The JSON surface should preserve more evidence.

## M4 Audit: Joshua-Readable Shared Surface

J601. M4 current verdict: keep, shrink.
J602. This is the plan's best user-facing artifact.
J603. The surface should be generated.
J604. The surface should not be edited by humans.
J605. The surface should not be source of truth.
J606. M4 doctor score: partial.
J607. Doctor should verify markdown and JSON agree.
J608. Doctor should verify the JSON schema.
J609. Doctor should verify freshness.
J610. Doctor should verify atomic rewrite receipts.
J611. M4 health score: partial.
J612. Health should report last render time.
J613. Health should report source timestamps.
J614. Health should report current verdict.
J615. M4 repair score: easy.
J616. Repair should regenerate from manager-state JSON.
J617. Repair should never edit source ledgers.
J618. M4 validate score: partial.
J619. Validate should compare markdown hash to JSON input hash.
J620. Validate should fail on stale source paths.
J621. M4 audit score: missing.
J622. Audit should diff last two reports.
J623. Audit should explain rank movement.
J624. Audit should show selected vs skipped actions.
J625. M4 why score: partial.
J626. The report can show rationale.
J627. The command needs machine `why`.
J628. M4 `--info` score: missing.
J629. M4 `--examples` score: missing.
J630. M4 quickstart score: missing.
J631. M4 help score: missing.
J632. M4 completion score: missing.
J633. M4 `--json` score: present if mirror exists.
J634. M4 `--robot-*` score: missing unless explicit.
J635. M4 canonical-cli-scoping grade: B-.
J636. M4 should become a renderer over manager-state.
J637. Markdown is right for Joshua.
J638. JSON is right for agents.
J639. Both must be from one JSON object.
J640. Do not allow markdown-only state.
J641. Do not scrape markdown.
J642. Do not make the pane chat the report.
J643. Do not make morning ritual a separate store.
J644. The path should probably be repo-local first.
J645. Proposed repo path: `.flywheel/manager-loop-state.md`.
J646. Proposed repo path: `.flywheel/manager-loop-state.json`.
J647. A global mirror can aggregate later.
J648. Global state before repo-local truth creates ambiguity.
J649. The report should show top-10.
J650. The report should show last decision.
J651. The report should show last five ticks.
J652. The report should show health.
J653. The report should show pending Joshua decisions.
J654. The report should show no human blocker if safe local work remains.
J655. The report should show evidence paths.
J656. The report should show stale sources.
J657. The report should show queue churn.
J658. The report should show current driver proof.
J659. It should not include long logs.
J660. It should be skimmed in 30 seconds.
J661. It should link to deeper JSON.
J662. It should link to bead IDs.
J663. It should link to dispatch rows.
J664. It should link to fuckup classes.
J665. It should link to reservation conflicts.
J666. It should link to `ntm` pane state evidence.

## Substrate Ownership Review

J667. Ownership rule: one authority per fact.
J668. Dispatch fact owner: `flywheel-loop` dispatch-log.
J669. Worker callback owner: existing dispatch callback contract until parity.
J670. Trauma fact owner: fuckup-log.
J671. Trauma promotion owner: flywheel doctor plus INCIDENTS ladder.
J672. Bead fact owner: `br`.
J673. Bead ranking owner: `bv`.
J674. Pane state owner: `ntm`.
J675. Pane actuation owner: `ntm`.
J676. File reservation owner: Agent Mail.
J677. Mailbox state owner: Agent Mail.
J678. Driver proof owner: flywheel-loop L57 checks plus `ntm` evidence.
J679. Manager policy owner: `flywheel-loop`.
J680. Manager markdown owner: renderer only.
J681. Ops-log authority owner: nobody in the current plan.
J682. That is the problem.
J683. The manager should not own bead scores.
J684. The manager should not own reservation expiry logic.
J685. The manager should not own pane freeze detection internals.
J686. The manager should not own issue dependency graphs.
J687. The manager should own cross-source queue selection.
J688. The manager should own decision receipts.
J689. The manager should own renderer state.
J690. The manager should own skipped-candidate explanation.
J691. The manager should own tick idempotency.
J692. The manager should own aggregate health.
J693. The manager should own "what should happen next."
J694. The manager should not own "what is true."
J695. Truth remains in source ledgers.
J696. Policy composes truth.
J697. That is the clean boundary.
J698. The plan currently collapses truth and policy into ops-log.
J699. Split them.
J700. Source facts stay put.
J701. Manager state is derived.
J702. Decision receipts are durable.
J703. Reports are rendered.
J704. Repairs regenerate derived state.
J705. Audits compare derived state to source facts.
J706. That is repairable.

## Working-Sibling Diffs

J707. Sibling 1: `ntm` attention feed.
J708. Difference: it senses and actuates, it does not plan.
J709. Manager should consume it.
J710. Manager should not fork it.
J711. Sibling 2: `ntm` robot attention command.
J712. Difference: it exposes operator-ready events.
J713. Manager should use it as a source.
J714. Sibling 3: `ntm` coordinator assign.
J715. Difference: it auto-assigns using `bv` recommendations.
J716. Manager should study the assignment receipts.
J717. Sibling 4: `ntm` work triage adapter.
J718. Difference: it already summarizes ready work.
J719. Manager should reuse the adapter where possible.
J720. Sibling 5: `bv --robot-triage`.
J721. Difference: it is repo-level work intelligence.
J722. Manager should lift one or more `bv` candidates per repo.
J723. Sibling 6: `bv --robot-next`.
J724. Difference: it gives the single best local candidate.
J725. Manager can use it for low-cost fallback.
J726. Sibling 7: `bv --robot-alerts`.
J727. Difference: it surfaces health and attention.
J728. Manager should fold alerts into candidate types.
J729. Sibling 8: `br` JSON.
J730. Difference: it owns bead status and deps.
J731. Manager should not use `br ready` as queue input.
J732. Manager should use `bv`.
J733. Sibling 9: Agent Mail reservations.
J734. Difference: it owns lock TTLs and conflicts.
J735. Manager should read or request via Agent Mail.
J736. Sibling 10: `flywheel-loop doctor --json`.
J737. Difference: it already aggregates health and fuckup triage.
J738. Manager should consume doctor packets.
J739. Sibling 11: `.flywheel/dispatch-log.jsonl`.
J740. Difference: it is already dispatch decision history.
J741. Manager decisions should append there.
J742. Sibling 12: `~/.local/state/flywheel/fuckup-log.jsonl`.
J743. Difference: it is already trauma event history.
J744. Manager should not duplicate fuckup rows.
J745. The closest complete sibling is `ntm` coordinator assign.
J746. It proves `bv` integration exists.
J747. It proves event emission exists.
J748. It proves assignment can be automated.
J749. But it is not fleet policy.
J750. That gap belongs in `flywheel-loop`.
J751. The closest reporting sibling is the morning report family.
J752. It proves markdown surfaces are useful.
J753. But report truth must be JSON-first.
J754. The closest write sibling is `fw_jsonl_append_validated`.
J755. It proves JSONL write validation exists.
J756. Use it instead of inventing an ops-log writer.
J757. The closest receipt sibling is franken decision receipt.
J758. It proves hash-chained decisions are expected in Jeff's corpus.
J759. Borrow the shape, not the code.
J760. Working-sibling conclusion: build a composer, not a new ecosystem.

## Atomic Write and Ledger Receipt Audit

J761. The plan says temp plus fsync plus os.replace.
J762. Good.
J763. The plan also says append-only per row.
J764. For append-only files, os.replace is not the only safe path.
J765. Append with a stable lock can also be safe.
J766. The existing local primitive is `fw_jsonl_append_validated`.
J767. Use that.
J768. Do not allow ad hoc `printf >>`.
J769. Do not allow every language to invent append semantics.
J770. Do not lock the data-file inode across rename.
J771. Use a stable sidecar lock if rewriting.
J772. Hold the lock through write.
J773. Hold the lock through fsync.
J774. Hold the lock through rename.
J775. Fsync the parent directory.
J776. Validate the line before append.
J777. Validate the file after append.
J778. On mismatch, emit a repairable failure.
J779. On retry, use idempotency key.
J780. M2 needs a tick id.
J781. M2 needs an idempotency key.
J782. M2 needs a previous receipt hash.
J783. M2 needs an input state hash.
J784. M2 needs selected queue item hash.
J785. M2 needs output action hash.
J786. M2 needs decision rationale.
J787. M2 needs evidence refs.
J788. M2 needs no-op reason.
J789. M2 needs rollback hint where possible.
J790. M2 needs actuation receipt path.
J791. If `ntm send` is used, record the `ntm` tracking receipt.
J792. If Agent Mail is used, record message or reservation id.
J793. If `br` is used, record bead id and JSON output hash.
J794. If `bv` is used, record robot output hash.
J795. If doctor is used, record doctor packet hash.
J796. M4 JSON mirror must be atomic rewrite.
J797. M4 markdown mirror must be atomic rewrite.
J798. Markdown and JSON should share the same source hash.
J799. If render fails, leave the previous report intact.
J800. If source validation fails, write a degraded health row.
J801. Do not overwrite good state with partial state.
J802. Do not report healthy from stale derived state.
J803. Do not escalate without the probe ledger.
J804. Do not call Joshua a blocker while safe local work remains.
J805. Do not let the manager surface become a transcript.
J806. The ledger receipt is the transcript.
J807. The report is a view.
J808. The source ledgers are the facts.

## Counter-Thesis Evaluation

J809. Counter-thesis: the manager architecture is already shipped in fragmented form.
J810. Finding: mostly true.
J811. `bv` covers repo-level top work.
J812. `br` covers issue persistence.
J813. Agent Mail covers reservations and messaging.
J814. `ntm` covers pane sensing and actuation.
J815. `flywheel-loop doctor` covers health and triage.
J816. dispatch-log covers dispatch events.
J817. fuckup-log covers trauma events.
J818. L57 covers driver proof.
J819. L52 covers issue-to-bead receipts.
J820. L53 covers blocker-to-fuckup receipts.
J821. L54 covers skill deep-dive before blocked.
J822. L56 covers fuckup-to-incident-to-rule promotion.
J823. The missing thing is not another raw event store.
J824. The missing thing is a manager read model.
J825. The missing thing is a queue crosswalk.
J826. The missing thing is a decision receipt.
J827. The missing thing is a Joshua-readable renderer.
J828. That is a small cut.
J829. It also matches Donella.
J830. Donella wants information flow.
J831. Information flow can be a view.
J832. It does not have to be a new truth store.
J833. Donella wants system goal clarity.
J834. The manager-state command gives that.
J835. Donella wants self-organization.
J836. `bv` plus doctor plus attention feed already self-organize locally.
J837. The manager composes the local self-organization.
J838. Donella wants rule changes.
J839. The rule change should be "manager decisions are receiptful."
J840. The rule change should not be "everybody writes a new log."
J841. So the counter-thesis is endorsed.
J842. Endorsed with one caveat.
J843. The current substrate is fragmented enough to hide top-level truth.
J844. Fragmentation still hurts.
J845. But the fix is indexing and composing.
J846. The fix is not centralizing ownership.

## Specific Revisions

J847. Revision 1: replace M1 authority claim.
J848. Diff:
J849. `- Workers, watchers, validators, doctor, integrator all append rows.`
J850. `+ Source systems keep owned ledgers; manager-state derives a normalized view.`
J851. Revision 2: replace "no other channel" sentence.
J852. Diff:
J853. `- no other channel for orchestrator-visible signals.`
J854. `+ orchestrator-visible signals are read through manager-state adapters over canonical ledgers.`
J855. Revision 3: move stock_delta ownership.
J856. Diff:
J857. `- stock_delta is the only place a writer asserts impact.`
J858. `+ source writers report facts; manager-state computes stock deltas from owned evidence.`
J859. Revision 4: rename top-level CLI.
J860. Diff:
J861. `- manager-loop doctor`
J862. `+ flywheel-loop manager doctor --json`
J863. Revision 5: add read-only first ship.
J864. Diff:
J865. `+ Phase 1 ships flywheel-loop manager state --json as read-only.`
J866. `+ No worker callback migration begins until state parity is measured.`
J867. Revision 6: add decision receipt.
J868. Diff:
J869. `+ Every manager tick emits schema=manager_decision_receipt/v1.`
J870. `+ Receipt includes tick_id, idempotency_key, input_hash, selected_item_hash, decision, rationale, evidence_refs, actuation_receipt_ref, previous_receipt_hash.`
J871. Revision 7: add dry-run/apply split.
J872. Diff:
J873. `- execute(decision)`
J874. `+ decide --dry-run writes no side effects; apply executes one idempotent decision and writes a receipt.`
J875. Revision 8: demote scoring modes.
J876. Diff:
J877. `- Donella-mode default = stock-impact * urgency / cost. Jeff-mode default = PageRank * unblocks / age.`
J878. `+ One score with visible components; repo-level work impact comes from bv, cross-source urgency comes from manager policy.`
J879. Revision 9: constrain queue authority.
J880. Diff:
J881. `+ manager queue items carry source_owner and repair_owner fields.`
J882. `+ manager never mutates source ledgers except through owner CLIs.`
J883. Revision 10: add robot contract.
J884. Diff:
J885. `+ flywheel-loop manager state --robot-schema`
J886. `+ flywheel-loop manager state --robot-examples`
J887. `+ flywheel-loop manager state --json`
J888. Revision 11: add CLI triad up front.
J889. Diff:
J890. `- Doctor / health / repair for manager-loop itself ships after M2.`
J891. `+ doctor, health, repair, validate, audit, why, info, examples, quickstart, help, completion ship with the first manager primitive.`
J892. Revision 12: keep callbacks during parity.
J893. Diff:
J894. `- Workers stop sending ntm send callbacks.`
J895. `+ Workers keep callbacks until manager-state ingests dispatch-log, Agent Mail, and ntm attention with measured parity for N ticks.`
J896. Revision 13: define parity.
J897. Diff:
J898. `+ parity = manager-state sees every DONE/BLOCKED dispatch callback, every reservation conflict, every fuckup-log blocker, and every stale pane alert within two tick intervals.`
J899. Revision 14: define stale source thresholds.
J900. Diff:
J901. `+ state.sources[].staleness_class = fresh|stale|missing|invalid.`
J902. Revision 15: define report regeneration.
J903. Diff:
J904. `+ manager report repair regenerates markdown/json from the latest valid manager-state JSON and never edits source ledgers.`
J905. Revision 16: add skipped-candidate receipts.
J906. Diff:
J907. `+ decision_receipt.skipped_candidates[] = {rank, id, reason_not_selected}.`
J908. Revision 17: add no-op tick.
J909. Diff:
J910. `+ no-op is an explicit decision with rationale and source freshness evidence.`
J911. Revision 18: add driver proof.
J912. Diff:
J913. `+ manager health includes driver_status=verified|marker_only|stale|missing.`
J914. Revision 19: add upstream issue gate.
J915. Diff:
J916. `+ upstream issues are drafts only; no PRs, no pushes, no patches to ntm/bv/br/agent-mail remotes.`
J917. Revision 20: add migration hold.
J918. Diff:
J919. `+ CALLBACKS_DEAD is gated on manager-state parity, not on M1 file creation.`

## Minimum Viable Cut

J920. Keep 1: `flywheel-loop manager state --json`.
J921. It reads doctor JSON.
J922. It reads `bv --robot-triage`.
J923. It reads `ntm robot-attention`.
J924. It reads dispatch-log.
J925. It reads fuckup-log.
J926. It reads Agent Mail reservation state where available.
J927. It emits a single JSON object.
J928. It is read-only.
J929. It can be validated.
J930. It can be regenerated.
J931. It solves 50 percent alone.
J932. Keep 2: `flywheel-loop manager decide --dry-run --json`.
J933. It selects one decision group.
J934. It emits a receipt candidate.
J935. It explains skipped candidates.
J936. It performs no action.
J937. It makes the manager reviewable.
J938. It solves another 20 percent.
J939. Keep 3: `flywheel-loop manager report --format markdown --atomic`.
J940. It renders the same JSON.
J941. It gives Joshua the morning surface.
J942. It gives orchestrators a shared surface.
J943. It solves another 10 percent.
J944. Defer 1: new ops-log as primary authority.
J945. Defer 2: killing xpane callbacks.
J946. Defer 3: pluggable scoring modes.
J947. Defer 4: global multi-orchestrator quorum.
J948. Defer 5: universal writer library in every language.
J949. Defer 6: CALLBACKS_DEAD migration.
J950. Defer 7: cross-repo top-k beyond available `bv` outputs.
J951. Defer 8: any upstream patches.
J952. The Pareto cut is not glamorous.
J953. That is why it is likely to ship.
J954. A read model is cheap.
J955. A decision receipt is bounded.
J956. A renderer is useful.
J957. A new bus is expensive.
J958. Avoid the expensive bus.

## Upstream Issue Drafts

J959. Draft issue 1 target: `bv`.
J960. Draft issue 1 title: Stable robot top-N contract for fleet manager consumers.
J961. What happened: flywheel manager-state needs to consume top-N work candidates across repos.
J962. Repro: call `bv --robot-triage` and consume recommendations as a machine contract.
J963. Expected: documented stable schema for top-N candidates, source score components, evidence refs, and limit handling.
J964. Observed: useful robot data exists, but manager consumers need a pinned contract and examples.
J965. Evidence: `beads_viewer/README.md:181-280` hash `eb0daa71fc1ff46c130a90542bf0495a9d0aeb2c5f260ec63b29c3207f9aa660`.
J966. Evidence: `beads_viewer/README.md:1081-1180` hash `a2de25c9dbbf657537926090f83a29bcb9448537db353f9dfa6c035a76bc4daa`.
J967. Cost: without stable schema, manager-state either scrapes or reimplements ranking.
J968. Tracking: create local flywheel bead if accepted by planning lane.
J969. Out of scope: no ranking rewrite requested.
J970. Out of scope: no PR from this review.
J971. Draft issue 2 target: `ntm`.
J972. Draft issue 2 title: Expose tracked actuation receipts as manager-state input.
J973. What happened: manager decisions need to link a chosen action to the actual pane actuation receipt.
J974. Repro: manager selects an `ntm send` action and must verify delivery without scraping pane chat.
J975. Expected: robot-mode actuation receipt includes stable id, target, command hash, delivery proof, and replay lookup.
J976. Observed: robot attention and send tracking exist, but manager-state needs the receipt contract pinned.
J977. Evidence: `ntm/docs/attention-feed-contract.md:1-100` hash `d034f26f66b10d0d7ac51b6d3121b7a141790baa18af1750cbcb1bef184e6a0a`.
J978. Evidence: `ntm/internal/robot/robot.go:2054-2098` hash `d8476b1129fa11594da311f0947217046a33b37ee15c7cac08a1ac7b51caf553`.
J979. Cost: without a stable receipt, manager decisions can be logged but not proven.
J980. Tracking: create local flywheel bead if accepted by planning lane.
J981. Out of scope: no policy planner inside `ntm`.
J982. Out of scope: no PR from this review.
J983. No Agent Mail upstream issue is needed now.
J984. Agent Mail already owns reservations strongly enough.
J985. No `br` upstream issue is needed now.
J986. `br` is not the ranking surface.
J987. No Socraticode upstream issue is needed now.
J988. Socraticode did its job.

## Canonical CLI Surface Required Before Ship

J989. Required: `flywheel-loop manager doctor --json`.
J990. Required: `flywheel-loop manager health --json`.
J991. Required: `flywheel-loop manager repair --dry-run --json`.
J992. Required: `flywheel-loop manager validate --strict --json`.
J993. Required: `flywheel-loop manager audit --since <duration> --json`.
J994. Required: `flywheel-loop manager why <decision_id> --json`.
J995. Required: `flywheel-loop manager info --json`.
J996. Required: `flywheel-loop manager examples`.
J997. Required: `flywheel-loop manager quickstart`.
J998. Required: `flywheel-loop manager help`.
J999. Required: shell completion updates.
J1000. Required: `flywheel-loop manager upstream-report --json`.
J1001. Required: `flywheel-loop manager state --json`.
J1002. Required: `flywheel-loop manager state --robot-schema`.
J1003. Required: `flywheel-loop manager state --robot-examples`.
J1004. Required: `flywheel-loop manager decide --dry-run --json`.
J1005. Required: `flywheel-loop manager apply --idempotency-key <key> --json`.
J1006. Required: `flywheel-loop manager report --format markdown --atomic`.
J1007. Required: every mutating command has dry-run.
J1008. Required: every mutating command has audit output.
J1009. Required: every mutating command has idempotency semantics.
J1010. Required: every mutating command identifies source owner.
J1011. Required: every repair command can explain what it touched.
J1012. Required: every validation failure has recommended action.
J1013. Required: health emits valid JSON even when unhealthy.
J1014. Required: stale source does not crash state rendering.
J1015. Required: missing optional source is degraded, not fatal.
J1016. Required: missing required source is broken with repair hint.
J1017. Required: `--json` is not a wrapper around markdown.
J1018. Required: markdown is rendered from JSON.

## Final Verdict

J1019. The plan should not ship as M1-M4 in the current order.
J1020. It should not start by creating `ops-log.jsonl`.
J1021. It should not start by changing worker behavior.
J1022. It should not start by killing callbacks.
J1023. It should not start by centralizing facts.
J1024. It should start by composing facts.
J1025. It should start read-only.
J1026. It should prove parity.
J1027. It should then add decision receipts.
J1028. It should then add the Joshua report.
J1029. Only after that should migration touch callbacks.
J1030. That revised plan is small enough to be real.
J1031. That revised plan matches Jeff's substrate discipline.
J1032. That revised plan matches Donella's information-flow diagnosis.
J1033. That revised plan matches Joshua's taste for practical leverage.
J1034. Public score: 9.5.
J1035. Jeff authenticity score: 9.6.
J1036. Donella compatibility score: 9.5.
J1037. Joshua taste score: 9.6.
J1038. Composite score: 9.6.
J1039. Final label: revise.
J1040. The architecture is one composing primitive plus receipt discipline.
J1041. Build that.
J1042. Do not build the bus first.
