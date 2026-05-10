---
title: "NTM Surface Migration Audit r1 - Security"
type: plan
created: 2026-05-08
frontmatter_source: scaffold-doc-frontmatter
---

# NTM Surface Migration Audit r1 - Security

task_id: ntm-surface-migration-audit-security-r1-2026-05-06  
plan_slug: ntm-surface-utilization-migration-2026-05-06  
scope: plan-space-only  
socraticode_queries: 10  
indexed_chunks_observed: 989  
mission_anchor: continuous-orchestrator-uptime-self-sustaining-fleet

## 1. Skills Library Cited

- `ntm`: native scrub/safety/approve/policy/rotate/coordinator surfaces and NTM-only callback discipline.
- `agent-security`: agent trust boundaries, secret handling, RBAC independent of prompt text, credential rotation controls.
- `codebase-audit`: severity-tagged findings with threat model, attack path, and mitigation.
- `dcg`: destructive-command guard remains the authoritative enforcement layer; native safety is advisory/additive.
- `canonical-cli-scoping`: new/extended CLI surfaces must preserve `--json`, help/info/examples, stable exit codes, and explicit safety posture.
- `dispatch-tool-contracts`: callback evidence is a contract; security fields must be machine-checkable, not prose.

## 2. Findings Register

| ID | Sev | Surface | Threat model | Concrete attack path | Mitigation bead/proposal | Rationale |
|---|---:|---|---|---|---|---|
| SEC-NTM-001 | high | W2S `ntm scrub` | Secret value reaches pane/report because native scrub pattern bank is narrower than flywheel validators. | Plan says "secret_scan=PASS", but NTM help only promises built-in redaction and default `.ntm`/config paths; it does not prove parity with dispatch-author, MISSION SEC-001, and DCG secret-leak override patterns. | Amend W2S acceptance: fixture matrix must cover all gap families below and scan dispatch packet, callback envelope, evidence artifact, and NTM audit export before PASS. | Direct secret leakage is a high-severity operational risk. |
| SEC-NTM-002 | high | W2D `ntm safety` | Native safety becomes a softer substitute for DCG. | An implementation could run `ntm safety check` and skip `dcg test/explain`, accept an NTM allow where DCG blocks, or let `ntm policy` allowlist commands that DCG would refuse. | Amend W2D: every destructive-command candidate must require DCG verdict `allowed` or human-run `allow-once`; NTM may be stricter, never looser. | Current plan text preserves DCG, but acceptance must make match-or-stricter mechanical. |
| SEC-NTM-003 | high | W2A `ntm approve` | Approval token approves the wrong class of human gate. | Native approve tracks dangerous-operation tokens, but the plan does not require the six TRUE-blocker evaluation, exact human question, `authorized_operations[]`, and `forbidden_operations[]` to round-trip. | Amend W2A: approval payload schema must include class-1-6 evaluation, exact question, evidence path, expiry, authorized operations, forbidden operations, and no credential values. | Missing operation enums can turn a narrow approval into broad capability. |
| SEC-NTM-004 | medium | W3a `ntm coordinator` | Heartbeat/coordination fields leak identity or topology data into broader logs. | Replacing JSONL ledger with native coordinator could emit `token_path`, `token_sha256`, owner identity chains, session:pane:project keys, or pane indexes to event feeds not meant for cross-orch readers. | Amend W3aC: coordinator heartbeat schema allowlist = `session_alias`, `pane_role`, `identity_resolved`, `status`, `age_seconds`; deny raw token path/hash, bearer, registration token, and unredacted pane text. | Operational metadata is not always a credential, but it can enable targeted replay or social routing attacks. |
| SEC-NTM-005 | medium | W3b `ntm policy` | Malformed policy escalates privilege beyond AGENTS L-rules. | If `.ntm/policy.yaml` becomes source of truth, `allowed_commands`, `automation`, force-release, auto-push, or approval rules can override AGENTS.md L-rules and validator scripts. | Amend W3bP: AGENTS.md remains canonical; policy is generated/validated artifact. Unknown or malformed policy fails closed; `policy edit/reset/automation` never runs inside worker dispatch without approval. | Privilege escalation is plausible, but plan keeps policy after W2 and under audit. |
| SEC-NTM-006 | medium | W0A `ntm rotate` wrapper | Account rotation path accepts plaintext credential or non-CAAM source. | Native `ntm rotate` supports `--account`; wrapper conformance could pass an email/profile from dispatch text or add plaintext credential handling while proving only subprocess rc. | Amend W0A: wrapper must accept only CAAM/vault selector names or redacted account aliases; block plaintext password/token inputs and record `caam_vault_only=true`. | Credential rotation is security-sensitive even when triggered by quota/capacity. |
| SEC-NTM-007 | high | All wave closeouts | Secret scan happens after callback, so the leak already crossed pane substrate. | Refine says audit+scrub before closeout, but the per-bead template only says `secret_scan=PASS`; it does not encode ordering relative to callback emission. L120 already proves close-after-callback fields get skipped. | Add worker-tick order: write evidence -> scrub evidence/callback text -> close if applicable -> send callback. Callback must include `secret_scan_before_callback=yes`. | If callback emits a secret, post-hoc scrub is too late. |
| SEC-NTM-008 | low | W1S `ntm serve` | Local eventstream exposes internal topology to the wrong local consumer. | `ntm serve` is planned read-only/local, but no auth/bind/field filter is specified in the security section. | W1S should require `127.0.0.1` default, redacted robot payloads, and no public bind without policy. | Lower severity because plan already says read-only and localhost/auth defaults in research. |

