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
| TP-001 | live-state-denylist | P0 | closed | Flywheel | `03-AUDIT-FINDINGS.md` Class 5; `04-BEADS-DAG.md` B0.5; `bash tests/live-state-denylist.sh` pass=14 fail=0 | Denylist covers `.ntm`, SQLite state, Beads ledgers, PLANS/audit/evidence/receipts, handoffs, credentials, secret-leak ledgers, halted propagators, and synthetic tests prove fail-closed/manual-review behavior. |
| TP-002 | engine-overlay-extraction | P0 | closed | Flywheel | `01-RESEARCH-A.md`; B1-B4/B10; B2 classifier implemented and fixture-tested; B3.1-B3.5 closed from staged sweeps; B4 closed from assembly run `20260513T024740`; B10 closed with `manual-review.closed.jsonl` 7374/7374 rows signed | Public staging tree exists, private/overlay state is excluded, depersonalization scans pass, halted propagators are absent, source git status stays unchanged, and manual-review queue is fully signed. |
| TP-003 | depersonalization-scan | P0 | closed | Flywheel | B1/B1.5/B3.1-B3.5; docs/scripts/templates/tests/README/.github scans pass; public prepublish and secret override tests pass | Classification table, codemod, and grep/secret scans pass across docs/scripts/templates/tests/package metadata. |
| TP-004 | halted-propagator-disposal | P0 | closed | Flywheel | `03-AUDIT-FINDINGS.md` Class 6a; B3.4; `bash tests/live-state-denylist.sh` pass=14 fail=0 | Halted propagators excluded from public extraction or shipped non-executable with explicit warning and test proof. |
| TP-005 | public-repo-package-surface | P0 | open | Flywheel | B8/B9/B10/B11/B14.5/B15; local CI/release/site workflows and static `site/` source authored; `23-TP-005-017-018-PUBLICATION-READINESS-RECEIPT.md`; private Vercel deploy receipt `state/private-live-site-deploy.receipt.json` | Public repo or export path, package/install surface, release metadata, checksum, CI, and license posture are staged or published. Current live blockers: remote repo is private and release `v0.2.0` is absent; private-live website content and install proxy checksum proof now pass. |
| TP-006 | isolated-reduced-mode | P0 | closed | Flywheel | B17/B17.5; `docs/getting-started/first-run.md`; `bash tests/installer-smoke.sh` pass=10 fail=0; `bash tests/journey-smoke.sh` pass=7 fail=0; `flywheel-zcljr` | Disposable isolated reduced-mode environment proves installer dry-run, install, installed files, reduced preflight, doctor, init, tick, dispatch/simulate, closeout validation, inspect, idempotent reinstall, uninstall, and byte-equality empty-prefix cleanup. |
| TP-007 | isolated-claude-path | P0 | closed | Flywheel | `scripts/preflight.sh`; `scripts/agent-lane-probe.sh`; `receipts/agent-lanes/claude.json`; `docs/runbooks/agent-lane-compatibility.md`; `bash tests/preflight-fixtures.sh` pass=19 fail=0; `bash tests/agent-lane-probe.sh` pass=10 fail=0; `bash tests/journey-smoke.sh` pass=7 fail=0; `flywheel-9adlp`; `flywheel-4oed2` | Claude lane is public copy downgraded to compatibility-target with an explicit blocker receipt until a strict isolated runtime receipt marks `runtime_proven=true`; CLI presence, weak receipts, duplicate/conflicting stage rows, and private-state findings do not permit supported copy. |
| TP-008 | isolated-codex-path | P0 | closed | Flywheel | `scripts/preflight.sh`; `scripts/agent-lane-probe.sh`; `receipts/agent-lanes/codex.json`; `docs/runbooks/agent-lane-compatibility.md`; `bash tests/preflight-fixtures.sh` pass=19 fail=0; `bash tests/agent-lane-probe.sh` pass=10 fail=0; `bash tests/journey-smoke.sh` pass=7 fail=0; `flywheel-9adlp`; `flywheel-4oed2` | Codex lane is public copy downgraded to compatibility-target with an explicit blocker receipt until a strict isolated runtime receipt marks `runtime_proven=true`; CLI presence, weak receipts, duplicate/conflicting stage rows, and private-state findings do not permit supported copy. |
| TP-009 | isolated-gemini-path | P0 | closed | Flywheel | `scripts/preflight.sh`; `scripts/agent-lane-probe.sh`; `receipts/agent-lanes/gemini.json`; `docs/runbooks/agent-lane-compatibility.md`; `bash tests/preflight-fixtures.sh` pass=19 fail=0; `bash tests/agent-lane-probe.sh` pass=10 fail=0; `bash tests/journey-smoke.sh` pass=7 fail=0; `flywheel-9adlp`; `flywheel-4oed2` | Gemini lane remains compatibility-target with an explicit blocker receipt until a strict runtime receipt proves journey behavior with `runtime_proven=true`, exactly one passing row for each required stage, and no private-state findings. |
| TP-010 | isolated-openclaw-path | P0 | closed | Flywheel | `scripts/preflight.sh`; `scripts/agent-lane-probe.sh`; `receipts/agent-lanes/openclaw.json`; `docs/runbooks/agent-lane-compatibility.md`; `bash tests/preflight-fixtures.sh` pass=19 fail=0; `bash tests/agent-lane-probe.sh` pass=10 fail=0; `bash tests/journey-smoke.sh` pass=7 fail=0; `flywheel-9adlp`; `flywheel-4oed2` | OpenClaw lane remains compatibility-target with an explicit blocker receipt until daemon or gateway smoke proves runtime behavior with `runtime_proven=true`, exactly one passing row for each required stage, and no private-state findings. |
| TP-011 | runbooks | P0 | closed | Flywheel | `docs/runbooks/public-release-runbook.md`; `docs/getting-started/first-run.md`; `flywheel-v1pz4`; `bash tests/naming-conventions.sh` pass=63 fail=0 | Public runbook now contains exact commands, expected output keys, failure branches, and receipt locations for reduced mode, matrix probes, install/uninstall, doctor, public gates, and closeout. |
| TP-012 | public-journey-stories | P0 | closed | Flywheel + ZestStream | `docs/stories/public-journey-and-redaction.md`; `CHARTER.md`; README links; `flywheel-v1pz4` | SMB/business-owner story and developer/operator story are public, honest, linked from the repo front door, and do not claim full harness support before runtime receipts. |
| TP-013 | methodology-consent-redaction | P0 | closed | Flywheel + Joshua | `docs/stories/public-journey-and-redaction.md`; TP-003 depersonalization gates; TP-020 public-surface scanner; `flywheel-v1pz4` | v0.2 case-study slot is methodology-reframed as Flywheel-on-Flywheel using operator-side release metrics only; external customer stories require per-surface consent; no named-client or implicit class leak ships in the public story. |
| TP-014 | skillos-boundary | P0 | closed | Flywheel + SkillOS | B16; Agent Mail messages `504` and `505`; `20-SKILLOS-CAPABILITY-BOUNDARY-HANDOFF-RECEIPT.md` | SkillOS accepted the v0.2 boundary as written: Flywheel owns public installability/loop engine, SkillOS owns capability control plane, proof surfaces are scoped, no private SkillOS state ships, and zero-ambient-skills v0.2 is acceptable pending later capability-pack ratification. |
| TP-015 | external-review | P0 | closed | Flywheel | B11.6; `flywheel-gr403.1`; `22-TP-015-EXTERNAL-REVIEW-PACKET.md`; `review-log.jsonl`; `docs/evidence/external-review-log.jsonl`; supplemental Agent Mail messages `509`/`510`/`511`/`512`; Mobile Eats row `2026-05-13T11:03:31Z`; Gemini CLI row `2026-05-13T11:15:00Z` | Two distinct non-Joshua reviewers cover the current public trust surface including `docs/evidence/publication-blocker-coverage.md`, with valid UTC timestamps and empty `blocking_findings`; private and public evidence logs validate under `scripts/validate_external_review.py --release --json`. |
| TP-016 | final-naming | P0 | closed | Flywheel | `docs/brand/naming-conventions.md`; `tests/naming-conventions.sh`; `bash tests/naming-conventions.sh` pass=63 fail=0; `flywheel-kl293` | Final repo/package/CLI/site naming is selected: repo `github.com/JYeswak/flywheel`, CLI/package namespace `flywheel`, SMB site `flywheel.zeststream.ai`, docs site `docs.flywheel.zeststream.ai`, and install endpoint `flywheel.zeststream.ai/install.sh`; tests reject stale/private names across public surfaces and stale support-tier vocabulary across publication plan surfaces. |
| TP-017 | ci-workflows | P0 | open | Flywheel | `.github/workflows/ci.yml`, `installer-smoke.yml`, `release.yml`, and `site.yml` authored; local contract/lint/smoke pass; `23-TP-005-017-018-PUBLICATION-READINESS-RECEIPT.md` | Required remote workflows exist and CI/installer-smoke pass on supported OS matrix. Current live blocker: GitHub remote reports no workflows or successful runs. |
| TP-018 | release-signoff | P0 | open | Joshua + Flywheel | B15; `23-TP-005-017-018-PUBLICATION-READINESS-RECEIPT.md`; `release-signoff.template.json`; TP-015 external-review gate closed for the current seven-surface public trust set | Git tag, GitHub release, checks, external review, and Joshua signoff all present. Current live blockers: release `v0.2.0`, release assets, remote checks, and Joshua signoff are absent; private-live website and install proxy checksum proof now pass. |
| TP-019 | doctor-warning-disposition | P1 | closed | Flywheel | `21-TP-019-DOCTOR-WARNING-DISPOSITION.md`; `flywheel-2djra`; full doctor status `warn` with `errors=[]`; publishability bar `pass` score 7/7; Agent Mail FD doctor `PASS`; Beads source repo normalization pass=6 fail=0 | Hard doctor errors were fixed; remaining callback, L-rule lag, oversized-file, watcher, capture-parity, surface-wiring, closed-bead, and plan-quality warnings are classified as non-release private-fleet/historical hygiene for public v0.2 and remain visible in doctor output. |
| TP-020 | todo-gap-scanner | P1 | closed | Flywheel | `bash tests/public-surface-gap-scanner.sh` pass=14 fail=0; `python3 .flywheel/scripts/public-surface-gap-scanner.py --repo . --release --json` status=pass file_count=48 undispositioned_count=0 | Public-surface gap scanner fails release when TODO/FIXME/gap/blocker/missing/unproven markers lack TP row, Bead id, or explicit non-release disposition; CI contract includes the scanner and covers the current evidence/runbook/site workflow surfaces. |

