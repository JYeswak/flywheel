# JSM-PUSH-READY Patch — flywheel-2xdi.135

**Target:** `/Users/josh/.claude/skills/slack-migration-to-mattermost-phase-1-extraction/SKILL.md`
**Patch type:** `jsm-push-ready` (NOT direct-mutation; skill is JSM-managed per `jsm list`)
**Operation:** insert one row in the "Script Contracts" table after the existing operator scripts
**Source bead:** `flywheel-2xdi.135`
**JSM discipline:** direct mutation forbidden because slack-migration-to-mattermost-phase-1-extraction is JSM-managed (visible in `jsm list`). This artifact is for the owning JSM/skillos flow to apply via `jsm push` or equivalent.

## Anchor (existing content — locate insertion point)

In SKILL.md "Script Contracts" section (line ~91-95), the table currently includes:

```markdown
| `scripts/build-artifact-manifest.py` | stage files | manifest JSON | fails on missing file | after each stage |
| `scripts/intake-official-export.py` | official ZIP + optional admin CSVs | quarantined raw artifacts + raw manifest | fails on missing input or bad ZIP | official-export path |
| `scripts/run-slackdump-export.sh` | slackdump auth/env | export directory + raw ZIP | fails on slackdump/export ZIP failure | Pro/Free or supplement path |
```

## Insertion block (one row appended to Script Contracts table)

```markdown
| `scripts/smoke-test-phase1.sh` | (none — uses bundled `assets/fixtures/slack-export-sample`) | end-to-end smoke artifacts in `${PHASE1_SMOKE_ROOT}` or tmpdir | fails on missing fixtures or zip/cp/mkdir errors | operator-on-demand validation of the raw→enriched→import-ready pipeline before each release |
```

## Rationale

`flywheel-2xdi.135` flagged `smoke-test-phase1.sh` as `gap-wired-but-cold`. 5-corpus probe receipt:

| Corpus | Match? |
|---|---|
| Recent flywheel jsonl ledgers (<30d) | gap-hunt.jsonl only (self-ref) |
| Sibling-repo dispatch-logs | none |
| Runtime source (.sh + bin) | none |
| **SKILL.md prose** | **PRE-PATCH: none. POST-PATCH: 1 row in Script Contracts table** |
| Launchd plists | none |

Without SKILL.md citation, the script is canonically orphan despite being a load-bearing smoke test for the Phase 1 extraction pipeline.

## JSM apply mechanism

Because slack-migration-to-mattermost-phase-1-extraction is JSM-managed (per
`jsm list`), this patch CANNOT be applied via direct file mutation. Instead:

1. JSM/skillos flow processes this artifact
2. Updates the canonical source-of-truth for the skill (wherever JSM stores it)
3. Pushes the updated SKILL.md to all install destinations via `jsm push`

Per dispatch packet SKILL-ENHANCE JSM DISCIPLINE BLOCK:
> "If `jsm status` or `jsm list --json` shows the skill is JSM-managed, direct
> live mutation under `~/.claude/skills/<skill>/` is forbidden. Produce a
> `jsm-push-ready` patch artifact instead."

## Sister Operator Library / Operator Router context

Per SKILL.md "Operator Router" section, the existing operator scripts route by phase
(intake → export → enrich → validate). The smoke-test-phase1.sh runs the
END-TO-END pipeline against fixtures — sister to the unit-level validate scripts
(`validate-phase1-artifacts.py`, `validate-phase1-jsonl.py`, etc.) but at the
integration/smoke level.

## Verification post-import (when JSM flow applies)

```bash
# 1. SKILL.md cite present
grep -q 'scripts/smoke-test-phase1.sh' /Users/josh/.claude/skills/slack-migration-to-mattermost-phase-1-extraction/SKILL.md

# 2. SKILL.md corpus (probe corpus 4) now contains script name
python3 -c "
import os
texts = []
for root, dirs, files in os.walk(os.path.expanduser('~/.claude/skills')):
    for f in files:
        if f == 'SKILL.md':
            try:
                with open(os.path.join(root, f)) as fh:
                    texts.append(fh.read())
            except: pass
corpus = '\n'.join(texts)
assert 'smoke-test-phase1.sh' in corpus
assert 'smoke-test-phase1' in corpus
print('SKILL.md corpus contains script')
"

# 3. Gap-hunt-probe wired-but-cold class no longer flags this script
# (would clear via SKILL.md cite, redundant with the substrate-registry allowlist
# already shipped in this bead — defense-in-depth)
```

## Boundary

This is a `jsm-push-ready` patch (not jsm-import-ready) because the target skill
is already JSM-managed. The patch lives in `.flywheel/audit/flywheel-2xdi.135/`
until the JSM/skillos owning flow applies it.

## Defense-in-depth

The bead's primary fix is the substrate-registry allowlist entry (already shipped
to `~/.claude/skills/.flywheel/data/substrate-registry.json`; `.flywheel` substrate
is unmanaged so direct edit is allowed). When the JSM flow applies THIS patch
artifact, the SKILL.md cite becomes a SECOND clearance path — defense-in-depth
against future calibration regressions.

This is the canonical "belt + suspenders" pattern from flywheel-2xdi.72.1.
