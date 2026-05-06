# Phase 3 Audit r1: Cross-Cutting Skill Routing

task_id: phase3-audit-cross-cutting-skill-routing-2026-05-06
parent_bead: flywheel-plan-mission-lock-paradigm-extension-2026-05-06
lens: cross-cutting-skill-routing
auditor: CloudyMill
created_at: 2026-05-06T14:34:08Z
scope: plan-space-only
socraticode_queries: 10
indexed_chunks_observed: 965
skill_search_catalog_total: 455
skill_search_filesystem_total: 463
skill_search_drift_count: 8
skill_search_freshness_status: WARN

## 1. Lens Scope

This lens audits whether Finding 4, `dispatch-systematically-under-injects-skills`,
is integrated as a sound routing system rather than as a larger prompt checklist.

Inspected sections:

| Artifact | Line range | Why inspected |
|---|---:|---|
| `02-REFINE-r2.md` | 73-188 | Defines the universal skill floor, five bead-class sets, discovery receipt, and self-test. |
| `02-REFINE-r2.md` | 190-244 | Defines the skillos coordination touchpoint and required ack. |
| `02-REFINE-r3.md` | 72-85 | Resolves route-health, aliases, missing skills, prompt budget, receipts, and ownership. |
| `02-REFINE-r3.md` | 174-180 | Leaves skillos API shape and receipt field names deferred. |
| `02-REFINE-r4.md` | 98-106 | Confirms both deferred questions remain unresolved before Phase 4. |
| `02-REFINE-r4.md` | 136-154 | Declares this audit lens and Phase 3 eligibility. |
| `01-RESEARCH-B-ecosystem-audit.md` | 16-47 | Provides the broader skill catalog coverage map. |
| `01-RESEARCH-B-ecosystem-audit.md` | 173-200 | States the surface-level skill map and gap routing pressure. |
| `03-AUDIT-r1-security.md` | 69-84 | Used only for disagreement and overlap analysis. |

Live catalog checks for this audit:

1. `mcp__skill_search__.catalog_stats_tool`: qdrant and ollama healthy,
   `route_gate_enabled=true`, `freshness_status=WARN`, `freshness_pct=78.0`,
   `drift_count=8`.
2. Exact `get_skill` checks:
   - `canonical-cli-scoping`: found, but `route_allowed=false`, reason
     `no_source`.
   - `find-skills`: found, but `route_allowed=false`, reason `no_source`.
   - `simplify`: not found.
   - `schema-complete-drift-guard`: not found.
3. Local filesystem check: `canonical-cli-scoping`, `de-slopify`,
   `code-simplifier`, and `simplify-and-refactor-code-isomorphically` exist;
   `simplify` and `schema-complete-drift-guard` do not.
4. Shell check: `find-skills` is not a command on this worker PATH; it is a skill
   whose instructions route to `npx skills find`.

## 2. Findings Register