## Live Publication Blocker Coverage

This table maps current `scripts/publication_readiness.py --json` live blocker
codes to release-blocker registry rows. Update this table when readiness blocker
codes change.

| Readiness blocker code | Registry rows | Coverage status |
|---|---|---|
| `remote_repo_private` | `TP-005` | open |
| `remote_workflows_missing` | `TP-017` | open |
| `remote_green_runs_missing` | `TP-017` | open |
| `github_release_missing_or_draft` | `TP-018` | open |
| `github_release_assets_missing` | `TP-018` | open |
| `joshua_release_signoff_missing` | `TP-018` | open |

## Progress Log

- 2026-05-13: Added `.flywheel/scripts/true-publication-registry-validate.py`
  and `tests/true-publication-registry-validate.sh`. The validator now proves
  registry row shape, unique IDs, required fields, and release-mode failure when
  rows remain open. TP-020 stays `in_progress` until TODO/gap scan coverage is
  tied to this registry or linked Beads.
- 2026-05-13: Closed TP-001 by expanding `state/live-state-denylist.yaml` to
  cover the Class 5 audit paths (`state.db*`, `beads.db*`,
  `.beads/issues.jsonl`, `.flywheel/PLANS/**`, `.flywheel/audit/**`,
  `.flywheel/evidence/**`, `.flywheel/receipts/**`, and
  `secret-leak-ledger.jsonl`) and extending `tests/live-state-denylist.sh` to
  13 focused assertions. Evidence: `bash tests/live-state-denylist.sh` passed;
  `python3 scripts/depersonalize.py --probe-denylist --root . --json` refuses
  the raw working tree with private-state findings as expected.
