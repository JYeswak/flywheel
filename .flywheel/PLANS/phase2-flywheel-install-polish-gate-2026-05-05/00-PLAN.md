# Phase 2 Flywheel-Install 5-Skill Polish Gate Plan

date: 2026-05-05
mode: plan-space only
task_id: phase2-flywheel-install-polish-gate-plan-2026-05-05
bead_db_writes: 0
execution_scope: templates/flywheel-install design only; no template edits in this pass
phase_1_dependency: execution blocked until Phase 1 stamp converges
socraticode_queries: 5

## Executive Verdict

This plan designs Phase 2 of the 5-skill polish gate: integrate the gate into
`templates/flywheel-install/` as an install-time and strict-doctor check, without
touching the template in this dispatch.

Phase 2 should not be implemented yet. The Phase 1 stamp report is REWORK:
`surface_passes=0/4`, `average_composite=7.66`, `must_fix_findings=12`, and
`phase_2_readiness=NO`. That means the right output now is an executable plan
arc plus bead decomposition, not template mutation.

The intended system shape is:

- Fresh installs get the gate substrate and a warn-mode baseline.
- Strict doctor and close validation become the blocking surfaces.
- Existing repos receive the gate by reconcile, not ad-hoc per-repo doctrine
  edits.
- Scope allowlists prevent client/domain files from being swept by generic
  rename or surface-discovery logic.
- Phase 3 fleet audit starts only after flywheel itself passes the gate and the
  template has proven install/reconcile behavior.

## System Frame

Boundary: `templates/flywheel-install/`, `flywheel-loop init`, repo-local
`.flywheel/` installs, strict doctor JSON, close validator, and the future
Zest Ledger grade substrate.

Primary stock: installed but unpolished operational surfaces. Examples:
repo-local CLIs, doctor probes, validators, README surfaces, generated
doctrine, template scripts, and wire-or-explain foundation surfaces.

Inflow:

- New repo installs from `templates/flywheel-install/`.
- Reconcile runs that copy newer canonical surfaces into existing repos.
- New executable, documentation, doctrine, or validator surfaces added by beads.
- Rename/refactor work that changes CLI or doc semantics.

Outflow:

- A surface passes all five skills at `>=9.0` with no must-fix findings.
- A surface is explicitly waived with owner, reason, expiry, and replacement
  bead/reference.
- A legacy surface is classified audit-only until touched by a mutation bead.

Feedback loops:

- Reinforcing loop: more surfaces get graded, grade receipts improve plan and
  implementation quality, fewer future fixes are needed, and the template
  propagates better defaults.
- Balancing loop: the gate can slow install or closeout if it overreaches.
  Mitigation is phased enforcement: warn on fresh bootstrap, strict on close and
  mutation-ready surfaces.

Meadows leverage points:

- #6 information flows: doctor JSON and local grade ledgers make unpolished
  surfaces visible.
- #5 rules: strict doctor and close validators refuse below-floor surfaces.
- #4 self-organization: repo-local manifests let each installed repo declare
  its safe surface scope without rewriting canonical doctrine.

## 1. Current-State Inventory of `templates/flywheel-install/`

Current files observed:

- `templates/flywheel-install/.flywheel/reboot-recovery/.gitkeep`
- `templates/flywheel-install/.flywheel/scripts/idle-pane-mechanical-gate.sh`
- `templates/flywheel-install/AGENTS.md`
- `templates/flywheel-install/ESCALATION-LADDER.md.tmpl`
- `templates/flywheel-install/GOAL.md.tmpl`
- `templates/flywheel-install/MISSION.md.tmpl`
- `templates/flywheel-install/MISSION.md.tmpl.bak.20260503T021638Z`
- `templates/flywheel-install/README.md`
- `templates/flywheel-install/STATE.md.tmpl`
- `templates/flywheel-install/halt-contract/fixtures/green.json`
- `templates/flywheel-install/halt-contract/fixtures/red-beads-db.json`
- `templates/flywheel-install/halt-contract/fixtures/yellow-disk.json`
- `templates/flywheel-install/halt-contract/v1.schema.json`
- `templates/flywheel-install/loop.json.tmpl`
- `templates/flywheel-install/render.sh`
- `templates/flywheel-install/schema.json`
- `templates/flywheel-install/schema.json.bak.20260503T021638Z`
- `templates/flywheel-install/tests/test_render.sh`
- `templates/flywheel-install/tests/test_render.sh.bak.20260503T021638Z`
- `templates/flywheel-install/validate-callback-before-close.sh.tmpl`