| ID | Severity | Section line range | Description | Mitigation |
|---|---:|---|---|---|
| CSR-001 | high | r2:79-92, r2:125-144, r3:79-85 | The plan classifies bead classes and selects defaults, but does not define a deterministic merge rule when multiple bead-class tags fire. Real beads often touch backend, db, substrate, docs, and security surfaces at once. Without a precedence lattice, dispatch authors can under-inject by choosing one class or over-inject by pasting every class. | Phase 4 bead: implement a skill-routing resolver with ordered inputs, dedupe, strictest-invariant-wins, conflict receipts, prompt-budget pruning, and fixture coverage for multi-class beads. |
| CSR-002 | high | r2:145-165, r3:76, r3:78 | Discovery-source disagreement is still under-specified. The receipt names `skill-search`, `local-skill-roots`, and `socraticode`, but not precedence when they disagree. In this audit, qdrant search failed to rank exact `canonical-cli-scoping` in a top-5 semantic query, exact lookup found it but blocked route health, local filesystem can read it, `find-skills` is a blocked-no-source skill, and no `find-skills` command exists on PATH. | Phase 4 bead: add a discovery precedence contract: exact `get_skill` and local readable `SKILL.md` first, semantic query second, external `npx skills find` only for installable ecosystem discovery, and grep/rg as deterministic filesystem fallback. Receipt must include `source_precedence`, `route_status`, and `disagreement_resolution`. |
| CSR-003 | medium | r2:190-244, r3:174-179, r4:98-103 | The skillos handshake is a dependency, but not yet a reliable protocol. R2 asks for an ack with path, schema version, alias policy, missing-skill policy, example invocation, limitations, and freshness semantics; r3/r4 defer the exact API shape. Missing states include request id, sent/acked/stale/unavailable, TTL, retry, duplicate handling, and degraded mode. | Phase 4 bead: define a `skillos_template_request` and `skillos_template_ack` JSONL schema with schema version, request id, producer version, TTL, idempotency key, and fixtures for missing relay, duplicate relay, stale relay, and skillos unavailable. |
| CSR-004 | medium | r2:145-165, r3:80-83, r4:102-103 | Stale skill references in old dispatches are not fully handled. The plan has catalog stats and receipt semantics, but the selected skill rows do not require `path`, `sha`, `version`, `freshness_status`, `route_allowed`, or `checked_at`. Old packets can keep naming a skill after rename or semantic drift without a validator-visible refresh decision. | Phase 4 close-validator bead: require every `skill_receipts[]` and alias/skip receipt to stamp `skill`, `resolved_to`, `path`, `sha`, `version`, `freshness_status`, `route_allowed`, `checked_at`, and `source`. Revalidate stale or blocked receipts at close. |
| CSR-005 | medium | LaneB:28-31, LaneB:133-142, r2:94-106, r2:125-135 | The universal and bead-class sets omit several cross-cutting operational concerns already present in Lane B or the skill catalog. `agent-mail` is explicitly ADOPT in Lane B, but not a universal or class overlay. Observability, agent monitoring, and cost attribution are routeable skills, but the routing plan does not state when concurrent-agent, telemetry, prompt-budget, or cost-bearing work must pull them. | Phase 4 routing bead: add cross-cutting overlays independent of bead class: coordination overlay (`agent-mail`) for concurrent or shared-surface work, observability overlay (`observability-platform` or `agent-monitoring`) for runtime/loop/health changes, and cost overlay (`cost-attribution`) for token, model, GPU, API, or budget-sensitive work. |
| CSR-006 | low | r2:172-185, r3:81-83 | The dispatch self-test is necessary but still gameable. `named_skill_count >= 3` plus universal/class representation can pass with irrelevant, blocked, or no-source skills if the packet also emits aliases or skip receipts. The plan lacks a negative fixture matrix that proves false positives and false negatives are caught. | Phase 4 fixture bead: replace the count heuristic with a coverage matrix over real bead samples. Gate on required overlays, class relevance, route health, exact or alias evidence, and negative examples where three named skills must still fail. |

findings_count: 6
critical: 0
high: 2
medium: 3
low: 1

## 3. Skill-Routing Collisions

Observed collision classes:

| Collision | Example bead shape | Ambiguity | Required resolution |
|---|---|---|---|
| Backend plus database | Adds an API endpoint and changes a table/index. | `backend-endpoint` and `db-migration` both fire. Auth/request skills and migration/schema skills are both required; prompt budget may prune the wrong set. | Merge both classes; strictest data and auth invariants win; primary excerpts go to the riskiest surface. |
| Substrate plus security plus CLI | Repairs Infisical/Railway/Vercel helper or dispatch command. | `substrate-fix`, security skills, and universal `canonical-cli-scoping` overlap. Secret hygiene, CLI scoping, and ops recovery constraints can disagree on evidence shape. | Require security negative invariant overlay plus CLI receipt; forbid raw secret evidence per security lens. |
| Docs/operator contract plus implementation | Changes README, doctrine, command help, or plan artifact while editing scripts. | Universal `readme-writing`, `de-slopify`, `canonical-cli-scoping`, and `simplify` all fire, but no rule chooses which are applied versus skipped. | Make durable docs/operator contract an overlay with explicit skip receipts for non-public or scratch-only text. |
| Missing exact skill plus fallback suite | `db-migration` selects `schema-complete-drift-guard`, which does not exist. | R3 allows fallback to safe migration/data quality skills, but does not say whether repeated selection blocks, warns, or creates a candidate when skillos is unavailable. | Same-tick skillos candidate with dedupe; allow fallback only with `missing_skill_followup` and `degraded_mode_reason`. |

skill_routing_collisions_count: 4

## 4. Cross-Cutting Concerns Missed

Missed or under-modeled concerns:

1. `agent-mail` coordination. Lane B explicitly adopts it for identity,
   callbacks, and file reservations, but r2/r3 do not make it a universal or
   overlay route for shared files, parallel lenses, append-only JSONL, or callback
   coordination.
2. Observability and agent monitoring. Routing health, skillos relay health,
   stale catalog freshness, and close-validator reject rates need metrics or
   doctor visibility; no overlay selects `observability-platform` or
   `agent-monitoring`.
3. Cost attribution. R3 defines a prompt-budget cap, but not token/cost metering
   for large skill injection, repeated skill reads, or model/tool routing costs.
4. Search-tool routing. The plan names skill-search, local roots, and Socraticode,
   but does not encode the exact-symbol versus semantic-search decision tree from
   `search-tool-routing-doctrine`.

