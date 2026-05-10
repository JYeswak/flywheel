---
title: "Phase 3 AUDIT r1 Lens 1 — Security Cross-Cutting"
type: plan
created: 2026-05-04
frontmatter_source: scaffold-doc-frontmatter
---

# Phase 3 AUDIT r1 Lens 1 — Security Cross-Cutting

Plan: `agent-security-controls-fleet-wide-2026-05-04`
Input: `.flywheel/plans/agent-security-controls-fleet-wide-2026-05-04/00-PLAN.md`
Lens: security cross-cutting only
ladder_passed: yes

## Skills And Search Baseline

Skills consulted:

- `jeff-convergence-audit`: Phase 1 broad-sweep shape and finding discipline.
- `security-audit-for-saas`: fail-open, duplicate-parser, shadow-recovery-path, and all-surfaces audit axioms.
- `security-pen-testing`: offensive secret scanning and bypass mindset.
- `mcp-secret-scanner`: MCP/Codex config parity and plaintext-token scanner limits.
- `agent-sandboxing`: filesystem, network, process, and mount containment checks.
- `agent-security`: defense-in-depth, output filtering, credential management, and sandbox principle.

Socraticode queries:

- `agent security audit override bypass runtime output leak pre-commit hook bypass container escape plan findings`
- `MCP spawned process leak headless Chrome token capture agent mail process tree security audit`

## Findings

### F1

finding_id: F1
severity: high
class: override-bypass
location: `00-PLAN.md` section 4 Canonical Settings Deny Block lines 82-86; B01 lines 156-161; L74 candidate line 125
description: The override pattern requires reason/expiry/owner/scope, but the plan leaves the JSON-safe representation undecided and does not require risk acknowledgement, normalized path matching, deny-rule IDs, or approval provenance. That creates an escape hatch where a broad or malformed override can silently neutralize the canonical deny block.
attack_vector: A worker writes an override receipt that claims `canonical-security-allow reason=debug` for `.env*` or a parent directory, the doctor only checks that the field exists and is unexpired, and the next task reads a live secret path under the allowed glob.
mitigation: Amend B01/B04/B09: define `.flywheel/security/v1/security-overrides.jsonl` with exact normalized path or command hash, denied-rule IDs, owner, reason, `risk_ack=true`, `approved_by`, `expires_at <= 24h`, and forbidden wildcard/parent-directory grants; add `security_override_active_count` and `security_override_invalid_count`; strict doctor fails expired, broad, or unapproved overrides.
joshua_decision_needed: yes
joshua_question: Should security overrides for live secret paths be disabled until the JSONL override schema and strict doctor checks land?

### F2

finding_id: F2
severity: high
class: runtime-output leak
location: `00-PLAN.md` top leak vectors lines 25-27; Runtime Safety lines 92-94; B06 lines 254-259
description: The `.env.test` standard covers synthetic fixture files, but it does not explicitly test inherited parent-process env, test-framework passthrough, child process env dumps, debug logs, screenshots, or pane capture. A repo can pass `.env.test` checks while still leaking a real token inherited from the shell or launchd environment.
attack_vector: A test runner starts with `ANTHROPIC_API_KEY` or an agent-mail token already in the process env, a failing test prints `os.environ`, and the runtime fixture only verifies that `.env.test` itself contains synthetic values.
mitigation: Amend B06/B09: add a poisoned-host-env fixture that injects synthetic live-shaped values into parent env, child process env, stdout, stderr, log files, validation receipts, and pane/callback capture; require the conformance harness to prove raw values are absent from all output artifacts while class/count receipts remain.
joshua_decision_needed: no
joshua_question: n/a

### F3

finding_id: F3
severity: high
class: singleton-trust
location: `00-PLAN.md` Executive Summary line 9; Canonical Settings Deny Block lines 82-86; Open Questions lines 388-391
description: The plan centers a canonical `settings.json` deny block but has not yet made settings precedence part of the schema or doctor gate. Local, repo, managed, and runtime-specific settings surfaces can diverge, and a permissive `settings.local.json` or equivalent can become the effective authority.
attack_vector: The fleet sync writes the managed block into repo `.claude/settings.json`, but a developer or tool has a higher-precedence local settings file that allows the same read; doctor reports the canonical block present while the agent runtime uses the permissive override.
mitigation: Amend B01/B03/B04: enumerate all settings surfaces and precedence for Claude, Codex, MCP, and repo-local configs; doctor must inspect each surface, compute the effective deny posture, and fail when any higher-precedence local surface weakens the canonical block.
joshua_decision_needed: no
joshua_question: n/a

