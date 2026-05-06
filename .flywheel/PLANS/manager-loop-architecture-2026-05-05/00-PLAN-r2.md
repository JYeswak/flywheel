---
schema_version: manager-loop-plan/v2
plan_slug: manager-loop-architecture-2026-05-05
integrated_at: 2026-05-05T18:12:00Z
status: r2-audit-foldback-plan-space
source_reviews:
  - 01-REVIEW-multi-model.md
  - 01-REVIEW-donella.md
  - 01-REVIEW-jeff.md
  - cross-orch-input/skillos-1-2026-05-05T1555Z.md
source_audit:
  - 02-AUDIT-r1.md
  - ../02-AUDIT-r1-cross-plan.md
audit_findings_count: 26
audit_findings_accepted: 22
audit_findings_revised: 4
audit_findings_rejected: 0
audit_findings_deferred: 0
cross_plan_deltas_resolved: 17
composite_score: 9.72
donella_leverage_distribution: "#3=1,#4=1,#5=5,#6=4,#8=3,#9=2"
final_primitive_count: 6
ship_first_primitive: A0-manager-state-read-model
global_pre_implementation_action: G0-cross-plan-contract-freeze
global_ship_first_implementation: P1+P2-selector-and-retry-stop-bleed
callback_cutover_policy: parity-gated
plan_space_only: true
---

# Manager-Loop Architecture For Orchestrators

## 0. R2 Header

R2-001. Schema version: `manager-loop-plan/v2`.
R2-002. Plan slug: `manager-loop-architecture-2026-05-05`.
R2-003. Integrated at: 2026-05-05T18:12:00Z.
R2-004. Source audit: `02-AUDIT-r1.md`.
R2-005. Source cross-plan audit: `../02-AUDIT-r1-cross-plan.md`.
R2-006. R1 audit findings count: 26.
R2-007. Accepted findings: 22.
R2-008. Accepted-with-revision findings: 4.
R2-009. Rejected findings: 0.
R2-010. Deferred findings: 0.
R2-011. Cross-plan deltas resolved: 17.
R2-012. Composite after R2 fold-back: 9.72.
R2-013. Critical R1 findings: 0, so no critical procedural acceptance was needed.
R2-014. High findings accepted by default per dispatch contract.
R2-015. High accepted-with-revision items: H06 and H09 only.
R2-016. Medium accepted-with-revision item: M08.
R2-017. Low accepted-with-revision item: L02.
R2-018. All other R1 high, medium, and low findings are accepted directly.
R2-019. No finding is rejected.
R2-020. No finding is deferred to audit without a plan change.
R2-021. Global pre-implementation action is now G0 cross-plan contract freeze.
R2-022. Global ship-first implementation remains Fleet P1+P2 after G0.
R2-023. Manager-loop ship-first implementation remains A0 manager-state read model.
R2-024. A1 remains mirror/index only and is not promoted to authority.
R2-025. A5 remains the sole callback parity verdict owner.
R2-026. Callbacks remain live until A5 emits a cutover permit.
R2-027. No source code edits are authorized by this plan artifact.
R2-028. No bead creation is authorized by this plan artifact.
R2-029. This R2 plan folds the R1 audit, not a new architecture.
R2-030. Required L112 string for this artifact: `OK_reintegrate_r2_manager_loop`.

001. This plan replaces conversational orchestration with a manager loop.
002. It does not replace `bv`, `br`, `ntm`, Agent Mail, doctor, or validation receipts.
003. It composes existing substrate into a shared decision surface.
004. It makes the scoring policy explicit.
005. It keeps callbacks alive until parity is proven.
006. It makes mission-anchor closure the primary stock.
007. It keeps Joshua as exception handler, not routine controller.
008. It is plan-space only.

## 1. Revised Why This Plan Exists

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
R2-031. R2 audit correction: success also requires a frozen cross-plan interface before implementation workers read Fleet and Manager plans together.
R2-032. R2 citation: `02-AUDIT-r1-cross-plan.md:67-76`.
R2-033. R2 citation: `02-AUDIT-r1-cross-plan.md:473-488`.
R2-034. R2 audit correction: stale M-number primitive names are now compatibility aliases only.
R2-035. R2 citation: `02-AUDIT-r1-cross-plan.md:85-100`.
R2-036. R2 audit correction: P1/P2 emit selector and retry receipts, not A1 ops-log authority rows.
R2-037. R2 citation: `02-AUDIT-r1-cross-plan.md:101-113`.
R2-038. R2 audit correction: A0 state and A4 renderer are distinct surfaces.
R2-039. R2 citation: `02-AUDIT-r1-cross-plan.md:114-124`.
R2-040. R2 audit correction: A1 is a validated input mirror and index, not control-plane owner.
R2-041. R2 citation: `02-AUDIT-r1-cross-plan.md:125-133`.
R2-042. R2 audit correction: mission-anchor references are a minimum schema now, not a claim that the full mission-coverage compiler exists.
R2-043. R2 citation: `02-AUDIT-r1-cross-plan.md:200-215`.
R2-044. R2 audit correction: command, artifact, redaction, parity, idempotency, and scoring contracts are no longer left to implementation beads.
R2-045. R2 citation: `02-AUDIT-r1.md:71-159`.
R2-046. R2 audit correction: the plan now treats robot-mode readers as first-class consumers.
R2-047. R2 citation: `02-AUDIT-r1.md:80-87`.
R2-048. R2 audit correction: Donella "mission value" is weighted and validated, not inferred from closure counts.
R2-049. R2 citation: `02-AUDIT-r1.md:152-159`.

