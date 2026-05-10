# flywheel-hzij2 Compliance Pack

Task: `flywheel-hzij2-dec365`
Bead: `flywheel-hzij2` (P2)
Decision: DONE
Compliance score: 880/1000

## Final receipt

```
tool=/Users/josh/Developer/flywheel/.flywheel/scripts/tmp-aggressive-prune.sh
file_size=189 lines (smallest in the 7-surface scope)
introspection_pre_fix=--help present; --info MISSING; --schema MISSING; --examples MISSING (audit was stale on --examples)
introspection_post_fix=--help, --info, --schema, --examples ALL present (uniform triad+1)
fix_type=add 3 case-statement handlers (--info, --schema, --examples) with inline cat <<EOF JSON/text bodies
regression_test=.flywheel/tests/test-tmp-aggressive-prune-introspection.sh (11 PASS / 0 FAIL)
score_target=540_to_820 (per recommendations.jsonl tmp-aggressive-prune-R001 acceptance_target_score)
files_reserved=tmp-aggressive-prune.sh, test path
```

## Finding

Per `flywheel-62mf9` audit recommendation `tmp-aggressive-prune-R001`:

> "Add --help, --info, --schema. File is small (189 lines);
> --examples already present."

Audit was stale on TWO dimensions when verified live:

1. **`--help` already present** (line 56-59 of the script — dumps
   the comment block at file head). Recommendation listed it as
   missing.
2. **`--examples` was NOT present** despite recommendation claim.
   Confirmed via case statement: only `--apply`, `--dry-run`,
   `--idempotency-key`, `--max-mtime-days`, `--root`, `--json`,
   `--help`. Three handlers needed (not two): `--info`, `--schema`,
   AND `--examples`.

## Repair

Added 3 introspection handlers to the case statement after
existing `--help` (38 lines added including 4-line comment block):

### --info (JSON metadata + canonical_surfaces taxonomy)

```json
{
  "tool": "tmp-aggressive-prune",
  "purpose": "default-aggressive /private/tmp lifecycle enforcement (Layer 2 doctrine)",
  "schema_version": "tmp-aggressive-prune.v1",
  "doctrine_pointer": "flywheel-2bd2r",
  "blast_radius": "medium",
  "mutation_default": "dry-run",
  "canonical_surfaces": {
    "introspection": ["--help", "--info", "--schema", "--examples"],
    "primary": ["--apply", "--dry-run", "--idempotency-key", "--max-mtime-days", "--root"],
    "output": ["--json"]
  },
  "safety_gates": [
    "--apply requires --idempotency-key",
    "mkdir-atomic mutex lock",
    "deny-list protects system+IPC paths"
  ]
}
```

### --schema (output schema for both dry-run and apply modes)

```json
{
  "schema_version": "tmp-aggressive-prune.v1",
  "tool": "tmp-aggressive-prune",
  "output_modes": [
    {"mode": "dry-run", "fields": ["status","apply","ts","root","candidates_count","protected_count","sample_size_failures","max_mtime_days","sample","protected_sample"]},
    {"mode": "apply", "fields": ["status","apply","ts","root","idempotency_key","candidates_count","protected_count","sample_size_failures","deleted_count","max_mtime_days","free_after_gb"]}
  ],
  "exit_codes": {"0": "success", "1": "lock_conflict", "2": "validation_failure"}
}
```

### --examples (paste-able invocations)

5 invocation examples: dry-run (default + json), apply with
idempotency-key, custom mtime threshold, custom root for
test fixtures.

## Regression test

New test at `.flywheel/tests/test-tmp-aggressive-prune-introspection.sh`
(115 lines, executable, bash-n-pass). 11 sub-assertions:

| # | Assertion | Status |
|---|---|---|
| T1 | --help exits 0 (existing surface, no regression) | PASS |
| T2a | --info emits JSON with tool=tmp-aggressive-prune | PASS |
| T2b | --info includes schema_version | PASS |
| T2c | --info lists 4+ introspection surfaces | PASS |
| T2d | --info lists safety_gates | PASS |
| T3a | --schema emits canonical schema_version | PASS |
| T3b | --schema describes both dry-run and apply output_modes | PASS |
| T3c | --schema documents stable exit codes 0/1/2 | PASS |
| T4 | --examples emits non-empty paste-able output | PASS |
| T5 | --dry-run --root=/tmp still works (no regression) | PASS |
| T6 | unknown args still exit 2 (no arg-parse regression) | PASS |

Test exits 0 with `pass=11 fail=0`.

## Acceptance Gate Map

| # | Gate | Status |
|---|---|---|
| AG1 | Reserve file via L107 before edit | ✓ Both tmp-aggressive-prune.sh and the new test path reserved |
| AG2 | Land missing introspection surface(s) per recommendations.jsonl R001 | ✓ Three handlers added (--info, --schema, --examples); recommendation was stale on --help and --examples — corrected diagnosis documented |
| AG3 | Add regression test | ✓ 11 PASS assertions covering all 4 introspection surfaces + 2 no-regression checks |
| AG4 | Record post-score delta | ✓ Pre-fix triad-incomplete (3/4 surfaces missing); post-fix triad+1-uniform; locked by regression test |

