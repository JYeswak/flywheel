# flywheel-odugq Evidence — JSM skill mutation gate bounded + offline-distinguishable

Task: `flywheel-odugq-859456`
Bead: `flywheel-odugq` (P3 OPEN → CLOSED this turn)
Title: [gfsr-followup] JSM skill mutation gate times out on jsm list
Date: 2026-05-09
Identity: MistyCliff (flywheel:0.4)
Origin: flywheel-gfsr-34720b L52 receipt — `skill-enhance-jsm-discipline.sh
--validate-packet` timed out on `jsm list --json` after 20s.
Mission fitness: `mission_fitness=infrastructure` — workers no longer
hang on JSM substrate flake; dispatch evidence now distinguishes
managed / unmanaged / unavailable cleanly.

## Bead acceptance, line by line

| Acceptance line | Status | Evidence |
|---|---|---|
| Skill mutation preflight has a bounded offline path for `.flywheel` or reports a stable skip reason | DID | `JSM_OFFLINE=1` env opt-out path + `--jsm-list-json PATH` fixture path are both honored; both emit `status=skipped` (or `status=pass` with `reason=not_skill_enhance` for non-skill packets) and `jsm_list_status=offline\|fixture` so the worker has a stable distinguishable signal. |
| Dispatch evidence can distinguish JSM-managed, unmanaged, and unavailable without hanging workers | DID | every emission now carries `jsm_list_status` ∈ `{live, fixture, unavailable, offline}`; per-skill records carry `jsm_status` ∈ `{managed, unmanaged, unavailable}`; default timeout reduced from 20s → 10s; live JSM probe completes in 1s today (`live-probe.json`). |

## What changed

### `.flywheel/scripts/skill-enhance-jsm-discipline.sh`

1. **`load_jsm_list` no longer aborts the worker on transport flake.**
   It always emits valid JSON on stdout and sets two globals
   (`JSM_LIST_STATUS`, `JSM_LIST_REASON`) so the caller can route on
   availability. Five branches:
   - `JSM_OFFLINE=1` → `offline` (intentional opt-out).
   - `--jsm-list-json PATH` readable → `fixture`.
   - `--jsm-list-json PATH` unreadable → `unavailable`.
   - `jsm` binary missing on PATH → `unavailable`.
   - Live `jsm list --json` timeout / non-zero exit / non-JSON → `unavailable`.
   - Otherwise → `live` with elapsed seconds in the reason.
2. **Default timeout reduced from 20s → 10s** (`JSM_LIST_TIMEOUT_SEC`
   override unchanged). Workers no longer wait 20s on every dispatch.
3. **`validate_packet`** gains an explicit `jsm_unavailable` branch
   that emits `status=skipped`, `jsm_list_status=...`, and per-skill
   records with `jsm_status=unavailable`. Errors array stays empty in
   this branch — we cannot validate the rules without classification,
   so we do not refuse the dispatch.
4. **`emit_audit`** sets `status=skipped` when JSM is unavailable;
   `pass` only when classification was actually performed.
5. **Per-skill records gain `jsm_status`** in both modes (`managed`,
   `unmanaged`, or `unavailable`) so the field is grep-friendly for
   downstream consumers.
6. **Subshell-state bug fixed.** Previous `list="$(load_jsm_list)"`
   captured stdout but the `JSM_LIST_STATUS` set inside the function
   never reached the caller (subshell). Switched to a tempfile pattern
   (`load_jsm_list >"$jsm_buf"; list="$(cat "$jsm_buf")"`) so globals
   propagate.
7. **Help text** documents env knobs (`JSM_BIN`, `JSM_LIST_TIMEOUT_SEC`,
   `JSM_LIST_JSON`, `JSM_OFFLINE`) + the `jsm_list_status` enum.

### `tests/skill-enhance-jsm-discipline.sh`

Six new assertions (now 14/14 PASS):

| Assertion | Behavior covered |
|---|---|
| `JSM_OFFLINE=1 emits skipped + jsm_list_status=offline + per-skill unavailable` | Explicit offline opt-out. |
| `missing jsm binary surfaces jsm_list_status=unavailable` | Binary not on PATH. |
| `slow jsm list times out fast and surfaces jsm_list_status=unavailable` | Timeout fixture (`JSM_LIST_TIMEOUT_SEC=2` against a `sleep 60` fake jsm). |
| `fixture path surfaces jsm_list_status=fixture` | `--jsm-list-json` snapshot path. |
| `managed skill record carries jsm_status=managed` | Per-skill record shape on managed classification. |
| `unmanaged skill record carries jsm_status=unmanaged` | Per-skill record shape on unmanaged classification. |

Existing 8 tests still PASS unchanged.

## Acceptance gates

| Gate | Status | Evidence |
|---|---|---|
| AG1 — substrate updated with close evidence | DID | `.flywheel/audit/flywheel-odugq/` carries this evidence pack, test output, pinned SHAs, and a live JSM probe receipt |
| AG2 — targeted test passes and named | DID | `bash tests/skill-enhance-jsm-discipline.sh` returns `SUMMARY pass=14 fail=0`; live probe `live-probe.json` shows `jsm_list_status=live`, `jsm_list_reason="jsm list --json (1s)"` (down from the 20s timeout that authored this bead) |
| AG3 — `br show flywheel-odugq` open until evidence exists | DID | this evidence pack exists; bead is closed in the same turn |

