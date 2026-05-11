# JSM-Import-Ready Patch — flywheel-oxzyr.2.1

**Target:** `/Users/josh/.claude/skills/.flywheel/bin/flywheel-loop`
**Patch type:** `jsm-import-ready` (`.flywheel` skill is unmanaged per `jsm list`)
**Operation:** insert chokepoint function block + refactor 3 mutation sites
**Source bead:** `flywheel-oxzyr.2.1`
**Sister:** spec at `.flywheel/audit/flywheel-cli-doctor-upgrade/flywheel-loop-pass-1-repair-spec.md` (mutate-chokepoint candidate section)

## What this patch ships

### 1. New function `_flywheel_loop_mutate()` (chokepoint)

Inserted between `# ====== END canonical-cli scaffold ======` (line 505 pre-patch) and the `FLYWHEEL_HOME=` env definition (line 506 pre-patch). Block wrapped with `# ====== BEGIN doctor-mode chokepoint (bead flywheel-oxzyr.2.1) ======` / `# ====== END doctor-mode chokepoint ======` markers for future surgical updates.

Function signature:
```
_flywheel_loop_mutate(action, target, payload, [run_id])
```

Actions: `file_write`, `file_truncate`, `dir_mkdir`. Other actions return rc=2 ERR.

4-step intent-then-apply discipline:
1. Record intent → `~/.local/state/flywheel/doctor-undo/<run-id>/intent.jsonl`
2. SHA-256 pre-state + content-hashed backup at `<sha-prefix>/<rel>.bak`
3. Perform mutation
4. Record outcome with pre_sha + post_sha + rc → `<run-id>/applied.jsonl`

Bypass: `FLYWHEEL_LOOP_MUTATE_DISABLED=1` skips backup chain (test/CI only).

### 2. Three mutation sites refactored to call chokepoint

| Old line | Site | Action class | Refactor |
|---|---|---|---|
| 303 (`audit_log_truncate`) | scaffold_cmd_repair | file_truncate | `_flywheel_loop_mutate file_truncate "$audit_log" ""` |
| 592 (`mkdir -p ticks_dir`) | native repo packet writer | dir_mkdir | `_flywheel_loop_mutate dir_mkdir "$ticks_dir" ""` |
| 612 (`printf > receipt`) | native repo packet writer | file_write | `_flywheel_loop_mutate file_write "$receipt" "$(printf '%s\n' "$packet")"` |

All 3 sites preserved with `# flywheel-oxzyr.2.1: route through chokepoint (was: ...)` provenance comments.

## Verification post-patch (already validated)

```
bash -n /Users/josh/.claude/skills/.flywheel/bin/flywheel-loop: OK
flywheel-loop --help: OK (canonical CLI surface intact)
flywheel-loop --info: OK
Roundtrip test (file_write):
  - pre_sha 057d6dbd... captured + backed up byte-exact
  - mutation applied (test.txt: initial-content-line-1 → NEW-CONTENT-ROUNDTRIP)
  - post_sha 1b12acbe... recorded
  - intent.jsonl + applied.jsonl + backup all present at run_id dir
```

## File-length receipt

Pre-patch: 852 lines (37,599 bytes)
Post-patch: 953 lines (~42KB)
Delta: +101 lines (chokepoint function + provenance comments at 3 sites)
Threshold: 1000 lines (per python-best-practices file-length); under cap.

## JSM management state

`jsm list` does NOT contain `.flywheel` skill (verified session-prior). Unmanaged → direct mutation allowed + this paired patch artifact provided for future JSM import if/when `.flywheel` becomes managed.

`no_direct_skill_mutation_reason=skill_unmanaged_direct_mutation_allowed_with_paired_jsm_import_ready_patch_artifact_written`

## Sister-bead dependency unlocked

Pass-2 sub-beads .2.2 through .2.6 (per decomposition manifest from
flywheel-oxzyr.2 DECLINE evidence) are now UNBLOCKED:

- **oxzyr.2.2** (doctor undo subcommand) can now read intent.jsonl + restore from backups/ chain
- **oxzyr.2.3** (FM-5 + FM-10 audit-only retraction) can route audit-trail writes through chokepoint
- **oxzyr.2.4** (FM-6 + FM-9 byte-exact undo) can rely on chokepoint backup chain
- **oxzyr.2.5** (FM-8 input-deaf quarantine) can route quarantine-state writes through chokepoint
- **oxzyr.2.6** (real fixture data + round-trip tests) can exercise chokepoint round-trip per fixture

The foundation is now in place.

## Sister-precedent — single-chokepoint discipline

Sister to:
- `feedback_dispatch_callback_first.md` (every dispatch must have callback route)
- `feedback_validate_redispatch_foundational_discipline.md` (validate-then-redispatch chokepoint)
- The mutate-chokepoint pattern matches the dispatch-chokepoint pattern at the orch level: single function all mutations flow through, single audit chain.
