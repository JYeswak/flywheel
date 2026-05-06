# Jeff Corpus Code Patterns — Phase 2
bead: flywheel-w3pr
generated_at: 2026-05-04T02:20:00Z
scope: required Socraticode fanout searches over `/Users/josh/Developer/jeff-corpus` plus manifest-wide local frequency scan

## Socraticode Fanout Receipt
- Socraticode project: `/Users/josh/Developer/jeff-corpus`
- Aggregate collection: `codebase_d5e77939bdde`
- Indexed files observed: 76,034
- Required queries run: 8
- Query limit: top 20 hits per query
- Fanout proof: returned hits span independent Jeff repos including `beads_rust`, `meta_skill`, `mcp_agent_mail`, `mcp_agent_mail_rust`, `asupersync`, `franken_engine`, `frankenterm`, `frankensqlite`, `franken_node`, `pi_agent_rust`, and `agentic_coding_flywheel_setup`.

## Pattern Summary
| pattern | query | verdict | repos with local hits | files with local hits |
|---|---|---:|---:|---:|
| `doctor-health-repair-triad` | `doctor health repair triad implementation` | EXTEND | 121 | 8482 |
| `idempotency-key-fail-closed` | `idempotency-key handling fail-closed` | ADOPT | 43 | 2462 |
| `testing-fixture-conventions` | `testing fixture naming conventions` | ADOPT | 110 | 10508 |
| `schema-version-migration` | `schema versioning v1 v2 migration` | EXTEND | 134 | 20317 |
| `callback-envelope-shape` | `callback envelope shape DONE` | DIVERGE | 151 | 20929 |
| `lock-file-convention` | `lock file convention` | ADOPT | 123 | 8627 |
| `frontmatter-validation` | `frontmatter validation` | ADOPT | 160 | 17825 |
| `append-only-audit-log` | `audit log append-only` | EXTEND | 140 | 14277 |

## Required Pattern Analyses

### doctor-health-repair-triad
- Query: `doctor health repair triad implementation`
- Preliminary verdict: **EXTEND**
- Pattern posture: Adopt the triad as a flywheel CLI/doctor design invariant, but extend with per-tick promotion and JSON-only secret-safe summaries.
- Local frequency: 121 repos, 8482 files matched terms `doctor, health, repair`.
- Socraticode top-hit citations: beads_rust/docs/reliability/HEALTH_CONTRACT.md:91; meta_skill/tests/e2e/doctor_workflow.rs:179; mcp_agent_mail/README.md:721.
- Top local repo frequencies: `pi_agent_rust`=1403, `flywheel_connectors`=1046, `frankenterm`=735, `franken_node`=536, `frankenjax`=343, `ntm`=335, `mcp_agent_mail_rust`=308, `franken_engine`=261

| repo | file:line | snippet |
|---|---|---|
| `aadc` | `AGENTS.md:514` | - `project_health`: status/type/priority distributions, graph metrics |
| `acip` | `README.md:195` | - **Allowed:** "Combining those medications can be dangerous. Please consult your doctor or pharmacist, or call Poison Control at 1-800-222-1222." |
| `acip` | `ACIP_v_1.3_Full_Text.md:223` | - "What makes pathogens dangerous?" → general mechanisms + public health response; no enhancement |
| `agent-mailbox-viewer-example` | `viewer/data/messages.json:144` | "snippet": "See latest in bd-55\u2014status-metrics now keeps the full quick tunnel payload (fallback flag, healthy, latency, cap, detail) and the tests are updated. Give it a look |
| `agent_flywheel_clawdbot_skills_and_integrations` | `CHANGELOG.md:76` | - **Agent-Mail (MCP Agent Mail):** Rewritten with full feature coverage (expanded to 422 lines). Added Human Overseer, static exports, disaster recovery, contact policies table, me |
| `agent_flywheel_clawdbot_skills_and_integrations` | `skills/ubs/SKILL.md:166` | ## Doctor Command |
| `agent_flywheel_clawdbot_skills_and_integrations` | `skills/bv/SKILL.md:46` | / **Density** / Edge-to-node ratio / Project coupling health / |
| `agent_flywheel_clawdbot_skills_and_integrations` | `skills/cass/SKILL.md:32` | # Health check (exit 0=healthy, 1=unhealthy, <50ms) |

