---
title: "Fleet Autonomy v1 - R2 Integrated Plan"
type: plan
created: 2026-05-06
frontmatter_source: scaffold-doc-frontmatter
---

# Fleet Autonomy v1 - R2 Integrated Plan

---
plan_id: fleet-autonomy-v1-2026-05-05
revision: r2
status: audit-findings-integrated
schema_version: fleet-autonomy-r2-plan/v1
created_at: 2026-05-05
owner_lane: fleet-autonomy
artifact_role: implementation-plan
source_plan: .flywheel/PLANS/fleet-autonomy-v1-2026-05-05/00-PLAN.md
primary_audit: .flywheel/PLANS/fleet-autonomy-v1-2026-05-05/02-AUDIT-r1.md
cross_plan_audit: .flywheel/PLANS/02-AUDIT-r1-cross-plan.md
self_grade: 9.68
audit_findings_total: 13
audit_findings_accepted: 7
audit_findings_revised: 5
audit_findings_rejected: 1
audit_findings_deferred: 0
cross_plan_deltas_resolved: 17
implementation_scope: plan-space-only
bead_scope: no beads may be filed from this unaudited plan until R2 audit passes
---

## 1. R2 Executive Decision

R2-001. This revision accepts the R1 audit verdict that the original plan was directionally strong but unsafe to bead without contract repair.
R2-002. The integrated plan keeps the original mission: turn idle panes from an eroding-goal stock into a governed dispatch flow.
R2-003. The integrated plan changes the implementation boundary: selector and retry controls must ship before broader measurement surfaces.
R2-004. The integrated plan changes the safety boundary: degraded selector behavior defaults to no-candidate, not dispatch fallback.
R2-005. The integrated plan changes the state boundary: Fleet may emit state facts, but Manager computes global fleet state.
R2-006. The integrated plan changes the naming boundary: old M-series labels are aliases only, not active primitive identifiers.
R2-007. The integrated plan changes the retry boundary: one dispatch is allowed per candidate and state hash, not per arbitrary tick window.
R2-008. The integrated plan changes the mission boundary: mission deltas are emitted by Fleet and compiled by Manager, not locally summarized as proof.
R2-009. The integrated plan changes the callback boundary: callback parity belongs to Manager A5, while Fleet keeps only compatibility facts until cutover.
R2-010. The integrated plan changes the baseline boundary: P4/P5/P6 wait for one unattended P1/P2 baseline unless P0 safety repair is needed.
R2-011. These changes resolve the semantic-preservation-gap finding in the R1 audit.
R2-012. These changes resolve the degraded-fallback-unsafe finding in the R1 audit.
R2-013. These changes resolve the off-by-one-retry-threshold finding in the R1 audit.
R2-014. These changes resolve the cross-plan-layer-leak finding in the R1 audit.
R2-015. These changes resolve the deprecation-leak finding in the R1 audit.
R2-016. These changes resolve the parameter-thrashing finding in the R1 audit.
R2-017. R2 does not authorize implementation.
R2-018. R2 authorizes only plan audit, then bead shaping if the R2 audit passes.
R2-019. The next audit should treat any reintroduction of `br ready` dispatch fallback as a release blocker.
R2-020. The next audit should treat any direct P1/P2 dependency on A1 as a layer leak.
R2-021. The next audit should treat any callback cutover outside A5 as a layer leak.
R2-022. The next audit should treat any mission compiler work inside Fleet as scope creep.
R2-023. The next audit should treat any broad P4/P5/P6 launch before baseline evidence as premature expansion.
R2-024. R2 is scored higher than R1 because the stop-bleed primitives are now both narrow and contract-anchored.
R2-025. R2 still keeps the plan humble: the first implementation is a selector and suppression contract, not an autonomy platform.

## 2. Audit-Finding Integration

