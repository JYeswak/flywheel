---
title: "Lane B Research - Ecosystem Audit"
type: plan
created: 2026-05-04
frontmatter_source: scaffold-doc-frontmatter
---

# Lane B Research - Ecosystem Audit

Plan: `agent-security-controls-fleet-wide-2026-05-04`
Phase: `1.RESEARCH Lane B`
Worker: `flywheel:3 codex`
Date: 2026-05-04

## Research Ledger

- Scope: ecosystem prior art and reusable patterns to ADOPT / EXTEND / AVOID. This is not Lane A problem inventory and not Lane C implementation design.
- Skills baseline: `/flywheel:skills-best-practices "agent security secrets sandbox auth"` was attempted from shell and failed because the slash surface is not a filesystem executable. Fallback used `skill-search` plus direct skill reads.
- Skill-search top 10: `agent-sandboxing`, `agent-security`, `cryptography-and-auth`, `mcp-secret-scanner`, `infisical-secrets`, `agent-mail`, `socraticode`, `security-audit-for-saas`, `authentication-authorization`, `security-review`.
- Skills read: `/Users/josh/.claude/skills/agent-security/SKILL.md`, `/Users/josh/.claude/skills/agent-sandboxing/SKILL.md`, `/Users/josh/.claude/skills/mcp-secret-scanner/SKILL.md`, `/Users/josh/.claude/skills/cross-collection-fanout/SKILL.md`.
- Socraticode corpus: `/Users/josh/Developer/jeff-corpus`, 8 searches over secret handling, `.env`, permission rules, file-read filters, log redaction, pre-commit hooks, container isolation, DCG, and agent-mail auth.
- Local probes: `~/.claude/settings.json`, `~/.claude/settings.local.json`, 11 discovered flywheel/fleet repos, `~/.local/state/flywheel/agent-mail-tokens/`, `~/.local/state/skillos/auth-markers/`, DCG v0.5.1.
- Web sources: Anthropic Claude Code docs, Anthropic GitHub issues/advisory, TIMEWELL zodchii-derived article, The Register report. Links are inline.
- Copyright note: the zodchii/TIMEWELL article asks for copy-paste settings and hook bodies. This artifact does not reproduce full third-party verbatim blocks; it extracts the primitive list and cites the source.

## B.1 Jeff Corpus Query - Security Primitives

