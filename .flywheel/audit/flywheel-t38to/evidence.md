# flywheel-t38to Evidence — fleet grep + rc=4 regression for jsonl-append stale-lock detection

Task: `flywheel-t38to-3b5de7`
Bead: `flywheel-t38to` (P3 OPEN → CLOSED this turn)
Title: [jsonl-append] grep fleet for rogue '> lock' pattern + add regression test for rc=4 path (per flywheel-xy71r finding)
Date: 2026-05-10
Identity: MistyCliff (flywheel:0.4)
Mission fitness: `mission_fitness=adjacent` — closes the
flywheel-xy71r surfaced followup (rogue `> .lock` writer search +
regression test for the rc=4 stale-lock path).

## Headline outcome

**Rogue-writer verdict: jsonl-append.sh ITSELF is the writer that
creates the lock path as a regular file** — its flock branch
(`9>"$lock"` redirect) opens the path for writing without `rm`'ing
on exit, leaving a 0-byte regular file behind. Cross-host
alternation between flock-available (Linux) and mkdir-fallback
(macOS without flock) re-enters the same path with incompatible
semantics and traps the macOS run forever.

A 7-test regression in
`tests/jsonl-append-rc4-stale-lock.sh` exercises the rc=4 stale-lock
path deterministically (stubs `command -v flock` to force the
mkdir branch on any platform).

## Fleet grep verdict (acceptance gate 1)

Searched 3 fleet directories for rogue `> .lock` style writers:

```bash
grep -rnE '> ?[^|]*\.lock[^/a-z]|>> ?[^|]*\.lock[^/a-z]' \
  /Users/josh/Developer/flywheel/.flywheel/scripts/ \
  ~/.claude/skills/.flywheel/ \
  ~/.local/share/flywheel-watchers/ \
  2>/dev/null | grep -v '\.bak\|\.lock-'
```

**Single hit**: `~/.local/share/flywheel-watchers/lib/jsonl-append.sh:29`
— but that's the .xy71r fix-comment citing the pattern in PROSE,
not a code emitter.

The actual rogue writer is the lib's OWN `fw_jsonl__with_lock`
function at line 24:

```bash
if command -v flock >/dev/null 2>&1; then
  (
    flock -x 9
    "$@"
  ) 9>"$lock"   # ← creates ${target}.lock as a regular file
fi
```