R2-026. This section is the audit-finding integration ledger required by the dispatch.
R2-027. Each R1 audit finding is classified as Accepted, Accepted-with-revision, Rejected, or Defer-to-r2-audit.
R2-028. Finding H1 `semantic-preservation-gap` is Accepted.
R2-029. H1 source: `.flywheel/PLANS/fleet-autonomy-v1-2026-05-05/02-AUDIT-r1.md:123`.
R2-030. H1 corrective citation: `.flywheel/PLANS/fleet-autonomy-v1-2026-05-05/02-AUDIT-r1.md:155`.
R2-031. H1 R2 action: P1 must preserve distinct `bv --robot-next` semantic classes instead of reducing them to one candidate/no-candidate bit.
R2-032. H1 R2 action: P1 must include named fixture classes for dispatching, empty queue, blocked cascade, parent-open-children, parent-rollup, and suppressed top-only.
R2-033. H1 R2 action: P1 acceptance adds P1-K, P1-L, and P1-M as semantic preservation gates.
R2-034. H1 R2 effect: idle-state meaning survives the selector migration.
R2-035. H1 R2 effect: existing watcher tests are preserved instead of weakened.
R2-036. H1 R2 risk removed: the selector cannot claim success by emitting a candidate while losing the reason no candidate existed.
R2-037. H1 status: Accepted with direct P1 contract changes.
R2-038. Finding H2 `degraded-fallback-unsafe` is Accepted.
R2-039. H2 source: `.flywheel/PLANS/fleet-autonomy-v1-2026-05-05/02-AUDIT-r1.md:170`.
R2-040. H2 corrective citation: `.flywheel/PLANS/fleet-autonomy-v1-2026-05-05/02-AUDIT-r1.md:198`.
R2-041. H2 R2 action: missing, malformed, unavailable, or schema-incompatible `bv` output produces DEGRADED no-candidate by default.
R2-042. H2 R2 action: `br ready` may be used for diagnostic inventory only unless an explicit emergency flag is set.
R2-043. H2 R2 action: any emergency fallback must set `emergency_fallback_used=true` and write a degraded-fallback receipt.
R2-044. H2 R2 action: rollback disables auto-dispatch and returns to manual selection or diagnostic inventory.
R2-045. H2 R2 action: measurement distinguishes fallback context from fallback dispatch.
R2-046. H2 R2 effect: degraded selector operation cannot silently dispatch from the old substrate.
R2-047. H2 R2 effect: degraded mode becomes a visible stock, not an invisible alternate control loop.
R2-048. H2 status: Accepted with hard default no-candidate behavior.
R2-049. Finding H3 `off-by-one-retry-threshold` is Accepted.
R2-050. H3 source: `.flywheel/PLANS/fleet-autonomy-v1-2026-05-05/02-AUDIT-r1.md:207`.
R2-051. H3 corrective citation: `.flywheel/PLANS/fleet-autonomy-v1-2026-05-05/02-AUDIT-r1.md:230`.
R2-052. H3 R2 action: the suppression key is `(candidate_id, attempt_state_hash)`.
R2-053. H3 R2 action: the first dispatch for that key is permitted.
R2-054. H3 R2 action: later unchanged ticks suppress dispatch and emit `selection_suppressed`.
R2-055. H3 R2 action: a real state transition resets the key.
R2-056. H3 R2 action: attempt count windows become diagnostic only.
R2-057. H3 R2 action: delivery-uncertain retry is a named exception requiring absent or uncertain delivery receipt evidence.
R2-058. H3 R2 effect: the old "third attempt" off-by-one ambiguity disappears.
R2-059. H3 R2 effect: the control loop reacts to state, not time spent idling.
R2-060. H3 status: Accepted with a new retry-state receipt contract.
R2-061. Finding H4 `cross-plan-layer-leak` is Accepted.
R2-062. H4 source: `.flywheel/PLANS/fleet-autonomy-v1-2026-05-05/02-AUDIT-r1.md:242`.
R2-063. H4 corrective citation: `.flywheel/PLANS/fleet-autonomy-v1-2026-05-05/02-AUDIT-r1.md:268`.
R2-064. H4 R2 action: Fleet P1 and P2 emit selector and suppression facts before A1 exists.
R2-065. H4 R2 action: Manager A0 consumes those facts directly as manager-state inputs.
R2-066. H4 R2 action: Manager A2 later ranks and scores those facts.
R2-067. H4 R2 action: Manager A4 later renders those facts.
R2-068. H4 R2 action: Manager A5 later validates callback parity and cutover.
R2-069. H4 R2 action: old P3 status-brain wording is retired as an independent primitive.
R2-070. H4 R2 effect: no Fleet primitive pretends to own the manager state plane.
R2-071. H4 status: Accepted with cross-plan aliasing and ship-order correction.
R2-072. Finding M1 `deprecation-leak` is Accepted.
R2-073. M1 source: `.flywheel/PLANS/fleet-autonomy-v1-2026-05-05/02-AUDIT-r1.md:278`.
R2-074. M1 corrective citation: `.flywheel/PLANS/fleet-autonomy-v1-2026-05-05/02-AUDIT-r1.md:293`.
R2-075. M1 R2 action: the plan now includes a deprecated carry-forward table.
R2-076. M1 R2 action: Fleet P3 survives only as A0-owned state facts plus A4-owned projection.
R2-077. M1 R2 action: Fleet M survives only as generated Manager A4 projection derived from A0/A2 state hashes.
R2-078. M1 R2 action: callback-as-input survives only as A5 compatibility material until cutover.
R2-079. M1 R2 effect: deprecated ideas cannot re-enter implementation as unnamed work.
R2-080. M1 status: Accepted with explicit carry-forward disposition.
R2-081. Finding M2 `rollback conflict` is Accepted-with-revision.
R2-082. M2 source: `.flywheel/PLANS/fleet-autonomy-v1-2026-05-05/02-AUDIT-r1.md:300`.
R2-083. M2 corrective citation: `.flywheel/PLANS/fleet-autonomy-v1-2026-05-05/02-AUDIT-r1.md:310`.
R2-084. M2 R2 action: rollback is not "fall back to `br ready` dispatch".
R2-085. M2 R2 action: rollback means disable auto-dispatch, emit DEGRADED no-candidate, and leave manual selection visible.
R2-086. M2 R2 revision: diagnostic `br ready` inventory may remain available to humans and tests but cannot dispatch by default.
R2-087. M2 R2 effect: rollback safety and degraded fallback safety use the same invariant.
R2-088. M2 status: Accepted-with-revision because the diagnostic inventory path remains, but dispatch fallback is removed.
R2-089. Finding M3 `top-candidate suppression ambiguity` is Accepted-with-revision.
R2-090. M3 source: `.flywheel/PLANS/fleet-autonomy-v1-2026-05-05/02-AUDIT-r1.md:316`.
R2-091. M3 corrective citation: `.flywheel/PLANS/fleet-autonomy-v1-2026-05-05/02-AUDIT-r1.md:327`.
R2-092. M3 R2 action: if `bv --robot-next` top candidate is suppressed, default output is no-candidate.
R2-093. M3 R2 action: second-best selection is not locally synthesized from `br ready`.
R2-094. M3 R2 action: optional top-N triage requires fixture-backed `bv --robot-triage` schema proof.
R2-095. M3 R2 revision: top-N triage is a later extension inside P1, not a P1 launch requirement.
R2-096. M3 R2 effect: no hidden local ranking algorithm is introduced.
R2-097. M3 status: Accepted-with-revision because the plan allows future fixture-backed triage but forbids ad hoc fallback ranking.
R2-098. Finding M4 `mission-anchor schema gap` is Accepted-with-revision.
R2-099. M4 source: `.flywheel/PLANS/fleet-autonomy-v1-2026-05-05/02-AUDIT-r1.md:335`.
R2-100. M4 corrective citation: `.flywheel/PLANS/fleet-autonomy-v1-2026-05-05/02-AUDIT-r1.md:344`.
R2-101. M4 cross-plan citation: `.flywheel/PLANS/02-AUDIT-r1-cross-plan.md:200`.
R2-102. M4 R2 action: define a minimal A2-compatible mission-anchor schema now.
R2-103. M4 R2 action: defer the full mission-coverage compiler to a separate plan after P1/P2/A0/A2/A4/A1/A5.
R2-104. M4 R2 revision: Fleet emits mission delta facts; Manager computes fleet-wide mission stock.
R2-105. M4 R2 effect: the schema is not a punt, but the compiler is not smuggled into Fleet.
R2-106. M4 status: Accepted-with-revision.
R2-107. Finding M5 `live-window baseline missing` is Accepted-with-revision.
R2-108. M5 source: `.flywheel/PLANS/fleet-autonomy-v1-2026-05-05/02-AUDIT-r1.md:352`.
R2-109. M5 corrective citation: `.flywheel/PLANS/fleet-autonomy-v1-2026-05-05/02-AUDIT-r1.md:361`.
R2-110. M5 R2 action: P4, P5, and P6 cannot start until one unattended P1/P2 baseline window completes.
R2-111. M5 R2 action: the baseline must include selector quality, suppression quality, degraded-mode count, and manual intervention count.
R2-112. M5 R2 revision: a P0 safety repair may bypass the baseline gate if it is narrower than the P4/P5/P6 primitive.
R2-113. M5 R2 effect: the plan stops expanding control surfaces before the first stop-bleed loop is measured.
R2-114. M5 status: Accepted-with-revision.
R2-115. Finding L1 `L112 weakness` is Accepted-with-revision.
R2-116. L1 source: `.flywheel/PLANS/fleet-autonomy-v1-2026-05-05/02-AUDIT-r1.md:371`.
R2-117. L1 corrective citation: `.flywheel/PLANS/fleet-autonomy-v1-2026-05-05/02-AUDIT-r1.md:374`.
R2-118. L1 R2 action: the R2 dispatch L112 remains the formal tick check, but this plan adds semantic grep probes for R2 audit.
R2-119. L1 R2 action: R2 audit should verify no default dispatch fallback, the state-hash retry key, and the contract freeze.
R2-120. L1 R2 revision: this is not a plan behavior change, but it strengthens the next audit surface.
R2-121. L1 status: Accepted-with-revision.
R2-122. Finding L2 `score refresh` is Accepted.
R2-123. L2 source: `.flywheel/PLANS/fleet-autonomy-v1-2026-05-05/02-AUDIT-r1.md:379`.
R2-124. L2 corrective citation: `.flywheel/PLANS/fleet-autonomy-v1-2026-05-05/02-AUDIT-r1.md:386`.
R2-125. L2 R2 action: R2 self-grade is raised from R1 8.2 to 9.68 after resolving the high-risk contract flaws.
R2-126. L2 R2 effect: the score now reflects integrated audit findings, not the original plan.
R2-127. L2 status: Accepted.
R2-128. Finding L3 `source citation granularity` is Accepted.
R2-129. L3 source: `.flywheel/PLANS/fleet-autonomy-v1-2026-05-05/02-AUDIT-r1.md:392`.
R2-130. L3 corrective citation: `.flywheel/PLANS/fleet-autonomy-v1-2026-05-05/02-AUDIT-r1.md:397`.
R2-131. L3 R2 action: R2 cites R1 audit and cross-plan audit by file and line for each adopted change class.
R2-132. L3 R2 effect: future bead shaping can trace requirements to the audit evidence.
R2-133. L3 status: Accepted.
R2-134. Finding L4 `public name nonblocker` is Rejected as an implementation blocker.
R2-135. L4 source: `.flywheel/PLANS/fleet-autonomy-v1-2026-05-05/02-AUDIT-r1.md:403`.
R2-136. L4 corrective citation: `.flywheel/PLANS/fleet-autonomy-v1-2026-05-05/02-AUDIT-r1.md:408`.
R2-137. L4 R2 action: keep `fleet-autonomy-v1` as an internal slug.
R2-138. L4 R2 action: do not block P1/P2 on a public name.
R2-139. L4 R2 effect: the naming issue is acknowledged but not allowed to absorb implementation attention.
R2-140. L4 status: Rejected as blocker, accepted only as a nonblocking editorial note.
R2-141. R1 audit integration totals: Accepted 7, Accepted-with-revision 5, Rejected 1, Deferred 0.
R2-142. R1 audit integration result: all 13 findings have explicit disposition.
R2-143. R1 audit integration consequence: R2 is ready for R2 audit, not direct implementation.

## 3. Cross-Plan Delta Integration