## 2. Final Primitives (Post-R2)

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
R2-A0-001. Canonical artifact path: `.flywheel/manager/state/manager-state.json`.
R2-A0-002. Canonical artifact path: `.flywheel/manager/state/manager-state.schema.json`.
R2-A0-003. Canonical artifact path: `.flywheel/manager/state/manager-state.md`.
R2-A0-004. Canonical artifact path: `.flywheel/manager/state/queue.json`.
R2-A0-005. Canonical artifact path: `.flywheel/manager/state/source-registry.json`.
R2-A0-006. Canonical artifact path: `.flywheel/manager/receipts/`.
R2-A0-007. Canonical artifact path: `.flywheel/manager/quarantine.jsonl`.
R2-A0-008. R2 citation: `02-AUDIT-r1.md:89-96`.
R2-A0-009. Source registry field: `source_id`.
R2-A0-010. Source registry field: `owner`.
R2-A0-011. Source registry field: `path_or_command`.
R2-A0-012. Source registry field: `stale_after_sec`.
R2-A0-013. Source registry field: `required`.
R2-A0-014. Source registry field: `fallback_source_id`.
R2-A0-015. Source registry field: `status=ok|stale|missing|quarantined|fallback_used`.
R2-A0-016. R2 citation: `02-AUDIT-r1.md:187-191`.
R2-A0-017. Redaction pipeline stage: ingest raw source row.
R2-A0-018. Redaction pipeline stage: classify secret and sensitive fields.
R2-A0-019. Redaction pipeline stage: redact or hash unsafe values before state write.
R2-A0-020. Redaction pipeline stage: refuse render when required value cannot be safely represented.
R2-A0-021. Redaction metadata field: `redaction_status`.
R2-A0-022. Redaction metadata field: `redaction_class`.
R2-A0-023. Redaction metadata field: `redaction_evidence_hash`.
R2-A0-024. R2 citation: `02-AUDIT-r1.md:98-105`.
R2-A0-025. A0 also accepts P1 `selector_receipt/v1` rows from dispatch-log or selector receipt JSONL after G0.
R2-A0-026. A0 also accepts P2 `retry_state_receipt/v1` rows from dispatch-log or retry receipt JSONL after G0.
R2-A0-027. A0 carries blocker ownership fields needed by A4 human-decision rendering.
R2-A0-028. R2 citation: `02-AUDIT-r1-cross-plan.md:137-187`.
R2-A0-029. Robot consumer smoke: peer process reads manager-state JSON, validates schema, calls `why` for one queue item, and exits with documented code.
R2-A0-030. R2 citation: `02-AUDIT-r1.md:199-204`.
126. CLI discipline: `flywheel-loop manager state --json`.
127. CLI discipline: `flywheel-loop manager state --markdown`.
128. CLI discipline: `flywheel-loop manager state --robot-schema`.
129. CLI discipline: `flywheel-loop manager validate state --json`.
130. CLI discipline: `flywheel-loop manager why <queue-item-id> --json`.
R2-A0-031. Root CLI discipline: `flywheel-loop manager doctor --json`.
R2-A0-032. Root CLI discipline: `flywheel-loop manager health --json`.
R2-A0-033. Root CLI discipline: `flywheel-loop manager repair --scope state --dry-run --json`.
R2-A0-034. Root CLI discipline: `flywheel-loop manager audit --json`.
R2-A0-035. Root CLI discipline: `flywheel-loop manager schema state --json`.
R2-A0-036. Root CLI discipline: `flywheel-loop manager --info --json`.
R2-A0-037. Root CLI discipline: `flywheel-loop manager --examples --json`.
R2-A0-038. Root CLI discipline: `flywheel-loop manager quickstart --json`.
R2-A0-039. Root CLI discipline: `flywheel-loop manager help state --json`.
R2-A0-040. Root CLI discipline: `flywheel-loop manager completion bash|zsh`.
R2-A0-041. Global CLI flags: `--json`, `--no-color`, `--no-emoji`, and `--width`.
R2-A0-042. Mutating CLI flags: `--dry-run`, `--apply`, `--explain`, and `--idempotency-key`.
R2-A0-043. R2 citation: `02-AUDIT-r1.md:71-78`.
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
R2-A1-001. Schema split: `manager-event-core/v1` is the only required base object.
R2-A1-002. Schema split: optional extensions are `mission`, `selector`, `retry_state`, `blocker_owner`, `skillos`, `validation`, `evidence`, and `reservation`.
R2-A1-003. Optional extensions may be absent without failing the mirror row when the event type does not need them.
R2-A1-004. Required extensions become required by `event_type`, not by every row.
R2-A1-005. R2 citation: `02-AUDIT-r1.md:169-174`.
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
R2-A1-006. Selector extension name: `selector`.
R2-A1-007. Selector field: `selector_source`.
R2-A1-008. Selector field: `selector_data_hash`.
R2-A1-009. Selector field: `selector_score`.
R2-A1-010. Selector field: `selector_unblocks`.
R2-A1-011. Selector field: `selector_reasons`.
R2-A1-012. Selector field: `selector_candidate_id`.
R2-A1-013. Selector field: `selector_claim_command`.
R2-A1-014. Selector field: `selector_show_command`.
R2-A1-015. Selector field: `selector_runtime_path`.
R2-A1-016. Selector field: `selector_fallback_reason`.
R2-A1-017. Selector field: `selector_error`.
R2-A1-018. Selector field: `selection_freshness_ts`.
R2-A1-019. Selector rows use `event_type=selector_candidate`.
R2-A1-020. R2 citation: `02-AUDIT-r1-cross-plan.md:137-157`.
R2-A1-021. Retry extension name: `retry_state`.
R2-A1-022. Retry field: `candidate_id`.
R2-A1-023. Retry field: `candidate_source`.
R2-A1-024. Retry field: `candidate_score`.
R2-A1-025. Retry field: `attempt_state_hash`.
R2-A1-026. Retry field: `attempt_count_window`.
R2-A1-027. Retry field: `state_changed_since_last_attempt`.
R2-A1-028. Retry field: `suppressed`.
R2-A1-029. Retry field: `suppression_reason`.
R2-A1-030. Retry field: `retry_after_seconds`.
R2-A1-031. Retry field: `retry_requires`.
R2-A1-032. Retry field: `upstream_gap`.
R2-A1-033. Retry state predicates include dependency, child bead, reservation, repair, probe, blocker, callback, and worker-started.
R2-A1-034. R2 citation: `02-AUDIT-r1-cross-plan.md:158-177`.
R2-A1-035. Blocker extension name: `blocker_owner`.
R2-A1-036. Blocker field: `blocker_owner`.
R2-A1-037. Blocker field: `work_blocked_at_source`.
R2-A1-038. Blocker field: `safe_local_work_remaining`.
R2-A1-039. Blocker field: `next_owner_for_blocker_path`.
R2-A1-040. Blocker field: `blocker_path_id`.
R2-A1-041. R2 citation: `02-AUDIT-r1-cross-plan.md:178-187`.
R2-A1-042. Peer log field: `peer_orch_canonical_log_path`.
R2-A1-043. Peer log field: `peer_orch_log_path_discovered_at`.
R2-A1-044. Peer log field: `peer_orch_log_path_source`.
R2-A1-045. R2 citation: `02-AUDIT-r1-cross-plan.md:188-199`.
233. Skillos integration: include `skill_invoked`.
234. Skillos citation: `cross-orch-input/skillos-1-2026-05-05T1555Z.md:23-29`.
235. Skillos integration: include peer canonical log path at registration time.
236. Skillos citation: `cross-orch-input/skillos-1-2026-05-05T1555Z.md:28-29`.
237. Skill eligibility: require `mission_anchor_evidence_path` for skill invocation rows.
238. Skillos citation: `cross-orch-input/skillos-1-2026-05-05T1555Z.md:30-38`.
R2-A1-046. Skillos fields are optional extension fields.
R2-A1-047. Manager-state generation cannot fail when skillos recommendation surface is absent.
R2-A1-048. A2 treats missing skillos recommendations as `skillos_recommendation_state=not_available`.
R2-A1-049. R2 citation: `02-AUDIT-r1.md:205-210`.
239. CLI discipline: `flywheel-loop manager ops-log validate --json`.
240. CLI discipline: `flywheel-loop manager ops-log doctor --json`.
241. CLI discipline: `flywheel-loop manager ops-log repair --dry-run --json`.
242. CLI discipline: `flywheel-loop manager ops-log why <event-id> --json`.
R2-A1-050. Ops-log CLI also inherits root `manager audit`, `manager schema ops-log`, `--info`, `--examples`, `quickstart`, `help ops-log`, and `completion`.
R2-A1-051. Quarantine path: `.flywheel/manager/quarantine.jsonl`.
R2-A1-052. Quarantine field: `quarantine_reason`.
R2-A1-053. Quarantine field: `source_row_ref`.
R2-A1-054. Quarantine field: `repair_action_ref`.
R2-A1-055. Quarantine threshold: DEGRADED when backlog exceeds 10 rows or oldest row exceeds two decision intervals.
R2-A1-056. Repair command: `flywheel-loop manager repair --scope quarantine --dry-run --json`.
R2-A1-057. R2 citation: `02-AUDIT-r1.md:193-198`.
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
R2-A2-001. `bv` fallback contract: A2 consumes `bv --robot-next` now and treats future top-N as an enhancement, not a blocker.
R2-A2-002. `bv` fallback contract: until a top-N robot contract exists, A2 builds top-N from A0 candidate facts, P1 selector receipts, retry-state receipts, and mission-anchor eligibility.
R2-A2-003. `bv` fallback contract: if neither `bv --robot-next` nor fallback source facts exist, A2 emits `queue_status=degraded:no_candidate_source`.
R2-A2-004. R2 citation: `02-AUDIT-r1.md:116-123`.
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
R2-A2-005. Queue robot command: `flywheel-loop manager queue --robot-next --json`.
R2-A2-006. Queue robot command: `flywheel-loop manager queue --robot-top-n --limit <n> --json`.
R2-A2-007. Queue robot command: `flywheel-loop manager queue --robot-schema --json`.
R2-A2-008. Queue robot command: `flywheel-loop manager queue why <queue-item-id> --json`.
R2-A2-009. Queue robot command: `flywheel-loop manager queue audit --json`.
R2-A2-010. R2 citation: `02-AUDIT-r1.md:80-87`.
R2-A2-011. Mission minimum field: `mission_anchor_id`.
R2-A2-012. Mission minimum field: `mission_anchor_evidence_path`.
R2-A2-013. Mission minimum field: `mission_delta_expected`.
R2-A2-014. Mission minimum field: `no_mission_anchor_reason`.
R2-A2-015. Mission minimum field: `validation_probe`.
R2-A2-016. Mission minimum field: `source_owner`.
R2-A2-017. R2 citation: `02-AUDIT-r1-cross-plan.md:200-215`.
327. Mission eligibility: work items require mission anchor.
328. Substrate exceptions: allowed only with typed `no_mission_anchor_reason`.
329. Substrate exception examples: driver repair, schema repair, storage receipt, callback import, reservation safety.
R2-A2-018. Substrate exception enum: `driver_repair`.
R2-A2-019. Substrate exception enum: `schema_repair`.
R2-A2-020. Substrate exception enum: `storage_receipt`.
R2-A2-021. Substrate exception enum: `callback_import`.
R2-A2-022. Substrate exception enum: `reservation_safety`.
R2-A2-023. Substrate exception enum: `security_redaction`.
R2-A2-024. Substrate exception field: `exception_owner`.
R2-A2-025. Substrate exception field: `expires_at`.
R2-A2-026. Substrate exception field: `max_queue_share_pct`.
R2-A2-027. Substrate exception threshold: DEGRADED when exceptions exceed 20 percent of actionable queue for two consecutive decision ticks.
R2-A2-028. R2 citation: `02-AUDIT-r1.md:107-114`.
R2-A2-029. Score component: `mission_value_weight`.
R2-A2-030. Score component: `urgency_weight`.
R2-A2-031. Score component: `unblock_weight`.
R2-A2-032. Score component: `confidence_weight`.
R2-A2-033. Score component: `if_wrong_cost_penalty`.
R2-A2-034. Score component: `substrate_exception_penalty`.
R2-A2-035. Valid mission closure evidence types: dispatch validated, bead closed with artifact proof, blocker removed with receipt, callback imported with task-id proof, and mission-anchor validation passed.
R2-A2-036. Weighted mission delta floor: HEALTHY requires positive weighted mission delta per pane-hour over active window.
R2-A2-037. R2 citation: `02-AUDIT-r1.md:152-159`.
330. Top-N naming: JSON preserves all eligible candidates; Markdown renders current top ten.
R2-A2-038. Machine contract name: `top_n_candidates`.
R2-A2-039. Markdown label: "top ten or fewer".
R2-A2-040. R2 citation: `02-AUDIT-r1-cross-plan.md:236-241`.
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
R2-A3-001. Tick lock fixture: active lock causes skipped receipt with prior lock ref.
R2-A3-002. Tick lock fixture: stale lock repair dry-run reports planned unlock and no write.
R2-A3-003. Tick lock fixture: stale lock apply requires `--apply --idempotency-key` and writes repair receipt.
R2-A3-004. R2 citation: `02-AUDIT-r1.md:255-259`.
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
R2-A3-005. Decision receipt field: `mode=dry_run|apply`.
R2-A3-006. Decision receipt field: `input_hash`.
R2-A3-007. Decision receipt field: `selected_item_hash`.
R2-A3-008. Decision receipt field: `idempotency_key_scope`.
R2-A3-009. Idempotency key binds `mode`, `input_state_hash`, `queue_hash`, `selected_item_hash`, and `decision_group`.
R2-A3-010. Dry-run receipt can never be replayed as apply receipt.
R2-A3-011. Apply receipt can never be duplicated for a different selected item hash.
R2-A3-012. R2 citation: `02-AUDIT-r1.md:134-141`.
421. Default cadence: decision tick every 300 seconds.
422. Multi-model citation: `01-REVIEW-multi-model.md:421-490`.
423. Ingest cadence: 60 seconds for source freshness.
424. Render cadence: 600 seconds or on demand for human Markdown.
425. Safety path: event-driven, not interval-bound.
426. One-decision rule: one discretionary decision group per tick.
427. Safety actions, validation imports, state render, and receipt repair are not capped by the discretionary decision limit.
R2-A3-013. Safety budget: at most three autonomous safety action groups per decision tick.
R2-A3-014. Safety ordering: security/redaction, stale lock repair, callback import, source freshness, reservation safety, pane-state repair.
R2-A3-015. Safety starvation field: `safety_starvation_count`.
R2-A3-016. Skipped safety field: `skipped_safety_reason`.
R2-A3-017. Skipped safety field: `next_safety_check_at`.
R2-A3-018. R2 citation: `02-AUDIT-r1.md:125-132`.
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
R2-A3-019. Cadence review metric: P95 ingest latency.
R2-A3-020. Cadence review metric: P95 decision latency.
R2-A3-021. Cadence review metric: P95 validation latency.
R2-A3-022. Cadence review metric: P95 render latency.
R2-A3-023. Cadence change requires config receipt with before/after metrics and rollback threshold.
R2-A3-024. R2 citation: `02-AUDIT-r1.md:217-221`.
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
R2-A4-001. Render input path: `.flywheel/manager/state/manager-state.json`.
R2-A4-002. Render input path: `.flywheel/manager/state/queue.json`.
R2-A4-003. Render output path: `.flywheel/manager/state/manager-state.md`.
R2-A4-004. Render output path: `.flywheel/manager/state/manager-surface.json`.
R2-A4-005. Render schema path: `.flywheel/manager/state/manager-surface.schema.json`.
R2-A4-006. R2 citation: `02-AUDIT-r1.md:89-96`.
R2-A4-007. Renderer must consume already redacted state and must not load raw ledgers directly.
R2-A4-008. Renderer output must include `redaction_status` summary and refuse unsafe raw values.
R2-A4-009. R2 citation: `02-AUDIT-r1.md:98-105`.
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
R2-A4-010. Pending Joshua decisions also carry `blocker_owner`.
R2-A4-011. Pending Joshua decisions also carry `work_blocked_at_source`.
R2-A4-012. Pending Joshua decisions also carry `next_owner_for_blocker_path`.
R2-A4-013. R2 citation: `02-AUDIT-r1-cross-plan.md:178-187`.
R2-A4-014. Robot smoke must verify a peer can read rendered robot JSON without parsing Markdown.
R2-A4-015. Robot smoke must verify a peer can map one displayed human question back to source refs.
R2-A4-016. R2 citation: `02-AUDIT-r1.md:199-204`.
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
R2-A5-001. Parity window N is exactly 288 decision ticks at 300 seconds, or one complete overnight failure corpus replay, whichever has more callback evidence.
R2-A5-002. Material divergence field: callback task id missing from manager-state.
R2-A5-003. Material divergence field: DONE/BLOCKED status mismatch.
R2-A5-004. Material divergence field: severity/status mismatch affecting closure or health.
R2-A5-005. Material divergence field: manual callback missing by task id.
R2-A5-006. Material divergence field: source hash mismatch after excluding volatile fields.
R2-A5-007. Material divergence field: stale Markdown with valid JSON is DEGRADED, not cutover-ready.
R2-A5-008. Allowed drift: timestamp formatting and display wrapping only.
R2-A5-009. Fail-closed behavior: any material divergence blocks cutover and emits repair/import target.
R2-A5-010. Rollback behavior: callback source channel re-enabled by config receipt if post-cutover regression appears.
R2-A5-011. R2 citation: `02-AUDIT-r1.md:143-150`.
R2-A5-012. Positive parity fixture: valid match across callback, manager-state, and ops-log mirror.
R2-A5-013. Negative parity fixture: stale Markdown with valid JSON.
R2-A5-014. Negative parity fixture: hash mismatch.
R2-A5-015. Negative parity fixture: invalid JSON.
R2-A5-016. R2 citation: `02-AUDIT-r1.md:211-216`.
592. Multi-model citation: `01-REVIEW-multi-model.md:858-865`.
593. Donella citation: `01-REVIEW-donella.md:888-891`.
594. Jeff citation: `01-REVIEW-jeff.md:940-943`.
595. CLI discipline: `flywheel-loop manager migration status --json`.
596. CLI discipline: `flywheel-loop manager migration import-callback --task-id <id> --json`.
597. CLI discipline: `flywheel-loop manager migration cutover --dry-run --json`.
598. CLI discipline: `flywheel-loop manager migration cutover --apply --json`.
599. CLI discipline: `flywheel-loop manager migration rollback --dry-run --json`.
R2-A5-017. Migration CLI also inherits `audit`, `schema migration`, `--info`, `--examples`, `quickstart`, `help migration`, `completion`, `--no-color`, `--no-emoji`, and `--width`.
R2-A5-018. R2 citation: `02-AUDIT-r1.md:181-186`.
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