- 2026-05-13: Advanced TP-003 but kept it open. Fixed the bead-id regex so
  `flywheel-first-run-target` is not treated as a bead ID, parameterized the
  remaining Joshua-path literals in public scripts, and added
  `state/depersonalization-scan-allowlist.yaml` for reviewed public brand
  mentions. Evidence: `docs/` and `scripts/` depersonalization scans pass with
  zero findings; `templates/` still fails with 238 findings and `tests/` still
  fails with 4 denylist findings, so TP-003 remains release-blocking.
- 2026-05-13: Advanced TP-003 further but kept it open. Depersonalized
  `templates/flywheel-install`, converted checked-in SkillOS/Mobile Eats
  allowlist fixtures to public slugs (`capability-control-plane`,
  `proof-product`), fixed template ledger replay `trust_domain`, corrected the
  render smoke to use the installed-template publishability bar, and made
  file-RAG template tests avoid dirtying checked-in state. Evidence:
  `python3 scripts/depersonalize.py --scan-table --root docs --json`,
  `--root scripts`, and `--root templates` all return zero findings;
  `find templates/flywheel-install/tests -maxdepth 1 -type f -name '*.sh' -print0 | sort -z | xargs -0 -n1 bash`
  passes; `bash tests/depersonalize-table-codemod.sh`,
  `bash tests/live-state-denylist.sh`, `bash tests/naming-conventions.sh`,
  `bash tests/installer-smoke.sh`, and
  `bash tests/true-publication-registry-validate.sh` pass. Remaining blocker:
  `python3 scripts/depersonalize.py --scan-table --root tests --json` now
  passes the denylist fixture layer but exposes 2239 replacement-table findings
  across historical/synthetic tests, so tests remain release-blocking until
  codemodded, narrowly allowlisted, or excluded from the public export with
  evidence.
- 2026-05-13: Closed TP-003. Added root-scoped depersonalization allowlist
  support so reviewed fixture-only `iso-timestamp`, `bead-id`, and
  `pane-number` rows pass only under a `tests` scan root; added single-file
  scan-root support for package metadata; codemodded private README and
  `.github` path/session/operator examples while preserving intentional public
  ZestStream ownership mentions through reviewed allowlist rows. Evidence:
  `bash tests/depersonalize-table-codemod.sh` pass=13 fail=0;
  `python3 scripts/depersonalize.py --scan-table --root docs --json`,
  `--root scripts`, `--root templates`, `--root tests`, `--root README.md`,
  and `--root .github` all return `status=pass` with zero findings;
  `bash tests/depersonalization-table.sh`, `bash tests/live-state-denylist.sh`,
  `bash tests/naming-conventions.sh`, `bash tests/installer-smoke.sh`,
  `bash tests/zeststream-public-prepublish-hook.sh`,
  `bash tests/dcg-secret-leak-overrides.sh`,
  `bash tests/true-publication-registry-validate.sh`, and
  `find templates/flywheel-install/tests -maxdepth 1 -type f -name '*.sh' -print0 | sort -z | xargs -0 -n1 bash`
  pass.
- 2026-05-13: Advanced TP-002 by closing DAG node B2 classification pass.
  Added `scripts/classify.py`, which emits `classification.jsonl` rows with
  `engine`, `engine-after-rewrite`, or `overlay` classes, explicit reasons,
  manual-review flags, and rewrite signals. Added a 20-file synthetic fixture
  corpus under `fixtures/classify/source` and `tests/classify.sh`. Evidence:
  `bash tests/classify.sh` pass=5 fail=0; `python3 scripts/classify.py
  --self-test --json` returns `status=pass`, `total_files=20`, and
  `null_class_count=0`; full repo run `python3 scripts/classify.py --root .
  --output <tmp>/classification.jsonl --json` returns `status=pass`,
  `total_files=14571`, `null_class_count=0`, and writes 14571 JSONL rows.
  TP-002 remains open because B3/B4/B10 still need extraction-tree sweeps,
  assembly, and manual-review queue closure before the public branch/export is
  release-safe.
- 2026-05-13: Closed TP-004 using the exclusion path ratified by Class 6a.
  `state/live-state-denylist.yaml` denies all three halted propagator filenames
  (`canonical-doctrine-sync.sh`, `sync-canonical-doctrine.sh`, and
  `agents-md-fleet-propagator.sh`) with `reason_code=halted_propagator`, and
  `tests/live-state-denylist.sh` now proves all three fail closed in a
  synthetic public-extraction tree. Evidence: `bash tests/live-state-denylist.sh`
  pass=14 fail=0; tests depersonalization scan remains clean.
- 2026-05-13: Advanced TP-014/B16 by sending the SkillOS capability-control-plane
  boundary handoff. Evidence: Agent Mail message `504` with subject
  `flywheel-skill-boundary-v0.2`, storage topic `flywheel-skill-boundary-v0-2`
  because MCP topic validation rejects dots, plus live WezTerm SkillOS pane `1`
  queued handoff. Receipt:
  `20-SKILLOS-CAPABILITY-BOUNDARY-HANDOFF-RECEIPT.md`. TP-014 remains
  `in_progress` until SkillOS acknowledges or the 2026-05-27T02:25:26Z
  zero-ambient-skills fallback is explicitly locked.
- 2026-05-13: Closed TP-014/B16 by acknowledgement path. SkillOS replied in
  Agent Mail message `505` on thread `504` and accepted the boundary as written:
  Flywheel owns public installability and loop-engine surfaces; SkillOS owns the
  capability control plane; Red Hat/SMB and Mobile Eats L170 are proof surfaces,
  not mission ceilings or ownership transfer; public Flywheel can name SkillOS
  as the capability-control-plane integration point without copying private
  SkillOS state; and zero-ambient-skills v0.2 is acceptable pending later
  capability-pack ratification. Receipt updated:
  `20-SKILLOS-CAPABILITY-BOUNDARY-HANDOFF-RECEIPT.md`.
