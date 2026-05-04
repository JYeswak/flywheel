# Phase 3 AUDIT r1 Lens 3 — Cross-Runtime Parity

Plan: `agent-security-controls-fleet-wide-2026-05-04`
Input: `.flywheel/plans/agent-security-controls-fleet-wide-2026-05-04/00-PLAN.md`
Lens: cross-runtime parity only
ladder_passed: yes

## 1. Skills And Socraticode Queries Used

Skills consulted:

- `jeff-convergence-audit`: Phase 1 broad-sweep finding discipline.
- `testing-conformance-harnesses`: runtime matrix, MUST-clause coverage, and golden parity checks.
- `codex-cli-tracker`: Codex panes are first-class infra with pinned versions and runtime-specific recovery limits.
- `mcp-server-design`: MCP tools need explicit target-agent design, capability gating, validation, and observability.
- `mcp-secret-scanner`: Claude/Codex MCP config parity and scanner limits.
- `canonical-cli-scoping`: doctor/health/repair, schema output, JSON stability, and dry-run discipline for new probes.
- `agent-fungibility-philosophy`: workers are meant to be interchangeable across runtimes, so controls cannot be runtime-local.

Socraticode queries:

- `cross runtime parity Claude Codex MCP settings deny rules doctor output conformance harness`
- `agent context parity codex claude mcp token redaction cross pane payload security`

Local precedent surfaced:

- `agent-context-parity-probe.py` and `tests/agent-context-parity-probe.sh` already separate Claude Bash-context proof from Codex ntm-send callback proof.
- `orch-capture-parity-probe.py` fixtures model runtime rows separately and treat raw pane scrollback alone as a gap.
- README documents that Claude-only proof cannot satisfy Codex-required runtime surfaces.

## 2. Findings

### P1

finding_id: P1
severity: high
class: Settings.json shape parity
location: `00-PLAN.md` Executive Summary line 9; Canonical Settings Deny Block lines 82-86; cross-cutting conclusions lines 70-74; open questions lines 388-392
description: The plan renders a canonical Claude settings deny block, but it does not define equivalent Codex or MCP enforcement semantics. It risks treating `settings.json` presence as fleet security even though Codex and MCP servers may ignore that file or use different glob/path grammar.
attack_vector: Claude rejects `.env` reads via `permissions.deny`, while a Codex worker or MCP-spawned tool reads the same path because its runtime never consumed the Claude settings block.
mitigation: Amend B01/B03/B09: define a runtime matrix for Claude, Codex, and MCP with settings source, glob semantics, and expected enforcement result; add golden fixtures proving `.env*`, `.ssh/**`, and `.mcp.json` reads fail or are marked `unsupported_runtime_gap` per runtime.
joshua_decision_needed: yes
joshua_question: Should unsupported Codex/MCP deny-rule enforcement block rollout, or be allowed as a named red `unsupported_runtime_gap` until a guard exists?

### P2

finding_id: P2
severity: medium
class: Pre-commit hook runtime asymmetry
location: `00-PLAN.md` Pre-Commit lines 96-98; B07 lines 272-277; coverage matrix line 356
description: B07 validates commit-time hooks, but runtimes can write files outside a git commit path. Claude shell edits, Codex tools, and MCP in-process writers may mutate the workspace without triggering `core.hooksPath` at all.
attack_vector: A Codex or MCP tool writes a token-bearing `.env.generated` file and hands off via callback without committing; the pre-commit hook never runs, and the runtime is still reported as hook-protected.
mitigation: Amend B07/B09: require an independent workspace scanner in doctor/validate/fleet-smoke that runs after each runtime writes fixture files; fixtures must include Claude shell write, Codex patch/write, and MCP tool write paths and assert identical detection.
joshua_decision_needed: no
joshua_question: n/a

### P3

finding_id: P3
severity: medium
class: Auth-marker expiry clock skew
location: `00-PLAN.md` Canonical Contract line 80; receipt freshness signal line 121; B03 lines 198-199; B09 lines 311-317
description: The plan includes issued/expires metadata and receipt freshness, but it does not require a shared UTC source or clock-skew tolerance across Claude, Codex, and MCP processes. A marker can be valid in one runtime and expired in another.
attack_vector: Claude issues a bounded security marker at one local clock, a Codex pane validates with a skewed pane environment or stale fixture time, and the same mutation is accepted by one runtime while rejected by another.
mitigation: Amend B01/B03/B09: require UTC RFC3339 timestamps, monotonic operation age where available, `clock_source` in receipts, max skew tolerance, and fixtures with skewed Claude/Codex/MCP clocks proving expiry decisions are consistent.
joshua_decision_needed: no
joshua_question: n/a

