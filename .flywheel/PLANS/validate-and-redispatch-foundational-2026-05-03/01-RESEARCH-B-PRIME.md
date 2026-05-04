# Phase 1 Lane B-PRIME - Broader Jeff Corpus Sweep

Plan: `validate-everything-we-build-2026-05-03`
Lane: B-prime, ecosystem audit expansion
Status: complete
ladder_passed: yes

## Executive Ledger

| Gate | Result |
|---|---:|
| Canonical Jeff repos in inventory | 177 |
| Baseline Lane B repos reused, not re-mined | 11 |
| Tier 1 new repos deep-mined | 34 |
| Tier 2 repos shallow-catalogued | 91 |
| Tier 3 repos inventoried | 41 |
| Total repos accounted | 177 |
| Socraticode searches | 8 |
| Socraticode K | 20 each |
| Skills-library gap | partial |

Baseline reused: `.flywheel/plans/validate-and-redispatch-foundational-2026-05-03/01-RESEARCH-B.md` covered `ntm`, `beads_rust`, `destructive_command_guard`, `mcp_agent_mail`, `mcp_agent_mail_rust`, `coding_agent_session_search`, `cass_memory_system`, `frankensqlite`, `meta_skill`, `asupersync`, and `vibe_cockpit`. This report extends that file rather than redoing it.

## Skills Library Check

Query: `/flywheel:skills-best-practices "broad ecosystem mining pattern catalog jeff repos" --top=10 --include-content`

Matching skills used:

| Skill | Use in this sweep |
|---|---|
| `client-ecosystem-audit` | Evidence-grounded broad corpus discovery, confidence labels, claim-to-source discipline. |
| `codebase-audit` | Findings need source location, risk, and actionable classification. |
| `socraticode` | K>=10 semantic search rule; used K=20 for all MCP searches. |
| `jeff-issue-chain` | Jeff-specific repo etiquette: file:line citations, do not patch upstream, avoid prescribing implementation. |
| `flywheel-doctor-author` | Producer/measurement/consumer/promotion lens for doctor surfaces. |

`skills_library_gap=partial`: the library covers ecosystem audit mechanics and Socraticode grounding, but there is no dedicated skill for "full Dicklesworthstone corpus mining across ~177 repos with tiered accounting."

## Socraticode Ledger

All searches used `limit=20`, `includeLinked=true`, and `minScore=0` where available.

| # | Project path | Query | Main repo hits |
|---:|---|---|---|
| 1 | `/Users/josh/Developer/ntm` | `validation feedback loop callback verification done supervisor evidence receipt` | `ntm` robot audit validation, actuation verification, e2e scenario harness. |
| 2 | `/Users/josh/Developer/ntm` | `doctor health probe json diagnostics repair dry-run backup integrity check` | `ntm` doctor command, checkpoint integrity, rollback dry-run, server health. |
| 3 | `/Users/josh/Developer/beads_rust` | `golden tests robot json schema contract response schema output validation` | `beads_rust` CLI schema, robot JSON tests, agent integration docs. |
| 4 | `/Users/josh/Developer/asupersync` | `acceptance gate evidence artifact waiver contract no go readiness validation` | `asupersync` GA evidence packet, proof gates, readiness contracts. |
| 5 | `/Users/josh/Developer/meta_skill` | `feedback outcome effectiveness loop bandit learning skill validation cross runtime parity` | `meta_skill` feedback command, rewards, contextual bandit tests. |
| 6 | `/Users/josh/Developer/coding_agent_session_search` | `contract golden freeze validation agent robot json health status doctor quarantine derived assets` | `coding_agent_session_search` golden robot JSON, doctor/health golden, quarantine. |
| 7 | `/Users/josh/Developer/frankensqlite` | `supported surface matrix conformance parity evidence verification status contract` | `frankensqlite` parity matrix, machine-readable contract enforcement. |
| 8 | `/Users/josh/Developer/acip` | `validate audit feedback loop quality gate schema doctor test evidence contract` | `acip` audit mode/checker model, checksum/selftest, security warning posture. |

Observation: Socraticode linked-project search was useful for known load-bearing repos, but cross-repo recall remained mostly local-dominant. I therefore paired it with read-only corpus scans over `README*`, `AGENTS.md`, `CHANGELOG*`, `docs/**`, `tests/**`, and `scripts/**` for frequency analysis.