| source | primitive | description | decision | reason |
|---|---|---|---|---|
| `pi_agent_rust/docs/security/baseline-audit.md:91` | Env var blocklist | Three-tier filtering: exact secret names, suffixes like `_TOKEN`, prefixes like `AWS_SECRET_*`; `process.env` is read-only and non-enumerable. | EXTEND | Strong runtime pattern, but deny-list alone misses novel secret names; Lane C should pair with allow-list mode for high-risk repos. |
| `pi_agent_rust/docs/security/baseline-audit.md:361` | Deny-list gap named | Explicitly flags blocklist weakness and proposes optional env allow-list mode. | ADOPT | This is the clearest Jeff prior art for "deny by default for high-security mode." |
| `pi_agent_rust/src/extensions_js.rs:16144` | File-read confinement | Opens by fd, resolves `/proc/self/fd/{fd}`, then verifies resolved path remains in workspace/extension roots. | EXTEND | Excellent for Linux/container runtimes; macOS flywheel needs analogous realpath/symlink checks if implemented outside Claude settings. |
| `pi_agent_rust/tests/adversarial_extensions.rs:502` | Filesystem escape fixture | Tests direct read of `/etc/passwd` must be blocked. | ADOPT | Lane C needs adversarial fixtures, not only settings presence checks. |
| `pi_agent_rust/tests/adversarial_extensions.rs:1157` | Multi-vector credential theft fixture | Tests env read, credential file read, env enumeration, and `GH_TOKEN` theft all fail together. | ADOPT | This maps exactly to the plan's 3 leak paths plus env enumeration. |
| `pi_agent_rust/docs/provider-auth-troubleshooting.md:541` | Four-layer redaction | Redacts headers, JSON fields, log contexts, live E2E headers, and emits diagnostic policy. | ADOPT | Best local prior art for runtime-output leak vector. |
| `pi_agent_rust/docs/provider-auth-redaction-diagnostics.json:91` | Banned secret exposures | Defines categories that must never appear in diagnostic output, logs, errors, or artifacts. | EXTEND | Convert into flywheel doctor/audit signal definitions rather than one-off docs. |
| `pi_agent_rust/scripts/e2e/run_all.sh:4671` | Artifact redaction gate | Validates environment and summary artifacts for high-confidence secret/token patterns. | ADOPT | This should become the validation fixture shape for `leaked_secret_pattern_count`. |
| `frankentui/crates/doctor_frankentui/src/redact.rs:1` | Redaction pipeline design | Deterministic, traceable, layered redaction for source-derived artifacts, logs, and manifests. | ADOPT | Good doctor-signal implementation model: redactions are counted and traceable. |
| `frankentui/crates/doctor_frankentui/tests/sandbox_redaction_tests.rs:239` | Redaction regression test | Asserts known GitHub/AWS/token strings are absent from redacted output. | ADOPT | Lane C should require negative assertions on fixture values. |
| `frankenterm/crates/frankenterm-core/src/policy.rs:9814` | Token redactor tests | Covers AWS secret key, bearer token, quoted bearer, Slack token, Stripe secret. | ADOPT | Pattern list overlaps with zodchii and should seed the canonical regex corpus. |
| `frankenterm/docs/security/redactor-coverage-methodology.md:1` | Recall/precision methodology | Defines TP/FN/FP and provider-by-provider recall for secret redactors. | EXTEND | Avoid "regex exists, therefore safe"; require measured recall/precision on fixture corpus. |
| `coding_agent_session_search/tests/util/e2e_log.rs:318` | Sanitized env capture | Captures only selected env vars and redacts sensitive exact/pattern matches. | ADOPT | Good lightweight pattern for diagnostic bundles and callbacks. |
| `mcp_agent_mail_rust/crates/mcp-agent-mail-server/src/console.rs:2725` | Console masking | Tests recursive masking of sensitive JSON params and nested auth/header fields. | ADOPT | Directly relevant to agent-mail identity/message surfaces. |
| `mcp_agent_mail_rust/EXISTING_MCP_AGENT_MAIL_STRUCTURE.md:901` | Snapshot scrub presets | Secret patterns plus `standard`, `strict`, `archive` scrub modes. | EXTEND | Flywheel needs a strict mode for worker transcript/security audit exports. |
| `mcp_agent_mail_rust/crates/mcp-agent-mail-server/src/startup_checks.rs:2545` | Auth startup probe | Fails short bearer tokens and inconsistent JWT config. | ADOPT | Security doctor should check config quality, not just file presence. |
| `destructive_command_guard/tests/suggest_allowlist_e2e.rs:1218` | Risk-ack allowlist | Refuses sensitive allowlist suggestions unless explicit `--accept-risk`. | ADOPT | Canonical override model for secret access: per-command, loud, logged, and risk-acknowledged. |
| `destructive_command_guard/scripts/e2e_test.sh:1418` | Allowlist semantics | Baseline deny, targeted allow, expired allow rejected, global wildcard rejected. | ADOPT | Settings deny-rule contract should include expiry and wildcard rejection tests. |
| `destructive_command_guard/docs/json-schema/hook-output.json:1` | Hook output schema | Stable JSON with `permissionDecision`, reason, one-time allow code, rule id. | EXTEND | Useful shape for a secret-read blocker if implemented as hook/guard. |
| `frankenpandas/githooks/README.md:1` | Committed hook dispatcher | Uses committed `githooks/` plus `core.hooksPath`, with ordered hook scripts. | ADOPT | `.git/hooks` is local-only; fleet-wide security should use committed hook path or installer doctor, not assume local hook exists. |
| `pi_agent_rust/tests/ext_conformance/.../secret-scanner/README.md:1` | Secret scanner plugin | Pattern matching, entropy analysis, git history scan, pre-commit integration. | EXTEND | Good feature list; local implementation should prefer existing `mcp-secret-scanner`/gitleaks/trufflehog where available. |
| `pi_agent_rust/tests/ext_conformance/.../secret-scanner.json:1` | PreToolUse secret scanner | Hook wrapper detects many provider token prefixes before commit-like commands. | EXTEND | Claude-only hook pattern; Codex needs parity path outside Claude hooks. |
| `pi_agent_rust/tests/ext_conformance/.../docker-security-scan.md:181` | Container security scan | Flags privileged containers, host network, sensitive mounts, env secrets, missing limits. | ADOPT | If Lane C uses container isolation, the control must include container hardening checks, not just `/dev/null` mounts. |
| `destructive_command_guard/tests/containers_pack_comprehensive.rs:649` | Docker destructive guard | Blocks dangerous Docker env-prefix/prune/volume operations. | ADOPT | DCG covers destructive Docker commands, not secret reads; pair it with secret controls. |