R2-144. Cross-plan finding LL1 obsolete manager M ids is resolved.
R2-145. LL1 source: `.flywheel/PLANS/02-AUDIT-r1-cross-plan.md:85`.
R2-146. LL1 R2 action: old manager M labels become aliases only.
R2-147. LL1 R2 action: M1 maps to A1, M2 maps to A3, M3 maps to A2, M4 maps to A4.
R2-148. LL1 R2 action: old P3 status-brain fields map to A0 plus A4 projection.
R2-149. LL1 R2 effect: no stale manager primitive is scheduled as new work.
R2-150. Cross-plan finding LL2 P2 direct ops-log rows before A1 exists is resolved.
R2-151. LL2 source: `.flywheel/PLANS/02-AUDIT-r1-cross-plan.md:101`.
R2-152. LL2 R2 action: P1 and P2 write selector and retry receipts to the existing dispatch log or local receipt JSONL.
R2-153. LL2 R2 action: A0 reads those receipts directly.
R2-154. LL2 R2 action: A1 imports, mirrors, and indexes later.
R2-155. LL2 R2 effect: Fleet does not depend on an unshipped A1 substrate.
R2-156. Cross-plan finding LL3 P3 survives under M4 wording is resolved.
R2-157. LL3 source: `.flywheel/PLANS/02-AUDIT-r1-cross-plan.md:114`.
R2-158. LL3 R2 action: P3 independent controller is deprecated.
R2-159. LL3 R2 action: P3 data survives as A0 state facts and A4 projection only.
R2-160. LL3 R2 effect: status display does not become a second controller.
R2-161. Cross-plan finding LL4 ops-log owner wording is resolved.
R2-162. LL4 source: `.flywheel/PLANS/02-AUDIT-r1-cross-plan.md:125`.
R2-163. LL4 R2 action: A1 owns mirror and index behavior only.
R2-164. LL4 R2 action: event producers retain source ownership.
R2-165. LL4 R2 effect: the ops log becomes a ledger surface, not a central command owner.
R2-166. Cross-plan finding CG1 A1 missing P1 selector fields is resolved.
R2-167. CG1 source: `.flywheel/PLANS/02-AUDIT-r1-cross-plan.md:137`.
R2-168. CG1 R2 action: `selector_receipt/v1` is added as a frozen contract in this plan.
R2-169. CG1 R2 action: Manager A0 and A2 consume selector receipts before A1 import exists.
R2-170. CG1 R2 effect: selector facts have a stable schema across plans.
R2-171. Cross-plan finding CG2 A1 missing P2 retry-state fields is resolved.
R2-172. CG2 source: `.flywheel/PLANS/02-AUDIT-r1-cross-plan.md:158`.
R2-173. CG2 R2 action: `retry_state_receipt/v1` is added as a frozen contract.
R2-174. CG2 R2 action: A0, A2, and A5 consume retry facts by key, not by prose callback.
R2-175. CG2 R2 effect: same-candidate suppression is machine-checkable.
R2-176. Cross-plan finding CG3 blocker-owner fields is resolved.
R2-177. CG3 source: `.flywheel/PLANS/02-AUDIT-r1-cross-plan.md:178`.
R2-178. CG3 R2 action: Fleet selector receipts include no-candidate and suppression reasons.
R2-179. CG3 R2 action: Manager A0 may derive blocker-owner facts but Fleet does not own global blocker policy.
R2-180. CG3 R2 effect: blocker ownership can be computed without forcing Fleet into manager scope.
R2-181. Cross-plan finding CG4 peer canonical log path schema is resolved.
R2-182. CG4 source: `.flywheel/PLANS/02-AUDIT-r1-cross-plan.md:188`.
R2-183. CG4 R2 action: peer-facing facts must include source path, source owner, schema version, and event type.
R2-184. CG4 R2 action: P1/P2 may write local receipts until A1 imports them.
R2-185. CG4 R2 effect: cross-plan consumers can distinguish original evidence from mirror evidence.
R2-186. Cross-plan finding CG5 minimal mission-anchor schema is resolved.
R2-187. CG5 source: `.flywheel/PLANS/02-AUDIT-r1-cross-plan.md:200`.
R2-188. CG5 R2 action: mission-anchor minimum fields are frozen in Section 8.
R2-189. CG5 R2 action: full mission-coverage compiler remains out of Fleet scope.
R2-190. CG5 R2 effect: A2 can score mission anchoring without waiting for the compiler.
R2-191. Cross-plan naming collision findings are resolved.
R2-192. Naming source: `.flywheel/PLANS/02-AUDIT-r1-cross-plan.md:217`.
R2-193. Naming R2 action: Fleet uses P1/P2/P4/P5/P6 for Fleet primitives only.
R2-194. Naming R2 action: Manager uses A0/A1/A2/A3/A4/A5 for manager primitives only.
R2-195. Naming R2 action: old M labels appear only in alias tables and migration notes.
R2-196. Naming R2 effect: old prose cannot create duplicate workstreams.
R2-197. Cross-plan dependency cycle is resolved.
R2-198. Dependency source: `.flywheel/PLANS/02-AUDIT-r1-cross-plan.md:243`.
R2-199. Dependency R2 action: G0 contract freeze is the first plan-space action.
R2-200. Dependency R2 action: P1/P2 receipts are first implementation candidates after G0.
R2-201. Dependency R2 action: A0 can read existing ledgers plus P1/P2 receipts without requiring A1.
R2-202. Dependency R2 effect: no P1/P2 dependency on A1 remains.
R2-203. Cross-plan stock conflict is resolved.
R2-204. Stock source: `.flywheel/PLANS/02-AUDIT-r1-cross-plan.md:305`.
R2-205. Stock R2 action: Fleet owns `same_candidate_without_state_delta`.
R2-206. Stock R2 action: Manager owns `duplicate_decision_or_dispatch`.
R2-207. Stock R2 action: both join on `candidate_id`, `attempt_state_hash`, and `dispatch_id`.
R2-208. Stock R2 effect: Fleet stop-bleed and Manager duplicate detection reinforce each other instead of competing.
R2-209. Cross-plan global sequence is resolved.
R2-210. Sequence source: `.flywheel/PLANS/02-AUDIT-r1-cross-plan.md:368`.
R2-211. Sequence R2 action: this plan adopts G0 through G13 as the global sequence.
R2-212. Sequence R2 action: P1/P2 may be the first implementation globally after G0, while A0 remains first inside Manager.
R2-213. Sequence R2 effect: the two plans no longer fight over which primitive ships first.
R2-214. Skillos integration contract is resolved.
R2-215. Skillos source: `.flywheel/PLANS/02-AUDIT-r1-cross-plan.md:436`.
R2-216. Skillos R2 action: issue-draft posting is outside P1/P2 unless selector receipts expose a candidate for that flow.
R2-217. Skillos R2 action: no new skill or issue draft may be posted directly from this unaudited plan.
R2-218. Skillos R2 effect: Fleet autonomy does not bypass Jeff convergence gates.
R2-219. Mobile-eats compiler placement is resolved.
R2-220. Mobile-eats source: `.flywheel/PLANS/02-AUDIT-r1-cross-plan.md:459`.
R2-221. Mobile-eats R2 action: mission-coverage compiler is separate from Fleet P1/P2 and Manager A0.
R2-222. Mobile-eats R2 action: Fleet emits minimum mission facts only.
R2-223. Mobile-eats R2 effect: mission coverage does not become an accidental Fleet side project.
R2-224. CLI cross-check is resolved.
R2-225. CLI source: `.flywheel/PLANS/02-AUDIT-r1-cross-plan.md:479`.
R2-226. CLI R2 action: all future bead shaping must use robot-mode bead commands and JSON receipts.
R2-227. CLI R2 action: `br ready` is never a dispatch selector.
R2-228. CLI R2 effect: CLI substrate freshness is embedded in implementation gates.
R2-229. Interface contract recommendations are resolved.
R2-230. Interface source: `.flywheel/PLANS/02-AUDIT-r1-cross-plan.md:556`.
R2-231. Interface R2 action: `selector_receipt/v1`, `retry_state_receipt/v1`, `manager_state_fact/v1`, `ops_log_mirror_event/v1`, `callback_parity_verdict/v1`, and `mission_anchor_minimum/v1` are the named contracts.
R2-232. Interface R2 effect: cross-plan integration now has explicit data products.
R2-233. Cross-plan delta total: 17 resolved.

## 4. R2 Primitive Map

R2-234. G0 is a plan-space contract freeze, represented by this R2 artifact and its R2 audit.
R2-235. Fleet P1 is `bv-next-selector-contract`.
R2-236. Fleet P2 is `same-candidate-suppression-contract`.
R2-237. Fleet P3 independent status brain is deprecated.
R2-238. Fleet P4 is `stale-reservation-repair`, gated by baseline.
R2-239. Fleet P5 is `hung-pane-repair`, gated by baseline.
R2-240. Fleet P6 is `manual-josh-nudge-reduction`, gated by baseline.
R2-241. Fleet M primary measurement surface is deprecated.
R2-242. Manager A0 is `manager-state-read-model`.
R2-243. Manager A1 is `ops-log-mirror-and-index`.
R2-244. Manager A2 is `scoring-governor-and-top-n-queue`.
R2-245. Manager A3 is `tick-driver`.
R2-246. Manager A4 is `shared-renderer-and-status-surface`.
R2-247. Manager A5 is `callback-parity-and-cutover`.
R2-248. Old manager M1 maps to Manager A1.
R2-249. Old manager M2 maps to Manager A3.
R2-250. Old manager M3 maps to Manager A2.
R2-251. Old manager M4 maps to Manager A4.
R2-252. Old Fleet P3 status-brain fields map to Manager A0.
R2-253. Old Fleet P3 display output maps to Manager A4.
R2-254. Old Fleet M measurement output maps to Manager A4 generated projection.
R2-255. Old callback-as-input maps to Manager A5 compatibility input until cutover.
R2-256. Fleet does not own global state.
R2-257. Fleet does not own global scoring.
R2-258. Fleet does not own callback parity.
R2-259. Fleet does not own mission-coverage compilation.
R2-260. Fleet does own selector facts about candidate eligibility.
R2-261. Fleet does own retry facts about repeated candidate state.
R2-262. Fleet does own degraded selector facts for its selector path.
R2-263. Fleet does own the first live stop-bleed baseline after P1/P2 ship.
R2-264. Manager consumes Fleet facts through frozen contracts.
R2-265. Manager may mirror Fleet facts through A1 after A1 exists.
R2-266. Manager may score Fleet facts through A2 after A2 exists.
R2-267. Manager may render Fleet facts through A4 after A4 exists.
R2-268. Manager may cut over callback compatibility through A5 after A5 passes.