Current template contract:

- `render.sh` is the sole template renderer. It preserves multiline values,
  fails on unresolved `{{marker}}`, requires Bash associative arrays, and
  renders one template at a time.
- `schema.json` declares template metadata, required frontmatter, required
  template files, and loop config keys.
- `README.md` documents render behavior, lock hashes, copied runtime files, and
  install expectations.
- `tests/test_render.sh` renders MISSION/GOAL/STATE/loop config, copies
  validators, asserts strict doctor readiness with fixtures, checks publishable
  bar status, checks CLI floor signals, verifies unresolved marker failures, and
  hashes template files.
- `MISSION.md.tmpl` already carries a repo-local CLI floor: executables under
  `bin/` must satisfy `canonical-cli-scoping`, and strict doctor exposes
  `repo_local_clis_below_canonical_floor`.
- `validate-callback-before-close.sh.tmpl` is a four-lens close validator with
  callback/evidence checks.
- `.flywheel/scripts/idle-pane-mechanical-gate.sh` is the L70 closeout gate for
  idle panes.
- `AGENTS.md` already includes doctrine for load-bearing docs, canonical CLI
  floors, file length discipline, three-surface doctrine landing, and meta-rule
  cache propagation.

Existing install-time gates:

- Template render failure on unresolved markers.
- Frontmatter and lock-hash expectations in generated repo docs.
- Strict doctor fixture assertions:
  `repo_docs_state == "ready"`, `loop_config_present == true`,
  `repo_local_clis_below_canonical_floor == 0`, and publishability status pass.
- Callback validator before close.
- Halt-contract schema and fixtures.
- Template hash checks.

Gap:

The template has canonical CLI and publishability components, but no explicit
surface-wide 5-skill polish gate. It cannot yet answer: "which installed
surfaces are wired but not polished, which skills failed, and what blocks
closeout?"

Best insertion point:

- Install/reconcile copies the gate substrate and runs discovery in warn mode.
- Strict doctor computes and exposes gate status.
- Close validator refuses below-floor touched surfaces.
- Template tests prove gate behavior before propagation.

## 2. 5-Skill Polish Gate as Install-Time Check Design

Gate identity:

The 5-skill polish gate consists of:

- `/ubs`
- `/simplify-and-refactor-code-isomorphically`
- `/extreme-software-optimization`
- `/readme-writing`
- `/canonical-cli-scoping`

Core rule:

Any operational surface touched by a wire-or-explain foundation bead, template
install, reconcile, source mutation, or closeout path remains
`wired-not-polished` until all applicable gate skills pass at `>=9.0` and there
are no must-fix findings.

Proposed template additions, for the implementation phase:

- `templates/flywheel-install/.flywheel/polish-gate/v1.manifest.json.tmpl`
- `templates/flywheel-install/.flywheel/polish-gate/surface-discovery.schema.json`
- `templates/flywheel-install/.flywheel/scripts/polish-gate-discover.sh`
- `templates/flywheel-install/.flywheel/scripts/polish-gate-runner.sh`
- `templates/flywheel-install/tests/test_polish_gate.sh`
- Updates to `templates/flywheel-install/MISSION.md.tmpl`
- Updates to `templates/flywheel-install/STATE.md.tmpl`
- Updates to `templates/flywheel-install/README.md`
- Updates to `templates/flywheel-install/schema.json`
- Updates to `templates/flywheel-install/tests/test_render.sh`
- Later update to `flywheel-loop doctor` fields, if doctor source is outside
  the template tree.

Manifest contract:

The installed repo should contain `.flywheel/polish-gate/v1.manifest.json` with:

- `gate_version`
- `repo`
- `installed_from_template_version`
- `surface_scope_mode`
- `scope_allowlists`
- `skill_thresholds`
- `waiver_policy`
- `grade_storage`
- `doctor_fields`
- `strict_enforcement_points`
- `legacy_bootstrap_policy`

