# External Prior-Art Audit: Wire-Or-Explain Tick Gate
plan: wire-or-explain-tick-gate-2026-05-04
task_id: woe-research-triad-external-05dd33
mode: READ-ONLY plan-space audit
generated_utc: 2026-05-04T23:03:09Z
primary_skill: research-triad
supporting_skills: donella-meadows-systems-thinking, gate-truth-separation, lean-formal-feedback-loop
## 0. Executive Verdict
Composite score: 8.3 / 10.0.
Pass threshold: 7.0.
Verdict: PASS.
The external corpus strongly supports the direction of the plan.
The strongest convergence is around provenance, lineage, attestation,
append-only evidence, event history, trace context, and telemetry moving from
observation into enforcement.
The exact plan primitive remains locally greenfield:
an orchestrator tick-close permit gate that refuses green closeout while a
shipped artifact has no consumer path and no bounded explanation.
The plan should not abandon the product phrase "wire-or-explain".
It should add standards-compatible schema aliases so future readers can map the
local language to industry language:
provenance, lineage, attestation, subject, predicate, consumer, event history.
This is a flow gate.
It is not a code gate, process gate, safety gate, or mission gate.
It regulates the stock of unresolved shipped artifacts by acting at the point
where operational flow would otherwise close green.
## 1. Inputs Read
Internal source I01:
.flywheel/plans/wire-or-explain-tick-gate-2026-05-04/00-INTENT.md
Internal source I02:
.flywheel/plans/wire-or-explain-tick-gate-2026-05-04/02-REFINE-r2.md
Internal source I03:
/tmp/jeff-corpus-archaeology-wire-or-explain-output.md
Internal source I04:
~/.claude/skills/research-triad/SKILL.md
Internal source I05:
~/.claude/skills/research-triad/configs/
Internal source I06:
~/.claude/skills/gate-truth-separation/SKILL.md
Internal source I07:
~/.claude/skills/donella-meadows-systems-thinking/SKILL.md
Internal source I08:
~/.claude/skills/lean-formal-feedback-loop/SKILL.md
## 2. Research Procedure
Local calibration:
research where "wire explain artifact lifecycle gate"
result: 0 local hits.
Local calibration:
research where "workflow provenance lineage attestation"
result: 0 local hits.
Local calibration:
research where "agent observability tool telemetry"
result: 0 local hits.
Source health:
research --version reported research 0.1.0.
Source health:
arxiv source returned live results.
Source health:
GitHub API rate limits were healthy at probe time.
Triangulation command A:
research triangulate "artifact provenance workflow gate" --max 5 --no-cache --json
Triangulation command B:
research triangulate "agent observability tool telemetry" --max 5 --no-cache --json
Triangulation command C:
research triangulate "software supply chain provenance attestation" --max 5 --no-cache --json
Triangulation command D:
research triangulate "workflow durability lineage state machine" --max 5 --no-cache --json
Targeted arxiv probes:
workflow provenance distributed ledgers.
Targeted arxiv probes:
software supply chain provenance attestation.
Targeted arxiv probes:
agent telemetry governance.
Targeted arxiv probes:
workflow anomaly detection provenance.
Socraticode pre-flight:
3 codebase_search queries, 30 indexed chunks observed.
## 3. Sources Cited
| id | axis | source | URL | retrieval_ts | grade | relevance |
|---|---|---|---|---|---|---|
| S01 | arxiv | Applying Distributed Ledgers to Manage Workflow Provenance | https://arxiv.org/pdf/1804.05395v1 | 2026-05-04T22:58:43Z | HIGH | Workflow provenance plus immutable ledger shape. |
| S02 | arxiv | Using Cloud-Aware Provenance to Reproduce Scientific Workflow Execution on Cloud | https://arxiv.org/pdf/1511.09061v1 | 2026-05-04T22:58:43Z | MED | Provenance as reproducibility substrate for workflow execution. |
| S03 | arxiv | Efficiently Processing Workflow Provenance Queries on SPARK | https://arxiv.org/pdf/1808.08424v2 | 2026-05-04T22:58:43Z | MED | Query and scale concerns for provenance ledgers. |
| S04 | arxiv | Governance-Aware Agent Telemetry for Closed-Loop Enforcement in Multi-Agent AI Systems | https://arxiv.org/pdf/2604.05119v1 | 2026-05-04T22:58:43Z | HIGH | Direct convergence on telemetry becoming enforcement. |
| S05 | arxiv | AgentGuard: Repurposing Agentic Orchestrator for Safety Evaluation of Tool Orchestration | https://arxiv.org/pdf/2502.09809v1 | 2026-05-04T22:58:43Z | MED | Tool orchestration failures and agentic safety evaluation. |
| S06 | arxiv | SoK: Analysis of Software Supply Chain Security by Establishing Secure Design Properties | https://arxiv.org/pdf/2406.10109v1 | 2026-05-04T22:58:44Z | HIGH | Transparency, validity, and separation properties for supply chains. |
| S07 | arxiv | Flow-Bench: A Dataset for Computational Workflow Anomaly Detection | https://arxiv.org/pdf/2306.09930v2 | 2026-05-04T22:58:43Z | MED | Workflow anomaly detection and failure-mode framing. |
| S08 | anthropic | Building Effective AI Agents | https://www.anthropic.com/engineering/building-effective-agents | 2026-05-04T23:03:09Z | HIGH | Workflow, orchestrator-worker, evaluator-optimizer, and tool-use patterns. |
| S09 | anthropic | How we built our multi-agent research system | https://www.anthropic.com/engineering/multi-agent-research-system | 2026-05-04T23:03:09Z | HIGH | Multi-agent statefulness, checkpointing, and error compounding. |
| S10 | anthropic | Define tools - Claude API Docs | https://platform.claude.com/docs/en/agents-and-tools/tool-use/define-tools | 2026-05-04T23:03:09Z | MED | Tool schema and structured tool contract framing. |
| S11 | industry | SLSA specification v1.2 | https://slsa.dev/spec/v1.2/ | 2026-05-04T23:03:09Z | HIGH | Levels, provenance, verification, and artifact security model. |
| S12 | industry | in-toto Attestation Framework Spec | https://github.com/in-toto/attestation/blob/main/spec/README.md | 2026-05-04T23:03:09Z | HIGH | Statement, subject, predicate, envelope, bundle model. |
| S13 | industry | Sigstore Rekor overview | https://docs.sigstore.dev/logging/overview/ | 2026-05-04T23:03:09Z | HIGH | Immutable transparency log and inclusion-proof model. |
| S14 | industry | GitHub Artifact Attestations | https://docs.github.com/en/enterprise-cloud%40latest/actions/concepts/security/artifact-attestations | 2026-05-04T23:03:09Z | HIGH | Practical artifact attestation and transparency-log integration. |
| S15 | industry | OpenTelemetry specification overview | https://opentelemetry.io/docs/specs/otel/overview/ | 2026-05-04T23:03:09Z | HIGH | Spans, trace context, propagated causal relationships, metrics, logs. |
| S16 | industry | OpenLineage Spec | https://github.com/OpenLineage/OpenLineage/blob/main/spec/OpenLineage.md | 2026-05-04T23:03:09Z | HIGH | Run events, jobs, datasets, facets, immutable schema URLs. |
| S17 | industry | Airflow OpenLineage integration | https://airflow.apache.org/docs/apache-airflow-providers-openlineage/stable/guides/structure.html | 2026-05-04T23:03:09Z | MED | Workflow scheduler integration without DAG file changes. |
| S18 | industry | Temporal Platform Documentation | https://docs.temporal.io/ | 2026-05-04T23:03:09Z | MED | Durable execution and resume-from-state workflow model. |
## 4. Query Bundle 1: Artifact Lifecycle Gates
Query bundle:
artifact lifecycle gates, provenance, lineage, attestation, and workflow evidence.
Finding 1.1:
External work does not use the exact local phrase "wire-or-explain".
Finding 1.2:
The strongest external vocabulary is "provenance" and "lineage".
Finding 1.3:
Workflow provenance research treats execution metadata as evidence that enables
reproduction, verification, and cross-system exchange. [S01] [S02] [S03]
Finding 1.4:
SLSA and in-toto provide a mature subject/predicate model for artifact evidence.
[S11] [S12]
Finding 1.5:
Sigstore/Rekor and GitHub Artifact Attestations show that append-only transparency
logs are production-grade patterns for software artifact evidence. [S13] [S14]
Finding 1.6:
OpenLineage gives the cleanest vocabulary for consumer relationships:
run events, jobs, datasets, inputs, outputs, and facets. [S16]
Finding 1.7:
Airflow/OpenLineage confirms that lineage capture can be integrated into a
workflow scheduler without asking every producer to hand-roll lineage code. [S17]
Implication for wire-or-explain:
B1 should use attestation-like row shape, not a bespoke ad hoc row shape.
Implication for wire-or-explain:
B2 should classify producer artifacts into a subject plus predicate, then attach
consumer lineage evidence.
Implication for wire-or-explain:
B3 should require consumer evidence that is independent of producer self-claims.
Implication for wire-or-explain:
B6 is the key divergence from standards. Standards document facts; the tick gate
must decide whether unresolved facts allow green close.
## 5. Query Bundle 2: Agentic Observability Prior Art
Query bundle:
agent observability, tool telemetry, closed-loop enforcement, multi-agent state.
Finding 2.1:
Anthropic distinguishes workflows from agents and treats orchestrator-worker and
evaluator-optimizer patterns as first-class production patterns. [S08]
Finding 2.2:
Anthropic emphasizes that tools need precise schemas and deserve the same design
attention as prompts. [S08] [S10]
Finding 2.3:
Anthropic's multi-agent research writeup emphasizes that stateful agents compound
errors and need checkpointing/resume rather than restart-from-zero. [S09]
Finding 2.4:
The GAAT paper is highly convergent with this plan because it argues that
multi-agent telemetry should feed a closed-loop enforcement path, not remain
downstream analytics. [S04]
Finding 2.5:
AgentGuard and adjacent agent-evaluation work show that tool orchestration has
distinct failure modes from ordinary model response quality. [S05]
Finding 2.6:
OpenTelemetry provides the dominant general observability model: traces, spans,
metrics, logs, context propagation, and causal relationships across boundaries.
[S15]
Finding 2.7:
The external observability corpus supports B5 status integration but warns that
status alone is insufficient.
Implication for wire-or-explain:
B5 must surface unresolved artifacts in status, but B6 must act on them.
Implication for wire-or-explain:
B6 should be named and documented as an enforcement handler, not a dashboard.
Implication for wire-or-explain:
B9 fault injection should include agent-tool failures, stale consumer evidence,
and false-success closeout receipts.
## 6. Query Bundle 3: Industry Standards To Compose With
Query bundle:
SLSA, in-toto, OpenTelemetry, OpenLineage, Airflow, Temporal, Sigstore/Rekor,
GitHub Artifact Attestations.
Finding 3.1:
SLSA v1.2 defines levels, tracks, and recommended attestation formats including
provenance. [S11]
Finding 3.2:
in-toto decomposes attestation into Statement, subject, predicate, envelope, and
bundle layers. [S12]
Finding 3.3:
Rekor provides an immutable transparency log for signed supply-chain metadata
and supports inclusion proof and integrity verification. [S13]
Finding 3.4:
GitHub Artifact Attestations operationalize Sigstore and write public repo
attestations into an immutable transparency log. [S14]
Finding 3.5:
OpenTelemetry gives the runtime evidence language for span identity, trace
context, propagated attributes, metrics, and logs. [S15]
Finding 3.6:
OpenLineage gives the lineage language for run events, jobs, datasets, inputs,
outputs, facets, namespaces, and versioned schema URLs. [S16]
Finding 3.7:
Airflow's OpenLineage provider shows that workflow systems can emit lineage
without rewriting every DAG. [S17]
Finding 3.8:
Temporal provides durable execution language: stateful workflows should resume
from recorded state after failure. [S18]
Composition recommendation:
Use in-toto/SLSA for static artifact evidence shape.
Composition recommendation:
Use OpenLineage for producer-consumer relationship vocabulary.
Composition recommendation:
Use OpenTelemetry for runtime flow, status, and trace identifiers.
Composition recommendation:
Use Temporal's durable execution framing for tick handler replay, idempotency,
and checkpoint semantics.
Composition recommendation:
Use Rekor/GitHub Artifact Attestation as the mental model for append-only
evidence and inclusion verification, but do not require real signing in Phase 4.
## 7. Query Bundle 4: Failure Mode Prior Art
Query bundle:
workflow anomaly detection, supply-chain attack models, agent tool failures,
observability without enforcement, provenance drift.
Finding 4.1:
The supply-chain literature splits security design into transparency, validity,
and separation. [S06]
Finding 4.2:
That maps cleanly to wire-or-explain:
transparency = ledger rows exist,
validity = rows prove the claimed consumer path,
separation = producer and consumer evidence are not the same self-claim.
Finding 4.3:
Workflow anomaly detection is a relevant analogy for B9, but it is not the same
as the tick-close gate. [S07]
Finding 4.4:
OpenTelemetry can describe traces and events, but by itself it does not decide
whether a tick should close green. [S15]
Finding 4.5:
OpenLineage can describe job and dataset relationships, but by itself it does
not decide whether an orchestrator may close a work tick. [S16]
Finding 4.6:
SLSA and in-toto can prove artifact provenance, but by themselves they do not
prove a runtime consumer actually adopted the artifact. [S11] [S12]
Finding 4.7:
The closest external match to the plan's enforcement posture is GAAT, which
explicitly moves agent telemetry into closed-loop enforcement. [S04]
Failure-mode implication:
FM1 false positive wired status needs independent consumer evidence.
Failure-mode implication:
FM2 false negative unwired status needs not_required and bounded defer states.
Failure-mode implication:
FM3 stale consumer evidence needs row supersession and revalidation timestamps.
Failure-mode implication:
FM4 bootstrap recursion needs a named bootstrap seed state.
Failure-mode implication:
FM5 cross-repo artifacts need trust-domain fields.
Failure-mode implication:
FM6 gate latency needs ranker and status p95 checks.
Failure-mode implication:
FM7 override abuse needs append-only bypass rows and expiry.
## 8. Convergence
Convergence C01:
Append-only evidence is strongly supported. [S01] [S13] [S14]
Convergence C02:
Artifact subject plus metadata predicate is strongly supported. [S11] [S12]
Convergence C03:
Cryptographic digests or immutable identifiers should be first-class fields.
[S12] [S13] [S14]
Convergence C04:
Consumer relationships should be represented as lineage, not prose. [S16] [S17]
Convergence C05:
Runtime flow should carry trace/run/span identifiers, not only file paths. [S15]
Convergence C06:
Workflow systems benefit from durable event history and resumability. [S09] [S18]
Convergence C07:
Agent systems need explicit orchestration patterns and evaluation loops. [S08]
Convergence C08:
Telemetry-only systems are insufficient when governance requires enforcement.
[S04]
Convergence C09:
Failure analysis should distinguish visibility, validity, and separation. [S06]
Convergence C10:
Lineage schemas should be versioned and use canonical schema URLs or equivalents.
[S16]
Convergence C11:
Rollout should preserve shadow/warn/enforce stages because enforcement systems
need calibration before hard failure.
## 9. Divergence
Divergence D01:
The exact terms `wired_into` and `deferred_until` are not standard vocabulary.
Divergence D02:
SLSA and in-toto focus on software supply-chain artifacts, not operational tick
closeout flow. [S11] [S12]
Divergence D03:
OpenTelemetry focuses on observation and propagation, not closeout permit
decisions. [S15]
Divergence D04:
OpenLineage focuses on data lineage and workflow metadata, not orchestration
doctrine closeout. [S16]
Divergence D05:
Temporal durable execution focuses on reliable workflow execution, not
unresolved shipped-artifact backlog. [S18]
Divergence D06:
Agent telemetry research converges on enforcement direction, but not on this
repo-local bead-driven B1-B15 decomposition. [S04] [S05]
## 10. Vocabulary Recommendations
Recommendation V01:
Keep the plan and operator-facing name `wire-or-explain`.
Reason:
The phrase names the operational behavior clearly and matches the local failure
mode better than generic "lineage".
Recommendation V02:
Keep `wired_into` as a human-readable field, but add canonical aliases:
`consumer_ref`, `consumer_class`, and `lineage_consumer`.
Reason:
OpenLineage and Airflow make "consumer lineage" the more portable vocabulary.
[S16] [S17]
Recommendation V03:
Keep `deferred_until`, but require `defer_reason`, `defer_owner`, and
`defer_recheck_command`.
Reason:
The plan needs bounded explanation, not indefinite exception.
Recommendation V04:
Add in-toto-shaped names to B1:
`subject`, `predicate_type`, `predicate`, `materials`, and `evidence_digest`.
Reason:
These make the ledger recognizable to SLSA/in-toto readers without turning
Phase 4 into a signing project. [S11] [S12]
Recommendation V05:
Use `event_history` or `tick_event_history` for the sequence that proves the
close handler read, classified, acted, logged, and slept.
Reason:
Temporal's durable execution language is the best external analogy. [S18]
Recommendation V06:
Use `trace_id` and `span_id` only when there is real runtime flow evidence.
Reason:
OpenTelemetry terms should not be borrowed as decoration. [S15]
Vocabulary rename suggestions count:
4 schema-level alias additions, not hard renames.
## 11. Risk Map
Risk R01:
Provenance without enforcement.
External analogue:
OpenTelemetry and OpenLineage can record facts without making a closeout
decision. [S15] [S16]
Plan response:
B6 must be load-bearing. B5 status is secondary.
Risk R02:
Subject/predicate mismatch.
External analogue:
in-toto and SLSA rely on correct subject and predicate binding. [S11] [S12]
Plan response:
B1 schema tests must reject rows whose subject digest does not match the
artifact path or output hash.
Risk R03:
Producer self-attestation passes as wiring proof.
External analogue:
The SoK separation property warns against collapsing authority and evidence.
[S06]
Plan response:
B3 must require consumer-side evidence or a bounded explanation.
Risk R04:
Stale consumer evidence.
External analogue:
Lineage and trace systems can preserve old facts that no longer reflect current
runtime behavior. [S15] [S16]
Plan response:
B3 and B5 need `validated_at`, `last_seen_at`, and `supersedes_row_id`.
Risk R05:
Gate latency becomes the new bottleneck.
External analogue:
Large provenance and trace datasets require ranking and query efficiency. [S03]
Plan response:
B4 ranker and B5 status must include p95 runtime and top-N unresolved output.
Risk R06:
Bootstrap recursion.
External analogue:
Trust systems need a trust root or bootstrap seed; otherwise validation recurses
forever. [S12] [S13]
Plan response:
B1 should encode `bootstrap_seed=true` only for the initial ledger row and B9
should test misuse.
Risk R07:
Cross-repo trust boundary is underspecified.
External analogue:
SLSA, in-toto, and Sigstore distinguish artifact identity, signer, and trust
domain. [S11] [S12] [S13]
Plan response:
B12 should add `source_repo`, `target_repo`, `actor_identity`, `session`, and
`trust_domain`.
Risk R08:
Shadow mode trains operators to ignore warnings.
External analogue:
Telemetry-only governance is explicitly called out as insufficient by GAAT.
[S04]
Plan response:
B7 should require a date-bound shadow period and an explicit enforce switch.
Risk R09:
False-negative not_required absorbs real work.
External analogue:
Attestation systems can encode claims, but policy must define valid claims.
[S12]
Plan response:
B2 and B6 need a narrow whitelist for `not_required` classes.
Risk R10:
Side-branch artifacts disappear.
External analogue:
Artifact attestations bind evidence to a concrete artifact and integrity proof.
[S14]
Plan response:
B13 should require branch ref, commit, artifact path, and evidence digest.
## 12. Greenfield Confirmation
Rediscovered pattern G01:
Append-only provenance ledger.
External match:
Workflow provenance ledgers, Rekor, GitHub Artifact Attestations. [S01] [S13]
[S14]
Rediscovered pattern G02:
Subject/predicate attestation schema.
External match:
SLSA and in-toto. [S11] [S12]
Rediscovered pattern G03:
Consumer lineage vocabulary.
External match:
OpenLineage and Airflow OpenLineage. [S16] [S17]
Rediscovered pattern G04:
Runtime flow and causal context.
External match:
OpenTelemetry. [S15]
Rediscovered pattern G05:
Durable event history and checkpointing.
External match:
Temporal and Anthropic multi-agent research. [S09] [S18]
Greenfield G06:
Tick-close permit gate over unresolved shipped operational artifacts.
Greenfield G07:
List-and-sort unresolved shipped artifacts as the closeout action surface.
Greenfield G08:
`wire-or-explain` as operator-facing doctrine vocabulary.
Greenfield G09:
Cross-orchestrator repo-local unresolved artifact enforcement tied to bead flow.
Greenfield confirmed count:
4.
## 13. Phase 4 B1-B15 Modifications
B1 modification:
Shape the ledger row as a standards-compatible attestation row.
B1 required fields:
`schema_version`, `row_id`, `created_at`, `source_repo`, `source_commit`,
`subject`, `subject_digest`, `predicate_type`, `predicate`, `materials`,
`actor_identity`, `session`, `pane`, `trust_domain`, `prev_hash`, `row_hash`.
B1 acceptance delta:
Schema fixtures include one SLSA/in-toto-shaped row and one OpenLineage-shaped
consumer row.
B1 source support:
[S11] [S12] [S16]
B2 modification:
Classifier emits both local artifact class and portable predicate type.
B2 required predicate types:
`doctrine`, `script`, `status_surface`, `report`, `receipt`, `dispatch`,
`bead_transition`, `runtime_probe`, `bootstrap_seed`.
B2 acceptance delta:
Classifier rejects artifacts that cannot produce a subject digest unless they
are explicitly non-file runtime observations.
B2 source support:
[S11] [S12] [S14]
B3 modification:
Detector must separate producer claim from consumer proof.
B3 consumer proof examples:
status command reads artifact, doctor includes artifact, dispatch template
references artifact, skill or doctrine file imports artifact, runtime probe uses
artifact.
B3 acceptance delta:
Producer self-reference alone leaves state `questionably_wired`, not `wired`.
B3 source support:
[S06] [S16] [S17]
B4 modification:
Ranker should score unresolved rows by blast radius, age, consumer criticality,
trust boundary, and closeout frequency.
B4 acceptance delta:
Top-N output includes rank explanation and estimated gate latency.
B4 source support:
[S03] [S06] [S15]
B5 modification:
Doctor/status integration exposes both observability and action fields.
B5 required fields:
`unwired_artifact_count_24h`, `questionably_wired_count_24h`,
`oldest_unresolved_age_seconds`, `top_unresolved`, `gate_mode`,
`last_close_handler_run_at`.
B5 acceptance delta:
Status cannot print green if B6 would fail in enforce mode.
B5 source support:
[S04] [S15]
B6 modification:
Tick-close handler is the load-bearing enforcement primitive.
B6 handler sequence:
read ledger, classify unresolved rows, list-and-sort, act or require bounded
explanation, append closeout event, return permit or fail.
B6 acceptance delta:
A tick with `unwired_artifact_count_24h > 0` cannot close green unless every
unwired row has `deferred_until`, `not_required`, or `bypassed` with expiry.
B6 source support:
[S04] [S09] [S18]
B7 modification:
Rollout must include off, shadow, warn, enforce, and rollback states.
B7 acceptance delta:
Shadow mode writes rows and status; warn mode blocks green summary text; enforce
mode blocks closeout.
B7 source support:
[S04] [S11] [S13]
B8 modification:
Dogfood import should materialize provenance rows for existing plan artifacts.
B8 acceptance delta:
The import emits subject digests and consumer references, not only file paths.
B8 source support:
[S01] [S12] [S16]
B9 modification:
Fault injection suite must include provenance failures and flow failures.
B9 required cases:
missing subject digest, stale consumer, producer self-proof, broken prev_hash,
expired defer, invalid not_required, cross-repo unknown trust domain, bootstrap
seed misuse, status green while gate fail, side-branch orphan.
B9 source support:
[S06] [S07] [S13]
B10 modification:
L109 doctrine should cite provenance, lineage, attestation, event history, and
closed-loop enforcement as external anchors.
B10 acceptance delta:
L109 names this as a flow gate and forbids treating dashboard visibility as
closure.
B10 source support:
[S04] [S11] [S12] [S15] [S16]
B11 modification:
`wire-status` JSON should be standards-shaped enough to feed future tools.
B11 required output:
summary, gate_mode, unresolved rows, row hashes, subject digests, consumer refs,
defer expiries, bypass rows, source grades, recommended next action.
B11 source support:
[S15] [S16]
B12 modification:
Cross-orchestrator rollout must include trust-domain fields and external
consumer references.
B12 acceptance delta:
Cross-repo row cannot be `wired` unless target repo evidence is observed or a
bounded defer explains why target evidence is not yet available.
B12 source support:
[S11] [S12] [S14] [S16]
B13 modification:
Side-branch artifact convention should produce an attestation row before merge.
B13 acceptance delta:
Branch name alone is not proof. Required proof is branch ref, commit, artifact
path, subject digest, and consumer or defer row.
B13 source support:
[S12] [S14]
B14 modification:
DCG reset blocker must emit a first-class unresolved row when reset output is
created but not consumed.
B14 acceptance delta:
Reset output that is left as a file only cannot close green.
B14 source support:
[S04] [S15] [S18]
B15 modification:
Memory/learn promotion should link this external audit as prior-art evidence.
B15 acceptance delta:
Future doctrine promotion records source IDs S01-S18 or a successor audit hash.
B15 source support:
[S01] [S04] [S11] [S12] [S16]
Phase 4 bead edits count:
15.
## 14. Acceptance-Gate Cross-References
Gate cross-ref A:
B1 schema fixture should cite SLSA and in-toto terms.
Gate cross-ref B:
B2 classifier fixture should include OpenLineage-inspired consumer terms.
Gate cross-ref C:
B3 detector fixture should encode the SoK separation property.
Gate cross-ref D:
B4 ranker fixture should test large-ledger query behavior.
Gate cross-ref E:
B5 status fixture should prove status and enforcement do not diverge.
Gate cross-ref F:
B6 close handler fixture should prove observability alone cannot close green.
Gate cross-ref G:
B7 rollout fixture should record mode transition history.
Gate cross-ref H:
B8 dogfood fixture should import existing plan artifacts into ledger rows.
Gate cross-ref I:
B9 fault fixture should include invalid digest, stale consumer, and expired
defer.
Gate cross-ref J:
B10 doctrine fixture should classify this as a flow gate.
Gate cross-ref K:
B11 status fixture should emit JSON consumable by later observability tools.
Gate cross-ref L:
B12 cross-orch fixture should include trust domain and target repo evidence.
Gate cross-ref M:
B13 side-branch fixture should reject branch-name-only evidence.
Gate cross-ref N:
B14 reset fixture should block file-only output.
Gate cross-ref O:
B15 memory fixture should cite source IDs and audit hash.
## 15. Composite Score
Score component A:
External convergence: 2.2 / 2.5.
Reason:
The standards ecosystem strongly validates the ledger, lineage, attestation,
trace, and durable event-history components.
Score component B:
Greenfield necessity: 1.7 / 2.0.
Reason:
The exact closeout permit primitive is not found externally and is justified by
the local failure mode.
Score component C:
Implementation guidance clarity: 1.7 / 2.0.
Reason:
External terms map cleanly to B1-B15, with no need to add a new Phase 4 gate.
Score component D:
Risk coverage: 1.4 / 1.5.
Reason:
Major risks are known and testable; stale lineage and trust-domain boundaries
need careful fixtures.
Score component E:
Vocabulary fit: 1.3 / 2.0.
Reason:
Local terms are good operator language but need standards aliases to avoid
future translation debt.
Composite:
8.3 / 10.0.
Pass:
yes.
## 16. Final Recommendation
Proceed to Phase 4 DECOMPOSE with B1-B15 intact.
Do not add a new bead.
Modify all 15 beads with the standards-compatible deltas above.
Treat B6 as bead number one in implementation priority.
Keep the plan invariant unchanged:
tick must not complete green while a shipped artifact remains unwired,
unexplained, or unbounded.
Use external standards as schema and vocabulary scaffolding.
Keep the enforcement mechanism local, explicit, and mechanical.