cross_cutting_concerns_missed_count: 4

## 5. Cross-Orch Handshake Gaps

Skillos is correctly assigned producer ownership for reusable taxonomy, aliases,
and templates. The gap is protocol completeness, not ownership.

Required but absent before Phase 4 implementation:

1. `request_id`, `idempotency_key`, `created_at`, `expires_at`, and
   `schema_version` for every flywheel -> skillos template request.
2. Acknowledgement states: `pending`, `sent`, `acked`, `rejected`, `stale`,
   `duplicate`, `producer_unavailable`, and `degraded_fallback_used`.
3. A source artifact contract: template path or API, producer commit/hash,
   taxonomy version, alias registry version, and known limitations.
4. Retry and timeout policy: when flywheel may proceed with local fallback, when it
   must wait, and when it must create a follow-up bead instead of blocking Phase 4.
5. Consumer trust boundary: flywheel consumes schema, aliases, and route metadata;
   it must not let skillos mutate dispatch packets or close-validator policy
   directly.

## 6. Single-Points-Of-Failure In Routing

| Single point | Failure mode | Current fallback | Gap |
|---|---|---|---|
| `skill-search-mcp` qdrant projection | Healthy today but stale or missing exact-route ranking. | Local `SKILL.md` fallback exists for one named case. | Needs general exact lookup/local precedence and stale projection warning. |
| Local skill filesystem | Skill exists locally but has no source freshness, or exact token is missing. | R3 allows aliases/fallbacks for two known tokens. | Needs generic alias/missing-skill policy and old-dispatch revalidation. |
| `find-skills` ecosystem surface | Skill exists but is blocked-no-source; command absent from PATH. | None in plan. | Treat as external install discovery only, not local routing truth. |
| Skillos template producer | Producer unavailable, stale, or duplicate relay. | R2 says coordinate before final amendment. | Needs ack ledger and degraded-mode rules. |
| Dispatch self-test | Count heuristic passes irrelevant or blocked skills. | Close receipts later catch some gaps. | Needs negative fixture matrix before code-space wiring. |

## 7. Mitigations Recommended

Phase 4 should decompose these into implementation beads:

1. `skill-routing-resolver`: deterministic class detection, multi-class merge,
   conflict receipts, prompt-budget pruning, and real-bead fixture matrix.
2. `skill-discovery-precedence-receipt`: exact lookup/local `SKILL.md` precedence,
   semantic search fallback, external `find-skills` role, route-health fields, and
   disagreement receipts.
3. `skillos-template-handshake`: request/ack JSONL schema, TTL, idempotency,
   dedupe, producer version, unavailable/stale/duplicate fixtures, and degraded
   fallback rules.
4. `skill-receipt-version-stamps`: `path`, `sha`, `version`,
   `freshness_status`, `route_allowed`, `checked_at`, and `source` in every
   selected/alias/skip receipt.
5. `cross-cutting-overlays`: agent-mail, observability/monitoring, cost
   attribution, and search-tool-routing overlays triggered independently of bead
   class.
6. `dispatch-self-test-negative-fixtures`: false-positive and false-negative tests
   proving three named skills are not enough unless coverage is relevant and
   routeable.

No r5 refine round is required for these. The plan already has the correct
producer/consumer split; the mitigations are Phase 4 implementation edges.

## 8. Audit Verdict

audit_disposition: auto_advance
critical_findings: 0
high_findings: 2
phase3_cross_cutting_lens_green_light: true

This lens finds no critical blocker. The major risks are mechanical: resolver
ambiguity and discovery-source disagreement. Both can be mitigated in Phase 4
without reopening the Phase 2 architecture because r3/r4 already assign
ownership: flywheel owns dispatch enforcement, skillos owns reusable taxonomy,
and close-validator owns proof.

## 9. Disagreement-With-Other-Lenses Note

Security lens overlap:

The security lens correctly raises packet-level secret hygiene and skillos trust
boundaries. This lens agrees, but treats those as overlays inside the routing
resolver rather than as a separate fourth gate. The same skill can be selected by
class routing while the security overlay decides what evidence is forbidden.

Idempotency/receipt lens prediction:

This lens expects the idempotency-receipt lens to focus on append-only JSONL,
latest-row selection, duplicate closure, stale relay, and validator field names.
The cross-cutting disagreement is only emphasis: this lens does not need the
final field names to judge the plan, but Phase 4 must include enough version and
freshness stamps for the close-validator to reject stale skill evidence.

Other-lens convergence:

If Lens 2 also finds zero critical issues, the three lenses can converge to
Phase 4. The Phase 4 DAG should carry mitigation beads, not a new refine loop,
unless Lens 2 discovers a critical append-only or close-validator contradiction.
