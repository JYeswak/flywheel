# Candidate L-Rules From Jeff Corpus

status: approval_only
source_bead: flywheel-w3pr.3

These are staged doctrine candidates, not canonical numbered L-rules. They
should not be copied into `AGENTS.md` until Joshua approves a follow-up doctrine
bead and the named implementation bead validates the pattern locally.

## Candidate: Mutation Surfaces Must Carry Safety Receipts

Phase 4 verdict: EXTEND.

Rule draft: Any flywheel surface that mutates shared state must emit a safety
receipt covering idempotency key, request fingerprint, lock owner/TTL,
append-only audit row, backup or no-backup reason, rollback posture, and
storage preflight when applicable.

Evidence:

- `.flywheel/jeff-corpus/v1/learnings/04-adopt-extend-avoid.md`, mutation-safety row = EXTEND.
- `asupersync/src/remote.rs:1426` is cited for idempotency-key handling.
- `remote_compilation_helper/install.sh:366` records lock PID metadata.
- `franken_engine/crates/franken-engine/tests/replacement_lineage_log.rs:297` tests replacement lineage logging.

Local validation dependency: `flywheel-l1vl`.

## Candidate: Active Runtime Parity Requires Runtime-Verified Proof

Phase 4 verdict: EXTEND.

Rule draft: Fixture-only parity may prove schemas and packet rendering, but any
claim that an active runtime is parity-compliant must carry runtime-verified
probe evidence for that runtime, or be marked below-runtime proof level in
doctor JSON.

Evidence:

- `.flywheel/jeff-corpus/v1/learnings/04-adopt-extend-avoid.md`, runtime parity proof matrix row = EXTEND.
- `cross_agent_session_resumer/tests/cass_parity_test.rs:1139` asserts shared message invariants across Claude Code, Codex, and Gemini providers.
- `destructive_command_guard/tests/codex_hook_protocol.rs:2022` verifies Codex and Claude allowlist behavior have structural parity.
- `agentic_coding_flywheel_setup/tests/e2e/test_cross_agent_resume_e2e.sh:1` runs a real cross-agent resume matrix and writes artifacts.

Local validation dependency: `flywheel-8qix`.

## Candidate: Corpus Work Is Not Done Until It Is Consumable

Phase 4 verdict: EXTEND.

Rule draft: Corpus, mirror, or bulk-ingest work is incomplete until downstream
consumers can search it, resume it, verify storage impact, and run a smoke query
against the produced substrate.

Evidence:

- `.flywheel/jeff-corpus/v1/learnings/04-adopt-extend-avoid.md`, corpus consumability gate included in EXTEND count.
- `INCIDENTS.md:1` documents the corpus-dispatch consumability failure and fix.
- `tests/jeff-corpus-accretive.sh:71` tests deterministic pending rows for delta indexing.
- `tests/jeff-corpus-library-ingestion.sh:47` tests learning artifact structure and derived bead creation.

Local validation dependency: existing Jeff corpus tests plus future recurrence threshold before L-rule promotion.

## Candidate: Validation Claims Require Replayable Fixtures

Phase 4 verdict: ADOPT.

Rule draft: A validation claim is not accepted unless it names a replay command,
input fixture, expected output or schema assertion, and owner bead. Frontmatter
and schema-bearing artifacts must be parsed structurally.

Evidence:

- `.flywheel/jeff-corpus/v1/learnings/04-adopt-extend-avoid.md`, fixture/schema/frontmatter rows = ADOPT/EXTEND.
- `aadc/tests/e2e_fixtures.sh:2` implements fixture-based E2E tests.
- `frankenscipy/docs/TEST_CONVENTIONS.md:1` defines reusable testing conventions.
- `pi_agent_rust/tests/ext_conformance/artifacts/templates-davila7/cli-tool/components/skills/productivity/skill-creator/scripts/quick_validate.py:1` validates skill/frontmatter structure.

Local validation dependency: `flywheel-0egk`.

## Candidate: Operational Substrate Must Expose Doctor, Health, And Repair

Phase 4 verdict: EXTEND.

Rule draft: A new operational substrate cannot be treated as operator-ready
until it exposes read-only doctor JSON, read-only health/status, and a repair
path with dry-run/apply separation or an explicit no-repair rationale.

Evidence:

- `.flywheel/jeff-corpus/v1/learnings/04-adopt-extend-avoid.md`, doctor/health/repair triad row = EXTEND.
- `mcp_agent_mail/README.md:721` documents Agent Mail doctor surfaces.
- `mcp_agent_mail/README.md:793` documents doctor repair dry-run behavior.
- `coding_agent_session_search/README.md:55` documents `cass health --json`.

Local validation dependency: `flywheel-hn8e`.