Summary: Jeff corpus agrees on mechanical gates, fixtures, redaction tests, explicit risk acknowledgements, and doctor/startup probes. It does not support relying on prompt rules or `.gitignore` alone.

## B.2 zodchii Twitter Source

Primary-source status: direct X content was not reliably accessible from the CLI/browser. The plan's `00-INTENT.md` quotes the three leak vectors, and TIMEWELL cites darkzodchi/zodchii's April 2026 guide, "The .env Setup That Keeps Claude Code From Leaking Your Secrets" at <https://timewell.jp/en/columns/claude-code-env-security-guide>. A Rattibha mirror for a separate darkzodchi hook thread is at <https://en.rattibha.com/thread/2040000216456143002>; it confirms the author's hook thesis that CLAUDE.md is advisory and hooks/settings are automatic enforcement.

| item | extracted primitive | decision | reason |
|---|---|---|---|
| Leak vector 1 | Direct file read: agent opens `.env`/secret file and contents enter conversation context. | ADOPT verbatim as threat class | Matches Anthropic issue #44868 and local Lane A scope. |
| Leak vector 2 | Runtime output capture: tests/errors/loggers print authorization headers, DB URLs, or env values. | ADOPT + EXTEND | Settings deny does not stop Bash child output; needs `.env.test` and output redaction. |
| Leak vector 3 | Grep/search collateral: search command prints matching secret-bearing lines. | ADOPT | Anthropic issue #44868 reproduces this with `grep -n`. |
| Deny rule list | `Read` blocks for `.env*`, `.dev.vars*`, `*.pem`, `*.key`, `secrets/**`, `credentials/**`, `.aws/**`, `.ssh/**`, database/credentials JSON/YAML, `.npmrc`, `.pypirc`; `Write` blocks for `.env*`, `secrets/**`, `.ssh/**`. | EXTEND | Strong baseline; add `Edit` if Claude permission syntax supports it, include `Bash`/shell guard for `cat`, `grep`, `sed`, `awk`, `head`, `tail` against secret paths. |
| Bash deny list | Deny destructive/exfil-capable commands such as forced git pushes, `curl | sh`, `wget`, wide chmod, and production-publish commands. | EXTEND | DCG already covers much of destructive side; secret lane should cover read/exfil and output redaction. |
| Pre-commit hook | Pattern detector for Anthropic, Stripe, GitHub, AWS, Slack, SendGrid, JWT, private-key starts; blocks sensitive filenames and key extensions. | EXTEND | Use as seed list, but prefer committed hooks + gitleaks/trufflehog + mcp-secret-scanner parity. Local-only `.git/hooks` is not fleet-enforcing. |
| Container isolation | Run agent in container with repo mounted and `.env` paths over-mounted from `/dev/null`, `:ro`, plus empty `--env-file`. | ADOPT for high-risk mode | Add no-new-privileges, cap drop, read-only rootfs where feasible, resource limits, and network policy from agent-sandboxing/Jeff corpus. |
| 6-item checklist | deny rules; dummy `.env.test`; secret pre-commit hook; vault/secret manager; `.env*` in `.gitignore` and history scan; move/blank `.env` outside agent-visible workspace. | ADOPT | This maps cleanly to doctor signals and Lane C phase gates. |
| CLAUDE.md reliance | Treat prompt instructions as reminders only. | ADOPT as anti-pattern | Matches `agent-security` anti-pattern "security by prompt engineering only." |