617. Ship order is final for this integrated plan after R2 fold-back.
618. Step 0: G0 cross-plan contract freeze.
R2-SO-001. G0 output: M-id to A-id alias table.
R2-SO-002. G0 output: `selector_receipt/v1`.
R2-SO-003. G0 output: `retry_state_receipt/v1`.
R2-SO-004. G0 output: blocker-owner fields.
R2-SO-005. G0 output: `mission_anchor_minimum/v1`.
R2-SO-006. G0 output: explicit rule that A1 is mirror/index only.
R2-SO-007. R2 citation: `02-AUDIT-r1-cross-plan.md:370-379`.
R2-SO-008. Global Step 1: Fleet P1+P2 selector and retry stop-bleed implementation, after G0.
R2-SO-009. Global Step 1 output: selector and suppression receipts in dispatch-log or receipt JSONL, not direct A1 authority rows.
R2-SO-010. R2 citation: `02-AUDIT-r1-cross-plan.md:380-386`.
619. Manager Step 1: A0 manager-state read model.
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
R2-SO-011. Cross-plan ship-order verdict: G0 first, P1+P2 first implementation globally, A0 first manager-loop implementation.
R2-SO-012. A1 is not first anywhere.
R2-SO-013. Callback death is not near-term.
R2-SO-014. R2 citation: `02-AUDIT-r1-cross-plan.md:431-434`.
R2-SO-015. R2 citation: `02-AUDIT-r1-cross-plan.md:493-510`.

