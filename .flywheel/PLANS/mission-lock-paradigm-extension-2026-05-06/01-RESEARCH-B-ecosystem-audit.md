# Research B - Ecosystem Audit

Plan arc: `mission-lock-paradigm-extension-2026-05-06`
Task: `plan-mission-lock-paradigm-extension-phase1-lane-b-2026-05-06`
Bead: `flywheel-plan-mission-lock-paradigm-extension-lane-b-2026-05-06`
Status: closed
Scope: plan-space-only

Lane A prerequisite: `00-INTENT.md` and `01-RESEARCH-A-problem-space-inventory.md`
are present and define the upstream trauma class: mission-lock currently declares
readiness without proving lock-time operational completeness. This lane audits
the ecosystem already available before Lane C designs extensions.

Socraticode pre-flight: 10 queries, 945 indexed chunks observed.

## 1. Skill Catalog Audit

Catalog probes covered `mission`, `scaffold`, `lock`, `init`, `audit`,
`e2e-no-mocks`, `saas-*`, `design-system`, `tokens`, and `primitives`.
Selected SKILL.md files were read for the mission-lock-relevant surfaces.

| Skill | Class | Current leverage | Rationale |
|---|---:|---|---|
| `mission-anchor-init` | ADOPT | Mission/GOAL/STATE gate and pivot history | Already defines mission anchoring and validation ritual; mission-lock should reuse this as the lower layer instead of inventing a second lock primitive. |
| `testing-real-service-e2e-no-mocks` | ADOPT | Real-service truth rule | Direct substrate for the alps "real or nothing" failure; lock-time must ask whether tests and runtime paths use reality or curated lies. |
| `security-audit-for-saas` | ADOPT | Security invariant extraction | Gives lock-time language for fail-open paths, identity, entitlements, and boundary validation. |
| `security-posture` | ADOPT | Probe-first security ladder | Covers secrets, credential hygiene, port exposure, and MCP/tool attack surface; useful for the vendor/secrets true-blocker class. |
| `canonical-cli-scoping` | ADOPT | CLI surface checklist | Mission-lock extensions and validators need `doctor`, `schema`, `json`, `dry-run`, `examples`, and `why` surfaces from the start. |
| `beads-workflow` | ADOPT | Plan-to-bead decomposition | Lock-time gaps should become beads immediately instead of being discovered during feature build. |
| `agent-mail` | ADOPT | Identity, callback, and file reservations | Provides coordination substrate for lock-time evidence and concurrent implementation ownership. |
| `saas-scaffolder` | EXTEND | SaaS skeleton and component baseline | Useful for app substrate, but generic; needs lock-time substrate checklist for design system, primitives, auth, data, and CI gates. |
| `demo-foundation` | EXTEND | Production-correct demos | Good anti-demo-only-code doctrine; mission-lock must attach it to real data and demoability decisions before build dispatch. |
| `react-best-practices` | EXTEND | Frontend performance and structure | Strong post-stack guidance, but not a complete lock-time design-system inventory. |
| `web-visual-qa` | EXTEND | Screenshot and visual verification loop | Needs mission-lock integration so expected viewports, density caps, and screenshot gates are known before implementation. |
| `e2e-testing-for-webapps` | EXTEND | Playwright and Supabase E2E methodology | Useful executor layer; mission-lock must decide test users, live URLs, auth bypass, and failure injection upfront. |
| `saas-cli-auth-flow` | EXTEND | CLI/web identity flows | Covers PKCE/device-code invariants; mission-lock should pull it when a project has CLI, remote, or headless auth. |
| `audit-preparation` | EXTEND | Evidence-backed audit readiness | Strong evidence discipline, but should be narrowed into lock-time readiness questions and receipt shape. |
| `ui-polish` | AVOID | Post-baseline polish only | Its own guidance says not to use it to start from scratch or when no basic design system exists; mission-lock should not treat polish as scaffold substrate. |

Adjacent command substrate:

| Surface | Class | Rationale |
|---|---:|---|
| `/flywheel:mission-lock` | EXTEND | Existing 14-section lock command is the target surface; keep its senior-dev-stack capture but add completeness audit gates. |
| `.flywheel/scripts/mission-anchor-dispatch-license.sh` | EXTEND | Existing dispatch-license schema/info/examples surface can be widened to include the six gap classes. |

Skill count: 15 audited. Classification count: 7 ADOPT, 7 EXTEND, 1 AVOID.

## 2. AGENTS-CANONICAL L-Rule Audit

`.flywheel/AGENTS-CANONICAL.md` is rich in process doctrine. Its current gap is
domain-level lock completeness: data lifecycle, negative invariants, scaffold
artifact lists, and trap-class cross-refs are implied by process rules but not
yet named as mission-lock requirements.

| L-rule | Current scope | Class | Rationale |
|---|---|---:|---|
| L50 - Socraticode-mandatory in every dispatch | Survey existing substrate before writing | ADOPT | Mission-lock must keep K>=10 survey evidence for new project and relock arcs. |
| L51 - Dispatch file reservations mandatory | Reserve files before edits | ADOPT | Lock-time implementation beads need ownership before workers mutate shared surfaces. |
| L52 - Issues to beads or explicit no-bead receipt | Findings become tracked work | ADOPT | Missing substrate found during mission-lock should become beads or explicit no-bead receipts. |
| L55 - Missing-skill escalation routes to skillos | Skill gaps become skillos candidates | EXTEND | Mission-lock should emit skill-gap candidates when no skill covers a required surface. |
| L56 - Fuckup-log -> INCIDENTS -> L-rule ladder | Doctrine promotion ladder | ADOPT | Cross-orch rows 151 and 152 already justify durable doctrine promotion. |
| L71 - Validate and redispatch discipline | Claims require mechanical validation | ADOPT | A mission lock is a claim; validator evidence must precede build dispatch. |
| L82 - Canonical CLI scoping mandatory | CLIs need doctor/schema/json/dry-run | ADOPT | Any new validator or lock doctor must expose the canonical CLI surface. |
| L83 - File length discipline fleet-wide | Size/density maintainability | EXTEND | Useful as a document/code density analogy; not enough for product UI density caps. |
| L84 - Locked worker identities canonical | Durable session/pane/project identities | ADOPT | Identity is a lock-time substrate when agents, callbacks, or ownership matter. |
| L88 - Publishability bar canonical | Seven-facet publishability gate | ADOPT | Lock-time must ask how publishability and demoability will be proven, not only built. |
| L89 - ZestStream voice public repo canonical | Public surface voice and tone | EXTEND | Relevant for external-facing projects; optional for internal-only lock arcs. |
| L91 - Dispatch delivery four-state receipt | Delivery is not work started | ADOPT | Lock-time readiness should distinguish generated docs from validated operational start. |
| L96 - Doctrine lands as 3-surface diff | Root/canonical/template propagation | EXTEND | Lane C changes must land in command, template, and doctrine surfaces together. |
| L100 - Identity primary key is session/pane/project | Stable tuple identity | ADOPT | Prevents mission-lock evidence from being attached to display names only. |
| L101 - Flywheel owns continuous fleet productivity | No idle unless true Josh blocker | EXTEND | True-blocker taxonomy belongs in mission-lock so projects do not punt early. |
| L111 - Real-time quality bar on every work body | Five-skill and three-judge bar | ADOPT | Lane B and Lane C artifacts must self-grade against current quality bar before close. |

L-rule count: 16 referenced.

## 3. Memory Rule Audit

Primary path: `~/.claude/projects/-Users-josh-Developer-flywheel/memory/`.
One cross-project memory was included because row 152 and Lane A explicitly name
the alps "real or nothing" correction as the data-lifecycle trap.

