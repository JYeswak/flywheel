# Jeff Ecosystem Deep Dive — 05 Doctrine Comparison

**Snapshot:** 2026-05-01
**Task:** `jeff_eco_pane4`
**Sources:** local Jeff checkouts (`ntm`, `beads_rust`, `vibe-cockpit`, `frankensqlite`, `asupersync`), READMEs, Jeffrey's Skills.md fetch, flywheel `AGENTS.md` L48-L65.
**No patches or issue submissions.**

## Summary

Jeff's repo doctrine strongly converges with our safety and substrate rules: no deletion, explicit destructive-action approval, `main` branch, manual edits over script rewrites, no file proliferation, compile/test checks, robot-mode machine-readable surfaces, beads + agent-mail pairing, and CASS-style memory reuse.

The main NEW-TO-US rules worth adopting are stricter file-deletion language, "no script-based code changes," "no file proliferation," strict robot/TUI boundary language, and explicit cancel-correct/no-orphan-task doctrine from asupersync. The main intentional divergence is backward compatibility: Jeff's local repos say early development means no compatibility shims; flywheel has live fleet repos and must preserve compatibility at operational boundaries.

## ntm/AGENTS.md

- **Rule:** "If I tell you to do something... YOU MUST LISTEN TO ME" (`ntm/AGENTS.md:9-12`)
- **Category:** CONVERGENT
- **Mapping:** Joshua override semantics in flywheel doctrine; L48 has `JOSHUA_OVERRIDE` for one-shot escalation override (`AGENTS.md:77-80`).
- **Action:** NOTE

- **Rule:** "NO FILE DELETION... NEVER ALLOWED TO DELETE A FILE WITHOUT EXPRESS PERMISSION" (`ntm/AGENTS.md:15-19`)
- **Category:** NEW-TO-US
- **Mapping:** We ban destructive commands generally, but no L-rule says every file deletion requires written permission.
- **Action:** ADOPT

- **Rule:** Irreversible commands require exact user command, explicit consequence acknowledgment, verbatim plan, and documented confirmation (`ntm/AGENTS.md:23-30`)
- **Category:** CONVERGENT
- **Mapping:** DCG hard rule in user doctrine; CLAUDE safety axiom; L48 probe-ledger spirit.
- **Action:** NOTE

- **Rule:** "ONLY Use `main`, NEVER `master`" and keep `master` synchronized for legacy URLs (`ntm/AGENTS.md:33-47`)
- **Category:** NEW-TO-US
- **Mapping:** No canonical flywheel L-rule for branch naming or legacy branch mirroring.
- **Action:** ADOPT if repo-local; do not force on third-party/client repos without audit.

- **Rule:** "No Script-Based Changes" (`ntm/AGENTS.md:98-106`)
- **Category:** NEW-TO-US
- **Mapping:** We prefer `apply_patch` and cautious edits, but do not explicitly ban repo-wide script rewrites.
- **Action:** ADOPT for code files; allow generated data/test fixtures only with explicit scope.

- **Rule:** "No File Proliferation" (`ntm/AGENTS.md:108-118`)
- **Category:** NEW-TO-US
- **Mapping:** Our style says scoped edits and avoid needless abstractions, but not a hard rule.
- **Action:** ADOPT

- **Rule:** "We do not care about backwards compatibility... early development" (`ntm/AGENTS.md:121-127`)
- **Category:** DIVERGENT-INTENTIONAL
- **Mapping:** Flywheel runs live orchestration across client and fleet repos; compatibility at command/file contracts is operational safety.
- **Action:** DOCUMENT-DIVERGENCE

- **Rule:** Robot commands have JSON stdout, diagnostic stderr, defined exit codes, and required arrays (`ntm/AGENTS.md:259-299`)
- **Category:** CONVERGENT
- **Mapping:** L50 dispatch callbacks require machine-verifiable fields (`AGENTS.md:143-159`); receipt validation is central to flywheel-loop.
- **Action:** ADOPT as wording template for flywheel commands.

- **Rule:** Agent Mail provides identities, inbox/outbox, searchable threads, and file reservations (`ntm/AGENTS.md:349-359`)
- **Category:** CONVERGENT
- **Mapping:** L51 file reservations (`AGENTS.md:177-204`), L61 dual-channel (`AGENTS.md:424-437`), L65 fleet-mail (`AGENTS.md:459-476`).
- **Action:** NOTE

- **Rule:** Beads are single source of truth for task state; Agent Mail for conversation/audit; share bead IDs as mail thread IDs (`ntm/AGENTS.md:429-470`)
- **Category:** CONVERGENT
- **Mapping:** L52 issues-to-beads (`AGENTS.md:207-241`), L51 reservations.
- **Action:** NOTE