## 4. Cross-Plan Reconciliation

673. This plan explicitly deprecates parts of fleet-autonomy-v1.
R2-XP-001. Cross-plan alias table is mandatory before implementation dispatch.
R2-XP-002. Alias: old `M1` maps to A1 only when discussing ops-log mirror/index.
R2-XP-003. Alias: old `M2` maps to A3 manager tick driver.
R2-XP-004. Alias: old `M3` maps to A2 scoring governor and queue.
R2-XP-005. Alias: old `M4` maps to A4 renderer, not A0 manager-state.
R2-XP-006. Alias: old `P3 status brain` maps to A0 state fields plus A4 projection.
R2-XP-007. R2 citation: `02-AUDIT-r1-cross-plan.md:85-100`.
R2-XP-008. Layer rule: P3 status fields land in A0 manager-state.
R2-XP-009. Layer rule: morning ritual rendering lands in A4 renderer.
R2-XP-010. R2 citation: `02-AUDIT-r1-cross-plan.md:114-124`.
R2-XP-011. Ownership rule: A0/A2/A3/A5 own manager policy surfaces.
R2-XP-012. Ownership rule: A1 mirrors evidence and may not be named as control-plane owner.
R2-XP-013. R2 citation: `02-AUDIT-r1-cross-plan.md:125-133`.
R2-XP-014. Metric owner rule: Fleet may emit mission deltas; Manager computes global mission stock.
R2-XP-015. Metric field: `mission_delta_source`.
R2-XP-016. Metric field: `mission_delta_validation_state`.
R2-XP-017. Metric field: `mission_delta_computed_by=manager`.
R2-XP-018. R2 citation: `02-AUDIT-r1-cross-plan.md:307-316`.
R2-XP-019. Redispatch stock split: Fleet owns `same_candidate_without_state_delta`.
R2-XP-020. Redispatch stock split: Manager owns `duplicate_decision_or_dispatch`.
R2-XP-021. Join fields: `candidate_id`, `attempt_state_hash`, and `dispatch_id`.
R2-XP-022. R2 citation: `02-AUDIT-r1-cross-plan.md:317-324`.
R2-XP-023. Callback parity stock rule: Manager A5 owns parity verdict.
R2-XP-024. Fleet role: emit callback facts and selector receipts.
R2-XP-025. Fleet may not declare callback cutover safe.
R2-XP-026. R2 citation: `02-AUDIT-r1-cross-plan.md:325-332`.
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