Copyright constraint: the full third-party settings/hook bodies are intentionally not copied into this artifact. Lane C should create local canonical variants from the extracted primitive list and cite the source.

## B.3 Anthropic GitHub Issues And Docs

| source | finding | decision | reason |
|---|---|---|---|
| Anthropic docs: <https://code.claude.com/docs/en/permissions> lines 98-105 | `deny` rules prevent tool use and win before ask/allow. | ADOPT | Official source confirms settings-level deny is the supported enforcement surface. |
| Anthropic docs: <https://code.claude.com/docs/en/settings> lines 512-527 | Docs explicitly recommend `permissions.deny` for sensitive files and say matching files are excluded from discovery/search/read. | ADOPT with validation | This is the contract to test fleet-wide. |
| Anthropic docs: permissions lines 321-333 | Permissions and sandboxing are complementary; deny rules block access, sandbox prevents Bash reaching resources. | ADOPT | Confirms settings alone is not the whole control plane. |
| Anthropic docs: permissions lines 336-357 | Managed settings can lock policies and managed hooks. | EXTEND | Future enterprise path; local fleet can mirror with ft04/canonical sync and doctor checks. |
| GitHub issue #44868: <https://github.com/anthropics/claude-code/issues/44868> | Open Apr 7 2026: `.env` / `.dev.vars` can be echoed via grep/read despite CLAUDE.md prohibitions; proposed path filter and output scrubber. | ADOPT | Best direct issue for the exact plan. It validates all three leak vectors. |
| GitHub issue #5616: <https://github.com/anthropics/claude-code/issues/5616> | Reports `.env` loaded/exported on startup even with read permissions denied. | EXTEND | Settings deny may not control already-loaded env; Lane C must test env visibility, not just file read. |
| GitHub issue #4160: <https://github.com/anthropics/claude-code/issues/4160> | Requests deterministic `.claudeignore`; says hooks/read denials are insufficient because indirect access exists. | EXTEND | Reinforces defense-in-depth and segmentation. |
| GitHub issue #27040: <https://github.com/anthropics/claude-code/issues/27040> | Reports deny permissions in project settings ignored. | ADOPT as regression fixture | Even if version-specific, a smoke fixture should catch this in current runtime. |
| GitHub issue #8961: <https://github.com/anthropics/claude-code/issues/8961> | Reports deny rules ignored for `.env.production.*` in some sessions. | ADOPT as regression fixture | Requires current-version validation before trusting policy. |
| GitHub advisory GHSA-x5gv-jw7f-j6xj: <https://github.com/anthropics/claude-code/security/advisories/GHSA-x5gv-jw7f-j6xj> | Older broad allowlist allowed file read + network exfiltration without confirmation; patched in v1.0.4. | ADOPT lesson | Prevent permissive allowlist regressions; default allowlists can become exfil paths. |
| The Register report: <https://www.theregister.com/2026/01/28/claude_code_ai_secrets_files/> | Reproduced `.env` reading despite `.claudeignore`/`.gitignore`, and notes settings permissions can block but are tricky. | ADOPT caution | `.gitignore` and `.claudeignore` should not be treated as sufficient gates. |

