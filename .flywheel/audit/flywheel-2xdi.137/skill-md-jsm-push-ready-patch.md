# JSM-PUSH-READY Patch — flywheel-2xdi.137

**Target:** `/Users/josh/.claude/skills/slack-migration-to-mattermost-phase-2-setup-and-import/SKILL.md`
**Patch type:** `jsm-push-ready` (skill is JSM-managed per `jsm list`)
**Operation:** insert one row in the Script Contracts / Operator scripts table for `smoke-test-phase2.sh`
**Source bead:** `flywheel-2xdi.137`
**Sister:** flywheel-2xdi.135 (Phase 1 smoke-test; same dual-fix pattern)

## Suggested insertion

```markdown
| `scripts/smoke-test-phase2.sh` | (none — uses internally-generated phase1 manifest + bulk-import zip fixtures) | end-to-end smoke artifacts: handoff.json, phase1-manifest.json, mattermost-bulk-import.zip, config.json, phase2-intake/{report,manifest}, live-report, staging-report, smoke-report, restore-report, activation-report, reconcile-report, cutover-report | fails on missing fixtures or stage failure | operator-on-demand validation of the Phase 2 setup + import pipeline before each release |
```

(Adapt the exact table/list format to match the destination SKILL.md
structure. Same shape as the 2xdi.135 Phase 1 SKILL.md patch.)

## Rationale

`flywheel-2xdi.137` flagged `smoke-test-phase2.sh` as `gap-wired-but-cold`.
5-corpus probe: only gap-hunt.jsonl self-ref (corpora 2-5 empty). Script is
operator-on-demand smoke test for the Phase 2 setup+import pipeline.

Per dispatch SKILL-ENHANCE JSM DISCIPLINE BLOCK: phase-2 skill is JSM-managed
→ direct mutation forbidden → this jsm-push-ready artifact for owning JSM
flow to apply at next push cycle.

## Defense-in-depth

Primary fix (registry-allowlist) already shipped to
`~/.claude/skills/.flywheel/data/substrate-registry.json` (47 → 48 entries).
This SKILL.md cite, when JSM flow applies, provides a second clearance path
via probe corpus 4 (skill_md_corpus).

## Boundary

JSM-push-ready patch (NOT jsm-import-ready) because target skill is already
JSM-managed. Patch lives in `.flywheel/audit/flywheel-2xdi.137/` until owning
JSM flow applies it.
