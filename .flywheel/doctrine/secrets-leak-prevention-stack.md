---
title: "Secrets Leak Prevention Stack"
type: doctrine
created: 2026-05-09
frontmatter_source: scaffold-doc-frontmatter
---

# Secrets Leak Prevention Stack

Status: Phase 4 callback contract landed by `flywheel-dwavb`.
Mission anchor: continuous-orchestrator-uptime-self-sustaining-fleet.

## Rank-3 Invariant

Agents handle secret references, not secret values. Dispatch packets, callbacks,
runbooks, validation evidence, PR descriptions, and reports may name secret
classes, key names, vault paths, and redaction labels. They must not contain raw
secret values, token fragments, raw env output, database URLs with credentials,
Agent Mail bearer tokens, or registration tokens.

Secrets are dereferenced only at execution boundaries that own the credential:
CI runtime, build runtime, deploy runtime, or a deliberately isolated sandbox.
Joshua owns rotation timing. The structural fix lands before rotation churn.

## Layer A: PreToolUse Bash Hook

Owner: `skillos:1`.

Purpose: prevent orchestrator Bash from turning safe sinks back into transcript
leaks. The hook tracks tainted `/tmp` files written from secret-bearing sources
such as `infisical`, `curl`, `vercel env pull`, and `gitleaks`, then blocks
value-revealing readback.

Allowed tainted-file probes:

- `shasum`
- `wc -c`
- `jq 'keys'`
- `jq -r '.[].secretKey'`

Forbidden tainted-file readback:

- `head -c`
- `cat`
- `tail`
- `grep`
- `awk`
- `sed`
- `jq -r '.[].value'`
- any other operation that reveals values from a tainted safe-sink file

Doctor invariant: `pretooluse_bash_diagnostic_hook_installed=yes|no` per
orchestrator session. Missing is WARN until the global hook is authorized and
installed.

## Layer B: Vercel-Infisical Native Path

Owner: `mobile-eats:1` for the originating deploy concern.

Purpose: remove unnecessary agent possession of deploy secrets by using native
Vercel/Infisical integration where the deploy substrate can hold the credential
principal directly. This is per-repo deploy work, not the canonical flywheel
Phase 1 close.

## Layer C: Rank-3 Generalization To Diagnostics

Owner: `skillos:1`.

Purpose: generalize the incident class beyond commit-time leaks. Safe-sink writes
are not sufficient when diagnostics read the sink back into the pane. The
canonical rule is handle-first: inspect shape, keys, sizes, checksums, and class
names without revealing values.

Source state:
`/Users/josh/Developer/skillos/state/secrets-leak-prevention-rank-3-doctrine-2026-05-08.json`.

## Layer D: AGENTS-CANONICAL L-Rule Extension

Owner: `flywheel:1`, bead `flywheel-hv071`.

Purpose: land the long-term operating rule in the flywheel doctrine surfaces.
The L-rule is L149 `PRE-COMMIT-GITLEAKS-MANDATORY`, carried in:

- `AGENTS.md`
- `.flywheel/AGENTS-CANONICAL.md`
- `templates/flywheel-install/AGENTS.md`

## Dispatch Architecture

Phase 1: canonical doctrine.

- Land L149 on all L96 surfaces.
- Document the stack in this file.
- Update README so new workers know where the security-clean rule lives.

Phase 2: wire-up.

- `flywheel-onboard.sh` installs or repairs the committed pre-commit scanner.
- Doctor emits `pre_commit_secret_scanner_installed=yes|no` or the equivalent
  `security.precommit_hook_installed` field.
- Existing repos get a seven-day WARN grace window before missing hooks become
  FAIL.

Phase 3: skillos linter.

- Skillos PR #90 is the dispatch linter and wrapper path.
- Dispatch packet composition rejects raw secret patterns before worker launch.

Phase 4: `evidence_redacted`.

- Bead `flywheel-dwavb` owns the callback contract extension.
- Worker DONE callbacks report `evidence_redacted=yes|no|n/a`.
- `yes` means evidence-class files were scanned or redacted before close.
- `no` is a close rejection. The worker owns remediation: run
  `gitleaks --no-git --piped` or the repo redactor against the evidence file,
  regenerate the durable evidence, and resend with `evidence_redacted=yes`.
- `n/a` is valid only when no evidence-class files were touched.
- The validator treats these reserved paths as evidence-class:
  `*/evidence/*`, `*/validation/*`, `*/secrets/*`, and
  `*/.flywheel/*-evidence.md`.

## Full Architecture

The prevention stack is four layers plus the rank-3 convention:

1. Pre-commit gitleaks or the synthetic redacted scanner blocks commit-time
   secret leakage before a repo is called security-clean.
2. The flywheel onboarding and doctor path wire the scanner and report install
   posture during the seven-day migration window.
3. Skillos PR #90 wraps dispatch creation with a linter so packet text does not
   launch workers with raw secret material.
4. Phase 4 callback validation makes evidence redaction an explicit close
   field, so validation and evidence artifacts cannot become the leak path after
   the code or packet surfaces were made clean.
5. The rank-3 convention keeps agents at handle level throughout: secret class,
   key name, vault path, hash, count, and redaction label are valid; raw values,
   token fragments, credential-bearing URLs, and raw env output are not.

## Evidence

- `flywheel-hv071`
- `.flywheel/handoffs/2026-05-08T212656Z-from-skillos-1-secrets-l-rule-promotion.md`
- `.flywheel/handoffs/2026-05-08T220500Z-from-skillos-1-vector-6-l-rule-extension.md`
- `mobile-eats` Nango credential leak, commit `63c9d58`
- `mobile-eats` vector-6 DATABASE_URL diagnostic readback incident
- `.flywheel/scripts/security-precommit-installer.sh`
- `githooks/pre-commit`
- `.flywheel/security/v1/secret-patterns.json`
- `tests/security-precommit-hook.sh`
- `tests/doctor-security-posture.sh`
- `flywheel-dwavb`
- `.flywheel/scripts/validate-callback.py`
- `tests/validate-callback.sh`
- `~/.claude/commands/flywheel/_shared/dispatch-template.md`
- `~/.claude/commands/flywheel/worker-tick.md`

## Four-Lens Self-Grade

four_lens=brand:9,sniff:9,jeff:9,public:8

Brand: puts the system goal at the rank-3 handle layer rather than reactive
rotation.

Sniff: names both observed leak vectors and the exact boundaries each layer
owns.

Jeff: preserves Beads/Agent Mail attribution boundaries by naming classes and
handles, not values or tokens.

Public: a future worker can tell which phase owns hook install, linter, and
callback redaction without reading pane history.