Issue conclusion: Official docs define the target state, but issue history shows the plan must include runtime smoke tests for current Claude/Codex behavior. "Settings present" is not a validation receipt.

## B.4 Existing Flywheel Substrate

### Current Claude Settings

| file | allow count | deny count | hook status | finding |
|---|---:|---:|---|---|
| `~/.claude/settings.json` | 97 | 0 | Has `PostToolUse`, `PreCompact`, `PreToolUse`, `SessionStart`, `Stop`, `UserPromptSubmit` | No global secret deny rules today. |
| `~/.claude/settings.local.json` | 611 | 0 | No hooks | Large local allow surface, no deny counterweight. |

Decision: EXTEND. This is the clearest local gap for Lane C: the fleet has hook infrastructure, but current settings have zero deny rules for secret paths.

### Fleet/Flywheel Repo Probe

Two probes produced different fleet boundaries:

- Active/known orchestration set from `fleet-roster.json`, loop registry, and fleet-audit session names: 11 repos.
- Broad filesystem `.flywheel` search under `~/Developer`: 25 candidate repos, including nested/test workspaces.

The mismatch itself is a Lane A/Lane C registry problem: the plan says "17 repos," the active orchestration substrate exposes 11, and the broad local substrate exposes 25. Lane C should define the canonical fleet membership source before enforcing.

| repo | `.claude/settings.json` | deny rules | secret-path deny | `.env` ignored | pre-commit hook |
|---|---:|---:|---:|---:|---:|
| `/Users/josh/Developer/alpsinsurance` | no | missing | 0 | yes | yes |
| `/Users/josh/Developer/clutterfreespaces` | no | missing | 0 | no | no |
| `/Users/josh/Developer/flywheel` | no | missing | 0 | no | no |
| `/Users/josh/Developer/mobile-eats` | no | missing | 0 | yes | no |
| `/Users/josh/Developer/picoz` | yes | 0 | 0 | yes | yes |
| `/Users/josh/Developer/skillos` | no | missing | 0 | no | no |
| `/Users/josh/Developer/terratitle` | no | missing | 0 | yes | no |
| `/Users/josh/Developer/vrtx` | yes | 0 | 0 | yes | no |
| `/Users/josh/Developer/zeststream-infra` | no | missing | 0 | no | no |
| `/Users/josh/Developer/zeststream-v2` | no | missing | 0 | no | no |
| `/Users/josh/Developer/zesttube` | no | missing | 0 | yes | no |

Broad candidate sample summary: 6/25 repos have `.claude/settings.json`, all 6 have `permissions.deny` count 0; 14/25 have `.env` covered in `.gitignore`; 4/25 have a local pre-commit hook. Decision: ADOPT probe shape, EXTEND coverage. Current fleet state is partial at best in both views: secret deny rules are 0 across all probed repos.

### Secret Stores And Markers

- `~/.local/state/flywheel/agent-mail-tokens/`: 3 files, all mode `0600`; values were not read or printed. Decision: ADOPT local mode discipline; EXTEND with doctor signal for mode/owner/count only.
- `~/.local/state/skillos/auth-markers/`: missing. Decision: EXTEND; if auth markers are expected, Lane A should clarify path or Lane C should avoid depending on a missing substrate.
- `~/.claude/references/claude-md-secrets.md`: Infisical is source of truth; `cf-secret` live-first/cache-fallback helper is canonical; no rotation without explicit ask. Decision: ADOPT. Secret file controls should route live values through Infisical/cf-secret, not project `.env` where possible.

### DCG Coverage

- `dcg --version`: v0.5.1.
- DCG supports Claude Code, Codex CLI, Gemini CLI, Copilot CLI, Cursor IDE; blocks destructive commands across git/filesystem/container/database/cloud packs.
- Decision: ADOPT as analog, not sufficient control. DCG protects destructive commands; it does not by itself prevent `Read(**/.env*)`, `grep -n .env`, or runtime log emission of secrets. Lane C should model secret controls after DCG's stable rule IDs, allow-once, risk acknowledgement, and corpus tests.