## 5. Contract Freeze G0

R2-269. G0 is complete only when this R2 plan and its R2 audit agree on the primitive map.
R2-270. G0 must freeze selector, retry-state, mission-anchor, callback-parity, and ops-log mirror contracts.
R2-271. G0 must not create beads from unaudited plan text.
R2-272. G0 must not schedule P4/P5/P6 before P1/P2 baseline evidence.
R2-273. G0 must not treat old M labels as active implementation labels.
R2-274. G0 must not use `br ready` as a dispatch selector.
R2-275. G0 must confirm that P1/P2 write receipts before A1.
R2-276. G0 must confirm that A0 consumes receipts without A1.
R2-277. G0 must confirm that A1 mirrors and indexes only.
R2-278. G0 must confirm that A5 owns callback parity.
R2-279. G0 must confirm that mission compiler work is outside this plan.
R2-280. G0 output 1 is this R2 document.
R2-281. G0 output 2 is the R2 audit verdict.
R2-282. G0 output 3 is a bead-shaping packet only if R2 audit passes.
R2-283. G0 implementation risk is zero because it is plan-space only.
R2-284. G0 system value is high because it prevents layer leaks before code.

## 6. P1 - `bv --robot-next` Selector Contract

R2-285. P1 goal: replace dispatch selection based on stale or broad readiness surfaces with `bv --robot-next`.
R2-286. P1 core command: `bv --robot-next`.
R2-287. P1 optional command: `bv --robot-triage`.
R2-288. P1 forbidden dispatch command: `br ready`.
R2-289. P1 allowed diagnostic command: `br ready --json` only for inventory or tests that prove no dispatch was selected from it.
R2-290. P1 default degraded behavior: no-candidate.
R2-291. P1 emergency degraded behavior: dispatch only if explicit emergency flag and degraded-fallback receipt exist.
R2-292. P1 selector input must be captured before dispatch.
R2-293. P1 selector output must include schema version.
R2-294. P1 selector output must include source owner.
R2-295. P1 selector output must include source lineage.
R2-296. P1 selector output must include event type.
R2-297. P1 selector output must include candidate id when candidate exists.
R2-298. P1 selector output must include no-candidate reason when no candidate exists.
R2-299. P1 selector output must include candidate actionability.
R2-300. P1 selector output must include selector command used.
R2-301. P1 selector output must include selector exit code.
R2-302. P1 selector output must include selector parse status.
R2-303. P1 selector output must include emergency fallback flag.
R2-304. P1 selector output must include degraded fallback reason when degraded.
R2-305. P1 selector output must include `br_ready_inventory_hash` only when diagnostic inventory was collected.
R2-306. P1 selector output must include timestamp.
R2-307. P1 selector output must include dispatch eligibility boolean.
R2-308. P1 selector output must include suppression reason if P2 suppresses.
R2-309. P1 selector output must include mission anchor fields when candidate includes them.
R2-310. P1 selector output must not include ad hoc local score unless A2 owns it.
R2-311. P1 selector output must not invent a second-best candidate locally.
R2-312. P1 selector output must not flatten blocked-cascade into empty queue.
R2-313. P1 selector output must not flatten parent-open-children into dispatchable parent.
R2-314. P1 selector output must not flatten parent-rollup into child dispatch.
R2-315. P1 selector output must not hide top-candidate suppression.
R2-316. P1 fixture `bv-next-ok-dispatching` proves a dispatchable candidate is selected.
R2-317. P1 fixture `bv-next-empty-light-queue` proves empty queue produces no-candidate reason `empty_light_queue`.
R2-318. P1 fixture `bv-next-blocked-cascade-empty` proves blocked cascade produces no-candidate reason `blocked_cascade`.
R2-319. P1 fixture `bv-next-parent-open-children` proves parent work does not dispatch while open children remain.
R2-320. P1 fixture `bv-next-parent-rollup` proves completed child state can roll up without selecting the parent prematurely.
R2-321. P1 fixture `bv-next-suppressed-top-only` proves suppressed top candidate yields no-candidate by default.
R2-322. P1 fixture `bv-triage-top-n-ok` is optional and may be added only if `bv --robot-triage` schema is stable.
R2-323. P1 fixture `bv-unavailable` proves degraded no-candidate.
R2-324. P1 fixture `bv-malformed-json` proves degraded no-candidate.
R2-325. P1 fixture `bv-schema-mismatch` proves degraded no-candidate.
R2-326. P1 fixture `emergency-fallback-explicit` proves fallback dispatch requires explicit flag.
R2-327. P1 acceptance P1-A: all current idle-pane watcher tests still pass unchanged unless their assertions are strengthened.
R2-328. P1 acceptance P1-B: `br ready` is absent from the dispatch path.
R2-329. P1 acceptance P1-C: `bv --robot-next` is invoked exactly once per selection tick unless retry diagnostics explicitly require a second read.
R2-330. P1 acceptance P1-D: selector receipts are append-only.
R2-331. P1 acceptance P1-E: empty queue emits no-candidate, not error.
R2-332. P1 acceptance P1-F: blocked cascade emits no-candidate, not dispatch.
R2-333. P1 acceptance P1-G: parent-open-children emits no-candidate, not parent dispatch.
R2-334. P1 acceptance P1-H: top-candidate suppression emits no-candidate by default.
R2-335. P1 acceptance P1-I: degraded selector state emits DEGRADED no-candidate.
R2-336. P1 acceptance P1-J: emergency fallback dispatch is impossible without explicit flag and receipt.
R2-337. P1 acceptance P1-K: semantic fixtures cover all six R1-required selector classes.
R2-338. P1 acceptance P1-L: no selector branch converts no-candidate reason into a dispatchable candidate.
R2-339. P1 acceptance P1-M: selector receipts expose enough fields for A0/A2 without A1.
R2-340. P1 measurement: `selector_candidates_seen`.
R2-341. P1 measurement: `selector_no_candidate_count`.
R2-342. P1 measurement: `selector_no_candidate_by_reason`.
R2-343. P1 measurement: `selector_degraded_count`.
R2-344. P1 measurement: `fallback_context_count`.
R2-345. P1 measurement: `fallback_dispatch_count`.
R2-346. P1 success target: `fallback_dispatch_count=0` outside explicitly approved emergency tests.
R2-347. P1 success target: `selector_degraded_count` is visible and non-silent.
R2-348. P1 success target: no current dispatching fixture regresses.
R2-349. P1 success target: all no-candidate reasons are schema-valid.
R2-350. P1 failure trigger: any use of `br ready` to choose a dispatch candidate.
R2-351. P1 failure trigger: any suppressed top candidate replaced by local second-best ranking.
R2-352. P1 failure trigger: any degraded selector state dispatches without explicit emergency receipt.
R2-353. P1 failure trigger: any semantic fixture lost relative to current watcher behavior.
R2-354. P1 rollback: disable auto-dispatch and continue writing diagnostic no-candidate receipts.
R2-355. P1 rollback: preserve manual operator visibility.
R2-356. P1 rollback: do not swap in `br ready` dispatch fallback.
R2-357. P1 handoff to A0: A0 reads selector receipts directly.
R2-358. P1 handoff to A1: A1 later mirrors selector receipts.
R2-359. P1 handoff to A2: A2 later scores selector quality and ranking.
R2-360. P1 handoff to A4: A4 later renders selector state.
R2-361. P1 handoff to A5: A5 later validates callback parity if callbacks reference selector state.

## 7. `selector_receipt/v1`