| Memory rule | Source | Class | Rationale |
|---|---|---:|---|
| `project_mission_lock_skill_2026_05_03.md` | flywheel | EXTEND | Documents the 14-section mission-lock skill; Lane C extends this rather than replacing it. |
| `feedback_skills_library_load_bearing.md` | flywheel | ADOPT | Skills -> Socraticode -> research triad is the right lock-time discovery order. |
| `feedback_data_decides_not_human_meatpuppet.md` | flywheel | ADOPT | Mission-lock should answer by data, methods, and doctrine before asking Joshua. |
| `feedback_publishability_bar_three_judges.md` | flywheel | ADOPT | Lock-time readiness should include publishability, not only internal correctness. |
| `project_self_sustaining_company_paradigm_2026_05_04.md` | flywheel | EXTEND | Good target state for identity/work/impact visibility; needs mission-lock application. |
| `feedback_three_audit_questions_per_surface.md` | flywheel | ADOPT | Every surface needs validation, documentation, and finding surfacing. |
| `feedback_four_lens_bar_fleet_wide.md` | flywheel | ADOPT | Useful for close quality; mission-lock needs surface-specific lenses. |
| `feedback_orchestrator_validates_callbacks.md` | flywheel | ADOPT | A DONE callback is not a lock; validation must be independent. |
| `feedback_worker_verify_callback_delivered.md` | flywheel | ADOPT | Transport receipts matter for lock-time orchestration handoff. |
| `feedback_flywheel_owns_continuous_productivity_no_downtime_unless_josh_blocker.md` | flywheel | EXTEND | True-blocker definition should be embedded in mission-lock readiness. |
| `feedback-real-or-nothing-no-fallback-data.md` | alpsinsurance | ADOPT | Runtime data analog of no-mocks: if data did not come from the real API, it is forbidden as fallback. |

Memory count: 11 referenced.

## 4. INCIDENTS.md Doctrine Audit

| Incident / doctrine entry | Source | Class | Rationale |
|---|---|---:|---|
| `mission-lock-drift-no-audit-trail` | `flywheel/INCIDENTS.md` | ADOPT | Locked mission writes already require lock-log audit evidence; extend from hash evidence to completeness evidence. |
| `two-truth-sources-before-decide` | `flywheel/INCIDENTS.md` | ADOPT | Lock-time readiness should require two live truth sources for mission-critical claims. |
| `publishability-bar-three-judges-close-gate` | `flywheel/INCIDENTS.md` | ADOPT | Close gates and lock gates should share the same three-judge publishability posture. |
| `orch-trust-trap-agentmail-as-completion-signal` | `flywheel/INCIDENTS.md` | EXTEND | Callback trust trap generalizes to lock-time: generated artifacts are not evidence by themselves. |
| `Plan-arc Phase 5 r1 polish: orch-heartbeat event-driven reconvergence` | `flywheel/INCIDENTS.md` | EXTEND | Shows cross-orch findings can invert a plan paradigm; Lane B reuses that ingestion pattern. |
| `phase3-polish-gate-fleet-broadcast` | `flywheel/INCIDENTS.md` | EXTEND | Mission-lock doctrine changes need fleet propagation, not only local docs. |
| `Mission anchor drift incident` | `mobile-eats/.flywheel/INCIDENTS.md` | ADOPT | First-turn MISSION read and unfilled MISSION halt are lock-time prerequisites. |
| `Mission anchor drift incident` | `alpsinsurance/.flywheel/INCIDENTS.md` | ADOPT | Same incident class independently appears in another repo, confirming cross-repo generality. |

Incident count: 8 referenced.

## 5. Cross-Orch Finding Ingestion

Rows 151 and 152 are absorbed in Lane A and remain live inputs for Lane B.

| Row | Source | Trauma class | Absorption status |
|---:|---|---|---|
| 151 | `mobile-eats:1` | `mission-lock-undersells-design-system-substrate` | Absorbed in `00-INTENT.md`; mapped here to scaffold/design-system substrate and publishability coverage. |
| 152 | `alps:1` | `mission-lock-must-elicit-negative-invariants` | Absorbed in `00-INTENT.md`; mapped here to data lifecycle, negative invariants, trap-class cross-refs, and skill-by-surface coverage. |

Similar prior rows: the `orch-trust-trap-agentmail-as-completion-signal` row
and the `orch-bash-prompt-state-change-trigger` row both reinforce the same
pattern: a visible artifact or callback is not enough; the system needs live
evidence that the underlying work state changed.

