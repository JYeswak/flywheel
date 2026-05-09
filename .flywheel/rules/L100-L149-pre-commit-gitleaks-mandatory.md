## L149 — PRE-COMMIT-GITLEAKS-MANDATORY

---
id: L149
title: Pre-commit gitleaks mandatory plus rank-3 secret handles
status: long_term
shipped: 2026-05-09
review_due: 2026-11-09
trauma_class: rank-3-secret-handle-drift
---

Every flywheel-onboarded repo MUST install a repo-local pre-commit secret
scanner before it can be called security-clean, and every secret-adjacent
worker flow MUST keep agents at the handle layer rather than the raw-value
layer. The rank-3 invariant is: agents may name secret classes, key names,
vault paths, and redacted handles; they do not hold or echo raw secret values.
Secrets are dereferenced only at CI, build, deploy, or other execution
boundaries that already own the credential principal.

**How to apply:**
- Phase 1 canonical rule: the installed repo doctrine carries this L-rule on
  all three L96 surfaces.
- Phase 2 wire-up: onboarding installs or repairs the committed security
  pre-commit hook idempotently. The hook may use gitleaks or the repo-local
  redacted synthetic scanner, but output must be class/path/line only and must
  never emit matched values.
- Doctor exposes `pre_commit_secret_scanner_installed=yes|no` or an equivalent
  `security.precommit_hook_installed` boolean. Missing hook is WARN during the
  seven-day migration grace window and FAIL after the grace expires.
- Doctor also exposes `pretooluse_bash_diagnostic_hook_installed=yes|no` per
  orchestrator session. Missing hook is WARN until the global PreToolUse Bash
  hook is authorized and installed.
- Dispatch packets, callback evidence, validation docs, runbooks, PR
  descriptions, and handoffs use secret handles such as
  `<INFISICAL_HANDLE:path.to.SECRET_NAME>` or redaction labels, not values.
- Evidence collection for secret-adjacent tasks must run through a redactor or
  scanner before write-time. Phase 4 callback contracts track this as
  `evidence_redacted=yes|no|n/a`. `yes` is required when `files_reserved`
  includes evidence-class paths (`*/evidence/*`, `*/validation/*`,
  `*/secrets/*`, or `*/.flywheel/*-evidence.md`). `n/a` is valid only when no
  evidence-class file was touched. `no` is a close rejection until the worker
  runs `gitleaks --no-git --piped` or the repo redactor and regenerates the
  evidence.

**Vector #6 readback rule:** Orchestrator Bash MUST NOT read contents of any
file under `/tmp/` that was written from `infisical`, `curl`, `vercel env pull`,
or `gitleaks` source material in the same session. Permitted operations on
tainted tmp files are metadata/key-only operations: `shasum`, `wc -c`,
`jq 'keys'`, and `jq -r '.[].secretKey'`. Forbidden operations include
`head -c`, `cat`, `tail`, `grep`, `awk`, `sed`, `jq -r '.[].value'`, and any
other value-revealing readback on tainted tmp files.

**Forbidden outputs:**
- Closing a repo as security-clean while the pre-commit secret scanner is
  missing, bypassed, or value-emitting.
- Printing raw env output, secret values, token fragments, database URLs, Agent
  Mail tokens, or bearer tokens into pane text, dispatch packets, callbacks,
  reports, validation docs, or runbooks.
- Reading a tainted `/tmp` safe-sink file back into context with value-revealing
  commands after it was written from secret-bearing sources.
- Closing a secret-adjacent or evidence-writing callback with
  `evidence_redacted=no`, or using `evidence_redacted=n/a` while reserved files
  include evidence-class paths.
- Rotating secrets as the first response to a leak class before the structural
  no-leak substrate is landed and proven. Joshua owns rotation timing.

**Evidence:** bead `flywheel-hv071`; skillos cross-orch handoffs
`.flywheel/handoffs/2026-05-08T212656Z-from-skillos-1-secrets-l-rule-promotion.md`
and
`.flywheel/handoffs/2026-05-08T220500Z-from-skillos-1-vector-6-l-rule-extension.md`;
skillos state
`/Users/josh/Developer/skillos/state/secrets-leak-prevention-rank-3-doctrine-2026-05-08.json`;
mobile-eats Nango credential commit `63c9d58`; mobile-eats vector-6
`DATABASE_URL` readback incident; security surfaces
`.flywheel/scripts/security-precommit-installer.sh`, `githooks/pre-commit`,
`.flywheel/security/v1/secret-patterns.json`, `tests/security-precommit-hook.sh`,
and `tests/doctor-security-posture.sh`; Phase 3 skillos linter PR #90; Phase 4
callback contract bead `flywheel-dwavb`.

Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet.

**Cross-references:** L48, L50, L51, L52, L53, L58, L60, L61, L71, L96, L107,
L120, L125, L136, and SEC-001..006.