- 2026-05-13: Closed TP-016 by turning the naming convention into an executable
  public-surface gate. `docs/brand/naming-conventions.md` now names the
  canonical public repository, CLI/package namespace, SMB site, docs site, and
  install endpoint. `tests/naming-conventions.sh` scans the release-facing
  README, charter, contribution, security, support, code-of-conduct, changelog,
  architecture, first-run, issue template, workflow, installer, CLI, preflight,
  and journey-smoke files for stale private operator markers, superseded product
  names, private lowercase fleet slugs, and accidental `yuzu` command/package
  namespace use. Evidence: `bash tests/naming-conventions.sh` pass=50 fail=0;
  `python3 scripts/depersonalize.py --scan-table --root docs --json` passes.
- 2026-05-13: Closed TP-006 with executable isolated reduced-mode evidence.
  `bash tests/installer-smoke.sh` passed 10/0, proving installer dry-run,
  install, installed files, reduced preflight from the installed binary,
  installed doctor, reduced first-run, idempotent reinstall, uninstall, and
  byte-equality empty-prefix cleanup. `bash tests/journey-smoke.sh` passed 7/0,
  proving the public reduced lane through preflight, init, doctor, tick,
  simulated dispatch, closeout validation, inspect, reduced-only matrix,
  unknown-lane rejection, and private-marker-free output. A direct reduced
  matrix probe returned `runtime_proven=true`, `registry_valid=true`, and
  `dispatch_or_simulate=pass`.
- 2026-05-13: Closed TP-019 by fixing the hard doctor errors and recording an
  explicit warning disposition. Public-copy banned-word failure is gone,
  Beads source repo leakage is zero in DB and JSONL, and Agent Mail FD pressure
  is below thresholds after the LaunchAgent restart. Remaining full-doctor
  warnings are classified in
  `21-TP-019-DOCTOR-WARNING-DISPOSITION.md` as private-fleet, historical
  validation, or maintainability hygiene that does not block the v0.2 public
  installer/reduced-mode release gate. Evidence:
  `bash tests/beads-source-repo-basename-normalization.sh` pass=6 fail=0;
  `.flywheel/scripts/agent-mail-fd-doctor.sh --doctor --json` status `PASS`;
  `.flywheel/scripts/publishability-bar.sh --doctor --json --repo /Users/josh/Developer/flywheel`
  status `pass`, score 7/7; full doctor status `warn` with `errors=[]`.
- 2026-05-13: Closed TP-011, TP-012, and TP-013 with public docs. Added
  `docs/runbooks/public-release-runbook.md` for exact commands, expected output
  keys, failure branches, and receipt locations across reduced mode, matrix
  probes, install/uninstall, doctor, public gates, and closeout. Added
  `docs/stories/public-journey-and-redaction.md` to separate the SMB trust
  story, developer story, and consent boundary: v0.2 uses the
  Flywheel-on-Flywheel meta-story with operator-side metrics only; external
  customer stories require explicit per-surface consent. README and first-run
  docs now link both pages. Bead: `flywheel-v1pz4`.
- 2026-05-13: Advanced TP-002/B4 by adding `scripts/assemble.py`, generated
  staging ignore coverage for `.flywheel/extraction/`, synthetic assembly
  fixtures, and `tests/assemble.sh`. The assembly pass classifies source files,
  copies only `engine` and `engine-after-rewrite` rows into staging, applies the
  depersonalization table inside staging, emits an assembly manifest, emits a
  manual-review JSONL queue, and records whether source git status changed.
  Evidence: `bash tests/assemble.sh` pass=7 fail=0; `bash tests/classify.sh`
  pass=5 fail=0; `python3 scripts/depersonalize.py --scan-table --root
  scripts/assemble.py --json` passes; `python3 scripts/depersonalize.py
  --scan-table --root tests/assemble.sh --json` passes. B4 remains open until
  B3.1-B3.5 extraction sweeps close.
- 2026-05-13: Optimized the B4 assembly pass after the first real run took
  32.18s for 14582 classified files, 10167 copied files, 4415 overlay rows, and
  3411 manual-review rows. Profile evidence showed `transform_text` consumed
  14.776s cumulative time, dominated by per-row public-value masking and string
  replacement. The implementation now applies only classification-matched
  depersonalization rows while preserving table order, and filters generated
  `.flywheel/extraction/` output from future assembly classifications. Fixture
  checksum proof passed for staged files and manual-review JSONL before/after
  the optimization. Follow-up assembly now also consumes
  `state/live-state-denylist.yaml` directly so private/manual-review paths are
  excluded from staging instead of relying on the narrower classifier overlay
  path list. Re-run evidence: real assembly pass `20260513T024740Z` produced
  classification_count=14583, copied_count=10117, overlay_count=4415,
  denylist_excluded_count=4025, manual_review_count=7374,
  source_git_status_unchanged=true, and runtime 18.36s.
- 2026-05-13: Closed B3.4 script sweep (`flywheel-j32kw`). Evidence from
  staging run `20260513T024740Z`: `python3 scripts/depersonalize.py
  --scan-table --root .flywheel/extraction/staging/scripts --json` passes with
  zero findings; the same scan passes with zero findings for
  `.flywheel/extraction/staging/.flywheel/scripts` and
  `.flywheel/extraction/staging/templates/flywheel-install/scripts`; full
  staging denylist probe and scan-table pass with zero findings; and `find`
  for `canonical-doctrine-sync.sh`, `sync-canonical-doctrine.sh`, and
  `agents-md-fleet-propagator.sh` returns count=0.
- 2026-05-13: Closed B3.1, B3.2, B3.3, B3.5, and B4 from staged extraction
  run `20260513T024740Z`. Evidence: `.flywheel/doctrine` plus
  `templates/flywheel-install/doctrine` contain 97 files and scan clean;
  `.flywheel/rules` contains 111 files and scans clean; AGENTS/state/memory
  surfaces scan clean; templates, `.flywheel/templates`, `.claude`, and
  skill/template staged surfaces scan clean; full staging denylist probe and
  scan-table pass with zero findings. B4 close evidence:
  `scripts/assemble.py` produced `.flywheel/extraction/staging` with
  source_git_status_unchanged=true, copied_count=10117,
  denylist_excluded_count=4025, and manual_review_count=7374; `bash
  tests/assemble.sh` pass=7 fail=0. TP-002 stays open because B10 must flush or
  sign the 7374 manual-review rows.