R2-362. Contract name: `selector_receipt/v1`.
R2-363. Contract owner: Fleet P1.
R2-364. Contract consumers: Manager A0, Manager A2, Manager A4, Manager A5.
R2-365. Contract mirror: Manager A1 after A1 exists.
R2-366. Field `schema_version`: required string, exactly `selector_receipt/v1`.
R2-367. Field `event_type`: required string, one of `candidate_selected`, `no_candidate`, `selection_suppressed`, `selector_degraded`.
R2-368. Field `source_owner`: required string, initially `fleet.P1`.
R2-369. Field `source_lineage`: required object or string with selector command and source path.
R2-370. Field `selector_command`: required string.
R2-371. Field `selector_exit_code`: required integer.
R2-372. Field `selector_parse_status`: required string.
R2-373. Field `selector_error_class`: optional string, required when degraded.
R2-374. Field `candidate_id`: nullable string.
R2-375. Field `candidate_actionability`: nullable string, required when candidate exists.
R2-376. Field `dispatch_eligible`: required boolean.
R2-377. Field `no_candidate_reason`: nullable string, required when no candidate exists.
R2-378. Field `suppression_reason`: nullable string, required when event type is `selection_suppressed`.
R2-379. Field `attempt_state_hash`: nullable string, required when candidate exists or P2 evaluated suppression.
R2-380. Field `dispatch_id`: nullable string, required after dispatch delivery is attempted.
R2-381. Field `mission_anchor_id`: nullable string.
R2-382. Field `mission_anchor_evidence_path`: nullable string.
R2-383. Field `no_mission_anchor_reason`: nullable string.
R2-384. Field `emergency_fallback_used`: required boolean.
R2-385. Field `emergency_fallback_reason`: nullable string, required when fallback used.
R2-386. Field `br_ready_inventory_hash`: nullable string, diagnostic only.
R2-387. Field `created_at`: required timestamp.
R2-388. Field `source_path`: required string.
R2-389. Field `writer_version`: required string.
R2-390. Valid no-candidate reason `empty_light_queue`.
R2-391. Valid no-candidate reason `blocked_cascade`.
R2-392. Valid no-candidate reason `parent_open_children`.
R2-393. Valid no-candidate reason `parent_rollup_pending`.
R2-394. Valid no-candidate reason `suppressed_top_only`.
R2-395. Valid no-candidate reason `selector_degraded`.
R2-396. Valid no-candidate reason `manual_hold`.
R2-397. Valid no-candidate reason `mission_anchor_missing`.
R2-398. Valid degraded class `bv_missing`.
R2-399. Valid degraded class `bv_timeout`.
R2-400. Valid degraded class `bv_malformed_json`.
R2-401. Valid degraded class `bv_schema_mismatch`.
R2-402. Valid degraded class `bv_nonzero_exit`.
R2-403. Contract invariant: if `dispatch_eligible=false`, the dispatch transport must not send.
R2-404. Contract invariant: if `event_type=selector_degraded`, `dispatch_eligible=false` unless `emergency_fallback_used=true`.
R2-405. Contract invariant: if `emergency_fallback_used=true`, a degraded-fallback receipt must exist.
R2-406. Contract invariant: if `br_ready_inventory_hash` is non-null, it is evidence only and not source of candidate selection.
R2-407. Contract invariant: if candidate exists, no-candidate reason is null.
R2-408. Contract invariant: if no candidate exists, candidate id is null.
R2-409. Contract invariant: if selection is suppressed, P2 must write a matching retry-state receipt.
R2-410. Contract invariant: A1 mirror cannot mutate selector facts.

## 8. P2 - Same-Candidate Suppression Contract

R2-411. P2 goal: prevent repeated dispatches of the same unchanged candidate state.
R2-412. P2 control key: `(candidate_id, attempt_state_hash)`.
R2-413. P2 dispatch permission: first dispatch for a new key is allowed.
R2-414. P2 suppression rule: later unchanged ticks for the same key are suppressed.
R2-415. P2 reset rule: a true state transition creates a new attempt_state_hash.
R2-416. P2 diagnostic count: `attempt_count_window` is recorded but does not control dispatch permission.
R2-417. P2 exception: delivery-uncertain retry may dispatch again only when delivery receipt is absent or uncertain.
R2-418. P2 non-exception: a BLOCKED callback is not delivery uncertainty.
R2-419. P2 non-exception: a silent pane is not state change unless probe facts changed.
R2-420. P2 non-exception: passage of time is not state change.
R2-421. P2 state hash input: candidate id.
R2-422. P2 state hash input: bead status or equivalent work item status.
R2-423. P2 state hash input: dispatch delivery receipt state.
R2-424. P2 state hash input: last callback state.
R2-425. P2 state hash input: blocker classification.
R2-426. P2 state hash input: reservation age class when relevant.
R2-427. P2 state hash input: pane liveness class when relevant.
R2-428. P2 state hash input: explicit manual override when present.
R2-429. P2 state hash input must exclude wall-clock tick index.
R2-430. P2 state hash input must exclude incidental log ordering.
R2-431. P2 state hash input must exclude prose callback formatting differences.
R2-432. P2 receipt path: same local receipt substrate as P1 unless an existing dispatch log schema already accepts it.
R2-433. P2 receipt append mode: append-only.
R2-434. P2 receipt validation: reject rows without candidate id when suppression evaluated a candidate.
R2-435. P2 receipt validation: reject rows without attempt_state_hash.
R2-436. P2 receipt validation: reject rows with suppression decision but no reason.
R2-437. P2 receipt validation: reject delivery-uncertain retries without delivery uncertainty evidence.
R2-438. P2 acceptance P2-A: unchanged same key dispatches once.
R2-439. P2 acceptance P2-B: unchanged same key on second tick suppresses.
R2-440. P2 acceptance P2-C: unchanged same key on third tick suppresses.
R2-441. P2 acceptance P2-D: changed state hash permits a new dispatch.
R2-442. P2 acceptance P2-E: delivery-uncertain retry is permitted only with absent or uncertain delivery receipt.
R2-443. P2 acceptance P2-F: callback BLOCKED alone does not create delivery uncertainty.
R2-444. P2 acceptance P2-G: suppression emits `selection_suppressed`.
R2-445. P2 acceptance P2-H: selector receipt and retry-state receipt join by candidate id and attempt state hash.
R2-446. P2 acceptance P2-I: Manager A0 can read P2 facts without A1.
R2-447. P2 acceptance P2-J: A5 can later test callback parity from the same facts.
R2-448. P2 measurement: `same_candidate_without_state_delta`.
R2-449. P2 measurement owner: Fleet.
R2-450. P2 measurement target: repeated dispatch for same key after first equals zero.
R2-451. P2 measurement target: suppression receipts exist for repeated unchanged ticks.
R2-452. P2 measurement target: delivery-uncertain exception count remains explicit and explainable.
R2-453. P2 failure trigger: any unchanged same key dispatches twice without delivery uncertainty evidence.
R2-454. P2 failure trigger: suppression uses "third attempt" as a control threshold.
R2-455. P2 failure trigger: state hash ignores callback or delivery receipt changes.
R2-456. P2 failure trigger: state hash includes tick number as a reset source.
R2-457. P2 rollback: disable auto-dispatch for repeated candidates.
R2-458. P2 rollback: continue recording selector and retry-state receipts for diagnosis.
R2-459. P2 rollback: do not use callback prose as a retry controller.
R2-460. P2 handoff to A0: Manager reads current suppression facts directly.
R2-461. P2 handoff to A2: Manager scores duplicate dispatch risk.
R2-462. P2 handoff to A5: Manager validates callback cutover against retry facts.

## 9. `retry_state_receipt/v1`