- **Rule:** `bv --robot-triage` is the graph-aware entry point; bare TUI blocks sessions (`ntm/AGENTS.md:495-516`)
- **Category:** CONVERGENT
- **Mapping:** L52 requires beaded findings; our dispatches already prefer robot surfaces.
- **Action:** ADOPT the "bare TUI blocks automated sessions" phrasing.

- **Rule:** `cass` avoids re-solving prior agent work; use robot/json (`ntm/AGENTS.md:728-752`)
- **Category:** CONVERGENT
- **Mapping:** L50 Socraticode mandatory; L54 skill deep-dive before blocked.
- **Action:** NOTE

## beads_rust/AGENTS.md

- **Rule:** No file deletion without written permission (`beads_rust/AGENTS.md:15-19`)
- **Category:** NEW-TO-US
- **Mapping:** Same as ntm; stronger than our current deletion stance.
- **Action:** ADOPT once canonicalized.

- **Rule:** Rust-only Cargo toolchain, explicit versions, zero unsafe code, single crate (`beads_rust/AGENTS.md:50-58`)
- **Category:** CONVERGENT
- **Mapping:** Repo-local engineering convention; not universal flywheel doctrine.
- **Action:** NOTE

- **Rule:** No script-based changes and no file proliferation (`beads_rust/AGENTS.md:93-112`)
- **Category:** NEW-TO-US
- **Mapping:** Our code-editing policy is close but softer.
- **Action:** ADOPT

- **Rule:** Non-invasive by design: `br` never executes git commands automatically (`beads_rust/AGENTS.md:352-355`, `beads_rust/README.md:122-131`)
- **Category:** CONVERGENT
- **Mapping:** L52 requires beads but still keeps git/commit responsibility explicit.
- **Action:** NOTE; use as evidence for doctor messages around `.beads/` sync.

- **Rule:** SQLite + JSONL hybrid, append-only audit log, hash-based IDs (`beads_rust/AGENTS.md:355-362`)
- **Category:** CONVERGENT
- **Mapping:** L52 durable issue substrate; L56 evidence ladder.
- **Action:** NOTE

- **Rule:** Sync safety checklist: no git operations, path allowlist, run safety tests, review logs (`beads_rust/AGENTS.md:368-384`)
- **Category:** NEW-TO-US
- **Mapping:** We have tests and doctor, but no equivalent checklist for flywheel `.flywheel/` sync/reconcile.
- **Action:** ADOPT as a template for flywheel reconcile/test docs.

## vibe-cockpit/AGENTS.md

- **Rule:** No file deletion without written permission (`vibe-cockpit/AGENTS.md:13-17`)
- **Category:** NEW-TO-US
- **Mapping:** Same deletion gap.
- **Action:** ADOPT

- **Rule:** Primary async runtime is Asupersync with Tokio compat bridge for tokio-locked crates (`vibe-cockpit/AGENTS.md:57-60`)
- **Category:** NEW-TO-US
- **Mapping:** Flywheel has no runtime doctrine; most primitives are shell/Python.
- **Action:** NOTE for future Rust daemons; WAIT for existing flywheel-loop.

- **Rule:** DuckDB over SQLite for analytical workloads (`vibe-cockpit/AGENTS.md:382-385`)
- **Category:** CONVERGENT
- **Mapping:** This matches fleet observatory analytical needs, but current vc collector failure blocks adoption.
- **Action:** NOTE

- **Rule:** Fail-soft collectors, timeout-bounded collection, idempotent inserts, versioned collector output (`vibe-cockpit/AGENTS.md:386-391`)
- **Category:** NEW-TO-US
- **Mapping:** L63 recovery rehearsal and doctor probes imply this, but do not state collector design law.
- **Action:** ADOPT for flywheel health daemons.

- **Rule:** Robot mode exposes the same data to agents via JSON CLI (`vibe-cockpit/AGENTS.md:355-362`, `vibe-cockpit/AGENTS.md:392-394`)
- **Category:** CONVERGENT
- **Mapping:** L50/L52 callback contracts and flywheel-loop JSON/receipt behavior.
- **Action:** NOTE

- **Rule:** vc collects from ntm, br, bv, dcg, process triage, mcp_agent_mail, etc. (`vibe-cockpit/AGENTS.md:319-337`)
- **Category:** CONVERGENT
- **Mapping:** Hive doctrine wants one observability substrate (`AGENTS.md:405-414`).
- **Action:** ENHANCE after beads collector gap is fixed.

## frankensqlite/AGENTS.md

- **Rule:** asupersync mandatory, no Tokio ecosystem; async functions take `&Cx` (`frankensqlite/AGENTS.md:59-70`)
- **Category:** NEW-TO-US
- **Mapping:** Flywheel has no explicit structured-concurrency/capability-context rule.
- **Action:** NOTE for future Rust; do not retrofit shell/Python loop.

- **Rule:** Concurrent-writer mode is the entire point; do not touch (`frankensqlite/AGENTS.md:263-287`)
- **Category:** CONVERGENT
- **Mapping:** Reliability-invariant and L48 substrate-exhaustion: do not undermine core substrate guarantees.
- **Action:** NOTE