- 2026-05-13: Advanced B10 by adding `scripts/review_queue.py`,
  `tests/review-queue.sh`, and synthetic review-queue fixtures. The reducer
  summarizes manual-review JSONL and safely signs rows that are either excluded
  from staging by the denylist or covered by mode-A codemod plus clean staging
  scan evidence. Evidence: `bash tests/review-queue.sh` pass=4 fail=0. Applied
  to `.flywheel/extraction/manual-review-queue/20260513T024740Z/manual-review.jsonl`,
  it wrote `manual-review.signed-safe.jsonl`, signed 7224 rows by policy, and
  left 150 unsigned `mode_b_pattern_rewrite_required` rows. B10 remains open
  until those 150 rows are reviewed, rewritten, or reclassified with evidence.
- 2026-05-13: Closed B10 and TP-002. Extended `scripts/review_queue.py` so
  mode-B keyword rows require an explicit evidence string before policy signoff;
  `bash tests/review-queue.sh` now proves the evidence-required path. Applied
  the reducer with evidence `run 20260513T024740Z full staging denylist probe
  pass count=0 and scan-table pass count=0`, producing
  `.flywheel/extraction/manual-review-queue/20260513T024740Z/manual-review.closed.jsonl`
  with 7374/7374 rows signed and `jq -e 'all(.signed_off_by; . != null)'`
  passing. B10 close evidence also includes full staging denylist probe pass
  count=0, full staging depersonalization scan pass count=0, halted propagator
  filename count=0, and existing staging run `20260513T024740Z`.
- 2026-05-13: Closed TP-007, TP-008, TP-009, and TP-010 by explicit
  compatibility-target downgrade. Added `scripts/agent-lane-probe.sh` and
  `docs/runbooks/agent-lane-compatibility.md` so public copy distinguishes
  command presence from runtime proof. `scripts/journey-smoke.sh` now reports
  Claude, Codex, Gemini, and OpenClaw as compatibility targets until a
  lane-specific receipt sets `runtime_proven=true`; reduced mode remains the
  runtime-proven public fallback. Follow-up bead `flywheel-4oed2` tracks the
  full-support promotion receipts so this downgrade is not mistaken for
  completed end-to-end lane support. Evidence:
  `bash tests/preflight-fixtures.sh` pass=19 fail=0;
  `bash tests/agent-lane-probe.sh` pass=8 fail=0;
  `bash tests/journey-smoke.sh` pass=7 fail=0;
  `bash tests/naming-conventions.sh` pass=55 fail=0;
  `bash tests/public-surface-gap-scanner.sh` pass=14 fail=0.
- 2026-05-13: Hardened the TP-007 through TP-010 compatibility promotion
  contract without changing support status. Runtime receipts now require
  exactly one passing row for every required journey stage, and
  `private_state_scan.findings` must be absent or empty. Public runbooks and
  doc assertions now state that duplicate/conflicting stage rows or
  private-state findings cannot promote support copy. Evidence:
  `bash tests/agent-lane-probe.sh` pass=10 fail=0;
  `bash tests/public-docs.sh` pass=69 fail=0;
  `bash tests/public-surface-gap-scanner.sh` pass=14 fail=0;
  `bash tests/true-publication-registry-validate.sh` pass=6 fail=0.
- 2026-05-13: Added context/model routing doctrine from operator input.
  `docs/runbooks/context-and-model-routing.md` now documents grep-first context
  discipline, no just-in-case context, batched tool calls, prompt-cache-friendly
  prefixes, graduated `SKILL.md` patterns, long-session summaries, tiered model
  routing, and NTM lower-model worker dispatch boundaries without embedding
  static provider price or model-version claims. Evidence:
  `bash tests/context-routing-discipline.sh` pass=23 fail=0.
- 2026-05-13: Advanced TP-015 without closing it. Added
  `scripts/validate_external_review.py`, `tests/external-review-gate.sh`, and
  `22-TP-015-EXTERNAL-REVIEW-PACKET.md`. The gate fixture-proves that exactly
  two distinct non-Joshua/non-`flywheel:1` review rows with verdicts in
  `approved` or `approved_with_followups` are required; the live gate currently
  returns `status=blocked` because `review-log.jsonl` is absent. Agent Mail
  contact requests from `BoldDog` to `JadeFinch` and
  `mobile-eats-pane2-bridge` are pending; direct message delivery was blocked
  by contact policy until the recipients approve. Evidence:
  `bash tests/external-review-gate.sh` pass=6 fail=0.
- 2026-05-13: Advanced TP-005, TP-017, and TP-018 without closing them. Added
  `scripts/publication_readiness.py`, `tests/publication-readiness.sh`, and
  `23-TP-005-017-018-PUBLICATION-READINESS-RECEIPT.md`. The verifier separates
  local packaging readiness from remote publication truth. Live release-mode
  output is `status=blocked` with blockers `remote_repo_private`,
  `remote_workflows_missing`, `remote_green_runs_missing`, and
  `github_release_missing_or_draft`; fixture tests prove the pass path and the
  private-remote block path. Evidence: `bash tests/publication-readiness.sh`
  pass=4 fail=0; `python3 scripts/publication_readiness.py --release --json`
  exits 1 with the four blockers above.
- 2026-05-13: Hardened the final publication gates without closing TP-005,
  TP-015, TP-017, or TP-018. Added static website source under `site/`, a
  `tests/website-static.sh` verifier, site coverage in the public gap scanner
  and publication readiness local-file gate, and site-root-scoped
  depersonalization allowlist rows for intentional public ZestStream/Joshua
  contact copy. Added `release-signoff.template.json` and
  `review-log.template.jsonl`, and strengthened
  `scripts/publication_readiness.py` so final readiness also requires the
  TP-015 external-review gate to pass. Added `.github/workflows/site.yml` as a
  pinned GitHub Pages workflow that publishes `site/`, `install.sh`,
  `install.sh.sha256`, `CNAME`, and `site-deploy-manifest.json`. Evidence:
  `bash tests/website-static.sh`
  pass=48 fail=0; `bash tests/external-review-gate.sh` pass=7 fail=0;
  `bash tests/publication-readiness.sh` pass=6 fail=0;
  `bash tests/github-workflows.sh` pass=50 fail=0;
  `python3 scripts/publication_readiness.py --json` returns `status=blocked`
  with blockers `remote_repo_private`, `remote_workflows_missing`,
  `remote_green_runs_missing`, `github_release_missing_or_draft`,
  `github_release_assets_missing`, `website_unavailable`,
  `install_proxy_checksum_mismatch`, `joshua_release_signoff_missing`, and
  `external_review_gate_blocked`.