Skill applicability:

- `/ubs` applies to executable, behavioral, lifecycle, safety, and validator
  surfaces. Fresh empty installs can warn; touched surfaces block on fail.
- `/simplify-and-refactor-code-isomorphically` applies to source-bearing scripts,
  CLIs, validators, and generators. Docs-only changes can mark it not
  applicable with a receipt.
- `/extreme-software-optimization` applies to hot paths, repeated doctor probes,
  install/reconcile scripts, and expensive fleet-wide scans. Small docs-only
  surfaces can mark it not applicable with a receipt.
- `/readme-writing` applies to repo-level docs, CLI docs, user-facing operator
  docs, and every new installed surface that an agent/operator must understand.
- `/canonical-cli-scoping` applies to executable CLIs, scripts with help
  surfaces, doctor/health/repair commands, validators, and command-like shell
  entrypoints.

Fresh install behavior:

- Copy the gate substrate.
- Render manifest and docs.
- Run surface discovery.
- Write a baseline grade summary in warn mode.
- Do not block an otherwise valid fresh install because the new repo has no
  project-specific surfaces yet.
- Do block if the gate substrate itself is malformed, non-executable when it
  must be executable, missing schema, or unable to emit parseable JSON.

Strict doctor behavior:

Add a `polish_gate` object to strict doctor JSON:

```json
{
  "polish_gate": {
    "version": "1",
    "status": "pass|warn|fail|missing",
    "mode": "bootstrap|strict|audit_only",
    "surfaces_total": 0,
    "surfaces_required": 0,
    "surfaces_passed": 0,
    "surfaces_below_floor": 0,
    "must_fix_findings": 0,
    "waivers_active": 0,
    "waivers_expired": 0,
    "stale_grades": 0,
    "latest_grade_receipt": ".flywheel/polish-gate/latest.json",
    "required_action": "none|run_gate|repair_findings|reconcile_template"
  }
}
```

Close validator behavior:

The close validator should require the callback or close receipt to include one
of:

- `polish_gate=pass`
- `polish_gate=not_applicable reason=<bounded reason>`
- `polish_gate=waived waiver_id=<id>`
- `polish_gate=audit_only reason=<legacy/prod baseline>`

For touched template surfaces, `audit_only` should be refused. Audit-only is for
legacy production surfaces that have not been changed in the current bead.

Grade storage:

- Primary local receipt:
  `.flywheel/polish-gate/grades.jsonl`
- Latest summary:
  `.flywheel/polish-gate/latest.json`
- Optional per-surface receipts:
  `.flywheel/polish-gate/surfaces/<surface_id>.json`
- Future Zest Ledger integration:
  append a grade row when the ledger exists; otherwise keep local JSONL and
  replay on ledger bootstrap.

Enforcement progression:

- Phase 2A: template contains gate manifest, discovery, local receipts, tests,
  docs, and warn-mode install baseline.
- Phase 2B: strict doctor fails when a touched required surface is below floor.
- Phase 2C: callback validator refuses close without gate receipt.
- Phase 2D: reconcile updates existing repos and reports missing or stale gate
  substrate.

## 3. Surface-Discovery Problem

The hard problem is not scoring. The hard problem is discovering the right
surfaces without sweeping client domain code, generated files, historical
transcripts, or backup artifacts.

Surface classes:

- Executable files under `bin/`, `scripts/`, `.flywheel/scripts/`,
  `.local/bin/`, or repo-declared command directories.
- Any file with an executable bit and a shell/Python/Rust/TypeScript shebang.
- Python, shell, Rust, or TypeScript files named like commands, probes, doctors,
  validators, generators, repair tools, dispatch tools, or installers.
- `pyproject.toml` console scripts, `package.json` `bin`, Cargo binary targets,
  and Makefile targets that wrap operational commands.
- `README.md`, `.flywheel/README.md`, operator docs, CLI docs, doctrine docs,
  and install/reconcile docs.