## 6. Open Questions For R2 Audit

830. Open questions for R2 audit count: 7.
831. Audit question 01: JSONL shards or SQLite index after shadow mode?
832. Default before audit: JSONL mirror/index from owner ledgers.
833. Audit evidence needed: query latency and corruption/repair rate after replay.
834. Audit question 02: is the R2 parity window strict enough?
835. Default before audit: 288 decision ticks or one complete overnight replay, whichever has more callback evidence.
836. Audit evidence needed: callback/log divergence distribution under valid and invalid fixtures.
837. Audit question 03: exact scoring weights for `manager-queue/v1`.
838. Default before audit: deterministic weights with visible components, `mission_value_weight`, and weighted mission delta floor.
839. Audit evidence needed: rank vs validated mission closure per pane-hour.
840. Audit question 04: which upstream `bv` robot top-N contract is needed after fallback proves useful?
841. Default before audit: use fallback; draft upstream issue only when manager-state proves top-N contract gap.
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
934. Final verdict: pass-to-r2-audit after R1 fold-back.
935. Final composite: 9.72.
936. Planning-workflow conformance: 9.8.
937. Donella authenticity: 9.7.
938. Jeff substrate compatibility: 9.7.
939. Joshua taste: 9.7.
940. Publishability after redaction: 9.45 advisory until public-redaction pass.
941. Ship first primitive: A0-manager-state-read-model.
942. Final deprecations: fleet-autonomy P3 independent controller, fleet-autonomy M primary measurement, callback-as-orchestrator-input.
943. Final preserved primitives: `bv` selection, retry-after-state-change, status schema fields, driver proof, dispatch delivery receipt, Agent Mail reservation safety, ntm pane actuation boundary, mission-anchor licensing.
944. L112 expected string: OK_reintegrate_r2_manager_loop.

