# JSM-import-ready paired patch — flywheel bin docs subcommand

**Target:** `~/.claude/skills/.flywheel/bin/flywheel`
**JSM status:** Class 1 (Joshua-unmanaged; `jsm show .flywheel` → not found)
**Bead:** flywheel-mv2th (Phase 1 of flywheel-38u3d)
**Discipline:** direct mutation applied + paired jsm-import-ready patch per cross-repo-consumer-vs-mutator-boundary doctrine

## What the patch does

Adds a `docs` canonical-cli subcommand to the existing `flywheel` binary (9 → 10 subcommands):

1. **`scaffold_docs_detect_project_type()`** — pure-bash heuristic returning one of 5 archetypes (`rust-lib` / `python-lib` / `ts-lib` / `frontend-spa` / `backend-service`) or `unknown`.
2. **`scaffold_docs_usage()`** — usage block (subcommands + flags + cross-refs to Jeff-skill + doctrine docs + phase-bead chain).
3. **`scaffold_cmd_docs_init()`** — `flywheel docs init` implementation. Phase 1 = detection-only; emits JSON envelope with `mutates_state=false`. Phase 2 (flywheel-ti46c) will wire actual scaffold-nextra.sh invocation.
4. **`scaffold_cmd_docs()`** — dispatcher for `docs <subcommand>`.
5. Wired into `scaffold_main`'s case statement + the `_scaffold_is_canonical_arg` allowlist.
6. Updated top-level usage text + topic-help list to include `docs`.

182 net lines added (4712 → 4894).

## Direct mutation already applied

`.flywheel` skill is Class 1 (Joshua-unmanaged). Direct mutation applied to live `~/.claude/skills/.flywheel/bin/flywheel` during this worker-tick. Paired patch artifact below for future JSM-import discipline.

## Apply (when `.flywheel` skill later gets JSM-imported)

```bash
cd <skillos-workspace>/.flywheel
patch -p1 < /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-mv2th/patches/flywheel.patch
diff bin/flywheel /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-mv2th/patches/flywheel.proposed
jsm push .
```

## Verify post-apply

```bash
FW=~/.claude/skills/.flywheel/bin/flywheel
bash -n "$FW" && echo SYNTAX_OK
"$FW" --help 2>&1 | grep -q "docs <subcommand>" && echo HELP_OK
"$FW" docs init --target /tmp/nonexistent-dir 2>&1 | jq -e '.archetype == "unknown"' >/dev/null && echo DETECTION_OK
bash /Users/josh/Developer/flywheel/tests/flywheel-docs-canonical-cli.sh | tail -1
# expect: SUMMARY pass=18 fail=0
```

## Rollback

```bash
cd ~/.claude/skills/.flywheel
patch -p1 -R < /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-mv2th/patches/flywheel.patch
```

## Phase chain reference

| Phase | Bead | Status |
|---|---|---|
| 1 (THIS) | flywheel-mv2th | docs init + project-type detection (this bead) |
| 2 | flywheel-ti46c | dogfood on flywheel repo (waits on Phase 1 close) |
| 3 | flywheel-sjr9e | alps + mobile-eats (waits on Phase 2) |
| 4 | flywheel-ll107 | blackfoot + terratitle + vrtx (deferred; waits on Phase 3) |

`no_direct_skill_mutation_reason=jsm_unmanaged_with_paired_jsm_import_ready_patch_artifact_written`