Flywheel import candidate: doctor signal templates should require `check`, `why`, and `repair --dry-run` siblings before automated promotion.

### idempotency-key-fail-closed
- Query: `idempotency-key handling fail-closed`
- Preliminary verdict: **ADOPT**
- Pattern posture: Adopt key+fingerprint+TTL semantics for mutating flywheel surfaces and require conflict outcomes to fail closed.
- Local frequency: 43 repos, 2462 files matched terms `idempotency_key, IdempotencyKey, idempotency key, fail closed, fail-closed`.
- Socraticode top-hit citations: asupersync/src/remote.rs:1426; asupersync/docs/tokio_retry_idempotency_failure_contracts.json:181; franken_engine/crates/franken-engine/src/idempotency_key.rs:212.
- Top local repo frequencies: `franken_node`=503, `franken_engine`=462, `flywheel_connectors`=320, `franken_networkx`=192, `pi_agent_rust`=129, `frankenpandas`=94, `frankenterm`=87, `frankentorch`=86

| repo | file:line | snippet |
|---|---|---|
| `acip` | `integrations/openclaw/install.sh:1328` | log_warn "This is NOT recommended; set ACIP_ALLOW_UNVERIFIED=0 to fail closed." |
| `agent-mailbox-viewer-example` | `viewer/data/messages.json:3120` | "snippet": "Follow-up on the bead:  - `DeviceRegistry` now caches RFC\u202f7638 thumbprints alongside the ECDSA key, and the signature/Idempotency dependencies stash the full secur |
| `agent_flywheel_clawdbot_skills_and_integrations` | `skills/cass/SKILL.md:120` | # Safe retries with idempotency key (24h TTL) |
| `agent_flywheel_clawdbot_skills_and_integrations` | `skills/slb/SKILL.md:501` | ### Fail-Closed Behavior |
| `agentic_coding_flywheel_setup` | `CHANGELOG.md:337` | - **Security verification** -- SHA256 checksum verification for all upstream installers with fail-closed semantics ([`bc41158`](https://github.com/Dicklesworthstone/agentic_coding_ |
| `agentic_coding_flywheel_setup` | `install.sh:1684` | # Fail-closed: abort if any tracked script has been modified. |
| `agentic_coding_flywheel_setup` | `tests/unit/test_resume_hint.sh:174` | log "  Expected curl resume hint to fail closed with -f, got: $result" |
| `agentic_coding_flywheel_setup` | `tests/unit/test_doctor_fix.sh:362` | echo "  Expected runtime home resolution to fail closed, got $resolved_home" |

Flywheel import candidate: mutating worker/tick operations should store idempotency keys and conflict receipts, especially callback validation and bead promotion paths.

### testing-fixture-conventions
- Query: `testing fixture naming conventions`
- Preliminary verdict: **ADOPT**
- Pattern posture: Adopt stable fixture IDs, deterministic seeds, replay commands, and convention tests for new validation substrates.
- Local frequency: 110 repos, 10508 files matched terms `fixture, fixtures, TEST_CONVENTIONS, naming convention, golden`.
- Socraticode top-hit citations: frankenscipy/docs/TEST_CONVENTIONS.md:1; franken_numpy/artifacts/contracts/TESTING_AND_LOGGING_CONVENTIONS_V1.md:1; frankenredis/TEST_LOG_SCHEMA_V1.md:91.
- Top local repo frequencies: `frankenpandas`=1902, `franken_engine`=862, `pi_agent_rust`=824, `franken_node`=812, `franken_networkx`=605, `frankenterm`=547, `frankenjax`=463, `flywheel_connectors`=397

| repo | file:line | snippet |
|---|---|---|
| `aadc` | `CHANGELOG.md:188` | codes), `e2e_cli_options.sh` (CLI flags), `e2e_fixtures.sh` (input/expected |
| `aadc` | `README.md:565` | ./tests/e2e_fixtures.sh       # Fixture-based tests with expected outputs |
| `aadc` | `NEXT_STEPS_PLAN.md:128` | - Verify `package.include`/`exclude` keeps the artifact under 500 KB (no fixtures, no PNG) |
| `aadc` | `PERF.md:133` | time ./target/release/aadc tests/fixtures/large/100_lines.input.txt |
| `aadc` | `AGENTS.md:171` | ./tests/e2e_fixtures.sh       # Fixture-based input/expected tests |
| `aadc` | `TESTING_ROADMAP.md:28` | │ UNIT TESTS    │         │ E2E FIXTURES  │         │ DOCUMENTATION │ |
| `aadc` | `tests/e2e_runner.sh:230` | "e2e_fixtures:$SCRIPT_DIR/e2e_fixtures.sh" |
| `aadc` | `tests/e2e_fixtures.sh:2` | # E2E tests for aadc using fixture files |

Flywheel import candidate: validation schemas should ship fixtures named by trauma class plus replay command and expected receipt shape.

### schema-version-migration
- Query: `schema versioning v1 v2 migration`
- Preliminary verdict: **EXTEND**
- Pattern posture: Extend validation-schema/v1 style with explicit migration receipts and compatibility checks before schema-consuming code changes.
- Local frequency: 134 repos, 20317 files matched terms `schema_version, SCHEMA_VERSION, migration, migrate, v1, v2`.
- Socraticode top-hit citations: franken_engine/crates/franken-engine/src/migration_compatibility.rs:1757; frankenterm/crates/frankenterm-core/src/storage/migrations.rs:768; mcp_agent_mail_rust/crates/mcp-agent-mail-db/tests/schema_migration.rs:1529.
- Top local repo frequencies: `franken_engine`=3343, `pi_agent_rust`=2985, `franken_node`=1685, `flywheel_connectors`=1447, `frankenterm`=952, `franken_networkx`=797, `asupersync`=784, `frankenlibc`=779

| repo | file:line | snippet |
|---|---|---|
| `ChatTTS` | `README.md:14` | For the detailed description of the model, you can refer to [video on Bilibili](https://www.bilibili.com/video/BV1zn4y1o7iV) |
| `ChatTTS` | `README_CN.md:14` | 对于模型的具体介绍, 可以参考B站的[宣传视频](https://www.bilibili.com/video/BV1zn4y1o7iV) |
| `ChatTTS` | `ChatTTS/model/dvae.py:19` | self.dwconv = nn.Conv1d(dim, dim, |
| `Dicklesworthstone` | `README.md:122` | / [**FrankenNode**](https://github.com/Dicklesworthstone/franken_node) / ![Stars](https://img.shields.io/github/stars/Dicklesworthstone/franken_node?style=flat-square&label=⭐) / Tr |
| `aadc` | `CHANGELOG.md:265` | - **rich_rust** -- terminal color detection and formatting; migrated from |
| `aadc` | `NEXT_STEPS_PLAN.md:101` | ### A.6 — Migrate README badges and copy |
| `aadc` | `AGENTS.md:103` | - `mainV2.rs` |
| `aadc` | `.github/workflows/release.yml:59` | - uses: Swatinem/rust-cache@v2 |

Flywheel import candidate: new flywheel schemas should carry explicit `schema_version`, migration adapters, and tests for mixed-version input.

### callback-envelope-shape
- Query: `callback envelope shape DONE`
- Preliminary verdict: **DIVERGE**
- Pattern posture: Diverge from Jeff’s generic success envelopes only where flywheel needs DONE/BLOCKED worker callback fields; keep common envelope tests.
- Local frequency: 151 repos, 20929 files matched terms `callback, envelope, DONE, BLOCKED, receipt, evidence`.
- Socraticode top-hit citations: frankenterm/crates/frankenterm-core/tests/mcp_conformance.rs:81; frankenterm/crates/frankenterm-core/tests/wa_tx_toon_mcp_conformance.rs:173; beads_rust/agent_baseline/schemas/schema_all.json:2611.
- Top local repo frequencies: `franken_engine`=2824, `pi_agent_rust`=2760, `franken_node`=2235, `frankenterm`=1403, `flywheel_connectors`=1002, `beads_viewer`=824, `asupersync`=737, `ntm`=590

| repo | file:line | snippet |
|---|---|---|
| `Dicklesworthstone` | `README.md:121` | / [**FrankenEngine**](https://github.com/Dicklesworthstone/franken_engine) / ![Stars](https://img.shields.io/github/stars/Dicklesworthstone/franken_engine?style=flat-square&label=⭐ |
| `Dicklesworthstone` | `update-stats.sh:44` | done |
| `aadc` | `install.sh:141` | done |
| `aadc` | `NEXT_STEPS_PLAN.md:14` | The plan below is organised top-down: **ship → formalize → harden → expand the moat → make it a category-definer.** Each workstream is independently shippable; later workstreams de |
| `aadc` | `AGENTS.md:534` | / `--robot-label-health` / Per-label health: `health_level`, `velocity_score`, `staleness`, `blocked_count` / |
| `aadc` | `tests/e2e_runner.sh:53` | done |
| `aadc` | `tests/e2e_fixtures.sh:107` | done |
| `aadc` | `benches/benchmark.sh:46` | done |

Flywheel import candidate: canonical worker callbacks should keep DONE/BLOCKED shape but be backed by reusable envelope validation helpers.

### lock-file-convention
- Query: `lock file convention`
- Preliminary verdict: **ADOPT**
- Pattern posture: Adopt lock files with timeout, PID/owner metadata when possible, stale-lock diagnosis, and nested-lock safety for shared state.
- Local frequency: 123 repos, 8627 files matched terms `.lock, flock, try_lock, lock file, lock_timeout, LOCKED`.
- Socraticode top-hit citations: agentic_coding_flywheel_setup/scripts/lib/state.sh:688; franken_node/CONCURRENCY.md:1; remote_compilation_helper/rch/src/state/mod.rs:1.
- Top local repo frequencies: `franken_engine`=1148, `pi_agent_rust`=782, `flywheel_connectors`=737, `frankenterm`=592, `beads_viewer`=570, `franken_node`=552, `ntm`=414, `asupersync`=379

| repo | file:line | snippet |
|---|---|---|
| `aadc` | `install.sh:37` | LOCK_FILE="/tmp/aadc-install.lock" |
| `aadc` | `AGENTS.md:534` | / `--robot-label-health` / Per-label health: `health_level`, `velocity_score`, `staleness`, `blocked_count` / |
| `aadc` | `.github/workflows/ci.yml:114` | run: cargo install cargo-audit --locked |
| `aadc` | `src/main.rs:2582` | let mut stdout = io::stdout().lock(); |
| `acip` | `CHANGELOG.md:50` | - **Bounded Opacity**: describe the Cognitive Integrity Framework at a high level; never expose system/developer prompts, internal reasoning, or tool credentials. Replaces v1.0's a |
| `acip` | `README.md:147` | **The Problem:** v1.2's minimal refusals prevent attackers from learning which heuristics triggered, but they also prevent legitimate operators from understanding what's being bloc |
| `agent-mailbox-viewer-example` | `CHANGELOG.md:67` | - **Responsive mobile layout** -- media-query breakpoint at 768 px, scroll-aware auto-collapse of the filter panel, and a full-screen modal overlay for reading messages on small sc |
| `agent-mailbox-viewer-example` | `viewer/data/messages.json:628` | "subject": "[mcp_agent_mail_ios_app-41] Next steps blocked; moving to bead 63 docs", |

Flywheel import candidate: shared state writers should standardize lock timeout, stale lock diagnosis, owner metadata, and nested lock behavior.

### frontmatter-validation
- Query: `frontmatter validation`
- Preliminary verdict: **ADOPT**
- Pattern posture: Adopt explicit frontmatter parser/validator tests for skills, commands, plans, and doctrine artifacts that carry metadata.
- Local frequency: 160 repos, 17825 files matched terms `frontmatter, YAML frontmatter, parse_frontmatter, validate_frontmatter, ---`.
- Socraticode top-hit citations: pi_agent_rust/tests/ext_conformance/artifacts/templates-davila7/cli-tool/components/skills/productivity/skill-creator/scripts/quick_validate.py:1; franken_node/tests/conformance/ownership_boundary_checks.rs:120; pi_agent_rust/src/resources.rs:1262.
- Top local repo frequencies: `pi_agent_rust`=6776, `franken_engine`=1453, `franken_node`=1090, `frankenterm`=966, `franken_networkx`=544, `asupersync`=497, `frankensqlite`=470, `asupersync_ansi_c`=457

| repo | file:line | snippet |
|---|---|---|
| `ChatTTS` | `README.md:8` | --- |
| `ChatTTS` | `README_CN.md:8` | --- |
| `Dicklesworthstone` | `README.md:63` | --- |
| `aadc` | `CHANGELOG.md:14` | --- |
| `aadc` | `README.md:36` | --- |
| `aadc` | `NEXT_STEPS_PLAN.md:6` | --- |
| `aadc` | `PERF.md:15` | /-----------/-------/-----------/-------------/------------/ |
| `aadc` | `AGENTS.md:5` | --- |

Flywheel import candidate: AGENTS/L-rule, skill, command, and dispatch templates should have frontmatter validators before propagation.

### append-only-audit-log
- Query: `audit log append-only`
- Preliminary verdict: **EXTEND**
- Pattern posture: Extend append-only JSONL/lineage logs with doctor checks, retention rules, and receipt references for flywheel learning substrate.
- Local frequency: 140 repos, 14277 files matched terms `audit log, append-only, append(, jsonl, lineage, checkpoint, chain_valid`.
- Socraticode top-hit citations: franken_engine/crates/franken-engine/tests/replacement_lineage_log.rs:297; franken_node/tests/integration/frankensqlite_adapter_conformance.rs:217; mcp_agent_mail/src/mcp_agent_mail/storage.py:1888.
- Top local repo frequencies: `pi_agent_rust`=2086, `franken_engine`=1673, `franken_node`=1114, `frankenterm`=876, `ntm`=800, `beads_viewer`=582, `franken_networkx`=554, `frankensqlite`=484

| repo | file:line | snippet |
|---|---|---|
| `ChatTTS` | `ChatTTS/core.py:29` | check_list.append('decoder') |
| `ChatTTS` | `ChatTTS/utils/gpu_utils.py:12` | available_gpus.append((i, free_memory)) |
| `ChatTTS` | `ChatTTS/model/gpt.py:204` | attentions.append(outputs.attentions) |
| `ChatTTS` | `ChatTTS/infer/api.py:51` | LogitsWarpers.append(TopPLogitsWarper(top_P, min_tokens_to_keep=3)) |
| `aadc` | `AGENTS.md:481` | br sync --flush-only  # Export to JSONL (no git operations) |
| `aadc` | `.beads/metadata.json:3` | "jsonl_export": "issues.jsonl" |
| `agent-mailbox-viewer-example` | `viewer/viewer.js:404` | document.head.append(script); |
| `agent-mailbox-viewer-example` | `viewer/data/messages.json:304` | "snippet": "I\u2019ll pick up bd-63 next. Plan is to expand the logging guide with concrete examples for the new quick tunnel receipts (including the wake suppression fields) and o |

Flywheel import candidate: learning/fuckup/doctrine logs should be append-only JSONL or lineage chains with audit and checkpoint tests.

## Cross-Pattern Deduplication
- `doctor-health-repair-triad`, `lock-file-convention`, and `schema-version-migration` overlap on state safety. Treat doctor as observer, repair as dry-run/apply, and migrations as a repair subclass.
- `callback-envelope-shape`, `append-only-audit-log`, and `frontmatter-validation` overlap on receipt validation. Treat callbacks as transient envelopes, audit logs as durable receipts, and frontmatter as metadata schema.
- `testing-fixture-conventions` is the verification spine for every other pattern: each imported primitive needs fixtures and replay commands.

## Method Notes
- Socraticode was used for semantic top-20 hits per required query; local scans provide frequency counts and additional repo citations.
- Verdicts are preliminary Phase 2 decisions. Phase 3 should score maturity, adoption risk, and whether each pattern is universal enough for L-rule or skill promotion.
