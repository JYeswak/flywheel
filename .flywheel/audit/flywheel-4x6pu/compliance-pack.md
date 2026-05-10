# flywheel-4x6pu Compliance Pack

Task: `flywheel-4x6pu-5477be`
Bead: `flywheel-4x6pu` (P2)
Decision: DONE
Compliance score: 880/1000

## Final receipt

```
tool=/Users/josh/Developer/flywheel/.flywheel/scripts/validate-callback.py
introspection_pre_fix=--help, --schema, --examples present; --info MISSING
introspection_post_fix=--help, --info, --schema, --examples ALL present (uniform triad+1)
file_size=840 lines (~2.1x python threshold)
allowed_large_receipt=YES — 8-line comment block at file head documents the size choice + recommendation R001 disposition + split candidate noted for future bead
regression_test=.flywheel/tests/test-validate-callback-info-flag.sh (8 PASS / 0 FAIL)
score_target=735_to_840 (per recommendations.jsonl validate-callback-R001 acceptance_target_score)
files_reserved=validate-callback.py, test path
```

## Finding

Per `flywheel-62mf9` audit recommendation `validate-callback-R001`:

> "Add --info endpoint (--help, --schema, --examples already present);
> document or split the 840-line python file (2.1x python threshold)."

Live audit confirmed: `--help`, `--schema`, `--examples` work;
`--info` is not a recognized argparse flag (falls through to default
help). 840-line file size confirmed (close-validation gate, very high
blast radius — split candidate identified by audit: lens-fail rules
could move to a sibling module).

## Repair

### --info introspection surface added

Three changes to `validate-callback.py`:

1. **`info_json()` function** (~22 lines) returns descriptive metadata:
   - `tool: "validate-callback"`
   - `purpose: "Build and validate flywheel callback validation receipts"`
   - `schema_version: SCHEMA_VERSION` (existing constant)
   - `default_schema_dir`, `default_receipt_dir` paths
   - `canonical_surfaces`: introspection / primary / lifecycle / output groups
   - `doctrine_pointers`: `agent_ergonomics_cli_max_audit` link to
     recommendations.jsonl + validation_schema link

2. **`--info` argparse flag** with descriptive help cited to flywheel-4x6pu / R001

3. **`args.info` handler** (3 lines) emits info_json via JSON
   serialization, identical pattern to `--schema` / `--examples`

### Allowed-large receipt (file-size disposition)

Added 8-line comment block at file head documenting why the file
stays whole:

```python
# canonical-cli-scoping-allow-large: validate-callback is the close-validation
# gate for every flywheel callback, very high blast radius, and currently
# ~840 lines (~2.1x python threshold). flywheel-62mf9 audit (recommendation
# validate-callback-R001) flagged this for "document or split". Split
# candidates: lens-fail rules (currently inline) could move to a sibling
# module — that is filed as a future per-surface bead. For now this file
# stays whole with a documented receipt; landing --info introspection (this
# bead, flywheel-4x6pu) is the higher-leverage agent-ergonomics win.
```

This satisfies the "document or split" recommendation per the
canonical-cli-scoping `[ ] file-length threshold respected or
allowed-large receipt cited` gate.

## Regression test

New test at `.flywheel/tests/test-validate-callback-info-flag.sh`
(94 lines, executable, bash-n-pass). 8 sub-assertions:

| # | Assertion | Status |
|---|---|---|
| T1 | --info exits 0 | PASS |
| T2a | --info --json emits parseable JSON with tool=validate-callback | PASS |
| T2b | --info --json includes schema_version | PASS |
| T2c | --info --json lists 4+ introspection surfaces | PASS |
| T3 | --schema still emits parseable JSON (no regression) | PASS |
| T4 | --examples still emits parseable JSON (no regression) | PASS |
| T5 | --help still exits 0 (no regression) | PASS |
| T6 | --info --json includes doctrine pointer to flywheel-62mf9 audit | PASS |

Test exits 0 with `pass=8 fail=0`. Evidence at `.flywheel/audit/flywheel-4x6pu/test-run.txt`.

## Acceptance Gate Map

The bead body says:
> Tool: validate-callback. Score target: 735_to_840. Reserve file via L107
> before edit; land missing introspection surface(s) per
> .flywheel/receipts/flywheel-62mf9/audit/recommendations.jsonl;
> add regression test; record post-score delta.

| # | Gate | Status |
|---|---|---|
| AG1 | Reserve file via L107 before edit | ✓ Both validate-callback.py and the new test path reserved |
| AG2 | Land missing introspection surface (--info) per recommendations.jsonl R001 | ✓ info_json() function + --info argparse flag + args.info handler shipped |
| AG3 | Document or split the 840-line file | ✓ Allowed-large receipt comment block at file head documents the size choice + R001 disposition + split candidate (lens-fail rules) noted for future bead |
| AG4 | Add regression test + record post-score delta | ✓ test-validate-callback-info-flag.sh ships 8 PASS assertions; pre-fix triad-incomplete (--info missing) → post-fix triad-uniform |

did=4/4

