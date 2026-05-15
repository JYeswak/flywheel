# Jeff Corpus ADOPT / EXTEND / AVOID Synthesis - Phase 4
bead: flywheel-w3pr.2
generated_at: 2026-05-04T10:22:00Z
scope: Phase 1 doctrine clusters, Phase 2 code-pattern frequencies, Phase 3 quality ranking, and Jeff-intel per-query learning artifacts

## Receipt
- Phase 1 input: `.flywheel/jeff-corpus/v1/learnings/01-doctrine-cluster.md`
- Phase 2 input: `.flywheel/jeff-corpus/v1/learnings/02-code-patterns.md`
- Phase 3 input: `.flywheel/jeff-corpus/v1/learnings/03-quality-ranking.md`
- Manifest baseline: `.flywheel/jeff-corpus/v1/manifest.json`, 177 repos
- Additional query artifacts: `~/.local/state/jeff-intel/learnings/{01..10}-*.md`
- New implementation beads filed by this synthesis: `flywheel-e7c2`, `flywheel-94si`, `flywheel-f2bm`, `flywheel-8qix`

## Verdict Counts
| verdict | count | patterns |
|---|---:|---|
| ADOPT | 5 | testing/fixture conventions, error taxonomy, frontmatter validation, secrets redaction canaries, canonical CLI registry checks |
| EXTEND | 9 | doctor/health/repair triad, schema/version migration, idempotency/lock/append-only lineage, subprocess drain receipts, state-store authority, Agent Mail dispatch receipts, runtime parity proof matrix, Jeff quality exemplars, corpus consumability gate |
| DIVERGE | 2 | generic callback envelope shape, generic success/status semantics |
| AVOID | 3 | prose-only "documentation as proof", conceptual/demo repos as operational exemplars, one-off scripts without runnable repair/test surfaces |