`STATE.json` records `cross_orch_findings_absorbed: [151, 152]`; Lane B keeps
that lineage and adds the ecosystem coverage map for Lane C.

## 6. Audit Synthesis

### Table A - Skill Substrate

| Substrate cluster | Items | Class | Rationale |
|---|---|---:|---|
| Mission anchor and lock | `mission-anchor-init`, `/flywheel:mission-lock` | EXTEND | Adopt the anchor layer; extend the lock command with completeness receipts. |
| Reality and data truth | `testing-real-service-e2e-no-mocks`, `e2e-testing-for-webapps`, alps real-or-nothing memory | ADOPT | Directly covers no-mocks/no-fallback and live E2E requirements. |
| SaaS scaffold and frontend | `saas-scaffolder`, `demo-foundation`, `react-best-practices`, `web-visual-qa` | EXTEND | Strong execution substrate; missing lock-time artifact inventory and density decisions. |
| Security and identity | `security-audit-for-saas`, `security-posture`, `saas-cli-auth-flow` | EXTEND | Adopt invariant extraction and probes; extend mission-lock trigger logic by surface. |
| Operations substrate | `canonical-cli-scoping`, `beads-workflow`, `agent-mail`, `audit-preparation` | ADOPT | Existing process substrate is mature enough to reuse directly. |
| Polish-first usage | `ui-polish` | AVOID | Do not start a project from a polish skill when scaffold substrate is missing. |

### Table B - L-Rule Substrate

| Substrate cluster | L-rules | Class | Rationale |
|---|---|---:|---|
| Evidence before action | L50, L71, L91, L111 | ADOPT | Mission-lock must be validated evidence, not text generation. |
| Finding routing | L52, L55, L56 | ADOPT | Gaps discovered at lock-time already have bead, skillos, and doctrine routes. |
| Operational surfaces | L51, L82, L84, L100 | ADOPT | Ownership, CLI, and identity requirements are already enforceable. |
| Publication and drift | L88, L89, L96 | EXTEND | Need mission-lock-specific propagation and public-surface decisions. |
| Density and productivity | L83, L101 | EXTEND | Useful primitives, but not yet a project-specific UI/data density contract. |

### Table C - Memory Substrate

| Substrate cluster | Memory rules | Class | Rationale |
|---|---|---:|---|
| Skill-first discovery | `feedback_skills_library_load_bearing`, `project_mission_lock_skill_2026_05_03` | EXTEND | Current command has base shape; discovery order is ready to adopt. |
| Reality and decision discipline | `feedback_data_decides_not_human_meatpuppet`, alps `feedback-real-or-nothing-no-fallback-data` | ADOPT | Directly answers data lifecycle and negative fallback questions. |
| Quality and audit | `feedback_publishability_bar_three_judges`, `feedback_three_audit_questions_per_surface`, `feedback_four_lens_bar_fleet_wide` | ADOPT | Good lock-time quality envelope. |
| Callback and delivery proof | `feedback_orchestrator_validates_callbacks`, `feedback_worker_verify_callback_delivered` | ADOPT | Prevents lock artifacts from being mistaken for completed operational proof. |
| Company autonomy | `project_self_sustaining_company_paradigm_2026_05_04`, `feedback_flywheel_owns_continuous_productivity_no_downtime_unless_josh_blocker` | EXTEND | True-blocker and founder-bottleneck language should be pulled into mission-lock. |

### Table D - INCIDENTS Substrate

| Substrate cluster | Incidents | Class | Rationale |
|---|---|---:|---|
| Lock audit trail | `mission-lock-drift-no-audit-trail` | ADOPT | Existing lock-log rule is the nearest hard substrate. |
| Evidence gates | `two-truth-sources-before-decide`, `publishability-bar-three-judges-close-gate`, `orch-trust-trap-agentmail-as-completion-signal` | ADOPT | These prevent artifact-only readiness claims. |
| Cross-orch ingestion | orch-heartbeat event-driven reconvergence, phase3 polish-gate broadcast | EXTEND | Pattern exists; mission-lock needs a dedicated cross-orch intake rule. |
| Mission anchor drift | mobile-eats and alps `.flywheel/INCIDENTS.md` entries | ADOPT | Independent repos prove first-turn mission anchor enforcement is universal. |