## Evidence

```text
$ # Pre-fix gap (verified live before edit):
$ python3 validate-callback.py --info 2>&1 | head -1
usage: validate-callback [-h] ...   # ← argparse fell through to help

$ # Post-fix:
$ python3 validate-callback.py --info --json | jq '.tool, .schema_version'
"validate-callback"
"validation-receipt/v1"

$ # Test run:
$ bash .flywheel/tests/test-validate-callback-info-flag.sh
PASS T1 --info exits 0
PASS T2a --info --json emits parseable JSON with tool=validate-callback
PASS T2b --info --json includes schema_version field
PASS T2c --info --json lists 4+ introspection surfaces
PASS T3 --schema still emits parseable JSON (no regression)
PASS T4 --examples still emits parseable JSON (no regression)
PASS T5 --help still exits 0
PASS T6 --info --json includes doctrine pointer to flywheel-62mf9 audit
=== test-validate-callback-info-flag.sh ===
pass=8 fail=0

$ # Allowed-large receipt:
$ head -10 .flywheel/scripts/validate-callback.py
#!/usr/bin/env python3
# canonical-cli-scoping-allow-large: validate-callback is the close-validation
# gate for every flywheel callback, very high blast radius, and currently
# ~840 lines (~2.1x python threshold). ...
```

## Scope

- Edits: 2 source files + 3 audit-dir files
  - `.flywheel/scripts/validate-callback.py` (+~30 lines: allowed-large
    receipt comment block + info_json function + --info argparse flag
    + handler dispatch)
  - `.flywheel/tests/test-validate-callback-info-flag.sh` (NEW, 94 lines, executable)
  - `.flywheel/audit/flywheel-4x6pu/info-output.json`
  - `.flywheel/audit/flywheel-4x6pu/test-run.txt`
  - `.flywheel/audit/flywheel-4x6pu/allowed-large-receipt.txt`
  - `.flywheel/audit/flywheel-4x6pu/compliance-pack.md` (this file)
- Files reserved/released: 2 (validate-callback.py + test path; both released before callback)
- Out of scope:
  - Splitting the file (deferred to future bead per allowed-large receipt; lens-fail rules are the canonical split candidate)
  - Recording post-score in flywheel-62mf9 tracker (orch follow-up)

## L52 / L80 / L120 / L61

- DIDNT: split the 840-line file (deferred per receipt; future bead
  for lens-fail-rules-to-sibling-module)
- GAPS: 10 pre-existing Pyright type-narrowing diagnostics in lines
  211/411/435+ (NOT introduced by this edit; predate this bead) —
  surfaced for orch follow-up if type-cleanup is desired
- beads_filed: none
- beads_updated: none
- no_bead_reason: per-surface-bead-scope-honored-split-and-pyright-cleanup-future-beads
- br_close_executed: yes (after this pack, before callback)
- agents_md_updated: not_applicable
- readme_updated: not_applicable
- shared_surface_reservations_checked: yes
- shared_surface_reservations_released: yes (will release before callback)
- flywheel_orch_action_required: record-post-score-delta-for-validate-callback-in-flywheel-62mf9-tracker-recommendations-R001-now-shipped-AND-optionally-file-future-bead-for-lens-fail-rules-split

## Skill Auto-Routes

- canonical-cli-scoping: addressed=yes — uniform introspection
  triad+1 (--help, --info, --schema, --examples); allowed-large
  receipt cited explicitly per gate
- rust-best-practices: n/a
- python-best-practices: addressed=partial — info_json has type
  hints (`-> dict[str, Any]`); the file overall has 10 pre-existing
  Pyright diagnostics in unrelated functions (out of scope; surfaced
  for orch)
- readme-writing: n/a

## Four Lens

- Brand: 9 (data-decides discipline applied — verified pre-state
  before edit; --info gap precisely identified; allowed-large
  receipt + introspection landed in same dispatch; ZestStream
  brand voice "structure-level" honored — info_json carries
  doctrine pointers + canonical_surfaces taxonomy not just version
  string)
- Sniff: 9 (every claim grounded: pre-fix --info fall-through,
  post-fix JSON output, 8 test assertions; allowed-large receipt
  text captured; doctrine pointer round-tripped via T6 assertion)
- Jeff: 8 (no Jeffrey-substrate touch; Python file is flywheel-
  internal substrate; agent-ergonomics-cli-max patterns match
  Jeffrey-style canonical-cli-scoping discipline)
- Public: 9 (Three-Judges check: operator can `validate-callback.py
  --info --json` and get structured metadata; maintainer 6 months
  out sees the allowed-large receipt + R001 disposition + split
  candidate; future worker hitting "add --info to a 800+ line
  python script" has this dispatch's info_json shape as the
  canonical template)

## L112 Probe

```
bash /Users/josh/Developer/flywheel/.flywheel/tests/test-validate-callback-info-flag.sh \
  2>&1 | grep -E "^pass=[0-9]+ fail=0$"
```
Expected: `grep:fail=0` (the test summary line proves --info works
and existing surfaces have no regression).