## Decision Table
| pattern | source signal | final verdict | why | flywheel target | bead/no-bead receipt |
|---|---|---|---|---|---|
| Testing patterns and fixture conventions | Phase 1 `testing-patterns`; Phase 2 `testing-fixture-conventions` in 110 repos; Phase 3 top repos all have fixtures/tests | ADOPT | This is the verification spine for every other import: stable fixture IDs, expected outputs, replay commands, and golden/conformance checks. | validation schemas, CLI tests, dispatch validators, doctor probes | Existing bead `flywheel-0egk`; no new bead because it already covers fixture IDs, schema versions, migration/mixed-version tests, and frontmatter validation. |
| Doctor / health / repair triad | Phase 1 `doctor-health-repair-triad`; Phase 2 local hits in 121 repos; high-ranking repos expose doctor/repair evidence | EXTEND | Flywheel already has doctor signals, but Jeff's pattern is a triad: observe, classify, and repair with dry-run/apply separation. Extend with L60 doctor signal contract and L82 canonical CLI scoping. | `flywheel-loop doctor`, canonical CLI surfaces, repair helpers | Existing bead `flywheel-hn8e`; no new bead because it directly imports the triad. |
| Error handling and recovery taxonomy | Phase 1 `error-handling-and-recovery`; Jeff-intel `01-error-handling-patterns.md` | ADOPT | Validation receipts need deterministic `failure_class`, `retry_policy`, and `recovery_hint`; prose errors are not enough for callbacks or doctors. | validation receipts, callback validator, doctor JSON | Existing bead `flywheel-esdx`; no new bead because it is the P1 derived implementation bead. |
| Schema versioning and migration discipline | Phase 1 `schema-versioning-and-migrations`; Phase 2 `schema-version-migration` in 134 repos | EXTEND | Flywheel has validation-schema/v1, but every schema-consuming change should carry mixed-version fixture proof and migration receipts. | `.flywheel/validation-schema/v1`, receipt parsers, future schema bumps | Existing bead `flywheel-0egk`; no new bead because schema-version expectations and mixed-version tests are in scope there. |
| Callback and receipt envelopes | Phase 1 `callback-and-receipt-envelope`; Phase 2 `callback-envelope-shape` in 151 repos | DIVERGE | Jeff's generic envelope pattern is useful, but flywheel must preserve DONE/BLOCKED, DID/DIDNT/GAPS, callback delivery verification, and no-bead/fuckup fields. Use common validation helpers without flattening worker semantics. | `.flywheel/scripts/validate-callback.py`, `.flywheel/scripts/verify-callback-delivery.sh`, L71, L80 | No new bead: covered by `flywheel-0wbf`, `flywheel-f589`, L71, and L80. DIVERGE reason: replacing flywheel callback shape would lose orchestrator-specific closure semantics. |
| IPC and transport contracts | Phase 1 `ipc-and-transport-contracts`; Phase 2 callback/CLI/robot hits | EXTEND | Adopt JSON/robot contract discipline, but map it to NTM, Agent Mail, and flywheel-specific callback validation instead of copying upstream transport shape. | dispatch template, NTM callback, Agent Mail receipts, canonical CLI registry | Existing bead `flywheel-ryzt` for CLI registry plus new `flywheel-f2bm` for Agent Mail dispatch receipt fields. |
| Idempotency, dry-run, lock files, append-only lineage | Phase 1 `idempotency-and-dry-run` and `append-only-audit-and-lineage`; Phase 2 `idempotency-key-fail-closed`, `lock-file-convention`, `append-only-audit-log` | EXTEND | These are one mutation-safety contract: idempotency key, lock owner/TTL, append-only receipt, backup/rollback, and storage headroom. Flywheel already has fragments; it needs one shared contract. | mutating scripts, state stores, lock repair, corpus compact/reindex, canonical CLI mutations | Existing bead `flywheel-l1vl`; no new bead because it covers idempotency, locks, append-only audit, backup, rollback, and storage precheck. |
| Frontmatter validation | Phase 2 `frontmatter-validation` in 160 repos | ADOPT | Flywheel relies on metadata in AGENTS.md, skills, commands, plans, and dispatch templates; frontmatter must be parsed structurally, not grepped. | L-rules, skills, slash commands, dispatch templates, README review | Existing bead `flywheel-0egk`; no new bead because frontmatter targets and a runnable check are explicit gates. |
| Subprocess orchestration and loop-driver drain receipts | Jeff-intel `03-subprocess-orchestration.md` | EXTEND | Long-running drivers need shutdown/drain evidence before restart or pause decisions. Current loop receipts prove ticks, not drain behavior. | launchd loop drivers, autoloop, worker drain/restart flows | New bead `flywheel-e7c2`. |
| SQLite / DB state-store authority | Jeff-intel `04-sqlite-db-patterns.md`; Phase 2 dual persistence and append-only lineage | EXTEND | State stores need declared source-of-truth, derived mirrors, backup, migration, integrity probe, and repair command. Canonical paths list artifacts, but not full authority contracts. | `.beads`, `.local/state/flywheel/*`, corpus manifests, dispatch logs | New bead `flywheel-94si`. |
| Agent Mail integration in dispatch receipts | Jeff-intel `05-agent-mail-integration.md`; L51/L84 doctrine | EXTEND | Dispatch validation should know whether Agent Mail file reservations and identities were actually used and released, without exposing tokens. | validation receipts, dispatch templates, worker callback evidence | New bead `flywheel-f2bm`. |
| Runtime parity proof matrix | Jeff-intel `07-cross-runtime-parity.md`; B11/q03g proof-level doctrine | EXTEND | Runtime claims need proof levels. `schema_only` can test rendering, but active-runtime parity requires live in-agent probe evidence. | parity probes, doctor proof-level distribution, cross-runtime docs | New bead `flywheel-8qix`. |
| Secret redaction gates | Jeff-intel `08-secrets-handling.md`; L58 token exposure doctrine | ADOPT | Evidence paths, callback logs, doctor JSON, and daily reports need canary fixtures so leaks fail mechanically. | validation artifacts, dispatch logs, doctor JSON, reports | Existing bead `flywheel-te36`; no new bead because it directly covers canary-secret fixture gates. |
| Canonical CLI surface registry | Jeff-intel `10-cli-canonical-scoping.md`; L82; Phase 2 CLI/robot patterns | ADOPT | Canonical CLI breadth should be generated or validated from one registry, otherwise every helper regresses differently. | flywheel CLIs, canonical CLI checks, README/canonical-paths | Existing bead `flywheel-ryzt`; no new bead because registry derivation is exactly its scope. |
| Jeff quality exemplars | Phase 3 top 20 led by `frankentui`, `frankensqlite`, `asupersync`, `coding_agent_session_search`, `ntm` | EXTEND | Use top-ranked repos as source exemplars for validation shape, not as copy-paste templates. Import invariant patterns only after 3+ independent examples. | Phase 5 promotions, skill drafts, candidate L-rules | Existing bead `flywheel-w3pr.3`; no new bead because Phase 5 owns staged skill/L-rule promotion. |
| Bottom-ranked conceptual/demo repos | Phase 3 bottom 20 with missing tests/docs/schema/doctor markers | AVOID | Many are essays, demos, generated artifacts, or tiny experiments. They can inform concept-space, but not operational substrate patterns unless separately validated. | synthesis filtering, future Jeff mining rubric | Explicit no-bead reason: not a flywheel implementation gap; this is a selection rule documented here. |
| Prose-only documentation as proof | Phase 3 caveats: 73 no test files, 74 no runnable test surface, 73 no schema markers, 64 no doctor markers | AVOID | Documentation without runnable validation is not a substrate. The three-Q audit requires validated, documented, and surfaced. | dispatch acceptance gates, README review, closure validation | Explicit no-bead reason: already canonical doctrine via three-Q memory, L71, L80, and README Gate 2 work. |
| One-off scripts without runnable repair/test surfaces | Phase 3 caveats: many repos contain single-purpose utilities without fixtures, schemas, doctor markers, or repair commands | AVOID | A one-off utility is useful source material, but it is not importable substrate until the behavior has a fixture, a repeatable validation command, and an owner-visible recovery path. | future mining rubric, implementation bead intake | Explicit no-bead reason: selection rule documented; file a bead only when the pattern repeats with runnable proof or when Flywheel owns the missing validation surface. |
| Generic success/status semantics | Phase 1/2 broad `status`, `ack`, `DONE` hits | DIVERGE | Flywheel has richer closure states than generic success: pass, fail, unknown, missing artifact, invalid callback, context drift, no-bead reason, tick-punted, and callback-delivery-verified. | validation schema, callback validation, worker closeout | No new bead: covered by validation-schema/v1 and `flywheel-esdx`; DIVERGE reason is preserving flywheel-specific failure states. |

