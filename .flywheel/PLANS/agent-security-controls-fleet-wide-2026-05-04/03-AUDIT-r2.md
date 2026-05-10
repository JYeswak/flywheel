---
title: "Phase 3 AUDIT r2 — Convergence Pass"
type: plan
created: 2026-05-04
frontmatter_source: scaffold-doc-frontmatter
---

# Phase 3 AUDIT r2 — Convergence Pass

Plan: `agent-security-controls-fleet-wide-2026-05-04`
Input: `.flywheel/plans/agent-security-controls-fleet-wide-2026-05-04/00-PLAN.md`
Round: r2 consolidated audit
ladder_passed: yes

## 1. r1 Finding Index

| id | class | severity | location | one-line attack vector |
|---|---|---|---|---|
| F1 | override-bypass | high | settings deny block / B01 / L74 | Broad or malformed `canonical-security-allow` receipt neutralizes deny rules for live secret paths. |
| F2 | runtime-output leak | high | leak vectors / runtime safety / B06 | Parent env or test-framework passthrough leaks live-shaped tokens despite clean `.env.test`. |
| F3 | singleton-trust | high | executive summary / settings block / open questions | Higher-precedence local settings allow a read while canonical repo settings appear present. |
| F4 | token-in-prose | medium | doctor signals / B04 / B05 | Promotion or daily-report prose rehydrates raw matched secret evidence. |
| F5 | migration-window | medium | rollout / propagation / rollout plan | Unsynced repos remain exploitable while sequential rollout protects only part of the fleet. |
| F6 | pre-commit hook bypass | medium | pre-commit / B07 / doctor signals | `--no-verify`, hooksPath drift, or non-commit writes bypass hook-only scanning. |
| F7 | container escape | high | container isolation / B08 / coverage matrix | Sandbox rejects `.env` but still permits home credential stores or host profile mounts. |
| F8 | cross-orch token capture | high | problem statement / coverage matrix / Lane B cross-check | Dispatch files, callbacks, and xpane payloads persist token-shaped prose before scrollback scrub catches it. |
| F9 | MCP-spawned process leak | medium | leak vector / cross-cutting / coverage / open questions | MCP child process inherits token env/profile and logs it outside config-file scanning. |
| F10 | weak-default | medium | contract / receipt freshness / B03 / B09 | Long-running mutation continues under a marker that expires mid-execution. |
| I1 | re-apply safety | high | settings block / propagation / B03 | Re-running apply duplicates deny-array entries or reorders settings and creates false drift. |
| I2 | partial-failure resume | high | rollout / propagation / B03 / rollout plan | Rerun after partial fleet failure duplicates successful repo work or skips failed repos. |
| I3 | receipt collision | medium | contract / receipt freshness / B03 / B09 | Two valid markers authorize overlapping bounded mutations with competing receipts. |
| I4 | doctor signal idempotency | medium | doctor signals / B04 / B05 | Same input doctor runs differ by volatile fields and trigger repeated promotion. |
| I5 | override receipt churn | medium | override pattern / B01 / B04 | Add/remove/re-add override histories produce different active-state doctor output. |
| I6 | pre-commit hook re-install | medium | pre-commit / B07 / doctor signals | Reinstall appends duplicate hook invocations or clobbers unmanaged hook content. |
| I7 | bead promotion replay | high | B05 / doctor signal table | Same doctor failure creates multiple auto-doctor beads because dedupe key is unspecified. |
| I8 | migration replay | medium | propagation / B03 / rollout plan | Already-protected repo replay overwrites metadata, backup refs, or rollback guards. |
| I9 | validation receipt overwrite | high | B03 / B09 / Three-Q | Parallel workers interleave or overwrite the same validation receipt path. |
| I10 | cross-runtime drift | medium | cross-cutting / settings / open questions | Claude and Codex render logically equivalent settings with different bytes/hashes. |
| P1 | settings.json shape parity | high | executive summary / settings / cross-cutting / open questions | Claude deny rules block reads while Codex or MCP ignores the same `settings.json`. |
| P2 | pre-commit hook runtime asymmetry | medium | pre-commit / B07 / coverage | Codex or MCP writes token-bearing files without a commit path, so hooks never run. |
| P3 | auth-marker expiry clock skew | medium | contract / receipt freshness / B03 / B09 | Marker is valid in one runtime and expired in another due to clock/source skew. |
| P4 | override receipt bypass per-runtime | high | override pattern / B01 / B04 | Codex and Claude normalize the same override path differently. |
| P5 | doctor output parity | medium | doctor signals / B04 / B09 | One runtime emits booleans/arrays differently and downstream `jq` logic diverges. |
| P6 | MCP-spawned process leak parity | high | leak vector / cross-cutting / coverage / B08 | MCP helper reads or logs secrets outside Claude deny-rule enforcement. |
| P7 | agent-mail token transit parity | high | problem statement / doctor signal / Lane B cross-check | Claude, Codex, and MCP agent-mail paths redact different callback or stderr substrates. |
| P8 | container isolation scope | medium | container isolation / B08 / L74 | Sandbox profile applies to bead workers but not orchestrator panes or MCP helpers. |
| P9 | conformance harness coverage | high | B09 / Three-Q / open questions | Shell-only conformance passes while Codex or MCP runtime remains untested. |
| P10 | xpane cross-orch leakage | high | problem statement / coverage / rollout | Cross-pane payload leaves protected Claude context and persists in less-protected runtime. |