### P4

finding_id: P4
severity: high
class: Override-receipt-bypass per-runtime
location: `00-PLAN.md` override pattern line 86; B01 lines 156-161; B04 lines 214-220
description: Override receipts are not tied to a runtime identity or parser. A Codex worker can write a JSONL receipt that Claude's checker treats as valid, or vice versa, even if the originating runtime used different path normalization or command identity.
attack_vector: Codex writes an override for `./.env` while Claude normalizes to the repo root `.env`; one checker sees a narrow exact override and the other sees broader path permission or misses the revocation.
mitigation: Amend B01/B04/B09: add `runtime`, `runtime_version`, `path_realpath`, `path_display`, `command_realpath`, and `parser_version` fields to override receipts; conformance must replay the same override through Claude, Codex, and MCP parser fixtures and compare active-state output.
joshua_decision_needed: no
joshua_question: n/a

### P5

finding_id: P5
severity: medium
class: Doctor output parity
location: `00-PLAN.md` Doctor Signals lines 104-121; B04 lines 214-220; B09 lines 311-317
description: B04 checks doctor JSON shape, but it does not require byte-stable names and JSON types across runtimes or shell environments. `jq` consumers can diverge if one runtime emits booleans and another emits stringified booleans or omits empty arrays.
attack_vector: Claude doctor fixture emits `.security.settings_deny_rules_present=true`, Codex path wraps or stringifies it as `"true"`, and promotion logic treats one as pass and one as fail.
mitigation: Amend B04/B09: add a doctor schema contract with exact JSON types for every security signal plus cross-runtime golden outputs; fixtures run doctor through Claude shell context and Codex ntm/callback context and compare normalized JSON.
joshua_decision_needed: no
joshua_question: n/a

### P6

finding_id: P6
severity: high
class: MCP-spawned process leak parity
location: `00-PLAN.md` leak vector line 25; cross-cutting conclusions lines 70-73; coverage matrix line 354; B08 lines 290-296
description: The plan scans MCP config literals but does not define a settings layer or sandbox policy for MCP-spawned subprocesses. Settings deny rules in Claude do not automatically constrain MCP server child processes, browser profiles, or agent-mail subprocesses.
attack_vector: A Claude session obeys `permissions.deny`, but an MCP browser or agent-mail helper receives the same workspace path and reads a token-bearing file through its own process tree.
mitigation: Amend B02/B08/B09: define an MCP runtime row in the security contract with allowed env, denied mounts, child-process stdout/stderr redaction, and per-server `security_posture` metadata; conformance launches a fake MCP server that attempts denied reads and proves redacted failure in all artifacts.
joshua_decision_needed: no
joshua_question: n/a

### P7

finding_id: P7
severity: high
class: agent-mail token transit parity
location: `00-PLAN.md` problem statement lines 31-33; doctor signal line 120; Lane B cross-check line 365
description: The plan names agent-mail token scrollback hits, but it does not prove Claude, Codex, and MCP-spawned agents use the same redaction policy for callbacks, inbox/outbox messages, pane scrollback, and agent-mail transport errors.
attack_vector: Claude redacts a token in a callback, Codex sends the same token through ntm callback text, and an MCP agent-mail tool logs the bearer value in stderr; only the pane scrollback signal is checked.
mitigation: Amend B04/B05/B09: add a three-runtime token transit fixture covering Claude callback, Codex callback, MCP agent-mail send/error path, inbox/outbox artifacts, ntm logs, and pane scrollback; require only class/hash redaction in every persisted substrate.
joshua_decision_needed: no
joshua_question: n/a

### P8

finding_id: P8
severity: medium
class: Container isolation scope
location: `00-PLAN.md` Container Isolation lines 100-102; B08 lines 290-296; L74 candidate line 125
description: B08 defines a prod-credential sandbox profile, but the plan does not say whether Claude orchestrators, Codex workers, and MCP-spawned agents are all subject to the same sandbox gate. It can become a bead-worker-only control while orchestrator or MCP paths remain bare-metal.
attack_vector: A bead-dispatched Codex worker runs under the sandbox profile, but a Claude orchestrator or MCP helper performs the same prod-credential diagnostic outside the sandbox because it is not classified as a worker.
mitigation: Amend B08/B09/B10: define `runtime_scope=claude|codex|mcp|shell` applicability in the sandbox profile and make doctor report unsandboxed high-risk runtimes separately; conformance must test that every runtime class either runs in the profile or emits `blocked_by=sandbox_required`.
joshua_decision_needed: yes
joshua_question: Should prod-credential sandbox requirements apply to orchestrator panes and MCP helpers, or only to bead-dispatched workers?