### Existing Skill Substrate

- `agent-security`: ADOPT primary. Its anti-pattern table explicitly rejects security by prompt engineering only, no output filtering, long-lived credentials, shared API keys.
- `agent-sandboxing`: ADOPT for high-risk/container mode. It specifies no bare-metal production, default-deny network policy, read-only roots, `/tmp` limits, `/secrets` tmpfs, and no Docker socket.
- `mcp-secret-scanner`: ADOPT. It already scans Claude/Codex MCP config paths and has a Codex parity anti-pattern. EXTEND it beyond MCP config into repo staged secret checks or use as pattern source.
- `cross-collection-fanout`: ADOPT for this plan's corpus query pattern. Security controls need federated source evidence and partial-result surfacing.

## B.5 Cross-Cut Findings

1. **Prompt rules are not controls.** Every source agrees: CLAUDE.md/AGENTS.md can remind, but execution-layer gates must enforce. Lane C should not count documentation as Q1 validation.
2. **Deny rules are necessary but incomplete.** They cover direct Read/Search only if current runtime honors them. They do not cover env already loaded into the process, Bash child output, screenshots, logs, or copied artifacts. Add fixture smoke tests.
3. **Runtime output redaction is first-class.** Jeff corpus has stronger redaction prior art than the zodchii article: provider-auth four-layer redaction, artifact scanning, recall/precision methodology. Adopt those, not only a grep hook.
4. **Local `.git/hooks` is not fleet-wide enforcement.** Use committed hook dispatchers, `core.hooksPath`, doctor checks, and callback validation. `.git/hooks/pre-commit` alone is a local marker.
5. **Codex parity is a core gap.** Claude has hooks/settings; Codex does not have the same hook surface. Use DCG-style multi-runtime guard patterns and doctor signals that prove both Claude and Codex coverage.

## B.6 Three-Q Audit

| question | result | evidence |
|---|---|---|
| VALIDATED | partial | Claims cite Socraticode repo/file/line, local probe outputs, or web URLs. No implementation was run because Lane B is read-only research. |
| DOCUMENTED | yes | Every primitive above has ADOPT/EXTEND/AVOID rationale. |
| SURFACED | yes | Cross-cut findings name actionable Lane C work: current-runtime smoke tests, redaction corpus, committed hooks, Codex parity, doctor signals. |

## B.7 Ladder Check

- Plan-space only: yes.
- Read-only source/config posture: yes. No settings, source, beads, or configs were edited.
- Only artifact edited: `.flywheel/plans/agent-security-controls-fleet-wide-2026-05-04/01-RESEARCH-B.md`.
- Secrets safety: yes. Token directories were probed by metadata only; secret values were not printed.
- Socraticode-first: yes, 8 security corpus searches against `/Users/josh/Developer/jeff-corpus`.
- Skills library: yes, slash surface attempted; skill-search fallback used; primary skills read.
- External verification: yes, web sources checked for zodchii-derived guide and Anthropic issues/docs.
- ladder_passed=yes.

## Lane C Inputs

- Build a canonical secret-deny contract with runtime smoke fixtures, not just settings JSON.
- Include both `Read/Search` path denial and Bash-output redaction gates.
- Add `.env.test` dummy-value fixture standards for every repo with runtime tests.
- Use committed hook/installer pattern rather than local `.git/hooks` as the only enforcement.
- Add doctor signals: `settings_deny_rules_count`, `secret_path_deny_missing_count`, `env_in_gitignore_count`, `pre_commit_secret_hook_present_count`, `leaked_secret_pattern_count`, `runtime_env_secret_visible_count`, `codex_secret_guard_parity_count`.
- Treat high-risk client/prod credential work as sandbox/container mode with `/dev/null` over-mounts plus container hardening.