## 8. Audit-Finding Integration Table

| ID | Category | Disposition | Audit citation | R2 location |
| --- | --- | --- | --- | --- |
| H01 | canonical CLI root surface | Accepted | `02-AUDIT-r1.md:71-78` | R2-A0-031..043; R2-A1-050; R2-A5-017 |
| H02 | robot-mode queue commands | Accepted | `02-AUDIT-r1.md:80-87` | R2-A2-005..010 |
| H03 | exact artifact paths | Accepted | `02-AUDIT-r1.md:89-96` | R2-A0-001..008; R2-A4-001..006 |
| H04 | redaction/security pipeline | Accepted | `02-AUDIT-r1.md:98-105` | R2-A0-017..024; R2-A4-007..009 |
| H05 | bounded mission exceptions | Accepted | `02-AUDIT-r1.md:107-114` | R2-A2-018..028 |
| H06 | `bv` top-N dependency | Accepted-with-revision | `02-AUDIT-r1.md:116-123` | R2-A2-001..004 |
| H07 | safety action budget | Accepted | `02-AUDIT-r1.md:125-132` | R2-A3-013..018 |
| H08 | dry-run/apply idempotency | Accepted | `02-AUDIT-r1.md:134-141` | R2-A3-005..012 |
| H09 | callback parity N/material divergence | Accepted-with-revision | `02-AUDIT-r1.md:143-150` | R2-A5-001..011 |
| H10 | mission value weighting | Accepted | `02-AUDIT-r1.md:152-159` | R2-A2-029..037 |
| M01 | command namespace consistency | Accepted | `02-AUDIT-r1.md:163-167` | R2-A0-031..043; R2-XP-001..007 |
| M02 | schema core vs extensions | Accepted | `02-AUDIT-r1.md:169-174` | R2-A1-001..005 |
| M03 | replay fixture specificity | Accepted | `02-AUDIT-r1.md:175-180` | R2-VT-033..044 |
| M04 | CLI global flags/help/schema | Accepted | `02-AUDIT-r1.md:181-186` | R2-A0-031..043; R2-A1-050; R2-A5-017 |
| M05 | source registry | Accepted | `02-AUDIT-r1.md:187-191` | R2-A0-009..016 |
| M06 | quarantine contract | Accepted | `02-AUDIT-r1.md:193-198` | R2-A1-051..057 |
| M07 | peer robot consumer smoke | Accepted | `02-AUDIT-r1.md:199-204` | R2-A0-029..030; R2-A4-014..016 |
| M08 | skillos optionality | Accepted-with-revision | `02-AUDIT-r1.md:205-210` | R2-A1-046..049 |
| M09 | divergence fixtures | Accepted | `02-AUDIT-r1.md:211-216` | R2-A5-012..016 |
| M10 | cadence evidence rule | Accepted | `02-AUDIT-r1.md:217-221` | R2-A3-019..024 |
| L01 | leverage distribution naming | Accepted | `02-AUDIT-r1.md:225-230` | frontmatter `donella_leverage_distribution` |
| L02 | reversibility caveat | Accepted-with-revision | `02-AUDIT-r1.md:231-235` | R2-VT-045..050 |
| L03 | glossary | Accepted | `02-AUDIT-r1.md:237-242` | R2-GL-001..015 |
| L04 | hash proof contract | Accepted | `02-AUDIT-r1.md:243-248` | R2-VT-021..032 |
| L05 | publishability caveat | Accepted | `02-AUDIT-r1.md:249-254` | R2-VT-055..059 |
| L06 | tick lock fixtures | Accepted | `02-AUDIT-r1.md:255-259` | R2-A3-001..004 |

R2-TBL-009. H06 reasoning: the audit offered "consume `bv --robot-triage` or block A2"; R2 chooses deterministic fallback so A2 is useful before top-N exists.
R2-TBL-010. H06 blunder defense: blocking A2 on future `bv` would turn an upstream contract gap into a manager-loop stall.
R2-TBL-011. H09 reasoning: the audit asked to define N; R2 makes N a concrete 288 ticks or replay corpus, whichever carries more evidence.
R2-TBL-012. H09 blunder defense: "24h" alone is not enough if there are no callbacks; replay corpus prevents empty parity.
R2-TBL-013. M08 reasoning: skillos recommendations are useful, but absence cannot fail manager-state generation.
R2-TBL-014. M08 blunder defense: hard-depending on skillos before A1 exists recreates a cross-plan dependency cycle.
R2-TBL-015. L02 reasoning: A0 is reversible before dependents consume it; after A2/A4/A1 depend on its schemas, rollback must be config-gated.
R2-TBL-016. L02 blunder defense: "delete without mutation" remains true only for the read model output, not for downstream contracts.

## 9. Cross-Plan Reconciliation Deltas

R2-XD-001. Source cross-plan audit: `../02-AUDIT-r1-cross-plan.md`.
R2-XD-002. Cross-plan findings resolved: 17.
R2-XD-003. Required closeout actions resolved: 10 of 10.
R2-XD-004. Layer leaks resolved: 4 of 4.
R2-XD-005. Contract gaps resolved: 5 of 5.
R2-XD-006. Naming collisions resolved: 4 of 4.
R2-XD-007. Stock conflicts resolved: 3 of 3.
R2-XD-008. Dependency cycles after correction: 0.