## 2. Re-Audit Pass

Skills consulted:

- `jeff-convergence-audit`: strict new-finding discipline and two-zero convergence rule.
- `security-audit-for-saas`: fail-open, duplicate-parser, normalization, shadow recovery-path, and surface-expansion axioms.
- `testing-conformance-harnesses`: MUST coverage, fail-closed skipped checks, real-artifact rule.
- `safe-migrations`: rollback, validation, and partial rollout semantics.
- `agent-fungibility-philosophy`: runtime fungibility requirement across Claude/Codex/MCP workers.

Socraticode queries:

- `agent security audit convergence cross finding interactions override idempotency runtime parity new critical findings`
- `security control plan audit synthesis findings interaction duplicate finding convergence no new critical`

Hunt classes re-checked against `00-PLAN.md`:

- Override and receipt surfaces: covered by F1, I3, I5, P4.
- Runtime output, prose, and token transit surfaces: covered by F2, F4, P7, P10.
- Settings precedence, runtime parity, and serializer drift: covered by F3, I10, P1, P5.
- Rollout, replay, migration-window, and partial-failure resume: covered by F5, I1, I2, I8.
- Hook bypass and in-process runtime writes: covered by F6, I6, P2.
- Container, MCP subprocess, and orchestrator/helper sandbox scope: covered by F7, F9, P6, P8.
- Marker expiry, clock skew, and mid-run bounded mutation semantics: covered by F10, P3.
- Conformance and validation receipt reliability: covered by I9, P9.
- Auto-promotion replay and duplicate surfacing: covered by I4, I7.

Rejected candidate notes:

- Symlink/case-normalized path bypass is not new: F1 requires exact normalized path matching, F3 covers settings-surface precedence, and P4 covers per-runtime path normalization.
- CI-less local file writes are not new: F6 covers hook bypass and P2 covers runtime writes outside commit flow.
- Stale or cached pane truth is not new for this plan: F8/P10 cover persisted cross-orch payloads, while P9 requires runtime-context proof instead of shell-only evidence.
- Fixture allowlist poisoning is not new: F2 covers poisoned runtime fixture output, F4 covers token-in-prose downstream rehydration, and B09 amendments are already the mitigation surface.
- Duplicate auto-beads across doctor retries are not new: I7 is exactly the replay class, with I4 covering volatile doctor output as the producer cause.

## 3. NEW Findings

findings_total: 0
findings_critical: 0
findings_high: 0

No genuinely new critical, high, medium, or low findings were identified. All candidate findings either restated a r1 finding or combined r1 findings into an interaction already covered by existing amendment surfaces.

## 4. Cross-Finding Interactions