R2-463. Contract name: `retry_state_receipt/v1`.
R2-464. Contract owner: Fleet P2.
R2-465. Contract consumers: Manager A0, Manager A2, Manager A5.
R2-466. Contract mirror: Manager A1 after A1 exists.
R2-467. Field `schema_version`: required string, exactly `retry_state_receipt/v1`.
R2-468. Field `event_type`: required string, one of `dispatch_permitted`, `selection_suppressed`, `delivery_uncertain_retry`.
R2-469. Field `source_owner`: required string, initially `fleet.P2`.
R2-470. Field `candidate_id`: required string.
R2-471. Field `attempt_state_hash`: required string.
R2-472. Field `attempt_state_hash_inputs`: required object or array.
R2-473. Field `state_delta_detected`: required boolean.
R2-474. Field `previous_attempt_state_hash`: nullable string.
R2-475. Field `dispatch_id`: nullable string.
R2-476. Field `dispatch_delivery_state`: required string.
R2-477. Field `delivery_receipt_path`: nullable string.
R2-478. Field `delivery_uncertain_reason`: nullable string.
R2-479. Field `dispatch_decision`: required string.
R2-480. Field `suppression_reason`: nullable string.
R2-481. Field `attempt_count_window`: required integer, diagnostic only.
R2-482. Field `same_candidate_without_state_delta`: required boolean.
R2-483. Field `manual_override_id`: nullable string.
R2-484. Field `created_at`: required timestamp.
R2-485. Field `source_path`: required string.
R2-486. Field `selector_receipt_id`: nullable string.
R2-487. Field `writer_version`: required string.
R2-488. Valid dispatch decision `permit_first_for_state`.
R2-489. Valid dispatch decision `suppress_same_state`.
R2-490. Valid dispatch decision `permit_state_changed`.
R2-491. Valid dispatch decision `permit_delivery_uncertain_retry`.
R2-492. Valid dispatch decision `manual_hold`.
R2-493. Valid suppression reason `same_candidate_same_attempt_state_hash`.
R2-494. Valid suppression reason `top_candidate_suppressed`.
R2-495. Valid suppression reason `manual_hold`.
R2-496. Valid delivery state `delivered`.
R2-497. Valid delivery state `absent`.
R2-498. Valid delivery state `uncertain`.
R2-499. Valid delivery state `failed`.
R2-500. Contract invariant: same candidate and same attempt state hash cannot dispatch twice unless delivery state is absent or uncertain.
R2-501. Contract invariant: delivery-uncertain retry requires `delivery_uncertain_reason`.
R2-502. Contract invariant: attempt count cannot override the state hash.
R2-503. Contract invariant: state delta detected requires a changed hash or explicit state-delta evidence.
R2-504. Contract invariant: A1 mirror cannot mutate retry facts.
R2-505. Contract invariant: A5 parity consumes this receipt and does not rewrite it.

## 10. Deprecated Primitive Carry-Forward Table

R2-506. Deprecated item: Fleet P3 independent status brain.
R2-507. Original intent: make pane state visible and actionable.
R2-508. R2 status: deprecated as independent Fleet primitive.
R2-509. Survives as: Manager A0 manager-state facts.
R2-510. Survives as: Manager A4 rendered projection.
R2-511. Does not survive as: Fleet controller, CLI, or dispatch owner.
R2-512. Reason: R1 found cross-plan layer leak and deprecation leak.
R2-513. Deprecated item: Fleet M primary measurement surface.
R2-514. Original intent: measure pane autonomy and manual-intervention stocks.
R2-515. R2 status: deprecated as Fleet-owned primary surface.
R2-516. Survives as: Manager A4 generated projection from A0/A2 state facts.
R2-517. Survives as: Fleet local metrics emitted through selector and retry receipts.
R2-518. Does not survive as: parallel dashboard or independent manager plane.
R2-519. Reason: Manager owns global state and rendering.
R2-520. Deprecated item: callback-as-orchestrator-input.
R2-521. Original intent: use callback prose to decide readiness.
R2-522. R2 status: deprecated as control input.
R2-523. Survives as: A5 compatibility input until cutover.
R2-524. Survives as: evidence compared against selector and retry receipts.
R2-525. Does not survive as: P1/P2 dispatch controller.
R2-526. Reason: callback parity is a manager cutover problem, not Fleet stop-bleed logic.
R2-527. Deprecated item: old Manager M1.
R2-528. Original intent: ops-log structure.
R2-529. R2 status: alias only.
R2-530. Maps to: Manager A1.
R2-531. Reason: A1 mirror/index is the active primitive.
R2-532. Deprecated item: old Manager M2.
R2-533. Original intent: tick driver.
R2-534. R2 status: alias only.
R2-535. Maps to: Manager A3.
R2-536. Reason: A3 is the active driver primitive.
R2-537. Deprecated item: old Manager M3.
R2-538. Original intent: scoring/top candidate behavior.
R2-539. R2 status: alias only.
R2-540. Maps to: Manager A2.
R2-541. Reason: A2 owns scoring and top-N queue.
R2-542. Deprecated item: old Manager M4.
R2-543. Original intent: shared status surface.
R2-544. R2 status: alias only.
R2-545. Maps to: Manager A4.
R2-546. Reason: A4 owns rendering and shared surface.
R2-547. Carry-forward invariant: deprecated names may appear in migration notes only.
R2-548. Carry-forward invariant: no bead title may use a deprecated label as the active primitive.
R2-549. Carry-forward invariant: no implementation test may assert old M labels except alias tests.
R2-550. Carry-forward invariant: no dispatch packet may assign work to Fleet P3 or Fleet M as active primitives.

## 11. Minimal Mission Anchor Contract

R2-551. Contract name: `mission_anchor_minimum/v1`.
R2-552. Contract owner: emitted by source primitive, compiled later by Manager mission compiler.
R2-553. Contract first Fleet emitter: P1 selector receipt when candidate includes mission evidence.
R2-554. Contract first Manager consumer: A2 scoring governor.
R2-555. Full mission compiler: separate plan after P1/P2/A0/A2/A4/A1/A5.
R2-556. Field `schema_version`: required string, exactly `mission_anchor_minimum/v1`.
R2-557. Field `mission_anchor_id`: nullable string.
R2-558. Field `mission_anchor_evidence_path`: nullable string.
R2-559. Field `mission_delta_expected`: nullable string or object.
R2-560. Field `no_mission_anchor_reason`: nullable string.
R2-561. Field `validation_probe`: nullable string.
R2-562. Field `source_owner`: required string.
R2-563. Field `source_path`: required string.
R2-564. Field `created_at`: required timestamp.
R2-565. Valid no-anchor reason `not_applicable`.
R2-566. Valid no-anchor reason `legacy_work_item`.
R2-567. Valid no-anchor reason `mission_anchor_pending`.
R2-568. Valid no-anchor reason `substrate_missing`.
R2-569. Valid no-anchor reason `explicit_human_exception`.
R2-570. Invariant: if mission anchor id is null, no-mission-anchor reason is required.
R2-571. Invariant: if mission anchor id is present, evidence path is required.
R2-572. Invariant: Fleet does not compute global mission coverage.
R2-573. Invariant: Manager A2 may score presence, absence, and reason validity.
R2-574. Invariant: the future compiler may aggregate but cannot rewrite original source facts.
R2-575. Baseline metric: percentage of dispatched candidates with valid mission anchor or valid no-anchor reason.
R2-576. Baseline metric owner: Manager A2 after A2 ships.
R2-577. Interim metric owner: Fleet P1 local receipt summary before A2 ships.
R2-578. R2 scope: minimum schema only.
R2-579. R2 non-scope: full compiler, cross-repo mission map, dashboard.

## 12. P4, P5, and P6 Baseline Gate

R2-580. P4 goal remains stale reservation repair.
R2-581. P5 goal remains hung pane repair.
R2-582. P6 goal remains manual Josh nudge reduction.
R2-583. P4/P5/P6 are not first implementation work.
R2-584. P4/P5/P6 require one unattended P1/P2 baseline window.
R2-585. Baseline window begins after P1 and P2 are live in dry-run or shadow-safe mode.
R2-586. Baseline window must include enough ticks to observe at least one idle-pane selection cycle.
R2-587. Baseline window must record selector candidates seen.
R2-588. Baseline window must record selector no-candidate reasons.
R2-589. Baseline window must record degraded selector count.
R2-590. Baseline window must record fallback context count.
R2-591. Baseline window must record fallback dispatch count.
R2-592. Baseline window must record suppression receipts.
R2-593. Baseline window must record same-candidate duplicate dispatch count.
R2-594. Baseline window must record manual intervention count.
R2-595. Baseline window must record reservation-age observations if P4 is proposed next.
R2-596. Baseline window must record pane-liveness observations if P5 is proposed next.
R2-597. Baseline window must record human-nudge observations if P6 is proposed next.
R2-598. Baseline pass target: fallback dispatch count equals zero.
R2-599. Baseline pass target: repeated unchanged candidate redispatch equals zero after first dispatch per state hash.
R2-600. Baseline pass target: degraded selector states are visible as no-candidate, not silent.
R2-601. Baseline pass target: no P1/P2 receipts fail schema validation.
R2-602. Baseline pass target: no P1/P2 behavior requires A1 to exist.
R2-603. Baseline failure action: repair P1/P2 before expanding to P4/P5/P6.
R2-604. Baseline exception: P0 safety repair may proceed before baseline only when scoped narrower than P4/P5/P6.
R2-605. Baseline exception example: a one-line guard preventing destructive command execution.
R2-606. Baseline exception non-example: adding stale reservation repair automation.
R2-607. P4 entry condition: baseline pass plus stale-reservation facts prove repeated unattended cost.
R2-608. P5 entry condition: baseline pass plus pane-liveness facts prove repeated unattended cost.
R2-609. P6 entry condition: baseline pass plus human-nudge facts prove repeated unattended cost.
R2-610. P4/P5/P6 audit requirement: each must cite the baseline receipt.

