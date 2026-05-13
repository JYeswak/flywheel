# True Publication Release-Blocker Registry

Created: 2026-05-13T01:15Z
Status: active registry
Scope: every TODO, gap item, audit finding, doctor warning, unproven support
claim, private-overlay dependency, and release-blocking ambiguity discovered
while moving Flywheel from public-preview readiness to true publication.

This registry is a release control surface. A row can close only with executable
evidence, a linked receipt, or an explicit non-release disposition. "Later" is
not a disposition.

## Registry Rules

1. Every new TODO/gap found during true-publication work gets a row here or a
   linked Bead/issue row before work continues past the local change.
2. Every `release_blocker` row must have an owner, evidence, next action, and
   closure proof before `v0.2.0` can publish.
3. Compatibility-target claims for Gemini/OpenClaw/Claude/Codex stay blocked
   until isolated receipts prove runtime behavior or public copy downgrades the
   claim.
4. Doctor warnings are not ignored; each is either fixed, mapped to this
   registry, or explicitly classified as non-release operational hygiene.

## Initial Rows

| ID | Class | Severity | Status | Owner | Source evidence | Required closure |
|---|---|---:|---|---|---|---|
| TP-001 | live-state-denylist | P0 | open | Flywheel | `03-AUDIT-FINDINGS.md` Class 5; `04-BEADS-DAG.md` B0.5 | Denylist exists, extractor refuses denylisted paths, synthetic denylist test fails closed. |
| TP-002 | engine-overlay-extraction | P0 | open | Flywheel | `01-RESEARCH-A.md`; B1-B4/B10 | Public export/branch installs without Joshua-local paths, private state, client material, or overlay-only dependencies. |
| TP-003 | depersonalization-scan | P0 | open | Flywheel | B1/B1.5/B3.1-B3.5 | Classification table, codemod, and grep/secret scans pass across docs/scripts/templates/tests/package metadata. |
| TP-004 | halted-propagator-disposal | P0 | open | Flywheel | `03-AUDIT-FINDINGS.md` Class 6a; B3.4 | Halted propagators excluded from public extraction or shipped non-executable with explicit warning and test proof. |
| TP-005 | public-repo-package-surface | P0 | open | Flywheel | B8/B9/B10/B11/B15 | Public repo or export path, package/install surface, release metadata, checksum, CI, and license posture are staged or published. |
| TP-006 | isolated-reduced-mode | P0 | open | Flywheel | B17/B17.5; `docs/getting-started/first-run.md` | Disposable isolated environment proves install, preflight, init, doctor, tick, dispatch/simulate, closeout, inspect. |
| TP-007 | isolated-claude-path | P0 | open | Flywheel | `10-HARNESS-SUPPORT-MATRIX.md`; B17.5 | Claude lane has isolated receipt or public copy downgrades claim with blocker class. |
| TP-008 | isolated-codex-path | P0 | open | Flywheel | `10-HARNESS-SUPPORT-MATRIX.md`; B17.5 | Codex lane has isolated receipt or public copy downgrades claim with blocker class. |
| TP-009 | isolated-gemini-path | P0 | open | Flywheel | `10-HARNESS-SUPPORT-MATRIX.md`; B17.5 | Gemini lane has isolated receipt or remains clearly compatibility-target with source/auth blocker. |
| TP-010 | isolated-openclaw-path | P0 | open | Flywheel | `10-HARNESS-SUPPORT-MATRIX.md`; B17.5 | OpenClaw lane has daemon/gateway smoke receipt or remains clearly compatibility-target with source/API blocker. |
| TP-011 | runbooks | P0 | open | Flywheel | B12.0-B12.3, B17 | Public runbooks contain exact commands, expected outputs, failure branches, and receipt locations for all supported paths. |
| TP-012 | public-journey-stories | P0 | open | Flywheel + ZestStream | B13.1-B13.7; Joshua SMB framing | SMB/business-owner story and developer/operator story are public, honest, and linked from repo/site. |
| TP-013 | methodology-consent-redaction | P0 | open | Flywheel + Joshua | `03-AUDIT-FINDINGS.md` Class 4/Class 6b; B11.5.0/B11.5/B13.4 | Case-study slot is methodology-reframed or consent matrix is complete; no named-client or implicit class leak ships. |
| TP-014 | skillos-boundary | P0 | open | Flywheel + SkillOS | B16; SkillOS handoff evidence | SkillOS capability-control-plane boundary is acked or 14-day fallback locks zero-skills v0.2 without overclaim. |
| TP-015 | external-review | P0 | open | Flywheel | B11.6 | Two non-Joshua reviewers approve or approve with follow-ups before release. |
| TP-016 | final-naming | P0 | open | Flywheel | `docs/brand/naming-conventions.md`; `tests/naming-conventions.sh` | Final repo/package/CLI/site naming is selected and tests reject stale/private names across public surfaces. |
| TP-017 | ci-workflows | P0 | open | Flywheel | Current file check: `.github/workflows/installer-smoke.yml` and `ci.yml` missing | CI and installer-smoke workflows exist and pass on supported OS matrix. |
| TP-018 | release-signoff | P0 | open | Joshua + Flywheel | B15 | Git tag, GitHub release, checks, website, install proxy, and Joshua signoff all present. |
| TP-019 | doctor-warning-disposition | P1 | open | Flywheel | Latest full doctor warning classes: callbacks, L-rule lag, oversized files, watcher fleet, unwired surfaces, closed-bead backlog, plan quality | Each warning fixed or classified as non-release with evidence; no release-blocking doctor error remains. |
| TP-020 | todo-gap-scanner | P1 | in_progress | Flywheel | `rg TODO/FIXME/gap/blocker/missing/unproven` finds public-surface rows | Add validation that fails release when TODO/gap rows lack registry, Bead, or explicit non-release disposition. |

## Progress Log

- 2026-05-13: Added `.flywheel/scripts/true-publication-registry-validate.py`
  and `tests/true-publication-registry-validate.sh`. The validator now proves
  registry row shape, unique IDs, required fields, and release-mode failure when
  rows remain open. TP-020 stays `in_progress` until TODO/gap scan coverage is
  tied to this registry or linked Beads.

## Immediate Next Actions

1. Wire a lightweight registry validator so TP-020 becomes executable instead of
   prose.
2. Reconcile open public-share Beads against this table: closed rows need
   receipt paths; open rows need owner and next action.
3. Start critical path at TP-001/TP-002/TP-003 because isolated install proof is
   meaningless until public extraction cannot leak private substrate.