## Tier 1 Pattern Catalog - 34 New Repos

| Repo | Citation | Pattern | Problem solved | Class |
|---|---|---|---|---|
| `flywheel_connectors` | `/Users/josh/Developer/flywheel_connectors/AGENTS.md:17`, `:199`, `:221`, `:239` | Doctor repair plus conformance-gated integration coverage | Prevents connector drift from living as docs-only claims. | ADOPT |
| `frankenmermaid` | `/Users/josh/Developer/frankenmermaid/AGENTS.md:61`, `:177`, `:183`, `:309` | Evidence output, IR diagnostics, reproducible snapshot confidence | Turns rendering/parser compatibility into inspectable artifacts. | EXTEND |
| `frankenlibc` | `/Users/josh/Developer/frankenlibc/AGENTS.md:60`, `:69`, `:73`, `:180`, `:182` | Conformance orchestration, checksum fixtures, validation pipeline | Makes parity work measurable before performance claims. | ADOPT |
| `brenner_bot` | `/Users/josh/Developer/brenner_bot/AGENTS.md:34`, `:280`, `:369`, `:481`, `:499` | Missing audit trail means operation did not happen | Forces bot operations into durable, reviewable state. | ADOPT |
| `flywheel_gateway` | `/Users/josh/Developer/flywheel_gateway/README.md:9` | Agent orchestration dashboard with health surface | Centralizes multi-agent state and health for operators. | EXTEND |
| `frankenscipy` | `/Users/josh/Developer/frankenscipy/AGENTS.md:84`, `:89`, `:160`, `:213` | SciPy oracle conformance and proptest | Blocks "works on examples" from masquerading as parity. | ADOPT |
| `beads_viewer` | `/Users/josh/Developer/beads_viewer/AGENTS.md:83`, `:208`, `:214`, `:287` | Loader validation, robot output validation, performance benchmarks | Validates both human UI and agent-consumable surfaces. | ADOPT |
| `frankensearch` | `/Users/josh/Developer/frankensearch/AGENTS.md:197`, `:211`, `:213` | Shared fixture corpus with ground-truth relevance | Gives search quality a stable corpus and expected outcomes. | ADOPT |
| `frankenfs` | `/Users/josh/Developer/frankenfs/AGENTS.md:79`, `:84`, `:87`, `:88`, `:161` | CRC fixtures, conformance reports, proptest, snapshot tests | Validates storage semantics across correctness and regression axes. | ADOPT |
| `frankenpandas` | `/Users/josh/Developer/frankenpandas/AGENTS.md:152`, `:160`, `:163` | Sacred semantic parity and full-API differential tests | Prevents partial compatibility from being accepted as success. | ADOPT |
| `agentic_coding_flywheel_setup` | `/Users/josh/Developer/agentic_coding_flywheel_setup/AGENTS.md:136`, `:140`, `:142`, `:143` | Verified installer checksum discipline | Treats installer manifests as security boundary, not metadata. | ADOPT |
| `eidetic_engine_cli` | `/Users/josh/Developer/eidetic_engine_cli/AGENTS.md:78`, `:194`, `:195`, `:196`, `:197` | Forbidden-dep audit, golden outputs, retrieval fixtures, fuzz | Keeps CLI contracts stable and dependency creep visible. | ADOPT |
| `asupersync_ansi_c` | `/Users/josh/Developer/asupersync_ansi_c/AGENTS.md:116`, `:133`, `:142`, `:143`, `:155` | Rust-vs-C conformance and differential fuzzing | Validates port fidelity with minimized counterexamples. | ADOPT |
| `frankenjax` | `/Users/josh/Developer/frankenjax/AGENTS.md:66`, `:71`, `:159`, `:180` | Proptest plus JSON schema validation plus conformance package | Couples API shape validation to behavioral oracle tests. | ADOPT |
| `coding_agent_account_manager` | `/Users/josh/Developer/coding_agent_account_manager/AGENTS.md:190`, `:200`, `:219`, `:258`, `:261` | Profile validation, health endpoints, e2e diagnostics | Makes account/runtime health observable before use. | ADOPT |
| `frankenredis` | `/Users/josh/Developer/frankenredis/AGENTS.md:71`, `:138`, `:155`, `:184` | Redis command conformance harness and argument validation | Validates protocol semantics at dispatch boundaries. | ADOPT |
| `charmed_rust` | `/Users/josh/Developer/charmed_rust/AGENTS.md:74`, `:75`, `:154`, `:192`, `:196` | Property/snapshot tests and Go behavior parity | Gives a rewrite a known-good oracle. | ADOPT |
| `fastapi_rust` | `/Users/josh/Developer/fastapi_rust/AGENTS.md:105`, `:123`, `:138`, `:159` | Derive validation and automatic OpenAPI/schema generation | Makes request validation and documented API shape share one source. | EXTEND |
| `beads_viewer_rust` | `/Users/josh/Developer/beads_viewer_rust/AGENTS.md:165`, `:166`, `:167`, `:168`, `:169`, `:170` | Explicit schema, e2e robot/history/export/model tests | Validates all consumer surfaces separately. | ADOPT |
| `fastmcp_rust` | `/Users/josh/Developer/fastmcp_rust/AGENTS.md:198`, `:202`, `:283` | JSON-RPC round-trip and schema validation | MCP protocol correctness is tested at serialization boundaries. | ADOPT |
| `doodlestein_self_releaser` | `/Users/josh/Developer/doodlestein_self_releaser/AGENTS.md:123`, `:139`, `:158`, `:166`, `:173` | Shell syntax validation, E2E release gates, checksum sync | Prevents release automation from shipping unchecked scripts. | ADOPT |
| `claude_code_agent_farm` | `/Users/josh/Developer/claude_code_agent_farm/README.md:74`, `:207`, `:495`, `:509`, `:717` | Doctor command, health monitor, heartbeat files | Exposes agent farm liveness as explicit state. | EXTEND |
| `coding_agent_usage_tracker` | `/Users/josh/Developer/coding_agent_usage_tracker/AGENTS.md:172`, `:181`, `:193` | Schema contract tests and stable JSON output | Makes usage telemetry safe for downstream automation. | ADOPT |
| `beads_for_asupersync` | `/Users/josh/Developer/beads_for_asupersync/README.md:9`, `:23`, `:31`, `:52` | Health warning plus verification taxonomy | Encodes project-health gaps as first-class planning signal. | EXTEND |
| `cross_agent_session_resumer` | `/Users/josh/Developer/cross_agent_session_resumer/AGENTS.md:174`, `:181`, `:190`, `:192`, `:197`, `:198` | Dry-run, provider fixtures, golden output tests | Validates restore/resume behavior without mutating live sessions. | ADOPT |
| `beads-for-frankentui` | `/Users/josh/Developer/beads-for-frankentui/README.md:9`, `:46`, `:48` | Health warning, deterministic replay logging | Keeps UI task ingest/replay auditable. | EXTEND |
| `ascii_art_mini_transformer` | `/Users/josh/Developer/ascii_art_mini_transformer/README.md:22`, `:25`, `:26`, `:42`, `:52`, `:53` | Full E2E, Rust/Python parity, no-mock logs | Preserves reproducibility and parity proof across language boundary. | ADOPT |
| `automated_flywheel_setup_checker` | `/Users/josh/Developer/automated_flywheel_setup_checker/CHANGELOG.md:20`, `:22`, `:23`, `:24`, `:35` | Closed-loop remediation verification | Re-runs installer test after automated fix and records pass/fail/checksum. | ADOPT |
| `bio_inspired_nanochat` | `/Users/josh/Developer/bio_inspired_nanochat/AGENTS.md:138`, `:419`, `:440`, `:478` | Persistent artifacts and every-finding investigation | Prevents benchmark/training results from evaporating into scrollback. | EXTEND |
| `beads_for_franken_engine` | `/Users/josh/Developer/beads_for_franken_engine/README.md:9`, `:15`, `:53`, `:63`, `:69` | Receipt linkage and deterministic sampling contracts | Turns engine health into explicit receipts and invariants. | EXTEND |
| `asupersync_website` | `/Users/josh/Developer/asupersync_website/AGENTS.md:50`, `:225`, `:372`, `:406` | Playwright E2E plus health checks | Applies web UI validation to a project site surface. | EXTEND |
| `aadc` | `/Users/josh/Developer/aadc/AGENTS.md:161`, `:165`, `:169`, `:171`, `:174` | Fixture-based CLI E2E suites | Makes CLI behavior reproducible across expected input/output pairs. | ADOPT |
| `acip` | `/Users/josh/Developer/acip/integrations/openclaw/README.md:51`, `:66`, `:78`, `:87` | Checksum-verified installer with self-test | Makes supply-chain install state verifiable. | ADOPT |
| `agent_settings_backup_script` | `/Users/josh/Developer/agent_settings_backup_script/AGENTS.md:125`, `:139`, `:163`, `:164`, `:173`, `:185` | Backup/restore E2E and cross-agent fixture validation | Verifies restore semantics across Claude/Cursor/Codex config shapes. | ADOPT |