### F4

finding_id: F4
severity: medium
class: token-in-prose
location: `00-PLAN.md` doctor signal table lines 117-121; B04 lines 214-220; B05 lines 233-239
description: The plan says doctor output and promotion descriptions must avoid secret values, but B05 still emits daily-report status, top failing repos, and auto-bead descriptions without a schema-level evidence redaction test. The producer can comply while a downstream consumer rehydrates raw evidence into prose.
attack_vector: `security-posture-probe.sh` returns redacted classes, but `doctor-signal-bead-promotion.sh` includes a raw matched line from a receipt or log excerpt in the created bead description for operator context.
mitigation: Amend B05/B09: promotion and daily-report fixtures must include a raw-token poisoned input and assert output contains only `class`, `path_hash`, `line_hash`, and redacted excerpts; add a test that created bead descriptions contain no token-shaped values.
joshua_decision_needed: no
joshua_question: n/a

### F5

finding_id: F5
severity: medium
class: migration-window
location: `00-PLAN.md` rollout line 17; Propagation lines 88-90; Rollout Plan lines 370-384
description: The rollout is explicitly sequential across source, active repos, then remaining repos, but the plan does not define a fleet-level degraded state while some repos are protected and others are not. Mixed posture lets work move to an unsynced repo with the same credentials during the migration window.
attack_vector: After flywheel and two active repos get deny rules, a worker in an unsynced repo can still read `.env` or MCP config and dispatch results through the shared orchestration substrate before the remaining repos are applied.
mitigation: Amend B03/B04/B09: add `security_rollout_incomplete_count`, `security_rollout_required_repos`, and a fleet receipt; strict doctor reports WARN/FAIL until every required repo has the same schema version, and dispatch packets to unsynced repos must include `blocked_by=security_rollout_incomplete` or a dry-run-only receipt.
joshua_decision_needed: no
joshua_question: n/a

### F6

finding_id: F6
severity: medium
class: pre-commit hook bypass
location: `00-PLAN.md` Pre-Commit lines 96-98; B07 lines 272-277; doctor signals lines 115-116
description: The committed hook pattern does not address `git commit --no-verify`, user changes to `core.hooksPath`, direct file edits outside commit flow, or CI-less local work. A pre-commit-only control is bypassable by design unless the scanner also runs in doctor, validate, and fleet-smoke paths.
attack_vector: A worker stages a token-bearing config, commits with `--no-verify`, then the bead callback cites hook installation as evidence even though the hook never ran.
mitigation: Amend B07/B09: require `security-posture-probe.sh` to scan staged and working-tree changes in validate/fleet smoke independent of git hooks; doctor must compare configured `core.hooksPath` to the expected committed path and fail on drift; acceptance gates include a `--no-verify` fixture that is caught by the non-hook scanner.
joshua_decision_needed: no
joshua_question: n/a

### F7

finding_id: F7
severity: high
class: container escape
location: `00-PLAN.md` Container Isolation lines 100-102; B08 lines 290-296; coverage matrix line 357
description: The sandbox profile mentions secret paths over-mounted from `/dev/null`, but B08's explicit rejection gate only names `.env` mount plus privileged/network/socket hazards. It does not enumerate home credential stores, Infisical/opencode caches, MCP configs, browser profiles, OrbStack/Docker sockets, or host `$HOME` bind mounts.
attack_vector: A prod-credential container avoids mounting `.env` but bind-mounts `~/.aws`, `~/.ssh`, `~/.config/infisical`, `~/.claude/.mcp.json`, or a browser profile; the B08 test passes because only `.env` was checked.
mitigation: Amend B08/B09: define a denied mount matrix for `.env*`, `.aws`, `.ssh`, `.config/infisical`, `.opencode`, `.claude`, `.codex`, `.mcp.json`, browser profiles, Docker/OrbStack sockets, and host `$HOME`; add fixtures proving each is rejected and that env allow-list mode strips host secret variables.
joshua_decision_needed: no
joshua_question: n/a

### F8

