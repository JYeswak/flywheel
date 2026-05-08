did=8/8 didnt=none gaps=none tmp_dir_released=true tests=PASS

# flywheel-2bd2r Tmp Lifecycle Evidence

Task: complete /tmp lifecycle doctrine Layers 1, 3, and 4, while treating
Layer 2 as already shipped by `.flywheel/scripts/tmp-aggressive-prune.sh` in
commit `2c21355`.

## Acceptance Map

1. Authored `.flywheel/doctrine/tmp-lifecycle.md` with the full four-layer
   doctrine, including Layer 2 citation to commit `2c21355`.
2. Extended `.flywheel/scripts/validate-callback-before-close.sh` to require
   `tmp_dir_released=true` and reject bare temp evidence paths matching the
   bead id outside the mktemp convention.
3. Extended `templates/flywheel-install/validate-callback-before-close.sh.tmpl`
   with the same additive close-gate behavior.
4. Updated dispatch packet surfaces at
   `/Users/josh/.claude/commands/flywheel/_shared/dispatch-template.md` and
   `/Users/josh/.claude/skills/.flywheel/dispatch-templates/skill-creation-with-handoff.md`
   to require `mktemp -d -t <bead-short-id>.XXXXXX`, a single scratch root,
   and cleanup before callback.
5. Added `tmp_dir_not_released` to `.flywheel/doctrine/failure-taxonomy.md`
   with retry policy `manual` and recovery hint
   `rm -rf $TMPDIR/<bead-id>.* && re-run br close`.
6. Added the doctor invariant in `/Users/josh/.claude/skills/.flywheel/lib/storage.sh`:
   `.storage.tmp_entry_count`, `.storage.tmp_entry_count_status`, root, and
   thresholds. Counts greater than `5000` warn; counts greater than `10000`
   are critical.
7. Added AGENTS L139 in `AGENTS.md`, `.flywheel/AGENTS-CANONICAL.md`, and the
   install template. L139 makes scratch release a close gate and the temp
   entry count a doctor invariant.
8. Added `tests/tmp-lifecycle-doctor.sh` and updated validator/doctor fixtures
   so the new close gate and critical doctor invariant are exercised.

## Verification

- `bash -n .flywheel/scripts/validate-callback-before-close.sh`
- `bash -n templates/flywheel-install/validate-callback-before-close.sh.tmpl`
- `bash -n /Users/josh/.claude/skills/.flywheel/lib/storage.sh`
- `bash -n tests/tmp-lifecycle-doctor.sh`
- `bash tests/validate-callback-before-close.sh`
- `bash tests/tmp-lifecycle-doctor.sh`
- `bash tests/test_four_lens_validator_did_total_structural.sh`
- `bash tests/test_four_lens_validator_bash_3_2_compat.sh`
- `bash tests/test_four_lens_jeff_version_contract_pass.sh`
- `bash tests/test_four_lens_jeff_version_contract_fail.sh`
- `bash templates/flywheel-install/tests/test_polish_gate_close_validator.sh`
- `bash tests/doctor-validation-signals.sh`

Current live `/private/tmp` top-level entry count observed: `5473`.

Current doctor storage projection:

- `tmp_entry_count=5473`
- `tmp_entry_count_status=warn`
- `warn_threshold=5000`
- `critical_threshold=10000`

Layer 2 dry-run was executed. The default command
`.flywheel/scripts/tmp-aggressive-prune.sh --dry-run --json` returned `rc=1`
with no JSON on the live candidate set. A debug run showed it reached
`candidates_count=7` and stopped while sampling size for
`/private/tmp/devio_semaphore_logi_hpp_OptionsPlus_A7D4B139-F9F9-44A6-9F5D-7BC0A9B8B80F`.
Because Layer 2 was explicitly read-only in this dispatch, I filed follow-up
bead `flywheel-2bd2r.1` instead of patching the prune script here.

## Four Lenses

Brand voice pass: the doctrine is direct, operational, and close-gate shaped.
It replaces advice with mechanical gates: mktemp convention, callback refusal,
taxonomy class, and doctor invariant.

Joshua sniff pass: /tmp lifecycle is the silent ops disaster. A 25-year
operations manager pattern applies here: every accreting surface gets
retention-by-default or you accept the floor breach. The 18,041-entry blindness
today proves doctrine without invariants is theater.

Jeff doctrine pass: the work cites and reinforces flywheel primitives instead
of prose-only judgment: beads, callback validator, failure taxonomy, AGENTS
L-rule, dispatch templates, receipt-in-repo, and doctor JSON.

Public publishability pass: I would fork-and-star this shape because it names
the seven publishability facets explicitly. Clear problem: temp accretion can
floor a host. Minimal mechanism: mktemp-only scratch, close-gate release, and
doctor count invariant. Reproducible tests: synthetic critical fixture and
validator fixtures. Safe defaults: dry-run prune remains Layer 2 and host
mutation is not expanded here. Operational receipts: evidence copied into the
repo and callbacks require `tmp_dir_released=true`. Failure taxonomy:
`tmp_dir_not_released` has a manual retry policy and recovery hint.
Extensibility: install templates and shared dispatch templates propagate the
rule to future workers.

## Socraticode

- queries: `5`
- indexed chunks observed: `50`

## Close Fields

- doctrine_doc_path: `.flywheel/doctrine/tmp-lifecycle.md`
- layer1_validator_extended: `true`
- layer1_dispatch_template_updated: `true`
- layer3_close_gate_added: `true`
- layer3_taxonomy_class_added: `true`
- layer4_doctor_invariant_added: `true`
- layer4_agents_md_l139_added: `true`
- layer4_test_fixture_pass: `true`
- tmp_entry_count_observed: `5473`
- tmp_dir_released: `true`
- joshua_lens_25yr_ops_cited: `true`
- receipt_in_repo: `true`
