---
title: "R1 Cross-Plan Audit: Manager-Loop x Fleet-Autonomy"
type: plan
created: 2026-05-06
frontmatter_source: scaffold-doc-frontmatter
---

## Contents

- [Executive Verdict](#executive-verdict)
- [Layer-Leak Findings](#layer-leak-findings)
- [Contract Gaps](#contract-gaps)
- [Naming Collisions](#naming-collisions)
- [Dependency Analysis](#dependency-analysis)
- [Stock And Loop Conflicts](#stock-and-loop-conflicts)
- [Loop Topology Review](#loop-topology-review)
- [Global Ship Sequence](#global-ship-sequence)
- [Skillos Integration Contract](#skillos-integration-contract)
- [Mobile-Eats Mission-Coverage Compiler Placement](#mobile-eats-mission-coverage-compiler-placement)
- [Canonical CLI Scoping Cross-Check](#canonical-cli-scoping-cross-check)
- [Finding Severity Table](#finding-severity-table)
- [Convergence Call](#convergence-call)
- [Compact DAG](#compact-dag)
- [Interface Contract Recommendations](#interface-contract-recommendations)
- [Final Decision](#final-decision)
- [Callback Metrics](#callback-metrics)
# R1 Cross-Plan Audit: Manager-Loop x Fleet-Autonomy

A001. Executive verdict: contradictions-found-revise.
A002. Replan needed: no.
A003. Proceed to per-plan audit r2 immediately: no.
A004. Re-integrate before r2: yes.
A005. Critical findings: 0.
A006. High findings: 6.
A007. Medium findings: 8.
A008. Low findings: 3.
A009. Total findings: 17.
A010. Layer leaks: 4.
A011. Contract gaps: 5.
A012. Naming collisions: 4.
A013. Dependency cycles: 0.
A014. Stock conflicts: 3.
A015. Global ship-first implementation primitive: P1+P2.
A016. Global pre-implementation action: G0-cross-plan-contract-freeze.
A017. Composite self-grade: 9.6.
A018. Audit scope: interfaces between two integrated plans only.
A019. No source edits beyond this plan-space audit.
A020. No bead creation.
A021. No Joshua questions.
A022. Socraticode preflight: 4 queries, limit 10 each, flywheel index 694 chunks.
A023. Skills consulted: jeff-convergence-audit.
A024. Skills consulted: jeff-swarm-ops.
A025. Skills consulted: donella-meadows-systems-thinking.
A026. Skills consulted: canonical-cli-scoping.
A027. Skills consulted: multi-pass-bug-hunting.
A028. Donella stock rule used: name stocks, inflows, outflows, feedback, delay.
A029. Jeff convergence rule used: do not dispatch beads from unaudited plan interfaces.
A030. Multi-pass method used: pass 1 layer scan, pass 2 contract scan, pass 3 stock/loop scan.
A031. Alias ML: `.flywheel/PLANS/manager-loop-architecture-2026-05-05/00-PLAN.md`.
A032. Alias FA: `.flywheel/PLANS/fleet-autonomy-v1-2026-05-05/00-PLAN.md`.
A033. Alias S25: `.flywheel/PLANS/fleet-autonomy-v1-2026-05-05/cross-orch-input/skillos-1-2026-05-05T1525Z.md`.
A034. Alias S55: `.flywheel/PLANS/manager-loop-architecture-2026-05-05/cross-orch-input/skillos-1-2026-05-05T1555Z.md`.
A035. Alias ME45: `.flywheel/PLANS/fleet-autonomy-v1-2026-05-05/cross-orch-input/mobile-eats-1-2026-05-05T1545Z.md`.
A036. Summary: the two plans can coexist.
A037. Summary: their layer model is mostly coherent.
A038. Summary: the largest concrete error is stale M-number references in Fleet.
A039. Summary: the largest behavioral risk is P1/P2 claiming to write ops-log rows before A1 exists.
A040. Summary: the largest schema risk is A1 missing explicit P1/P2 fields.
A041. Summary: the largest Donella risk is duplicate stock measurement without one metric owner.
A042. Summary: the clean correction is a contract freeze, not a replan.

## Executive Verdict

A043. Verdict: contradictions-found-revise.
A044. The plans agree on the core layer separation.
A045. ML says fleet-autonomy remains substrate selection and watcher safety at ML:751-752.
A046. FA says manager-loop owns the control plane while Fleet owns stop-bleed selector facts at FA:31-35.
A047. The plans agree that callbacks are not the long-term control path.
A048. ML keeps callbacks alive until parity at ML:21-25 and ML:587-660.
A049. FA explicitly deprecates callback-as-orchestrator-input at FA:45-54 and FA:469-474.
A050. The plans agree that mission-anchor closure is the main stock.
A051. ML names verified mission-anchor closure as primary stock at ML:85-89 and ML:934-977.
A052. FA names verified mission-anchor closure value at FA:63-74 and FA:731-740.
A053. The plans agree that skillos is separate.
A054. ML cites skillos as capability control plane at ML:751-757.
A055. FA consumes the earlier skillos observability gaps without absorbing skillos at FA:88-90 and FA:433-447.
A056. The plans agree that mission-coverage-compiler is separate.
A057. ML says it does not absorb the compiler at ML:758-760.
A058. FA says the compiler is separate at FA:83-87 and FA:463-465.
A059. The plans disagree in command and primitive naming.
A060. ML renamed primitives A0-A5 at ML:100-107 and ML:181-183.
A061. FA still references manager-loop M1/M3/M4/M2 at FA:52 and FA:516-519.
A062. The plans disagree in global ship order wording.
A063. ML says A0 ships first at ML:14 and ML:666-680.
A064. FA says P1+P2 ships first at FA:17 and FA:498-516.
A065. This is not a fundamental conflict if ship-first is scoped.
A066. It is a cross-plan bug if implementation workers read both literally.
A067. The global answer: G0 contract freeze, then P1+P2 implementation first.
A068. Why P1+P2 first: it stops the known wrong-work selector and emits better inputs.
A069. Why not A0 first globally: A0 is read-only and can run in parallel, but it should consume corrected selector receipts.
A070. Why not A1 first: ML explicitly demotes A1 to mirror/index and delays authority at ML:181-205 and ML:690-692.
A071. Why not A3 first: ML defers tick apply until state, scoring, surface, and parity gates exist at ML:390-501 and ML:666-676.
A072. Convergence call: re-integrate before r2.
A073. Required re-integration is small.
A074. It is a text and interface contract correction.
A075. It does not require new architecture.
A076. It does not require Joshua.

## Layer-Leak Findings

A077. LL1 severity: high.
A078. LL1 title: Fleet still names Manager primitives with obsolete M ids.
A079. ML evidence: Manager names A0-A5 and says A0 is the first primitive at ML:100-110.
A080. ML evidence: Manager ship order uses A0/A2/A4/A1/A5/A3 at ML:666-676.
A081. FA evidence: Fleet still says P1/P2 emit facts to manager-loop M1, M3, M4, and M2 at FA:52.
A082. FA evidence: Fleet wave 2 still says manager-loop M0/M1/M3/M4 integration at FA:516-519.
A083. Interface impact: workers can dispatch against non-existent or deprecated primitive names.
A084. Interface impact: M1 in the original plan meant ops-log; A1 now means ops-log mirror.
A085. Interface impact: M4 in old plan was shared surface; A4 now is renderer, while A0 owns manager-state.
A086. Fix: add a cross-plan alias table before implementation.
A087. Alias: old M1 -> A1 only when discussing ops-log mirror/index.
A088. Alias: old M2 -> A3 manager tick driver.
A089. Alias: old M3 -> A2 scoring governor and queue.
A090. Alias: old M4 -> A4 renderer, not A0 manager-state.
A091. Alias: old P3 status brain -> A0 state fields plus A4 projection.
A092. Verdict: revise before audit r2.
A093. LL2 severity: high.
A094. LL2 title: Fleet P2 claims direct ops-log rows before Manager A1 exists.
A095. ML evidence: A1 is mirror/index, not authority, at ML:181-205.
A096. ML evidence: A1 ships after A0, A2, and A4 at ML:666-670.
A097. ML evidence: new ops-log as primary authority is deferred at ML:690-692.
A098. FA evidence: P2 says it emits `redispatch_without_state_delta` and `selection_suppressed` ops-log rows at FA:261-263.
A099. FA evidence: Wave 1 must not build manager-loop M1/M3/M4 at FA:512-516.
A100. Interface impact: P1/P2 cannot both avoid manager-loop buildout and require A1 write availability.
A101. Correct interface: P1/P2 write selector/suppression receipts to existing dispatch-log or local selector receipt file.
A102. Correct interface: A0 reads those receipts directly.
A103. Correct interface: A1 imports them later as mirror/index rows.
A104. Fix wording: replace "P2 emits ops-log rows" with "P2 emits selector receipts; A1 imports them when present."
A105. Verdict: revise before r2.
A106. LL3 severity: medium.
A107. LL3 title: Fleet says P3 survives under manager-loop M4, but Manager splits state and renderer.
A108. ML evidence: A0 owns manager-state JSON, Markdown projection, and robot schema at ML:107-179.
A109. ML evidence: A4 is projection over manager-state JSON at ML:503-585.
A110. FA evidence: P3 is deprecated and survives as status schema/read model under manager-loop M4 at FA:266-306.
A111. FA evidence: M is superseded by manager-loop M4 renderer at FA:308-335.
A112. Interface impact: Fleet collapses A0 state and A4 renderer into one M4 bucket.
A113. Correct split: P3 status fields land in A0 manager-state.
A114. Correct split: M morning ritual lands in A4 renderer.
A115. Fix wording: "P3 survives under A0; M survives under A4."
A116. Verdict: revise before r2.
A117. LL4 severity: medium.
A118. LL4 title: Fleet overstates ops-log and manager-state as joint control-plane owners.
A119. ML evidence: A1 is mirror/index, no owned ledger replacement at ML:181-207.
A120. ML evidence: worker claims may not affect closure, health, or mission stock at ML:231-235.
A121. FA evidence: P3 replacement shape says manager-loop ops-log and manager-state own the control plane at FA:302-304.
A122. Interface impact: "ops-log owns control plane" invites A1 authority drift.
A123. Correct ownership: A0/A2/A3/A5 own manager policy surfaces; A1 mirrors evidence.
A124. Correct wording: "manager-loop owns control-plane policy; A1 is a validated input mirror."
A125. Verdict: revise wording.

## Contract Gaps

A126. CG1 severity: high.
A127. CG1 title: A1 schema does not explicitly include P1 selector fields.
A128. ML evidence: A1 schema minimum is listed at ML:237-264.
A129. ML evidence: A1 has generic evidence fields and mission fields but no selector-specific fields at ML:237-264.
A130. FA evidence: P1 required selector fields are listed at FA:163-175.
A131. FA evidence: P1 acceptance requires dispatch log preserve selector score and unblocks at FA:176-185.
A132. Missing fields: `selector_source`.
A133. Missing fields: `selector_data_hash`.
A134. Missing fields: `selector_score`.
A135. Missing fields: `selector_unblocks`.
A136. Missing fields: `selector_reasons`.
A137. Missing fields: `selector_candidate_id`.
A138. Missing fields: `selector_claim_command`.
A139. Missing fields: `selector_show_command`.
A140. Missing fields: `selector_runtime_path`.
A141. Missing fields: `selector_fallback_reason`.
A142. Missing fields: `selector_error`.
A143. Missing fields: `selection_freshness_ts`.
A144. Interface impact: A2 cannot reliably rank P1 facts if P1 fields hide inside `details`.
A145. Fix: A1 selector-event schema must embed `selector/*` object or use typed `event_type=selector_candidate`.
A146. Verdict: revise before r2.
A147. CG2 severity: high.
A148. CG2 title: A1 schema does not explicitly include P2 retry-state fields.
A149. ML evidence: A1 schema minimum stops at generic task/bead/evidence/correlation fields at ML:237-264.
A150. FA evidence: P2 required fields are listed at FA:225-248.
A151. FA evidence: P2 acceptance gates require state hash, retry predicate, visibility, and suppression routing at FA:249-260.
A152. Missing fields: `candidate_id`.
A153. Missing fields: `candidate_source`.
A154. Missing fields: `candidate_score`.
A155. Missing fields: `attempt_state_hash`.
A156. Missing fields: `attempt_count_window`.
A157. Missing fields: `state_changed_since_last_attempt`.
A158. Missing fields: `suppressed`.
A159. Missing fields: `suppression_reason`.
A160. Missing fields: `retry_after_seconds`.
A161. Missing fields: `retry_requires`.
A162. Missing fields: `upstream_gap`.
A163. Missing state predicates: dependency, child bead, reservation, repair, probe, blocker, callback, worker-started.
A164. Interface impact: Manager A5 cannot validate "redispatch without state delta" without exact state predicates.
A165. Fix: add `retry_state` object to A1 and A0 manager-state schema.
A166. Verdict: revise before r2.
A167. CG3 severity: high.
A168. CG3 title: blocker ownership split is present in Fleet but absent from Manager A1 schema.
A169. ML evidence: A1 schema minimum does not include blocker-owner fields at ML:237-264.
A170. ML evidence: A4 pending Joshua decisions require `safe_local_work_remaining` at ML:554-558.
A171. FA evidence: skillos gap integration requires `blocker_owner`, `work_blocked`, and `safe_local_work_remaining` at FA:433-438.
A172. S25 evidence: original gap says blocker-path ownership is not work-path block at S25:39-43.
A173. Interface impact: A4 cannot ask "why_not_agent" correctly without A1/A0 carrying safe local work status.
A174. Interface impact: Manager may re-create false human blockers.
A175. Fix: add `blocker_owner`, `work_blocked_at_source`, `safe_local_work_remaining`, `next_owner_for_blocker_path`, and `blocker_path_id`.
A176. Verdict: revise before r2.
A177. CG4 severity: medium.
A178. CG4 title: peer canonical log path is named but not actually a schema field.
A179. ML evidence: A1 says include peer canonical log path at registration time at ML:265-270.
A180. ML evidence: A1 schema fields do not name `peer_orch_canonical_log_path_known_at_registration_time` at ML:237-264.
A181. FA evidence: fleet-mail auth/search gap routes peer receipts into ops-log/manager input at FA:439-444.
A182. S55 evidence: recurrence explicitly asks for `peer_orch_canonical_log_path_known_at_registration_time` at S55:28 and S55:45-47.
A183. Interface impact: integration can pass prose review while schema consumers still cannot find peer log paths.
A184. Fix: add exact field name or document exact alias.
A185. Recommended field: `peer_orch_canonical_log_path`.
A186. Recommended field: `peer_orch_log_path_discovered_at`.
A187. Recommended field: `peer_orch_log_path_source`.
A188. Verdict: revise.
A189. CG5 severity: medium.
A190. CG5 title: minimal mission-anchor schema is still punted while both plans require it.
A191. ML evidence: A2 queue item requires `mission_anchor_id`, `mission_anchor_evidence_path`, and `mission_delta_expected` at ML:340-347.
A192. ML evidence: A2 permits typed substrate exceptions at ML:362-364.
A193. FA evidence: P1/P2 global goal depends on mission-anchor value at FA:70-74.
A194. FA evidence: Fleet punts exact minimal mission-anchor schema to audit at FA:688-690.
A195. ME45 evidence: full mission coverage compiler is separate and richer at ME45:33-57.
A196. Interface impact: P1/P2 can block on a schema that is declared out-of-scope for mission-coverage-compiler.
A197. Correct answer: do not wait for full mission-coverage-compiler.
A198. Minimal cross-plan schema: `mission_anchor_id`.
A199. Minimal cross-plan schema: `mission_anchor_evidence_path`.
A200. Minimal cross-plan schema: `mission_delta_expected`.
A201. Minimal cross-plan schema: `no_mission_anchor_reason`.
A202. Minimal cross-plan schema: `validation_probe`.
A203. Minimal cross-plan schema: `source_owner`.
A204. Verdict: revise before r2.

## Naming Collisions

A205. NC1 severity: high.
A206. NC1 collision: manager M ids versus A ids.
A207. ML evidence: Manager names A0-A5 at ML:100-107, ML:181-183, ML:293-295, ML:390-392, ML:503-505, and ML:587-589.
A208. FA evidence: Fleet still references M1/M3/M4/M2 at FA:52 and FA:516-519.
A209. Resolution: publish alias table in both plans.
A210. NC2 severity: medium.
A211. NC2 collision: `manager-state` versus renderer/shared surface.
A212. ML evidence: A0 outputs manager-state JSON and Markdown projection at ML:126-129.
A213. ML evidence: A4 renders over manager-state and is not source of truth at ML:503-585.
A214. FA evidence: P3 survives as read model under M4 and M survives as M4 renderer at FA:266-335.
A215. Resolution: A0 is state, A4 is renderer.
A216. NC3 severity: medium.
A217. NC3 collision: `ops-log` as mirror versus outcomes channel versus control plane.
A218. ML evidence: A1 is mirror/index only at ML:181-207 and authority is deferred at ML:690-692.
A219. FA evidence: P2 says emits ops-log rows at FA:261-263 and P3 replacement says ops-log owns control plane at FA:302-304.
A220. S55 evidence: skillos should cite ops-log as outcomes channel when it exists at S55:34.
A221. Resolution: `ops-log` means A1 mirror/index until a later explicit authority promotion.
A222. NC4 severity: low.
A223. NC4 collision: top-10 versus top-N versus fewer-than-ten mission-eligible items.
A224. ML evidence: A2 preserves more than top ten in JSON and renders top ten in Markdown at ML:334-335.
A225. ML evidence: fewer mission-eligible items is valid at ML:384-385 and ML:878-881.
A226. FA evidence: P6 and P1/P2 feed manager-loop but do not promise ten items at FA:399-427 and FA:131-198.
A227. Resolution: call the machine contract `top_n_candidates`; Markdown can render "top ten or fewer."

## Dependency Analysis

A228. DAG node: G0-cross-plan-contract-freeze.
A229. G0 inputs: ML integrated plan and FA integrated plan.
A230. G0 output: alias table, selector receipt schema, retry-state schema, blocker-owner schema, mission-anchor minimum schema.
A231. G0 reason: without G0, implementation workers can read M1/M3/M4 literally.
A232. DAG node: P1+P2 selector and retry stop-bleed.
A233. P1+P2 inputs: `bv --robot-next`, existing dispatch-log, callback/closure state, retry-state predicates.
A234. P1+P2 outputs: selector receipts and suppression receipts.
A235. FA evidence: P1+P2 ship now at FA:117-124, FA:131-198, and FA:199-264.
A236. ML evidence: Manager preserves P1 and P2 at ML:733-738.
A237. DAG node: A0 manager-state read model.
A238. A0 inputs: existing ledgers plus P1/P2 receipts when present.
A239. ML evidence: A0 read model inputs at ML:116-129.
A240. FA evidence: P1/P2 emit inputs manager-loop consumes at FA:112-113 and FA:487-552.
A241. DAG node: A2 scoring governor.
A242. A2 inputs: A0 state, `bv`, mission license, skillos optional recommendations.
A243. ML evidence: A2 inputs at ML:305-313.
A244. FA evidence: mission-anchor loop routes selector eligibility to manager scoring at FA:70-74.
A245. DAG node: A4 shared surface renderer.
A246. A4 inputs: A0 state, A2 queue, last decision receipts.
A247. ML evidence: A4 inputs at ML:511-519.
A248. FA evidence: M survives as renderer at FA:308-335.
A249. DAG node: A1 ops-log mirror/index.
A250. A1 inputs: owner ledgers, P1/P2 selector receipts, callback imports, manager decision receipts.
A251. ML evidence: A1 inflows at ML:190-199.
A252. FA evidence: P2 says selector/suppression facts need manager-loop visibility at FA:261-263.
A253. DAG node: A5 migration/callback cutover governor.
A254. A5 inputs: A0, A1, callback imports, parity gates.
A255. ML evidence: A5 gates at ML:625-635.
A256. FA evidence: callback parity and manual callback import are Wave 3 at FA:520-522.
A257. DAG node: A3 manager tick driver.
A258. A3 inputs: A0, A2, previous receipts, driver health.
A259. ML evidence: A3 inputs and delegation boundaries at ML:390-420.
A260. FA evidence: Fleet says manager-loop owns control plane at FA:31-35.
A261. DAG node: P4 reservation follow-up.
A262. P4 depends on P1/P2 and manager-state proof.
A263. FA evidence: P4 deferral at FA:337-365.
A264. ML evidence: P4 concern preserved and Agent Mail mutation remains owner at ML:742-744.
A265. DAG node: P5 pane recovery follow-up.
A266. P5 depends on P1/P2 and manager-state reducing ambiguity.
A267. FA evidence: P5 deferral at FA:367-397.
A268. ML evidence: P5 concern preserved and ntm owns actuation at ML:745-747.
A269. DAG node: P6 repair-bead aging follow-up.
A270. P6 depends on P1/P2 and manager queue proof.
A271. FA evidence: P6 deferral at FA:399-427.
A272. ML evidence: P6 concern preserved as queue signal at ML:748-750.
A273. DAG node: skillos mission-lock.
A274. skillos is independent and non-blocking.
A275. S55 evidence: proceed independently at S55:21-29 and S55:51-61.
A276. ML evidence: skillos remains separate but integrated at ML:751-757.
A277. FA evidence: skillos 15:25 is observability input, not scope takeover, at FA:88-90 and FA:433-447.
A278. DAG node: mission-coverage-compiler.
A279. compiler is separate and later.
A280. ME45 evidence: compiler routed to a separate plan input at ME45:49-57.
A281. ML evidence: manager does not absorb compiler at ML:758-760.
A282. FA evidence: Fleet does not expand into compiler at FA:83-87 and FA:463-465.
A283. Dependency cycle verdict: none after correcting P1/P2 output target.
A284. Conditional cycle warning: if P1/P2 literally require A1 ops-log rows before A1 exists, Wave 1 gains a dangling dependency.
A285. Conditional cycle evidence: FA:261-263 conflicts with ML:666-670.
A286. Correction breaks the cycle: P1/P2 write dispatch-log selector receipts; A1 imports later.

## Stock And Loop Conflicts

A287. SC1 severity: medium.
A288. SC1 title: verified mission-anchor closure has two narrators but only one metric owner is named implicitly.
A289. ML evidence: primary stock and health thresholds at ML:934-977.
A290. FA evidence: mission-anchor closure value is the goal at FA:63-74 and FA:731-740.
A291. Conflict: both plans describe the stock.
A292. Not a problem if Manager owns global metric and Fleet owns selector inputs.
A293. Required rule: Fleet may emit mission deltas; Manager computes global mission stock.
A294. Required field: `mission_delta_source`.
A295. Required field: `mission_delta_validation_state`.
A296. Required field: `mission_delta_computed_by=manager`.
A297. SC2 severity: medium.
A298. SC2 title: redispatch counts can diverge between selector receipts and manager duplicate dispatch metrics.
A299. ML evidence: A3 measures duplicate dispatch count at ML:421-428.
A300. FA evidence: P1 acceptance and P2 health depend on same-bead redispatch counts at FA:181-185 and FA:720-727.
A301. Conflict: selector-level repeated attempts and manager-level duplicate dispatches are not the same stock.
A302. Required split: Fleet owns `same_candidate_without_state_delta`.
A303. Required split: Manager owns `duplicate_decision_or_dispatch`.
A304. Required join: both share `candidate_id`, `attempt_state_hash`, and `dispatch_id`.
A305. SC3 severity: medium.
A306. SC3 title: callback/log divergence is both migration stock and fleet measurement stock.
A307. ML evidence: A1 and A5 own callback/log divergence at ML:188-211 and ML:587-660.
A308. FA evidence: callback cutover safety is measurement loop D at FA:742-751.
A309. Conflict: if Fleet reports parity and Manager reports parity separately, cutover can split-brain.
A310. Required owner: Manager A5 owns parity verdict.
A311. Required Fleet role: Fleet emits callback facts and selector receipts.
A312. Required rule: Fleet may not declare callback cutover safe.
A313. Donella loop read: all three conflicts are information-flow problems, not parameter problems.
A314. Donella loop read: the response is one owner per stock plus source refs.
A315. Donella loop read: reminders or prose warnings will not prevent split metrics.

## Loop Topology Review

A316. Loop 1 current failure: callback overload.
A317. ML evidence: callback noise became operating environment at ML:32-40.
A318. FA evidence: old callback reaction loop is deprecated at FA:75-83 and FA:469-474.
A319. Coherence: good.
A320. Interface rule: callbacks remain compatibility input until A5 permit.
A321. Loop 2 current failure: wrong selector and same-state redispatch.
A322. FA evidence: P1/P2 solve immediate selector loop at FA:80-82 and FA:131-264.
A323. ML evidence: A2/A5 consume retry-after-state-change and divergence gates at ML:733-738.
A324. Coherence: good if A3 dispatch uses P1/P2 eligibility.
A325. Interface rule: A3 must call selector eligibility or consume A2 queue items derived from it.
A326. Loop 3 current failure: mission compression.
A327. ME45 evidence: mission compressed to one stale blocker at ME45:13-16 and ME45:17-28.
A328. FA evidence: compiler separate, mission-anchor requirement consumed at FA:83-87 and FA:451-465.
A329. ML evidence: compiler not absorbed, mission refs required at ML:758-760 and ML:340-347.
A330. Coherence: good.
A331. Interface rule: minimal mission-anchor refs now, full compiler later.
A332. Loop 4 current failure: manual callbacks invisible to validation.
A333. S25 evidence: callback-grade misses manual callbacks by task id at S25:51-55.
A334. FA evidence: manual import is mandatory before cutover at FA:445-450.
A335. ML evidence: A5 cutover gate includes manual callbacks by task id at ML:625-635.
A336. Coherence: good.
A337. Interface rule: manual import belongs in A5 and is a prerequisite for cutover.
A338. Loop 5 current failure: skill/capability selection invisible to outcomes.
A339. S55 evidence: skillos asks for `skill_invoked` and `--robot-skill-recommend` at S55:23-29.
A340. ML evidence: A1 includes skill fields and A2 consumes skillos recommendations at ML:253-270 and ML:311-329.
A341. FA evidence: Fleet does not own skill selection; it only consumes skillos gaps as observability evidence at FA:88-90.
A342. Coherence: good with one caveat.
A343. Caveat: skillos cannot hard-depend on A1 ops-log before A1 ships.

## Global Ship Sequence

A344. G0: cross-plan contract freeze.
A345. G0 is plan-space only.
A346. G0 output 1: M-id to A-id alias table.
A347. G0 output 2: selector receipt schema.
A348. G0 output 3: retry-state receipt schema.
A349. G0 output 4: blocker-owner fields.
A350. G0 output 5: minimal mission-anchor schema.
A351. G0 output 6: explicit rule that A1 is mirror/index only.
A352. G0 cites ML A-id naming at ML:100-107.
A353. G0 cites FA stale M-id references at FA:52 and FA:516-519.
A354. G1: P1+P2 combined selector contract.
A355. G1 is the first implementation primitive.
A356. G1 uses `bv --robot-next` through the selector contract.
A357. G1 emits selector and suppression receipts to dispatch-log or selector receipt JSONL.
A358. G1 does not write A1-only ops-log rows directly.
A359. G1 cites FA ship-now P1/P2 at FA:117-124 and FA:498-516.
A360. G1 cites ML preserving P1/P2 at ML:733-738.
A361. G2: A0 manager-state read model.
A362. G2 reads existing ledgers plus G1 receipts.
A363. G2 is read-only.
A364. G2 cites ML A0 at ML:107-179.
A365. G2 cites FA Wave 2 manager integration at FA:516-519.
A366. G3: A2 scoring governor read-only.
A367. G3 consumes `bv`, mission anchor refs, selector receipts, and optional skillos recommendations.
A368. G3 cites ML A2 at ML:293-389.
A369. G3 cites FA mission selector loop at FA:70-74 and FA:731-740.
A370. G4: A4 shared surface renderer.
A371. G4 renders JSON/Markdown from A0/A2.
A372. G4 cites ML A4 at ML:503-585.
A373. G4 cites FA M deprecation into renderer at FA:308-335.
A374. G5: A1 ops-log compatibility mirror/index in shadow mode.
A375. G5 imports G1 receipts and owned ledgers.
A376. G5 cannot be authority yet.
A377. G5 cites ML A1 at ML:181-291.
A378. G5 corrects FA P2 row wording at FA:261-263.
A379. G6: A5 migration and callback parity governor.
A380. G6 imports manual callbacks and verifies parity.
A381. G6 cites ML A5 at ML:587-660.
A382. G6 cites FA Wave 3 callback parity at FA:520-522.
A383. G7: A3 manager tick driver dry-run.
A384. G7 selects but does not mutate beyond receipts.
A385. G7 cites ML A3 at ML:390-501.
A386. G8: A3 apply for one discretionary decision group per tick.
A387. G8 requires A0/A2/A4/A1/A5 green or explicit degraded permit.
A388. G8 cites ML ship order at ML:671-676.
A389. G9: A5 callback cutover permit.
A390. G9 can only happen after parity gates pass.
A391. G9 cites ML cutover gates at ML:625-635.
A392. G9 cites FA callback cutover safety at FA:742-751.
A393. G10: evaluate P4.
A394. G10 only if manager-state proves stale reservations are top bottleneck.
A395. G10 cites FA P4 deferral at FA:337-365.
A396. G11: evaluate P5.
A397. G11 only if manager-state proves frozen panes are top bottleneck.
A398. G11 cites FA P5 deferral at FA:367-397.
A399. G12: evaluate P6.
A400. G12 only if manager-state proves repair aging is top bottleneck.
A401. G12 cites FA P6 deferral at FA:399-427.
A402. G13: mission-coverage-compiler plan.
A403. G13 is separate and later.
A404. G13 cites ME45 route at ME45:49-57, FA:532-534, and ML:758-760.
A405. Ship-order conclusion: P1+P2 is first implementation.
A406. Ship-order conclusion: A0 is first manager-loop implementation.
A407. Ship-order conclusion: A1 is not first anywhere.
A408. Ship-order conclusion: callback death is not near-term.

## Skillos Integration Contract

A409. skillos layer: capability control plane.
A410. S55 evidence: skillos decides which skill/capability applies at S55:13-19.
A411. ML evidence: manager accepts `skill_invoked` and skill recommendation refs at ML:751-757.
A412. FA evidence: Fleet consumes skillos observability gaps, not skill selection policy, at FA:88-90 and FA:433-447.
A413. Contract 1: skillos mission-lock proceeds independently.
A414. Contract 2: skillos publishes `--robot-skill-recommend`.
A415. Contract 3: Manager A2 may consume skillos recommendations as a feature, not a gate.
A416. ML evidence: default before audit says skillos recommendation is a feature, not a gate, at ML:914-916.
A417. Contract 4: A1 records `skill_invoked` and `skill_recommendation_ref` once A1 exists.
A418. ML evidence: those fields exist at ML:253-254.
A419. Contract 5: until A1 exists, skillos outcomes use dispatch-log/manager-state refs, not hard dependency on ops-log.
A420. S55 caveat: ops-log is an outcomes channel "when it exists" at S55:34.
A421. Contract 6: fleet-mail auth/search recurrence belongs to manager/flywheel observability, not skillos local retry.
A422. S25 evidence: mail search failed through missing authenticated context at S25:45-49.
A423. S55 evidence: recurrence is real at S55:28 and S55:47.
A424. Contract 7: blocker-owner split must be represented in A0/A1 fields.
A425. S25 evidence: blocker owner differs from work blocked at S25:39-43.
A426. FA evidence: Fleet routes that to `blocker_owner`, `work_blocked`, `safe_local_work_remaining` at FA:433-438.
A427. ML gap: A1 must add those fields; A4 already needs safe-local-work context at ML:554-558.
A428. Skillos coherence verdict: coherent with one schema repair.

## Mobile-Eats Mission-Coverage Compiler Placement

A429. Placement verdict: correct.
A430. The compiler is owned by neither Manager nor Fleet.
A431. It is a separate plan.
A432. ME45 evidence: flywheel routes compiler doctrine to a new plan input at ME45:49-57.
A433. FA evidence: Fleet consumes only mission-anchor requirement and does not expand into compiler at FA:83-87 and FA:463-465.
A434. ML evidence: Manager requires mission anchor refs but compiler owns richer matrix at ML:758-760.
A435. Boundary: Manager A2 can require mission refs.
A436. Boundary: Fleet P1/P2 can refuse non-mission work unless substrate exception exists.
A437. Boundary: neither plan audits all closed beads against artifact/test/doc proof.
A438. Boundary: neither plan regenerates mission beads.
A439. Boundary: compiler later owns full coverage matrix.
A440. Risk: both plans currently rely on minimal mission anchor before compiler exists.
A441. Answer: freeze minimal schema in G0.
A442. Minimal schema is not the compiler.
A443. Minimal schema only prevents mission-blind dispatch.
A444. Full compiler later prevents mission compression at repo planning layer.
A445. Mobile-eats coherence verdict: coherent after minimal schema freeze.

## Canonical CLI Scoping Cross-Check

A446. ML has strong CLI scoping for A0.
A447. ML evidence: A0 CLI discipline and doctor fields at ML:155-166.
A448. FA references canonical CLI scoping for P3 retained fields at FA:284-286.
A449. Gap: Fleet still names obsolete manager-loop command groups.
A450. Gap evidence: FA references M0/M1/M3/M4 at FA:516-519.
A451. Required correction: use `flywheel-loop manager state`, `score`, `render`, `ops-log`, `migration`, and `tick` groups or whatever exact command tree Manager freezes.
A452. Required correction: Fleet implementation bead must not invent `flywheel-loop status` as independent P3.
A453. FA evidence: P3 standalone is deprecated at FA:266-306.
A454. ML evidence: manager primitive must be inspectable and repairable at ML:997-1001.
A455. CLI verdict: acceptable after alias and command freeze.

## Finding Severity Table

A456. F01 high: obsolete manager M ids in Fleet cross-plan references.
A457. F02 high: P2 ops-log direct-write claim before A1 exists.
A458. F03 medium: P3/M collapse A0 state and A4 renderer.
A459. F04 medium: ops-log named as control-plane owner.
A460. F05 high: A1 missing P1 selector fields.
A461. F06 high: A1 missing P2 retry-state fields.
A462. F07 high: A1 missing blocker-owner fields.
A463. F08 medium: peer canonical log path prose without schema field.
A464. F09 medium: minimal mission-anchor schema punted while required.
A465. F10 high: global ship order ambiguous without scoped interpretation.
A466. F11 medium: verified mission stock has duplicate narrators.
A467. F12 medium: redispatch count stock split not defined.
A468. F13 medium: callback parity stock needs Manager-only verdict.
A469. F14 low: top-10/top-N naming drift.
A470. F15 low: skillos outcomes channel should not hard-depend on A1 before it exists.
A471. F16 low: mission-coverage minimal schema may be mistaken for compiler.
A472. F17 medium: Fleet wave wording says no manager build but references manager M surfaces.

## Convergence Call

A473. Call: re-integrate before per-plan audit r2.
A474. Reason: the audit found interface contradictions, not architecture failure.
A475. Reason: implementation workers would misread primitive ids and write targets.
A476. Reason: schema gaps are concrete enough to patch in plan text.
A477. Reason: no new review lane is needed before correction.
A478. Required r1 closeout action 1: update Fleet plan references from M ids to A ids.
A479. Required r1 closeout action 2: add cross-plan alias table.
A480. Required r1 closeout action 3: declare P1/P2 receipt write path before A1.
A481. Required r1 closeout action 4: extend A1/A0 schema with selector fields.
A482. Required r1 closeout action 5: extend A1/A0 schema with retry-state fields.
A483. Required r1 closeout action 6: extend A1/A0 schema with blocker-owner fields.
A484. Required r1 closeout action 7: add minimal mission-anchor schema.
A485. Required r1 closeout action 8: set Manager A5 as sole callback parity verdict owner.
A486. Required r1 closeout action 9: define global sequence G0-G13.
A487. Required r1 closeout action 10: keep skillos and compiler non-blocking.
A488. Proceed to r2 only after those are reflected in the integrated plan text.
A489. Do not create beads from this audit yet.
A490. Do not patch watcher code from this audit yet.
A491. Do not file upstream issues from this audit yet.
A492. This audit is plan-space interface hardening.

## Compact DAG

A493. G0-cross-plan-contract-freeze has no source mutation.
A494. G0 precedes all implementation.
A495. P1+P2 depends on G0.
A496. A0 depends on G0 and can read pre-P1 ledgers but reaches exit with P1/P2 receipts.
A497. A2 depends on A0 plus minimal mission-anchor schema.
A498. A4 depends on A0 and A2.
A499. A1 depends on G0 and can ship after A0/A2/A4 define consumers.
A500. A5 depends on A0 and A1.
A501. A3 dry-run depends on A0 and A2.
A502. A3 apply depends on A0, A2, A4, A1, and A5 parity status.
A503. P4 depends on P1/P2 and A0 evidence.
A504. P5 depends on P1/P2 and A0 evidence.
A505. P6 depends on P1/P2 and A2/A0 evidence.
A506. skillos mission-lock is independent.
A507. skillos recommendations are optional A2 inputs.
A508. mission-coverage-compiler is independent and later.
A509. No cycle exists after P1/P2 receipt path correction.
A510. A dangling dependency exists before correction.

## Interface Contract Recommendations

A511. Contract name: `selector_receipt/v1`.
A512. Owner: Fleet P1.
A513. Consumer: A0 and A2.
A514. Required fields: all FA:163-175 fields.
A515. Required source refs: `source_owner=fleet-autonomy`.
A516. Required validation: dispatch-log append validates JSON.
A517. Contract name: `retry_state_receipt/v1`.
A518. Owner: Fleet P2.
A519. Consumer: A0, A2, A5.
A520. Required fields: all FA:225-248 fields.
A521. Required source refs: previous attempt ids.
A522. Required validation: state-change predicate must be typed.
A523. Contract name: `manager_state_fact/v1`.
A524. Owner: Manager A0.
A525. Consumer: A2/A4/A3/A5 and humans through A4.
A526. Required source refs: every fact has source ledger and hash.
A527. Contract name: `ops_log_mirror_event/v1`.
A528. Owner: Manager A1.
A529. Consumer: A0/A5 after shadow mode.
A530. Required source refs: source row id and source hash.
A531. Contract name: `callback_parity_verdict/v1`.
A532. Owner: Manager A5.
A533. Consumer: Manager A3 and cutover gate.
A534. Required source refs: callback imports, manual task id import, dispatch-log offsets.
A535. Contract name: `mission_anchor_minimum/v1`.
A536. Owner: flywheel cross-plan contract until compiler ships.
A537. Consumer: Fleet P1/P2, Manager A2, skillos skill eligibility.
A538. Required fields: lines A198-A203 above.

## Final Decision

A539. Executive verdict repeated: contradictions-found-revise.
A540. Fundamental conflict: no.
A541. Cross-plan coherence after corrections: yes.
A542. Safe to convert to beads now: no.
A543. Safe to run r2 after text integration: yes.
A544. The two plans must coexist.
A545. Fleet fixes bad local selection and emits trustworthy facts.
A546. Manager composes those facts into cross-fleet decisions.
A547. skillos recommends capability, not work ownership.
A548. mission-coverage-compiler verifies broad mission coverage later.
A549. The main failure to avoid is accidental re-centralization into ops-log authority.
A550. The second failure to avoid is stale M-number dispatch.
A551. The third failure to avoid is using mission-anchor refs as a fake compiler.
A552. The fourth failure to avoid is callback cutover before manual callback import.
A553. The fifth failure to avoid is duplicate metric ownership.
A554. With those fixed, the architecture is coherent.
A555. Without those fixed, implementation workers will create subtle drift.
A556. This is exactly the kind of bug convergence audit is for.

## Callback Metrics

A557. self_grade=Y.
A558. composite=9.6.
A559. critical=0.
A560. high=6.
A561. medium=8.
A562. low=3.
A563. total_findings=17.
A564. verdict=revise.
A565. layer_leaks=4.
A566. contract_gaps=5.
A567. naming_collisions=4.
A568. dependency_cycles=0.
A569. stock_conflicts=3.
A570. global_ship_first=P1+P2.
A571. l112_expected=OK_audit_r1_cross_plan.
A572. End.