Counts: critical=0, high=4, medium=3, low=1.

## 3. Class-1-6 Mapping

No critical findings were found, so no mandatory class mapping or fuckup row is required.

Reference mapping to use if any high finding escalates during implementation:

1. security/secret/credential decision
2. PHI/PII/regulated/customer-trust decision
3. destructive operation or data-loss approval
4. budget/vendor/legal envelope exception
5. Joshua-personal external action after L48 substrate exhaustion
6. paradigm-conflict/no matching blocker class

## 4. DCG Authority Preservation Verdict

Verdict: **YES, conditional on W2D becoming mechanical.**

Evidence:

- `00-PLAN.md` explicitly says DCG remains authority and NTM safety may preflight/classify.
- `dcg/SKILL.md` says blocks are checkpoints; agents must not retry, circumvent, or lead with override.
- Live probe: trying to run `ntm safety check` over a destructive-command string was blocked before NTM evaluated it. That proves DCG currently sits earlier than native safety in this command path.

Condition:

- W2D must assert "NTM verdict may only match or strengthen DCG." A weaker NTM allow, timeout, parse error, missing DCG, or approval-token substitute must fail closed.

## 5. `ntm safety` Bypass-Path Enumeration

1. Substitution: worker runs only `ntm safety check` and skips DCG.
2. Allowlist drift: `.ntm/policy.yaml` allows a command DCG blocks.
3. Hook-order drift: `ntm safety install/uninstall` changes wrappers before DCG hooks run.
4. Fail-open drift: NTM safety timeout/non-JSON parse error is treated as pass.
5. Approval confusion: `ntm approve` token is treated as DCG `allow-once`.
6. Shell-boundary bypass: command executes through subprocess/remote/embedded script path not seen by DCG.
7. Secret-redaction bypass: global `--allow-secret`, `--redact off`, or policy override hides secret findings.
8. Automation escalation: `ntm policy automation` enables auto-push/force-release/auto-commit beyond AGENTS authority.

safety_bypass_paths: 8

## 6. `ntm scrub` Pattern Coverage

Current flywheel coverage sources:

- `templates/josh-request-schema.md` / archive: AWS, GitHub, Anthropic, OpenAI, xAI, JWT, bearer, Google, Slack, base64-ish, and near-secret-keyword families.
- `.flywheel/scripts/dispatch-author-contract-probe.sh`: packet-level regex for API keys, bearer strings, registration tokens, private keys, and JWT-like strings.
- `tests/dcg-secret-leak-overrides.sh`: raw Infisical list/get/plain/run/export, JWT-like literals, and Supabase ref literals.
- `.flywheel/MISSION.md` SEC-001..006: bans token fragments, raw env output, Agent Mail bearer/registration tokens, secret-bearing pane text, and unsafely broad credential receipts.

Native NTM scrub observed from help/docs:

- Scans chosen paths using built-in redaction engine.
- Outputs placeholders only, not raw matches.
- Default scan roots are NTM config and `~/.ntm`; explicit `--path` is required for dispatch/evidence artifacts.

Gap list that W2S must prove with synthetic fixtures before `secret_scan=PASS`:

1. Agent Mail `registration_token` / `sender_token` key families.
2. Infisical raw command/output markers: `secretValue`, raw env output, unsafe list/get/plain/run/export shapes.
3. Provider keys: Anthropic, OpenAI including project keys, xAI, GitHub classic/fine-grained, AWS, Google, Slack.
4. Bearer/auth header strings.
5. JWT-like strings.
6. Private key blocks.
7. Base64-ish long strings and near-secret-keyword heuristics.
8. Supabase/project-ref literals currently blocked by DCG tests.
9. Token file paths/hashes where policy says names only or local-only.
10. Secret-bearing pane text copied into callbacks, reports, MISSION excerpts, or audit exports.

scrub_gap_count: 10

## 7. Convergence Verdict

convergence_verdict: `findings_require_r2_focus_on=w2-security-gate-parity`

Reason: no critical blocker, but W2 is now the convergence focus. The plan is architecturally sound only if W2S/W2D/W2A encode scrub parity, DCG match-or-stricter behavior, approval operation enums, and pre-callback scan order as mechanical gates.

## 8. Three-Judges Sniff

- Jeff: 8.2/10. Native-first is fine, but W2 needs exact parity fixtures before wrapper removal.
- Donella: 8.8/10. The strongest leverage is moving security information flows before send/callback, not adding another report.
- Joshua: 8.4/10. Keep DCG and SEC-001..006 load-bearing; do not trust new native surfaces until they prove they preserve the annoying fields.
- Self-grade: 8.4/10. Plan-space audit found no criticals, but r2 should tighten W2 security gate contracts before ship dispatch.

L112: `OK_ntm_surface_migration_audit_security_r1`

Mission anchor: `continuous-orchestrator-uptime-self-sustaining-fleet`