finding_id: F8
severity: high
class: cross-orch token capture
location: `00-PLAN.md` problem statement lines 25-33; coverage matrix lines 350-351; Lane B primitive cross-check line 365
description: The plan covers pane scrollback and agent-mail token masking, but it does not explicitly cover cross-orchestrator packet substrates: `ntm send` payloads, dispatch logs, `/tmp/dispatch_*` files, callback messages, and xpane context handoffs. Those are the exact places token-bearing prose can cross from one orchestrator to another.
attack_vector: A worker includes a credential-like excerpt in a cross-orch dispatch packet or DONE callback; the pane scrub signal catches scrollback later, but the `/tmp` prompt file and dispatch log already persisted the token-shaped string and may be read by another orchestrator.
mitigation: Amend B04/B05/B09: add `cross_orch_secret_payload_hits_count` scanning dispatch logs, `/tmp/dispatch_*`, callback payloads, and ntm-send prompt files with redacted class/path/hash output; add a fleet smoke fixture that sends a synthetic token through the cross-orch path and proves every persisted substrate is scrubbed.
joshua_decision_needed: no
joshua_question: n/a

### F9

finding_id: F9
severity: medium
class: MCP-spawned process leak
location: `00-PLAN.md` leak vector line 25; cross-cutting conclusions lines 70-73; coverage matrix line 354; open questions lines 388-392
description: MCP configs are included as files, but the plan does not cover secrets leaking through MCP-spawned process trees, browser automation profiles, child-process env, or MCP stderr/stdout. This misses sibling risks to the documented headless browser leak class.
attack_vector: An MCP server such as browser automation, Claude Chrome, or agent-mail subprocess inherits a token-bearing env var or profile path and logs it to stderr; scanner and settings deny checks pass because no config file contains a literal token.
mitigation: Amend B02/B08/B09: add an MCP process-tree fixture that launches a fake MCP server with poisoned env/profile paths and asserts stdout/stderr/log artifacts are redacted; B08 must deny browser profile and credential-store mounts for MCP-spawned processes.
joshua_decision_needed: no
joshua_question: n/a

### F10

finding_id: F10
severity: medium
class: weak-default
location: `00-PLAN.md` Canonical Contract line 80; doctor signal line 121; B03 lines 198-199; B09 lines 311-317
description: The plan includes issued/expires metadata and receipt freshness, but it does not define fail-closed behavior when an `auth-marker/v1` or sibling security marker expires mid-execution. Without a rule, long-running bounded mutations can continue under a stale marker or fail halfway without rollback semantics.
attack_vector: A propagation apply starts with a valid marker, runs across many repos, crosses the 24h expiry during the final repos, and still writes settings because only the initial preflight checked validity.
mitigation: Amend B01/B03/B09: define marker lease semantics for mutating operations: preflight requires `expires_at` beyond worst-case runtime, mid-run checkpoints revalidate before each repo write, expired marker aborts before the next mutation, and the apply receipt records rollback state for already-mutated repos.
joshua_decision_needed: yes
joshua_question: Should marker expiry be a hard abort before the next repo mutation, even if that leaves a partial rollout requiring rollback/resume?

## Hunt List Coverage

| Hunt class | Result |
|---|---|
| Override-bypass | Finding F1 |
| Runtime-output leak | Finding F2 |
| Singleton-trust | Finding F3 |
| Token-in-prose | Finding F4 |
| Migration-window | Finding F5 |
| Pre-commit hook bypass | Finding F6 |
| Container escape | Finding F7 |
| Cross-orch token capture | Finding F8 |
| MCP-spawned process leak | Finding F9 |
| Auth-marker-v1 expiry | Finding F10 |

No hunt-list class required a `no instance found` placeholder.

## Critical And High Findings

Critical findings: 0

High findings requiring Joshua-disposes visibility before Phase 4 bead creation:

- F1 override-bypass
- F2 runtime-output leak
- F3 singleton-trust
- F7 container escape
- F8 cross-orch token capture

## Three-Q Audit

VALIDATED:

- Every finding cites `00-PLAN.md` section and line range.
- Every finding includes a concrete exploit scenario.
- Socraticode was queried twice for local precedent around doctor promotion, token capture, MCP process-tree, and cross-orch leakage.

DOCUMENTED:

- Each finding has an explicit mitigation as a bead amendment.
- Security skills consulted are named at the top of the artifact.
- High findings are separated for Joshua-disposes pause.

SURFACED:

- Findings map directly to existing beads B01-B09; no new standalone bead is mandatory from Lens 1, but Phase 3 synthesis should decide whether F8 needs a separate cross-orch payload scrub bead if Lens 3 reaches the same conclusion.
- Joshua decisions needed: 2.

## Ladder Check

Plan-space only:

- No settings mutations.
- No source implementation edits.
- No bead creation.
- No commits.
- Output artifact only: `.flywheel/plans/agent-security-controls-fleet-wide-2026-05-04/03-AUDIT-r1-lens1-security.md`.

Ladder verdict: `ladder_passed=yes`.