- **Rule:** Key design: page-level MVCC, `BEGIN` auto-promotes to concurrent, WAL crash recovery, conformance testing, property/snapshot testing (`frankensqlite/AGENTS.md:363-375`)
- **Category:** NEW-TO-US
- **Mapping:** Not flywheel doctrine, but directly relevant to future br/agent-mail storage.
- **Action:** WAIT until frankensqlite runtime status matures.

- **Rule:** README states current runtime is hybrid and native/ECS sections are design/partial implementation (`frankensqlite/README.md:138-152`)
- **Category:** CONVERGENT
- **Mapping:** Our Jeff issue protocol requires distinguishing live behavior from target design.
- **Action:** ADOPT this "current status before claims" pattern in our audits.

- **Rule:** Multi-process swarm users should read `docs/concurrency-contract.md`; supported/unsupported shapes are explicit (`frankensqlite/README.md:184-194`)
- **Category:** NEW-TO-US
- **Mapping:** We need a similar contract for flywheel daemon/file/mail surfaces.
- **Action:** ADOPT as a template for recovery/doctor substrate contracts.

## asupersync/AGENTS.md

- **Rule:** Runtime forbids orphan tasks, cancellation data loss, ambient authority; all effects flow through explicit `Cx` (`asupersync/AGENTS.md:59-71`)
- **Category:** NEW-TO-US
- **Mapping:** L48/L63 address operational escalation/recovery, not structured runtime semantics.
- **Action:** ADOPT conceptually for future daemons.

- **Rule:** Dependency policy: do not introduce another executor/runtime into core; preserve deterministic lab runtime (`asupersync/AGENTS.md:73-79`)
- **Category:** NEW-TO-US
- **Mapping:** No flywheel equivalent.
- **Action:** NOTE

- **Rule:** Core code should not write to stdout/stderr; use structured tracing and deterministic test logs (`asupersync/AGENTS.md:176-183`)
- **Category:** NEW-TO-US
- **Mapping:** We have JSON command contracts but not a library-output doctrine.
- **Action:** ADOPT for any flywheel libraries/daemons.

- **Rule:** Tests must assert no task leaks, no obligation leaks, losers drained, region close implies quiescence (`asupersync/AGENTS.md:214-220`)
- **Category:** NEW-TO-US
- **Mapping:** L63 recovery drills are operational; this is unit-level concurrency proof discipline.
- **Action:** ADOPT for Rust daemons.

- **Rule:** Asupersync README: correctness is structural, cancellation is a protocol, effects require capabilities, lab runtime is deterministic (`asupersync/README.md:28-47`)
- **Category:** NEW-TO-US
- **Mapping:** Strongly aligned with flywheel's reliability-invariant axiom.
- **Action:** ADOPT as vocabulary for future recovery primitives.

## Jeffrey's Skills.md

- **Rule:** Site frames skills as "Professionally crafted skills for Claude Code, Codex, and other AI agents" with `jsm` sync, and presents UBS/CASS/BV/NTM as creator lineage (fetched homepage metadata/body).
- **Category:** CONVERGENT
- **Mapping:** Our "reuse before build" doctrine and L54 skill-deep-dive; L62 adds our missing telemetry row.
- **Action:** NOTE; do not duplicate marketplace mechanics inside flywheel.

## Recommended Adoptions

1. **Canonical no-deletion-without-written-permission rule.** Highest safety value, low effort, converges across all Jeff repos. Map to DCG/flywheel doctor as an explicit L-rule candidate.

2. **No script-based code rewrites.** Adopt as a code-file rule with a narrow exception for generated artifacts and explicit mechanical migrations. This directly reduces high-blast-radius agent edits.

3. **No file proliferation.** Add canonical language: revise existing code in place unless the new file is genuinely new functionality. This aligns with our anti-bloat posture.

4. **Robot/TUI boundary wording.** "Bare TUI blocks automated sessions" should become flywheel command doctrine wherever a tool has both interactive and robot modes.

5. **Fail-soft, timeout-bounded, idempotent collectors.** Lift from vibe-cockpit into flywheel health daemon standards; it directly supports L63 recovery rehearsal and observability reliability.

## Divergences to Document

- **Backward compatibility:** Jeff's early-development repos explicitly reject shims (`ntm/AGENTS.md:121-127`). Flywheel should not adopt this globally because it coordinates live client/fleet state. Use repo-local adoption only.
- **Async runtime purity:** asupersync/frankensqlite should guide future Rust daemons, but retrofitting flywheel-loop away from shell/Python would be churn without immediate substrate value.
- **DuckDB to frankensqlite:** vc uses DuckDB today for analytics (`vibe-cockpit/AGENTS.md:382-385`); frankensqlite is promising but hybrid/partial (`frankensqlite/README.md:138-152`). Wait for mature storage boundaries before migration.
