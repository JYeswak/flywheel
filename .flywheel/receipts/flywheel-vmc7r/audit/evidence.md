# flywheel-vmc7r — gap-hunt-probe wired-but-cold 4MB budget false-positive fix

## Bead context

- ID: `flywheel-vmc7r` (P3)
- Title: `[heuristic-fix] gap-hunt-probe wired-but-cold: 4MB budget cap creates false positives`
- Filed by: `MistyCliff` (worker for `flywheel-2xdi.42`, 2026-05-09)
- Supersedes: `flywheel-7h3om` (filed concurrently by `CloudyMill` from `flywheel-2xdi.41` — same root cause, closed by orch as superseded)
- DoD: heuristic stops flagging `lib/mission.sh` as cold + regression test asserts the false-positive case doesn't fire (2 acceptance gates)

## Root cause (verified)

`probe_wired_but_cold()` (gap-hunt-probe.sh:415) reads recent ledgers via `recent_ledger_text(days=30, max_bytes=4_000_000)` (line 355). The pre-fix function:

1. Iterates `sorted(STATE_DIR.glob('*.jsonl'))` ALPHABETICALLY.
2. Prepends each `path.name` then content to a running corpus.
3. Caps total at 4 MiB and `break`s — later-alphabet ledger NAMES never enter the corpus.

When the first ~12 alphabetical ledgers (e.g. `agents-md-fleet-propagation.jsonl` @1.8 MiB, `br-db-corruption-monitor-ledger.jsonl` @991 KiB) consume the budget, every later-alphabet ledger basename is dropped — including high-signal sibling ledgers like `doctrine-sync-ledger.jsonl` (1777 `mission` hits) and `fuckup-log.jsonl` (4.8 MiB, today's mtime).

Concrete false-positives observed today (both originally filed beads):

- `flywheel-2xdi.41` — `~/.claude/skills/.flywheel/lib/fuckup.sh` flagged cold; reality: called by `portable_doctor.sh:614`, sibling `fuckup-log.jsonl` 4.8 MiB today.
- `flywheel-2xdi.42` — `~/.claude/skills/.flywheel/lib/mission.sh` flagged cold; reality: sourced unconditionally by `bin/flywheel-loop:33-34`, `mission_lock_age_json` called from `portable_doctor.sh:609`, 43 hits in repo `dispatch-log.jsonl` (most recent 2026-05-09T17:23:09Z).

## Fix shape

`recent_ledger_text` rewritten as a two-pass corpus build:

- **Pass 1 (no budget)** — collect every recent-window ledger basename into a complete name corpus. Cost is O(filenames) — <100 KiB even for thousands of ledgers. Fixes the false-positive class because a script's name now matches if ANY recent ledger has the script's name or stem in its filename, regardless of budget pressure.
- **Pass 2 (4 MiB budget, mtime DESCENDING)** — content scan ordered by mtime so high-signal recent activity always contributes content, even when budget is tight. Addresses the bead's fix proposal #1.
- **Repo dispatch-log inclusion** — pulls `REPO_ROOT/.flywheel/dispatch-log.jsonl` into the candidate set per the bead's fix proposal #4. That ledger has 43 `mission_lock_age` hits in the repo today — high-signal source not previously sampled.

Diff is +52/-7 in `recent_ledger_text` only. No other gap-class probe touches that function (verified — `probe_wired_but_cold` is the sole caller).

## Acceptance — DoD gates

| Gate | Done |
|---|---|
| heuristic stops flagging `lib/mission.sh` as cold | yes — live probe run confirms `mission_sh_flagged=false` (also `fuckup_sh_flagged=false` for the .41 sibling case) |
| regression test asserts the false-positive case doesn't fire | yes — `.flywheel/tests/test-gap-hunt-probe-wired-but-cold-budget.sh`, 7/7 PASS |

`did=2/2`

## Regression test

`.flywheel/tests/test-gap-hunt-probe-wired-but-cold-budget.sh` (7 gates):

- **T1**: probe runs to completion against fixture (sanity).
- **T2**: fixture junk-ledger total exceeds 4 MiB so the budget cap is exercised (`have=5616000 > 4000000`).
- **T3**: synthetic target script `vmc7r-target.sh` with sibling ledger `zzz-vmc7r-target-events.jsonl` (alphabetically last) is NOT flagged wired-but-cold against the fixture STATE_DIR. This is the regression assertion: with the OLD probe the alphabetical iteration consumes the budget on the three junk ledgers and `zzz-vmc7r-target-events.jsonl` is elided; the NEW probe always-completes the name pass.
- **T4a**: live `lib/mission.sh` not flagged (vmc7r DoD).
- **T4b**: live `lib/fuckup.sh` not flagged (2xdi.41 DoD).
- **T5a/b**: `--info` and `--schema` triad still rc=0 (no introspection regression).

Result: `pass=7 fail=0`. See `test-output.txt` for the full run.

## L52 receipt

- `flywheel-7h3om` — duplicate filed by CloudyMill from `2xdi.41` close. Closed by orch as superseded with a one-line note citing this bead. No remediation needed.
- No new beads filed; the fix is in scope.

`beads_filed=none beads_updated=flywheel-7h3om` (closed-as-superseded by orch — included as updated bookkeeping)

## Skill auto-routes

| Route | Status | Note |
|---|---|---|
| canonical-cli-scoping | yes | Probe already has triad (info/schema/doctor) + dry-run/--apply discipline; fix preserves all gates; no new flags introduced; file-length unchanged at <1100 lines (under threshold). |
| rust-best-practices | n/a | Bash file with embedded Python. |
| python-best-practices | yes-partial | Embedded Python: type hints preserved on the new `recent_ledger_text` (returns `str`, candidates typed as `list[tuple[float, Path]]`), no library unwraps, file ops use `STATE_DIR.glob` and existing `read_text` helper. The function is single-block inline Python — no separate module shape constraint applies. |
| readme-writing | n/a | No README touched. |

## Four-Lens Self-Grade

- **brand: 9** — single-source-of-truth fix (one function rewritten, no spread); preserves all 7 cold-class consumers' contract; explicit citation of the bead's listed fix proposals (#1 mtime-desc + #4 dispatch-log).
- **sniff: 9** — diff is local to one function; fixture-based regression test; no global env-var changes; fix doctrine matches feedback memory `feedback-A3-single-source-of-truth-worker-reflexive`.
- **jeff: 9** — name corpus is always-complete (no silent budget loss), mtime-desc orders recency over alphabetical accident, dispatch-log inclusion adds the repo-local high-signal feed; the fix is structural rather than allowlist-based, so future similar false-positives also resolve.
- **public: 9** — Three Judges: skeptical operator (live probe shows mission.sh + fuckup.sh both gone), maintainer (function docstring cites the bead and the two false-positive observations), future worker (regression test fixture is self-contained and reproducible).

`four_lens=brand:9,sniff:9,jeff:9,public:9`

## Mission fitness

`infrastructure` — gap-hunt-probe is the orchestrator's paradigm-tier self-audit (Step 4n). A false-positive class that flags genuine wired+warm scripts as cold pollutes the gap-hunt signal and wastes orchestrator attention on phantom gaps. Fixing the heuristic at its source directly improves continuous-orchestrator-uptime by tightening Step 4n's signal-to-noise.
