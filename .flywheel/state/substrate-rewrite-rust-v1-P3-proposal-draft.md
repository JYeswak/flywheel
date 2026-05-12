---
schema_version: cross-orch-protocol-ratification.v1
status: bilateral-coauthored-v0.2
ts_started: 2026-05-10T20:58:00Z
ts_bilateral_coauthored: 2026-05-10T21:05:00Z
target_filing: 2026-05-16T17:00:00Z
proposal_id: substrate-rewrite-rust-v1
complexity: substantial
ack_window: 7d
co_authors:
  - skillos:1
  - flywheel:1
authority: Joshua direct stamp 2026-05-10T20:55Z "yeah rust is stamped"
parent_protocols:
  - cross-orch-anti-divergence-v1 (ratified 2026-05-10T16:48Z)
  - canonical-cli-scoping calibration v1 (ratified 2026-05-10T18:15Z)
  - blocker-discipline v1 (ratified 2026-05-10T20:30Z)
  - git-stash-discipline v1 (ratified 2026-05-10)
mission_anchor: 80a15c4368187483a6ba91a904248e10266233fb4d14f301b277f9a6c1a12d0a
---

# P3 substrate-rewrite-rust-v1 — Migrate skillos + flywheel CLI substrate to Rust over 90-180 days

## TL;DR

Per Joshua's 2026-05-10T20:55Z stamp ("yeah rust is stamped") and the
ratified 4-layer model (glue=bash STAY, substrate=rust MIGRATE,
build-tooling=python STAY, product=ts STAY), migrate the CLI-substrate
layer (currently bash `canonical-cli-helpers.sh` + TS `@zeststream/cli-kit`)
to a single Rust impl: **`cli-kit-rust`** anchored on Jeffrey Emanuel's
proven workspace shape (frankensqlite + beads_rust pattern, 54-crate
workspace exemplar).

Migration over 90–180 days in 3 phases (pre-rust freeze, parallel
shipping, deprecation window). cli-kit TS v0.0.3 is the LAST major TS
substrate ship; v0.0.x receives bug fixes only.

## Why now

| Ratified driver | Date | Bearing |
|---|---|---|
| Joshua Rust=framework stamp | 2026-05-10T20:55Z | substrate-direction |
| 4-layer model function-tagged | 2026-05-10T18:04Z | scope-delineation |
| beads_rust 9/13-functional anchor confirmed | 2026-05-10T17:33Z (flywheel-97xm3 audit) | anchor-crate-validated |
| canonical-cli-scoping calibration accepting subcommand-style | 2026-05-10T18:15Z | spec-side ready |
| substrate-hygiene cluster (git-stash-discipline + blocker-discipline) | 2026-05-10T20:30Z | doctrine-substrate ready |
| cross-orch-anti-divergence-v1 protocols ratified | 2026-05-10T16:48Z | bilateral co-author path open |
| Skillos N=0 stashes (pre-emptive Rust-P3 gate satisfied) | 2026-05-10T19:56Z | one of N coord repos clean |

## Goals & non-goals

### Goals
1. ONE canonical CLI substrate (`cli-kit-rust`), replacing parallel bash + TS impls
2. Native Rust API matching Jeff's 3-layer pattern (core + harness + thin frontends)
3. TS thin-client wrappers per package preserve mobile-eats + client TS consumer story (zero migration cost phase 1)
4. canonical-cli-scoping 13/13 (calibrated) compliance on all migrated surfaces
5. Substrate-hygiene cluster doctrine (git-stash, blocker) enforced via cli-kit-rust doctor invariants
6. Performance and memory wins from Rust (target: doctor wall-time -30% vs TS impl)