did=3/3 didnt=none gaps=none.

## Pinned artifact SHAs

| Artifact | Path | SHA-256 |
|---|---|---|
| validator script | `.flywheel/scripts/skill-enhance-jsm-discipline.sh` | `a52ef55e9af83e35cb9c18510232e40b881a4ef5416a6b44cd49944731adf56a` |
| validator tests | `tests/skill-enhance-jsm-discipline.sh` | `1a3bf90a48a891264412b51701bf12b44573b778d9de420ff14df6e42952d454` |

## Live probe receipt (verbatim from `live-probe.json`)

```json
{"status":"refused","jsm_list_status":"live","jsm_list_reason":"jsm list --json (1s)","errors":1,"skills":5}
```

The 20s timeout that authored this bead is gone — the live JSM call
now completes in 1s. The `status:"refused"` result is unrelated to
this bead (it's the validator complaining about the meta-packet's
own missing patch artifacts, which is correct behavior for a
non-skill-enhance dispatch).

## Verification commands (re-runnable)

```bash
# Full test suite
bash /Users/josh/Developer/flywheel/tests/skill-enhance-jsm-discipline.sh
# expected: SUMMARY pass=14 fail=0

# Offline path (workers can use this when JSM is known-unavailable)
JSM_OFFLINE=1 \
  /Users/josh/Developer/flywheel/.flywheel/scripts/skill-enhance-jsm-discipline.sh \
  --validate-packet /tmp/dispatch_flywheel-odugq-859456.md --json | jq '.jsm_list_status'
# expected: "offline"

# Bounded live path (default timeout 10s)
/Users/josh/Developer/flywheel/.flywheel/scripts/skill-enhance-jsm-discipline.sh \
  --validate-packet /tmp/dispatch_flywheel-odugq-859456.md --json | jq '.jsm_list_status'
# expected: "live" (when JSM responds) or "unavailable" (when JSM is slow / down)
```

## L112 probe (worker callback)

```bash
bash /Users/josh/Developer/flywheel/tests/skill-enhance-jsm-discipline.sh 2>/dev/null | tail -1
```

Expected (literal): `SUMMARY pass=14 fail=0`.

## Boundary

- **No skill mutation.** `~/.claude/skills/<any>` not touched. The script lives in the flywheel repo, not under `~/.claude/skills/`, so JSM discipline does not apply to its own self-edit.
- **No backwards-compat break.** Existing fixture path (`--jsm-list-json`) keeps working with `jsm_list_status=fixture`. All 8 prior tests still PASS.
- **No upstream patch.** `jsm` binary (Jeffrey-owned) is not modified.
- **`status=skipped` is exit 0.** Per the help text update, exit code 0 covers both `pass` and `skipped`. Workers that need to distinguish look at `.jsm_list_status` not the exit code. Refused is still exit 1, usage error still exit 2.

## Skill auto-routes

- `canonical-cli-scoping=yes` — script exposes `--audit`, `--validate-packet`, `--skills`, `--jsm-list-json`, `--json`, `--help`/`-h`. Stable exit codes 0/1/2. Schema-versioned output (`skill-enhance-jsm-discipline/v1`). New env knobs documented in help.
- `rust-best-practices=n/a` — no Rust.
- `python-best-practices=n/a` — no Python.
- `readme-writing=n/a` — no public README touched.

## L61 ECOSYSTEM-TOUCH BLOCK

- `agents_md_updated=no` — this is a script-level fix; AGENTS.md does not name `skill-enhance-jsm-discipline.sh` directly.
- `readme_updated=not_applicable`.
- `no_touch_reason=script-level_bound-and-distinguish_no_doctrine_or_AGENTS_change_required`.

## Four-Lens Self-Grade — bar = Three Judges + Jeffrey + Donella

- **Brand: 9** — closes the bead's two acceptance lines verbatim. The 20s → 10s default + per-emission `jsm_list_status` give workers a single grep-friendly signal for the missing classification class.
- **Sniff: 9** — three concrete failure-class fixtures (offline env, missing binary, slow timeout) prove the bounded paths work; live probe confirms 1s real-world completion; subshell-state bug caught by the JSM_OFFLINE test (the manual probe surfaced empty `jsm_list_status` until the tempfile pattern landed).
- **Jeff: 9** — Jeffrey-not-Jeff in human-facing prose; small surface (one script + one test); no upstream patch; backwards-compatible (fixture path preserved); explicit help-text documentation of the new env knobs.
- **Public: 9** — Three Judges check passes:
  - **operator (acting tomorrow)**: one bash command runs the suite and reports 14/14; `JSM_OFFLINE=1` is one env var to flip when JSM substrate is known-down.
  - **maintainer (extending later)**: `jsm_list_status` enum is the extension point — adding a `cached` branch (e.g., `jsm-list-cache.json`) would slot in the same shape without touching the per-skill records.
  - **future worker (LLM agent)**: the four-state availability enum is reusable for any other JSM-shaped substrate gate; the subshell-state lesson (functions returning JSON via `$(...)` lose globals; use tempfile + cat) is documented in the file.

`four_lens=brand:9,sniff:9,jeff:9,public:9` (4/4 PASS at threshold 8).

## L52 Receipt

`beads_filed=none beads_updated=flywheel-odugq
no_bead_reason=script-level_fix_complete_no_followup_observed_gap_in_scope_today`.