- Template files under `templates/flywheel-install/`.
- Canonical doctrine surfaces such as `AGENTS.md`, `MISSION.md.tmpl`,
  `GOAL.md.tmpl`, `STATE.md.tmpl`, and close validators.
- Wire-or-explain ledger rows that name artifact paths.

Default exclusions:

- `.git/`
- `.beads/issues.jsonl*`
- `.pytest_cache/`, `node_modules/`, `.venv/`, `dist/`, `build/`, cache dirs
- Backup files such as `*.bak.*`
- Fixtures unless executable or explicitly declared as validation surfaces
- Generated receipts and grade JSON unless they are schema fixtures
- Transcripts, scrollback dumps, temporary dispatch packets, and screenshots
- Client domain source paths unless a repo-local mission allowlist includes them

Surface ID:

Use a stable ID derived from:

- repo slug
- normalized path
- surface class
- command name if present

Example shape:

```json
{
  "surface_id": "flywheel:templates/flywheel-install/render.sh:script",
  "path": "templates/flywheel-install/render.sh",
  "class": "script",
  "skills_required": ["ubs", "simplify", "extreme_optimization", "readme", "canonical_cli"],
  "enforcement": "strict",
  "source": "template-discovery"
}
```

Waiver and allowlist model:

Waivers should be explicit and expiring:

```json
{
  "surface_id": "example",
  "skill": "canonical_cli",
  "reason": "legacy CLI replaced by bd-123",
  "owner": "repo-maintainer",
  "expires_at": "2026-06-05",
  "replacement_ref": "bd-123",
  "mode": "waived_below_floor"
}
```

Waivers do not count as passes. They produce `warn` or `fail` depending on
enforcement mode and expiry.

Discovery should produce three outputs:

- `discovered_surfaces.json`
- `surface_discovery_summary.json`
- doctor JSON fields that summarize pass/warn/fail without forcing operators to
  read raw receipts.

## 4. Cross-Repo Coordination

Principle:

Fix propagation mechanisms, not individual repo doctrine by hand.

Template versioning:

- Bump `templates/flywheel-install/schema.json` from `0.1.0` to the next
  template version during implementation.
- Record `polish_gate_version` in rendered `loop.json`.
- Record the gate in rendered MISSION/STATE docs.
- Add a template hash for every new gate file.

Fresh repos:

- `flywheel-loop init --repo <repo>` installs the gate substrate.
- Initial surface discovery runs in bootstrap warn mode.
- Strict mode turns on when the repo attempts closeout or source mutation for a
  discovered required surface.

Existing repos:

- Reconcile installs the gate substrate into `.flywheel/`.
- Doctor reports `polish_gate.status="missing"` before reconcile and
  `status="warn"` after bootstrap if legacy surfaces lack grades.
- Existing production/domain surfaces are audit-only until touched by a bead.
- Repo-local `.flywheel/` surfaces are strict once reconciled.

Fleet propagation:

- Do not edit ALPS, Blackfoot, TerraTitle, PicoZ, or other client root doctrine
  directly as part of Phase 2.
- Use a reconcile command or dispatch packet per repo.
- Store per-repo results in plan receipts and future beads.
- Phase 3 ecosystem audit consumes the template version and doctor fields after
  Phase 2 proves itself.

Backcompat:

- Old repos without `.flywheel/polish-gate/` must produce a warning, not a crash.
- Missing gate schema yields `required_action="reconcile_template"`.
- Malformed gate schema yields strict failure after reconcile.
- Old close receipts without gate fields remain historical; new close receipts
  must include gate fields after the template version is active.

## 5. Scope-Aware-Rename Interaction

The 5-skill polish gate is not itself a rename, but it will use the same
discipline. Surface discovery and future CLI naming changes must respect
scope-aware allowlists.

Rule:

No global repository-wide replacement, scan, or enforcement pass may assume the
whole repo is operational substrate. The allowed scope is declared by repo type
and mission lock.

Default scope classes:

- Flywheel repo: `.flywheel/`, `templates/flywheel-install/`, root operational
  docs, tests, command scripts, and canonical loop substrate.
- Skillos repo: `.flywheel/`, skill authoring substrate, and declared skill
  docs.