| Cross-plan ID | Disposition | Audit citation | R2 plan resolution |
| --- | --- | --- | --- |
| F01 | Resolved | `02-AUDIT-r1-cross-plan.md:494-495` | R2-XP-001..007 alias table |
| F02 | Resolved | `02-AUDIT-r1-cross-plan.md:495-496` | R2-SO-008..010 and R2-A0-025..026 |
| F03 | Resolved | `02-AUDIT-r1-cross-plan.md:496-497` | R2-XP-008..010 |
| F04 | Resolved | `02-AUDIT-r1-cross-plan.md:497-498` | R2-XP-011..013 |
| F05 | Resolved | `02-AUDIT-r1-cross-plan.md:498-499` | R2-A1-006..020 |
| F06 | Resolved | `02-AUDIT-r1-cross-plan.md:499-500` | R2-A1-021..034 |
| F07 | Resolved | `02-AUDIT-r1-cross-plan.md:500-501` | R2-A1-035..041 |
| F08 | Resolved | `02-AUDIT-r1-cross-plan.md:501-502` | R2-A1-042..045 |
| F09 | Resolved | `02-AUDIT-r1-cross-plan.md:502-503` | R2-A2-011..017 |
| F10 | Resolved | `02-AUDIT-r1-cross-plan.md:503-504` | R2-SO-001..015 |
| F11 | Resolved | `02-AUDIT-r1-cross-plan.md:504-505` | R2-XP-014..018 |
| F12 | Resolved | `02-AUDIT-r1-cross-plan.md:505-506` | R2-XP-019..022 |
| F13 | Resolved | `02-AUDIT-r1-cross-plan.md:506-507` | R2-XP-023..026; R2-A5-001..011 |
| F14 | Resolved | `02-AUDIT-r1-cross-plan.md:507-508` | R2-A2-038..040 |
| F15 | Resolved | `02-AUDIT-r1-cross-plan.md:508-509` | R2-A1-046..049 |
| F16 | Resolved | `02-AUDIT-r1-cross-plan.md:509-510` | R2-A2-011..017 and R2-XD-040..044 |
| F17 | Resolved | `02-AUDIT-r1-cross-plan.md:510-512` | R2-SO-001..015 and R2-XP-001..026 |

R2-XD-009. Closeout action 1 resolved: Fleet M-id references require alias table before implementation.
R2-XD-010. R2 citation: `02-AUDIT-r1-cross-plan.md:519-520`.
R2-XD-011. Closeout action 2 resolved: cross-plan alias table exists in R2-XP-001..007.
R2-XD-012. R2 citation: `02-AUDIT-r1-cross-plan.md:520-521`.
R2-XD-013. Closeout action 3 resolved: P1/P2 receipt write path precedes A1 authority.
R2-XD-014. R2 citation: `02-AUDIT-r1-cross-plan.md:521-522`.
R2-XD-015. Closeout action 4 resolved: selector fields added to A1/A0 schema.
R2-XD-016. R2 citation: `02-AUDIT-r1-cross-plan.md:522-523`.
R2-XD-017. Closeout action 5 resolved: retry-state fields added to A1/A0 schema.
R2-XD-018. R2 citation: `02-AUDIT-r1-cross-plan.md:523-524`.
R2-XD-019. Closeout action 6 resolved: blocker-owner fields added to A1/A0/A4 contract.
R2-XD-020. R2 citation: `02-AUDIT-r1-cross-plan.md:524-525`.
R2-XD-021. Closeout action 7 resolved: minimal mission-anchor schema frozen.
R2-XD-022. R2 citation: `02-AUDIT-r1-cross-plan.md:525-526`.
R2-XD-023. Closeout action 8 resolved: A5 is sole callback parity verdict owner.
R2-XD-024. R2 citation: `02-AUDIT-r1-cross-plan.md:526-527`.
R2-XD-025. Closeout action 9 resolved: global sequence G0-G13 is incorporated as G0/P1+P2/A0/A2/A4/A1/A5/A3 with later P4-P6/compiler evaluation.
R2-XD-026. R2 citation: `02-AUDIT-r1-cross-plan.md:527-528`.
R2-XD-027. Closeout action 10 resolved: skillos and compiler remain non-blocking and outside Manager/Fleet ownership.
R2-XD-028. R2 citation: `02-AUDIT-r1-cross-plan.md:528-529`.
R2-XD-029. Contract name: `selector_receipt/v1`.
R2-XD-030. Owner: Fleet P1.
R2-XD-031. Consumer: A0 and A2.
R2-XD-032. Validation: dispatch-log append validates JSON or local selector receipt JSONL validates schema.
R2-XD-033. R2 citation: `02-AUDIT-r1-cross-plan.md:558-564`.
R2-XD-034. Contract name: `retry_state_receipt/v1`.
R2-XD-035. Owner: Fleet P2.
R2-XD-036. Consumer: A0, A2, and A5.
R2-XD-037. Validation: state-change predicate is typed.
R2-XD-038. R2 citation: `02-AUDIT-r1-cross-plan.md:564-569`.
R2-XD-039. Contract name: `mission_anchor_minimum/v1`.
R2-XD-040. Owner: flywheel cross-plan contract until mission-coverage-compiler ships.
R2-XD-041. Consumer: Fleet P1/P2, Manager A2, and skillos skill eligibility.
R2-XD-042. It is not the full mission-coverage compiler.
R2-XD-043. It only prevents mission-blind dispatch.
R2-XD-044. R2 citation: `02-AUDIT-r1-cross-plan.md:582-585`.

## 10. R2 Glossary