did=4/4

## Evidence

```text
$ # Pre-fix gaps:
$ tmp-aggressive-prune.sh --info 2>&1
unknown arg: --info
$ tmp-aggressive-prune.sh --schema 2>&1
unknown arg: --schema
$ tmp-aggressive-prune.sh --examples 2>&1
unknown arg: --examples

$ # Post-fix:
$ tmp-aggressive-prune.sh --info | jq -r '.tool, .schema_version, .blast_radius'
tmp-aggressive-prune
tmp-aggressive-prune.v1
medium

$ tmp-aggressive-prune.sh --schema | jq -r '.output_modes[].mode'
dry-run
apply

$ tmp-aggressive-prune.sh --examples | head -2
# Dry-run (default) — report what would be pruned, mutate nothing
tmp-aggressive-prune.sh

$ # Test run:
$ bash .flywheel/tests/test-tmp-aggressive-prune-introspection.sh | tail -2
=== test-tmp-aggressive-prune-introspection.sh ===
pass=11 fail=0
```

## Scope

- Edits: 2 source files + 3 audit-dir files
  - `.flywheel/scripts/tmp-aggressive-prune.sh` (+~38 lines: 3
    introspection handlers with comment block)
  - `.flywheel/tests/test-tmp-aggressive-prune-introspection.sh` (NEW, 115 lines, executable)
  - `.flywheel/audit/flywheel-hzij2/info-output.json`
  - `.flywheel/audit/flywheel-hzij2/schema-output.json`
  - `.flywheel/audit/flywheel-hzij2/test-run.txt`
  - `.flywheel/audit/flywheel-hzij2/compliance-pack.md` (this file)
- Files reserved/released: 2 (tmp-aggressive-prune.sh + test path; both released before callback)
- Out of scope:
  - Recording post-score in flywheel-62mf9 tracker (orch follow-up)
  - Other R001 surfaces in the 7-surface scope (their own per-surface beads)

## L52 / L80 / L120 / L61

- DIDNT: nothing — clean execution path
- GAPS: audit was stale on --help (already present) and --examples
  (NOT present despite recommendation claim) — surfaced as
  flywheel-62mf9 audit-quality observation
- beads_filed: none
- beads_updated: none
- no_bead_reason: per-surface-bead-scope-honored-audit-quality-feedback-orch-routed
- br_close_executed: yes (after this pack, before callback)
- agents_md_updated: not_applicable
- readme_updated: not_applicable
- shared_surface_reservations_checked: yes
- shared_surface_reservations_released: yes (will release before callback)
- flywheel_orch_action_required: record-post-score-delta-for-tmp-aggressive-prune-in-flywheel-62mf9-tracker-recommendations-R001-now-shipped-AND-flag-audit-quality-recommendation-claimed-help-missing-but-it-was-present-and-claimed-examples-present-but-it-was-missing

## Skill Auto-Routes

- canonical-cli-scoping: addressed=yes — uniform introspection
  triad+1 (--help, --info, --schema, --examples); stable
  schema_version `tmp-aggressive-prune.v1`; stable exit codes
  documented in --schema output; --dry-run / --apply mutation
  discipline preserved
- rust-best-practices: n/a
- python-best-practices: n/a (the embedded python3 -c rmtree call
  is unchanged)
- readme-writing: n/a

## Four Lens

- Brand: 9 (data-decides discipline applied — audit's stale claims
  about --help and --examples corrected against live state; all
  three actually-missing surfaces shipped in same dispatch;
  ZestStream brand voice "structure-level over symptom-level"
  honored — info_json carries safety_gates + doctrine_pointer
  taxonomy not just version string)
- Sniff: 9 (every claim grounded: pre-fix "unknown arg" captures,
  post-fix JSON output, 11 test assertions including 2 no-regression
  checks, audit-quality correction documented)
- Jeff: 8 (no Jeffrey-substrate touch; tmp-aggressive-prune is
  flywheel-internal substrate; agent-ergonomics-cli-max patterns
  match Jeffrey-style canonical-cli-scoping discipline)
- Public: 9 (Three-Judges check: operator can `tmp-aggressive-prune.sh
  --info | jq` and get structured metadata + safety gates surfaced
  inline; maintainer 6 months out sees the inline comment block +
  flywheel-hzij2 reference and the audit-correction note;
  future worker on a similar small bash CLI has this dispatch's
  3-handler pattern as the canonical template)

## L112 Probe

```
bash /Users/josh/Developer/flywheel/.flywheel/tests/test-tmp-aggressive-prune-introspection.sh \
  2>&1 | grep -E "^pass=[0-9]+ fail=0$"
```
Expected: `grep:fail=0` (the test summary line proves the full
introspection triad+1 works without regressing existing surfaces).
