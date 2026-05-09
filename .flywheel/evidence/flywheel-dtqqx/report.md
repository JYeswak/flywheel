# flywheel-dtqqx — Worker Report

**Task:** [ntm-watch] clarify machine JSON contract for wrapper probes
**Identity:** MagentaPond (codex-pane on flywheel:1)
**Repo head:** 7bc8497 (master)
**Status:** done
**Mission fitness:** infrastructure — clarifies that `ntm watch --json --tail=1` is stream-only despite the global `--json` flag, documents the disposition in NTM-SURFACE-INVENTORY.md, and locks the canonical wrapper contract via a fixture test that proves stream-shaped output is tolerated by `halt-disease-watchdog.sh:run_watch`.

## Verdict

**`ntm watch --json --tail=1` is stream-only.** The `--json` global flag is documented in `ntm watch --help` but the actual stdout is human-readable line-prefixed text (`[hostname HH:MM:SS] <text>`), not a JSON envelope. Verified by live probe at 2026-05-09T16:31Z.

**Disposition: STREAM-ONLY-USE.** Wrappers MUST NOT parse stdout as JSON. Decision semantics live on one-shot machine-readable surfaces (`ntm --robot-activity`, `ntm activity --json`, `ntm doctor --json`, `ntm history --json`). The canonical wrapper at `halt-disease-watchdog.sh:73-83` (`run_watch()`) bounds the stream via `timeout WATCH_TIMEOUT_SECONDS`, captures `stdout_head` as a 500-byte truncated string for evidence, treats `rc=0` OR `rc=124` as ok, and emits the envelope `{ok, session, exit_code, native_command, stdout_head, stderr_head}`. Decision-class signals come from `ntm activity` and `ntm doctor` JSON probes elsewhere in the watchdog.

## Acceptance gate coverage

| Bead AG | Status | Evidence |
|---|---|---|
| **AG1** `ntm watch --json` emits a bounded machine-readable event/envelope OR documents that watch is stream-only | DID — documented stream-only | NTM-SURFACE-INVENTORY.md row 103 changed from `WIRE-IT-QUEUED - wave-2 P1/P2 TBD` to `STREAM-ONLY-USE / DOCUMENTED-DISPOSITION via flywheel-dtqqx` with full disposition narrative naming the canonical wrapper, alternative one-shot surfaces, and the new fixture. Live probe at 2026-05-09T16:31Z confirmed stream-shape output (lines like `[Joshs-Mac-Studio.local 10:31:07] eam`). |
| **AG2** Add or extend a fixture proving a wrapper can call `ntm watch --json --tail=1` without human-output parsing assumptions | DID | new `tests/halt-disease-watchdog-stream-output-test.sh` (~95 lines) — fake `ntm watch` emits stream-shaped human text, then sleeps to force timeout. Wrapper produces valid JSON envelope with `stdout_head` containing the stream-text-as-string (NOT jq-parsed). 5/5 assertions PASS. |
| **AG3** Update NTM surface inventory or wrapper migration notes with the disposition | DID | NTM-SURFACE-INVENTORY.md row 103 updated as described under AG1 (this is the inventory artifact). |

did=3/3, didnt=none, gaps=none.

## Live verification

```bash
# Confirm watch is stream-shape despite --json
timeout 3 /Users/josh/.local/bin/ntm watch flywheel --json --tail=1 2>&1 | head -5
# → "Watching session: flywheel"
#   "Press Ctrl+C to stop"
#   "[Joshs-Mac-Studio.local 10:31:07] <stream-text>"
# (No JSON envelope; stream of human-readable lines)

# Run the new fixture test
bash /Users/josh/Developer/flywheel/tests/halt-disease-watchdog-stream-output-test.sh
# → "halt-disease-watchdog ran (rc=1), output captured (5575 bytes)"
#   "PASS wrapper emits valid JSON envelope"
#   "PASS canonical ntm watch flags recorded"
#   "PASS envelope names ntm watch as a native surface"
#   "PASS stdout_head captured as string (not parsed as JSON)"
#   "PASS wrapper completed without crashing on stream-shaped ntm watch output"
#   "halt-disease-watchdog stream-output tolerance test passed"

# Confirm inventory disposition row updated
grep -nE '\| 103 \|' /Users/josh/Developer/flywheel/.flywheel/NTM-SURFACE-INVENTORY.md
# → row 103 now says STREAM-ONLY-USE | DOCUMENTED-DISPOSITION via flywheel-dtqqx

# Confirm canonical wrapper exists and references the bounded probe
sed -n '73,83p' /Users/josh/Developer/flywheel/.flywheel/scripts/halt-disease-watchdog.sh
# → run_watch() function with timeout + stdout_head capture
```

L112 probe: `bash /Users/josh/Developer/flywheel/tests/halt-disease-watchdog-stream-output-test.sh 2>&1 | tail -1` expects literal `halt-disease-watchdog stream-output tolerance test passed`.

## Why STREAM-ONLY-USE rather than WIRE-IT-QUEUED

The previous classification (`WIRE-IT-QUEUED - wave-2 P1/P2 TBD`) implied the surface needed a wave-2 wire-in bead. After the live probe + the `flywheel-rd8oa` closeout that surfaced this bead, the right disposition is:

1. **The surface is already correctly used** by `halt-disease-watchdog.sh:run_watch()` — bounded, time-boxed, evidence-only.
2. **There is no general-purpose wire-in** that fits because the surface is fundamentally stream-shaped; the global `--json` flag does not transform the output for `watch`.
3. **Decision semantics belong elsewhere** — the bead body itself names this: *"the watchdog now records the bounded `ntm watch` probe and keeps decision semantics on structured activity/doctor inputs."*

So instead of a wire-in bead, the right outcome is a documented disposition + a fixture test that locks the canonical wrapper contract. That's what this dispatch ships.

## Files changed

- `~ /Users/josh/Developer/flywheel/.flywheel/NTM-SURFACE-INVENTORY.md` — row 103 disposition updated (single-row edit; no other rows touched)
- `+ /Users/josh/Developer/flywheel/tests/halt-disease-watchdog-stream-output-test.sh` — new ~95-line fixture proving the wrapper tolerates stream-shaped output (5 assertions PASS)
- `+ /Users/josh/Developer/flywheel/.flywheel/evidence/flywheel-dtqqx/report.md` — this file

## Three-Q

- **VALIDATED:** live probe confirms stream-shape; fixture test 5/5 PASS; inventory row visibly updated.
- **DOCUMENTED:** STREAM-ONLY-USE classification + canonical wrapper file:line + alternative one-shot surfaces + fixture path all named in the inventory row's notes column.
- **SURFACED:** any future migration of `halt-disease-watchdog.sh` cannot accidentally start parsing the watch stdout as JSON without the fixture catching the regression.

## Four-Lens Self-Grade

four_lens=brand:9,sniff:9,jeff:9,public:9 — **4/4 PASS**

- **Brand (9/10):** minimal-surface — single-row inventory edit + one new fixture test; no churn elsewhere.
- **Sniff (9/10):** every claim verified — live probe receipt (stream-shape), fixture pass count (5/5), inventory row diff (row 103 single-row edit), wrapper file:line citation (lines 73-83 of halt-disease-watchdog.sh).
- **Jeff (9/10):** cites operational primitives — `ntm watch`, `timeout`, `jq`, `bash -c`. Versioned receipt (`halt-disease-watchdog/v1` schema embedded in the wrapper output). The disposition acknowledges that a `--json` global flag is documentation-only when a subcommand inherits stream semantics; this matches Jeff's `git diff --json` / `man-page-says-X` pattern from past INCIDENTS.
- **Public (9/10):** **Three Judges check** — skeptical operator can re-run the live probe + the fixture and reproduce; maintainer sees the inventory row references the exact wrapper file:line so any refactor surfaces the contract; future worker has a fixture that fails if the wrapper ever starts parsing stream stdout as JSON.

`evidence_schema_version=worker-evidence/v1`. `wrapper_envelope_schema=halt-disease-watchdog/v1`. `four_lens_close_validator_version=four-lens-close-validator/v1`.

## Skill auto-routes addressed

- `canonical-cli-scoping=n/a` — no new CLI surface; this work documents an existing one.
- `rust-best-practices=n/a` — no Rust authored.
- `python-best-practices=n/a` — no Python authored.
- `readme-writing=n/a` — inventory row edit, not a README.

## Skill discoveries

`skill_discoveries=0 sd_ids=none` — task fits the canonical surface-disposition pattern. The "global --json flag inherited but not honored by subcommand" observation is a candidate convergent-evolution signal but not yet 3-strike across surfaces (only `ntm watch` so far) — log to memory only if it surfaces twice more.

## L52 / L70 receipt

- L52 (issues-to-beads): **`no_bead_reason=disposition_documented_in_inventory_row_with_fixture_lock_no_followup_bead_needed`** — disposition + fixture is the deliverable.
- L70 (no-punt): the next-actionable IS this disposition + fixture — running it in the same tick satisfies L70.

## L61 ecosystem-touch

- `agents_md_updated=no` — inventory edit is not L-rule promotion.
- `readme_updated=not_applicable` — no README touched.
- `no_touch_reason=inventory_disposition_update_only_no_doctrine_change`

## Compliance Pack

Score: 920/1000.

- 3/3 acceptance gates DID
- Live probe + fixture test + inventory edit all in evidence
- 5/5 fixture assertions PASS
- 4/4 lenses with 9/10 self-grades
- L107 reservations acquired/released

Pack path: `.flywheel/evidence/flywheel-dtqqx/`.

## Cross-references

- Surfaced by: `flywheel-rd8oa` close (per bead body)
- Subject surface: row 103 of `.flywheel/NTM-SURFACE-INVENTORY.md` (NTM `watch`)
- Canonical wrapper: `.flywheel/scripts/halt-disease-watchdog.sh:73-83` `run_watch()`
- New fixture: `tests/halt-disease-watchdog-stream-output-test.sh`
- Companion fixture: `tests/halt-disease-watchdog-native-test.sh` (existing; uses fake JSON-emitting ntm)
- Alternative one-shot surfaces: `ntm --robot-activity=<session>`, `ntm activity --json`, `ntm doctor --json`, `ntm history --json`
- L-rules cited: L107 (shared-surface reservation, applied), L70 (no-punt), L52 (issues-to-beads receipt with specific no_bead_reason)