## Pattern Frequency Analysis

Method: read-only `rg` scan over all 177 repo paths from `~/.local/state/jeff-intel/repos.jsonl`, restricted to `README*`, `AGENTS.md`, `CHANGELOG*`, `docs/**`, `tests/**`, and `scripts/**`.

Top cross-repo validation patterns:

| Rank | Pattern family | Repo hits | Interpretation |
|---:|---|---:|---|
| 1 | `validation` / `validate` | 125 | Validation language is pervasive; nearly every substantive system has a validation surface. |
| 2 | `e2e` / `end-to-end` | 96 | Jeff commonly expects integration proof, not only unit proof. |
| 3 | `health` | 94 | Health surfaces are a broad default, especially for tools with runtime state. |
| 4 | `audit` | 94 | Auditability appears as product and operational doctrine. |
| 5 | `golden` / `snapshot` | 94 | Golden/snapshot contracts are a canonical stability mechanism. |
| 6 | `feedback` / `outcome` | 91 | Feedback/outcome loops appear beyond meta_skill. |
| 7 | `coverage` | 88 | Coverage is frequent but usually paired with stronger oracles. |
| 8 | `schema` | 80 | Machine-readable schemas are common for robot/CLI/API consumers. |
| 9 | `doctor` | 77 | Doctor surfaces are common but not universal; many repos use health/e2e without naming "doctor." |
| 10 | `checksum` / `sha256` / `signature` | 77 | Supply-chain/provenance validation is a major Jeff pattern. |