### X1 — Override Replay And Runtime Parser Amplification

Findings: F1 + I3 + I5 + P4

Interaction: A broad override is dangerous on its own, but it becomes worse when two markers authorize competing mutations, override event history churns, and Claude/Codex normalize the path differently.

Synthesis amendment: B01/B04/B09 should treat override validation, idempotency keying, tombstone projection, and runtime parser parity as one conformance group, not separate optional tests.

New finding? no. Covered by F1/I3/I5/P4.

### X2 — Runtime Leak Hidden By Shell-Only Conformance

Findings: F2 + F4 + P7 + P9

Interaction: Runtime-output leakage can pass if the conformance harness only runs from the orchestrator shell and promotion/daily-report consumers are not tested with poisoned callback and agent-mail substrates.

Synthesis amendment: B06/B09 should require the poisoned-env fixture to flow through Claude callback, Codex callback, MCP agent-mail error path, receipts, and promotion output.

New finding? no. Covered by F2/F4/P7/P9.

### X3 — Partial Rollout Plus Cross-Orch Lateral Movement

Findings: F5 + I2 + I8 + P1 + P10

Interaction: Sequential rollout plus incomplete resume semantics can leave some repos unprotected; cross-runtime payloads can then carry sensitive context from protected to unprotected runtimes.

Synthesis amendment: B03/B04/B09 should couple fleet rollout state with runtime destination metadata and block or dry-run dispatch into unsynced repos.

New finding? no. Covered by F5/I2/I8/P1/P10.

### X4 — MCP Helper Escapes Both Settings And Sandbox

Findings: F7 + F9 + P6 + P8

Interaction: MCP subprocesses can bypass both Claude settings denies and bead-worker sandbox assumptions if their own process tree, mounts, and env are not treated as a runtime scope.

Synthesis amendment: B08/B09 should include MCP as a first-class runtime in the denied mount matrix, process-tree fixture, and sandbox applicability matrix.

New finding? no. Covered by F7/F9/P6/P8.

### X5 — Unstable Doctor Output Creates Duplicate Unsafe Work

Findings: F4 + I4 + I7 + I9 + P5

Interaction: Non-deterministic doctor JSON can create duplicate promotion work; if promotion descriptions or validation receipts are not atomic/redacted, duplicate work can persist raw evidence or overwrite the proof trail.

Synthesis amendment: B04/B05/B09 should share one deterministic signal schema, promotion idempotency key, redacted output contract, and atomic receipt manifest.

New finding? no. Covered by F4/I4/I7/I9/P5.

## 5. Convergence Verdict

convergence: yes

r1 produced `0` critical findings. r2 produced `0` new critical findings. Per the dispatch convergence test, Phase 3 AUDIT has two consecutive rounds with zero new critical findings and is converged.

New findings:

- findings_new: 0
- findings_new_critical: 0
- findings_new_high: 0

## 6. Three-Q Audit

VALIDATED:

- All three r1 artifacts were read before this r2 artifact was written.
- The 30-row finding index includes id, class, severity, location, and one-line attack vector.
- Candidate findings were checked against r1 coverage before being rejected as not new.
- Socraticode was queried twice for local convergence, parity, duplicate-capture, and idempotency precedents.

DOCUMENTED:

- Cross-finding interactions are recorded separately from new findings.
- Each interaction lists the r1 findings that already cover it and the bead-amendment synthesis surface.
- The convergence verdict names the strict rule: two consecutive rounds with `0` new critical findings.

SURFACED:

- Phase 3 synthesis should consolidate r1 findings plus the five interaction groups into Phase 4 bead amendments.
- No Joshua-disposes pause is required for new critical findings from r2 because there are none; existing r1 Joshua decisions still remain for synthesis.

## 7. Ladder Check

Plan-space only:

- No settings mutations.
- No source implementation edits.
- No bead creation.
- No commits.
- Output artifact only: `.flywheel/plans/agent-security-controls-fleet-wide-2026-05-04/03-AUDIT-r2.md`.

Ladder verdict: `ladder_passed=yes`.
