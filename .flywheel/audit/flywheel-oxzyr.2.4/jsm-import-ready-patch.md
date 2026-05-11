# JSM-import-ready patch — flywheel-oxzyr.2.4 FM-6 + FM-9 detect/fix invariants

## Status

**Applied** to working tree at `~/.claude/skills/.flywheel/bin/flywheel-loop`
per Joshua-domain skill discipline (jsm-unmanaged `.flywheel` substrate per
flywheel-2xdi.154 audit) + 2xdi.60.1 precedent for direct mutation paired
with jsm-import-ready patch.

Sister patches in the same wave: oxzyr.2.1 (chokepoint), oxzyr.2.2 (undo),
oxzyr.2.3 (FM-5/FM-10 audit-only retraction), oxzyr.2.5 (FM-8 quarantine).

## Artifacts

| File | Hash | Purpose |
|---|---|---|
| `~/.claude/skills/.flywheel/bin/flywheel-loop` (post-patch) | `82deb563cd9a44fb536f3173187d01b4d51047eca41449109e6b943ad5605ef1` | full bin post-mutation |

## What the patch adds

Two new functions in the `BEGIN doctor-mode chokepoint` module + two
dispatcher intercepts in the `doctor)` case. All additions are sandwiched
between existing markers; no existing code rewritten.

### `_flywheel_loop_fm6_detect_fix()` (lines 1037-1151)

- Class: legacy-loop-config-schema-drift (byte-exact undo)
- Surface: `flywheel-loop doctor fm6 --target PATH [--dry-run|--apply] [--run-id ID] [--json]`
- Detect: parse loop config JSON; flag drift on unknown keys / missing required keys / malformed JSON
- Fix: build migrated JSON (archive unknown under `_unknown_keys_archive`; fill missing required); write via `_flywheel_loop_mutate file_write`
- Schema: `fm6-detect-fix/v1`
- Exit codes: 0=clean | 1=DRIFTED+migrated | 2=usage | 3=DRIFTED+dry-run

### `_flywheel_loop_fm9_detect_fix()` (lines 1156-1265)

- Class: frozen-projection-of-mutable-state-in-tick-prompts (byte-exact undo)
- Surface: `flywheel-loop doctor fm9 --template PATH [--dry-run|--apply] [--run-id ID] [--json]`
- Detect: scan for 3 literal-pattern classes (`hardcoded_user_path`, `hardcoded_bead_id`, `hardcoded_git_sha`)
- Fix: perl regex substitutions → `{{user_home}}` / `{{bead_id}}` / `{{sha}}`; write via `_flywheel_loop_mutate file_write`
- Schema: `fm9-detect-fix/v1`
- Exit codes: 0=clean | 1=FROZEN+rewritten | 2=usage | 3=FROZEN+dry-run

### Dispatcher intercepts (lines 1340-1349 inside `doctor)` case)

```bash
# flywheel-oxzyr.2.4: intercept `doctor fm6` (legacy-loop-config-schema-drift) + `doctor fm9` (frozen-projection-in-tick-prompts)
if [[ "${1:-}" == "fm6" ]]; then
    shift; _flywheel_loop_fm6_detect_fix "$@"; exit $?
fi
if [[ "${1:-}" == "fm9" ]]; then
    shift; _flywheel_loop_fm9_detect_fix "$@"; exit $?
fi
```

## Live verification

```
$ flywheel-loop doctor fm6 --help
usage: flywheel-loop doctor fm6 --target PATH [--dry-run|--apply] [--run-id ID] [--json]   rc=2

$ flywheel-loop doctor fm9 --help
usage: flywheel-loop doctor fm9 --template PATH [--dry-run|--apply] [--run-id ID] [--json]   rc=2
```

End-to-end byte-exact undo round-trip verified for both FMs:
- FM-6: drift config → apply → undo → restored_sha (`687d6e76…`) == pre_sha
- FM-9: frozen template → apply → undo → restored_sha (`da07eebb…`) == pre_sha

## Regression test

`.flywheel/tests/test-oxzyr.2.4-fm6-fm9-byte-exact-undo.sh` (10 AGs / 12 PASS / 0 FAIL).

Test sandboxes the chokepoint backup chain via `FLYWHEEL_DOCTOR_UNDO_DIR=$WORK/undo` so it does not pollute prod state directory.

## Skillos-side commit (peer-orch responsibility)

```bash
cd ~/.claude/skills/.flywheel
git add bin/flywheel-loop
git commit -m "feat(doctor-mode): fm6 + fm9 detect/fix invariants (byte-exact undo class) [flywheel-oxzyr.2.4]

Adds _flywheel_loop_fm6_detect_fix (legacy-loop-config-schema-drift) and
_flywheel_loop_fm9_detect_fix (frozen-projection-of-mutable-state-in-tick-
prompts) to the doctor-mode chokepoint module. Both implement the byte-exact
undo class: substrate mutation through _flywheel_loop_mutate produces a
content-hashed backup, and 'flywheel-loop doctor undo <run-id>' restores
byte-exact (verified pre_sha == restored_sha for both FMs).

Sister functions to oxzyr.2.3 fm5+fm10 (audit-only retraction class).

Dispatcher intercepts added in doctor) case after fm8.

Schemas: fm6-detect-fix/v1 + fm9-detect-fix/v1.

Regression: flywheel.git/.flywheel/tests/test-oxzyr.2.4-fm6-fm9-byte-exact-undo.sh
(10 AGs / 12 PASS / 0 FAIL, including byte-exact undo round-trip for both FMs).

Cross-references:
  flywheel.git audit pack: .flywheel/audit/flywheel-oxzyr.2.4/
  Foundations: oxzyr.2.1 (chokepoint), oxzyr.2.2 (undo subcommand)
  Sister: oxzyr.2.3 (fm5+fm10 audit-only retraction)
  Open siblings: oxzyr.2.5 (fm8 already landed in tree by sibling worker),
                 oxzyr.2.6 (real-fixture round-trip tests for all 10 FMs)"
```

## Errexit trap (reusable knowledge for next FM author)

Found during pre-commit smoke test: `grep -c PATTERN | wc -l` inside `$(...)`
with `set -euo pipefail` (top of flywheel-loop) silently aborts the function
when grep returns rc=1 (no matches). The function returns rc=1 with empty
output — no error message, no stderr.

Fix pattern (applied in fm9 + inline-commented for next author):
```bash
n_pattern="$(grep -oE 'PATTERN' "$target" 2>/dev/null | wc -l | tr -d ' \n' || true)"
```

The `|| true` swallows the pipefail-propagated rc=1 so the substitution
succeeds and the deterministic `"0"` reaches jq.

## Cross-references

- Source bead: flywheel-oxzyr.2.4 (P1)
- Parent: flywheel-oxzyr.2 (pass-2 wave; stays open)
- Foundations: flywheel-oxzyr.2.1 (chokepoint) + flywheel-oxzyr.2.2 (undo)
- Sister: flywheel-oxzyr.2.3 (fm5+fm10 audit-only)
- Siblings: flywheel-oxzyr.2.5 (fm8; already in tree), flywheel-oxzyr.2.6 (fixture round-trip)
- Spec: `.flywheel/audit/flywheel-cli-doctor-upgrade/flywheel-loop-pass-1-repair-spec.md` (lines 41-100, FM-6 + FM-9 sections)
- Substrate boundary: jsm-unmanaged `.flywheel` skill (per flywheel-2xdi.154)
- Joshua-domain mutation precedent: flywheel-2xdi.60.1