- 2026-05-13: Closed local documentation and reduced-mode Bead backlog without
  closing the live publication blockers. Added public concept pages for loops,
  Beads, Agent Mail, Socraticode, SkillOS boundary, and evidence contracts; added
  reference pages for commands, repo-local files, and troubleshooting; added
  `tests/public-docs.sh`; and added a repo-local static accessibility checker at
  `scripts/website_accessibility.py`. Closed B5, B6, B6.5, B7, B11.5.0,
  B11.5, B12.0, B12.1, B12.2, B12.3, B13.1, B13.2, B13.3, B13.4, B13.5, and
  B17.5 with executable evidence. B13.6 remains open because mailto subject
  proof is not the same as browser-validated send proof. Evidence:
  `bash tests/public-docs.sh` pass=20 fail=0;
  `bash tests/website-accessibility.sh` passes; `bash tests/github-workflows.sh`
  pass=55 fail=0; `bash tests/public-surface-gap-scanner.sh` pass=8 fail=0;
  public gap scanner release mode now scans 42 files with
  `undispositioned_count=0`; `python3 scripts/depersonalize.py --scan-table
  --root docs --json` passes.
- 2026-05-13: Advanced B14 without closing it. Added
  `scripts/check_links.py` and `tests/public-links.sh` to validate local
  markdown links, markdown anchors, website href/src paths, and website anchors
  while treating external URLs as skipped local-network-neutral references.
  Wired the checker into CI and the public release runbook. Evidence:
  `bash tests/public-links.sh` pass=3 fail=0; live link-check JSON
  `status=pass`, `source_count=31`, `checked_count=54`,
  `skipped_external_count=7`, and `failure_count=0`; `bash
  tests/github-workflows.sh` pass=57 fail=0. B14 remains open because the final
  cross-reference pass must include live deployed website and release asset
  surfaces after B13.7/TP-018 are real.
- 2026-05-13: Advanced B8 without closing it. Added
  `tests/release-assets.sh` and wired it into CI plus the release workflow
  pre-package validation. The smoke builds the same local asset set expected
  from the release workflow: `install.sh`, `install.sh.sha256`, `SHA256SUMS`,
  `flywheel-v0.2.0-test.tar.gz`, and
  `flywheel-v0.2.0-test.tar.gz.sha256`; then verifies all checksum files and
  confirms the tarball contains `README.md` and `install.sh`. Evidence:
  `bash tests/release-assets.sh` pass=9 fail=0; `bash
  tests/github-workflows.sh` pass=59 fail=0. B8 remains open because no live
  GitHub release/probe release exists yet.
- 2026-05-13: Strengthened release workflow pre-package gates without closing
  B8/TP-018. `.github/workflows/release.yml` now runs public surface gap,
  naming, public docs, public links, website static/accessibility, local release
  asset smoke, installer smoke, and `scripts/validate_external_review.py
  --release --json` before publishing assets. This ensures tag packaging cannot
  bypass TP-015 review evidence. Evidence: `bash tests/github-workflows.sh`
  pass=62 fail=0.
- 2026-05-13: Tightened TP-005/TP-018 local readiness manifest. Added the new
  concept/reference docs, link checker, accessibility checker, public-docs test,
  public-links test, website-accessibility test, and release-assets smoke test to
  `scripts/publication_readiness.py` required local files. Evidence:
  `bash tests/publication-readiness.sh` pass=6 fail=0; live
  `python3 scripts/publication_readiness.py --json` has no
  `local_required_file_missing` blockers and remains blocked only by real
  remote/release/site/review/signoff facts.
- 2026-05-13: Added actionable cutover output to final readiness. Blocked
  `scripts/publication_readiness.py` results now include `.next_actions[]` rows
  with blocker code, owner, action, and verification command. This keeps
  remaining human/live-publication steps explicit instead of relying on a prose
  handoff. Evidence: `bash tests/publication-readiness.sh` pass=8 fail=0; live
  readiness output includes next actions for repo visibility, workflows, green
  runs, release, release assets, website, install proxy, signoff, and external
  review.
- 2026-05-13: Advanced B13.6 contact routing without closing it. Added
  `scripts/contact_route_probe.py` and `tests/contact-routing.sh` to prove the
  public contact page has exactly one public `mailto:` form, the
  `joshua@zeststream.ai` address, the `[Flywheel] Public site inquiry` subject,
  required labelled `topic`/`message` fields, a submit button, and direct
  mailto fallback. The probe emits
  `delivery_claim=mailto_client_open_only`, so it does not overclaim browser
  send or email delivery. Evidence: `bash tests/contact-routing.sh` passes;
  `python3 scripts/contact_route_probe.py --file site/contact/index.html
  --json` returns `status=pass`, `submit_button_count=1`, and no failures;
  depersonalization scans pass for `scripts/contact_route_probe.py`,
  `tests/contact-routing.sh`, `docs`, and `site`; `bash
  tests/depersonalize-table-codemod.sh` pass=13 fail=0; `bash
  tests/github-workflows.sh` pass=64 fail=0; `bash
  tests/publication-readiness.sh` pass=8 fail=0. B13.6 remains open because
  its original acceptance requires browser validation that a message sends with
  the subject prefix within sixty seconds.
- 2026-05-13: Closed B13.6 by explicit static-site/mailto disposition rather
  than overclaiming email delivery. v0.2 proves public contact routing only:
  `joshua@zeststream.ai`, `[Flywheel] Public site inquiry`, labelled fields,
  a submit button, and direct fallback. Form-backed delivery proof is tracked
  separately as non-blocking Bead `flywheel-lz51w`. Evidence:
  `bash tests/contact-routing.sh` passes; `bash tests/public-docs.sh` pass=22
  fail=0; `bash tests/publication-readiness.sh` pass=17 fail=0.