R2-GL-001. `manager-state.json`: canonical A0 JSON read model over existing ledgers and robot surfaces.
R2-GL-002. `manager-state.md`: A4 human projection rendered from manager-state JSON.
R2-GL-003. `manager-surface.json`: A4 robot projection for peer readers.
R2-GL-004. `queue.json`: A2 ranked candidate list with score components and eligibility state.
R2-GL-005. `top_n_candidates`: machine contract for all eligible ranked candidates.
R2-GL-006. "top ten or fewer": Markdown rendering phrase for the current highest-ranked visible candidates.
R2-GL-007. `ops-log mirror`: A1 compatibility mirror/index over owner ledgers and imported callbacks.
R2-GL-008. `ops-log authority`: deferred future promotion that is not part of R2.
R2-GL-009. `decision receipt`: A3 or A5 JSON receipt that binds inputs, selected item, mode, idempotency, and validation.
R2-GL-010. `selector receipt`: Fleet P1 output consumed by A0/A2 before A1 exists.
R2-GL-011. `retry_state receipt`: Fleet P2 output consumed by A0/A2/A5 before A1 exists.
R2-GL-012. `mission_anchor_minimum/v1`: small cross-plan schema proving mission linkage now.
R2-GL-013. `mission-coverage-compiler`: later richer plan that owns the full mission matrix.
R2-GL-014. `callback parity verdict`: A5-owned verdict over compatibility callbacks and manager-state/import surfaces.
R2-GL-015. R2 citation: `02-AUDIT-r1.md:237-242`.

## 11. R2 Verdict Thresholds And Measurement Revisions

R2-VT-001. R2 preserves the original HEALTHY/DEGRADED/BROKEN vocabulary.
R2-VT-002. R2 revises primary mission closure from count-only trend to weighted mission delta.
R2-VT-003. Primary HEALTHY: weighted mission delta per pane-hour is positive over active window.
R2-VT-004. Primary DEGRADED: weighted mission delta is flat for 4 decision ticks while dispatches continue.
R2-VT-005. Primary BROKEN: weighted mission delta is zero for 8 decision ticks while dispatches continue.
R2-VT-006. R2 citation: `02-AUDIT-r1.md:152-159`.
R2-VT-007. Callback parity HEALTHY: zero material divergence for 288 decision ticks or overnight corpus replay, whichever has more callback evidence.
R2-VT-008. Callback parity DEGRADED: divergence exists but import/repair path is active and cutover remains blocked.
R2-VT-009. Callback parity BROKEN: divergence affects closure, health, or truth classification.
R2-VT-010. R2 citation: `02-AUDIT-r1.md:143-150`.
R2-VT-011. Source freshness HEALTHY: all required sources are fresh or have typed fallback.
R2-VT-012. Source freshness DEGRADED: one required source stale with fallback used.
R2-VT-013. Source freshness BROKEN: required source stale without fallback.
R2-VT-014. R2 citation: `02-AUDIT-r1.md:187-191`.
R2-VT-015. Exception share HEALTHY: substrate exceptions under 20 percent of actionable queue.
R2-VT-016. Exception share DEGRADED: substrate exceptions exceed 20 percent for two consecutive decision ticks.
R2-VT-017. Exception share BROKEN: substrate exceptions bypass mission gating without owner and expiry.
R2-VT-018. R2 citation: `02-AUDIT-r1.md:107-114`.
R2-VT-019. Cadence HEALTHY: P95 ingest, decision, validation, and render latency fit current cadence.
R2-VT-020. Cadence changes require config receipt and rollback threshold.
R2-VT-021. Hash algorithm: SHA-256 over canonical JSON.
R2-VT-022. Canonical JSON sort: keys sorted recursively.
R2-VT-023. Excluded volatile fields: `generated_at`, `observed_at`, `duration_ms`, and terminal display width.
R2-VT-024. Storage path: `.flywheel/manager/receipts/source-hashes/`.
R2-VT-025. Hash proof applies to A0 manager-state, A2 queue, A4 render, A5 parity corpus, and A3 decision receipt inputs.
R2-VT-026. R2 citation: `02-AUDIT-r1.md:243-248`.
R2-VT-027. Replay fixture path: `.flywheel/manager/fixtures/overnight-callback-overload/`.
R2-VT-028. Replay fixture path: `.flywheel/manager/fixtures/skillos-manual-callback-gap/`.
R2-VT-029. Replay fixture path: `.flywheel/manager/fixtures/mobile-eats-mission-compression/`.
R2-VT-030. Replay fixture path: `.flywheel/manager/fixtures/parity-valid-match/`.
R2-VT-031. Replay fixture path: `.flywheel/manager/fixtures/parity-stale-markdown/`.
R2-VT-032. Replay fixture path: `.flywheel/manager/fixtures/parity-invalid-json/`.
R2-VT-033. Replay command: `flywheel-loop manager replay --fixture <name> --json`.
R2-VT-034. Expected output: fixture-specific verdict plus source hash proof.
R2-VT-035. R2 citation: `02-AUDIT-r1.md:175-180`.
R2-VT-036. Reversibility before dependents: A0 output can be deleted and regenerated from owner ledgers.
R2-VT-037. Reversibility after dependents: A0 schema changes require compatibility shim or migration receipt.
R2-VT-038. Reversibility before cutover: A5 can refuse cutover and callbacks remain active.
R2-VT-039. Reversibility after cutover: callback source channel can be restored by rollback config receipt.
R2-VT-040. Reversibility for A3: dry-run mode can be stopped by driver config; apply mode requires rollback hint per decision receipt.
R2-VT-041. R2 citation: `02-AUDIT-r1.md:231-235`.
R2-VT-042. Public publishability score is advisory until a public-redaction pass runs.
R2-VT-043. Composite gate passes at 9.72.
R2-VT-044. Publishability after redaction remains 9.45 and does not block R2 plan-space convergence.
R2-VT-045. R2 citation: `02-AUDIT-r1.md:249-254`.
R2-VT-046. R2 final verdict: pass-to-r2-audit.
R2-VT-047. R2 composite: 9.72.
R2-VT-048. Planning-workflow conformance: 9.8.
R2-VT-049. Donella authenticity: 9.75.
R2-VT-050. Jeff substrate compatibility: 9.75.
R2-VT-051. Joshua taste: 9.75.
R2-VT-052. Critical findings remaining: 0.
R2-VT-053. High findings remaining in plan-space: 0 known after fold-back.
R2-VT-054. R2 audit should verify the fold-back rather than re-open r1 unless a contradiction remains.
R2-VT-055. L112 expected string: `OK_reintegrate_r2_manager_loop`.