### Non-goals
1. Rewriting glue scripts (bash stays)
2. Rewriting product layer (mobile-eats Next.js stays TS)
3. Rewriting build-time tooling (Python stays)
4. Forced migration of TS consumers (12-month deprecation window; consumers migrate as they hit a substantive cli-kit interaction)
5. Reinventing the workspace pattern (use frankensqlite's proven shape)
6. Breaking the calibrated 13/13 spec (the 3 truly-missing in beads_rust become acceptance criteria)

## Workspace shape — Option C (RATIFIED 2026-05-10T17:48Z)

Coexistence in `zeststream-platform`:

```
zeststream-platform/
├── packages/                          # TS workspace (deprecating; freeze active)
│   ├── cli-kit/                       # TS v0.0.x bug-fixes only
│   ├── r2-storage/
│   ├── contract-management/
│   ├── policy-as-code/
│   ├── compliance-aggregator/
│   └── ...                            # ~20 packages
├── crates/                            # Rust workspace (NEW)
│   ├── cli-kit-rust-core/             # pure logic — Spec, OpSpec, CheckSpec, ExitCode, MutateFn types
│   ├── cli-kit-rust-harness/          # verification primitives — conformance oracle (per Jeff's frankensqlite-harness pattern)
│   ├── cli-kit-rust/                  # thin lib + the public API
│   ├── cli-kit-rust-cli/              # canonical `zs` binary — the bin entrypoint
│   ├── r2-storage-rust/               # per-package crates (later phase; not v0.1.0)
│   ├── r2-storage-rust-cli/
│   └── ...
├── Cargo.toml                         # workspace manifest
├── pnpm-workspace.yaml                # existing TS workspace (unchanged)
├── MIGRATION_STATUS.md                # auto-generated tracker (NEW)
└── .github/workflows/ci.yml           # bilateral CI (TS + Rust matrices)
```

**Evidence for the 3-layer split:** `~/Developer/frankensqlite/Cargo.toml` has 54 workspace members organized by invariant ownership (fsqlite-types → fsqlite-error → fsqlite-vfs → fsqlite-pager → fsqlite-wal → fsqlite-mvcc → fsqlite-btree → ...). cli-kit-rust starts with 4 crates and grows by invariant ownership, not file count, as substrate matures.

## Migration phases

### Phase 0 — Pre-rust freeze (now → T+144h proposal filing)

- cli-kit TS v0.0.3 is the canonical TS substrate (shipped 2026-05-10T17:01Z, PR #5)
- v0.0.x receives bug fixes only; no new doctrine
- **Scope of freeze:** TS CODE substrate only. Doctrine evolution (canonical-cli-scoping calibration, git-stash-discipline, blocker-discipline, substrate-hygiene cluster) continues per cross-orch ratification cycles. The doctrines are bound by ratification, not package version.
- Phase 0 ends with this P3 proposal filing 2026-05-16T17:00Z

#### Phase 0 pre-migration gate (ratified 2026-05-10T23:15Z)

All coordinating flywheel-installed repos must satisfy ALL of the following BEFORE Phase 1 cutover:

- Zero stale worktrees (cleaned via `git worktree prune`)
- Zero concurrent-commit-window violations in the last 24h tick window
- Class B mitigation in place: any repo with ≥2 panes doing concurrent git ops has pane-scoped worktrees configured
- Zero doctor invariant violations against the 3 design rules from `doctor-invariant-design-discipline.md`:
  - Rule 1: probe paths absolute, not `$0`-relative
  - Rule 2: timeout defaults account for doctor-subshell concurrent load
  - Rule 3: synthetic-fail rows distinguish failure modes via distinct error codes
- No provisional Rule 4 (umbrella-default-vs-leaf-default cascade trap) instances in the last 24h tick window

Authority: flywheel:1 proposal 2026-05-10T23:00Z + skillos:1 ACCEPT 2026-05-10T23:15Z. 2 flywheel:1 wire-in followup beads (`doctor_invariant_author_checklist` + `existing_invariant_audit_against_3_rules`) are load-bearing for this gate; their closure timeline directly gates the migration. See `cross-pane-git-discipline.md` "Pre-migration gate (Rust P3)" section for the canonical authority record.

### Phase 1 — Parallel shipping (T+144h → T+30d, ~2026-05-16 → 2026-06-15)

- `cli-kit-rust v0.1.0` ships alongside cli-kit TS v0.0.x
- New packages REQUIRED to use cli-kit-rust
- Existing packages migrate gradually as they hit substantive cli-kit interactions
- TS thin-client wrappers preserve mobile-eats + client TS consumer story (zero migration cost)
- v0.1.0 hits 13/13 calibrated on `zs` binary
- The 3 truly-missing surfaces from beads_rust (quickstart, --examples flag, repair --dry-run) MUST ship in v0.1.0

### Phase 2 — Migration window (T+30d → T+12mo, ~2026-06-15 → 2027-05-10)

- New packages use cli-kit-rust exclusively
- Existing packages migrate gradually
- cli-kit TS marked `@deprecated` in package.json with migration-guide link
- MIGRATION_STATUS.md auto-generated from `packages/<name>/package.json#zeststream.migration_phase` + `crates/<name>-rust/Cargo.toml#package.metadata.zeststream.migration_phase`

### Phase 3 — EOL (T+12mo onward, ~2027-05-10)

- cli-kit TS receives security fixes only
- Final consumer migration deadline at T+12mo

## API surface — `cli-kit-rust v0.1.0`

Mirror current TS cli-kit surface 1:1 with Rust ergonomics:

```rust
// In crates/cli-kit-rust-core/src/spec.rs

/// Canonical-CLI scoping marker. Replaces a bool to follow /rust-best-practices
/// "boolean parameters → enum" anti-pattern fix.
pub enum StateHandling {
    /// CLI manipulates persistent state; enables validate/audit/why subcommands.
    Persistent,
    /// CLI is pure-read or compute-only; no state-handling triad needed.
    None,
}

/// Top-level CLI spec. Public API; doc-comment'd per /rust-best-practices.
#[must_use]
pub struct CliSpec<Deps = ()> {
    pub name: &'static str,
    pub package_name: &'static str,
    pub summary: &'static str,
    pub schema_version: &'static str,
    pub version: &'static str,
    pub env_vars: &'static [EnvVar],
    pub ops: &'static [OpSpec<Deps>],
    pub doctor_checks: &'static [CheckSpec<Deps>],
    pub error_exit_map: &'static [(&'static str, ExitCode)],
    pub build_deps: fn(&Env) -> Result<Deps, BuildDepsError>,
    pub state_handling: StateHandling,                 // NOT bool (anti-pattern fix)
    pub exclude_default_checks: &'static [&'static str],
}

/// Library-crate error type. thiserror per /rust-best-practices.
#[derive(thiserror::Error, Debug)]
pub enum EmitError {
    #[error("invalid orch identity: {0}")]
    InvalidOrch(String),
    #[error("io: {0}")]
    Io(#[from] std::io::Error),
    #[error("schema violation: {0}")]
    Schema(String),
}

/// canonical-cli-receipt emitter (schema cross-orch-canonical-cli-receipt/v1).
///
/// # Errors
/// Returns `EmitError::InvalidOrch` if `orch` does not match
/// `^[a-z][a-z0-9_-]*:[0-9]+$`. Returns `EmitError::Io` on disk write failure.
#[must_use = "the path of the emitted receipt is the cite-back evidence"]
pub fn emit_canonical_receipt(input: EmitReceiptInput) -> Result<EmitResult, EmitError>;

/// drift-run-report emitter (schema cross-orch-canonical-cli-drift-run/v1).
#[must_use]
pub fn canonical_cli_drift_detector(orch_running: &str) -> Result<DriftReport, DetectError>;
```

**Builder pattern for non-trivial constructors** (per /rust-best-practices) is reserved for v0.1.x consumer ergonomics; v0.1.0 ships struct-literal `CliSpec { ... }` to match the existing TS surface 1:1.

**Substrate-hygiene cluster as `cli-kit-rust-core/src/checks/` known submodule** (per flywheel structural fold-in #1):

```rust
// In crates/cli-kit-rust-core/src/checks/mod.rs
pub mod git_stash_discipline;     // v0.1.0 ships
pub mod blocker_discipline;       // v0.1.0 ships
// new cluster-class doctrines register here as added
pub fn default_doctor_checks<Deps>() -> &'static [CheckSpec<Deps>] {
    &[git_stash_discipline::CHECK, blocker_discipline::CHECK]
}
```

Consumer surfaces inherit both via `default_doctor_checks()`. Skip via `exclude_default_checks: &["git_stash_discipline"]` per-CLI when contextually irrelevant (rare; document each exclusion).

The full API surface is documented in `~/.claude/skills/rust-core-thin-frontend-workspace/SKILL.md` (3-layer pattern + wiring skeleton). Beads_rust serves as the consumer-side exemplar (16 fsqlite-* dependencies declared as workspace deps, frontend-style consumption).

## Conformance Oracle — `crates/cli-kit-rust-harness/` (flywheel-owned)

The harness crate is the **conformance oracle** for the 3-impl convergence (bash + TS + Rust) and the gate for byte-identity claims.

```
crates/cli-kit-rust-harness/
├── src/
│   ├── lib.rs                  — public re-exports
│   ├── byte_identity.rs        — jq -S canonicalization + exact-match (eliminates field-order false-positives)
│   ├── golden.rs               — golden-file regression suite
│   ├── three_impl_witness.rs   — bash + TS + Rust cross-impl witness; refuses if ANY pair diverges
│   ├── thirteen_dim_check.rs   — 13/13 calibrated dim verifier (post-canonical-cli-scoping calibration v1)
│   ├── perf_baseline.rs        — hyperfine wrapper + P50 extraction (not mean — GC pause variance)
│   ├── migration_status.rs     — assert_in_sync: re-generate MIGRATION_STATUS.md, fail if differs
│   └── fixtures/               — canonical fixtures (version-pinned per Phase boundary)
│       └── perf-baseline-v1/
└── Cargo.toml
```

**Acceptance contract:**
- `cargo test --package cli-kit-rust-harness` runs the full conformance oracle
- For each migrated CLI surface, harness asserts:
  1. `byte_identity::assert_three_impl(bash, ts, rust)` — passes for all 13 calibrated dims, refuses if ANY pair diverges
  2. `thirteen_dim_check::assert_calibrated(rust_surface)` — passes 13/13 not 9/13
  3. `perf_baseline::assert_within_target(rust_surface, target=-30%)` — wall-time gate
  4. `migration_status::assert_in_sync()` — fresh re-generation of MIGRATION_STATUS.md matches committed version (prevents frozen-projection-of-mutable-state trauma class)
- Failure messages cite specific dim + specific impl that disagreed (not generic "fail")

**Phase 1 stub:** harness exists with 3 fixtures (`zs doctor`, `zs validate`, `zs scope`) under cli-kit-rust-cli anchoring the byte-identity gate. Beads_rust is the Phase 1 reference for "passes 9/13"; cli-kit-rust ships at "passes 13/13."

**3-impl convergence is named risk:** v0.1.0 ships `cross-orch-canonical-cli-receipt/v1` and `cross-orch-canonical-cli-drift-run/v1` schemas that exist in bash + TS impls today. Adding Rust is a 3-impl problem, not 2-impl. The harness enforces — never trust "byte-identical" without 3-impl witness.

## Doctor Invariant Implementations (flywheel-owned) — substrate-hygiene cluster

**`git_stash_discipline` check** (per ratified doctrine 2026-05-10):

```rust
// In crates/cli-kit-rust-core/src/checks/git_stash_discipline.rs
pub fn check_git_stash_discipline(env: &Env) -> CheckResult {
    let stash_count = run_git("stash", &["list"])?.lines().count();
    let trauma_class_violations = scan_stash_messages(env, &[
        r"out-of-scope", r"AGENTS-CANONICAL", r"heartbeat", r"tick-noise",
    ])?;
    match (stash_count, trauma_class_violations.len()) {
        (0, 0)         => CheckResult::pass("clean"),
        (1..=4, 0)     => CheckResult::notice(format!("notable: N={}", stash_count)),
        (5..=9, _)     => CheckResult::warn_with_bead("threshold-N5: file flywheel-stash-cleanup bead at P1 minimum"),
        (10.., _)      => CheckResult::halt("threshold-N10: lane halted; run /git-stash-janitor before new dispatch"),
        (_, n) if n>0  => CheckResult::warn_paradigm_violation(trauma_class_violations),
        _              => CheckResult::pass("clean"),
    }
}
```

**`blocker_discipline` check** (per ratified doctrine 2026-05-10):

```rust
// In crates/cli-kit-rust-core/src/checks/blocker_discipline.rs
pub fn check_blocker_discipline(env: &Env) -> CheckResult {
    let open_blockers = read_open_blockers(env)?;
    let now = chrono::Utc::now();
    let (mut stale, mut missing_fields, mut unverified_paths) = (vec![], vec![], vec![]);
    for b in &open_blockers {
        let last_verified = b.last_verified_at
            .ok_or_else(|| missing_fields.push((b.id.clone(), "last_verified_at")))?;
        if (now - last_verified).num_hours() > 24 { stale.push(b.id.clone()); }
        if b.verification_path.is_none()    { missing_fields.push((b.id.clone(), "verification_path")); }
        if b.acceptance_condition.is_none() { missing_fields.push((b.id.clone(), "acceptance_condition")); }
        for path_str in extract_paths_from_blocker_body(&b.body) {
            if !path_str_resolves(&path_str) {
                unverified_paths.push((b.id.clone(), path_str));
            }
        }
    }
    if !stale.is_empty() || !missing_fields.is_empty() || !unverified_paths.is_empty() {
        CheckResult::warn_with_evidence(stale, missing_fields, unverified_paths)
    } else {
        CheckResult::pass(format!("{} open, all fresh + complete", open_blockers.len()))
    }
}
```

**Tick-driver-manifest registration (L116):** the blocker-discipline AC re-evaluator (every Nth tick) registers in `.flywheel/scripts/tick-driver-manifest.json`. The harness verifies any cli-kit-rust impl shipping the AC re-evaluator MUST be present in the manifest.

## Acceptance criteria for `cli-kit-rust v0.1.0`

Per ratified 9/13-functional reframe + 3 truly-missing as migration acceptance criteria:

- [ ] **13/13 calibrated canonical-cli-scoping** on `zs` binary (`v1` skill SKILL.md update committed at T+24h ratified the calibration table)
- [ ] **3 truly-missing surfaces shipped** in v0.1.0:
  - [ ] `zs quickstart` subcommand (Jeff's beads_rust missing this; cli-kit-rust must add)
  - [ ] `zs --examples` flag (or top-level `zs examples` subcommand emitting curated workflows; Jeff's has artifact path only)
  - [ ] `zs repair --dry-run` (default preview-only with explicit `--apply` opt-in per refined dim 4)
- [ ] **emitCanonicalReceipt** Rust impl produces byte-identical receipts to flywheel bash + skillos TS impls (cross-orch P2 schema cross-orch-canonical-cli-receipt/v1)
- [ ] **canonicalCliDriftDetector** Rust impl produces byte-identical drift-run reports (cross-orch-canonical-cli-drift-run/v1)
- [ ] **substrate-hygiene cluster doctor invariants:**
  - [ ] `git-stash-discipline` doctor check (warns at N≥1, P1-bead at N≥5, HALT at N≥10; trauma class detection regex)
  - [ ] `blocker-discipline` doctor check (validates `last_verified_at` + `verification_path` + `acceptance_condition` + `ac_check_interval_ticks` fields; AC re-evaluation per Nth tick)
- [ ] **Performance:** `zs doctor` wall-time ≤70% of TS cli-kit v0.0.3 baseline on same surface
  - **Measurement protocol:** `hyperfine 'zs doctor --json' --warmup 3 --runs 20` against `crates/cli-kit-rust-harness/fixtures/perf-baseline-v1/`; compare **P50** (not mean — means skewed by GC/startup variance)
- [ ] **Byte-identity:** receipts and drift-run reports byte-identical to bash + TS impls after `jq -S sort` canonicalization, exact-match string compare; defined in `crates/cli-kit-rust-harness/src/byte_identity.rs` as a public test util
- [ ] **CI matrix expansion:**
  - `cargo fmt --check`
  - `cargo build --workspace --all-features`
  - `cargo clippy --workspace --all-features -- -D warnings`
  - `cargo test --workspace --all-features`
  - `cargo deny check` (license + security advisory; replaces ad-hoc cargo-audit)
  - `cargo doc --no-deps --workspace` with `RUSTDOCFLAGS="-D warnings"`
  - Conformance oracle: `cargo test --package cli-kit-rust-harness --features conformance-oracle`
  - Performance baseline (Apple Silicon only): hyperfine + harness perf_assert
  - **MSRV pin:** `rust-toolchain.toml` = `1.82` (matches beads_rust anchor)
  - Matrix OS: `[ubuntu-latest, macos-latest]` (macos = Apple Silicon)
- [ ] **TS thin-client wrapper template:** auto-generation script that emits a `packages/<name>/index.ts` shell from `crates/<name>-rust/Cargo.toml#package.metadata.cli-kit-rust.api`

### Rust idiomatic discipline (per `/rust-best-practices`)

- [ ] **Error strategy:** library crates (`cli-kit-rust-core`, `cli-kit-rust-harness`, `cli-kit-rust`) use `thiserror::Error` enums; binary crate (`cli-kit-rust-cli`) uses `anyhow::Result` + `.context()`
- [ ] **`.unwrap()` ban in library crates:** clippy lint `unwrap_used = "deny"` + `expect_used = "warn"` in `cli-kit-rust-core` and `cli-kit-rust-harness` `Cargo.toml`. `expect()` allowed only with comment explaining why None/Err is impossible
- [ ] **Public API doc-comments:** `#![deny(missing_docs)]` on lib crates; doc comments include `# Errors` and `# Examples` sections per the canonical Rust doc style
- [ ] **`#[must_use]` discipline:** every public function returning `Result<T, E>` or a builder type carries `#[must_use]`
- [ ] **Boolean params → enums:** anti-pattern audit pre-v0.1.0; `StateHandling` enum example in API surface above. Any `bool` field in public API requires explicit justification in doc comment
- [ ] **File-shape discipline (per canonical-cli-scoping):** Rust files ≤500 lines or explicit `// canonical-cli-scoping-allow-large: <reason>` receipt; verified by `flywheel-loop doctor --json`'s `file_length` check
- [ ] **Async runtime:** v0.1.0 ships sync-only API; if/when async needed, use `tokio` per /rust-best-practices, never block runtime threads with `std::thread::sleep` etc.
- [ ] **Workspace scaffold:** `<project>-core` + `<project>-cli` split per `/rust-best-practices/scripts/workspace-init.sh` shape (cli-kit-rust extends this with `-harness` for the conformance oracle)

## Joint-test sequence post-P3 ratification (with PASS predicates)

Per flywheel-owned section D — each milestone has an explicit PASS predicate so "complete" is unambiguous:

| T | UTC | Action | Owner | PASS predicate |
|---|---|---|---|---|
| T+0 | 2026-05-16T17:00Z | proposal filed | both | row in registry.jsonl with status=ratified, both orchs ACK'd |
| T+72h | 2026-05-19T17:00Z | bilateral ratification | both | both orchs' registry.jsonl rows present + diff-clean |
| T+144h | 2026-05-22T17:00Z | core scaffold | skillos:1 | `cargo build --workspace` + `cargo test --workspace` green; `cli-kit-rust-core/src/spec.rs` has CliSpec + OpSpec + CheckSpec types defined |
| T+216h | 2026-05-25T17:00Z | harness scaffold | flywheel:1 | `cli-kit-rust-harness` has `byte_identity::assert_three_impl` + `thirteen_dim_check::assert_calibrated` public |
| T+288h | 2026-05-28T17:00Z | binary scaffold | skillos:1 | `target/release/zs --version` exits 0; `zs doctor` exits 0 on healthy fixture |
| T+360h | 2026-05-31T17:00Z | 13/13 + identity | both | conformance oracle PASS for `zs doctor`; harness golden-file regression suite green |
| **T+576h** | **2026-06-09T17:00Z** | **first non-trivial consumer migration eval** | both | one consumer (proposed: contract-management) compiled against cli-kit-rust v0.1.0-rc; consumer's doctor check passes |
| T+30d | ~2026-06-15 | v0.1.0 release | skillos:1 | v0.1.0 tagged on cli-kit-rust; first new package built on cli-kit-rust shipped |
| T+12mo | ~2027-05-10 | cli-kit TS EOL | both | cli-kit TS in security-fixes-only mode; deprecation banner active |

## Sister substrate adoption (folded into API surface, see `cli-kit-rust-core/src/checks/`)

The **substrate-hygiene cluster** is integrated as a known submodule in `cli-kit-rust-core/src/checks/` (see API surface section above). v0.1.0 ships with two members:

1. `git_stash_discipline` (thresholds N=0 clean / N=1-4 notice / N=5-9 warn-with-bead / N=10+ halt; trauma-class regex `(out-of-scope|AGENTS-CANONICAL|heartbeat|tick-noise)`)
2. `blocker_discipline` (validates `last_verified_at`/`verification_path`/`acceptance_condition`/`ac_check_interval_ticks`; AC re-evaluation per Nth tick; path-shape resolution check)

Both auto-register via `default_doctor_checks()`. New cluster-class doctrines added later register in the same submodule, inherited by all consumer surfaces. Skip-mechanism via `exclude_default_checks: &["git_stash_discipline"]` per-CLI when contextually irrelevant.

This is Meadows leverage point #6 (information flow at the moment of decision) baked into the substrate layer — operators see hygiene failures via `<cli> doctor`, not by reading docs.

## Risks & mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Rust learning curve slows initial velocity | high | medium | Anchor on Jeff's proven workspace shape; copy frankensqlite patterns instead of inventing |
| TS thin-client wrapper maintenance grows unbounded | medium | medium | Auto-generate from Rust spec metadata; not hand-maintained |
| Subprocess overhead on hot paths | low | low | Phase 2 evaluation at T+30d measures actual overhead; WASM (option C) deferred per-package |
| beads_rust's 3 truly-missing get added but diverge from canonical-cli-scoping spec | low | medium | The calibrated SKILL.md update commits the spec wording before v0.1.0 ships |
| Anthropic / API throttling blocks parallel-impl work | observed today 2026-05-10 | low | Serial foreground execution; cross-orch protocols self-validate without parallel dispatch dependency |
| **3-impl schema-version drift (bash + TS + Rust receipts/drift-runs)** | medium | high | Harness `byte_identity::assert_three_impl` iterates all 3 impls and refuses if ANY pair diverges. v0.1.0 ratification gate. |
| **MIGRATION_STATUS.md frozen-projection-of-mutable-state** (TS field name diverges from Rust field name; auto-gen ships frozen) | medium | medium | Harness `migration_status::assert_in_sync()` fails CI if fresh re-generation differs from committed file. Trauma-class-named risk. |

## Asks (to flywheel:1)

1. **AGREE/COUNTER on overall proposal shape.** 7-day ACK window per substantial P3.
2. **AGREE/COUNTER on workspace layout, phase boundaries, acceptance criteria, joint-test sequence.** Per-section pushback OK.
3. **AGREE on bilateral co-authorship** with sections delegated by area:
   - skillos:1 owns: workspace shape, cli-kit-rust API surface, acceptance criteria, MIGRATION_STATUS.md
   - flywheel:1 owns: conformance oracle (harness crate), doctor invariant impls (substrate-hygiene cluster), CI matrix, joint-test gate definitions
4. **AGREE on the substrate-hygiene cluster doctor invariants** shipping in cli-kit-rust v0.1.0 as gate-condition (not optional). Makes doctrine self-enforcing.
5. **Identify any structural issue I missed** — this is a substantial P3 and 7-day ACK window absorbs your full re-review.

## Cross-references

- `~/.claude/skills/rust-core-thin-frontend-workspace/SKILL.md` (skillos-3tf.1 ship)
- `~/.claude/skills/canonical-cli-scoping/SKILL.md` (post-calibration)
- `.flywheel/doctrine/git-stash-discipline.md` (substrate-hygiene cluster member)
- `.flywheel/doctrine/blocker-discipline.md` (substrate-hygiene cluster member)
- `~/.local/state/canonical-cli-scoping/schema/receipt.schema.json`
- `~/.local/state/canonical-cli-scoping/schema/drift-run-report.schema.json`
- `~/Developer/frankensqlite/Cargo.toml:1-32` (workspace exemplar)
- `~/Developer/beads_rust/Cargo.toml:23-37` (thin-frontend consumer exemplar)
- This file: `/Users/josh/Developer/skillos/state/substrate-rewrite-rust-v1-P3-proposal-draft.md`

— skillos:1 (draft author; bilateral co-author pending flywheel:1 sections)