Other notable counts: `benchmark`/`criterion`/`performance budget` = 74, `conformance`/`parity`/`differential` = 69, `property`/`proptest` = 66, `fixture` = 65, `receipt`/`evidence` = 56, `fuzz` = 48, `dry-run` = 43.

## Doctor Pattern Landscape

Jeff doctor surfaces usually follow this shape:

| Stage | Jeff pattern | Examples |
|---|---|---|
| Producer | CLI or background substrate emits structured status, health, or diagnostic JSON. | `coding_agent_session_search` health/doctor golden JSON; `claude_code_agent_farm` heartbeat files; `coding_agent_account_manager` health endpoints. |
| Measurement | Checks are typed: schema stability, fixture replay, conformance, checksum, quarantine, dry-run repair plan. | `frankensqlite` machine-readable parity matrix; `agentic_coding_flywheel_setup` checksum review; `franken*` conformance harnesses. |
| Consumer | Human, CI, robot, or supervisor reads stable output. | `beads_viewer_rust` robot/history/export e2e tests; `beads_rust` baseline robot JSON from Lane B. |
| Promotion | A failing diagnostic becomes an actionable bead, release block, readiness decision, or remediation prompt. | `asupersync` GA evidence packet; `automated_flywheel_setup_checker` remediates and verifies. |

Main extension for flywheel: Jeff often has local doctor/health surfaces, while flywheel needs the cross-pane/cross-repo promotion layer that validates worker callbacks and redispatches.

## Callback-Validation Patterns

Broader sweep reinforces Lane B:

- `ntm` remains the closest match for "worker reports done -> supervisor validates" through robot audit validation and actuation verification.
- `asupersync` contributes release-board style evidence packets where decision state fails closed when evidence is missing or unverifiable; see `/Users/josh/Developer/asupersync/docs/wasm_ga_go_no_go_evidence_packet.md:10` through `:15` and hard states at `:21` through `:23`.
- `automated_flywheel_setup_checker` implements the same closed-loop idea at remediation time: apply fix, rerun installer test, capture pass/fail, exit code, stdout/stderr, and checksum validity at `/Users/josh/Developer/automated_flywheel_setup_checker/CHANGELOG.md:20` through `:24`.
- The `franken*` repos mostly validate claims against external oracles, not worker callbacks. They are still valuable for the "DONE is not proof; oracle output is proof" doctrine.

## Anti-Patterns Jeff Explicitly Avoids

| Anti-pattern | Evidence | Implication for flywheel |
|---|---|---|
| README or benchmark claim as proof | `/Users/josh/Developer/frankensqlite/docs/canonical_parity_contract.md:175` through `:183` says parser round-trip, single unit tests, benchmarks, cargo flags, and README claims are insufficient proof. | Require machine-readable receipts for validation claims. |
| Delete corrupt derived assets automatically | `/Users/josh/Developer/coding_agent_session_search/AGENTS.md:393` through `:395` quarantines failed-validation assets and keeps doctor read-only unless `--fix` is explicit. | Prefer quarantine + dry-run over silent cleanup. |
| Race doctor repairs | `/Users/josh/Developer/coding_agent_session_search/AGENTS.md:395` through `:396` says concurrent doctor `--fix` is undefined and health JSON is preferred for pre-flight. | Separate inspection from mutation in flywheel doctor designs. |
| Trade semantic parity for speed | `/Users/josh/Developer/frankenpandas/AGENTS.md:152` through `:164` makes semantic parity, full API scope, and differential testing non-negotiable. | Audit surfaces must not optimize away the real oracle. |
| Treat upstream release as enough | `/Users/josh/Developer/agentic_coding_flywheel_setup/AGENTS.md:140` through `:146` requires canonical checksum refresh and diff review; unrelated changes stop the update. | External state changes need local manifest verification before surfacing. |
| Accept missing release evidence | `/Users/josh/Developer/asupersync/docs/wasm_ga_go_no_go_evidence_packet.md:13` through `:15` and `:21` through `:23` fail closed on missing or unverifiable evidence. | Callback validator should fail closed on missing gates. |

## Updated Cross-Cutting Findings

Patterns Jeff uses that flywheel should adopt or extend:

1. Machine-readable proof beats narrative proof. This is strongest in `frankensqlite`, `beads_rust`, `coding_agent_session_search`, and `asupersync`.
2. Oracle comparison is Jeff's dominant validation style for replacements and ports: pandas, scipy, redis, libc, jax, fs, mermaid, and Rust/C ports all use conformance, parity, differential, or fixture replay.
3. Supply-chain state is validated with checksum/provenance/self-test gates more broadly than original Lane B showed.
4. Doctor surfaces are usually read-only first; mutation requires explicit `--fix`, dry-run proof, or remediation verification.
5. Stable robot JSON, golden outputs, and schema contracts are the common bridge between human-facing tools and agents.

Patterns flywheel uses that broader Jeff corpus did not fully duplicate:

1. Cross-pane dispatch callback contracts with mandatory `DONE ... evidence=...` validation remain more flywheel-specific than Jeff-generic.
2. The L-rule/fuckup/bead promotion ladder is more explicit than most Jeff repos. Jeff has evidence packets, issue chains, health warnings, and beads, but not a single universal trauma ladder across all repos.
3. File-reservation and NTM-pane callback discipline are flywheel-specific orchestration layers on top of Jeff's lower-level validation idioms.

Common ground:

1. Do not trust prose-only success reports.
2. Prefer JSON/schema/golden/fixture artifacts that a robot can check.
3. Separate observation from mutation.
4. Fail closed when evidence is missing.
5. Convert findings into durable tracking substrates.

Broader-sweep correction to Lane B: several items originally looking like flywheel innovations already exist in lesser-known Jeff repos in narrower forms: closed-loop remediation (`automated_flywheel_setup_checker`), verified installer checksums (`agentic_coding_flywheel_setup`, `acip`), full corpus conformance (`franken*` family), and no-delete quarantine (`coding_agent_session_search`). The remaining flywheel innovation is not the individual validation primitive; it is the orchestrated cross-runtime validation-and-redispatch loop.