### P9

finding_id: P9
severity: high
class: Conformance harness coverage
location: `00-PLAN.md` B09 lines 311-317; Three-Q lines 400-403; open questions line 389
description: B09 requires conformance and fleet smoke, but it does not explicitly require both Claude and Codex execution contexts or MCP process fixtures. A shell-only harness can pass while the actual Codex or MCP runtime remains untested.
attack_vector: `bash tests/security-control-conformance.sh` passes from the orchestrator shell, but Codex cannot resolve the same tool path or MCP server output is unredacted; the plan still reports security conformance.
mitigation: Amend B09: require a runtime coverage matrix with `claude_shell`, `codex_ntm_callback`, and `mcp_subprocess` rows for every MUST clause; fail conformance if any required runtime row is missing, blocked without receipt, or only proven by orchestrator shell.
joshua_decision_needed: no
joshua_question: n/a

### P10

finding_id: P10
severity: high
class: xpane cross-orch leakage
location: `00-PLAN.md` problem statement lines 31-33; coverage matrix lines 350-351; rollout lines 372-374
description: The plan covers worker callbacks and pane scrollback but does not define which runtime's security policy governs cross-pane payloads between sessions and runtimes. Payloads can cross from a protected Claude orchestrator into a less-protected Codex or MCP context.
attack_vector: `flywheel:1` sends an xpane packet to `zeststream:1` containing context copied from a secret-bearing receipt; Claude's deny rules governed the source pane, but Codex receives and persists the payload without the same deny/redaction contract.
mitigation: Amend B04/B05/B09: add `cross_runtime_payload_secret_hits_count` scanning ntm send payloads, dispatch files, callback messages, and coordination logs; require source-runtime and destination-runtime metadata plus a fixture routing a synthetic token through Claude-to-Claude, Claude-to-Codex, and Claude-to-MCP payload paths.
joshua_decision_needed: no
joshua_question: n/a

## 3. Hunt List Coverage

| Hunt item | Result |
|---|---|
| Settings.json shape parity | P1 |
| Pre-commit hook runtime asymmetry | P2 |
| Auth-marker expiry clock skew | P3 |
| Override-receipt-bypass per-runtime | P4 |
| Doctor output parity | P5 |
| MCP-spawned process leak parity | P6 |
| agent-mail token transit parity | P7 |
| Container isolation scope | P8 |
| Conformance harness coverage | P9 |
| xpane cross-orch leakage | P10 |

Every requested hunt class has at least one finding.

## 4. Critical And High Findings

Critical findings: 0

High findings for Joshua-disposes visibility:

- P1 settings deny-rule parity
- P4 per-runtime override bypass
- P6 MCP-spawned process leak parity
- P7 agent-mail token transit parity
- P9 conformance harness coverage
- P10 xpane cross-orch leakage

Joshua decisions needed:

- P1 unsupported runtime enforcement policy
- P8 sandbox scope across orchestrator/MCP/helper runtimes

## 5. Three-Q Audit

VALIDATED:

- Every finding cites `00-PLAN.md` section and line range.
- Every finding includes a concrete cross-runtime divergence scenario.
- Socraticode was queried twice for local parity, conformance, capture, and callback precedent.

DOCUMENTED:

- Each finding has an explicit mitigation as a bead amendment.
- Skills consulted are named in section 1.
- Critical/high findings are separated for Joshua-disposes.

SURFACED:

- Findings map to existing beads B01-B10.
- Lens 3 agrees with Lens 1/Lens 2 that cross-orch payload scrub and cross-runtime canonicalization may deserve standalone Phase 4 beads if Phase 3 synthesis chooses to split them from B04/B09.

## 6. Ladder Check

Plan-space only:

- No settings mutations.
- No source implementation edits.
- No bead creation.
- No commits.
- Output artifact only: `.flywheel/plans/agent-security-controls-fleet-wide-2026-05-04/03-AUDIT-r1-lens3-cross-runtime-parity.md`.

Ladder verdict: `ladder_passed=yes`.