The `9>"$lock"` redirect opens the path as a regular FILE for
writing (creating it if absent), and **does NOT `rm` the file on
exit** (only the mkdir branch's `rmdir "$lock"` cleans up).

Cross-host trap: a Linux machine (or any host with flock) takes
the IF branch, leaves the regular file behind. A macOS run
(without flock) takes the ELSE branch, which expects to mkdir at
the same path — fails forever, because a regular file is there.

The xy71r fix detects this and returns rc=4 with structured WARN
in the mkdir branch. The flock branch's leave-file-behind
behavior is preserved (it works fine for flock-style locking;
the issue is only the cross-branch incompatibility).

A potentially-cleaner sub-fix (out of this bead's scope) would be
to either:
1. `rm "$lock"` after the flock subshell exits.
2. Use a different lock-path convention for flock vs mkdir
   (e.g., `${target}.flock` vs `${target}.mkdir-lock`).

For now the rc=4 detection is the correct guardrail — it
converts a 5-second silent stall into an immediate diagnosable
error, which is what xy71r shipped.

## Other lock-path findings during the search

While searching, the fleet's `~/.local/state/flywheel/` directory
has 9 lock paths that exist as 0-byte regular files (vs 3 as
directories):

| Lock path | Type | mtime |
|---|---|---|
| codex-stuck-detector.jsonl.lock | DIR | (active) |
| file-reservations.jsonl.lock | FILE 0B | 2026-05-04 15:05 |
| flywheel-refresh-source.apply.lock | FILE 0B | 2026-05-04 21:59 |
| fuckup-log.jsonl.lock | DIR | (active) |
| loop-driver-runs.jsonl.lock | FILE 0B | 2026-05-09 18:44 |
| orch-no-punt-log.jsonl.lock | DIR | (active) |
| session-topology.jsonl.lock | FILE 0B | 2026-05-06 16:07 |
| session-topology.jsonl.topology-refresh.lock | FILE 0B | 2026-05-06 16:07 |
| tick-driver.lock | FILE 0B | 2026-05-09 18:50 |
| topology-tick-refresh.jsonl.lock | FILE 0B | 2026-05-06 16:07 |
| two-blocker-ticks-state.json.lock | FILE 0B | 2026-05-05 19:49 |
| wire-or-explain-ledger.jsonl.lock | FILE 0B | 2026-05-08 16:08 |

**These FILE-shaped lock paths are NOT necessarily bugs** —
several are created by Python `fcntl.flock` consumers (e.g.,
`shared-surface-reservation-check.sh:135` opens
`file-reservations.jsonl.lock` as a regular file via
`lock_path.open("a+")` for fcntl-style locking). That's correct
flock-style usage.

The trap is when a different consumer of the SAME lock path
expects a DIRECTORY (mkdir-based locking). For
`leverage-ceiling.jsonl.lock`, that cross-convention collision
was the xy71r bug.

This finding is captured here as informational; not a separate
bead because each .lock path's "correct shape" depends on which
consumer is canonical, and the rc=4 detection in the lib is the
right guardrail for cross-convention safety.

## Regression test (acceptance gate 2)

`tests/jsonl-append-rc4-stale-lock.sh` 7 PASS gates:

| # | Test | Behavior |
|---|---|---|
| 1 | lib exists with rc=4 branch + flywheel-xy71r citation | substrate gate (file path + 3 marker strings) |
| 2 | rc=4 propagation through fw_jsonl_append_validated case stmt | confirms rc surfaces to caller |
| 3 | regular-file lock + mkdir branch forced → rc=4 | exercises the rc=4 path (stubs `command -v flock` to force mkdir) |
| 4 | stderr emits structured WARN | confirms diagnostic message format |
| 5 | ledger unmutated when rc=4 | no silent data loss when refusing |
| 6 | positive control — directory at lock path → mkdir branch succeeds | non-stale path still works |
| 7 | mkdir branch cleans up lock directory after success | no leftover state from positive path |

Test isolates fixture in `mktemp -d`; trap cleanup ensures no
host-state pollution. Stubs `command -v flock` via shell function
shadow so the test deterministically exercises the mkdir branch
on any platform (Linux, macOS-with-flock, macOS-without-flock).

## Acceptance gates

| Gate | Status | Evidence |
|---|---|---|
| AG1 — grep fleet for rogue `> lock` pattern | DID | 3-directory grep yielded only the lib's own .xy71r fix-comment in prose; root cause: the lib's flock branch creates `${target}.lock` as a regular file via `9>"$lock"` and doesn't rm on exit |
| AG2 — add regression test for rc=4 path | DID | `tests/jsonl-append-rc4-stale-lock.sh` 7/7 PASS (substrate gate + 2 negative + 1 positive control + cleanup invariant) |

did=2/2 didnt=none gaps=none.

## Pinned artifact SHAs

| Artifact | Path | SHA-256 |
|---|---|---|
| regression test | `tests/jsonl-append-rc4-stale-lock.sh` | `844b0c632712f1b9e89120c6696cd41e0d021f85d7172e3b5ec5c449f4a815ef` |

## Verification commands (re-runnable)

```bash
# Regression suite (7 PASS)
bash /Users/josh/Developer/flywheel/tests/jsonl-append-rc4-stale-lock.sh
# expected: SUMMARY pass=7 fail=0

# rc=4 branch still in source
grep -nE 'flywheel-xy71r|return 4' \
  ~/.local/share/flywheel-watchers/lib/jsonl-append.sh
# expected: at least 3 lines (xy71r citation + return 4 in fw_jsonl__with_lock + return 4 in fw_jsonl_append_validated case)

# Fleet rogue-writer grep
grep -rnE '> ?[^|]*\.lock[^/a-z]|>> ?[^|]*\.lock[^/a-z]' \
  /Users/josh/Developer/flywheel/.flywheel/scripts/ \
  ~/.claude/skills/.flywheel/ \
  ~/.local/share/flywheel-watchers/ \
  2>/dev/null | grep -v '\.bak\|\.lock-'
# expected: 1 line (the xy71r prose citation in jsonl-append.sh:29)
```

## L112 probe (worker callback)

```bash
bash /Users/josh/Developer/flywheel/tests/jsonl-append-rc4-stale-lock.sh 2>/dev/null | tail -1
```

Expected (literal): `SUMMARY pass=7 fail=0`.

## Boundary

- **No edit to `~/.local/share/flywheel-watchers/lib/jsonl-append.sh`.**
  The xy71r fix is in place and works; my regression test exercises
  it.
- **No cleanup of the 9 file-shaped lock paths** in
  `~/.local/state/flywheel/`. Several are correctly used by
  fcntl.flock consumers (e.g.,
  `shared-surface-reservation-check.sh`); cleaning them
  indiscriminately would break those consumers. The rc=4
  detection IS the canonical guardrail for cross-convention
  collisions.
- **No follow-up bead for the flock-branch leaving-file-behind
  cleanup.** Per xy71r close, the rc=4 detection is the
  intentional guardrail; a "rm on exit" sub-fix is potentially
  cleaner but is out of this bead's scope and may break
  cross-host flock-style semantics.

## Skill auto-routes

- `canonical-cli-scoping=n/a` — no CLI authored.
- `rust-best-practices=n/a` — no Rust.
- `python-best-practices=n/a` — no Python.
- `readme-writing=n/a` — substrate test, not README.

## L61 ECOSYSTEM-TOUCH BLOCK

- `agents_md_updated=no` — no doctrine surface mutated.
- `readme_updated=not_applicable`.
- `no_touch_reason=substrate_regression_test_only_no_lib_edit_no_doctrine_surface_mutated_xy71r_fix_already_in_source_test_lives_in_flywheel_repo_lib_in_local_share_flywheel-watchers`.

## Four-Lens Self-Grade — bar = Three Judges + Jeffrey + Donella

- **Brand: 9** — closes 2/2 acceptance gates; rogue-writer
  verdict is concrete + cites line numbers; 7-test regression
  guards substrate + behavior + cleanup invariants.
- **Sniff: 9** — outcome-shaped headline ("rogue-writer verdict:
  jsonl-append.sh ITSELF is the writer… cross-host alternation
  traps the macOS run forever… 7-test regression exercises the
  rc=4 path deterministically"); fleet grep evidence with grep
  command + result count; 9-row file-shape table for the wider
  fleet finding (informational, with rationale for why it's not
  a separate bead).
- **Jeff: 9** — Jeffrey-not-Jeff in human-facing prose; small
  surface (one regression test + one audit pack); refuses to
  edit the lib (fix is already in place), refuses to clean up
  the wider .lock-as-file fleet (would break legitimate fcntl
  consumers), refuses to file a follow-up for the flock-branch
  cleanup (out of scope per xy71r close discipline).
- **Public: 9** — Three Judges check passes:
  - **operator (acting tomorrow)**: 3 verification commands
    confirm regression + branch + grep status in <10s.
  - **maintainer (extending later)**: the test stubs
    `command -v flock` deterministically — adding a new lock
    convention or new rc class is a one-line addition to the
    case stmt + a test variant.
  - **future worker (LLM agent)**: facing another mkdir-vs-flock
    lock-path collision, the worker has (a) the rc=4
    detection pattern as the canonical guardrail, (b) the
    cross-host alternation diagnosis as the root-cause shape,
    (c) the 9-row fleet table as a baseline for what's
    correctly file-shaped (fcntl consumers) vs incorrectly
    (mkdir consumers).

`four_lens=brand:9,sniff:9,jeff:9,public:9` (4/4 PASS at threshold 8).

## L52 Receipt

`beads_filed=none beads_updated=flywheel-t38to
no_bead_reason=2of2_DoD_closed_fleet_grep_verdict_jsonl-append.sh_flock_branch_is_the_writer_via_9_redirect_lock_no_rm_on_exit_rc=4_regression_test_exercises_path_deterministically_via_command_v_flock_stub_no_followup_observed_wider_fleet_lock_file_findings_informational_legitimate_fcntl_consumers_use_file_shape_correctly`.