- 2026-05-13: Added an upstream-substrate adoption lane for Asupersync without
  making it a Flywheel runtime dependency. `docs/runbooks/upstream-substrate-adoption.md`
  records the current status as `gated-evaluation`, names promotion gates for
  upstream source/package/site/platform/test posture, requires a repo-local Rust
  POC receipt before runtime promotion, and forbids rewriting the current
  shell/Python loop engine for runtime purity. Created follow-up Bead
  `flywheel-j8u97` for the non-v0.2 POC/adoption packet. Evidence:
  `bash tests/upstream-substrate-adoption.sh` passes; CI contract includes the
  test and runbook markdownlint path; `scripts/publication_readiness.py` now
  treats the runbook and test as required local release files.
- 2026-05-13: Tightened the local publication manifest around the first-run
  journey. `scripts/publication_readiness.py` now requires public preflight,
  journey-smoke, installer-smoke, preflight fixture, first-run, agent-lane,
  context-routing, and release-runbook surfaces in addition to later website
  and release gates. This prevents a future local readiness pass if the
  install/doctor/loop proof path is accidentally omitted. Evidence:
  `bash tests/publication-readiness.sh` pass=9 fail=0, including a fixture that
  deletes `scripts/journey-smoke.sh` and observes
  `local_required_file_missing`.
- 2026-05-13: Hardened the Joshua signoff predicate. Release signoff now
  requires `schema_version=flywheel.release_signoff.v0`, `status=approved`,
  exact `approver=Joshua Nowak`, matching `remote` and `tag`, and a parseable
  ISO-8601 UTC `signed_at` ending in `Z`. Alias approvers, malformed
  timestamps, and schema-less signoff fixtures remain blocked. Evidence:
  `bash tests/publication-readiness.sh` pass=12 fail=0.
- 2026-05-13: Hardened TP-015 external review scope. External reviews now must
  cover `README.md`, `CHARTER.md`, `docs/getting-started/first-run.md`, and
  `docs/runbooks/public-release-runbook.md`; reviewer kinds must be one of
  `external_agent`, `external_human`, or `external_agent_or_human`; and
  `reviewed_at` must be a parseable ISO-8601 UTC timestamp ending in `Z`.
  Evidence: `bash tests/external-review-gate.sh` pass=9 fail=0; `ruff check
  scripts/validate_external_review.py` and `shellcheck
  tests/external-review-gate.sh` pass.
- 2026-05-13: Closed TP-015 and removed it from current live blockers. The
  review log has two distinct external-agent reviewers with complete required
  surfaces, valid UTC timestamps, and empty `blocking_findings`; the external
  review release gate passes. Follow-up copy polish was tracked and closed in
  `flywheel-9d1fd`. Evidence: `python3 scripts/validate_external_review.py
  --release --json` returns `status=pass`; `bash tests/external-review-gate.sh`
  pass=9 fail=0.
- 2026-05-13: Hardened release/site cutover mechanics without closing
  TP-017/TP-018. Manual `workflow_dispatch` runs now fetch tags and
  `git checkout --detach "$tag"` before release asset packaging or Pages
  install-proxy asset generation, preventing default-branch `install.sh` drift.
  The final release runbook now lists all four required remote workflows and
  requires exact `approver=Joshua Nowak`; tests guard both requirements.
  Evidence: `bash tests/github-workflows.sh` pass=68 fail=0; `bash
  tests/publication-readiness.sh` pass=17 fail=0; `bash tests/public-docs.sh`
  pass=22 fail=0; focused `shellcheck` passes; release/site workflow YAML
  parses.
- 2026-05-13: Hardened release/site checksum manifests without closing live
  blockers. Release and Site Deploy workflows now compute `install.sh.sha256`
  from inside the artifact directory, and release tarball checksum manifests are
  also artifact-relative. This preserves both proxy hash comparison and
  downloaded-asset `shasum -c` verification. Evidence: `bash
  tests/release-assets.sh` pass=10 fail=0; `bash tests/github-workflows.sh`
  pass=70 fail=0; focused `shellcheck` passes; release/site workflow YAML
  parses.
- 2026-05-13: Made TP-015 review evidence usable from the public export. Added
  sanitized `docs/evidence/external-review-log.jsonl`, changed the Release
  workflow to validate that public evidence path explicitly, and kept the
  private `.flywheel/PLANS` review log as the working source of truth. Evidence:
  `bash tests/external-review-gate.sh` pass=10 fail=0; `python3
  scripts/depersonalize.py --scan-table --root docs --json` status=pass;
  `bash tests/depersonalize-table-codemod.sh` pass=13 fail=0; `bash
  tests/github-workflows.sh` pass=70 fail=0.
- 2026-05-13: Reopened TP-015 for supplemental review after adding new public
  trust surfaces. `scripts/validate_external_review.py` now requires review rows
  to cover `docs/evidence/publication-evidence.md` and
  `docs/runbooks/release-cutover-authorization.md` in addition to the original
  README, charter, first-run, and public-release surfaces. Created
  `flywheel-gr403.1` to track collection of the two supplemental non-Joshua
  review rows. Evidence: `bash tests/external-review-gate.sh` pass=10 fail=0;
  `bash tests/publication-readiness.sh` pass=42 fail=0; `bash
  tests/true-publication-registry-validate.sh` pass=4 fail=0; live
  `python3 scripts/publication_readiness.py --json` now reports
  `external_review_gate_blocked`.
- 2026-05-13: Closed supplemental TP-015 again. SkillOS and Mobile Eats returned
  two distinct supplemental external-agent review rows covering all six current
  trust surfaces with `approved_with_followups` verdicts and empty
  `blocking_findings`. The private working log and sanitized public evidence log
  both validate. Evidence: `python3 scripts/validate_external_review.py
  --release --json` status=`pass`; `python3 scripts/validate_external_review.py
  --log docs/evidence/external-review-log.jsonl --release --json` status=`pass`;
  `bash tests/external-review-gate.sh` pass=10 fail=0.
- 2026-05-13: Reopened TP-015 for a second supplemental review after adding
  `docs/evidence/publication-blocker-coverage.md` as a public trust surface.
  `scripts/validate_external_review.py` now requires review rows to include that
  page, and the public evidence log intentionally blocks until SkillOS/Mobile
  Eats or other distinct non-Joshua reviewers return updated rows. Evidence:
  Agent Mail messages `509` and `510`; `bash tests/external-review-gate.sh`
  pass=10 fail=0; the then-current publication readiness and registry gates
  passed with TP-015 blocked as expected.