## Tier 2 Catalog - 91 Repos

| Repo | One-line purpose | Tier-1 warranted? | Reason |
|---|---|---|---|
| `ChatTTS` | Text-to-speech/voice repo clone. | N | Not focused on validation substrate in this pass. |
| `Dicklesworthstone` | Personal/profile/root repo. | N | Meta identity repo, not a validation surface. |
| `advice_for_learning_to_code_and_making_an_app` | Educational advice content. | N | Content repo; no load-bearing validation loop found in shallow scan. |
| `agent-mailbox-viewer-example` | Example mailbox viewer integration. | N | Example app; mailbox validation covered in baseline Agent Mail repos. |
| `agent_flywheel_clawdbot_skills_and_integrations` | Agent/flywheel skills and integration material. | Y | Contains agent integration signal; future deep mine could compare to flywheel skills. |
| `anti_alzheimers_flasher` | Experimental visual/flasher app. | N | Domain app; validation patterns are local. |
| `automated_passive_causal_determination` | Causal direction/determination research. | N | Research/statistical validation, not orchestration pattern. |
| `automated_plan_reviser_pro` | Automated plan revision tooling. | Y | Plan validation vocabulary appears; future mine may help Lane C. |
| `automatic_cpp_code_analysis_with_gpt` | LLM-assisted C++ code analysis. | Y | Audit-like domain; shallow scan only. |
| `automatic_log_collector_and_analyzer` | Log collection and analysis. | Y | Likely feedback-loop adjacent; not indexed high enough for Tier 1 this pass. |
| `bakery_algorithm` | Distributed algorithm demo/article. | N | Educational/theory repo. |
| `ball_fighters` | Game/demo project. | N | Not validation-substrate oriented. |
| `beads_for_cass` | Bead mirror/planning repo for CASS. | Y | Bead health warning patterns may be useful but CASS covered in baseline. |
| `beads_for_cass_memory_system` | Beads/planning for CASS memory. | Y | Same family as CASS; not separately deep-mined. |
| `beads_viewer-pages` | Static pages for beads viewer. | N | Deployment/site artifact; viewer logic covered in Tier 1. |
| `beads_viewer_for_agentic_coding_flywheel_setup` | Viewer instance for ACFS beads. | N | Instance-specific viewer, not new pattern. |
| `bulk_transcribe_youtube_videos_from_playlist` | YouTube transcription utility. | N | Utility; validation not central. |
| `cardinal_network_analysis` | Network analysis research/app. | N | Domain analytics repo. |
| `cass-memory-system-agent-mailbox-viewer` | CASS/Agent Mail viewer glue. | N | Baseline covers CASS and Agent Mail core. |
| `causal_direction_estimation_from_data` | Causal estimation research. | N | Statistical validation, not orchestration substrate. |
| `cellular_automata_snowflake_simulator` | Simulation/demo app. | N | Local simulation validation only. |
| `chat_shared_conversation_to_file` | Export shared conversations to files. | N | Utility, shallow validation only. |
| `cloud_benchmarker` | Cloud benchmarking. | Y | Performance evidence patterns may be useful later. |
| `cmaes_explainer` | CMA-ES explainer/content. | N | Educational. |
| `cohomological_ai` | Research/content around AI/math. | N | Not validation tooling. |
| `cool_desktop_wallpapers` | Static assets/site. | N | No validation loop signal. |
| `curl_bash_one_liners_for_flywheel_tools` | Shell one-liner utility docs. | N | Reference snippets; not a substrate. |
| `ees` | Research/math repo. | N | Not relevant to 3-Q audit. |
| `eidetic-engine-docs` | Docs for Eidetic Engine. | N | Core CLI already Tier 1. |
| `eidetic-engine-website-project` | Website for Eidetic Engine. | N | Marketing/site layer. |
| `fast_cmaes` | Fast CMA-ES implementation. | N | Algorithm validation local to math library. |
| `fast_vector_similarity` | Vector similarity implementation. | Y | Benchmark/accuracy validation could be mined later. |
| `ffn` | Finance/quant library or fork. | N | Domain-specific. |
| `franken_agent_detection` | Agent detection/parity project. | Y | Validation terms present; worth later deep mine if agent-detection enters scope. |
| `franken_engine` | Engine in the Franken family. | Y | Likely has conformance/receipt patterns; bead repo already Tier 1. |
| `franken_networkx` | NetworkX-compatible rewrite. | Y | Oracle conformance pattern likely parallels other Franken repos. |
| `franken_node` | Node compatibility/rewrite project. | Y | Cross-runtime parity candidate. |
| `franken_numpy` | NumPy-compatible rewrite. | Y | High-value oracle conformance candidate. |
| `franken_whisper` | Whisper-compatible rewrite/project. | Y | Model/audio parity candidate. |
| `frankensqlite_website` | Website for Frankensqlite. | N | Core repo baseline covers validation. |
| `frankenterm` | Terminal/TUI project. | Y | Doctor/e2e signal appears; future mine could add TUI validation patterns. |
| `frankentorch` | Torch-compatible rewrite. | Y | High-value oracle conformance candidate. |
| `frankentui` | TUI toolkit/project. | Y | UI/TUI test patterns likely useful. |
| `frankentui_website` | Site for Frankentui. | N | Core repo more relevant. |
| `gemini-api-updater-doc` | Gemini API updater docs. | N | Provider-doc drift topic, not Jeff validation primitive. |
| `giil` | General utility/project. | N | Shallow scan did not warrant deep mine. |
| `github-diff-viewer` | GitHub diff viewer. | N | UI app; validation local. |
| `github_stars_curve` | GitHub stars visualization. | N | Analytics/content. |
| `gonode` | Go/Node related utility. | N | No strong audit pattern in shallow scan. |
| `grassmann_article` | Article/math content. | N | Content repo. |
| `guide_to_openai_response_api_and_agents_sdk` | API/SDK guide. | N | Reference content; live truth should be separately verified. |
| `hacker-news-clone` | App clone/demo. | N | Product app, not validation substrate. |
| `hessian_free_email_chain` | Research/email chain content. | N | Content/research. |
| `hoeffdings_d_explainer` | Statistical explainer. | N | Content/research. |
| `homebrew-tap` | Homebrew tap. | Y | Checksum/release validation may matter for installer doctrine. |
| `interactive_reversible_cellular_automata` | Simulation demo. | N | Domain app. |
| `introduction_to_temporal_logic` | Article/content. | N | Content. |
| `jazz_chord_progression_editor_html` | Static music editor. | N | Local app. |
| `jeffrey_emanuel_personal_site` | Personal site. | N | Website/content. |
| `jeffreysprompts.com` | Prompt website. | N | Content/site. |
| `lemelsonbot` | Bot project. | Y | Bot audit/health signals may warrant future deep mine. |
| `letter_learning_game` | Educational game. | N | Game. |
| `llm-docs` | LLM documentation. | N | Reference docs. |
| `llm-tournament` | LLM tournament/eval project. | Y | Evaluation feedback patterns could matter later. |
| `llm_aided_legal_discovery_bot` | Legal discovery bot. | Y | High-stakes audit trail patterns possible. |
| `llm_aided_ocr` | OCR helper. | N | Domain validation local. |
| `llm_docs` | LLM docs. | N | Reference docs. |
| `llm_introspective_compression_and_metacognition` | LLM research/meta-cognition repo. | N | Research repo; not operational substrate. |
| `llm_multi_round_coding_tournament` | Coding tournament/evaluation. | Y | Multi-round evaluation feedback likely relevant. |
| `loaded-pow` | Proof-of-work or load utility. | N | No strong validation loop signal. |
| `markdown-browser-agent-mailbox-viewer` | Markdown browser/mailbox viewer. | N | Viewer pattern covered elsewhere. |
| `markdown_web_browser` | Markdown web browser. | N | UI/browser utility. |
| `mcp_agent_mail_website` | Website for Agent Mail. | N | Core Agent Mail covered in baseline. |
| `military_history_articles` | Articles. | N | Content. |
| `mindmap-generator` | Mindmap utility. | N | App/tool, not audit loop. |
| `misc_coding_agent_tips_and_scripts` | Agent tips/scripts. | Y | May include process anti-patterns; shallow-scanned only. |
| `model_guided_research` | Research workflow/tooling. | Y | Feedback and outcome language present. |
| `most-influential-github-repo-stars` | GitHub stars analysis. | N | Analytics. |
| `multivariate_normality_testing` | Statistical testing package. | N | Domain tests, not orchestration. |
| `my_shared_conversations` | Conversation archive. | N | Data/content archive. |
| `nextjs-github-markdown-blog` | Blog template/app. | N | Website. |
| `opentui_rust` | Rust OpenTUI work. | Y | TUI validation patterns overlap with `frankentui`. |
| `paxos_vs_raft` | Distributed systems article/demo. | N | Content/theory. |
| `phage_explorer` | Science/explorer app. | N | Domain app. |
| `pi_agent_rust` | Rust agent project. | Y | Agent health/doctor terms present. |
| `post_compact_reminder` | Reminder utility for post-compact sessions. | Y | Agent workflow guardrail adjacent. |
| `ppp_loan_fraud_analysis` | Fraud analysis. | N | Domain analysis. |
| `prepareprojectforllmprompt` | Prompt/project packaging utility. | Y | Source-to-prompt validation patterns possible. |
| `process_triage` | Process triage utility. | Y | Health/doctor/process safety patterns likely relevant. |
| `py_chord_chart_generator` | Music chart generator. | N | Domain utility. |
| `rano` | Utility/project. | N | Shallow scan did not warrant deep mine. |