- Client repos: `.flywheel/` by default. Domain source code is excluded unless
  the mission allowlist says otherwise.
- ALPS: only `.flywheel/` is safe for generic flywheel install/reconcile and
  rename work. ALPS root source remains off-limits.
- Product repos: `.flywheel/` plus explicit source paths declared by repo-local
  MISSION/GOAL.

Manifest field:

```json
{
  "scope_allowlists": [
    {
      "name": "repo_local_flywheel",
      "include": [".flywheel/**", "AGENTS.md"],
      "exclude": [".beads/**", "**/*.bak.*"],
      "enforcement": "strict"
    }
  ]
}
```

Rename-aware checks:

- Surface discovery should flag suspicious broad scans in plan review.
- Gate runner should report excluded paths count.
- Doctor should expose `scope_allowlist_status`.
- Any future `flywheel-loop` or `/flywheel:` rename plan must run against this
  allowlist model before touching files.

## 6. Phase 3 Trigger Conditions

Phase 3 is the ecosystem audit and fleet rollout phase. It must wait.

Phase 3 may start only when all conditions below are true:

- Phase 1 wave-0 surfaces pass the 5-skill polish gate at `>=9.0` per skill.
- Phase 1 has no must-fix findings open.
- The Phase 1 stamp report changes from REWORK to PASS.
- Cluster A canonical CLI breadth issues are closed.
- Cluster B README/operator-depth issues are closed.
- Cluster C oversized detector/ledger packaging is closed or has explicit
  allow-large receipts.
- The template implementation has a passing fresh-install fixture.
- The template implementation has a passing existing-repo reconcile fixture.
- Strict doctor JSON includes parseable `polish_gate` fields.
- Close validator refuses a touched below-floor surface in a fixture.
- Scope allowlist fixture proves ALPS/root-style domain files are excluded.
- Local grade receipts can be written and read without the Zest Ledger.
- Reconcile is idempotent.
- No template test depends on accidental local state.

Phase 3 first audit set:

- Flywheel itself.
- Skillos.
- One low-risk internal repo with `.flywheel/` only.
- One client repo in audit-only mode, with ALPS-style root exclusion verified.

Phase 3 must not begin from the current state because Phase 1 readiness is
explicitly `NO`.

## 7. Bead Decomposition and DAG Sketch

No beads are filed by this dispatch. The following is a decomposition list only.

Candidate beads:

1. P2-01: Define polish gate manifest and discovery schemas.
2. P2-02: Add surface discovery script and JSON output contract.
3. P2-03: Add 5-skill grade runner receipt format and local grade storage.
4. P2-04: Add template docs for gate lifecycle, modes, waivers, and receipts.
5. P2-05: Add MISSION/STATE/loop template fields for polish gate status.
6. P2-06: Add template tests for manifest render, discovery, and bad fixture
   detection.
7. P2-07: Add strict doctor `polish_gate` JSON fields.
8. P2-08: Wire close validator to require gate callback fields for touched
   surfaces.
9. P2-09: Add reconcile/backcompat behavior for existing repos.
10. P2-10: Add scope allowlist fixtures, including ALPS root exclusion.
11. P2-11: Add Zest Ledger replay adapter for local gate receipts.
12. P2-12: Run Phase 2 template audit and publishability review before Phase 3.

DAG sketch:

```text
P2-01 schema
  -> P2-02 discovery
  -> P2-03 runner/receipts
  -> P2-06 tests

P2-01 schema
  -> P2-04 docs
  -> P2-05 templates
  -> P2-09 reconcile

P2-02 discovery
  -> P2-10 scope fixtures
  -> P2-07 doctor fields
  -> P2-08 close validator

P2-03 runner/receipts
  -> P2-11 ledger replay

P2-06 tests
P2-07 doctor fields
P2-08 close validator
P2-09 reconcile
P2-10 scope fixtures
  -> P2-12 Phase 2 audit
  -> Phase 3 ecosystem audit
```

Suggested sequencing:

- Build schema and discovery before runner behavior.
- Add tests before strict enforcement.
- Add docs with the implementation bead that changes operator behavior.
- Gate reconcile last, after fresh install works.
- Audit before Phase 3.

