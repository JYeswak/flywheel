---
title: scaffold-canonical-cli.sh comprehensive bug-fix bundle (3 bugs in 1 pass)
type: apply-spec
created: 2026-05-10
parent: flywheel-ws02m (scaffolder author bead — closed)
chain: doctor-mode-integration / scaffolder-revision
bundles: flywheel-946sy + flywheel-52fox + flywheel-gnfi3
---

# Scaffolder bug-fix bundle (3 bugs)

Three scaffolder bugs surfaced across waves 1-3 (jh5bb, aav72, hj4ip). All
three live in the same script (`.flywheel/scripts/scaffold-canonical-cli.sh`)
and one revision pass closes all three. Fix once before campaign continues
(~150 surfaces remain across other lanes).

## Bug 1 (946sy AG1 + gnfi3): absolute-path test scaffold double-slash

**Symptom**: when target path is absolute and outside REPO_ROOT (e.g.,
`/Users/josh/.claude/skills/.flywheel/bin/<binary>`), the generated test file
emits `SCRIPT="$ROOT/<absolute-target>"` which produces `$ROOT//Users/...`
(double-slash) — invalid path; tests fail to find the binary under test.

**Workaround applied inflight**: MistyCliff sed-fixed each generated test in
aav72; CloudyMill same in hj4ip. ~16 generated tests patched manually.

**Fix**: detect absolute target path in scaffolder template emission. Use
bash parameter expansion or branch:
```bash
if [[ "$TARGET_PATH" = /* ]]; then
  echo 'SCRIPT="'"$TARGET_PATH"'"'  # absolute, no $ROOT prefix
else
  echo 'SCRIPT="$ROOT/'"$TARGET_PATH"'"'  # relative, $ROOT prefix
fi
```

**Acceptance**: scaffolder run on absolute target produces test with valid
`SCRIPT=` line; scaffolder run on relative target unchanged.

## Bug 2 (946sy AG2): cmd_doctor/cmd_health/cmd_validate stubs use `[[ ]] && X || Y`

**Symptom**: scaffolder emits short-circuit return idioms in stub bodies:
```bash
cmd_doctor() {
  [[ -d "$ROOT/.flywheel" ]] && return 0 || return 1
}
```
Same scaffolder paired with `canonical-cli-lint.sh` flags this as L4 violation
(short-circuit-in-helper, error severity). Self-inconsistency: tool produces
code that fails its own paired linter.

**Workaround applied inflight**: hj4ip worker rewrote stubs to if/then/else/fi
in 8 files post-scaffold.

**Fix**: scaffolder template uses if/then/else/fi:
```bash
cmd_doctor() {
  if [[ -d "$ROOT/.flywheel" ]]; then
    return 0
  else
    return 1
  fi
}
```

**Acceptance**: scaffolder-emitted stubs pass canonical-cli-lint.sh L4 check
without modification.

## Bug 3 (52fox): backup naming collision under concurrent scaffolding

**Symptom**: `.bak.scaffold-<TS>` suffix collides when 2+ workers run
scaffolder concurrently (same-second TS). Peer worker overwrites peer's
backup; recoverability lost.

**Real incident**: aav72 wave 2 (pane 4) and hj4ip wave 3 (pane 3) ran in
parallel at 2026-05-10T16:03:18-19Z. 8 backups overwritten. MistyCliff
restored from peer's git stash inflight.

**Fix**: append PID + nanosecond resolution to backup suffix:
```bash
local ts; ts="$(date -u +%Y%m%dT%H%M%S%NZ)"  # nanosecond precision
local pid="$$"
local bak="${target}.bak.scaffold-${ts}-${pid}"
```

**Acceptance**: 2 concurrent scaffolder runs on adjacent targets produce
non-colliding `.bak.scaffold-*` files.

## Combined regression test

Add to `tests/scaffold-canonical-cli.sh`:
1. AG1: scaffold synthetic absolute-path target → assert no double-slash in
   generated test SCRIPT= line
2. AG2: scaffold any synthetic target → run canonical-cli-lint.sh on
   generated stubs → assert zero L4 violations
3. AG3: spawn 2 background scaffolder processes against 2 targets in same
   second → assert both .bak files survive (test by counting .bak files)

Existing tests must continue to pass.

## Acceptance gate

- All 3 bugs fixed in `.flywheel/scripts/scaffold-canonical-cli.sh`
- Regression tests added (3 new assertions)
- 20/20 existing scaffolder e2e + 3 new = 23/23 pass
- `canonical-cli-lint.sh` on freshly-scaffolded stub: zero violations
- Idempotent re-scaffold of existing surfaces (jh5bb/aav72/hj4ip outputs)
  produces no new violations
- One commit per bug fix (3 commits) OR one bundled commit with clear
  multi-paragraph message
- Bundle closes flywheel-946sy + flywheel-52fox + flywheel-gnfi3 in same pass

## Boundary

- Don't add new features — bug-fix only
- Existing helper signatures unchanged
- Backward-compat: existing scaffolded surfaces don't need re-scaffolding
  (their .bak file naming under old scheme is fine; only NEW scaffolds use
  new scheme)

## Estimated effort

~1.5 hours total:
- Bug 1 (path): 20 min
- Bug 2 (stubs): 20 min
- Bug 3 (backups): 20 min
- Regression tests: 30 min
- Test + commit + close 3 beads: 20 min

## Dependencies

- jloib.0b (scaffolder ws02m base) — CLOSED
- e4lfb (shebang guard) — CLOSED, lives alongside this fix in same script