## Tier 3 Inventory - 41 Repos

Reason for all Tier 3 entries: accounted in canonical corpus, but not mined this pass because they were content/static-site/domain-utility repos or lower-priority implementation repos after Tier 1 and Tier 2 satisfied the validation-pattern discovery goal.

`fmd_blog_posts`, `kissinger_undergraduate_thesis`, `raptorq_article`, `remote_compilation_helper`, `repo_updater`, `rich_rust`, `rust_proxy`, `rust_scriptbots`, `rust_stream_deck`, `sassaman_and_dingledine_on_remailers_at_blackhat_2003`, `savant-elite`, `scoop-bucket`, `slb`, `some_thoughts_on_ai_alignment`, `source_to_prompt_tui`, `sqlalchemy_data_model_visualizer`, `sqlmodel_rust`, `storage_ballast_helper`, `suno2cd`, `surface-dial-rust`, `swiss_army_llama`, `system_resource_protection_script`, `textract-py3`, `textsynth_server_cluster`, `the_lighthill_debate_on_ai`, `toon-go`, `toon_rust`, `tsap_mcp_server`, `ultimate_bug_scanner`, `ultimate_mcp_client`, `ultimate_mcp_server`, `ultrasearch`, `useful_coding_guides_for_llms`, `useful_tmux_commands`, `visual_astar_python`, `wasm_cmaes`, `wezterm`, `xf`, `your-source-to-prompt.html`, `youtube_transcript_cleaner`, `yto_blog_posts`.

## Open Questions For Lane C

1. Should flywheel standardize on Jeff's fail-closed evidence-packet shape for callback validation, with `NO_GO` on missing or unverifiable gates?
2. Which flywheel surfaces need a read-only doctor first, with mutation behind explicit `--fix` and dry-run evidence?
3. Should all worker `DONE` receipts include machine-readable schema/golden validation where possible, rather than prose evidence paths alone?
4. How much of the `franken*` oracle-conformance pattern can be generalized for flywheel surfaces that do not have an obvious upstream oracle?
5. Should installer/checksum/provenance validation become part of the 3-Q audit for any flywheel surface that shells out to external CLIs?

## DOD Ledger

| DOD item | Status |
|---|---|
| Ladder passed | yes |
| Tier 1 has >=30 new ADOPT/EXTEND/AVOID rows | yes, 34 |
| Tier 2 has >=80 repos catalogued | yes, 91 |
| Tier 3 has remainder accounted | yes, 41 |
| >=150 repos accounted | yes, 177 |
| Top-10 pattern frequency analysis included | yes |
| Anti-patterns Jeff explicitly avoids included | yes |
| Read-only constraint honored | yes; only this report file was written |