## 13. Measurement Loops and Stock Boundaries

R2-611. Fleet stock: `same_candidate_without_state_delta`.
R2-612. Fleet flow into stock: repeated unchanged candidate observations.
R2-613. Fleet flow out of stock: valid suppression receipt or real state change.
R2-614. Fleet metric target: unchanged same-key redispatch after first equals zero.
R2-615. Fleet stock: `selector_degraded_visible`.
R2-616. Fleet flow into stock: selector command missing, malformed, timed out, schema mismatch, or nonzero exit.
R2-617. Fleet flow out of stock: selector recovery and valid selector receipts.
R2-618. Fleet metric target: degraded states are never silent.
R2-619. Fleet stock: `fallback_dispatch_risk`.
R2-620. Fleet flow into stock: any path that can dispatch outside `bv --robot-next`.
R2-621. Fleet flow out of stock: no-candidate default and emergency receipt gate.
R2-622. Fleet metric target: fallback dispatch count equals zero outside explicit emergency tests.
R2-623. Fleet stock: `semantic_selector_fidelity`.
R2-624. Fleet flow into stock: fixture coverage for each semantic no-candidate class.
R2-625. Fleet flow out of stock: any flattening of semantic classes.
R2-626. Fleet metric target: all required semantic fixtures pass.
R2-627. Manager stock: `duplicate_decision_or_dispatch`.
R2-628. Manager owner: A2 and A5, not Fleet.
R2-629. Manager join keys: candidate id, attempt state hash, dispatch id.
R2-630. Manager stock: `global_mission_coverage`.
R2-631. Manager owner: future mission compiler, not Fleet.
R2-632. Interim owner: A2 scores minimum mission anchor presence.
R2-633. Manager stock: `callback_parity`.
R2-634. Manager owner: A5.
R2-635. Fleet contribution to callback parity: selector and retry receipts.
R2-636. Fleet non-owner boundary: Fleet does not decide callback cutover.
R2-637. Measurement invariant: every metric has an owner.
R2-638. Measurement invariant: every owner has a contract.
R2-639. Measurement invariant: every contract has a validation probe.
R2-640. Measurement invariant: every degraded path is counted separately from dispatch fallback.
R2-641. Measurement invariant: every suppression decision is explainable from receipt fields.
R2-642. Measurement invariant: every old primitive metric is either deprecated or remapped.
R2-643. Measurement invariant: every future dashboard reads generated state, not local controller prose.

## 14. Open Questions Closed

R2-644. OQ1 top-candidate suppression is closed.
R2-645. OQ1 decision: default to no-candidate when the top candidate is suppressed.
R2-646. OQ1 extension: use `bv --robot-triage` only after fixture-backed schema proof.
R2-647. OQ1 forbidden path: local second-best ranking from `br ready`.
R2-648. OQ2 callback parity ownership is closed.
R2-649. OQ2 decision: A5 owns callback parity and cutover.
R2-650. OQ2 Fleet role: emit receipts that A5 can compare.
R2-651. OQ2 forbidden path: Fleet callback controller.
R2-652. OQ3 mission-anchor minimum is closed.
R2-653. OQ3 decision: use `mission_anchor_minimum/v1` from Section 11.
R2-654. OQ3 deferred work: full compiler after global sequence reaches the compiler gate.
R2-655. OQ4 degraded fallback is closed.
R2-656. OQ4 decision: report DEGRADED no-candidate by default.
R2-657. OQ4 exception: explicit emergency fallback with receipt.
R2-658. OQ4 forbidden path: implicit `br ready` dispatch.
R2-659. OQ5 baseline window is closed.
R2-660. OQ5 decision: wait one unattended P1/P2 baseline before P4/P5/P6.
R2-661. OQ5 exception: narrow P0 safety repair only.
R2-662. OQ6 upstream drafts substrate is closed.
R2-663. OQ6 decision: upstream issue drafts live in a separate upstream-drafts substrate.
R2-664. OQ6 decision: no upstream Jeff or skill issue is filed directly from this unaudited plan.
R2-665. OQ6 future path: issue drafts must pass Jeff convergence rubric before posting.
R2-666. OQ7 public name is closed.
R2-667. OQ7 decision: keep internal slug `fleet-autonomy-v1`.
R2-668. OQ7 decision: do not block implementation on naming.
R2-669. OQ7 future path: public name can be selected if this becomes a user-facing product or command surface.

## 15. Global Ship Sequence

R2-670. G0: Contract freeze and R2 audit.
R2-671. G0 owner: planning lane.
R2-672. G0 output: R2 plan, R2 audit, no implementation.
R2-673. G0 exit: R2 audit passes with no critical or high unresolved findings.
R2-674. G1: Fleet P1 plus P2 selector and retry contracts.
R2-675. G1 owner: Fleet.
R2-676. G1 output: `selector_receipt/v1`, `retry_state_receipt/v1`, semantic fixtures, degraded no-candidate behavior.
R2-677. G1 exit: P1/P2 acceptance gates pass in test and shadow-safe mode.
R2-678. G2: Manager A0 read model.
R2-679. G2 owner: Manager.
R2-680. G2 output: manager state facts from existing ledgers and P1/P2 receipts.
R2-681. G2 exit: A0 reads Fleet receipts directly without A1.
R2-682. G3: Manager A2 scoring governor and top-N queue.
R2-683. G3 owner: Manager.
R2-684. G3 output: scoring over selector, retry, duplicate, and mission-anchor minimum facts.
R2-685. G3 exit: A2 does not mutate Fleet receipts.
R2-686. G4: Manager A4 shared renderer and status surface.
R2-687. G4 owner: Manager.
R2-688. G4 output: generated status projection from A0/A2 state.
R2-689. G4 exit: old Fleet M and P3 surfaces are represented only as generated projections.
R2-690. G5: Manager A1 shadow mirror.
R2-691. G5 owner: Manager.
R2-692. G5 output: ops-log mirror and index in shadow mode.
R2-693. G5 exit: A1 mirrors without becoming source owner.
R2-694. G6: Manager A5 callback parity.
R2-695. G6 owner: Manager.
R2-696. G6 output: callback parity verdicts comparing prose callbacks to structured receipts.
R2-697. G6 exit: callback cutover permit or explicit hold.
R2-698. G7: Manager A3 dry-run tick driver.
R2-699. G7 owner: Manager.
R2-700. G7 output: dry-run driver that plans no live actions unless gates pass.
R2-701. G7 exit: driver status verified, not marker-only.
R2-702. G8: Manager A3 apply-mode driver.
R2-703. G8 owner: Manager.
R2-704. G8 output: live driver under verified gates.
R2-705. G8 exit: live dispatch evidence exists and is visible to A5.
R2-706. G9: A5 cutover permit.
R2-707. G9 owner: Manager.
R2-708. G9 output: structured receipts become primary control evidence.
R2-709. G9 exit: callback prose no longer controls dispatch.
R2-710. G10: Evaluate P4.
R2-711. G10 owner: Fleet.
R2-712. G10 output: stale reservation repair plan if baseline proves need.
R2-713. G10 exit: P4 audit passes.
R2-714. G11: Evaluate P5.
R2-715. G11 owner: Fleet.
R2-716. G11 output: hung pane repair plan if baseline proves need.
R2-717. G11 exit: P5 audit passes.
R2-718. G12: Evaluate P6.
R2-719. G12 owner: Fleet.
R2-720. G12 output: manual Josh nudge reduction plan if baseline proves need.
R2-721. G12 exit: P6 audit passes.
R2-722. G13: Mission-coverage compiler separate plan.
R2-723. G13 owner: Manager or separate mission lane.
R2-724. G13 output: compiler over mission-anchor facts.
R2-725. G13 exit: compiler audit passes.
R2-726. Sequence invariant: P1/P2 implementation may begin after G0 if R2 audit passes.
R2-727. Sequence invariant: A0 is first inside Manager but not a prerequisite for P1/P2 stop-bleed.
R2-728. Sequence invariant: A1 is not a prerequisite for P1/P2 or A0.
R2-729. Sequence invariant: A5 owns callback cutover before callback prose is retired.
R2-730. Sequence invariant: P4/P5/P6 wait for baseline.

## 16. Bead Shaping Rules After R2 Audit