## 7. Coverage Matrix

| Gap class | Skill substrate | L-rule substrate | Memory substrate | INCIDENTS substrate | Lane C design pressure |
|---|---|---|---|---|---|
| `data-lifecycle` | `testing-real-service-e2e-no-mocks`, `e2e-testing-for-webapps`, `demo-foundation` define real data and demo boundaries. | L50, L71, L91 require evidence before dispatch/work-start claims. | Alps real-or-nothing rule names curated fallback, stale defaults, and placeholder data as forbidden. | Two-truth-sources and mission-lock drift incidents demand live evidence, not doc assertions. | Add lock-time data lifecycle questions: source, freshness, empty/error state, deletion/archive, and fallback prohibition. |
| `negative-invariants` | `security-audit-for-saas`, `security-posture`, and no-mocks provide invariant extraction patterns. | L52 and L56 route discovered forbidden states to beads/doctrine. | Data-decides and real-or-nothing memories give the strongest "must not" language. | Row 152 plus publishability incidents prove missing negative invariants cost hours. | Add required "must never happen" section per surface, with owner and validator. |
| `trap-class-cross-refs` | `testing-real-service-e2e-no-mocks` pairs with real-or-nothing; `ui-polish` warns against pre-scaffold usage. | L55 provides missing-skill escalation; L96 provides propagation if a trap becomes doctrine. | Skill-library-load-bearing and four-lens memories say adjacent rules must be consulted. | Orch-trust and event-driven incidents show sibling traps recur when not cross-linked. | Add a cross-ref table mapping each selected skill to known trap siblings and forbidden substitutes. |
| `skill-arsenal-by-surface` | 15 audited skills cover mission, data, scaffold, auth, security, E2E, visual QA, audit, and ops. | L50 makes skill/Socraticode survey mandatory; L55 covers missing skill classes. | Skills-library-load-bearing is direct doctrine for this gap. | Mission anchor drift incidents show project starts fail when existing substrate is skipped. | Add mission-lock output section listing selected skills per product surface with ADOPT/EXTEND/AVOID. |
| `substrate-artifacts` | `saas-scaffolder`, `demo-foundation`, `react-best-practices`, and `web-visual-qa` provide partial artifact lists. | L82, L84, L88, L100 provide CLI, identity, publishability, and ownership substrate. | Self-sustaining-company and three-audit-questions memories define visibility and audit needs. | Row 151 and mission-lock drift incident are the key evidence that docs alone are insufficient. | Add a scaffold validator inventory: tokens, primitives, auth, data, CI gates, identity, SEO, density, and demo surfaces. |
| `failure-mode-audit` | `audit-preparation`, `security-posture`, `canonical-cli-scoping`, and `beads-workflow` provide audit and recovery primitives. | L52, L56, L71, L111 define finding capture, doctrine promotion, validation, and quality bar. | Orchestrator-validates-callbacks and worker-verify-callback-delivered memories cover false completion modes. | Two-truth, orch-trust, and publishability incidents cover the recurring failure modes. | Add a lock-time failure-mode matrix: false readiness, hidden fallback, missing substrate, unowned identity, and unvalidated demo. |

## Lane B Verdict

Lane B found enough existing substrate to avoid a greenfield redesign. The
system already has strong rules for evidence, skill discovery, issue routing,
identity, CLI shape, publishability, and callback validation. The missing part
is a mission-lock-specific contract that names the six Lane A gap classes and
requires receipts before "ready to build" is declared.

Lane C should therefore design a narrow extension:

1. Extend `/flywheel:mission-lock` with data lifecycle, negative invariants,
   trap-class cross-refs, skill-by-surface, substrate artifacts, and
   failure-mode audit sections.
2. Add a validator/doctor that fails closed when those sections are missing or
   evidence-free.
3. Route every lock-time gap to beads, skillos, or explicit no-bead reason.
4. Land the change across command, template, and doctrine surfaces per L96.
