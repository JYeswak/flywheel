# FM-9: frozen-projection in templates

**Class:** byte-exact-undo (Shape A canonical exemplar)
**Test mode:** RUN+UNDO — `flywheel-loop doctor fm9 --template <PATH> --apply` + `doctor undo <run-id>` (.2.4 ship)
**MEMORY source:** `feedback_frozen_projection_of_mutable_state_class.md` (META-RULE 2026-05-06)

## Detect predicate (3 literal-pattern classes)
1. `hardcoded_user_path`: `/Users/[A-Za-z0-9_-]+/` → `{{user_home}}/`
2. `hardcoded_bead_id`: `(flywheel|skillos|fm9_demo|...)-[a-z0-9]{4,8}` → `{{bead_id}}`
3. `hardcoded_git_sha`: `[a-f0-9]{40}` → `{{sha}}`

FROZEN if any class has ≥1 match.

## Fix strategy (byte-exact undo via chokepoint)
- Apply 3 perl regex substitutions in sequence
- Write via `_flywheel_loop_mutate file_write`
- `doctor undo <run-id>` restores byte-exact original

## Round-trip protocol
1. Copy `corrupt-tmpl-with-literal.tmpl` to scratch
2. Capture pre_sha
3. `flywheel-loop doctor fm9 --template <scratch> --apply --run-id <RUN_ID> --json` → expect rc=1, all 3 classes detected
4. Verify scratch content matches `expected-source-named.tmpl` (perl regex output)
5. `flywheel-loop doctor undo <RUN_ID> --apply --json` → expect rc=0
6. Verify restored sha == pre_sha

## Fixture files
- `corrupt-tmpl-with-literal.tmpl` — template with all 3 literal classes present
- `expected-source-named.tmpl` — same template with `{{user_home}}` / `{{bead_id}}` / `{{sha}}` substitutions
- `undo-original.bak` — byte-exact baseline