- 2026-05-13: Updated the TP-015 review packet and pending template to match
  the seven-surface validator. `22-TP-015-EXTERNAL-REVIEW-PACKET.md` now marks
  TP-015 open, names `docs/evidence/publication-blocker-coverage.md` as a
  required review surface, and the JSONL template includes the same surface.
  Agent Mail message `511` notified the review recipients of the updated row
  shape. Evidence: `bash tests/external-review-gate.sh` pass=10 fail=0.
- 2026-05-13: Aligned public and private release-cutover authorization surfaces
  with reopened TP-015. Both cutover checklists now include
  `external_review_gate_blocked` in tested blocker-code coverage and stop on
  TP-015 alongside TP-005/TP-017/TP-018; the publication-readiness receipt again
  lists external review as an expected current blocker. Evidence: `bash
  tests/publication-readiness.sh` pass=54 fail=0; `bash tests/public-docs.sh`
  pass=41 fail=0; `bash tests/public-surface-gap-scanner.sh` pass=8 fail=0.
- 2026-05-13: Hardened the cutover-coverage regression to prevent future
  blocker-list drift. `tests/publication-readiness.sh` now reads the blocked
  fixture's actual `.blockers[].code` values and verifies every code appears in
  the public cutover runbook and, when present, the private authorization
  packet. Evidence: `bash tests/publication-readiness.sh` pass=56 fail=0;
  fresh export `codex-public-export-20260513T1052Z` pass with staged
  publication-readiness 44/0.
- 2026-05-13: Sent the updated seven-surface TP-015 review request directly to
  live WezTerm panes after Agent Mail remained quiet: SkillOS pane `1` and
  Mobile Eats pane `4`. The request names
  `docs/evidence/publication-blocker-coverage.md` as required and points
  reviewers to `22-TP-015-EXTERNAL-REVIEW-PACKET.md` plus
  `review-log.template.jsonl`. TP-015 remains open until review rows land and
  the external-review release gate passes.
- 2026-05-13: Fixed a reviewer-caught TP-015 runbook drift and recorded one
  current seven-surface review row without closing TP-015. Mobile Eats found
  that `docs/runbooks/public-release-runbook.md` still listed six review
  surfaces and omitted `docs/evidence/publication-blocker-coverage.md`; the
  runbook now includes all validator-required surfaces, and
  `tests/external-review-gate.sh` regresses that the runbook lists every
  required surface. Mobile Eats re-reviewed and returned a valid current row
  with empty `blocking_findings`; SkillOS did not return a current row. Evidence:
  `bash tests/external-review-gate.sh` pass=11 fail=0; private and public
  external-review release validators both remain blocked with
  `valid_review_count=1`, `distinct_reviewer_count=1`.
- 2026-05-13: Closed the second supplemental TP-015 external-review gate for
  the current seven-surface public trust set. Gemini CLI completed an
  independent read-only cold review after the Mobile Eats row, verified that
  `docs/runbooks/public-release-runbook.md` and
  `docs/runbooks/release-cutover-authorization.md` consistently include
  `docs/evidence/publication-blocker-coverage.md`, and returned a valid row
  with empty `blocking_findings`. Private and public review logs now both pass
  release validation with `valid_review_count=2` and
  `distinct_reviewer_count=2`; live publication readiness no longer reports
  `external_review_gate_blocked`.
- 2026-05-13: Removed manual drift from the live blocker coverage validator.
  `.flywheel/scripts/true-publication-registry-validate.py` now derives
  `expected_readiness_blockers` from `scripts/publication_readiness.py --json`
  and checks the registry coverage table against that live set. Evidence:
  `bash tests/true-publication-registry-validate.sh` pass=6 fail=0; validator
  JSON reports `open_count=3`, coverage count `8`, and zero errors.
- 2026-05-13: Refreshed current publication-lane verifier evidence after the
  upstream-substrate and public-top-level checks joined the public readiness
  surface. Evidence: `bash tests/naming-conventions.sh` pass=55 fail=0; `bash
  tests/external-review-gate.sh` pass=11 fail=0; `bash
  tests/publication-readiness.sh` pass=61 fail=0; `bash
  tests/true-publication-registry-validate.sh` pass=6 fail=0.
- 2026-05-13: Repaired recurring Agent Mail FD pressure before it could become a
  publication doctor failure. Dry-run planned the expected bootout/bootstrap
  sequence; apply recovered from one bootstrap rc=5 retry, kickstarted the
  service, verified child PID `55850`, and direct FD doctor now reports
  `PASS`, `total_fds=57`, `lock_fd_count=0`, `warnings=[]`, `errors=[]`. Full
  loop doctor still reports `status=warn` for classified non-release warnings,
  with `errors=[]` and no `agent_mail_fd_doctor_warn` rows.
- 2026-05-13: Refreshed publication evidence after hardening saved cutover
  receipt replay. `tests/cutover-receipts.sh` now covers 15 cases and directly
  rejects private repo receipts, missing workflows, feature-branch-only green
  runs, draft/prerelease releases, empty assets, missing asset digests,
  checksum drift, non-success website HEAD receipts, pending signoff, wrong
  signoff remote, wrong signoff tag, and missing receipt files. Current local
  evidence: `bash tests/cutover-receipts.sh` pass=15 fail=0; `bash
  tests/publication-readiness.sh` pass=65 fail=0; `bash tests/public-docs.sh`
  pass=65 fail=0; `bash tests/true-publication-registry-validate.sh` pass=6
  fail=0. Public export `codex-public-export-20260513T1645Z` passes staged
  cutover receipts 15/0, public docs 65/0, publication readiness 52/0, and
  depersonalization scan with zero findings.

## Immediate Next Actions

1. Make the GitHub repository public or publish the approved public export path,
   push the workflow files, and obtain green CI/installer-smoke runs visible to
   `scripts/publication_readiness.py`.
2. Deploy `site/` to `flywheel.zeststream.ai`, publish tag/release `v0.2.0`,
   verify install assets/checksums and install proxy, then get Joshua signoff
   before closing TP-018/B15 or the thread goal.
