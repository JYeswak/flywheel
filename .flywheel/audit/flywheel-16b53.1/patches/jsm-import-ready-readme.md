# jsm-import-ready patch artifact — flywheel-16b53.1

Per Skill-Enhance JSM Discipline Block: `.flywheel` is **unmanaged** (per
`jsm show .flywheel` returning "Skill '.flywheel' not found" and `jsm list`
returning no entry). Direct mutation under `~/.claude/commands/flywheel/` is
allowed; this patch artifact accompanies the direct edit so a future JSM
import can apply the same change verbatim.

## Patch summary

Two files modified in `~/.claude/commands/flywheel/`:

1. `_shared/dispatch-template.md` — new `## OWNED WRITE ROOTS BLOCK` (+72 lines)
   inserted before `## SHARED-SURFACE RESERVATION BLOCK` (line 338 pre-patch)
2. `worker-tick.md` — added 14-line OWNED_WRITE_ROOTS verification sub-bullet
   to step 3 (Reserve files before editing) before step 4

## Patch content for JSM-import replay

When the `.flywheel` skill is JSM-managed in the future, apply this patch as a
`jsm push`-ready commit:

### File 1: `_shared/dispatch-template.md`

Insert immediately before `## SHARED-SURFACE RESERVATION BLOCK`:

```markdown
## OWNED WRITE ROOTS BLOCK

Workers MUST verify every Write/Edit destination path resolves under one of
these allowed roots BEFORE invoking the Write or Edit tools, or before any
shell command (`cat > path`, `tee path`, `>> path`, `cp src dest`, etc.) that
writes to an absolute path.

This block exists because cross-orch canonical substrate (skillos, mobile-eats,
other peer-orch repos) is reachable by absolute path from the worker's process,
and an absolute-path-construction error can silently clobber another orch's
canonical doctrine. Surfaced by `flywheel-16b53` after the `v38e1.5` worker
wrote stub-content over 9 skillos canonical doctrine files via this exact
drift class.

**Default allowlist (per dispatch — orch may extend or restrict):**
- `/Users/josh/Developer/flywheel/` — this repo's working tree
- `/tmp/` and `mktemp -d` outputs under `$WORK_TMP` — scratch only
- `~/.local/state/flywheel/` — worker substrate state
- `~/.claude/skills/.flywheel/` — only via paired-jsm-import patch pattern; NOT direct edit
- `.beads/issues.jsonl` (under the flywheel repo) — only via `br` CLI, never direct edit

**Forbidden default — peer-orch canonical substrate (never write without explicit orch dispatch):**
- `/Users/josh/Developer/skillos/` — Class 2 substrate, owned by skillos:1
- `/Users/josh/Developer/mobile-eats/` — peer-orch substrate, owned by mobile-eats:1
- `/Users/josh/Developer/{vrtx,terratitle,alpsinsurance,polymarket-pico-z,clutterfreespaces,...}/` — client substrate
- Any other `~/Developer/<repo>/` directory not on the per-bead allowlist

**Per-bead override:** the orch may extend or restrict the default allowlist
in the dispatch packet's task body via an explicit `OWNED_WRITE_ROOTS=` line.

(... full block content as appears in current ~/.claude/commands/flywheel/_shared/dispatch-template.md ...)
```

### File 2: `worker-tick.md`

Inside step 3 ("Reserve files before editing"), append before step 4:

```markdown
   - **Verify every absolute-path Write destination against `OWNED_WRITE_ROOTS`
     before invoking Write/Edit.** See the dispatch-template's `OWNED WRITE
     ROOTS BLOCK` for the default allowlist + per-bead override mechanism.
     The check: resolve via `realpath`, find toplevel via
     `git -C $(dirname <path>) rev-parse --show-toplevel`, verify against
     the bead allowlist. If no match: STOP, do NOT write, send BLOCKED with
     `blocker_class=owned_write_root_violation`. Per the `flywheel-16b53`
     trauma-class incident (v38e1.5 drift), absolute-path-construction errors
     can silently clobber peer-orch canonical substrate without this guard.
   - The DONE callback MUST include
     `owned_write_roots_verified=yes owned_write_roots_allowlist=<roots>`
     when any absolute-path write occurred. Missing or `no`/`unknown` is
     rejected by the callback validator per L120-sibling discipline.
```

## Provenance

- Source bead: `flywheel-16b53.1` (P0 mitigation A from `flywheel-16b53` investigation)
- Direct-edit commit: ships in flywheel side with this evidence pack
- Live files (post-patch):
  - `~/.claude/commands/flywheel/_shared/dispatch-template.md` (lines 338-411 contain the new block)
  - `~/.claude/commands/flywheel/worker-tick.md` (step 3 final sub-bullets)
- JSM management status (verified at time of authoring): unmanaged
  (`jsm show .flywheel` returned not-found; `jsm list` had no `.flywheel` entry)

## When to re-import via JSM

Re-import if any of:
- `.flywheel` becomes JSM-managed
- The dispatch-template / worker-tick.md surfaces are migrated under JSM control
- A peer worker authors a competing OWNED_WRITE_ROOTS pattern that needs reconciling