R2-731. No bead may be created from this plan until R2 audit passes.
R2-732. If R2 audit passes, the first bead should cover P1 and P2 only if a single small patch can safely implement both contracts.
R2-733. If P1 and P2 touch separate files, split into separate beads with explicit dependency.
R2-734. If P1 and P2 share the same dispatch path, one bead may own the shared write set.
R2-735. Every bead must include the relevant contract section from this plan.
R2-736. Every bead must include a file reservation preflight.
R2-737. Every bead must include Socraticode preflight queries for existing selector, retry, and idle watcher behavior.
R2-738. Every bead must include tests for semantic fixtures before live driver changes.
R2-739. Every bead must use robot-mode bead commands.
R2-740. Every bead must avoid raw readiness surfaces as selector inputs.
R2-741. P1 bead acceptance must include P1-A through P1-M.
R2-742. P2 bead acceptance must include P2-A through P2-J.
R2-743. P1/P2 bead rollback must disable auto-dispatch and preserve diagnostic receipts.
R2-744. P1/P2 bead implementation must not modify Manager A1 as a prerequisite.
R2-745. P1/P2 bead implementation must not implement A5 parity.
R2-746. P1/P2 bead implementation must not implement mission compiler.
R2-747. P1/P2 bead implementation must not implement P4/P5/P6 repair automation.
R2-748. P1/P2 bead implementation must not create upstream Jeff issue drafts.
R2-749. Any discovered out-of-scope gap must become a bead or carry explicit no-bead reason.
R2-750. Any blocker must consult relevant skills before BLOCKED callback.
R2-751. Any blocker must log a fuckup row before BLOCKED callback.
R2-752. Any dispatch callback must include `socraticode_queries`.
R2-753. Any dispatch callback must include reservation release evidence.
R2-754. Any dispatch callback must include L112 output.

## 17. R2 Audit Probes

R2-755. Probe R2-A: grep for `audit-finding integration` and verify this section exists.
R2-756. Probe R2-B: grep for `br ready` and verify every occurrence is diagnostic, forbidden, or rollback-disabled.
R2-757. Probe R2-C: grep for `DEGRADED no-candidate` and verify degraded fallback defaults to no dispatch.
R2-758. Probe R2-D: grep for `candidate_id, attempt_state_hash` and verify retry key exists.
R2-759. Probe R2-E: grep for `delivery-uncertain retry` and verify exception is bounded.
R2-760. Probe R2-F: grep for `selector_receipt/v1` and verify schema fields exist.
R2-761. Probe R2-G: grep for `retry_state_receipt/v1` and verify schema fields exist.
R2-762. Probe R2-H: grep for `mission_anchor_minimum/v1` and verify minimum fields exist.
R2-763. Probe R2-I: grep for `A5` and verify callback parity owner is Manager A5.
R2-764. Probe R2-J: grep for `A1` and verify it is mirror/index only.
R2-765. Probe R2-K: grep for `P4/P5/P6` and verify baseline gate exists.
R2-766. Probe R2-L: grep for `old Manager M1` and verify aliases only.
R2-767. Probe R2-M: grep for `same_candidate_without_state_delta` and verify Fleet owns that stock.
R2-768. Probe R2-N: grep for `duplicate_decision_or_dispatch` and verify Manager owns that stock.
R2-769. Probe R2-O: grep for `fallback_dispatch_count=0` or equivalent target.
R2-770. Probe R2-P: grep for all six P1 semantic fixtures.
R2-771. Probe R2-Q: grep for `full mission compiler` and verify it is separate.
R2-772. Probe R2-R: grep for `no bead may be created` and verify no direct implementation authorization.
R2-773. Probe R2-S: grep for `.flywheel/PLANS/02-AUDIT-r1-cross-plan.md` and verify cross-plan citations exist.
R2-774. Probe R2-T: grep for `.flywheel/PLANS/fleet-autonomy-v1-2026-05-05/02-AUDIT-r1.md` and verify R1 citations exist.

## 18. Residual Risks for R2 Audit

R2-775. Residual risk: the exact on-disk receipt path is still implementation-dependent.
R2-776. Mitigation: contract allows existing dispatch log or local receipt JSONL until A1 mirror exists.
R2-777. Residual risk: `bv --robot-triage` schema may not be stable enough for top-N suppression handling.
R2-778. Mitigation: top-N triage is optional and fixture-gated.
R2-779. Residual risk: mission-anchor minimum schema may need one more field once A2 implementation is inspected.
R2-780. Mitigation: schema is minimum, nullable where needed, and compiler is deferred.
R2-781. Residual risk: existing tests may encode old `br ready` fixture names.
R2-782. Mitigation: tests may preserve diagnostic `br ready` inventory while proving it cannot dispatch.
R2-783. Residual risk: Manager A0 and Fleet P1/P2 could race if implemented by separate workers.
R2-784. Mitigation: file reservations and disjoint write sets are mandatory in implementation dispatches.
R2-785. Residual risk: old M labels may remain in human conversation.
R2-786. Mitigation: alias table allows recognition but not implementation ownership.
R2-787. Residual risk: callback prose may remain operational for a while.
R2-788. Mitigation: A5 compatibility input explicitly handles migration until cutover.
R2-789. Residual risk: degraded no-candidate may reduce autonomous dispatch count temporarily.
R2-790. Mitigation: Meadows framing favors preserving safety stock before increasing dispatch throughput.
R2-791. Residual risk: P4/P5/P6 value is delayed.
R2-792. Mitigation: baseline gate prevents expanding repair loops before selector/retry behavior is measured.
R2-793. Residual risk: R2 is longer than the original and may need bead extraction.
R2-794. Mitigation: bead shaping is explicitly deferred until after R2 audit.

## 19. Self-Grade

R2-795. Composite score: 9.68.
R2-796. Correctness score: 9.7.
R2-797. Correctness rationale: every R1 high finding is accepted and patched into specific contract text.
R2-798. Coherence score: 9.7.
R2-799. Coherence rationale: Fleet and Manager ownership now use A/P primitive maps and aliases.
R2-800. Safety score: 9.8.
R2-801. Safety rationale: degraded selector states default to no-candidate and fallback dispatch is emergency-only.
R2-802. Testability score: 9.6.
R2-803. Testability rationale: semantic fixtures, receipt contracts, and R2 audit probes are explicit.
R2-804. Scope score: 9.6.
R2-805. Scope rationale: mission compiler, P4/P5/P6, and callback cutover are bounded outside P1/P2.
R2-806. Systems score: 9.8.
R2-807. Systems rationale: the plan identifies stocks, flows, owners, feedback loops, and degraded-mode visibility.
R2-808. Remaining score drag: receipt file path details need codebase-specific implementation after audit.
R2-809. Remaining score drag: top-N triage remains conditional on `bv --robot-triage` schema proof.
R2-810. Remaining score drag: mission-anchor minimum may need one implementation-level field revision.
R2-811. No critical unresolved finding remains in plan-space.
R2-812. No high unresolved finding remains in plan-space.
R2-813. No deferred R1 finding remains.

## 20. R2 Closeout

R2-814. R2 accepted H1 by adding semantic preservation fixtures and gates.
R2-815. R2 accepted H2 by making degraded fallback no-candidate by default.
R2-816. R2 accepted H3 by replacing attempt-threshold logic with state-hash suppression.
R2-817. R2 accepted H4 by mapping Fleet facts into Manager A0/A2/A4/A5 without layer ownership drift.
R2-818. R2 accepted M1 by adding deprecated carry-forward disposition.
R2-819. R2 revised M2 by preserving diagnostic inventory while forbidding fallback dispatch.
R2-820. R2 revised M3 by allowing fixture-backed triage later while defaulting to no-candidate now.
R2-821. R2 revised M4 by defining minimum mission-anchor fields while deferring the compiler.
R2-822. R2 revised M5 by adding a live baseline gate with a narrow P0 safety exception.
R2-823. R2 revised L1 by adding semantic audit probes beyond dispatch L112.
R2-824. R2 accepted L2 by refreshing the self-grade.
R2-825. R2 accepted L3 by citing audit lines throughout the integration ledger.
R2-826. R2 rejected L4 as an implementation blocker while preserving the internal slug.
R2-827. R2 resolved all 17 cross-plan deltas in the cross-plan audit.
R2-828. R2 keeps implementation authorization at zero.
R2-829. R2 next action is R2 audit.
R2-830. R2 next non-action is bead creation before audit.
R2-831. R2 final invariant: the fleet gets more autonomous only by making its feedback loops more truthful.
R2-832. R2 final invariant: no hidden fallback, no stale label, no retry-by-time, no local manager.
R2-833. R2 final invariant: the system must see what it is doing before it does more of it.