## 8. Risks and Mitigations

Risk 1: Template amplification.

Any template bug replicates into every newly initialized repo.

Mitigation: versioned manifest, fixture installs, strict template tests, hash
checks, fresh install fixture, reconcile fixture, and no implementation before
Phase 1 passes.

Risk 2: Install-time friction.

Running five deep reviews during initial install can make bootstrap too slow or
too brittle.

Mitigation: install only runs discovery and warn-mode baseline. Strict scoring
blocks close and mutation, not empty bootstrap.

Risk 3: False positives in client repos.

Generic scans may classify client domain files as flywheel operational surfaces.

Mitigation: fail-closed scope allowlists, ALPS root exclusion fixture, and
repo-local mission declarations.

Risk 4: Skill invocation is partly human/rubric-based.

Some skills may not have deterministic CLI adapters.

Mitigation: runner stores grade receipts with skill name, reviewer, score,
must-fix count, evidence paths, and mode. Machine adapters can be added later
without changing the manifest.

Risk 5: Zest Ledger is not always present.

A hard dependency would block fresh repos.

Mitigation: local JSONL is primary for Phase 2; Zest Ledger replay is a later
adapter.

Risk 6: Waivers become permanent debt.

Mitigation: waivers expire, never count as passes, require owner/reason/ref, and
doctor reports active and expired waiver counts.

Risk 7: README checks become content theater.

Mitigation: `/readme-writing` must be tied to operator tasks, command examples,
troubleshooting, limitations, and actual gate/doctor behavior.

Risk 8: Canonical CLI checks remain too narrow.

Phase 1 found canonical CLI breadth issues.

Mitigation: Phase 2 implementation must use canonical-cli-scoping as a gate for
all command-like surfaces, not only obvious `bin/` executables.

Risk 9: File size and complexity drift.

The detector/runner can become another large unpolished surface.

Mitigation: apply file-length thresholds from canonical-cli-scoping and require
allow-large receipts before accepting oversized scripts.

Risk 10: Backcompat breaks historical repos.

Mitigation: missing gate substrate warns and asks for reconcile; malformed
new gate substrate fails only after reconcile has opted the repo into the new
version.

## 9. success criteria

Plan success criteria:

- This file exists at
  `.flywheel/PLANS/phase2-flywheel-install-polish-gate-2026-05-05/00-PLAN.md`.
- It includes current-state inventory of `templates/flywheel-install/`.
- It defines the 5-skill polish gate install-time check design.
- It names the surface-discovery problem and exclusions.
- It defines cross-repo coordination without ad-hoc per-repo doctrine edits.
- It preserves scope-aware-rename discipline.
- It states Phase 3 trigger conditions.
- It decomposes implementation into candidate beads without filing them.
- It lists risks and mitigations.
- It includes a testable success criteria section for L112.

Implementation success criteria for the future Phase 2 bead set:

- Fresh install fixture passes with gate substrate present and warn-mode
  baseline written.
- Existing repo reconcile fixture installs the gate idempotently.
- Strict doctor exposes parseable `polish_gate` JSON.
- Strict doctor fails a touched below-floor required surface.
- Close validator refuses missing gate callback fields for touched surfaces.
- Scope fixture excludes ALPS-style domain root files.
- Local gate receipts work without Zest Ledger.
- Waivers are explicit, expiring, and visible in doctor output.
- Template README and MISSION explain operator behavior with concrete commands.
- Template tests prove render, schema, discovery, doctor, and validator paths.

Three-judge sniff:

- Jeff: 9.6. The plan gives schema, doctor fields, idempotent reconcile path,
  validator hook, and test fixtures before mutation.
- Donella: 9.6. The plan names stocks, inflows, outflows, feedback loops, and
  leverage points; enforcement is phased to avoid bootstrap overload.
- Joshua: 9.5. The plan keeps execution blocked until Phase 1 is real, avoids
  ad-hoc client edits, and turns the gate into propagation substrate.

Composite: 9.57

Blocking verdict:

- Plan artifact: pass.
- Phase 2 implementation: blocked until Phase 1 converges.
- Phase 3: blocked until Phase 2 template implementation and fixture evidence
  exist.