## Existing Flywheel Surface Map
| flywheel surface | Jeff pattern imported | status |
|---|---|---|
| AGENTS.md L60/L71/L80/L82 | doctor contract, callback validation, DID/DIDNT/GAPS, canonical CLI scoping | already doctrine |
| AGENTS.md L58/L84 | token hygiene, durable Agent Mail worker identities | already doctrine |
| `.flywheel/validation-schema/v1` | receipt schema, fixtures, parser | already implemented by B01; extended by `flywheel-0egk` and `flywheel-esdx` |
| `.flywheel/scripts/validate-callback.py` | callback envelope validation | already implemented; preserve flywheel-specific callback fields |
| `.flywheel/scripts/verify-callback-delivery.sh` | callback delivery verification | already implemented; keep worker-side dogfood |
| `.flywheel/scripts/jeff-corpus-*` | corpus consumability, delta reindex, compaction, storage gating | already implemented; synthesis says keep storage preflight as non-optional |
| `.flywheel/canonical-paths.txt` | substrate registry | extend through implementation beads when new contracts land |
| `tests/` fixture harnesses | Jeff fixture/golden/conformance pattern | expand through `flywheel-0egk`, `flywheel-hn8e`, `flywheel-l1vl`, and new beads |

## Joshua Decision Points
| decision | why it adds friction | recommendation |
|---|---|---|
| Make runtime parity proof levels hard-fail or warn-first | Runtime probes can be flaky, but schema-only parity claims are dangerous. | Warn for `schema_only` for 7 days, then fail active-runtime parity claims unless `runtime_verified`; matches JD-002 graduated rule. |
| Require mutation-safety contract for every existing script immediately or only for new/changed scripts | Full backfill will create a large audit queue. | Apply hard gate to new/changed mutating scripts; audit two existing scripts in `flywheel-l1vl`, then expand by findings. |
| Treat Agent Mail reservation gaps as callback validation failure | Strict failure may slow read-only dispatches and small edits. | Fail only when dispatch declares edited files or multi-file scope; allow explicit `reservation_not_required` for read-only/single trivial work. |
| Promote Jeff patterns to L-rules now or stage first | Premature L-rule promotion can freeze a pattern before flywheel adaptation is tested. | Stage in `flywheel-w3pr.3` first; promote after at least one implementation bead validates the pattern locally. |

## Bead / No-Bead Receipts
| pattern group | receipt |
|---|---|
| fixture/schema/frontmatter | existing `flywheel-0egk` |
| doctor/health/repair triad | existing `flywheel-hn8e` |
| failure taxonomy | existing `flywheel-esdx` |
| secret redaction | existing `flywheel-te36` |
| canonical CLI registry | existing `flywheel-ryzt` |
| mutation safety: idempotency/lock/append-only/backup | existing `flywheel-l1vl` |
| callback verification | no new bead: existing `flywheel-0wbf`, `flywheel-f589`, L71, L80 |
| subprocess drain receipts | new `flywheel-e7c2` |
| state-store authority | new `flywheel-94si` |
| Agent Mail dispatch receipts | new `flywheel-f2bm` |
| runtime parity proof matrix | new `flywheel-8qix` |
| quality exemplar promotion | existing `flywheel-w3pr.3` |
| bottom-ranked conceptual repos | no_bead_reason=selection_rule_documented_not_implementation_gap |
| one-off scripts without runnable proof | no_bead_reason=selection_rule_documented_file_bead_only_when_pattern_repeats_with_validation_or_repair_surface |

## Three-Q Check On This Synthesis
- VALIDATED: source artifacts exist, manifest repo count is 177, final decision table covers Phase 1/2 repeated patterns plus per-query Jeff-intel artifacts, and new bead receipts exist.
- DOCUMENTED: this file is the decision ledger under `.flywheel/jeff-corpus/v1/learnings/`.
- SURFACED: implementation work is surfaced through existing and new `jeff-corpus-derived` beads, with Joshua decision points preserved for Phase 5/L-rule promotion.
